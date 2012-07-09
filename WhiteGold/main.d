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

ProjectInfo projectInfo = null;

int main(string[] argv){
    Main.init(argv);
    projectInfo = new ProjectInfo();
    version(DRAW_SAMPLE){
        NormalLayerInfo layerInfo1 = new NormalLayerInfo("レイヤー1", true, "dat/sample/mapchip256_a.png");
        projectInfo.layerInfos ~= layerInfo1;
        layerInfo1.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
//         layerInfo1.chipLayout = [128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,
//                                  128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128,128];
        NormalLayerInfo layerInfo2 = new NormalLayerInfo("レイヤー2", true, "dat/sample/mapchip256_b.png");
        layerInfo2.chipLayout.length = projectInfo.mapSizeH * projectInfo.mapSizeV;
//         layerInfo2.chipLayout = [130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,122,123,124,125,130,130,200,201,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,138,139,140,141,130,130,216,217,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,154,155,156,157,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,170,171,172,173,130,130,130,130,130,130,146,130,130,130,130,130,130,146,130,
//                                  130,186,187,188,189,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,200,201,130,130,130,
//                                  130,130,130,130,61,130,130,130,130,146,130,130,130,130,130,216,217,130,130,130,
//                                  130,130,130,130,77,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,93,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,122,123,124,125,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,138,139,140,141,
//                                  130,130,130,130,146,130,130,130,200,201,130,130,130,130,130,130,154,155,156,157,
//                                  130,130,130,130,130,130,130,130,216,217,130,130,130,130,130,130,170,171,172,173,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,186,187,188,189,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,
//                                  130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130,130];
        projectInfo.layerInfos ~= layerInfo2;
        projectInfo.AddMapchipFile("dat/sample/mapchip256_a.png");
        projectInfo.AddMapchipFile("dat/sample/mapchip256_b.png");
        layerInfo1.layoutPixbuf = CreatePixbufFromLayout(0);
        layerInfo2.layoutPixbuf = CreatePixbufFromLayout(1);
    }
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
    return 0;
}

Pixbuf CreatePixbufFromLayout(int layerIndex){
    Pixbuf ret = new Pixbuf(GdkColorspace.RGB, true, 8, projectInfo.partsSizeH * projectInfo.mapSizeH, projectInfo.partsSizeV * projectInfo.mapSizeV);
    NormalLayerInfo normalLayerInfo = cast(NormalLayerInfo)projectInfo.layerInfos[layerIndex];
    Pixbuf mapChip = projectInfo.mapchipPixbufList[normalLayerInfo.mapchipFilePath];
    int chipLayout[] = normalLayerInfo.chipLayout;
    // マップチップの横分割数
    int chipDivNumH = mapChip.getWidth() / projectInfo.partsSizeH;
    for(int y = 0 ; y < projectInfo.mapSizeV ; ++ y){
        for(int x = 0 ; x < projectInfo.mapSizeH ; ++ x){
            int chipIndex = normalLayerInfo.chipLayout[x + y * projectInfo.mapSizeH];
            int chipSrcOffsetX = chipIndex % chipDivNumH;
            int chipSrcOffsetY = chipIndex / chipDivNumH;
            mapChip.copyArea(projectInfo.partsSizeH * chipSrcOffsetX, projectInfo.partsSizeV * chipSrcOffsetY, projectInfo.partsSizeH, projectInfo.partsSizeV, ret, x * projectInfo.partsSizeH, y * projectInfo.partsSizeV);
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
    string texts[] = readedText.split("\r\n");
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
Pixbuf CreateGridPixbuf(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
    long time = std.datetime.Clock.currStdTime();
    Pixbuf gridPixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, partsSizeH * mapSizeH, partsSizeV * mapSizeV);
    char* pixels = gridPixbuf.getPixels();
    int length = mapSizeH * mapSizeV * partsSizeH * partsSizeV * 4;
    int intervalH = partsSizeH * 4;
    int pixelNumH = mapSizeH * partsSizeH;
    pixels[0..length] = 0;
    for(int i=0;i<length;i+=4){
        if(((i / 4) / pixelNumH) % partsSizeV == 0 || i % intervalH == 0){
            pixels[i..i+3]=220;
            pixels[i+3]=255;
        }
    }
    printf("CreateGridPixbuf %ld ms\n",(std.datetime.Clock.currStdTime() - time) / 10000);
	return gridPixbuf;
}
Pixbuf CreateGuidePixbuf(int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV){
    Pixbuf guidePixbuf = new Pixbuf(GdkColorspace.RGB, true, 8, partsSizeH * mapSizeH, partsSizeV * mapSizeV);
    char* pixels = guidePixbuf.getPixels();
    int length = mapSizeH * mapSizeV * partsSizeH * partsSizeV * 4;
    pixels[0..length] = 0;
    return guidePixbuf;
}
void UpdateGuidePixbuf(Pixbuf pixbuf, int mapSizeH, int mapSizeV, int partsSizeH, int partsSizeV, int cursorGridX, int cursorGridY, int selectWidth, int selectHeight, bool tiling){
    char* pixels = pixbuf.getPixels();
    int length = mapSizeH * mapSizeV * partsSizeH * partsSizeV * 4;
    pixels[0..length] = 0;
    int leftPixelX = cursorGridX * partsSizeH + 1;
    int rightPixelX = cursorGridX * partsSizeH + partsSizeH * selectWidth - 1 - 1;
    int topPixelY = cursorGridY * partsSizeV + 1;
    int bottomPixelY = cursorGridY * partsSizeV + partsSizeV * selectHeight - 1 - 1;
    printf("XY(%d,%d)(%d,%d)\n",cursorGridX,cursorGridY,leftPixelX,rightPixelX);
    for(int pixelX = leftPixelX ; pixelX < rightPixelX ; ++ pixelX){
        int pixelIndexUp = (pixelX * 4) + (topPixelY * mapSizeH * partsSizeH * 4);
        printf("pixelIndexUp = %d\n",pixelIndexUp);
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
}
