module project_info;
private import imports.all;
private import main;
private import gui.edit_window;
private import gui.layer_window;
private import gui.parts_window;
private import gui.overview_window;

enum EWindowType{
    EDIT,
    LAYER,
    PARTS,
    OVERVIEW,
}

struct ChipReplaceInfo{
    int gridX;
    int gridY;
    int newChipGridX;
    int newChipGridY;
    this(int gridX,int gridY,int newChipGridX,int newChipGridY){
        this.gridX = gridX;
        this.gridY = gridY;
        this.newChipGridX = newChipGridX;
        this.newChipGridY = newChipGridY;
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
    string projectPath = null;
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
        foreach(layerInfo;layerInfos){
            ret.layerInfos ~= layerInfo.getSerializable();
        }
		return ret;
    }
    void initBySerializable(SerializableProjectInfo serializableProjectInfo){
        mapSizeH = serializableProjectInfo.mapSizeH;
        mapSizeV = serializableProjectInfo.mapSizeV;
        partsSizeH = serializableProjectInfo.partsSizeH;
        partsSizeV = serializableProjectInfo.partsSizeV;
        projectPath = serializableProjectInfo.projectPath;
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
        foreach(layerInfo;layerInfos){
            printf("[%x] ProjectInfo.initBySerializable 4 %s\n",layerInfo,toMBSz(layerInfo.mapchipFilePath));
            AddMapchipFile(layerInfo.mapchipFilePath);
            layerInfo.CreateTransparentPixbuf();
            layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
        }
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
        this.editWindow.onCsvLoadedFunction = &onCsvLoaded;
        this.editWindow.onChipReplacedFunction = &onChipReplaced;
        this.editWindow.onSelectionMovedFunction = &onSelectionMoved;
        this.editWindow.onChipReplaceCompletedFunction = &onChipReplaceCompleted;
        this.editWindow.onUndoFunction = &onUndo;
        this.editWindow.onRedoFunction = &onRedo;
        this.editWindow.onScrollChangedFunction = &onScrollChanged;
    }
    void SetLayerWindow(LayerWindow layerWindow){
        this.layerWindow = layerWindow;
        this.layerWindow.onSelectedLayerChangedFunction = &onSelectedLayerChanged;
        this.layerWindow.onLayerVisibilityChangedFunction = &onLayerVisibilityChanged;
        this.layerWindow.onLayerAddedFunction = &onLayerAdded;
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
        LayerInfo layerInfo = new LayerInfo("レイヤー2", true, "dat/sample/mapchip256_b.png");
        layerInfo.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
        layerInfo.chipLayout[0..length] = -1;
        AddMapchipFile("dat/sample/mapchip256_b.png");
        layerInfo.CreateTransparentPixbuf();
        layerInfo.layoutPixbuf = CreatePixbufFromLayout(layerInfo);
        layerInfos ~= layerInfo;
        layerWindow.Reload();
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
    void onMapSizeChanged(int mapSizeH, int mapSizeV){
        int oldMapSizeH = this.mapSizeH;
        int oldMapSizeV = this.mapSizeV;
        this.mapSizeH = mapSizeH;
        this.mapSizeV = mapSizeV;
        foreach(layerInfo;layerInfos){
            layerInfo.MapSizeChanged(oldMapSizeH, oldMapSizeV);
        }
        editWindow.queueDraw();
        overviewWindow.Reload();
    }
    void onCsvLoaded(CsvProjectInfo info){
        mapSizeH = info.mapSizeH;
        mapSizeV = info.mapSizeV;
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
        int oldStartGridX = layerInfo.gridSelection.startGridX;
        int oldStartGridY = layerInfo.gridSelection.startGridY;
        int oldEndGridX = layerInfo.gridSelection.endGridX;
        int oldEndGridY = layerInfo.gridSelection.endGridY;
        layerInfo.gridSelection.startGridX = cast(int)(startX / partsSizeH);
        layerInfo.gridSelection.startGridY = cast(int)(startY / partsSizeV);
        layerInfo.gridSelection.endGridX = cast(int)(endX / partsSizeH);
        layerInfo.gridSelection.endGridY = cast(int)(endY / partsSizeV);
        // グリッド座標が変わっていない場合は再描画必要ない
        if(oldStartGridX != layerInfo.gridSelection.startGridX || oldStartGridY != layerInfo.gridSelection.startGridY || oldEndGridX != layerInfo.gridSelection.endGridX || oldEndGridY != layerInfo.gridSelection.endGridY){
            editWindow.UpdateGuide();
            editWindow.queueDraw();
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
        printf("onChipReplaced 1\n");
        EditInfo editInfos[];
        LayerInfo layerInfo = currentLayerInfo;
        foreach(chipReplaceInfo;chipReplaceInfos){
            with(chipReplaceInfo){
                int oldChipId = layerInfo.GetChipId(gridX, gridY);
                Pixbuf mapchip = mapchipPixbufList[layerInfo.mapchipFilePath];
                int mapchipDivNumH = cast(int)mapchip.getWidth() / partsSizeH;
                int newChipId = newChipGridX + newChipGridY * mapchipDivNumH;
                int layoutIndex = gridX + gridY * mapSizeH;
                editInfos ~= EditInfo(currentLayerIndex,layoutIndex,oldChipId,newChipId);
                layerInfo.ReplaceChip(gridX,gridY,newChipId);
            }
        }
        tmpEditInfosTree ~= editInfos;
        editWindow.queueDraw();
        overviewWindow.queueDraw();
        printf("onChipReplaced 2\n");
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
        }
    }
    void onScrollChanged(){
        if(overviewWindow !is null){
            overviewWindow.queueDraw();
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
class LayerInfo{
    class GridSelection{
        int startGridX = 0;
        int startGridY = 0;
        int endGridX = 0;
        int endGridY = 0;
    }
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
    SerializableLayerInfo getSerializable(){
        SerializableLayerInfo ret = new SerializableLayerInfo();
        ret.name = name;
        ret.visible = visible;
        ret.mapchipFilePath = mapchipFilePath;
        ret.chipLayout = chipLayout;
        return ret;
    }
    void initBySerializable(SerializableLayerInfo serializableLayerInfo){
        printf("LayerInfo.initBySerializable %s\n",toMBSz(serializableLayerInfo.mapchipFilePath));
        name = serializableLayerInfo.name;
        visible = serializableLayerInfo.visible;
        mapchipFilePath = serializableLayerInfo.mapchipFilePath;
        chipLayout = serializableLayerInfo.chipLayout;
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
    void CreateTransparentPixbuf(){
        if(transparentPixbuf !is null){
            transparentPixbuf.unref();
            delete transparentPixbuf;
        }
        transparentPixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH, projectInfo.partsSizeV);
        transparentPixbuf.fill(0x00000000);
    }
    void MapSizeChanged(int oldMapSizeH, int oldMapSizeV){
        int oldChipLayout[] = chipLayout.dup;
        chipLayout.clear;
        chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
        chipLayout[0..length] = -1;
        for(int gridY = 0 ; gridY < min(oldMapSizeV, projectInfo.mapSizeV) ; ++ gridY){
            for(int gridX = 0 ; gridX < min(oldMapSizeH, projectInfo.mapSizeH) ; ++ gridX){
                int oldLayoutIndex = gridX + gridY * oldMapSizeH;
                int newLayoutIndex = gridX + gridY * projectInfo.mapSizeH;
                chipLayout[newLayoutIndex] = oldChipLayout[oldLayoutIndex];
            }
        }
        layoutPixbuf = CreatePixbufFromLayout(this);
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
    string projectPath = null;
   SerializableLayerInfo layerInfos[];
    void describe(T)(T ar){
        ar.describe(mapSizeH);
        ar.describe(mapSizeV);
        ar.describe(partsSizeH);
        ar.describe(partsSizeV);
        ar.describe(layerInfos);
        ar.describe(projectPath);
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