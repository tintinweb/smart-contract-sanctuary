/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


contract Token {



mapping(address => uint) public balances;

mapping(address => mapping(address => uint)) public allowance;



uint public totalSupply = 20000000000 * 10 ** 8;

string public name =  "SKYMOON";

string public symbol = "SKY";

uint public decimals = 8;


address public deadWallet = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => uint) public walletToPurchaseTime;
	mapping (address => uint) public walletToSellime;	

    address[] private _excluded;
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10000000000 * 10**_decimals;     // Supply do Token = 20 billions
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _maxTxAmount = 30000000 * 10**_decimals;    // 30 millions - Initial max buy
    uint256 public _maxRxAmount = 10000000 * 10**_decimals;    // 10 millions - Initial max sell
	uint256 public _maxWallet = 300000000 * 10**_decimals;     // 300 millions - Initial max Wallet	
    uint256 public numTokensToSwap = 5000000 * 10**_decimals; // 5 millions
	uint public sellPerSecond = 20; // 20seconds
    uint public buyPerSecond = 10;	// 10seocnds

	struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 marketing;
        uint256 liquidity;
        uint256 burn;
    }

event Transfer(address indexed from, address indexed to, uint value);

event Approval(address indexed owner, address indexed spender, uint value);


constructor() {

balances[msg.sender] = totalSupply;

}



function balanceOf(address owner) public view returns(uint) {

return balances[owner];

}



function transfer(address to, uint value) public returns(bool) {

require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');

balances[to] += value;

balances[msg.sender] -= value;

emit Transfer(msg.sender, to, value);

return true;

}



function transferFrom(address from, address to, uint value) public returns(bool) {

require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');

require(allowance[from][msg.sender] >= value, 'Sem permissao (allowance too low)');

balances[to] += value;

balances[from] -= value;

emit Transfer(from, to, value);

return true;

}



function approve(address spender, uint value) public returns(bool) {

allowance[msg.sender][spender] = value;

emit Approval(msg.sender, spender, value);

return true;

}

}