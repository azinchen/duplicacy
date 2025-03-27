#!/bin/bash
# scripts/update_apk_versions.sh
# This script extracts package names and versions from a specified Dockerfile,
# checks for updates from Alpine package repositories (main first, then community),
# and updates the Dockerfile if necessary.
# Usage: ./scripts/update_apk_versions.sh <path/to/Dockerfile>
# If no argument is provided, it defaults to "Dockerfile" in the current directory.

DOCKERFILE="${1:-Dockerfile}"

if [ ! -f "$DOCKERFILE" ]; then
  echo "Error: Dockerfile not found at '$DOCKERFILE'"
  exit 1
fi

# --- 1. Extract Alpine Version from Dockerfile ---
ALPINE_VERSION_FULL=$(grep '^FROM alpine:' "$DOCKERFILE" | head -n1 | sed -E 's/FROM alpine:(.*)/\1/')
ALPINE_BRANCH=$(echo "$ALPINE_VERSION_FULL" | cut -d. -f1,2)
echo "Using Alpine branch version: $ALPINE_BRANCH"

# --- 2. Extract Package List from Dockerfile ---
joined_content=$(sed ':a;N;$!ba;s/\\\n/ /g' "$DOCKERFILE")
package_lines=$(echo "$joined_content" | grep -oP 'apk --no-cache --no-progress add\s+\K[^&]+')
packages=$(echo "$package_lines" | tr ' ' '\n' | sed '/^\s*$/d' | sort -u)

echo "Found packages in $DOCKERFILE:"
echo "$packages"
echo

# --- 3. Function to Precisely Extract Version from HTML using AWK ---
extract_new_version() {
    local url="$1"
    local html
    html=$(curl -s "$url")
    local version
    version=$(echo "$html" | awk 'BEGIN { RS="</tr>"; FS="\n" } 
      /<th class="header">Version<\/th>/ {
         if (match($0, /<strong>([^<]+)<\/strong>/, a)) {
            print a[1]
         }
      }' | head -n 1)
    echo "$version"
}

# --- 4. Function to Update a Single Package ---
update_package() {
    pkg_with_version="$1"  # e.g., tar=1.35-r2
    if [[ "$pkg_with_version" == *"="* ]]; then
        pkg=$(echo "$pkg_with_version" | cut -d'=' -f1)
        current_version=$(echo "$pkg_with_version" | cut -d'=' -f2)
    else
        pkg="$pkg_with_version"
        current_version=""
    fi

    # First try the "main" repository.
    URL="https://pkgs.alpinelinux.org/package/v${ALPINE_BRANCH}/main/x86_64/${pkg}"
    echo "Checking package '$pkg' (current version: $current_version) from: $URL"
    new_version=$(extract_new_version "$URL")
    repo="main"

    # If not found in main, try the "community" repository.
    if [ -z "$new_version" ]; then
        URL="https://pkgs.alpinelinux.org/package/v${ALPINE_BRANCH}/community/x86_64/${pkg}"
        echo "  Not found in main, trying community: $URL"
        new_version=$(extract_new_version "$URL")
        repo="community"
    fi

    if [ -z "$new_version" ]; then
        echo "  Could not retrieve new version for '$pkg' from either repository. Skipping."
        return
    fi

    if [ "$current_version" != "$new_version" ]; then
        echo "  Updating '$pkg' from $current_version to $new_version (found in $repo repo)"
        sed -i "s/${pkg}=${current_version}/${pkg}=${new_version}/g" "$DOCKERFILE"
    else
        echo "  '$pkg' is up-to-date ($current_version)."
    fi
    echo
}

# --- 5. Loop Over All Packages and Update ---
while IFS= read -r package; do
    update_package "$package"
done <<< "$packages"

