/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity = 0.7.6;


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

interface Minter is ERC20 {
    event Mint(address indexed to, uint256 value, uint indexed period, uint userEthLocked, uint totalEthLocked);

    function governanceRouter() external view returns (GovernanceRouter);
    function mint(address to, uint period, uint128 userEthLocked, uint totalEthLocked) external returns (uint amount);
    function userTokensToClaim(address user) external view returns (uint amount);
    function periodTokens(uint period) external pure returns (uint128);
    function periodDecayK() external pure returns (uint decayK);
    function initialPeriodTokens() external pure returns (uint128);
}

interface PoolFactory {
    event PoolCreatedEvent(address tokenA, address tokenB, bool aIsWETH, address indexed pool);

    function getPool(address tokenA, address tokenB) external returns (address);
    function findPool(address tokenA, address tokenB) external view returns (address);
    function pools(uint poolIndex) external view returns (address pool);
    function getPoolCount() external view returns (uint);
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

abstract contract LiquifiToken is ERC20 {

    function transfer(address to, uint256 value) public override returns (bool success) {
        if (accountBalances[msg.sender] >= value && value > 0) {
            accountBalances[msg.sender] -= value;
            accountBalances[to] += value;
            emit Transfer(msg.sender, to, value);
            return true;
        }
        return false;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool success) {
        if (accountBalances[from] >= value && allowed[from][msg.sender] >= value && value > 0) {
            accountBalances[to] += value;
            accountBalances[from] -= value;
            allowed[from][msg.sender] -= value;
            emit Transfer(from, to, value);
            return true;
        }
        return false;
    }

    function balanceOf(address owner) public override view returns (uint256 balance) {
        return accountBalances[owner];
    }

    function approve(address spender, uint256 value) external override returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint256 remaining) {
      return allowed[owner][spender];
    }

    mapping (address => uint256) internal accountBalances;
    mapping (address => mapping (address => uint256)) internal allowed;
}

interface LiquifiCallee {
    // availableBalance contains 128 bits of availableBalanceA and 128 bits of availableBalanceB
    // delayedSwapsIncome contains 128 bits of delayedSwapsIncomeA and 128 bits of delayedSwapsIncomeB
    function onLiquifiSwap(bytes calldata data, address sender, uint availableBalance, uint delayedSwapsIncome, uint instantNotFee) external;
}

abstract contract LiquifiLiquidityPool is LiquidityPool, LiquifiToken {
    using Math for uint256;
    
    uint8 public override constant decimals = 18;
    uint public override constant minimumLiquidity = 10**3;
    string public override constant name = 'Liquifi Pool Token';
    
    ERC20 public override immutable tokenA;
    ERC20 public override immutable tokenB;
    bool public override immutable aIsWETH;
    GovernanceRouter public override immutable governanceRouter;

    Liquifi.PoolBalances internal savedBalances;
    receive() external payable {
        assert(msg.sender == address(tokenA) && aIsWETH);
    }

    constructor(address tokenAAddress, address tokenBAddress, bool _aIsWETH, address _governanceRouter) internal {
        Liquifi._require(tokenAAddress != tokenBAddress && 
            tokenAAddress != address(0) &&
            tokenBAddress != address(0), Liquifi.Error.T_INVALID_TOKENS_PAIR, Liquifi.ErrorArg.A_NONE);
   
        tokenA = ERC20(tokenAAddress);
        tokenB = ERC20(tokenBAddress);
        aIsWETH = _aIsWETH;
        governanceRouter = GovernanceRouter(_governanceRouter);
    }

    function poolBalances() external override view returns (
        uint balanceALocked,
        uint poolFlowSpeedA, // flow speed: (amountAIn * 2^32)/second

        uint balanceBLocked,
        uint poolFlowSpeedB, // flow speed: (amountBIn * 2^32)/second

        uint totalBalanceA,
        uint totalBalanceB,

        uint delayedSwapsIncome,
        uint rootKLastTotalSupply
    ) {
        balanceALocked = savedBalances.balanceALocked;
        poolFlowSpeedA = savedBalances.poolFlowSpeedA;

        balanceBLocked = savedBalances.balanceBLocked;
        poolFlowSpeedB = savedBalances.poolFlowSpeedB;

        totalBalanceA = savedBalances.totalBalanceA;
        totalBalanceB = savedBalances.totalBalanceB;

        delayedSwapsIncome = savedBalances.delayedSwapsIncome;
        rootKLastTotalSupply = savedBalances.rootKLastTotalSupply;
    }

    function actualizeBalances(Liquifi.ErrorArg location) internal virtual returns (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint availableBalanceA, uint availableBalanceB);
    function changedBalances(BreakReason reason, Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint orderId) internal virtual;

    function smartTransfer(address token, address to, uint value, Liquifi.ErrorArg tokenType) internal {
        bool success;
        if (tokenType == Liquifi.ErrorArg.Q_TOKEN_ETH) {
            WETH(token).withdraw(value);
            (success,) = to.call{value:value}(new bytes(0)); // TransferETH
        } else {
            bytes memory data;
            (success, data) = token.call(abi.encodeWithSelector(
                0xa9059cbb // bytes4(keccak256(bytes('transfer(address,uint256)')));
                , to, value));
            success = success && (data.length == 0 || abi.decode(data, (bool)));
        }

        Liquifi._require(success, Liquifi.Error.U_TOKEN_TRANSFER_FAILED, tokenType);
    }

    function mintProtocolFee(
        uint availableBalanceA, uint availableBalanceB, Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state
    ) private returns (uint _totalSupply, uint protocolFee) {
        uint rootKLastTotalSupply = _balances.rootKLastTotalSupply;
        _totalSupply = uint128(rootKLastTotalSupply);
        uint _rootKLast = uint128(rootKLastTotalSupply >> 128);
        Liquifi.setFlag(_state, Liquifi.Flag.TOTAL_SUPPLY_DIRTY);
        (,,protocolFee,,) = Liquifi.unpackGovernance(_state);

        if (protocolFee != 0) {
            if (_rootKLast != 0) {
                uint rootK = Math.sqrt(uint(availableBalanceA).mul(availableBalanceB));
                if (rootK > _rootKLast) {
                    uint numerator = _totalSupply.mul(rootK.subWithClip(_rootKLast));
                    uint denominator = (rootK.mul(1000 - protocolFee) / protocolFee).add(_rootKLast);
                    uint liquidity = numerator / denominator;

                    if (liquidity > 0) {
                        address protocolFeeReceiver = governanceRouter.protocolFeeReceiver();
                        _totalSupply = _mint(protocolFeeReceiver, liquidity, _totalSupply, MintReason.PROTOCOL_FEE);
                    }
                }
            }
        }
    }

    function _mint(address to, uint liquidity, uint _totalSupply, MintReason reason) private returns (uint) {
        emit Mint(to, liquidity, reason);
        accountBalances[to] += liquidity;
        return _totalSupply.add(liquidity);
    }

    function updateTotalSupply(Liquifi.PoolBalances memory _balances, uint totalSupply, uint protocolFee) private pure {
        uint availableBalanceA = Math.subWithClip(_balances.totalBalanceA, _balances.balanceALocked);
        uint availableBalanceB = Math.subWithClip(_balances.totalBalanceB, _balances.balanceBLocked);
        uint K = availableBalanceA.mul(availableBalanceB);

        _balances.rootKLastTotalSupply = (
            (protocolFee == 0 ? 0 : uint(uint128(Math.sqrt(K))) << 128) |
            Liquifi.trimTotal(totalSupply, Liquifi.ErrorArg.X_TOTAL_SUPPLY)
        );
    }

    function mint(address to) external override returns (uint liquidity) {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint availableBalanceA, uint availableBalanceB) = actualizeBalances(Liquifi.ErrorArg.K_IN_MINT);
        {
            Liquifi.ErrorArg invalidState = Liquifi.checkInvalidState(_state);
            Liquifi._require(
                invalidState <= Liquifi.ErrorArg.T_FEE_CHANGED_WITH_ORDERS_OPEN
            , Liquifi.Error.J_INVALID_POOL_STATE, invalidState);
        }

        (uint _totalSupply, uint protocolFee) = mintProtocolFee(availableBalanceA, availableBalanceB, _balances, _state);

        uint amountA = tokenA.balanceOf(address(this)).subWithClip(_balances.totalBalanceA);
        uint amountB = tokenB.balanceOf(address(this)).subWithClip(_balances.totalBalanceB);

        liquidity = (_totalSupply == 0) 
            ? Math.sqrt(amountA.mul(amountB)).subWithClip(minimumLiquidity) 
            : Math.min((amountA.mul(_totalSupply)) / availableBalanceA, (amountB.mul(_totalSupply)) / availableBalanceB);

        Liquifi._require(liquidity != 0, Liquifi.Error.L_INSUFFICIENT_LIQUIDITY, Liquifi.ErrorArg.C_OUT_AMOUNT);
        if (_totalSupply == 0) {
            _totalSupply = _mint(address(0), minimumLiquidity, _totalSupply, MintReason.INITIAL_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        }
        
        _totalSupply = _mint(to, liquidity, _totalSupply, MintReason.DEPOSIT);

        _balances.totalBalanceA = Liquifi.trimTotal(amountA.add(_balances.totalBalanceA), Liquifi.ErrorArg.B_IN_AMOUNT);
        _balances.totalBalanceB = Liquifi.trimTotal(amountB.add(_balances.totalBalanceB), Liquifi.ErrorArg.B_IN_AMOUNT);
        Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);

        updateTotalSupply(_balances, _totalSupply, protocolFee);
        changedBalances(BreakReason.MINT, _balances, _state, 0);
    }

    function burn(address to, bool extractETH) external override returns (uint amountA, uint amountB) {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint availableBalanceA, uint availableBalanceB) 
            = actualizeBalances(Liquifi.ErrorArg.L_IN_BURN);
        uint liquidity = Liquifi.trimAmount(balanceOf(address(this)), Liquifi.ErrorArg.B_IN_AMOUNT);

        (uint _totalSupply, uint protocolFee) = mintProtocolFee(availableBalanceA, availableBalanceB, _balances, _state);

        Liquifi._require(_totalSupply != 0, Liquifi.Error.L_INSUFFICIENT_LIQUIDITY, Liquifi.ErrorArg.L_IN_BURN);
    
        amountA = liquidity.mul(availableBalanceA) / _totalSupply;
        amountB = liquidity.mul(availableBalanceB) / _totalSupply;

        Liquifi._require(amountA * amountB != 0, Liquifi.Error.L_INSUFFICIENT_LIQUIDITY, Liquifi.ErrorArg.B_IN_AMOUNT);

        ERC20 _tokenA = tokenA; // gas savings
        ERC20 _tokenB = tokenB; // gas savings

        accountBalances[address(this)] = 0;
        _totalSupply = _totalSupply.subWithClip(liquidity);

        smartTransfer(address(_tokenA), to, amountA, (extractETH && aIsWETH) ? Liquifi.ErrorArg.Q_TOKEN_ETH : Liquifi.ErrorArg.O_TOKEN_A);
        smartTransfer(address(_tokenB), to, amountB, Liquifi.ErrorArg.P_TOKEN_B);

        _balances.totalBalanceA = Liquifi.trimTotal(_tokenA.balanceOf(address(this)), Liquifi.ErrorArg.O_TOKEN_A);
        _balances.totalBalanceB = Liquifi.trimTotal(_tokenB.balanceOf(address(this)), Liquifi.ErrorArg.P_TOKEN_B);
        Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);

        updateTotalSupply(_balances, _totalSupply, protocolFee);
        changedBalances(BreakReason.BURN, _balances, _state, 0);
    }

    function splitDelayedSwapsIncome(uint delayedSwapsIncome) internal pure returns (uint delayedSwapsIncomeA, uint delayedSwapsIncomeB){
        delayedSwapsIncomeA = uint128(delayedSwapsIncome >> 128);
        delayedSwapsIncomeB = uint128(delayedSwapsIncome);
    }

    function subDelayedSwapsIncome(Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint subA, uint subB) internal pure {
        if (_balances.delayedSwapsIncome != 0) {
            (uint delayedSwapsIncomeA, uint delayedSwapsIncomeB) = splitDelayedSwapsIncome(_balances.delayedSwapsIncome);
            _balances.delayedSwapsIncome = 
                    Math.subWithClip(delayedSwapsIncomeA, subA) << 128 |
                    Math.subWithClip(delayedSwapsIncomeB, subB);
            Liquifi.setFlag(_state, Liquifi.Flag.SWAPS_INCOME_DIRTY);
        }
    }

    function swap(
        address to, bool extractETH, uint amountAOut, uint amountBOut, bytes calldata externalData
    ) external override returns (uint amountAIn, uint amountBIn) {
        uint availableBalanceA;
        uint availableBalanceB;
        Liquifi.PoolBalances memory _balances; 
        Liquifi.PoolState memory _state;
        (_balances, _state, availableBalanceA, availableBalanceB) = actualizeBalances(Liquifi.ErrorArg.F_IN_SWAP);
        {
            Liquifi.ErrorArg invalidState = Liquifi.checkInvalidState(_state);
            Liquifi._require(
                invalidState <= Liquifi.ErrorArg.T_FEE_CHANGED_WITH_ORDERS_OPEN
            , Liquifi.Error.J_INVALID_POOL_STATE, invalidState);
        }
        uint instantNotFee = 1000;
        {
            // set fee to zero if new order doesn't exceed current limits
            (uint delayedSwapsIncomeA, uint delayedSwapsIncomeB) = splitDelayedSwapsIncome(_balances.delayedSwapsIncome);
            uint exceedingAIncome = availableBalanceB == 0 ? 0 : delayedSwapsIncomeA.subWithClip(delayedSwapsIncomeB * availableBalanceA / availableBalanceB);
            uint exceedingBIncome = availableBalanceA == 0 ? 0 : delayedSwapsIncomeB.subWithClip(delayedSwapsIncomeA * availableBalanceB / availableBalanceA);
            
            if (amountAOut > exceedingAIncome || amountBOut > exceedingBIncome) {
                (uint instantFee,,,,) = Liquifi.unpackGovernance(_state);
                instantNotFee -= instantFee;
            }
        }
        
        Liquifi._require(amountAOut | amountBOut != 0, Liquifi.Error.F_ZERO_AMOUNT_VALUE, Liquifi.ErrorArg.C_OUT_AMOUNT);
        Liquifi._require(amountAOut < availableBalanceA && amountBOut < availableBalanceB, Liquifi.Error.E_TOO_BIG_AMOUNT_VALUE, Liquifi.ErrorArg.C_OUT_AMOUNT);
        
        { // localize variables to reduce stack depth
            // optimistically transfer tokens
            if (amountAOut > 0) {
                smartTransfer(address(tokenA), to, amountAOut, (extractETH && aIsWETH) ? Liquifi.ErrorArg.Q_TOKEN_ETH : Liquifi.ErrorArg.O_TOKEN_A);
                _balances.totalBalanceA = uint128(Math.subWithClip(_balances.totalBalanceA, amountAOut));
            }
            if (amountBOut > 0) {
                smartTransfer(address(tokenB), to, amountBOut, Liquifi.ErrorArg.P_TOKEN_B);
                _balances.totalBalanceB = uint128(Math.subWithClip(_balances.totalBalanceB, amountBOut));
            }

            if (externalData.length > 0) {
                uint availableBalance = (availableBalanceA << 128) | availableBalanceB;
                // flash swap, also allows to execute swap without pror call of processDelayedOrders
                LiquifiCallee(to).onLiquifiSwap(externalData, msg.sender, availableBalance, _balances.delayedSwapsIncome, instantNotFee);
            }
            
            {
                // compute amountIn and update totalBalance
                uint newTotalBalance;
                newTotalBalance = tokenA.balanceOf(address(this));
                amountAIn = Liquifi.trimAmount(newTotalBalance.subWithClip(_balances.totalBalanceA), Liquifi.ErrorArg.B_IN_AMOUNT);
                _balances.totalBalanceA = Liquifi.trimTotal(newTotalBalance, Liquifi.ErrorArg.O_TOKEN_A);

                newTotalBalance = tokenB.balanceOf(address(this));
                amountBIn = Liquifi.trimAmount(newTotalBalance.subWithClip(_balances.totalBalanceB), Liquifi.ErrorArg.B_IN_AMOUNT);
                _balances.totalBalanceB = Liquifi.trimTotal(newTotalBalance, Liquifi.ErrorArg.P_TOKEN_B);

                Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);
            }
        }

        subDelayedSwapsIncome(_balances, _state, amountAOut, amountBOut);

        Liquifi._require(amountAIn | amountBIn != 0, Liquifi.Error.F_ZERO_AMOUNT_VALUE, Liquifi.ErrorArg.B_IN_AMOUNT);
        
        { // check invariant
            uint newBalanceA = availableBalanceA.subWithClip(amountAOut).mul(1000);
            newBalanceA = newBalanceA.add(amountAIn * instantNotFee);
            uint newBalanceB = availableBalanceB.subWithClip(amountBOut).mul(1000);
            newBalanceB = newBalanceB.add(amountBIn * instantNotFee);
            
            Liquifi._require(
                newBalanceA.mul(newBalanceB) >= availableBalanceA.mul(availableBalanceB).mul(1000**2), 
                Liquifi.Error.J_INVALID_POOL_STATE, Liquifi.ErrorArg.F_IN_SWAP);
        }

        changedBalances(BreakReason.SWAP, _balances, _state, 0);
    }
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

contract LiquifiDelayedExchangePool is LiquifiLiquidityPool, DelayedExchangePool {
    using Math for uint256;
    ActivityMeter private immutable activityMeter;

    mapping(uint => Liquifi.Order) private orders;
    Liquifi.PoolState private savedState;
    // BreakHash value computed last before current block
    // This field is useful for price oracles: it allows to calculate average price for arbitrary period in past
    // using FlowBreakEvent list provided by offchain code 
    //
    // Also this field includes processing flag in the least valuable bit
    // So, only highest 255 bits should be used for hash validation
    // This word is always saved in enter()
    bytes32 private prevBlockBreakHash;
    uint private immutable poolIndex;

    constructor(address tokenAAddress, address tokenBAddress, bool _aIsWETH, address _governanceRouter, uint _index) 
        LiquifiLiquidityPool(tokenAAddress, tokenBAddress, _aIsWETH, _governanceRouter) public {
        savedState.nextBreakTime = Liquifi.maxTime;
        poolIndex = _index;
        activityMeter = GovernanceRouter(_governanceRouter).activityMeter();
    }

    // use LPTXXXXXX symbols where XXXXXX is index in the pool factory
    // it takes much less bytecode than concatenation of tokens symbols
    function symbol() external view override returns (string memory _symbol) {
        bytes memory symbolBytes = "\x4c\x50\x54\x30\x30\x30\x30\x30\x30"; // LPT
        uint _index = poolIndex;
        uint pos = 8;
        while (pos > 2) {
            symbolBytes[pos--] = bytes1(uint8(48 + _index % 10));
            _index = _index / 10;
        }
        
        _symbol = string(symbolBytes);
    }

    function poolTime(Liquifi.PoolState memory _state) private view returns (uint) {
        return Liquifi.checkFlag(_state, Liquifi.Flag.POOL_LOCKED) ? _state.lastBalanceUpdateTime : Liquifi.trimTime(block.timestamp);
    }

    function poolQueue() external override view returns (
        uint firstByTokenAStopLoss, uint lastByTokenAStopLoss, // linked list of orders sorted by (amountAIn/stopLossAmount) ascending
        uint firstByTokenBStopLoss, uint lastByTokenBStopLoss, // linked list of orders sorted by (amountBIn/stopLossAmount) ascending
    
        uint firstByTimeout, uint lastByTimeout // linked list of orders sorted by timeouts ascending
    ) {
        firstByTokenAStopLoss = savedState.firstByTokenAStopLoss;
        lastByTokenAStopLoss = savedState.lastByTokenAStopLoss;
        firstByTokenBStopLoss = savedState.firstByTokenBStopLoss;
        lastByTokenBStopLoss = savedState.lastByTokenBStopLoss;
        
        firstByTimeout = savedState.firstByTimeout;
        lastByTimeout = savedState.lastByTimeout;
    }

    function lastBreakHash() external override view returns (bytes32) {
        return savedState.lastBreakHash;
    }

    function poolState() external override view returns (
        bytes32 _prevBlockBreakHash,
        uint packed, // see Liquifi.PoolState for details
        uint notFee,

        uint lastBalanceUpdateTime,
        uint nextBreakTime,
        uint maxHistory,
        uint ordersToClaimCount,
        uint breaksCount
    ) {
        _prevBlockBreakHash = prevBlockBreakHash;

        packed = savedState.packed;
        notFee = savedState.notFee;

        lastBalanceUpdateTime = savedState.lastBalanceUpdateTime;
        nextBreakTime = savedState.nextBreakTime;
        maxHistory = savedState.maxHistory;
        ordersToClaimCount = savedState.ordersToClaimCount;
        breaksCount = savedState.breaksCount;
    }

    function findOrder(uint orderId) external override view returns (        
        uint nextByTimeout, uint prevByTimeout,
        uint nextByStopLoss, uint prevByStopLoss,
        
        uint stopLossAmount,
        uint amountIn,
        uint period,
        
        address owner,
        uint timeout,
        uint flags
    ) {
        Liquifi.Order storage order = orders[uint64(orderId)];
        nextByTimeout = order.nextByTimeout;
        prevByTimeout = order.prevByTimeout;
        nextByStopLoss = order.nextByStopLoss;
        prevByStopLoss = order.prevByStopLoss;

        stopLossAmount = order.stopLossAmount;
        amountIn = order.amountIn;
        period = order.period;

        owner = order.owner;
        timeout = order.timeout;
        flags = order.flags;
    }

    function totalSupply() external override view returns (uint) {
        return uint128(savedBalances.rootKLastTotalSupply);
    }

    function applyGovernance(uint packedGovernanceFields) external override {
        (address governor, ) = governanceRouter.governance();
        Liquifi._require(msg.sender == governor, Liquifi.Error.Y_UNAUTHORIZED_SENDER, Liquifi.ErrorArg.S_BY_GOVERNANCE);
        savedState.packed = uint96(packedGovernanceFields);
        emit GovernanceApplied(packedGovernanceFields);
    }

    function addOrder(
        address owner, uint orderFlags, uint prevByStopLoss, uint prevByTimeout, 
        uint stopLossAmount, uint period
    ) external override returns (uint id) {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, ,) = actualizeBalances(Liquifi.ErrorArg.E_IN_ADD_ORDER);
        {
            Liquifi.ErrorArg invalidState = Liquifi.checkInvalidState(_state);
            Liquifi._require(invalidState == Liquifi.ErrorArg.A_NONE, Liquifi.Error.J_INVALID_POOL_STATE, invalidState);
        }

        Liquifi._require(period > 0, Liquifi.Error.G_ZERO_PERIOD_VALUE, Liquifi.ErrorArg.E_IN_ADD_ORDER);
        Liquifi._require(stopLossAmount > 0, Liquifi.Error.F_ZERO_AMOUNT_VALUE, Liquifi.ErrorArg.D_STOP_LOSS_AMOUNT);
 
        uint amountIn;
        bool isTokenAIn = Liquifi.isTokenAIn(orderFlags);
        {  // localize variables to reduce stack depth
            Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);
            uint _totalBalance = isTokenAIn ? _balances.totalBalanceA : _balances.totalBalanceB;
            _balances.totalBalanceA = Liquifi.trimTotal(tokenA.balanceOf(address(this)), Liquifi.ErrorArg.O_TOKEN_A);
            _balances.totalBalanceB = Liquifi.trimTotal(tokenB.balanceOf(address(this)), Liquifi.ErrorArg.P_TOKEN_B);
            uint newTotalBalance = isTokenAIn ? _balances.totalBalanceA : _balances.totalBalanceB;

            Liquifi._require(newTotalBalance > _totalBalance, Liquifi.Error.F_ZERO_AMOUNT_VALUE, Liquifi.ErrorArg.B_IN_AMOUNT);

            amountIn = Liquifi.trimAmount(newTotalBalance.subWithClip(_totalBalance), Liquifi.ErrorArg.B_IN_AMOUNT);
            Liquifi._require(amountIn > 0, Liquifi.Error.F_ZERO_AMOUNT_VALUE, Liquifi.ErrorArg.B_IN_AMOUNT);
            
            if (isTokenAIn) {
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY);
                _balances.balanceALocked = Liquifi.trimAmount(amountIn + _balances.balanceALocked, Liquifi.ErrorArg.O_TOKEN_A);
                _balances.poolFlowSpeedA = Liquifi.trimFlowSpeed(_balances.poolFlowSpeedA + (amountIn << 32) / period, Liquifi.ErrorArg.O_TOKEN_A); // multiply to 2^32 to keep precision
            } else {
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY);
                _balances.balanceBLocked = Liquifi.trimAmount(amountIn + _balances.balanceBLocked, Liquifi.ErrorArg.P_TOKEN_B);
                _balances.poolFlowSpeedB = Liquifi.trimFlowSpeed(_balances.poolFlowSpeedB + (amountIn << 32) / period, Liquifi.ErrorArg.P_TOKEN_B); // multiply to 2^32 to keep precision
            } 
        }

        (,,,uint maxPeriod,) = Liquifi.unpackGovernance(_state);
        Liquifi._require(period <= maxPeriod, Liquifi.Error.D_TOO_BIG_PERIOD_VALUE, Liquifi.ErrorArg.E_IN_ADD_ORDER);
        Liquifi.trimAmount(stopLossAmount, Liquifi.ErrorArg.D_STOP_LOSS_AMOUNT); // check limits before usage

        id = saveOrder(
            _state,
            period, 
            prevByTimeout, prevByStopLoss, // overflow only leads to position re-computing
            amountIn, 
            stopLossAmount, 
            isTokenAIn);

        {
            Liquifi.Order storage order = orders[id];
            (order.stopLossAmount, order.amountIn, order.period) = (uint112(stopLossAmount), uint112(amountIn), uint32(period)); //already trimmed  

            uint64 timeout = Liquifi.trimTime(poolTime(_state) + period);
            (order.owner, order.timeout, order.flags) = (owner, timeout, uint8(orderFlags));
        }
                                     
        changedBalances(BreakReason.ORDER_ADDED, _balances, _state, id);
    }

    function processDelayedOrders() external override
        returns (uint availableBalance, uint delayedSwapsIncome, uint packed) {
        Liquifi.PoolBalances memory _balances; 
        Liquifi.PoolState memory _state;
        uint availableBalanceA;
        uint availableBalanceB;
        (_balances, _state, availableBalanceA, availableBalanceB) = actualizeBalances(Liquifi.ErrorArg.N_IN_PROCESS_DELAYED_ORDERS);
        availableBalance = (availableBalanceA << 128) | availableBalanceB;
        delayedSwapsIncome = _balances.delayedSwapsIncome;
        packed = _state.packed;
        exit(_balances, _state);
    }
    
    function claimOrder (
        bytes32 previousBreakHash,
        // availableBalance (0), flowSpeed (1), others (2)
        // uint256 others = 
        //             (uint(_balances.poolFlowSpeedB) << 224) |
        //             (uint(_state.notFee) << 208) | 
        //             (uint(time) << 144) | 
        //             (uint(orderId) << 80) | 
        //             (uint(_state.packed >> 20) << 4) |
        //             uint(reason);
        // uint availableBalance = (availableBalanceA << 128) | availableBalanceB;
        // uint flowSpeed = (uint(_balances.poolFlowSpeedA) << 112) | (_balances.poolFlowSpeedB >> 32);
        // see LiquifiPoolRegister.claimOrder for breaks list details
        uint[] calldata breaksHistory
    ) external override returns (address owner, uint amountAOut, uint amountBOut) {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state) = enter(Liquifi.ErrorArg.M_IN_CLAIM_ORDER);

        uint lastIndex = breaksHistory.length;
        Liquifi._require(lastIndex != 0, Liquifi.Error.M_EMPTY_LIST, Liquifi.ErrorArg.H_IN_BREAKS_HISTORY);
        Liquifi._require(lastIndex % 3 == 0, Liquifi.Error.N_BAD_LENGTH, Liquifi.ErrorArg.H_IN_BREAKS_HISTORY);
        
        lastIndex = (lastIndex / 3) - 1;
        
        Liquifi.OrderClaim memory claim;
        claim.orderId = getBreakOrderId(breaksHistory, 0);
        bool partialHistory = getBreakOrderId(breaksHistory, lastIndex) != claim.orderId
            || (uint8(getBreakReason(breaksHistory, lastIndex)) & uint8(BreakReason.ORDER_CLOSED) == 0); // check for any close reason
        
        // try to fail earlier if some more breaks happened after history collecting
        Liquifi._require(!partialHistory || getBreakTime(breaksHistory, lastIndex) == _state.nextBreakTime,
            Liquifi.Error.R_INCOMPLETE_HISTORY,  Liquifi.ErrorArg.H_IN_BREAKS_HISTORY);
        
        Liquifi._require(getBreakReason(breaksHistory, 0) == BreakReason.ORDER_ADDED, 
            Liquifi.Error.Q_ORDER_NOT_ADDED, Liquifi.ErrorArg.H_IN_BREAKS_HISTORY);

        // All orders are closed before fee change applying, so it is safe to use old fee for partial history
        // notFee is not saved on exit(), so it is safe to change it for current request only
        _state.notFee = uint16(getBreakFee(breaksHistory, 0));
        
        uint amountIn;
        {
            uint orderPeriod;
            Liquifi.Order storage order = orders[claim.orderId];
    
            (amountIn, orderPeriod) = (order.amountIn, order.period); // grouped read
            (owner, claim.flags) = (order.owner, order.flags); // grouped read

            Liquifi._require(orderPeriod > 0, // check a required property
                Liquifi.Error.V_ORDER_NOT_EXIST, Liquifi.ErrorArg.M_IN_CLAIM_ORDER);

            claim.orderFlowSpeed = (amountIn << 32) / orderPeriod; //= Sai' or = Sbi'            
            claim.previousOthers = breaksHistory[2];
        }
        
        {
            uint index = 0;

            while(index <= lastIndex) {
                previousBreakHash = computeBreakHash(previousBreakHash, breaksHistory, index);
                appendSegmentToClaim(
                    breaksHistory[index * 3],
                    breaksHistory[index * 3 + 1],
                    breaksHistory[index * 3 + 2],
                    _state.notFee,
                    claim
                );
                index++;
            }
        }

        {
            bytes32 lashHash;
            if (partialHistory) {
                lashHash = _state.lastBreakHash;
                processBreaks(_balances, _state, claim);
                Liquifi._require(claim.closeReason != 0, Liquifi.Error.P_ORDER_NOT_CLOSED, Liquifi.ErrorArg.M_IN_CLAIM_ORDER);
            } else {
                claim.closeReason = uint(getBreakReason(breaksHistory, lastIndex));
                Liquifi.Order storage order = orders[claim.orderId];
                lashHash = bytes32(
                    uint(order.nextByTimeout) << 192
                    | (uint(order.prevByTimeout) << 128)
                    | (uint(order.nextByStopLoss) << 64)
                    | uint(order.prevByStopLoss)
                );
            }

            // compare all except for the lowest bit
            Liquifi._require(previousBreakHash >> 1 == lashHash >> 1,
                        Liquifi.Error.O_HASH_MISMATCH, Liquifi.ErrorArg.H_IN_BREAKS_HISTORY);
        }
        
        {
            uint totalPeriod = extractBreakTime(claim.previousOthers) - getBreakTime(breaksHistory, 0);
            amountIn = claim.closeReason == uint(BreakReason.ORDER_CLOSED) ? 0 : amountIn.subWithClip((claim.orderFlowSpeed * totalPeriod) >> 32);
            (amountAOut, amountBOut) = Liquifi.isTokenAIn(claim.flags) ? (amountIn, claim.amountOut) : (claim.amountOut, amountIn);
        }
        
        {
            ERC20 token;
            if (amountAOut > 0) {
                token = tokenA;
                smartTransfer(address(token), owner, amountAOut, ((claim.flags & uint(Liquifi.OrderFlag.EXTRACT_ETH) != 0) && aIsWETH) ? Liquifi.ErrorArg.Q_TOKEN_ETH : Liquifi.ErrorArg.O_TOKEN_A);
                _balances.totalBalanceA = Liquifi.trimTotal(token.balanceOf(address(this)), Liquifi.ErrorArg.O_TOKEN_A);
                _balances.balanceALocked = uint112(Math.subWithClip(_balances.balanceALocked, amountAOut));
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY);
            }
            
            if (amountBOut > 0) {
                token = tokenB;
                smartTransfer(address(token), owner, amountBOut, Liquifi.ErrorArg.P_TOKEN_B);
                _balances.totalBalanceB = Liquifi.trimTotal(token.balanceOf(address(this)), Liquifi.ErrorArg.P_TOKEN_B);
                _balances.balanceBLocked = uint112(Math.subWithClip(_balances.balanceBLocked, amountBOut));
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY);
            }

            Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);
        }
        
        delete orders[claim.orderId];
        emit OrderClaimedEvent(claim.orderId, owner);
        _state.ordersToClaimCount -= 1; 
        exit(_balances, _state);
    }

    bytes32 private constant one = bytes32(uint(1));
    
    function enter(Liquifi.ErrorArg location) private returns (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state) {
        _state = savedState;
        _balances = savedBalances;
        
        bytes32 _prevBlockBreakHash = prevBlockBreakHash;
        bool mutexFlag1 = _prevBlockBreakHash & one == one;
        {
            bool mutexFlag2 = _state.breaksCount & 1 != 0;
            Liquifi._require(mutexFlag1 == mutexFlag2, Liquifi.Error.S_REENTRANCE_NOT_SUPPORTED, location);    
        }
        
        if (!Liquifi.checkFlag(_state, Liquifi.Flag.GOVERNANCE_OVERRIDEN)) {
            (, uint96 defaultGovernancePacked) = governanceRouter.governance();
            _state.packed = defaultGovernancePacked;
        }

        _state.packed = ((_state.packed >> 20) << 20); // clear 20 transient bits

        if (Liquifi.checkFlag(_state, Liquifi.Flag.POOL_LOCKED)) {
            Liquifi.setInvalidState(_state, Liquifi.ErrorArg.W_POOL_LOCKED);
        }

        (,uint desiredOrdersFee,,,) = Liquifi.unpackGovernance(_state);
        uint16 notFee = uint16(1000 - desiredOrdersFee);
        if (notFee != _state.notFee) {
            if (_state.firstByTimeout != 0) { 
                // queue is not empty
                // no orders adding allowed
                Liquifi.setInvalidState(_state, Liquifi.ErrorArg.T_FEE_CHANGED_WITH_ORDERS_OPEN);
            } else {
                savedState.notFee = notFee;
                _state.notFee = notFee;
            }
        }

        // save hash if it was calculated in past
        if (_state.lastBalanceUpdateTime < poolTime(_state)) {
            _prevBlockBreakHash = _state.lastBreakHash;
        }
        // negate mutex bit in _prevBlockBreakHash and temporarly save it in Flags.MUTEX
        if (mutexFlag1) {
            Liquifi.clearFlag(_state, Liquifi.Flag.MUTEX);
            _prevBlockBreakHash = _prevBlockBreakHash & ~(one);
        } else {
            Liquifi.setFlag(_state, Liquifi.Flag.MUTEX);
            _prevBlockBreakHash = _prevBlockBreakHash | one;
        }
        
        prevBlockBreakHash = _prevBlockBreakHash;
    }

    function exit(Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state) private {
        if (Liquifi.checkFlag(_state, Liquifi.Flag.HASH_DIRTY)) {
            savedState.lastBreakHash = _state.lastBreakHash;
        }
        
        if (Liquifi.checkFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY)) {
            (savedBalances.balanceALocked, savedBalances.poolFlowSpeedA) = (_balances.balanceALocked, _balances.poolFlowSpeedA);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY)) {
            (savedBalances.balanceBLocked, savedBalances.poolFlowSpeedB) = (_balances.balanceBLocked, _balances.poolFlowSpeedB);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.TOTALS_DIRTY)) {
            (savedBalances.totalBalanceA, savedBalances.totalBalanceB) = (_balances.totalBalanceA, _balances.totalBalanceB);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.SWAPS_INCOME_DIRTY)) {
            (savedBalances.delayedSwapsIncome) = (_balances.delayedSwapsIncome);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.TOTAL_SUPPLY_DIRTY)) {
            (savedBalances.rootKLastTotalSupply) = (_balances.rootKLastTotalSupply);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.QUEUE_STOPLOSS_DIRTY)) {
            (savedState.firstByTokenAStopLoss, savedState.lastByTokenAStopLoss, savedState.firstByTokenBStopLoss, savedState.lastByTokenBStopLoss) = 
                (_state.firstByTokenAStopLoss, _state.lastByTokenAStopLoss, _state.firstByTokenBStopLoss, _state.lastByTokenBStopLoss);
        }

        if (Liquifi.checkFlag(_state, Liquifi.Flag.QUEUE_TIMEOUT_DIRTY)) {
            (savedState.firstByTimeout, savedState.lastByTimeout) = (_state.firstByTimeout, _state.lastByTimeout);
        }

        // set mutex bit in breaksCount to same value as in prevBlockBreakHash
        if (Liquifi.checkFlag(_state, Liquifi.Flag.MUTEX)) {
            _state.breaksCount |= uint64(1);
        } else {
            _state.breaksCount &= ~uint64(1);
        }

        // last word of state is always saved
        (savedState.lastBalanceUpdateTime, savedState.nextBreakTime, savedState.maxHistory, savedState.ordersToClaimCount, savedState.breaksCount) 
            = (_state.lastBalanceUpdateTime, _state.nextBreakTime, _state.maxHistory, _state.ordersToClaimCount, _state.breaksCount);
    }

    function actualizeBalances(Liquifi.ErrorArg location) internal override(LiquifiLiquidityPool) returns (
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint availableBalanceA, uint availableBalanceB
    ) {
        (_balances, _state) = enter(location);
        Liquifi.OrderClaim memory claim;
        processBreaks(_balances, _state, claim);
        (availableBalanceA, availableBalanceB) = updateBalanceLocked(poolTime(_state), _balances, _state);

        Liquifi.ErrorArg invalidState = Liquifi.checkInvalidState(_state);
        if (invalidState != Liquifi.ErrorArg.A_NONE) {
            emit OperatingInInvalidState(uint(location), uint(invalidState));
        }
    }

    function computeBreakHash(bytes32 previousBreakHash, uint[] calldata breaks, uint index) private pure returns (bytes32 breakHash) {
        index = index * 3;
        return keccak256(abi.encodePacked(
            previousBreakHash,
            uint(breaks[index + 0]), uint(breaks[index + 1]), uint(breaks[index + 2])
        ));
    } 

    function extractBreakTime(uint others) private pure returns (uint) { 
        return uint64(others >> 144);
    }
    function getBreakTime(uint[] calldata breaks, uint i) private pure returns (uint) { 
        return extractBreakTime(breaks[i * 3 + 2]);
    }
    function getBreakOrderId(uint[] calldata breaks, uint i) private pure returns (uint) { 
        return uint64(breaks[i * 3 + 2] >> 80); 
    }
    function getBreakReason(uint[] calldata breaks, uint i) private pure returns (BreakReason) { 
        return BreakReason(uint8(breaks[i * 3 + 2]) & 15); 
    }
    function getBreakFee(uint[] calldata breaks, uint i) private pure returns (uint notFee) { 
        return uint16(breaks[i * 3 + 2] >> 208); 
    }

    function computeBreakRate(uint availableBalance, uint poolFlowSpeed, uint period, uint notFee) private pure returns (uint balance) {
        return availableBalance + ((poolFlowSpeed * period) >> 32) * notFee / 1000;
    }

    function appendSegmentToClaim(
        uint availableBalance, uint flowSpeed, uint others, uint notFee, Liquifi.OrderClaim memory claim    
    ) private pure {
        uint poolFlowSpeedA = uint144(claim.previousFlowSpeed >> 112);
        uint poolFlowSpeedB = uint144(((claim.previousFlowSpeed << 144) >> 112) | (claim.previousOthers >> 224));
        uint availableBalanceA = uint128(claim.previousAvailableBalance >> 128);
        uint availableBalanceB = uint128(claim.previousAvailableBalance);
        uint period = extractBreakTime(others) - extractBreakTime(claim.previousOthers);
        claim.previousOthers = others;
        claim.previousAvailableBalance = availableBalance;
        claim.previousFlowSpeed = flowSpeed;

        uint rateNumerator = computeBreakRate(availableBalanceA, poolFlowSpeedA, period, notFee); // = x0 + Sa' * t * gamma
        uint rateDenominator = computeBreakRate(availableBalanceB, poolFlowSpeedB, period, notFee); // = y0 + Sb' * t * gamma
        
        if (rateNumerator != 0 && rateDenominator != 0) {
            uint tmp = (claim.orderFlowSpeed * period) >> 32; //= Sai' * t or = Sbi' * t
            tmp = tmp * notFee / 1000; // = (Sai' * t ) * gamma or = (Sbi' * t) * gamma
            tmp = Liquifi.isTokenAIn(claim.flags)
                ? tmp * rateDenominator / rateNumerator // = (Sai' * t ) * gamma * P
                : tmp * rateNumerator / rateDenominator; // = (Sbi' * t) * gamma * P
            claim.amountOut += tmp;
        }
    }

    function processBreaks(
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, Liquifi.OrderClaim memory claim
    ) private {
        if(_state.nextBreakTime > poolTime(_state)) { // also guarantees that there are some orders
            return;
        }

        Liquifi.Order storage order;
        uint64 _breakTime = _state.nextBreakTime;
        while (_breakTime <= poolTime(_state) && claim.closeReason == 0) {
            {
                (uint availableBalanceA, uint availableBalanceB) = updateBalanceLocked(_breakTime, _balances, _state);
                // below this line [rate] = x0/y0 = availableBalanceA/availableBalanceB because t = [period since last update] = 0.
                order = orders[_state.firstByTimeout];
                if (order.timeout <= _breakTime) {
                    _closeOrder(_state.firstByTimeout, order, BreakReason.ORDER_CLOSED, _breakTime, _balances, _state, claim);
                } else {
                    order = orders[_state.firstByTokenAStopLoss];
                    if (_state.firstByTokenAStopLoss != 0 && availableBalanceB > 0 &&
                        (order.amountIn * _state.notFee / 1000) * availableBalanceB
                            <= availableBalanceA * order.stopLossAmount) {
                        _closeOrder(_state.firstByTokenAStopLoss, order, BreakReason.ORDER_CLOSED_BY_STOP_LOSS, 
                            _breakTime, _balances, _state, claim); 
                    } else {
                        order = orders[_state.firstByTokenBStopLoss];
                        if (_state.firstByTokenBStopLoss != 0 && availableBalanceA > 0 &&
                            (order.amountIn * _state.notFee / 1000) * availableBalanceA
                                <= availableBalanceB * order.stopLossAmount) {
                            _closeOrder(_state.firstByTokenBStopLoss, order, BreakReason.ORDER_CLOSED_BY_STOP_LOSS, 
                                _breakTime, _balances, _state, claim);
                        }
                    }
                }
            }
            //update nextBreakTime
            _breakTime = _state.firstByTimeout == 0 ? Liquifi.maxTime : orders[_state.firstByTimeout].timeout;
            
            if (_state.firstByTokenAStopLoss != 0) {
                order = orders[_state.firstByTokenAStopLoss];
                uint tokenAStopLoss = computeStopLossTimeout((order.amountIn * _state.notFee / 1000), order.stopLossAmount, _balances, _state);
                if (tokenAStopLoss < _breakTime) {
                    _breakTime = uint64(tokenAStopLoss);
                }
            }

            if (_state.firstByTokenBStopLoss != 0) {
                order = orders[_state.firstByTokenBStopLoss];
                uint tokenBStopLoss = computeStopLossTimeout(order.stopLossAmount, (order.amountIn * _state.notFee / 1000), _balances, _state);
                if (tokenBStopLoss < _breakTime) {
                    _breakTime = uint64(tokenBStopLoss);
                }
            }

            _state.nextBreakTime = _breakTime;
        }
    }

    function computeStopLossTimeout(
        uint stopLossRateNumerator, // guaranteed to !=0
        uint stopLossRateDenominator, // guaranteed to !=0
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state
    ) private pure returns (uint timeout) {
        // P = (gamma * Sa' * t + x0) / (gamma * Sb' * t + y0)   =>
        // => t = (x0 - y0 * P) / ((Sb' * P - Sa') * gamma)
        uint availableBalanceA = Math.subWithClip(_balances.totalBalanceA, _balances.balanceALocked);
        uint availableBalanceB = Math.subWithClip(_balances.totalBalanceB, _balances.balanceBLocked);

        int numerator = int(availableBalanceA) - int(availableBalanceB * stopLossRateNumerator / stopLossRateDenominator); // = x0 - y0 * P
        int denominator = (int((uint(_balances.poolFlowSpeedB) * stopLossRateNumerator / stopLossRateDenominator) >> 32 ) - int(_balances.poolFlowSpeedA >> 32)) * _state.notFee / 1000; // (Sb' * P - Sa') * gamma

        int period = denominator != 0 ? numerator / denominator : Liquifi.maxTime;
        return period >= 0 && period + _state.nextBreakTime + 1 <= Liquifi.maxTime 
                    ? uint(period + _state.nextBreakTime + 1) // add one second to tolerate precision losses 
                    : Liquifi.maxTime;
    }

    function computeAvailableBalance(
        uint effectiveTime, 
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state
    ) private pure returns (uint availableBalanceA, uint availableBalanceB) {
        if (_balances.totalBalanceA < _balances.balanceALocked || _balances.totalBalanceB < _balances.balanceBLocked) {
            Liquifi.setInvalidState(_state, Liquifi.ErrorArg.V_INSUFFICIENT_TOTAL_BALANCE);
        }
        uint oldAvailableBalanceA = Math.subWithClip(_balances.totalBalanceA, _balances.balanceALocked); // = x0
        uint oldAvailableBalanceB = Math.subWithClip(_balances.totalBalanceB, _balances.balanceBLocked); // = y0
        Liquifi._require(effectiveTime <= _state.nextBreakTime, Liquifi.Error.H_BALANCE_AFTER_BREAK, Liquifi.ErrorArg.G_IN_COMPUTE_AVAILABLE_BALANCE);
        Liquifi._require(effectiveTime >= _state.lastBalanceUpdateTime, Liquifi.Error.I_BALANCE_OF_SAVED_UPD, Liquifi.ErrorArg.G_IN_COMPUTE_AVAILABLE_BALANCE);
        uint period = effectiveTime - _state.lastBalanceUpdateTime;
        if (period == 0) {
            return (oldAvailableBalanceA, oldAvailableBalanceB);
        }
        
        uint amountInA = _balances.poolFlowSpeedA * period; // = Sa' * t (premultiplied to 2^32)
        uint amountInB = _balances.poolFlowSpeedB * period; // = Sb' * t (premultiplied to 2^32)

        uint amountInAAdjusted = (amountInA * _state.notFee / 1000) >> 32; // = gamma * Sa' * t
        uint amountInBAdjusted = (amountInB * _state.notFee / 1000) >> 32; // = gamma * Sb' * t

        uint balanceIncreasedA = oldAvailableBalanceA.add(amountInAAdjusted); // = x0 + gamma * Sa' * t
        uint balanceIncreasedB = oldAvailableBalanceB.add(amountInBAdjusted); // = y0 + gamma * Sb' * t

        availableBalanceA = balanceIncreasedB == 0 ? oldAvailableBalanceA : Liquifi.trimTotal(
            balanceIncreasedA.subWithClip(amountInBAdjusted.mul(balanceIncreasedA) / balanceIncreasedB),
            Liquifi.ErrorArg.O_TOKEN_A); // = x0 + gamma * Sa' * t - gamma * Sb' * t * P
        availableBalanceB = balanceIncreasedA == 0 ? oldAvailableBalanceB : Liquifi.trimTotal(
            balanceIncreasedB.subWithClip(amountInAAdjusted.mul(balanceIncreasedB) / balanceIncreasedA),
            Liquifi.ErrorArg.P_TOKEN_B
        ); // = y0 + gamma * Sb' * t - gamma * Sa' * t / P
        
        // Constant product check: 
        // (x0 + gamma * Sa' * t - gamma * Sb' * t * P)*(y0 + gamma * Sb' * t - gamma * Sa' * t / P) >= x0 * y0
        if (availableBalanceA.mul(availableBalanceB) < oldAvailableBalanceA.mul(oldAvailableBalanceB)) {
            Liquifi.setInvalidState(_state, Liquifi.ErrorArg.U_BAD_EXCHANGE_RATE);
        }
        
        // And some additional check
        if (_balances.totalBalanceA < availableBalanceA || _balances.totalBalanceB < availableBalanceB) {
            Liquifi.setInvalidState(_state, Liquifi.ErrorArg.V_INSUFFICIENT_TOTAL_BALANCE);
        }
    }

    function changedBalances(BreakReason reason, Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, uint orderId) internal override(LiquifiLiquidityPool) {
        Liquifi.OrderClaim memory claim; 
        flowBroken(
            _balances,
            _state,
            poolTime(_state),
            orderId,
            reason,
            claim
        );
        exit(_balances, _state);
    }
    
    function updateBalanceLocked(
        uint effectiveTime, Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state
    ) private pure returns (uint availableBalanceA, uint availableBalanceB) {
        (availableBalanceA, availableBalanceB) = computeAvailableBalance(effectiveTime, _balances, _state);
        if (effectiveTime == _state.lastBalanceUpdateTime) {
            return (availableBalanceA, availableBalanceB);
        }  

        if (!Liquifi.checkFlag(_state, Liquifi.Flag.ARBITRAGEUR_FULL_FEE)) {
            uint period = effectiveTime - _state.lastBalanceUpdateTime;
            (uint delayedSwapsIncomeA, uint delayedSwapsIncomeB) = splitDelayedSwapsIncome(_balances.delayedSwapsIncome);
            _balances.delayedSwapsIncome = 
                uint(Liquifi.trimTotal(delayedSwapsIncomeA + ((_balances.poolFlowSpeedA * period) >> 32), Liquifi.ErrorArg.O_TOKEN_A)) << 128 |
                uint(Liquifi.trimTotal(delayedSwapsIncomeB + ((_balances.poolFlowSpeedB * period) >> 32), Liquifi.ErrorArg.P_TOKEN_B));
            Liquifi.setFlag(_state, Liquifi.Flag.SWAPS_INCOME_DIRTY);
        }

        _balances.balanceALocked = Liquifi.trimAmount(Math.subWithClip(_balances.totalBalanceA, availableBalanceA), Liquifi.ErrorArg.O_TOKEN_A);
        _balances.balanceBLocked = Liquifi.trimAmount(Math.subWithClip(_balances.totalBalanceB, availableBalanceB), Liquifi.ErrorArg.P_TOKEN_B);

        Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY);
        Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY);
        _state.lastBalanceUpdateTime = uint64(effectiveTime);
    }

    function flowBroken(
        // params ordered to reduce stack depth
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state,
        uint time, uint orderId, BreakReason reason, Liquifi.OrderClaim memory claim
    ) private returns (bytes32 _lastBreakHash) {
        {
            uint availableBalance;
            {               
                (uint availableBalanceA, uint availableBalanceB) = computeAvailableBalance(time, _balances, _state);
                availableBalance = (availableBalanceA << 128) | availableBalanceB;
            }

            {
                uint256 others = 
                    (uint(_balances.poolFlowSpeedB) << 224) |
                    (uint(_state.notFee) << 208) | 
                    (uint(time) << 144) | 
                    (uint(orderId) << 80) | 
                    (uint(_state.packed >> 20) << 4) |
                    uint(reason);
                uint256 _totalBalance = (uint(_balances.totalBalanceA) << 128) | uint(_balances.totalBalanceB);
                uint flowSpeed = (uint(_balances.poolFlowSpeedA) << 112) | (_balances.poolFlowSpeedB >> 32);

                emit FlowBreakEvent(
                    msg.sender, _totalBalance, _balances.rootKLastTotalSupply, orderId,
                    // breakHash is computed over all fields below
                    _state.lastBreakHash,
                    availableBalance, flowSpeed, others   
                );

                Liquifi.setFlag(_state, Liquifi.Flag.HASH_DIRTY);
                _state.lastBreakHash = _lastBreakHash = keccak256(abi.encodePacked(
                        _state.lastBreakHash, availableBalance, flowSpeed, others
                ));

                _state.nextBreakTime = (_balances.poolFlowSpeedA | _balances.poolFlowSpeedB == 0) ? Liquifi.maxTime : uint64(time);
                _state.breaksCount += 2; // not likely to have overflow here, but it is ok
            
                if (claim.orderId != 0 && claim.closeReason == 0) {
                    if (claim.orderId == orderId && (uint(reason) & uint(BreakReason.ORDER_CLOSED) != 0)) {
                        claim.closeReason = uint(reason);
                    }
                    appendSegmentToClaim(
                        availableBalance, 
                        flowSpeed,
                        others, 
                        _state.notFee, 
                        claim);
                }
            }

            if (aIsWETH) {
                activityMeter.liquidityEthPriceChanged(time, uint128(availableBalance >> 128), uint128(_balances.rootKLastTotalSupply));
            }
        }
        // prevent order breaks history growth over maxHistory
        (,,,,uint desiredMaxHistory) = Liquifi.unpackGovernance(_state);
        if (_state.maxHistory < desiredMaxHistory) {
            _state.maxHistory = uint16(desiredMaxHistory);
        }

        while(reason != BreakReason.ORDER_CLOSED_BY_HISTORY_LIMIT) {
            uint closingId = (_state.breaksCount & ~uint64(1)) - (_state.maxHistory * 2); // valid id is always even;
            
            Liquifi.Order storage order = orders[closingId];

            if (orderId != closingId && // we're not changing this order right now
                order.period != 0  // check order existance by required field 'period'
                && order.prevByStopLoss & 1 == 0 // check that order is not closed: closed order has invalid id (odd) in prevByStopLoss
            ) {
                _closeOrder(closingId, order, BreakReason.ORDER_CLOSED_BY_HISTORY_LIMIT, time, _balances, _state, claim);
                 _state.breaksCount -= 2; // don't count breaks produced by closing orders by history
                break;
            } 

            if (desiredMaxHistory == 0 || _state.maxHistory == desiredMaxHistory) {
                break;
            }
            
            _state.maxHistory--; // _state.maxHistory > desiredMaxHistory. Reduce it by one and try to close one more order
            desiredMaxHistory = 0;
        }
    }

    function closeOrder(uint id) external override {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, ,) = actualizeBalances(Liquifi.ErrorArg.R_IN_CLOSE_ORDER);

        Liquifi.Order memory order = orders[id];
        // check order existance by required field 'period'
        Liquifi._require(order.period > 0, Liquifi.Error.V_ORDER_NOT_EXIST, Liquifi.ErrorArg.R_IN_CLOSE_ORDER);
        
        BreakReason reason = BreakReason.ORDER_CLOSED_BY_REQUEST;
        if (msg.sender != order.owner) {
            (address governor, ) = governanceRouter.governance();
            Liquifi._require(msg.sender == governor, Liquifi.Error.Y_UNAUTHORIZED_SENDER, Liquifi.ErrorArg.R_IN_CLOSE_ORDER);
            reason = BreakReason.ORDER_CLOSED_BY_GOVERNOR;
        }

        // check that order is open: closed order has invalid id (odd) in prevByStopLoss
        Liquifi._require(order.prevByStopLoss & 1 == 0, Liquifi.Error.X_ORDER_ALREADY_CLOSED, Liquifi.ErrorArg.R_IN_CLOSE_ORDER);
        Liquifi.OrderClaim memory claim; 
       
        _closeOrder(id, order, reason, poolTime(_state), _balances, _state, claim);

        exit(_balances, _state);
    }

    function _closeOrder(uint id, Liquifi.Order memory order, BreakReason reason, uint effectiveTime, 
        Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state, Liquifi.OrderClaim memory claim
    ) private {
        deleteOrderFromQueue(order, _state);
        {
            uint orderFlowSpeed = (uint(order.amountIn) << 32) / order.period; // multiply to 2^32 to keep precision
            uint effectivePeriod = uint(effectiveTime).subWithClip(order.timeout - order.period);
            uint orderIncome = orderFlowSpeed.mul(effectivePeriod);
            uint orderFee = (orderIncome >> 32).mul(1000 - _state.notFee) / 1000; 

            if (Liquifi.isTokenAIn(order.flags)) {
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY);
                _balances.balanceALocked = uint112(Math.subWithClip(_balances.balanceALocked, orderFee)); 
                _balances.poolFlowSpeedA = uint144(Math.subWithClip(_balances.poolFlowSpeedA, orderFlowSpeed));
                subDelayedSwapsIncome(_balances, _state, orderIncome, 0);
            } else {
                Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY);
                
                _balances.balanceBLocked = uint112(Math.subWithClip(_balances.balanceBLocked, orderFee)); 
                _balances.poolFlowSpeedB = uint144(Math.subWithClip(_balances.poolFlowSpeedB, orderFlowSpeed));
                subDelayedSwapsIncome(_balances, _state, 0, orderIncome);
            }
        }

        bytes32 _lastBreakHash = flowBroken(
            _balances,
            _state,
            effectiveTime,
            id,
            reason,
            claim    
        );

        Liquifi.Order storage storedOrder = orders[id];  
        // save gas by re-using existing fields
        // set highest bit to 1 in nextByTimeout to mark order as closed
        storedOrder.nextByTimeout = uint64(uint(_lastBreakHash) >> 192);
        storedOrder.prevByTimeout = uint64(uint(_lastBreakHash) >> 128);
        storedOrder.nextByStopLoss = uint64(uint(_lastBreakHash) >> 64);
        storedOrder.prevByStopLoss = uint64(uint(_lastBreakHash) | 1);

        _state.ordersToClaimCount += 1; 
    }

    function deleteOrderFromQueue(Liquifi.Order memory order, Liquifi.PoolState memory _state) private {
        bool isTokenA = Liquifi.isTokenAIn(order.flags);
        if (order.prevByTimeout == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_TIMEOUT_DIRTY);
            _state.firstByTimeout = order.nextByTimeout;
        } else {
            orders[order.prevByTimeout].nextByTimeout = order.nextByTimeout;
        }

        if (order.nextByTimeout == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_TIMEOUT_DIRTY);
            _state.lastByTimeout = order.prevByTimeout;
        } else {
            orders[order.nextByTimeout].prevByTimeout = order.prevByTimeout;
        }


        if (order.prevByStopLoss == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_STOPLOSS_DIRTY);
            if (isTokenA) {
                _state.firstByTokenAStopLoss = order.nextByStopLoss;
            } else {
                _state.firstByTokenBStopLoss = order.nextByStopLoss;
            }
        } else {
            orders[order.prevByStopLoss].nextByStopLoss = order.nextByStopLoss;
        }

        if (order.nextByStopLoss == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_STOPLOSS_DIRTY);
            if (isTokenA) {
                _state.lastByTokenAStopLoss = order.prevByStopLoss;
            } else {
                _state.lastByTokenBStopLoss = order.prevByStopLoss;
            }
        } else {
            orders[order.nextByStopLoss].prevByStopLoss = order.prevByStopLoss;
        }
    }

    function saveOrder(Liquifi.PoolState memory _state,
        uint period, uint prevByTimeout, uint prevByStopLoss, 
        uint amountIn, uint stopLossAmount, bool isTokenA
    ) private returns (uint64 id) {
        uint timeout = Liquifi.trimTime(poolTime(_state) + period);
        id = 2 + _state.breaksCount & ~uint64(1); // valid id is always even

        uint nextByTimeout;
        (prevByTimeout, nextByTimeout) = ensureTimeoutSort(_state, timeout, prevByTimeout);
        uint nextByStopLoss;
        (prevByStopLoss, nextByStopLoss) = ensureStopLossSort(_state, stopLossAmount, amountIn, isTokenA, prevByStopLoss);

        Liquifi.Order storage order = orders[id];
        (order.nextByTimeout, order.prevByTimeout, order.nextByStopLoss, order.prevByStopLoss) =
            (uint64(nextByTimeout), uint64(prevByTimeout), uint64(nextByStopLoss), uint64(prevByStopLoss));
        
        if (prevByTimeout == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_TIMEOUT_DIRTY);
            _state.firstByTimeout = id;
        } else {
            orders[prevByTimeout].nextByTimeout = id;
        }

        if (nextByTimeout == 0) {
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_TIMEOUT_DIRTY);
            _state.lastByTimeout = id;
        } else {
            orders[nextByTimeout].prevByTimeout = id;
        }

        if (prevByStopLoss == 0) {   
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_STOPLOSS_DIRTY);
            if (isTokenA) {
                _state.firstByTokenAStopLoss = id;
            } else {
                _state.firstByTokenBStopLoss = id;
            }
        } else {
            orders[prevByStopLoss].nextByStopLoss = id;
        }

        if (nextByStopLoss == 0) {   
            Liquifi.setFlag(_state, Liquifi.Flag.QUEUE_STOPLOSS_DIRTY);
            if (isTokenA) {
                _state.lastByTokenAStopLoss = id;
            } else {
                _state.lastByTokenBStopLoss = id;
            }
        } else {
            orders[nextByStopLoss].prevByStopLoss = id;
        }
    }

    // find position in linked list sorted by timeouts ascending
    function ensureTimeoutSort(Liquifi.PoolState memory _state, uint timeout, uint prevByTimeout) private view returns (uint _prevByTimeout, uint _nextByTimeout) {
        _nextByTimeout = _state.firstByTimeout;
        _prevByTimeout = prevByTimeout;

        if (_prevByTimeout != 0) {
            Liquifi.Order memory prevByTimeoutOrder = orders[_prevByTimeout];
            if (prevByTimeoutOrder.period > 0 // check order existance by required field 'period'
                && prevByTimeoutOrder.prevByStopLoss & 1 == 0 // check that order is not closed: closed order has invalid id (odd) in prevByStopLoss
                ) {
                _nextByTimeout = prevByTimeoutOrder.nextByTimeout;
                uint prevTimeout = prevByTimeoutOrder.timeout;
                
                // iterate towards list start if needed
                while (_prevByTimeout != 0) {
                    if (prevTimeout <= timeout) {
                        break;
                    }

                    _nextByTimeout = _prevByTimeout;
                    _prevByTimeout = orders[_prevByTimeout].prevByTimeout;
                    prevTimeout = orders[_prevByTimeout].timeout;
                }               
            } else {
                // invalid prevByTimeout passed, start search from list head
                _prevByTimeout = 0;
            }            
        }

        // iterate towards list end if needed
        while (_nextByTimeout != 0 && orders[_nextByTimeout].timeout < timeout) {
            _prevByTimeout = _nextByTimeout;
            _nextByTimeout = orders[_nextByTimeout].nextByTimeout;
        }
    }

    // find position in linked list sorted by (amountIn/stopLossAmount) ascending
    function ensureStopLossSort(Liquifi.PoolState memory _state, uint stopLossAmount, uint amountIn, bool isTokenA, uint prevByStopLoss) private view returns (uint _prevByStopLoss, uint _nextByStopLoss) {
        _nextByStopLoss = isTokenA ? _state.firstByTokenAStopLoss : _state.firstByTokenBStopLoss;
        _prevByStopLoss = prevByStopLoss;

        if (_prevByStopLoss != 0) {
            Liquifi.Order memory prevByStopLossOrder = orders[_prevByStopLoss];
            if (prevByStopLossOrder.period > 0  // check order existance by required field 'period'
                && prevByStopLossOrder.prevByStopLoss & 1 == 0 // check that order is not closed: closed order has invalid id (odd) in prevByStopLoss
                && Liquifi.isTokenAIn(prevByStopLossOrder.flags) == isTokenA) {
                _nextByStopLoss = prevByStopLossOrder.nextByStopLoss;

                // iterate towards list start if needed
                (uint prevStopLossAmount, uint prevAmountIn) = (prevByStopLossOrder.stopLossAmount, prevByStopLossOrder.amountIn);
                while(_prevByStopLoss != 0) {
                    if (prevAmountIn * stopLossAmount <= amountIn * prevStopLossAmount) {
                        break;
                    }

                    _nextByStopLoss = _prevByStopLoss;
                    _prevByStopLoss = orders[_prevByStopLoss].prevByStopLoss;
                    
                    (prevStopLossAmount, prevAmountIn) = 
                        (orders[_prevByStopLoss].stopLossAmount, orders[_prevByStopLoss].amountIn); // grouped read
                }

            } else {
                // invalid prevByStopLoss passed, start search from list head
                _prevByStopLoss = 0;
            }            
        }

        // iterate towards list end if needed
        while(_nextByStopLoss != 0) {            
            (uint nextStopLossAmount, uint nextAmountIn) = 
                (orders[_nextByStopLoss].stopLossAmount, orders[_nextByStopLoss].amountIn); // grouped read

            if (nextAmountIn * stopLossAmount >= amountIn * nextStopLossAmount) {
                break;
            }

            _prevByStopLoss = _nextByStopLoss;
            _nextByStopLoss = orders[_nextByStopLoss].nextByStopLoss;
        }
    }

    // force reserves to match balances
    function sync() external override {
        (Liquifi.PoolBalances memory _balances, Liquifi.PoolState memory _state) = enter(Liquifi.ErrorArg.M_IN_CLAIM_ORDER);
        Liquifi.setFlag(_state, Liquifi.Flag.TOTALS_DIRTY);
        _balances.totalBalanceA = Liquifi.trimTotal(tokenA.balanceOf(address(this)), Liquifi.ErrorArg.O_TOKEN_A);
        _balances.totalBalanceB = Liquifi.trimTotal(tokenB.balanceOf(address(this)), Liquifi.ErrorArg.P_TOKEN_B);
        if (_state.firstByTimeout == 0 && _state.ordersToClaimCount == 0) {
            _balances.balanceALocked = 0;
            _balances.poolFlowSpeedA = 0;
            _balances.balanceBLocked = 0;
            _balances.poolFlowSpeedB = 0;
            Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_A_DIRTY);
            Liquifi.setFlag(_state, Liquifi.Flag.BALANCE_B_DIRTY);
        }
        exit(_balances, _state);
    }
}

// SPDX-License-Identifier: GPL-3.0
contract LiquifiPoolFactory is PoolFactory {
    address private immutable weth;
    address private immutable governanceRouter;
    
    mapping(address => mapping(address => address)) private poolMap;
    address[] public override pools;

    constructor(address _governanceRouter) public {
        governanceRouter = _governanceRouter;
        weth = address(GovernanceRouter(_governanceRouter).weth());
        if (address(GovernanceRouter(_governanceRouter).poolFactory()) == address(0)) {
            GovernanceRouter(_governanceRouter).setPoolFactory(this);
        }
    }

    function getPool(address token1, address token2) external override returns (address pool) {
        address _weth = weth;
        if ((token1 == _weth ? address(0) : token1) > (token2 == _weth ? address(0) : token2)) {
            (token2, token1) = (token1, token2); // ensure that weth cannot become tokenB
        }

        bool aIsWETH = token1 == _weth;
        pool = poolMap[token1][token2];
        if (pool == address(0)) {
            pool = address(new LiquifiDelayedExchangePool{ /* make pool address deterministic */ salt: bytes32(uint(1))}(
                token1, token2, aIsWETH, governanceRouter, pools.length
            ));
            pools.push(pool);
            poolMap[token1][token2] = pool;
            poolMap[token2][token1] = pool;
            emit PoolCreatedEvent(token1, token2, aIsWETH, pool);
        }
    }

    function findPool(address token1, address token2) external override view returns (address pool) {
        return poolMap[token1][token2];
    }

    function getPoolCount() external override view returns (uint) {
        return pools.length;
    }
}