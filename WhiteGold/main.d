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
        projectInfo.layerInfos ~= new NormalLayerInfo("レイヤー1", true, "dat/sample/mapchip256_a.png");
        projectInfo.AddMapchipFile("dat/sample/mapchip256_a.png");
        projectInfo.layerInfos ~= new NormalLayerInfo("レイヤー2", true, "dat/sample/mapchip256_b.png");
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
