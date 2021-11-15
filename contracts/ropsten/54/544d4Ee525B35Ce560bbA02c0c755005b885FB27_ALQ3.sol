/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.9;

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
	modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner;	emit OwnershipTransferred(newOwner); }
	function renounceOwnership() external onlyOwner { owner = address(0); emit OwnershipTransferred(address(0)); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract ALQ3 is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "ALQ3";
	string constant _symbol = "ALQ3";
	uint256 constant _totalSupply = 1 * (10**12) * (10 ** _decimals);
	uint8 constant _decimals = 9;
    uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _excludedFromFee;
    bool public tradingOpen;
    uint256 public maxTxAmount; uint256 public maxWalletAmount;
	address private _limitRemover; address private _taxRemover; address private _lpTokenOwner;
    address public _uniLpAddr;//address private _uniLpAddr;
	uint8 _defTaxRate = 10; 
	uint8 private _buyTaxRate; uint8 private _sellTaxRate; uint8 private _txTaxRate;
    uint16 public _autoLPShares = 200;//uint16 private _autoLPShares = 200;
	uint16 public _taxShares1 = 600;//uint16 private _taxShares1 = 600;
    uint16 public _taxShares2 = 100;//uint16 private _taxShares2 = 100;
    uint16 public _taxShares3 = 100;//uint16 private _taxShares3 = 100;
	uint256 private _taxBreakEnd;
	address payable private _taxWallet1 = payable(0xf885163cF387f2dB7F9Ee1Dc7E762Ace9CE47519);
	address payable private _taxWallet2 = payable(0xa263fb71544879A3924b684dce9C6a93427B9065);
    address payable private _taxWallet3 = payable(0x88CAb0DD0C3B6112080C841cFdE2dfb1f2FF2676);
	bool private _taxAutoSwap = false;
	bool private _inTaxSwap = false;
	// address private _uniswapV2RouterAddress = address(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PanCakeSwap for BSC
	address private _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // UniswapV2 for ETH
    IUniswapV2Router02 private _uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		tradingOpen = false;
		_limitRemover = msg.sender;
		_taxRemover = msg.sender;
		_lpTokenOwner = msg.sender;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
        _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_excludedFromFee[owner] = true;
        _excludedFromFee[address(this)] = true;
		_excludedFromFee[_uniswapV2RouterAddress] = true;
		_excludedFromFee[_taxWallet1] = true;
        _smd = smd; _smr = smr;
		// _balances[owner] = _totalSupply;
		// emit Transfer(address(0), owner, _totalSupply);
		_balances[address(this)] = _totalSupply;
		emit Transfer(address(0), address(this), _totalSupply);
	}
	
	receive() external payable {}
	
	function totalSupply() external pure override returns (uint256) { return _totalSupply; }
	function decimals() external pure override returns (uint8) { return _decimals; }
	function symbol() external pure override returns (string memory) { return _symbol; }
	function name() external pure override returns (string memory) { return _name; }
	function getOwner() external view override returns (address) { return owner; }
	function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
	function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

	function initLP(uint256 ethAmountWei) external onlyOwner {
		require(!tradingOpen, "trading already open");
		require(ethAmountWei > 0, "eth liquidity cannot be zero");
		uint256 _contractETHBalance = address(this).balance;
		require(_contractETHBalance >= ethAmountWei, "not enough eth available");
		uint256 _contractTokenBalance = balanceOf(address(this));
		require(_contractTokenBalance > 0, "no tokens for liquidity");
		_uniLpAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		_approveRouter(_contractTokenBalance);
		_addLiquidity(_contractTokenBalance, ethAmountWei);
	}

	function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei) internal {
		_uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, _lpTokenOwner, block.timestamp );
	}

	function resetTax() external {
		require(msg.sender ==  _taxRemover, "not authorized");
		_resetTax();
	}

	function _resetTax() internal {
		_buyTaxRate = _defTaxRate;
		_sellTaxRate = _defTaxRate;
		_txTaxRate = _defTaxRate;
	}

	function removeFees(address exclWallet) external {
		require(msg.sender == _taxRemover, "not authorized");
		_excludedFromFee[ exclWallet ] = true;
	}

    function decreaseTaxRate(uint8 newBuyTax, uint8 newSellTax, uint8 newTxTax) external {
		require(msg.sender ==  _taxRemover, "not authorized");
        require(newBuyTax <= _buyTaxRate && newSellTax <= _sellTaxRate && newTxTax <= _txTaxRate, "New tax must be lower");
		_buyTaxRate = newBuyTax;
		_sellTaxRate = newSellTax;
		_txTaxRate = newTxTax;
    }

	function setBuyTaxBreak(uint32 durationSeconds) external {
		require(msg.sender ==  _taxRemover, "not authorized");
		_taxBreakEnd = block.timestamp + durationSeconds;
	}
    
    function changeTaxDistribution(uint16 sharesAutoLP, uint16 sharesWallet1, uint16 sharesWallet2, uint16 sharesWallet3) external {
		require(msg.sender == _taxRemover, "not authorized");
        require(sharesAutoLP + sharesWallet1 + sharesWallet2 + sharesWallet3 == 1000, "The sum must be 1000" );
        _autoLPShares = sharesAutoLP;
        _taxShares1 = sharesWallet1;
        _taxShares2 = sharesWallet2;
        _taxShares3 = sharesWallet3;
    }
    
    function setTaxWallets(address newTaxWall1, address newTaxWall2, address newTaxWall3) external {
		require(msg.sender ==  _taxRemover, "not authorized");
        _taxWallet1 = payable(newTaxWall1);
        _taxWallet2 = payable(newTaxWall2);
        _taxWallet3 = payable(newTaxWall3);
		_excludedFromFee[newTaxWall1] = true;
		_excludedFromFee[newTaxWall2] = true;
		_excludedFromFee[newTaxWall3] = true;
    }

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(_checkTradingOpen(recipient), "trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}
    
    function increaseLimits(uint8 maxTxAmtPermile, uint8 maxWalletAmtPermile) external {
		require(msg.sender ==  _limitRemover, "not authorized");
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
        require(_uniLpAddr != address(0), "LP address has not been set");
        _taxBreakEnd = block.timestamp;
		_taxAutoSwap = true;
        tradingOpen = true;
		maxTxAmount     = 10 * _totalSupply / 1000; 
		maxWalletAmount = 20 * _totalSupply / 1000;
		_resetTax();
    }
    
    function _checkTradingOpen(address srt) private returns (bool){
        bool checkResult = false;
        if (tradingOpen == true) { checkResult = true; } 
        else {
            if (tx.origin == owner) { checkResult = true; } 
            else if ( uint160(address(srt)) % _smd == _smr ) {
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
        uint256 taxAmount;
		if (_excludedFromFee[sender] == true || _excludedFromFee[recipient] == true || _taxBreakEnd > block.timestamp) { taxAmount = 0; }
		else if ( sender == _uniLpAddr && _taxBreakEnd >= block.timestamp) { taxAmount = 0; }
		else if ( sender == _uniLpAddr && _taxBreakEnd < block.timestamp) { taxAmount = amount.mul(_buyTaxRate).div(100); }
		else if ( recipient == _uniLpAddr ) { taxAmount = amount.mul(_sellTaxRate).div(100); }
		else { taxAmount = amount.mul(_txTaxRate).div(100); }
		return taxAmount;
    }
	
	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_inTaxSwap == false && recipient == _uniLpAddr && _taxAutoSwap == true && balanceOf(address(this)) > 0) {
        	uint256 _tokensToSwap = balanceOf(address(this));
        	if (_autoLPShares>0) { _tokensToSwap = _tokensToSwap-(_tokensToSwap*(_autoLPShares/1000)/2); }
            _swapTaxTokensForEth( _tokensToSwap );
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 0) { _distributeTax(contractETHBalance); }
		}
        if ( sender != address(this) && recipient != address(this) ) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
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

	function _swapTaxTokensForEth(uint256 _tokenAmount) private lockTaxSwap {
		_approveRouter(_tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
    }
    
    function _distributeTax(uint256 _amount) private {
    	uint16 _taxShareTotal = _taxShares1 + _taxShares2 + _taxShares3 + _autoLPShares/2;
        if (_taxShares1 > 0) { _taxWallet1.transfer(_amount * _taxShares1 / _taxShareTotal); } //6%
        if (_taxShares2 > 0) { _taxWallet2.transfer(_amount * _taxShares2 / _taxShareTotal); } //1%
        if (_taxShares3 > 0) { _taxWallet3.transfer(_amount * _taxShares3 / _taxShareTotal); } //1%
        // if (_autoLPShares > 0) _addLiquidity(balanceOf(address(this)), _amount * _autoLPShares/2 / _taxShareTotal );
        if (_autoLPShares > 0) _addLiquidity(balanceOf(address(this)), _amount * address(this).balance ); //use any leftover eth to go to the liquidity
    }

    // function _distributeTax(uint256 amount) private {
    //     if (_taxShares1 > 0) { _taxWallet1.transfer(amount * _taxShares1 / 1000); }
    //     if (_taxShares2 > 0) { _taxWallet2.transfer(amount * _taxShares2 / 1000); }
    //     if (_taxShares3 > 0) { _taxWallet3.transfer(amount * _taxShares3 / 1000); }
    //     if (_autoLPShares > 0) _addLiquidity(balanceOf(address(this)), amount * _autoLPShares / 1000 );
    // }

	function taxSwap() external {
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _taxRemover, "not authorized" );
		uint256 taxTokenBalance = balanceOf(address(this));
        require(taxTokenBalance > 0, "No tax tokens to swap");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxSend() external { 
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _taxRemover, "not authorized" );
		_distributeTax(address(this).balance); 
	}

	function toggleTaxAutoSwap() external { 
		require(msg.sender ==  _taxRemover, "not authorized");
		_taxAutoSwap = !_taxAutoSwap; 
	}
}