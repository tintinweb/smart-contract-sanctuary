/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoteStrategy {

    function snapshot(address target) external;
    function totalVotePower(address target, uint blockNo) external view returns(uint);
    function votePower(address target, uint blockNo, address account) external view returns(uint);
    function minPower(address target) external view returns(uint);
    function creationFee(address target) external view returns(uint);
    function minQuorum(address target) external view returns(uint);
    function voteDifferential(address target) external view returns(uint);
    function duration(address target) external view returns(uint64);
    function executionDelay(address target) external view returns(uint64);
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\TimelockExecutor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IVoteStrategy.sol";

enum ProposalState { Auto, Pending, Voting, Passed, Failed, Queued, Executed, Canceled, Expired }

struct ProposalMeta {
    uint256 proposalId;
    ProposalState state;        
    uint64 startedAt;   // the timestamp when this proposal is active for voting
    uint64 endedBy;     // the timestamp when this proposal finish
    uint64 executionTime;
    bytes32 contentHash;    // hash of the proposal content
    address target;     // the address of the affected DABot, 0x0 address for platform setting
    address proposer;   // the account who initiates this proposal
    uint256 blockNo;
    uint256 forVotes;
    uint256 againstVotes;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] args;
    bool[] delegateCalls;
}

interface IGovernanceEvent {
    event DefaultStrategyChanged(address indexed strategy);
    event StrategyChanged(address indexed target, address indexed strategy);
    event ExecutorChanged(address indexed executor);
    event NewProposal(uint proposalId, string title, uint64 startedAt, uint64 endedBy, address indexed target,
                    address indexed proposer, bytes32 contentHash);
    event StateChanged(uint proposalId, ProposalState newState, bytes data);
    event Vote(address indexed voter, uint proposalId, uint votePower, bool support);
    event Unvote(address indexed voter, uint proposalId);
}

interface IGovernance is IGovernanceEvent {

    function setDefaultStrategy(IVoteStrategy strategy) external;
    function setVoteStrategy(address target, IVoteStrategy strategy) external;

    function getProposalById(uint proposalId) external view returns(ProposalMeta memory);
    function createProposal(
        string memory title,
        address target,
        bytes32 contentHash,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory args,
        bool[] memory delegateCalls
    ) external returns(uint);
    function cancelProposal(uint256 proposalId) external;
    function vote(uint256 proposalId, bool support) external;
    function unvote(uint256 proposalId) external;
    function updateState(uint256 proposalId, ProposalState state) external;
    function queueProposal(uint256 proposalId) external;
    function executeProposal(uint256 proposalId) external payable;
}




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\TimelockExecutor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "./IGovernance.sol";

interface ITimelockExecutor {
    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when a new delay (between queueing and execution) is set
     * @param delay new delay
     **/
    event NewDelay(uint256 delay);

    /**
     * @dev emitted when a new (trans)action is Queued.
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event QueuedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    event CancelledAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall
    );

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bool withDelegatecall,
        bytes resultData
    );

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Getter of the delay between queuing and execution
     * @return The delay in seconds
     **/
    function getDelay() external view returns (uint256);

    /**
     * @dev Returns whether an action (via actionHash) is queued
     * @param actionHash hash of the action to be checked
     * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
     * @return true if underlying action of actionHash is queued
     **/
    function isActionQueued(bytes32 actionHash) external view returns (bool);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverGracePeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view returns (bool);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    //   function isProposalOverGracePeriod(IAaveGovernanceV2 governance, uint256 proposalId)
    //     external
    //     view
    //     returns (bool);

    /**
     * @dev Getter of grace period constant
     * @return grace period in seconds
     **/
    function GRACE_PERIOD() external view returns (uint256);

    /**
     * @dev Getter of minimum delay constant
     * @return minimum delay in seconds
     **/
    function MINIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Getter of maximum delay constant
     * @return maximum delay in seconds
     **/
    function MAXIMUM_DELAY() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that queue a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external payable returns (bytes memory);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     **/
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) external returns (bytes32);
}




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\TimelockExecutor.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

library Errors {
    /// Common error
    string constant CM_CONTRACT_HAS_BEEN_INITIALIZED = "CM-01"; 
    string constant CM_FACTORY_ADDRESS_IS_NOT_CONFIGURED = "CM-02";
    string constant CM_VICS_ADDRESS_IS_NOT_CONFIGURED = "CM-03";
    string constant CM_VICS_EXCHANGE_IS_NOT_CONFIGURED = "CM-04";
    string constant CM_CEX_FUND_MANAGER_IS_NOT_CONFIGURED = "CM-05";
    string constant CM_TREASURY_MANAGER_IS_NOT_CONFIGURED = "CM-06";
    string constant CM_CEX_DEFAULT_MASTER_ACCOUNT_IS_NOT_CONFIGURED = "CM-07";
    string constant CM_ADDRESS_IS_NOT_ICEXDABOTCERTTOKEN = "CM-08";
    

    /// IBCertToken error  (Bot Certificate Token)
    string constant BCT_CALLER_IS_NOT_OWNER = "BCT-01"; 
    string constant BCT_REQUIRE_ALL_TOKENS_BURNT = "BCT-02";
    string constant BCT_UNLOCK_AMOUNT_EXCEEDS_TOTAL_LOCKED = "BCT-03";
    string constant BCT_INSUFFICIENT_LIQUID_FOR_UNLOCKING = "BCT-04a";
    string constant BCT_INSUFFICIENT_LIQUID_FOR_LOCKING = "BCT-04b";
    string constant BCT_AMOUNT_EXCEEDS_TOTAL_STAKE = "BCT-05";
    string constant BCT_CANNOT_MINT_TO_ZERO_ADDRESS = "BCT-06";
    string constant BCT_INSUFFICIENT_LIQUID_FOR_BURN = "BCT-07";
    string constant BCT_INSUFFICIENT_ACCOUNT_FUND = "BCT-08";
    string constant BCT_CALLER_IS_NEITHER_BOT_NOR_CERTLOCKER = "BCT-09";

    /// IBCEXCertToken error (Cex Bot Certificate Token)
    string constant CBCT_CALLER_IS_NOT_FUND_MANAGER = "CBCT-01";

    /// GovernToken error (Bot Governance Token)
    string constant BGT_CALLER_IS_NOT_OWNED_BOT = "BGT-01";
    string constant BGT_CANNOT_MINT_TO_ZERO_ADDRESS = "BGT-02";
    string constant BGT_CALLER_IS_NOT_GOVERNANCE = "BGT-03";

    // VaultBase error (VB)
    string constant VB_CALLER_IS_NOT_DABOT = "VB-01a";
    string constant VB_CALLER_IS_NOT_OWNER_BOT = "VB-01b";
    string constant VB_INVALID_VAULT_ID = "VB-02";
    string constant VB_INVALID_VAULT_TYPE = "VB-03";
    string constant VB_INVALID_SNAPSHOT_ID = "VB-04";

    // RegularVault Error (RV)
    string constant RV_VAULT_IS_RESTRICTED = "RV-01";
    string constant RV_DEPOSIT_LOCKED = "RV-02";
    string constant RV_WITHDRAWL_AMOUNT_EXCEED_DEPOSIT = "RV-03";

    // BotVaultManager (VM)
    string constant VM_VAULT_EXISTS = "VM-01";

    // BotManager (BM)
    string constant BM_DOES_NOT_SUPPORT_IDABOT = "BM-01";
    string constant BM_DUPLICATED_BOT_QUALIFIED_NAME = "BM-02";
    string constant BM_TEMPLATE_IS_NOT_REGISTERED = "BM-03";
    string constant BM_GOVERNANCE_TOKEN_IS_NOT_DEPLOYED = "BM-04";
    string constant BM_BOT_IS_NOT_REGISTERED = "BM-05";

    // DABotModule (BMOD)
    string constant BMOD_CALLER_IS_NOT_OWNER = "BMOD-01";
    string constant BMOD_CALLER_IS_NOT_BOT_MANAGER = "BMOD-02";
    string constant BMOD_BOT_IS_ABANDONED = "BMOD-03";

    // DABotControllerLib (BCL)
    string constant BCL_DUPLICATED_MODULE = "BCL-01";
    string constant BCL_CERT_TOKEN_IS_NOT_CONFIGURED = "BCL-02";
    string constant BCL_GOVERN_TOKEN_IS_NOT_CONFIGURED = "BCL-03";
    string constant BCL_GOVERN_TOKEN_IS_NOT_DEPLOYED = "BCL-04";
    string constant BCL_WARMUP_LOCKER_IS_NOT_CONFIGURED = "BCL-05";
    string constant BCL_COOLDOWN_LOCKER_IS_NOT_CONFIGURED = "BCL-06";
    string constant BCL_UKNOWN_MODULE_ID = "BCL-07";
    string constant BCL_BOT_MANAGER_IS_NOT_CONFIGURED = "BCL-08";

    // DABotController (BCMOD)
    string constant BCMOD_CANNOT_CALL_TEMPLATE_METHOD_ON_BOT_INSTANCE = "BCMOD-01";
    string constant BCMOD_CALLER_IS_NOT_OWNER = "BCMOD-02";
    string constant BCMOD_MODULE_HANDLER_NOT_FOUND_FOR_METHOD_SIG = "BCMOD-03";
    string constant BCMOD_NEW_OWNER_IS_ZERO = "BCMOD-04";

    // CEXFundManagerModule (CFMOD)
    string constant CFMOD_DUPLICATED_BENEFITCIARY = "CFMOD-01";
    string constant CFMOD_INVALID_CERTIFICATE_OF_ASSET = "CFMOD-02";
    string constant CFMOD_CALLER_IS_NOT_FUND_MANAGER = "CFMOD-03";

    // DABotSettingLib (BSL)
    string constant BSL_CALLER_IS_NOT_OWNER = "BSL-01";
    string constant BSL_CALLER_IS_NOT_GOVERNANCE_EXECUTOR = "BSL-02";
    string constant BSL_IBO_ENDTIME_IS_SOONER_THAN_IBO_STARTTIME = "BSL-03";
    string constant BSL_BOT_IS_ABANDONED = "BSL-04";

    // DABotSettingModule (BSMOD)
    string constant BSMOD_IBO_ENDTIME_IS_SOONER_THAN_IBO_STARTTIME =  "BSMOD-01";
    string constant BSMOD_INIT_DEPOSIT_IS_LESS_THAN_CONFIGURED_THRESHOLD = "BSMOD-02";
    string constant BSMOD_FOUNDER_SHARE_IS_ZERO = "BSMOD-03";
    string constant BSMOD_INSUFFICIENT_MAX_SHARE = "BSMOD-04";
    string constant BSMOD_FOUNDER_SHARE_IS_GREATER_THAN_IBO_SHARE = "BSMOD-05";

    // DABotCertLocker (LOCKER)
    string constant LOCKER_CALLER_IS_NOT_OWNER_BOT = "LOCKER-01";

    // DABotStakingModule (BSTMOD)
    string constant BSTMOD_PRE_IBO_REQUIRED = "BSTMOD-01";
    string constant BSTMOD_AFTER_IBO_REQUIRED = "BSTMOD-02";
    string constant BSTMOD_INVALID_PORTFOLIO_ASSET = "BSTMOD-03";
    string constant BSTMOD_PORTFOLIO_FULL = "BSTMOD-04";
    string constant BSTMOD_INVALID_CERTIFICATE_ASSET = "BSTMOD-05";
    string constant BSTMOD_PORTFOLIO_ASSET_NOT_FOUND = "BSTMOD-06";
    string constant BSTMOD_ASSET_IS_ZERO = "BSTMOD-07";
    string constant BSTMOD_INVALID_STAKING_CAP = "BSTMOD-08";
    string constant BSTMOD_INSUFFICIENT_FUND = "BSTMOD-09";
    string constant BSTMOD_CAP_IS_ZERO = "BSTMOD-10";
    string constant BSTMOD_CAP_IS_LESS_THAN_STAKED_AND_IBO_CAP = "BSTMOD-11";
    string constant BSTMOD_WERIGHT_IS_ZERO = "BSTMOD-12";

    // CEX FundManager (CFM)
    string constant CFM_REQ_TYPE_IS_MISMATCHED = "CFM-01";
    string constant CFM_INVALID_REQUEST_ID = "CFM-02";
    string constant CFM_CALLER_IS_NOT_BOT_TOKEN = "CFM-03";
    string constant CFM_CLOSE_TYPE_VALUE_IS_NOT_SUPPORTED = "CFM-04";
    string constant CFM_UNKNOWN_REQUEST_TYPE = "CFM-05";
    string constant CFM_CALLER_IS_NOT_REQUESTER = "CFM-06";
    string constant CFM_CALLER_IS_NOT_APPROVER = "CFM-07";
    string constant CFM_CEX_CERTIFICATE_IS_REQUIRED = "CFM-08";
    string constant CFM_TREASURY_ASSET_CERTIFICATE_IS_REQUIRED = "CFM-09";
    string constant CFM_FAIL_TO_TRANSFER_VALUE = "CFM-10";
    string constant CFM_AWARDED_ASSET_IS_NOT_TREASURY = "CFM-11";
    string constant CFM_INSUFFIENT_ASSET_TO_MINT_STOKEN = "CFM-12";

    // TreasuryAsset (TA)
    string constant TA_MINT_ZERO_AMOUNT = "TA-01";
    string constant TA_LOCK_AMOUNT_EXCEED_BALANCE = "TA-02";
    string constant TA_UNLOCK_AMOUNT_AND_PASSED_VALUE_IS_MISMATCHED = "TA-03";
    string constant TA_AMOUNT_EXCEED_AVAILABLE_BALANCE = "TA-04";
    string constant TA_AMOUNT_EXCEED_VALUE_BALANCE = "TA-05";
    string constant TA_FUND_MANAGER_IS_NOT_SET = "TA-06";
    string constant TA_FAIL_TO_TRANSFER_VALUE = "TA-07";

    // Governance (GOV)
    string constant GOV_DEFAULT_STRATEGY_IS_NOT_SET = "GOV-01";
    string constant GOV_INSUFFICIENT_POWER_TO_CREATE_PROPOSAL = "GOV-02";
    string constant GOV_INSUFFICIENT_VICS_TO_CREATE_PROPOSAL = "GOV-03";
    string constant GOV_INVALID_PROPOSAL_ID = "GOV-04";
    string constant GOV_REQUIRED_PROPOSER_OR_GUARDIAN = "GOV-05";
    string constant GOV_TARGET_SHOULD_BE_ZERO_OR_REGISTERED_BOT = "GOV-06";
    string constant GOV_INSUFFICIENT_POWER_TO_VOTE = "GOV-07";
    string constant GOV_INVALID_NEW_STATE = "GOV-08";
    string constant GOV_CANNOT_CHANGE_STATE_OF_CLOSED_PROPOSAL = "GOV-08";
    string constant GOV_INVALID_CREATION_DATA = "GOV-09";
    string constant GOV_CANNOT_CHANGE_STATE_OF_ON_CHAIN_PROPOSAL = "GOV-10";
    string constant GOV_PROPOSAL_DONT_ACCEPT_VOTE = "GOV-11";
    string constant GOV_DUPLICATED_VOTE = "GOV-12";
    string constant GOV_CAN_ONLY_QUEUE_PASSED_PROPOSAL = "GOV-13";
    string constant GOV_DUPLICATED_ACTION = "GOV-14";
    string constant GOV_INVALID_VICS_ADDRESS = "GOV-15";

    // Timelock Executor (TLE)
    string constant TLE_DELAY_SHORTER_THAN_MINIMUM = "TLE-01";
    string constant TLE_DELAY_LONGER_THAN_MAXIMUM = "TLE-02";
    string constant TLE_ONLY_BY_ADMIN = "TLE-03";
    string constant TLE_ONLY_BY_PENDING_ADMIN = "TLE-04";
    string constant TLE_ONLY_BY_THIS_TIMELOCK = "TLE-05";
    string constant TLE_EXECUTION_TIME_UNDERESTIMATED = "TLE-06";
    string constant TLE_ACTION_NOT_QUEUED = "TLE-07";
    string constant TLE_TIMELOCK_NOT_FINISHED = "TLE-08";
    string constant TLE_GRACE_PERIOD_FINISHED = "TLE-09";
    string constant TLE_NOT_ENOUGH_MSG_VALUE = "TLE-10";

    // DABotVoteStrategy (BVS) string constant BVS_ = "BVS-";
    string constant BVS_NOT_A_REGISTERED_DABOT = "BVS-01";

    // DABotWhiteList (BWL) string constant BWL_ = "BWL-";
    string constant BWL_ACCOUNT_IS_ZERO = "BWL-01";
    string constant BWL_ACCOUNT_IS_NOT_WHITELISTED = "BWL-02";
}

/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\TimelockExecutor.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "../common/Errors.sol";
////import "./ITimelockExecutor.sol";
////import "./IGovernance.sol";

contract TimeLockExecutor is ITimelockExecutor {
    uint256 public immutable override GRACE_PERIOD;
    uint256 public immutable override MINIMUM_DELAY;
    uint256 public immutable override MAXIMUM_DELAY;

    address private _admin;
    address private _pendingAdmin;
    uint256 private _delay;

    mapping(bytes32 => bool) private _queuedTransactions;

    /**
     * @dev Constructor
     * @param admin admin address, that can call the main functions, (Governance)
     * @param delay minimum time between queueing and execution of proposal
     * @param gracePeriod time after `delay` while a proposal can be executed
     * @param minimumDelay lower threshold of `delay`, in seconds
     * @param maximumDelay upper threhold of `delay`, in seconds
     **/
    constructor(
        address admin,
        uint256 delay,
        uint256 gracePeriod,
        uint256 minimumDelay,
        uint256 maximumDelay
    ) {
        require(delay >= minimumDelay, Errors.TLE_DELAY_SHORTER_THAN_MINIMUM);
        require(delay <= maximumDelay, Errors.TLE_DELAY_LONGER_THAN_MAXIMUM);
        _delay = delay;
        _admin = admin;

        GRACE_PERIOD = gracePeriod;
        MINIMUM_DELAY = minimumDelay;
        MAXIMUM_DELAY = maximumDelay;

        emit NewDelay(delay); 
        emit NewAdmin(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, Errors.TLE_ONLY_BY_ADMIN);
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == address(this), Errors.TLE_ONLY_BY_THIS_TIMELOCK);
        _;
    }

    modifier onlyPendingAdmin() {
        require(msg.sender == _pendingAdmin, Errors.TLE_ONLY_BY_PENDING_ADMIN);
        _;
    }

    /**
     * @dev Set the delay
     * @param delay delay between queue and execution of proposal
     **/
    function setDelay(uint256 delay) public onlyTimelock {
        _validateDelay(delay);
        _delay = delay;

        emit NewDelay(delay);
    }

    /**
     * @dev Function enabling pending admin to become admin
     **/
    function acceptAdmin() public onlyPendingAdmin {
        _admin = msg.sender;
        _pendingAdmin = address(0);

        emit NewAdmin(msg.sender);
    }

    /**
     * @dev Setting a new pending admin (that can then become admin)
     * Can only be called by this executor (i.e via proposal)
     * @param newPendingAdmin address of the new admin
     **/
    function setPendingAdmin(address newPendingAdmin) public onlyTimelock {
        _pendingAdmin = newPendingAdmin;

        emit NewPendingAdmin(newPendingAdmin);
    }

    /**
     * @dev Function, called by Governance, that queue a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the action Hash
     **/
    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public override onlyAdmin returns (bytes32) {
        require(
            executionTime >= block.timestamp + _delay,
            Errors.TLE_EXECUTION_TIME_UNDERESTIMATED
        );

        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                bytes4(keccak256(bytes(signature))),
                data,
                executionTime,
                withDelegatecall
            )
        );
        _queuedTransactions[actionHash] = true;

        emit QueuedAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall
        );
        return actionHash;
    }

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns action hash
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the action Hash of the canceled tx
     **/
    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public override onlyAdmin returns (bytes32) {
        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                bytes4(keccak256(bytes(signature))),
                data,
                executionTime,
                withDelegatecall
            )
        );
        _queuedTransactions[actionHash] = false;

        emit CancelledAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall
        );
        return actionHash;
    }

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param withDelegatecall boolean, true = transaction delegatecalls the target, else calls the target
     * @return the callData executed as memory bytes
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 executionTime,
        bool withDelegatecall
    ) public payable override onlyAdmin returns (bytes memory) {
        bytes32 actionHash = keccak256(
            abi.encode(
                target,
                value,
                bytes4(keccak256(bytes(signature))),
                data,
                executionTime,
                withDelegatecall
            )
        );
        require(_queuedTransactions[actionHash], Errors.TLE_ACTION_NOT_QUEUED);
        require(block.timestamp >= executionTime, Errors.TLE_TIMELOCK_NOT_FINISHED);
        require(
            block.timestamp <= executionTime + GRACE_PERIOD,
            Errors.TLE_GRACE_PERIOD_FINISHED
        );

        _queuedTransactions[actionHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        bool success;
        bytes memory resultData;
        if (withDelegatecall) {
            require(msg.value >= value, Errors.TLE_NOT_ENOUGH_MSG_VALUE);
            // solium-disable-next-line security/no-call-value
            (success, resultData) = target.delegatecall(callData);
        } else {
            // solium-disable-next-line security/no-call-value
            (success, resultData) = target.call{value: value}(callData);
        }

        require(success, string(resultData));

        emit ExecutedAction(
            actionHash,
            target,
            value,
            signature,
            data,
            executionTime,
            withDelegatecall,
            resultData
        );

        return resultData;
    }

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view override returns (address) {
        return _admin;
    }

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view override returns (address) {
        return _pendingAdmin;
    }

    /**
     * @dev Getter of the delay between queuing and execution
     * @return The delay in seconds
     **/
    function getDelay() external view override returns (uint256) { 
        return _delay;
    }

    /**
     * @dev Returns whether an action (via actionHash) is queued
     * @param actionHash hash of the action to be checked
     * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
     * @return true if underlying action of actionHash is queued
     **/
    function isActionQueued(bytes32 actionHash)
        external
        view
        override
        returns (bool)
    {
        return _queuedTransactions[actionHash];
    }

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverGracePeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view override returns (bool) { 
        ProposalMeta memory proposal = governance.getProposalById(proposalId);
        return (block.timestamp > proposal.executionTime + GRACE_PERIOD);
    }

    function _validateDelay(uint256 delay) internal view {
        require(delay >= MINIMUM_DELAY, Errors.TLE_DELAY_SHORTER_THAN_MINIMUM);
        require(delay <= MAXIMUM_DELAY, Errors.TLE_DELAY_LONGER_THAN_MAXIMUM);
    }

    receive() external payable {}
}