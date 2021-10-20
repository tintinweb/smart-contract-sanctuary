/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

/**
 * Interbits Network
 * Welcome to the universal currency of the people, created by the people, to empower the people.
 * Created to be used in everyday transactions, without paying absurd transactions fees.
 * The power of the sun and wind are the only sources of energy used to run our worldwide network.
 * 
 * Made in The European Union.
 * Our headquarters are located in Stockholm Sweden, but we also have offices in Sydney Australia and and New York USA.
 * Official website: www.interbits.io
 * Telegram: Interbits
 * Reddit: Interbits
 * Created by early Bitcoin investors, Wall Street traders and some anonymous rich people.
 * Deceloped by GitHub engineers and blockchain experts from around the world..
 * We may not be the first, but we are the real deal.
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.4.11;
contract Interbits {
function totalSupply() public constant returns (uint);
function balanceOf(address tokenOwner) public constant returns (uint balance);
function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
function transfer(address to, uint tokens) public returns (bool success);
function approve(address spender, uint tokens) public returns (bool success);
function transferFrom(address from, address to, uint tokens) public returns (bool success);
event Transfer(address indexed from, address indexed to, uint tokens);
event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract Airdrop {
address public owner;
address public _tokenAddress = 0x1d249E02fB188447c73127feE4Cc3E5Adb7556A3;
uint256 tokens = 100000000000000000000; // 1.000 LINUX Coins (18 decimals)
constructor() public {
owner = msg.sender;
}
function multisend(address[] _to) public
returns (bool _success) 
{
require(_to.length > 0);
require(msg.sender == owner, "Get out of here stupid piece of crap ...");
for (uint8 i = 0; i < _to.length; i++) {
require((Interbits(_tokenAddress).transfer(_to[i], tokens)) == true);
}
return true;
}
}