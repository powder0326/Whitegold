module gui.edit_window;

import imports.all;
import main;
import project_info;
import dialog.new_project_dialog;

/**
   エディット用ウインドウ

   マップチップを配置していくウインドウ。このウインドウはアプリ起動時に開かれ、アプリを終了するまで閉じない。
 */
class EditWindow : MainWindow{
    void delegate() onHideFunction;
    void delegate(EWindowType windowType, bool show) onWindowShowHideFunction;
    void delegate(int,int,int,int) onMapSizeAndPartsSizeChangedFunction;
    void delegate(CsvProjectInfo) onCsvLoadedFunction;
    EditWindowEditArea editArea = null;
    this(){
        super("エディットウインドウ");
//         setSizeRequest(320, 320);
        setDefaultSize(240, 240);
        setIcon(new Pixbuf("dat/icon/application--pencil.png"));
        VBox mainBox = new VBox(false,0);
		mainBox.packStart(new EditWindowMenubar(),false,false,0);
		mainBox.packStart(new EditWindowToolArea(),false,false,0);
        editArea = new EditWindowEditArea();
		mainBox.packStart(editArea,true,true,0);
		mainBox.packStart(new EditWindowStatusbarArea(),false,false,0);
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
            Button editUndoButton = new Button();
            editUndoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return-180-left.png")));
            packStart(editUndoButton , false, false, 2 );
            Button editRedoButton = new Button();
            editRedoButton.setImage(new Image(new Pixbuf("dat/icon/arrow-return.png")));
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
            penButton.setActive(1);
            // 区切り線
            packStart(new VSeparator() , false, false, 4 );
            // グリッド関連
            ToggleButton gridButton = new ToggleButton();
            gridButton.setImage(new Image(new Pixbuf("dat/icon/grid.png")));
            packStart(gridButton , false, false, 2 );
        }
        void onDrawButtonToggled(ToggleButton toggleButton){
            if(toggleButton is penButton){
                if(penButton.getActive()){
                    if(!penButtonDownBySelf){
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
            this(){
                super();
                addOnExpose(&exposeCallback);
                setSizeRequest(projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
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
                return true;
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

