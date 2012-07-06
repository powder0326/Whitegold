module gui.overview_window;
import imports.all;
import main;
import project_info;

/**
   オーバービューウインドウ

   マップ全体の縮小表示。
 */
class OverviewWindow : MainWindow{
    static const int ZOOM_MIN = 10;
    static const int ZOOM_MAX = 100;
    int zoomRate = 50;
    OverviewWindowViewArea viewArea = null;
    Statusbar statusbar = null;
    this(){
        super("オーバービュー");
//         setSizeRequest(320, 320);
        setDefaultSize(240, 240);
        setIcon(new Pixbuf("dat/icon/picture-sunset.png"));
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new OverviewWindowToolArea(),false,false,0);
        viewArea = new OverviewWindowViewArea();
		mainBox.packStart(viewArea,true,true,0);
        add(mainBox);
        statusbar = new Statusbar();
        statusbar.push(1, format("表示倍率:%d%%",zoomRate));
		mainBox.packStart(statusbar,false,false,0);
        setDeletable(false);
    }
    void Reload(){
        viewArea.Reload();
    }
/**
   オーバービュー用ウインドウ上部のツールボタン郡表示領域

   ここの領域のボタンを押すといろいろ処理する。
*/
    class OverviewWindowToolArea : HBox{
        this(){
            super(false,0);
            setBorderWidth(2);
            // 拡大縮小
            Button zoomPlusButton = new Button();
            zoomPlusButton.setImage(new Image(new Pixbuf("dat/icon/magnifier-zoom-in.png")));
            zoomPlusButton.addOnClicked((Button button){
                    zoomRate = min(zoomRate + 10, ZOOM_MAX);
                    statusbar.pop(1);
                    statusbar.push(1, format("表示倍率:%d%%",zoomRate));
                    viewArea.Reload();
                });
            packStart(zoomPlusButton , false, false, 2 );
            Button zoomMinusButton = new Button();
            zoomMinusButton.addOnClicked((Button button){
                    zoomRate = max(zoomRate - 10, ZOOM_MIN);
                    statusbar.pop(1);
                    statusbar.push(1, format("表示倍率:%d%%",zoomRate));
                    viewArea.Reload();
                });
            zoomMinusButton.setImage(new Image(new Pixbuf("dat/icon/magnifier-zoom-out.png")));
            packStart(zoomMinusButton , false, false, 2 );
        }
    }
/**
   オーバービュー用ウインドウメインの表示領域

   エディットウインドウの表示領域と同じ内容を表示。拡大縮小ができるのと、ここで視界の矩形を移動するとエディットウインドウのスクロールも移動するように。
*/
    class OverviewWindowViewArea : ScrolledWindow{
        class EditDrawingArea : DrawingArea{
            this(){
                super();
                addOnExpose(&exposeCallback);
                double width = cast(double)projectInfo.partsSizeH * cast(double)projectInfo.mapSizeH * (cast(double)zoomRate / 100.0); 
                double height = cast(double)projectInfo.partsSizeV * cast(double)projectInfo.mapSizeV * (cast(double)zoomRate / 100.0); 
                setSizeRequest(cast(int)width, cast(int)height);
            }
            bool exposeCallback(GdkEventExpose* event, Widget widget){
                Drawable dr = getWindow();
                // 全てのレイヤーに対して
                foreach(layerInfo;projectInfo.layerInfos){
                    if(layerInfo.type != ELayerType.NORMAL || !layerInfo.visible){
                        continue;
                    }
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)layerInfo;
                    if(normalLayerInfo.layoutPixbuf !is null){
                        Pixbuf scaledPixbuf = normalLayerInfo.layoutPixbuf.scaleSimple(cast(int)getWidth(), cast(int)getHeight(), GdkInterpType.NEAREST/*,TILES,BILINEAR,HYPER*/);
                        dr.drawPixbuf(scaledPixbuf, 0, 0);
                    }
                }
                return true;
            }
        }
        EditDrawingArea drawingArea = null;
        this(){
            super();
            setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
            drawingArea = new EditDrawingArea();
            addWithViewport(drawingArea);
        }
        void Reload(){
            double width = cast(double)projectInfo.partsSizeH * cast(double)projectInfo.mapSizeH * (cast(double)zoomRate / 100.0); 
            double height = cast(double)projectInfo.partsSizeV * cast(double)projectInfo.mapSizeV * (cast(double)zoomRate / 100.0); 
            drawingArea.setSizeRequest(cast(int)width, cast(int)height);
            queueDraw();
        }
    }
}
