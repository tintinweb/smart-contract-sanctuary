/**
 *Submitted for verification at FtmScan.com on 2021-12-05
*/

/*
 -----------------------FtmElon.sol --------------------------
                
                name     : FtmElon
                symbol   : FTMELON
                decimals : 9
                supply   : 10 000 000 000
				telegram : t.me/ftmelon
				website  : ftmelon.net
				
 -----------------------Tokenomics --------------------------
                
                Liqudiity            : 4%
                Marketing            : 4%
                Reflections FTM      : 3%
                Reflections FTMELON  : 2%
------------------------------------------------------------
                Total SLippage       : 13%
------------------------------------------------------------
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
  function _distributorTransfer(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event SwapBack(uint256 rewardamount, uint256 marketingamount, uint256 minimumFtmToLiquify, uint256 maximumToLiquify);
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
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
 */
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
    
    // process existing FTMELON dividend rewards for the shareholder if any are present, then set the amount owed to the shareholder
    function setShareFtmElon(address shareholder, uint256 amount) external;
    
    // process existing WFTM dividend rewards for the shareholder if any are present, then set the amount owed to the shareholder
    function setShareWFTM(address shareholder, uint256 amount) external;
    
    // update FTMELON rewards totals
    function updateFtmelonTotals(uint256 amount) external;
    
    // update WFTM rewards totals
    function updateWFTMTotals() external payable;
    
    // process eligible dividend rewards
    function process(uint256 gas) external;
}

/*Ftmelon
 * Contract Inteface implementation for IRewardsDistributor
 * : Methods used to process dividend rewards
 */ 
contract RewardsDistributor is IRewardsDistributor, ReentrancyGuard {
    using SafeMath for uint256;

    // initialized during the contract constructor, set to the FTMELON token contract
    address _token;

    // struct to hold data for dividend reward
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    receive() external payable {
        updateWFTMTotals(); 
    }

    // initialized during the contract constructor, set to the Spookyswap V2 router
    IUniswapV2Router02 _spookySwapV2Router2;
            
    // 2% reward paid in BITFTMELON
    IBEP20 addressRewardFtmelon = IBEP20(address(this)); 
                
    // list of dividend rewards shareholders
    address[] shareholdersFtmElon;
    
    // hashmap of shareholder indexes, what position of the list is x shareholder ?
    mapping (address => uint256) shareholderIndexesFtmElon;
    
    // hashmap of shareholder claim times, measured in this block's timestamp
    mapping (address => uint256) shareholderClaimsFtmElon;

    // list of dividend rewards shareholders
    address[] shareholdersWFTM;
    
    // hashmap of shareholder indexes, what position of the list is x shareholder ?
    mapping (address => uint256) shareholderIndexesWFTM;
    
    // hashmap of shareholder claim times, measured in this block's timestamp
    mapping (address => uint256) shareholderClaimsWFTM;

    // hashmap of shareholders to FTMELON Share data structs containing their current dividend reward info 
    mapping (address => Share) public sharesFtmElon;

    // hashmap of shareholders to WFTM Share data structs containing their current dividend reward info 
    mapping (address => Share) public sharesWFTM;

    // total token FTMELON shares available
    uint256 public totalFtmElonShares;
    
    // total token WFTM shares available
    uint256 public totalWFTMShares;
    
    // total dividend FTMELON token rewards accumulated
    uint256 public totalFtmElonTokenDividends;
    
    // total dividend WFTM rewards accumulated
    uint256 public totalWFTMDividends;
    
    // total dividend FTMELON token rewards paid out
    uint256 public totalFtmElonDistributed;
    
    // total dividend WFTM rewards paid out
    uint256 public totalWFTMDistributed;
    
    // dividends FTMELON tokens per share calculated
    uint256 public dividendsFtmElonTokenPerShare;
    
    // dividends WFTM per share calculated
    uint256 public dividendsWFTMPerShare;
    
    // FTMELON token dividends per share accuracy
    uint256 public dividendsFtmElonTokenPerShareAccuracyFactor = 10 ** 36;

    // WFTM dividends per share accuracy
    uint256 public dividendsWFTMPerShareAccuracyFactor = 10 ** 36;

    // minimum period between dividend reward distributions
    uint256 public minPeriod = 45 minutes;
    
    // minimum dividend reward amount before it can be distributed
    uint256 public minDistribution = 1 * (10 ** 18);

    /*
     * index of the current shareholder getting a dividend reward
     * Used as the shareholders are cycled through one by one until the gas runs out.
     * Eventually when the last shareholder gets their reward, it goes back to zero and starts over again from the first shareholder
     */
    uint256 currentIndexWFTM;
    
    uint256 currentIndexFtmElon;

    // has this contract been initialized ?
    bool initialized;
    
    // initialization method
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    // checks that the sender is the FTMELON token contract address
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    // initialize the Spookyswap V2 router
    constructor (address _router) {

        _spookySwapV2Router2 = _router != address(0)
            ? IUniswapV2Router02(_router)
            : IUniswapV2Router02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        _token = msg.sender;
        addressRewardFtmelon = IBEP20(msg.sender);
    }
    
    /*
     * Can be called by the FTMELON token contract address
     * : sets the token distribution params
     */ 
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    /*
     * Can be called by the FTMELON token contract address
     * : distributes pending shareholder dividend rewards, and updates the shareholder's dividend reward amount
     */ 
    function setShareFtmElon(address shareholder, uint256 amount) external override onlyToken {
        if(sharesFtmElon[shareholder].amount > 0){
            distributeDividendFtmElon(shareholder);
        }

        if(amount > 0 && sharesFtmElon[shareholder].amount == 0){
            addShareholderFtmElon(shareholder);
        }else if(amount == 0 && sharesFtmElon[shareholder].amount > 0){
            removeShareholderFtmElon(shareholder);
        }

        totalFtmElonShares = totalFtmElonShares.sub(sharesFtmElon[shareholder].amount).add(amount);
        sharesFtmElon[shareholder].amount = amount;
        sharesFtmElon[shareholder].totalExcluded = getCumulativeDividendsFtmElon(sharesFtmElon[shareholder].amount);
    }
    
    /*
     * Can be called by the WFTM token contract address
     * : distributes pending shareholder dividend rewards, and updates the shareholder's dividend reward amount
     */ 
    function setShareWFTM(address shareholder, uint256 amount) external override onlyToken {
        if(sharesWFTM[shareholder].amount > 0){
             distributeDividendWFTM(shareholder);
        }

        if(amount > 0 && sharesWFTM[shareholder].amount == 0){
            addShareholderWFTM(shareholder);
        }else if(amount == 0 && sharesFtmElon[shareholder].amount > 0){
            removeShareholderWFTM(shareholder);
        }

        totalWFTMShares = totalWFTMShares.sub(sharesWFTM[shareholder].amount).add(amount);
        sharesWFTM[shareholder].amount = amount;
        sharesWFTM[shareholder].totalExcluded = getCumulativeDividendsWFTM(sharesWFTM[shareholder].amount);
    }

    /*
     * Can be called by the FTMELON token contract address
     * : Update FTMELON distribution totals
     */ 

    function updateFtmelonTotals(uint256 ftmElonAmount) external override onlyToken {
        // FTMELON are deposited to the contract automatically on buys/sells, no need to convert
        uint256 amount = ftmElonAmount;
        totalFtmElonTokenDividends = totalFtmElonTokenDividends.add(amount);
        dividendsFtmElonTokenPerShare = dividendsFtmElonTokenPerShare.add(dividendsFtmElonTokenPerShareAccuracyFactor.mul(amount).div(totalFtmElonShares));
    }
    
    /*
    * Can be called by the WFTM contract address
    * : Update WFTM distribution totals
    */ 

    function updateWFTMTotals() public payable override {
        // already in WFTM, so no spookySwapping is needed
        uint256 amount = msg.value;
        totalWFTMDividends = totalWFTMDividends.add(amount);
        dividendsWFTMPerShare = dividendsWFTMPerShare.add(dividendsWFTMPerShareAccuracyFactor.mul(amount).div(totalWFTMShares));
    }

    /*
     * Can be called by the FTMELON token contract address
     * : process eligible dividend rewards
     */ 
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCountWFTM = shareholdersWFTM.length;
        uint256 shareholderCountFtmElon = shareholdersFtmElon.length;
        
        if (shareholderCountWFTM == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCountWFTM) {
            if (currentIndexWFTM >= shareholderCountWFTM){
                currentIndexWFTM = 0;
            }

            if (shouldDistributeWFTM(shareholdersWFTM[currentIndexWFTM])) {
                distributeDividendWFTM(shareholdersWFTM[currentIndexWFTM]);
                currentIndexWFTM++;
            }
            
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            
            if (currentIndexFtmElon >= shareholderCountFtmElon){
                currentIndexFtmElon = 0;
            }
            
            if (gasUsed < gas && shouldDistributeFtmElon(shareholdersFtmElon[currentIndexFtmElon])) {
                distributeDividendFtmElon(shareholdersFtmElon[currentIndexFtmElon]);
                currentIndexFtmElon++;
            }
        
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();

            iterations++;
        }
    }
    
    /*
     * Internal function only
     * : checks to see if the shareholder has met the minimum requirements for a FTMELON dividend reward distribution
     */ 
    function shouldDistributeFtmElon(address shareholder) internal view returns (bool) {
        return shareholderClaimsFtmElon[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarningsFtmElon(shareholder) > minDistribution;
    }
    
    /*
     * Internal function only
     * : checks to see if the shareholder has met the minimum requirements for a WFTM dividend reward distribution
     */ 
    function shouldDistributeWFTM(address shareholder) internal view returns (bool) {
        return shareholderClaimsWFTM[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarningsWFTM(shareholder) > minDistribution;
    }

    /*
     * Internal function only
     * : send the shareholder the FTMELON dividend reward distribution, and update the totals
     */ 
    function distributeDividendFtmElon(address shareholder) internal {
        if(sharesFtmElon[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsFtmElon(shareholder);
        if(amount > 0){
            totalFtmElonDistributed = totalFtmElonDistributed.add(amount);
            shareholderClaimsFtmElon[shareholder] = block.timestamp;
            addressRewardFtmelon._distributorTransfer(address(this), shareholder, amount);
            sharesFtmElon[shareholder].totalRealised = sharesFtmElon[shareholder].totalRealised.add(amount);
            sharesFtmElon[shareholder].totalExcluded = getCumulativeDividendsFtmElon(sharesFtmElon[shareholder].amount);
        }
    }
    
    /*
     * Internal function only
     * : send the shareholder the WFTM dividend reward distribution, and update the totals
     */ 
    function distributeDividendWFTM(address shareholder) internal nonReentrant {
        if(sharesWFTM[shareholder].amount == 0){ return; }
        bool success;

        uint256 amount = getUnpaidEarningsWFTM(shareholder);
        if(amount > 0){
            totalWFTMDistributed = totalWFTMDistributed.add(amount);
            shareholderClaimsWFTM[shareholder] = block.timestamp;
            (success,) = payable(shareholder).call{value: amount, gas: 5000}("");
            sharesWFTM[shareholder].totalRealised = sharesWFTM[shareholder].totalRealised.add(amount);
            sharesWFTM[shareholder].totalExcluded = getCumulativeDividendsWFTM(sharesWFTM[shareholder].amount);
        }
    }

    /*
     * Can be called by anyone
     * : see the amount of dividend rewards in FTMELON are currently owned to the shareholder address
     */ 
    function getUnpaidEarningsFtmElon(address shareholder) public view returns (uint256) {
        if(sharesFtmElon[shareholder].amount == 0){ return 0; }

        uint256 shareholdertotalFtmElonTokenDividends = getCumulativeDividendsFtmElon(sharesFtmElon[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesFtmElon[shareholder].totalExcluded;

        if(shareholdertotalFtmElonTokenDividends <= shareholderTotalExcluded){ return 0; }

        return shareholdertotalFtmElonTokenDividends.sub(shareholderTotalExcluded);
    }
    
    /*
     * Can be called by anyone
     * : see the amount of dividend rewards in WFTM are currently owned to the shareholder address
     */ 
    function getUnpaidEarningsWFTM(address shareholder) public view returns (uint256) {
        if(sharesWFTM[shareholder].amount == 0){ return 0; }

        uint256 shareholdertotalWFTMDividends = getCumulativeDividendsWFTM(sharesWFTM[shareholder].amount);
        uint256 shareholderTotalExcluded = sharesWFTM[shareholder].totalExcluded;

        if(shareholdertotalWFTMDividends <= shareholderTotalExcluded){ return 0; }

        return shareholdertotalWFTMDividends.sub(shareholderTotalExcluded);
    }

    /*
     * Internal function only
     * : calculate how many total dividend FTMELON rewards were received for a shareholder
     */ 
    function getCumulativeDividendsFtmElon(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsFtmElonTokenPerShare).div(dividendsFtmElonTokenPerShareAccuracyFactor);
    }
    
    /*
     * Internal function only
     * : calculate how many total dividend WFTM rewards were received for a shareholder
     */ 
    function getCumulativeDividendsWFTM(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsWFTMPerShare).div(dividendsWFTMPerShareAccuracyFactor);
    }

    /*
     * Internal function only
     * : add a new shareholder
     */ 
    function addShareholderWFTM(address shareholder) internal {
        shareholderIndexesWFTM[shareholder] = shareholdersWFTM.length;
        shareholdersWFTM.push(shareholder);
    }

    /*
     * Internal function only
     * : remove a shareholder
     */ 
    function removeShareholderWFTM(address shareholder) internal {
        shareholdersWFTM[shareholderIndexesWFTM[shareholder]] = shareholdersWFTM[shareholdersWFTM.length-1];
        shareholderIndexesWFTM[shareholdersWFTM[shareholdersWFTM.length-1]] = shareholderIndexesWFTM[shareholder];
        shareholdersWFTM.pop();
    }

    /*
     * Internal function only
     * : add a new shareholder
     */ 
    function addShareholderFtmElon(address shareholder) internal {
        shareholderIndexesFtmElon[shareholder] = shareholdersFtmElon.length;
        shareholdersFtmElon.push(shareholder);
    }

    /*
     * Internal function only
     * : remove a shareholder
     */ 
    function removeShareholderFtmElon(address shareholder) internal {
        shareholdersFtmElon[shareholderIndexesFtmElon[shareholder]] = shareholdersFtmElon[shareholdersFtmElon.length-1];
        shareholderIndexesFtmElon[shareholdersFtmElon[shareholdersFtmElon.length-1]] = shareholderIndexesFtmElon[shareholder];
        shareholdersFtmElon.pop();
    }
}

contract FtmElon is IBEP20, Ownable {
    using SafeMath for uint256;
    
    // Token name
    string constant _name       = "FtmElon";
    
    // Token symbol
    string constant _symbol     = "FTMELON";
    
    // Token decimals
    uint8 constant _decimals    = 9;
    
    // How much percetage of LP is sent back to the BSC dead address
    uint256 liquidityFee        = 4;
    
    // How much percetage is sent to the marketing address
    uint256 marketingFee        = 4;
    
    // How much percetage in FTMELON is sent to the shareholders
    uint256 reflectionFeeFtmElon = 2;
    
    // How much percetage in WFTM is sent to the shareholders
    uint256 reflectionWFTMFee  = 3;
    
    // total sum fee percentage
	uint256 public totalFee     = 13;
    
    // fee denominator 100%
    uint256 feeDenominator      = 100;
    
    uint256 targetLiquidity = 20;
    
    uint256 targetLiquidityDenominator = 100;
    
    // BSC dead address
    address addressDead     = 0x000000000000000000000000000000000000dEaD;
    
    // BSC zero address
    address addressZero     = 0x0000000000000000000000000000000000000000;
    
    // uint256 maximum
    uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    
    // SpookySwap mainnet router address
    address routerAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    
    // total supply of tokens ( 10,000,000,000 )
    uint256 _totalTokenAmount = 10 * 10**9 * (10 ** _decimals);
    
    // maximum transaction token amount ( 1,000,000,000 )
    uint256 public _maxTxAmount = _totalTokenAmount * 10 / 100;
	
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

    // initialization of the SpookySwap V2 Router
    IUniswapV2Router02 public _spookySwapV2Router;
    
    // initialization of the SpookySwap V2 Trading Pair
    address public _spookySwapV2Pair;
   
    // boolean to signify if SpookySwap trading is open yet
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
    uint256 public swapThreshold = _totalTokenAmount * 10 / 10000; // 0.1% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    // initialize parent contract Ownable
    constructor () {

        // initialize Spookyswap

		_spookySwapV2Router = IUniswapV2Router02(routerAddress); 
        
         // Create a spookySwap pair for this new token
        _spookySwapV2Pair = IUniswapV2Factory(_spookySwapV2Router.factory())
            .createPair(_spookySwapV2Router.WETH(), address(this));

        // set the SpookySwap router address to the max allowance
        _allowances[address(this)][address(_spookySwapV2Router)] = MAX_INT;

        // initialize a new RewardsDistributor contract on the SpookySwap router
        distributor = new RewardsDistributor(address(_spookySwapV2Router));

        // the contract creator is exempt from fees
        isFeeExempt[msg.sender] = true;

        isFeeExempt[address(distributor)] = true;
        
        isFeeExempt[address(this)] = true;
                
        // the contract creator is exempt from the token transaction limit
        isTxLimitExempt[msg.sender] = true;

        // the contract creator is exempt from the token trade interval time limit
        isTimelockExempt[msg.sender] = true;
        
        // the BSC dead address is exempt from the token trade interval time limit
        isTimelockExempt[addressDead] = true;
        
        // the FtmElon contract address is exempt from the token trade interval time limit
        isTimelockExempt[address(this)] = true;

        // the SpookySwap V2 Pair contract address is exempt from the token trade fee dividends
        isDividendExempt[_spookySwapV2Pair] = true;

          // don't let the reward distributor get rewards
        isDividendExempt[address(distributor)] = true;
        
        // the FtmElon contract address is exempt from the token trade fee dividends
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
    
    // get contract trading symbol ( FTMELON )
    function symbol() external pure override returns (string memory) { return _symbol; }
    
    // get contract name ( FtmElon )
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
     * Internal function only
     * : transfers FtmElon tokens from one address to another after various checks
     */ 
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        
        // if the FtmElon contract is already in the process of swapping, transfer the tokens immediately
        if(inSwap) { return _basicTransfer(sender, recipient, amount); }

        // check to see if the pre-sale is over and trading is allowed yet
        if(sender != owner()){
            require(tradingOpen, "Trading not open yet");
        }

        // check to see if a bot is trying to trade in quick succession ( stop trades faster than 45 seconds apart )
        if (sender == _spookySwapV2Pair &&
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
            try distributor.setShareFtmElon(sender, _balances[sender]) {} catch {}
            try distributor.setShareWFTM(sender, _balances[sender]) {} catch {}
        }

        // update and increase the recipient's dividend amount now that they have more tokens
        if(!isDividendExempt[recipient]) {
            try distributor.setShareFtmElon(recipient, _balances[recipient]) {} catch {} 
            try distributor.setShareWFTM(recipient, _balances[recipient]) {} catch {} 
        }
        
        // process token dividend rewards until the gas amount passed to the function runs out
        if(sender != address(distributor) && recipient != address(distributor) && sender != address(this) && recipient != address(this)){
            try distributor.process(distributorGas) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        
        return true;
    }
    
    /*
     * Internal function only
     * : transfers FtmElon tokens from one address to another but does no checks except to make sure they have the tokens first
     */ 
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /*
     * Internal function only
     * : transfers FtmElon tokens from one address to another but does no checks except to make sure they have the tokens first
     */ 
    function _distributorTransfer(address sender, address recipient, uint256 amount) external onlyDistributor returns (bool) {
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
        uint256 ftmElonReflectionFee = amount.mul(reflectionFeeFtmElon).div(feeDenominator);

        // update the FTMELON token reflection reward dividend to the contract
        // since these tokens are transfered directly to the contract address
        // we can calculate them right now, it's 2% by default       
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount - ftmElonReflectionFee);
        emit Transfer(sender, address(this), feeAmount);
        _balances[address(distributor)] = _balances[address(distributor)].add(ftmElonReflectionFee);
        emit Transfer(sender, address(this), feeAmount);
        try distributor.updateFtmelonTotals(ftmElonReflectionFee) {} catch {}

        return amount.sub(feeAmount);
    }

    /*
     * Can be called by the owner
     * : sends any WFTM in the contract address to the marketing address
     */ 
    function flushFtmBalance(uint256 amountPercentage) external onlyOwner {
        uint256 amountFTM = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountFTM * amountPercentage / 100);
    }

    /*
     * Can be called by the owner
     * : sets the trading on SpookySwap to open or closed ( after a pre-sale )
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
     * : if the token balance of the FtmElon contract is greater than the swap threshold of token supply, swap the FtmElon tokens back to WFTM
     */ 
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != _spookySwapV2Pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
    
    /*
     * Internal function only
     * : swap the FtmElon tokens back to WFTM and take reward dividend fees
     */ 
    function swapBack() internal swapping {
        
        // calculate LP fees and the amount to swap back
        uint256 dynamicLiquidityFee = liquidityFee;
        // We don't want to spookySwap the 13% by default total fees
        // We want to swap only the WFTM fees
        uint256 wFTMFeesOnly = totalFee - reflectionFeeFtmElon;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(wFTMFeesOnly).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        // input is the FtmElon token contract address and the output is the WFTM address
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _spookySwapV2Router.WETH();

        // FtmElon contract balance before the swap from FTMELON to WFTM
        uint256 balanceBefore = address(this).balance;

        // swap it on the Spookyswap V2 Router
        _spookySwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        // remove the balance that was swapped
        uint256 amountFTM = address(this).balance.sub(balanceBefore);

        uint256 totalFTMFee = wFTMFeesOnly.sub(dynamicLiquidityFee.div(2));
        
        // calculate WFTM fees
        uint256 amountFTMLiquidity = amountFTM.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);
        uint256 amountFTMReflectionWFTM = amountFTM.mul(reflectionWFTMFee).div(totalFTMFee);
        uint256 amountFTMMarketing = amountFTM.mul(marketingFee).div(totalFTMFee);

        // update the WFTM reflection reward dividend to the contract
        // update the WFTM totals, we can't calculate this until AFTER we convert to WFTM

        (bool success, ) = payable(distributor).call{value: amountFTMReflectionWFTM}("");
        (success,) = payable(marketingFeeReceiver).call{value: amountFTMMarketing}("");
        
        // supress warning message
        success = false;
    
        emit SwapBack(amountFTMReflectionWFTM, amountFTMMarketing, amountFTMLiquidity, amountToLiquify);

        // add LPs from the swap back transaction
        if(amountToLiquify > 0){
            _spookySwapV2Router.addLiquidityETH{value: amountFTMLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountFTMLiquidity, amountToLiquify);
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
        require(holder != address(this) && holder != _spookySwapV2Pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShareFtmElon(holder, 0);
            distributor.setShareWFTM(holder, 0);
        }else{
            distributor.setShareFtmElon(holder, _balances[holder]);
            distributor.setShareWFTM(holder, _balances[holder]);
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
    function setFees(uint256 _liquidityFee, uint256 _reflectionFeeFtmElon, uint _reflectionWFTMFee,uint256 _marketingFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFeeFtmElon = _reflectionFeeFtmElon;
        reflectionWFTMFee = _reflectionWFTMFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFeeFtmElon).add(_reflectionWFTMFee).add(_marketingFee);
    }

    /*
     * Can be called by the owner
     * : sets the marketing address for marketing fee payments
     */ 
    function setFeeReceivers(address _marketingFeeReceiver) external onlyOwner {
        require(_marketingFeeReceiver != address(0));  
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    /*
     * Can be called by the owner
     * : sets the boolean that signifies if tokens can be swapped back to WFTM and the threshold amount of tokens that can be swapped back
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
        return accuracy.mul(balanceOf(_spookySwapV2Pair).mul(2)).div(getCirculatingSupply());
    }

    // checks that the sender is the distributor
    modifier onlyDistributor() {
        require(msg.sender == address(distributor)); 
        _;
    }

    event AutoLiquify(uint256 amountFTM, uint256 amountBOG);

}