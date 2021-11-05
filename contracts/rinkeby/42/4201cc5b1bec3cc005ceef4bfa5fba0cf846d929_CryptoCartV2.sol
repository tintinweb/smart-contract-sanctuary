/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

/** 
	   _____                  _         _____           _    __      _____  
	  / ____|                | |       / ____|         | |   \ \    / /__ \ 
	 | |     _ __ _   _ _ __ | |_ ___ | |     __ _ _ __| |_   \ \  / /   ) |
	 | |    | '__| | | | '_ \| __/ _ \| |    / _` | '__| __|   \ \/ /   / / 
	 | |____| |  | |_| | |_) | || (_) | |___| (_| | |  | |_     \  /   / /_ 
	  \_____|_|   \__, | .__/ \__\___/ \_____\__,_|_|   \__|     \/   |____|
				   __/ | |                                                  
				  |___/|_|                                                  
                                                          
   #CryptoCart V2
   
   Great features:
   -2% fee auto add to the liquidity pool
   -2% fee auto moved to vault address

   1,000,000 total supply
   
   2% fee for liquidity will go to an address that the contract creates, and the contract will sell it and add to liquidity automatically.
   2% fee for vault will go to an vault address.
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

abstract contract Editor is Context {
    address private _editor;

    event EditorRoleTransferred(address indexed previousEditor, address indexed newEditor);

    constructor () {
        address msgSender = _msgSender();
        _editor = msgSender;
        emit EditorRoleTransferred(address(0), msgSender);
    }
    
    function editors() public view virtual returns (address) {
        return _editor;
    }

    modifier onlyEditor() {
        require(editors() == _msgSender(), "caller is not the editors");
        _;
    }
	
    function transferEditorRole(address newEditor) public virtual onlyEditor {
        require(newEditor != address(0), "new editor is the zero address");
        emit EditorRoleTransferred(_editor, newEditor);
        _editor = newEditor;
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
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
        _decimals = 18;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);
	function WETH() external pure returns (address);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

library SafeMath {
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

contract CryptoCartV2 is ERC20, Ownable, Editor {
    using SafeMath for uint256;
	
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	
    bool private swapping;
	bool public swapEnable = true;
	
    uint256 public swapTokensAtAmount = 500 * (10**18);
	
	address public vaultAddress;
    uint256 public liquidityFee;
	uint256 public vaultFee;
	
    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
	
    constructor(address payable _vaultAddress, uint256 _liquidityFee, uint256 _vaultFee) ERC20("CryptoCart V2", "CCv2") {
	    vaultAddress = _vaultAddress;
		liquidityFee = _liquidityFee;
		vaultFee = _vaultFee;
		
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
		
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		
        excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);
        _mint(owner(), 1000000 * (10**18));
    }

    receive() external payable {
  	}
	
	function setSwapTokensAtAmount(uint256 swapTokens) external onlyOwner {
  	    swapTokensAtAmount = swapTokens * (10**18);
  	}

	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
    }
		
    function excludeFromFees(address account, bool excluded) public onlyOwner onlyEditor{
        require(_isExcludedFromFees[account] != excluded, "CCv2: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "CCv2: The Uniswap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "CCv2: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }
	
	function updateVaultAddress(address payable newAddress) public onlyOwner onlyEditor{
		vaultAddress = newAddress;
	}
	
	function updateVaultFee(uint256 newFee) public onlyOwner onlyEditor {
        require(newFee >= 0 && newFee <= 10000, "CCv2: vaultFee fee must be between 0 and 10000");
        vaultFee = newFee;
    }
	
	function updateLiquidityFee(uint256 newFee) public onlyOwner onlyEditor{
        require(newFee >= 0 && newFee <= 10000, "CCv2: Liquidity fee must be between 0 and 10000");
        liquidityFee = newFee;
    }
	
	function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
		
		if(automatedMarketMakerPairs[to])
		{
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= swapTokensAtAmount;
			
            if (!swapping && canSwap && swapEnable) {
                swapping = true;
				
				uint256 half = swapTokensAtAmount.div(2);
				uint256 otherHalf = swapTokensAtAmount.sub(half);
				
				swapTokensForETH(half);
				uint256 newBalance = address(this).balance;
				addLiquidity(otherHalf, newBalance);	
				
				emit SwapAndLiquify(half, newBalance, otherHalf);
                swapping = false;
            }
			
			bool takeFee = !swapping;
			
			if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
				takeFee = false;
			}
			
			if(takeFee) 
			{
				uint256 lfee = amount.div(10000).mul(liquidityFee);
				if(lfee > 0) {
				   super._transfer(from, address(this), lfee);
				}
				
				uint256 vfees = amount.div(10000).mul(vaultFee);
				if(vfees > 0) {
				   super._transfer(from, vaultAddress, vfees);
				}
				amount = amount.sub(vfees).sub(lfee);
			}
        }
        super._transfer(from, to, amount);
    }
	
	function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount, 0, 0, editors(), block.timestamp);
    }
	
    function swapTokensForETH(uint256 tokenAmount) private {
         address[] memory path = new address[](2);
         path[0] = address(this);
         path[1] = uniswapV2Router.WETH();
         _approve(address(this), address(uniswapV2Router), tokenAmount);
         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this),block.timestamp);
    }
	
	function dropTokens(address[] memory _recipients, uint256[] memory _amount) public{
        require(_recipients.length == _amount.length);
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
			require(balanceOf(msg.sender) >= _amount[i]);
			super._transfer(msg.sender, _recipients[i], _amount[i]);
        }
    }
	
	function dropTokensV2 (address[] memory _recipients, uint256  _amount) public{
        for (uint i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0));
			require(balanceOf(msg.sender) >= _amount);
			super._transfer(msg.sender, _recipients[i], _amount);
        }
    }
}