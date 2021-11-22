/**
 *Submitted for verification at BscScan.com on 2021-11-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.8;

contract PriceToken{

struct token{
	// State variables
	address tokenaddress;
	string name;
	string symbol;
	string usdtprice;
}

token []emps;

function addToken(address empid, string memory name, string memory symbol, string memory usdtprice) public{
	    token memory e = token (empid, name, symbol, usdtprice);
	    emps.push(e);
    }

// Function to get details of token
function getToken(address tokenaddress) public view returns(string memory, string memory, string memory){
	uint i;
	for(i=0; i<emps.length; i++)
	{
		token memory e = emps[i];
		// Looks for a matching
		if(e.tokenaddress == tokenaddress){
				return(e.name, e.symbol, e.usdtprice);
		}
	}
	return("Not Found", "Not Found", "Not Found");}
}