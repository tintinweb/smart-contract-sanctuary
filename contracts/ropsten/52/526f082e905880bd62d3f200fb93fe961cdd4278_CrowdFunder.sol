pragma solidity ^0.4.25;
contract CrowdFunder{
    struct Funder{  //赞助者
        address addr;    //姓名
        uint amount;       //出资总额
    }   

    struct Compaign{        //被赞助人
        address beneficiary;        //钱包地址
        uint   fundingGoal;         //收赞助总额
        uint numFunder;             //被赞助总人数
        uint amount;                //已赞助总额
        mapping(uint =>Funder) funders;     //存储出资人信息
    }

    uint numCompaigns;          //被赞助人数
    mapping(uint => Compaign) compaigns;        //存储被赞助人信息

    //新增一个Compaign,传入受益人地址和所需要赞助的金额总数
    function newCompaign(address beneficiary,uint fundingGoal) public returns(uint CompaignsId){
        CompaignsId = numCompaigns++;
        compaigns[CompaignsId] = Compaign(beneficiary,fundingGoal,0,0);
    }
    //通过CompaignId给某个Compaign赞助
    function contribute(uint CompaignsId) public payable{
       Compaign storage c = compaigns[CompaignsId];
        c.funders[c.numFunder++] = Funder({addr:msg.sender,amount:msg.value});
        c.amount+=msg.value;
        c.beneficiary.transfer(msg.value);
    }
    //检查某个campaignId编号的受益人集资是否达标,不达标返回false,达标返回true;
    function checkGoal(uint CompaignsId) public view returns (bool flag){
        Compaign storage c = compaigns[CompaignsId];
        if (c.amount<c.fundingGoal){
            return false;
        }else{
            return true;
        }
    }
}