// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IChimERC721Upgradeable.sol";
import "./IChimERC1155Upgradeable.sol";

contract ChimSwapERC721UpgradeableV1 is Initializable, ContextUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // Chim erc 721 contract address
    address private _chimErc721Address;
    // Chim erc 1155 contract address
    address private _chimErc1155Address;

    // Chim erc 1155 available stars token id list
    mapping(uint8 => uint256[]) private _starsTokenIds;

    // Loot type data
    struct LootTypeData {
        mapping(uint8 => uint16) mainTokenStarsPercents;
        uint256[] additionalTokenIds;
        uint256[] additionalTokenAmounts;
        uint256 totalOpened;
    }
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%
    mapping(uint256 => LootTypeData) private _lootTypes;

    // Reward data
    struct RewardData {
        uint256[] tokenIds;
        uint256[] tokenAmounts;
    }
    mapping(uint256 => RewardData) private _lootRewards;

    // Chim swap data
    uint256 private _randomData;

    // Emitted when available stars token ids updated
    event StarsTokenIdsUpdated(uint8 stars, uint256[] starsTokenIds);

    // Emitted when lootType created/updated
    event LootTypeUpdated(uint256 lootTypeId, uint16 mainTokenStar1Percent, uint16 mainTokenStar2Percent, uint16 mainTokenStar3Percent, uint16 mainTokenStar4Percent, uint16 mainTokenStar5Percent, uint256[] additionalTokenIds, uint256[] additionalTokenAmounts);

    // Emitted when loot opened
    event LootOpened(uint256 nftErc721TokenId, uint256 lootTypeId, uint256 randomStarData, uint256 randomTokenData, uint8 mainTokenStars, uint256 mainTokenId);

    function initialize(
        address chimErc721Address_,
        address chimErc1155Address_
    ) public virtual initializer {
        __ChimSwapERC721_init(chimErc721Address_, chimErc1155Address_);
    }

    function __ChimSwapERC721_init(
        address chimErc721Address_,
        address chimErc1155Address_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __ChimSwapERC721_init_unchained(chimErc721Address_, chimErc1155Address_);
    }

    function __ChimSwapERC721_init_unchained(
        address chimErc721Address_,
        address chimErc1155Address_
    ) internal initializer {
        require(chimErc721Address_ != address(0), "ChimSwapERC721: invalid erc721 address");
        require(chimErc1155Address_ != address(0), "ChimSwapERC721: invalid erc1155 address");
        _chimErc721Address = chimErc721Address_;
        _chimErc1155Address = chimErc1155Address_;
    }

    function getChimErc721Address() external view virtual returns (address) {
        return _chimErc721Address;
    }

    function getChimErc1155Address() external view virtual returns (address) {
        return _chimErc1155Address;
    }

    function getStarsTokenIds(uint8 stars_) external view virtual returns (uint256[] memory) {
        return _starsTokenIds[stars_];
    }

    function getLootType(uint256 lootTypeId_)
        external
        view
        virtual
        returns (
            uint16 mainTokenStar1Percent,
            uint16 mainTokenStar2Percent,
            uint16 mainTokenStar3Percent,
            uint16 mainTokenStar4Percent,
            uint16 mainTokenStar5Percent,
            uint256[] memory additionalTokenIds,
            uint256[] memory additionalTokenAmounts,
            uint256 totalOpened
        )
    {
        LootTypeData storage lootType = _lootTypes[lootTypeId_];
        return (
            lootType.mainTokenStarsPercents[1],
            lootType.mainTokenStarsPercents[2],
            lootType.mainTokenStarsPercents[3],
            lootType.mainTokenStarsPercents[4],
            lootType.mainTokenStarsPercents[5],
            lootType.additionalTokenIds,
            lootType.additionalTokenAmounts,
            lootType.totalOpened
        );
    }

    function getLootReward(uint256 nftErc721TokenId_)
        external
        view
        virtual
        returns (
            uint256[] memory tokenIds,
            uint256[] memory tokenAmounts
        )
    {
        RewardData storage lootReward =_lootRewards[nftErc721TokenId_];
        return (
            lootReward.tokenIds,
            lootReward.tokenAmounts
        );
    }

    function checkBeforeOpenLoot(address nftErc721TokenOwner_, uint256 nftErc721TokenId_) public view virtual returns (bool) {
        require(!paused(), "ChimSwapERC721: paused");
        require(IChimERC721Upgradeable(_chimErc721Address).exists(nftErc721TokenId_) && IChimERC721Upgradeable(_chimErc721Address).ownerOf(nftErc721TokenId_) == nftErc721TokenOwner_, "ChimSwapERC721: invalid check token existence or owner");
        require(!IChimERC721Upgradeable(_chimErc721Address).paused(), "ChimSwapERC721: chimErc721 is paused");
        uint256 lootTypeId = IChimERC721Upgradeable(_chimErc721Address).getTokenTypeId(nftErc721TokenId_);
        LootTypeData storage lootType = _lootTypes[lootTypeId];
        require((lootType.mainTokenStarsPercents[1] + lootType.mainTokenStarsPercents[2] + lootType.mainTokenStarsPercents[3] + lootType.mainTokenStarsPercents[4] + lootType.mainTokenStarsPercents[5]) == _100_PERCENT, "ChimSwapERC721: invalid lootType stars percents");
        require((lootType.mainTokenStarsPercents[1] == 0 || (lootType.mainTokenStarsPercents[1] != 0 && _starsTokenIds[1].length != 0)), "ChimSwapERC721: invalid check star 1 tokens");
        require((lootType.mainTokenStarsPercents[2] == 0 || (lootType.mainTokenStarsPercents[2] != 0 && _starsTokenIds[2].length != 0)), "ChimSwapERC721: invalid check star 2 tokens");
        require((lootType.mainTokenStarsPercents[3] == 0 || (lootType.mainTokenStarsPercents[3] != 0 && _starsTokenIds[3].length != 0)), "ChimSwapERC721: invalid check star 3 tokens");
        require((lootType.mainTokenStarsPercents[4] == 0 || (lootType.mainTokenStarsPercents[4] != 0 && _starsTokenIds[4].length != 0)), "ChimSwapERC721: invalid check star 4 tokens");
        require((lootType.mainTokenStarsPercents[5] == 0 || (lootType.mainTokenStarsPercents[5] != 0 && _starsTokenIds[5].length != 0)), "ChimSwapERC721: invalid check star 5 tokens");
        require(!IChimERC1155Upgradeable(_chimErc1155Address).paused() && IChimERC1155Upgradeable(_chimErc1155Address).isApprovedMinter(address(this)), "ChimSwapERC721: chimErc1155 is paused or not approved minter");
        return true;
    }

    function getMainToken(
        uint256 randomStarData_,
        uint256 randomTokenData_,
        uint256 lootTypeId_
    ) public view returns (uint256 mainTokenId, uint8 mainTokenStars) {
        LootTypeData storage lootType = _lootTypes[lootTypeId_];
        require((lootType.mainTokenStarsPercents[1] + lootType.mainTokenStarsPercents[2] + lootType.mainTokenStarsPercents[3] + lootType.mainTokenStarsPercents[4] + lootType.mainTokenStarsPercents[5]) == _100_PERCENT, "ChimSwapERC721: invalid lootType stars percents");

        uint16 checksPercent = 0;
        uint16 randomStarValue = uint16((randomStarData_ ^ (randomStarData_ >> 64) ^ (randomStarData_ >> 128) ^ (randomStarData_ >> 192)) % _100_PERCENT);
        for (uint8 stars = 1; stars <= 5; stars++) {
            require(lootType.mainTokenStarsPercents[stars] == 0 || (lootType.mainTokenStarsPercents[stars] != 0 && _starsTokenIds[stars].length != 0), "ChimSwapERC721: invalid starsTokenIds length");
            checksPercent += lootType.mainTokenStarsPercents[stars];
            if (randomStarValue < checksPercent) {
                uint16 randomTokenValue = uint16((randomTokenData_ ^ (randomTokenData_ >> 64) ^ (randomTokenData_ >> 128) ^ (randomTokenData_ >> 192)) % _starsTokenIds[stars].length);
                mainTokenStars = stars;
                mainTokenId = _starsTokenIds[stars][randomTokenValue];
                break;
            }
        }

        return (
            mainTokenId,
            mainTokenStars
        );
    }

    function openLoot(uint256 nftErc721TokenId_) external virtual nonReentrant whenNotPaused {
        require(checkBeforeOpenLoot(_msgSender(), nftErc721TokenId_), "ChimSwapERC721: open loot not allowed");
        require(IChimERC721Upgradeable(_chimErc721Address).getApproved(nftErc721TokenId_) == address(this) || IChimERC721Upgradeable(_chimErc721Address).isApprovedForAll(_msgSender(), address(this)), "ChimSwapERC721: open loot not approved");

        uint256 lootTypeId = IChimERC721Upgradeable(_chimErc721Address).getTokenTypeId(nftErc721TokenId_);
        LootTypeData storage lootType = _lootTypes[lootTypeId];
        lootType.totalOpened += 1;

        (uint256 randomStarData, uint256 randomTokenData) = getRandomValues(_msgSender(), nftErc721TokenId_, lootTypeId, lootType.totalOpened);
        (uint256 mainTokenId, uint8 mainTokenStars) = getMainToken(randomStarData, randomTokenData, lootTypeId);
        _randomData = _randomData ^ randomStarData ^ randomTokenData;

        uint256 batchLength = lootType.additionalTokenIds.length + 1;
        uint256[] memory batchTokenIds = new uint256[](batchLength);
        uint256[] memory batchTokenAmounts = new uint256[](batchLength);

        batchTokenIds[0] = mainTokenId;
        batchTokenAmounts[0] = 1;
        for (uint256 index = 0; index < lootType.additionalTokenIds.length; index++) {
            batchTokenIds[index + 1] = lootType.additionalTokenIds[index];
            batchTokenAmounts[index + 1] = lootType.additionalTokenAmounts[index];
        }

        RewardData storage lootReward =_lootRewards[nftErc721TokenId_];
        lootReward.tokenIds = batchTokenIds;
        lootReward.tokenAmounts = batchTokenAmounts;

        IChimERC721Upgradeable(_chimErc721Address).burn(nftErc721TokenId_);
        IChimERC1155Upgradeable(_chimErc1155Address).mintBatch(_msgSender(), batchTokenIds, batchTokenAmounts, "");

        emit LootOpened(nftErc721TokenId_, lootTypeId, randomStarData, randomTokenData, mainTokenStars, mainTokenId);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateStarsTokenIds(uint8 stars_, uint256[] memory tokenIds_) external virtual onlyOwner {
        require(stars_ >= 1 && stars_ <= 5, "ChimSwapERC721: invalid stars");
        _starsTokenIds[stars_] = tokenIds_;
        emit StarsTokenIdsUpdated(stars_, tokenIds_);
    }

    function updateLootType(
        uint256 lootTypeId_,
        uint16 mainTokenStar1Percent_,
        uint16 mainTokenStar2Percent_,
        uint16 mainTokenStar3Percent_,
        uint16 mainTokenStar4Percent_,
        uint16 mainTokenStar5Percent_,
        uint256[] memory additionalTokenIds_,
        uint256[] memory additionalTokenAmounts_
    ) external virtual onlyOwner {
        require(lootTypeId_ != 0, "ChimSwapERC721: invalid lootTypeId");
        require((mainTokenStar1Percent_ + mainTokenStar2Percent_ + mainTokenStar3Percent_ + mainTokenStar4Percent_ + mainTokenStar5Percent_) == _100_PERCENT,  "ChimSwapERC721: invalid stars percentage sum");
        require(additionalTokenIds_.length == additionalTokenAmounts_.length, "ChimSwapERC721: arrays length mismatch");

        LootTypeData storage lootType = _lootTypes[lootTypeId_];
        lootType.mainTokenStarsPercents[1] = mainTokenStar1Percent_;
        lootType.mainTokenStarsPercents[2] = mainTokenStar2Percent_;
        lootType.mainTokenStarsPercents[3] = mainTokenStar3Percent_;
        lootType.mainTokenStarsPercents[4] = mainTokenStar4Percent_;
        lootType.mainTokenStarsPercents[5] = mainTokenStar5Percent_;
        lootType.additionalTokenIds = additionalTokenIds_;
        lootType.additionalTokenAmounts = additionalTokenAmounts_;

        emit LootTypeUpdated(lootTypeId_, mainTokenStar1Percent_, mainTokenStar2Percent_, mainTokenStar3Percent_, mainTokenStar4Percent_, mainTokenStar5Percent_, additionalTokenIds_, additionalTokenAmounts_);
    }

    function getRandomValues(
        address nftErc721TokenOwner_,
        uint256 nftErc721TokenId_,
        uint256 lootTypeId_,
        uint256 lootTypeTotalOpened_
    )
        internal
        virtual
        view
        returns (
            uint256 randomStarData,
            uint256 randomTokenData
        )
    {
        uint256 startValue = uint256(keccak256(abi.encodePacked(
            nftErc721TokenOwner_,
            nftErc721TokenId_,
            lootTypeTotalOpened_,
            block.difficulty,
            lootTypeId_,
            _randomData,
            block.number
        )));
        uint256 value1 = uint256(keccak256(abi.encodePacked(
            block.number,
            (startValue >> 64),
            lootTypeTotalOpened_,
            block.difficulty,
            nftErc721TokenId_
        )));
        uint256 value2 = uint256(keccak256(abi.encodePacked(
            startValue,
            lootTypeId_,
            nftErc721TokenOwner_,
            block.difficulty,
            value1
        )));
        randomStarData = (value1 ^ (value2 >> 79) ^ (value1 >> 107) ^ (value2 >> 199));
        randomTokenData = (value2 ^ (value1 >> 37) ^ (value2 >> 131) ^ (value1 >> 193));
        return (
            randomStarData,
            randomTokenData
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IChimERC721Upgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    // public read methods
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function paused() external view returns (bool);
    function exists(uint256 tokenId) external view returns (bool);
    function existsBatch(uint256[] memory tokenIds) external view returns (bool[] memory);
    function getTypesCount() external view returns (uint256);
    function getType(uint256 typeId) external view returns (string memory name, string memory uri, uint256 totalSupply);
    function getTokenTypeId(uint256 tokenId) external view returns (uint256);

    // public write methods
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IChimERC1155Upgradeable is IERC1155Upgradeable {
    // public read methods
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function owner() external view returns (address);
    function getOwner() external view returns (address);
    function paused() external view returns (bool);
    function royaltyParams() external view returns (address royaltyAddress, uint256 royaltyPercent);
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function exists(uint256 tokenId) external view returns (bool);
    function uri(uint256 tokenId) external view returns (string memory);
    function totalSupply(uint256 tokenId) external view returns (uint256);
    function tokenInfo(uint256 tokenId) external view returns (uint256 tokenSupply, string memory tokenURI);
    function tokenInfoBatch(uint256[] memory tokenIds) external view returns (uint256[] memory batchTokenSupplies, string[] memory batchTokenURIs);
    function isApprovedMinter(address minterAddress) external view returns (bool);

    // public write methods
    function burn(address account, uint256 tokenId, uint256 value) external;
    function burnBatch(address account, uint256[] memory tokenIds, uint256[] memory values) external;

    // minter write methods
    function setTokenURI(uint256 tokenId, string memory tokenURI) external;
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}