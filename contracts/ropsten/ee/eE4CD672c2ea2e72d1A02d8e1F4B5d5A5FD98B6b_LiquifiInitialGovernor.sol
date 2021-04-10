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

library LiquifiDAO {
    enum ProposalStatus { 
        IN_PROGRESS,
        APPROVED,
        DECLINED,
        VETO
    }
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

contract LiquifiProposal {
    using Math for uint256;
    event ProposalVoted(address user, Vote vote, uint influence);

    ERC20 public immutable govToken;
    LiquifiInitialGovernor public immutable governor;

    enum Vote {
        NONE, YES, NO, ABSTAIN, NO_WITH_VETO
    }

    mapping(address => Vote) public voted;
    // 0 - hasn't voted
    // 1 - voted yes
    // 2 - voted no
    // 3 - voted abstain
    // 4 - voted noWithVeto

    string public description;
    uint public approvalsInfluence = 0;
    uint public againstInfluence = 0;
    uint public abstainInfluence = 0;
    uint public noWithVetoInfluence = 0;
    
    LiquifiDAO.ProposalStatus public result;
    
    uint public immutable started; //time when proposal was created
    uint public immutable totalInfluence;
    
    uint public immutable option;
    uint public immutable newValue;
    uint public immutable quorum;
    uint public immutable vetoPercentage;
    uint public immutable votingPeriod;
    uint public immutable threshold;
    address public immutable addr;
    address public immutable addr2;

    constructor(string memory _description, 
            uint _totalInfluence, 
            address _govToken, 
            uint _option, uint _newValue, 
            uint _quorum, uint _threshold, uint _vetoPercentage, uint _votingPeriod, 
            address _address, address _address2) {
        description = _description;
        started = block.timestamp;
        totalInfluence = _totalInfluence; 
        governor = LiquifiInitialGovernor(msg.sender);
        govToken = ERC20(_govToken);

        option = _option;
        newValue = _newValue;

        quorum = _quorum;
        threshold = _threshold;
        vetoPercentage = _vetoPercentage;
        votingPeriod = _votingPeriod;
        addr = _address;
        addr2 = _address2;
    }

    function vote(Vote _vote) public {
        address user = msg.sender;
        uint influence = govToken.balanceOf(user);
        (uint deposited,) = governor.deposits(user);
        influence = influence.add(deposited);
        vote(_vote, influence);
    }


    function vote(Vote _vote, uint influence) public {
        address user = msg.sender;
        require(voted[user] == Vote.NONE, "You have already voted!");

        voted[user] = _vote; // prevent reentrance

        require(influence > 0, "Proposal.vote: No governance tokens in wallet");
        governor.proposalVote(user, influence, endTime());

        if (checkIfEnded() != LiquifiDAO.ProposalStatus.IN_PROGRESS)
            return;
            
        if (_vote == Vote.YES) {
            approvalsInfluence += influence;
        } else if (_vote == Vote.NO) {
            againstInfluence += influence;
        } else if (_vote == Vote.ABSTAIN) {
            abstainInfluence += influence;
        } else if (_vote == Vote.NO_WITH_VETO) {
            noWithVetoInfluence += influence;
            againstInfluence += influence;
        }
        emit ProposalVoted(user, _vote, influence);
    }

    function endTime() public view returns (uint) {
        return started + 1 hours * votingPeriod;
    }

    function checkIfEnded() public returns (LiquifiDAO.ProposalStatus) {
        require(result == LiquifiDAO.ProposalStatus.IN_PROGRESS, "voting completed");
        
        if (block.timestamp > endTime()) {
            return finalize();
        } else {
            return LiquifiDAO.ProposalStatus.IN_PROGRESS;
        }
    }

    function finalize() public returns (LiquifiDAO.ProposalStatus) {
        require(block.timestamp > endTime(), "Proposal: Period hasn't passed");

        if ((totalInfluence != 0) 
            && (100 * (approvalsInfluence + againstInfluence + abstainInfluence) / totalInfluence < quorum )){
            result = LiquifiDAO.ProposalStatus.DECLINED;
            governor.proposalFinalization(result, 0, 0, address(0), address(0));
            return result;        
        }

        if ((approvalsInfluence + againstInfluence + abstainInfluence) != 0 &&
            (100 * noWithVetoInfluence / (approvalsInfluence + againstInfluence + abstainInfluence) >= vetoPercentage)) {
            result = LiquifiDAO.ProposalStatus.VETO;
            governor.proposalFinalization(result, 0, 0, address(0), address(0));
        }
        else if ((approvalsInfluence + againstInfluence) != 0 &&
            (100 * approvalsInfluence / (approvalsInfluence + againstInfluence) > threshold)) {
            result = LiquifiDAO.ProposalStatus.APPROVED;
            governor.proposalFinalization(result, option, newValue, addr, addr2);
        }
        else {
            result = LiquifiDAO.ProposalStatus.DECLINED;
            governor.proposalFinalization(result, 0, 0, address(0), address(0));
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
//import { Debug } from "./libraries/Debug.sol";
contract LiquifiInitialGovernor {
    using Math for uint256;

    event EmergencyLock(address sender, address pool);
    event ProposalCreated(address proposal);
    event ProposalFinalized(address proposal, LiquifiDAO.ProposalStatus proposalStatus);
    event DepositWithdrawn(address user, uint amount);

    struct CreatedProposals{
        uint amountDeposited;
        LiquifiDAO.ProposalStatus status;
        address creator;
    }

    struct Deposit {
        uint amount;
        uint unfreezeTime;
    }
    
    LiquifiProposal[] public deployedProposals;
    mapping(address => CreatedProposals) proposalInfo;
    mapping(/* user */address => Deposit) public deposits;
    address[] public userDepositsList;

    uint public immutable tokensRequiredToCreateProposal; 
    uint public constant quorum = 10; //percenrage
    uint public constant threshold = 50;
    uint public constant vetoPercentage = 33;
    uint public immutable votingPeriod; //hours

    ERC20 private immutable govToken;
    GovernanceRouter public immutable governanceRouter;
	
	PoolFactory public immutable newPoolFactory;

    constructor(address _governanceRouterAddress, uint _tokensRequiredToCreateProposal, uint _votingPeriod, address _newPoolFactory) {
        tokensRequiredToCreateProposal = _tokensRequiredToCreateProposal;
        votingPeriod = _votingPeriod;
        govToken = GovernanceRouter(_governanceRouterAddress).minter();
        governanceRouter = GovernanceRouter(_governanceRouterAddress);
        (address oldGovernor,) = GovernanceRouter(_governanceRouterAddress).governance();
        if (oldGovernor == address(0)) {
            GovernanceRouter(_governanceRouterAddress).setGovernor(address(this));
        }
		newPoolFactory = PoolFactory(_newPoolFactory);
    }

    function deposit(address user, uint amount, uint unfreezeTime) private {
        uint deposited = deposits[user].amount;
        if (deposited < amount) {
            uint remainingAmount = amount.subWithClip(deposited);
            require(govToken.transferFrom(user, address(this), remainingAmount), "LIQUIFI_GV: TRANSFER FAILED");
            deposits[user].amount = amount;
        }
        deposits[user].unfreezeTime = Math.max(deposits[user].unfreezeTime, unfreezeTime);
        userDepositsList.push(user);
    } 

    function withdraw() public {
        require(_withdraw(msg.sender, block.timestamp) > 0, "LIQUIFI_GV: WITHDRAW FAILED");
    }

    function _withdraw(address user, uint maxTime) private returns (uint) {
        uint amount = deposits[user].amount;
        if (amount == 0 || deposits[user].unfreezeTime >= maxTime) {
            return 0;
        }
        
        deposits[user].amount = 0;
        require(govToken.transfer(user, amount), "LIQUIFI_GV: TRANSFER FAILED");
        emit DepositWithdrawn(user, amount);
        return amount;
    }

    function withdrawAll() public {
        withdrawMultiple(0, userDepositsList.length);
    }

    function withdrawMultiple(uint fromIndex, uint toIndex) public {
        uint maxWithdrawTime = block.timestamp;
        (address currentGovernor,) = governanceRouter.governance();

        if (currentGovernor != address(this)) {
            maxWithdrawTime = type(uint).max;
        }
        
        for(uint userIndex = fromIndex; userIndex < toIndex; userIndex++) {
            _withdraw(userDepositsList[userIndex], maxWithdrawTime);
        }
    }

    function createProposal(string memory _proposal, uint _option, uint _newValue, address _address, address _address2) public {
        address creator = msg.sender;
        LiquifiProposal newProposal = new LiquifiProposal(_proposal, govToken.totalSupply(), address(govToken), _option, _newValue, quorum, threshold, vetoPercentage, votingPeriod, _address, _address2);
        
        uint tokensRequired = deposits[creator].amount.add(tokensRequiredToCreateProposal);
        deposit(creator, tokensRequired, newProposal.endTime());

        deployedProposals.push(newProposal);

        proposalInfo[address(newProposal)].amountDeposited = tokensRequiredToCreateProposal;
        proposalInfo[address(newProposal)].creator = creator;
        emit ProposalCreated(address(newProposal));
    }

    function emergencyLock(address pool) public returns (bool locked) {
        uint gasBefore = gasleft();
        try DelayedExchangePool(pool).processDelayedOrders() {
            return false;
        } catch (bytes memory /*lowLevelData*/) {
            uint gasAfter = gasleft();
            require((gasBefore - gasAfter) * 10 / gasBefore >= 1, "LIQUIFI: LOW GAS");
            lockPool(pool);
            if (knownPool(pool)) {
                emit EmergencyLock(msg.sender, pool);
            }
            return true;
        }
    }

    function getDeployedProposals() public view returns (LiquifiProposal[] memory) {
        return deployedProposals;
    }

    function proposalVote(address user, uint influence, uint unfreezeTime) public {
        address proposal = msg.sender;
        require(proposalInfo[proposal].amountDeposited > 0, "LIQUIFI_GV: BAD SENDER");
        require(proposalInfo[proposal].status == LiquifiDAO.ProposalStatus.IN_PROGRESS, "LIQUIFI_GV: PROPOSAL FINALIZED");

        deposit(user, influence, unfreezeTime);
    }

    function proposalFinalization(LiquifiDAO.ProposalStatus _proposalStatus, uint _option, uint /* _value */, address _address, address /* _address2 */) public {
        address proposal = msg.sender;
        require(proposalInfo[proposal].amountDeposited > 0, "LIQUIFI_GV: BAD SENDER");
        require(proposalInfo[proposal].status == LiquifiDAO.ProposalStatus.IN_PROGRESS, "LIQUIFI_GV: PROPOSAL FINALIZED");
        
        if (_proposalStatus == LiquifiDAO.ProposalStatus.APPROVED) {
            if (_option == 1) { 
                changeGovernor(_address); 
            }
        }

        proposalInfo[proposal].status = _proposalStatus;   
        emit ProposalFinalized(proposal, _proposalStatus);   
    }

    function changeGovernor(address _newGovernor) private {
        governanceRouter.setGovernor(_newGovernor);
    }

    function lockPool(address pool) internal {
        (,uint governancePacked,,,,,,) = DelayedExchangePool(pool).poolState();

        governancePacked = governancePacked | (1 << uint(Liquifi.Flag.POOL_LOCKED));
        governancePacked = governancePacked | (1 << uint(Liquifi.Flag.GOVERNANCE_OVERRIDEN));
        DelayedExchangePool(pool).applyGovernance(governancePacked);
    }

    function knownPool(address pool) private returns (bool) {
        address tokenA = address(DelayedExchangePool(pool).tokenA());
        address tokenB = address(DelayedExchangePool(pool).tokenB());
        return governanceRouter.poolFactory().findPool(tokenA, tokenB) == pool;
    }

    function updatePoolFactory() public {
        governanceRouter.setPoolFactory(newPoolFactory);
    }
}