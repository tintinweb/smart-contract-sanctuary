/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CocoBank{
    //銀行名稱
    string public bank_name;
    //銀行地址
    address payable public bank_address;
    //銀行所有人
    address payable owner_address;
    //存戶地址集合
    address[] all_address;
    //存戶數量
    uint256 public depositor_amount;
    //存戶結構
    struct Depositor{
        address payable depositor_address;
        uint256 number; //存戶編號
        string name;    //存戶姓名
        uint256 blance; //存戶餘額
        uint256 LastTransferTime; //最近一次匯款時間
        uint256 LastTransferAmount; //最近一次匯款金額
    }
    //存戶映射
    mapping(address=>string) address_to_name;
    mapping(string=>Depositor) name_to_depositor;

    //建構函式
    constructor(){
        bank_name = "CocoPonziScheme";
        bank_address = payable(address(this));
        owner_address = payable(msg.sender);
        depositor_amount = 1;
    }
    
    //檢查器
    modifier IsBankOwner(){
        require(msg.sender == owner_address,"You are not the Owner!");
        _;
    }
    modifier IsRegister(){
        Depositor memory d = name_to_depositor[address_to_name[msg.sender]];
        require(d.depositor_address == msg.sender ,"You Must Register First!");
        _;
    }
    
    //事件紀錄
    event event_withdraw(address Depositor,uint256 Balance);
    event event_receive(address Sender,uint256 Amount);
    event event_adddepositor(string DepositorName,address DepositorAddress);

    function RegisterDepositor(string memory DepositorName, address payable DepositorAddress) public {
        all_address.push(DepositorAddress);
        address_to_name[DepositorAddress] = DepositorName;
        name_to_depositor[DepositorName].name = DepositorName;
        name_to_depositor[DepositorName].depositor_address = DepositorAddress;
        name_to_depositor[DepositorName].blance = 0;
        name_to_depositor[DepositorName].LastTransferTime = 0;
        name_to_depositor[DepositorName].LastTransferAmount = 0;
        name_to_depositor[DepositorName].number = depositor_amount;
        depositor_amount ++;
        emit event_adddepositor(DepositorName,DepositorAddress);
    }
    
    //   Depositor Function
    function CheckMyBalance() IsRegister public view returns(uint256) {
        Depositor memory d = name_to_depositor[address_to_name[msg.sender]];
        uint day = (block.timestamp - d.LastTransferTime)/60/60/24;
        d.blance += (day * 10 * d.LastTransferAmount)/100;
        return d.blance;
    }
    
    function Withdraw() IsRegister external{
        Depositor storage d = name_to_depositor[address_to_name[msg.sender]];
        require(d.blance > 0,"Balance not enought!");
        payable(msg.sender).transfer(d.blance);
        d.blance = 0;
        emit event_withdraw(msg.sender,d.blance);
    }
    
    //   Bank Owner Function
    function GetAllBalance () public IsBankOwner view returns(uint256){
        uint256 sum = 0;
        for(uint i=0;i<all_address.length;i++){
            address tmp = all_address[i];
            string memory name = address_to_name[tmp];
            sum += name_to_depositor[name].blance;
        }
        return sum;
    }
    
    function DestroyContract() external IsBankOwner{
        selfdestruct(payable(msg.sender));
    }
    
    //   Contract Function
    fallback() external payable {
    }
    
    receive() external IsRegister payable {
        emit event_receive(msg.sender,msg.value);
        Depositor storage d = name_to_depositor[address_to_name[msg.sender]];
        d.blance += msg.value;
        d.LastTransferAmount = msg.value;
        d.LastTransferTime = block.timestamp;
    }
    
}