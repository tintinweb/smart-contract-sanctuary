/**
 *Submitted for verification at snowtrace.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

// CHANGE ADDRESSES
pragma solidity ^0.8.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
    uint public treasuryFees;
    uint public epochBlock;
    address public pool;
    address public treasury;
    bool public ini;
    uint public burnBlock;
    uint public burnModifier;
    address public governance;
    address public liquidityManager;
    address private _treasury;
    address private _staking;

	function init() public {
	    require(ini==true);ini=false;
		_treasury = 0x56D4F9Eed62651D69Af66886A0aA3f9c0500FDeA;
        _staking = 0x5E31d498c820d6B4d358FceeEaCA5DE8Cc2f0Cbb;
		_staking = _staking;
	    governance = msg.sender;
	    _balances[governance] = 1e24;
	    emit Transfer(governance,0x000000000000000000000000000000000000dEaD,1e24);
		burnBlock = block.number;
		epochBlock = block.number;
		burnModifier = 10000;
		liquidityManager = msg.sender;
	}
	
	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of treasury
		return 1e24-_balances[_treasury];
	}

	function decimals() public pure returns (uint) {
		return 18;
	}

	function balanceOf(address a) public view returns (uint) {
		return _balances[a];
	}

	function transfer(address recipient, uint amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function disallow(address spender) public returns (bool) {
		delete _allowances[msg.sender][spender];
		emit Approval(msg.sender, spender, 0);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) { // hardcoded trader joe router
		if (spender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4) {
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
		else {
			_allowances[msg.sender][spender] = true; //boolean is cheaper for trading
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded trader joe router
		if (spender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4||_allowances[owner][spender] == true) {
			return 2**256 - 1;
		} else {
			return 0;
		}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded trader joe router
		require(msg.sender == 0x60aE616a2155Ee3d9A68541Ba4544862310933d4||_allowances[sender][msg.sender] == true);
		_transfer(sender, recipient, amount);
		return true;
	}

	function burn(uint amount) public {
		require(msg.sender == _staking);
		_burn(amount);
	}

	function _burn(uint amount) internal {
		require(_balances[pool] > amount);
		_balances[pool] -= amount;
		_balances[_treasury]+=amount;//treasury
		emit Transfer(pool,_treasury,amount);
		I(pool).sync();
	}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		if(recipient==pool&&sender!=liquidityManager){
		    uint genesis = epochBlock;
		    require(genesis!=0);
		    uint blocksPassed = block.number - genesis;
		    uint maxBlocks = 15768000;
		    if(blocksPassed<maxBlocks){
		        uint toBurn = (100 - blocksPassed*50/maxBlocks);// percent
		        if(toBurn>=50&&toBurn<=100){
		            uint treasuryShare = amount*toBurn/1000;//10% is max burn, 5% is min
	            	amount -= treasuryShare;
            		_balances[_treasury] += treasuryShare;//treasury
        			treasuryFees+=treasuryShare;
		        }
		    }
		}
		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);
	}

	function _beforeTokenTransfer(address from,address to, uint amount) internal {
		address p = pool;
		uint pB = _balances[p];
		if(pB>1e22 && block.number>=burnBlock && from!=p && to!=p) {
			uint toBurn = pB*10/burnModifier;
			burnBlock+=43200;
			_burn(toBurn);
		}
	}

	function setBurnModifier(uint amount) external {
		require(msg.sender == governance && amount>=200 && amount<=100000);
		burnModifier = amount;
	}

	function setPool(address a) external {
		require(msg.sender == governance);
		pool = a;
	}
}

interface I{
	function sync() external;
}