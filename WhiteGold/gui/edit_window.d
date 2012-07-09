module gui.edit_window;

import imports.all;
import main;
import project_info;
import dialog.new_project_dialog;
import dialog.resize_dialog;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */
version = USE_SCANLINE;

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
    void delegate() onScrollChangedFunction;
    EditWindowEditArea editArea = null;
    EditWindowToolArea toolArea = null;
    bool showGrid = false;
    this(){
        super("エディットウインドウ");
//         setSizeRequest(320, 320);
        setDefaultSize(240, 240);
        move(10, 10);
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
    void UpdateGuide(){
        version(DRAW_GUIDE_DIRECT){
            editArea.drawingArea.queueDraw();
        }else{
            printf("UpdateGuide 1\n");
            NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
            int width = normalLayerInfo.gridSelection.endGridX - normalLayerInfo.gridSelection.startGridX + 1;
            int height = normalLayerInfo.gridSelection.endGridY - normalLayerInfo.gridSelection.startGridY + 1;
            UpdateGuidePixbuf(editArea.drawingArea.guidePixbuf, projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV, editArea.mouseGridX, editArea.mouseGridY, width, height, false);
            printf("UpdateGuide 2\n");
        }
    }
    /**
       視界情報取得

       x1:視界左端がViewPortの横幅を1.0とした場合にどの位置にあるか
       y1:視界上端がViewPortの縦幅を1.0とした場合にどの位置にあるか
       x2:視界右端がViewPortの横幅を1.0とした場合にどの位置にあるか
       y2:視界下端がViewPortの縦幅を1.0とした場合にどの位置にあるか
     */
    void GetViewPortInfo(ref double x1, ref double y1, ref double x2, ref double y2){
        printf("GetViewPortInfo 1\n");
        Adjustment adjustmentH = editArea.getHadjustment();
        x1 = adjustmentH.getValue() / (adjustmentH.getUpper() - adjustmentH.getLower());
        x2 = (adjustmentH.getValue() + adjustmentH.getPageSize()) / (adjustmentH.getUpper() - adjustmentH.getLower());
        Adjustment adjustmentV = editArea.getVadjustment();
        y1 = adjustmentV.getValue() / (adjustmentV.getUpper() - adjustmentV.getLower());
        y2 = (adjustmentV.getValue() + adjustmentV.getPageSize()) / (adjustmentV.getUpper() - adjustmentV.getLower());
        printf("GetViewPortInfo 2\n");
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
            editMenu.append(new MenuItem(&onMenuActivate, "リサイズ","edit.resize", true));
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
            case "edit.resize":
                ResizeDialog dialog = new ResizeDialog();
                dialog.setModal(true);
                dialog.showAll();
//                     if(onMapSizeAndPartsSizeChangedFunction !is null){
//                         dialog.onMapSizeAndPartsSizeChangedFunction = onMapSizeAndPartsSizeChangedFunction;
//                     }
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
        int mouseGridX = 0;
        int mouseGridY = 0;
        class EditDrawingArea : DrawingArea{
            abstract class ChipDrawStrategyBase{
                abstract bool onButtonPress(GdkEventButton* event, Widget widget);
                abstract bool onButtonRelease(GdkEventButton* event, Widget widget);
                abstract bool onMotionNotify(GdkEventMotion* event, Widget widget);
            }
            void drawChip(int gridX, int gridY){
                printf("drawChip 1\n");
                ChipReplaceInfo[] chipReplaceInfos;
                NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                with(normalLayerInfo.gridSelection){
                    for(int yi = 0, y = startGridY ; y <= endGridY ; ++ yi, ++ y){
                        for(int xi = 0, x = startGridX ; x <= endGridX ; ++ xi, ++ x){
                            if(gridX + xi >= projectInfo.mapSizeH || gridY + yi >= projectInfo.mapSizeV || gridX + xi < 0 || gridY + yi < 0){
                                continue;
                            }
                            chipReplaceInfos ~= ChipReplaceInfo(gridX + xi, gridY + yi, x, y);
                        }
                    }
                }
                if(this.outer.outer.onChipReplacedFunction !is null){
                    this.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                }
                printf("drawChip 2\n");
            }
            /**
               タイリングしてチップを配置

               startGridX:左上グリッドX座標
               startGridY:左上グリッドY座標
               endGridX:右下グリッド座標
               endGridY:右下グリッド座標
            */
            void tilingChip(int gridX1, int gridY1, int gridX2, int gridY2){
                    printf("tilingChip 1\n");
                    ChipReplaceInfo[] chipReplaceInfos;
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    with(normalLayerInfo.gridSelection){
                        int width = endGridX - startGridX + 1;
                        int height = endGridY - startGridY + 1;
                        for(int gridY = gridY1 ; gridY <= gridY2 ; ++ gridY){
                            for(int gridX = gridX1 ; gridX <= gridX2 ; ++ gridX){
                                int x = startGridX + (gridX - gridX1) % width;
                                int y = startGridY + (gridY - gridY1) % height;
                                chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, x, y);
                            }
                        }
                    }
                    if(this.outer.outer.onChipReplacedFunction !is null){
                        this.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                    }
                    printf("tilingChip 2\n");
            }
            class ChipDrawStrategyPen : ChipDrawStrategyBase{
                int lastGridX,lastGridY;
                bool pressed = false;
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    pressed = true;
                    // チップ配置
                    drawChip(mouseGridX, mouseGridY);
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
                        if(mouseGridX != lastGridX || mouseGridY != lastGridY){
                            lastGridX = mouseGridX;
                            lastGridY = mouseGridY;
                            drawChip(mouseGridX, mouseGridY);
                        }
                    }
                    return true;
                }
            }
            class ChipDrawStrategyTilingPen : ChipDrawStrategyBase{
                enum EMode{
                    NORMAL,
                    DRAGGING,
                }
                EMode mode = EMode.NORMAL;
                int startGridX = 0;
                int startGridY = 0;
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonPress\n");
                    mode = EMode.DRAGGING;
                    startGridX = mouseGridX;
                    startGridY = mouseGridY;
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonRelease\n");
                    mode = EMode.NORMAL;
                    tilingChip(startGridX, startGridY, mouseGridX, mouseGridY);
                    if(this.outer.outer.outer.onChipReplaceCompletedFunction !is null){
                        this.outer.outer.outer.onChipReplaceCompletedFunction();
                    }
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
                    long time = std.datetime.Clock.currStdTime();
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
                    version(USE_SCANLINE){
                        while(infos.length>= 1){
                            Info info = infos[$-1];
                            infos = infos[0..$-1];
                            // 指定座標から左右を検索
                            int leftGridX = 0;
						    int rightGridX =  projectInfo.mapSizeH - 1;
                            // 右方向
                            int gridY = info.gridY;
                            for(int gridX = info.gridX ; gridX < projectInfo.mapSizeH ; ++ gridX){
                                int tmpLayoutIndex = gridY * projectInfo.mapSizeH + gridX;
                                int currentChipId = tmpChipLayout[tmpLayoutIndex];
                                if(currentChipId == startChipId){
                                    editInfos ~= EditInfo(projectInfo.currentLayerIndex, tmpLayoutIndex, currentChipId, newChipId);
                                    tmpChipLayout[tmpLayoutIndex] = newChipId;
                                    chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, layerInfo.gridSelection.startGridX, layerInfo.gridSelection.startGridY);
                                }else{
                                    rightGridX = gridX;
                                    break;
                                }
                            }
                            // 左方向
                            for(int gridX = info.gridX - 1; gridX >= 0 ; -- gridX){
                                int tmpLayoutIndex = gridY * projectInfo.mapSizeH + gridX;
                                int currentChipId = tmpChipLayout[tmpLayoutIndex];
                                if(currentChipId == startChipId){
                                    editInfos ~= EditInfo(projectInfo.currentLayerIndex, tmpLayoutIndex, currentChipId, newChipId);
                                    tmpChipLayout[tmpLayoutIndex] = newChipId;
                                    chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, layerInfo.gridSelection.startGridX, layerInfo.gridSelection.startGridY);
                                }else{
                                    leftGridX = gridX;
                                    break;
                                }
                            }
                            // 上下のラインでキュー追加
                            // 上
                            if(gridY - 1 >= 0){
                                bool lastGridOk = false;
                                for(int gridX = leftGridX ; gridX <= rightGridX ; ++ gridX){
                                    int tmpLayoutIndex = (gridY - 1) * projectInfo.mapSizeH + gridX;
                                    int currentChipId = tmpChipLayout[tmpLayoutIndex];
                                    if(currentChipId == startChipId){
                                        lastGridOk = true;
                                        if(gridX == rightGridX){
                                            infos ~= Info(gridX, gridY - 1);
                                        }
                                    }else{
                                        if(lastGridOk){
                                            infos ~= Info(gridX - 1, gridY - 1);
                                        }
                                        lastGridOk = false;
                                    }
                                }
                            }
                            // 下
                            if(gridY + 1 < projectInfo.mapSizeV){
                                bool lastGridOk = false;
                                for(int gridX = leftGridX ; gridX <= rightGridX ; ++ gridX){
                                    int tmpLayoutIndex = (gridY + 1) * projectInfo.mapSizeH + gridX;
                                    int currentChipId = tmpChipLayout[tmpLayoutIndex];
                                    if(currentChipId == startChipId){
                                        lastGridOk = true;
                                        if(gridX == rightGridX){
                                            infos ~= Info(gridX, gridY + 1);
                                        }
                                    }else{
                                        if(lastGridOk){
                                            infos ~= Info(gridX - 1, gridY + 1);
                                        }
                                        lastGridOk = false;
                                    }
                                }
                            }
                        }
                    }else{
                        while(infos.length>= 1){
                            Info info = infos[$-1];
                            infos = infos[0..$-1];
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
                    }
                    printf("Fill %ld ms\n",(std.datetime.Clock.currStdTime() - time) / 10000);
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
            Pixbuf gridPixbuf = null;
            version(DRAW_GUIDE_DIRECT){}else{
                Pixbuf guidePixbuf = null;
            }
            this(){
                super();
                setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
                addOnButtonPress(&onButtonPress);
                addOnButtonRelease(&onButtonRelease);
                addOnMotionNotify(&onMotionNotify);
                addOnExpose(&exposeCallback);
                setSizeRequest(projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
                gridPixbuf = CreateGridPixbuf(projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV);
                version(DRAW_GUIDE_DIRECT){}else{
                    guidePixbuf = CreateGuidePixbuf(projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV);
                    UpdateGuidePixbuf(guidePixbuf, projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV, mouseGridX, mouseGridY, 1, 1, false);
                }
                chipDrawStrategy = new ChipDrawStrategyPen();
                addOnRealize((Widget widget){
                        // 透過色パターン
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
                printf("EditWindow.exposeCallback 1\n");
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
                    dr.drawPixbuf(gridPixbuf, 0, 0);
                }
                // カーソル位置の四角描画
                version(DRAW_GUIDE_DIRECT){
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.currentLayerInfo;
                    dr.drawPixbuf(normalLayerInfo.layoutPixbuf, 0, 0);
                    int selectWidth = normalLayerInfo.gridSelection.endGridX - normalLayerInfo.gridSelection.startGridX + 1;
                    int selectHeight = normalLayerInfo.gridSelection.endGridY - normalLayerInfo.gridSelection.startGridY + 1;
                    int leftPixelX = mouseGridX * projectInfo.partsSizeH + 1;
                    int rightPixelX = mouseGridX * projectInfo.partsSizeH + projectInfo.partsSizeH * selectWidth - 1 - 1;
                    int topPixelY = mouseGridY * projectInfo.partsSizeV + 1;
                    int bottomPixelY = mouseGridY * projectInfo.partsSizeV + projectInfo.partsSizeV * selectHeight - 1 - 1;
                    gdk.RGB.RGB.rgbGcSetForeground(gc, 0xFF0000);
                    dr.drawRectangle(gc, false, leftPixelX, topPixelY, rightPixelX - leftPixelX ,bottomPixelY - topPixelY);
                }else{
                    dr.drawPixbuf(guidePixbuf, 0, 0);
                }
                printf("EditWindow.exposeCallback 2\n");
                return true;
            }
            bool onButtonPress(GdkEventButton* event, Widget widget){
                int lastMouseGridX = mouseGridX;
                int lastMouseGridY = mouseGridY;
                mouseGridX = min(cast(int)(event.x / projectInfo.partsSizeH), projectInfo.mapSizeH - 1);
                mouseGridY = min(cast(int)(event.y / projectInfo.partsSizeV), projectInfo.mapSizeV - 1);
                if(lastMouseGridX != mouseGridX || lastMouseGridY != mouseGridY){
                    UpdateGuide();
                    queueDraw();
                }
                return chipDrawStrategy.onButtonPress(event, widget);
            }
            bool onButtonRelease(GdkEventButton* event, Widget widget){
                int lastMouseGridX = mouseGridX;
                int lastMouseGridY = mouseGridY;
                mouseGridX = min(cast(int)(event.x / projectInfo.partsSizeH), projectInfo.mapSizeH - 1);
                mouseGridY = min(cast(int)(event.y / projectInfo.partsSizeV), projectInfo.mapSizeV - 1);
                if(lastMouseGridX != mouseGridX || lastMouseGridY != mouseGridY){
                    UpdateGuide();
                    queueDraw();
                }
                return chipDrawStrategy.onButtonRelease(event, widget);
            }
            bool onMotionNotify(GdkEventMotion* event, Widget widget){
                int lastMouseGridX = mouseGridX;
                int lastMouseGridY = mouseGridY;
                mouseGridX = min(cast(int)(event.x / projectInfo.partsSizeH), projectInfo.mapSizeH - 1);
                mouseGridY = min(cast(int)(event.y / projectInfo.partsSizeV), projectInfo.mapSizeV - 1);
                if(lastMouseGridX != mouseGridX || lastMouseGridY != mouseGridY){
                    UpdateGuide();
                    queueDraw();
                }
                return chipDrawStrategy.onMotionNotify(event, widget);
            }
        }
        EditDrawingArea drawingArea = null;
        this(){
            super();
            drawingArea = new EditDrawingArea();
            addWithViewport(drawingArea);
            Adjustment adjustmentH = getHadjustment();
            adjustmentH.addOnValueChanged(&ScrollChanged);
            adjustmentH.addOnChanged(&ScrollChanged);
            Adjustment adjustmentV = getVadjustment();
            adjustmentV.addOnValueChanged(&ScrollChanged);
            adjustmentV.addOnChanged(&ScrollChanged);
        }
        void ScrollChanged(Adjustment){
            if(this.outer.onScrollChangedFunction !is null){
                onScrollChangedFunction();
            }
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

