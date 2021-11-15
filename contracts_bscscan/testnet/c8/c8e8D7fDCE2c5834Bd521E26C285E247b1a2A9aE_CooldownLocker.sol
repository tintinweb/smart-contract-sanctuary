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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./CertToken.sol";
import "./DABotCommon.sol";


abstract contract CertLocker is IMasterContract {

    DABotCommon.LockerInfo internal _info;

    function init(bytes calldata data) external virtual payable override {
        require(address(_info.owner) == address(0), "Locker: locker initialized");
        (_info) = abi.decode(data, (DABotCommon.LockerInfo));
    }

    function lockedBalance() public view returns(uint) {
        return CertToken(_info.token).balanceOf(address(this));
    }

    function asset() external view returns(IERC20) {
        return CertToken(_info.token).asset();
    }

    function owner() external view returns(address) {
        return _info.owner;
    }

    function detail() public view returns(DABotCommon.LockerInfoEx memory result) {
        result.locker = address(this);
        result.info = _info;
        result.amount = CertToken(_info.token).balanceOf(address(this));
        result.asset = address(CertToken(_info.token).asset());
        result.reward = _getReward();
    }

    function _getReward() internal view virtual returns(uint256);

    function unlockable() public view returns(bool) {
        return block.timestamp >= _info.release_at;
    }

    /**
    @dev Tries to unlock this locker if the time condition meets, otherise skipping the action.
     */
    function tryUnlock() public returns(bool) {
        require(msg.sender == address(_info.bot), "Locker: Permission denial");
        if (!unlockable()) 
            return false;
        _unlock();  
        return true;
    }

    function _unlock() internal virtual;

    function finalize() external payable {
        require(msg.sender == address(_info.bot), "Locker: Permission denial");
        selfdestruct(payable(_info.owner));
    }
}

/**
@dev This contract provides support for staking warmup feature. 
When users stake into a DABot, user will not immediately receive the certificate token.
Instead, these tokens will be locked inside an instance of this contract for a predefined
period, the warm-up period. 

During the warm-up period, certificate tokens will not generate any reward, no matter rewards
are added to the DABot or not. After the warm-up period, users can claim these tokens to 
their wallet.

If users do not claim tokens after warm-up period, the tokens are still kept securedly inside
the contract. Locked tokens will also entitle to receive rewards. When users claim the tokens, 
rewards will be distributed automatically to users' wallet. 
 */
contract WarmupLocker is CertLocker {

    event Release(IDABot bot, address indexed owner, address indexed certToken, uint256 certAmount, address indexed asset, uint256 reward);

    function _getReward() internal view override returns(uint256) {
        return block.timestamp < _info.release_at ? 0 :
                         CertToken(_info.token).getClaimableReward(address(this)) * (block.timestamp - _info.release_at) / (block.timestamp - _info.created_at);
    }

    function _unlock() internal override {

        CertToken token = CertToken(_info.token);
        
        require(_info.token != address(0), "CertToken: null token address");
        require(address(token.asset()) != address(0), "CertToken: null asset address");

        token.claimReward();
        IERC20 asset = token.asset();
        uint256 certAmount = token.balanceOf(address(this));
        uint256 rewards = asset.balanceOf(address(this));
        token.transfer(_info.owner, certAmount);
        uint256 entitledRewards = _getReward();
        if (rewards > 0) {
            require(rewards >= entitledRewards, "Actual rewards is less than entitled rewards");
            if (entitledRewards > 0) asset.transfer(_info.owner, entitledRewards);
            if (rewards - entitledRewards > 0) asset.transfer(_info.token, rewards - entitledRewards);
        }
        emit Release(_info.bot, _info.owner, _info.token, certAmount, address(asset), entitledRewards);
    }
}


contract CooldownLocker is CertLocker {

    event Release(IDABot bot, address indexed owner, address indexed certToken, uint certAmount, 
                    address indexed asset, uint256 assetAmount, uint256 penalty);

    function _getReward() internal view override returns(uint256) {
        return CertToken(_info.token).getClaimableReward(address(this)) * 10 / 100;
    }

    function _unlock() internal override {
        CertToken token = CertToken(_info.token);
        uint256 penalty = token.getClaimableReward(address(this)) * 90 / 100;
        uint256 certAmount = token.balanceOf(address(this));
        token.burn(certAmount); 

        IERC20 asset = token.asset();
        asset.transfer(address(token), penalty);

        uint256 assetAmount = asset.balanceOf(address(this));
        asset.transfer(_info.owner, assetAmount);

        emit Release(_info.bot, _info.owner, _info.token, certAmount, address(asset), assetAmount, penalty);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DABotCommon.sol";
import "../token/PeggedToken.sol";

/**
@dev CertToken is a familiy of ERC20-compliant token which are issued by a DABot
to represent users' staked assets. A DABot could accept several staked assets. Each
staked asset will have a corresponding CertToken. By staking to a DABot, users recieve
an equivalent amount of CertToken. These CertToken tokens are used to claim interests as
well as the staked assets.

The interest of CertToken comes from the trading activities of a DABot. This means the 
interest could be either positve or negative.
 */
contract CertToken is PeggedToken {

    constructor() PeggedToken("", "", IERC20(address(0))) {

    } 
 
    function init(bytes calldata data) external virtual payable override {
        require(address(asset) == address(0), "CertToken: contract initialized");
        (asset, _owner) = abi.decode(data, (IERC20, address));
    }

    function name() public view override returns(string memory) {
        IDABot bot = IDABot(_owner);
        return string(abi.encodePacked(bot.botSymbol(), " ", IRoboFiToken(address(asset)).symbol(), " Certificate"));
    }

    function symbol() public view override returns(string memory) {
        IDABot bot = IDABot(_owner);
        return string(abi.encodePacked(bot.botSymbol(), IRoboFiToken(address(asset)).symbol()));
    }

    function decimals() public view override returns (uint8) {
        return IRoboFiToken(address(asset)).decimals();
    }

    function _transferToken(address payor, uint amount) internal override {
        // Do nothing, the token should be transfer from the owner bot.
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../common/Factory.sol";

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
        address certToken;    // the certificate asset to return to stake-users
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
        uint8 botType;              // type of the bot (inherits from the bot's template)
        string botSymbol;           // get the bot name.
        string botName;             // get the bot full name.
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
    
    function botType() view external returns(uint8);
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
    event BotDeployed(uint botId, address indexed bot, DABotCommon.BotDetail detail);
    event CertTokenDeployed(address indexed bot, address indexed asset, address indexed certtoken);
    event TemplateRegistered(address indexed template, string name, uint8 templateType);
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

import "./RoboFiToken.sol";

/**
@dev Prepresent a token which is pegged by another asset. To mint a pegged token, users have
to deposit an amount of asset. At any time, users could get back the deposited asset by 
burning the pegged tokens. Pegged token is a kind of interest-beared token, which means 
that over time each minted pegged token could have higher value than the orginal deposited 
assets. However, it could suffer a loss, i.e., negative interest.

PeggedToken is used as the base of certificate token issued by DABot. Users stake their 
asset to the bot and get back certificate token. If the trading (done by DABot operators)
gets profit, holders of certificate token will get positive interest pro-rata to their 
staked amount. On the other hand, if the trading gets loss, certificate token holders 
will suffer the trading loss, also pro-rata to their staked amount.
 */
contract PeggedToken is RoboFiToken {

    IERC20 public asset;
    uint public pointSupply;

    address internal _owner;        // only token owner could mint and burn the token. 
                                    // in most cases, the token owner is the DABot, not human.
                                    
    mapping(address => uint) private _pointBalances;

    modifier onlyOwner() {
        require(_msgSender() == _owner, "PeggedToken: permission denied");
        _;
    }

    event Mint(address indexed recepient, uint256 amount, uint256 point);
    event ClaimReward(address indexed sender, uint256 rewards, uint256 point);

    constructor(string memory name, string memory symbol, IERC20 peggedAsset) RoboFiToken(name, symbol, 0, _msgSender()) {
        asset = peggedAsset;
        _owner = _msgSender();
    }

    function init(bytes calldata data) external virtual payable override {
        require(address(asset) == address(0), "PeggedToken: contract initialized");
        (_name, _symbol, asset, _owner) = abi.decode(data, (string, string, IERC20, address));
        asset.approve(_owner, type(uint256).max);
    }

    function finalize() external onlyOwner {
        require(totalSupply() == 0, "PeggedToken: need to burn all tokens first");

        selfdestruct(payable(_owner));
    }

    function mulPointRate(uint256 value) internal view returns (uint256) {
        return pointSupply == 0 ? value : (value * asset.balanceOf(address(this)) / pointSupply);
    }

    function divPointRate(uint256 value) internal view returns (uint256) {
        return pointSupply == 0 ? value: (value * pointSupply / asset.balanceOf(address(this)));
    } 

    function pointBalanceOf(address sender) external view returns (uint256) {
        return _pointBalances[sender];
    }

    function mint(address recepient, uint amount) external onlyOwner payable returns (uint256) {
        return _mint(recepient, recepient, amount);
    }

    function mintTo(address payor, address recepient, uint amount) external onlyOwner payable returns(uint256) {
        return _mint(payor, recepient, amount);
    }

    function _mint(address payor, address recepient, uint amount) internal returns(uint256 mintedPoint) {
        mintedPoint = divPointRate(amount);
        _transferToken(payor, amount);
        super._mint(recepient, amount);
        _pointBalances[recepient] += mintedPoint;
        pointSupply += mintedPoint;

        emit Mint(recepient, amount, mintedPoint);
    }

    function _transferToken(address payor, uint amount) internal virtual {
        if (payor != address(0))
            asset.transferFrom(payor, address(this), amount);
    }

    function burn(address account, uint amount) external onlyOwner {
        _burn(account, amount);
    }

    function burn(uint amount) external {
        _burn(_msgSender(), amount);
    }

    function claimReward() external returns(uint) {
        return _claimReward(_msgSender());
    }

    function claimRewardFor(address account) external onlyOwner returns(uint) {
        return _claimReward(account);
    }

    function _claimReward(address account) internal returns(uint reward) {
        reward = getClaimableReward(account);
        if (reward == 0)
            return 0;

        uint256 newPointBalance = divPointRate(balanceOf(account));
        uint256 diffPointBalance = _pointBalances[account] - newPointBalance;

        _pointBalances[account] = newPointBalance;
        pointSupply -= diffPointBalance;

        asset.transfer(account, reward);

        emit ClaimReward(account, reward, newPointBalance);
    }

    function getClaimableReward(address reciever) public view returns(uint) {
        uint256 pointValue = mulPointRate(_pointBalances[reciever]);
        uint256 balance = balanceOf(reciever);
        return pointValue >= balance ? pointValue - balance : 0;
    }

    function _beforeTokenTransfer(address sender, address, uint256) internal override {
        if (sender != address(0))
            _claimReward(sender);
    }

    function _afterTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        uint256 point = amount * _pointBalances[sender] / (balanceOf(sender) + amount);

        _pointBalances[sender] -= point;

        if (recipient != address(0)) { // transfer point
            _pointBalances[recipient] += point;
        } else { // burn point
            pointSupply -= point;
            asset.transfer(sender, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../common/IMasterContract.sol";
import "./IRoboFiToken.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract RoboFiToken is Context, IRoboFiToken, IMasterContract {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_, uint256 initAmount_, address holder_) {
        _name = name_;
        _symbol = symbol_;
        if (holder_ != address(0))
            _mint(holder_, initAmount_);
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (string name, string symbol, uint256 initSupply address holder)
    function init(bytes calldata data) external virtual payable override {
        require(_totalSupply == 0, "RT: contract is already initialized");
        uint256 _initSupply;
        address _holder;
        (_name, _symbol, _initSupply, _holder) = abi.decode(data, (string, string, uint256, address));
        if (_initSupply > 0)
            _mint(_holder, _initSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "RT: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "RT: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "RT: transfer from the zero address");
        require(recipient != address(0), "RT: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "RT: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        _afterTokenTransfer(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "RT: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "RT: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _internalBurn(account, amount);

        _afterTokenTransfer(account, address(0), amount);

        emit Transfer(account, address(0), amount);
    }

    function _internalBurn(address account, uint256 amount) internal {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "RT: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "RT: approve from the zero address");
        require(spender != address(0), "RT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

