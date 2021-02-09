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

    function version() external view returns (uint256);

    function pair() external view returns (address);

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

    function allowRecoverRewardToken(address _token) external view returns (bool);

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

// This implements BPool contract, and allows for generalized staking, yield farming, and token distribution.
contract StakePool is IStakePool {
    using SafeMath for uint256;
    uint256 public override version; // 3001
    // Info of each user.
    struct UserInfo {
        uint256 amount;
        mapping(uint8 => uint256) rewardDebt;
        mapping(uint8 => uint256) reward;
        mapping(uint8 => uint256) accumulatedEarned; // will accumulate every time user harvest
        mapping(uint8 => uint256) lockReward;
        mapping(uint8 => uint256) lockRewardReleased;
        uint256 lastStakeTime;
    }

    // Info of each rewardPool funding.
    struct RewardPoolInfo {
        address rewardToken; // Address of rewardPool token contract.
        address rewardRebaser; // Address of rewardRebaser contract.
        address rewardMultiplier; // Address of rewardMultiplier contract.
        uint256 startRewardBlock; // Start reward block number that rewardPool distribution occurs.
        uint256 lastRewardBlock; // Last block number that rewardPool distribution occurs.
        uint256 endRewardBlock; // Block number which rewardPool distribution ends.
        uint256 rewardPerBlock; // Reward token amount to distribute per block.
        uint256 accRewardPerShare; // Accumulated rewardPool per share, times 1e18.
        uint256 lockRewardPercent; // Lock reward percent - 0 to disable lock & vesting
        uint256 startVestingBlock; // Block number which vesting starts.
        uint256 endVestingBlock; // Block number which vesting ends.
        uint256 numOfVestingBlocks;
        uint256 totalPaidRewards;
    }

    mapping(address => UserInfo) public userInfo;
    RewardPoolInfo[] public rewardPoolInfo;
    address public override pair;
    address public rewardFund;
    address public timelock;
    address public controller;

    uint256 public balance;
    uint256 public unstakingFrozenTime = 3 days;
    uint256 private unlocked = 1;
    bool private _initialized = false;
    uint256 public constant BLOCKS_PER_DAY = 6528;

    constructor(address _controller, uint256 _version) {
        controller = _controller;
        timelock = msg.sender;
        version = _version;
    }

    modifier lock() {
        require(unlocked == 1, "StakePool: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier onlyTimeLock() {
        require(msg.sender == timelock, "StakePool: !timelock");
        _;
    }

    function allowRecoverRewardToken(address _token) external view override returns (bool) {
        for (uint8 pid = 0; pid < rewardPoolInfo.length; ++pid) {
            RewardPoolInfo storage rewardPool = rewardPoolInfo[pid];
            if (rewardPool.rewardToken == _token) {
                // do not allow to drain reward token if less than 30 days after pool ends
                if (block.number < (rewardPool.endRewardBlock + (BLOCKS_PER_DAY * 30))) {
                    return false;
                }
            }
        }
        return true;
    }

    // called once by the factory at time of deployment
    function initialize(
        address _pair,
        uint256 _unstakingFrozenTime,
        address _rewardFund,
        address _timelock
    ) external override {
        require(_initialized == false, "StakePool: Initialize must be false.");
        require(unstakingFrozenTime <= 30 days, "StakePool: unstakingFrozenTime > 30 days");
        pair = _pair;
        unstakingFrozenTime = _unstakingFrozenTime;
        rewardFund = _rewardFund;
        timelock = _timelock;
        _initialized = true;
    }

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
    ) external override lock onlyTimeLock {
        require(rewardPoolInfo.length <= 16, "StakePool: Reward pool length > 16");
        require(IStakePoolController(controller).isWhitelistRewardRebaser(_rewardRebaser), "StakePool: Invalid reward rebaser");
        require(IStakePoolController(controller).isWhitelistRewardMultiplier(_rewardMultiplier), "StakePool: Invalid reward multiplier");
        require(_startVestingBlock <= _endVestingBlock, "StakePool: startVestingBlock > endVestingBlock");
        _startBlock = (block.number > _startBlock) ? block.number : _startBlock;
        require(_startBlock < _endRewardBlock, "StakePool: startBlock >= endRewardBlock");
        require(_lockRewardPercent <= 100, "StakePool: invalid lockRewardPercent");
        updateReward();
        rewardPoolInfo.push(
            RewardPoolInfo({
                rewardToken: _rewardToken,
                rewardRebaser: _rewardRebaser,
                startRewardBlock: _startBlock,
                rewardMultiplier: _rewardMultiplier,
                lastRewardBlock: _startBlock,
                endRewardBlock: _endRewardBlock,
                rewardPerBlock: _rewardPerBlock,
                accRewardPerShare: 0,
                lockRewardPercent: _lockRewardPercent,
                startVestingBlock: _startVestingBlock,
                endVestingBlock: _endVestingBlock,
                numOfVestingBlocks: _endVestingBlock - _startVestingBlock,
                totalPaidRewards: 0
            })
        );
        emit AddRewardPool(rewardPoolInfo.length - 1);
    }

    function updateRewardMultiplier(uint8 _pid, address _rewardMultiplier) external override lock onlyTimeLock {
        require(IStakePoolController(controller).isWhitelistRewardMultiplier(_rewardMultiplier), "StakePool: Invalid reward multiplier");
        updateReward(_pid);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        rewardPool.rewardMultiplier = _rewardMultiplier;
        emit UpdateRewardMultiplier(_pid, _rewardMultiplier);
    }

    function updateRewardRebaser(uint8 _pid, address _rewardRebaser) external override lock onlyTimeLock {
        require(IStakePoolController(controller).isWhitelistRewardRebaser(_rewardRebaser), "StakePool: Invalid reward rebaser");
        updateReward(_pid);
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        rewardPool.rewardRebaser = _rewardRebaser;
        emit UpdateRewardRebaser(_pid, _rewardRebaser);
    }

    // Return reward multiplier over the given _from to _to block.
    function getRewardMultiplier(
        uint8 _pid,
        uint256 _from,
        uint256 _to,
        uint256 _rewardPerBlock
    ) public view override returns (uint256) {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        address rewardMultiplier = rewardPool.rewardMultiplier;
        if (rewardMultiplier == address(0)) {
            return _to.sub(_from).mul(_rewardPerBlock);
        }
        return
            IStakePoolRewardMultiplier(rewardMultiplier).getRewardMultiplier(
                rewardPool.startRewardBlock,
                rewardPool.endRewardBlock,
                _from,
                _to,
                _rewardPerBlock
            );
    }

    function getRewardRebase(
        uint8 _pid,
        address _rewardToken,
        uint256 _pendingReward
    ) public view override returns (uint256) {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        address rewardRebaser = rewardPool.rewardRebaser;
        if (rewardRebaser == address(0)) {
            return _pendingReward;
        }
        return IStakePoolRewardRebaser(rewardRebaser).getRebaseAmount(_rewardToken, _pendingReward);
    }

    function getRewardPerBlock(uint8 pid) external view override returns (uint256) {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[pid];
        uint256 rewardPerBlock = rewardPool.rewardPerBlock;
        if (block.number < rewardPool.startRewardBlock || block.number > rewardPool.endRewardBlock) return 0;
        uint256 reward = getRewardMultiplier(pid, block.number, block.number + 1, rewardPerBlock);
        return getRewardRebase(pid, rewardPool.rewardToken, reward);
    }

    function updateRewardPool(
        uint8 _pid,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock
    ) external override lock onlyTimeLock {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        require(block.number <= rewardPool.endRewardBlock && block.number <= _endRewardBlock, "StakePool: blockNumber > endRewardBlock");
        updateReward(_pid);
        rewardPool.endRewardBlock = _endRewardBlock;
        rewardPool.rewardPerBlock = _rewardPerBlock;
        emit UpdateRewardPool(_pid, _endRewardBlock, _rewardPerBlock);
    }

    function stake(uint256 _amount) external override lock {
        IValueLiquidPair(pair).transferFrom(msg.sender, address(this), _amount);
        _stakeFor(msg.sender);
    }

    function stakeFor(address _account) external override lock {
        require(IStakePoolController(controller).isWhitelistStakingFor(msg.sender), "StakePool: Invalid sender");
        _stakeFor(_account);
    }

    function _stakeFor(address _account) internal {
        uint256 _amount = IValueLiquidPair(pair).balanceOf(address(this)).sub(balance);
        require(_amount > 0, "StakePool: Invalid balance");
        balance = balance.add(_amount);
        UserInfo storage user = userInfo[_account];
        getAllRewards(_account);
        user.amount = user.amount.add(_amount);
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = user.amount.mul(rewardPoolInfo[_pid].accRewardPerShare).div(1e18);
        }
        user.lastStakeTime = block.timestamp;
        emit Deposit(_account, _amount);
    }

    function rewardPoolInfoLength() public view override returns (uint256) {
        return rewardPoolInfo.length;
    }

    function unfrozenStakeTime(address _account) public view override returns (uint256) {
        return userInfo[_account].lastStakeTime + unstakingFrozenTime;
    }

    function removeStakeInternal(uint256 _amount) internal {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "StakePool: invalid withdraw amount");
        require(block.timestamp >= user.lastStakeTime.add(unstakingFrozenTime), "StakePool: frozen");
        getAllRewards(msg.sender);
        balance = balance.sub(_amount);
        user.amount = user.amount.sub(_amount);
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = user.amount.mul(rewardPoolInfo[_pid].accRewardPerShare).div(1e18);
        }
    }

    function withdraw(uint256 _amount) external override lock {
        removeStakeInternal(_amount);
        IValueLiquidPair(pair).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function getAllRewards(address _account) public override {
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            getReward(_pid, _account);
        }
    }

    function claimReward() external override {
        getAllRewards(msg.sender);
    }

    function getReward(uint8 _pid, address _account) public override {
        updateReward(_pid);
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 _pendingReward = user.amount.mul(_accRewardPerShare).div(1e18).sub(user.rewardDebt[_pid]);
        uint256 _lockRewardPercent = rewardPool.lockRewardPercent;
        if (_lockRewardPercent > 0) {
            if (block.number > rewardPool.endVestingBlock) {
                uint256 _unlockReward = user.lockReward[_pid].sub(user.lockRewardReleased[_pid]);
                if (_unlockReward > 0) {
                    _pendingReward = _pendingReward.add(_unlockReward);
                    user.lockRewardReleased[_pid] = user.lockRewardReleased[_pid].add(_unlockReward);
                }
            } else {
                if (_pendingReward > 0) {
                    uint256 _toLocked = _pendingReward.mul(_lockRewardPercent).div(100);
                    _pendingReward = _pendingReward.sub(_toLocked);
                    user.lockReward[_pid] = user.lockReward[_pid].add(_toLocked);
                }
                uint256 _startVestingBlock = rewardPool.startVestingBlock;
                if (block.number > _startVestingBlock) {
                    uint256 _toReleased = user.lockReward[_pid].mul(block.number.sub(_startVestingBlock)).div(rewardPool.numOfVestingBlocks);
                    uint256 _lockRewardReleased = user.lockRewardReleased[_pid];
                    if (_toReleased > _lockRewardReleased) {
                        uint256 _unlockReward = _toReleased.sub(_lockRewardReleased);
                        user.lockRewardReleased[_pid] = _lockRewardReleased.add(_unlockReward);
                        _pendingReward = _pendingReward.add(_unlockReward);
                    }
                }
            }
        }
        if (_pendingReward > 0) {
            user.accumulatedEarned[_pid] = user.accumulatedEarned[_pid].add(_pendingReward);
            rewardPool.totalPaidRewards = rewardPool.totalPaidRewards.add(_pendingReward);
            user.rewardDebt[_pid] = user.amount.mul(_accRewardPerShare).div(1e18);
            uint256 reward = user.reward[_pid].add(_pendingReward);
            user.reward[_pid] = reward;
            // Safe reward transfer, just in case if rounding error causes pool to not have enough reward amount
            address rewardToken = rewardPool.rewardToken;
            uint256 rewardBalance = IERC20(rewardToken).balanceOf(rewardFund);
            if (rewardBalance > 0) {
                user.reward[_pid] = 0;
                uint256 rebaseAmount = getRewardRebase(_pid, rewardToken, reward);
                uint256 paidAmount = rebaseAmount > rewardBalance ? rewardBalance : rebaseAmount;
                IStakePoolRewardFund(rewardFund).safeTransfer(rewardToken, _account, paidAmount);
                emit PayRewardPool(_pid, rewardToken, _account, reward, rebaseAmount, paidAmount);
            }
        }
    }

    function pendingReward(uint8 _pid, address _account) external view override returns (uint256) {
        UserInfo storage user = userInfo[_account];
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint256 _accRewardPerShare = rewardPool.accRewardPerShare;
        uint256 lpSupply = IValueLiquidPair(pair).balanceOf(address(this));
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock && lpSupply != 0) {
            uint256 _incRewardPerShare =
                getRewardMultiplier(_pid, _lastRewardBlock, _endRewardBlockApplicable, rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
            _accRewardPerShare = _accRewardPerShare.add(_incRewardPerShare);
        }
        uint256 pending = user.amount.mul(_accRewardPerShare).div(1e18).add(user.reward[_pid]).sub(user.rewardDebt[_pid]);
        return getRewardRebase(_pid, rewardPool.rewardToken, pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external override lock {
        require(IStakePoolController(controller).isAllowEmergencyWithdrawStakePool(address(this)), "StakePool: Not allow emergencyWithdraw");
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        balance = balance.sub(amount);
        user.amount = 0;
        IValueLiquidPair(pair).transfer(msg.sender, amount);
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            user.rewardDebt[_pid] = 0;
            user.reward[_pid] = 0;
        }
    }

    function getUserInfo(uint8 _pid, address _account)
        public
        view
        override
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 accumulatedEarned,
            uint256 lockReward,
            uint256 lockRewardReleased
        )
    {
        UserInfo storage user = userInfo[_account];
        amount = user.amount;
        rewardDebt = user.rewardDebt[_pid];
        accumulatedEarned = user.accumulatedEarned[_pid];
        lockReward = user.lockReward[_pid];
        lockRewardReleased = user.lockRewardReleased[_pid];
    }

    function updateReward() public override {
        uint8 rewardPoolLength = uint8(rewardPoolInfo.length);
        for (uint8 _pid = 0; _pid < rewardPoolLength; ++_pid) {
            updateReward(_pid);
        }
    }

    function updateReward(uint8 _pid) public override {
        RewardPoolInfo storage rewardPool = rewardPoolInfo[_pid];
        uint256 _endRewardBlock = rewardPool.endRewardBlock;
        uint256 _endRewardBlockApplicable = block.number > _endRewardBlock ? _endRewardBlock : block.number;
        uint256 _lastRewardBlock = rewardPool.lastRewardBlock;
        if (_endRewardBlockApplicable > _lastRewardBlock) {
            uint256 lpSupply = IValueLiquidPair(pair).balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 _incRewardPerShare =
                    getRewardMultiplier(_pid, _lastRewardBlock, _endRewardBlockApplicable, rewardPool.rewardPerBlock).mul(1e18).div(lpSupply);
                rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(_incRewardPerShare);
            }
            rewardPool.lastRewardBlock = _endRewardBlockApplicable;
        }
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
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePool: Invalid provider");
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
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePool: Invalid provider");
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
        require(IStakePoolController(controller).isWhitelistStakingFor(provider), "StakePool: Invalid provider");
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

contract StakePoolHasOperatorCreator is IStakePoolCreator {
    uint256 public override version = 3002;

    struct PoolRewardInfo {
        address rewardRebaser;
        address rewardMultiplier;
        uint256 startBlock;
        uint256 endRewardBlock;
        uint256 rewardPerBlock;
        uint256 lockRewardPercent;
        uint256 startVestingBlock;
        uint256 endVestingBlock;
        uint256 unstakingFrozenTime;
    }

    function create() external override returns (address) {
        StakePool pool = new StakePool(msg.sender, version);
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
        StakePool pool = StakePool(poolAddress);
        PoolRewardInfo memory poolRewardInfo = abi.decode(data, (PoolRewardInfo));
        pool.addRewardPool(
            rewardToken,
            poolRewardInfo.rewardRebaser,
            poolRewardInfo.rewardMultiplier,
            poolRewardInfo.startBlock,
            poolRewardInfo.endRewardBlock,
            poolRewardInfo.rewardPerBlock,
            poolRewardInfo.lockRewardPercent,
            poolRewardInfo.startVestingBlock,
            poolRewardInfo.endVestingBlock
        );
        pool.initialize(pair, poolRewardInfo.unstakingFrozenTime, address(stakePoolRewardFund), address(timelock));
    }
}