module gui.edit_window;

import imports.all;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */
class EditWindow : MainWindow{
    this(){
        super("エディットウインドウ");
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new EditWindowMenubar(),false,false,0);
        add(mainBox);
    }
}

/**
   エディット用ウインドウ上部のメニュー

   ファイルの読み込みや保存等、メニューから行う処理を色々記述。
 */
class EditWindowMenubar : MenuBar{
    this(){
        super();
		Menu fileMenu = append("ファイル");
		fileMenu.append(new MenuItem(&onMenuActivate, "開く","file.open", true));
		fileMenu.append(new MenuItem(&onMenuActivate, "上書き保存","file.save", true));
		fileMenu.append(new MenuItem(&onMenuActivate, "名前を付けて保存","file.save_with_name", true));
    }
	void onMenuActivate(MenuItem menuItem)
	{
		string action = menuItem.getActionName();
		switch( action )
		{
// 			case "help.about":
// 				GtkDAbout dlg = new GtkDAbout();
// 				dlg.addOnResponse(&onDialogResponse);
// 				dlg.showAll();
// 				break;
// 			default:
// 				MessageDialog d = new MessageDialog(
// 					this,
// 					GtkDialogFlags.MODAL,
// 					MessageType.INFO,
// 					ButtonsType.OK,
// 					"You pressed menu item "~action);
// 				d.run();
// 				d.destroy();
// 			break;
		}
	}
}
