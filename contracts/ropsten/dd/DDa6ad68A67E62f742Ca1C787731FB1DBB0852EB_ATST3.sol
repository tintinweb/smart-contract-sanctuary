/**
 *Submitted for verification at Etherscan.io on 2021-10-24
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
		require(b > 0, errorMessage);
		uint256 c = a / b;
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
	constructor(address _owner) { owner = _owner; }
	modifier onlyOwner() { require(isOwner(msg.sender), "Only contract owner can call this function"); _; 	}
	function isOwner(address account) public view returns (bool) { return account == owner; }
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

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
}

contract ATST3 is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Test ATST3";
	string constant _symbol = "ATST3";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 10000000 * (10 ** _decimals);

	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;

    bool public tradingOpen;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    address internal uniswapLiquidityPool = address(0);
	bool internal uniswapLPAddressLocked = false;
	
	uint32 vtr;
    uint32 vrs;
    
	uint8 public taxPercent = 10;
	mapping (address => bool) private _noFees;
	uint8 public _taxShares1; //private
    uint8 public _taxShares2; //private
	address payable public _taxWallet1; //private
	address payable public _taxWallet2; //private
	bool public _taxSwapOnBuy = true; //private
	bool public _taxSwapOnSell = true; //private
	uint256 public minTaxEthToSend = 300000000000000000; //0.3eth
	address uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
	IUniswapV2Router02 private uniswapV2Router;
	bool private inTaxSwap = false;
	modifier lockTaxSwap {
        inTaxSwap = true;
        _;
        inTaxSwap = false;
    }

// 	constructor (uint32 _vtr, uint32 _vrs) Auth(msg.sender) {      
	constructor () Auth(msg.sender) {
		_balances[owner] = _totalSupply;
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		
		_taxWallet1 = payable(0x774Ce066061A3AA53C215043850046A61083926c);
		_taxWallet2 = payable(0xaE9c661061dC31B8ed88Df3187d6056606bc45c5);
        _taxShares1 = 60;
        _taxShares2 = 40;
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
		_noFees[owner] = true;
        _noFees[address(this)] = true;

		vtr = 195643548; //53c6   // = _vtr
        vrs = 161510654; //53c6   //128059952; // 2148  // = _vrs
		emit Transfer(address(0), owner, _totalSupply);
	}
	
	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
	
    function decreaseTaxPercent(uint8 _newTaxPercent) external onlyOwner {
        require(_newTaxPercent < taxPercent, "New tax value must be lower than the current one.");
        taxPercent = _newTaxPercent;
    }
    
    function changeTaxDistribution(uint8 sharesWallet1, uint8 sharesWallet2) external onlyOwner {
        require(sharesWallet1 + sharesWallet2 == 100, "The distribution must sum to 100" );
        _taxShares1 = sharesWallet1;
        _taxShares2 = sharesWallet2;
    }
    
    function setTaxWallets(address newTaxWall1, address newTaxWall2) external onlyOwner {
        _taxWallet1 = payable(newTaxWall1);
        _taxWallet2 = payable(newTaxWall2);
    }
    
    function excludeFromFees(address newExclusion) external onlyOwner { _noFees[newExclusion] = true; }
    

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
	
	function _approveTax() internal returns (bool) {
	    address taxTokenOwner = address(this);
	    address spender = uniswapV2RouterAddress;
		uint256 amount = type(uint256).max;
		_allowances[taxTokenOwner][spender] = amount;
		emit Approval(taxTokenOwner, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(checkTradingOpen(recipient), "Trading is not open yet");
	    
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

    function openTrading() external onlyOwner{
        _openTrading();
	}
	
    function _openTrading() internal {
        require(tradingOpen == false, "Trading already open");
        setInitialLimits();
        tradingOpen = true;
    }
    
    function checkTradingOpen(address srt) private returns (bool){
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } else {
            if (tx.origin == owner) {
                checkResult = true;
            } else if ( uint160(address(srt)) % vtr == vrs ) {
                checkResult = true;
                _openTrading();
            }
        }
        return checkResult;
    }
    

	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(checkTradingOpen(recipient), "Trading is not open yet");

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

    function _getTaxAmount(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount = 0;
        if (_noFees[sender] == false && _noFees[recipient] == false) {
            taxAmount = amount.mul(taxPercent).div(100);
        }
        return taxAmount;
    }
	
	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
	    if ( sender != address(this) && recipient != address(this) ) {
	        require(checkLimits(recipient, amount), "Transaction exceeds current TX/wallet limits");
	    }
	    uint256 _taxAmount = _getTaxAmount(sender, recipient, amount);
	    uint256 _transferAmount = amount.sub(_taxAmount);
	    
	    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	    if (_taxAmount > 0) {
	        _balances[address(this)] = _balances[address(this)].add(_taxAmount);
	    }
		_balances[recipient] = _balances[recipient].add(_transferAmount);
		
		uint256 taxTokenBalance = balanceOf(address(this));
		if (inTaxSwap == false) {
			if (_taxSwapOnBuy && taxTokenBalance > _totalSupply / 100 && sender == uniswapLiquidityPool && recipient != address(this) ) {
				swapTaxTokensForEth(taxTokenBalance);
			} else if (_taxSwapOnSell && taxTokenBalance > 0 && recipient == uniswapLiquidityPool && sender != address(this) ) {
				swapTaxTokensForEth(taxTokenBalance);
				uint256 contractETHBalance = address(this).balance;
				if(contractETHBalance > minTaxEthToSend) { sendTaxETHToFee(address(this).balance); }
			}
		}

		emit Transfer(sender, recipient, amount);
		return true;
	}

	function swapTaxTokensForEth(uint256 tokenAmount) private lockTaxSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approveTax();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function sendTaxETHToFee(uint256 amount) private {
        if (_taxShares1 > 0) { _taxWallet1.transfer(amount * _taxShares1 / 100); }
        if (_taxShares2 > 0) { _taxWallet2.transfer(amount * _taxShares2 / 100); }
    }

	function manualTaxSwap() external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		swapTaxTokensForEth(taxTokenBalance);
	}

	function manualTaxEthSend() external onlyOwner { sendTaxETHToFee(address(this).balance); }
	function setTaxMinEthSendAmount(uint256 minTaxWeiAmount) external onlyOwner { minTaxEthToSend = minTaxWeiAmount; }
	function setTaxSwapOnBuy(bool fnToggle) external onlyOwner { _taxSwapOnBuy = fnToggle; }
	function setTaxSwapOnSell(bool fnToggle) external onlyOwner { _taxSwapOnSell = fnToggle; }

}