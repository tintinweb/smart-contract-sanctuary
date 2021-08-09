/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

pragma solidity 0.8.6;
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity 0.8.6;
abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity 0.8.6;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

pragma solidity 0.8.6;
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor()  {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity 0.8.6;
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
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

pragma solidity 0.8.6;
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

pragma solidity 0.8.6;
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

pragma solidity 0.8.6;
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

pragma solidity 0.8.6;
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

pragma solidity 0.8.6;
contract BnbPrediction is Ownable, Pausable {
    using SafeMath for uint256;

    struct Round {
        uint256 epoch;
        uint256 startBlock;
        uint256 lockBlock;
        uint256 endBlock;
        int256 lockPrice;
        int256 closePrice;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    enum Position {Bull, Bear}

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }
    string [] public symbols;
    mapping(string => address) symbolOracle;
    mapping(string => uint) symbolSwitch;
    mapping(string => uint256) currentEpochMap;
    mapping(string => uint256) oracleLatestRoundId;
    //    mapping(uint256 => Round) public rounds;
    mapping(string => mapping(uint256 => mapping(address => BetInfo))) ledger;
    mapping(string => mapping(address => uint256[])) public userRounds;
    mapping(string => mapping(uint256 => Round)) public rounds;
    //    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    //    mapping(address => uint256[]) public userRounds;
    //    uint256 public currentEpoch;
    mapping(string => uint256) public intervalBlocks;
    mapping(string => uint256) public bufferBlocks;
    address public adminAddress;
    address public operatorAddress;
    uint256 public treasuryAmount;
    //    AggregatorV3Interface internal oracle;
    //    uint256 public oracleLatestRoundId;

    uint256 public constant TOTAL_RATE = 1000; // 100%
    uint256 public rewardRate = 975; // 90%
    uint256 public treasuryRate = 25; // 10%
    uint256 public minBetAmount;
    uint256 public oracleUpdateAllowance; // seconds

    //    bool public genesisStartOnce = false;
    //    bool public genesisLockOnce = false;
    mapping(string => bool) public genesisStartOnce;
    mapping(string => bool) public genesisLockOnce;
    IUniswapV2Router01 public  uniswapV2Router;
    address public  uniswapV2Pair;
    //手续费分配
    uint256 public TOTAL_FEE = 100;
    uint256 public destroyRate = 50;
    uint256 public teamRate = 50;
    bool public openRepurchase = false;
    address public teamAddress;
    //最小回购金额
    uint256 minimumRepurchaseAmount = 2;
    //token 合约地址
    address tokenAddress = 0xf4883aF3534B2E3d11550c287cB16E9f8365B667;
    address blackHoleAddress = 0x000000000000000000000000000000000000dEaD;
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    event StartRound(uint256 indexed epoch, uint256 blockNumber,string symbol);
    event LockRound(uint256 indexed epoch, uint256 blockNumber, int256 price,string symbol);
    event EndRound(uint256 indexed epoch, uint256 blockNumber, int256 price,string symbol);
    event BetBull(address indexed sender, uint256 indexed currentEpoch, uint256 amount,string symbol);
    event BetBear(address indexed sender, uint256 indexed currentEpoch, uint256 amount,string symbol);
    event Claim(address indexed sender, uint256 indexed currentEpoch, uint256 amount,string symbol);
    event ClaimTreasury(uint256 destroyAmount,uint256 teamAmount);
    event RatesUpdated(uint256 indexed epoch, uint256 rewardRate, uint256 treasuryRate,string symbol);
    event MinBetAmountUpdated(uint256 indexed epoch, uint256 minBetAmount);
    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount,
        string symbol
    );
    event Pause(uint256 epoch,string symbol);
    event Unpause(uint256 epoch,string symbol);
    event TotalFeeUpdated(uint256 epoch,uint256 destroyRate,uint256 teamRate);

    constructor(
        address _teamAddress,
//        address _routerAddress,
        address _adminAddress,
        address _operatorAddress,
        uint256 _minBetAmount,
        uint256 _oracleUpdateAllowance
    )  {
        symbolOracle['ETH'] = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        symbolOracle['BNB'] = 0xcf0f51ca2cDAecb464eeE4227f5295F2384F84ED;
        symbolOracle['BTC'] = 0xECe365B379E1dD183B20fc5f022230C044d51404;
        symbolSwitch['ETH'] = 1;
        symbolSwitch['BNB'] = 1;
        symbolSwitch['BTC'] = 1;
        intervalBlocks['BNB'] =120;
        intervalBlocks['BTC'] =120;
        intervalBlocks['ETH'] =120;
        bufferBlocks['BNB'] =10;
        bufferBlocks['BTC'] =10;
        bufferBlocks['ETH'] =10;
        symbols.push('ETH');
        symbols.push('BNB');
        symbols.push('BTC');
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        minBetAmount = _minBetAmount;
        oracleUpdateAllowance = _oracleUpdateAllowance;
//        _setUniswapV2Router(_routerAddress);
        teamAddress = _teamAddress;

    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "operator: wut?");
        _;
    }

    modifier onlyAdminOrOperator() {
        require(msg.sender == adminAddress || msg.sender == operatorAddress, "admin | operator: wut?");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @dev set admin address
     * callable by owner
     */
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Cannot be zero address");
        adminAddress = _adminAddress;
    }

    /**
     * @dev set operator address
     * callable by admin
     */
    function setOperator(address _operatorAddress) external onlyAdmin {
        require(_operatorAddress != address(0), "Cannot be zero address");
        operatorAddress = _operatorAddress;
    }

    /**
     * @dev set interval blocks
     * callable by admin
     */
    function setIntervalBlocks(string memory _symbol,uint256 _intervalBlocks) external onlyAdmin {
        intervalBlocks[_symbol] = _intervalBlocks;
    }

    function getIntervalBlocks(string memory _symbol) external view returns(uint256){
        return intervalBlocks[_symbol];
    }

    /**
     * @dev set buffer blocks
     * callable by admin
     */
    function setBufferBlocks(string memory _symbol,uint256 _bufferBlocks) external onlyAdmin {
        require(_bufferBlocks <= intervalBlocks[_symbol], "Cannot be more than intervalBlocks");
        bufferBlocks[_symbol] = _bufferBlocks;
    }

    function setSymbol(string memory _symbol,uint256 _bufferBlocks,uint256 _intervalBlocks,address _oracleAddress) external onlyAdmin {
        require(symbolOracle[_symbol] == address(0),"cannotAddRepeatedly");
        symbols.push(_symbol);
        bufferBlocks[_symbol] = _bufferBlocks;
        intervalBlocks[_symbol] = _intervalBlocks;
        symbolSwitch[_symbol] = 1;
        symbolOracle[_symbol] = _oracleAddress;

    }



    /**
     * @dev set Oracle address
     * callable by admin
     */
    function setOracle(string memory _symbol,address _oracle) external onlyAdmin {
        require(_oracle != address(0), "Cannot be zero address");
        //        oracle = AggregatorV3Interface(_oracle);
        symbolOracle[_symbol] = _oracle;
    }

    /**
     * @dev set oracle update allowance
     * callable by admin
     */
    function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external onlyAdmin {
        oracleUpdateAllowance = _oracleUpdateAllowance;
    }
    /**
     * @dev set Router update allowance
     * callable by admin
     */
    function setRouter(address _routerAddress) external  onlyAdmin{
        _setUniswapV2Router(_routerAddress);
    }

    function _setUniswapV2Router(address _routerAddress) internal {
        router = _routerAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .getPair(tokenAddress, _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

    }

    /**
     * @dev set reward rate
     * callable by admin
     */
    function setRewardRate(uint256 _rewardRate) external onlyAdmin {
        require(_rewardRate <= TOTAL_RATE, "rewardRate cannot be more than 100%");
        rewardRate = _rewardRate;
        treasuryRate = TOTAL_RATE.sub(_rewardRate);
        for(uint i=0;i<symbols.length;i++){
            emit RatesUpdated(currentEpochMap[symbols[i]], rewardRate, treasuryRate,symbols[i]);
        }
    }

    function setPpenRepurchase(bool _openRepurchase) external onlyAdmin {
        openRepurchase = _openRepurchase;
    }


    /**
     * @dev set DestroyRate
     * callable by admin
     */
    function setDestroyRate(uint256 _destroyRate) external onlyAdmin {
        require(_destroyRate <= TOTAL_FEE, "rewardRate cannot be more than 100%");
        destroyRate = _destroyRate;
        teamRate = TOTAL_RATE.sub(_destroyRate);

        emit TotalFeeUpdated(currentEpochMap["BNB"], destroyRate, teamRate);
    }



    /**
     * @dev set treasury rate
     * callable by admin
     */
    function setTreasuryRate(uint256 _treasuryRate) external onlyAdmin {
        require(_treasuryRate <= TOTAL_RATE, "treasuryRate cannot be more than 100%");
        rewardRate = TOTAL_RATE.sub(_treasuryRate);
        treasuryRate = _treasuryRate;
        for(uint i=0;i<symbols.length;i++){
            emit RatesUpdated(currentEpochMap[symbols[i]], rewardRate, treasuryRate,symbols[i]);
        }
    }

    /**
     * @dev set minBetAmount
     * callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        minBetAmount = _minBetAmount;

        emit MinBetAmountUpdated(currentEpochMap["BNB"], minBetAmount);
    }

    /**
     * @dev set Team address
     * callable by admin
     */
    function setTeamAddress(address _teamAddress) external onlyAdmin {
        require(_teamAddress != address(0), "Cannot be zero address");
        teamAddress = _teamAddress;
    }

    /**
     * @dev Start genesis round  启动创世轮
     */
    function genesisStartRound(string memory _symbol) external onlyOperator whenNotPaused {
        require(!genesisStartOnce[_symbol], "Can only run genesisStartRound once");

        currentEpochMap[_symbol] = currentEpochMap[_symbol] + 1;
        _startRound(_symbol,currentEpochMap[_symbol]);
        genesisStartOnce[_symbol] = true;
    }

    function getGenesisStartOnce(string memory _symbol) public view returns(bool){
        return genesisStartOnce[_symbol];
    }

    function getGenesisLockOnce(string memory _symbol) public view returns(bool){
        return genesisLockOnce[_symbol];
    }

    /**
     * @dev Lock genesis round  锁定创世轮
     */
    function genesisLockRound(string memory _symbol) external onlyOperator whenNotPaused {
        require(genesisStartOnce[_symbol], "Can only run after genesisStartRound is triggered");
        require(!genesisLockOnce[_symbol], "Can only run genesisLockRound once");
        require(
            block.number <= rounds[_symbol][currentEpochMap[_symbol]].lockBlock.add(bufferBlocks[_symbol]),
            "Can only lock round within bufferBlocks"
        );

        int256 currentPrice = _getPriceFromOracle(_symbol);
        _safeLockRound(_symbol,currentEpochMap[_symbol], currentPrice);

        currentEpochMap[_symbol] = currentEpochMap[_symbol] + 1;
        _startRound(_symbol,currentEpochMap[_symbol]);
        genesisLockOnce[_symbol] = true;
    }

    /**
     * @dev Start the next round n, lock price for round n-1, end round n-2  开始第 n 轮，锁定第 n-1 轮的价格，结束第 n-2 轮
     */
    function executeRound(string memory _symbol) external onlyOperator whenNotPaused {
        require(
            genesisStartOnce[_symbol] && genesisLockOnce[_symbol],
            "Can only run after genesisStartRound and genesisLockRound is triggered"
        );
        int256 currentPrice = _getPriceFromOracle(_symbol);
        // CurrentEpoch refers to previous round (n-1)
        uint256  current = currentEpochMap[_symbol];
        _safeLockRound(_symbol,current, currentPrice);
        _safeEndRound(_symbol,current - 1, currentPrice);
        _calculateRewards(_symbol,current - 1);

        // Increment currentEpoch to current round (n)
        current = current + 1;
        currentEpochMap[_symbol] = current;
        _safeStartRound(_symbol,current);
    }

    /**
     * @dev Bet bear position
     * 投跌
     */
    function betBear(string memory _symbol) external payable whenNotPaused notContract {
        require(symbolSwitch[_symbol] == 1,"the_currency_is_not_yet_open");
        uint256  current = currentEpochMap[_symbol];
        require(_bettable(_symbol,current), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[_symbol][current][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[_symbol][current];
        round.totalAmount = round.totalAmount.add(amount);
        round.bearAmount = round.bearAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[_symbol][current][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(current);

        emit BetBear(msg.sender, current, amount,_symbol);
    }

    /**
     * @dev Bet bull position
     * 投涨
     */
    function betBull(string memory _symbol) external payable whenNotPaused notContract {
        require(symbolSwitch[_symbol] == 1,"the_currency_is_not_yet_open");
        uint256  current = currentEpochMap[_symbol];
        require(_bettable(_symbol,current), "Round not bettable");
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(ledger[_symbol][current][msg.sender].amount == 0, "Can only bet once per round");

        // Update round data
        uint256 amount = msg.value;
        Round storage round = rounds[_symbol][current];
        round.totalAmount = round.totalAmount.add(amount);
        round.bullAmount = round.bullAmount.add(amount);

        // Update user data
        BetInfo storage betInfo = ledger[_symbol][current][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[_symbol][msg.sender].push(current);

        emit BetBull(msg.sender, current, amount,_symbol);
    }

    /**
     * @dev Claim reward 索取奖励
     */
    function claim(string memory _symbol,uint256 epoch) external notContract {
        require(rounds[_symbol][epoch].startBlock != 0, "Round has not started");
        require(block.number > rounds[_symbol][epoch].endBlock, "Round has not ended");
        require(!ledger[_symbol][epoch][msg.sender].claimed, "Rewards claimed");

        uint256 reward;
        // Round valid, claim rewards
        if (rounds[_symbol][epoch].oracleCalled) {
            require(claimable(_symbol,epoch, msg.sender), "Not eligible for claim");
            Round memory round = rounds[_symbol][epoch];
            reward = ledger[_symbol][epoch][msg.sender].amount.mul(round.rewardAmount).div(round.rewardBaseCalAmount);
        }
        // Round invalid, refund bet amount
        else {
            require(refundable(_symbol,epoch, msg.sender), "Not eligible for refund");
            reward = ledger[_symbol][epoch][msg.sender].amount;
        }

        BetInfo storage betInfo = ledger[_symbol][epoch][msg.sender];
        betInfo.claimed = true;
        _safeTransferBNB(address(msg.sender), reward);

        emit Claim(msg.sender, epoch, reward,_symbol);
    }

    /**
     * @dev Claim all rewards in treasury  索取金库中的所有奖励
     * callable by admin
     */
    function claimTreasury() external onlyAdmin {
        _claimTreasury();
    }

    /**
     * @dev set minimumRepurchaseAmount
     * callable by admin
     */
    function setMinimumRepurchaseAmount(uint256 _minimumRepurchaseAmount) external onlyAdmin {
        minimumRepurchaseAmount = _minimumRepurchaseAmount;
    }

    function setPtToken(address _ptToken) external onlyAdmin {
        require(_ptToken != address(0), "Cannot be zero address");
        tokenAddress = _ptToken;
    }

    function _claimTreasury() internal {
        if(treasuryAmount > minimumRepurchaseAmount){
            uint256 destroy = 0;
            if(openRepurchase){
                destroy = treasuryAmount.mul(destroyRate).div(TOTAL_FEE);
                address[] memory path = new address[](2);
                path[0] = uniswapV2Router.WETH();
                path[1] = tokenAddress;
                //50%回购TP销毁
                uniswapV2Router.swapExactETHForTokens{value:destroy}(0, path,blackHoleAddress,block.timestamp+1000);
            }
            uint256 team =  treasuryAmount.sub(destroy);
            //50%
            treasuryAmount = 0;
            _safeTransferBNB(teamAddress, team);

            emit ClaimTreasury(destroy,team);
        }

    }

    /**
     * @dev Return round epochs that a user has participated  返回用户参与的轮次
     */
    function getUserRounds(
        string memory _symbol,
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, uint256) {
        uint256 length = size;
        if (length > userRounds[_symbol][user].length - cursor) {
            length = userRounds[_symbol][user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[_symbol][user][cursor + i];
        }

        return (values, cursor + length);
    }

    /**
     * @dev called by the admin to pause, triggers stopped state
     * 由管理员调用暂停，触发停止状态
     */
    function pause(string memory _symbol) public onlyAdminOrOperator whenNotPaused {
        _pause();

        emit Pause(currentEpochMap[_symbol],_symbol);
    }

    /**
     * @dev called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     * 由管理员调用以取消暂停，返回到正常状态重置创世状态。一旦暂停，轮次将需要由创世启动
     */
    function unpause(string memory _symbol) public onlyAdmin whenPaused {
        genesisStartOnce[_symbol] = false;
        genesisLockOnce[_symbol] = false;
        _unpause();

        emit Unpause(currentEpochMap[_symbol],_symbol);
    }

    /**
     * @dev Get the claimable stats of specific epoch and user account
     *获取特定时期和用户帐户的可索赔统计数据
     */
    function claimable(string memory _symbol,uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_symbol][epoch][user];
        Round memory round = rounds[_symbol][epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
        round.oracleCalled &&
        ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
        (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @dev Get the refundable stats of specific epoch and user account
     * 获取特定时期和用户帐户的可退款统计信息
     */
    function refundable(string memory _symbol,uint256 epoch, address user) public view returns (bool) {
        BetInfo memory betInfo = ledger[_symbol][epoch][user];
        Round memory round = rounds[_symbol][epoch];
        return !round.oracleCalled && block.number > round.endBlock.add(bufferBlocks[_symbol]) && betInfo.amount != 0;
    }

    /**
     * @dev Start round
     * Previous round n-2 must end 上一轮 n-2 必须结束
     */
    function _safeStartRound(string memory _symbol,uint256 epoch) internal {
        require(genesisStartOnce[_symbol], "Can only run after genesisStartRound is triggered");
        require(rounds[_symbol][epoch - 2].endBlock != 0, "Can only start round after round n-2 has ended");
        require(block.number >= rounds[_symbol][epoch - 2].endBlock, "Can only start new round after round n-2 endBlock");
        _startRound(_symbol,epoch);
    }

    function _startRound(string memory _symbol,uint256 epoch) internal {
        Round storage round = rounds[_symbol][epoch];
        round.startBlock = block.number;
        round.lockBlock = block.number.add(intervalBlocks[_symbol]);
        round.endBlock = block.number.add(intervalBlocks[_symbol] * 2);
        round.epoch = epoch;
        round.totalAmount = 0;
        _claimTreasury();
        emit StartRound(epoch, block.number,_symbol);
    }

    /**
     * @dev Lock round
     */
    function _safeLockRound(string memory _symbol,uint256 epoch, int256 price) internal {
        require(rounds[_symbol][epoch].startBlock != 0, "Can only lock round after round has started");
        require(block.number >= rounds[_symbol][epoch].lockBlock, "Can only lock round after lockBlock");
        require(block.number <= rounds[_symbol][epoch].lockBlock.add(bufferBlocks[_symbol]), "Can only lock round within bufferBlocks");
        _lockRound(_symbol,epoch, price);
    }

    function _lockRound(string memory _symbol,uint256 epoch, int256 price) internal {
        Round storage round = rounds[_symbol][epoch];
        round.lockPrice = price;

        emit LockRound(epoch, block.number, round.lockPrice,_symbol);
    }

    /**
     * @dev End round
     */
    function _safeEndRound(string memory _symbol,uint256 epoch, int256 price) internal {
        require(rounds[_symbol][epoch].lockBlock != 0, "Can only end round after round has locked");
        require(block.number >= rounds[_symbol][epoch].endBlock, "Can only end round after endBlock");
        require(block.number <= rounds[_symbol][epoch].endBlock.add(bufferBlocks[_symbol]), "Can only end round within bufferBlocks");
        _endRound(_symbol,epoch, price);
    }

    function _endRound(string memory _symbol,uint256 epoch, int256 price) internal {
        Round storage round = rounds[_symbol][epoch];
        round.closePrice = price;
        round.oracleCalled = true;

        emit EndRound(epoch, block.number, round.closePrice,_symbol);
    }

    /**
     * @dev Calculate rewards for round
     */
    function _calculateRewards(string memory _symbol,uint256 epoch) internal {
        require(rewardRate.add(treasuryRate) == TOTAL_RATE, "rewardRate and treasuryRate must add up to TOTAL_RATE");
        require(rounds[_symbol][epoch].rewardBaseCalAmount == 0 && rounds[_symbol][epoch].rewardAmount == 0, "Rewards calculated");
        Round storage round = rounds[_symbol][epoch];
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        uint256 treasuryAmt;
        // Bull wins
        if (round.closePrice > round.lockPrice && round.bullAmount > 0) {
            rewardBaseCalAmount = round.bullAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = round.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice && round.bearAmount > 0) {
            rewardBaseCalAmount = round.bearAmount;
            rewardAmount = round.totalAmount.mul(rewardRate).div(TOTAL_RATE);
            treasuryAmt = round.totalAmount.mul(treasuryRate).div(TOTAL_RATE);
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            rewardAmount = 0;
            treasuryAmt = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = rewardAmount;

        // Add to treasury
        treasuryAmount = treasuryAmount.add(treasuryAmt);

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt,_symbol);
    }

    /**
     * @dev Get latest recorded price from oracle
     * If it falls below allowed buffer or has not updated, it would be invalid
     * 如果它低于允许的缓冲区或尚未更新，则无效
     */
    function _getPriceFromOracle(string memory _symbol) internal returns (int256) {
        uint256 leastAllowedTimestamp = block.timestamp.add(oracleUpdateAllowance);
        (uint80 roundId, int256 price, , uint256 timestamp, ) = AggregatorV3Interface(symbolOracle[_symbol]).latestRoundData();
        require(timestamp <= leastAllowedTimestamp, "Oracle update exceeded max timestamp allowance");
        require(roundId > oracleLatestRoundId[_symbol], "Oracle update roundId must be larger than oracleLatestRoundId");
        oracleLatestRoundId[_symbol] = uint256(roundId);
        return price;
    }

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{gas: 23000, value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Determine if a round is valid for receiving bets
     * Round must have started and locked
     * Current block must be within startBlock and endBlock
     * 确定一个回合是否可以接收投注 回合必须已经开始并被锁定 当前区块必须在 startBlock 和 endBlock 之内
     */
    function _bettable(string memory _symbol,uint256 epoch) internal view returns (bool) {
        return
        rounds[_symbol][epoch].startBlock != 0 &&
        rounds[_symbol][epoch].lockBlock != 0 &&
        block.number > rounds[_symbol][epoch].startBlock &&
        block.number < rounds[_symbol][epoch].lockBlock;
    }
}