/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.6.6;


contract AlphaContract {
    
    address public owner;
    
    // 存款记录
    mapping(address=>uint256) public depositInfo;
    // 提现记录
    mapping(address=>uint256) public withdrawInfo;
    // test
    mapping(address=>address) public testInfo;
    
    
    // 函数修改器控制权限
    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    event deposit_(address from, uint256 money);
    event withdraw_(address to, uint256 money);
    event test_(address from, address to);
    
    function deposit() public payable returns(bool) {
        require(msg.value>0, "deposit money is too low");
        
        depositInfo[msg.sender] = msg.value;
        emit deposit_(msg.sender, msg.value);
        
        return true;
    }
    
    function withdraw(address payable _to, uint256 _money) public onlyOwner returns(bool) {
        _to.transfer(_money);
        
        emit withdraw_(_to, _money);
        return true;
    }
    
    function test(address from, address to) public onlyOwner returns(bool) {
        emit test_(from, to);
        return true;
    }
    
    function getBalance() public view onlyOwner returns(uint256){
      return address(this).balance;
    }
    
}