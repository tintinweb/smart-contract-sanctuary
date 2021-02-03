/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma abicoder v2;
pragma solidity >=0.7.6;

interface IStakePoolCreator {
    function version() external returns (uint256);

    function create() external returns (address);

    function initialize(
        address poolAddress,
        address pair,
        address rewardToken,
        address timelock,
        address stakePoolRewardFund,
        bytes calldata data
    ) external;
}

interface IValueLiquidRouter {
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
        bool isBPool;
    }

    function factory() external view returns (address);

    function controller() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external;

    function addStakeLiquidity(
        address stakePool,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addStakeLiquidityETH(
        address stakePool,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256 totalAmountOut);

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256 totalAmountIn);

    function createPair(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address to,
        uint8 flag
    ) external returns (uint256 liquidity);

    function createPairETH(
        address token,
        uint256 amountToken,
        uint32 tokenWeight,
        uint32 swapFee,
        address to,
        uint8 flag
    ) external payable returns (uint256 liquidity);
}

interface IValueLiquidFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

    function feeTo() external view returns (address);

    function formula() external view returns (address);

    function protocolFee() external view returns (uint256);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function isPair(address) external view returns (bool);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external returns (address pair);

    function getWeightsAndSwapFee(address pair)
        external
        view
        returns (
            uint32 tokenWeight0,
            uint32 tokenWeight1,
            uint32 swapFee
        );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setProtocolFee(uint256) external;
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IValueLiquidPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "ds-math-division-by-zero");
        c = a / b;
    }
}

contract TimeLock {
    using SafeMath for uint256;
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 1 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;
    bool private _initialized;
    address public admin;
    address public pendingAdmin;
    uint256 public delay;
    bool public admin_initialized;
    mapping(bytes32 => bool) public queuedTransactions;

    constructor() {
        admin_initialized = false;
        _initialized = false;
    }

    function initialize(address _admin, uint256 _delay) public {
        require(_initialized == false, "Timelock::constructor: Initialized must be false.");
        require(_delay >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = _delay;
        admin = _admin;
        _initialized = true;
        emit NewAdmin(admin);
        emit NewDelay(delay);
    }

    receive() external payable {}

    function setDelay(uint256 _delay) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(_delay >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = _delay;
        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);
        emit NewAdmin(admin);
    }

    function setPendingAdmin(address _pendingAdmin) public {
        // allows one time setting of admin for deployment purposes
        if (admin_initialized) {
            require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        } else {
            require(msg.sender == admin, "Timelock::setPendingAdmin: First call must come from admin.");
            admin_initialized = true;
        }
        pendingAdmin = _pendingAdmin;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }
}

interface IEpochController {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);

    function nextEpochAllocatedReward(address _pool) external view returns (uint256);
}

interface IStakePoolEpochReward {
    event AllocateReward(uint256 blocktime, uint256 amount);
    event Deposit(address indexed account, uint256 amount);
    event PayRewardPool(
        uint256 indexed poolId,
        address indexed rewardToken,
        address indexed account,
        uint256 pendingReward,
        uint256 rebaseAmount,
        uint256 paidReward
    );
    event Withdraw(address indexed account, uint256 amount);

    function version() external view returns (uint256);

    function pair() external view returns (address);

    function rewardToken() external view returns (address);

    function rewardFund() external view returns (address);

    function epochController() external view returns (address);

    function allowRecoverRewardToken(address _token) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);

    function nextEpochAllocatedReward() external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function unlockWithdrawEpoch(address _account) external view returns (uint256);

    function unlockRewardEpoch(address _account) external view returns (uint256);

    function stake(uint256) external;

    function stakeFor(address _account) external;

    function withdraw(uint256) external;

    function claimReward() external;

    function emergencyWithdraw() external;

    function setEpochController(address) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function allocateReward(uint256 _amount) external;

    function removeLiquidity(
        address provider,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
}

interface IValueLiquidProvider {
    function factory() external view returns (address);

    function controller() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function removeLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address pair,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address pair,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function stake(
        address stakePool,
        uint256 amount,
        uint256 deadline
    ) external;

    function stakeWithPermit(
        address stakePool,
        uint256 amount,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStakePoolController {
    event MasterCreated(address indexed farm, address indexed pair, uint256 version, address timelock, address stakePoolRewardFund, uint256 totalStakePool);
    event SetWhitelistStakingFor(address indexed contractAddress, bool value);
    event SetWhitelistStakePool(address indexed contractAddress, int8 value);
    event SetStakePoolCreator(address indexed contractAddress, uint256 verion);
    event SetWhitelistRewardRebaser(address indexed contractAddress, bool value);
    event SetWhitelistRewardMultiplier(address indexed contractAddress, bool value);
    event SetStakePoolVerifier(address indexed contractAddress, bool value);
    event ChangeGovernance(address indexed governance);
    event SetFeeCollector(address indexed feeCollector);
    event SetFeeToken(address indexed token);
    event SetFeeAmount(uint256 indexed amount);

    function allStakePools(uint256) external view returns (address stakePool);

    function isStakePool(address contractAddress) external view returns (bool);

    function isStakePoolVerifier(address contractAddress) external view returns (bool);

    function isWhitelistStakingFor(address contractAddress) external view returns (bool);

    function isWhitelistStakePool(address contractAddress) external view returns (int8);

    function setStakePoolVerifier(address contractAddress, bool state) external;

    function setWhitelistStakingFor(address contractAddress, bool state) external;

    function setWhitelistStakePool(address contractAddress, int8 state) external;

    function addStakePoolCreator(address contractAddress) external;

    function isWhitelistRewardRebaser(address contractAddress) external view returns (bool);

    function isAllowEmergencyWithdrawStakePool(address _address) external view returns (bool);

    function setWhitelistRewardRebaser(address contractAddress, bool state) external;

    function isWhitelistRewardMultiplier(address contractAddress) external view returns (bool);

    function setAllowEmergencyWithdrawStakePool(address _address, bool state) external;

    function setWhitelistRewardMultiplier(address contractAddress, bool state) external;

    function setEnableWhitelistRewardRebaser(bool value) external;

    function setEnableWhitelistRewardMultiplier(bool value) external;

    function allStakePoolsLength() external view returns (uint256);

    function create(
        uint256 version,
        address pair,
        address rewardToken,
        uint256 rewardFundAmount,
        uint256 delayTimeLock,
        bytes calldata data,
        uint8 flag
    ) external returns (address);

    function createPair(
        uint256 version,
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee,
        address rewardToken,
        uint256 rewardFundAmount,
        uint256 delayTimeLock,
        bytes calldata poolRewardInfo,
        uint8 flag
    ) external returns (address);

    function setGovernance(address) external;

    function setFeeCollector(address _address) external;

    function setFeeToken(address _token) external;

    function setFeeAmount(uint256 _token) external;
}

interface IStakePoolRewardRebaser {
    function getRebaseAmount(address rewardToken, uint256 baseAmount) external view returns (uint256);
}

interface IStakePoolRewardMultiplier {
    function getRewardMultiplier(
        uint256 _start,
        uint256 _end,
        uint256 _from,
        uint256 _to,
        uint256 _rewardPerBlock
    ) external view returns (uint256);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IStakePoolRewardFund {
    function initialize(address _stakePool, address _timelock) external;

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) external;
}

// This implements BPool contract, and allows for generalized staking, yield farming (by epoch), and token distribution.
contract StakePoolEpochReward is IStakePoolEpochReward {
    using SafeMath for uint256;
    uint256 public override version;

    /* ========== DATA STRUCTURES ========== */

    struct UserInfo {
        uint256 amount;
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
        uint256 epochTimerStart;
    }

    struct Snapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    /* ========== STATE VARIABLES ========== */

    address public override epochController;
    address public override rewardToken;

    uint256 public withdrawLockupEpochs;
    uint256 public rewardLockupEpochs;

    mapping(address => UserInfo) public userInfo;
    Snapshot[] public snapshotHistory;

    address public override pair;
    address public override rewardFund;
    address public timelock;
    address public controller;

    uint256 public balance;
    uint256 private _unlocked = 1;
    bool private _initialized = false;
    uint256 public constant BLOCKS_PER_DAY = 6528;

    constructor(address _controller, uint256 _version) {
        controller = _controller;
        timelock = msg.sender;
        version = _version;
        Snapshot memory genesisSnapshot = Snapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        snapshotHistory.push(genesisSnapshot);
    }

    modifier lock() {
        require(_unlocked == 1, "StakePoolEpochReward: LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    modifier onlyTimeLock() {
        require(msg.sender == timelock, "StakePoolEpochReward: !timelock");
        _;
    }

    modifier onlyEpochController() {
        require(msg.sender == epochController, "StakePoolEpochReward: !epochController");
        _;
    }

    modifier updateReward(address _account) {
        if (_account != address(0)) {
            UserInfo storage user = userInfo[_account];
            user.rewardEarned = earned(_account);
            user.lastSnapshotIndex = latestSnapshotIndex();
        }
        _;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _pair,
        address _rewardFund,
        address _timelock,
        address _epochController,
        address _rewardToken,
        uint256 _withdrawLockupEpochs,
        uint256 _rewardLockupEpochs
    ) external {
        require(_initialized == false, "StakePoolEpochReward: Initialize must be false.");
        pair = _pair;
        rewardToken = _rewardToken;
        rewardFund = _rewardFund;
        setEpochController(_epochController);
        setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
        timelock = _timelock;
        _initialized = true;
    }

    /* ========== GOVERNANCE ========== */

    function setEpochController(address _epochController) public override lock onlyTimeLock {
        epochController = _epochController;
        epoch();
        nextEpochPoint();
        nextEpochLength();
        nextEpochAllocatedReward();
    }

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) public override lock onlyTimeLock {
        require(_withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 56, "_withdrawLockupEpochs: out of range"); // <= 2 week
        withdrawLockupEpochs = _withdrawLockupEpochs;
        rewardLockupEpochs = _rewardLockupEpochs;
    }

    function allocateReward(uint256 _amount) external override lock onlyEpochController {
        require(_amount > 0, "StakePoolEpochReward: Cannot allocate 0");
        uint256 _before = IERC20(rewardToken).balanceOf(address(rewardFund));
        TransferHelper.safeTransferFrom(rewardToken, msg.sender, rewardFund, _amount);
        if (balance > 0) {
            uint256 _after = IERC20(rewardToken).balanceOf(address(rewardFund));
            _amount = _after.sub(_before);

            // Create & add new snapshot
            uint256 _prevRPS = getLatestSnapshot().rewardPerShare;
            uint256 _nextRPS = _prevRPS.add(_amount.mul(1e18).div(balance));

            Snapshot memory _newSnapshot = Snapshot({time: block.number, rewardReceived: _amount, rewardPerShare: _nextRPS});
            emit AllocateReward(block.number, _amount);
            snapshotHistory.push(_newSnapshot);
        }
    }

    function allowRecoverRewardToken(address _token) external view override returns (bool) {
        if (rewardToken == _token) {
            // do not allow to drain reward token if less than 1 months after LatestSnapshot
            if (block.number < (getLatestSnapshot().time + (BLOCKS_PER_DAY * 30))) {
                return false;
            }
        }
        return true;
    }

    // =========== Epoch getters

    function epoch() public view override returns (uint256) {
        return IEpochController(epochController).epoch();
    }

    function nextEpochPoint() public view override returns (uint256) {
        return IEpochController(epochController).nextEpochPoint();
    }

    function nextEpochLength() public view override returns (uint256) {
        return IEpochController(epochController).nextEpochLength();
    }

    function nextEpochAllocatedReward() public view override returns (uint256) {
        return IEpochController(epochController).nextEpochAllocatedReward(address(this));
    }

    // =========== Snapshot getters

    function latestSnapshotIndex() public view returns (uint256) {
        return snapshotHistory.length.sub(1);
    }

    function getLatestSnapshot() internal view returns (Snapshot memory) {
        return snapshotHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address _account) public view returns (uint256) {
        return userInfo[_account].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address _account) internal view returns (Snapshot memory) {
        return snapshotHistory[getLastSnapshotIndexOf(_account)];
    }

    // =========== _account getters

    function rewardPerShare() public view returns (uint256) {
        return getLatestSnapshot().rewardPerShare;
    }

    function earned(address _account) public view override returns (uint256) {
        uint256 latestRPS = getLatestSnapshot().rewardPerShare;
        uint256 storedRPS = getLastSnapshotOf(_account).rewardPerShare;

        UserInfo memory user = userInfo[_account];
        return user.amount.mul(latestRPS.sub(storedRPS)).div(1e18).add(user.rewardEarned);
    }

    function canWithdraw(address _account) external view returns (bool) {
        return userInfo[_account].epochTimerStart.add(withdrawLockupEpochs) <= epoch();
    }

    function canClaimReward(address _account) external view returns (bool) {
        return userInfo[_account].epochTimerStart.add(rewardLockupEpochs) <= epoch();
    }

    function unlockWithdrawEpoch(address _account) public view override returns (uint256) {
        return userInfo[_account].epochTimerStart.add(withdrawLockupEpochs);
    }

    function unlockRewardEpoch(address _account) public view override returns (uint256) {
        return userInfo[_account].epochTimerStart.add(rewardLockupEpochs);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _amount) external override lock {
        IValueLiquidPair(pair).transferFrom(msg.sender, address(this), _amount);
        _stakeFor(msg.sender);
    }

    function stakeFor(address _account) external override lock {
        require(IStakePoolController(controller).isWhitelistStakingFor(msg.sender), "StakePoolEpochReward: Invalid sender");
        _stakeFor(_account);
    }

    function _stakeFor(address _account) internal {
        uint256 _amount = IValueLiquidPair(pair).balanceOf(address(this)).sub(balance);
        require(_amount > 0, "StakePoolEpochReward: Invalid balance");
        balance = balance.add(_amount);
        UserInfo storage user = userInfo[_account];
        user.epochTimerStart = epoch(); // reset timer
        user.amount = user.amount.add(_amount);
        emit Deposit(_account, _amount);
    }

    function removeStakeInternal(uint256 _amount) internal {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _epoch = epoch();
        require(user.epochTimerStart.add(withdrawLockupEpochs) <= _epoch, "StakePoolEpochReward: still in withdraw lockup");
        require(user.amount >= _amount, "StakePoolEpochReward: invalid withdraw amount");
        _claimReward(false);
        balance = balance.sub(_amount);
        user.epochTimerStart = _epoch; // reset timer
        user.amount = user.amount.sub(_amount);
    }

    function withdraw(uint256 _amount) public override lock {
        removeStakeInternal(_amount);
        IValueLiquidPair(pair).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function exit() external {
        withdraw(userInfo[msg.sender].amount);
    }

    function _claimReward(bool _lockChecked) internal updateReward(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];
        uint256 _reward = user.rewardEarned;
        if (_reward > 0) {
            if (_lockChecked) {
                uint256 _epoch = epoch();
                require(user.epochTimerStart.add(rewardLockupEpochs) <= _epoch, "StakePoolEpochReward: still in reward lockup");
                user.epochTimerStart = _epoch; // reset timer
            }
            user.rewardEarned = 0;
            // Safe reward transfer, just in case if rounding error causes pool to not have enough reward amount
            uint256 _rewardBalance = IERC20(rewardToken).balanceOf(rewardFund);
            uint256 _paidAmount = _rewardBalance > _reward ? _reward : _rewardBalance;
            IStakePoolRewardFund(rewardFund).safeTransfer(rewardToken, msg.sender, _paidAmount);
            emit PayRewardPool(0, rewardToken, msg.sender, _reward, _reward, _paidAmount);
        }
    }

    function claimReward() public override {
        _claimReward(true);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external override lock {
        require(IStakePoolController(controller).isAllowEmergencyWithdrawStakePool(address(this)), "StakePoolEpochReward: Not allow emergencyWithdraw");
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        balance = balance.sub(amount);
        user.amount = 0;
        IValueLiquidPair(pair).transfer(msg.sender, amount);
    }

    function removeLiquidity(
        address provider,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public override lock returns (uint256 amountA, uint256 amountB) {
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePoolEpochReward: Invalid provider");
        removeStakeInternal(liquidity);
        IValueLiquidPair(pair).approve(provider, liquidity);
        emit Withdraw(msg.sender, liquidity);
        (amountA, amountB) = IValueLiquidProvider(provider).removeLiquidity(address(pair), tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETH(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override lock returns (uint256 amountToken, uint256 amountETH) {
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePoolEpochReward: Invalid provider");
        removeStakeInternal(liquidity);
        IValueLiquidPair(pair).approve(provider, liquidity);
        emit Withdraw(msg.sender, liquidity);
        (amountToken, amountETH) = IValueLiquidProvider(provider).removeLiquidityETH(
            address(pair),
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override lock returns (uint256 amountETH) {
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePoolEpochReward: Invalid provider");
        removeStakeInternal(liquidity);
        IValueLiquidPair(pair).approve(provider, liquidity);
        emit Withdraw(msg.sender, liquidity);
        amountETH = IValueLiquidProvider(provider).removeLiquidityETHSupportingFeeOnTransferTokens(
            address(pair),
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }
}

contract StakePoolEpochRewardCreator is IStakePoolCreator {
    uint256 public override version = 4001;
    struct PoolRewardInfo {
        address epochController;
        uint256 withdrawLockupEpochs;
        uint256 rewardLockupEpochs;
    }

    function create() external override returns (address) {
        StakePoolEpochReward pool = new StakePoolEpochReward(msg.sender, version);
        return address(pool);
    }

    function initialize(
        address poolAddress,
        address pair,
        address rewardToken,
        address timelock,
        address stakePoolRewardFund,
        bytes calldata data
    ) external override {
        StakePoolEpochReward pool = StakePoolEpochReward(poolAddress);

        PoolRewardInfo memory poolRewardInfo = abi.decode(data, (PoolRewardInfo));
        pool.initialize(
            pair,
            address(stakePoolRewardFund),
            address(timelock),
            poolRewardInfo.epochController,
            rewardToken,
            poolRewardInfo.withdrawLockupEpochs,
            poolRewardInfo.rewardLockupEpochs
        );
    }
}