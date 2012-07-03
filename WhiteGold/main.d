module main;

import imports.all;
import gui.edit_window;

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
    Main.run();
    return 0;
}
