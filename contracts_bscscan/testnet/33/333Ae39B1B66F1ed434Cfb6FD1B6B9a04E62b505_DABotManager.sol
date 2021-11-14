// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoboFiFactory {
    function deploy(address masterContract, 
                    bytes calldata data, 
                    bool useCreate2) 
        external 
        payable 
        returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDABot.sol";

struct BotRepository {
    IDABot[] bots;
    mapping(address => uint) botIndex;   // mapping a bot's address to 1-based bot index
    mapping(bytes32 => uint) qfnIndex;   // mapping a bot's qualified name to 1-based bot index
}

library BotRepositoryLib {

    function indexOf(BotRepository storage repo, address bot) internal view returns(uint result) {
        result = repo.botIndex[bot];
        if (result > repo.bots.length)
            result = 0;
    }

    function indexOfQFN(BotRepository storage repo, string memory qualifiedName) internal view returns(uint result) {       
        result = repo.qfnIndex[keccak256(abi.encodePacked(qualifiedName))];
        if (result > repo.bots.length)
            result = 0;
    }

    function addBot(BotRepository storage repo, IDABot bot) internal {
        require(indexOf(repo, address(bot)) == 0, 'BotRepo: bot existed');
        repo.bots.push(bot);
        _updateBotIndex(repo, bot, repo.bots.length);
    }

    function removeBot(BotRepository storage repo, IDABot bot) internal {
        uint idx = indexOf(repo, address(bot));
        require(idx > 0, 'BotRepo: bot not found');
        idx--;  // convert 1-based to 0-based index
        uint lastIdx = repo.bots.length - 1;
        if (idx < lastIdx) {
            IDABot lastBot = repo.bots[lastIdx];
            repo.bots[idx] = lastBot;
            _updateBotIndex(repo, lastBot, idx);
        }
        repo.bots.pop();
    }

    function clear(BotRepository storage repo) internal {
        delete repo.bots;
    }

    function _updateBotIndex(BotRepository storage repo, IDABot bot, uint index) private {
        repo.botIndex[address(bot)] = index;
        repo.qfnIndex[keccak256(abi.encodePacked(bot.qualifiedName()))] = index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/proxy/utils/initializable.sol";
import "../token/IRoboFiERC20.sol";
import "../common/Ownable.sol";
import "../common/IConfigurator.sol";
import "../common/Errors.sol";

import "./DABotCommon.sol"; 
import "./interfaces/IDABotManager.sol"; 
import "./interfaces/IDABot.sol"; 
import "./interfaces/IBotVault.sol";
import "./BotRepository.sol"; 

contract DABotManager is Context, Ownable, Initializable, IDABotManagerEvent {

    using BotRepositoryLib for BotRepository;
    using ERC165Checker for address;

    BotRepository private botRepo;
    BotRepository private templateRepo;
    
    IConfigurator internal _configurator;
    IBotVaultManager public immutable vaultManager;

    modifier supportIDABot(address account) {
        require(account.supportsInterface(type(IDABot).interfaceId), Errors.BM_DOES_NOT_SUPPORT_IDABOT);
        _;
    }

    constructor(IBotVaultManager vault) {
        vaultManager = vault;
    }

    function initialize(IConfigurator configuratorProvider) external payable initializer {
        _transferOwnership(_msgSender());
        _configurator = configuratorProvider;
        
    }

    function setConfigurator(IConfigurator provider) external onlyOwner {
        _configurator = provider;
    }

    function configurator() external view returns(IConfigurator) {
        return _configurator;
    }
   
    function totalBots() external view returns(uint) {
        return botRepo.bots.length;
    }

    /**
    @dev Registers a DABot template (i.e., master contract). 
    Registered template cannot be removed.
     */
    function addTemplate(address template) public supportIDABot(template) onlyOwner {
        templateRepo.addBot(IDABot(template));
        BotMetaData memory metadata = IDABot(template).metadata();

        emit TemplateRegistered(template, metadata.name, metadata.version, metadata.botType); 
    }

    /**
    @dev Retrieves a list of registered DABot templates.
     */
    function templates() external view returns(IDABot[] memory) {
        return templateRepo.bots;
    }

    /**
    @dev Determine whether an address is a registered bot template.
     */
    function isRegisteredTemplate(address template) external view returns(bool) {
        return templateRepo.indexOf(template) > 0;
    } 

    function isRegisteredBot(address account) public view returns(bool) {
        return botRepo.indexOf(account) > 0;
    }

    function removeBots(address[] calldata bots) external onlyOwner {
        for(uint i = 0; i < bots.length; i ++) {
            botRepo.removeBot(IDABot(bots[i]));
            emit BotRemoved(bots[i]);
        }
    }


    /**
    @dev Deploys a bot for a given template.

    params:
        `template`  : address of the master contract containing the logic of the bot
        `name`      : name of the bot
        `setting`   : various settings of the bot. See {sol\DABot.BotSetting}
     */
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external returns(uint botId, address bot) {

        string memory qualifiedName = string(abi.encodePacked(symbol, ":", name)); 

        require(botRepo.indexOfQFN(qualifiedName) == 0, Errors.BM_DUPLICATED_BOT_QUALIFIED_NAME);
        require(templateRepo.indexOf(template) > 0, Errors.BM_TEMPLATE_IS_NOT_REGISTERED);

        IRoboFiFactory factory = IRoboFiFactory(_configurator.addressOf(AddressBook.ADDR_FACTORY));
        IRoboFiERC20 vics = IRoboFiERC20(_configurator.addressOf(AddressBook.ADDR_VICS));

        require(address(factory) != address(0), Errors.CM_FACTORY_ADDRESS_IS_NOT_CONFIGURED);
        require(address(vics) != address(0), Errors.CM_VICS_ADDRESS_IS_NOT_CONFIGURED);

        BotMetaData memory meta = BotMetaData(name, symbol, '', 0, false, false, false, 
            _msgSender(), address(this), template, address(0));

        bot = factory.deploy(template, abi.encode(meta, initData), true);

        IDABot daBot = IDABot(bot);

        BotSetting memory setting = daBot.setting();
        meta = daBot.metadata();

        require(meta.gToken != address(0), Errors.BM_GOVERNANCE_TOKEN_IS_NOT_DEPLOYED);

        vics.transferFrom(_msgSender(), meta.gToken, setting.initDeposit); 
        botRepo.addBot(daBot);
        daBot.createPortfolioVaults();
        daBot.createGovernVaults();

        emit BotDeployed(botId, bot, daBot.botDetails());
    }

    /**
    @dev Gets the bot id for the specified bot name. Returns -1 if no bot found.
     */
    function botIdOf(string calldata qualifiedName) external view returns(int) {
        return int(botRepo.indexOfQFN(qualifiedName)) - 1; 
    }
    
    /**
    @dev Queries details information for a list of bot Id.
     */
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output) {
        output = new BotDetail[](botId.length);
        for(uint i = 0; i < botId.length; i++) {
            if (botId[i] >= botRepo.bots.length) continue;
            IDABot bot = botRepo.bots[botId[i]];
            output[i] = bot.botDetails();
            output[i].id = botId[i];
        }
    }

    function snapshot(address botAccount) external {
        require(isRegisteredBot(botAccount), Errors.BM_BOT_IS_NOT_REGISTERED);
        IDABot(botAccount).snapshot();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/IRoboFiERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 
import "./IDABotController.sol";
import "./IDABotSettingModule.sol";
import "./IDABotStakingModule.sol";
import "./IDABotGovernModule.sol";
import "./IDABotFundManagerModule.sol";

interface IDABot is IDABotController, 
    IDABotSettingModule, 
    IDABotStakingModule, 
    IDABotGovernModule, 
    IDABotFundManagerModule 
{
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotCertTokenEvent {
    /**
    @dev Triggered when the bot owner locked an amount of certificate token for trading (or yield farming).
    @param assetAmount the amount of the underlying asset locked.
     */
    event Lock(uint assetAmount);

    /**
    @dev Triggered when the bot owner unlocked an amount of certificate token.
    @param assetAmount the amount of the underlying asset unlocked.
     */
    event Unlock(uint assetAmount);

    /**
    @dev Triggered when the amount of pegged assets of this certificate token has been changed.
    @param amount the changed amount.
    @param profitOrLoss true if the the pegged assets increase, false on otherwise.
     */
    event Compound(uint amount, bool profitOrLoss);
}

interface IDABotCertToken is IERC20, IDABotCertTokenEvent {

    /**
    @dev Gets the total deposit of the underlying asset within this certificate.
     */
    function totalStake() external view returns(uint);

    function totalLiquid() external view returns(uint);

    /**
    @dev Queries the bot who owned this certificate.
     */
    function owner() external view returns(address);
    
    /**
    @dev Gets the underlying asset of this certificate.
     */
    function asset() external view returns (IERC20);
    
    /**
    @dev Returns the equivalent amount of the underlying asset for the given amount
        of certificate tokens.
    @param certTokenAmount - the amount of certificate tokens.
     */
    function value(uint certTokenAmount) external view returns(uint);

    function lock(uint assetAmount) external;

    function unlock(uint assetAmount) external;

    /**
    @dev Mints an amount of certificate tokens to the given amount. The equivalent of
        underlying asset should be tranfered to this certificate contract by the caller.
    @param account - the address to recieve minted tokens.
    @param certTokenAmount - the amount of tokens to mint.
    @notice Only the owner bot can call this function.
     */
    function mint(address account, uint certTokenAmount) external returns(uint);

    /**
    @dev Burns an amount of certificate tokens, and returns the equivalant amount of
        the underlying asset to the specified account.
    @param account - the address holing certificate tokens to burn.
    @param certTokenAmount - the amount of certificate token to burn.
    @return the equivalent amount of underlying asset tranfered to the specified account.
    @notice Only the owner bot can call this function.
     */
    function burn(address account, uint certTokenAmount) external returns (uint);

    /**
    @dev Burns an amount of certificate tokens, and returns the equivalent amount of the 
        underlying asset to the caller.
    @param amount - the amount of certificate token to burn.
    @return the equivalent amount of underlying asset transfered to the caller.
     */
    function burn(uint amount) external returns(uint);

    /**
    @dev Burns an amount of certificate tokens without returning any underlying assets.
    @param account - the account holding certificate tokens to burn.
    @param amount - the amount of certificate tokens to burn.
    @notice Only owner bot can call this function.
     */
    function slash(address account, uint amount) external;

    /**
    @dev Compound a given amount of the underlying asset to the total deposit. 
        The compoud could be either profit or loss.
    @param amount - the compound amount.
    @param profitOrLoss - `true` to increase the total deposit, `false` to decrease.
     */
    function compound(uint amount, bool profitOrLoss) external;

    /**
    @dev Deletes this certificate token contracts.
     */
    function finalize() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 

interface IDABotControllerEvent {
    event BotAbandoned(bool value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ModuleHandlerChanged(bytes32 moduleId, address indexed oldModuleAddress, address indexed newModuleAddress);
    event ModuleRegistered(bytes32 moduleId, address indexed moduleAddress, string name, string version);
}

/**
@dev The generic interface of a DABot.
 */
interface IDABotController is IDABotControllerEvent {
    function abandon(bool value) external;
    function modulesInfo() external view returns(BotModuleInfo[] memory result);
    function governToken() external view returns(address);
    function qualifiedName() external view returns(string memory);
    function metadata() external view returns(BotMetaData memory);
    function setting() external view returns(BotSetting memory);
    function botDetails() view external returns(BotDetail memory);
    function updatePortfolio(address asset, uint maxCap, uint iboCap, uint weight) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";

bytes32 constant IDABotFundManagerModuleID = keccak256('fundmanager.module');

interface IDABotFundManagerModuleEvent {
    event Award(AwardingDetail[] pnl, uint[] totalStakes, uint[] certTokenValues);
    event AwardCompound(address indexed asset, uint amount, uint mode);
    event AwardBenefitciary(address indexed benefitciary, address indexed portfolioAsset, address indexed awardedAsset, uint amount, uint share, uint totalShare);
    event AddBenefitciary(address indexed benefitciary);
}

interface IDABotFundManagerModule is IDABotFundManagerModuleEvent {
    
    /**
    @dev Gets detailed information about benefitciaries of staking rewards.
     */
    function benefitciaries() external view returns(BenefitciaryInfo[] memory result);

    /**
    @dev Replaces the current bot's benefitciaries with its bot template's
    @notice Only bot owner can call.
     */
    function resetBenefitciaries() external; 

    /**
    @dev Add new benefitciary
    @param benefitciary - the benefitciary address. Should not be added before.
     */
    function addBenefitciary(address benefitciary) external;

    /**
     @dev Add profit/loss for each asset in the portfolio.
     @param pnl - list of AwardingDetail data.
     */
    function award(AwardingDetail[] calldata pnl) external;

    /**
    @dev Checks the pending stake rewarod of a given account for specified assets.
    @param account - the account to check.
    @param assets - the list of assets to check for reward. 
        If empty list is passed, all assets in the portfolio are checked.
    @param subVaults - the list of sub-vaults to check. 
        If empty list is passed, all sub vaults (i.e., [0, 1, 2]) are checked.
     */
    function pendingStakeReward(address account, address[] calldata assets, 
        bytes calldata subVaults) external view returns(StakingReward[] memory);

    /**
    @dev Checks the pending governance rewardsof a given account.
    @param account - the account to check.
    @param subVaults - the lst oof sub-vaults to check. 
        if empty list is passed, all sub vaults (i.e., [0, 1]) are checked.
     */
    function pendingGovernReward(address account, bytes calldata subVaults) external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";
import "../interfaces/IBotVault.sol";

bytes32 constant IDABotGovernModuleID = keccak256('governance.module');

interface IDABotGovernModuleEvent {
    
}

interface IDABotGovernModule {

    /**
    @dev Creates staking vaults for governance tokens. This method should be called
        internally only by the bot manager.
     */
    function createGovernVaults() external;

    /**
    @dev Gets the vaults of governance tokens.
    @param account - the account to query depsot/reward information
     */
    function governVaults(address account) external view returns(VaultInfo[] memory);

    /**
    @dev Claims all pending governance rewards in all vaults.
     */
    function harvestGovernanceReward() external;

    /**
    @dev Queries the total pending governance rewards in all vaults
    @param account - the account to query.
     */
    function governanceReward(address account) external view returns(uint);

    /**
    @dev Gets the maximum amount of gToken that an account could mint from a bot.
    @param account - the account to query.
    @return the total mintable amount of gToken.
     */
    function mintableShare(address account) external view returns(uint);

    /** 
    @dev Gets the details accounting for the amount of mintable shares.
    @param account the account to query
    @return an array of MintableShareDetail strucs.
     */
    function iboMintableShareDetail(address account) external view returns(MintableShareDetail[] memory); 

    /**
    @dev Calculates the output for an account who mints shares with the given VICS amount.
    @param account - the account to query
    @param vicsAmount - the amount of VICS used to mint shares.
    @return payment - the amount of VICS for minting shares.
            shares - the amount of shares mintied.
            fee - the amount of VICS for minting fee. 
     */
    function calcOutShare(address account, uint vicsAmount) external view returns(uint payment, uint shares, uint fee);

    /**
    @dev Get the total balance of shares owned by the specified account. The total includes
        shares within the account's wallet, and shares staked in bot's vaults.
    @param account - the account to query.
    @return the number of shares.
     */
    function shareOf(address account) external view returns(uint);

    /**
    @dev Mints shares for the given VICS amount. Minted shares will directly stakes to BotVault for rewards.
    @param vicsAmount - the amount of VICS used to mint shared.
    @notice
        Minted shares during IBO will be locked in separated pool, which onlly allow users to withdraw
        after 1 month after the IBO ends.

        VICS for payment will be kept inside the share contracts. Whereas, VICS for fee are transfered
        to the tax address, configured in the platform configurator.
     */
    function mintShare(uint vicsAmount) external;

    /**
    @dev Burns an amount of gToken and sends the corresponding VICS to caller's wallet.
    @param amount - the amount of gToken to burn.
     */
    function burnShare(uint amount) external;

    /**
    @dev Takes a snapshot of current vote powers (i.e. amount of gov)
     */
    function snapshot() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBotVault.sol";
import "../DABotCommon.sol";
import "../../common/IRoboFiFactory.sol";
import "../../common/IConfigurator.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";

bytes32 constant IDABotSettingModuleID = keccak256('setting.module');

interface IDABotSettingModuleEvent {
    event SettingChanged(uint what, BotSetting setting);  
    event AddressWritten(bytes32 itemId, address indexed value);
    event UintWritten(bytes32 itemId, uint value);
    event BytesWritten(bytes32 itemId, bytes value);
}

interface IDABotSettingModule is IDABotSettingModuleEvent {   
    function status() external view returns(uint);
    function iboTime() external view returns(uint startTime, uint endTime);
    function stakingTime() external view returns(uint warmup, uint cooldown, uint unit);
    function pricePolicy() external view returns(uint priceMul, uint commission);
    function profitSharing() external view returns(uint128);
    function setIBOTime(uint startTime, uint endTime) external;
    function setStakingTime(uint warmup, uint cooldown, uint unit) external;
    function setPricePolicy(uint priceMul, uint commission) external;
    function setProfitSharing(uint sharingScheme) external;

    function readAddress(bytes32 itemId, address defaultAddress) external view returns(address);
    function readUint(bytes32 itemId, uint defaultValue) external view returns(uint);
    function readBytes(bytes32 itemId, bytes calldata defaultValue) external view returns(bytes memory);

    function writeAddress(bytes32 itemId, address value) external;
    function writeUint(bytes32 itemId, uint value) external;
    function writeBytes(bytes32 itemId, bytes calldata value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDABotCertToken.sol";
import "../DABotCommon.sol";
import "../interfaces/IBotVault.sol";

bytes32 constant IDABotStakingModuleID = keccak256("staking.module");

interface IDABotStakingModuleEvent {
     event PortfolioUpdated(address indexed asset, address indexed certToken, uint maxCap, uint iboCap, uint weight);
     event AssetRemoved(address indexed asset, address indexed certToken);   
     event Stake(address indexed asset, uint amount, address indexed certToken, uint certAmount, address indexed locker);
     event Unstake(address indexed certToken, uint certAmount, address indexed asset, 
          uint assetAmount, address indexed locker, uint releaseTime);
}

interface IDABotStakingModule is IDABotStakingModuleEvent {

     /**
     @dev Gets the detailed information of the bot's portfolio.
     @return the arrays of UserPortfolioAsset struct.
      */
     function portfolioDetails() external view returns(UserPortfolioAsset[] memory);

     /**
     @dev Gets the portfolio information for the given asset.
     @param asset - the asset to query.
      */
     function portfolioOf(address asset) external view returns(UserPortfolioAsset memory);

     /**
     @dev Adds or update an asset in the bot's portfolio.
     @param asset - the crypto asset to add/update in the portfolio.
     @param maxCap - the maximum amount of crypto asset to stake to the bot.
     @param iboCap - the maximum amount of crypto asset to stake during the bot's IBO.
     @param weight - the preference index of an asset in the portfolio. This is used
               to calculate the mintable amount of governance shares in accoardance to 
               staked amount. 

               Gven the same USD-worth amount of two assets, the one with higher weight 
               will contribute more to the mintable amount of shares than the other.
      */
     function updatePortfolioAsset(address asset, uint maxCap, uint iboCap, uint weight) external;

     /**
     @dev Removes an asset from the bot's portfolio.
     @param asset - the crypto asset to remove.
     @notice asset could only be removed before the IBO. After that, asset could only be
               remove if there is no tokens of this asset staked to the bot.
      */
     function removePortfolioAsset(address asset) external;

     /**
     @dev Creates vaults for each asset in the portfolio. This method should be called 
          internally by the bot manager.
      */
     function createPortfolioVaults() external;

     /**
     @dev Gets the vaults of certificate tokens in the portfolio.
     @param certToken the certificate token.
     @param account the account to query deposit/reward information
      */
     function certificateVaults(address certToken, address account) external view returns(VaultInfo[] memory);

     /**
     @dev Queries the total staking reward of the specific certificate token of the given account
     @param certToken the certificate token.
     @param account the account to query.
      */
     function stakingReward(address certToken, address account) external view returns(uint);

     /**
     @dev Claims all pending staking rewards of the callers.
      */
     function harvestStakingReward() external; 

     /**
     @dev Moves certificate tokens staked in warm-up vault to regular vault.
          If the tokens are locked, the operation will be reverted.
      */
     function upgradeVault(address certToken) external;

     /**
     @dev Gets the maximum amount of crypto asset that could be staked  to the bot.
     @param asset - the crypto asset to check.
     @return the maximum amount of crypto asset to stake.
      */
     function getMaxStake(address asset) external returns(uint);

     /**
     @dev Stakes an amount of crypto asset to the bot to receive staking certificate tokens.
     @param asset - the asset to stake.
     @param amount - the amount to stake.
      */
     function stake(address asset, uint amount) external;

     /**
     @dev Burns an amount of staking certificates to get back underlying asset.
     @param certToken - the certificate to burn.
     @param amount - the amount to burn.
      */
     function unstake(IDABotCertToken certToken, uint amount) external;

     /**
     @dev Gets the total staking balance of an account for the specific asset.
          The balance includes pending stakes (i.e., warmup) and excludes 
          pending unstakes (i.e., cooldown)
     @param account - the account to query.
     @param asset - the crypto asset to query.
     @return the total staked amount of the asset.
      */
     function stakeBalanceOf(address account, address asset) external view returns(uint);

     /**
     @dev Gets the total pending stake balance of an account for the specific asset.
     @param account - the account to query.
     @param asset - the asset to query.
     @return the total pending stake.
      */
     function warmupBalanceOf(address account, address asset) external view returns(uint);

     /**
     @dev Gets to total pending unstake balance of an account for the specific certificate.
     @param account - the account to query.
     @param certToken - the certificate token to query.
     @return the total pending unstake.
      */
     function cooldownBalanceOf(address account, address certToken) external view returns(uint);

     /**
     @dev Gets the certificate contract of an asset of a bot.
     @param asset - to crypto asset to query.
     @return the address of the certificate contract.
      */
     function certificateOf(address asset) external view returns(address);

     /**
     @dev Gets the underlying asset of a certificate.
     @param certToken - the address of the certificate contract.
     @return the address of the underlying crypto asset.
      */
     function assetOf(address certToken) external view returns(address);

     /**
     @dev Determines whether an account is a certificate locker.
     @param account - the account to check.
     @return true - if the account is an certificate locker instance creatd by the bot.
      */
     function isCertLocker(address account) external view returns(bool);

     /**
     @dev Gets the details of lockers for pending stake.
     @param account - the account to query.
     @return the array of LockerInfo struct.
      */
     function warmupDetails(address account) external view returns(LockerInfo[] memory);

     /**
     @dev Gets the details of lockers for pending unstake.
     @param account - the account to query.
     @return the array of LockerInfo struct.
      */
     function cooldownDetails(address account) external view returns(LockerInfo[] memory);

     /**
     @dev Releases tokens in all pending stake lockers. 
     @notice At most 20 lockers are unlocked. If the caller has more than 20, additional 
          transactions are required.
      */
     function releaseWarmups() external;

     /**
     @dev Releases token in all pending unstake lockers.
     @notice At most 20 lockers are unlocked. If the caller has more than 20, additional 
          transactions are required.
      */
     function releaseCooldowns() external;

     
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoboFiERC20 is IERC20 {
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}