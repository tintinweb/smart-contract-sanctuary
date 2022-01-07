/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

/**
 *Submitted for verification at FtmScan.com on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// A modification of OpenZeppelin ERC20
// Original can be found here: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol

contract eERC {
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
	//event BulkTransfer(address indexed from, address[] indexed recipients, uint[] amounts);

	mapping (address => mapping (address => bool)) private _allowances;
	mapping (address => uint) private _balances;

	string private _name;
	string private _symbol;
	bool private _init;
    uint public treasuryFees;
    uint public epochBlock;
    address public pool;
    bool public ini;
    uint public burnBlock;
    uint public burnModifier;
    address public liquidityManager;

	function init() public {
	    //require(ini==false);ini=true;
		//_treasury = 0xeece0f26876a9b5104fEAEe1CE107837f96378F2;
		//_founding = 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		//_staking = 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8;
		liquidityManager = msg.sender; // will be a contract
	}

	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function totalSupply() public view returns (uint) {//subtract balance of treasury
		return 1e24-_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2];
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

	function approve(address spender, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52) {
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
		else {
			_allowances[msg.sender][spender] = true; //boolean is cheaper for trading
			emit Approval(msg.sender, spender, 2**256 - 1);
			return true;
		}
	}

	function allowance(address owner, address spender) public view returns (uint) { // hardcoded spookyswap router, also spirit
		if (spender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||spender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[owner][spender] == true) {
			return 2**256 - 1;
		} else {
			return 0;
		}
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) { // hardcoded spookyswap router, also spirit
		require(msg.sender == 0xF491e7B69E4244ad4002BC14e878a34207E38c29||msg.sender == 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52||_allowances[sender][msg.sender] == true);
		_transfer(sender, recipient, amount);
		return true;
	}

	function _burn(uint amount) internal {
		require(_balances[pool] > amount);
		_balances[pool] -= amount;
		_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2]+=amount;//treasury
		emit Transfer(pool,0xeece0f26876a9b5104fEAEe1CE107837f96378F2,amount);
		I(pool).sync();}

	function _transfer(address sender, address recipient, uint amount) internal {
	    uint senderBalance = _balances[sender];
		require(sender != address(0)&&senderBalance >= amount);
		_beforeTokenTransfer(sender, recipient, amount);
		_balances[sender] = senderBalance - amount;
		if((recipient==pool||recipient==0xE3450307997CB52C50B50fF040681401C56AecDe)&&sender!=liquidityManager){
		    uint genesis = epochBlock;
		    require(genesis!=0);
		    uint blocksPassed = block.number - genesis;
		    uint maxBlocks = 31536000;
		    if(blocksPassed<maxBlocks){
		        uint toBurn = (100 - blocksPassed*50/maxBlocks);// percent
		        if(toBurn>=50&&toBurn<=100){
		            uint treasuryShare = amount*toBurn/1000;//10% is max burn, 5% is min
	            	amount -= treasuryShare;
            		_balances[0xeece0f26876a9b5104fEAEe1CE107837f96378F2] += treasuryShare;//treasury
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
			burnBlock+=86400;
			_burn(toBurn);
		}
	}

	function setBurnModifier(uint amount) external {
		require(msg.sender == 0x5C8403A2617aca5C86946E32E14148776E37f72A && amount>=200 && amount<=100000);
		burnModifier = amount;
	}
}

interface I{
	function sync() external;
}