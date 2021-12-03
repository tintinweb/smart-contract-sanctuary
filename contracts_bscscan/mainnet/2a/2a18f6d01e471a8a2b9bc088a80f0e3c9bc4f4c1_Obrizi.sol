/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

//TZADKIEL, BRINGS WEALTH, SUCCESS AND LUCK INTO THIS TOKEN. HAIL TZADKIEL
contract Obrizi{
mapping(address => uint) public balances;
mapping(address => mapping(address => uint)) public allowance;
uint public totalSupply = 120000000 * 10 ** 18;
string public name = "Ozini Network";
string public symbol = "OZNI"; // IOPHIEL BRINGS BEAUTY TO THIS TOKEN AND EVERY PERCEPTION OF THIS TOKEN, HAIL. YBARION MAKES THIS TOKEN BE, FEEL AND BE SEEN AS EXTREMLY VALUABLE BY EVERYONE. HAIL.
uint public decimals = 18;
event Transfer(address indexed from, address indexed to, uint value);
event Approval(address indexed owner, address indexed spender, uint value);
constructor() {
balances[msg.sender] = totalSupply;
}
function balanceOf(address owner) public view returns(uint) {
return balances[owner];
}//Mammon is owner, the wealth magnate. all who own this coin are infused with his energy through this coin. HAIL MAMMON.
function transfer(address to, uint value) public returns(bool) {
require(balanceOf(msg.sender) >= value, 'balance too low');
balances[to] += value;
balances[msg.sender] -= value;
emit Transfer(msg.sender, to, value);
return true;
}
function transferFrom(address from, address to, uint value) public returns(bool) {
require(balanceOf(from) >= value, 'balance too low');
require(allowance[from][msg.sender] >= value, 'allowance too low');
balances[to] += value;
balances[from] -= value;
emit Transfer(from, to, value);
return true;
}
function approve(address spender, uint value) public returns (bool) {
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}
}

//clauneck's guidance, hail THE ONE WHO ENSURES AND ENSURED SUCCESS.
//HAYLEL BEN SHAHAR ORGANISES FOR THE SUCCESS OF THIS TOKEN, FOR ITS PRICE TO RISE AND BE HIGH AND CONTINUE TO BECOME HIGHER