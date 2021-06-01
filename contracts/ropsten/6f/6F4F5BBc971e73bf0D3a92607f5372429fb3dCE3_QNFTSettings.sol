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
    event SetPriceMultipliers(
        uint256 tokenPriceMultiplier,
        uint256 nonTokenPriceMultiplier,
        uint256 upgradePriceMultiplier
    );
    event AddLockOption(
        uint256 minAmount,
        uint256 maxAmount,
        uint32 lockDuration,
        uint8 discount // percent
    );
    event UpdateLockOption(
        uint32 indexed lockOptionId,
        uint256 minAmount,
        uint256 maxAmount,
        uint32 lockDuration,
        uint8 discount // percent
    );
    event AddCharacters(uint256[] prices, uint256 maxSupply);
    event UpdateCharacterPrice(uint32 indexed characterId, uint256 price);
    event UpdateCharacterPrices(
        uint32 startIndex,
        uint32 length,
        uint256 price
    );
    event UpdateCharacterPricesFromArray(uint32[] indexes, uint256[] prices);
    event UpdateCharacterMaxSupply(
        uint32 indexed characterId,
        uint256 maxSupply
    );
    event UpdateCharacterMaxSupplies(
        uint32 startIndex,
        uint32 length,
        uint256 supply
    );
    event UpdateCharacterMaxSuppliesFromArray(
        uint32[] indexes,
        uint256[] supplies
    );
    event AddFavCoinPrices(uint256[] mintPrices);
    event UpdateFavCoinPrice(uint32 favCoinId, uint256 price);
    event StartMint(uint256 startedAt);
    event EndMint();
    event PauseMint(uint256 pausedAt);
    event UnpauseMint(uint256 unPausedAt);

    // constants
    uint32 public NFT_SALE_DURATION; // default: 2 weeks

    // mint options set
    uint256 public qstkPrice; // qstk price
    uint256 public nonTokenPriceMultiplier; // percentage - should be multiplied to non token price - image + favorite coin
    uint256 public tokenPriceMultiplier; // percentage - should be multiplied to token price - qstk
    uint256 public override upgradePriceMultiplier; // percentage - should be multiplied to coin mint price - favorite coin - used for favorite coin upgrade price calculation

    LockOption[] public lockOptions; // array of lock options
    uint256[] private _characterPrices; // array of character purchase prices
    uint256[] private _characterMaxSupply; // limitation count for the given character
    uint256[] private _favCoinPrices; // array of favorite coin purchase prices

    // mint options set
    uint256 public override mintStartTime;
    bool public override mintStarted;
    bool public override mintPaused;
    bool public override onlyAirdropUsers;

    // By default, transfer is not allowed for redeemed NFTs to prevent spam sell. Users can transfer redeemed NFTS after this flag is enabled.
    bool public override transferAllowedAfterRedeem;

    IQSettings public settings; // QSettings contract address

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(
            settings.getManager() == msg.sender,
            "QNFTSettings: caller is not the manager"
        );
        _;
    }

    function initialize(
        address _settings,
        uint256 _qstkPrice,
        uint256 _tokenPriceMultiplier,
        uint256 _nonTokenPriceMultiplier,
        uint256 _upgradePriceMultiplier,
        uint32 _nftSaleDuration
    ) external initializer {
        __Context_init();

        settings = IQSettings(_settings);
        qstkPrice = _qstkPrice;
        nonTokenPriceMultiplier = _nonTokenPriceMultiplier;
        tokenPriceMultiplier = _tokenPriceMultiplier;
        upgradePriceMultiplier = _upgradePriceMultiplier;
        NFT_SALE_DURATION = _nftSaleDuration;

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
    function lockOptionLockDuration(uint32 _lockOptionId)
        external
        view
        override
        returns (uint32)
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
        uint32 _lockDuration,
        uint8 _discount
    ) external onlyManager {
        require(_discount <= 100, "QNFTSettings: invalid discount");
        lockOptions.push(
            LockOption(_minAmount, _maxAmount, _lockDuration, _discount)
        );

        emit AddLockOption(_minAmount, _maxAmount, _lockDuration, _discount);
    }

    /**
     * @dev update a lock option
     */
    function updateLockOption(
        uint32 _lockOptionId,
        uint256 _minAmount,
        uint256 _maxAmount,
        uint32 _lockDuration,
        uint8 _discount
    ) external onlyManager {
        require(
            lockOptions.length > _lockOptionId,
            "QNFTSettings: invalid lock option id"
        );
        require(_discount <= 100, "QNFTSettings: invalid discount");

        lockOptions[_lockOptionId] = LockOption(
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );

        emit UpdateLockOption(
            _lockOptionId,
            _minAmount,
            _maxAmount,
            _lockDuration,
            _discount
        );
    }

    function characterPrice(uint32 _characterId)
        external
        view
        override
        returns (uint256)
    {
        return _characterPrices[_characterId];
    }

    /**
     * @dev returns the count of nft characters
     */
    function characterCount() public view override returns (uint256) {
        return _characterPrices.length;
    }

    /**
     * @dev adds new character mint prices/max supplies
     */
    function addCharacters(uint256[] memory _prices, uint256 _maxSupply)
        external
        onlyManager
    {
        for (uint256 i = 0; i < _prices.length; i++) {
            _characterPrices.push(_prices[i]);
            _characterMaxSupply.push(_maxSupply);
        }

        emit AddCharacters(_prices, _maxSupply);
    }

    /**
     * @dev updates a character price
     */
    function updateCharacterPrice(uint32 _characterId, uint256 _price)
        external
        onlyManager
    {
        require(
            _characterPrices.length > _characterId,
            "QNFTSettings: invalid character id"
        );

        _characterPrices[_characterId] = _price;

        emit UpdateCharacterPrice(_characterId, _price);
    }

    /**
     * @dev updates multiple character prices
     */
    function updateCharacterPrices(
        uint32 _startIndex,
        uint32 _length,
        uint256 _price
    ) external onlyManager {
        require(
            _characterPrices.length >= _startIndex + _length,
            "QNFTSettings: invalid character ids range"
        );

        for (uint256 i = 0; i < _length; i++) {
            _characterPrices[_startIndex + i] = _price;
        }

        emit UpdateCharacterPrices(_startIndex, _length, _price);
    }

    /**
     * @dev updates multiple character prices
     */
    function updateCharacterPricesFromArray(
        uint32[] memory _indexes,
        uint256[] memory _prices
    ) external onlyManager {
        require(
            _indexes.length == _prices.length,
            "QNFTSettings: length doesn't match"
        );

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                _indexes[i] < _characterPrices.length,
                "QNFTSettings: invalid index"
            );
            _characterPrices[_indexes[i]] = _prices[i];
        }

        emit UpdateCharacterPricesFromArray(_indexes, _prices);
    }

    function characterMaxSupply(uint32 _characterId)
        external
        view
        override
        returns (uint256)
    {
        return _characterMaxSupply[_characterId];
    }

    /**
     * @dev updates a character max supply
     */
    function updateCharacterMaxSupply(uint32 _characterId, uint256 _maxSupply)
        external
        onlyManager
    {
        require(
            _characterMaxSupply.length > _characterId,
            "QNFTSettings: invalid character id"
        );

        _characterMaxSupply[_characterId] = _maxSupply;

        emit UpdateCharacterMaxSupply(_characterId, _maxSupply);
    }

    /**
     * @dev updates multiple character max supplies
     */
    function updateCharacterMaxSupplies(
        uint32 _startIndex,
        uint32 _length,
        uint256 _supply
    ) external onlyManager {
        require(
            _characterMaxSupply.length >= _startIndex + _length,
            "QNFTSettings: invalid character ids range"
        );

        for (uint256 i = 0; i < _length; i++) {
            _characterMaxSupply[_startIndex + i] = _supply;
        }

        emit UpdateCharacterMaxSupplies(_startIndex, _length, _supply);
    }

    /**
     * @dev updates multiple character max supplies
     */
    function updateCharacterMaxSuppliesFromArray(
        uint32[] memory _indexes,
        uint256[] memory _supplies
    ) external onlyManager {
        require(
            _indexes.length == _supplies.length,
            "QNFTSettings: length doesn't match"
        );

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                _indexes[i] < _characterMaxSupply.length,
                "QNFTSettings: invalid index"
            );
            _characterMaxSupply[_indexes[i]] = _supplies[i];
        }

        emit UpdateCharacterMaxSuppliesFromArray(_indexes, _supplies);
    }

    function favCoinPrices(uint32 _favCoinId)
        external
        view
        override
        returns (uint256)
    {
        return _favCoinPrices[_favCoinId];
    }

    /**
     * @dev returns the count of favorite coins
     */
    function favCoinsCount() public view override returns (uint256) {
        return _favCoinPrices.length;
    }

    /**
     * @dev adds new favorite coins
     */
    function addFavCoinPrices(uint256[] memory _prices) external onlyManager {
        for (uint16 i = 0; i < _prices.length; i++) {
            _favCoinPrices.push(_prices[i]);
        }

        emit AddFavCoinPrices(_prices);
    }

    /**
     * @dev updates a favorite coin
     */
    function updateFavCoinPrice(uint32 _favCoinId, uint256 _price)
        external
        onlyManager
    {
        require(_favCoinPrices.length > _favCoinId, "QNFTSettings: invalid id");

        _favCoinPrices[_favCoinId] = _price;

        emit UpdateFavCoinPrice(_favCoinId, _price);
    }

    /**
     * @dev calculate mint price of given mint options
     */
    function calcMintPrice(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    )
        external
        view
        override
        returns (
            uint256 totalPrice,
            uint256 tokenPrice,
            uint256 nonTokenPrice
        )
    {
        require(
            characterCount() > _characterId,
            "QNFTSettings: invalid character option"
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

        uint256 decimal =
            IERC20MetadataUpgradeable(settings.getQStk()).decimals();
        tokenPrice =
            (qstkPrice *
                _lockAmount *
                (100 - lockOption.discount) *
                tokenPriceMultiplier) /
            (10**decimal) /
            10000;

        nonTokenPrice =
            ((_characterPrices[_characterId] + _favCoinPrices[_favCoinId]) *
                nonTokenPriceMultiplier) /
            100;

        totalPrice = tokenPrice + nonTokenPrice;
    }

    function setPriceMultipliers(
        uint256 _tokenPriceMultiplier,
        uint256 _nonTokenPriceMultiplier,
        uint256 _upgradePriceMultiplier
    ) external onlyManager {
        tokenPriceMultiplier = _tokenPriceMultiplier;
        nonTokenPriceMultiplier = _nonTokenPriceMultiplier;
        upgradePriceMultiplier = _upgradePriceMultiplier;

        emit SetPriceMultipliers(
            _tokenPriceMultiplier,
            _nonTokenPriceMultiplier,
            _upgradePriceMultiplier
        );
    }

    /**
     * @dev starts/restarts mint process
     */
    function startMint() external onlyManager {
        mintStarted = true;
        mintStartTime = block.timestamp;
        mintPaused = false;

        emit StartMint(mintStartTime);
    }

    /**
     * @dev ends mint process
     */
    function endMint() external onlyManager {
        require(
            mintStarted == true && !mintFinished(),
            "QNFTSettings: mint not in progress"
        );
        mintStartTime = block.timestamp - NFT_SALE_DURATION;

        emit EndMint();
    }

    /**
     * @dev pause mint process
     */
    function pauseMint() external onlyManager {
        require(
            mintStarted == true && !mintFinished(),
            "QNFTSettings: mint not in progress"
        );
        require(mintPaused == false, "QNFTSettings: mint already paused");

        mintPaused = true;

        emit PauseMint(block.timestamp);
    }

    /**
     * @dev unpause mint process
     */
    function unPauseMint() external onlyManager {
        require(
            mintStarted == true && !mintFinished(),
            "QNFTSettings: mint not in progress"
        );
        require(mintPaused == true, "QNFTSettings: mint not paused");

        mintPaused = false;

        emit UnpauseMint(block.timestamp);
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

    function setOnlyAirdropUsers(bool _onlyAirdropUsers) external onlyManager {
        onlyAirdropUsers = _onlyAirdropUsers;
    }

    function setTransferAllowedAfterRedeem(bool _allow) external onlyManager {
        transferAllowedAfterRedeem = _allow;
    }

    function setSettings(IQSettings _settings) external onlyManager {
        settings = _settings;
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
    uint32 lockDuration; // e.g. 3 months, 6 months, 1 year
    uint8 discount; // percent e.g. 10%, 20%, 30%
}

struct NFTData {
    // NFT data
    uint32 characterId;
    uint32 favCoinId;
    uint32 metaId;
    uint32 unlockTime;
    uint256 lockAmount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQNFTSettings {
    function favCoinsCount() external view returns (uint256);

    function lockOptionsCount() external view returns (uint256);

    function characterCount() external view returns (uint256);

    function characterPrice(uint32 characterId) external view returns (uint256);

    function favCoinPrices(uint32 favCoinId) external view returns (uint256);

    function lockOptionLockDuration(uint32 lockOptionId)
        external
        view
        returns (uint32);

    function characterMaxSupply(uint32 characterId)
        external
        view
        returns (uint256);

    function calcMintPrice(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint256 _lockAmount,
        uint256 _freeAmount
    )
        external
        view
        returns (
            uint256 totalPrice,
            uint256 tokenPrice,
            uint256 nonTokenPrice
        );

    function mintStarted() external view returns (bool);

    function mintPaused() external view returns (bool);

    function mintStartTime() external view returns (uint256);

    function mintEndTime() external view returns (uint256);

    function mintFinished() external view returns (bool);

    function onlyAirdropUsers() external view returns (bool);

    function transferAllowedAfterRedeem() external view returns (bool);

    function upgradePriceMultiplier() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IQSettings {
    function getManager() external view returns (address);

    function getFoundationWallet() external view returns (address);

    function getQStk() external view returns (address);

    function getQAirdrop() external view returns (address);

    function getQNftSettings() external view returns (address);

    function getQNftGov() external view returns (address);

    function getQNft() external view returns (address);
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