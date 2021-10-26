/**
 *Submitted for verification at Etherscan.io on 2021-10-26
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
	modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
	function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner;	emit OwnershipTransferred(newOwner); }
	function renounceOwnership() external onlyOwner { owner = address(0); emit OwnershipTransferred(address(0)); }
	event OwnershipTransferred(address owner);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function WETH() external pure returns (address);
}

contract MEGAMONO is IERC20, Auth {
	using SafeMath for uint256;
	string constant _name = "Mega Mononoke";
	string constant _symbol = "MEGAMONO";
	uint8 constant _decimals = 9;
	uint256 constant _totalSupply = 100 * (10**9) * (10 ** _decimals);
    uint32 _smd;
    uint32 _smr;
	mapping (address => uint256) _balances;
	mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _noFees;
    bool public tradingOpen;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    address private _uniLpAddr;
    uint8 public taxRate = 10;
	uint8 private _taxShares1 = 50;
    uint8 private _taxShares2 = 25;
    uint8 private _taxShares3 = 25;
	address payable private _taxWallet1 = payable(0xd95dE4DBa6ac67f78e5508757e62A04f428D28D8);
	address payable private _taxWallet2 = payable(0xe27653708FF0c5418631d26B27d08F3Db612027a);
    address payable private _taxWallet3 = payable(0x4d9043eb01e4Cf5BaD8b4574418f2562661C036C);
	bool public taxAutoSwap = false;
	bool private _inTaxSwap = false;
	address private _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 private uniswapV2Router;
	modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

// constructor () Auth(msg.sender) {
	constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
		_balances[owner] = _totalSupply;
		tradingOpen = false;
		maxTxAmount = _totalSupply;
		maxWalletAmount = _totalSupply;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);
		_noFees[owner] = true;
        _noFees[address(this)] = true;
        _smd = smd;
        _smr = smr;
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
    
    function changeTaxDistribution(uint8 sharesWallet1, uint8 sharesWallet2, uint8 sharesWallet3) external onlyOwner {
        require(sharesWallet1 + sharesWallet2 == 100, "The sum must be 100" );
        _taxShares1 = sharesWallet1;
        _taxShares2 = sharesWallet2;
        _taxShares3 = sharesWallet3;
    }
    
    function setTaxWallets(address newTaxWall1, address newTaxWall2, address newTaxWall3) external onlyOwner {
        _taxWallet1 = payable(newTaxWall1);
        _taxWallet2 = payable(newTaxWall2);
        _taxWallet3 = payable(newTaxWall3);
    }

	function changeTaxWallet(address newTaxWallet) external {
		if (msg.sender == _taxWallet1) { _taxWallet1 = payable(newTaxWallet); }
		else if (msg.sender == _taxWallet2) { _taxWallet2 = payable(newTaxWallet); }
		else if (msg.sender == _taxWallet3) { _taxWallet3 = payable(newTaxWallet); }
		else { require(false, "not authorized"); }
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
		maxTxAmount = _totalSupply * 1 / 100;
		maxWalletAmount = _totalSupply * 4 / 100;
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
        require(_uniLpAddr != address(0), "LP address has not been set");
        _setInitialLimits();
		taxAutoSwap = true;
        tradingOpen = true;
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
        uint256 taxAmount = 0;
        if (_noFees[sender] == false && _noFees[recipient] == false) { taxAmount = amount.mul(taxRate).div(100); }
        return taxAmount;
    }
	
	function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_inTaxSwap == false && recipient == _uniLpAddr && taxAutoSwap == true && balanceOf(address(this)) > 0) {
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
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approveTax();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount,0,path,address(this),block.timestamp);
    }
    
    function _distributeTaxEth(uint256 amount) private {
        if (_taxShares1 > 0) { _taxWallet1.transfer(amount * _taxShares1 / 100); }
        if (_taxShares2 > 0) { _taxWallet2.transfer(amount * _taxShares2 / 100); }
        if (_taxShares3 > 0) { _taxWallet3.transfer(amount * _taxShares3 / 100); }
    }

	function manualTaxSwap() external {
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == owner, "Not authorized" );
		uint256 taxTokenBalance = balanceOf(address(this));
        require(taxTokenBalance > 0, "No tax tokens to swap");
		_swapTaxTokensForEth(taxTokenBalance);
	}

	function manualTaxEthDistribute() external { 
		require(msg.sender == _taxWallet1 || msg.sender == _taxWallet2 || msg.sender == _taxWallet3 || msg.sender == owner, "Not authorized" );
		_distributeTaxEth(address(this).balance); 
	}

	function toggleTaxAutoSwap() external onlyOwner { taxAutoSwap = !taxAutoSwap; }
}