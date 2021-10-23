/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

//CHANGE ADDRESSES
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

// Very slow erc20 implementation. Limits release of the funds with emission rate in _beforeTokenTransfer().
// Even if there will be a vulnerability in upgradeable contracts defined in _beforeTokenTransfer(), it won't be devastating.
// Developers can't simply rug.

interface I{function genesisBlock() external view returns(uint);}

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	event BulkTransfer(address indexed from, address[] indexed recipients, uint[] amounts);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
	bool private _init;
    address private _treasury;
    address private _founding;
	function init() public {
		require(_init == false && msg.sender == 0x3F22EA01e31c6D9b208cd6E95F9B4c74F3C9AFa6);
		_init = true; _name = "Aletheo"; _symbol = "LET";
		_treasury = 0x2D9F853F1a71D0635E64FcC4779269A05BccE2E2;
		_founding = 0x2D9F853F1a71D0635E64FcC4779269A05BccE2E2;
		_balances[0x3F22EA01e31c6D9b208cd6E95F9B4c74F3C9AFa6] = 6e24;//treasury
	}
	
	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function totalSupply() public view returns (uint) {return 6e24-_balances[_treasury];}//subtract balance of treasury
	function decimals() public pure returns (uint) {return 18;}
	function balanceOf(address a) public view returns (uint) {return _balances[a];}
	function transfer(address recipient, uint amount) public returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
	function disallow(address spender) public returns (bool) {delete _allowances[msg.sender][spender];emit Approval(msg.sender, spender, 0);return true;}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded uniswapv2 router 02, transfer helper library
		if (spender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {emit Approval(msg.sender, spender, 2**256 - 1);return true;}
		else {_allowances[msg.sender][spender] = true;emit Approval(msg.sender, spender, 2**256 - 1);return true;}
	}

	function allowance(address owner, address spender) public view returns (uint) { // uniswapv2 router 02, transfer helper library
		if (spender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D||_allowances[owner][spender] == true) {return 2**256 - 1;} else {return 0;}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // uniswapv2 router 02, transfer helper library
		require(msg.sender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || _allowances[sender][msg.sender] == true);_transfer(sender, recipient, amount);return true;
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		uint treasuryShare = amount/100;
		_beforeTokenTransfer(sender, amount);
		amount -= treasuryShare;
		_balances[sender] = senderBalance - amount;
		_balances[recipient] += amount;
		_balances[_treasury] += treasuryShare;
		emit Transfer(sender, recipient, amount);
	}

	function bulkTransfer(address[] memory recipients, uint[] memory amounts) public returns (bool) { // will be used by the contract, or anybody who wants to use it
		require(recipients.length == amounts.length && amounts.length < 100,"human error");
		uint senderBalance = _balances[msg.sender]; uint total;
		for(uint i = 0;i<amounts.length;i++) {total += amounts[i];_balances[recipients[i]] += amounts[i];}
		require(senderBalance >= total,"balance is low");
		if (msg.sender == _treasury) {_beforeTokenTransfer(msg.sender, total);}//treasury
		_balances[msg.sender] = senderBalance - total; emit BulkTransfer(msg.sender, recipients, amounts); return true;
	}

	function _beforeTokenTransfer(address from, uint amount) internal view {
		if(from == _treasury) {//from treasury
			uint genesisBlock = I(_founding).genesisBlock();
			require(genesisBlock != 0);
			uint treasury = _balances[_treasury]; //treasury
			uint withd =  5e24 - treasury;
			uint allowed = (block.number - genesisBlock)*28e15 - withd;
			require(amount <= allowed && amount <= treasury);
		}
	}
}