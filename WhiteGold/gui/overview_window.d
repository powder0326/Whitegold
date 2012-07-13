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
    void delegate(double centerX, double cneterY) onScrollCenterChangedFunction;
    Cursor cursorNormal = null;
    Cursor cursorDragging = null;
    this(){
        super("オーバービュー");
//         setSizeRequest(320, 320);
        setDefaultSize(240, 240);
        move(0, 240);
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
        addOnRealize((Widget widget){
                cursorNormal = new Cursor(widget.getDisplay() , new Pixbuf("dat/cursor/hand.png"), 0, 0);
                //cursorNormal = new Cursor(widget.getDisplay(), GdkCursorType.HAND2);
                cursorDragging = new Cursor(widget.getDisplay() , new Pixbuf("dat/cursor/hand2.png"), 0, 0);
                setCursor(cursorNormal);
            });
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
            enum EMode{
                NORMAL,
                DRAGGING,
            }
            EMode mode = EMode.NORMAL;
            this(){
                super();
                addOnButtonPress(&onButtonPress);
                addOnButtonRelease(&onButtonRelease);
                addOnMotionNotify(&onMotionNotify);
                addOnExpose(&exposeCallback);
                double width = cast(double)projectInfo.partsSizeH * cast(double)projectInfo.mapSizeH * (cast(double)zoomRate / 100.0); 
                double height = cast(double)projectInfo.partsSizeV * cast(double)projectInfo.mapSizeV * (cast(double)zoomRate / 100.0); 
                setSizeRequest(cast(int)width, cast(int)height);
            }
            bool exposeCallback(GdkEventExpose* event, Widget widget){
                printf("OverviewWindow.exposeCallback 1\n");
                Drawable dr = getWindow();
                // 全てのレイヤーに対して
                foreach(layerInfo;projectInfo.layerInfos){
                    if(!layerInfo.visible){
                        continue;
                    }
                    if(layerInfo.layoutPixbuf !is null){
                        Pixbuf scaledPixbuf = layerInfo.layoutPixbuf.scaleSimple(cast(int)getWidth(), cast(int)getHeight(), GdkInterpType.NEAREST/*,TILES,BILINEAR,HYPER*/);
                        dr.drawPixbuf(scaledPixbuf, 0, 0);
                        scaledPixbuf.unref();
                        delete scaledPixbuf;
                    }
                }
                // 視界表示
                double x1,y1,x2,y2;
                projectInfo.editWindow.GetViewPortInfo(x1,y1,x2,y2);
                GC gc = new GC(dr);
                gdk.RGB.RGB.rgbGcSetForeground(gc, 0xFF0000);
//                 gc.setForeground(new Color(255,0,0));
                dr.drawRectangle(gc, false,
                                 cast(int)(x1 * getWidth()),
                                 cast(int)(y1 * getHeight()),
                                 cast(int)(x2 * getWidth() - x1 * getWidth()) ,
                                 cast(int)(y2 * getHeight() - y1 * getHeight()));
                printf("OverviewWindow.exposeCallback 2\n");
                return true;
            }
            bool onButtonPress(GdkEventButton* event, Widget widget){
                getWindow().setCursor(cursorDragging);
                mode = EMode.DRAGGING;
                if(this.outer.outer.onScrollCenterChangedFunction !is null){
                    this.outer.outer.onScrollCenterChangedFunction(event.x / getWidth(), event.y / getHeight());
                }
                return true;
            }
            bool onButtonRelease(GdkEventButton* event, Widget widget){
                getWindow().setCursor(cursorNormal);
                mode = EMode.NORMAL;
                return true;
            }
            bool onMotionNotify(GdkEventMotion* event, Widget widget){
                if(mode == EMode.DRAGGING){
                    if(this.outer.outer.onScrollCenterChangedFunction !is null){
                        this.outer.outer.onScrollCenterChangedFunction(event.x / getWidth(), event.y / getHeight());
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
