/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

pragma solidity = 0.7.6;


interface PoolFactory {
    event PoolCreatedEvent(address tokenA, address tokenB, bool aIsWETH, address indexed pool);

    function getPool(address tokenA, address tokenB) external returns (address);
    function findPool(address tokenA, address tokenB) external view returns (address);
    function pools(uint poolIndex) external view returns (address pool);
    function getPoolCount() external view returns (uint);
}

interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256 supply);

    function approve(address spender, uint256 value) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface ActivityMeter {
    event Deposit(address indexed user, address indexed pool, uint amount);
    event Withdraw(address indexed user, address indexed pool, uint amount);

    function actualizeUserPool(uint endPeriod, address user, address pool) external returns (uint ethLocked, uint mintedAmount) ;  
    function deposit(address pool, uint128 amount) external returns (uint ethLocked, uint mintedAmount);
    function withdraw(address pool, uint128 amount) external returns (uint ethLocked, uint mintedAmount);
    function actualizeUserPools() external returns (uint ethLocked, uint mintedAmount);
    function liquidityEthPriceChanged(uint effectiveTime, uint availableBalanceEth, uint totalSupply) external;
    function effectivePeriod(uint effectiveTime) external view returns (uint periodNumber, uint quantaElapsed);
    function governanceRouter() external view returns (GovernanceRouter);
    function userEthLocked(address user) external view returns (uint ethLockedPeriod, uint ethLocked, uint totalEthLocked);
    
    function ethLockedHistory(uint period) external view returns (uint ethLockedTotal);

    function poolsPriceHistory(uint period, address pool) external view returns (
        uint cumulativeEthPrice,
        uint240 lastEthPrice,
        uint16 timeRef
    );

    function userPoolsSummaries(address user, address pool) external view returns (
        uint144 cumulativeAmountLocked,
        uint16 amountChangeQuantaElapsed,

        uint128 lastAmountLocked,
        uint16 firstPeriod,
        uint16 lastPriceRecord,
        uint16 earnedForPeriod
    );

    function userPools(address user, uint poolIndex) external view returns (address pool);
    function userPoolsLength(address user) external view returns (uint length);

    function userSummaries(address user) external view returns (
        uint128 ethLocked,
        uint16 ethLockedPeriod,
        uint16 firstPeriod
    );
    
    function poolSummaries(address pool) external view returns (
        uint16 lastPriceRecord
    );
    
    function users(uint userIndex) external view returns (address user);
    function usersLength() external view returns (uint);
}

interface Minter is ERC20 {
    event Mint(address indexed to, uint256 value, uint indexed period, uint userEthLocked, uint totalEthLocked);

    function governanceRouter() external view returns (GovernanceRouter);
    function mint(address to, uint period, uint128 userEthLocked, uint totalEthLocked) external returns (uint amount);
    function userTokensToClaim(address user) external view returns (uint amount);
    function periodTokens(uint period) external pure returns (uint128);
    function periodDecayK() external pure returns (uint decayK);
    function initialPeriodTokens() external pure returns (uint128);
}

interface WETH is ERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface GovernanceRouter {
    event GovernanceApplied(uint packedGovernance);
    event GovernorChanged(address covernor);
    event ProtocolFeeReceiverChanged(address protocolFeeReceiver);
    event PoolFactoryChanged(address poolFactory);

    function schedule() external returns(uint timeZero, uint miningPeriod);
    function creator() external returns(address);
    function weth() external returns(WETH);

    function activityMeter() external returns(ActivityMeter);
    function setActivityMeter(ActivityMeter _activityMeter) external;

    function minter() external returns(Minter);
    function setMinter(Minter _minter) external;

    function poolFactory() external returns(PoolFactory);
    function setPoolFactory(PoolFactory _poolFactory) external;

    function protocolFeeReceiver() external returns(address);
    function setProtocolFeeReceiver(address _protocolFeeReceiver) external;

    function governance() external view returns (address _governor, uint96 _defaultGovernancePacked);
    function setGovernor(address _governor) external;
    function applyGovernance(uint96 _defaultGovernancePacked) external;
}

interface LiquidityPool is ERC20 {
    enum MintReason { DEPOSIT, PROTOCOL_FEE, INITIAL_LIQUIDITY }
    event Mint(address indexed to, uint256 value, MintReason reason);

    // ORDER_CLOSED reasons are all odd, other reasons are even
    // it allows to check ORDER_CLOSED reasons as (reason & ORDER_CLOSED) != 0
    enum BreakReason { 
        NONE,        ORDER_CLOSED, 
        ORDER_ADDED, ORDER_CLOSED_BY_STOP_LOSS, 
        SWAP,        ORDER_CLOSED_BY_REQUEST,
        MINT,        ORDER_CLOSED_BY_HISTORY_LIMIT,
        BURN,        ORDER_CLOSED_BY_GOVERNOR
    }

    function poolBalances() external view returns (
        uint balanceALocked,
        uint poolFlowSpeedA, // flow speed: (amountAIn * 2^32)/second

        uint balanceBLocked,
        uint poolFlowSpeedB, // flow speed: (amountBIn * 2^32)/second

        uint totalBalanceA,
        uint totalBalanceB,

        uint delayedSwapsIncome,
        uint rootKLastTotalSupply
    );

    function governanceRouter() external returns (GovernanceRouter);
    function minimumLiquidity() external returns (uint);
    function aIsWETH() external returns (bool);

    function mint(address to) external returns (uint liquidityOut);
    function burn(address to, bool extractETH) external returns (uint amountAOut, uint amountBOut);
    function swap(address to, bool extractETH, uint amountAOut, uint amountBOut, bytes calldata externalData) external returns (uint amountAIn, uint amountBIn);

    function tokenA() external view returns (ERC20);
    function tokenB() external view returns (ERC20);
}

interface DelayedExchangePool is LiquidityPool {
    event FlowBreakEvent( 
        address sender, 
        // total balance contains 128 bit of totalBalanceA and 128 bit of totalBalanceB
        uint totalBalance, 
        // contains 128 bits of rootKLast and 128 bits of totalSupply
        uint rootKLastTotalSupply, 
        uint indexed orderId,
        // breakHash is computed over all fields below
        
        bytes32 lastBreakHash,
        // availableBalance consists of 128 bits of availableBalanceA and 128 bits of availableBalanceB
        uint availableBalance, 
        // flowSpeed consists of 144 bits of poolFlowSpeedA and 112 higher bits of poolFlowSpeedB
        uint flowSpeed,
        // others consists of 32 lower bits of poolFlowSpeedB, 16 bit of notFee, 64 bit of time, 64 bit of orderId, 76 higher bits of packed and 4 bit of reason (BreakReason)
        uint others      
    );

    event OrderClaimedEvent(uint indexed orderId, address to);
    event OperatingInInvalidState(uint location, uint invalidStateReason);
    event GovernanceApplied(uint packedGovernance);
    
    function addOrder(
        address owner, uint orderFlags, uint prevByStopLoss, uint prevByTimeout, 
        uint stopLossAmount, uint period
    ) external returns (uint id);

    // availableBalance contains 128 bits of availableBalanceA and 128 bits of availableBalanceB
    // delayedSwapsIncome contains 128 bits of delayedSwapsIncomeA and 128 bits of delayedSwapsIncomeB
    function processDelayedOrders() external returns (uint availableBalance, uint delayedSwapsIncome, uint packed);

    function claimOrder (
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory
    ) external returns (address owner, uint amountAOut, uint amountBOut);

    function applyGovernance(uint packedGovernanceFields) external;
    function sync() external;
    function closeOrder(uint id) external;

    function poolQueue() external view returns (
        uint firstByTokenAStopLoss, uint lastByTokenAStopLoss, // linked list of orders sorted by (amountAIn/stopLossAmount) ascending
        uint firstByTokenBStopLoss, uint lastByTokenBStopLoss, // linked list of orders sorted by (amountBIn/stopLossAmount) ascending
    
        uint firstByTimeout, uint lastByTimeout // linked list of orders sorted by timeouts ascending
    );

    function lastBreakHash() external view returns (bytes32);

    function poolState() external view returns (
        bytes32 _prevBlockBreakHash,
        uint packed, // see Liquifi.PoolState for details
        uint notFee,

        uint lastBalanceUpdateTime,
        uint nextBreakTime,
        uint maxHistory,
        uint ordersToClaimCount,
        uint breaksCount
    );

    function findOrder(uint orderId) external view returns (        
        uint nextByTimeout, uint prevByTimeout,
        uint nextByStopLoss, uint prevByStopLoss,
        
        uint stopLossAmount,
        uint amountIn,
        uint period,
        
        address owner,
        uint timeout,
        uint flags
    );
}

enum ConvertETH { NONE, IN_ETH, OUT_ETH }

interface PoolRegister {
    event Mint(address token1, uint amount1, address token2, uint amount2, uint liquidityOut, address to, ConvertETH convertETH);
    event Burn(address token1, uint amount1, address token2, uint amount2, uint liquidityIn, address to, ConvertETH convertETH);
    event Swap(address tokenIn, uint amountIn, address tokenOut, uint amountOut, address to, ConvertETH convertETH, uint fee);
    event DelayedSwap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, ConvertETH convertETH, uint16 period, uint64 orderId);
    event OrderClaimed(uint orderId, address tokenA, uint amountAOut, address tokenB, uint amountBOut, address to);

    function factory() external view returns (PoolFactory);
    function weth() external view returns (WETH);
    
    function deposit(address token1, uint amount1, address token2, uint amount2, address to, uint timeout) 
        external returns (uint liquidityOut, uint amount1Used, uint amount2Used);
    function depositWithETH(address token, uint amount, address to, uint timeout) 
        payable external returns (uint liquidityOut, uint amountETHUsed, uint amountTokenUsed);
    
    function withdraw(address token1, address token2, uint liquidity, address to, uint timeout) external returns (uint amount1, uint amount2);
    function withdrawWithETH(address token1, uint liquidityIn, address to, uint timeout) external returns (uint amount1, uint amountETH);

    function swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, uint timeout) external returns (uint amountOut);
    function swapFromETH(address tokenOut, uint minAmountOut, address to, uint timeout) payable external returns (uint amountOut);
    function swapToETH(address tokenIn, uint amountIn, uint minAmountOut, address to, uint timeout) external returns (uint amountETHOut);

    function delayedSwap(
        address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, uint timeout,
        uint prevByStopLoss, uint prevByTimeout
    ) external returns (uint orderId);
    function delayedSwapFromETH(
        address tokenOut, uint minAmountOut, address to, uint timeout, 
        uint prevByStopLoss, uint prevByTimeout
    ) external payable returns (uint orderId);
    function delayedSwapToETH(address tokenIn, uint amountIn, uint minAmountOut, address to, uint timeout,
        uint prevByStopLoss, uint prevByTimeout
    ) external returns (uint orderId);

    function processDelayedOrders(address token1, address token2, uint timeout) external returns (uint availableBalanceA, uint availableBalanceB);

    function claimOrder(
        address tokenIn, address tokenOut,
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory,
        uint timeout
    ) external returns (address to, uint amountOut, uint amountRefund);

    function claimOrderWithETH(
        address token,
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory,
        uint timeout
    ) external returns (address to, uint amountOut, uint amountRefund);

    function setupDistributionPool(
        address tokenIn, address tokenOut, uint initialBalance, uint minDistributionPrice, uint8 coverageRatio, uint minDealAmount
    ) external;

    function updateDistributionPool(
        address tokenIn, address tokenOut, uint addedBalance, uint minDistributionPrice, uint8 coverageRatio, uint minDealAmount
    ) external;

    function removeDistributionPool(
        address tokenIn, address tokenOut
    ) external;

    function withdrawFromDistributionPool(
        address tokenIn, address tokenOut, uint amountToWithdraw
    ) external;

}

library Liquifi {
    enum Flag { 
        // padding 8 bits
        PAD1, PAD2, PAD3, PAD4, PAD5, PAD6, PAD7, PAD8,
        // transient flags
        HASH_DIRTY, BALANCE_A_DIRTY, BALANCE_B_DIRTY, TOTALS_DIRTY, QUEUE_STOPLOSS_DIRTY, QUEUE_TIMEOUT_DIRTY, MUTEX, INVALID_STATE,
        TOTAL_SUPPLY_DIRTY, SWAPS_INCOME_DIRTY, RESERVED1, RESERVED2,
        // persistent flags set by governance
        POOL_LOCKED, ARBITRAGEUR_FULL_FEE, GOVERNANCE_OVERRIDEN
    }

    struct PoolBalances { // optimized for storage
        // saved on BALANCE_A_DIRTY in exit()
        uint112 balanceALocked;
        uint144 poolFlowSpeedA; // flow speed: (amountAIn * 2^32)/second

        // saved on BALANCE_B_DIRTY in exit()
        uint112 balanceBLocked;
        uint144 poolFlowSpeedB; // flow speed: (amountBIn * 2^32)/second
        
        // saved on TOTALS_DIRTY in exit()
        uint128 totalBalanceA;
        uint128 totalBalanceB;

        // saved on SWAPS_INCOME_DIRTY in exit()
        // contains 128 bits of delayedSwapsIncomeA and 128 bits of delayedSwapsIncomeB
        uint delayedSwapsIncome;
        
        // saved on TOTAL_SUPPLY_DIRTY in exit()
        // contains 128 bits of rootKLast and 128 bits of totalSupply
        // rootKLast = sqrt(availableBalanceA * availableBalanceB), as of immediately after the most recent liquidity event
        uint rootKLastTotalSupply;
    }

    struct PoolState { // optimized for storage
        // saved on HASH_DIRTY in exit()
        bytes32 lastBreakHash;

        // saved on QUEUE_STOPLOSS_DIRTY in exit()
        uint64 firstByTokenAStopLoss; uint64 lastByTokenAStopLoss; // linked list of orders sorted by (amountAIn/stopLossAmount) ascending
        uint64 firstByTokenBStopLoss; uint64 lastByTokenBStopLoss; // linked list of orders sorted by (amountBIn/stopLossAmount) ascending

        // saved on QUEUE_TIMEOUT_DIRTY in exit()
        uint64 firstByTimeout; uint64 lastByTimeout; // linked list of orders sorted by timeouts ascending
        // this field contains
        // 8 bits of instantSwapFee
        // 8 bits of desiredOrdersFee
        // 8 bits of protocolFee
        // 32 bits of maxPeriod
        // 16 bits of desiredMaxHistory
        // 4 bits of persistent flags
        // 12 bits of transient flags
        // 8 bits of transient invalidStateReason (ErrorArg)
        // Packing reduces stack depth and helps in governance
        uint96 packed; // not saved in exit(), saved only by governance
        uint16 notFee; // not saved in exit()

        // This word is always saved in exit()
        uint64 lastBalanceUpdateTime;
        uint64 nextBreakTime;
        uint32 maxHistory;
        uint32 ordersToClaimCount;
        uint64 breaksCount; // counter with increments of 2. 1st bit is used as mutex flag
    }

    enum OrderFlag { 
        NONE, IS_TOKEN_A, EXTRACT_ETH
    }

    struct Order { // optimized for storage, fits into 3 words
        // Also closing hash is saved in this word on order close.
        // Closing hash always has last bit = 1, I.e. prevByStopLoss & 1 == 1
        uint64 nextByTimeout; uint64 prevByTimeout;
        uint64 nextByStopLoss; uint64 prevByStopLoss;
        
        // mostly used together
        uint112 stopLossAmount;
        uint112 amountIn;
        uint32 period;

        address owner;
        uint64 timeout;
        uint8 flags;
    }

    struct OrderClaim { //in-memory only
        uint amountOut;
        uint orderFlowSpeed;
        uint orderId;
        uint flags;
        uint closeReason;
        uint previousAvailableBalance;
        uint previousFlowSpeed;
        uint previousOthers;
    }

    enum Error { 
        A_MUL_OVERFLOW, 
        B_ADD_OVERFLOW, 
        C_TOO_BIG_TIME_VALUE, 
        D_TOO_BIG_PERIOD_VALUE,
        E_TOO_BIG_AMOUNT_VALUE,
        F_ZERO_AMOUNT_VALUE,
        G_ZERO_PERIOD_VALUE,
        H_BALANCE_AFTER_BREAK,
        I_BALANCE_OF_SAVED_UPD,
        J_INVALID_POOL_STATE,
        K_TOO_BIG_TOTAL_VALUE,
        L_INSUFFICIENT_LIQUIDITY,
        M_EMPTY_LIST,
        N_BAD_LENGTH,
        O_HASH_MISMATCH,
        P_ORDER_NOT_CLOSED,
        Q_ORDER_NOT_ADDED,
        R_INCOMPLETE_HISTORY,
        S_REENTRANCE_NOT_SUPPORTED,
        T_INVALID_TOKENS_PAIR,
        U_TOKEN_TRANSFER_FAILED,
        V_ORDER_NOT_EXIST,
        W_DIV_BY_ZERO,
        X_ORDER_ALREADY_CLOSED,
        Y_UNAUTHORIZED_SENDER,
        Z_TOO_BIG_FLOW_SPEED_VALUE
    }

    enum ErrorArg {
        A_NONE,
        B_IN_AMOUNT,
        C_OUT_AMOUNT,
        D_STOP_LOSS_AMOUNT,
        E_IN_ADD_ORDER,
        F_IN_SWAP,
        G_IN_COMPUTE_AVAILABLE_BALANCE,
        H_IN_BREAKS_HISTORY,
        I_USER_DATA,
        J_IN_ORDER,
        K_IN_MINT,
        L_IN_BURN,
        M_IN_CLAIM_ORDER,
        N_IN_PROCESS_DELAYED_ORDERS,
        O_TOKEN_A,
        P_TOKEN_B,
        Q_TOKEN_ETH,
        R_IN_CLOSE_ORDER,
        S_BY_GOVERNANCE,
        T_FEE_CHANGED_WITH_ORDERS_OPEN,
        U_BAD_EXCHANGE_RATE,
        V_INSUFFICIENT_TOTAL_BALANCE,
        W_POOL_LOCKED,
        X_TOTAL_SUPPLY
    }

    // this methods allows to pass some information in 'require' calls without storing strings in contract bytecode 
    // messages will be like "FAIL https://err.liquifi.org/XY" where X and Y are error and errorArg from respective enums
    function _require(bool condition, Error error, ErrorArg errorArg) internal pure {
        if (condition) return;
        { // new scope to not waste message memory if condition is satisfied 
            // FAIL https://err.liquifi.org/__
            bytes memory message = "\x46\x41\x49\x4c\x20\x68\x74\x74\x70\x73\x3a\x2f\x2f\x65\x72\x72\x2e\x6c\x69\x71\x75\x69\x66\x69\x2e\x6f\x72\x67\x2f\x5f\x5f";
            
            message[29] = bytes1(65 + uint8(error));
            message[30] = bytes1(65 + uint8(errorArg));
            require(false, string(message));
        }
    }

    uint64 constant maxTime = ~uint64(0);

    function trimTime(uint time) internal pure returns (uint64 trimmedTime) {
        Liquifi._require(time <= maxTime, Liquifi.Error.C_TOO_BIG_TIME_VALUE, Liquifi.ErrorArg.A_NONE);
        return uint64(time);
    }

    function trimPeriod(uint period, Liquifi.ErrorArg periodType) internal pure returns (uint32 trimmedPeriod) {
        Liquifi._require(period <= ~uint32(0), Liquifi.Error.D_TOO_BIG_PERIOD_VALUE, periodType);
        return uint32(period);
    }

    function trimAmount(uint amount, Liquifi.ErrorArg amountType) internal pure returns (uint112 trimmedAmount) {
        Liquifi._require(amount <= ~uint112(0), Liquifi.Error.E_TOO_BIG_AMOUNT_VALUE, amountType);
        return uint112(amount);
    }


    function trimTotal(uint amount, Liquifi.ErrorArg amountType) internal pure returns (uint128 trimmedAmount) {
        Liquifi._require(amount <= ~uint128(0), Liquifi.Error.K_TOO_BIG_TOTAL_VALUE, amountType);
        return uint128(amount);
    }

    function trimFlowSpeed(uint amount, Liquifi.ErrorArg amountType) internal pure returns (uint144 trimmedAmount) {
        Liquifi._require(amount <= ~uint144(0), Liquifi.Error.Z_TOO_BIG_FLOW_SPEED_VALUE, amountType);
        return uint144(amount);
    }

    function checkFlag(PoolState memory _state, Flag flag) internal pure returns(bool) {
        return _state.packed & uint96(1 << uint(flag)) != 0;
    }

    function setFlag(PoolState memory _state, Flag flag) internal pure {
        _state.packed = _state.packed | uint96(1 << uint(flag));
    }

    function clearFlag(PoolState memory _state, Flag flag) internal pure {
        _state.packed = _state.packed & ~uint96(1 << uint(flag));
    }

    function unpackGovernance(PoolState memory _state) internal pure returns(
        uint instantSwapFee, uint desiredOrdersFee, uint protocolFee, uint maxPeriod, uint desiredMaxHistory
    ) {
        desiredMaxHistory = uint16(_state.packed >> 24);
        maxPeriod = uint32(_state.packed >> 40);
        protocolFee = uint8(_state.packed >> 72);
        desiredOrdersFee = uint8(_state.packed >> 80);
        instantSwapFee = uint8(_state.packed >> 88);
    }

    function setInvalidState(PoolState memory _state, Liquifi.ErrorArg reason) internal pure {
        setFlag(_state, Liquifi.Flag.INVALID_STATE);
        uint oldReason = uint8(_state.packed);
        if (uint(reason) > oldReason) {
            _state.packed = _state.packed & ~uint96(~uint8(0)) | uint96(reason);
        }
    }

    function checkInvalidState(PoolState memory _state) internal pure returns (Liquifi.ErrorArg reason) {
        reason = Liquifi.ErrorArg.A_NONE;
        if (checkFlag(_state, Liquifi.Flag.INVALID_STATE)) {
            return Liquifi.ErrorArg(uint8(_state.packed));
        }
    }

    function isTokenAIn(uint orderFlags) internal pure returns (bool) {
        return orderFlags & uint(Liquifi.OrderFlag.IS_TOKEN_A) != 0;
    }
}

library Math {
    
    function max(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = x < y ? x : y;
    }

    function sqrt(uint x) internal pure returns (uint result) {
        uint y = x;
        result = (x + 1) / 2;
        while (result < y) {
            y = result;
            result = (x / result + result) / 2;
        }
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        Liquifi._require(y == 0 || (z = x * y) / y == x, Liquifi.Error.A_MUL_OVERFLOW, Liquifi.ErrorArg.A_NONE);
    }

    function mulWithClip(uint x, uint y, uint maxValue) internal pure returns (uint z) {
        if (y != 0 && ((z = x * y) / y != x || z > maxValue)) {
            z = maxValue;
        }
    }

    function subWithClip(uint x, uint y) internal pure returns (uint z) {
        if ((z = x - y) > x) {
            return 0;
        }
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        Liquifi._require((z = x + y) >= x, Liquifi.Error.B_ADD_OVERFLOW, Liquifi.ErrorArg.A_NONE);
    }

    function addWithClip(uint x, uint y, uint maxValue) internal pure returns (uint z) {
        if ((z = x + y) < x || z > maxValue) {
            z = maxValue;
        }
    }

    // function div(uint x, uint y, Liquifi.ErrorArg scope) internal pure returns (uint z) {
    //     Liquifi._require(y != 0, Liquifi.Error.R_DIV_BY_ZERO, scope);
    //     z = x / y;
    // }
}

// SPDX-License-Identifier: GPL-3.0
//import { Debug } from "./libraries/Debug.sol";
contract LiquifiPoolRegister is PoolRegister {
    PoolFactory public immutable override factory;
    WETH public immutable override weth;
	ERC20 public immutable lqf;
	
	uint public immutable tokensRequiredToCreateDistributionPool; 

    using Math for uint256;

    struct DistributionPool {
		address owner;
		address tokenIn;
		address tokenOut;
		uint balance;
		uint minDistributionPrice;
		uint8 coverageRatio;
		uint minDealAmount;
    }
	
	mapping(/*pool*/address => DistributionPool) public distributionPools;
	
    modifier beforeTimeout(uint timeout) {
        require(timeout >= block.timestamp, 'LIQUIFI: EXPIRED CALL');
        _;
    }

    constructor (address _governanceRouter, uint _tokensRequiredToCreateDistributionPool) public {
        factory = GovernanceRouter(_governanceRouter).poolFactory();
        weth = GovernanceRouter(_governanceRouter).weth();
		lqf = ERC20(GovernanceRouter(_governanceRouter).minter());
		tokensRequiredToCreateDistributionPool = _tokensRequiredToCreateDistributionPool;
    }

    receive() external payable {
        assert(msg.sender == address(weth));
    }

    function smartTransferFrom(address token, address to, uint value, ConvertETH convertETH) internal {
        address from = (token == address(weth) && convertETH == ConvertETH.IN_ETH) ? address(this) : msg.sender;

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            ERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'LIQUIFI: TRANSFER_FROM_FAILED');
    }

    function smartTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            ERC20.transfer.selector, to, value));
        success = success && (data.length == 0 || abi.decode(data, (bool)));

        require(success, "LIQUIFI: TOKEN_TRANSFER_FAILED");
    }

    function smartTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'LIQUIFI: ETH_TRANSFER_FAILED');
    }

    // Registry always creates pools with tokens in proper order
    function properOrder(address tokenA, address tokenB) view private returns (bool) {
        return (tokenA == address(weth) ? address(0) : tokenA) < (tokenB == address(weth) ? address(0) : tokenB);
    }

    function _deposit(address token1, uint amount1, address token2, uint amount2, address to, ConvertETH convertETH, uint timeout) 
        private beforeTimeout(timeout) returns (uint liquidityOut, uint amountA, uint amountB) {
        address pool;
        {
            (address tokenA, address tokenB) = properOrder(token1, token2) ? (token1, token2) : (token2, token1);
            (amountA, amountB) = properOrder(token1, token2) ? (amount1, amount2) : (amount2, amount1);
            pool = factory.getPool(tokenA, tokenB);
        }
        uint availableBalanceA;
        uint availableBalanceB;
        {
            (uint availableBalance, , ) = DelayedExchangePool(pool).processDelayedOrders();
            availableBalanceA = uint128(availableBalance >> 128);
            availableBalanceB = uint128(availableBalance);
        }
        
        if (availableBalanceA != 0 && availableBalanceB != 0) {
            uint amountBOptimal = amountA.mul(availableBalanceB) / availableBalanceA;
            if (amountBOptimal <= amountB) {
                //require(amountBOptimal >= amountBMin, 'LIQUIFI: INSUFFICIENT_B_AMOUNT');
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = amountB.mul(availableBalanceA) / availableBalanceB;
                assert(amountAOptimal <= amountA);
                //require(amountAOptimal >= amountAMin, 'LIQUIFI: INSUFFICIENT_A_AMOUNT');
                amountA = amountAOptimal;
            }
        }

        (amount1, amount2) = properOrder(token1, token2) ? (amountA, amountB) : (amountB, amountA);

        smartTransferFrom(token1, pool, amount1, convertETH);
        smartTransferFrom(token2, pool, amount2, convertETH);
        liquidityOut = DelayedExchangePool(pool).mint(to);
        emit Mint(token1, amount1, token2, amount2, liquidityOut, to, convertETH);
    }

    function deposit(address token1, uint amount1, address token2, uint amount2, address to, uint timeout) 
        external override returns (uint liquidityOut, uint amount1Used, uint amount2Used) {
        uint amountA;
        uint amountB;
        (liquidityOut, amountA, amountB) = _deposit(token1, amount1, token2, amount2, to, ConvertETH.NONE, timeout);
        (amount1Used, amount2Used) = properOrder(token1, token2) ? (amountA, amountB) : (amountB, amountA);
    }

    function depositWithETH(address token, uint amount, address to, uint timeout) 
        payable external override returns (uint liquidityOut, uint amountETHUsed, uint amountTokenUsed) {
        uint amountETH = msg.value;
        weth.deposit{value: amountETH}();
        require(weth.approve(address(this), amountETH), "LIQUIFI: WETH_APPROVAL_FAILED");
        (liquidityOut, amountETHUsed, amountTokenUsed) = _deposit(address(weth), amountETH, token, amount, to, ConvertETH.IN_ETH, timeout);
        
        if (amountETH > amountETHUsed) {
            uint refundETH = amountETH - amountETH;
            weth.withdraw(refundETH);
            smartTransferETH(msg.sender, refundETH);
        }
    }

    function _withdraw(address token1, address token2, uint liquidityIn, address to, ConvertETH convertETH, uint timeout) 
        private beforeTimeout(timeout) returns (uint amount1, uint amount2) {
        address pool = factory.findPool(token1, token2);
        require(pool != address(0), "LIQIFI: WITHDRAW_FROM_INVALID_POOL");
        require(
            DelayedExchangePool(pool).transferFrom(msg.sender, pool, liquidityIn),
            "LIQIFI: TRANSFER_FROM_FAILED"
        );
        (uint amountA, uint amountB) = DelayedExchangePool(pool).burn(to, convertETH == ConvertETH.OUT_ETH);
        (amount1, amount2) = properOrder(token1, token2) ? (amountA, amountB) : (amountB, amountA);
        emit Burn(token1, amount1, token2, amount2, liquidityIn, to, convertETH);
    }

    function withdraw(address token1, address token2, uint liquidityIn, address to, uint timeout) 
        external override returns (uint amount1, uint amount2) {
        return _withdraw(token1, token2, liquidityIn, to, ConvertETH.NONE, timeout);
    }

    function withdrawWithETH(address token, uint liquidityIn, address to, uint timeout) 
        external override returns (uint amountToken, uint amountETH) {
        (amountETH, amountToken) = _withdraw(address(weth), token, liquidityIn, to, ConvertETH.OUT_ETH, timeout);
    }

    function _swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, ConvertETH convertETH, uint timeout) 
        private beforeTimeout(timeout) returns (uint amountOut) {
        address pool = factory.findPool(tokenIn, tokenOut);
        require(pool != address(0), "LIQIFI: SWAP_ON_INVALID_POOL");

        smartTransferFrom(tokenIn, pool, amountIn, convertETH);
        
        bool isTokenAIn = properOrder(tokenIn, tokenOut);
        (uint amountAOut, uint amountBOut, uint fee) = getAmountsOut(pool, isTokenAIn, amountIn, minAmountOut);
        DelayedExchangePool(pool).swap(to, convertETH == ConvertETH.OUT_ETH, amountAOut, amountBOut, new bytes(0));
        amountOut = isTokenAIn ? amountBOut : amountAOut;
        emit Swap(tokenIn, amountIn, tokenOut, amountOut, to, convertETH, fee);
    }

    function swap(address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, uint timeout) 
        external override returns (uint amountOut) {
        return _swap(tokenIn, amountIn, tokenOut, minAmountOut, to, ConvertETH.NONE, timeout);
    }

    function swapFromETH(address tokenOut, uint minAmountOut, address to, uint timeout) 
        external payable override returns (uint amountOut) {
        uint amountETH = msg.value;
        weth.deposit{value: amountETH}();
        require(weth.approve(address(this), amountETH), "LIQUIFI: WETH_APPROVAL_FAILED");
        
        return _swap(address(weth), amountETH, tokenOut, minAmountOut, to, ConvertETH.IN_ETH, timeout);
    }

    function swapToETH(address tokenIn, uint amountIn, uint minAmountOut, address to, uint timeout) 
        external override returns (uint amountETHOut) {
        amountETHOut = _swap(tokenIn, amountIn, address(weth), minAmountOut, to, ConvertETH.OUT_ETH, timeout);
    }

    function _delayedSwap(
        address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, ConvertETH convertETH, uint time, 
        uint prevByStopLoss, uint prevByTimeout
    ) private beforeTimeout(time) returns (uint orderId) {
        time -= block.timestamp; // reuse variable to reduce stack size

        address pool = factory.findPool(tokenIn, tokenOut);
        require(pool != address(0), "LIQIFI: DELAYED_SWAP_ON_INVALID_POOL");
        smartTransferFrom(tokenIn, pool, amountIn, convertETH);
        

        uint orderFlags = 0;
        if (properOrder(tokenIn, tokenOut)) {
            orderFlags |= 1; // IS_TOKEN_A
        }
        if (convertETH == ConvertETH.OUT_ETH) {
            orderFlags |= 2; // EXTRACT_ETH
        }
        orderId = DelayedExchangePool(pool).addOrder(to, orderFlags, prevByStopLoss, prevByTimeout, minAmountOut, time);
        // TODO: add optional checking if prevByStopLoss/prevByTimeout matched provided values
        DelayedSwap(tokenIn, amountIn, tokenOut, minAmountOut, to, convertETH, uint16(time), uint64(orderId));
		
		_counterSwap(pool, tokenOut, amountIn, minAmountOut, time + block.timestamp);
    }

    function delayedSwap(
        address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, uint timeout, 
        uint prevByStopLoss, uint prevByTimeout
    ) external override returns (uint orderId) {
        require(tokenOut != address(0), "LIQUIFI: INVALID TOKEN OUT");
        return _delayedSwap(tokenIn, amountIn, tokenOut, minAmountOut, to, ConvertETH.NONE, timeout, prevByStopLoss, prevByTimeout);
    }

    function delayedSwapFromETH(
        address tokenOut, uint minAmountOut, address to, uint timeout, 
        uint prevByStopLoss, uint prevByTimeout
    ) external payable override returns (uint orderId) {
        uint amountETH = msg.value;
        weth.deposit{value: amountETH}();
        require(weth.approve(address(this), amountETH), "LIQUIFI: WETH_APPROVAL_FAILED");

        return _delayedSwap(address(weth), amountETH, tokenOut, minAmountOut, to, ConvertETH.IN_ETH, timeout, prevByStopLoss, prevByTimeout);
    }

    function delayedSwapToETH(address tokenIn, uint amountIn, uint minAmountOut, address to, uint timeout,
        uint prevByStopLoss, uint prevByTimeout
    ) external override returns (uint orderId) {
        orderId = _delayedSwap(tokenIn, amountIn, address(weth), minAmountOut, to, ConvertETH.OUT_ETH, timeout, prevByStopLoss, prevByTimeout);
    }

    function processDelayedOrders(address token1, address token2, uint timeout) 
        external override beforeTimeout(timeout) returns (uint availableBalance1, uint availableBalance2) {
        address pool = factory.findPool(token1, token2);
        require(pool != address(0), "LIQIFI: PROCESS_DELAYED_ORDERS_ON_INVALID_POOL");
        uint availableBalance;
        (availableBalance, , ) = DelayedExchangePool(pool).processDelayedOrders();
        uint availableBalanceA = uint128(availableBalance >> 128);
        uint availableBalanceB = uint128(availableBalance);
        (availableBalance1, availableBalance2) = properOrder(token1, token2) ? (availableBalanceA, availableBalanceB) : (availableBalanceB, availableBalanceA);
    }

    function _claimOrder(
        address token1, address token2,
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaks,
        uint timeout
    ) private beforeTimeout(timeout) returns (address to, uint amountAOut, uint amountBOut) {
        address pool = factory.findPool(token1, token2);
        require(pool != address(0), "LIQIFI: CLAIM_ORDER_ON_INVALID_POOL");
        (to, amountAOut, amountBOut) = DelayedExchangePool(pool).claimOrder(previousBreakHash, breaks);
        (address tokenA, address tokenB) = properOrder(token1, token2) ? (token1, token2) : (token2, token1);
        uint orderId = uint64(breaks[2] >> 80);
        emit OrderClaimed(orderId, tokenA, amountAOut, tokenB, amountBOut, to);
    }
    
    function claimOrder(
        address tokenIn, address tokenOut,
        bytes32 previousBreakHash,
        // data from FlowBreakEvent events should be passed in this array
        // first event is the one related to order creation (having finalizing orderId and reason = ORDER_ADDED)
        // last event is the one related to order closing  (having finalizing orderId and reason = ORDER_TIMEOUT|ORDER_STOP_LOSS)
        // 3 256bit variable per event are packed in one list to reduce stack depth: 
        // availableBalance (0), flowSpeed (1), others (2)
        // availableBalance consists of 128 bits of availableBalanceA and 128 bits of availableBalanceB
        // flowSpeed consists of 144 bits of poolFlowSpeedA and 112 higher bits of poolFlowSpeedB
        // others consists of 32 lower bits of poolFlowSpeedB, 16 bit of notFee, 64 bit of time, 64 bit of orderId, 76 higher bits of packed and 4 bit of reason (BreakReason)
        uint[] calldata breaksHistory,
        uint timeout
    ) external override returns (address to, uint amountOut, uint amountRefund) {
        uint amountAOut;
        uint amountBOut;
        (to, amountAOut, amountBOut) = _claimOrder(tokenIn, tokenOut, previousBreakHash, breaksHistory, timeout);
        (amountOut, amountRefund) = properOrder(tokenIn, tokenOut) ? (amountBOut, amountAOut) : (amountAOut, amountBOut);
    }

    function claimOrderWithETH(
        address token,
        bytes32 previousBreakHash,
        // see LiquifyPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory,
        uint timeout
    ) external override returns (address to, uint amountETHOut, uint amountTokenOut) {
        return _claimOrder(address(weth), token, previousBreakHash, breaksHistory, timeout);
    }

    function getAmountOut(uint amountIn, uint balanceIn, uint balanceOut, uint notFee) private pure returns (uint amountOut) {
        require(balanceOut > 0, 'LIQIFI: INSUFFICIENT_LIQUIDITY_OUT');
        require(balanceIn > 0, 'LIQIFI: INSUFFICIENT_LIQUIDITY_IN');
        uint amountInWithFee = amountIn.mul(notFee);
        uint numerator = amountInWithFee.mul(balanceOut);
        uint denominator = balanceIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountsOut(address pool, bool isTokenAIn, uint amountIn, uint minAmountOut) private returns (uint amountAOut, uint amountBOut, uint fee) {
        (uint availableBalance, uint delayedSwapsIncome, uint packed) = DelayedExchangePool(pool).processDelayedOrders();
        uint availableBalanceA = uint128(availableBalance >> 128);
        uint availableBalanceB = uint128(availableBalance);
        (uint instantSwapFee) = unpackGovernance(packed);

        uint amountOut;
        if (isTokenAIn) {
            amountOut = getAmountOut(amountIn, availableBalanceA, availableBalanceB, 1000);
            if (swapPaysFee(availableBalance, delayedSwapsIncome, 0, amountOut)) {
                amountOut = getAmountOut(amountIn, availableBalanceA, availableBalanceB, 1000 - instantSwapFee);
                fee = instantSwapFee;
            }    
            amountBOut = amountOut;
        } else { 
            amountOut = getAmountOut(amountIn, availableBalanceB, availableBalanceA, 1000);
            if (swapPaysFee(availableBalance, delayedSwapsIncome, amountOut, 0)) {
                amountOut = getAmountOut(amountIn, availableBalanceB, availableBalanceA, 1000 - instantSwapFee);
                fee = instantSwapFee;
            }
            amountAOut = amountOut;
        }
        require(amountOut >= minAmountOut, "LIQIFI: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function swapPaysFee(uint availableBalance, uint delayedSwapsIncome, uint amountAOut, uint amountBOut) private pure returns (bool) {
        uint availableBalanceA = uint128(availableBalance >> 128);
        uint availableBalanceB = uint128(availableBalance);

        uint delayedSwapsIncomeA = uint128(delayedSwapsIncome >> 128);
        uint delayedSwapsIncomeB = uint128(delayedSwapsIncome);
        
        uint exceedingAIncome = availableBalanceB == 0 ? 0 : uint(delayedSwapsIncomeA).subWithClip(uint(delayedSwapsIncomeB) * availableBalanceA / availableBalanceB);
        uint exceedingBIncome = availableBalanceA == 0 ? 0 : uint(delayedSwapsIncomeB).subWithClip(uint(delayedSwapsIncomeA) * availableBalanceB / availableBalanceA);
        
        return amountAOut > exceedingAIncome || amountBOut > exceedingBIncome;
    }

    function unpackGovernance(uint packed) internal pure returns(
        uint8 instantSwapFee
    ) {
        instantSwapFee = uint8(packed >> 88);
    }

    function setupDistributionPool(
        address tokenIn, address tokenOut, uint initialBalance, uint minDistributionPrice, uint8 coverageRatio, uint minDealAmount
    ) external override {
        require(tokenIn != address(0), "LIQUIFI: INVALID TOKEN IN");
        require(tokenOut != address(0), "LIQUIFI: INVALID TOKEN OUT");
		
		smartTransferFrom(address(lqf), address(this), tokensRequiredToCreateDistributionPool, ConvertETH.NONE);
		if(initialBalance > 0)
			smartTransferFrom(tokenIn, address(this), initialBalance, ConvertETH.NONE);

        (address tokenA, address tokenB) = properOrder(tokenIn, tokenOut) ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
		address pool = factory.findPool(tokenA, tokenB);
        require(pool != address(0), "LIQIFI: INVALID DISTRIBUTION POOL");

		DistributionPool memory distributionPool = distributionPools[pool];
        require(distributionPool.owner == address(0), "LIQIFI: DPOOL ALREADY EXISTS");
		
		distributionPool.owner = msg.sender;
		distributionPool.tokenIn = tokenIn;
		distributionPool.tokenOut = tokenOut;
		distributionPool.balance = initialBalance;
		distributionPool.minDistributionPrice = minDistributionPrice;
		distributionPool.coverageRatio = coverageRatio;
		distributionPool.minDealAmount = minDealAmount;
		
		distributionPools[pool] = distributionPool;
    }

    function updateDistributionPool(
        address tokenIn, address tokenOut, uint addedBalance, uint minDistributionPrice, uint8 coverageRatio, uint minDealAmount
    ) external override {
        require(tokenIn != address(0), "LIQUIFI: INVALID TOKEN IN");
        require(tokenOut != address(0), "LIQUIFI: INVALID TOKEN OUT");
		
		if(addedBalance > 0)
			smartTransferFrom(tokenIn, address(this), addedBalance, ConvertETH.NONE);

        (address tokenA, address tokenB) = properOrder(tokenIn, tokenOut) ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
		address pool = factory.findPool(tokenA, tokenB);
        require(pool != address(0), "LIQIFI: INVALID DISTRIBUTION_POOL");

		DistributionPool memory distributionPool = distributionPools[pool];
        require(distributionPool.owner == msg.sender, "LIQIFI: SENDER IS NOT DPOOL OWNER");
        require(distributionPool.tokenIn == tokenIn, "LIQIFI: INVALID TOKEN ORDER IN DPOOL");
		
		distributionPools[pool].balance += addedBalance;
		distributionPools[pool].minDistributionPrice = minDistributionPrice;
		distributionPools[pool].coverageRatio = coverageRatio;
		distributionPools[pool].minDealAmount = minDealAmount;
    }
	
    function removeDistributionPool(
        address tokenIn, address tokenOut
    ) external override {
        require(tokenIn != address(0), "LIQUIFI: INVALID TOKEN IN");
        require(tokenOut != address(0), "LIQUIFI: INVALID TOKEN OUT");

        (address tokenA, address tokenB) = properOrder(tokenIn, tokenOut) ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
		address pool = factory.findPool(tokenA, tokenB);
        require(pool != address(0), "LIQIFI: INVALID_DISTRIBUTION_POOL");

		DistributionPool memory distributionPool = distributionPools[pool];
        require(distributionPool.owner == msg.sender, "LIQIFI: SENDER IS NOT DPOOL OWNER");
        require(distributionPool.tokenIn == tokenIn, "LIQIFI: INVALID TOKEN ORDER IN DPOOL");
		
		smartTransfer(address(lqf), msg.sender, tokensRequiredToCreateDistributionPool);
		if(distributionPool.balance > 0)
			smartTransfer(tokenIn, msg.sender, distributionPool.balance);
		
		delete distributionPools[pool];
    }

    function withdrawFromDistributionPool(
        address tokenIn, address tokenOut, uint amountToWithdraw
    ) external override {
        require(tokenIn != address(0), "LIQUIFI: INVALID TOKEN IN");
        require(tokenOut != address(0), "LIQUIFI: INVALID TOKEN OUT");

        (address tokenA, address tokenB) = properOrder(tokenIn, tokenOut) ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
		address pool = factory.findPool(tokenA, tokenB);
        require(pool != address(0), "LIQIFI: INVALID_DISTRIBUTION_POOL");

		DistributionPool memory distributionPool = distributionPools[pool];
        require(distributionPool.owner == msg.sender, "LIQIFI: SENDER IS NOT DPOOL OWNER");
        require(distributionPool.tokenIn == tokenIn, "LIQIFI: INVALID TOKEN ORDER IN DPOOL");
		
        require(distributionPool.balance >= amountToWithdraw, "LIQUIFI: INSUFFICIENT DPOOL BALANCE");
		smartTransfer(tokenIn, msg.sender, amountToWithdraw);
		
		distributionPools[pool].balance -= amountToWithdraw;
    }

    function _counterSwap(
        address pool, address tokenIn, uint amountOut, uint minAmountIn, uint timeout
    ) private {

		DistributionPool memory distributionPool = distributionPools[pool];

		if(distributionPool.tokenIn == tokenIn && distributionPool.balance > 0 && amountOut >= distributionPool.minDealAmount) {

			uint availableBalanceIn;
			uint availableBalanceOut;
			{
				(uint availableBalance, , ) = DelayedExchangePool(pool).processDelayedOrders();
				uint availableBalanceA = uint128(availableBalance >> 128);
				uint availableBalanceB = uint128(availableBalance);
				(availableBalanceIn, availableBalanceOut) = properOrder(tokenIn, distributionPool.tokenOut) ? 
						(availableBalanceA, availableBalanceB) : (availableBalanceB, availableBalanceA);
			}
			
			if (availableBalanceIn != 0 && availableBalanceOut != 0) {
				if(availableBalanceOut.mul(1000000) / availableBalanceIn > distributionPool.minDistributionPrice) {
					uint amountIn = distributionPool.balance.min(amountOut.mul(availableBalanceIn) / 
						availableBalanceOut).mul(distributionPool.coverageRatio) >> 8;
						
					uint distributionPrice = (amountIn.mul(997) / 1000).add(availableBalanceIn).mul(1000000) / (amountOut.mul(997) / 1000).add(availableBalanceOut);

					if(minAmountIn < amountOut.mul(991).mul(distributionPrice) / 1000000000) {
						uint minAmountOut = amountIn.mul(distributionPool.minDistributionPrice) / 1000000;
						address to = distributionPool.owner;
						_delayedSwapInternal(tokenIn, amountIn, distributionPool.tokenOut, minAmountOut, to, timeout, 0, 0);
						distributionPools[pool].balance -= amountIn;
					}
				}
			}
		}
    }

    function _delayedSwapInternal(
        address tokenIn, uint amountIn, address tokenOut, uint minAmountOut, address to, uint time, 
        uint prevByStopLoss, uint prevByTimeout
    ) private beforeTimeout(time) returns (uint orderId) {
        time -= block.timestamp; // reuse variable to reduce stack size

        address pool = factory.findPool(tokenIn, tokenOut);
        require(pool != address(0), "LIQIFI: DELAYED_SWAP_ON_INVALID_POOL");
        smartTransfer(tokenIn, pool, amountIn);

        uint orderFlags = 0;
        if (properOrder(tokenIn, tokenOut)) {
            orderFlags |= 1; // IS_TOKEN_A
        }
        orderId = DelayedExchangePool(pool).addOrder(to, orderFlags, prevByStopLoss, prevByTimeout, minAmountOut, time);
        // TODO: add optional checking if prevByStopLoss/prevByTimeout matched provided values
        DelayedSwap(tokenIn, amountIn, tokenOut, minAmountOut, to, ConvertETH.NONE, uint16(time), uint64(orderId));
    }
}