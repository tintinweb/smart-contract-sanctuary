//SourceUnit: CosmoseGlobal.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

contract CosmoseGlobal {
    address payable public owner;
    
    mapping(address => uint) public balances;
    uint bidIncrement;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    event AddMoney(address sender, uint value);
    event WithdrawMoney(address sender, uint value);
    
    receive() payable external{
        receiveFunds();
    }

    function receiveFunds() public payable returns(bool) {
        require(msg.sender != address(0));
        balances[msg.sender] = msg.value;
        emit AddMoney(msg.sender, msg.value);
        return true;
    }

    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        // only the manager is allowed to call it
        return address(this).balance;
    }

    function withdrawForAdmin() public payable onlyOwner returns(bool) {
        uint balance = address(this).balance;
        owner.transfer(balance);
        return true;
    }
    
    function withdrawFunds(address _to, uint amount) payable public returns(bool) {
        require(balances[_to] > 0); 
        payable(_to).transfer(amount);
        emit WithdrawMoney(_to, amount);
        return true;
    }
    
    
}