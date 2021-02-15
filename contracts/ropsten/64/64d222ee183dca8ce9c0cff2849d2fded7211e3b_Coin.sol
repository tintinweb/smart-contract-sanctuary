/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

pragma solidity ^0.5.16;
contract Coin {
 address public minter;
 mapping (address => uint) public balances;
constructor() public {
minter = msg.sender;
}
function mint(address receiver, uint amount) public
{
if (msg.sender != minter) return;
balances[receiver] += amount;
}
function send(address receiver, uint amount) public
{
if (balances[msg.sender] < amount) return;
balances[msg.sender] -= amount;
 balances[receiver] += amount;
}
}