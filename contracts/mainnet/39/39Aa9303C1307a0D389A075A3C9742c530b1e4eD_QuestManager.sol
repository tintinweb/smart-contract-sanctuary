/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity 0.8.6;


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

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

library SignatureVerifier {
    function verify(
        address signer,
        address account,
        uint256[] calldata ids,
        bytes calldata signature
    ) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(account, ids);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function verify(
        address signer,
        uint256 id,
        address[] calldata accounts,
        bytes calldata signature
    ) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(id, accounts);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function getMessageHash(address account, uint256[] memory ids) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, ids));
    }
    function getMessageHash(uint256 id, address[] memory accounts) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, accounts));
    }

    function getEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        //solium-disable-next-line
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}

contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
}

interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

abstract contract ImmutableModule is ModuleKeys {
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Nexus contract address
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return SavingsManager Module address from the Nexus
     * @return Address of the SavingsManager Module contract
     */
    function _savingsManager() internal view returns (address) {
        return nexus.getModule(KEY_SAVINGS_MANAGER);
    }

    /**
     * @dev Return Recollateraliser Module address from the Nexus
     * @return  Address of the Recollateraliser Module contract (Phase 2)
     */
    function _recollateraliser() internal view returns (address) {
        return nexus.getModule(KEY_RECOLLATERALISER);
    }

    /**
     * @dev Return Liquidator Module address from the Nexus
     * @return  Address of the Liquidator Module contract
     */
    function _liquidator() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Nexus
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }
}

library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

struct Balance {
    /// units of staking token that has been deposited and consequently wrapped
    uint88 raw;
    /// (block.timestamp - weightedTimestamp) represents the seconds a user has had their full raw balance wrapped.
    /// If they deposit or withdraw, the weightedTimestamp is dragged towards block.timestamp proportionately
    uint32 weightedTimestamp;
    /// multiplier awarded for staking for a long time
    uint8 timeMultiplier;
    /// multiplier duplicated from QuestManager
    uint8 questMultiplier;
    /// Time at which the relative cooldown began
    uint32 cooldownTimestamp;
    /// Units up for cooldown
    uint88 cooldownUnits;
}

struct QuestBalance {
    /// last timestamp at which the user made a write action to this contract
    uint32 lastAction;
    /// permanent multiplier applied to an account, awarded for PERMANENT QuestTypes
    uint8 permMultiplier;
    /// multiplier that decays after each "season" (~9 months) by 75%, to avoid multipliers getting out of control
    uint8 seasonMultiplier;
}

/// @notice Quests can either give permanent rewards or only for the season
enum QuestType {
    PERMANENT,
    SEASONAL
}

/// @notice Quests can be turned off by the questMaster. All those who already completed remain
enum QuestStatus {
    ACTIVE,
    EXPIRED
}

struct Quest {
    /// Type of quest rewards
    QuestType model;
    /// Multiplier, from 1 == 1.01x to 100 == 2.00x
    uint8 multiplier;
    /// Is the current quest valid?
    QuestStatus status;
    /// Expiry date in seconds for the quest
    uint32 expiry;
}

interface IQuestManager {
    event QuestAdded(
        address questMaster,
        uint256 id,
        QuestType model,
        uint16 multiplier,
        QuestStatus status,
        uint32 expiry
    );
    event QuestCompleteQuests(address indexed user, uint256[] ids);
    event QuestCompleteUsers(uint256 indexed questId, address[] accounts);
    event QuestExpired(uint16 indexed id);
    event QuestMaster(address oldQuestMaster, address newQuestMaster);
    event QuestSeasonEnded();
    event QuestSigner(address oldQuestSigner, address newQuestSigner);
    event StakedTokenAdded(address stakedToken);

    // GETTERS
    function balanceData(address _account) external view returns (QuestBalance memory);

    function getQuest(uint256 _id) external view returns (Quest memory);

    function hasCompleted(address _account, uint256 _id) external view returns (bool);

    function questMaster() external view returns (address);

    function seasonEpoch() external view returns (uint32);

    // ADMIN
    function addQuest(
        QuestType _model,
        uint8 _multiplier,
        uint32 _expiry
    ) external;

    function addStakedToken(address _stakedToken) external;

    function expireQuest(uint16 _id) external;

    function setQuestMaster(address _newQuestMaster) external;

    function setQuestSigner(address _newQuestSigner) external;

    function startNewQuestSeason() external;

    // USER
    function completeUserQuests(
        address _account,
        uint256[] memory _ids,
        bytes calldata _signature
    ) external;

    function completeQuestUsers(
        uint256 _questId,
        address[] memory _accounts,
        bytes calldata _signature
    ) external;

    function checkForSeasonFinish(address _account) external returns (uint8 newQuestMultiplier);
}

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

interface IStakedToken {
    // GETTERS
    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);

    function STAKED_TOKEN() external view returns (IERC20);

    function getRewardToken() external view returns (address);

    function pendingAdditionalReward() external view returns (uint256);

    function whitelistedWrappers(address) external view returns (bool);

    function balanceData(address _account) external view returns (Balance memory);

    function balanceOf(address _account) external view returns (uint256);

    function rawBalanceOf(address _account) external view returns (uint256, uint256);

    function calcRedemptionFeeRate(uint32 _weightedTimestamp)
        external
        view
        returns (uint256 _feeRate);

    function safetyData()
        external
        view
        returns (uint128 collateralisationRatio, uint128 slashingPercentage);

    function delegates(address account) external view returns (address);

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getVotes(address account) external view returns (uint256);

    // HOOKS/PERMISSIONED
    function applyQuestMultiplier(address _account, uint8 _newMultiplier) external;

    // ADMIN
    function whitelistWrapper(address _wrapper) external;

    function blackListWrapper(address _wrapper) external;

    function changeSlashingPercentage(uint256 _newRate) external;

    function emergencyRecollateralisation() external;

    function setGovernanceHook(address _newHook) external;

    // USER
    function stake(uint256 _amount) external;

    function stake(uint256 _amount, address _delegatee) external;

    function stake(uint256 _amount, bool _exitCooldown) external;

    function withdraw(
        uint256 _amount,
        address _recipient,
        bool _amountIncludesFee,
        bool _exitCooldown
    ) external;

    function delegate(address delegatee) external;

    function startCooldown(uint256 _units) external;

    function endCooldown() external;

    function reviewTimestamp(address _account) external;

    function claimReward() external;

    function claimReward(address _to) external;

    // Backwards compatibility
    function createLock(uint256 _value, uint256) external;

    function exit() external;

    function increaseLockAmount(uint256 _value) external;

    function increaseLockLength(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
/**
 * @title   QuestManager
 * @author  mStable
 * @notice  Centralised place to track quest management and completion status
 * @dev     VERSION: 1.0
 *          DATE:    2021-08-25
 */
contract QuestManager is IQuestManager, Initializable, ContextUpgradeable, ImmutableModule {
    /// @notice Tracks the completion of each quest (user => questId => completion)
    mapping(address => mapping(uint256 => bool)) private _questCompletion;

    /// @notice User balance structs containing all data needed to scale balance
    mapping(address => QuestBalance) internal _balances;

    /// @notice List of quests, whose ID corresponds to their position in the array (from 0)
    Quest[] private _quests;
    /// @notice Timestamp at which the current season started
    uint32 public override seasonEpoch;
    /// @notice Timestamp at which the contract was created
    uint32 public startTime;

    /// @notice A whitelisted questMaster who can administer quests including signing user quests are completed.
    address public override questMaster;
    /// @notice account that can sign a user's quest as being completed.
    address internal _questSigner;

    /// @notice List of all staking tokens
    address[] internal _stakedTokens;

    /**
     * @param _nexus System nexus
     */
    constructor(address _nexus) ImmutableModule(_nexus) {}

    /**
     * @param _questMaster account that can sign user quests as completed
     * @param _questSignerArg account that can sign user quests as completed
     */
    function initialize(address _questMaster, address _questSignerArg) external initializer {
        startTime = SafeCast.toUint32(block.timestamp);
        questMaster = _questMaster;
        _questSigner = _questSignerArg;
    }

    /**
     * @dev Checks that _msgSender is either governor or the quest master
     */
    modifier questMasterOrGovernor() {
        _questMasterOrGovernor();
        _;
    }

    function _questMasterOrGovernor() internal view {
        require(_msgSender() == questMaster || _msgSender() == _governor(), "Not verified");
    }

    /***************************************
                    Getters
    ****************************************/

    /**
     * @notice Gets raw quest data
     */
    function getQuest(uint256 _id) external view override returns (Quest memory) {
        return _quests[_id];
    }

    /**
     * @dev Simply checks if a given user has already completed a given quest
     * @param _account User address
     * @param _id Position of quest in array
     * @return bool with completion status
     */
    function hasCompleted(address _account, uint256 _id) public view override returns (bool) {
        return _questCompletion[_account][_id];
    }

    /**
     * @notice Raw quest balance
     */
    function balanceData(address _account) external view override returns (QuestBalance memory) {
        return _balances[_account];
    }

    /***************************************
                    Admin
    ****************************************/

    /**
     * @dev Sets the quest master that can administoer quests. eg add, expire and start seasons.
     */
    function setQuestMaster(address _newQuestMaster) external override questMasterOrGovernor {
        emit QuestMaster(questMaster, _newQuestMaster);

        questMaster = _newQuestMaster;
    }

    /**
     * @dev Sets the quest signer that can sign user quests as being completed.
     */
    function setQuestSigner(address _newQuestSigner) external override onlyGovernor {
        emit QuestSigner(_questSigner, _newQuestSigner);

        _questSigner = _newQuestSigner;
    }

    /**
     * @dev Adds a new stakedToken
     */
    function addStakedToken(address _stakedToken) external override onlyGovernor {
        require(_stakedToken != address(0), "Invalid StakedToken");

        _stakedTokens.push(_stakedToken);

        emit StakedTokenAdded(_stakedToken);
    }

    /***************************************
                    QUESTS
    ****************************************/

    /**
     * @dev Called by questMasters to add a new quest to the system with default 'ACTIVE' status
     * @param _model Type of quest rewards multiplier (does it last forever or just for the season).
     * @param _multiplier Multiplier, from 1 == 1.01x to 100 == 2.00x
     * @param _expiry Timestamp at which quest expires. Note that permanent quests should still be given a timestamp.
     */
    function addQuest(
        QuestType _model,
        uint8 _multiplier,
        uint32 _expiry
    ) external override questMasterOrGovernor {
        require(_expiry > block.timestamp + 1 days, "Quest window too small");
        require(_multiplier > 0 && _multiplier <= 50, "Quest multiplier too large > 1.5x");

        _quests.push(
            Quest({
                model: _model,
                multiplier: _multiplier,
                status: QuestStatus.ACTIVE,
                expiry: _expiry
            })
        );

        emit QuestAdded(
            msg.sender,
            _quests.length - 1,
            _model,
            _multiplier,
            QuestStatus.ACTIVE,
            _expiry
        );
    }

    /**
     * @dev Called by questMasters to expire a quest, setting it's status as EXPIRED. After which it can
     * no longer be completed.
     * @param _id Quest ID (its position in the array)
     */
    function expireQuest(uint16 _id) external override questMasterOrGovernor {
        require(_id < _quests.length, "Quest does not exist");
        require(_quests[_id].status == QuestStatus.ACTIVE, "Quest already expired");

        _quests[_id].status = QuestStatus.EXPIRED;
        if (block.timestamp < _quests[_id].expiry) {
            _quests[_id].expiry = SafeCast.toUint32(block.timestamp);
        }

        emit QuestExpired(_id);
    }

    /**
     * @dev Called by questMasters to start a new quest season. After this, all current
     * seasonMultipliers will be reduced at the next user action (or triggered manually).
     * In order to reduce cost for any keepers, it is suggested to add quests at the start
     * of a new season to incentivise user actions.
     * A new season can only begin after 9 months has passed.
     */
    function startNewQuestSeason() external override questMasterOrGovernor {
        require(block.timestamp > (startTime + 39 weeks), "First season has not elapsed");
        require(block.timestamp > (seasonEpoch + 39 weeks), "Season has not elapsed");

        uint256 len = _quests.length;
        for (uint256 i = 0; i < len; i++) {
            Quest memory quest = _quests[i];
            if (quest.model == QuestType.SEASONAL) {
                require(
                    quest.status == QuestStatus.EXPIRED || block.timestamp > quest.expiry,
                    "All seasonal quests must have expired"
                );
            }
        }

        seasonEpoch = SafeCast.toUint32(block.timestamp);

        emit QuestSeasonEnded();
    }

    /***************************************
                    USER
    ****************************************/

    /**
     * @dev Called by anyone to complete one or more quests for a staker. The user must first collect a signed message
     * from the whitelisted _signer.
     * @param _account Account that has completed the quest
     * @param _ids Quest IDs (its position in the array)
     * @param _signature Signature from the verified _questSigner, containing keccak hash of account & ids
     */
    function completeUserQuests(
        address _account,
        uint256[] memory _ids,
        bytes calldata _signature
    ) external override {
        uint256 len = _ids.length;
        require(len > 0, "No quest IDs");

        uint8 questMultiplier = checkForSeasonFinish(_account);

        // For each quest
        for (uint256 i = 0; i < len; i++) {
            require(_validQuest(_ids[i]), "Invalid Quest ID");
            require(!hasCompleted(_account, _ids[i]), "Quest already completed");
            require(
                SignatureVerifier.verify(_questSigner, _account, _ids, _signature),
                "Invalid Quest Signer Signature"
            );

            // Store user quest has completed
            _questCompletion[_account][_ids[i]] = true;

            // Update multiplier
            Quest memory quest = _quests[_ids[i]];
            if (quest.model == QuestType.PERMANENT) {
                _balances[_account].permMultiplier += quest.multiplier;
            } else {
                _balances[_account].seasonMultiplier += quest.multiplier;
            }
            questMultiplier += quest.multiplier;
        }

        uint256 len2 = _stakedTokens.length;
        for (uint256 i = 0; i < len2; i++) {
            IStakedToken(_stakedTokens[i]).applyQuestMultiplier(_account, questMultiplier);
        }

        emit QuestCompleteQuests(_account, _ids);
    }

    /**
     * @dev Called by anyone to complete one or more accounts for a quest. The user must first collect a signed message
     * from the whitelisted _questMaster.
     * @param _questId Quest ID (its position in the array)
     * @param _accounts Accounts that has completed the quest
     * @param _signature Signature from the verified _questMaster, containing keccak hash of id and accounts
     */
    function completeQuestUsers(
        uint256 _questId,
        address[] memory _accounts,
        bytes calldata _signature
    ) external override {
        require(_validQuest(_questId), "Invalid Quest ID");
        uint256 len = _accounts.length;
        require(len > 0, "No accounts");
        require(
            SignatureVerifier.verify(_questSigner, _questId, _accounts, _signature),
            "Invalid Quest Signer Signature"
        );

        Quest memory quest = _quests[_questId];

        // For each user account
        for (uint256 i = 0; i < len; i++) {
            require(!hasCompleted(_accounts[i], _questId), "Quest already completed");

            // store user quest has completed
            _questCompletion[_accounts[i]][_questId] = true;

            // _applyQuestMultiplier(_accounts[i], quests);
            uint8 questMultiplier = checkForSeasonFinish(_accounts[i]);

            // Update multiplier
            if (quest.model == QuestType.PERMANENT) {
                _balances[_accounts[i]].permMultiplier += quest.multiplier;
            } else {
                _balances[_accounts[i]].seasonMultiplier += quest.multiplier;
            }
            questMultiplier += quest.multiplier;

            uint256 len2 = _stakedTokens.length;
            for (uint256 j = 0; j < len2; j++) {
                IStakedToken(_stakedTokens[j]).applyQuestMultiplier(_accounts[i], questMultiplier);
            }
        }

        emit QuestCompleteUsers(_questId, _accounts);
    }

    /**
     * @dev Simply checks if a quest is valid. Quests are valid if their id exists,
     * they have an ACTIVE status and they have not yet reached their expiry timestamp.
     * @param _id Position of quest in array
     * @return bool with validity status
     */
    function _validQuest(uint256 _id) internal view returns (bool) {
        return
            _id < _quests.length &&
            _quests[_id].status == QuestStatus.ACTIVE &&
            block.timestamp < _quests[_id].expiry;
    }

    /**
     * @dev Checks if the season has just finished between now and the users last action.
     * If it has, we reset the seasonMultiplier. Either way, we update the lastAction for the user.
     * NOTE - it is important that this is called as a hook before each state change operation
     * @param _account Address of user that should be updated
     */
    function checkForSeasonFinish(address _account)
        public
        override
        returns (uint8 newQuestMultiplier)
    {
        QuestBalance storage balance = _balances[_account];
        // If the last action was before current season, then reset the season timing
        if (_hasFinishedSeason(balance.lastAction)) {
            // Remove 85% of the multiplier gained in this season
            balance.seasonMultiplier = (balance.seasonMultiplier * 15) / 100;
            balance.lastAction = SafeCast.toUint32(block.timestamp);
        }
        return balance.seasonMultiplier + balance.permMultiplier;
    }

    /**
     * @dev Simple view fn to check if the users last action was before the starting of the current season
     */
    function _hasFinishedSeason(uint32 _lastAction) internal view returns (bool) {
        return _lastAction < seasonEpoch;
    }
}