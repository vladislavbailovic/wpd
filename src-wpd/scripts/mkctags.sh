#/bin/bash

hasctags=$(which ctags);
if [ "" == "$hasctags" ]; then
	echo "Install ctags"
	exit 1
fi

find WPD_PLUGIN_DIR \
	-type f \
	-regextype posix-egrep \
	-regex ".*\.(php|js)" \
	! -path "*/.git*" \
	! -path "*/node_modules/*" \
	! -path "*/build/*"  \
	! -path "*/wp-content/uploads/*" \
	! -path "*/*.min.js" \
| ctags -f "WPD_PLUGIN_DIR/WPD_PLUGIN.tags" --fields=+KSn -L -
