/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

// Very slow erc20 implementation. Limits release of the funds with emission rate in _beforeTokenTransfer().
// Even if there will be a vulnerability in upgradeable contracts defined in _beforeTokenTransfer(), it won't be devastating.
// Developers can't simply rug.
// Allowances are booleans now instead of uints and uni v2 router is hardcoded, so it achieves -7100 gas per trade on uni v2 post-Berlin
// _mint() and _burn() functions are removed.
// Token name and symbol can be changed.
// Bulk transfer allows to transact in bulk cheaper by making up to three times less store writes in comparison to regular erc-20 transfers

interface I{function lgeOngoing() external returns(bool);}

contract VSRERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
//	event BulkTransfer(address indexed from, address[] indexed recipients, uint[] amounts);
//	event BulkTransferFrom(address[] indexed senders, uint[] amounts, address indexed recipient);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
	bool private _init;

	function init() public {
		require(_init == false);
		_init = true;
		_name = "Aletheo";
		_symbol = "LET";
		_balances[0x901628CF11454AFF335770e8a9407CccAb3675BE] = 1e24;
		_balances[0x3E6AE87673424B1a1111E7F8180294B57be36476] = 999e24;
	}

	function name() public view returns (string memory) {return _name;}
	function symbol() public view returns (string memory) {return _symbol;}
	function totalSupply() public view returns (uint) {uint supply = (block.number - 12640000)*42e16+1e24;if (supply > 1e27) {supply = 1e27;}return supply;}
	function decimals() public pure returns (uint) {return 18;}
	function balanceOf(address a) public view returns (uint) {return _balances[a];}
	function transfer(address recipient, uint amount) public returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
	function disallow(address spender) public returns (bool) {delete _allowances[msg.sender][spender];emit Approval(msg.sender, spender, 0);return true;}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded mainnet uniswapv2 router 02, transfer helper library
		if (spender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {emit Approval(msg.sender, spender, 2**256 - 1);return true;}
		else {_allowances[msg.sender][spender] = true;emit Approval(msg.sender, spender, 2**256 - 1);return true;}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded mainnet uniswapv2 router 02, transfer helper library
		if (spender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D||_allowances[owner][spender] == true) {return 2**256 - 1;} else {return 0;}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded mainnet uniswapv2 router 02, transfer helper library, also univ3 router now
		require(msg.sender == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D|| msg.sender == 0xE592427A0AEce92De3Edee1F18E0157C05861564 || _allowances[sender][msg.sender] == true);_transfer(sender, recipient, amount);return true;
	}

	function _transfer(address sender, address recipient, uint amount) internal {
		require(sender != address(0) && recipient != address(0));
		_beforeTokenTransfer(sender, amount);
		uint senderBalance = _balances[sender];
		require(senderBalance >= amount);
		_balances[sender] = senderBalance - amount;
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	/*function bulkTransfer(address[] memory recipients, uint[] memory amounts) public returns (bool) { // will be used by the contract, or anybody who wants to use it
		require(recipients.length == amounts.length && amounts.length < 100,"human error");
		uint senderBalance = _balances[msg.sender];
		uint total;
		for(uint i = 0;i<amounts.length;i++) {total += amounts[i];_balances[recipients[i]] += amounts[i];}
		require(senderBalance >= total);
		if (msg.sender == 0x3E6AE87673424B1a1111E7F8180294B57be36476) {_beforeTokenTransfer(msg.sender, total);}
		_balances[msg.sender] = senderBalance - total;
		emit BulkTransfer(msg.sender, recipients, amounts);
		return true;
	}

	function bulkTransferFrom(address[] memory senders, address recipient, uint[] memory amounts) public returns (bool) {
		require(senders.length == amounts.length && amounts.length < 100,"human error");
		uint total;
		uint senderBalance;
		for (uint i = 0;i<amounts.length;i++) {
			senderBalance = _balances[senders[i]];
			if (senderBalance >= amounts[i] && _allowances[senders[i]][msg.sender]== true){total+= amounts[i];_balances[senders[i]] = senderBalance - amounts[i];}
			else {delete senders[i];delete amounts[i];}
		}
		_balances[msg.sender] += total;
		emit BulkTransferFrom(senders, amounts, recipient);
		return true;
	}*/

	function _beforeTokenTransfer(address from, uint amount) internal {
		if(I(0x901628CF11454AFF335770e8a9407CccAb3675BE).lgeOngoing() == true) {require(from == 0x901628CF11454AFF335770e8a9407CccAb3675BE);}
		else {
			if (from == 0x3E6AE87673424B1a1111E7F8180294B57be36476) {// hardcoded treasury proxy address
				require(block.number > 1264e4);
				uint treasury = _balances[0x3E6AE87673424B1a1111E7F8180294B57be36476];
				uint withd =  999e24 - treasury;
				uint allowed = (block.number - 1264e4)*42e16 - withd;
				require(amount <= allowed && amount <= treasury);
			}
		}
	}
}