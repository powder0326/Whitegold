module dialog.resize_dialog;
private import imports.all;
private import project_info;
private import main;

class ResizeDialog : Window{
    void delegate(int,int) onMapSizeChangedFunction;
    this(){
        super("マップのリサイズ");
        setBorderWidth(10);
        HBox mainBox = new HBox(false, 5);
        add(mainBox);

        VBox leftBox = new VBox(false, 5);
        Table table1 = new Table(2,2,false);
        table1.attach(new Label("幅:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d パーツ",projectInfo.mapSizeH)),1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label("高さ:"),0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d パーツ",projectInfo.mapSizeV)),1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.setBorderWidth(10);
        Frame frame1 = new Frame(table1, "変更前");
        leftBox.packStart(frame1, false, false, 0);

        Table table2 = new Table(3,2,false);
        table2.attach(new Label("幅:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinMapH = new SpinButton(new Adjustment(projectInfo.mapSizeH, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table2.attach(spinMapH,1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table2.attach(new Label("パーツ"),2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table2.attach(new Label("高さ:"),0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinMapV = new SpinButton(new Adjustment(projectInfo.mapSizeV, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table2.attach(spinMapV,1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table2.attach(new Label("パーツ"),2,3,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        Frame frame2 = new Frame(table2, "変更後");
        leftBox.packStart(frame2, false, false, 0);
        mainBox.packStart(leftBox, false, false, 0);


        VBox rightBox = new VBox(false, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                if(onMapSizeChangedFunction !is null){
                    onMapSizeChangedFunction(
                        cast(int)spinMapH.getValue(),
                        cast(int)spinMapV.getValue());
                }
                destroy();
            });
        rightBox.packStart(buttonOk, false, false, 0);
        Button buttonCancel = new Button("Cancel");
        buttonCancel.addOnClicked((Button button){
                destroy();
            });
        rightBox.packStart(buttonCancel, false, false, 0);
        mainBox.packStart(rightBox, false, false, 0);
        
        showAll();
    }
}