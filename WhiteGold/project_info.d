module project_info;
private import imports.all;
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
    int horizontalNum = 20;
    int verticalNum = 20;
    int cellSize = 16;
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
    }
    void SetLayerWindow(LayerWindow layerWindow){
        this.layerWindow = layerWindow;
        this.layerWindow.onSelectedLayerChangedFunction = &onSelectedLayerChanged;
    }
    void SetPartsWindow(PartsWindow partsWindow){
        this.partsWindow = partsWindow;
    }
    void SetOverviewWindow(OverviewWindow overviewWindow){
        this.overviewWindow = overviewWindow;
    }
    void onSelectedLayerChanged(int index){
        currentLayerIndex = index;
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
    string name(){
        return name_;
    }
    void name(string value){
        return name_ = value;
    }
    bool visible(){
        return visible_;
    }
    void visible(bool value){
        return visible_ = value;
    }
    string mapchipFilePath = "";
private:
    string name_ = "layer";
    bool visible_ = true;
}

