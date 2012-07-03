module gui.overview_window;
import imports.all;
import project_info;

/**
   オーバービューウインドウ

   マップ全体の縮小表示。
 */
class OverviewWindow : MainWindow{
    void delegate(EWindowType windowType, bool show) onWindowShowHideFunction;
    this(){
        super("オーバービュー");
//         setSizeRequest(320, 320);
        addOnDelete(&onDelete);
    }
    /// 右上の×ボタンが押されても破棄せずに非表示にするだけ
    bool onDelete(Event event, Widget widget){
        if(onWindowShowHideFunction !is null){
            onWindowShowHideFunction(EWindowType.OVERVIEW, false);
        }
        return true;
    }
}
