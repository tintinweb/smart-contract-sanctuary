/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CoCoBank{
    //銀行名稱
    string public bank_name;
    //銀行地址
    address payable public bank_address;
    //日存款利率
    uint256 public day_time_deposit;
    //日借款利率
    uint256 public day_certificate_deposit;
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
        uint256 credit; //存戶貸款
    }
    //存戶映射
    mapping(address=>string) address_to_name;
    mapping(string=>Depositor) name_to_depositor;
    
    //建構函式
    constructor(string memory bankname){
        bank_name = bankname;
        bank_address = payable(msg.sender);
        depositor_amount = 1;
        day_time_deposit = 10;
        day_certificate_deposit = 10;
    }
    
    //檢查器
    modifier IsBankOwner(){
        require(msg.sender==bank_address,"You are not the Owner!");
        _;
    }
    
    //事件紀錄
    event event_withdraw(address Depositor,uint256 Balance);
    event event_receive(address Sender,uint256 Amount);
    event event_adddepositor(string DepositorName,address DepositorAddress);

    function AddDepositor(string memory DepositorName, address payable DepositorAddress) public {
        all_address.push(DepositorAddress);
        address_to_name[DepositorAddress] = DepositorName;
        name_to_depositor[DepositorName].name = DepositorName;
        name_to_depositor[DepositorName].depositor_address = DepositorAddress;
        name_to_depositor[DepositorName].blance = 0;
        name_to_depositor[DepositorName].credit = 0;
        name_to_depositor[DepositorName].number = depositor_amount;
        depositor_amount ++;
        emit event_adddepositor(DepositorName,DepositorAddress);
    }
    
    function AddBalance (string memory DepositorName, uint256 amount) public IsBankOwner {
        name_to_depositor[DepositorName].blance += amount;
    }
    
    function AddLoan (string memory DepositorName, uint256 amount) public IsBankOwner {
        name_to_depositor[DepositorName].credit += amount;
    }
    
    function CheckContractBalance() external IsBankOwner view returns(uint256) {
        return bank_address.balance;
    }
    
    function CheckBalance (address payable DepositorAddress) public view returns(uint256){
        Depositor memory d = name_to_depositor[address_to_name[DepositorAddress]];
        return d.blance;
    }
    
    function CheckCredit (address payable DepositorAddress) public view returns(uint256){
        Depositor memory d = name_to_depositor[address_to_name[DepositorAddress]];
        return d.credit;
    }
    
    function MyBalance() external view returns(uint256) {
        Depositor memory d = name_to_depositor[address_to_name[msg.sender]];
        return d.blance;
    }
    
    function GetAllBalance () public IsBankOwner view returns(uint256){
        uint256 sum = 0;
        for(uint i=0;i<all_address.length;i++){
            address tmp = all_address[i];
            string memory name = address_to_name[tmp];
            sum += name_to_depositor[name].blance;
        }
        return sum;
    }
    
    function Withdraw(uint256 amount) external returns(uint256){
        address payable user = payable(msg.sender);
        uint balance = CheckBalance(user);
        
        require(balance > amount,"Balance not enought!");
        
        user.transfer(amount);
        string memory name = address_to_name[msg.sender];
        uint newblance = (name_to_depositor[name].blance -= amount);
        
        emit event_withdraw(msg.sender,amount);
        return newblance;
    }
    
    fallback() external payable {
    }
    
    receive() external payable {
        emit event_receive(msg.sender,msg.value);
    }
    
    function DestroyContract() external IsBankOwner{
        selfdestruct(payable(msg.sender));
    }
}