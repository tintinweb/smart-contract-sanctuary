// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Roles {
    bytes32 constant ROLE_ADMIN = keccak256('operator.dabot.role');
    bytes32 constant ROLE_OPERATORS = keccak256('operator.dabot.role');
    bytes32 constant ROLE_TEMPLATE_CREATOR = keccak256('creator.template.dabot.role');
    bytes32 constant ROLE_BOT_CREATOR = keccak256('creator.dabot.role');
}

library AddressBook {
    bytes32 constant ADDR_FACTORY = keccak256('factory.address');
    bytes32 constant ADDR_VICS = keccak256('vics.address');
    bytes32 constant ADDR_TAX = keccak256('tax.address');
    bytes32 constant ADDR_VOTER = keccak256('voter.address');
    bytes32 constant ADDR_BOT_MANAGER = keccak256('botmanager.address');
    bytes32 constant ADDR_VICS_EXCHANGE = keccak256('exchange.vics.address');
}

library Config {
    bytes32 constant PROPOSAL_DEPOSIT = keccak256('deposit.proposal.config');
    bytes32 constant PROPOSAL_REWARD_PERCENT = keccak256('reward.proposal.config');
    bytes32 constant CREATOR_DEPOSIT = keccak256('deposit.creator.config');
}

interface IConfigurator {
    function addressOf(bytes32 addrId) external view returns(address);
    function configOf(bytes32 configId) external view returns(uint);
    function bytesConfigOf(bytes32 configId) external view returns(bytes memory);
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

struct StakingPNL {
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

import "@openzeppelin/contracts/utils/Context.sol";
import "./DABotCommon.sol";
import "./interfaces/IDABotModule.sol";
import "./controller/DABotControllerLib.sol";

abstract contract DABotModule is IDABotModule, Context {

    using DABotMetaLib for BotMetaData;

    event ModuleRegistered(string name, bytes32 moduleId, address indexed moduleAddress);

    modifier onlyTemplateAdmin() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(ds.isTemplate && (ds.botOwner == _msgSender()), 
            "BotModule: caller is not template admin");
        _;
    }

    modifier onlyBotOwner() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(!ds.isTemplate && (!ds.initialized || ds.botOwner == _msgSender()), "BotModule: caller is not the owner");
        _;
    }

    modifier onlyBotManager() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(!ds.initialized || ds.botManager == _msgSender(), 'BotModule: caller is not the bot manager');
        _;
    }

    modifier activeBot() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(!ds.abandoned, "Bot is abandoned");
        _;
    }

    modifier initializer() {
        BotMetaData storage ds = DABotMetaLib.metadata();
        require(!ds.initialized, "BotModule: contract initialized");
        _;
    }

    function configurator() internal view returns(IConfigurator) {
        BotMetaData storage meta = DABotMetaLib.metadata();
        return meta.manager().configurator();
    }

    function onRegister(address moduleAddress) external override onlyTemplateAdmin {
        _onRegister(moduleAddress);
    }

    function onInitialize(bytes calldata data) external override initializer {
        _initialize(data);
    }

    function _initialize(bytes calldata data) internal virtual;
    function _onRegister(address moduleAddress) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IBotTemplateController.sol";
import "../interfaces/IDABotGovernToken.sol";
import "../interfaces/IDABotManager.sol";
import "../DABotCommon.sol";

struct BotTemplateController {
    mapping(bytes4 => bytes32) selectors;
    mapping(bytes32 => address) moduleAddresses;
    bytes32[] modules;
}

string constant ERR_ADMIN_REQUIRED = "Controller: admin required";  
string constant ERR_CONTRACT_INITIALIZED = "Controller: contract initialized";
string constant ERR_MODULE_EXISTS = "Controller: module exists";
string constant ERR_CERT_TOKEN_NOT_SET = "Controller: certificate token contract is not set";
string constant ERR_GOVERN_TOKEN_NOT_SET = "Controller: governance token contract is not set";
string constant ERR_GOVERN_TOKEN_NOT_DEPLOYED = "Controller: governance token is not deployed";
string constant ERR_WARMUP_LOCKER_NOT_SET = "Controller: warmup locker is not set";
string constant ERR_COOLDOWN_LOCKER_NOT_SET = "Controller: cooldown locker is not set";
string constant ERR_UNKNOWN_MODULE_ID = "Controller: unknown module id";
string constant ERR_BOT_MANAGER_NOT_SET = "Controller: bot manager is not set";
string constant ERR_FACTORY_NOT_SET = "Controller: factory is not set";

struct BotCoreData {
    BotTemplateController controller;
    BotMetaData metadata;
    BotSetting setting;
}

library DABotTemplateControllerLib {

    using DABotTemplateControllerLib for BotTemplateController;

    bytes32 constant CORE_STORAGE_POSITION = keccak256("core.dabot.storage");

    function coredata() internal pure returns(BotCoreData storage ds) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function controller() internal view returns (BotTemplateController storage) {
        return coredata().controller;
    }

    function requireNewModule(bytes32 moduleId) internal view {
        BotTemplateController storage ds = controller();
        require(ds.module(moduleId) == address(0), ERR_MODULE_EXISTS);
    }

    function module(BotTemplateController storage ds, bytes32 moduleId) internal view returns(address) {
        return ds.moduleAddresses[moduleId];
    }

    function moduleOfSelector(BotTemplateController storage ds, bytes4 selector) internal view returns(address) {
        bytes32 moduleId = ds.selectors[selector];
        return ds.moduleAddresses[moduleId];
    }

    function registerModule(BotTemplateController storage ds, bytes32 moduleId, address moduleAddress) internal returns(address oldModuleAddress) {
        oldModuleAddress = ds.moduleAddresses[moduleId];
        ds.moduleAddresses[moduleId] = moduleAddress;
    }

    function registerSelectors(BotTemplateController storage ds, bytes32 moduleId, bytes4[] memory selectors) internal {
        for(uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = moduleId;
    }

    
}

library DABotMetaLib {

    using DABotMetaLib for BotMetaData;
    using DABotTemplateControllerLib for BotTemplateController;

    bytes32 constant CORE_STORAGE_POSITION = keccak256("core.dabot.storage");

    function coredata() internal pure returns(BotCoreData storage ds) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function metadata() internal view returns (BotMetaData storage) {
        return coredata().metadata;
    }

    function manager(BotMetaData storage ds) internal view returns(IDABotManager _manager) {
        _manager = IDABotManager(ds.botManager);
        require(address(_manager) != address(0), ERR_BOT_MANAGER_NOT_SET);
    }

    function configurator(BotMetaData storage ds) internal view returns(IConfigurator _config) {
        _config = ds.manager().configurator();
    }

    function factory(BotMetaData storage ds) internal view returns(IRoboFiFactory _factory) {
        IConfigurator config = ds.configurator();
        _factory = IRoboFiFactory(config.addressOf(AddressBook.ADDR_FACTORY));
        require(address(_factory) != address(0), ERR_FACTORY_NOT_SET);
    }

    function governToken(BotMetaData storage ds) internal view returns(IDABotGovernToken) {
        address gToken = ds.gToken;
        require(gToken != address(0), ERR_GOVERN_TOKEN_NOT_DEPLOYED);
        return IDABotGovernToken(gToken);
    }

    function module(BotMetaData storage ds, bytes32 moduleId) internal view returns(address) {
        if (ds.botTemplate == address(0)) {
            return DABotTemplateControllerLib.controller().module(moduleId);
        }
        return IBotTemplateController(ds.botTemplate).module(moduleId);
    }

    function deployCertToken(BotMetaData storage ds, address asset) internal returns(address) {
        address certTokenMaster = ds.module(BOT_MODULE_CERTIFICATE_TOKEN);
        if (certTokenMaster == address(0)) {
            revert(string(abi.encodePacked(
                ERR_CERT_TOKEN_NOT_SET, 
                '. template: ', 
                Strings.toHexString(uint160(ds.botTemplate), 20)
                )));
        }
        require(certTokenMaster != address(0), ERR_CERT_TOKEN_NOT_SET);

        return ds.factory().deploy(
            certTokenMaster,
            abi.encode(address(this), asset),
            false
        );
    }

    function deployGovernanceToken(BotMetaData storage ds) internal returns(address) {
        address governTokenMaster = ds.module(BOT_MODULE_GOVERNANCE_TOKEN);
        require(governTokenMaster != address(0), ERR_GOVERN_TOKEN_NOT_SET);

        return ds.factory().deploy(
            governTokenMaster,
            abi.encode(address(this)),
            false
        );
    }

    function deployLocker(BotMetaData storage ds, bytes32 lockerType, LockerData memory data) internal returns(address) {
        address lockerMaster = ds.module(lockerType);
        if (lockerMaster == address(0)) {
            if (lockerType == BOT_MODULE_WARMUP_LOCKER)
                revert(ERR_WARMUP_LOCKER_NOT_SET);
            if (lockerType == BOT_MODULE_COOLDOWN_LOCKER) 
                revert(ERR_COOLDOWN_LOCKER_NOT_SET);
            revert(ERR_UNKNOWN_MODULE_ID);
        }
        return ds.factory().deploy(
            lockerMaster,
            abi.encode(data),
            false
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IBotTemplateController {
    function module(bytes32 moduleId) external view returns(address);
    function moduleOfSelector(bytes32 selector) external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/IRoboFiERC20.sol";

struct VaultData {
    address botToken;
    IERC20 asset;
    address bot;
    uint8 index;
    bytes4 vaultType;
}

struct UserInfo {
    uint deposit;
    uint debtPoints;
    uint debt;
    uint lockPeriod;
    uint lastDepositDate;
}

struct VaultInfo {
    VaultData data;
    uint totalDeposit;
    bytes option;
} 

interface IBotVaultEvent {
    event Deposit(uint vID, address indexed payor, address indexed account, uint amount);
    event Widthdraw(uint vID, address indexed account, uint amount);
    event RewardAdded(uint vID, uint assetAmount);
}

interface IBotVault is IBotVaultEvent {
    function deposit(uint vID, uint amount) external;
    function delegateDeposit(uint vID, address payor, address account, uint amount, uint lockTime) external;
    function withdraw(uint vID, uint amount) external;
    function delegateWidthdraw(uint vID, address account, uint amount) external;
    function pendingReward(uint vID, address account) external view returns(uint);
    function balanceOf(uint vID, address account) external view returns(uint);
    function updateReward(uint vID, uint assetAmount) external;

    function getUserInfo(uint vID, address account) external view returns(UserInfo memory result);
    function getVaultInfo(uint vID) external view returns(VaultInfo memory);
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
    function setBotManager(address botManager) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotGovernToken is IERC20 {

    function owner() external view returns(address);
    function asset() external view returns (IERC20);
    function value(uint amount) external view returns(uint);
    function mint(address account, uint amount) external;
    function burn(uint amount) external returns(uint);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBotVault.sol";
import "../DABotCommon.sol";
import "../../common/IRoboFiFactory.sol";
import "../../common/IConfigurator.sol";
interface IDABotManager {
    
    function configurator() external view returns(IConfigurator);
    function vaultManager() external view returns(IBotVaultManager);
    function addTemplate(address template) external;
    function templates() external view returns(address[] memory);
    function isRegisteredTemplate(address template) external view returns(bool);
    function isRegisteredBot(address account) external view returns(bool);
    function totalBots() external view returns(uint);
    function botIdOf(string calldata qualifiedName) external view returns(int);
    function queryBots(uint[] calldata botId) external view returns(BotDetail[] memory output);
    function deployBot(address template, 
                        string calldata symbol, 
                        string calldata name,
                        BotModuleInitData[] calldata initData
                        ) external;

    event BotDeployed(uint botId, address indexed bot, BotDetail detail); 
    event TemplateRegistered(address indexed template, string name, string version, uint8 templateType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
@dev An common interface of a DABot module.
 */
interface IDABotModule {
    function moduleInfo() external view returns(string memory name, string memory version, bytes32 moduleId);
    function onRegister(address moduleAddress) external;
    function onInitialize(bytes calldata data) external;
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
    function stakingTime() external view returns(uint warmup, uint cooldown);
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

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IDABotSettingModule.sol";
import "../controller/DABotControllerLib.sol";
import "../DABotCommon.sol";

string constant ERR_ABANDONED = "DABot: bot abandoned";

struct SettingStorage { 
    mapping(bytes32 => address) addrStorage;
    mapping(bytes32 => uint) uintStorage;
    mapping(bytes32 => bytes) blobStorage;
}

library DABotSettingLib {

    string constant ERR_OWNER_REQUIRED = "Setting: owner required"; 
    string constant ERR_VOTE_CONTROLLER_REQUIRED = "Setting: vote controller required";


    using DABotSettingLib for BotSetting;
    using DABotMetaLib for BotMetaData;

    bytes32 constant CORE_STORAGE_POSITION = keccak256("core.dabot.storage");
    bytes32 constant SETTING_STORAGE_POSITION = keccak256("setting.dabot.storage");

    function coredata() internal pure returns(BotCoreData storage ds) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setting() internal view returns(BotSetting storage) {
        return coredata().setting;
    }

    function settingStorage() internal pure returns(SettingStorage storage ds) {
        bytes32 position = SETTING_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function status(BotSetting storage _setting) internal view returns(BotStatus result) {
        BotMetaData storage meta = DABotMetaLib.metadata();

        if (meta.abandoned) return BotStatus.ABANDONED;
        if (block.timestamp < _setting.iboStartTime()) return BotStatus.PRE_IBO;
        if (block.timestamp < _setting.iboEndTime()) return BotStatus.IN_IBO;
        return BotStatus.ACTIVE;
    }

    /**
    @dev Ensures that following conditions are met
        1) bot is not abandoned, and
        2) either bot is pre-ibo stage and sender is bot owner, or the sender is vote controller module
     */
    function requireSettingChangable(address account) internal view {
        BotMetaData storage _metadata = DABotMetaLib.metadata();
        
        require(!_metadata.abandoned, ERR_ABANDONED);

        if (_metadata.isTemplate) {
            require(account == _metadata.botOwner, ERR_OWNER_REQUIRED);
            return;
        }

        BotSetting storage _setting = DABotSettingLib.setting();
        if (block.timestamp < _setting.iboStartTime()) {
            require(account == _metadata.botOwner, ERR_OWNER_REQUIRED);
            return;
        }
        address voteController = _metadata.module(BOT_MODULE_VOTE_CONTROLER);
        require(account == voteController, ERR_VOTE_CONTROLLER_REQUIRED);
    }

    function readAddress(SettingStorage storage ds, bytes32 itemId, address defaultAddress) internal view returns(address result) {
        result = ds.addrStorage[itemId]; 
        if (result == address(0)) { 
            BotMetaData storage _metadata = DABotMetaLib.metadata();
             if (_metadata.botManager == address(0))
                return result;
            if (_metadata.botTemplate != address(0))
                result = IDABotSettingModule(_metadata.botTemplate).readAddress(itemId, defaultAddress);
            if (result == address(0))
                result = _metadata.configurator().addressOf(itemId);
            if (result == address(0))
                result = defaultAddress;
        }
    }

    function writeAddress(SettingStorage storage ds, bytes32 itemId, address value) internal {
        ds.addrStorage[itemId] = value;
    }

    function readUint(SettingStorage storage ds, bytes32 itemId, uint defaultValue) internal view returns(uint result) {
        result = ds.uintStorage[itemId];
        if (result == 0) {
            BotMetaData storage _metadata = DABotMetaLib.metadata();
            if (_metadata.botManager == address(0))
                return result;
            if (_metadata.botTemplate != address(0))
                result = IDABotSettingModule(_metadata.botTemplate).readUint(itemId, defaultValue);
            if (result == 0)
                result = _metadata.configurator().configOf(itemId);
            if (result == 0)
                result = defaultValue;
        }

    }

    function writeUint(SettingStorage storage ds, bytes32 itemId, uint value) internal {
        ds.uintStorage[itemId] = value;
    }

    function readBytes(SettingStorage storage ds, bytes32 itemId, bytes calldata defaultValue) internal view returns(bytes memory result) {
        result = ds.blobStorage[itemId];
        if (result.length == 0) {
            BotMetaData storage _metadata = DABotMetaLib.metadata();
            if (_metadata.botManager == address(0))
                return result;
            if (_metadata.botTemplate != address(0))
                result = IDABotSettingModule(_metadata.botTemplate).readBytes(itemId, defaultValue);
            if (result.length == 0)
                result = _metadata.configurator().bytesConfigOf(itemId);
            if (result.length == 0)
                result = defaultValue;
        }
    }

    function writeBytes(SettingStorage storage ds, bytes32 itemId, bytes calldata defaultValue) internal {
        ds.blobStorage[itemId] = defaultValue;
    }

    function iboStartTime(BotSetting memory info) internal pure returns(uint) {
        return info.iboTime & 0xFFFFFFFF;
    }

    function iboEndTime(BotSetting memory info) internal pure returns(uint) {
        return info.iboTime >> 32;
    }

    function setIboTime(BotSetting storage info, uint start, uint end) internal {
        require(start < end, "invalid ibo start/end time");
        info.iboTime = uint64((end << 32) | start);
    }

    function warmupTime(BotSetting storage info) internal view returns(uint) {
        return info.stakingTime & 0xFF;
    }

    function cooldownTime(BotSetting storage info) internal view returns(uint) {
        return (info.stakingTime >> 8) & 0xFF;
    }

    function getStakingTimeMultiplier(BotSetting storage info) internal view returns (uint) {
        uint unit = stakingTimeUnit(info);
        if (unit == 0) return 1 days;
        if (unit == 1) return 1 hours;
        if (unit == 2) return 1 minutes;
        return 1 seconds;
    }

    function stakingTimeUnit(BotSetting storage info) internal view returns (uint) {
        return (info.stakingTime >> 16);
    }

    function setStakingTime(BotSetting storage info, uint warmup, uint cooldown, uint unit) internal {
        info.stakingTime = uint24((unit << 16) | (cooldown << 8) | warmup);
    }

    function priceMultiplier(BotSetting storage info) internal view returns(uint) {
        return info.pricePolicy & 0xFFFF;
    }

    function commission(BotSetting storage info) internal view returns(uint) {
        return info.pricePolicy >> 16;
    }

    function setPricePolicy(BotSetting storage info, uint _priceMul, uint _commission) internal {
        info.pricePolicy = uint32((_commission << 16) | _priceMul);
    }

    function profitShare(BotSetting storage info, uint actor) internal view returns(uint) {
        return (info.profitSharing >> actor * 16) & 0xFFFF;
    }

    function setProfitShare(BotSetting storage info, uint sharingScheme) internal {
        info.profitSharing = uint128(sharingScheme);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "../../common/IConfigurator.sol";
import "../interfaces/IDABotSettingModule.sol";
import "../DABotModule.sol";
import "./DABotSettingLib.sol";

string constant ERR_INVALID_IBO_TIME = 'BotSetting: IBO end time should be later than IBO start time';
string constant ERR_INVALID_CREATOR_DEPOSIT = 'BotSetting: init deposit is less than configured value';
string constant ERR_INVALID_FOUNDER_SHARE = 'BotSetting: founder share is zero';
string constant ERR_INSUFFICIENT_MAX_SHARE = 'BotSetting: insufficient max share';

contract DABotSettingModule is DABotModule, IDABotSettingModuleEvent {

    using DABotSettingLib for BotSetting;
    using DABotSettingLib for SettingStorage;
    using DABotTemplateControllerLib for BotTemplateController;

    /**
    @dev Ensure the modification of bot settings to comply with the following rule:

    Before the IBO time, bot owner could freely change the bot setting.
    After the IBO has started, bot settings must be changed via the voting protocol.
     */
    modifier SettingGuard() {
        DABotSettingLib.requireSettingChangable(msg.sender);
        _;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotSettingModuleID, moduleAddress);
        bytes4[15] memory selectors =  [
            IDABotSettingModule.status.selector,
            IDABotSettingModule.iboTime.selector,
            IDABotSettingModule.stakingTime.selector,
            IDABotSettingModule.pricePolicy.selector,
            IDABotSettingModule.profitSharing.selector,
            IDABotSettingModule.setIBOTime.selector,
            IDABotSettingModule.setStakingTime.selector,
            IDABotSettingModule.setPricePolicy.selector,
            IDABotSettingModule.setProfitSharing.selector,

            IDABotSettingModule.readAddress.selector,
            IDABotSettingModule.readUint.selector,
            IDABotSettingModule.readBytes.selector,
            IDABotSettingModule.writeAddress.selector,
            IDABotSettingModule.writeUint.selector,
            IDABotSettingModule.writeBytes.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotSettingModuleID;

        emit ModuleRegistered("IDABotSettingModule", IDABotSettingModuleID, moduleAddress);
    }

    function _initialize(bytes calldata data) internal override {
        BotCoreData storage ds = DABotSettingLib.coredata();
        BotSetting memory setting = abi.decode(data, (BotSetting));
        IConfigurator config = configurator();

        require(setting.iboEndTime() > setting.iboStartTime(), ERR_INVALID_IBO_TIME);
        require(setting.initDeposit >= config.configOf(Config.CREATOR_DEPOSIT), ERR_INVALID_CREATOR_DEPOSIT);
        require(setting.initFounderShare > 0, ERR_INVALID_FOUNDER_SHARE);
        require(setting.maxShare >= setting.initFounderShare + setting.iboShare, ERR_INSUFFICIENT_MAX_SHARE);

        ds.setting = setting;

        emit SettingChanged(0, setting);
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "DABotSettingModule";
        version = "v0.1.210901";
        moduleId = IDABotSettingModuleID;
    }

    function status() external view returns(BotStatus) {
        return DABotSettingLib.setting().status();
    }

    function iboTime() external view returns(uint startTime, uint endTime) {
        BotSetting storage _setting = DABotSettingLib.setting();
        startTime = _setting.iboStartTime();
        endTime = _setting.iboEndTime();
    }

    /**
    @dev Retrieves the staking settings of this bot, including the warm-up and cool-down time.
     */
    function stakingTime() external view returns(uint warmup, uint cooldown) {
        BotSetting storage _setting = DABotSettingLib.setting();
        warmup = _setting.warmupTime();
        cooldown = _setting.cooldownTime();
    }

    /**
    @dev Retrieves the pricing policy of this bot, including the after-IBO price multiplier and commission.
     */
    function pricePolicy() external view returns(uint priceMul, uint commission) {
        BotSetting storage _setting = DABotSettingLib.setting();
        priceMul = _setting.priceMultiplier();
        commission = _setting.commission();
    }

    /**
    @dev Retrieves the profit sharing scheme of this bot.
     */
    function profitSharing() external view returns(uint144) {
        BotSetting storage _setting = DABotSettingLib.setting();
        return _setting.profitSharing;
    }

    function setIBOTime(uint startTime, uint endTime) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setIboTime(startTime, endTime);
        emit SettingChanged(0, _setting);
    }
    
    function setStakingTime(uint warmup, uint cooldown, uint unit) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setStakingTime(warmup, cooldown, unit);
        emit SettingChanged(1, _setting);
    }

    function setPricePolicy(uint priceMul, uint commission) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setPricePolicy(priceMul, commission);
        emit SettingChanged(2, _setting);
    }

    function setProfitSharing(uint sharingScheme) external SettingGuard {
        BotSetting storage _setting = DABotSettingLib.setting();
        _setting.setProfitShare(sharingScheme);
        emit SettingChanged(3, _setting);
    }

    function readAddress(bytes32 itemId, address defaultAddress) external view returns(address) {
        return DABotSettingLib.settingStorage().readAddress(itemId, defaultAddress);
    }

    function readUint(bytes32 itemId, uint defaultValue) external view returns(uint) {
        return DABotSettingLib.settingStorage().readUint(itemId, defaultValue);
    }

    function readBytes(bytes32 itemId, bytes calldata defaultValue) external view returns(bytes memory) {
        return DABotSettingLib.settingStorage().readBytes(itemId, defaultValue);
    }

    function writeAddress(bytes32 itemId, address value) external SettingGuard {
        DABotSettingLib.settingStorage().writeAddress(itemId, value);
        emit AddressWritten(itemId, value);
    }

    function writeUint(bytes32 itemId, uint value) external SettingGuard {
        DABotSettingLib.settingStorage().writeUint(itemId, value);
        emit UintWritten(itemId, value);
    }

    function writeBytes(bytes32 itemId, bytes calldata value) external SettingGuard {
        DABotSettingLib.settingStorage().writeBytes(itemId, value);
        emit BytesWritten(itemId, value);
    }
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

