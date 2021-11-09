/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

/*
 -----------------------BitRides.sol --------------------------
                
                name     : BitRides
                symbol   : RIDES
                decimals : 9
                supply   : 10 000 000 000
------------------------------------------------------------

  ____    _   _     ____    _       _              
 | __ )  (_) | |_  |  _ \  (_)   __| |   ___   ___ 
 |  _ \  | | | __| | |_) | | |  / _` |  / _ \ / __|
 | |_) | | | | |_  |  _ <  | | | (_| | |  __/ \__ \
 |____/  |_|  \__| |_| \_\ |_|  \__,_|  \___| |___/
                                                   
  ___
    _-_-  _/\______\\__
 _-_-__  / ,-. -|-  ,-.`-.
    _-_- `( o )----( o )-'
           `-'      `-'


Author/Dev: MoonMan
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
 */
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * Source: https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template
 */
interface IBEP20 {

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

/**
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the addressZero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * Source: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
 */
interface IUniswapV2Factory {
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

/**
 * Source: https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
 */
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

    function permit(address owner, address spender, uint value, uint addressDeadline, uint8 v, bytes32 r, bytes32 s) external;

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

/**
 * Source: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
 */
 interface IUniswapV2Router01 {
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
        uint addressDeadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint addressDeadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint addressDeadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint addressDeadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint addressDeadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint addressDeadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint addressDeadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint addressDeadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint addressDeadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint addressDeadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint addressDeadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint addressDeadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * Source: https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
 */
 interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint addressDeadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint addressDeadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint addressDeadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint addressDeadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint addressDeadline
    ) external;
}

/*
 * Contract Inteface with virtual methods
 * : Methods used to process dividend rewards
 */ 
interface IRewardsDistributor {
    
    // set the minimum amount of tokens and the minimum time period for a distribution
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    
    // process existing RIDES dividend rewards for the shareholder if any are present, then set the amount owed to the shareholder
    function setShareBitRides(address shareholder, uint256 amount) external;
    
    // process existing WBNB dividend rewards for the shareholder if any are present, then set the amount owed to the shareholder
    function setShareWBNB(address shareholder, uint256 amount) external;
    
    // deposit RIDES rewards to the BitRides contract
    function depositBitrides() external payable;
    
    // deposit WBNB rewards to the BitRides contract
    function depositWBNB() external payable;
    
    // process eligible dividend rewards
    function process(uint256 gas) external;
}

/*
 * Contract Inteface implementation for IRewardsDistributor
 * : Methods used to process dividend rewards
 */ 
contract RewardsDistributor is IRewardsDistributor {
    using SafeMath for uint256;

    // initialized during the contract constructor, set to the RIDES token contract
    address _token;

    // struct to hold data for dividend reward
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // initialized during the contract constructor, set to the Pancakeswap V2 router
    IUniswapV2Router02 _pancakeswapV2Router2;
            
    // 2% reward paid in BITRIDES
    IBEP20 addressRewardBitrides = IBEP20(address(this)); 
            
    // 3% reward paid in WBNB
    IBEP20 addressRewardWBNB = IBEP20(address(this)); 
    
    // list of dividend rewards shareholders
    address[] shareholders;
    
    // hashmap of shareholder indexes, what position of the list is x shareholder ?
    mapping (address => uint256) shareholderIndexes;
    
    // hashmap of shareholder claim times, measured in this block's timestamp
    mapping (address => uint256) shareholderClaims;

    // hashmap of shareholders to RIDES Share data structs containing their current dividend reward info 
    mapping (address => Share) public sharesBitRides;

    // hashmap of shareholders to WBNB Share data structs containing their current dividend reward info 
    mapping (address => Share) public sharesWBNB;

    // total token RIDES shares available
    uint256 public totalBitRidesShares;
    
    // total token WBNB shares available
    uint256 public totalWBNBShares;
    
    // total dividend RIDES token rewards accumulated
    uint256 public totalRidesTokenDividends;
    
    // total dividend WBNB rewards accumulated
    uint256 public totalWBNBDividends;
    
    // total dividend RIDES token rewards paid out
    uint256 public totalDistributed;
    
    // total dividend WBNB rewards paid out
    uint256 public totalWBNBDistributed;
    
    // dividends RIDES tokens per share calculated
    uint256 public dividendsRidesTokenPerShare;
    
    // dividends WBNB per share calculated
    uint256 public dividendsWBNBPerShare;
    
    // RIDES token dividends per share accuracy
    uint256 public dividendsRidesTokenPerShareAccuracyFactor = 10 ** 36;

    // WBNB dividends per share accuracy
    uint256 public dividendsWBNBPerShareAccuracyFactor = 10 ** 36;

    // minimum period between dividend reward distributions
    uint256 public minPeriod = 45 minutes;
    
    // minimum dividend reward amount before it can be distributed
    uint256 public minDistribution = 1 * (10 ** 18);

    /*
     * index of the current shareholder getting a dividend reward
     * Used as the shareholders are cycled through one by one until the gas runs out.
     * Eventually when the last shareholder gets their reward, it goes back to zero and starts over again from the first shareholder
     */
    uint256 currentIndex;

    // has this contract been initialized ?
    bool initialized;
    
    // initialization method
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    // checks that the sender is the RIDES token contract address
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    // initialize the Pancakeswap V2 router
    constructor (address _router) {

             _pancakeswapV2Router2 = _router != address(0)
            ? IUniswapV2Router02(_router)
            : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }
    
    /*
     * Can be called by the RIDES token contract address
     * : sets the token distribution params
     */ 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    /*
     * Can be called by the RIDES token contract address
     * : distributes pending shareholder dividend rewards, and updates the shareholder's dividend reward amount
     */ 
    function setShareBitRides(address shareholder, uint256 amount) external override onlyToken {
        if(sharesBitRides[shareholder].amount > 0){
            distributeDividendBitRides(shareholder);
        }

        if(amount > 0 && sharesBitRides[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && sharesBitRides[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalBitRidesShares = totalBitRidesShares.sub(sharesBitRides[shareholder].amount).add(amount);
        sharesBitRides[shareholder].amount = amount;
        sharesBitRides[shareholder].totalExcluded = getCumulativeDividendsBitRides(sharesBitRides[shareholder].amount);
    }
    
    /*
     * Can be called by the WBNB token contract address
     * : distributes pending shareholder dividend rewards, and updates the shareholder's dividend reward amount
     */ 
    function setShareWBNB(address shareholder, uint256 amount) external override onlyToken {
        if(sharesWBNB[shareholder].amount > 0){
            distributeDividendBitRides(shareholder);
        }

        if(amount > 0 && sharesWBNB[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && sharesBitRides[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalWBNBShares = totalWBNBShares.sub(sharesWBNB[shareholder].amount).add(amount);
        sharesWBNB[shareholder].amount = amount;
        sharesWBNB[shareholder].totalExcluded = getCumulativeDividendsWBNB(sharesWBNB[shareholder].amount);
    }

    /*
     * Can be called by the RIDES token contract address
     * : convert and deposit WBNB from the sender to the RIDES contract and keep it for the reflection of RIDES tokens back to the shareholders
     */ 

    function depositBitrides() external payable override onlyToken {
        uint256 balanceBefore = addressRewardBitrides.balanceOf(address(this));
    
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router2.WETH();
        path[1] = address(addressRewardBitrides);
        
        uint256 amount = addressRewardBitrides.balanceOf(address(this)).sub(balanceBefore);

        totalRidesTokenDividends = totalRidesTokenDividends.add(amount);
        dividendsRidesTokenPerShare = dividendsRidesTokenPerShare.add(dividendsRidesTokenPerShareAccuracyFactor.mul(amount).div(totalBitRidesShares));
    }
    
     /*
     * Can be called by the WBNB contract address
     * : deposit WBNB from the sender to WBNB in the contract and keep it for the reflection of WBNB back to the shareholders
     */ 

    function depositWBNB() external payable override onlyToken {
        uint256 balanceBefore = addressRewardWBNB.balanceOf(address(this));
    
        address[] memory path = new address[](2);
        path[0] = _pancakeswapV2Router2.WETH();
        path[1] = address(addressRewardWBNB);

        _pancakeswapV2Router2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = addressRewardWBNB.balanceOf(address(this)).sub(balanceBefore);

        totalWBNBDividends = totalWBNBDividends.add(amount);
        dividendsWBNBPerShare = dividendsWBNBPerShare.add(dividendsRidesTokenPerShareAccuracyFactor.mul(amount).div(totalWBNBShares));
    }

    /*
     * Can be called by the RIDES token contract address
     * : process eligible dividend rewards
     */ 
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if (shouldDistributeBitRides(shareholders[currentIndex]) && shouldDistributeWBNB(shareholders[currentIndex])) {
                distributeDividendBitRides(shareholders[currentIndex]);
                distributeDividendWBNB(shareholders[currentIndex]);
            }
        
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    /*
     * Internal function only
     * : checks to see if the shareholder has met the minimum requirements for a RIDES dividend reward distribution
     */ 
    function shouldDistributeBitRides(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarningsBitRides(shareholder) > minDistribution;
    }
    
    /*
     * Internal function only
     * : checks to see if the shareholder has met the minimum requirements for a WBNB dividend reward distribution
     */ 
    function shouldDistributeWBNB(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarningsWBNB(shareholder) > minDistribution;
    }

    /*
     * Internal function only
     * : send the shareholder the RIDES dividend reward distribution, and update the totals
     */ 
    function distributeDividendBitRides(address shareholder) internal {
        if(sharesBitRides[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsBitRides(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            addressRewardBitrides.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            sharesBitRides[shareholder].totalRealised = sharesBitRides[shareholder].totalRealised.add(amount);
            sharesBitRides[shareholder].totalExcluded = getCumulativeDividendsBitRides(sharesBitRides[shareholder].amount);
        }
    }
    
    /*
     * Internal function only
     * : send the shareholder the WBNB dividend reward distribution, and update the totals
     */ 
    function distributeDividendWBNB(address shareholder) internal {
        if(sharesWBNB[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsWBNB(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            addressRewardWBNB.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            sharesWBNB[shareholder].totalRealised = sharesWBNB[shareholder].totalRealised.add(amount);
            sharesWBNB[shareholder].totalExcluded = getCumulativeDividendsWBNB(sharesWBNB[shareholder].amount);
        }
    }

    /*
     * Can be called by anyone
     * : immediately claim dividend RIDES rewards if eligible
     */ 
    function claimDividendBitRides() external {
        distributeDividendBitRides(msg.sender);
    }
    
    /*
     * Can be called by anyone
     * : immediately claim dividend WBNBrewards if eligible
     */ 
    function claimDividendWBNB() external {
        distributeDividendWBNB(msg.sender);
    }

    /*
     * Can be called by anyone
     * : see the amount of dividend rewards in RIDES are currently owned to the shareholder address
     */ 
    function getUnpaidEarningsBitRides(address shareholder) public view returns (uint256) {
        if(sharesBitRides[shareholder].amount == 0){ return 0; }

        uint256 shareholdertotalRidesTokenDividends = getCumulativeDividendsBitRides(sharesBitRides[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesBitRides[shareholder].totalExcluded;

        if(shareholdertotalRidesTokenDividends <= shareholderTotalExcluded){ return 0; }

        return shareholdertotalRidesTokenDividends.sub(shareholderTotalExcluded);
    }
    
    /*
     * Can be called by anyone
     * : see the amount of dividend rewards in WBNB are currently owned to the shareholder address
     */ 
    function getUnpaidEarningsWBNB(address shareholder) public view returns (uint256) {
        if(sharesWBNB[shareholder].amount == 0){ return 0; }

        uint256 shareholdertotalWBNBDividends = getCumulativeDividendsWBNB(sharesWBNB[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesWBNB[shareholder].totalExcluded;

        if(shareholdertotalWBNBDividends <= shareholderTotalExcluded){ return 0; }

        return shareholdertotalWBNBDividends.sub(shareholderTotalExcluded);
    }

    /*
     * Internal function only
     * : calculate how many total dividend RIDES rewards were received for a shareholder
     */ 
    function getCumulativeDividendsBitRides(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsWBNBPerShare).div(dividendsWBNBPerShareAccuracyFactor);
    }
    
    /*
     * Internal function only
     * : calculate how many total dividend WBNB rewards were received for a shareholder
     */ 
    function getCumulativeDividendsWBNB(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsWBNBPerShare).div(dividendsWBNBPerShareAccuracyFactor);
    }

    /*
     * Internal function only
     * : add a new shareholder
     */ 
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /*
     * Internal function only
     * : remove a shareholder
     */ 
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract BitRides is IBEP20, Ownable {
    using SafeMath for uint256;
    
    // Token name
    string constant _name       = "BitRides";
    
    // Token symbol
    string constant _symbol     = "RIDES";
    
    // Token decimals
    uint8 constant _decimals    = 9;
    
    // How much percetage of LP is sent back to the BSC dead address
    uint256 liquidityFee        = 4;
    
    // How much percetage is sent to the marketing address
    uint256 marketingFee        = 4;
    
    // How much percetage in RIDES is sent to the shareholders
    uint256 reflectionFeeBitRides = 2;
    
    // How much percetage in WBNB is sent to the shareholders
    uint256 reflectionWBNBFee  = 3;
    
    // total sum fee percentage
	uint256 public totalFee     = 13;
    
    // fee denominator 100%
    uint256 feeDenominator      = 100;
    
    // are we deploying the contract to the BSC testnet or the mainnet?
    bool testnetEnabled     = true;
    
    // the contract address for the BUSD reward tokens
    address addressBusd     = 0x55d398326f99059fF775485246999027B3197955;
    
    // BSC dead address
    address addressDead     = 0x000000000000000000000000000000000000dEaD;
    
    // BSC zero address
    address addressZero     = 0x0000000000000000000000000000000000000000;
    
    // uint256 maximum
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    // PancakeSwap mainnet router address
    address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    // PancakeSwap testtnet router address
    address routerAddressTestnet = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    // total supply of tokens ( 10,000,000,000 )
    uint256 _totalTokenAmount = 10 * 10**9 * (10 ** _decimals);
    
    // maximum transaction token amount ( 1,000,000,000 )
    uint256 public _maxTxAmount = _totalTokenAmount * 10 / 100;

    // max wallet can hold of 2% of the total token amount
    uint256 public _maxWalletToken = ( _totalTokenAmount * 20 ) / 100;

    // hashmap of addresses to token balances
    mapping (address => uint256) _balances;
    
    // hashmap of addresses to token allowances
    mapping (address => mapping (address => uint256)) _allowances;

    // hashmap of addresses to a boolean for fee exemption status
    mapping (address => bool) isFeeExempt;
    
    // hashmap of addresses to a boolean for unlimited transaction token amounts
    mapping (address => bool) isTxLimitExempt;
    
    // hashmap of addresses to a boolean for an exemption of the pre-sale time lock
    mapping (address => bool) isTimelockExempt;
    
    // hashmap of addresses to a boolean for an exemption of reward dividends
    mapping (address => bool) isDividendExempt;

    // hashmap of addresses to a timeout for minimum intervals between trades
    mapping (address => uint) private botStopperTimer;

    // initialization of the address for the LP receiver ( BSC dead )
    address public autoLiquidityReceiver;
    
    // initialization of the address for the marketing fees receiver
    address public marketingFeeReceiver;

    // initialization of the PancakeSwap V2 Router
    IUniswapV2Router02 public _pancakeswapV2Router;
    
    // initialization of the PancakeSwap V2 Trading Pair
    address public _pancakeswapV2Pair;
   
    // boolean to signify if PancakeSwap trading is open yet
    bool public tradingOpen = true;

    // initialization of the RewardsDistributor contract
    RewardsDistributor distributor;
    
    // initialization of the reward distribution gas amount
    uint256 distributorGas = 500000;

    // boolean to signify if the transaction time limit is enabled ( stops bots from spamming trades on a single address )
    bool public botStopperEnabled = true;
    
    // time in seconds that a single address must wait between trades
    uint8 public botStopperTimerInterval = 45;
    
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalTokenAmount * 10 / 10000; // 0.01% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    // initialize parent contract Ownable
    constructor () {

        // initialize Pancakeswap with the testnet address if testnet is enabled
        
        if (testnetEnabled == true) {
            routerAddress = routerAddressTestnet;
        }

		_pancakeswapV2Router = IUniswapV2Router02(routerAddress); 
        
         // Create a pancakeswap pair for this new token
        _pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        // set the PancakeSwap router address to the max allowance
        _allowances[address(this)][address(_pancakeswapV2Router)] = MAX_INT;

        // initialize a new RewardsDistributor contract on the PancakeSwap router
        distributor = new RewardsDistributor(address(_pancakeswapV2Router));

        // the contract creator is exempt from fees
        isFeeExempt[msg.sender] = true;
        
        // the contract creator is exempt from the token transaction limit
        isTxLimitExempt[msg.sender] = true;

        // the contract creator is exempt from the token trade interval time limit
        isTimelockExempt[msg.sender] = true;
        
        // the BSC dead address is exempt from the token trade interval time limit
        isTimelockExempt[addressDead] = true;
        
        // the BitRides contract address is exempt from the token trade interval time limit
        isTimelockExempt[address(this)] = true;

        // the PancakeSwap V2 Pair contract address is exempt from the token trade fee dividends
        isDividendExempt[_pancakeswapV2Pair] = true;
        
        // the BitRides contract address is exempt from the token trade fee dividends
        isDividendExempt[address(this)] = true;
        
        // the BSC dead address is exempt from the token trade fee dividends
        isDividendExempt[addressDead] = true;

        // send LPs generated to the BSC dead address 
        autoLiquidityReceiver = addressDead;
        
        // send marketing fee dividends to the contract creator address
        marketingFeeReceiver = msg.sender;

        // initially allocate all the tokens to the contract creator address
        _balances[msg.sender] = _totalTokenAmount;
        emit Transfer(address(0), msg.sender, _totalTokenAmount);
    }

    receive() external payable { }

    // get total token amount
    function totalSupply() external view override returns (uint256) { return _totalTokenAmount; }
    
    // get contract decimals ( 9 )
    function decimals() external pure override returns (uint8) { return _decimals; }
    
    // get contract trading symbol ( RIDES )
    function symbol() external pure override returns (string memory) { return _symbol; }
    
    // get contract name ( BitRides )
    function name() external pure override returns (string memory) { return _name; }
    
    // get contract owner ( Initialized as the contract creator address )
    function getOwner() external view override returns (address) { return owner(); }
    
    // get adddress token balance
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    
    // get adddress token allowance
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    /*
     * Can be called by anyone
     * : sets the amount spenadable for the spender 
     */ 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /*
     * Can be called by anyone
     * : sets the maximum possible amount spenadable for the spender 
     */ 
    function approveMax(address spender) external returns (bool) {
        return approve(spender, MAX_INT);
    }

    /*
     * Can be called by anyone
     * : transfers the token amount from the contract sender to the recipient
     */ 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /*
     * Can be called by anyone
     * : transfers the token amount from the sender address to the recipient address after checking the sender's token balance for fund availability
     */ 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != MAX_INT){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    /*
     * Can be called by the owner
     * : sets the maximum permitted wallet holding (percent of total supply)
     */ 
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalTokenAmount * maxWallPercent ) / 100;
    }

    /*
     * Internal function only
     * : transfers BitRides tokens from one address to another after various checks
     */ 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        // if the BitRides contract is already in the process of swapping, transfer the tokens immediately
        if(inSwap) { return _basicTransfer(sender, recipient, amount); }

        // check to see if the pre-sale is over and trading is allowed yet
        if(sender != owner()){
            require(tradingOpen, "Trading not open yet");
        }

        // check to see if the recipient's token holdings will exceed the max limit of tokens ( anti-whale mechanism )
        if (sender != owner() && recipient != address(this)  && recipient != address(addressDead) && recipient != _pancakeswapV2Pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken, "Total Holding is currently limited, you can not buy that much.");}
        
        // check to see if a bot is trying to trade in quick succession ( stop trades faster than 45 seconds apart )
        if (sender == _pancakeswapV2Pair &&
            botStopperEnabled &&
            !isTimelockExempt[recipient]) {
            require(botStopperTimer[recipient] < block.timestamp, "Please wait for cooldown between buys");
            botStopperTimer[recipient] = block.timestamp + botStopperTimerInterval;
        }
        
        // check to see if the sender is trying to send more than the maximum for a single transaction
        checkTxLimit(sender, amount);

        // check to see if it should swap back LP and reward dividends
        if(shouldSwapBack()) { swapBack(); }

        // subtract the amount sent from the sender's token balance
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        // remove the transaction tax from the sender's token balance
        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        
        // add the amount sent to the recipient's token balance
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // update and reduce the sender's dividend amount now that they have less tokens
        if(!isDividendExempt[sender]) {
            try distributor.setShareBitRides(sender, _balances[sender]) {} catch {}
            try distributor.setShareWBNB(sender, _balances[sender]) {} catch {}
        }

        // update and increase the recipient's dividend amount now that they have more tokens
        if(!isDividendExempt[recipient]) {
            try distributor.setShareBitRides(recipient, _balances[recipient]) {} catch {} 
            try distributor.setShareWBNB(recipient, _balances[recipient]) {} catch {} 
        }
        
        // process token dividend rewards until the gas amount passed to the function runs out
        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        
        return true;
    }
    
    /*
     * Internal function only
     * : transfers BitRides tokens from one address to another but does no checks except to make sure they have the tokens first
     */ 
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /*
     * Internal function only
     * : assertion to make sure that the sender's amount doesn't exceed the transaction limit, if the sender is not exempt
     */ 
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    /*
     * Internal function only
     * : returns boolean true if the seller is not exempt from the transaction fees
     */ 
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    /*
     * Internal function only
     * : removes the fees from the sender account and adds it to the contract address
     */ 
    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    /*
     * Can be called by the owner
     * : sends any WBNB in the contract address to the marketing address
     */ 
    function flushBnbBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountBNB * amountPercentage / 100);
    }

    /*
     * Can be called by the owner
     * : sets the trading on PancakeSwap to open or closed ( after a pre-sale )
     */ 
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }

    /*
     * Can be called by the owner
     * : sets the trading cooldown period between trades ( stop bots using the same address to trade from spamming )
     */ 
    function cooldownEnabled(bool _status, uint8 _interval) public onlyOwner {
        botStopperEnabled = _status;
        botStopperTimerInterval = _interval;
    }

    /*
     * Internal function only
     * : if the token balance of the BitRides contract is greater than the swap threshold of token supply, swap the BitRides tokens back to WBNB
     */ 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != _pancakeswapV2Pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    /*
     * Internal function only
     * : swap the BitRides tokens back to WBNB and take reward dividend fees
     */ 
    function swapBack() internal swapping {
        
        // calculate LP fees and the amount to swap back
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        // input is the BitRides token contract address and the output is the WBNB address
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeswapV2Router.WETH();

        // BitRides contract balance before the swap from RIDES to WBNB
        uint256 balanceBefore = address(this).balance;

        // swap it on the Pancakeswap V2 Router
        _pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        // remove the balance that was swapped
        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        // calculate WBNB fees
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountReflectionBitRides = amountBNB.mul(reflectionFeeBitRides).div(totalBNBFee);
        uint256 amountBNBReflectionWBNB = amountBNB.mul(reflectionWBNBFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        // send the WBNB reflection reward dividend to holders
        try distributor.depositBitrides{value: amountReflectionBitRides}() {} catch {}
        try distributor.depositWBNB{value: amountBNBReflectionWBNB}() {} catch {}
        
        // send BitRides 2% reflection to this contract
        (bool tmpSuccess,) = payable(address(this)).call{value: amountReflectionBitRides, gas: 30000}("");
        
        address[] memory path2 = new address[](2);
        path2[0] = _pancakeswapV2Router.WETH();
        path2[1] = _pancakeswapV2Router.WETH();

        // send marketing fee out
        _pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBNBMarketing}(
            0,
            path,
            marketingFeeReceiver,
            block.timestamp
        );
        
        // supress warning message
        tmpSuccess = false;
    
        // add LPs from the swap back transaction
        if(amountToLiquify > 0){
            _pancakeswapV2Router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    /*
     * Can be called by the owner
     * : sets the transaction token volume limit
     */ 
    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    /*
     * Can be called by the owner
     * : adds address to a list which is exempt from dividends
     */ 
    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != _pancakeswapV2Pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShareBitRides(holder, 0);
            distributor.setShareWBNB(holder, 0);
        }else{
            distributor.setShareBitRides(holder, _balances[holder]);
            distributor.setShareWBNB(holder, _balances[holder]);
        }
    }

    /*
     * Can be called by the owner
     * : adds address to a list which can bypass fees/taxes
     */ 
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    /*
     * Can be called by the owner
     * : adds address to a list which can bypass the transaction token volume limit
     */ 
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    /*
     * Can be called by the owner
     * : adds address to a list which is exempt from the repeat transaction timelock
     */ 
    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    /*
     * Can be called by the owner
     * : sets the transaction fees after they are initialized
     */ 
    function setFees(uint256 _liquidityFee, uint256 _reflectionFeeBitRides, uint _reflectionWBNBFee,uint256 _marketingFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFeeBitRides = _reflectionFeeBitRides;
        reflectionWBNBFee = _reflectionWBNBFee;
        marketingFee = _marketingFee;
    }

    /*
     * Can be called by the owner
     * : sets the marketing address for marketing fee payments
     */ 
    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    /*
     * Can be called by the owner
     * : sets the boolean that signifies if tokens can be swapped back to WBNB and the threshold amount of tokens that can be swapped back
     */ 
    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    /*
     * Can be called by the owner
     * : sets the minimum quantities for shareholder dividends in terms of time or token amount
     */ 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    /*
     * Can be called by the owner
     * : sets the gas for token distribution operations
     */ 
    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    /*
     * Can be called by anyone
     * : gets the current circulating supply of tokens
     */ 
    function getCirculatingSupply() public view returns (uint256) {
        return _totalTokenAmount.sub(balanceOf(addressDead)).sub(balanceOf(addressZero));
    }

    /*
     * Can be called by anyone
     * : gets the current LP liquidity
     */ 
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(_pancakeswapV2Pair).mul(2)).div(getCirculatingSupply());
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

}