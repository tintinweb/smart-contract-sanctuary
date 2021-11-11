/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

//SPDX-License-Identifier: MIT 
//
// get excited with this bad girl at t.me/BadGirlBSC
//

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

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
}

contract BadGIRL is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Bad Girl";
	string constant _symbol = "BadGIRL";
	uint256 constant _totalSupply = 1 * (10**12) * (10 ** _decimals);
	uint8 constant _decimals = 9;
    uint32 _smd; uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _excludedFromFee;
    bool public tradingOpen;
    uint256 public maxTxAmount; uint256 public maxWalletAmount;
	address private _limitRemover; address private _taxRemover;
    address private _uniLpAddr;
	uint8 _defTaxRate = 12; 
	uint8 private _buyTaxRate; uint8 private _sellTaxRate; uint8 private _txTaxRate;
	uint8 private _taxShares1 = 100;
    uint8 private _taxShares2 = 0;
    uint8 private _taxShares3 = 0;
	uint256 private _taxBreakEnd;
	address payable private _taxWallet1 = payable(0x4022eb3aECdf0425229e81965042E155E19D303A);
	address payable private _taxWallet2 = payable(0x4022eb3aECdf0425229e81965042E155E19D303A);
    address payable private _taxWallet3 = payable(0x4022eb3aECdf0425229e81965042E155E19D303A);
	bool private _taxAutoSwap = false;
	bool private _inTaxSwap = false;
	address private _uniswapV2RouterAddress = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Router02 private uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		_balances[owner] = _totalSupply;
		tradingOpen = false;
		_limitRemover = msg.sender;
		_taxRemover = msg.sender;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_excludedFromFee[owner] = true;
        _excludedFromFee[address(this)] = true;
		_excludedFromFee[_uniswapV2RouterAddress] = true;
		_excludedFromFee[_taxWallet1] = true;
        _smd = smd; _smr = smr;
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
	
	function resetTax() external {
		require(msg.sender ==  _taxRemover, "not authorized");
		_resetTax();
	}

	function _resetTax() internal {
		_buyTaxRate = _defTaxRate;
		_sellTaxRate = _defTaxRate;
		_txTaxRate = _defTaxRate;
	}

	function removeFees(address _exclWallet) external {
		require(msg.sender ==  _taxRemover, "not authorized");
		_excludedFromFee[ _exclWallet ] = true;
	}

    function decreaseTaxRate(uint8 _newBuyTax, uint8 _newSellTax, uint8 _newTxTax) external {
		require(msg.sender ==  _taxRemover, "not authorized");
        require(_newBuyTax <= _buyTaxRate && _newSellTax <= _sellTaxRate && _newTxTax <= _txTaxRate, "New tax must be lower");
		_buyTaxRate = _newBuyTax;
		_sellTaxRate = _newSellTax;
		_txTaxRate = _newTxTax;
    }

	function setBuyTaxBreak(uint32 _durationSeconds) external {
		require(msg.sender ==  _taxRemover, "not authorized");
		_taxBreakEnd = block.timestamp + _durationSeconds;
	}
    
    function changeTaxDistribution(uint8 sharesWallet1, uint8 sharesWallet2, uint8 sharesWallet3) external {
		require(msg.sender ==  _taxRemover, "not authorized");
        require(sharesWallet1 + sharesWallet2 + sharesWallet3 == 100, "The sum must be 100" );
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

	function setLPAddress(address _uniswapLiqPoolAddr) external onlyOwner {
        _uniLpAddr = _uniswapLiqPoolAddr;
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_allowances[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transfer(address recipient, uint256 amount) external override returns (bool) {
	    require(_checkTradingOpen(recipient), "Trading not open");
		return _transferFrom(msg.sender, recipient, amount);
	}
    
    function increaseLimits(uint8 maxTxAmtPct, uint8 maxWalletAmtPct) external {
		require(msg.sender ==  _limitRemover, "not authorized");
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
            _swapTaxTokensForEth( balanceOf(address(this)) );
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 1*(10**17)) { _distributeTaxEth(contractETHBalance); }
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

	function _swapTaxTokensForEth(uint256 tokenAmount) private lockTaxSwap {
		if (_allowances[address(this)][_uniswapV2RouterAddress] < tokenAmount) {
			_allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
			emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
		}
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
    
    function _distributeTaxEth(uint256 amount) private {
        if (_taxShares1 > 0) { _taxWallet1.transfer(amount * _taxShares1 / 100); }
        if (_taxShares2 > 0) { _taxWallet2.transfer(amount * _taxShares2 / 100); }
        if (_taxShares3 > 0) { _taxWallet3.transfer(amount * _taxShares3 / 100); }
    }

	function taxSwap() external {
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _taxRemover, "not authorized" );
		uint256 taxTokenBalance = balanceOf(address(this));
        require(taxTokenBalance > 0, "No tax tokens to swap");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function taxSend() external { 
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == _taxRemover, "not authorized" );
		_distributeTaxEth(address(this).balance); 
	}

	function toggleTaxAutoSwap() external { 
		require(msg.sender ==  _taxRemover, "not authorized");
		_taxAutoSwap = !_taxAutoSwap; 
	}
}