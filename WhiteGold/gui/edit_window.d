module gui.edit_window;

import imports.all;
import main;
import project_info;
import dialog.new_project_dialog;
import dialog.resize_dialog;
import dialog.export_setting_dialog;

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
    void delegate(int,int,EAnchor) onMapSizeChangedFunction;
    void delegate(int,int,int,int) onExportSettingChangedFunction;
    void delegate(int,int,int,int) onNewProjectFunction;
    void delegate(CsvProjectInfo) onCsvLoadedFunction;
    void delegate(ChipReplaceInfo[]) onChipReplacedFunction;
    void delegate(int,int,int,int,int,int) onSelectionMovedFunction;
    void delegate() onChipReplaceCompletedFunction;
    void delegate() onUndoFunction;
    void delegate() onRedoFunction;
    void delegate() onScrollChangedFunction;
    void delegate(int) onSyringeUsedFunction;
    EditWindowEditArea editArea = null;
    EditWindowMenubar menuBar = null;
    EditWindowToolArea toolArea = null;
    bool showGrid = false;
    this(){
        super(APPLICATION_NAME ~ " " ~ "名称未設定");
//         setSizeRequest(320, 320);
        setDefaultSize(baseInfo.editWindowInfo.width, baseInfo.editWindowInfo.height);
        printf("EditWindow.this %d,%d,%d,%d\n",baseInfo.editWindowInfo.x, baseInfo.editWindowInfo.y,baseInfo.editWindowInfo.width, baseInfo.editWindowInfo.height);
        setIcon(new Pixbuf("dat/icon/application--pencil.png"));
        VBox mainBox = new VBox(false,0);
        menuBar = new EditWindowMenubar();
		mainBox.packStart(menuBar,false,false,0);
        toolArea = new EditWindowToolArea();
		mainBox.packStart(toolArea,false,false,0);
        editArea = new EditWindowEditArea();
		mainBox.packStart(editArea,true,true,0);
		mainBox.packStart(new EditWindowStatusbarArea(),false,false,0);
        toolArea.penButton.setActive(1);
        add(mainBox);
        addOnHide(&onHide);
        addOnDelete(&onDelete);
        addOnRealize((Widget widget){
                move(baseInfo.editWindowInfo.x, baseInfo.editWindowInfo.y);
            });
    }
    void Reload(){
        editArea.Reload();
    }
    void onHide(Widget widget){
        if(onHideFunction !is null){
            onHideFunction();
        }
    }
    bool onDelete(Event e, Widget widget){
        if(projectInfo.changeExists){
            if(!OpenYesNoDialog(format("%sへの変更が保存されていません。\n本当に終了しますか？",projectInfo.projectPath))){
                return true;
            }
        }
        with(baseInfo.editWindowInfo){
            getSize(width, height);
            getPosition(x, y);
        }
        with(baseInfo.partsWindowInfo){
            projectInfo.partsWindow.getSize(width, height);
            projectInfo.partsWindow.getPosition(x, y);
        }
        with(baseInfo.layerWindowInfo){
            projectInfo.layerWindow.getSize(width, height);
            projectInfo.layerWindow.getPosition(x, y);
        }
        with(baseInfo.overviewWindowInfo){
            projectInfo.overviewWindow.getSize(width, height);
            projectInfo.overviewWindow.getPosition(x, y);
        }
        return false;
    }
    bool OpenYesNoDialog(string message){
        MessageDialog d = new MessageDialog(
            this,
            GtkDialogFlags.MODAL,
            MessageType.QUESTION,
            ButtonsType.YES_NO,
            message);
        int responce = d.run();
        d.destroy();
        return responce == ResponseType.GTK_RESPONSE_YES;
    }
    void OpenNewProject(){
        if(projectInfo.changeExists){
            if(!OpenYesNoDialog(format("%sへの変更が保存されていません。\n変更を破棄してよろしいですか？",projectInfo.projectPath))){
                return;
            }
        }
        NewProjectDialog dialog = new NewProjectDialog();
        dialog.setModal(true);
        dialog.showAll();
        if(onNewProjectFunction !is null){
            dialog.onNewProjectFunction = onNewProjectFunction;
        }
    }
    void OpenProject(){
        if(projectInfo.changeExists){
            if(!OpenYesNoDialog(format("%sへの変更が保存されていません。\n変更を破棄してよろしいですか？",projectInfo.projectPath))){
                return;
            }
        }
        FileChooserDialog fs = new FileChooserDialog("プロジェクト選択", this, FileChooserAction.OPEN);
        FileFilter fileFilter = new FileFilter();
        fileFilter.setName("mapファイル");
        fileFilter.addPattern("*.map");
        fs.addFilter(fileFilter);
        if(baseInfo.lastProjectPath !is null){
            fs.setCurrentFolder(baseInfo.lastProjectPath);
        }
        if( fs.run() == ResponseType.GTK_RESPONSE_OK )
        {
            SerializableProjectInfo serializableProjectInfo;
            Serializer s = new Serializer(fs.getFilename(), FileMode.In);
            s.describe(serializableProjectInfo);
            delete s;
            projectInfo.initBySerializable(serializableProjectInfo);
            string splited[] = fs.getFilename().split("\\");
            baseInfo.lastProjectPath = "";
            foreach(tmp;splited[0..length - 1]){
                baseInfo.lastProjectPath ~= tmp ~ "\\";
            }
        }
        projectInfo.projectPath = fs.getFilename();
        projectInfo.changeExists = false;
        setTitle(APPLICATION_NAME ~ " " ~ (projectInfo.projectPath is null ? "名称未設定" : projectInfo.projectPath) );
        fs.hide();
    }
    void SaveProject(){
        if(projectInfo.projectPath !is null){
            SerializableProjectInfo serializableProjectInfo = projectInfo.getSerializable();
            Serializer s = new Serializer(projectInfo.projectPath, FileMode.Out);
            s.describe(serializableProjectInfo);
            delete s;
            projectInfo.changeExists = false;
            setTitle(APPLICATION_NAME ~ " " ~ (projectInfo.projectPath is null ? "名称未設定" : projectInfo.projectPath));
        }
    }
    void SaveProjectWithName(){
        FileChooserDialog fs = new FileChooserDialog("保存先選択", this, FileChooserAction.SAVE);
//                 fs.setCurrentFolderUri("file:///C:/Programing");
        if(baseInfo.lastProjectPath !is null){
            fs.setCurrentFolder(baseInfo.lastProjectPath);
        }
        if( fs.run() == ResponseType.GTK_RESPONSE_OK )
        {
            SerializableProjectInfo serializableProjectInfo = projectInfo.getSerializable();
            string filePath = fs.getFilename();
            if(filePath.length < ".map".length || filePath[length - 4..length] != ".map"){
                filePath ~= ".map";
            }
            Serializer s = new Serializer(filePath, FileMode.Out);
            s.describe(serializableProjectInfo);
            delete s;
            string splited[] = filePath.split("\\");
            baseInfo.lastProjectPath = "";
            foreach(tmp;splited[0..length - 1]){
                baseInfo.lastProjectPath ~= tmp ~ "\\";
            }
			projectInfo.projectPath = filePath;
            projectInfo.changeExists = false;
			setTitle(APPLICATION_NAME ~ " " ~ (projectInfo.projectPath is null ? "名称未設定" : projectInfo.projectPath));
        }
        fs.hide();
    }
    void OpenResizeDialog(){
        ResizeDialog dialog = new ResizeDialog();
        dialog.setModal(true);
        dialog.showAll();
        if(onMapSizeChangedFunction !is null){
            dialog.onMapSizeChangedFunction = onMapSizeChangedFunction;
        }
    }
    void Undo(){
        if(onUndoFunction !is null){
            onUndoFunction();
        }
    }
    void Redo(){
        if(onRedoFunction !is null){
            onRedoFunction();
        }
    }
    void ExportSetting(){
        ExportSettingDialog dialog = new ExportSettingDialog();
        dialog.setModal(true);
        dialog.showAll();
        if(onExportSettingChangedFunction !is null){
            dialog.onExportSettingChangedFunction = onExportSettingChangedFunction;
        }
    }
    void UpdateGuide(){
        editArea.drawingArea.queueDraw();
    }
    /**
       視界情報取得

       x1:視界左端がViewPortの横幅を1.0とした場合にどの位置にあるか
       y1:視界上端がViewPortの縦幅を1.0とした場合にどの位置にあるか
       x2:視界右端がViewPortの横幅を1.0とした場合にどの位置にあるか
       y2:視界下端がViewPortの縦幅を1.0とした場合にどの位置にあるか
     */
    void GetViewPortInfo(ref double x1, ref double y1, ref double x2, ref double y2){
//         printf("GetViewPortInfo 1\n");
        Adjustment adjustmentH = editArea.getHadjustment();
        x1 = adjustmentH.getValue() / (adjustmentH.getUpper() - adjustmentH.getLower());
        x2 = (adjustmentH.getValue() + adjustmentH.getPageSize()) / (adjustmentH.getUpper() - adjustmentH.getLower());
        Adjustment adjustmentV = editArea.getVadjustment();
        y1 = adjustmentV.getValue() / (adjustmentV.getUpper() - adjustmentV.getLower());
        y2 = (adjustmentV.getValue() + adjustmentV.getPageSize()) / (adjustmentV.getUpper() - adjustmentV.getLower());
//         printf("GetViewPortInfo 2\n");
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
        MenuItem menuItemUndo = null;
        MenuItem menuItemRedo = null;
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
            menuItemUndo = new MenuItem(&onMenuActivate, "取り消し","edit.undo", true, accelGroup, 'z');
            menuItemUndo.setSensitive(false);
            editMenu.append(menuItemUndo);
            menuItemRedo = new MenuItem(&onMenuActivate, "やり直し","edit.redo", true, accelGroup, 'y');
            menuItemRedo.setSensitive(false);
            editMenu.append(menuItemRedo);
            editMenu.append(new SeparatorMenuItem());
            editMenu.append(new MenuItem(&onMenuActivate, "リサイズ","edit.resize", true));
            editMenu.append(new MenuItem(&onMenuActivate, "エクスポート設定","edit.export_setting", true));
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
            case "file.open":
                OpenProject();
                break;
            case "file.save":
                SaveProject();
                break;
            case "file.save_with_name":
                SaveProjectWithName();
                break;
            case "file.import_csv":
                if(projectInfo.changeExists){
                    if(!OpenYesNoDialog(format("%sへの変更が保存されていません。\n変更を破棄してよろしいですか？",projectInfo.projectPath))){
                        return;
                    }
                }
                FileChooserDialog fs = new FileChooserDialog("CSVファイル選択", this.outer, FileChooserAction.OPEN);
                FileFilter fileFilter = new FileFilter();
                fileFilter.setName("csvファイル");
                fileFilter.addPattern("*.csv");
                fs.addFilter(fileFilter);
                if(baseInfo.lastImportCsvPath !is null){
                    fs.setCurrentFolder(baseInfo.lastImportCsvPath);
                }
                if( fs.run() == ResponseType.GTK_RESPONSE_OK )
                {
                    CsvProjectInfo info = ParseCsv(fs.getFilename());
                    if(this.outer.onCsvLoadedFunction !is null){
                        this.outer.onCsvLoadedFunction(info);
                    }
                    string splited[] = fs.getFilename().split("\\");
                    baseInfo.lastImportCsvPath = "";
                    foreach(tmp;splited[0..length - 1]){
                        baseInfo.lastImportCsvPath ~= tmp ~ "\\";
                    }
                }
                fs.hide();
                break;
            case "file.export_csv":
                FileChooserDialog fs = new FileChooserDialog("CSVファイル選択", this.outer, FileChooserAction.SAVE);
                if(baseInfo.lastExportCsvPath !is null){
                    fs.setCurrentFolder(baseInfo.lastExportCsvPath);
                }
                if( fs.run() == ResponseType.GTK_RESPONSE_OK )
                {
                    string exported = ExportCsv(projectInfo);
                    string filePath = fs.getFilename();
                    if(filePath.length < ".csv".length || filePath[length - 4..length] != ".csv"){
                        filePath ~= ".csv";
                    }
                    std.file.write(filePath, exported);
                    string splited[] = filePath.split("\\");
                    baseInfo.lastExportCsvPath = "";
                    foreach(tmp;splited[0..length - 1]){
                        baseInfo.lastExportCsvPath ~= tmp ~ "\\";
                    }
                }
                fs.hide();
                break;
            case "edit.undo":
                Undo();
                break;
            case "edit.redo":
                Redo();
                break;
            case "edit.resize":
                OpenResizeDialog();
                break;
            case "edit.export_setting":
                ExportSetting();
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
            fileOpenButton.addOnClicked((Button button){OpenProject();});
            packStart(fileOpenButton , false, false, 2 );
            Button fileSaveButton = new Button();
            fileSaveButton.setImage(new Image(new Pixbuf("dat/icon/disk.png")));
            fileSaveButton.addOnClicked((Button button){SaveProject();});
            packStart(fileSaveButton , false, false, 2 );
            Button fileSaveWithNameButton = new Button();
            fileSaveWithNameButton.setImage(new Image(new Pixbuf("dat/icon/disk--pencil.png")));
            fileSaveWithNameButton.addOnClicked((Button button){SaveProjectWithName();});
            packStart(fileSaveWithNameButton , false, false, 2 );
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // Undo Redo
            editUndoButton = new Button();
            editUndoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return-180-left.png")));
            editUndoButton.setSensitive(false);
            editUndoButton.addOnClicked((Button button){
                    Undo();
                });
            packStart(editUndoButton , false, false, 2 );
            editRedoButton = new Button();
            editRedoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return.png")));
            editRedoButton.setSensitive(false);
            editRedoButton.addOnClicked((Button button){
                    Redo();
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
            enum EGuideMode{
                CURSOR,
                TILING,
            }
            EGuideMode guideMode = EGuideMode.CURSOR;
            int tilingStartGridX = 0;
            int tilingStartGridY = 0;
            abstract class ChipDrawStrategyBase{
                abstract EDrawingType type();
                abstract bool onButtonPress(GdkEventButton* event, Widget widget);
                abstract bool onButtonRelease(GdkEventButton* event, Widget widget);
                abstract bool onMotionNotify(GdkEventMotion* event, Widget widget);
                abstract bool onKeyPress(GdkEventKey* event, Widget widget);
            }
            void drawChip(int gridX, int gridY){
                printf("drawChip 1\n");
                ChipReplaceInfo[] chipReplaceInfos;
                LayerInfo layerInfo = projectInfo.currentLayerInfo;
                if(layerInfo.gridSelection !is null){
                    with(layerInfo.gridSelection){
                        for(int yi = 0, y = startGridY ; y <= endGridY ; ++ yi, ++ y){
                            for(int xi = 0, x = startGridX ; x <= endGridX ; ++ xi, ++ x){
                                if(gridX + xi >= projectInfo.mapSizeH || gridY + yi >= projectInfo.mapSizeV || gridX + xi < 0 || gridY + yi < 0){
                                    continue;
                                }
                                chipReplaceInfos ~= ChipReplaceInfo(gridX + xi, gridY + yi, x, y, projectInfo.currentLayerIndex);
                            }
                        }
                    }
                }else{
                    chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, -1, -1, projectInfo.currentLayerIndex);
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
                LayerInfo layerInfo = projectInfo.currentLayerInfo;
                if(layerInfo.gridSelection !is null){
                    with(layerInfo.gridSelection){
                        int width = endGridX - startGridX + 1;
                        int height = endGridY - startGridY + 1;
                        for(int gridY = gridY1 ; gridY <= gridY2 ; ++ gridY){
                            for(int gridX = gridX1 ; gridX <= gridX2 ; ++ gridX){
                                int x = startGridX + (gridX - gridX1) % width;
                                int y = startGridY + (gridY - gridY1) % height;
                                chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, x, y, projectInfo.currentLayerIndex);
                            }
                        }
                    }
                }else{
                    for(int gridY = gridY1 ; gridY <= gridY2 ; ++ gridY){
                        for(int gridX = gridX1 ; gridX <= gridX2 ; ++ gridX){
                            chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, -1, -1, projectInfo.currentLayerIndex);
                        }
                    }
                }
                if(this.outer.outer.onChipReplacedFunction !is null){
                    this.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                }
                printf("tilingChip 2\n");
            }
            void selectionMoved(int srcGridX, int srcGridY, int dstGridX, int dstGridY, int gridWidth, int gridHeight){
                if(this.outer.outer.onSelectionMovedFunction !is null){
                    this.outer.outer.onSelectionMovedFunction(srcGridX, srcGridY, dstGridX, dstGridY, gridWidth, gridHeight);
                }
            }
            class ChipDrawStrategyPen : ChipDrawStrategyBase{
                int lastGridX,lastGridY;
                bool pressed = false;
                override EDrawingType type(){
                    return EDrawingType.PEN;
                }
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
                override bool onKeyPress(GdkEventKey* event, Widget widget){
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
                override EDrawingType type(){
                    return EDrawingType.TILING_PEN;
                }
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonPress\n");
                    mode = EMode.DRAGGING;
                    guideMode = EGuideMode.TILING;
                    tilingStartGridX = startGridX = mouseGridX;
                    tilingStartGridY = startGridY = mouseGridY;
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onButtonRelease\n");
                    mode = EMode.NORMAL;
                    guideMode = EGuideMode.CURSOR;
                    tilingChip(min(startGridX, mouseGridX),
                               min(startGridY, mouseGridY),
                               max(startGridX, mouseGridX),
                               max(startGridY, mouseGridY));
                    if(this.outer.outer.outer.onChipReplaceCompletedFunction !is null){
                        this.outer.outer.outer.onChipReplaceCompletedFunction();
                    }
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
                    printf("ChipDrawStrategyTilingPen.onMotionNotify\n");
                    return true;
                }
                override bool onKeyPress(GdkEventKey* event, Widget widget){
                    return true;
                }
            }
            class ChipDrawStrategySelect : ChipDrawStrategyBase{
                enum EMode{
                    NORMAL,
                    DRAGGING,
                    MOVING,
                }
                EMode mode = EMode.NORMAL;
                int startGridX = 0;
                int startGridY = 0;
                class Selection{
                    int startGridX;
                    int startGridY;
                    int endGridX;
                    int endGridY;
                    int moveGridX = 0;
                    int moveGridY = 0;
                    Pixbuf pixbuf = null;
                    this(int startGridX, int startGridY, int endGridX, int endGridY){
                        this.startGridX = startGridX;
                        this.startGridY = startGridY;
                        this.endGridX = endGridX;
                        this.endGridY = endGridY;
                    }
                    void Normalize(){
                        int tmpStartGridX = startGridX;
                        int tmpStartGridY = startGridY;
                        int tmpEndGridX = endGridX;
                        int tmpEndGridY = endGridY;
                        startGridX = min(tmpStartGridX, tmpEndGridX);
                        startGridY = min(tmpStartGridY, tmpEndGridY);
                        endGridX = max(tmpStartGridX, tmpEndGridX);
                        endGridY = max(tmpStartGridY, tmpEndGridY);
                    }
                }
                Selection selection = null;
                struct ClipBoardInfo{
                    int layerIndex;
                    int offsetGridX;
                    int offsetGridY;
                    int chipId;
                    this(int layerIndex, int offsetGridX, int offsetGridY, int chipId){
                        this.layerIndex = layerIndex;
                        this.offsetGridX = offsetGridX;
                        this.offsetGridY = offsetGridY;
                        this.chipId = chipId;
                    }
                }
                ClipBoardInfo clipBoard[];
                int moveStartGridX = 0;
                int moveStartGridY = 0;
                override EDrawingType type(){
                    return EDrawingType.SELECT;
                }
                override bool onButtonPress(GdkEventButton* event, Widget widget){
//                     printf("ChipDrawStrategySelect.onButtonPress\n");
                    LayerInfo layerInfo = projectInfo.currentLayerInfo;
                    if(!layerInfo.mapchipFileExists()){
                        return true;
                    }
                    if(mode == EMode.NORMAL){
                        if(selection !is null &&
                           selection.startGridX <= mouseGridX &&
                           selection.endGridX >= mouseGridX &&
                           selection.startGridY <= mouseGridY &&
                           selection.endGridY >= mouseGridY){
                            moveStartGridX = mouseGridX;
                            moveStartGridY = mouseGridY;
                            // 元の場所をSelection側にコピー(Todo! SHIFT押下時は全てのレイヤーを対象に)
                            LayerInfo layerInfo = projectInfo.currentLayerInfo;
                            selection.pixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH * (selection.endGridX - selection.startGridX + 1), projectInfo.partsSizeV * (selection.endGridY - selection.startGridY + 1));
                            layerInfo.layoutPixbuf.copyArea(projectInfo.partsSizeH * selection.startGridX, projectInfo.partsSizeV * selection.startGridY, projectInfo.partsSizeH * (selection.endGridX - selection.startGridX + 1), projectInfo.partsSizeV * (selection.endGridY - selection.startGridY + 1), selection.pixbuf, 0, 0);
                            // 元の場所を削除(Pixbufの表示だけ)(Todo! SHIFT押下時は全てのレイヤーを対象に)
                            Pixbuf pixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH, projectInfo.partsSizeV);
                            pixbuf.fill(0x00000000);
                            for(int y = selection.startGridY ; y <= selection.endGridY ; ++ y){
                                for(int x = selection.startGridX ; x <= selection.endGridX ; ++ x){
                                    pixbuf.copyArea(0, 0, projectInfo.partsSizeH, projectInfo.partsSizeV, layerInfo.layoutPixbuf, x * projectInfo.partsSizeH, y * projectInfo.partsSizeV);
                                }
                            }
                            mode = EMode.MOVING;
                        }else{
                            mode = EMode.DRAGGING;
                            selection = new Selection(mouseGridX, mouseGridY, mouseGridX, mouseGridY);
                            queueDraw();
                        }
                    }
                    return true;
                }
                override bool onButtonRelease(GdkEventButton* event, Widget widget){
//                     printf("ChipDrawStrategySelect.onButtonRelease\n");
                    if(mode == EMode.DRAGGING){
                        mode = EMode.NORMAL;
                        selection.endGridX = mouseGridX;
                        selection.endGridY = mouseGridY;
                        selection.Normalize();
                    }
                    else if(mode == EMode.MOVING){
                        mode = EMode.NORMAL;
                        // 移動を確定
                        selectionMoved(selection.startGridX,selection.startGridY,selection.startGridX + selection.moveGridX, selection.startGridY + selection.moveGridY, selection.endGridX - selection.startGridX + 1, selection.endGridY - selection.startGridY + 1);
//                         drawChip(selection.startGridX + selection.moveGridX, selection.startGridY + selection.moveGridY);
                    }
                    return true;
                }
                override bool onMotionNotify(GdkEventMotion* event, Widget widget){
//                     printf("ChipDrawStrategySelect.onMotionNotify\n");
                    if(mode == EMode.DRAGGING){
                        selection.endGridX = mouseGridX;
                        selection.endGridY = mouseGridY;
//                         selection.Normalize();
                    }
                    else if(mode == EMode.MOVING){
                        selection.moveGridX = mouseGridX - moveStartGridX;
                        selection.moveGridY = mouseGridY - moveStartGridY;
                    }
                    return true;
                }
                override bool onKeyPress(GdkEventKey* event, Widget widget){
                    LayerInfo layerInfo = projectInfo.currentLayerInfo;
                    if(mode == EMode.NORMAL && selection !is null){
                        void copyFunc(){
                            clipBoard.clear;
                            if(event.state & GdkModifierType.SHIFT_MASK){
                                foreach(i,layerInfo;projectInfo.layerInfos){
                                    for(int offsetY = 0, gridY = selection.startGridY ; gridY <= selection.endGridY ; ++ offsetY, ++ gridY){
                                        for(int offsetX = 0, gridX = selection.startGridX ; gridX <= selection.endGridX ; ++ offsetX, ++ gridX){
                                            int chipId = layerInfo.GetChipId(gridX, gridY);
                                            clipBoard ~= ClipBoardInfo(i, offsetX, offsetY, chipId);
                                        }
                                    }
                                }
                            }else{
                                LayerInfo layerInfo = projectInfo.currentLayerInfo;
                                for(int offsetY = 0, gridY = selection.startGridY ; gridY <= selection.endGridY ; ++ offsetY, ++ gridY){
                                    for(int offsetX = 0, gridX = selection.startGridX ; gridX <= selection.endGridX ; ++ offsetX, ++ gridX){
                                        int chipId = layerInfo.GetChipId(gridX, gridY);
                                        clipBoard ~= ClipBoardInfo(projectInfo.currentLayerIndex, offsetX, offsetY, chipId);
                                    }
                                }
                            }
                        }
                        void deleteFunc(){
                            ChipReplaceInfo[] chipReplaceInfos;
                            if(event.state & GdkModifierType.SHIFT_MASK){
                                for(int layerIndex = 0 ; layerIndex < projectInfo.layerInfos.length ; ++ layerIndex){
                                    for(int gridY = selection.startGridY ; gridY <= selection.endGridY ; ++ gridY){
                                        for(int gridX = selection.startGridX ; gridX <= selection.endGridX ; ++ gridX){
                                            chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, -1, -1, layerIndex);
                                        }
                                    }
                                }
                            }else{
                                for(int gridY = selection.startGridY ; gridY <= selection.endGridY ; ++ gridY){
                                    for(int gridX = selection.startGridX ; gridX <= selection.endGridX ; ++ gridX){
                                        chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, -1, -1, projectInfo.currentLayerIndex);
                                    }
                                }
                            }
                            if(this.outer.outer.outer.onChipReplacedFunction !is null){
                                this.outer.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                            }
                            // 元の場所をSelection側にコピー
                            selection.pixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH * (selection.endGridX - selection.startGridX + 1), projectInfo.partsSizeV * (selection.endGridY - selection.startGridY + 1));
                            layerInfo.layoutPixbuf.copyArea(projectInfo.partsSizeH * selection.startGridX, projectInfo.partsSizeV * selection.startGridY, projectInfo.partsSizeH * (selection.endGridX - selection.startGridX + 1), projectInfo.partsSizeV * (selection.endGridY - selection.startGridY + 1), selection.pixbuf, 0, 0);
                            if(this.outer.outer.outer.onChipReplaceCompletedFunction !is null){
                                this.outer.outer.outer.onChipReplaceCompletedFunction();
                            }
                        }
                        switch(event.keyval){
                            // 削除
                        case GdkKeysyms.GDK_Delete:
                            printf("delete\n");
                            deleteFunc();
                            break;
                            // コピー
                        case GdkKeysyms.GDK_c:
                        case GdkKeysyms.GDK_C:
                            if(event.state & GdkModifierType.CONTROL_MASK){
                                printf("copy\n");
                                copyFunc();
                            }
                            break;
                            // カット
                        case GdkKeysyms.GDK_x:
                        case GdkKeysyms.GDK_X:
                            if(event.state & GdkModifierType.CONTROL_MASK){
                                printf("cut\n");
                                copyFunc();
                                deleteFunc();
                            }
                            break;
                            // ペースト
                        case GdkKeysyms.GDK_v:
                        case GdkKeysyms.GDK_V:
                            if(event.state & GdkModifierType.CONTROL_MASK){
                                if(clipBoard.length > 0){
                                    ChipReplaceInfo[] chipReplaceInfos;
                                    foreach(one;clipBoard){
                                        int gridX = mouseGridX + one.offsetGridX;
                                        int gridY = mouseGridY + one.offsetGridY;
                                        if(gridX >= projectInfo.mapSizeH || gridY >= projectInfo.mapSizeV || gridX < 0 || gridY < 0){
                                            continue;
                                        }
                                        LayerInfo layerInfo = projectInfo.layerInfos[one.layerIndex];
                                        int gridXInMapchip,gridYInMapchip;
                                        layerInfo.GetGridXYInMapchip(one.chipId, gridXInMapchip, gridYInMapchip);
                                        chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, gridXInMapchip, gridYInMapchip, one.layerIndex);
                                    }
                                    if(this.outer.outer.outer.onChipReplacedFunction !is null){
                                        this.outer.outer.outer.onChipReplacedFunction(chipReplaceInfos);
                                    }
                                    if(this.outer.outer.outer.onChipReplaceCompletedFunction !is null){
                                        this.outer.outer.outer.onChipReplaceCompletedFunction();
                                    }
                                }
                                printf("paste\n");
                            }
                            break;
                        default:
                            break;
                        }
                    }
                    return true;
                }
            }
            class ChipDrawStrategyFill : ChipDrawStrategyBase{
                override EDrawingType type(){
                    return EDrawingType.FILL;
                }
                override bool onButtonPress(GdkEventButton* event, Widget widget){
                    long time = std.datetime.Clock.currStdTime();
                    int cursorGridX = cast(int)(event.x / projectInfo.partsSizeH);
                    int cursorGridY = cast(int)(event.y / projectInfo.partsSizeV);
                    LayerInfo layerInfo = projectInfo.currentLayerInfo;
                    int layoutIndex = cursorGridY * projectInfo.mapSizeH + cursorGridX;
                    int startChipId = layerInfo.chipLayout[layoutIndex];
                    int newChipId = -1;
                    if(!layerInfo.mapchipFileExists()){
                        return true;
                    }
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
                                chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, layerInfo.gridSelection !is null ? layerInfo.gridSelection.startGridX : -1, layerInfo.gridSelection !is null ? layerInfo.gridSelection.startGridY : -1, projectInfo.currentLayerIndex);
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
                                chipReplaceInfos ~= ChipReplaceInfo(gridX, gridY, layerInfo.gridSelection !is null ? layerInfo.gridSelection.startGridX : -1, layerInfo.gridSelection !is null ? layerInfo.gridSelection.startGridY : -1, projectInfo.currentLayerIndex);
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
                override bool onKeyPress(GdkEventKey* event, Widget widget){
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
            this(){
                super();
                setPolicy(GtkPolicyType.AUTOMATIC, GtkPolicyType.AUTOMATIC);
                addOnButtonPress(&onButtonPress);
                addOnButtonRelease(&onButtonRelease);
                addOnMotionNotify(&onMotionNotify);
                addOnKeyPress(&onKeyPress);
                setCanFocus(1);
                addEvents(EventMask.BUTTON_PRESS_MASK);
                addOnExpose(&exposeCallback);
                setSizeRequest(projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
                gridPixbuf = CreateGridPixbuf(projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV);
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
                foreach(i, layerInfo;projectInfo.layerInfos){
                    if(!layerInfo.visible){
                        continue;
                    }
                    dr.drawPixbuf(layerInfo.layoutPixbuf, 0, 0);
                    // 選択領域用画像描画
                    if(i == projectInfo.currentLayerIndex){
                        if(chipDrawStrategy.type == EDrawingType.SELECT){
                            auto strategySelect = cast(ChipDrawStrategySelect)chipDrawStrategy;
                            if(strategySelect.selection !is null){
                                int leftGridX = min(strategySelect.selection.startGridX, strategySelect.selection.endGridX);
                                int topGridY = min(strategySelect.selection.startGridY, strategySelect.selection.endGridY);
                                int x = (leftGridX + strategySelect.selection.moveGridX) * projectInfo.partsSizeH;
                                int y = (topGridY + strategySelect.selection.moveGridY) * projectInfo.partsSizeV;
                                dr.drawPixbuf(strategySelect.selection.pixbuf, x, y);
                            }
                        }
                    }
                }
                if(showGrid){
                    // グリッド描画
                    dr.drawPixbuf(gridPixbuf, 0, 0);
                    // エクスポート範囲描画
                    gc.setRgbFgColor(new Color(100, 100, 255));
                    dr.drawRectangle(
                        gc,false,
                        projectInfo.exportStartGridX * projectInfo.partsSizeH,
                        projectInfo.exportStartGridY * projectInfo.partsSizeV,
                        (projectInfo.exportEndGridX + 1) * projectInfo.partsSizeH,
                        (projectInfo.exportEndGridY + 1) * projectInfo.partsSizeH,
                        );
                }
                // カーソル位置の四角描画
                switch(chipDrawStrategy.type){
                case EDrawingType.SELECT:
                {
                    auto strategySelect = cast(ChipDrawStrategySelect)chipDrawStrategy;
                    if(strategySelect.selection !is null){
                        int leftGridX = min(strategySelect.selection.startGridX, strategySelect.selection.endGridX);
                        int topGridY = min(strategySelect.selection.startGridY, strategySelect.selection.endGridY);
                        // 選択領域描画
                        int x = (leftGridX + strategySelect.selection.moveGridX) * projectInfo.partsSizeH;
                        int y = (topGridY + strategySelect.selection.moveGridY) * projectInfo.partsSizeV;
                        int width = projectInfo.partsSizeH * (std.math.abs(strategySelect.selection.endGridX - strategySelect.selection.startGridX) + 1) - 1;
                        int height = projectInfo.partsSizeV * (std.math.abs(strategySelect.selection.endGridY - strategySelect.selection.startGridY) + 1) - 1;
                        GC gc = new GC(dr);
                        gc.setRgbFgColor(new Color(0,0,0));
                        // 内部の斜線(上辺から)
                        for(int tmpX = x ; tmpX < x + width ; tmpX += 8){
                            if(y + (x + width - tmpX) > y + height){
                                int value  = (y + (x + width - tmpX)) - (y + height);
                                dr.drawLine(gc, tmpX, y, x + width - value, y + (x + width - tmpX) - value);
                                dr.drawLine(gc, x + (x + width) - tmpX, y, x + value, y + (x + width - tmpX) - value);
                            }else{
                                dr.drawLine(gc, tmpX, y, x + width, y + (x + width - tmpX));
                                dr.drawLine(gc, x + (x + width) - tmpX, y, x, y + (x + width - tmpX));
                            }
                        }
                        // 内部の斜線(左辺右辺から)
                        for(int tmpY = y ; tmpY < y + height ; tmpY += 8){
                            if(x + (y + height - tmpY) > x + width){
                                int value = (x + (y + height - tmpY)) - (x + width);
                                dr.drawLine(gc, x, tmpY, x + (y + height - tmpY) - value, y + height - value);
                            }else{
                                dr.drawLine(gc, x, tmpY, x + (y + height - tmpY), y + height);
                            }
                            if(x + width - (y + height - tmpY) < x){
                                int value = x - (x + width - (y + height - tmpY));
                                dr.drawLine(gc, x + width, tmpY, x + width - (y + height - tmpY) + value, y + height - value);
                            }else{
                                dr.drawLine(gc, x + width, tmpY, x + width - (y + height - tmpY), y + height);
                            }
                        }
                        // 外枠
                        gc.setRgbFgColor(new Color(255,255,255));
                        dr.drawRectangle(gc, false, x, y, width, height);
                    }
                }
                break;
                default:
                {
                    if(guideMode == EGuideMode.CURSOR){
                        LayerInfo layerInfo = projectInfo.currentLayerInfo;
                        int selectWidth = layerInfo.gridSelection !is null ? layerInfo.gridSelection.endGridX - layerInfo.gridSelection.startGridX + 1 : 1;
                        int selectHeight = layerInfo.gridSelection !is null ? layerInfo.gridSelection.endGridY - layerInfo.gridSelection.startGridY + 1 : 1;
                        int leftPixelX = mouseGridX * projectInfo.partsSizeH + 1;
                        int rightPixelX = mouseGridX * projectInfo.partsSizeH + projectInfo.partsSizeH * selectWidth - 1 - 1;
                        int topPixelY = mouseGridY * projectInfo.partsSizeV + 1;
                        int bottomPixelY = mouseGridY * projectInfo.partsSizeV + projectInfo.partsSizeV * selectHeight - 1 - 1;
                        gdk.RGB.RGB.rgbGcSetForeground(gc, 0xFF0000);
                        dr.drawRectangle(gc, false, leftPixelX, topPixelY, rightPixelX - leftPixelX ,bottomPixelY - topPixelY);
                    }
                    else if(guideMode == EGuideMode.TILING){
                        LayerInfo layerInfo = projectInfo.currentLayerInfo;
                        gdk.RGB.RGB.rgbGcSetForeground(gc, 0xFF0000);
                        int selectWidth = layerInfo.gridSelection !is null ? layerInfo.gridSelection.endGridX - layerInfo.gridSelection.startGridX + 1 : 1;
                        int selectHeight = layerInfo.gridSelection !is null ? layerInfo.gridSelection.endGridY - layerInfo.gridSelection.startGridY + 1 : 1;
                        int startGridX = 0;
                        int i = 0;
                        for(;;++i){
                            startGridX = tilingStartGridX - selectWidth * i;
                            if(startGridX <= 0){
                                break;
                            }
                        }
                        int startGridY = 0;
                        int j = 0;
                        for(;;++j){
                            startGridY = tilingStartGridY - selectHeight * j;
                            if(startGridY <= 0){
                                break;
                            }
                        }
                        for(int gridY = startGridY ; gridY < projectInfo.mapSizeV ; gridY += selectHeight){
                            for(int gridX = startGridX ; gridX < projectInfo.mapSizeH ; gridX += selectWidth){
                                gdk.RGB.RGB.rgbGcSetForeground(gc, 0xFF0000);
                                dr.drawRectangle(gc, false, gridX * projectInfo.partsSizeH + 1, gridY * projectInfo.partsSizeV + 1, selectWidth * projectInfo.partsSizeH - 2, selectHeight * projectInfo.partsSizeV - 2);
                            }
                        }
                    }
                }
                break;
                }
                printf("EditWindow.exposeCallback 2\n");
                return true;
            }
            bool onButtonPress(GdkEventButton* event, Widget widget){
                this.outer.outer.setFocus(this);
                int lastMouseGridX = mouseGridX;
                int lastMouseGridY = mouseGridY;
                mouseGridX = min(cast(int)(event.x / projectInfo.partsSizeH), projectInfo.mapSizeH - 1);
                mouseGridY = min(cast(int)(event.y / projectInfo.partsSizeV), projectInfo.mapSizeV - 1);
                if(lastMouseGridX != mouseGridX || lastMouseGridY != mouseGridY){
                    UpdateGuide();
                    queueDraw();
                }
                // 右クリックはスポイト専用なのでStrategyに渡さない
                if(event.button == 3){
                    return true;
                }else{
                    return chipDrawStrategy.onButtonPress(event, widget);
                }
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
                // 右クリックはスポイト専用なのでStrategyに渡さない
                if(event.button == 3){
                    if(this.outer.outer.onSyringeUsedFunction){
                        LayerInfo layerInfo = projectInfo.currentLayerInfo;
                        int chipId = layerInfo.GetChipId(mouseGridX, mouseGridY);
                        this.outer.outer.onSyringeUsedFunction(chipId);
                    }
                    return true;
                }else{
                    return chipDrawStrategy.onButtonRelease(event, widget);
                }
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
            bool onKeyPress(GdkEventKey* event, Widget widget){
                return chipDrawStrategy.onKeyPress(event, widget);
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
            if(drawingArea.gridPixbuf !is null){
                drawingArea.gridPixbuf.unref();
                delete drawingArea.gridPixbuf;
            }
            drawingArea.gridPixbuf = CreateGridPixbuf(projectInfo.mapSizeH, projectInfo.mapSizeV, projectInfo.partsSizeH, projectInfo.partsSizeV);
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

