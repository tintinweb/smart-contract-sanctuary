// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "./ContractImports.sol";

contract BasicTokenTestV7 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private _name = "BasicTokenTestV7";
    string private _symbol = "BTTV7";

    uint8 private _decimals = 18;

    uint256 private _totalSupply = 1 * 10**9 * 10**_decimals;

    uint256 public _devFee = 5;

    address payable public _devWalletAddress = payable(0x45e81C742d8B6A05B30b63f4879dc4Fec374acD2);

    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;
    
    bool _inSwappingTokens;
    bool public _swapTokensEnabled = true;
    
    uint256 public _maxTxAmount = _totalSupply;
    uint256 private _minTokensToSwap = _totalSupply.div(1000);
    
    modifier lockTheSwap {
        _inSwappingTokens = true;
        _;
        _inSwappingTokens = false;
    }
    
    constructor() {

        // Set UniswapV2Router address
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

        // Create UniswapV2Pair for token
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);

        // Set remainder of the contract variables
        _uniswapV2Router = uniswapV2Router;
        
        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Assign all tokens to owner
        _balances[_msgSender()] = _totalSupply;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    // Allow contract to recieve ETH from UniswapV2Router when swapping
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function setDevFeePercentage(uint256 devFee) external onlyOwner() {
        _devFee = devFee;
    }
   
    function setMaxTxPercentage(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _totalSupply.mul(maxTxPercent).div(100);
    }

    function setSwapTokensEnabled(bool enabled) public onlyOwner {
        _swapTokensEnabled = enabled;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // Initiate swapTokens if contract token balance meets minimum
        // amount of tokens needed for swap.

        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance > _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        
        bool meetsMinimumTokenBalance = contractTokenBalance >= _minTokensToSwap;

        if (
            meetsMinimumTokenBalance &&
            !_inSwappingTokens &&
            _swapTokensEnabled
        ) {
            swapTokensForETH(_minTokensToSwap);
        }
        
        // Transfer tokens

        uint256 totalTransferAmount = amount;

        _balances[from] = _balances[from].sub(amount);

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            uint256 feeAmount = calculateDevFee(amount);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            amount = amount.sub(feeAmount);
        }
        
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, totalTransferAmount);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Swap tokens for ETH
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _devWalletAddress,
            block.timestamp
        );
    }
    
    function calculateDevFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_devFee).div(100);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(_uniswapV2Router), "Alert: The router already has that address");
        _uniswapV2Router = IUniswapV2Router02(newAddress);
        address uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Pair = uniswapV2Pair;
    }
}