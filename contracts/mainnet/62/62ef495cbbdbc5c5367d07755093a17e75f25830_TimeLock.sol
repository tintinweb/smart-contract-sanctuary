/**
 *Submitted for verification at Etherscan.io on 2021-02-09
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

interface IStakePool {
    event Deposit(address indexed account, uint256 amount);
    event AddRewardPool(uint256 indexed poolId);
    event UpdateRewardPool(uint256 indexed poolId, uint256 endRewardBlock, uint256 rewardPerBlock);
    event PayRewardPool(
        uint256 indexed poolId,
        address indexed rewardToken,
        address indexed account,
        uint256 pendingReward,
        uint256 rebaseAmount,
        uint256 paidReward
    );
    event UpdateRewardRebaser(uint256 indexed poolId, address rewardRebaser);
    event UpdateRewardMultiplier(uint256 indexed poolId, address rewardMultiplier);
    event Withdraw(address indexed account, uint256 amount);

    function version() external returns (uint256);

    function pair() external returns (address);

    function initialize(
        address _pair,
        uint256 _unstakingFrozenTime,
        address _rewardFund,
        address _timelock
    ) external;

    function stake(uint256) external;

    function stakeFor(address _account) external;

    function withdraw(uint256) external;

    function getReward(uint8 _pid, address _account) external;

    function getAllRewards(address _account) external;

    function claimReward() external;

    function pendingReward(uint8 _pid, address _account) external view returns (uint256);

    function allowRecoverRewardToken(address _token) external returns (bool);

    function getRewardPerBlock(uint8 pid) external view returns (uint256);

    function rewardPoolInfoLength() external view returns (uint256);

    function unfrozenStakeTime(address _account) external view returns (uint256);

    function emergencyWithdraw() external;

    function updateReward() external;

    function updateReward(uint8 _pid) external;

    function updateRewardPool(
        uint8 _pid,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock
    ) external;

    function getRewardMultiplier(
        uint8 _pid,
        uint256 _from,
        uint256 _to,
        uint256 _rewardPerBlock
    ) external view returns (uint256);

    function getRewardRebase(
        uint8 _pid,
        address _rewardToken,
        uint256 _pendingReward
    ) external view returns (uint256);

    function updateRewardRebaser(uint8 _pid, address _rewardRebaser) external;

    function updateRewardMultiplier(uint8 _pid, address _rewardMultiplier) external;

    function getUserInfo(uint8 _pid, address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 accumulatedEarned,
            uint256 lockReward,
            uint256 lockRewardReleased
        );

    function addRewardPool(
        address _rewardToken,
        address _rewardRebaser,
        address _rewardMultiplier,
        uint256 _startBlock,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock,
        uint256 _lockRewardPercent,
        uint256 _startVestingBlock,
        uint256 _endVestingBlock
    ) external;

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

contract StakePoolRewardFund is IStakePoolRewardFund {
    uint256 public constant BLOCKS_PER_DAY = 6528;
    address public stakePool;
    address public timelock;
    bool private _initialized;

    function initialize(address _stakePool, address _timelock) external override {
        require(_initialized == false, "StakePoolRewardFund: already initialized");
        stakePool = _stakePool;
        timelock = _timelock;
        _initialized = true;
    }

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) external override {
        require(msg.sender == stakePool, "StakePoolRewardFund: !stakePool");
        TransferHelper.safeTransfer(_token, _to, _value);
    }

    function recoverRewardToken(
        address _token,
        uint256,
        address
    ) external {
        require(msg.sender == timelock, "StakePoolRewardFund: !timelock");
        require(IStakePool(stakePool).allowRecoverRewardToken(_token), "StakePoolRewardFund: not allow recover reward token");
    }
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

contract StakePoolController is IStakePoolController {
    IValueLiquidFactory public swapFactory;
    address public governance;

    address public feeCollector;
    address public feeToken;
    uint256 public feeAmount;

    mapping(address => bool) private _stakePools;
    mapping(address => bool) private _whitelistStakingFor;
    mapping(address => bool) private _whitelistRewardRebaser;
    mapping(address => bool) private _whitelistRewardMultiplier;
    mapping(address => int8) private _whitelistStakePools;
    mapping(address => bool) public _stakePoolVerifiers;
    mapping(uint256 => address) public stakePoolCreators;
    address[] public override allStakePools;
    bool public enableWhitelistRewardRebaser = true;
    bool public enableWhitelistRewardMultiplier = true;
    bool private _initialized = false;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    mapping(address => bool) public allowEmergencyWithdrawStakePools;

    modifier discountCHI(uint8 flag) {
        uint256 gasStart = gasleft();
        _;
        if ((flag & 0x1) == 1) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

    function initialize(address _swapFactory) public {
        require(_initialized == false, "StakePoolController: initialized");
        governance = msg.sender;
        swapFactory = IValueLiquidFactory(_swapFactory);
        _initialized = true;
    }

    function isStakePool(address b) external view override returns (bool) {
        return _stakePools[b];
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "StakePoolController: !governance");
        _;
    }

    function setFeeCollector(address _address) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        feeCollector = _address;
        emit SetFeeCollector(_address);
    }

    function setEnableWhitelistRewardRebaser(bool value) external override onlyGovernance {
        enableWhitelistRewardRebaser = value;
    }

    function setEnableWhitelistRewardMultiplier(bool value) external override onlyGovernance {
        enableWhitelistRewardMultiplier = value;
    }

    function setFeeToken(address _token) external override onlyGovernance {
        require(_token != address(0), "StakePoolController: invalid _token");
        feeToken = _token;
        emit SetFeeToken(_token);
    }

    function setFeeAmount(uint256 _feeAmount) external override onlyGovernance {
        feeAmount = _feeAmount;
        emit SetFeeAmount(_feeAmount);
    }

    function isWhitelistStakingFor(address _address) external view override returns (bool) {
        return _whitelistStakingFor[_address];
    }

    function isWhitelistStakePool(address _address) external view override returns (int8) {
        return _whitelistStakePools[_address];
    }

    function isStakePoolVerifier(address _address) external view override returns (bool) {
        return _stakePoolVerifiers[_address];
    }

    function isAllowEmergencyWithdrawStakePool(address _address) external view override returns (bool) {
        return allowEmergencyWithdrawStakePools[_address];
    }

    function setWhitelistStakingFor(address _address, bool state) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        _whitelistStakingFor[_address] = state;
        emit SetWhitelistStakingFor(_address, state);
    }

    function setAllowEmergencyWithdrawStakePool(address _address, bool state) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        allowEmergencyWithdrawStakePools[_address] = state;
    }

    function setStakePoolVerifier(address _address, bool state) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        _stakePoolVerifiers[_address] = state;
        emit SetStakePoolVerifier(_address, state);
    }

    function setWhitelistStakePool(address _address, int8 state) external override {
        require(_address != address(0), "StakePoolController: invalid address");
        require(_stakePoolVerifiers[msg.sender] == true, "StakePoolController: invalid stake pool verifier");
        _whitelistStakePools[_address] = state;
        emit SetWhitelistStakePool(_address, state);
    }

    function addStakePoolCreator(address _address) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        uint256 version = IStakePoolCreator(_address).version();
        require(version >= 1000, "Invalid stake pool creator version");
        stakePoolCreators[version] = _address;
        emit SetStakePoolCreator(_address, version);
    }

    function isWhitelistRewardRebaser(address _address) external view override returns (bool) {
        if (!enableWhitelistRewardRebaser) return true;
        return _address == address(0) ? true : _whitelistRewardRebaser[_address];
    }

    function setWhitelistRewardRebaser(address _address, bool state) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        _whitelistRewardRebaser[_address] = state;
        emit SetWhitelistRewardRebaser(_address, state);
    }

    function isWhitelistRewardMultiplier(address _address) external view override returns (bool) {
        if (!enableWhitelistRewardMultiplier) return true;
        return _address == address(0) ? true : _whitelistRewardMultiplier[_address];
    }

    function setWhitelistRewardMultiplier(address _address, bool state) external override onlyGovernance {
        require(_address != address(0), "StakePoolController: invalid address");
        _whitelistRewardMultiplier[_address] = state;
        emit SetWhitelistRewardMultiplier(_address, state);
    }

    function setGovernance(address _governance) external override onlyGovernance {
        require(_governance != address(0), "StakePoolController: invalid governance");
        governance = _governance;
        emit ChangeGovernance(_governance);
    }

    function allStakePoolsLength() external view override returns (uint256) {
        return allStakePools.length;
    }

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
    ) public override discountCHI(flag) returns (address) {
        address pair = swapFactory.getPair(tokenA, tokenB, tokenWeightA, swapFee);
        if (pair == address(0)) {
            pair = swapFactory.createPair(tokenA, tokenB, tokenWeightA, swapFee);
        }
        return create(version, pair, rewardToken, rewardFundAmount, delayTimeLock, poolRewardInfo, 0);
    }

    function createInternal(
        address stakePoolCreator,
        address pair,
        address stakePoolRewardFund,
        address rewardToken,
        uint256 delayTimeLock,
        bytes calldata data
    ) internal returns (address) {
        TimeLock timelock = new TimeLock();
        IStakePool pool = IStakePool(IStakePoolCreator(stakePoolCreator).create());
        allStakePools.push(address(pool));
        _stakePools[address(pool)] = true;
        emit MasterCreated(address(pool), pair, pool.version(), address(timelock), stakePoolRewardFund, allStakePools.length);
        IStakePoolCreator(stakePoolCreator).initialize(address(pool), pair, rewardToken, address(timelock), address(stakePoolRewardFund), data);
        StakePoolRewardFund(stakePoolRewardFund).initialize(address(pool), address(timelock));
        timelock.initialize(msg.sender, delayTimeLock);
        return address(pool);
    }

    function create(
        uint256 version,
        address pair,
        address rewardToken,
        uint256 rewardFundAmount,
        uint256 delayTimeLock,
        bytes calldata data,
        uint8 flag
    ) public override discountCHI(flag) returns (address) {
        require(swapFactory.isPair(pair), "StakePoolController: invalid pair");
        address stakePoolCreator = stakePoolCreators[version];
        require(stakePoolCreator != address(0), "StakePoolController: Invalid stake pool creator version");

        if (feeCollector != address(0) && feeToken != address(0) && feeAmount > 0) {
            TransferHelper.safeTransferFrom(feeToken, msg.sender, feeCollector, feeAmount);
        }

        StakePoolRewardFund stakePoolRewardFund = new StakePoolRewardFund();
        if (rewardFundAmount > 0) {
            require(IERC20(rewardToken).balanceOf(msg.sender) >= rewardFundAmount, "StakePoolController: Not enough rewardFundAmount");
            TransferHelper.safeTransferFrom(rewardToken, msg.sender, address(stakePoolRewardFund), rewardFundAmount);
        }
        return createInternal(stakePoolCreator, pair, address(stakePoolRewardFund), rewardToken, delayTimeLock, data);
    }
}