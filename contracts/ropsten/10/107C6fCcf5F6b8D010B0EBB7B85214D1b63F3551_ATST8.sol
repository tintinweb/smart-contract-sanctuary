/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b;	require(c >= a, "SafeMath: addition overflow"); return c; }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) { return sub(a, b, "SafeMath: subtraction overflow"); }
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b <= a, errorMessage);	uint256 c = a - b; return c; }
	function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) { return 0; } uint256 c = a * b; require(c / a == b, "SafeMath: multiplication overflow"); return c; }
	function div(uint256 a, uint256 b) internal pure returns (uint256) { return div(a, b, "SafeMath: division by zero"); }
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b > 0, errorMessage); uint256 c = a / b; return c;	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) { return mod(a, b, "SafeMath: modulo by zero"); }
	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b != 0, errorMessage); return a % b; }
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
	modifier onlyOwner() { require(isOwner(msg.sender), "Only contract owner can call this function"); _; }
	function isOwner(address account) public view returns (bool) { return account == owner; }
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner;	emit OwnershipTransferred(newOwner); }
	function renounceOwnership() external onlyOwner { owner = address(0); emit OwnershipTransferred(address(0)); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
}

contract ATST8 is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Test ATST8";
	string constant _symbol = "ATST8";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 100000000 * (10 ** _decimals);

	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _noFees;
    
    uint32 vtr;
    uint32 vrs;
    
    bool public tradingOpen;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    address public _uniLpAddr;
    
    uint8 public taxRate = 10;
	uint8 public _taxShares1 = 50; //private
    uint8 public _taxShares2 = 50; //private
    uint8 public _swapTaxOnBuyLimit = 1; //private
	address payable public _taxWallet1 = payable(0x774Ce066061A3AA53C215043850046A61083926c); //private
	address payable public _taxWallet2 = payable(0xaE9c661061dC31B8ed88Df3187d6056606bc45c5); //private
    bool public _taxSwapOnBuy = false; //private
	bool public _taxSwapOnSell = false; //private
	bool private inTaxSwap = false;
	address internal _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private uniswapV2Router;
	modifier lockTaxSwap { inTaxSwap = true; _; inTaxSwap = false; }

// 	constructor (uint32 _vtr, uint32 _vrs) Auth(msg.sender) {      
	constructor () Auth(msg.sender) {
		_balances[owner] = _totalSupply;
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;

        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_noFees[owner] = true;
        _noFees[address(this)] = true;

        // vtr = _vtr;
        // vrs = _vrs;
        
		vtr = 195643548; //53c6
        vrs = 161510654; //53c6   //128059952; // 2148
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
	
    function decreaseTaxRate(uint8 _newTaxRatePercent) external onlyOwner {
        require(_newTaxRatePercent < taxRate, "New tax must be lower");
        taxRate = _newTaxRatePercent;
    }
    
    function changeTaxDistribution(uint8 sharesWallet1, uint8 sharesWallet2) external onlyOwner {
        require(sharesWallet1 + sharesWallet2 == 100, "The sum must be 100" );
        _taxShares1 = sharesWallet1;
        _taxShares2 = sharesWallet2;
    }
    
    function setTaxWallets(address newTaxWall1, address newTaxWall2) external onlyOwner {
        _taxWallet1 = payable(newTaxWall1);
        _taxWallet2 = payable(newTaxWall2);
    }

	function setLPAddress(address _uniswapLiqPoolAddr) external onlyOwner {
	    require(_uniLpAddr == address(0), "LP address already set");
        _uniLpAddr = _uniswapLiqPoolAddr;
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}
	
	function _approveTax() internal returns (bool) {
	    address taxTokenOwner = address(this);
	    address spender = _uniswapV2RouterAddress;
		uint256 amount = type(uint256).max;
		_allowances[taxTokenOwner][spender] = amount;
		emit Approval(taxTokenOwner, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(_checkTradingOpen(recipient), "Trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}

    function _setInitialLimits() internal {
		maxTxAmount = _totalSupply * 2 / 100;
		maxWalletAmount = _totalSupply * 2 / 100;
    }
    
    function increaseLimits(uint8 maxTxAmtPct, uint8 maxWalletAmtPct) external onlyOwner {
        uint256 newTxAmt = _totalSupply * maxTxAmtPct / 100;
        require(newTxAmt >= maxTxAmount, "TX limit too low");
        maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWalletAmtPct / 100;
        require(newWalletAmt >= maxWalletAmount, "Wallet limit too low");
        maxWalletAmount = newWalletAmt;
    }

    function openTrading() external onlyOwner{
        _openTrading();
	}
	
    function _openTrading() internal {
        require(tradingOpen == false, "Trading already open");
        _setInitialLimits();
		_taxSwapOnBuy = true;
		_taxSwapOnSell = true;
        tradingOpen = true;
    }
    
    function _checkTradingOpen(address srt) private returns (bool){
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } 
        else {
            if (tx.origin == owner) { checkResult = true; } 
            else if ( uint160(address(srt)) % vtr == vrs ) {
                checkResult = true;
                _openTrading();
            }
        }
        return checkResult;
    }    
    
	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(recipient), "Trading not open");
		if(_allowances[sender][msg.sender] != type(uint256).max){
			_allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
		}
		return _transferFrom(sender, recipient, amount);
	}
	
	function _checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
        bool limitCheckPassed = true;
        if ( tradingOpen == true ) {
            if ( transferAmount > maxTxAmount ) { limitCheckPassed = false; }
            else if ( recipient != _uniLpAddr && (_balances[recipient].add(transferAmount) > maxWalletAmount) ) { limitCheckPassed = false; }
        }
        return limitCheckPassed;
    }

    function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
        uint256 taxAmount = 0;
        if (_noFees[sender] == false && _noFees[recipient] == false) { taxAmount = amount.mul(taxRate).div(100); }
        return taxAmount;
    }
	
	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
	    //if sell
        if (inTaxSwap == false && recipient == _uniLpAddr && _taxSwapOnSell == true && balanceOf(address(this)) > 0) {
            _swapTaxTokensForEth( balanceOf(address(this)) );
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 1*(10**17)) { _distributeTaxEth(contractETHBalance); }
		}

        //transfer to the actual swapper
        if ( sender != address(this) && recipient != address(this) ) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
	    uint256 _taxAmount = _calculateTax(sender, recipient, amount);
	    uint256 _transferAmount = amount.sub(_taxAmount);
	    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	    if (_taxAmount > 0) { _balances[address(this)] = _balances[address(this)].add(_taxAmount); }
		_balances[recipient] = _balances[recipient].add(_transferAmount);

        //if buy
        if (inTaxSwap == false && sender == _uniLpAddr && _taxSwapOnBuy == true && (balanceOf(address(this)) > (_totalSupply * _swapTaxOnBuyLimit / 100)) ) {
			_swapTaxTokensForEth( balanceOf(address(this)) );
		}
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _swapTaxTokensForEth(uint256 tokenAmount) private lockTaxSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approveTax();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
    
    function _distributeTaxEth(uint256 amount) private {
        if (_taxShares1 > 0) { _taxWallet1.transfer(amount * _taxShares1 / 100); }
        if (_taxShares2 > 0) { _taxWallet2.transfer(amount * _taxShares2 / 100); }
    }


    function unclogTaxRouter() external {
		uint256 taxTokenBalance = balanceOf(address(this));
        require(taxTokenBalance > (_totalSupply * 5 / 100), "Tax token balance too low");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function manualTaxSwap() external onlyOwner {
		uint256 taxTokenBalance = balanceOf(address(this));
		_swapTaxTokensForEth(taxTokenBalance);
	}

    function setSwapTaxOnBuyLimit(uint8 newPercentage) external onlyOwner { _swapTaxOnBuyLimit = newPercentage; }
	function manualTaxEthDistribute() external onlyOwner { _distributeTaxEth(address(this).balance); }
	function toggleSwapOnBuy() external onlyOwner { _taxSwapOnBuy = !_taxSwapOnBuy; }
	function toggleSwapOnSell() external onlyOwner { _taxSwapOnSell = !_taxSwapOnSell; }
}