module dialog.new_project_dialog;
private import imports.all;
private import project_info;
private import main;

class NewProjectDialog : Dialog{
    this(){
        super();
        VBox mainBox = getContentArea();
        setTitle("新規マップの作成");
        // マップの幅高さ
        HBox hbox1 = new HBox(true, 0);
        Label labelMapH = new Label("マップの横幅");
        hbox1.packStart(labelMapH, true, true, 1);
        TextView textViewMapH = new TextView();
        textViewMapH.getBuffer().setText(std.conv.to!(string)(projectInfo.horizontalNum));
        hbox1.packStart(textViewMapH, true, true, 1);
        Label labelMapV = new Label("マップの高さ");
        hbox1.packStart(labelMapV, true, true, 1);
        TextView textViewMapV = new TextView();
        textViewMapV.getBuffer().setText(std.conv.to!(string)(projectInfo.verticalNum));
        hbox1.packStart(textViewMapV, true, true, 1);
        mainBox.packStart(hbox1, false, false, 0);
        // チップ幅高さ
        HBox hbox2 = new HBox(true, 0);
        Label labelPartsH = new Label("パーツの横幅");
        hbox2.packStart(labelPartsH, true, true, 1);
        TextView textViewPartsH = new TextView();
        textViewPartsH.getBuffer().setText(std.conv.to!(string)(projectInfo.partsSizeH));
        hbox2.packStart(textViewPartsH, true, true, 1);
        Label labelPartsV = new Label("パーツの高さ");
        hbox2.packStart(labelPartsV, true, true, 1);
        TextView textViewPartsV = new TextView();
        textViewPartsV.getBuffer().setText(std.conv.to!(string)(projectInfo.partsSizeV));
        hbox2.packStart(textViewPartsV, true, true, 1);
        mainBox.packStart(hbox2, false, false, 0);
        // OK Cancelボタン
        HBox hbox3 = new HBox(true, 0);
        Button buttonOk = new Button("OK");
        hbox3.packStart(buttonOk, true, true, 1);
        Button buttonCancel = new Button("Cancel");
        hbox3.packStart(buttonCancel, true, true, 1);
        mainBox.packStart(hbox3, false, false, 0);
        showAll();
    }
}