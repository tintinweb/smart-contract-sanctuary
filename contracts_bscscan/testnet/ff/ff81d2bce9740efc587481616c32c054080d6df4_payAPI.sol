// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract payAPI {
    mapping(string=>mapping(address=>payItem)) public payInfo ; //项目=》付款人=》付款信息
    mapping(address=>bool) public member ; //是否会员
    mapping(string=>uint) public payStandard ; //收费标准
    mapping(address=>bool) private myContract ; //调用的合约地址
    address  admin ;
    struct payItem{
        uint end ;
        uint value ;
    }

    function _addPayInfo(string memory payName_,uint value_) public onlyContract {
         if(value_ > 0 ){
            payInfo[payName_][msg.sender] = payItem(block.timestamp,value_);
            payable(admin).transfer(value_);
        }
    }

    function addContract(address contract_) external onlyAdmin {
        myContract[contract_] = true ;
    }

    function addPayStandard(string memory name_,uint value_) external returns(bool){
        payStandard[name_] = value_ ;
        return true ;
    }

    function changeAdmin(address admin_) external onlyAdmin{
        admin = admin_ ;
    }

    modifier onlyAdmin{
        require(msg.sender == admin ,"You are not admin");
        _;
    }

    modifier onlyMembersOrPay(string memory payName_){
        require(msg.sender == admin || member[msg.sender] || payInfo[payName_][msg.sender].value >= payStandard[payName_]) ; //会员或者管理员 && 单次收费
        _;
    }

    modifier onlyContract {
        require(myContract[msg.sender]);
        _;
    }

    constructor(){
        admin = msg.sender ;
    }
}