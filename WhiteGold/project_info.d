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
    int mapSizeH = 10;
    int mapSizeV = 10;
    int partsSizeH = 16;
    int partsSizeV = 16;
    // レイヤー関連
    int currentLayerIndex = 0;
    LayerInfoBase layerInfos[];
    LayerInfoBase currentLayerInfo(){
        return layerInfos[currentLayerIndex];
    }
    // マップチップ関連
    Pixbuf[string] mapchipPixbufList;
    void AddMapchipFile(string mapchipFilePath){
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
    // 各種処理関数
    void SetEditWindow(EditWindow editWindow){
        this.editWindow = editWindow;
        this.editWindow.onHideFunction = &onHideEditWindow;
        this.editWindow.onWindowShowHideFunction = &onWindowShowHide;
        this.editWindow.onMapSizeAndPartsSizeChangedFunction = &onMapSizeAndPartsSizeChanged;
        this.editWindow.onCsvLoadedFunction = &onCsvLoaded;
        this.editWindow.onChipReplacedFunction = &onChipReplaced;
        this.editWindow.onChipReplaceCompletedFunction = &onChipReplaceCompleted;
        this.editWindow.onUndoFunction = &onUndo;
        this.editWindow.onRedoFunction = &onRedo;
        this.editWindow.onScrollChangedFunction = &onScrollChanged;
    }
    void SetLayerWindow(LayerWindow layerWindow){
        this.layerWindow = layerWindow;
        this.layerWindow.onSelectedLayerChangedFunction = &onSelectedLayerChanged;
        this.layerWindow.onLayerVisibilityChangedFunction = &onLayerVisibilityChanged;
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
    }
    void onLayerVisibilityChanged(int index, bool visible){
        layerInfos[index].visible = visible;
        editWindow.queueDraw();
        overviewWindow.queueDraw();
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
    void onMapSizeAndPartsSizeChanged(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
        this.mapSizeH = mapSizeH;
        this.mapSizeV = mapSizeV;
        this.partsSizeH = partsSizeH;
        this.partsSizeV = partsSizeV;
        editWindow.Reload();
    }
    void onCsvLoaded(CsvProjectInfo info){
        mapSizeH = info.mapSizeH;
        mapSizeV = info.mapSizeV;
        partsSizeH = info.partsSizeH;
        partsSizeV = info.partsSizeV;
        layerInfos.clear;
        foreach(i,chipLayout;info.chipLayouts){
            NormalLayerInfo normalLayerInfo = new NormalLayerInfo(format("レイヤー%d",i), true, "");
            normalLayerInfo.chipLayout = chipLayout;
            layerInfos ~= normalLayerInfo;
        }
        editWindow.Reload();
        partsWindow.Reload();
        layerWindow.Reload();
        overviewWindow.Reload();
    }
    void onMapchipFileLoaded(string mapchipFilePath){
        AddMapchipFile(mapchipFilePath);
        NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)currentLayerInfo;
        normalLayerInfo.mapchipFilePath = mapchipFilePath;
        normalLayerInfo.layoutPixbuf = CreatePixbufFromLayout(currentLayerIndex);
        partsWindow.Reload();
        editWindow.Reload();
        overviewWindow.Reload();
    }
    void onSelectionChanged(double startX, double startY, double endX, double endY){
        NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)currentLayerInfo;
        int oldStartGridX = normalLayerInfo.gridSelection.startGridX;
        int oldStartGridY = normalLayerInfo.gridSelection.startGridY;
        int oldEndGridX = normalLayerInfo.gridSelection.endGridX;
        int oldEndGridY = normalLayerInfo.gridSelection.endGridY;
        normalLayerInfo.gridSelection.startGridX = cast(int)(startX / partsSizeH);
        normalLayerInfo.gridSelection.startGridY = cast(int)(startY / partsSizeV);
        normalLayerInfo.gridSelection.endGridX = cast(int)(endX / partsSizeH);
        normalLayerInfo.gridSelection.endGridY = cast(int)(endY / partsSizeV);
        // グリッド座標が変わっていない場合は再描画必要ない
        if(oldStartGridX != normalLayerInfo.gridSelection.startGridX || oldStartGridY != normalLayerInfo.gridSelection.startGridY || oldEndGridX != normalLayerInfo.gridSelection.endGridX || oldEndGridY != normalLayerInfo.gridSelection.endGridY){
            partsWindow.queueDraw();
        }
    }
    /**
       ある場所のチップのIndexを入れ替えてPixbufも更新。

       tmpEditInfosTreeに入れ替え履歴を入れるが、undoQueueへの代入はonChipReplaceCompletedが呼ばれるまで待つ。これは1ストローク分の履歴を1回のUndoで戻せるようにしたいため。
     */
    EditInfo tmpEditInfosTree[][];
    void onChipReplaced(ChipReplaceInfo[] chipReplaceInfos){
        EditInfo editInfos[];
        NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)currentLayerInfo;
        foreach(chipReplaceInfo;chipReplaceInfos){
            with(chipReplaceInfo){
                int oldChipId = normalLayerInfo.GetChipId(gridX, gridY);
                Pixbuf mapchip = mapchipPixbufList[normalLayerInfo.mapchipFilePath];
                int mapchipDivNumH = cast(int)mapchip.getWidth() / partsSizeH;
                int newChipId = newChipGridX + newChipGridY * mapchipDivNumH;
                int layoutIndex = gridX + gridY * mapSizeH;
                editInfos ~= EditInfo(currentLayerIndex,layoutIndex,oldChipId,newChipId);
                normalLayerInfo.ReplaceChip(gridX,gridY,newChipId);
            }
        }
        tmpEditInfosTree ~= editInfos;
        editWindow.queueDraw();
        overviewWindow.queueDraw();
    }
    /**
       チップの入れ替え確定

       tmpEditInfosの内容をundoQueueに反映する。
       */
    void onChipReplaceCompleted(){
        undoQueue ~= tmpEditInfosTree;
        redoQueue.clear;
        tmpEditInfosTree.clear;
        updateUndoRedo();
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
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)layerInfos[editInfo.layerIndex];
                    int gridX = editInfo.layoutIndex % mapSizeH;
                    int gridY = editInfo.layoutIndex / mapSizeH;
                    normalLayerInfo.ReplaceChip(gridX,gridY,editInfo.oldChipId);
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
                    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)layerInfos[editInfo.layerIndex];
                    int gridX = editInfo.layoutIndex % mapSizeH;
                    int gridY = editInfo.layoutIndex / mapSizeH;
                    normalLayerInfo.ReplaceChip(gridX,gridY,editInfo.newChipId);
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
enum ELayerType{
    NORMAL,
    JSON,
}
abstract class LayerInfoBase{
    abstract ELayerType type();
    abstract string name();
    abstract void name(string value);
    abstract bool visible();
    abstract void visible(bool value);
}
class NormalLayerInfo : LayerInfoBase{
    class GridSelection{
        int startGridX = 0;
        int startGridY = 0;
        int endGridX = 0;
        int endGridY = 0;
    }
    this(string name, bool visible, string mapchipFilePath){
        this.name_ = name;
        this.visible_ = visible;
        this.mapchipFilePath = mapchipFilePath;
        gridSelection = new GridSelection();
    }
    override ELayerType type(){
        return ELayerType.NORMAL;
    }
    override string name(){
        return name_;
    }
    override void name(string value){
        name_ = value;
    }
    override bool visible(){
        return visible_;
    }
    override void visible(bool value){
        visible_ = value;
    }
    string mapchipFilePath = "";
    int chipLayout[];
    Pixbuf layoutPixbuf;
    GridSelection gridSelection = null;
    void ReplaceChip(int gridX, int gridY, int newChipId){
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
        int newChipGridX = newChipId % mapchipDivNumH;
        int newChipGridY = newChipId / mapchipDivNumH;
        mapchip.copyArea(projectInfo.partsSizeH * newChipGridX, projectInfo.partsSizeV * newChipGridY, projectInfo.partsSizeH, projectInfo.partsSizeV, layoutPixbuf, gridX * projectInfo.partsSizeH, gridY * projectInfo.partsSizeV);
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
private:
    string name_ = "layer";
    bool visible_ = true;
}

