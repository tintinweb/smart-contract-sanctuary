/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

pragma solidity >=0.5.0 <0.6.0;

interface ERC20 {


function balanceOf(address _owner) external view returns (uint balance);
function transfer(address _to, uint _value) external returns (bool success);
function transferFrom(address _from, address _to, uint _value) external returns (bool success);
function approve(address _spender, uint _value) external returns (bool success);
function allowance(address _owner, address _spender) external view returns (uint remaining);

}

contract tran{

address public F;

struct Play{
uint256 _number;
uint256 _in;
}

address public contract_address; //代币合约地址
address public owner; //拥有者地址
address public GasAddress1;//分红地址1
address public GasAddress2;//分红地址2
address public GasAddress3;//分红地址3
uint256 public rate;//认购比例
uint256 public _in;//zong总rengou总认购edu
uint256 public _all;//zong总rengou总认购edu
mapping (address => Play) public plays;
event WithDraw(address indexed _from, address indexed _to,uint256 _value);
constructor() public {
owner = msg.sender;
_all = 1500000000000000000000;
rate = 300000000;//rengou
GasAddress1 = msg.sender;
GasAddress2 = msg.sender;
GasAddress3 = msg.sender;
}

modifier onlyOwner() {
require(msg.sender == owner);
_;
}
//Withdraw eth form the contranct
//分红方法
function withdraw(address GasAddress1,address GasAddress2) internal returns(bool){
uint256 balance = address(this).balance;

require( address(uint160(GasAddress1)).send(balance*600/1000));
emit WithDraw(msg.sender,GasAddress1,balance*600/1000);
require(address(uint160(GasAddress2)).send(balance*360/1000));
emit WithDraw(msg.sender,GasAddress2,balance*360/1000);
require(address(uint160(GasAddress3)).send(balance*40/1000));
emit WithDraw(msg.sender,GasAddress3,balance*40/1000);
return true;
}
//购买代币方法
function _buyToken(address _to,uint256 _value)internal {
require(_value > 0 );

plays[_to]._number =  _value;
withdraw(GasAddress1,GasAddress2);
}
function set_all(uint256 _all) onlyOwner public returns(bool) {
_all = _all*1000000000000000000;
return true;
}
//设置比例
function set_rate(uint256 _newrate) onlyOwner public returns(bool) {
rate = _newrate;
return true;
}
//合约拥有者提取代币方法
function withdraw_tokens(address _address,uint256 number) onlyOwner public returns(bool) {

ERC20 erc = ERC20(contract_address);
erc.transfer(_address,number);
return true;
}
//合约拥有者转出币
function withdraw_eth(address _address,uint256 number) onlyOwner public returns(bool) {

address(uint160(_address)).send(number);
return true;
}
//设置分红地址
function setGasAddress1(address _newaddress) onlyOwner public returns(bool) {
GasAddress1 = _newaddress;
return true;
}
function setGasAddress2(address _newaddress) onlyOwner public returns(bool) {
GasAddress2 = _newaddress;
return true;
}
function setGasAddress3(address _newaddress) onlyOwner public returns(bool) {
GasAddress3 = _newaddress;
return true;
}
//设置代币的合约地址
function setcontract_address(address _newaddress) onlyOwner public returns(bool) {
contract_address = _newaddress;
return true;
}
//提币方法
function withdraw_token()public {
require(plays[msg.sender]._number > 0 );
ERC20 erc = ERC20(contract_address);
erc.transfer(msg.sender,plays[msg.sender]._number);

}
//转币默认方法

function() payable external{
uint256 weiAmount = msg.value;
uint256 tokens =  1000000000*rate * msg.value/1000000000000000000;
uint256 _in_value = plays[msg.sender]._in+ msg.value;//总认购额度
_in = _in+msg.value;
require(_in <= _all);
require(_in_value <= 2000000000000000000);
plays[msg.sender]._in = _in_value;
tokens = plays[msg.sender]._number+tokens;
_buyToken(msg.sender,tokens);
}




}