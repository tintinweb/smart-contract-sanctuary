/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline) external returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}
/**
 * uniswap 
 * tax = 5%
 * transfer = 10% burn.
 * 
 */
contract EthereuMatrix is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "EMBETA";
    string private constant _symbol = "EM6";
    uint256 private  _totalSupply = 1000000000 *10 ** 18;
    address payable private _marketAddr;
    address public _routerAddress;
    uint256 public _OpenTradingBlockNo;
    uint256 public _burnedAmount;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping(address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private bots;
    
    bool private _swapEnabled;
    bool private inSwap = false;

    uint8 _taxFee = 5;
    uint8 _burnFee = 10;
    
    uint256 _minAmountTokenForSwap = 100000 * 10**18;

    uint256 _maxTxAmount = 100000 * 10**18;

    event TadingOpen(bool _openTrading);
    event Tax(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyMarketOfficer() {
        require(_marketAddr == _msgSender(), "Ownable: caller is not the Market Officer");
        _;
    }
    
    constructor(address payable marketAddr, address routerAddress) {
        _marketAddr = marketAddr;

        _swapEnabled = false;
        _routerAddress = routerAddress;
        _balances[msg.sender]= _totalSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketAddr] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                            .createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function openTrading() external onlyOwner(){
        _swapEnabled = true;
        _OpenTradingBlockNo = block.number;
        emit TadingOpen(true);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure  returns (uint8) {
        return 18;
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
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalBurned() public view returns (uint256) {
        return _burnedAmount;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));

        return true;
    }
   
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERR:invalid amount");

        uint256 fromBalance = _balances[from];
        
        _balances[from] = fromBalance.sub(amount, "ERC20: transfer amount exceeds balance");

        if(owner() == from || to == owner() || _isExcludedFromFee[from] || _isExcludedFromFee[to]){
            _balances[to] += amount;
            emit Transfer(from, to, amount);
            return;
        }

        if(inSwap){
            _balances[to] += amount;
            return;
        }

        _transferStandard(from,to,amount);    
    }

    function _transferStandard(address from, address to, uint256 amount) internal {
        
        require(_swapEnabled, "ERR: swap not enabled.");
        
        if(from != uniswapV2Pair && (to == uniswapV2Pair || to == _routerAddress)){

            require(!bots[from] && !bots[to], "ERR: locked.");

            swapTokensForEth();
            
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }

            emit Transfer(from, to, amount);
            
        } else if(from == uniswapV2Pair || from == _routerAddress){
            
            if(block.number - _OpenTradingBlockNo <= 5){
                bots[to] = true;
            }

            uint256 tax = amount.mul(_taxFee).div(100);
            uint256 finalAmount = amount.sub(tax);
            _balances[to] += finalAmount;
            _balances[address(this)] += tax;

            emit Transfer(from, to, finalAmount);
            emit Tax(from, to, tax);
        } else {
            uint256 burned = amount.mul(_burnFee).div(100);
            uint256 finalAmount = amount.sub(burned);
            _balances[to] += finalAmount;
            _burnedAmount += burned;
            _totalSupply -= burned;

            emit Transfer(from, to, finalAmount);
            emit Burn(from, to, burned);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal  {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function swapTokensForEth() private lockTheSwap {
        uint256 tokenAmount = _balances[address(this)];
        if(tokenAmount < _minAmountTokenForSwap){
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _marketAddr,
            block.timestamp
        );
    }

    function manualswap() external onlyMarketOfficer() {
        swapTokensForEth();
    }

    function ban(address botAddr) external onlyMarketOfficer() {
        bots[botAddr] = true;
    }

    function free(address botAddr) external onlyMarketOfficer() {
        bots[botAddr] = false;
    }
    
    function sendETHToFee(uint256 amount) private {
        _marketAddr.transfer(amount);
    }

    function balanceOfThis() public view returns (uint256) {
        return _balances[address(this)];
    }
}