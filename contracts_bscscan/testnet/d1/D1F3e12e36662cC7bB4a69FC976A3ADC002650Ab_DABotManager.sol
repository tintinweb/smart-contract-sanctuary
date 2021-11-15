// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMasterContract.sol";

contract RoboFiFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    mapping(address => address) public masterContractOf; // Mapping from clone contracts to their masterContract

    // Deploys a given master Contract as a clone.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address) {
        require(masterContract != address(0), "Factory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address
        address cloneAddress; // Address where the clone contract will reside.

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);

        return cloneAddress;
    }
}

contract ERC20Factory {

    RoboFiFactory private factory;

    constructor (RoboFiFactory factory_) {
        factory = factory_;
    }

    function deploy(string memory name_, 
                    string memory symbol_, 
                    uint256 initAmount_,
                    address holder_,
                    address master_) public payable {
        bytes memory data = abi.encode(name_, symbol_, initAmount_, holder_);
        factory.deploy(master_, data, true);
        // *
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterContract {
    function init(bytes calldata data) external payable;
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

import "../token/IRoboFiToken.sol";
import "../Ownable.sol";
import "../Factory.sol"; 
import "./IDABot.sol"; 

abstract contract BotManagerSetting is Context, Ownable, IDABotManager {
    struct DABotSetting {
        address operatorAddress;
        address taxAddress;     // the address to receive commission fee 
        uint proposalDeposit;   // the amount of VICS a user has to deposit to create new proposalDeposit
        uint8 proposalReward;   // the percentage of proposalDeposit for awarding proposal settlement (for both approved and expired proposals).
                                // the remain part of proposalDeposit will go to operatorAddress.
        uint minCreatorDeposit; // the minimum amount that a bot creator has to deposit to the newly created bot.
    }

    DABotSetting internal _settings;

    constructor() {
        _settings.operatorAddress = _msgSender();
        _settings.proposalDeposit = 100 * 1e18;
        _settings.proposalReward = 70;
        _settings.minCreatorDeposit = 0;
    }

    /**
    @dev Gets the address of the platform operator.
     */
    function operatorAddress() external view override returns(address) {
        return _settings.operatorAddress;
    }

    /**
    @dev Gets the address to receiving tax.
     */
    function taxAddress() external view override returns(address) {
        return _settings.taxAddress;
    }
    
    /**
    @dev Gets the deposit amount (in VICS) that a person has to pay to create a proposal.
     */
    function proposalDeposit() external view override returns (uint) {
        return _settings.proposalDeposit;
    }
    
    function proposalReward() external view override returns (uint) {
        return _settings.proposalReward;
    }

    function minCreatorDeposit() external view override returns (uint) {
        return _settings.minCreatorDeposit;
    }
    
    function setOperatorAddress(address account) external onlyOwner {
        _settings.operatorAddress = account;

        emit OperatorAddressChanged(account);
    }

    function setTaxAddress(address account) external onlyOwner {
        _settings.taxAddress = account;

        emit TaxAddressChanged(account);
    }
    
    function setProposalDeposit(uint amount) external onlyOwner {
        _settings.proposalDeposit = amount;

        emit ProposalDepositChanged(amount);
    }
    
    function setProposalReward(uint8 percentage) external onlyOwner {
        require(percentage <= 100, "DABotManager: value out of range.");
        _settings.proposalReward = percentage;

        emit ProposalRewardChanged(percentage);
    }

    function setMinCreatorDeposit(uint amount) external onlyOwner {
        _settings.minCreatorDeposit = amount;

        emit MinCreatorDepositChanged(amount);
    }
}

contract DABotManager is BotManagerSetting {

    IDABot[] private _bots;
    mapping(bytes32 => int) _botSymbolToIndex;

    address[] private _templates;
    mapping(address => bool) private _registeredTemplates;

    RoboFiFactory public override factory;
    IRoboFiToken public vicsToken;
    address public certTokenMaster;

    

    constructor(RoboFiFactory _factory, address vics, address _certTokenMaster) {
        factory = _factory;
        vicsToken = IRoboFiToken(vics);
        certTokenMaster = _certTokenMaster;
    }

    function setCertTokenMaster(address certToken) external onlyOwner {
        certTokenMaster = certToken;
    }
    
    function totalBots() external view returns(uint) {
        return _bots.length;
    }

    /**
    @dev Registers a DABot template (i.e., master contract). Once registered, a bot template will
    never be remove.
     */
    function addTemplate(address template) public onlyOwner {
        require(!_registeredTemplates[template], "DABotManager: template existed");

        _registeredTemplates[template] = true;
        _templates.push(template);

        emit TemplateRegistered(template);
    }

    /**
    @dev Retrieves a list of registered DABot templates.
     */
    function templates() external view returns(address[] memory) {
        return _templates;
    }

    /**
    @dev Determine whether an address is a registered bot template.
     */
    function isRegisteredTemplate(address template) external view returns(bool) {
        return _registeredTemplates[template];
    } 

    /**
    @dev Deploys a bot for a given template.

    params:
        `template`  : address of the master contract containing the logic of the bot
        `name`      : name of the bot
        `setting`   : various settings of the bot. See {IDABot.sol\DABot.BotSetting}
     */
    function deployBot(address template, 
                        string calldata botsymbol, 
                        string calldata botname,
                        DABotCommon.BotSetting calldata setting,
                        DABotCommon.PortfolioCreationData[] calldata portfolio
                        ) external returns(uint botId, address bot) {

        bytes32 botSymbolHash = keccak256(abi.encode(botsymbol)); 

        require(_botSymbolToIndex[botSymbolHash] == 0, "DABotManager: bot name exists");
        require(_registeredTemplates[template], "DABotManager: unregistered template");

        bot = factory.deploy(template, abi.encode(botsymbol, botname, address(this), setting, portfolio), true);
        vicsToken.transferFrom(_msgSender(), bot, setting.initDeposit); 
        botId = _bots.length;

        IDABot daBot = IDABot(bot);
        _bots.push(daBot);
        _botSymbolToIndex[botSymbolHash] = int(_bots.length);

        emit BotDeployed(_msgSender(), address(template), botId, bot);

        // for(uint idx = 0; idx < portfolio.length; idx++) {
        //     daBot.updatePortfolio(portfolio[idx].asset, portfolio[idx].cap, portfolio[idx].iboCap, portfolio[idx].weight);
        // }
        IRoboFiToken(bot).transfer(_msgSender(), setting.initFounderShare);
        Ownable(bot).transferOwnership(_msgSender());
    }

    /**
    @dev Gets the bot id for the specified bot name. Returns -1 if no bot found.
     */
    function botIdOf(string calldata botsymbol) external view returns(int) {
        return _botSymbolToIndex[keccak256(abi.encode(botsymbol))] - 1; 
    }
    
    /**
    @dev Deploys a certificate token for a bot's porfolio asset.

    Should only be called internally by a bot.
     */
    function deployBotCertToken(address peggedAsset) external override returns(address token) {
        token = factory.deploy(certTokenMaster, abi.encode(peggedAsset, _msgSender()), false);

        emit CertTokenDeployed(_msgSender(), peggedAsset, token);
    }

    /**
    @dev Queries details information for a list of bot Id.
     */
    function queryBots(uint[] calldata botId) external view returns(DABotCommon.BotDetail[] memory output) {
        output = new DABotCommon.BotDetail[](botId.length);
        for(uint i = 0; i < botId.length; i++) {
            if (botId[i] >= _bots.length) continue;
            IDABot bot = _bots[botId[i]];
            output[i] = bot.botDetails();
            output[i].id = botId[i];
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../Factory.sol";

library DABotCommon {

    enum ProfitableActors { BOT_CREATOR, GOVERNANCE_USER, STAKE_USER, ROBOFI_GAME }
    enum StakingTimeUnit { DAY, HOUR, MINUTE, SECOND }
    enum BotStatus { PRE_IBO, IN_IBO, ACTIVE, ABANDONED }

    struct PortfolioCreationData {
        address asset;
        uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
        uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
        uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
    }

   
    struct PortfolioAsset {
        address certAsset;    // the certificate asset to return to stake-users
        uint256 cap;            // the maximum stake amount for this asset (bot-lifetime).
        uint256 iboCap;         // the maximum stake amount for this asset within the IBO.
        uint256 weight;         // preference weight for this asset. Use to calculate the max purchasable amount of governance tokens.
        uint256 totalStake;     // the total stake of all users.
    }

    struct UserPortfolioAsset {
        address asset;
        PortfolioAsset info;
        uint256 userStake;
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
    
    struct BotDetail { // represents a detail information of a bot, merely use for bot infomation query
        uint id;                    // the unique id of a bot within its manager.
                                    // note: this id only has value when calling {DABotManager.queryBots}
        address botAddress;         // the contract address of the bot.
        address masterContract;     // reference to the master contract of a bot contract.
                                    // in most cases, a bot contract is a proxy to a master contract.
                                    // particular settings of a bot are stored in the bot contracts.
        BotStatus status;           // 0 - PreIBO, 1 - InIBO, 2 - Active, 3 - Abandonned
        string botSymbol;                // get the bot name.
        string botName;            // get the bot full name.
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

    /**
    @dev The detail buy privilege of an account during the IBO period
     */
    struct ShareBuyablePrivilege {
        address asset;
        uint stakeAmount;
        uint shareBuyable;
        uint weight;
        uint iboCap;
    }

    /**
    @dev Records warming-up certificate tokens of a DABot.
     */
    struct LockerInfo {         
        IDABot bot;             // the DABOT which creates this locker.
        address owner;          // the locker owner, who is albe to unlock and get tokens after the specified release time.
        address token;          // the contract of the certificate token.
        uint64 created_at;      // the moment when locker is created.
        uint64 release_at;      // the monent when locker could be unlock. 
    }

    /**
    @dev Provides detail information of a warming-up token lock, plus extra information.
     */
    struct LockerInfoEx {
        address locker;
        LockerInfo info;
        uint256 amount;         // the locked amount of cert token within this locker.
        uint256 reward;         // the accumulated rewards
        address asset;          // the stake asset beyond the certificated token
    }
   
    function iboStartTime(BotSetting storage info) view internal returns(uint) {
        return info.iboTime & 0xFFFFFFFF;
    }

    function iboEndTime(BotSetting storage info) view internal returns(uint) {
        return info.iboTime >> 32;
    }

    function setIboTime(BotSetting storage info, uint start, uint end) internal {
        require(start < end, "invalid ibo start/end time");
        info.iboTime = uint64((end << 32) | start);
    }

    function warmupTime(BotSetting storage info) view internal returns(uint) {
        return info.stakingTime & 0xFF;
    }

    function cooldownTime(BotSetting storage info) view internal returns(uint) {
        return (info.stakingTime >> 8) & 0xFF;
    }

    function getStakingTimeMultiplier(BotSetting storage info) view internal returns (uint) {
        uint unit = stakingTimeUnit(info);
        if (unit == 0) return 1 days;
        if (unit == 1) return 1 hours;
        if (unit == 2) return 1 minutes;
        return 1 seconds;
    }

    function stakingTimeUnit(BotSetting storage info) view internal returns (uint) {
        return (info.stakingTime >> 16);
    }

    function setStakingTime(BotSetting storage info, uint warmup, uint cooldown, uint unit) internal {
        info.stakingTime = uint24((unit << 16) | (cooldown << 8) | warmup);
    }

    function priceMultiplier(BotSetting storage info) view internal returns(uint) {
        return info.pricePolicy & 0xFFFF;
    }

    function commission(BotSetting storage info) view internal returns(uint) {
        return info.pricePolicy >> 16;
    }

    function setPricePolicy(BotSetting storage info, uint _priceMul, uint _commission) internal {
        info.pricePolicy = uint32((_commission << 16) | _priceMul);
    }

    function profitShare(BotSetting storage info, ProfitableActors actor) view internal returns(uint) {
        return (info.profitSharing >> uint(actor) * 16) & 0xFFFF;
    }

    function setProfitShare(BotSetting storage info, uint sharingScheme) internal {
        info.profitSharing = uint128(sharingScheme);
    }
}

/**
@dev The generic interface of a DABot.
 */
interface IDABot {
    
    function botSymbol() view external returns(string memory);
    function name() view external returns(string memory);
    function symbol() view external returns(string memory);
    function version() view external returns(string memory);

    /**
    @dev Retrieves the detail infromation of this DABot.

    Note: all fields of {DABotCommon.BotDetail} are filled, except {id} which is filled 
    by only the DABotManager.
     */
    function botDetails() view external returns(DABotCommon.BotDetail memory);
    function updatePortfolio(address asset, uint maxCap, uint iboCap, uint weight) external;

}


interface IDABotManager {
    
    function factory() external view returns(RoboFiFactory);

    /**
    @dev Gets the address to receive tax.
     */
    function taxAddress() external view returns (address);

    /**
    @dev Gets the address of the platform operator.
     */
    function operatorAddress() external view returns (address);

    /**
    @dev Gets the deposit amount (in VICS) that a person has to pay to create a proposal.
         When a proposal is settled (either approved or rejected), the account who submits or 
         clean the proposal will be awarded a portion of the deposit. The remain will go to operator addresss.

         See {proposalReward()}.
     */
    function proposalDeposit() external view returns (uint);
    
    /**
    @dev Gets the the percentage of proposalDeposit for awarding proposal settlement (for both approved and expired proposals).
         the remain part of proposalDeposit will go to operatorAddress.
     */
    function proposalReward() external view returns (uint);

    /**
    @dev Gets the minimum amount of VICS that a bot creator has to deposit to his newly created bot.
     */
    function minCreatorDeposit() external view returns(uint);

    function deployBotCertToken(address peggedAsset) external returns(address);

    event OperatorAddressChanged(address indexed account);
    event TaxAddressChanged(address indexed account);
    event ProposalDepositChanged(uint value);
    event ProposalRewardChanged(uint value);
    event MinCreatorDepositChanged(uint value);
    event BotDeployed(address indexed creator, address indexed template, uint botId, address indexed bot);
    event CertTokenDeployed(address indexed bot, address indexed asset, address indexed certtoken);
    event TemplateRegistered(address indexed template);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoboFiToken is IERC20 {
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

