// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interface/structs.sol";
import "../interface/IQNFTSettings.sol";
import "../interface/IQSettings.sol";

/**
 * @author fantasy
 */
contract QNFTSettings is IQNFTSettings, ContextUpgradeable {
    // events
    event SetNonTokenPriceMultiplier(
        address indexed owner,
        uint256 nonTokenPriceMultiplier
    );
    event SetTokenPriceMultiplier(
        address indexed owner,
        uint256 tokenPriceMultiplier
    );
    event AddLockOption(
        address indexed owner,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 lockDuration,
        uint256 discount // percent
    );
    event UpdateLockOption(
        address indexed owner,
        uint256 indexed lockOptionId,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 lockDuration,
        uint256 discount // percent
    );
    event AddCharacterPrices(address indexed owner, uint256[] prices);
    event UpdateCharacterPrice(
        address indexed owner,
        uint256 indexed characterId,
        uint256 price
    );
    event AddFavCoinPrices(address indexed owner, uint256[] mintPrices);
    event UpdateFavCoinPrice(
        address indexed owner,
        uint256 favCoinId,
        uint256 price
    );
    event StartMint(address indexed owner, uint256 startedAt);
    event PauseMint(address indexed owner, uint256 pausedAt);
    event UnpauseMint(address indexed owner, uint256 unPausedAt);

    // constants
    uint256 public constant PERCENT_MAX = 100;
    uint256 public constant NFT_SALE_DURATION = 1209600; // 2 weeks

    // mint options set
    uint256 public qstkPrice; // qstk price
    uint256 public nonTokenPriceMultiplier; // percentage - should be multiplied to non token price - image + coin
    uint256 public tokenPriceMultiplier; // percentage - should be multiplied to token price - qstk

    LockOption[] public lockOptions; // array of lock options
    uint16 public override bgImageCount; // count of background images
    uint256[] public override characterPrices; // array of character purchase prices
    uint256[] public override favCoinPrices; // array of favorite coin purchase prices

    // mint options set
    bool public override onlyAirdropUsers;
    bool public override mintStarted;
    bool public override mintPaused;
    uint256 public override mintStartTime;

    IQSettings public settings; // QSettings contract address

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(
            settings.manager() == msg.sender,
            "QNFTSettings: caller is not the manager"
        );
        _;
    }

    function initialize(address _settings) external initializer {
        __Context_init();
        qstkPrice = 0.00001 ether; // qstk price = 0.00001 ether
        nonTokenPriceMultiplier = PERCENT_MAX; // non token price multiplier = 100%;
        tokenPriceMultiplier = PERCENT_MAX; // token price multiplier = 100%;
        settings = IQSettings(_settings);
        onlyAirdropUsers = true;
    }

    /**
     * @dev returns the count of lock options
     */
    function lockOptionsCount() public view override returns (uint256) {
        return lockOptions.length;
    }

    /**
     * @dev returns the lock duration of given lock option id
     */
    function lockOptionLockDuration(uint256 _lockOptionId)
        public
        view
        override
        returns (uint256)
    {
        require(
            _lockOptionId < lockOptions.length,
            "QNFTSettings: invalid lock option"
        );

        return lockOptions[_lockOptionId].lockDuration;
    }

    /**
     * @dev adds a new lock option
     */
    function addLockOption(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _lockDuration,
        uint8 _discount
    ) public onlyManager {
        require(_discount < PERCENT_MAX, "QNFTSettings: invalid discount");
        lockOptions.push(
            LockOption(_minAmount, _maxAmount, _lockDuration, _discount)
        );

        emit AddLockOption(
            msg.sender,
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );
    }

    /**
     * @dev update a lock option
     */
    function updateLockOption(
        uint256 _lockOptionId,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _lockDuration,
        uint8 _discount
    ) public onlyManager {
        uint256 length = lockOptions.length;
        require(length > _lockOptionId, "QNFTSettings: invalid lock option id");

        lockOptions[_lockOptionId] = LockOption(
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );

        emit UpdateLockOption(
            msg.sender,
            _lockOptionId,
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );
    }

    /**
     * @dev sets background image count
     */
    function setBgImageCount(uint16 _bgImageCount) public onlyManager {
        bgImageCount = _bgImageCount;
    }

    /**
     * @dev returns the count of nft characters
     */
    function characterCount() public view override returns (uint256) {
        return characterPrices.length;
    }

    /**
     * @dev adds a new nft iamges set
     */
    function addCharacterPrices(uint256[] memory _characterPrices)
        public
        onlyManager
    {
        uint256 length = _characterPrices.length;
        for (uint256 i = 0; i < length; i++) {
            characterPrices.push(_characterPrices[i]);
        }

        emit AddCharacterPrices(msg.sender, _characterPrices);
    }

    /**
     * @dev removes a nft character
     */
    function updateCharacterPrice(uint256 _characterId, uint256 _price)
        public
        onlyManager
    {
        uint256 length = characterPrices.length;
        require(length > _characterId, "QNFTSettings: invalid character id");

        characterPrices[_characterId] = _price;

        emit UpdateCharacterPrice(msg.sender, _characterId, _price);
    }

    /**
     * @dev returns the count of favorite coins
     */
    function favCoinsCount() public view override returns (uint256) {
        return favCoinPrices.length;
    }

    /**
     * @dev adds a new favorite coin
     */
    function addFavCoinPrices(uint256[] memory _favCoinPrices)
        public
        onlyManager
    {
        uint256 length = _favCoinPrices.length;
        for (uint16 i = 0; i < length; i++) {
            favCoinPrices.push(_favCoinPrices[i]);
        }

        emit AddFavCoinPrices(msg.sender, _favCoinPrices);
    }

    /**
     * @dev removes a favorite coin
     */
    function updateFavCoinPrice(uint256 _favCoinId, uint256 _price)
        public
        onlyManager
    {
        uint256 length = favCoinPrices.length;
        require(length > _favCoinId, "QNFTSettings: invalid id");

        favCoinPrices[_favCoinId] = _price;

        emit UpdateFavCoinPrice(msg.sender, _favCoinId, _price);
    }

    /**
     * @dev calculate mint price of given mint options
     */
    function calcMintPrice(
        uint256 _characterId,
        uint256 _bgImageId,
        uint256 _favCoinId,
        uint256 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    ) public view override returns (uint256) {
        require(
            characterCount() > _characterId,
            "QNFTSettings: invalid character option"
        );
        require(
            bgImageCount > _bgImageId,
            "QNFTSettings: invalid background option"
        );
        require(
            lockOptionsCount() > _lockOptionId,
            "QNFTSettings: invalid lock option"
        );
        require(favCoinsCount() > _favCoinId, "QNFTSettings: invalid fav coin");

        LockOption memory lockOption = lockOptions[_lockOptionId];

        require(
            lockOption.minAmount <= _lockAmount + _freeAmount &&
                _lockAmount <= lockOption.maxAmount,
            "QNFTSettings: invalid mint amount"
        );

        // mintPrice = qstkPrice * lockAmount * discountRate * tokenPriceMultiplier + (characterMintPrice + favCoinMintPrice) * nonTokenPriceMultiplier

        uint256 decimal = IERC20MetadataUpgradeable(settings.qstk()).decimals();
        uint256 tokenPrice =
            (qstkPrice *
                _lockAmount *
                (uint256(PERCENT_MAX) - lockOption.discount)) /
                (10**decimal) /
                PERCENT_MAX;
        tokenPrice = (tokenPrice * tokenPriceMultiplier) / PERCENT_MAX;

        uint256 nonTokenPrice =
            characterPrices[_characterId] + favCoinPrices[_favCoinId];
        nonTokenPrice = (nonTokenPrice * nonTokenPriceMultiplier) / PERCENT_MAX;

        return tokenPrice + nonTokenPrice;
    }

    /**
     * @dev sets token price multiplier - qstk
     */
    function setTokenPriceMultiplier(uint256 _tokenPriceMultiplier)
        public
        onlyManager
    {
        tokenPriceMultiplier = _tokenPriceMultiplier;

        emit SetTokenPriceMultiplier(msg.sender, tokenPriceMultiplier);
    }

    /**
     * @dev sets non token price multiplier - character + coins
     */
    function setNonTokenPriceMultiplier(uint256 _nonTokenPriceMultiplier)
        public
        onlyManager
    {
        nonTokenPriceMultiplier = _nonTokenPriceMultiplier;

        emit SetNonTokenPriceMultiplier(msg.sender, nonTokenPriceMultiplier);
    }

    /**
     * @dev starts/restarts mint process
     */
    function startMint() public onlyManager {
        require(!mintStarted || mintFinished(), "QNFT: mint in progress");

        mintStarted = true;
        mintStartTime = block.timestamp;
        mintPaused = false;

        emit StartMint(msg.sender, mintStartTime);
    }

    /**
     * @dev pause mint process
     */
    function pauseMint() public onlyManager {
        require(
            mintStarted == true && !mintFinished(),
            "QNFT: mint not in progress"
        );
        require(mintPaused == false, "QNFT: mint already paused");

        mintPaused = true;

        emit PauseMint(msg.sender, block.timestamp);
    }

    /**
     * @dev unpause mint process
     */
    function unPauseMint() public onlyManager {
        require(
            mintStarted == true && !mintFinished(),
            "QNFT: mint not in progress"
        );
        require(mintPaused == true, "QNFT: mint not paused");

        mintPaused = false;

        emit UnpauseMint(msg.sender, block.timestamp);
    }

    /**
     * @dev returns the mint end time
     */
    function mintEndTime() public view override returns (uint256) {
        return mintStartTime + NFT_SALE_DURATION;
    }

    /**
     * @dev checks if mint process is finished
     */
    function mintFinished() public view override returns (bool) {
        return mintStarted && mintEndTime() <= block.timestamp;
    }

    function setOnlyAirdropUsers(bool _onlyAirdropUsers) public onlyManager {
        onlyAirdropUsers = _onlyAirdropUsers;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// structs
struct LockOption {
    uint256 minAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 maxAmount; // e.g. 0QSTK, 100QSTK, 200QSTK, 300QSTK
    uint256 lockDuration; // e.g. 3 months, 6 months, 1 year
    uint8 discount; // percent e.g. 10%, 20%, 30%
}

struct NFTData {
    // NFT data
    uint256 characterId;
    uint256 bgImageId;
    uint256 favCoinId;
    uint256 lockDuration;
    uint256 lockAmount;
    uint256 defaultEmotionIndex;
    uint256 createdAt;
    bool withdrawn;
    string metaUrl;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFTSettings {
    function favCoinsCount() external view returns (uint256);

    function lockOptionsCount() external view returns (uint256);

    function characterCount() external view returns (uint256);

    function bgImageCount() external view returns (uint16);

    function characterPrices(uint256 _nftCharacterId)
        external
        view
        returns (uint256);

    function favCoinPrices(uint256 _favCoinId) external view returns (uint256);

    function lockOptionLockDuration(uint256 _lockOptionId)
        external
        view
        returns (uint256);

    function calcMintPrice(
        uint256 _characterId,
        uint256 _bgImageId,
        uint256 _favCoinId,
        uint256 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    ) external view returns (uint256);

    function mintStarted() external view returns (bool);

    function mintPaused() external view returns (bool);

    function mintStartTime() external view returns (uint256);

    function mintEndTime() external view returns (uint256);

    function mintFinished() external view returns (bool);

    function onlyAirdropUsers() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQSettings {
    function manager() external view returns (address);

    function qstk() external view returns (address);

    function foundation() external view returns (address);
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
interface IERC20Upgradeable {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}