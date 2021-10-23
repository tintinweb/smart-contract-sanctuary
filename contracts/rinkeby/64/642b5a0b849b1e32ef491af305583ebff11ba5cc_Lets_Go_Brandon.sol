/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		// Solidity only automatically asserts when dividing by 0
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
	address internal owner;

	constructor(address _owner) {
		owner = _owner;
	}

	modifier onlyOwner() {
		require(isOwner(msg.sender), "Only contract owner can call this function"); _;
	}

	function isOwner(address account) public view returns (bool) {
		return account == owner;
	}

	function transferOwnership(address payable newOwner) external onlyOwner {
		owner = newOwner;
		emit OwnershipTransferred(newOwner);
	}
	
	function renounceOwnership() external onlyOwner {
		owner = address(0);
		emit OwnershipTransferred(address(0));
	}

	event OwnershipTransferred(address owner);
}

contract Lets_Go_Brandon is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Let's Go Brandon Coin";
	string constant _symbol = "LGBC";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 100000000 * (10 ** _decimals);

	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;

    bool public tradingOpen;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    address internal uniswapLiquidityPool = address(0);
	bool internal uniswapLPAddressLocked = false;


    
    

	constructor () Auth(msg.sender) {      
		_balances[owner] = _totalSupply;
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
	
		emit Transfer(address(0), owner, _totalSupply);
	}

	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
	

	function setLPAddress(address _uniswapLiqPoolAddr) external onlyOwner {
	    require(uniswapLPAddressLocked == false, "The LP address can no longer be changed");
        uniswapLiquidityPool = _uniswapLiqPoolAddr;
	}

	function lockLPAddress() external onlyOwner {
	    require(uniswapLPAddressLocked == false, "The LP address is already locked");
	    require(uniswapLiquidityPool != address(0), "Cannot lock LP address until it has been set");
	    uniswapLPAddressLocked = true;
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function approveMax(address spender) external returns (bool) {
		return approve(spender, type(uint256).max );
	}
	
    function checkTradingOpen() private view returns (bool){
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } else {
            if (tx.origin == owner) {
                checkResult = true;
            } 
        }
        return checkResult;
    }

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(checkTradingOpen(), "Trading is not open yet");
	    
		return _transferFrom(msg.sender, recipient, amount);
	}

    function setInitialLimits() internal {
		maxTxAmount = _totalSupply / 100 * 2;
		maxWalletAmount = _totalSupply / 100 * 2;
    }
    
    function increaseLimits(uint16 maxTxAmtPct, uint16 maxWalletAmtPct) external onlyOwner {
        uint256 newTxAmt = _totalSupply / 100 * maxTxAmtPct;
        require(newTxAmt >= maxTxAmount, "New TX limit is lower than current limit");
        maxTxAmount = newTxAmt;
        
        uint256 newWalletAmt = _totalSupply / 100 * maxWalletAmtPct;
        require(newWalletAmt >= maxWalletAmount, "New wallet limit is lower than current limit");
        maxWalletAmount = newWalletAmt;
    }
    
    function removeAllLimitsLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
    }

    function openTrading() external onlyOwner{
        _openTrading();
	}
	
    function _openTrading() internal {
        require(tradingOpen == false, "Trading already open");
        setInitialLimits();
        tradingOpen = true;
    }
    
  

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingOpen(), "Trading is not open yet");

		if(_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
		}

		return _transferFrom(sender, recipient, amount);
	}
	
	function checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( tradingOpen == true ) {
            if ( transferAmount > maxTxAmount ) {
                limitCheckPassed = false;
            } else if ( recipient != uniswapLiquidityPool && (_balances[recipient].add(transferAmount) > maxWalletAmount) ) {
                limitCheckPassed = false;
            }
        }
        return limitCheckPassed;
    }

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
	    require(checkLimits(recipient, amount), "Transaction exceeds current TX/wallet limits");
		_balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
		return true;
	}
}