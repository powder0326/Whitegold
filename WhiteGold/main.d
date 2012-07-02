module main;

import imports.all;
import gui.edit_window;

int main(string[] argv)
{
    Main.init(argv);
    EditWindow editWindow = new EditWindow();
    editWindow.showAll();
    Main.run();
    return 0;
}
