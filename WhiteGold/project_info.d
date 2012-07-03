module project_info;

class ProjectInfo{
    int horizontalNum = 20;
    int verticalNum = 20;
    int cellSize = 16;
    LayerInfoBase layerInfos[];
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

