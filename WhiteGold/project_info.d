module project_info;
private import imports.all;
private import main;
private import gui.edit_window;
private import gui.layer_window;
private import gui.parts_window;
private import gui.overview_window;

static const string APPLICATION_NAME = "Whitegold";

enum EWindowType{
    EDIT,
    LAYER,
    PARTS,
    OVERVIEW,
}
enum EGridType{
    NORMAL,
    DOTTED,
}
enum EAnchor{
    DIRECTION_1,
    DIRECTION_2,
    DIRECTION_3,
    DIRECTION_4,
    DIRECTION_5,
    DIRECTION_6,
    DIRECTION_7,
    DIRECTION_8,
    DIRECTION_9,
}

struct ChipReplaceInfo{
    int gridX;
    int gridY;
    int newChipGridX;
    int newChipGridY;
    int layerIndex;
    this(int gridX,int gridY,int newChipGridX,int newChipGridY, int layerIndex){
        this.gridX = gridX;
        this.gridY = gridY;
        this.newChipGridX = newChipGridX;
        this.newChipGridY = newChipGridY;
        this.layerIndex = layerIndex;
    }
}
struct EditInfo{
    this(int layerIndex, int layoutIndex, int oldChipId, int newChipId){
        this.layerIndex = layerIndex;
        this.layoutIndex = layoutIndex;
        this.oldChipId = oldChipId;
        this.newChipId = newChipId;
    }
    int layerIndex;
    int layoutIndex;
    int oldChipId;
    int newChipId;
}

class ProjectInfo{
    int mapSizeH = 20;
    int mapSizeV = 20;
    int partsSizeH = 16;
    int partsSizeV = 16;
    int exportStartGridX = 0;
    int exportStartGridY = 0;
    int exportEndGridX = 20 - 1;
    int exportEndGridY = 20 - 1;
    int grid1Color = 0xAAAAAA;
    int grid1Type = EGridType.NORMAL;
    int grid1Interval = 1;
    string projectPath = null;
    bool changeExists = false;
    // レイヤー関連
    int currentLayerIndex = 0;
    LayerInfo layerInfos[];
    LayerInfo currentLayerInfo(){
        return layerInfos[currentLayerIndex];
    }
    // マップチップ関連
    Pixbuf[string] mapchipPixbufList;
    void AddMapchipFile(string mapchipFilePath){
        printf("AddMapchipFile %s\n",toMBSz(mapchipFilePath));
        if(mapchipFilePath !in mapchipPixbufList){
            mapchipPixbufList[mapchipFilePath] = new Pixbuf(mapchipFilePath);
        }
    }
    // Undo/Redo関連
    // [] 1回のUndoで戻す単位
    // [][] 1回のUndoで戻す単位の中に含まれている編集リスト(左クリックで移動しつつ描いた場合などの１ストローク単位で管理するので複数ありうる)
    // [][][] 各編集内容(チップが複数選択されていた場合があるので複数ありうる)
    EditInfo[][][] undoQueue;
    EditInfo[][][] redoQueue;
    // 各種ウインドウ
    EditWindow editWindow = null;
    LayerWindow layerWindow = null;
    PartsWindow partsWindow = null;
    OverviewWindow overviewWindow = null;
    SerializableProjectInfo getSerializable(){
        SerializableProjectInfo ret = new SerializableProjectInfo();
        ret.mapSizeH = mapSizeH;
        ret.mapSizeV = mapSizeV;
        ret.partsSizeH = partsSizeH;
        ret.partsSizeV = partsSizeV;
        ret.projectPath = projectPath;
        ret.exportStartGridX = exportStartGridX;
        ret.exportStartGridY = exportStartGridY;
        ret.exportEndGridX = exportEndGridX;
        ret.exportEndGridY = exportEndGridY;
        ret.grid1Color = grid1Color;
        ret.grid1Type = grid1Type;
        ret.grid1Interval = grid1Interval;
        foreach(layerInfo;layerInfos){
            ret.layerInfos ~= layerInfo.getSerializable();
        }
		return ret;
    }
    void initBySerializable(Window parentWindow, SerializableProjectInfo serializableProjectInfo){
        mapSizeH = serializableProjectInfo.mapSizeH;
        mapSizeV = serializableProjectInfo.mapSizeV;
        partsSizeH = serializableProjectInfo.partsSizeH;
        partsSizeV = serializableProjectInfo.partsSizeV;
        projectPath = serializableProjectInfo.projectPath;
        exportStartGridX = serializableProjectInfo.exportStartGridX;
        exportStartGridY = serializableProjectInfo.exportStartGridY;
        exportEndGridX = serializableProjectInfo.exportEndGridX;
        exportEndGridY = serializableProjectInfo.exportEndGridY;
        grid1Color = serializableProjectInfo.grid1Color;
        grid1Type = serializableProjectInfo.grid1Type;
        grid1Interval = serializableProjectInfo.grid1Interval;
        layerInfos.clear;
        foreach(serializableLayerInfo;serializableProjectInfo.layerInfos){
            LayerInfo layerInfo = new LayerInfo();
            layerInfo.initBySerializable(serializableLayerInfo);
            printf("ProjectInfo.initBySerializable 1 %s\n",toMBSz(serializableLayerInfo.mapchipFilePath));
            printf("[%x] ProjectInfo.initBySerializable 2 %s\n",layerInfo,toMBSz(layerInfo.mapchipFilePath));
            layerInfos ~= layerInfo;
            printf("[%x] ProjectInfo.initBySerializable 3 %s\n",layerInfo,toMBSz(layerInfo.mapchipFilePath));
        }
        // 基本データは設定完了したので画像など生成処理
        struct MapchipPathReplaceInfo{
            string src;
            string dst;
            this(string src, string dst){
                this.src = src;
                this.dst = dst;
            }
        }
        MapchipPathReplaceInfo mapchipPathReplaceInfos[];
        foreach(layerInfo;layerInfos){
            printf("[%x] ProjectInfo.initBySerializable 4 %s\n",layerInfo,toMBSz(layerInfo.mapchipFilePath));
            // mapchipファイルパスの置換情報が存在するなら
            bool Finder(MapchipPathReplaceInfo info){
                return info.src == layerInfo.mapchipFilePath;
            }
            MapchipPathReplaceInfo founds[] = std.algorithm.find!(Finder)(mapchipPathReplaceInfos);
            if(founds.length == 1){
                layerInfo.mapchipFilePath = founds[0].dst;
            }
            // mapchipファイルが存在しないなら
            if(!std.file.exists(layerInfo.mapchipFilePath)){
                MessageDialog d = new MessageDialog(
                    parentWindow,
                    GtkDialogFlags.MODAL,
                    MessageType.WARNING,
                    ButtonsType.OK,
                    format("%sがありません。マップチップファイルを選択してください。",layerInfo.mapchipFilePath));
                d.run();
                d.destroy();
                FileChooserDialog fs = new FileChooserDialog("マップチップファイル選択", parentWindow, FileChooserAction.OPEN);
                if(baseInfo.lastMapchipPath !is null){
                    fs.setCurrentFolder(baseInfo.lastMapchipPath);
                }
                if( fs.run() == ResponseType.GTK_RESPONSE_OK )
                {
                    mapchipPathReplaceInfos ~= MapchipPathReplaceInfo(layerInfo.mapchipFilePath, fs.getFilename());
                    layerInfo.mapchipFilePath = fs.getFilename();
                    string splited[] = fs.getFilename().split("\\");
                    baseInfo.lastMapchipPath = "";
                    foreach(tmp;splited[0..length - 1]){
                        baseInfo.lastMapchipPath ~= tmp ~ "\\";
                    }
                }
                fs.hide();
            }
            AddMapchipFile(layerInfo.mapchipFilePath);
            layerInfo.CreateTransparentPixbuf();
            layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
        }
        changeExists = false;
        editWindow.setTitle(APPLICATION_NAME ~ " " ~ (projectPath is null ? "名称未設定" : projectPath) );
        editWindow.Reload();
        layerWindow.Reload();
        overviewWindow.Reload();
        partsWindow.Reload();
    }
    // 各種処理関数
    void SetEditWindow(EditWindow editWindow){
        this.editWindow = editWindow;
        this.editWindow.onHideFunction = &onHideEditWindow;
        this.editWindow.onWindowShowHideFunction = &onWindowShowHide;
        this.editWindow.onNewProjectFunction = &onNewProject;
        this.editWindow.onMapSizeChangedFunction = &onMapSizeChanged;
        this.editWindow.onExportSettingChangedFunction = &onExportSettingChanged;
        this.editWindow.onCsvLoadedFunction = &onCsvLoaded;
        this.editWindow.onChipReplacedFunction = &onChipReplaced;
        this.editWindow.onSelectionMovedFunction = &onSelectionMoved;
        this.editWindow.onChipReplaceCompletedFunction = &onChipReplaceCompleted;
        this.editWindow.onUndoFunction = &onUndo;
        this.editWindow.onRedoFunction = &onRedo;
        this.editWindow.onScrollChangedFunction = &onScrollChanged;
        this.editWindow.onSyringeUsedFunction = &onSyringeUsed;
    }
    void SetLayerWindow(LayerWindow layerWindow){
        this.layerWindow = layerWindow;
        this.layerWindow.onSelectedLayerChangedFunction = &onSelectedLayerChanged;
        this.layerWindow.onLayerVisibilityChangedFunction = &onLayerVisibilityChanged;
        this.layerWindow.onLayerAddedFunction = &onLayerAdded;
        this.layerWindow.onLayerDeletedFunction = &onLayerDeleted;
        this.layerWindow.onLayerMovedFunction = &onLayerMoved;
    }
    void SetPartsWindow(PartsWindow partsWindow){
        this.partsWindow = partsWindow;
        this.partsWindow.onMapchipFileLoadedFunction = &onMapchipFileLoaded;
        this.partsWindow.onSelectionChangedFunction = &onSelectionChanged;
    }
    void SetOverviewWindow(OverviewWindow overviewWindow){
        this.overviewWindow = overviewWindow;
        this.overviewWindow.onScrollCenterChangedFunction = &onScrollCenterChanged;
    }
    void onSelectedLayerChanged(int index){
        currentLayerIndex = index;
        partsWindow.Reload();
        editWindow.queueDraw();
    }
    void onLayerVisibilityChanged(int index, bool visible){
        layerInfos[index].visible = visible;
        editWindow.queueDraw();
        overviewWindow.queueDraw();
    }
    void onLayerAdded(){
        LayerInfo layerInfo = new LayerInfo(format("レイヤー%d",layerInfos.length), true, null);
        layerInfo.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
        layerInfo.chipLayout[0..length] = -1;
        layerInfo.CreateTransparentPixbuf();
        layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
        layerInfos ~= layerInfo;
        layerWindow.Reload();
    }
    void onLayerDeleted(){
        bool Remover(LayerInfo layerInfo){
            return currentLayerInfo is layerInfo;
        }
        if(layerInfos.length <= 1){
            return;
        }
        layerInfos = remove!(Remover)(layerInfos);
        layerWindow.Reload();
    }
    void onLayerMoved(bool isUp){
        if(isUp){
            if(currentLayerIndex >= 1){
                swap(layerInfos[currentLayerIndex], layerInfos[currentLayerIndex - 1]);
            }
        }else{
            if(currentLayerIndex <= layerInfos.length - 2){
                swap(layerInfos[currentLayerIndex], layerInfos[currentLayerIndex + 1]);
            }
        }
        layerWindow.Reload();
        editWindow.queueDraw();
        overviewWindow.queueDraw();
        partsWindow.Reload();
    }
    void onHideEditWindow(){
        Main.quit();
    }
    void onWindowShowHide(EWindowType windowType, bool show){
        final switch(windowType){
        case EWindowType.EDIT:
            show ? editWindow.show() : editWindow.hide();
            break;
        case EWindowType.PARTS:
            show ? partsWindow.show() : partsWindow.hide();
            break;
        case EWindowType.LAYER:
            show ? layerWindow.show() : layerWindow.hide();
            break;
        case EWindowType.OVERVIEW:
            show ? overviewWindow.show() : overviewWindow.hide();
            break;
        }
    }
    void onNewProject(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
        this.mapSizeH = mapSizeH;
        this.mapSizeV = mapSizeV;
        this.exportStartGridX = 0;
        this.exportStartGridY = 0;
        this.exportEndGridX = this.mapSizeH - 1;
        this.exportEndGridY = this.mapSizeV - 1;
        this.partsSizeH = partsSizeH;
        this.partsSizeV = partsSizeV;
        layerInfos = layerInfos[0..1];
        foreach(layerInfo;layerInfos){
            layerInfo.Reset();
        }
        editWindow.Reload();
        partsWindow.Reload();
        overviewWindow.Reload();
        layerWindow.Reload();
    }
    void onMapSizeChanged(int mapSizeH, int mapSizeV, EAnchor anchor){
        int oldMapSizeH = this.mapSizeH;
        int oldMapSizeV = this.mapSizeV;
        this.mapSizeH = mapSizeH;
        this.mapSizeV = mapSizeV;
        foreach(layerInfo;layerInfos){
            layerInfo.MapSizeChanged(oldMapSizeH, oldMapSizeV, anchor);
        }
        this.exportStartGridX = 0;
        this.exportStartGridY = 0;
        this.exportEndGridX = this.mapSizeH - 1;
        this.exportEndGridY = this.mapSizeV - 1;
        editWindow.Reload();
        overviewWindow.Reload();
    }
    void onExportSettingChanged(int startX, int endX, int startY, int endY){
        this.exportStartGridX = startX;
        this.exportStartGridY = startY;
        this.exportEndGridX = endX;
        this.exportEndGridY = endY;
        editWindow.queueDraw();
    }
    void onCsvLoaded(CsvProjectInfo info){
        mapSizeH = info.mapSizeH;
        mapSizeV = info.mapSizeV;
        exportStartGridX = 0;
        exportStartGridY = 0;
        exportEndGridX = mapSizeH - 1;
        exportEndGridY = mapSizeV - 1;
        partsSizeH = info.partsSizeH;
        partsSizeV = info.partsSizeV;
        layerInfos.clear;
        foreach(i,chipLayout;info.chipLayouts){
            LayerInfo layerInfo = new LayerInfo(format("レイヤー%d",i), true, null);
            layerInfo.chipLayout = chipLayout;
            layerInfo.CreateTransparentPixbuf();
            layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
            layerInfos ~= layerInfo;
        }
        editWindow.Reload();
        partsWindow.Reload();
        layerWindow.Reload();
        overviewWindow.Reload();
    }
    void onMapchipFileLoaded(string mapchipFilePath){
        AddMapchipFile(mapchipFilePath);
        LayerInfo layerInfo = currentLayerInfo;
        layerInfo.mapchipFilePath = mapchipFilePath;
        layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
        partsWindow.Reload();
        editWindow.Reload();
        overviewWindow.Reload();
    }
    void onSelectionChanged(double startX, double startY, double endX, double endY){
        printf("onSelectionChanged 1\n");
        LayerInfo layerInfo = currentLayerInfo;
		bool forceDraw = false;
		if(layerInfo.gridSelection is null){
			layerInfo.generateGridSelection();
			forceDraw = true;
		}
        int oldStartGridX = layerInfo.gridSelection.startGridX;
        int oldStartGridY = layerInfo.gridSelection.startGridY;
        int oldEndGridX = layerInfo.gridSelection.endGridX;
        int oldEndGridY = layerInfo.gridSelection.endGridY;
        layerInfo.gridSelection.startGridX = cast(int)(startX / partsSizeH);
        layerInfo.gridSelection.startGridY = cast(int)(startY / partsSizeV);
        layerInfo.gridSelection.endGridX = cast(int)(endX / partsSizeH);
        layerInfo.gridSelection.endGridY = cast(int)(endY / partsSizeV);
        layerInfo.clipBoard.clear;
        // グリッド座標が変わっていない場合は再描画必要ない
        if(forceDraw || oldStartGridX != layerInfo.gridSelection.startGridX || oldStartGridY != layerInfo.gridSelection.startGridY || oldEndGridX != layerInfo.gridSelection.endGridX || oldEndGridY != layerInfo.gridSelection.endGridY){
            editWindow.UpdateGuide();
            editWindow.queueDraw();
            partsWindow.UpdateStatusBar();
            partsWindow.queueDraw();
        }
        printf("onSelectionChanged 2\n");
    }
    /**
       ある場所のチップのIndexを入れ替えてPixbufも更新。

       tmpEditInfosTreeに入れ替え履歴を入れるが、undoQueueへの代入はonChipReplaceCompletedが呼ばれるまで待つ。これは1ストローク分の履歴を1回のUndoで戻せるようにしたいため。
     */
    EditInfo tmpEditInfosTree[][];
    void onChipReplaced(ChipReplaceInfo[] chipReplaceInfos){
//         printf("onChipReplaced 1\n");
        EditInfo editInfos[];
        foreach(chipReplaceInfo;chipReplaceInfos){
            with(chipReplaceInfo){
                LayerInfo layerInfo = layerInfos[layerIndex];
                if(!layerInfo.mapchipFileExists()){
                    continue;
                }
                Pixbuf mapchip = mapchipPixbufList[layerInfo.mapchipFilePath];
                int mapchipDivNumH = cast(int)mapchip.getWidth() / partsSizeH;
                int oldChipId = layerInfo.GetChipId(gridX, gridY);
                int newChipId = (newChipGridX < 0 || newChipGridY < 0) ? -1 : newChipGridX + newChipGridY * mapchipDivNumH;
                int layoutIndex = gridX + gridY * mapSizeH;
                editInfos ~= EditInfo(layerIndex,layoutIndex,oldChipId,newChipId);
                layerInfo.ReplaceChip(gridX,gridY,newChipId);
//                 printf("onChipReplaced[%d:(%d,%d)(%d->%d)]",layerIndex,gridX,gridY,oldChipId,newChipId);
            }
        }
        tmpEditInfosTree ~= editInfos;
        editWindow.queueDraw();
        overviewWindow.queueDraw();
//         printf("onChipReplaced 2\n");
    }
    void onSelectionMoved(int srcGridX, int srcGridY, int dstGridX, int dstGridY, int gridWidth, int gridHeight){
        LayerInfo layerInfo = currentLayerInfo;
        struct ReplaceInfo{
            int gridX;
            int gridY;
            int newChipId;
            this(int gridX, int gridY, int newChipId){
                this.gridX = gridX;
                this.gridY = gridY;
                this.newChipId = newChipId;
            }
        }
        ReplaceInfo replaceInfos[];
        EditInfo editInfos[];
        // 元の場所の削除
        for(int gridY = srcGridY ; gridY < srcGridY + gridHeight ; ++ gridY){
            for(int gridX = srcGridX ; gridX < srcGridX + gridWidth ; ++ gridX){
                int newChipId = -1;
                int oldChipId = layerInfo.GetChipId(gridX, gridY);
                int layoutIndex = gridX + gridY * mapSizeH;
                replaceInfos ~= ReplaceInfo(gridX, gridY, newChipId);
                editInfos ~= EditInfo(currentLayerIndex,layoutIndex,oldChipId,newChipId);
                printf("(%d,%d) %d->%d\n",gridX,gridY,oldChipId,newChipId);
            }
        }
        // 移動後の反映
        for(int offsetY = 0 ; offsetY < gridHeight ; ++ offsetY){
            for(int offsetX = 0 ; offsetX < gridWidth ; ++ offsetX){
                int newChipId = layerInfo.GetChipId(srcGridX + offsetX, srcGridY + offsetY);
                int oldChipId = layerInfo.GetChipId(dstGridX + offsetX, dstGridY + offsetY);
                int layoutIndex = (dstGridX + offsetX) + (dstGridY + offsetY) * mapSizeH;
                replaceInfos ~= ReplaceInfo(dstGridX + offsetX,dstGridY + offsetY,newChipId);
                editInfos ~= EditInfo(currentLayerIndex,layoutIndex,oldChipId,newChipId);
            }
        }
        foreach(replaceInfo;replaceInfos){
            layerInfo.ReplaceChip(replaceInfo.gridX, replaceInfo.gridY ,replaceInfo.newChipId);
        }
        EditInfo editInfosTree[][] = [editInfos];
        undoQueue ~= editInfosTree;
        redoQueue.clear;
        updateUndoRedo();

        editWindow.queueDraw();
        overviewWindow.queueDraw();
    }
    /**
       チップの入れ替え確定

       tmpEditInfosの内容をundoQueueに反映する。
       */
    void onChipReplaceCompleted(){
        printf("onChipReplaceCompleted 1\n");
        undoQueue ~= tmpEditInfosTree;
        redoQueue.clear;
        tmpEditInfosTree.clear;
        updateUndoRedo();
        printf("onChipReplaceCompleted 2\n");
    }
    void updateUndoRedo(){
        editWindow.toolArea.editUndoButton.setSensitive(undoQueue.length >= 1);
        editWindow.toolArea.editRedoButton.setSensitive(redoQueue.length >= 1);
        editWindow.menuBar.menuItemUndo.setSensitive(undoQueue.length >= 1);
        editWindow.menuBar.menuItemRedo.setSensitive(redoQueue.length >= 1);
        changeExists = true;
        editWindow.setTitle(APPLICATION_NAME ~ " " ~ (projectPath is null ? "名称未設定" : projectPath) ~ " *");
    }
    void onUndo(){
        if(undoQueue.length >= 1){
            EditInfo editInfosTree[][] = undoQueue[$ - 1];
            redoQueue ~= editInfosTree;
            foreach_reverse(editInfos;editInfosTree){
                foreach(editInfo;editInfos){
                    LayerInfo layerInfo = layerInfos[editInfo.layerIndex];
                    int gridX = editInfo.layoutIndex % mapSizeH;
                    int gridY = editInfo.layoutIndex / mapSizeH;
                    layerInfo.ReplaceChip(gridX,gridY,editInfo.oldChipId);
                }
            }
            undoQueue = undoQueue[0..$ - 1];
            updateUndoRedo();
            editWindow.queueDraw();
            overviewWindow.queueDraw();
        }
    }
    void onRedo(){
        if(redoQueue.length >= 1){
            EditInfo editInfosTree[][] = redoQueue[$ - 1];
            undoQueue ~= editInfosTree;
            foreach_reverse(editInfos;editInfosTree){
                foreach(editInfo;editInfos){
                    LayerInfo layerInfo = layerInfos[editInfo.layerIndex];
                    int gridX = editInfo.layoutIndex % mapSizeH;
                    int gridY = editInfo.layoutIndex / mapSizeH;
                    layerInfo.ReplaceChip(gridX,gridY,editInfo.newChipId);
                }
            }
            redoQueue = redoQueue[0..$ - 1];
            updateUndoRedo();
            editWindow.queueDraw();
            overviewWindow.queueDraw();
        }
    }
    void onScrollChanged(){
        if(overviewWindow !is null){
            overviewWindow.queueDraw();
        }
    }
    static if(true){
        void onSyringeUsed(ClipBoardInfo clipBoard[]){
            LayerInfo layerInfo = currentLayerInfo;
            if(clipBoard.length == 1){
                layerInfo.SetSelectionByChipId(clipBoard[0].chipId);
                partsWindow.queueDraw();
            }else{
                // 複数マスが選択された場合はクリップボードに格納し、そのチップ群を描画するように。
                layerInfo.clipBoard = clipBoard;
                layerInfo.gridSelection = null;
                partsWindow.queueDraw();
            }
        }
    }else{
        void onSyringeUsed(int chipId){
            LayerInfo layerInfo = currentLayerInfo;
            layerInfo.SetSelectionByChipId(chipId);
            partsWindow.queueDraw();
        }
    }
    void onScrollCenterChanged(double centerX, double centerY){
        Adjustment adjustmentH = editWindow.editArea.getHadjustment();
        double x = (adjustmentH.getUpper() - adjustmentH.getLower()) * centerX - adjustmentH.getPageSize() / 2.0;
        adjustmentH.setValue(min(x, adjustmentH.getUpper() - adjustmentH.getPageSize()));
        Adjustment adjustmentV = editWindow.editArea.getVadjustment();
        double y = (adjustmentV.getUpper() - adjustmentV.getLower()) * centerY - adjustmentV.getPageSize() / 2.0;
        adjustmentV.setValue(min(y, adjustmentV.getUpper() - adjustmentV.getPageSize()));
    }
}
class GridSelection{
    int startGridX = 0;
    int startGridY = 0;
    int endGridX = 0;
    int endGridY = 0;
}
class LayerInfo{
    this(){
        gridSelection = new GridSelection();
    }
    this(string name, bool visible, string mapchipFilePath){
        this.name = name;
        this.visible = visible;
        this.mapchipFilePath = mapchipFilePath;
        gridSelection = new GridSelection();
    }
    ~this(){
		if(layoutPixbuf !is null){
            layoutPixbuf.unref();
            delete layoutPixbuf;
        }
		if(transparentPixbuf !is null){
            transparentPixbuf.unref();
            delete transparentPixbuf;
        }
    }
    string name = "layer";
    bool visible = true;
    string mapchipFilePath = null;
    int chipLayout[];
    Pixbuf layoutPixbuf;
    Pixbuf transparentPixbuf;
    GridSelection gridSelection = null;
    ClipBoardInfo clipBoard[];
    int GetClipBoardWidth(){
        int minValue,maxValue;
        if(clipBoard.length == 0){
            return 0;
        }
        foreach(tmp;clipBoard){
            minValue = min(tmp.offsetGridX, minValue);
            maxValue = max(tmp.offsetGridX, maxValue);
        }
        return maxValue - minValue + 1;
    }
    int GetClipBoardHeight(){
        int minValue,maxValue;
        if(clipBoard.length == 0){
            return 0;
        }
        foreach(tmp;clipBoard){
            minValue = min(tmp.offsetGridY, minValue);
            maxValue = max(tmp.offsetGridY, maxValue);
        }
        return maxValue - minValue + 1;
    }
    SerializableLayerInfo getSerializable(){
        SerializableLayerInfo ret = new SerializableLayerInfo();
        ret.name = name;
        ret.visible = visible;
        ret.mapchipFilePath = mapchipFilePath;
        ret.chipLayout = chipLayout;
        return ret;
    }
    void generateGridSelection(){
        gridSelection = new GridSelection();
    }
    void initBySerializable(SerializableLayerInfo serializableLayerInfo){
        printf("LayerInfo.initBySerializable %s\n",toMBSz(serializableLayerInfo.mapchipFilePath));
        name = serializableLayerInfo.name;
        visible = serializableLayerInfo.visible;
        mapchipFilePath = serializableLayerInfo.mapchipFilePath;
        chipLayout = serializableLayerInfo.chipLayout;
    }
    bool mapchipFileExists(){
        if(mapchipFilePath is null){
            return false;
        }
        if(!(mapchipFilePath in projectInfo.mapchipPixbufList)){
            return false;
        }
        return true;
    }
    void ReplaceChip(int gridX, int gridY, int newChipId){
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        if(newChipId < 0){
            transparentPixbuf.copyArea(0, 0, projectInfo.partsSizeH, projectInfo.partsSizeV, layoutPixbuf, gridX * projectInfo.partsSizeH, gridY * projectInfo.partsSizeV);
        }
        else{
            int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
            int newChipGridX = newChipId % mapchipDivNumH;
            int newChipGridY = newChipId / mapchipDivNumH;
            mapchip.copyArea(projectInfo.partsSizeH * newChipGridX, projectInfo.partsSizeV * newChipGridY, projectInfo.partsSizeH, projectInfo.partsSizeV, layoutPixbuf, gridX * projectInfo.partsSizeH, gridY * projectInfo.partsSizeV);
        }
        chipLayout[gridX + gridY * projectInfo.mapSizeH] = newChipId;
    }
    int GetChipId(int gridX, int gridY){
        return chipLayout[gridX + gridY * projectInfo.mapSizeH];
    }
    int GetChipIdInMapchip(int gridX, int gridY){
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
        return gridX + gridY * mapchipDivNumH;
    }
    void GetGridXYInMapchip(int chipId, out int gridX, out int gridY){
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
        gridX = chipId % mapchipDivNumH;
        gridY = chipId / mapchipDivNumH;
    }
    void CreateTransparentPixbuf(){
        if(transparentPixbuf !is null){
            transparentPixbuf.unref();
            delete transparentPixbuf;
        }
        transparentPixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH, projectInfo.partsSizeV);
        transparentPixbuf.fill(0x00000000);
    }
    void MapSizeChanged(int oldMapSizeH, int oldMapSizeV, EAnchor anchor){
        int oldChipLayout[] = chipLayout.dup;
        chipLayout.clear;
        chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
        chipLayout[0..length] = -1;
        // アンカー対応
        static if(true){
            int oldStartX,oldStartY;
            int newStartX,newStartY;
            int sizeX = min(projectInfo.mapSizeH, oldMapSizeH);
            int sizeY = min(projectInfo.mapSizeV, oldMapSizeV);
            // 横
            switch(anchor){
            case EAnchor.DIRECTION_1:
            case EAnchor.DIRECTION_4:
            case EAnchor.DIRECTION_7:
                oldStartX = newStartX = 0;
                break;
            case EAnchor.DIRECTION_2:
            case EAnchor.DIRECTION_5:
            case EAnchor.DIRECTION_8:
                oldStartX = (oldMapSizeH - 1) - min(oldMapSizeH - 1, projectInfo.mapSizeH - 1);
                newStartX = (projectInfo.mapSizeH - 1) - min(oldMapSizeH - 1, projectInfo.mapSizeH - 1);
                if(oldStartX > 0){
                    oldStartX /= 2;
                }
                if(newStartX > 0){
                    newStartX /= 2;
                }
                break;
            case EAnchor.DIRECTION_3:
            case EAnchor.DIRECTION_6:
            case EAnchor.DIRECTION_9:
                oldStartX = (oldMapSizeH - 1) - min(oldMapSizeH - 1, projectInfo.mapSizeH - 1);
                newStartX = (projectInfo.mapSizeH - 1) - min(oldMapSizeH - 1, projectInfo.mapSizeH - 1);
                break;
            }
            // 縦
            switch(anchor){
            case EAnchor.DIRECTION_7:
            case EAnchor.DIRECTION_8:
            case EAnchor.DIRECTION_9:
                oldStartY = newStartY = 0;
                break;
            case EAnchor.DIRECTION_4:
            case EAnchor.DIRECTION_5:
            case EAnchor.DIRECTION_6:
                oldStartY = (oldMapSizeV - 1) - min(oldMapSizeV - 1, projectInfo.mapSizeV - 1);
                newStartY = (projectInfo.mapSizeV - 1) - min(oldMapSizeV - 1, projectInfo.mapSizeV - 1);
                if(oldStartY > 0){
                    oldStartY /= 2;
                }
                if(newStartY > 0){
                    newStartY /= 2;
                }
                break;
            case EAnchor.DIRECTION_1:
            case EAnchor.DIRECTION_2:
            case EAnchor.DIRECTION_3:
                oldStartY = (oldMapSizeV - 1) - min(oldMapSizeV - 1, projectInfo.mapSizeV - 1);
                newStartY = (projectInfo.mapSizeV - 1) - min(oldMapSizeV - 1, projectInfo.mapSizeV - 1);
                break;
            }
            for(int oldY = oldStartY, newY = newStartY, countY = 0 ; countY < sizeY ; ++ oldY, ++ newY, ++ countY){
                for(int oldX = oldStartX, newX = newStartX, countX = 0 ; countX < sizeX ; ++ oldX, ++ newX, ++ countX){
                    int oldLayoutIndex = oldX + oldY * oldMapSizeH;
                    int newLayoutIndex = newX + newY * projectInfo.mapSizeH;
                    chipLayout[newLayoutIndex] = oldChipLayout[oldLayoutIndex];
                }
            }
        }else{
            for(int gridY = 0 ; gridY < min(oldMapSizeV, projectInfo.mapSizeV) ; ++ gridY){
                for(int gridX = 0 ; gridX < min(oldMapSizeH, projectInfo.mapSizeH) ; ++ gridX){
                    int oldLayoutIndex = gridX + gridY * oldMapSizeH;
                    int newLayoutIndex = gridX + gridY * projectInfo.mapSizeH;
                    chipLayout[newLayoutIndex] = oldChipLayout[oldLayoutIndex];
                }
            }
        }
        layoutPixbuf = CreatePixbufFromLayout(this);
    }
    void SetSelectionByChipId(int chipId){
        clipBoard.clear;
        if(!mapchipFileExists){
            return;
        }
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
        int mapchipDivNumV = cast(int)mapchip.getHeight() / projectInfo.partsSizeV;
        bool found = false;
        for(int gridY = 0 ; gridY < mapchipDivNumV ; ++ gridY){
            for(int gridX = 0 ; gridX < mapchipDivNumH ; ++ gridX){
                if(chipId == GetChipIdInMapchip(gridX, gridY)){
                    if(gridSelection is null){
                        gridSelection = new GridSelection();
                    }
                    gridSelection.startGridX = gridSelection.endGridX = gridX;
                    gridSelection.startGridY = gridSelection.endGridY = gridY;
                    found = true;
                }
            }
        }
        if(!found){
            gridSelection = null;
        }
    }
    void Reset(){
        gridSelection = new GridSelection();
        chipLayout.clear;
        chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
        chipLayout[0..length] = -1;
        CreateTransparentPixbuf();
        if(layoutPixbuf !is null){
            layoutPixbuf.unref();
            delete layoutPixbuf;
        }
        layoutPixbuf = CreatePixbufFromLayout(this);
    }
}

class SerializableProjectInfo{
    int mapSizeH = 20;
    int mapSizeV = 20;
    int partsSizeH = 16;
    int partsSizeV = 16;
    int exportStartGridX = 0;
    int exportStartGridY = 0;
    int exportEndGridX = 20 - 1;
    int exportEndGridY = 20 - 1;
    int grid1Color = 0xAAAAAA;
    int grid1Type = EGridType.NORMAL;
    int grid1Interval = 1;
    string projectPath = null;
    SerializableLayerInfo layerInfos[];
    void describe(T)(T ar){
        ar.describe(mapSizeH);
        ar.describe(mapSizeV);
        ar.describe(partsSizeH);
        ar.describe(partsSizeV);
        ar.describe(layerInfos);
        ar.describe(projectPath);
        ar.describe(exportStartGridX);
        ar.describe(exportStartGridY);
        ar.describe(exportEndGridX);
        ar.describe(exportEndGridY);
        ar.describe(grid1Color);
        ar.describe(grid1Type);
        ar.describe(grid1Interval);
    }
}

class SerializableLayerInfo{
    string name;
    bool visible;
    string mapchipFilePath;
    int chipLayout[];
    void describe(T)(T ar){
        ar.describe(name);
        ar.describe(visible);
        ar.describe(mapchipFilePath);
        ar.describe(chipLayout);
    }
}

class SerializableBaseInfo{
    string lastProjectPath;
    string lastImportCsvPath;
    string lastExportCsvPath;
    string lastMapchipPath;
    SerializableWindowInfo editWindowInfo;
    SerializableWindowInfo partsWindowInfo;
    SerializableWindowInfo layerWindowInfo;
    SerializableWindowInfo overviewWindowInfo;
    this(){
        editWindowInfo = new SerializableWindowInfo();
        editWindowInfo.x = 0;
        editWindowInfo.y = 0;
        editWindowInfo.width = 240;
        editWindowInfo.height = 240;
        layerWindowInfo = new SerializableWindowInfo();
        layerWindowInfo.x = 240 * 0;
        layerWindowInfo.y = 240;
        layerWindowInfo.width = 240;
        layerWindowInfo.height = 240;
        overviewWindowInfo = new SerializableWindowInfo();
        overviewWindowInfo.x = 240 * 1;
        overviewWindowInfo.y = 240;
        overviewWindowInfo.width = 240;
        overviewWindowInfo.height = 240;
        partsWindowInfo = new SerializableWindowInfo();
        partsWindowInfo.x = 240 * 2;
        partsWindowInfo.y = 240;
        partsWindowInfo.width = 240;
        partsWindowInfo.height = 240;
    }
    void describe(T)(T ar){
        ar.describe(lastProjectPath);
        ar.describe(lastImportCsvPath);
        ar.describe(lastExportCsvPath);
        ar.describe(lastMapchipPath);
        ar.describe(editWindowInfo);
        ar.describe(partsWindowInfo);
        ar.describe(layerWindowInfo);
        ar.describe(overviewWindowInfo);
    }
}

class SerializableWindowInfo{
    int x;
    int y;
    int width;
    int height;
    void describe(T)(T ar){
        ar.describe(x);
        ar.describe(y);
        ar.describe(width);
        ar.describe(height);
    }
 }