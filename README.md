# calibre_to_native_language_path

calibre to native language path, **SHOULD** be in **utf8** environment, close calibre before execute.

把calibre文件的拼音路径改回中文，注意必须是在**utf8**环境下，执行之前必须先关闭calibre。

# install

archlinux:

    sudo pacman -S perl-rename

# usage

    perl calibre_to_native_language_path.pl [calibre book directory path]

    perl calibre_to_native_language_path.pl ~/Calibre
