/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract Nfthere {
struct User
{
string username;
string addr;
bool registered;
}

mapping(string => User) accounts;

function signup(string memory _username, string memory _addr) external
{
require(!accounts[_username].registered, "Username already exists");

accounts[_username] = User(_username, _addr, true);
}

function getAccount(string memory _username) external view returns(string memory, string memory)
{
return(accounts[_username].username, accounts[_username].addr);
}
}