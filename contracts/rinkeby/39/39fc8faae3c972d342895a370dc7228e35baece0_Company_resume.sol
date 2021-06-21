/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Company_resume{

    uint ID;
    uint count;
    event log (string message); //定義文字事件
    //協力廠進料資訊
    struct material{
        string mat_company;     //物料公司名
        string mat_part;        //物料（零件）名字
        string mat_checker;     //物料檢驗人員
        string mat_supervisor;  //負責品保主管
        string mat_time;        //日期(2021.0504++)
        uint256 mat_number;     //物料數量
    }
    //協力廠進料檢驗資料
    struct material_sheet{      //進料檢驗單據
        uint256 [10][10] check;  //有第5個檢查項目，包含8次檢查結果 //荷重機1、荷重機2、卡尺、厚薄規、檢具
    }


   //協力廠工作站=workcenter=wc縮寫
   struct process1{
       string wc_ID;        //批號ＩＤ
       string wc_day;       //日期
       string wc_loc;       //location
       string wc_worker;    //作業員
       string wc_supervisor;//單位主管
       string wc_QA;        //品保人員
   }
    //協力廠工作站過程數據 4＊12
    //早班分成三次進行數據檢查，共有4個工作站12個工作站檢出項目，從1-1電阻尺顯示器～4-4側流通性壓力表
    struct process2{
        uint256[6][15] wc_data;
    }

    
    //part_data
    struct part_sheet {
        string part_name;           //零件名稱
        string part_ID;             //零件ＩＤ
        string part_loc;            //地點
        string part_day;            //檢驗紀錄日期
        string part_approved_name;  //零件核准人員
        string part_checked_name;   //零件審核人員
        string part_drawn_name;     //零件作成人員
        uint256 part_number;        //當批零件數量
    }
    //part_check_data
    struct part_sheet_2{   
        uint256 [10][10]part_check;     //零件8個檢查項目，包含5次檢查結果//後牙螺牙距、後缸螺牙距、Ｕ型架高度、Ｕ型架孔徑、鎖緊扭力、Ｕ型架寬、長度、鎖緊扭力
    }



    //中心廠進料基本資訊
    struct import_sheet {
            string im_part_name;           //零件名稱
            string im_part_ID;             //零件ＩＤ
            string im_part_company;        //進口協力廠名稱
            string im_part_day;            //接收日期
            string im_part_approved_name;  //零件核准人員
            string importer;                //零件進口人員
            uint256 im_part_number;        //當批零件數量
            bool im_OK;                    //抽樣核可狀態
        }



    //中心廠成車組裝
    struct assembly1{
            string ass_car_ID;  //成車引擎編號
            string ass_part_ID; //所使用零件
            string ass_day;     //組裝日期、時間
            string ass_station; //工作站
            string [5]  ass_worker;  //組裝人員
    }
    //成車組裝機器數值
    struct assembly2{
            uint [10][10] assembly_value;
    }

    //成車資料
    struct car1{
            string car_ID;          //汽車編號
            string car_type;        //汽車型號
            string car_color;       //車身顏色
            uint256 car_engine_num; //引擎號碼
    }
    //成車檢驗判定
    struct car2{
            bool [11] car_final_check;
            //[1]後裝 final_line
            //[2]引擎室 car_engine
            //[3]速率煞車 car_brake
            //[4]ＣＯ/ＨＣ car_COHC
            //[5]定位資料car_position
            //[6]動態地溝（底盤） car_chassis
            //[7]car_4WD 四輪定位
            //[9]car_dynamic 動態
            //[10]car_painting 塗裝

    }

    
//////////////////////////////////對結構mapping/////////////////////////////////////////////////////

    mapping (uint256=>material_sheet) uint_sheet;  //將數字映射到檢驗表結構

    mapping (string=>material) map_mat_str;     //將文字映射到物料結構
    mapping (uint256=>material) map_mat_uint;   //將數字映射到物料結構

    mapping (string=>part_sheet) map_part_str;  //將文字映射到零件表結構
    mapping (uint256=>part_sheet) map_part_uint;//將數字映射到零件結構

    //mapping (string=>part_sheet_2) map_part_str2;  //將文字映射到零件表結構
    mapping (uint256=>part_sheet_2) map_part_uint2;//將數字映射到零件結構

    mapping (uint256=>process1) map_wc_uint;   //將數字映射到工作站
    mapping (uint256=>process2) map_wc_uint2;   //將數字映射到工作站-2

    mapping (uint256=>import_sheet) map_im_uint; //將數字映射到中心廠進料資訊
    
    mapping (uint256=> assembly1) map_ass_uint;//將數字映射到組裝工作站
    mapping (uint256=>assembly2) map_ass_uint2;//將數字映射到組裝工作站-2

    mapping (uint=>car1)map_car_uint;   //將數字映射到成車檢驗
    mapping (uint=>car2)map_car_uint2;  //將數字映射到成車檢－２

/////////////////////////////////////輸入上游檢驗資料/////////////////////////////////////////
    
    //輸入物料來源資料(名字、公司、負責人員、數量)
    function push1_material_data(string memory company_name,string memory material_name,string memory mat_importer,string memory supervisor,uint256 number) public{
       ID=count;
       material storage c =map_mat_uint[ID];
       c.mat_company=company_name;
       c.mat_part=material_name;
       c.mat_checker=mat_importer;
       c.mat_supervisor=supervisor;
       c.mat_number=number;
       emit log ("push material data");
    }
    

    //輸入物料檢測內容，因有過度堆疊問題採分開輸入的方式
        function push2_check_data(uint id, uint j, uint256 check1,uint256 check2,uint256 check3,uint256 check4,uint256 check5, uint256 check6, uint256 check7,uint256 check8) public{
        ID=id;
        material_sheet storage c =uint_sheet[ID];
        c.check[1][j]=check1;
        c.check[2][j]=check2;
        c.check[3][j]=check3;
        c.check[4][j]=check4;
        c.check[5][j]=check5;
        c.check[6][j]=check6;
        c.check[7][j]=check7;
        c.check[8][j]=check8;
        emit log ("push check data");
    }    
    //確認陣列內輸入的值
    function view_mat(uint256 id,uint256 i,uint256 j) public view returns(uint){
       
        return uint_sheet[id].check[i][j];
    }
//////////////////////////////////////////工作站機器讀值//////////////////////////////////////////////

function push3_workcenter_data(string memory id,string memory wc_date,string memory wc_gps,string memory worker,string memory supervisor,string memory QA)public
{
    ID=count;
    process1 storage c =map_wc_uint[ID];
    c.wc_ID=id;
    c.wc_day=wc_date;
    c.wc_loc=wc_gps;
    c.wc_worker=worker;
    c.wc_supervisor=supervisor;
    c.wc_QA=QA;
    emit log ("push workcenter data");
}
function push4_workcenter_machince_data(uint id, uint i,uint j,uint256 value) public{
    ID=id;
    process2 storage c = map_wc_uint2[ID];
    c.wc_data[j][i]=value;
    emit log ("push wc_machince data");
    }
/////////////////////////////////////輸入協力廠-零件完成品基本及檢驗資料/////////////////////////////////////////

    function push5_part_data(string memory partname,string memory partID,string memory partday,string memory approved_name,
    string memory checked_name,string memory drawn_name,string memory gps,uint256 part_num)public
    {   
        ID=count;
        part_sheet storage c = map_part_uint[ID];
        c.part_name=partname;
        c.part_ID=partID;
        c.part_day=partday;
        c.part_approved_name=approved_name;
        c.part_loc=gps;
        c.part_checked_name=checked_name;
        c.part_drawn_name=drawn_name;
        c.part_number=part_num;
        emit log ("push part data");
    }
   

    function push6_part_check_data(uint id, uint k,uint256 part_check1,uint256 part_check2,uint256 part_check3,uint256 part_check4,uint256 part_check5) public{
        ID=id;
        part_sheet_2 storage c = map_part_uint2[ID];
        c.part_check[1][k]=part_check1;
        c.part_check[2][k]=part_check2;
        c.part_check[3][k]=part_check3;
        c.part_check[4][k]=part_check4;
        c.part_check[5][k]=part_check5;
        emit log ("push part check data");
    }

     function viewwwwwwww(uint256 id, uint256 i,uint256 j) public view returns(uint){
        return map_part_uint2[id].part_check[i][j];}
    /*
    function push_part_check_data(uint256 part_check11,uint256 part_check12,uint256 part_check13,uint256 part_check14,uint256 part_check15) public{
        ID=count;
        part_sheet_2 storage c = map_part_uint2[ID];
        c.part_check1[1]=part_check11;
        c.part_check1[2]=part_check12;
        c.part_check1[3]=part_check13;
        c.part_check1[4]=part_check14;
        c.part_check1[5]=part_check15;
    }*/
////////////////////////////////////輸入中心廠-進料資訊/////////////////////////////////////////
 function push7_import_data(string memory name,string memory id,string memory company,string memory date,string memory checker,string memory im_importer,uint256 num,bool isok)public
    {
        ID=count;
        import_sheet storage c =map_im_uint[ID];
        c.im_part_name=name;
        c.im_part_ID=id;
        c.im_part_company=company;
        c.im_part_day=date;
        c.im_part_approved_name=checker;
        c.importer=im_importer;
        c.im_part_number=num;
        c.im_OK=isok;
        emit log ("push import data");
    }
////////////////////////////////////輸入中心廠-組裝資訊/////////////////////////////////////////
    function push8_assembly_data(string memory car_ID,string memory part_ID,string memory date,string memory station,string memory worker,uint256 i)public{
        ID=count;
        assembly1 storage c=map_ass_uint[ID];
        c.ass_car_ID=car_ID;
        c.ass_part_ID=part_ID;
        c.ass_day=date;
        c.ass_station=station;
        c.ass_worker[i]=worker;
        emit log ("push assembly data");
    }

    function push9_assembly_machine_value(uint id,uint i,uint j,uint value)public{
         ID=id;
         assembly2 storage c =map_ass_uint2[ID];
         c.assembly_value[i][j]=value;
         emit log ("push assembly material data");
    }
////////////////////////////////////輸入中心廠-成車檢驗結果//////////////////////////////////////////////////////

    function push91_car_data(string memory carID,string memory type_car,string memory color,uint256 engine_ID)public{
        ID=count;
        car1 storage c=map_car_uint[ID];
        c.car_ID=carID;
        c.car_type=type_car;
        c.car_color=color;
        c.car_engine_num=engine_ID;
        emit log ("push final car data");

    }

    function push92_car_check(uint id,bool final_line,bool car_engine,bool car_brake,bool car_COHC,bool car_position,bool car_4WD,bool car_dynamic,bool car_painting)public{
        ID=id;
        car2 storage c=map_car_uint2[ID];
        c.car_final_check[1]=final_line;
        c.car_final_check[2]=car_engine;
        c.car_final_check[3]=car_brake;
        c.car_final_check[4]=car_COHC;
        c.car_final_check[5]=car_position;
        c.car_final_check[6]=car_4WD;
        c.car_final_check[7]=car_dynamic;
        c.car_final_check[8]=car_painting;
        emit log ("push car_check data");
    }

//////////////////////////////判斷檢驗內容///////////////////////////////////////////
    
    //與檢驗表進行比對 ，輸入的i是check][j][i]，
    function compare1_mat_sheet (uint256 id,uint i) public returns(uint,string memory){
        emit log ("compare mat data");
        ID=id;
        material_sheet storage c =uint_sheet[ID];
        //bool ok= true;
        string memory result;
        uint count_problem=0;//不合格點計數
      
            for(uint j=1;j<=8;j++){
                
                if(i==1)
                {   
                    if(c.check[j][i]>1930 || c.check[j][i]<1730)
                     { count_problem++;
                      result="check error,plz re-check!";}
                      
                }else if (i==2){
                    if(c.check[j][i]-2520>150||c.check[j][i]<2370)
                    {  count_problem++;
                       result="check error,plz re-check!";}
                }
                else if (i==3){
                    if(c.check[j][i]-300>2||c.check[j][i]<298)
                     { count_problem++;
                       result="check error,plz re-check!";}
                }
                else if (i==4){
                    if(c.check[j][i]>260)
                      { count_problem++;
                        result="check error,plz re-check!";}
                }
                else if (i==5){
                    if(c.check[j][i]<10||c.check[j][i]>65)
                     { count_problem++;
                       result="check error,plz re-check!";}
                }
            }  
        return (count_problem,result);
    }
    //與零件檢驗進行比對 
    function compare2_part_sheet (uint256 id,uint i) public returns(uint,string memory){
        emit log ("compare part data");
        ID=id;
        part_sheet_2 storage c =map_part_uint2[ID];
        //bool ok= true;
        string memory result2;
        uint count_problem2=0;      //不合格點計數
      
            for(uint j=1;j<=5;j++){
                
                if(i==1)
                {   
                    if(c.part_check[j][i]>8030 || c.part_check[j][i]<7970)       //79.7~80.3
                     { count_problem2++;
                      result2="check error,plz re-check!";}
                      
                }else if (i==2){
                    if(c.part_check[j][i]>6030||c.part_check[j][i]<5970)     //59.7~60.3
                    {  count_problem2++;
                       result2="check error,plz re-check!";}
                }
                else if (i==3){
                    if(c.part_check[j][i]>11300||c.part_check[j][i]<11100)     //111~113
                     { count_problem2++;
                       result2="check error,plz re-check!";}
                }
                else if (i==4){
                    if(c.part_check[j][i]>1006||c.part_check[j][i]<994)      //9.94~10.06
                      { count_problem2++;
                        result2="check error,plz re-check!";}
                }
                else if (i==5){
                    if(c.part_check[j][i]<1570||c.part_check[j][i]>2160)     //15.7~21.6
                     { count_problem2++;
                       result2="check error,plz re-check!";}
                }
                else if (i==6){
                    if(c.part_check[j][i]<900||c.part_check[j][i]>950)     //9.0~9.5
                     { count_problem2++;
                       result2="check error,plz re-check!";}
                }
                else if (i==7){
                    if(c.part_check[j][i]<10700||c.part_check[j][i]>10800)     //107~108
                     { count_problem2++;
                       result2="check error,plz re-check!";}
                }
                else if (i==8){
                    if(c.part_check[j][i]<900||c.part_check[j][i]>1400)     //9~14
                     { count_problem2++;
                       result2="check error,plz re-check!";}
                }
            }  
        return (count_problem2,result2);
    }

    //進行成車組裝比對
    function compare3_car_sheet(uint256 id)public returns(string memory error_text ,uint jj,uint count_problem3,string memory ok_text){
        emit log("Compare the car sheet");     //event
        ID=id;
        car2 storage c=map_car_uint2[ID];
        uint if_ok;             //計算正確數量
       // uint count_problem3;  //計算出錯數量
       // uint jj;//第j個有異
       // string memory error_text ; //error words
        // string memory ok_text ;  //ok words
        for(uint i=1;i<=8;i++)
        {
            if(c.car_final_check[i]==true){ 
                if_ok++;                      //如果判定結果無誤則＋1
                
            }else
            {
                count_problem3++;             // 判定有誤計數
                jj=i;
            }         
        }
        if (count_problem3>0)
        {error_text="ERROR in the car sheet! Plz re-check: ";}
        if (if_ok==8){
        ok_text="It's all OK in car sheet."; //全部正確
        }

        return (error_text,jj,count_problem3,ok_text); //（error判定結果,第n個有誤,共有幾個,全部ok的通知）
        
    }


    /*
    function CheckBalance (address payable SalesAddress) public view returns(uint256){
        Sales memory s = name_sales[address_name[SalesAddress]];
        return s.salary-s.withdrawn;
    }

    function MyBalance() external view returns(uint256) {
        Sales memory s = name_sales[address_name[msg.sender]];
        return s.salary-s.withdrawn;
    }
_part_rule[1]=8000;        //80+-0.3
        _part_rule[2]=6000;        //60+-0.3
        _part_rule[3]=11200;       //112+-1
        _part_rule[4]=1000;        //10+0.06
        _part_rule[5]=1865;        //18.65+-2.95
        _part_rule[6]=900;         //9+0.5-0
        _part_rule[7]=10700;       //107+1+0
        _part_rule[8]=1150;        //11.5+-2.5
    
_mat_rule[1]=1830;        //18.3+-1 （未來要判斷的基準值）
        _mat_rule[2]=2520;        //25.2+-1.5
        _mat_rule[3]=300;         //3.0+-0.02
        _mat_rule[4]=260;         //<2.6
        _mat_rule[5]=38;          //0.38+-0.28

0xefe494529f7f3a246a7ff6bdba721950a2e2a366b2191d891ca9c2b8b5e50666
contract:
0x93771e481F70838090F10Be029fE1493fe56BD9E
*/
}