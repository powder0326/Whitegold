module gui.edit_window;

import imports.all;
version = DRAW_SAMPLE;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */
class EditWindow : MainWindow{
    this(){
        super("エディットウインドウ");
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new EditWindowMenubar(),false,false,0);
		mainBox.packStart(new EditWindowToolArea(),false,false,0);
		mainBox.packStart(new EditWindowEditArea(),true,true,0);
        add(mainBox);
    }
/**
   エディット用ウインドウ上部のメニュー

   ファイルの読み込みや保存等、メニューから行う処理を色々記述。
*/
    class EditWindowMenubar : MenuBar{
        CheckMenuItem checkMenuItemPartsWindow = null;
        CheckMenuItem checkMenuItemLayerWindow = null;
        CheckMenuItem checkMenuItemOverviewWindow = null;
        this(){
            super();
            AccelGroup accelGroup = new AccelGroup();
            this.outer.addAccelGroup(accelGroup);
            Menu fileMenu = append("ファイル");
            fileMenu.append(new MenuItem(&onMenuActivate, "新規作成","file.new", true, accelGroup, 'n'));
            fileMenu.append(new MenuItem(&onMenuActivate, "開く","file.open", true, accelGroup, 'o'));
            fileMenu.append(new MenuItem(&onMenuActivate, "名前を付けて保存","file.save_with_name", true, accelGroup, 's'));
            fileMenu.append(new MenuItem(&onMenuActivate, "上書き保存","file.save", true, accelGroup, 's',GdkModifierType.CONTROL_MASK|GdkModifierType.SHIFT_MASK));
            fileMenu.append(new SeparatorMenuItem());
            fileMenu.append(new MenuItem(&onMenuActivate, "CSV読み込み","file.import_csv", true));
            fileMenu.append(new MenuItem(&onMenuActivate, "CSV書き出し","file.export_csv", true));
            fileMenu.append(new MenuItem(&onMenuActivate, "png書き出し","file.export_png", true, accelGroup, 'q'));
            fileMenu.append(new SeparatorMenuItem());
            fileMenu.append(new MenuItem(&onMenuActivate, "終了","file.quit", true));
            Menu editMenu = append("編集");
            editMenu.append(new MenuItem(&onMenuActivate, "取り消し","edit.undo", true, accelGroup, 'z'));
            editMenu.append(new MenuItem(&onMenuActivate, "やり直し","edit.redo", true, accelGroup, 'y'));
            editMenu.append(new SeparatorMenuItem());
            editMenu.append(new MenuItem(&onMenuActivate, "プロジェクト設定","edit.setting", true));
            Menu windowMenu = append("ウインドウ");
            checkMenuItemPartsWindow = new CheckMenuItem("パーツウインドウ", true);
            checkMenuItemPartsWindow.addOnToggled(&onToggleWindowShow);
            checkMenuItemPartsWindow.setActive(true);
            windowMenu.append(checkMenuItemPartsWindow);
            checkMenuItemLayerWindow = new CheckMenuItem("レイヤーウインドウ", true);
            checkMenuItemLayerWindow.addOnToggled(&onToggleWindowShow);
            checkMenuItemLayerWindow.setActive(true);
            windowMenu.append(checkMenuItemLayerWindow);
            checkMenuItemOverviewWindow = new CheckMenuItem("オーバービューウインドウ", true);
            checkMenuItemOverviewWindow.addOnToggled(&onToggleWindowShow);
            checkMenuItemOverviewWindow.setActive(true);
            windowMenu.append(checkMenuItemOverviewWindow);
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
            default:
                break;
            }
        }
        void onToggleWindowShow(CheckMenuItem checkMenuItem){
        }
    }
/**
   エディット用ウインドウ上部のツールボタン郡表示領域

   ここの領域のボタンを押すといろいろ処理する。メニューとかぶる項目がほとんど。
*/
    class EditWindowToolArea : HBox{
        this(){
            super(false,0);
            setBorderWidth(2);
            // ファイル関連
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
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // Undo Redo
            Button editUndoButton = new Button();
            editUndoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return-180-left.png")));
            packStart(editUndoButton , false, false, 2 );
            Button editRedoButton = new Button();
            editRedoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return.png")));
            packStart(editRedoButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // ペン関連
            ToggleButton penButton = new ToggleButton();
            penButton.setImage(new Image(new Pixbuf("dat/icon/pencil.png")));
            packStart(penButton , false, false, 2 );
            ToggleButton tilingPenButton = new ToggleButton();
            tilingPenButton.setImage(new Image(new Pixbuf("dat/icon/pencil--plus.png")));
            packStart(tilingPenButton , false, false, 2 );
            ToggleButton fillButton = new ToggleButton();
            fillButton.setImage(new Image(new Pixbuf("dat/icon/paint-can.png")));
            packStart(fillButton , false, false, 2 );
            ToggleButton selectButton = new ToggleButton();
            selectButton.setImage(new Image(new Pixbuf("dat/icon/selection.png")));
            packStart(selectButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // グリッド関連
            ToggleButton gridButton = new ToggleButton();
            gridButton.setImage(new Image(new Pixbuf("dat/icon/grid.png")));
            packStart(gridButton , false, false, 2 );
        }
    }
/**
   エディット用ウインドウメインの編集領域

   ここにマップチップを配置していく。
*/
    class EditWindowEditArea : ScrolledWindow{
        Pixbuf sampleMapchipA;
        Pixbuf sampleMapchipB;
        this(){
            super();
            class EditDrawingArea : DrawingArea{
                this(){
                    super();
                    addOnExpose(&exposeCallback);
                    setSizeRequest(16 * 24, 16 * 24);
                    sampleMapchipA = new Pixbuf("dat/sample/mapchip256_a.png"); 
                    sampleMapchipB = new Pixbuf("dat/sample/mapchip256_b.png"); 
                }
                bool exposeCallback(GdkEventExpose* event, Widget widget){
                    version(DRAW_SAMPLE){
                        Drawable dr = getWindow();
                        for(int y = 0 ; y < 24 ; ++ y){
                            for(int x = 0 ; x < 24 ; ++ x){
                                dr.drawPixbuf(null, sampleMapchipA, 16 * 7, 16 * 0, x * 16, y * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                            }
                        }
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 10, 16 * 7, 8 * 16, 8 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 11, 16 * 7, 9 * 16, 8 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 12, 16 * 7, 10 * 16, 8 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 13, 16 * 7, 11 * 16, 8 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);

                        dr.drawPixbuf(null, sampleMapchipB, 16 * 10, 16 * 8, 8 * 16, 9 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 11, 16 * 8, 9 * 16, 9 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 12, 16 * 8, 10 * 16, 9 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 13, 16 * 8, 11 * 16, 9 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);

                        dr.drawPixbuf(null, sampleMapchipB, 16 * 10, 16 * 9, 8 * 16, 10 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 11, 16 * 9, 9 * 16, 10 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 12, 16 * 9, 10 * 16, 10 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 13, 16 * 9, 11 * 16, 10 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);

                        dr.drawPixbuf(null, sampleMapchipB, 16 * 10, 16 * 10, 8 * 16, 11 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 11, 16 * 10, 9 * 16, 11 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 12, 16 * 10, 10 * 16, 11 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 13, 16 * 10, 11 * 16, 11 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);

                        dr.drawPixbuf(null, sampleMapchipB, 16 * 10, 16 * 11, 8 * 16, 12 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 11, 16 * 11, 9 * 16, 12 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 12, 16 * 11, 10 * 16, 12 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);
                        dr.drawPixbuf(null, sampleMapchipB, 16 * 13, 16 * 11, 11 * 16, 12 * 16, 16, 16, GdkRgbDither.NORMAL, 0, 0);

                    }
                    return true;
                }
            }
            addWithViewport(new EditDrawingArea());
        }
    }
}

