module main;

private import imports.all;
private import project_info;
private import gui.edit_window;
private import gui.parts_window;
private import gui.layer_window;

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
    editWindow.showAll();
    PartsWindow partsWindow = new PartsWindow();
    partsWindow.showAll();
    LayerWindow layerWindow = new LayerWindow();
    layerWindow.showAll();
    Main.run();
    return 0;
}
