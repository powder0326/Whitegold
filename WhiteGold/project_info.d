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
    }
    void SetLayerWindow(LayerWindow layerWindow){
        this.layerWindow = layerWindow;
        this.layerWindow.onSelectedLayerChangedFunction = &onSelectedLayerChanged;
        this.layerWindow.onLayerVisibilityChangedFunction = &onLayerVisibilityChanged;
    }
    void SetPartsWindow(PartsWindow partsWindow){
        this.partsWindow = partsWindow;
        this.partsWindow.onMapchipFileLoadedFunction = &onMapchipFileLoaded;
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
    this(string name, bool visible, string mapchipFilePath){
        this.name_ = name;
        this.visible_ = visible;
        this.mapchipFilePath = mapchipFilePath;
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
private:
    string name_ = "layer";
    bool visible_ = true;
}

