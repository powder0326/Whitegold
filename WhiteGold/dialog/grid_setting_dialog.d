module dialog.grid_setting_dialog;
private import imports.all;
private import project_info;
private import main;

class GridSettingDialog : Window{
    void delegate(bool,int,EGridType,int) onGridSettingChangedFunction;
    this(){
        super("グリッド設定");
        setBorderWidth(10);
        HBox mainBox = new HBox(false, 5);
        add(mainBox);

        VBox leftBox = new VBox(false, 5);
        Table table1 = new Table(2,2,false);
        table1.attach(new Label("表示"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        CheckButton checkButton1 = new CheckButton();
        checkButton1.setActive(projectInfo.grid1Visible);
        table1.attach(checkButton1,1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        table1.attach(new Label("グリッド間隔"),2,3,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        SpinButton spinButton1 = new SpinButton(new Adjustment(projectInfo.grid1Interval, 1.0, 16.0, 1.0, 10.0, 0),1,0);
        table1.attach(spinButton1,3,4,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        table1.attach(new Label("種類"),4,5,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        ComboBox comboBox = new ComboBox(true);
        comboBox.appendText("実線");
		comboBox.appendText("破線");
        if(projectInfo.grid1Type == EGridType.NORMAL){
            comboBox.setActive(0);
        }else{
            comboBox.setActive(1);
        }
        table1.attach(comboBox,5,6,0,1,AttachOptions.FILL,AttachOptions.EXPAND,1,1);
        table1.attach(new Label("色"),6,7,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        DrawingArea da = new DrawingArea();
        da.setSizeRequest(24,24);
        da.modifyBg(GtkStateType.NORMAL, new Color(cast(char)(projectInfo.grid1Color >> 16), cast(char)(projectInfo.grid1Color >> 8), cast(char)(projectInfo.grid1Color >> 0)));
        int gridColor1 = projectInfo.grid1Color;
        da.addOnButtonPress((GdkEventButton* event, Widget widget){
                ColorSelectionDialog dialog = new ColorSelectionDialog("色選択");
                ColorSelection colorSelection = dialog.getColorSelection();
                colorSelection.setCurrentColor(new Color(cast(char)(gridColor1 >> 16), cast(char)(gridColor1 >> 8), cast(char)(gridColor1 >> 0)));
                dialog.run();
                dialog.destroy();
                Color color = new Color(255,255,255);
                colorSelection.getCurrentColor(color);
                gridColor1 = color.getValue24();
                printf("color = %x\n",color.getValue24());
                da.modifyBg(GtkStateType.NORMAL, color);
				return true;
            });
        table1.attach(da,7,8,0,1,AttachOptions.FILL,AttachOptions.FILL,1,1);
        table1.setBorderWidth(10);
        Frame frame1 = new Frame(table1, "グリッド１");
        leftBox.packStart(frame1, false, false, 0);

        mainBox.packStart(leftBox, false, false, 0);

        VBox rightBox = new VBox(false, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                if(onGridSettingChangedFunction !is null){
                    EGridType gridType = cast(EGridType)comboBox.getActive();
                    onGridSettingChangedFunction(checkButton1.getActive() == 1, cast(int)spinButton1.getValue(), gridType, gridColor1);
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