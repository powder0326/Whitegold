module gui.layer_window;

import imports.all;
private import main;
private import project_info;

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
    class LayerWindowListview : TreeView{
        enum EColumn{
            LAYER_VISIBLE,
            LAYER_NAME,
        }
        this(){
            super();
            // データ設定
            static GType [2] columns = [
                GType.INT,
                GType.STRING,
                ];
            ListStore listStore = new ListStore(columns);
            TreeIter it;
            foreach(layerInfo ; projectInfo.layerInfos){
                it = listStore.createIter();
                listStore.setValue( it, EColumn.LAYER_VISIBLE, layerInfo.visible );
                listStore.setValue( it, EColumn.LAYER_NAME, layerInfo.name );
            }
            setModel(listStore);
            // 可視/非可視切り替え列
            CellRendererToggle cellRendererToggle = new CellRendererToggle();
            cellRendererToggle.setProperty( "active", 1 );
            cellRendererToggle.setProperty( "activatable", 1 );
            TreeViewColumn columnToggle = new TreeViewColumn();
            columnToggle.packStart(cellRendererToggle, 0 );
            columnToggle.addAttribute(cellRendererToggle, "active", EColumn.LAYER_VISIBLE);
            columnToggle.setTitle( "表示" );
            appendColumn(columnToggle);
            CellRendererText cellRendererLayerName = new CellRendererText();
            // change value in store on toggle event
            cellRendererToggle.addOnToggled( delegate void(string p, CellRendererToggle){
                    auto path = new TreePath( p );
                    auto it = new TreeIter( listStore, path );
                    listStore.setValue(it, EColumn.LAYER_VISIBLE, it.getValueInt( EColumn.LAYER_VISIBLE ) ? 0 : 1 );
                });
            // レイヤー名列
            TreeViewColumn columnLayerName = new TreeViewColumn();
            columnLayerName.packStart(cellRendererLayerName, 0 );
            columnLayerName.addAttribute(cellRendererLayerName, "text", EColumn.LAYER_NAME);
            columnLayerName.setTitle( "レイヤー名" );
            appendColumn(columnLayerName);
        }
    }
}