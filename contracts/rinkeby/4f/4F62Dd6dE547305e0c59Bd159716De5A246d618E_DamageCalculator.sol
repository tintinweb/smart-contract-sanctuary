// SPDX-License-Identifier: MIT

/// @title RaidParty Party Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IParty.sol";
import "../interfaces/IDamageCalculator.sol";
import "../interfaces/IHero.sol";
import "../interfaces/IFighter.sol";
import "../interfaces/IEquipment.sol";
import "../interfaces/IHeroURIHandler.sol";
import "../interfaces/IFighterURIHandler.sol";
import "../interfaces/IEquipmentURIHandler.sol";

contract DamageCalculator is IDamageCalculator, Initializable {
    IHero private _hero;
    IFighter private _fighter;
    IEquipment private _equipment;

    uint32 private constant PRECISION = 1000;

    function initialize(
        address hero,
        address fighter,
        address equipment
    ) external initializer {
        _hero = IHero(hero);
        _fighter = IFighter(fighter);
        _equipment = IEquipment(equipment);
    }

    function getHero() external view returns (address) {
        return address(_hero);
    }

    function getFighter() external view returns (address) {
        return address(_fighter);
    }

    function getEquipment() external view returns (address) {
        return address(_equipment);
    }

    function getDamage(
        uint256 hero,
        uint256[] calldata fighters,
        uint256[] calldata equipment
    ) external view override returns (uint32) {
        if (hero == 0) {
            return 0;
        }

        uint256 f = 0;
        uint256 d = 0;
        uint256 m = 0;

        Stats.HeroStats memory hStats = IHeroURIHandler(_hero.getHandler())
            .getStats(hero);
        m = hStats.dmgMultiplier;
        m += ((hStats.enhancement * PRECISION) / 5) / PRECISION;

        for (uint256 i = 0; i < hStats.partySize; i++) {
            if (fighters[i] != 0) {
                Stats.FighterStats memory fStats = IFighterURIHandler(
                    _fighter.getHandler()
                ).getStats(fighters[i]);
                f +=
                    (fStats.dmg *
                        (PRECISION + ((fStats.enhancement * PRECISION) / 5))) /
                    PRECISION;
            }
        }

        for (uint256 i = 0; i < equipment.length; i++) {
            if (equipment[i] != 0) {
                Stats.EquipmentStats memory eStats = IEquipmentURIHandler(
                    _equipment.getHandler()
                ).getStats(equipment[i]);
                d += eStats.dmg;
                m += eStats.dmgMultiplier;
            }
        }

        return uint32(m * (2500 + f + d));
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IParty {
    struct PartyData {
        uint256 hero;
        mapping(uint256 => uint256) fighters;
        mapping(uint256 => uint256) equipment;
        uint32 dmg;
    }

    event Equipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event Unequipped(address indexed user, uint8 item, uint8 slot, uint256 id);

    event DamageUpdated(
        address indexed user,
        uint32 damagePrev,
        uint32 damageCurr
    );

    function equip(
        uint8 item,
        uint8 id,
        uint8 slot
    ) external;

    function unequip(uint8 item, uint8 slot) external;

    function enhance(
        uint8 item,
        uint8 slot,
        uint256 burnTokenId
    ) external;

    function updateDamage(address user) external;

    function updateDamageBatch(address[] calldata users) external;

    function getHero(address user) external view returns (uint256);

    function getFighters(address user) external view returns (uint256[] memory);

    function getEquipment(address user)
        external
        view
        returns (uint256[] memory);

    function getDamage(address user) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IDamageCalculator {
    function getDamage(
        uint256 hero,
        uint256[] calldata fighters,
        uint256[] calldata equipment
    ) external view returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IHeroURIHandler.sol";
import "./ISeeder.sol";

interface IHero is IERC721 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    event SeederUpdated(address indexed caller, address indexed seeder);

    function setHandler(IHeroURIHandler handler) external;

    function getHandler() external view returns (address);

    function setSeeder(ISeeder seeder) external;

    function getSeeder() external view returns (address);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IFighterURIHandler.sol";
import "./ISeeder.sol";

interface IFighter is IERC721 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    event SeederUpdated(address indexed caller, address indexed seeder);

    function setHandler(IFighterURIHandler handler) external;

    function getHandler() external view returns (address);

    function setSeeder(ISeeder seeder) external;

    function getSeeder() external view returns (address);

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IEquipmentURIHandler.sol";

interface IEquipment is IERC1155 {
    event HandlerUpdated(address indexed caller, address indexed handler);

    function setHandler(IEquipmentURIHandler handler) external;

    function getHandler() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnhanceable.sol";
import "../lib/Stats.sol";

interface IHeroURIHandler is IEnhanceable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.HeroStats memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IEnhanceable.sol";
import "../lib/Stats.sol";

interface IFighterURIHandler is IEnhanceable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.FighterStats memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Stats.sol";

interface IEquipmentURIHandler {
    function uri(uint256 tokenId) external view returns (string memory);

    function getStats(uint256 tokenId)
        external
        view
        returns (Stats.EquipmentStats memory);

    function updateStats(uint256 tokenId, Stats.EquipmentStats memory stats)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Stats {
    struct HeroStats {
        uint8 dmgMultiplier;
        uint8 partySize;
        uint8 enhancement;
    }

    struct FighterStats {
        uint32 dmg;
        uint8 enhancement;
    }

    struct EquipmentStats {
        uint32 dmg;
        uint8 dmgMultiplier;
        uint8 slot;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
pragma solidity ^0.8.0;

interface ISeeder {
    struct RandomnessRequest {
        uint256 block;
        uint256 identifier;
    }

    struct SeedData {
        uint256 randomnessId;
        bool requested;
    }

    event Seeding(address indexed caller, uint256 indexed identifier);

    event Seeded(
        address indexed caller,
        uint256 indexed identifier,
        uint256 seed
    );

    event Requested(address indexed caller, uint256 indexed identifier);

    function requestSeed(uint256 identifier) external;

    function getSeed(uint256 identifier) external view returns (uint256);

    function getQueueTop() external view returns (uint256);

    function getQueueBottom() external view returns (uint256);

    function executeRequest(uint256 request) external;

    function executeRequestMulti(uint256 count) external;

    function isSeeded(uint256 identifier) external view returns (bool);

    function setFee(uint256 fee) external;

    function getFee() external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnhanceable {
    function enhancementCost(uint256 tokenId) external view returns (uint256);

    function enhance(uint256 tokenId, uint256 burnTokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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