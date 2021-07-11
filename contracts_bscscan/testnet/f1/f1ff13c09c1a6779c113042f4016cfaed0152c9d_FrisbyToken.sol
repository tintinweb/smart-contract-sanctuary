/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract Ownable {
    mapping (address => uint) public balances;
    address public contractOwner;
    
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        contractOwner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == contractOwner, 'Sorry, You do not have that priviege');
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

contract FrisbyToken is Ownable {
    mapping (address => mapping(address => uint)) public allowance;
    mapping(address => uint) public referenceid;
    uint public totalSupply = 500000000 * 10 ** 18;
    string public name = "Frisby Pay";
    string public symbol = "FBPAY";
    uint public decimals = 18;
    uint public airDropAmount = 2000 * 10 ** 18;
    address airDropReceiver;
    address[] public airDropList;
    uint idcounter;
    uint public tokenPrice = 30000;
    uint selfdropamount;
    uint public idoDeadline = block.timestamp +(60 * 1 days);
    uint public datecreated = block.timestamp;
    uint public idoMin = 1 * 10 ** 18;
    
    

    event Transfer(address indexed from, address indexed to, uint  value);
    event Approval(address indexed owner, address indexed spender, uint  value);
    event Received(address, uint);
    event createdId(address user, uint256 id);
    event TokenBurn(uint value);
    event changedName(string indexed previousName, string indexed newName);
    event changedSymbol(string indexed previousSymbol, string indexed newSymbol);
    event changedTokenPrice(uint previousPrice, uint newPrice);
    event changedIdoDeadline(uint oldDate, uint newDate);
    event changedIdoMin(uint oldValue, uint newValue);
    
    constructor () {
        balances[contractOwner] = totalSupply;
    }
    modifier airDropFull {
        require(airDropList.length<1000, 'Airdrop participants reached');
        _;
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
    
    function balance() onlyOwner public view returns(uint) {
        return balances[contractOwner];
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
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
    
    function airDrop() airDropFull public payable {
        
        require(referenceid[msg.sender]==0, 'Airdrop already claimed');
        idcounter += 1;
        
        balances[msg.sender] += airDropAmount;
        balances[contractOwner] -= airDropAmount;
        airDropList.push(msg.sender);
        referenceid[msg.sender] = idcounter;
        
        
        emit Transfer(contractOwner, msg.sender, airDropAmount);
        emit createdId(msg.sender,idcounter);
    }
    
    function idoBuy() public payable {
        require(block.timestamp<idoDeadline, 'reverted, IDO has ended');
        require(msg.value>=idoMin, 'Amount too small, check website for IDO details');
        selfdropamount = msg.value*tokenPrice;
        airDropReceiver = msg.sender;
        balances[airDropReceiver] += selfdropamount;
        balances[contractOwner] -= selfdropamount;
        emit Transfer(contractOwner, airDropReceiver, selfdropamount);
    }
    
    receive() external payable {
        require(block.timestamp<idoDeadline, 'reverted, IDO has ended');
        require(msg.value>=idoMin, 'Amount too small, check website for IDO details');
        selfdropamount = msg.value*tokenPrice;
        airDropReceiver = msg.sender;
        balances[airDropReceiver] += selfdropamount;
        balances[contractOwner] -= selfdropamount;
        emit Transfer(contractOwner, airDropReceiver, selfdropamount);
    }
    
    function getAirDropList() onlyOwner view public returns(address[] memory) {
        return airDropList;
    }
    
    function distributeToken(address[] memory addresses, uint _value) onlyOwner public returns(bool){
         for (uint i = 0; i < addresses.length; i++) {
             balances[contractOwner] -= _value;
             balances[addresses[i]] += _value;
             emit Transfer(contractOwner, addresses[i], _value);
         }
         return true;
    }
    
    function withdraw() onlyOwner public returns(bool)  {
        payable(contractOwner).transfer(address(this).balance);
        return true;
        
    }
    
    function burnToken(uint value) onlyOwner public returns(bool) {
        balances[contractOwner] -= value;
        totalSupply -= value;
        return true;
        
        
    }
    
    
}