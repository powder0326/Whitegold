/*
  GTKの参考ページ
  ■HBox,VBox
  http://www.kmc.gr.jp/~ranran/memo/gtk.1998-1.html
  
  ■SpinButton関連
  http://www.geocities.jp/tiplinux/gtk/gtk_spin_button.html
  http://book.geocities.jp/gtkmm_ja/docs/tutorial/html/sec-spinbutton.html
 */

module main;

private import imports.all;
private import project_info;
private import gui.edit_window;
private import gui.parts_window;
private import gui.layer_window;
private import gui.overview_window;

SerializableBaseInfo baseInfo = null;
ProjectInfo projectInfo = null;

int main(string[] argv){
    Serializer.registerClassConstructor!(SerializableProjectInfo)({ return new SerializableProjectInfo(); });
    Serializer.registerClassConstructor!(SerializableLayerInfo)({ return new SerializableLayerInfo(); });
    Serializer.registerClassConstructor!(SerializableBaseInfo)({ return new SerializableBaseInfo(); });
    Serializer.registerClassConstructor!(SerializableWindowInfo)({ return new SerializableWindowInfo(); });
    Main.init(argv);
    projectInfo = new ProjectInfo();
    if(std.file.exists("setting.dat")){
        SerializableProjectInfo serializableProjectInfo;
        Serializer s = new Serializer("setting.dat", FileMode.In);
        s.describe(baseInfo);
        delete s;
    }else{
        baseInfo = new SerializableBaseInfo();
    }
//         LayerInfo layerInfo1 = new LayerInfo("レイヤー0", true, "dat/sample/mapchip256_a.png");
    LayerInfo layerInfo1 = new LayerInfo("レイヤー0", true, null);
    projectInfo.layerInfos ~= layerInfo1;
    layerInfo1.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
    layerInfo1.chipLayout[0..length] = -1;
//         projectInfo.AddMapchipFile("dat/sample/mapchip256_a.png");
    layerInfo1.CreateTransparentPixbuf();
    layerInfo1.layoutPixbuf = CreatePixbufFromLayout(layerInfo1);

//         NormalLayerInfo layerInfo2 = new NormalLayerInfo("レイヤー2", true, "dat/sample/mapchip256_b.png");
//         projectInfo.layerInfos ~= layerInfo2;
//         layerInfo2.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
//         layerInfo2.chipLayout[0..length] = -1;
//         projectInfo.AddMapchipFile("dat/sample/mapchip256_b.png");
//         layerInfo2.CreateTransparentPixbuf();
//         layerInfo2.layoutPixbuf = CreatePixbufFromLayout(layerInfo2);
    EditWindow editWindow = new EditWindow();
    projectInfo.SetEditWindow(editWindow);
    editWindow.showAll();
    PartsWindow partsWindow = new PartsWindow();
    projectInfo.SetPartsWindow(partsWindow);
    partsWindow.showAll();
    LayerWindow layerWindow = new LayerWindow();
    projectInfo.SetLayerWindow(layerWindow);
    layerWindow.showAll();
    OverviewWindow overviewWindow = new OverviewWindow();
    projectInfo.SetOverviewWindow(overviewWindow);
    overviewWindow.showAll();
    Main.run();
    // 設定保存
    {
        Serializer s = new Serializer("setting.dat", FileMode.Out);
        s.describe(baseInfo);
        delete s;
    }
    return 0;
}

// Todo! これはNormalLayerInfoクラス自身に持たせよう
Pixbuf CreatePixbufFromLayout(LayerInfo layerInfo){
    Pixbuf ret = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
    if(layerInfo.mapchipFilePath is null){
        ret.fill(0x00000000);
        return ret;
    }
    Pixbuf mapChip = projectInfo.mapchipPixbufList[layerInfo.mapchipFilePath];
    int chipLayout[] = layerInfo.chipLayout;
    // マップチップの横分割数
    int chipDivNumH = mapChip.getWidth() / projectInfo.partsSizeH;
    // 透明Pixbuf

    for(int y = 0 ; y < projectInfo.mapSizeV ; ++ y){
        for(int x = 0 ; x < projectInfo.mapSizeH ; ++ x){
            int chipIndex = layerInfo.chipLayout[x + y * projectInfo.mapSizeH];
            if(chipIndex < 0){
                layerInfo.transparentPixbuf.copyArea(0, 0, projectInfo.partsSizeH, projectInfo.partsSizeV, ret, x * projectInfo.partsSizeH, y * projectInfo.partsSizeV);
            }else{
                int chipSrcOffsetX = chipIndex % chipDivNumH;
                int chipSrcOffsetY = chipIndex / chipDivNumH;
                mapChip.copyArea(projectInfo.partsSizeH * chipSrcOffsetX, projectInfo.partsSizeV * chipSrcOffsetY, projectInfo.partsSizeH, projectInfo.partsSizeV, ret, x * projectInfo.partsSizeH, y * projectInfo.partsSizeV);
            }
        }
    }
    return ret;
}

struct CsvProjectInfo{
    int mapSizeH,mapSizeV,partsSizeH,partsSizeV,layerNum;
    int chipLayouts[][];
}
// dmd.2.053ってまだTuple返せないのね……
CsvProjectInfo ParseCsv(string csvFilePath){
    int mapSizeH,mapSizeV,partsSizeH,partsSizeV,layerNum;
    int chipLayouts[][];
    void ReadProjectInfo(string projectInfoText){
        string splited[] = projectInfoText.split(",");
        mapSizeH = std.conv.to!(int)(splited[0]);
        mapSizeV = std.conv.to!(int)(splited[1]);
        partsSizeH = std.conv.to!(int)(splited[2]);
        partsSizeV = std.conv.to!(int)(splited[3]);
        layerNum = std.conv.to!(int)(splited[4]);
        printf("ReadProjectInfo %d,%d,%d,%d,%d\n",mapSizeH,mapSizeV,partsSizeH,partsSizeV,layerNum);
    }
    string readedText = std.file.readText(csvFilePath);
    string texts[];
    if(count(readedText, "\r\n") == 0){
        texts = readedText.split("\n");
    }else{
        texts = readedText.split("\r\n");
    }
    printf("1 texts.length = %d\n",texts.length);
    // 最初の一行目がプロジェクト情報領域
    string projectInfoText = texts[0];
    ReadProjectInfo(projectInfoText);
    texts = texts[1..$];
    printf("2 texts.length = %d\n",texts.length);
    // それぞれのレイヤーのテキスト取得
    int chipLayout[];
    int appendCount = 0;
    foreach(text;texts){
        string splited[] = text.split(",");
        foreach(tmp;splited){
            chipLayout ~= std.conv.to!(int)(tmp);
            ++ appendCount;
            // 現在のレイヤー分は格納し終わったので次のレイヤー分取得開始
            if(appendCount >= mapSizeH * mapSizeV){
                chipLayouts ~= chipLayout;
                chipLayout.clear;
                appendCount = 0;
            }
        }
    }
    CsvProjectInfo ret;
    ret.mapSizeH = mapSizeH;
    ret.mapSizeV = mapSizeV;
    ret.partsSizeH = partsSizeH;
    ret.partsSizeV = partsSizeV;
    ret.chipLayouts = chipLayouts;
    return ret;
}
string ExportCsv(ProjectInfo projectInfo){
    string ret;
    with(projectInfo){
        ret ~= format("%d,%d,%d,%d,%d\r\n",mapSizeH,mapSizeV,partsSizeH,partsSizeV,layerInfos.length);
        foreach(layerInfo;layerInfos){
            for(int gridY = 0 ; gridY < mapSizeV ; ++gridY){
                for(int gridX = 0 ; gridX < mapSizeH ; ++gridX){
                    int index = gridX + gridY * mapSizeH;
                    if(gridX == mapSizeH - 1){
                        ret ~= format("%d",layerInfo.chipLayout[index]);
                    }else{
                        ret ~= format("%d,",layerInfo.chipLayout[index]);
                    }
                }
                ret ~= "\r\n";
            }
            ret ~= "\r\n";
        }
    }
	return ret;
}
Pixbuf CreateGridPixbuf(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
    long time = std.datetime.Clock.currStdTime();
    Pixbuf gridPixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, partsSizeH * mapSizeH, partsSizeV * mapSizeV);
    gridPixbuf.fill(0x00000000);
    char* pixels = gridPixbuf.getPixels();
    int length = mapSizeH * mapSizeV * partsSizeH * partsSizeV * 4;
    void DrawHorizontalLine(int x1, int x2, int y, int color, bool dotted){
        for(int x = x1 ; x <= x2 ; ++ x){
            if(dotted){
                if((x + 2) % 8 < 4){
                    continue;
                }
            }
            int index = x * 4 + (y * partsSizeH * mapSizeH * 4);
            pixels[index+0]=cast(char)(color >> 16);
            pixels[index+1]=cast(char)(color >> 8);
            pixels[index+2]=cast(char)(color >> 0);
            pixels[index+3]=255;
        }
    }
    void DrawVerticalLine(int y1, int y2, int x, int color, bool dotted){
        for(int y = y1 ; y <= y2 ; ++ y){
            if(dotted){
                if((y + 2) % 8 < 4){
                    continue;
                }
            }
            int index = x * 4 + (y * partsSizeH * mapSizeH * 4);
            pixels[index+0]=cast(char)(color >> 16);
            pixels[index+1]=cast(char)(color >> 8);
            pixels[index+2]=cast(char)(color >> 0);
            pixels[index+3]=255;
        }
    }
    for(int y = 0 ; y < partsSizeV * mapSizeV ; ++ y){
        bool grid2Drawed = false;
        if(projectInfo.grid2Visible){
            if(y % partsSizeV == 0 && (y / partsSizeV) % projectInfo.grid2Interval == 0){
                DrawHorizontalLine(0, partsSizeH * mapSizeH - 1, y, projectInfo.grid2Color, projectInfo.grid2Type == EGridType.DOTTED);
                grid2Drawed = true;
            }
        }
        if(!grid2Drawed && projectInfo.grid1Visible){
            if(y % partsSizeV == 0 && (y / partsSizeV) % projectInfo.grid1Interval == 0){
                DrawHorizontalLine(0, partsSizeH * mapSizeH - 1, y, projectInfo.grid1Color, projectInfo.grid1Type == EGridType.DOTTED);
            }
        }
    }
    for(int x = 0 ; x < partsSizeH * mapSizeH ; ++ x){
        bool grid2Drawed = false;
        if(projectInfo.grid2Visible){
            if(x % partsSizeH == 0 && (x / partsSizeH) % projectInfo.grid2Interval == 0){
                DrawVerticalLine(0, partsSizeV * mapSizeV - 1, x, projectInfo.grid2Color, projectInfo.grid2Type == EGridType.DOTTED);
                grid2Drawed = true;
            }
        }
        if(!grid2Drawed && projectInfo.grid1Visible){
            if(x % partsSizeH == 0 && (x / partsSizeH) % projectInfo.grid1Interval == 0){
                DrawVerticalLine(0, partsSizeV * mapSizeV - 1, x, projectInfo.grid1Color, projectInfo.grid1Type == EGridType.DOTTED);
            }
        }
    }
//     printf("CreateGridPixbuf %ld ms\n",(std.datetime.Clock.currStdTime() - time) / 10000);
	return gridPixbuf;
}
Pixbuf CreateGuidePixbuf(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
    Pixbuf guidePixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, partsSizeH * mapSizeH, partsSizeV * mapSizeV);
    guidePixbuf.fill(0x00000000);
    return guidePixbuf;
}
void UpdateGuidePixbuf(Pixbuf pixbuf, int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV, int cursorGridX, int cursorGridY, int selectWidth, int selectHeight, bool tiling){
    long time = std.datetime.Clock.currStdTime();
    pixbuf.fill(0x00000000);
    char* pixels = pixbuf.getPixels();
    int length = mapSizeH * mapSizeV * partsSizeH * partsSizeV * 4;
    int leftPixelX = cursorGridX * partsSizeH + 1;
    int rightPixelX = cursorGridX * partsSizeH + partsSizeH * selectWidth - 1 - 1;
    int topPixelY = cursorGridY * partsSizeV + 1;
    int bottomPixelY = cursorGridY * partsSizeV + partsSizeV * selectHeight - 1 - 1;
    for(int pixelX = leftPixelX ; pixelX < rightPixelX ; ++ pixelX){
        int pixelIndexUp = (pixelX * 4) + (topPixelY * mapSizeH * partsSizeH * 4);
        pixels[pixelIndexUp + 0] = 255;
        pixels[pixelIndexUp + 1] = 0;
        pixels[pixelIndexUp + 2] = 0;
        pixels[pixelIndexUp+ 3] = 255;
        int pixelIndexDown = (pixelX * 4) + (bottomPixelY * mapSizeH * partsSizeH * 4);
        pixels[pixelIndexDown + 0] = 255;
        pixels[pixelIndexDown + 1] = 0;
        pixels[pixelIndexDown + 2] = 0;
        pixels[pixelIndexDown+ 3] = 255;
    }
    for(int pixelY = topPixelY ; pixelY < bottomPixelY ; ++ pixelY){
        int pixelIndexLeft = (leftPixelX * 4) + (pixelY * mapSizeH * partsSizeH * 4);
        pixels[pixelIndexLeft + 0] = 255;
        pixels[pixelIndexLeft + 1] = 0;
        pixels[pixelIndexLeft + 2] = 0;
        pixels[pixelIndexLeft+ 3] = 255;
        int pixelIndexRight = (rightPixelX * 4) + (pixelY * mapSizeH * partsSizeH * 4);
        pixels[pixelIndexRight + 0] = 255;
        pixels[pixelIndexRight + 1] = 0;
        pixels[pixelIndexRight + 2] = 0;
        pixels[pixelIndexRight+ 3] = 255;
    }
//     printf("UpdateGuidePixbuf %ld ms\n",(std.datetime.Clock.currStdTime() - time) / 10000);
}
