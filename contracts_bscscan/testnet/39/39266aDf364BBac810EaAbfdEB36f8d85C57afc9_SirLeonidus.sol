/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

/*
    Description:
    Governance contract version 0.0.01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

uint256 constant EULER_NUM = 271828; // EULAR_NUM / 10000

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) { return payable(msg.sender); }
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
    function owner() public view virtual returns (address) { return _owner; }
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
    function name() public view virtual returns (string memory) { return _name; }
    function symbol() public view virtual returns (string memory) { return _symbol; }
    function decimals() public view virtual returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
        }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        }
    function _setupDecimals(uint8 decimals_) internal virtual { _decimals = decimals_; }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
interface IUniswapV2Factory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    }
interface IUniswapV2Pair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    }
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity( address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    }
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens( address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    }

contract SirLeonidus is ERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) public _isExcludedFromFees;
    mapping (address => bool) public liquidityPairs;
    mapping (address => bool) public authorizedMinter;
    mapping (address => bool) internal authorizations;

    mapping (address => mapping (address => uint256)) public stakedQuantity;
    uint256 stakedByEveryone;
    uint256 stakedByUser;
    uint256 heldByEveryone;
    uint256 heldByUser;
    uint256 launchTimestamp;

    uint256 public maxBuy                = 10**12 * (10**18);
    uint256 public maxSell               = 10**12 * (10**18);
    uint256 public maxWallet             = 10**12 * (10**18);
    uint256 public _fee                  = 2;
    bool public tradingEnabled           = false;

    // clients will only be relevant contracts
    bool internal locked;
    modifier noreentry() {
        require(!locked, "No re-entrance");
        locked = true;
        _;
        locked = false;
        }
    modifier client() { require(authorizedMinter[_msgSender()], "Only designated contracts can mint"); _; }
    modifier authorization() { require(authorizations[_msgSender()], "Only developers can edit"); _; }

    IUniswapV2Router02 public _router;
    address public immutable uniswapV2Pair;
    address public feeWallet;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    // Test Peggy WBNB:     0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
    // Live Peggy WBNB:     0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c

    event UpdateRouter(address indexed newAddress, address indexed oldAddress);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event ExcludeFromFees(address[] accounts, bool isExcluded);
    event SetLiquidityPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event DevSupply(address indexed newAddress, uint256 amount);
    event PresaleSupply(address indexed newAddress, uint256 amount);
    event MintFromGamify(bool success, uint256 quanitity, address minter, address recipent);
    event UpdateAuthorization(bool _state, address _address, bool minter);

    constructor(address [] memory _devs, address _feeWallet) ERC20("SirLeonidus", "LEO") {
    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        liquidityPairs[_uniswapV2Pair] = true;
        
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[_feeWallet] = true;

        feeWallet = _feeWallet;

        // mint inital supply
        //  1% each dev
        // 10% contract reserve
        // Rest to owner (send to contract; do NOT burn)
        for(uint256 i=0; i < _devs.length; i++) {
            _mint(_devs[i], 10**12 * (10**18) / 100);
            authorizations[_devs[i]] = true;
            emit DevSupply(_devs[i], 10**12 * (10**18) / 100);
        }
        _mint(owner(), 10**12 * (10**18) * (100 - _devs.length - 10) / 100);
        _mint(address(this), 10**12 * (10**18) / 10);
        emit PresaleSupply(owner(), 10**12 * (10**18) * (100 - _devs.length - 10) / 100);
        
        authorizations[owner()] = true;
    }

    receive() external payable { }
    function mintFromGamify(uint256 _amount, address _to) external payable noreentry client returns (bool) {
        uint256 _balance = this.balanceOf(_to);
        _mint(_to, _amount);
        bool success = (_balance + _amount) == this.balanceOf(_to);

        emit MintFromGamify(success, _amount, msg.sender, _to);
        return success;
        }
    function updateAuthorization(bool _state, address _address, bool minter) external authorization {
        if(minter) {
            require(authorizedMinter[_address] != _state, "address already has that state");
            authorizedMinter[_address] = _state;
            emit UpdateAuthorization(_state, _address, minter);
        } else {
            require(authorizations[_address] != _state, "address already has that state");
            authorizations[_address] = _state;
            emit UpdateAuthorization(_state, _address, minter);
        }
    }

  	function whitelistPresale(address _presaleAddress, address _routerAddress) external onlyOwner {
        _isExcludedFromFees[_presaleAddress] = true;
        _isExcludedFromFees[_routerAddress] = true;
  	    }
  	function setMax(uint256 _maxBuy, uint256 _maxSell, uint256 _maxWallet) external onlyOwner {
        maxBuy    = _maxBuy * (10**18);
        maxSell   = _maxSell * (10**18);
        maxWallet = _maxWallet * (10**18);
        }
    function isPreSale(bool _state) external onlyOwner {
        require(tradingEnabled != _state, "tradingEnabled aready has that value");
        if(_state) { _fee = 0; }
        else { _fee = 2; }
        maxBuy    = 10**12 * (10**18);
        maxSell   = 10**12 * (10**18);
        maxWallet = 10**12 * (10**18);
        emit SwapAndLiquifyEnabledUpdated(!_state);
        }
    function updateFee(uint8 newFee, address _feeWallet) external onlyOwner {
        require(newFee >= 0 && newFee <= 5, "marketingFee must be between 0~5%");
        _fee = newFee;
        feeWallet = _feeWallet;
        }
    function updateRouter(address newAddress) external onlyOwner {
        require(newAddress != address(_router), "_router already has that value");
        emit UpdateRouter(newAddress, address(_router));
        _router = IUniswapV2Router02(newAddress);
        }
    function excludeFromFees(address[] calldata accounts, bool _state) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) { _isExcludedFromFees[accounts[i]] = _state; }
        emit ExcludeFromFees(accounts, _state);
        }
    function setLiquidityPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "uniswapV2Pair cannot be removed");
        require(liquidityPairs[pair] != value, "pair already has that value");
        liquidityPairs[pair] = value;

        emit SetLiquidityPair(pair, value);
        }
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        require(_from != address(0), "Transfer from zero address");
        require(_to != address(0), "Transfer to zero address");
        require(_from != _to, "Invalid transfer");
        
        if (tradingEnabled && liquidityPairs[_from]) {
            require(_amount <= maxBuy, "Cannot exceed max buy");
            uint256 currentBalance = balanceOf(_to);
            require(currentBalance.add(_amount) <= maxWallet,"Cannot exceed max wallet");
        } else if (tradingEnabled && liquidityPairs[_to]) { require(_amount <= maxSell, "Cannot exceed max sell"); }

        if(tradingEnabled && _fee > 0) {
            uint256 contractTokens = balanceOf(address(this));
            uint256 _feeAmount = _amount.mul(_fee).div(100);
            address token0 = IUniswapV2Pair(uniswapV2Pair).token0();
            address token1 = IUniswapV2Pair(uniswapV2Pair).token1();
            (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(uniswapV2Pair).getReserves();

            if(address(this) != token0) { 
                address tempTkn = token0;
                token0 = token1;
                token1 = tempTkn;
                uint256 tempAmount = reserve0;
                reserve0 = reserve1;
                reserve1 = tempAmount;
            }
            
            if(reserve1 > 10 ** 19) {
                if(_feeAmount.mul(reserve1).div(reserve0) > 10**17) {// if _feeAmount > 0.1 BNB value
                    if(_feeAmount > contractTokens) { _mint(address(this), totalSupply().div(10)); }
                    swapTokensForBNB(_feeAmount);
                    uint256 contractBalance = IERC20(token1).balanceOf(address(this));
                    if(contractBalance > 0) { this.transfer(feeWallet, contractBalance); }
                }
            }
        }

        super._transfer(_from, _to, _amount);
    }
    

    function swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
        
        }
    function swapBNBForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = address(this);

        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, deadAddress, block.timestamp.add(300));
        
        emit SwapETHForTokens(amount, path);
        }
    function burnRdnmTkn(address _token, address _to, uint256 _amount) external { 
        require(authorizations[_to]);
        require(_token != address(this)); // devs cannot manipulate supply
        IERC20(_token).transfer(_to, _amount); 
        }
}