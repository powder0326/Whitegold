module gui.parts_window;

private import imports.all;
private import main;
private import project_info;

/**
   パーツ用ウインドウ

   レイヤー毎にマップチップ用のパーツを読み込んで表示する。ここから選択したパーツをエディット用ウインドウに配置する。
 */
class PartsWindow : MainWindow{
    PartsWindowMapchipArea mapchipArea;
    this(){
        super("パーツ");
//         setSizeRequest(320, 320);
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new PartsWindowToolArea(),false,false,0);
        mapchipArea = new PartsWindowMapchipArea();
		mainBox.packStart(mapchipArea,true,true,0);
        add(mainBox);
        setDeletable(false);
    }
    void Reload(){
        mapchipArea.Reload();
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
        class MapchipDrawingArea : DrawingArea{
            this(){
                super();
                addOnExpose(&exposeCallback);
                if(projectInfo.currentLayerInfo.type == ELayerType.NORMAL){
                    NormalLayerInfo layerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    mapchip = projectInfo.mapchipPixbufList[layerInfo.mapchipFilePath];
                    setSizeRequest(mapchip.getWidth(), mapchip.getHeight());
                }
            }
            bool exposeCallback(GdkEventExpose* event, Widget widget){
                Drawable dr = getWindow();
                version(DRAW_SAMPLE){
                    dr.drawPixbuf(mapchip, 0, 0);
                }
                return true;
            }
        }
        MapchipDrawingArea drawingArea = null;
        Pixbuf mapchip;
        this(){
            super();
            drawingArea = new MapchipDrawingArea();
            addWithViewport(drawingArea);
        }
        /**
           再読み込み

           選択レイヤが変更された時等に呼ばれる。mapchip画像を再設定して再描画を行う。
        */
        void Reload(){
            if(projectInfo.currentLayerInfo.type == ELayerType.NORMAL){
                NormalLayerInfo layerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                mapchip = projectInfo.mapchipPixbufList[layerInfo.mapchipFilePath];
                drawingArea.setSizeRequest(mapchip.getWidth(), mapchip.getHeight());
                queueDraw();
            }
        }
    }
}
