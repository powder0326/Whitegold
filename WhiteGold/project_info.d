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

class ProjectInfo{
    int mapSizeH = 20;
    int mapSizeV = 20;
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
    }
    void onSelectedLayerChanged(int index){
        currentLayerIndex = index;
        partsWindow.Reload();
    }
    void onLayerVisibilityChanged(int index, bool visible){
        layerInfos[index].visible = visible;
        editWindow.Reload();
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
        normalLayerInfo.gridSelection.startGridX = cast(int)(startX / partsSizeH);
        normalLayerInfo.gridSelection.startGridY = cast(int)(startY / partsSizeV);
        normalLayerInfo.gridSelection.endGridX = cast(int)(endX / partsSizeH);
        normalLayerInfo.gridSelection.endGridY = cast(int)(endY / partsSizeV);
        partsWindow.queueDraw();
    }
    void onChipReplaced(ChipReplaceInfo[] chipReplaceInfos){
        NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)currentLayerInfo;
        foreach(chipReplaceInfo;chipReplaceInfos){
            with(chipReplaceInfo){
                normalLayerInfo.ReplaceChip(gridX,gridY,newChipGridX,newChipGridY);
            }
        }
        editWindow.queueDraw();
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
    void ReplaceChip(int gridX, int gridY, int newChipGridX, int newChipGridY){
        Pixbuf mapchip = projectInfo.mapchipPixbufList[mapchipFilePath];
        mapchip.copyArea(projectInfo.partsSizeH * newChipGridX, projectInfo.partsSizeV * newChipGridY, projectInfo.partsSizeH, projectInfo.partsSizeV, layoutPixbuf, gridX * projectInfo.partsSizeH, gridY * projectInfo.partsSizeV);
        int mapchipDivNumH = cast(int)mapchip.getWidth() / projectInfo.partsSizeH;
        chipLayout[gridX + gridY * projectInfo.mapSizeH] = newChipGridX + newChipGridY * mapchipDivNumH;
    }
private:
    string name_ = "layer";
    bool visible_ = true;
}

