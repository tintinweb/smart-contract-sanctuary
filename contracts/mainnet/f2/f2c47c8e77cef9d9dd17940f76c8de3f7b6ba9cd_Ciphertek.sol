/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Ownable {
    mapping (address => uint) public balances;
    address public contractOwner;
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        contractOwner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == contractOwner, 'Sorry, You do not have that priviliege');
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        balances[newOwner] += balances[contractOwner];
        balances[contractOwner] -= balances[contractOwner];
        emit ownershipTransferred(contractOwner, newOwner);
        contractOwner = newOwner;
    }
}

contract Ciphertek is Ownable {
    mapping (address => mapping(address => uint)) public allowance;
    uint public totalSupply = 63000000 * 10 ** 18;
    string public name = "Ciphertek Token";
    string public symbol = "CITEK";
    uint public decimals = 18;
    uint public tokenPrice = 1;
    uint idoReceiveamount;
    address idoReceiver;
    uint public idoDeadline = block.timestamp +(90 * 1 days);
    uint public idoMin = 1 * 10 ** 17;
    uint public idoAmountRaised;
    
    event Transfer(address indexed from, address indexed to, uint  value);
    event Approval(address indexed owner, address indexed spender, uint  value);
    event changedName(string indexed previousName, string indexed newName);
    event changedSymbol(string indexed previousSymbol, string indexed newSymbol);
    event changedTokenPrice(uint previousPrice, uint newPrice);
    event changedIdoDeadline(uint oldDate, uint newDate);
    event changedIdoMin(uint oldValue, uint newValue);
    
    constructor () {
        balances[contractOwner] = totalSupply;
    }
    
    function changeName(string memory newName)onlyOwner public returns(bool) {
        emit changedName(name, newName);
        name = newName;
        return true;
    }
    
    function changeSymbol(string memory newSymbol)onlyOwner public returns(bool) {
        emit changedSymbol(symbol, newSymbol);
        symbol = newSymbol;
        return true;
    }
    
    function changeTokenPrice(uint newPrice)onlyOwner public returns(bool){
        emit changedTokenPrice(tokenPrice, newPrice);
        tokenPrice = newPrice;
        return true;
        
    }
    
    function changeIdoDeadline(uint newDate)onlyOwner public returns(bool){
        emit changedIdoDeadline(idoDeadline, newDate);
        idoDeadline = newDate;
        return true;
    }
    
    function changeIdoMin(uint newValue)onlyOwner public returns(bool){
        emit changedIdoMin(idoMin, newValue);
        idoMin = newValue;
        return true;
    }
    
    function balanceOf(address _address) public view returns(uint) {
        return balances[_address];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender)>=value, 'insufficient balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
       require(balanceOf(from)>=value, 'insufficient balance'); 
       require(allowance[from][msg.sender] >= value, 'allowance too low');
       
       balances[to] += value;
       balances[from] -= value;
       emit Transfer(from, to, value);
       return true;
    }
    
    function approve (address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function idoBuy() public payable {
        require(block.timestamp<=idoDeadline, 'reverted, IDO has ended');
        require(msg.value>=idoMin, 'Amount too small, check website for IDO details');
        idoReceiveamount = msg.value*tokenPrice;
        idoReceiver = msg.sender;
        balances[idoReceiver] += idoReceiveamount;
        balances[contractOwner] -= idoReceiveamount;
        idoAmountRaised += msg.value;
        emit Transfer(contractOwner, idoReceiver, idoReceiveamount);
    }
    
    receive() external payable {
        require(block.timestamp<=idoDeadline, 'reverted, IDO has ended');
        require(msg.value>=idoMin, 'Amount too small, check website for IDO details');
        idoReceiveamount = msg.value*tokenPrice;
        idoReceiver = msg.sender;
        balances[idoReceiver] += idoReceiveamount;
        balances[contractOwner] -= idoReceiveamount;
        idoAmountRaised += msg.value;
        emit Transfer(contractOwner, idoReceiver, idoReceiveamount);
    }
    
    function distributeToken(address[] memory addresses, uint _value) onlyOwner public returns(bool){
         for (uint i = 0; i < addresses.length; i++) {
             balances[contractOwner] -= _value;
             balances[addresses[i]] += _value;
             emit Transfer(contractOwner, addresses[i], _value);
         }
         return true;
    }
    
    function getEther() onlyOwner public returns(bool)  {
        payable(contractOwner).transfer(address(this).balance);
        return true;
    }
    
}