module dialog.new_project_dialog;
private import imports.all;
private import project_info;
private import main;

class NewProjectDialog : Window{
    this(){
        super("新規マップの作成");
        setBorderWidth(10);
        VBox mainBox = new VBox(false, 5);
        add(mainBox);
        // テスト
        Table table = new Table(2,1,false);
        SpinButton spin = new SpinButton(new Adjustment(1.0, 0.0, 100.0, 1.0, 10.0, 0),1,0);
        table.attach(new Label("Spin this:"),0,1,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        table.attach(spin,1,2,0,1,AttachOptions.FILL,AttachOptions.FILL,4,4);
        mainBox.packStart(table, true, true, 1);
        // マップの幅高さ
        HBox hbox1 = new HBox(true, 5);
        Label labelMapH = new Label("マップの横幅");
        hbox1.packStart(labelMapH, true, true, 1);
        Entry textViewMapH = new Entry();
        textViewMapH.setText(std.conv.to!(string)(projectInfo.horizontalNum));
        textViewMapH.setSizeRequest(40, 20);
        textViewMapH.setMaxLength(3);
        hbox1.packStart(textViewMapH, true, true, 1);
        Label labelMapV = new Label("マップの高さ");
        hbox1.packStart(labelMapV, true, true, 1);
        Entry textViewMapV = new Entry();
        textViewMapV.setText(std.conv.to!(string)(projectInfo.verticalNum));
        textViewMapV.setMaxLength(3);
        hbox1.packStart(textViewMapV, true, true, 1);
        mainBox.packStart(hbox1, false, false, 0);
        // チップ幅高さ
        HBox hbox2 = new HBox(true, 5);
        Label labelPartsH = new Label("パーツの横幅");
        hbox2.packStart(labelPartsH, true, true, 1);
        Entry textViewPartsH = new Entry();
        textViewPartsH.setText(std.conv.to!(string)(projectInfo.partsSizeH));
        textViewPartsH.setMaxLength(3);
        hbox2.packStart(textViewPartsH, true, true, 1);
        Label labelPartsV = new Label("パーツの高さ");
        hbox2.packStart(labelPartsV, true, true, 1);
        Entry textViewPartsV = new Entry();
        textViewPartsV.setText(std.conv.to!(string)(projectInfo.partsSizeV));
        textViewPartsV.setMaxLength(3);
        hbox2.packStart(textViewPartsV, true, true, 1);
        mainBox.packStart(hbox2, false, false, 0);
        // OK Cancelボタン
        HBox hbox3 = new HBox(true, 5);
        Button buttonOk = new Button("OK");
        buttonOk.addOnClicked((Button button){
                // Todo! 設定値の反映処理
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