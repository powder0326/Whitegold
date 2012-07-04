module gui.overview_window;
import imports.all;
import project_info;

/**
   オーバービューウインドウ

   マップ全体の縮小表示。
 */
class OverviewWindow : MainWindow{
    this(){
        super("オーバービュー");
//         setSizeRequest(320, 320);
        setDeletable(false);
    }
}
