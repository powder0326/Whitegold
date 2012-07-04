module dialog.new_project_dialog;
private import imports.all;

class NewProjectDialog : Dialog{
    this(){
        super();
        VBox mainBox = getContentArea();
        setTitle("新規マップの作成");
        // OK Cancelボタン
        HBox hbox3 = new HBox(false, 0);
        Button buttonOk = new Button("OK");
        hbox3.packStart(buttonOk, true, true, 1);
        Button buttonCancel = new Button("Cancel");
        hbox3.packStart(buttonCancel, true, true, 1);
        mainBox.packStart(hbox3, false, false, 0);
        showAll();
    }
}