module gui.parts_window;

import imports.all;

/**
   パーツ用ウインドウ

   レイヤー毎にマップチップ用のパーツを読み込んで表示する。ここから選択したパーツをエディット用ウインドウに配置する。
 */
class PartsWindow : MainWindow{
    this(){
        super("パーツウインドウ");
//         setSizeRequest(320, 320);
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new PartsWindowToolArea(),false,false,0);
		mainBox.packStart(new PartsWindowMapchipArea(),true,true,0);
        add(mainBox);
    }
/**
   パーツ用ウインドウ上部のツールボタン郡表示領域

   ここの領域のボタンを押すといろいろ処理する。
*/
    class PartsWindowToolArea : HBox{
        this(){
            super(false,0);
            setBorderWidth(2);
            // ファイル関連
            Button fileOpenButton = new Button();
            fileOpenButton.setImage(new Image(new Pixbuf("dat/icon/folder-horizontal-open.png")));
            packStart(fileOpenButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // AutoTile
            Button toggleAutoTileButton = new Button();
            toggleAutoTileButton.setImage(new Image(new Pixbuf("dat/icon/wall-break.png")));
            packStart(toggleAutoTileButton , false, false, 2 );
        }
    }
/**
   パーツ用ウインドウメインの表示領域

   ここに読み込んだマップチップを表示する。クリックで選択。
*/
    class PartsWindowMapchipArea : ScrolledWindow{
        Pixbuf mapchip;
        this(){
            super();
            class MapchipDrawingArea : DrawingArea{
                this(){
                    super();
                    addOnExpose(&exposeCallback);
                    mapchip = new Pixbuf("dat/sample/mapchip256_a.png");
                    setSizeRequest(mapchip.getWidth(), mapchip.getHeight());
                }
                bool exposeCallback(GdkEventExpose* event, Widget widget){
                    Drawable dr = getWindow();
                    version(DRAW_SAMPLE){
                        dr.drawPixbuf(mapchip, 0, 0);
                    }
                    return true;
                }
            }
            addWithViewport(new MapchipDrawingArea());
        }
    }
}
