module dialog.export_setting_dialog;
private import imports.all;
private import project_info;
private import main;

class ExportSettingDialog : Window{
    void delegate(int,int,int,int) onExportSettingChangedFunction;
    this(){
        super("エクスポート設定");
        setBorderWidth(10);
        HBox mainBox = new HBox(false, 5);
        add(mainBox);

        VBox leftBox = new VBox(false, 5);
        Table table1 = new Table(4,2,false);
        table1.attach(new Label("左端X:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d",projectInfo.exportStartGridX)),1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label("右端X:"),2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d",projectInfo.exportEndGridX)),3,4,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);

        table1.attach(new Label("上端Y:"),0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d",projectInfo.exportStartGridY)),1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label("下端Y:"),2,3,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table1.attach(new Label(format("%d",projectInfo.exportEndGridY)),3,4,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);


        table1.setBorderWidth(10);
        Frame frame1 = new Frame(table1, "変更前エクスポート範囲");
        leftBox.packStart(frame1, false, false, 0);

        Table table2 = new Table(4,2,false);
        table2.attach(new Label("左端X:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinStartX = new SpinButton(new Adjustment(projectInfo.exportStartGridX, 0.0, projectInfo.mapSizeH - 1, 1.0, 10.0, 0),1,0);
        table2.attach(spinStartX,1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table2.attach(new Label("右端X:"),2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinEndX = new SpinButton(new Adjustment(projectInfo.exportEndGridX, 0.0, projectInfo.mapSizeH - 1, 1.0, 10.0, 0),1,0);
        table2.attach(spinEndX,3,4,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);

        table2.attach(new Label("上端X:"),0,1,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinStartY = new SpinButton(new Adjustment(projectInfo.exportStartGridY, 0.0, projectInfo.mapSizeV - 1, 1.0, 10.0, 0),1,0);
        table2.attach(spinStartY,1,2,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table2.attach(new Label("下端X:"),2,3,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);
        SpinButton spinEndY = new SpinButton(new Adjustment(projectInfo.exportEndGridY, 0.0, projectInfo.mapSizeV - 1, 1.0, 10.0, 0),1,0);
        table2.attach(spinEndY,3,4,1,2,AttachOptions.FILL,AttachOptions.FILL,4,4);


        Frame frame2 = new Frame(table2, "変更後エクスポート範囲");
        leftBox.packStart(frame2, false, false, 0);
        mainBox.packStart(leftBox, false, false, 0);


        VBox rightBox = new VBox(false, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                if(onExportSettingChangedFunction !is null){
                    onExportSettingChangedFunction(
                        cast(int)spinStartX.getValue(),
                        cast(int)spinEndX.getValue(),
                        cast(int)spinStartY.getValue(),
                        cast(int)spinEndY.getValue());
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