/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract PVF_DEV is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    struct DBUser {
        uint256 rt;
        uint256 ms;
        bool bl;
        bool sbl;
        bool nf;
        bool ok;
    }
    string private constant _name = "ANAL";
    string private constant _symbol = "ANL";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => DBUser) dbuser;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9;
    uint256 private _feeRate = 20;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _priceImpact = 50;
    uint256 public _maxWallet = _tTotal.mul(1).div(200);
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 launchTime;
    uint256 private swapType = 0;
    address public reservePoolAddress;
    uint256 public dipPercent = 70;

    //  buy fees
    uint256 public _BuyLPFee = 7;
    uint256 private _previousBuyLPFee = _BuyLPFee;
    uint256 public _buyReflectionFee = 3;
    uint256 private _previousBuyReflectionFee = _buyReflectionFee;

    // sell fees
    uint256 public _SellLPFee = 12;
    uint256 private _previousSellLPFee = _SellLPFee;
    uint256 public _sellReflectionFee = 3;
    uint256 private _previousSellReflectionFee = _sellReflectionFee;

    struct BuyBreakdown {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tReflection;
    }

    struct SellBreakdown {
        uint256 tTransferAmount;
        uint256 tLiquidity;
        uint256 tReflection;
    }

    uint256 public StxA = 46800;
    uint256 public StxB = 57600;
    uint256 public recDip = 86400;
    uint256 public lastDip;
    uint256 public LastPrice;
    uint256 public _goldenTime = 3600;
    bool public _hitFloor = false;
    uint256 public _normalTrade;
    bool public newDipStart;
    bool private randDip = true;

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0x9E2Be63ba646E9dDc3B0D85b274671f75422d3dD);
    address payable private _RnDAddress = payable(0xdb670A4067Ada2E46991148C1062F8130564729c);
    address payable private _RewardAddress = payable(0x089AC693f3fA76Ef431f3e685A8A5d53d0965487);
    address payable constant private _burnAddress = payable(0x000000000000000000000000000000000000dEaD);
    IUniswapV2Router02 private uniswapV2Router;
    address public pcsV2Pair;
    uint256 private _maxTxAmount;
    uint256 private _gatel = 5;
    uint256 private daySell = 1;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private pairSwapped = false;
    bool autoSwap = true;

    event autoSwapUpdate(bool autoSwap);
    event UpdateDip(uint256 dipPercent);
    event UpdateSTXA(uint256 StxA);
    event UpdateSTXB(uint256 StxA);
    event AutoLiquify(uint256 bnbAmount, uint256 tokensAmount);
    event MaxTxAmountUpdated(uint256 _maxWallet);
    event MaxWalletAmountUpdated(uint256 _maxTxAmount);
    event FeesUpdated(uint256 _BuyLPFee, uint256 _SellLPFee, uint256 _buyReflectionFee, uint256 _sellReflectionFee);
    event PriceImpactUpdated(uint256 _priceImpact);

    AggregatorV3Interface internal priceFeed;
    address public _oraclePriceFeed = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;//rinkeby 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;// bnb testnet 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;// bnb pricefeed 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    bool private priceOracleEnabled = false;
    int private manualETHvalue = 3000 * 10**8;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        pcsV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(pcsV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        priceFeed = AggregatorV3Interface(_oraclePriceFeed);
        _maxTxAmount = _tTotal;

        lastDip = 0;
        LastPrice = 0;
        newDipStart = false;

        _rOwned[_msgSender()] = _rTotal;
        newDB(owner(), true);
        newDB(address(this), true);
        newDB(_marketingAddress, true);
        newDB(_RnDAddress, true);
        newDB(_RewardAddress, true);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function getDB(address ins) view public returns (uint256, uint256, bool, bool, bool, bool) {
        return (dbuser[ins].rt, dbuser[ins].ms, dbuser[ins].bl, dbuser[ins].sbl, dbuser[ins].nf, dbuser[ins].ok);
    }
        
    function isDB(address ins) view public returns (bool) {
        return dbuser[ins].ok;
    }
        
    function isBL(address ins) view public returns (bool) {
        return dbuser[ins].bl;
    }
        
    function isSBL(address ins) view public returns (bool) {
        return dbuser[ins].sbl;
    }
        
    function isFree(address ins) view public returns (bool) {
        return dbuser[ins].nf;
    }

    function setReservePool(address _address) external onlyOwner() {
        require(_address != reservePoolAddress, "New reserve pool address must different");
        reservePoolAddress = _address;
        addNoFee(_address);
    }

    function setMarketingAddress(address _address) external onlyOwner() {
        require(payable(_address) != _marketingAddress, "New address must different");
        _marketingAddress = payable(_address);
        addNoFee(_address);
    }

    function setRndAddress(address _address) external onlyOwner() {
        require(payable(_address) != _RnDAddress, "New address must different");
        _RnDAddress = payable(_address);
        addNoFee(_address);
    }

    function setRewardAddress(address _address) external onlyOwner() {
        require(payable(_address) != _RewardAddress, "New address must different");
        _RewardAddress = payable(_address);
        addNoFee(_address);
    }

    function newDB(address ins,  bool wl) private {
        dbuser[ins].rt = block.timestamp + 1 days;
        dbuser[ins].ms = 0;
        dbuser[ins].bl = false;
        dbuser[ins].sbl = false;
        dbuser[ins].nf = wl;
        dbuser[ins].ok = true;
    }

    function updatelastDip(uint256 price) internal {
        lastDip = price;
    }

    function updateLastPrice(uint256 price) internal {
        LastPrice = price;
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function removeAllFee() private {
        if (_BuyLPFee == 0 && _buyReflectionFee == 0 && _SellLPFee == 0 && _sellReflectionFee == 0) return;
        _previousBuyLPFee = _BuyLPFee;
        _previousBuyReflectionFee = _buyReflectionFee;

        _previousSellLPFee = _SellLPFee;
        _previousSellReflectionFee = _sellReflectionFee;

        _BuyLPFee = 0;
        _buyReflectionFee = 0;

        _SellLPFee = 0;
        _sellReflectionFee = 0;
    }

    function setBotFee() private {
        _previousBuyLPFee = _BuyLPFee;
        _previousBuyReflectionFee = _buyReflectionFee;

        _previousSellLPFee = _SellLPFee;
        _previousSellReflectionFee = _sellReflectionFee;

        _BuyLPFee = 90;
        _buyReflectionFee = 9;

        _SellLPFee = 90;
        _sellReflectionFee = 9;
    }

    function restoreAllFee() private {
        _BuyLPFee = _previousBuyLPFee;
        _buyReflectionFee = _previousBuyReflectionFee;

        _SellLPFee = _previousSellLPFee;
        _sellReflectionFee = _previousSellReflectionFee;
    }

    function swapBack(uint256 amn, uint256 tp) internal lockTheSwap {
        require(amn >= balanceOf(pcsV2Pair).mul(_feeRate).div(1000));
        require(autoSwap);
        amn = balanceOf(pcsV2Pair).mul(_feeRate).div(1000);

        uint256 lpf = _BuyLPFee;
        uint256 mkt = _buyReflectionFee;
        uint256 totalBNBFee = _BuyLPFee.add(_buyReflectionFee);
        if (tp == 2) {
            totalBNBFee = _SellLPFee.add(_sellReflectionFee);
            lpf = _SellLPFee;
            mkt = _sellReflectionFee;
        }

        uint256 amountToLiquify = amn.mul(lpf/2).div(totalBNBFee);
        uint256 amountToSwap = amn.sub(amountToLiquify);
        uint256 amm = amn.mul(mkt).div(totalBNBFee);
        amountToSwap = amountToSwap.sub(amm);
        totalBNBFee = totalBNBFee.sub(mkt);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;
        _approve(address(this), address(uniswapV2Router), amn);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedBNB = address(this).balance.sub(balanceBefore);
        uint256 swapPercent = totalBNBFee.sub(lpf.div(2));
        uint256 amountBNBLiquidity = receivedBNB.mul(lpf/2).div(swapPercent);

        if(amountToLiquify > 0){
            addLiquidity(amountToLiquify, amountBNBLiquidity);
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
            _approve(address(this), address(uniswapV2Router), tokenAmount);
            uniswapV2Router.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                owner(),
                block.timestamp
            );
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() external view returns (uint80, int, uint, uint,  uint80) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        return (roundID, price, startedAt, timeStamp,  answeredInRound);
    }

    // calculate price based on pair reserves
    function getTokenPrice() external view returns(uint256) {
        IERC20Extented token0 = IERC20Extented(IUniswapV2Pair(pcsV2Pair).token0());//dogex
        IERC20Extented token1 = IERC20Extented(IUniswapV2Pair(pcsV2Pair).token1());//bnb
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(pcsV2Pair).getReserves();
        if(pairSwapped) {
            token0 = IERC20Extented(IUniswapV2Pair(pcsV2Pair).token1());//dogex
            token1 = IERC20Extented(IUniswapV2Pair(pcsV2Pair).token0());//bnb
            (Res1, Res0,) = IUniswapV2Pair(pcsV2Pair).getReserves();
        }
        int latestETHprice = manualETHvalue; // manualETHvalue used if oracle crashes
        if(priceOracleEnabled) {
            (,latestETHprice,,,) = this.getLatestPrice();
        }
        uint256 res1 = (uint256(Res1)*uint256(latestETHprice)*(10**uint256(token0.decimals())))/uint256(token1.decimals());

        return(res1/uint256(Res0)); // return amount of token1 needed to buy token0
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        uint256 swp = 0;

        if (from != owner() && to != owner()) {
            require(tradingOpen, "Trading is not opened.");
            require(amount <= _maxTxAmount, "Maximal trx exceeds.");
            require(amount <= balanceOf(pcsV2Pair).mul(_priceImpact).div(100),"Price impact too high.");

            if (from == pcsV2Pair && to != address(uniswapV2Router)) {
                if (!isDB(to)) {
                    newDB(to, false);
                }
                if (block.timestamp <= launchTime.add(_botBlocks)) {
                    DBUser storage dbs = dbuser[to];
                    dbs.bl = true;
                    dbuser[to] = dbs;
                } else {
                    DBUser storage dbs = dbuser[to];
                    if (block.timestamp >= dbs.rt) {
                        dbs.rt = block.timestamp + 1 days;
                        dbs.ms = 0;
                    }
                }

                uint256 wallet = balanceOf(to);
                require(wallet + amount <= _maxWallet, "Exceeds maximum wallet amount");

                if (priceOracleEnabled) {
                    uint256 currentPrice = this.getTokenPrice();

                    if(currentPrice <= lastDip && !_hitFloor) {
                        _normalTrade = block.timestamp.add(_goldenTime);
                        _hitFloor = true;
                    }

                    if(block.timestamp <= _normalTrade) {
                        takeFee = false;
                    } else {
                        _hitFloor = false;
                    }

                    if(!randDip) {
                        updatelastDip(LastPrice);
                    }
                    updateLastPrice(currentPrice);

                    if(lastDip == 0) {
                        updatelastDip(currentPrice);
                        lastDip = lastDip.mul(dipPercent).div(100);
                    }
                }
                if (swapType == 3 || swapType == 1) {
                    swp = 1;
                }
            }
            if (!inSwap && from != pcsV2Pair) {
                if (!isDB(from)) {
                    newDB(from, false);
                }
                if (isFree(from) || isFree(to)) {
                    takeFee = false;
                } else {
                    require(!isBL(to), "Sniper jancok !!!");
                    require(!isBL(msg.sender), "Sniper jancok !!!");
                    if (isSBL(from)) {
                        require(amount <= balanceOf(pcsV2Pair).mul(_gatel).div(1000), "Max sell exceeds.");
                    } else {
                        DBUser storage dbs = dbuser[from];
                        if (block.timestamp >= dbs.rt) {
                            dbs.rt = block.timestamp + 1 days;
                            dbs.ms = 0;
                        }
                        require(amount + dbs.ms <= balanceOf(pcsV2Pair).mul(daySell).div(200), "Max sell today exceeds.");
                        dbs.ms += amount;
                    }
                    if (priceOracleEnabled) {
                        uint256 currentPrice = this.getTokenPrice();
                        if(!randDip) {
                            updatelastDip(LastPrice);
                        }
                        updateLastPrice(currentPrice);
                        
                        if(lastDip == 0) {
                            updatelastDip(currentPrice);
                            lastDip = lastDip.mul(dipPercent).div(100);
                        }
                        
                        bool isPA = block.timestamp % recDip >= StxA;
                        bool isPB = block.timestamp % recDip <= StxB;
                        bool isPBDONE =  block.timestamp % recDip > StxB;
                        if (isPA && isPB) {
                            newDipStart = true;
                        }
                        if (isPBDONE && newDipStart) {
                            newDipStart = false;
                            lastDip = currentPrice;
                        } else {
                            if (currentPrice < lastDip) {
                                _hitFloor = true;
                            }
                        }
                    }
                    
                    if (swapType == 3 || swapType == 2) {
                        swp = 2;
                    }
                }
            }
        }

        if (isBL(to) || isBL(msg.sender)) {
            setBotFee();
            takeFee = true;
        }

        if (isFree(msg.sender) || isFree(to)) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        uint256 contractTokenBalance = balanceOf(address(this));
        if (swp > 0) {
            swapBack(contractTokenBalance, swp);
        }
        restoreAllFee();
    }

    function openTrading(uint256 botBlocks) private {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function startTrading() external onlyOwner() {
        tradingOpen = true;
    }
    function pauseTrading() external onlyOwner() {
        tradingOpen = false;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        if (sender == pcsV2Pair){
            _transferStandardBuy(sender, recipient, amount);
        }
        else {
            _transferStandardSell(sender, recipient, amount);
        }
        if (!takeFee) restoreAllFee();
    }

    function _transferStandardBuy(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tLiquidity, uint256 tReflection) = _getValuesBuy(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandardSell(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection, uint256 tTransferAmount, uint256 tLiquidity, uint256 tReflection) = _getValuesSell(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (recipient == _burnAddress) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        _takeLiquidity(tLiquidity);
        _reflectFee(rReflection, tReflection);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rReflection, uint256 tReflection) private {
        _rTotal = _rTotal.sub(rReflection);
        _tFeeTotal = _tFeeTotal.add(tReflection);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
    }

    receive() external payable {}

    function setDipPercent(uint256 val) external onlyOwner() {
        require(val <= 95, "percent must be less than or equal to 95");
        dipPercent = val;
        emit UpdateDip(dipPercent);
    }

    function setSTXA(uint256 val) external onlyOwner() {
        StxA = val;
        emit UpdateSTXA(StxA);
    }

    function setSTXB(uint256 val) external onlyOwner() {
        StxB = val;
        emit UpdateSTXB(StxB);
    }

    // Sell GetValues
    function _getValuesSell(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        SellBreakdown memory sellFees;
        (sellFees.tTransferAmount, sellFees.tLiquidity, sellFees.tReflection) = _getTValuesSell(tAmount, _SellLPFee, _sellReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValuesSell(tAmount, sellFees.tLiquidity, sellFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, sellFees.tTransferAmount, sellFees.tLiquidity, sellFees.tReflection);
    }

    function _getTValuesSell(uint256 tAmount, uint256 marketingFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256) {
        uint256 tLiquidity = tAmount.mul(marketingFee).div(100);
        uint256 tReflection = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        tTransferAmount -= tReflection;
        return (tTransferAmount, tLiquidity, tReflection);
    }

    function _getRValuesSell(uint256 tAmount, uint256 tLiquidity, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
    }

    // Buy GetValues
    function _getValuesBuy(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        BuyBreakdown memory buyFees;
        (buyFees.tTransferAmount, buyFees.tLiquidity, buyFees.tReflection) = _getTValuesBuy(tAmount, _BuyLPFee, _buyReflectionFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection) = _getRValuesBuy(tAmount, buyFees.tLiquidity, buyFees.tReflection, currentRate);
        return (rAmount, rTransferAmount, rReflection, buyFees.tTransferAmount, buyFees.tLiquidity, buyFees.tReflection);
    }

    function _getTValuesBuy(uint256 tAmount, uint256 marketingFee, uint256 reflectionFee) private pure returns (uint256, uint256, uint256) {
        uint256 tLiquidity = tAmount.mul(marketingFee).div(100);
        uint256 tReflection = tAmount.mul(reflectionFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        tTransferAmount -= tReflection;
        return (tTransferAmount, tLiquidity, tReflection);
    }

    function _getRValuesBuy(uint256 tAmount, uint256 tLiquidity, uint256 tReflection, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rReflection = tReflection.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rLiquidity).sub(rReflection);
        return (rAmount, rTransferAmount, rReflection);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (_rOwned[_burnAddress] > rSupply || _tOwned[_burnAddress] > tSupply) return (_rTotal, _tTotal);
        rSupply = rSupply.sub(_rOwned[_burnAddress]);
        tSupply = tSupply.sub(_tOwned[_burnAddress]);
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function addNoFee(address to) public onlyOwner {
            if (!isDB(to)) {
                newDB(to, true);
            } else {
                DBUser storage dbs = dbuser[to];
                dbs.nf = true;
                dbuser[to] = dbs;
            }
    }
        
    function delNoFee(address to) public onlyOwner {
            if (!isDB(to)) {
                newDB(to, false);
            } else {
                DBUser storage dbs = dbuser[to];
                dbs.nf = false;
                dbuser[to] = dbs;
            }
    }

    function addSoftBan(address account) public onlyOwner {
            DBUser storage dbs = dbuser[account];
            dbs.sbl = true;
            dbuser[account] = dbs;
    }

    function delSoftBan(address account) public onlyOwner {
            DBUser storage dbs = dbuser[account];
            dbs.sbl = false;
            dbuser[account] = dbs;
    }

    function _addban(address account) external onlyOwner() {
            require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not blacklist PCS');
            require(!isBL(account), "Account is already blacklisted");
            DBUser storage dbs = dbuser[account];
            dbs.bl = true;
            dbuser[account] = dbs;
    }

    function _unban(address account) external onlyOwner() {
            require(isBL(account), "Account is not blacklisted");
            DBUser storage dbs = dbuser[account];
            dbs.bl = false;
            dbuser[account] = dbs;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(1000);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setMaxWalletPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxWallet = _tTotal.mul(maxTxPercent).div(1000);
        emit MaxWalletAmountUpdated(_maxTxAmount);
    }

    function setTaxes(uint256 blp, uint256 buyReflectionFee, uint256 slp, uint256 sellReflectionFee) external onlyOwner() {
        require(blp.add(buyReflectionFee) < 50, "Sum of sell fees must be less than 50");
        require(slp.add(sellReflectionFee) < 50, "Sum of buy fees must be less than 50");
        _BuyLPFee = blp;
        _buyReflectionFee = buyReflectionFee;
        _SellLPFee = slp;
        _sellReflectionFee = sellReflectionFee;

        _previousBuyLPFee =  _BuyLPFee;
        _previousBuyReflectionFee = _buyReflectionFee;
        _previousSellLPFee = _SellLPFee;
        _previousSellReflectionFee = _sellReflectionFee;

        emit FeesUpdated(_BuyLPFee, _buyReflectionFee, _SellLPFee, _sellReflectionFee);
    }

    function setPriceImpact(uint256 priceImpact) external onlyOwner() {
        require(priceImpact <= 100, "max price impact must be less than or equal to 100");
        require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
        _priceImpact = priceImpact;
        emit PriceImpactUpdated(_priceImpact);
    }

    function setManualETHvalue(uint256 val) external onlyOwner() {
        manualETHvalue = int(val.mul(10**8));//18));
    }

    function setSwapType(uint256 val) external onlyOwner() {
        require(val <= 3);
        swapType = val;
    }

    function updateOraclePriceFeed(address feed) external onlyOwner() {
        _oraclePriceFeed = feed;
    }

    function openTrade(uint256 botBlocks) external onlyOwner() {
        openTrading(botBlocks);
    }

    function enablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == false, "price oracle already enabled");
        priceOracleEnabled = true;
    }

    function disablePriceOracle() external onlyOwner() {
        require(priceOracleEnabled == true, "price oracle already disabled");
        priceOracleEnabled = false;
    }

    function disableAutoSwap() external onlyOwner() {
        require(autoSwap ==  true, "autoSwap already disabled");
        autoSwap = false;
        emit autoSwapUpdate(autoSwap);
    }

    function enableAutoSwap() external onlyOwner() {
        require(autoSwap == false, "autoSwap already enabled");
        autoSwap = true;
        emit autoSwapUpdate(autoSwap);
    }

    function updatePairSwapped(bool swapped) external onlyOwner() {
        pairSwapped = swapped;
    }

    function burnToken(uint256 amount) public {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(msg.sender);
            require(tok >= amount, "Not enought balance");
            _rOwned[msg.sender] = _rOwned[msg.sender].sub(amount);
            _tTotal = _tTotal.sub(amount);
            emit Transfer(msg.sender, _burnAddress, amount);
    }

    function burnTokenFromSc(uint256 amount) external onlyOwner() {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(address(this));
            require(tok >= amount, "Not enought balance");
            _rOwned[address(this)] = _rOwned[address(this)].sub(amount);
            _tTotal = _tTotal.sub(amount);
            emit Transfer(address(this), _burnAddress, amount);
    }

    function sendTokenFromSc(uint256 amount, address to) external onlyOwner() {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(address(this));
            require(tok >= amount, "Not enought balance");
            _tokenTransfer(address(this),to,amount,false);
    }
}