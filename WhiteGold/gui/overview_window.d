module gui.overview_window;
import imports.all;
import main;
import project_info;

/**
   オーバービューウインドウ

   マップ全体の縮小表示。
 */
class OverviewWindow : MainWindow{
    double zoomRate = 0.5;
    this(){
        super("オーバービュー");
//         setSizeRequest(320, 320);
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new OverviewWindowToolArea(),false,false,0);
		mainBox.packStart(new OverviewWindowViewArea(),true,true,0);
        add(mainBox);
        setDeletable(false);
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
            packStart(zoomPlusButton , false, false, 2 );
            Button zoomMinusButton = new Button();
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
                double width = cast(double)projectInfo.partsSizeH * cast(double)projectInfo.mapSizeH * zoomRate; 
                double height = cast(double)projectInfo.partsSizeV * cast(double)projectInfo.mapSizeV * zoomRate; 
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
                    Pixbuf scaledPixbuf = normalLayerInfo.layoutPixbuf.scaleSimple(cast(int)getWidth(), cast(int)getHeight(), GdkInterpType.NEAREST/*,TILES,BILINEAR,HYPER*/);
                    dr.drawPixbuf(scaledPixbuf, 0, 0);
                }
                return true;
            }
        }
        EditDrawingArea drawingArea = null;
        this(){
            super();
            drawingArea = new EditDrawingArea();
            addWithViewport(drawingArea);
        }
        void Reload(){
            double width = cast(double)projectInfo.partsSizeH * cast(double)projectInfo.mapSizeH * zoomRate; 
            double height = cast(double)projectInfo.partsSizeV * cast(double)projectInfo.mapSizeV * zoomRate; 
            setSizeRequest(cast(int)width, cast(int)height);
            queueDraw();
        }
    }
}
