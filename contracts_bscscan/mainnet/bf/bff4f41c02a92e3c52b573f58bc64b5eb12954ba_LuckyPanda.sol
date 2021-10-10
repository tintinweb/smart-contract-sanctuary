/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

/** 
⚡️Lucky Panda (LKPA)⚡️

⚡️Total supply: 
100 billion (1,000,000,000,000)
⚡️Initial flow pool: 3 BNB
⚡️10% transaction fee
⚡️locker 1 year of strong security
⚡️5% Automatic repurchase anti-whale mechanism
⚡️Fair Launch (no pre-sale, no dumping)
 */
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
 * Forked Distributor from SafeEarn V2 with performance adjustments (credit woofydev) 
 */
interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSafemoonThreshold) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external;
    function process(uint256 gas) external;
    function processManually() external;
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

  
    function approve(address spender, uint256 amount) external returns (bool);

  
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
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

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

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
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
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
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

/** Forked Distributor from SafeEarn with performance adjustments (credit woofydev) */
contract DividendDistributor is IDividendDistributor {
    
    using SafeMath for uint256;
    using Address for address;
    // SafeVault Contract
    address _token;
    // Share of the Safemoon Pie
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    // bnb address
    address WBNB =  0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //  0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c mainnet
    // Reward in WETH
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; //mainnet 0xe9e7cea3dedca5984780bafc599bd69add087d56
    IUniswapV2Router02 router;
    // shareholder fields
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    // shares math and fields
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    // distributes daily
    uint256 public minPeriod = 24 hours;
    
    uint256 public minDistribution = 1 * (10 ** 15);
   
    uint256 public swapToSafemoonThreshold = 1 * (10 ** 18);
    // current index in shareholder array 
    uint256 currentIndex;

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IUniswapV2Router02(_router)
        : IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //   main router 0x10ED43C718714eb63d5aA57B78B54704E256024E
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSafemoonThreshold) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        swapToSafemoonThreshold = _bnbToSafemoonThreshold;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function deposit() external override onlyToken {
        
        uint256 bnbBalance = address(this).balance;
        if (bnbBalance >= swapToSafemoonThreshold) {
            
            uint256 balanceBefore = IERC20(WBNB).balanceOf(address(this));
            
            address[] memory path = new address[](2);
            path[0] = BUSD;
            path[1] = WBNB;

            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: swapToSafemoonThreshold}(
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amount = IERC20(WBNB).balanceOf(address(this)).sub(balanceBefore);

            totalDividends = totalDividends.add(amount);
            dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        }
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function processManually() external override onlyToken {
        uint256 shareholderCount = shareholders.length;
        
        if(shareholderCount == 0) { return; }

        uint256 iterations = 0;
        currentIndex = 0;

        while(iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            IERC20(WBNB).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        require(shouldDistribute(msg.sender), 'Must wait 24 hours to claim dividend!');
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
    
    function setAxieinfinityAddress(address nSFM) external onlyToken {
        WBNB = nSFM;
    }
    receive() external payable { }

}


contract LuckyPanda is IERC20, Context, Ownable {
    
    using SafeMath for uint256;
    using SafeMath for uint8;
    using Address for address;
    
    // wrapped bnb address for swapping
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    // token data
    string constant _name = " LuckyPanda";
    string constant _symbol = " LKPA";
    uint8 constant _decimals = 18;
    // 100 million Max Supply
    uint256 _totalSupply = 100000000000 * (10**18);
    
    uint256 public _maxTxAmount =100000000000 * (10**18);
    
    uint256 public _maxWalletToken = 400000000000 * (10**18);
    // balances
    mapping (address => uint256) _balances; 
    mapping (address => mapping (address => uint256)) _allowances;
    // exemptions
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    // fees for instance 200 means 2% 
    uint256 public liquidityFee = 200;
    uint256 public buybackFee = 100;
    uint256 public reflectionFee = 700;
    uint256 public marketingFee = 500;
    // total fees
    uint256 totalFeeSells = 7000;
    uint256 totalFeeBuys = 500;
    uint256 feeDenominator = 10000;
    // receiving addresses
    address public autoLiquidityReceiver;
    
    address public marketingFeeReceiver = 0x32DC576A051F462E11fd0eff1CD0CD19078FaE13;
    // target liquidity is 12%
    uint256 targetLiquidity = 12;
    uint256 targetLiquidityDenominator = 100;
    // Pancakeswap V2 Router
    IUniswapV2Router02 public router;
    address public pair;
    // buy back data
    bool public autoBuybackEnabled = true;
    
    bool public tradingOpen = true;
    
    uint256 autoBuybackAccumulator = 0;
    uint256 autoBuybackAmount = 1 * 10**18;
    uint256 autoBuybackBlockPeriod = 5800; // 1/2 hours
    uint256 autoBuybackBlockLast = block.number;
    bool public allowTransferToMarketing = true;
    // gas for distributor
    DividendDistributor distributor;
    uint256 distributorGas = 500000;
    // in charge of swapping
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply.div(1000); // 1% or 10 million to start
    // true if our threshold decreases with circulating supply
    bool public canChangeSwapThreshold = false;
    uint256 public swapThresholdPercentOfCirculatingSupply = 1000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    // Uniswap Router V2
    address private _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // false if we should disable auto liquidity pairing for any reason
    bool public shouldPairLiquidity = true;
    // because transparency is important
    uint256 public totalBNBMarketing = 0;
    uint256 public totalBNBAxieinfinityReflections = 0;
    
    // initialize some stuff
    constructor (
    ) {
        // Pancakeswap V2 Router
        router = IUniswapV2Router02(_dexRouter);
        // Liquidity Pool Address for BNB -> Vault
        pair = IUniswapV2Factory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        // Wrapped BNB Address used for trading on PCS
        WBNB = router.WETH();
        // our dividend Distributor
        distributor = new DividendDistributor(_dexRouter);
        // send LP tokens to the burn wallet
        autoLiquidityReceiver = DEAD;
        // exempt deployer from fees
        isFeeExempt[msg.sender] = true;
        // exempt deployer from TX limit
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(this)] =true;
        // exempt this contract, the LP, and OUR burn wallet from receiving  Rewards
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        approve(_dexRouter, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    /** Approve Total Supply */
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
    /** Transfer Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // check if we have reached the transaction limit
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        
         // max wallet code
        if (sender != _owner && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            
        }
        
        
        // if we're in swap perform a basic transfer
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        uint256 amountReceived;
        // limit gas consumption by splitting up operations
        if(shouldSwapBack()) { 
            swapBack();
            amountReceived = handleTransferBody(sender, recipient, amount);
        } else if(shouldAutoBuyback()) { 
            triggerAutoBuyback(); 
            amountReceived = handleTransferBody(sender, recipient, amount);
        } else {
            amountReceived = handleTransferBody(sender, recipient, amount);
            uint256 gasToUse = distributorGas > gasleft() ? gasleft().mul(3).div(4) : distributorGas;
            try distributor.process(gasToUse) {} catch {}
        }
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    /** Takes Associated Fees and sets holders' new Share for the Safemoon Distributor */
    function handleTransferBody(address sender, address recipient, uint256 amount) internal returns (uint256) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        return amountReceived;
    }
    /** Basic Transfer with no swaps for BNB -> Vault or Vault -> BNB */
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        handleTransferBody(sender, recipient, amount);
        return true;
    }

    /** False if sender is Fee Exempt, True if not */
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }
    /** Takes Proper Fee (5% buys / transfers, 30% on sells) and stores in contract */
    function takeFee(address receiver, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        return amount.sub(feeAmount);
    }
    /** True if we should swap from Vault => BNB */
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }
   
    function swapBack() internal swapping {
        
        // check if we need to add liquidity 
        uint256 dynamicLiquidityFee = (isOverLiquified(targetLiquidity, targetLiquidityDenominator) || !shouldPairLiquidity)? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFeeSells).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);
        
        // path from token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;
        // swap tokens for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch{}
        // how much BNB did we swap?
        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        
        // total amount of BNB to allocate
        uint256 totalBNBFee = totalFeeSells.sub(dynamicLiquidityFee.div(2));
        // how much bnb is sent to liquidity, reflections, and marketing
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
        // deposit BNB for reflections and marketing
        transferToDistributorAndMarketing(amountBNBReflection, amountBNBMarketing);
        
        // add liquidity if we need to
        if(amountToLiquify > 0 && shouldPairLiquidity ){
            try router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
        ) {} catch {}
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }
    /** Transfers BNB to Safemoon Distributor and Marketing Wallet */
    function transferToDistributorAndMarketing(uint256 distributorBNB, uint256 marketingBNB) internal {
        (bool success,) = payable(address(distributor)).call{value: distributorBNB, gas: 30000}("");
        if (success) {
            try distributor.deposit() {totalBNBAxieinfinityReflections = totalBNBAxieinfinityReflections.add(marketingBNB);} catch {}
        }
        
        if (allowTransferToMarketing) {
            (bool successful,) = payable(marketingFeeReceiver).call{value: marketingBNB, gas: 30000}("");
            if (successful) {
                totalBNBMarketing = totalBNBMarketing.add(marketingBNB);
            }
        }
    }

    /** Should Vault buy/burn right now? */
    function shouldAutoBuyback() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && autoBuybackEnabled
        && autoBuybackBlockLast + autoBuybackBlockPeriod <= block.number // After N blocks from last buyback
        && address(this).balance >= autoBuybackAmount;
    }
    /** Buy back tokens to make up for buy fee */
    function triggerAutoBuyback() internal {
        buyTokens(autoBuybackAmount, DEAD);
        autoBuybackBlockLast = block.number;
        autoBuybackAccumulator = autoBuybackAccumulator.add(autoBuybackAmount);
    }
    
    /**
     * Buys SafeVault with bnb in the contract, sending to target address
     */ 
    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp.add(30)
        );
        if (to == DEAD && canChangeSwapThreshold) {
            swapThreshold = getCirculatingSupply().div(swapThresholdPercentOfCirculatingSupply);
        }
    }
    
    /** 0 = process manually | 1 = process with standard gas | Above 1 = process with custom gas limit */
    function manuallyProcessDividends(uint256 distributorGasFee) public {
        if (distributorGasFee == 0) {
            try distributor.processManually() {} catch {}
        } else if (distributorGasFee == 1) {
            try distributor.process(distributorGas) {} catch {}
        } else {
            try distributor.process(distributorGasFee) {} catch {}
        }
    }
    /** Sets Various Fees */
    function setFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        buybackFee = _buybackFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSells = _liquidityFee.add(_buybackFee).add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
        require(totalFeeSells < feeDenominator/2);
    }
    
    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
    
    function getIsFeeExempt(address holder) external view returns (bool) {
        return isFeeExempt[holder];
    }
    
     // switch Trading
    function tradingStatus(bool _status) public onlyOwner {
        tradingOpen = _status;
    }
    
    function getIsDividendExempt(address holder) external view returns (bool) {
        return isDividendExempt[holder];
    }
    
    function getIsTxLimitExempt(address holder) external view returns (bool) {
        return isTxLimitExempt[holder];
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }
    
    function setAutoBuybackSettings(bool _enabled, uint256 _amount, uint256 _period) external onlyOwner {
        autoBuybackEnabled = _enabled;
        autoBuybackAccumulator = 0;
        autoBuybackAmount = _amount;
        autoBuybackBlockPeriod = _period;
        autoBuybackBlockLast = block.number;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, bool changeSwapThreshold, bool shouldAutomateLiquidity, uint256 percentOfCirculatingSupply) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        canChangeSwapThreshold = changeSwapThreshold;
        swapThresholdPercentOfCirculatingSupply = percentOfCirculatingSupply;
        shouldPairLiquidity = shouldAutomateLiquidity;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _bnbToSafemoonThreshold) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution, _bnbToSafemoonThreshold);
    }

    function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas < 1000000);
        distributorGas = gas;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= _totalSupply / 2500);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }
    
    /**
     * Buy and Burn VAULT with bnb stored in contract
     */ 
    function triggerVaultBuyback(uint256 amount) public onlyOwner {
        buyTokens(amount, DEAD);
        emit VaultBuyBackAndBurn(amount);
    }

    function setAllowTransferToMarketing(bool _canSendToMarketing) public onlyOwner {
        allowTransferToMarketing = _canSendToMarketing;
    }
    
    function setBuyingFee(uint256 buyFee) public onlyOwner {
        totalFeeBuys = buyFee;
    }
    
    function setDexRouter(address nRouter) public onlyOwner{
        _dexRouter = nRouter;
        router = IUniswapV2Router02(nRouter);
    }

    function setAutoBuyBack(bool enable) public onlyOwner {
        autoBuybackEnabled = enable;
    }

    
    function getBNBQuantityInContract() public view returns(uint256){
        return address(this).balance;
    }
    
    function getTotalFee(bool selling) public view returns (uint256) {
        if(selling){ return totalFeeSells; }
        return totalFeeBuys;
    }
    /** Returns the Circulating Supply of Vault ( supply not owned by Burn Wallet ) */
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD));
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply()) > target;
    }
    
    function getDistributorAddress() external view returns (address) {
        return address(distributor);
    }
    
    
 function airdrop(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

    uint256 SCCC = 0;

    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(from) >= SCCC, "Not enough tokens to airdrop");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(from,addresses[i],tokens[i]);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], _balances[addresses[i]]) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[from]) {
        try distributor.setShare(from, _balances[from]) {} catch {}
    }
}

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event VaultBuyBackAndBurn(uint256 amountBNB);
}