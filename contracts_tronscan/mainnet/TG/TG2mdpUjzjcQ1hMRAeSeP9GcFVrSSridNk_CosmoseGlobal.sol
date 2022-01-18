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
        owner.transfer(msg.value);
        emit AddMoney(msg.sender, msg.value);
        return true;
    }

    // returning the contract's balance in wei
    function getBalance() public view returns(uint){
        // only the manager is allowed to call it
        return address(this).balance;
    }

    
    function transfer(address to, uint value) public returns(bool success){
        require(balances[to] > 0); 
        payable(to).transfer(value);
        emit WithdrawMoney(msg.sender, value);
        return true;
    }
    
    
}