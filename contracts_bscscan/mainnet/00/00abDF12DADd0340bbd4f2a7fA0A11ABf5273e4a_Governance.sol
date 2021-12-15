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
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
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
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;


library Roles {
    bytes32 constant ROLE_ADMIN = keccak256('operator.dabot.role');
    bytes32 constant ROLE_OPERATORS = keccak256('operator.dabot.role');
    bytes32 constant ROLE_TEMPLATE_CREATOR = keccak256('creator.template.dabot.role');
    bytes32 constant ROLE_BOT_CREATOR = keccak256('creator.dabot.role');
    bytes32 constant ROLE_FUND_APPROVER = keccak256('approver.fund.role');
}

library AddressBook {
    bytes32 constant ADDR_FACTORY = keccak256('factory.address');
    bytes32 constant ADDR_VICS = keccak256('vics.address');
    bytes32 constant ADDR_TAX = keccak256('tax.address');
    bytes32 constant ADDR_GOVERNANCE = keccak256('governance.address');
    bytes32 constant ADDR_GOVERNANCE_EXECUTOR = keccak256('executor.governance.address');
    bytes32 constant ADDR_BOT_MANAGER = keccak256('botmanager.address');
    bytes32 constant ADDR_VICS_EXCHANGE = keccak256('exchange.vics.address');
    bytes32 constant ADDR_TREASURY_MANAGER = keccak256('treasury-manager.address');
    bytes32 constant ADDR_CEX_FUND_MANAGER = keccak256('fund-manager.address');
    bytes32 constant ADDR_CEX_DEFAULT_MASTER_ACCOUNT = keccak256('default.master.address');
}

library Config {
    /// The amount of VICS that a proposer has to pay when create a new proposal
    bytes32 constant PROPOSAL_DEPOSIT = keccak256('deposit.proposal.config');

    /// The percentage of proposal creation fee distributed to the account that execute a propsal
    bytes32 constant PROPOSAL_REWARD_PERCENT = keccak256('reward.proposal.config');

    /// The minimum VICS a bot creator has to deposit to a newly created bot
    bytes32 constant CREATOR_DEPOSIT = keccak256('deposit.creator.config');

    /// The minim 
    bytes32 constant PROPOSAL_CREATOR_MININUM_POWER = keccak256('minpower.goverance.config');
    
    /// The minimum percentage of for-votes over total votes a proposal has to achieve to be passed
    bytes32 constant PROPOSAL_MINIMUM_QUORUM = keccak256('minquorum.governance.config');

    /// The minimum difference (in percentage) between for-votes and against-vote for a proposal to be passed
    bytes32 constant PROPOSAL_VOTE_DIFFERENTIAL = keccak256('differential.governance.config');

    /// The voting duration of a proposal
    bytes32 constant PROPOSAL_DURATION = keccak256('duration.goverance.config');

    /// The interval that a passed proposed is waiting in queue before being executed
    bytes32 constant PROPOSAL_EXECUTION_DELAY = keccak256('execdelay.governance.config');
}

interface IConfigurator {
    function addressOf(bytes32 addrId) external view returns(address);
    function configOf(bytes32 configId) external view returns(uint);
    function bytesConfigOf(bytes32 configId) external view returns(bytes memory);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}





/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
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
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
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




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoboFiERC20 is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IRoboFiFactory {
    function deploy(address masterContract, 
                    bytes calldata data, 
                    bool useCreate2) 
        external 
        payable 
        returns(address);
}





/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";


string constant ERR_PERMISSION_DENIED = "DABot: permission denied";

bytes32 constant BOT_MODULE_VOTE_CONTROLER = keccak256("vote.dabot.module");
bytes32 constant BOT_MODULE_STAKING_CONTROLER = keccak256("staking.dabot.module");
bytes32 constant BOT_MODULE_CERTIFICATE_TOKEN = keccak256("certificate-token.dabot.module");
bytes32 constant BOT_MODULE_GOVERNANCE_TOKEN = keccak256("governance-token.dabot.module");

bytes32 constant BOT_MODULE_WARMUP_LOCKER = keccak256("warmup.dabot.module");
bytes32 constant BOT_MODULE_COOLDOWN_LOCKER = keccak256("cooldown.dabot.module");

enum BotStatus { PRE_IBO, IN_IBO, ACTIVE, ABANDONED }

struct BotModuleInitData {
    bytes32 moduleId;
    bytes data;
}

struct BotSetting {             // for saving storage, the meta-fields of a bot are encoded into a single uint256 byte slot.
    uint64 iboTime;             // 32 bit low: iboStartTime (unix timestamp), 
                                // 32 bit high: iboEndTime (unix timestamp)
    uint24 stakingTime;         // 8 bit low: warm-up time, 
                                // 8 bit mid: cool-down time
                                // 8 bit high: time unit (0 - day, 1 - hour, 2 - minute, 3 - second)
    uint32 pricePolicy;         // 16 bit low: price multiplier (fixed point, 2 digits for decimal)
                                // 16 bit high: commission fee in percentage (fixed point, 2 digit for decimal)
    uint128 profitSharing;      // packed of 16bit profit sharing: bot-creator, gov-user, stake-user, and robofi-game
    uint initDeposit;           // the intial deposit (in VICS) of bot-creator
    uint initFounderShare;      // the intial shares (i.e., governance token) distributed to bot-creator
    uint maxShare;              // max cap of gtoken supply
    uint iboShare;              // max supply of gtoken for IBO. Constraint: maxShare >= iboShare + initFounderShare
}

struct BotMetaData {
    string name;
    string symbol;
    string version;
    uint8 botType;
    bool abandoned;
    bool isTemplate;        // determine this module is a template, not a bot instance
    bool initialized;       // determines whether the bot has been initialized 
    address botOwner;       // the public address of the bot owner
    address botManager;
    address botTemplate;    // address of the template contract 
    address gToken;         // address of the governance token
}

struct BotDetail { // represents a detail information of a bot, merely use for bot infomation query
    uint id;                    // the unique id of a bot within its manager.
                                // note: this id only has value when calling {DABotManager.queryBots}
    address botAddress;         // the contract address of the bot.

    BotStatus status;           // 0 - PreIBO, 1 - InIBO, 2 - Active, 3 - Abandonned
    uint8 botType;              // type of the bot (inherits from the bot's template)
    string botSymbol;           // get the bot name.
    string botName;             // get the bot full name.
    address governToken;        // the address of the governance token
    address template;           // the address of the master contract which defines the behaviors of this bot.
    string templateName;        // the template name.
    string templateVersion;     // the template version.
    uint iboStartTime;          // the time when IBO starts (unix second timestamp)
    uint iboEndTime;            // the time when IBO ends (unix second timestamp)
    uint warmup;                // the duration (in days) for which the staking profit starts counting
    uint cooldown;              // the duration (in days) for which users could claim back their stake after submiting the redeem request.
    uint priceMul;              // the price multiplier to calculate the price per gtoken (based on the IBO price).
    uint commissionFee;         // the commission fee when buying gtoken after IBO time.
    uint initDeposit;           
    uint initFounderShare;
    uint144 profitSharing;
    uint maxShare;              // max supply of governance token.
    uint circulatedShare;       // the current supply of governance token.
    uint iboShare;              // the max supply of gtoken for IBO.
    uint userShare;             // the amount of governance token in the caller's balance.
    UserPortfolioAsset[] portfolio;
}

struct BotModuleInfo {
    string name;
    string version;
    address handler;
}

struct PortfolioCreationData {
    address asset;
    uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
    uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
    uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
}

struct PortfolioAsset {
    address certToken;    // the certificate asset to return to stake-users
    uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
    uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
    uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
}

struct UserPortfolioAsset {
    address asset;
    PortfolioAsset info;
    uint256 userStake;
    uint256 totalStake;     // the total stake of all users.
    uint256 certSupply;     // the total supply of the certificated token
}

/**
@dev Records warming-up certificate tokens of a DABot.
*/
struct LockerData {         
    address bot;            // the DABOT which creates this locker.
    address owner;          // the locker owner, who is albe to unlock and get tokens after the specified release time.
    address token;          // the contract of the certificate token.
    uint64 created_at;      // the moment when locker is created.
    uint64 release_at;      // the monent when locker could be unlock. 
}

/**
@dev Provides detail information of a warming-up token lock, plus extra information.
    */
struct LockerInfo {
    address locker;
    LockerData info;
    uint256 amount;         // the locked amount of cert token within this locker.
    uint256 reward;         // the accumulated rewards
    address asset;          // the stake asset beyond the certificated token
}

struct MintableShareDetail {
    address asset;
    uint stakeAmount;
    uint mintableShare;
    uint weight;
    uint iboCap;
}

struct AwardingDetail {
    address asset;
    uint compound;
    uint reward;
    uint compoundMode;  // 0 - increase, 1 - decrrease
}

struct StakingReward {
    address asset;
    uint amount;
}

struct BenefitciaryInfo {
    address account;
    string name;
    string shortName;
    uint weight;
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../../token/IRoboFiERC20.sol";

struct VaultData {
    address botToken;
    IERC20 asset;
    address bot;
    uint8 index;                // the index-th vault generated from botToken
                                //  0 - warmup vault, 1 - regular vault, 2 - VIP vault
    bytes4 vaultType;           // type of the vault, used to determine the vault handler
}

struct UserInfo {
    uint deposit;
    uint debtPoints;
    uint debt;
    uint lockPeriod;
    uint lastDepositTime;
}

struct VaultInfo {
    VaultData data;             
    UserInfo user;
    uint totalDeposit;          // total deposits in the vault
    uint accRewardPerShare;     // the pending reward per each unit of deposit
    uint lastRewardTime;        // the block time of the last reward transaction
    uint pendingReward;         // the pending reward for the caller
    bytes option;               // vault option
} 

struct RegularVaultOption {
    bool restricted;    // restrict deposit activity to bot only
}


interface IBotVaultEvent {
    event Deposit(uint vID, address indexed payor, address indexed account, uint amount);
    event Widthdraw(uint vID, address indexed account, uint amount);
    event RewardAdded(uint vID, uint assetAmount);
    event Snapshot(uint vID, uint snapshotId);
}

interface IBotVault is IBotVaultEvent {
    function deposit(uint vID, uint amount) external;
    function delegateDeposit(uint vID, address payor, address account, uint amount, uint lockTime) external;
    function withdraw(uint vID, uint amount) external;
    function delegateWithdraw(uint vID, address account, uint amount) external;
    function pendingReward(uint vID, address account) external view returns(uint);
    function balanceOf(uint vID, address account) external view returns(uint);
    function balanceOfAt(uint vID, address account, uint blockNo) external view returns(uint);
    function updateReward(uint vID, uint assetAmount) external;
    function claimReward(uint vID, address account) external;

    /**
    @dev Queries user deposit info for the given vault.
    @param vID the vault ID to query.
    @param account the user account to query.
     */
    function getUserInfo(uint vID, address account) external view returns(UserInfo memory result);
    function getVaultInfo(uint vID, address account) external view returns(VaultInfo memory);
    function getVaultOption(uint vID) external view returns(bytes memory);
    function setVaultOption(uint vID, bytes calldata option) external;
}

interface IBotVaultManagerEvent is IBotVaultEvent {
    event OpenVault(uint vID, VaultData data);
    event DestroyVault(uint vID);
    event RegisterHandler(bytes4 vaultType, address handler);
    event BotManagerUpdated(address indexed botManager);
}

interface IBotVaultManager is IBotVault, IBotVaultManagerEvent {
    function vaultOf(uint vID) external view returns(VaultData memory result);
    function validVault(uint vID) external view returns(bool);
    function createVault(VaultData calldata data) external returns(uint);
    function destroyVault(uint vID) external;
    function vaultId(address botToken, uint8 vaultIndex) external pure returns(uint);
    function registerHandler(bytes4 vaultType, IBotVault handler) external;
    function botManager() external view returns(address);
    function setBotManager(address account) external;
    function snapshot(uint vID) external;
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../common/Errors.sol";
////import "../common/Ownable.sol";
////import "../common/IConfigurator.sol";
////import "./IGovernance.sol";
////import "./IVoteStrategy.sol";

struct Vote {
    uint power;
    bool support;
}

struct Proposal { 
    ProposalMeta meta;
    IVoteStrategy strategy;   // the address of the strategy to determine voting power of an account
    mapping(address => Vote) votes;
}


library GovernanceLib {

    uint constant HUNDRED_PERCENT = 10000;

    function isValid(Proposal storage p) internal view returns(bool) {
        return p.meta.proposalId > 0 && address(p.strategy) != address(0);
    }

    function totalVotePower(Proposal storage p) internal view returns(uint) {
        return p.strategy.totalVotePower(p.meta.target, p.meta.blockNo);
    }

    function votePower(Proposal storage p, address account) internal view returns(uint) {
        return p.strategy.votePower(p.meta.target, p.meta.blockNo, account);
    }

    function state(Proposal storage p) internal view returns(ProposalState) {
        uint64 current = uint64(block.timestamp);
        if (current < p.meta.startedAt)
            return ProposalState.Pending;
        if (p.meta.state != ProposalState.Auto)
            return p.meta.state;
        if (current < p.meta.endedBy)
            return ProposalState.Voting;
        return ProposalState.Failed;
    }

    function validQuorum(Proposal storage p) internal view returns(bool) {
        return validQuorum(p, p.strategy.totalVotePower(p.meta.target, p.meta.blockNo));
    }

    function validQuorum(Proposal storage p, uint totalVotes) internal view returns(bool) {
        return p.meta.forVotes * HUNDRED_PERCENT / totalVotes >= p.strategy.minQuorum(p.meta.target);
    }

    function validVoteDifferential(Proposal storage p) internal view returns(bool) {
        return validVoteDifferential(p, p.strategy.totalVotePower(p.meta.target, p.meta.blockNo));
    }

    function validVoteDifferential(Proposal storage p, uint totalVotes) internal view returns(bool) {
        uint forPercent = p.meta.forVotes * HUNDRED_PERCENT / totalVotes;
        uint againstPercent = p.meta.againstVotes * HUNDRED_PERCENT / totalVotes;
        return forPercent >= againstPercent + p.strategy.voteDifferential(p.meta.target);
    }

    function isPassedProposal(Proposal storage p) internal view returns(bool) {
        uint totalVotes = p.strategy.totalVotePower(p.meta.target, p.meta.blockNo);
        return validQuorum(p, totalVotes) && validVoteDifferential(p, totalVotes);
    }

    function isOffchainProposal(Proposal storage p) internal view returns(bool) {
        return p.meta.targets.length == 0;
    }
}



/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
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
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "./IBotVault.sol";
////import "../DABotCommon.sol";
////import "../../common/IRoboFiFactory.sol";
////import "../../common/IConfigurator.sol";

interface IDABotManagerEvent {
    event BotRemoved(address indexed bot);
    event BotDeployed(uint botId, address indexed bot, BotDetail detail); 
    event TemplateRegistered(address indexed template, string name, string version, uint8 templateType);
}

interface IDABotManager is IDABotManagerEvent {
    
    function configurator() external view returns(IConfigurator);
    function vaultManager() external view returns(IBotVaultManager);
    function addTemplate(address template) external;
    function templates() external view returns(address[] memory);
    function isRegisteredTemplate(address template) external view returns(bool);
    function isRegisteredBot(address botAccount) external view returns(bool);
    function totalBots() external view returns(uint);
    function botIdOf(string calldata qualifiedName) external view returns(int);
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output);
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external;
    function snapshot(address botAccount) external;
}




/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


/** 
 *  SourceUnit: d:\Snap\marketplace\robofi-contracts-core\contracts\voting\Governance.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/proxy/utils/initializable.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "../dabot/interfaces/IDABotManager.sol";
////import "../common/Errors.sol";
////import "../common/Ownable.sol";
////import "../common/IConfigurator.sol";
////import "./IGovernance.sol";
////import "./IVoteStrategy.sol";
////import "./ITimelockExecutor.sol";
////import "./GovernanceLib.sol";

contract Governance is Ownable, IGovernanceEvent, Initializable {
    using GovernanceLib for Proposal;

    IConfigurator public config;
    IERC20 public vics;

    address private _guardian;
    uint256 private _proposalCount;
    mapping(uint256 => Proposal) _proposals;
    mapping(address => IVoteStrategy) _strategies;
    IVoteStrategy public defaultStrategy;
    ITimelockExecutor public executor;

    uint256 constant HUNDRED_PERCENT = 10000;

    /// Target should be either 0x0 or account of a DABot
    modifier validTarget(address target) {
        if (target != address(0)) {
            require(
                _botManager().isRegisteredBot(target),
                Errors.GOV_TARGET_SHOULD_BE_ZERO_OR_REGISTERED_BOT
            );
        }
        _;
    }

    modifier validProposalId(uint256 id) {
        require(_proposals[id].isValid(), Errors.GOV_INVALID_PROPOSAL_ID);
        _;
    }

    modifier votingProposal(uint256 id) {
        Proposal storage p = _proposals[id];
        require(p.isValid(), Errors.GOV_INVALID_PROPOSAL_ID);
        require(
            p.state() == ProposalState.Voting,
            Errors.GOV_PROPOSAL_DONT_ACCEPT_VOTE
        );
        _;
    }

    modifier onlyOperator() {
        // TODO: check for operator role in configurator
        _;
    }

    function initialize(IConfigurator _config) external payable initializer {
        _transferOwnership(_msgSender());
        setConfigProvider(_config);
    }

    function setDefaultStrategy(IVoteStrategy strategy) external onlyOwner {
        defaultStrategy = strategy;
        emit DefaultStrategyChanged(address(strategy));
    }

    function setVoteStrategy(address target, IVoteStrategy strategy) external onlyOwner {
        _strategies[target] = strategy;
        emit StrategyChanged(target, address(strategy));
    }

    function setExecutor(ITimelockExecutor _executor) public onlyOwner {
        executor = _executor;
        emit ExecutorChanged(address(_executor));
    }

    function setConfigProvider(IConfigurator _config) public onlyOwner {
        config = _config;
        vics = IERC20(_config.addressOf(AddressBook.ADDR_VICS));
        require(address(vics) != address(0), Errors.GOV_INVALID_VICS_ADDRESS);
    }

    function getProposalById(uint proposalId) external view returns(ProposalMeta memory p) {
        p = _proposals[proposalId].meta;
        p.state = _proposals[proposalId].state();
    }

     function getStrategy(address target) public view returns (IVoteStrategy strategy) {
        strategy = _strategies[target];
        if (address(strategy) == address(0) && _botManager().isRegisteredBot(target)) 
            strategy = defaultStrategy;
    }

    function createProposal(
        string memory title,
        address target,
        bytes32 contentHash,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory args,
        bool[] memory delegateCalls
    ) external validTarget(target) returns (uint256) {
        require(
            targets.length == values.length &&
                values.length == signatures.length &&
                values.length == args.length &&
                values.length == delegateCalls.length,
            Errors.GOV_INVALID_CREATION_DATA
        );

        _proposalCount++;
        Proposal storage p = _proposals[_proposalCount];
        p.strategy = _getStrategy(target);
        p.meta.target = target;
        p.meta.blockNo = block.number;

        uint power = p.votePower(msg.sender);
        uint proposalCreationFee = p.strategy.creationFee(target);

        require(
            power * HUNDRED_PERCENT / p.totalVotePower() >= p.strategy.minPower(target),
            Errors.GOV_INSUFFICIENT_POWER_TO_CREATE_PROPOSAL
        );
        require(
            vics.balanceOf(msg.sender) >= proposalCreationFee,
            Errors.GOV_INSUFFICIENT_VICS_TO_CREATE_PROPOSAL
        );

        vics.transferFrom(msg.sender, address(this), proposalCreationFee);
        uint256 duration = p.strategy.duration(target);

        p.meta = ProposalMeta(
            _proposalCount,
            ProposalState.Auto,
            uint64(block.timestamp),
            uint64(block.timestamp + duration),
            0,
            contentHash,
            target,
            msg.sender,
            block.number,
            0,
            0,
            targets,
            values,
            signatures,
            args,
            delegateCalls
        );
        p.strategy.snapshot(target);
        _emitProposal(p, title);      
        _vote(p, msg.sender, power, true);
        return p.meta.proposalId;
    }

    function _emitProposal(Proposal storage p, string memory title) private {
        emit NewProposal( 
            p.meta.proposalId,
            title,
            p.meta.startedAt,
            p.meta.endedBy,
            p.meta.target,
            msg.sender,
            p.meta.contentHash
        );
    }

    function cancelProposal(uint256 proposalId)
        external
        validProposalId(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(
            msg.sender == p.meta.proposer || msg.sender == _guardian,
            Errors.GOV_REQUIRED_PROPOSER_OR_GUARDIAN
        );
        require(
            p.meta.state == ProposalState.Auto ||
                p.meta.state == ProposalState.Queued
        );

        _updateState(p, ProposalState.Canceled, bytes(''));
    }

    function vote(uint256 proposalId, bool support)
        public
        votingProposal(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(p.votes[msg.sender].power == 0, Errors.GOV_DUPLICATED_VOTE);

        uint256 power = p.votePower(msg.sender);
        require(power > 0, Errors.GOV_INSUFFICIENT_POWER_TO_VOTE);
        _vote(p, msg.sender, power, support);
    }

    function _vote(Proposal storage p, address account, uint power, bool support) private {
        p.votes[account].power = power;
        p.votes[account].support = support;

        bool passed = false;
        if (support) {
            p.meta.forVotes += power;
            passed = p.isPassedProposal();
        } else p.meta.againstVotes += power;
        emit Vote(account, p.meta.proposalId, power, support);
        if (passed) _updateState(p, ProposalState.Passed, bytes(''));
    }

    function unvote(uint256 proposalId) external votingProposal(proposalId) {
        Proposal storage p = _proposals[proposalId];
        uint256 currentPower = p.votes[msg.sender].power;
        if (currentPower == 0) return;

        if (p.votes[msg.sender].support) {
            p.meta.forVotes -= currentPower;
        } else p.meta.againstVotes -= currentPower;
        delete p.votes[msg.sender];
        emit Unvote(msg.sender, proposalId);
    }

    function updateState(uint256 proposalId, ProposalState state)
        external
        validProposalId(proposalId)
        onlyOperator
    {
        Proposal storage p = _proposals[proposalId];
        require(
            p.isOffchainProposal(),
            Errors.GOV_CANNOT_CHANGE_STATE_OF_ON_CHAIN_PROPOSAL
        );

        ProposalState currentState = p.state();
        require(
            state == ProposalState.Queued || state == ProposalState.Executed,
            Errors.GOV_INVALID_NEW_STATE
        );
        if (state == ProposalState.Queued)
            require(
                currentState == ProposalState.Passed,
                Errors.GOV_CANNOT_CHANGE_STATE_OF_CLOSED_PROPOSAL
            );
        if (state == ProposalState.Executed)
            require(
                currentState == ProposalState.Queued ||
                    currentState == ProposalState.Passed,
                Errors.GOV_CANNOT_CHANGE_STATE_OF_CLOSED_PROPOSAL
            );
        _updateState(p, state, bytes(''));
    }

    function queueProposal(uint256 proposalId)
        external
        validProposalId(proposalId)
    {
        Proposal storage p = _proposals[proposalId];
        require(
            p.state() == ProposalState.Passed,
            Errors.GOV_CAN_ONLY_QUEUE_PASSED_PROPOSAL
        );

        uint256 executionTime = block.timestamp + executor.getDelay();
        for (uint256 i = 0; i < p.meta.targets.length; i++) {
            _queueOrRevert(
                p.meta.targets[i],
                p.meta.values[i],
                p.meta.signatures[i],
                p.meta.args[i],
                executionTime,
                p.meta.delegateCalls[i]
            );
        }
        p.meta.executionTime = uint64(executionTime);
        _updateState(p, ProposalState.Queued, abi.encode(executionTime));
    }

    function executeProposal(uint256 proposalId)
        external
        payable
        validProposalId(proposalId)
    {
        Proposal storage proposal = _proposals[proposalId];
        for (uint256 i = 0; i < proposal.meta.targets.length; i++) {
            executor.executeTransaction{
                value: proposal.meta.values[i]
            }(
                proposal.meta.targets[i],
                proposal.meta.values[i],
                proposal.meta.signatures[i],
                proposal.meta.args[i],
                proposal.meta.executionTime,
                proposal.meta.delegateCalls[i]
            );
        }
        _updateState(proposal, ProposalState.Executed, bytes(''));
    }

    function _updateState(Proposal storage p, ProposalState state, bytes memory data) private {
        p.meta.state = state;
        emit StateChanged(p.meta.proposalId, state, data); 
    }

    function _getStrategy(address target) private view returns (IVoteStrategy strategy) {
        strategy = getStrategy(target);
        require(
            address(strategy) != address(0),
            Errors.GOV_DEFAULT_STRATEGY_IS_NOT_SET
        );
    }

    function _botManager() private view returns (IDABotManager) {
        return IDABotManager(config.addressOf(AddressBook.ADDR_BOT_MANAGER));
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory callData,
        uint256 executionTime,
        bool withDelegatecall
    ) internal {
        require(
            !executor.isActionQueued(
                keccak256(
                    abi.encode(
                        target,
                        value,
                        bytes4(keccak256(bytes(signature))),
                        callData,
                        executionTime,
                        withDelegatecall
                    )
                )
            ),
            Errors.GOV_DUPLICATED_ACTION
        );
        executor.queueTransaction(
            target,
            value,
            signature,
            callData,
            executionTime,
            withDelegatecall
        );
    }
}