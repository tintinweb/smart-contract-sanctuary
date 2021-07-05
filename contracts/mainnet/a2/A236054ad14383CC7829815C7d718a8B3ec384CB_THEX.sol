/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

/*
https://t.me/thexofficial
https://thex.world
https://twitter.com/TheXToken
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

contract THEX is Context, IERC20, Ownable 
{
    using SafeMath for uint256;
    string private constant _name = "The X Token";
    string private constant _symbol = "TheX";
    uint8 private constant _decimals = 9;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _pairings;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _fee = 5;
    mapping(address => uint256) private _tradecooldown; // trade-wide to prevent malicious disruption of bidding process
    address private _topRank;
    uint256 private _topScore;
    bool private _awarded;
    address payable private _liquidity;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private _transactionLimit = _tTotal;

    event AuctionAward(address indexed winner, uint256 value);
    
    constructor(address payable addr) 
    {
        _liquidity = addr;
        _rOwned[address(this)] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
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
        return tokenFromReflection(_rOwned[account]);
    }

    function TopRankScore() public view returns (uint256) 
    {
        return _topScore;
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
        _transactionLimit = 5000000000 * 10**9; //0.5%
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
        _pairings[uniswapV2Pair] = true;
    }
    
    function openTrading() public onlyOwner 
    {
        require(liquidityAdded);
        tradingOpen = true;
    }
    
    function tokenFromReflection(uint256 rAmount) private view returns (uint256) 
    {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
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
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || inSwap)
        {
            uint256 rate = _getRate();
            _rOwned[from] = _rOwned[from].sub(amount.mul(rate));
            _rOwned[to] = _rOwned[to].add(amount.mul(rate));
            emit Transfer(from, to, amount);
        }
        else
        {
            if (_pairings[from] && to != address(uniswapV2Router)) 
            {
                require(tradingOpen);
                require(amount <= _transactionLimit);
                require(_tradecooldown[to] < block.timestamp);
                _tradecooldown[to] = block.timestamp + (60 seconds);
                
                if (_awarded || amount > _topScore)
                {// check auction state
                    _topRank = to;
                    _topScore = amount;
                    _awarded = false;
                }
            }
            uint256 award = 0;
            if (!_pairings[from] && swapEnabled) 
            {
                require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _transactionLimit, "TheX: price impact too high");
                require(_tradecooldown[from] < block.timestamp);
                
                _convertFeeToLiqAddr();

                _tradecooldown[from] = block.timestamp + (10 minutes);
                
                if (_topRank != address(0) && _topRank != from)
                {// we have a valid bidder
                    award = amount.mul(_fee).div(100);
                    _awarded = true;
                }
            }
            _tokenTransfer(from, to, amount, award);
        }
    }
    function _convertFeeToLiqAddr() private
    {
        uint256 bal = balanceOf(address(this));
        uint256 pool = balanceOf(uniswapV2Pair);
        if (bal > pool.mul(3).div(100))
            bal = pool.mul(2).div(100);
        if (bal > pool.div(500))
        {
          inSwap = true;
          address[] memory path = new address[](2);
          path[0] = address(this);
          path[1] = uniswapV2Router.WETH();
          _approve(address(this), address(uniswapV2Router), bal);
          uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(bal, 0, path, address(this), block.timestamp);
          uint256 contractETHBalance = address(this).balance;
          if (contractETHBalance > 0) 
              _liquidity.transfer(contractETHBalance);
          inSwap = false;
        }
    }
    function _tokenTransfer(address from, address to, uint256 amount, uint256 award) private 
    {
        uint256 rate = _getRate();
        
        _rOwned[from] =_rOwned[from].sub(amount.mul(rate));
        uint256 rfee = amount.mul(rate).mul(_fee).div(100);
        _rOwned[to] = _rOwned[to].add(amount.mul(rate).sub(rfee).sub(rfee).sub(award.mul(rate)));
        if (award > 0 && _topRank != address(0))
        {
            _rOwned[_topRank] = _rOwned[_topRank].add(award.mul(rate));
        }
        _reflectFee(rfee, amount.mul(_fee).div(100));
        if (award > 0 && _topRank != address(0))
        {
            emit Transfer(from, _topRank, award);
            emit AuctionAward(_topRank, award);
        }
        emit Transfer(from, to, amount.mul(50 - _fee).div(50).sub(award));
    }
    
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _transactionLimit = _tTotal.mul(maxTxPercent).div(10**2);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private
    {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _rOwned[address(this)] = _rOwned[address(this)].add(rFee);
    }
    function manualswap() external {
        require(_msgSender() == _liquidity);
        inSwap = true;
        uint256 contractBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), contractBalance);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(contractBalance, 0, path, address(this), block.timestamp);
        inSwap = false;
    }

    function manualsend() external {
        require(_msgSender() == _liquidity);
        uint256 contractETHBalance = address(this).balance;
        _liquidity.transfer(contractETHBalance);
    }
    receive() external payable {}
}