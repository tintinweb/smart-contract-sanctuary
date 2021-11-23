/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

/** 
	  ____  _   _ ____     _____          _     
	 |  _ \| \ | |  _ \   / ____|        | |    
	 | |_) |  \| | |_) | | |     __ _ ___| |__  
	 |  _ <| . ` |  _ <  | |    / _` / __| '_ \ 
	 | |_) | |\  | |_) | | |___| (_| \__ \ | | |
	 |____/|_| \_|____/   \_____\__,_|___/_| |_|
												
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
	
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IBEP20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
	
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 9;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
	
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IPancakeSwapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeSwapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
	
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
	
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
	
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
	
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
	
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
	
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
	
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
	
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
	
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
	
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
	
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
	
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));
    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    require(!(a == - 2**255 && b == -1) && (b > 0));
    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract BNBCash is BEP20, Ownable {
    using SafeMath for uint256;
	
    IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
	
    bool private swapping;
	bool public swapEnable = true;
	
    uint256 public swapTokensAtAmount = 100000 * (10**9);
	uint256 public maxTxAmount = 200000000 * (10**9);
	
	uint256[] public walletsFee;
	
	address public BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address[] public wallets = [                                               
        0x3c56cfdCfc8587b4Fd1d2f3BDEd7dD8685aF8b93,                                      
        0xC0CC6dab5286A133D54681EEe4d2530B9b76E0F6                                      
    ];	
	
    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) public isBlackListed;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event AddedBlackList(address _address);
    event RemovedBlackList(address _address);
	event DestroyedBlackFunds(address _blackListedUser, uint _balance);
	
    constructor() BEP20("BNB Cash", "BNBCH") {
      
    	IPancakeSwapV2Router02 _pancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _pancakeSwapV2Pair = IPancakeSwapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), BUSDAddress);

        pancakeSwapV2Router = _pancakeSwapV2Router;
        pancakeSwapV2Pair   = _pancakeSwapV2Pair;
		
        _setAutomatedMarketMakerPair(_pancakeSwapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);
		
		walletsFee.push(100);
        walletsFee.push(100);
        walletsFee.push(100);
		
        _mint(owner(), 200000000 * (10**9));
    }

    receive() external payable {
  	}
	
	function setSwapTokensAtAmount(uint256 swapTokens) external onlyOwner {
  	     swapTokensAtAmount = swapTokens;
  	}
	
	function setMaxTxAmount(uint256 _maxTxAmount) external onlyOwner() {
        maxTxAmount = _maxTxAmount;
    }
	
	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
    }
		
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != pancakeSwapV2Pair, "The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function setWalletsFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
		walletsFee[0] = buy;
		walletsFee[1] = sell;
		walletsFee[2] = p2p;
	}
	
	function setWallets(address payable[] calldata addresses) external onlyOwner() {
        require(addresses.length==wallets.length, "Different size of input to wallets size.");
        for(uint i=0; i < wallets.length;i++){
            wallets[i] = addresses[i];
        }
    }
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
		require(!isBlackListed[from], "BEP20: transfer from the blacklist address");
		require(!isBlackListed[to], "BEP20: transfer to the blacklist address");
        if(from != owner() && to != owner()) 
		{
		    require(amount <= maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
		}
		
		if(automatedMarketMakerPairs[to]) 
		{
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
			
            if (!swapping && canSwap && swapEnable) {
                swapping = true;
				
				swapTokensForBNB(swapTokensAtAmount);
				
				uint amountPerWallet = address(this).balance.div(wallets.length);
				for(uint i=0; i < wallets.length-1; i++){
					payable(wallets[i]).transfer(amountPerWallet);
				}
                swapping = false;
            }
        }
		
        bool takeFee = !swapping;
		
		if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
		
		if(takeFee) {
		    uint256 allfee;
		    allfee = collectFee(amount, automatedMarketMakerPairs[to], !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]);
			super._transfer(from, address(this), allfee);
			amount = amount.sub(allfee);
		}
        super._transfer(from, to, amount);
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256) {
        uint256 totalFee = amount.mul(p2p ? walletsFee[2] : sell ? walletsFee[1] : walletsFee[0]).div(10000);
        return totalFee;
    }
	
	function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
		path[1] = BUSDAddress;
        path[2] = pancakeSwapV2Router.WETH();
		
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
	
	function burn(uint256 _value) public {
	    uint256 burnAmount = _value;
        require(balanceOf(msg.sender) >= burnAmount);
        _burn(msg.sender, burnAmount);
    }
    
	function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }
	
    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
	
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
		require(isBlackListed[_blackListedUser]);
		uint dirtyFunds = balanceOf(_blackListedUser);
		_burn(_blackListedUser, dirtyFunds);
		emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}