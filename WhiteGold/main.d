module main;

import imports.all;
import gui.edit_window;
import gui.parts_window;
import gui.layer_window;

int main(string[] argv)
{
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
