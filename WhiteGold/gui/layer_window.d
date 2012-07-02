module gui.layer_window;

import imports.all;

/**
   レイヤー用ウインドウ

   カレントレイヤーの選択やレイヤーの可視、非可視を切り替えるウインドウ。
 */
class LayerWindow : MainWindow{
    this(){
        super("レイヤー");
//         setSizeRequest(320, 320);
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new LayerWindowMenubar(),false,false,0);
		mainBox.packStart(new LayerWindowToolArea(),false,false,0);
		mainBox.packStart(new LayerWindowListview(),true,true,0);
        add(mainBox);
    }
/**
   レイヤー用ウインドウ上部のメニュー

   レイヤーの作成や移動を行う。
*/
    class LayerWindowMenubar : MenuBar{
        this(){
            super();
            AccelGroup accelGroup = new AccelGroup();
            this.outer.addAccelGroup(accelGroup);
            Menu editMenu = append("編集");
            editMenu.append(new MenuItem(&onMenuActivate, "新規レイヤー作成","edit.add_layer", true));
            editMenu.append(new MenuItem(&onMenuActivate, "選択レイヤーを削除","edit.delete_layer", true));
            editMenu.append(new MenuItem(&onMenuActivate, "選択レイヤーを隠す","edit.hide_layer", true));
            editMenu.append(new MenuItem(&onMenuActivate, "選択レイヤーを上に移動","edit.moveup_layer", true));
            editMenu.append(new MenuItem(&onMenuActivate, "選択レイヤーを下に移動","edit.movedown_layer", true));
            editMenu.append(new MenuItem(&onMenuActivate, "選択レイヤーの設定","edit.edit_layer", true));
        }
        void onMenuActivate(MenuItem menuItem)
        {
            string action = menuItem.getActionName();
            switch( action )
            {
            default:
                break;
            }
        }
    }
/**
   レイヤー用ウインドウ上部のツールボタン郡表示領域

   ここの領域のボタンを押すといろいろ処理する。メニューとかぶる項目がほとんど。
*/
    class LayerWindowToolArea : HBox{
        this(){
            super(false,0);
            setBorderWidth(2);
            Button fileNewButton = new Button();
            fileNewButton.setImage(new Image(new Pixbuf("dat/icon/blue-document.png")));
            packStart(fileNewButton , false, false, 2 );
            Button fileOpenButton = new Button();
            fileOpenButton.setImage(new Image(new Pixbuf("dat/icon/folder-horizontal-open.png")));
            packStart(fileOpenButton , false, false, 2 );
            Button fileSaveButton = new Button();
            fileSaveButton.setImage(new Image(new Pixbuf("dat/icon/disk.png")));
            packStart(fileSaveButton , false, false, 2 );
            Button fileSaveWithNameButton = new Button();
            fileSaveWithNameButton.setImage(new Image(new Pixbuf("dat/icon/disk--pencil.png")));
            packStart(fileSaveWithNameButton , false, false, 2 );
        }
    }
/**
   レイヤー用ウインドウのレイヤー一覧表示領域

   レイヤー毎にレイヤー名を表示。左のチェックボックスクリックで可視、非可視の切り替え可能。
   https://live.gnome.org/Vala/GTKSample ここにチェックボックス付きリストビューのサンプルコードあり。
*/
    class LayerWindowToolArea : HBox{
        this(){
            super(false,0);
            setBorderWidth(2);
    }
}