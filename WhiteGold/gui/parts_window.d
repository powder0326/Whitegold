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
    void delegate(string mapchipFilePath) onMapchipFileLoadedFunction;
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
            fileOpenButton.addOnClicked((Button button){
                    FileChooserDialog fs = new FileChooserDialog("マップチップファイル選択", this.outer, FileChooserAction.OPEN);
                    if( fs.run() == ResponseType.GTK_RESPONSE_OK )
                    {
                        if(this.outer.onMapchipFileLoadedFunction !is null){
                            this.outer.onMapchipFileLoadedFunction(fs.getFilename());
                        }
                    }
                    fs.hide();

                });
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
                addOnMotionNotify(&onMotionNotify);
                if(projectInfo.currentLayerInfo.type == ELayerType.NORMAL){
                    NormalLayerInfo layerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    if(layerInfo.mapchipFilePath !is null && layerInfo.mapchipFilePath in projectInfo.mapchipPixbufList){
                        mapchip =  projectInfo.mapchipPixbufList[layerInfo.mapchipFilePath];
                    }else{
                        mapchip =  null;
                    }
                    if(mapchip){
                        setSizeRequest(mapchip.getWidth(), mapchip.getHeight());
                    }
                }
            }
            bool exposeCallback(GdkEventExpose* event, Widget widget){
                Drawable dr = getWindow();
                if(mapchip !is null){
                    dr.drawPixbuf(mapchip, 0, 0);
                }
                // 選択領域描画
                NormalLayerInfo layerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                int x = layerInfo.gridSelection.startGridX * projectInfo.partsSizeH;
                int y = layerInfo.gridSelection.startGridY * projectInfo.partsSizeV;
                int width = projectInfo.partsSizeH * (layerInfo.gridSelection.endGridX - layerInfo.gridSelection.startGridX) - 1;
                int height = projectInfo.partsSizeV * (layerInfo.gridSelection.endGridY - layerInfo.gridSelection.startGridY) - 1;
                GC gc = new GC(dr);
                gc.setRgbFgColor(new Color(255,255,255));
                dr.drawRectangle(gc, false, x, y, width, height);
                return true;
            }
            bool onButtonPress(GdkEventButton* event, Widget widget)
            {
                printf("onButtonPress event.button = %d\n");
                if ( event.button == 1 ){
                }
                return false;
            }
            bool onButtonRelease(GdkEventButton* event, Widget widget)
            {
                printf("onButtonRelease event.button = %d\n");
                if ( event.button == 1 ){
                }
                return false;
            }
            bool onMotionNotify(GdkEventMotion* event, Widget widget){
                printf("onMotionNotify (%f,%f)\n",event.x,event.y);
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
                if(layerInfo.mapchipFilePath !is null && layerInfo.mapchipFilePath in projectInfo.mapchipPixbufList){
                    mapchip =  projectInfo.mapchipPixbufList[layerInfo.mapchipFilePath];
                }else{
                    mapchip =  null;
                }
                if(mapchip){
                    drawingArea.setSizeRequest(mapchip.getWidth(), mapchip.getHeight());
                }
                queueDraw();
            }
        }
    }
}
