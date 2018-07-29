pragma solidity ^0.4.21;

contract Ownable {
//Owner address
address public owner;

//event transfer ownershipp
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

constructor() public {
owner = msg.sender;
}

//set modifier only owner
modifier onlyOwner() {
require(msg.sender == owner);
_;
}

//transfer of ownership
function transferOwnership(address newOwner) onlyOwner public {
require(newOwner != address(0));
emit OwnershipTransferred(owner, newOwner);
owner = newOwner;
}
}

contract NestEgg is Ownable {
//variable for contract address
string public userData;

//adress for user
address public lastDonator;

//required subscribe price
uint public price = 1;

//state of subscribe
bool public isPayed;

event Withdraw(address _from, address _to, uint256 _amount);

constructor() public {
    isPayed = false;
}

//set modifier for onlyPayed methods;
modifier onlyPayed(){
require(isPayed == true);
_;
}

//getting ether
function () external payable {
//require(msg.value >= price);
setValue();
}

//return current smart-contract address
function getCurrentAddress() public view returns (address){
return this;
}

// return current balance
function getCurrentBalance() public view returns (uint256){
return address(this).balance;
}

//set subscribe price
function setPrice(uint _price) external onlyOwner {
price = _price;
}

//internal function for setting balance and subscribe state and last donator address
function setValue() internal {
lastDonator = msg.sender;
setSubscribe();
}

//set subscribe state
function setSubscribe() internal {
isPayed = true;
}

//set data to smart-contract(for data)
function setData(string _userData) public onlyOwner onlyPayed returns (bool){
userData = _userData;
return true;
}

//return smart-contract(for data) address
function getData() public view returns(string){
return userData;
}

//destruct smart-contract and withdrawing eteher to owner
function ownerKill() public onlyOwner {
selfdestruct(owner);
}

//withdraw ether from smart-contract
function withdraw(address _to, uint256 _amount ) external onlyOwner {
require(address(this).balance >= _amount);
_to.transfer(_amount * 1 ether);
}

}