module gui.edit_window;

import imports.all;
import main;
import project_info;
import dialog.new_project_dialog;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */

enum EDrawingType{
    PEN,
    TILING_PEN,
    FILL,
    SELECT,
}
class EditWindow : MainWindow{
    void delegate() onHideFunction;
    void delegate(EWindowType windowType, bool show) onWindowShowHideFunction;
    void delegate(int,int,int,int) onMapSizeAndPartsSizeChangedFunction;
    void delegate(CsvProjectInfo) onCsvLoadedFunction;
    void delegate(ChipReplaceInfo[]) onChipReplacedFunction;
    void delegate() onChipReplaceCompletedFunction;
    void delegate() onUndoFunction;
    void delegate() onRedoFunction;
    EditWindowEditArea editArea = null;
    EditWindowToolArea toolArea = null;
    bool showGrid = false;
    this(){
        super("エディットウインドウ");
//         setSizeRequest(320, 320);
        setDefaultSize(240, 240);
        setIcon(new Pixbuf("dat/icon/application--pencil.png"));
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new EditWindowMenubar(),false,false,0);
        toolArea = new EditWindowToolArea();
		mainBox.packStart(toolArea,false,false,0);
        editArea = new EditWindowEditArea();
		mainBox.packStart(editArea,true,true,0);
		mainBox.packStart(new EditWindowStatusbarArea(),false,false,0);
        toolArea.penButton.setActive(1);
        add(mainBox);
        addOnHide(&onHide);
    }
    void Reload(){
        editArea.Reload();
    }
    void onHide(Widget widget){
        printf("EditWindow.onHide\n");
        if(onHideFunction !is null){
            onHideFunction();
        }
    }
    void OpenNewProject(){
        NewProjectDialog dialog = new NewProjectDialog();
        dialog.setModal(true);
        dialog.showAll();
        if(onMapSizeAndPartsSizeChangedFunction !is null){
            dialog.onMapSizeAndPartsSizeChangedFunction = onMapSizeAndPartsSizeChangedFunction;
        }
    }
/**
   エディット用ウインドウ上部のメニュー

   ファイルの読み込みや保存等、メニューから行う処理を色々記述。
*/
    class EditWindowMenubar : MenuBar{
        class CustomCheckMenuItem : CheckMenuItem{
            EWindowType windowType;
            this(string label, bool active, EWindowType windowType){
                super(label, active);
                this.windowType = windowType;
            }
        }
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
            CustomCheckMenuItem checkMenuItemPartsWindow = new CustomCheckMenuItem("パーツウインドウ", true, EWindowType.PARTS);
            checkMenuItemPartsWindow.addOnToggled(&onWindowShowHide);
            checkMenuItemPartsWindow.setActive(true);
            windowMenu.append(checkMenuItemPartsWindow);
            CustomCheckMenuItem checkMenuItemLayerWindow = new CustomCheckMenuItem("レイヤーウインドウ", true, EWindowType.LAYER);
            checkMenuItemLayerWindow.addOnToggled(&onWindowShowHide);
            checkMenuItemLayerWindow.setActive(true);
            windowMenu.append(checkMenuItemLayerWindow);
            CustomCheckMenuItem checkMenuItemOverviewWindow = new CustomCheckMenuItem("オーバービューウインドウ", true, EWindowType.OVERVIEW);
            checkMenuItemOverviewWindow.addOnToggled(&onWindowShowHide);
            checkMenuItemOverviewWindow.setActive(true);
            windowMenu.append(checkMenuItemOverviewWindow);
        }
        void onMenuActivate(MenuItem menuItem)
        {
            string action = menuItem.getActionName();
            switch( action )
            {
            case "file.new":
                OpenNewProject();
                break;
            case "file.import_csv":
                FileChooserDialog fs = new FileChooserDialog("CSVファイル選択", this.outer, FileChooserAction.OPEN);
//                 fs.setCurrentFolderUri("file:///C:/Programing");
                if( fs.run() == ResponseType.GTK_RESPONSE_OK )
                {
                    CsvProjectInfo info = ParseCsv(fs.getFilename());
                    if(this.outer.onCsvLoadedFunction !is null){
                        this.outer.onCsvLoadedFunction(info);
                    }
                }
                fs.hide();
                break;
            default:
                break;
            }
        }
        void onWindowShowHide(CheckMenuItem checkMenuItem){
            CustomCheckMenuItem customCheckMenuItem = cast(CustomCheckMenuItem)checkMenuItem;
            if(this.outer.onWindowShowHideFunction !is null){
                this.outer.onWindowShowHideFunction(customCheckMenuItem.windowType, customCheckMenuItem.getActive() == 1);
            }
        }
    }
/**
   エディット用ウインドウ上部のツールボタン郡表示領域

   ここの領域のボタンを押すといろいろ処理する。メニューとかぶる項目がほとんど。
*/
    class EditWindowToolArea : HBox{
        ToggleButton penButton = null;
        bool penButtonUpByOther = false;
        bool penButtonDownBySelf = false;
        ToggleButton tilingPenButton = null;
        bool tilingPenButtonUpByOther = false;
        bool tilingPenButtonDownBySelf = false;
        ToggleButton fillButton = null;
        bool fillButtonUpByOther = false;
        bool fillButtonDownBySelf = false;
        ToggleButton selectButton = null;
        bool selectButtonUpByOther = false;
        bool selectButtonDownBySelf = false;
        Button editUndoButton = null;
        Button editRedoButton = null;
        this(){
            super(false,0);
            setBorderWidth(2);
            // ファイル関連
            Button fileNewButton = new Button();
            fileNewButton.setImage(new Image(new Pixbuf("dat/icon/blue-document.png")));
            fileNewButton.addOnClicked((Button button){OpenNewProject();});
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
            editUndoButton = new Button();
            editUndoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return-180-left.png")));
            editUndoButton.setSensitive(false);
            editUndoButton.addOnClicked((Button button){
                    if(this.outer.onUndoFunction !is null){
                        this.outer.onUndoFunction();
                    }
                });
            packStart(editUndoButton , false, false, 2 );
            editRedoButton = new Button();
            editRedoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return.png")));
            editRedoButton.setSensitive(false);
            editRedoButton.addOnClicked((Button button){
                    if(this.outer.onRedoFunction !is null){
                        this.outer.onRedoFunction();
                    }
                });
            packStart(editRedoButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // ペン関連
            penButton = new ToggleButton();
            penButton.setImage(new Image(new Pixbuf("dat/icon/pencil.png")));
            penButton.addOnToggled(&onDrawButtonToggled);
            packStart(penButton , false, false, 2 );
            tilingPenButton = new ToggleButton();
            tilingPenButton.setImage(new Image(new Pixbuf("dat/icon/pencil--plus.png")));
            tilingPenButton.addOnToggled(&onDrawButtonToggled);
            packStart(tilingPenButton , false, false, 2 );
            fillButton = new ToggleButton();
            fillButton.setImage(new Image(new Pixbuf("dat/icon/paint-can.png")));
            fillButton.addOnToggled(&onDrawButtonToggled);
            packStart(fillButton , false, false, 2 );
            selectButton = new ToggleButton();
            selectButton.setImage(new Image(new Pixbuf("dat/icon/selection.png")));
            selectButton.addOnToggled(&onDrawButtonToggled);
            packStart(selectButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // グリッド関連
            ToggleButton gridButton = new ToggleButton();
            gridButton.setImage(new Image(new Pixbuf("dat/icon/grid.png")));
            gridButton.addOnToggled((ToggleButton toggleButton){
                    showGrid = toggleButton.getActive() == 1;
                    this.outer.editArea.queueDraw();
                });
            packStart(gridButton , false, false, 2 );
        }
        void onDrawButtonToggled(ToggleButton toggleButton){
            if(toggleButton is penButton){
                if(penButton.getActive()){
                    if(!penButtonDownBySelf){
                        this.outer.editArea.drawingArea.ChangeDrawingType(EDrawingType.PEN);
                        if(tilingPenButton.getActive()){
                            tilingPenButtonUpByOther = true;
                            tilingPenButton.setActive(0);
                        }
                        if(fillButton.getActive()){
                            fillButtonUpByOther = true;
                            fillButton.setActive(0);
                        }
                        if(selectButton.getActive()){
                            selectButtonUpByOther = true;
                            selectButton.setActive(0);
                        }
                    }else{
                        penButtonDownBySelf = false;
                    }
                }else{
                    if(!penButtonUpByOther){
                        penButtonDownBySelf = true;
                        penButton.setActive(1);
                    }else{
                        penButtonUpByOther = false;
                    }
                }
            }
            if(toggleButton is tilingPenButton){
                if(tilingPenButton.getActive()){
                    if(!penButtonDownBySelf){
                        this.outer.editArea.drawingArea.ChangeDrawingType(EDrawingType.TILING_PEN);
                        if(penButton.getActive()){
                            penButtonUpByOther = true;
                            penButton.setActive(0);
                        }
                        if(fillButton.getActive()){
                            fillButtonUpByOther = true;
                            fillButton.setActive(0);
                        }
                        if(selectButton.getActive()){
                            selectButtonUpByOther = true;
                            selectButton.setActive(0);
                        }
                    }else{

                        tilingPenButtonDownBySelf = false;
                    }
                }else{
                    if(!tilingPenButtonUpByOther){
                        tilingPenButton.setActive(1);
                    }else{
                        tilingPenButtonUpByOther = false;
                    }
                }
            }
            if(toggleButton is fillButton){
                if(fillButton.getActive()){
                    if(!penButtonDownBySelf){
                        this.outer.editArea.drawingArea.ChangeDrawingType(EDrawingType.FILL);
                        if(penButton.getActive()){
                            penButtonUpByOther = true;
                            penButton.setActive(0);
                        }
                        if(tilingPenButton.getActive()){
                            tilingPenButtonUpByOther = true;
                            tilingPenButton.setActive(0);
                        }
                        if(selectButton.getActive()){
                            selectButtonUpByOther = true;
                            selectButton.setActive(0);
                        }
                    }else{
                        fillButtonDownBySelf = false;
                    }
                }else{
                    if(!fillButtonUpByOther){
                        fillButton.setActive(1);
                    }else{
                        fillButtonUpByOther = false;
                    }
                }
            }
            if(toggleButton is selectButton){
                if(selectButton.getActive()){
                    if(!penButtonDownBySelf){
                        this.outer.editArea.drawingArea.ChangeDrawingType(EDrawingType.SELECT);
                        if(penButton.getActive()){
                            penButtonUpByOther = true;
                            penButton.setActive(0);
                        }
                        if(tilingPenButton.getActive()){
                            tilingPenButtonUpByOther = true;
                            tilingPenButton.setActive(0);
                        }
                        if(fillButton.getActive()){
                            fillButtonUpByOther = true;
                            fillButton.setActive(0);
                        }
                    }else{
                        selectButtonDownBySelf = false;
                    }
                }else{
                    if(!selectButtonUpByOther){
                        selectButton.setActive(1);
                    }else{
                        selectButtonUpByOther = false;
                    }
                }
            }
        }
    }
/**
   エディット用ウインドウメインの編集領域

   ここにマップチップを配置していく。
*/
    class EditWindowEditArea : ScrolledWindow{
        class EditDrawingArea : DrawingArea{
            abstract class ChipDrawStrategyBase{
                abstract bool onButtonPress(GdkEventButton* event, Widget widget);
                abstract bool onButtonRelease(GdkEventButton* event, Widget widget);
                abstract bool onMotionNotify(GdkEventMotion* event, Widget widget);
            }
            class ChipDrawStrategyPen : ChipDrawStrategyBase{
                int lastGridX,lastGridY;
                bool pressed = false;
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    pressed = true;
                    // チップ配置
                    int gridX = lastGridX = cast(int)(event.x / projectInfo.partsSizeH);
                    int gridY = lastGridY = cast(int)(event.y / projectInfo.partsSizeV);
                    drawChip(gridX, gridY);
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    pressed = false;
                    if(this.outer.outer.outer.onChipReplaceCompletedFunction !is null){
                        this.outer.outer.outer.onChipReplaceCompletedFunction();
                    }
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
                    if(pressed){
                        // グリッドが変わったら描画
                        int gridX = cast(int)(event.x / projectInfo.partsSizeH);
                        int gridY = cast(int)(event.y / projectInfo.partsSizeV);
                        if(gridX != lastGridX || gridY != lastGridY){
                            lastGridX = gridX;
                            lastGridY = gridY;
                            drawChip(gridX, gridY);
                        }
                    }
                    return true;
                }
                void drawChip(int gridX, int gridY){
                    ChipReplaceInfo[] chipReplaceInfos;
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    with(normalLayerInfo.gridSelection){
                        for(int yi = 0, y = startGridY ; y <= endGridY ; ++ yi, ++ y){
                            for(int xi = 0, x = startGridX ; x <= endGridX ; ++ xi, ++ x){
                                chipReplaceInfos ~= ChipReplaceInfo(gridX + xi, gridY + yi, x, y);
                            }
                        }
                    }
                    if(this.outer.outer.outer.onChipReplacedFunction !is null){
                        this.outer.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                    }
                }
            }
            class ChipDrawStrategyTilingPen : ChipDrawStrategyBase{
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonPress\n");
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonRelease\n");
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onMotionNotify\n");
                    return true;
                }
            }
            class ChipDrawStrategySelect : ChipDrawStrategyBase{
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategySelect.onButtonPress\n");
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategySelect.onButtonRelease\n");
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
                    printf("ChipDrawStrategySelect.onMotionNotify\n");
                    return true;
                }
            }
            class ChipDrawStrategyFill : ChipDrawStrategyBase{
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    int cursorGridX = cast(int)(event.x / projectInfo.partsSizeH);
                    int cursorGridY = cast(int)(event.y / projectInfo.partsSizeV);
                    NormalLayerInfo layerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    int layoutIndex = cursorGridY * projectInfo.mapSizeH + cursorGridX;
                    int startChipId = layerInfo.chipLayout[layoutIndex];
                    int newChipId = -1;
                    if(layerInfo.gridSelection !is null){
                        newChipId = layerInfo.GetChipIdInMapchip(layerInfo.gridSelection.startGridX, layerInfo.gridSelection.startGridY);
                    }
                    if(startChipId == newChipId){
                        // 同じチップIDなら塗りつぶす意味が無い。
                        return true;
                    }
                    struct Info{
                        this(int gridX, int gridY){
                            this.gridX = gridX;
                            this.gridY = gridY;
                        }
                        int gridX = 0;
                        int gridY = 0;
                    }
                    EditInfo editInfos[];
                    Info infos[];
                    infos ~= Info(cursorGridX, cursorGridY); 
                    int i = 0;
                    ChipReplaceInfo[] chipReplaceInfos;
                    int[] tmpChipLayout = layerInfo.chipLayout.dup;
                    while(infos.length>= 1){
                        Info info = infos[$-1];
                        infos = infos[0..$-1]; // あってる？
                        int tmpLayoutIndex = info.gridY * projectInfo.mapSizeH + info.gridX;
                        int currentChipId = tmpChipLayout[tmpLayoutIndex];
                        if(currentChipId == startChipId){
                            editInfos ~= EditInfo(projectInfo.currentLayerIndex, tmpLayoutIndex, currentChipId, newChipId);
                            tmpChipLayout[tmpLayoutIndex] = newChipId;
                            chipReplaceInfos ~= ChipReplaceInfo(info.gridX, info.gridY, layerInfo.gridSelection.startGridX, layerInfo.gridSelection.startGridY);
                            // 領域を超えない範囲で周り4方向のキュー追加
                            int leftGridX = info.gridX - 1;
                            int leftGridY = info.gridY;
                            if(leftGridX >= 0){
                                infos ~= Info(leftGridX, leftGridY);
                            }
                            int rightGridX = info.gridX + 1;
                            int rightGridY = info.gridY;
                            if(rightGridX < projectInfo.mapSizeH){
                                infos ~= Info(rightGridX, rightGridY);
                            }
                            int upGridX = info.gridX;
                            int upGridY = info.gridY - 1;
                            if(upGridY >= 0){
                                infos ~= Info(upGridX, upGridY);
                            }
                            int downGridX = info.gridX;
                            int downGridY = info.gridY + 1;
                            if(downGridY < projectInfo.mapSizeV){
                                infos ~= Info(downGridX, downGridY);
                            }
                        }
                        ++ i;
                    }
                    if(this.outer.outer.outer.onChipReplacedFunction){
                        this.outer.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                    }
                    if(this.outer.outer.outer.onChipReplaceCompletedFunction){
                        this.outer.outer.outer.onChipReplaceCompletedFunction();
                    }
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
                    return true;
                }
            }
            ChipDrawStrategyBase chipDrawStrategy = null;
            void ChangeDrawingType(EDrawingType type){
                final switch(type){
                case EDrawingType.PEN:
                    chipDrawStrategy = new ChipDrawStrategyPen();
                    break;
                case EDrawingType.TILING_PEN:
                    chipDrawStrategy = new ChipDrawStrategyTilingPen();
                    break;
                case EDrawingType.FILL:
                    chipDrawStrategy = new ChipDrawStrategyFill();
                    break;
                case EDrawingType.SELECT:
                    chipDrawStrategy = new ChipDrawStrategySelect();
                    break;
                }
            }
            this(){
                super();
                setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
                addOnButtonPress(&onButtonPress);
                addOnButtonRelease(&onButtonRelease);
                addOnMotionNotify(&onMotionNotify);
                addOnExpose(&exposeCallback);
                setSizeRequest(projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
                chipDrawStrategy = new ChipDrawStrategyPen();
                addOnRealize((Widget widget){
                        Pixmap bgPixmap = new Pixmap(widget.getWindow(), 4 * 2, 4 * 2, -1);
                        GC gc = new GC(widget.getWindow());
                        Color color1 = new Color(200,200,200);
                        Color color2 = new Color(255,255,255);
                        for(int y = 0 ; y < 4 * 2 ; ++ y){
                            for(int x = 0 ; x < 4 * 2 ; ++ x){
                                if(y % 2 == 0){
                                    if(x % 2 == 0){
                                        gc.setRgbFgColor(color1);
                                    }else{
                                        gc.setRgbFgColor(color2);
                                    }
                                }else{
                                    if(x % 2 == 0){
                                        gc.setRgbFgColor(color2);
                                    }else{
                                        gc.setRgbFgColor(color1);
                                    }
                                }
                                bgPixmap.drawRectangle(gc, true, x * 4, y * 4, 4, 4);
                            }
                        }
                        widget.getWindow().setBackPixmap(bgPixmap,0);
                    });
            }
            bool exposeCallback(GdkEventExpose* event, Widget widget){
                Drawable dr = getWindow();
                GC gc = new GC(dr);
                // 全てのレイヤーに対して
                foreach(layerInfo;projectInfo.layerInfos){
                    if(layerInfo.type != ELayerType.NORMAL || !layerInfo.visible){
                        continue;
                    }
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)layerInfo;
                    dr.drawPixbuf(normalLayerInfo.layoutPixbuf, 0, 0);
                }
                // グリッド描画
                if(showGrid){
//                     GdkPoint points[];
                    gc.setLineAttributes (1, GdkLineStyle.ON_OFF_DASH, GdkCapStyle.NOT_LAST, GdkJoinStyle.MITER);
                    gc.setRgbFgColor(new Color(80,80,80));
                    int width = projectInfo.partsSizeH * projectInfo.mapSizeH;
                    int height = projectInfo.partsSizeV * projectInfo.mapSizeV;
                    for(int y = 0 ; y < height ; y += projectInfo.partsSizeV){
                        for(int x = 0 ; x < width ; x += projectInfo.partsSizeH){
//                             points ~= GdkPoint(x, y);
                            dr.drawLine(gc, -4, y, width, y);
                            dr.drawLine(gc, x, -4, x, height);
                        }
                    }
//                     dr.drawLines(gc, points);
                }
                return true;
            }
            bool onButtonPress(GdkEventButton* event, Widget widget)
            {
                return chipDrawStrategy.onButtonPress(event, widget);
            }
            bool onButtonRelease(GdkEventButton* event, Widget widget)
            {
                return chipDrawStrategy.onButtonRelease(event, widget);
            }
            bool onMotionNotify(GdkEventMotion* event, Widget widget){
                return chipDrawStrategy.onMotionNotify(event, widget);
            }
        }
        EditDrawingArea drawingArea = null;
        this(){
            super();
            drawingArea = new EditDrawingArea();
            addWithViewport(drawingArea);
        }
        void Reload(){
            drawingArea.setSizeRequest(projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
            queueDraw();
        }
    }
/**
   エディット用ステータスバー領域。

   現在のグリッド座標とかを表示。
*/
    class EditWindowStatusbarArea : HBox{
        this(){
            super(true,0);
            Statusbar statusbar1 = new Statusbar();
            statusbar1.setHasResizeGrip(0);
            packStart(statusbar1, true, true, 1);
            Statusbar statusbar2 = new Statusbar();
            statusbar2.setHasResizeGrip(0);
            packStart(statusbar2, true, true, 1);
            Statusbar statusbar3 = new Statusbar();
            packStart(statusbar3, true, true, 1);
        }
    }
}

