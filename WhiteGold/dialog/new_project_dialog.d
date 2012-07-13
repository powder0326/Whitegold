module dialog.new_project_dialog;
private import imports.all;
private import project_info;
private import main;

class NewProjectDialog : Window{
    void delegate(int,int,int,int) onMapSizeAndPartsSizeChangedFunction;
    this(){
        super("新規マップの作成");
        setBorderWidth(10);
        VBox mainBox = new VBox(false, 5);
        add(mainBox);
        Table table = new Table(4,2,false);
        SpinButton spinMapH = new SpinButton(new Adjustment(projectInfo.mapSizeH, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table.attach(new Label("マップの横幅:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table.attach(spinMapH,1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinMapV = new SpinButton(new Adjustment(projectInfo.mapSizeV, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table.attach(new Label("マップの高さ:"),2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table.attach(spinMapV,3,4,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinPartsH = new SpinButton(new Adjustment(projectInfo.partsSizeH, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table.attach(new Label("パーツの横幅:"),0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table.attach(spinPartsH,1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinPartsV = new SpinButton(new Adjustment(projectInfo.partsSizeV, 1.0, 256.0, 1.0, 10.0, 0),1,0);
        table.attach(new Label("パーツの高さ:"),2,3,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table.attach(spinPartsV,3,4,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        mainBox.packStart(table, true, true, 1);
        // OK Cancelボタン
        HBox hbox3 = new HBox(true, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                if(onMapSizeAndPartsSizeChangedFunction !is null){
                    onMapSizeAndPartsSizeChangedFunction(
                        cast(int)spinMapH.getValue(),
                        cast(int)spinMapV.getValue(),
                        cast(int)spinPartsH.getValue(),
                        cast(int)spinPartsV.getValue());
                }
                destroy();
            });
        hbox3.packStart(buttonOk, true, true, 1);
        Button buttonCancel = new Button("Cancel");
        buttonCancel.addOnClicked((Button button){destroy();});
        hbox3.packStart(buttonCancel, true, true, 1);
        mainBox.packStart(hbox3, false, false, 0);
        showAll();
    }
}