module gui.edit_window;

import imports.all;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */
class EditWindow : MainWindow{
    this(){
        super("エディットウインドウ");
    }
}
