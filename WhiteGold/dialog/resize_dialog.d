module dialog.resize_dialog;
private import imports.all;
private import project_info;
private import main;

class ResizeDialog : Window{
    void delegate(int,int,EAnchor) onMapSizeChangedFunction;
    Button anchorButtons[EAnchor.max + 1];
    Pixbuf anchorPixbuf = null;
    EAnchor currentAnchor = EAnchor.DIRECTION_7;
    this(){
        super("マップのリサイズ");
        anchorPixbuf = new Pixbuf("dat/icon/picture-sunset.png");
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

        Table table3 = new Table(0,0,true);
        foreach(ref anchorButton;anchorButtons){
            anchorButton = new Button();
            anchorButton.addOnClicked((Button button){
                    for(int i = 0 ; i <= EAnchor.max ; ++ i){
                        if(anchorButtons[i] is button){
                            anchorButtons[i].setImage(new Image(anchorPixbuf));
                            currentAnchor = cast(EAnchor)i;
                        }else{
                            anchorButtons[i].setImage(null);
                        }
                    }
                });
        }
        anchorButtons[currentAnchor].setImage(new Image(anchorPixbuf));
        table3.attach(anchorButtons[EAnchor.DIRECTION_7],0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_8],1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_9],2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_4],0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_5],1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_6],2,3,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_1],0,1,2,3,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_2],1,2,2,3,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table3.attach(anchorButtons[EAnchor.DIRECTION_3],2,3,2,3,AttachOptions.FILL,AttachOptions.FILL,4,4);
        Frame frame3 = new Frame(table3, "アンカー");
        leftBox.packStart(frame3, false, false, 0);
        mainBox.packStart(leftBox, false, false, 0);

        VBox rightBox = new VBox(false, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                if(onMapSizeChangedFunction !is null){
                    onMapSizeChangedFunction(
                        cast(int)spinMapH.getValue(),
                        cast(int)spinMapV.getValue(),
                        currentAnchor);
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
    ~this(){
        anchorPixbuf.unref;
        delete anchorPixbuf;
    }
}