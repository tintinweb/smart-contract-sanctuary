pragma solidity ^0.4.18;

/*
项目：“企业金链”智能合约，客户案例
时间：2018-03-20
 */

contract ethworld {
    string public ProjectName="亦思教育";
    string public ProjectTag="企业金链";  //行业金链,企业金链,媒体金链

    string public Descript="官网：tjiace.com 地址:天津市和平区南京路181号天津世纪都会写字楼1505室 电话:022-27371166 E-mail：<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0a63646c654a7e60636b696f24696567">[email&#160;protected]</a> 亦思创艺教育（International Academy of Creative Education, IACE）, 初创于英国，是一所被英国创意艺术大学(UCA)及英国伯明翰艺术设计学院(BCU)等多个世界著名艺术设计院校认可的本科、硕士及博士预科培训机构。亦思教育(IACE)与英国各艺术大学的本科，硕士及博士艺术教育课程直接接轨，专注于为有意向赴英修读本科、硕士及博士学位的学生做好留学准备。亦思创艺教育(IACE)开设的国际预科课程，国际化艺术指导、专业作品集培训及留学艺术规划等课程将满足各个专业、不同学生需求。我们致力于提供最优秀的海归及海外艺术导师、教授、设计师及艺术家团队为热爱艺术设计的学生开辟一条崭新的创意之路。";
    string[] public Images;
    address public ProjectOwner;

//    event loginfo(address fromaddr,address toaddr,string info);
    
    modifier OnlyOwner() { // Modifier
        require(msg.sender == ProjectOwner);
        _;
    }   
    
    function ethworld() public {
        ProjectOwner=msg.sender;
    }
    
    function SetProjectName(string NewProjectName) OnlyOwner public {
        if(bytes(ProjectName).length==0) ProjectName = NewProjectName;
    }

    function SetProjectTag(string NewTag) OnlyOwner public {
        if(bytes(ProjectTag).length==0) ProjectTag = NewTag;
    }
    
    //set description
    function SetDescript(string NewDescript) OnlyOwner public{ 
        Descript=NewDescript;
    }

    //insert imagimage
    function InsertImage(string ImageAddress) OnlyOwner public{
        Images.push(ImageAddress);
    }
        //changeimage
    function ChangeImage(string ImageAddress,uint index) OnlyOwner public{
        if(index<Images.length)
        {
            Images[index]=ImageAddress;
        }
    }
    
    //del image
    function DeleteImage(uint index) OnlyOwner public{
        if(index<Images.length)
        {
            for(uint loopindex=index;loopindex<(Images.length-1);loopindex++)
            {
                Images[loopindex]=Images[loopindex+1];
            }
            Images.length--;
        }
    }
    
    //change owner of ethworld content
    function ChangeOwner(address newowner) OnlyOwner public{
//        loginfo(owner,newowner,"转移智能合约(DAPP)控制权");
        ProjectOwner=newowner;
    }

    //kill this
    function KillContracts() OnlyOwner public{
//        loginfo(msg.sender,0,"销毁智能合约(DAPP)");
        selfdestruct(msg.sender);
    }
    
    
//the end
}