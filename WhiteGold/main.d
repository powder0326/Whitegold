module main;

import imports.all;
import gui.edit_window;
import gui.parts_window;
import gui.layer_window;

class GlobalData{
    int horizontalNum = 20;
    int verticalNum = 20;
    int cellSize = 16;
}
GlobalData globalData = null;

int main(string[] argv)
{
    globalData = new GlobalData();
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
