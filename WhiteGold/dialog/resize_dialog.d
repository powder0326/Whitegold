module dialog.resize_dialog;
private import imports.all;
private import project_info;
private import main;

class ResizeDialog : Window{
    void delegate(int,int,int,int) onMapSizeAndPartsSizeChangedFunction;
    this(){
        super("マップのリサイズ");
        setBorderWidth(10);
        VBox mainBox = new VBox(false, 5);
        add(mainBox);
        Frame frame1 = new Frame("変更前");
        mainBox.packStart(frame1, false, false, 0);
        showAll();
    }
}