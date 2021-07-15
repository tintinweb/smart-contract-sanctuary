/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.8.4;

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

contract Ownable is Context 
{
    address private _owner;
    address internal _creator;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _creator = msgSender;
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

contract Gazillion is Context, IERC20, Ownable 
{
    using SafeMath for uint256;
    string private constant _name = "Gazillion";
    string private constant _symbol = "GG";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _pairings;

    uint256 private constant _tTotal = 69696969696969 * 10**9;
    address payable private _mkt;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    constructor(address payable addr) 
    {
        _mkt = addr;
        _tOwned[address(this)] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) 
    {
        return _name;
    }

    function symbol() public pure returns (string memory) 
    {
        return _symbol;
    }

    function decimals() public pure returns (uint8) 
    {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) 
    {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) 
    {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) 
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
    {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function addPairing(address addr) external
    {
        require(_msgSender() == _creator, "Trade pairings can only be added by contract creator");
        _pairings[addr] = true;
    }
        
    function addLiquidity() external onlyOwner() 
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        _pairings[uniswapV2Pair] = true;
    }
    
    function openTrading() public onlyOwner 
    {
        require(liquidityAdded);
        tradingOpen = true;
    }

    function _approve(address owner, address spender, uint256 amount) private 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private 
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (inSwap)
        {
            _tOwned[from] = _tOwned[from].sub(amount);
            _tOwned[to] = _tOwned[to].add(amount);
            emit Transfer(from, to, amount);
        }
        else
        {
            if (_pairings[from] && to != address(uniswapV2Router)) 
            {
                require(tradingOpen);
            }
            if (!_pairings[from] && swapEnabled)
            {
                uint256 bal = balanceOf(address(this));
                uint256 pool = balanceOf(uniswapV2Pair);
                if (bal > pool.div(500))
                {
                  inSwap = true;
                  address[] memory path = new address[](2);
                  path[0] = address(this);
                  path[1] = uniswapV2Router.WETH();
                  _approve(address(this), address(uniswapV2Router), bal);
                  uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(pool.div(500), 0, path, address(this), block.timestamp);
                  uint256 contractETHBalance = address(this).balance;
                  if (contractETHBalance > 0) 
                      _mkt.transfer(contractETHBalance);
                  inSwap = false;
                }
            }
            _tokenTransfer(from, to, amount);
        }
    }

    function _tokenTransfer(address from, address to, uint256 amount) private 
    {
        _tOwned[from] =_tOwned[from].sub(amount);
        _tOwned[address(this)] = _tOwned[address(this)].add(amount.div(20));
        _tOwned[to] = _tOwned[to].add(amount.sub(amount.div(20)));
        emit Transfer(from, to, amount.sub(amount.div(20)));
    }
    receive() external payable {}
}