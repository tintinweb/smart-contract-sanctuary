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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IVicsExchange {
    /**
    @dev Exchanges the given input amount of a specific asset to an equivalent amount
        of VICS.
     */
    function swap(IERC20 asset, uint amountIn) external returns(uint amountOut);
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

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../common/IConfigurator.sol";
import "../../common/IVicsExchange.sol";
import "../DABotCommon.sol";
import "../DABotModule.sol";
import "../interfaces/IBotVault.sol";
import "../interfaces/IDABotFundManagerModule.sol";
import "../setting/DABotSettingLib.sol";
import "../staking/DABotStakingLib.sol";
import "../controller/DABotControllerLib.sol";
import "./DABotFundManagerLib.sol";

contract CEXFundManagerModule is DABotModule, IDABotFundManagerModuleEvent {
    using DABotTemplateControllerLib for BotTemplateController;
    using DABotSettingLib for BotSetting;
    using DABotStakingLib for BotStakingData;
    using DABotMetaLib for BotMetaData;
    using DABotFundManagerLib for FundManagementData;
    using SafeERC20 for IERC20;

    bytes4 constant WARMUP_VAULT = 0x5f0378a7; // warmup.vault
    bytes4 constant REGULAR_VAULT = 0x3e472239; //regular.vault
    bytes4 constant VIP_VAULT = 0x2c52665a; // vip.vault

    IBotVaultManager private immutable vaultManager;

    constructor(IBotVaultManager _vault) {
        vaultManager = _vault;
    }

    function _onRegister(address moduleAddress) internal override {
        BotTemplateController storage ds = DABotTemplateControllerLib.controller();
        ds.registerModule(IDABotFundManagerModuleID, moduleAddress); 
        bytes4[6] memory selectors =  [
            IDABotFundManagerModule.benefitciaries.selector,
            IDABotFundManagerModule.resetBenefitciaries.selector,
            IDABotFundManagerModule.addBenefitciary.selector,
            IDABotFundManagerModule.updatePnl.selector,
            IDABotFundManagerModule.pendingStakeReward.selector,
            IDABotFundManagerModule.pendingGovernReward.selector
        ];
        for (uint i = 0; i < selectors.length; i++)
            ds.selectors[selectors[i]] = IDABotFundManagerModuleID;

        emit ModuleRegistered("IDABotFundManagerModule", IDABotFundManagerModuleID, moduleAddress);
    }

    function _initialize(bytes calldata) internal override {
        _resetBenefitciaries();
    }

    function moduleInfo() external pure override returns(string memory name, string memory version, bytes32 moduleId) {
        name = "CEXFundManagerModule";
        version = "v0.1.210902";
        moduleId = IDABotFundManagerModuleID;
    }

    function resetBenefitciaries() external onlyBotOwner {
        _resetBenefitciaries();
    }

    function _resetBenefitciaries() private {
        BotMetaData storage meta = DABotMetaLib.metadata();
        FundManagementData storage fund = DABotFundManagerLib.fundData();
        delete fund.benefitciaries;
        BenefitciaryInfo[] memory _benefitciaries = IDABotFundManagerModule(meta.botTemplate).benefitciaries();
        for (uint i = 0; i < _benefitciaries.length; i++)
            fund.addBenefitciary(_benefitciaries[i].account);
    }

    function addBenefitciary(address benefitciary) external onlyBotOwner {
        FundManagementData storage fund = DABotFundManagerLib.fundData();
        for (uint i = 0; i < fund.benefitciaries.length; i++)
            require(fund.benefitciaries[i] != benefitciary, 'FundManagement: benefitciary existed');
        fund.benefitciaries.push(benefitciary);

        emit AddBenefitciary(benefitciary);
    }

    function benefitciaries() external view returns(BenefitciaryInfo[] memory result) {
        FundManagementData storage data = DABotFundManagerLib.fundData();
        result = new BenefitciaryInfo[](data.benefitciaries.length);
        uint profitSharing = DABotSettingLib.setting().profitSharing;

        for (uint i = 0; i < data.benefitciaries.length; i++) {
            address account = data.benefitciaries[i];
            result[i] = BenefitciaryInfo(
                    account,
                    DABotFundManagerLib.benefitciaryName(account),
                    DABotFundManagerLib.benefitciaryShortName(account),
                    profitSharing & 0xffff
                );
            profitSharing = profitSharing >> 16;
        }
    }

    function updatePnl(StakingPNL[] calldata pnl) external {
        for (uint i = 0; i < pnl.length; i++) {
            _updatePnl(pnl[i]);
        }
        emit Award(pnl);
    }

    function pendingStakeReward(address account, IRoboFiERC20[] memory assets, 
        bytes memory subVaults) external view returns(StakingReward[] memory result) 
    {
        BotStakingData storage ds = DABotStakingLib.staking();
        if (assets.length == 0) 
            assets = ds.assets;
        if (subVaults.length == 0) 
            subVaults = abi.encodePacked(uint8(0), uint8(1), uint8(2));

        result = new StakingReward[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            result[i].asset = address(assets[i]);
            uint vID = vaultManager.vaultId(ds.portfolio[assets[i]].certToken, 0);
            for (uint j = 0; j < subVaults.length; j++) {
                uint8 x = uint8(subVaults[j]);
                result[i].amount += vaultManager.pendingReward(vID + uint(x), account);
            }
        }
    }

    function pendingGovernReward(address account, bytes memory subVaults) external view returns(uint result) {
        if (subVaults.length == 0) 
            subVaults = abi.encodePacked(uint8(0), uint8(1));
        result = 0;
        uint vID = vaultManager.vaultId(DABotMetaLib.metadata().gToken, 1);
        for (uint i = 0; i < subVaults.length; i++) {
            uint8 x = uint8(subVaults[i]);
            result += vaultManager.pendingReward(vID + uint(x), account);
        }
    }

    function _updatePnl(StakingPNL calldata pnl) internal {
        BotStakingData storage ds = DABotStakingLib.staking();
        IDABotCertToken certToken = ds.certificateOf(IRoboFiERC20(pnl.asset));
        if (address(certToken) == address(0)) 
            revert(string(
                abi.encodePacked("FundManager: invalid certificate for asset ", Strings.toHexString(uint160(pnl.asset), 20))));
        IERC20 asset = IERC20(pnl.asset);

        if (pnl.compound > 0) {
            if (pnl.compoundMode == 0) 
                asset.safeTransferFrom(_msgSender(), address(certToken), pnl.compound);
            certToken.compound(pnl.compound, pnl.compoundMode == 0);
            
            emit AwardCompound(address(asset), pnl.compound, pnl.compoundMode);
        }
        if (pnl.reward > 0) {
            FundManagementData storage fund = DABotFundManagerLib.fundData(); 
            uint128 shareScheme = DABotSettingLib.setting().profitSharing;
            uint total = 0;
            for(uint i = 0; i < fund.benefitciaries.length; i++) {
                if (fund.benefitciaries[i] != address(0)) 
                    total += shareScheme & 0xffff;
                shareScheme = shareScheme >> 16;
            }
            shareScheme = DABotSettingLib.setting().profitSharing;
            for(uint i = 0; i < fund.benefitciaries.length; i++) {
                if (fund.benefitciaries[i] != address(0)) {
                    _award(address(certToken), asset, fund.benefitciaries[i], pnl.reward, (shareScheme & 0xffff), total);
                }
                shareScheme = shareScheme >> 16;
            }
        }
    }

    function _award(address certToken, IERC20 asset, address benefitciary, uint reward, uint share, uint totalShare) internal {
        BotMetaData storage meta = DABotMetaLib.metadata();
        uint amount = reward * share / totalShare;

        if (benefitciary == BOT_CREATOR_BENEFITCIARY) {
            asset.safeTransferFrom(_msgSender(), meta.botOwner, amount);
        } else if (benefitciary == GOV_USER_BENEFITCIARY) {
            IConfigurator config = meta.configurator();
            IVicsExchange xchg = IVicsExchange(config.addressOf(AddressBook.ADDR_VICS_EXCHANGE));
            IERC20 vics = IERC20(config.addressOf(AddressBook.ADDR_VICS));

            asset.safeTransferFrom(_msgSender(), address(this), amount);
            asset.approve(address(xchg), amount);
            uint vicsAmount = xchg.swap(asset, amount);
            IERC20 gToken = meta.governToken();
            uint vID = vaultManager.vaultId(address(gToken), 1);

            vics.transfer(address(vaultManager), vicsAmount);
            _awardVault(vID, 2, vicsAmount, [uint(100), 120, 0]);

            emit AwardBenefitciary(benefitciary, address(asset), address(vics), vicsAmount, share, totalShare);
            return;

        } else if (benefitciary == STAKE_USER_BENEFITCIARY) {
            uint vID = vaultManager.vaultId(certToken, 0);
            asset.safeTransferFrom(_msgSender(), address(vaultManager), amount);
            _awardVault(vID, 3, amount, [uint(80), 100, 120]);
        } else {
            asset.safeTransferFrom(_msgSender(), benefitciary, amount);
            IBotBenefitciary(benefitciary).onAward(amount);
        }
        emit AwardBenefitciary(benefitciary, address(asset), address(asset), amount, share, totalShare);
    }

    function _awardVault(uint vID, uint numVault, uint amount, uint[3] memory weight) internal {
        uint[] memory deposit = new uint[](numVault);
        uint total;
        for (uint i = 0; i < numVault; i++) {
            deposit[i] = vaultManager.getVaultInfo(vID + i, address(this)).totalDeposit * weight[i];
            total += deposit[i];
        }
        if (total == 0)
            return;
        for (uint i = 0; i < numVault; i++) {
            vaultManager.updateReward(vID + i, deposit[i] * amount / total); 
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 
import "../interfaces/IBotBenefitciary.sol"; 

struct FundManagementData {
    address[] benefitciaries;
}

address constant BOT_CREATOR_BENEFITCIARY = address(1);
address constant GOV_USER_BENEFITCIARY = address(2);
address constant STAKE_USER_BENEFITCIARY = address(3);

library DABotFundManagerLib {
    bytes32 constant FUND_MANAGER_STORAGE_POSITION = keccak256("fundmanager.dabot.storage");


    function fundData() internal pure returns(FundManagementData storage ds) {
        bytes32 position = FUND_MANAGER_STORAGE_POSITION;
        assembly {
            ds.slot :=  position
        }
    }

    function benefitciaryName(address benefitciary) internal view returns(string memory) {
        if (benefitciary == BOT_CREATOR_BENEFITCIARY)
            return "Bot Creator";
        if (benefitciary == GOV_USER_BENEFITCIARY)
            return "Governance Users";
        if (benefitciary == STAKE_USER_BENEFITCIARY)
            return "Stake Users";
        return IBotBenefitciary(benefitciary).name();
    }

    function benefitciaryShortName(address benefitciary) internal view returns(string memory) {
        if (benefitciary == BOT_CREATOR_BENEFITCIARY)
            return "Bot Creator";
        if (benefitciary == GOV_USER_BENEFITCIARY)
            return "Gov. Users";
        if (benefitciary == STAKE_USER_BENEFITCIARY)
            return "Stake Users";
        return IBotBenefitciary(benefitciary).shortName();
    }

    function addBenefitciary(FundManagementData storage ds, address benefitciary) internal {
        ds.benefitciaries.push(benefitciary);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol"; 


/**
@dev The interface of a bot benefitciary who is awarded from the bot's activities.
 */
interface IBotBenefitciary {

    function name() external view returns(string memory);
    function shortName() external view returns(string memory);
    function onAward(uint amount) external;
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
}

interface IBotVault is IBotVaultEvent {
    function deposit(uint vID, uint amount) external;
    function delegateDeposit(uint vID, address payor, address account, uint amount, uint lockTime) external;
    function withdraw(uint vID, uint amount) external;
    function delegateWithdraw(uint vID, address account, uint amount) external;
    function pendingReward(uint vID, address account) external view returns(uint);
    function balanceOf(uint vID, address account) external view returns(uint);
    function updateReward(uint vID, uint assetAmount) external;

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
    function setBotManager(address botManager) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/IRoboFiERC20.sol";
import "../DABotCommon.sol";

interface IDABotCertLocker is IRoboFiERC20 {
    function asset() external view returns(IRoboFiERC20);
    function detail() external view returns(LockerInfo memory);
    function lockedBalance() external view returns(uint);
    function unlockerable() external view returns(bool);
    function tryUnlock() external returns(bool, uint);
    function finalize() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDABotCertToken is IERC20 {

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
    @param amount - the amount of certificate tokens.
     */
    function value(uint amount) external view returns(uint);

    function lock(uint amount) external;

    function unlock(uint amount) external;

    /**
    @dev Mints an amount of certificate tokens to the given amount. The equivalent of
        underlying asset should be tranfered to this certificate contract by the caller.
    @param account - the address to recieve minted tokens.
    @param amount - the amount of tokens to mint.
    @notice Only the owner bot can call this function.
     */
    function mint(address account, uint amount) external;

    /**
    @dev Burns an amount of certificate tokens, and returns the equivalant amount of
        the underlying asset to the specified account.
    @param account - the address holing certificate tokens to burn.
    @param amount - the amount of certificate token to burn.
    @return the equivalent amount of underlying asset tranfered to the specified account.
    @notice Only the owner bot can call this function.
     */
    function burn(address account, uint amount) external returns (uint);

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
    @param profit - `true` to increase the total deposit, `false` to decrease.
     */
    function compound(uint amount, bool profit) external;

    /**
    @dev Deletes this certificate token contracts.
     */
    function finalize() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";

bytes32 constant IDABotFundManagerModuleID = keccak256('fundmanager.module');

interface IDABotFundManagerModuleEvent {
    event Award(StakingPNL[] pnl);
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
     @param pnl - list of StakingPNL data.
     */
    function updatePnl(StakingPNL[] calldata pnl) external;

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

import "../../token/IRoboFiERC20.sol";
import "../interfaces/IDABotCertLocker.sol";
import "../interfaces/IDABotCertToken.sol";
import "../DABotCommon.sol";
import "../controller/DABotControllerLib.sol";

string constant ERR_PRE_IBO_OPERATION = "Staking: operation is only supported in pre-IBO";
string constant ERR_AFTER_IBO_OPERATION = "Staking: operation is only supported in after-IBO";
string constant ERR_INVALID_PORTFOLIO_ASSET = "Staking: invalid portfolio asset"; 
string constant ERR_PORTFOLIO_FULL = "Staking: portfolio is full";
string constant ERR_INVALID_CERTIFICATE_ASSET = "Staking: invalid certificate asset";
string constant ERR_PORTFOLIO_ASSET_NOT_FOUND = "Staking: asset is not in portfolio";
string constant ERR_ZERO_ASSET = "Staking: asset is zero";
string constant ERR_INVALID_STAKING_CAP = "Staking: invalid cap";
string constant ERR_INSUFFICIENT_FUND = "Staking: insufficient fund";
string constant ERR_ZERO_CAP = "Staking: zero cap";
string constant ERR_INVALID_CAP = "Staking: cap is less than stake and ibo cap";
string constant ERR_ZERO_WEIGHT = "Staking: zero weight";

struct BotStakingData {
    IRoboFiERC20[]  assets; 
    mapping(IRoboFiERC20 => PortfolioAsset) portfolio;
    mapping(address => IDABotCertLocker[]) warmup;
    mapping(address => IDABotCertLocker[]) cooldown;
    mapping(address => bool) lockers;
}

library DABotStakingLib {
    bytes32 constant STAKING_STORAGE_POSITION = keccak256("staking.dabot.storage");

    using DABotStakingLib for BotStakingData;
    using DABotMetaLib for BotMetaData;

    function staking() internal pure returns(BotStakingData storage ds) {
        bytes32 position = STAKING_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function stakeBalanceOf(BotStakingData storage ds, address account, IRoboFiERC20 asset) internal view returns(uint) {
        BotMetaData storage meta = DABotMetaLib.metadata();
        IBotVaultManager vault = IDABotManager(meta.botManager).vaultManager();
        IDABotCertToken certToken = ds.certificateOf(asset);
        uint vID = vault.vaultId(address(certToken), 0);

        return certToken.balanceOf(account)
                + ds.warmupBalanceOf(account, asset)
                + vault.balanceOf(vID, account)
                + vault.balanceOf(vID + 1, account)
                + vault.balanceOf(vID + 2, account)
                - ds.cooldownBalanceOf(account, ds.certificateOf(asset));
    }

    function totalStake(BotStakingData storage ds, IRoboFiERC20 asset) internal view returns(uint) {
        return IDABotCertToken(ds.portfolio[asset].certToken).totalStake();
    }

    function warmupBalanceOf(BotStakingData storage ds, address account, IRoboFiERC20 asset) internal view returns(uint) {
        IDABotCertLocker[] storage lockers = ds.warmup[account];
        return lockedBalance(lockers, address(asset));
    }

    function cooldownBalanceOf(BotStakingData storage ds, address account, IDABotCertToken certToken) internal view returns(uint) {
        IDABotCertLocker[] storage lockers = ds.cooldown[account];
        return lockedBalance(lockers, address(certToken.asset()));
    }
    
    function certificateOf(BotStakingData storage ds, IRoboFiERC20 asset) internal view returns(IDABotCertToken) {
        return IDABotCertToken(ds.portfolio[asset].certToken); 
    }

    function assetOf(address certToken) public view returns(IERC20) {
        return IDABotCertToken(certToken).asset(); 
    }

    function lockedBalance(IDABotCertLocker[] storage lockers, address asset) internal view returns(uint result) {
        result = 0;
        for (uint i = 0; i < lockers.length; i++) 
            if (address(lockers[i].asset()) == asset)
                result += lockers[i].lockedBalance();
    }

    function portfolioDetails(BotStakingData storage ds) internal view returns(UserPortfolioAsset[] memory output) {
        output = new UserPortfolioAsset[](ds.assets.length);
        for(uint i = 0; i < ds.assets.length; i++) {
            IRoboFiERC20 asset = ds.assets[i];
            output[i].asset = address(asset);
            output[i].info = ds.portfolio[asset];
            output[i].userStake = ds.stakeBalanceOf(msg.sender, asset);
            output[i].totalStake = ds.totalStake(asset);
            output[i].certSupply = IERC20(ds.portfolio[asset].certToken).totalSupply();
        }
    }

    function portfolioOf(BotStakingData storage ds, IRoboFiERC20 asset) internal view returns(UserPortfolioAsset memory  output) {
        output.asset = address(asset);
        output.info = ds.portfolio[asset];
        output.userStake = ds.stakeBalanceOf(msg.sender, asset);
        output.totalStake = ds.totalStake(asset);
        output.certSupply = IERC20(ds.portfolio[asset].certToken).totalSupply();
    }

    function updatePortfolioAsset(BotStakingData storage ds, IRoboFiERC20 asset, uint maxCap, uint iboCap, uint weight) internal {
        PortfolioAsset storage pAsset = ds.portfolio[asset];

        if (address(pAsset.certToken) == address(0)) {
            pAsset.certToken = DABotMetaLib.metadata().deployCertToken(address(asset));
            ds.assets.push(asset);
        }

        if (maxCap > 0) pAsset.cap = maxCap;
        if (iboCap > 0) pAsset.iboCap = iboCap;
        if (weight > 0) pAsset.weight = weight;

        uint _totalStake = IDABotCertToken(pAsset.certToken).totalStake();

        require((pAsset.cap >= _totalStake) && (pAsset.cap >= pAsset.iboCap), ERR_INVALID_STAKING_CAP);
    }

    function removePortfolioAsset(BotStakingData storage ds, IRoboFiERC20 asset) internal returns(address) {
        require(address(asset) != address(0), ERR_ZERO_ASSET);
        for(uint i = 0; i < ds.assets.length; i++)
            if (address(ds.assets[i]) == address(asset)) {
                address certToken = ds.portfolio[asset].certToken;
                IDABotCertToken(certToken).finalize(); 
                delete ds.portfolio[asset];
                ds.assets[i] = ds.assets[ds.assets.length - 1];
                ds.assets.pop();
                return certToken;
            }
        revert(ERR_PORTFOLIO_ASSET_NOT_FOUND);
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

