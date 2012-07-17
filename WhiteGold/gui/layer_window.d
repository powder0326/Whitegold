module gui.layer_window;

private import imports.all;
private import main;
private import project_info;

/**
   レイヤー用ウインドウ

   カレントレイヤーの選択やレイヤーの可視、非可視を切り替えるウインドウ。
 */
class LayerWindow : MainWindow{
    void delegate(int index) onSelectedLayerChangedFunction;
    void delegate(int index, bool visible) onLayerVisibilityChangedFunction;
    void delegate() onLayerAddedFunction;
    void delegate() onLayerDeletedFunction;
    void delegate(bool isUp) onLayerMovedFunction;
    VBox mainBox;
    LayerWindowListview layerWindowListview = null;
    this(){
        super("レイヤー");
//         setSizeRequest(320, 320);
        setDefaultSize(baseInfo.layerWindowInfo.width, baseInfo.layerWindowInfo.height);
        setIcon(new Pixbuf("dat/icon/layers.png"));
        mainBox = new VBox(false,0);
		mainBox.packStart(new LayerWindowMenubar(),false,false,0);
		mainBox.packStart(new LayerWindowToolArea(),false,false,0);
        layerWindowListview = new LayerWindowListview();
		mainBox.packStart(layerWindowListview,true,true,0);
        add(mainBox);
        setDeletable(false);
        addOnRealize((Widget widget){
                move(baseInfo.layerWindowInfo.x, baseInfo.layerWindowInfo.y);
            });
    }
    void Reload(){
//         layerWindowListview.Reload();
        layerWindowListview.destroy();
        layerWindowListview = new LayerWindowListview();
		mainBox.packStart(layerWindowListview,true,true,0);
        mainBox.showAll();
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
            Button addLayerButton = new Button();
            addLayerButton.setImage(new Image(new Pixbuf("dat/icon/layer--plus.png")));
            addLayerButton.addOnClicked((Button button){
                    if(this.outer.onLayerAddedFunction !is null){
                        this.outer.onLayerAddedFunction();
                    }
                });
            packStart(addLayerButton , false, false, 2 );
            Button deleteLayerButton = new Button();
            deleteLayerButton.setImage(new Image(new Pixbuf("dat/icon/cross-circle.png")));
            deleteLayerButton.addOnClicked((Button button){
                    if(this.outer.onLayerDeletedFunction !is null){
                        this.outer.onLayerDeletedFunction();
                    }
                });
            packStart(deleteLayerButton , false, false, 2 );
            Button moveUpLayerButton = new Button();
            moveUpLayerButton.setImage(new Image(new Pixbuf("dat/icon/arrow-090.png")));
            moveUpLayerButton.addOnClicked((Button button){
                    if(this.outer.onLayerMovedFunction !is null){
                        this.outer.onLayerMovedFunction(true);
                    }
                });
            packStart(moveUpLayerButton , false, false, 2 );
            Button moveDownButton = new Button();
            moveDownButton.setImage(new Image(new Pixbuf("dat/icon/arrow-270.png")));
            moveDownButton.addOnClicked((Button button){
                    if(this.outer.onLayerMovedFunction !is null){
                        this.outer.onLayerMovedFunction(false);
                    }
                });
            packStart(moveDownButton , false, false, 2 );
            Button editLayerButton = new Button();
            editLayerButton.setImage(new Image(new Pixbuf("dat/icon/wrench-screwdriver.png")));
            packStart(editLayerButton , false, false, 2 );
            ToggleButton showHideLayerButton = new ToggleButton();
            showHideLayerButton.setImage(new Image(new Pixbuf("dat/icon/eye.png")));
            packStart(showHideLayerButton , false, false, 2 );
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
        ListStore listStore = null;
        this(){
            super();
            // データ設定
            static GType [2] columns = [
                GType.INT,
                GType.STRING,
                ];
            listStore = new ListStore(columns);
            TreeIter it;
            TreePath firstPath = null;
            foreach(i,layerInfo ; projectInfo.layerInfos){
                it = listStore.createIter();
                listStore.setValue( it, EColumn.LAYER_VISIBLE, layerInfo.visible );
                listStore.setValue( it, EColumn.LAYER_NAME, layerInfo.name );
                if(i == 0){
                    firstPath = listStore.getPath(it);
                }
            }
            setModel(listStore);
            TreeSelection treeSelection = getSelection();
            treeSelection.setMode(SelectionMode.SINGLE);
            treeSelection.addOnChanged((TreeSelection ts){
                    TreeIter it = ts.getSelected();
                    if(it is null){
                        return;
                    }
                    string value = listStore.getValueString(it, EColumn.LAYER_NAME);
                    TreePath path = listStore.getPath(it);
                    int indices[] = path.getIndices;
                    if(this.outer.onSelectedLayerChangedFunction !is null){
                        this.outer.onSelectedLayerChangedFunction(indices[0]);
                    }
                });
            // 一番上を選択しておく
            if(firstPath !is null){
                treeSelection.selectPath(firstPath);
            }
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
                    int indices[] = path.getIndices;
                    listStore.setValue(it, EColumn.LAYER_VISIBLE, it.getValueInt( EColumn.LAYER_VISIBLE ) ? 0 : 1 );
                    if(this.outer.onLayerVisibilityChangedFunction !is null){
                        this.outer.onLayerVisibilityChangedFunction(indices[0], it.getValueInt( EColumn.LAYER_VISIBLE ) == 1);
                    }
                });
            // レイヤー名列
            TreeViewColumn columnLayerName = new TreeViewColumn();
            columnLayerName.packStart(cellRendererLayerName, 0 );
            columnLayerName.addAttribute(cellRendererLayerName, "text", EColumn.LAYER_NAME);
            columnLayerName.setTitle( "レイヤー名" );
            appendColumn(columnLayerName);
        }
        void Reload(){
            TreeSelection treeSelection = getSelection();
            treeSelection.unselectAll();
            listStore.clear;
            TreeIter it;
            TreePath selectPath = null;
            foreach(i,layerInfo ; projectInfo.layerInfos){
                it = listStore.createIter();
                listStore.setValue( it, LayerWindowListview.EColumn.LAYER_VISIBLE, layerInfo.visible );
                listStore.setValue( it, LayerWindowListview.EColumn.LAYER_NAME, layerInfo.name );
                if(i == projectInfo.currentLayerIndex){
                    selectPath = listStore.getPath(it);
                }
            }
            if(selectPath !is null){
                treeSelection.selectPath(selectPath);
            }
        }
    }
}