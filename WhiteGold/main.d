module main;

private import imports.all;
private import project_info;
private import gui.edit_window;
private import gui.parts_window;
private import gui.layer_window;
private import gui.overview_window;

ProjectInfo projectInfo = null;

int main(string[] argv){
    Main.init(argv);
    projectInfo = new ProjectInfo();
    version(DRAW_SAMPLE){
        NormalLayerInfo layerInfo1 = new NormalLayerInfo("レイヤー1", true, "dat/sample/mapchip256_a.png");
        projectInfo.layerInfos ~= layerInfo1;
        for(int i = 0 ; i < projectInfo.mapSizeH * projectInfo.mapSizeV ; ++ i){
            layerInfo1.chipLayout ~= 0;
        }
        NormalLayerInfo layerInfo2 = new NormalLayerInfo("レイヤー2", true, "dat/sample/mapchip256_b.png");
        for(int i = 0 ; i < projectInfo.mapSizeH * projectInfo.mapSizeV ; ++ i){
            layerInfo2.chipLayout ~= 16 * 8 + 3;
        }
        projectInfo.layerInfos ~= layerInfo2;
        projectInfo.AddMapchipFile("dat/sample/mapchip256_a.png");
        projectInfo.AddMapchipFile("dat/sample/mapchip256_b.png");
    }
    EditWindow editWindow = new EditWindow();
    projectInfo.SetEditWindow(editWindow);
    editWindow.showAll();
    PartsWindow partsWindow = new PartsWindow();
    projectInfo.SetPartsWindow(partsWindow);
    partsWindow.showAll();
    LayerWindow layerWindow = new LayerWindow();
    projectInfo.SetLayerWindow(layerWindow);
    layerWindow.showAll();
    OverviewWindow overviewWindow = new OverviewWindow();
    projectInfo.SetOverviewWindow(overviewWindow);
    overviewWindow.showAll();
    Main.run();
    return 0;
}

/*
  GTKの参考ページ
  ■HBox,VBox
  http://www.kmc.gr.jp/~ranran/memo/gtk.1998-1.html
  
  ■SpinButton関連
  http://www.geocities.jp/tiplinux/gtk/gtk_spin_button.html
  http://book.geocities.jp/gtkmm_ja/docs/tutorial/html/sec-spinbutton.html
 */