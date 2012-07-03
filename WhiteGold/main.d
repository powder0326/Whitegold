module main;

import imports.all;
private import project_info;
private import gui.edit_window;
private import gui.parts_window;
private import gui.layer_window;

ProjectInfo projectInfo = null;

int main(string[] argv){
    projectInfo = new ProjectInfo();
    version(DRAW_SAMPLE){
        projectInfo.layerInfos ~= new NormalLayerInfo("レイヤー1", true, "");
        projectInfo.layerInfos ~= new NormalLayerInfo("レイヤー2", true, "");
        projectInfo.layerInfos ~= new NormalLayerInfo("レイヤー3", false, "");
    }
    Main.init(argv);
    EditWindow editWindow = new EditWindow();
    editWindow.showAll();
    PartsWindow partsWindow = new PartsWindow();
    partsWindow.showAll();
    LayerWindow layerWindow = new LayerWindow();
    layerWindow.showAll();
    Main.run();
    return 0;
}
