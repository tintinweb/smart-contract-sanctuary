// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// Openzeppelin
import '@openzeppelin/contracts/utils/Strings.sol';
import './helpers/WarpBase.sol';

// helpers
import './helpers/Base64.sol';

// interfaces
import './interfaces/IBond.sol';
import './interfaces/IStarshipParts.sol';
import './interfaces/IStarshipPartsControl.sol';

contract StarshipPartsControl is IStarshipPartsControl, WarpBase {
    using Strings for uint256;

    /* ======== EVENTS ======== */
    event PermanentURI(string _value, uint256 indexed _id);
    event PartCreated(
        address account,
        uint256 partId,
        uint256 strength,
        string typeOf,
        uint256 minValue
    );
    event BuildFuel(address from, address to, uint256 partId, uint256 strength);
    event UseFuel(address account, uint256 fuelId, uint256 currentAmount, uint256 amountUsed);

    //* ======== Variables ======== */
    mapping(address => bool) internal bondTokens;
    mapping(address => bool) internal hangars;
    mapping(uint256 => PartInfo) internal parts;

    mapping(PartType => uint256) totals;
    PartType nextPart;

    address starshipParts;
    uint256 counter;
    uint256 public maxIntegrity;
    uint256 public maxParts;
    uint256 public minimumValue;
    uint256 multiplier;

    //* ======== Modifiers ======== */

    /** @notice Only Bond Tokens can call X function */
    modifier onlyBondTokens() {
        require(bondTokens[msg.sender], 'BondToken: Oops not a bond token.');
        _;
    }

    /** @notice Only hangars can call X function */
    modifier onlyHangar() {
        require(hangars[msg.sender], 'BondToken: Oops not a hangar');
        _;
    }

    /** ===== Initialize ===== */
    function initialize() public initializer {
        __WarpBase_init(); // also inits ownable

        multiplier = 1;
        maxIntegrity = 5000;
        maxParts = 10250; // 10,250 spaceships
        nextPart = PartType.BRIDGE;
        minimumValue = 250000000000; // 250$
    }

    /**
     *  @notice allow mint for bond
     *  @param _to address
     *  @param _strength uint256
     */
    function buildFuel(address _to, uint256 _strength) external onlyOwner {
        // Mint and set
        IStarshipParts(starshipParts).mint(_to, counter);
        parts[counter] = PartInfo({strength: _strength, typeOf: PartType.FUEL});

        // Update counter and emit
        emit BuildFuel(msg.sender, _to, counter, parts[counter].strength);
        counter += 1;
    }

    /**
     *  @notice allow mint for bond
     *  @param _to address
     *  @param _paid uint256 note: USD in 9 decimals. 10000000000 <-- 10$
     */
    function buildPart(address _to, uint256 _paid)
        public
        override
        whenNotPaused
        onlyBondTokens
        returns (uint256)
    {
        // Ensure minimum price paid.
        require(_paid >= minimumValue, 'Minimum value not paid');

        // Get Starship part data
        uint256 tokenId = counter;
        PartType typeOf = getPartType();
        uint256 strength = typeOf == PartType.FUEL
            ? ((_paid / 1e9) + 1) * multiplier
            : min(((_paid / 1e9) + 1) * multiplier, maxIntegrity);

        // note: this is purely for test cases and since we are on matic, we don't really care about gas right? :kek:
        if (strength == 0) strength = 1;

        // Mint and set
        IStarshipParts(starshipParts).mint(_to, tokenId);
        parts[tokenId] = PartInfo({strength: strength, typeOf: typeOf});

        // Update counter and emit
        counter += 1;
        emit PartCreated(
            _to,
            tokenId,
            parts[tokenId].strength,
            getStringPartType(parts[tokenId].typeOf),
            minimumValue
        );

        return tokenId;
    }

    /**
     *  @notice burn nft for bond
     *  @param tokenId uint
     */
    function usePart(uint256 tokenId) public override whenNotPaused onlyHangar {
        IStarshipParts(starshipParts).burn(tokenId);
    }

    /** @dev useFuel
        @param _fuelId {integer}
        @param _amount {integer}
     */
    function useFuel(uint256 _fuelId, uint256 _amount) external override whenNotPaused onlyHangar {
        require(parts[_fuelId].typeOf == PartType.FUEL, 'Not fuel');

        emit UseFuel(
            IStarshipParts(starshipParts).ownerOf(_fuelId),
            _fuelId,
            parts[_fuelId].strength,
            _amount
        );

        parts[_fuelId].strength -= _amount;
        if (parts[_fuelId].strength == 0) usePart(_fuelId);
    }

    /** @dev setMinimumValue */
    function setMinimumValue(uint256 _min) external onlyOwner {
        minimumValue = _min;
    }

    /** @dev setMinimumValue */
    function setMaxIntegrity(uint256 _max) external onlyOwner {
        maxIntegrity = _max;
    }

    /** @dev setMaxParts */
    function setMaxParts(uint256 _max) external onlyOwner {
        maxParts = _max;
    }

    /** @notice add an allowed bond contract to bond token */
    function setBondToken(address _bondToken, bool _set) external onlyOwner {
        bondTokens[_bondToken] = _set;
    }

    /** @notice add an allowed hangar contract to hangar token */
    function setHangar(address _hangar, bool _set) external onlyOwner {
        hangars[_hangar] = _set;
    }

    /** @notice Set starship parts */
    function setStarshipParts(address _address) external onlyOwner {
        starshipParts = _address;
    }

    /** @notice Set strength multiplier */
    function setMultiplier(uint256 _multiplier) external onlyOwner {
        multiplier = _multiplier;
    }

    /** === GETTERS */

    /** @dev getMinimumValue */
    function getMinimumValue() external view override returns (uint256) {
        return minimumValue;
    }

    /** @notice get part type enum based on tokenId */
    function getPartType() internal returns (PartType) {
        if (
            totals[PartType.BRIDGE] >= maxParts &&
            totals[PartType.HULL] >= maxParts &&
            totals[PartType.ENGINE] >= maxParts
        ) return PartType.FUEL;

        if (nextPart == PartType.BRIDGE) {
            totals[PartType.BRIDGE] += 1;
            nextPart = PartType.HULL;
            return PartType.BRIDGE;
        } else if (nextPart == PartType.HULL) {
            totals[PartType.HULL] += 1;
            nextPart = PartType.ENGINE;
            return PartType.HULL;
        } else if (nextPart == PartType.ENGINE) {
            totals[PartType.ENGINE] += 1;
            nextPart = PartType.FUEL;
            return PartType.ENGINE;
        }

        // First part is a bridge
        totals[PartType.FUEL] += 1;
        nextPart = PartType.BRIDGE;
        return PartType.FUEL;
    }

    /** @notice get count for specific part type */
    function getPartCount(PartType typeOf) external view override returns (uint256) {
        return totals[typeOf];
    }

    /** @notice get string */
    function getStringPartType(PartType typeOf) public pure override returns (string memory) {
        if (typeOf == PartType.BRIDGE) return 'Bridge';
        if (typeOf == PartType.HULL) return 'Hull';
        if (typeOf == PartType.ENGINE) return 'Engine';
        if (typeOf == PartType.FUEL) return 'Fuel';

        return 'Unknown';
    }

    /** @notice get bond info */
    function getPartInfo(uint256 _tokenId) external view override returns (PartInfo memory) {
        return parts[_tokenId];
    }

    /** @notice get last starship part id */
    function getCounter() external view override returns (uint256) {
        return counter;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract WarpBase is Initializable {
    bool public paused;
    address public owner;
    mapping(address => bool) public pausers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseChanged(address indexed by, bool indexed paused);

    /** ========  MODIFIERS ========  */

    /** @notice modifier for owner only calls */
    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    /** @notice pause toggler */
    modifier onlyPauseToggler() {
        require(owner == msg.sender || pausers[msg.sender], 'Ownable: caller is not the owner');
        _;
    }

    /** @notice modifier for pausing contracts */
    modifier whenNotPaused() {
        require(!paused || owner == msg.sender || pausers[msg.sender], 'Feature is paused');
        _;
    }

    /** ========  INITALIZE ========  */
    function __WarpBase_init() internal initializer {
        owner = msg.sender;
        paused = false;
    }

    /** ========  OWNERSHIP FUNCTIONS ========  */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** ===== PAUSER FUNCTIONS ========== */

    /** @dev allow owner to add or remove pausers */
    function setPauser(address _pauser, bool _allowed) external onlyOwner {
        pausers[_pauser] = _allowed;
    }

    /** @notice toggle pause on and off */
    function setPause(bool _paused) external onlyPauseToggler {
        paused = _paused;

        emit PauseChanged(msg.sender, _paused);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

library Base64 {
    bytes internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return '';

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

// Info for bond holder
struct Bond {
    uint256 payout; // WARP remaining to be paid
    uint256 vesting; // Blocks left to vest
    uint256 lastBlock; // Last interaction
    uint256 pricePaid; // In DAI, for front end viewing
}

interface IBond {
    function redeem(uint256 _recipient, bool _stake) external returns (uint256);

    function getBond(uint256 bondId) external view returns (Bond memory);

    function pendingPayoutFor(uint256 _tokenId) external view returns (uint256 pendingPayout_);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

interface IStarshipParts is IERC721EnumerableUpgradeable {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function mint(address _to, uint256 _tokenId) external;

    function burn(uint256 _tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/* ======== Structs ======== */
enum PartType {
    BRIDGE,
    HULL,
    ENGINE,
    FUEL
}

struct PartInfo {
    uint256 strength;
    PartType typeOf;
}

interface IStarshipPartsControl {
    function buildPart(address _to, uint256 _paid) external returns (uint256);

    function usePart(uint256 _tokenId) external;

    function getPartInfo(uint256 _tokenId) external view returns (PartInfo memory);

    function useFuel(uint256 _tokenId, uint256 _amount) external;

    function getMinimumValue() external view returns (uint256);

    function getStringPartType(PartType typeOf) external view returns (string memory);

    function getCounter() external view returns (uint256);

    function getPartCount(PartType typeOf) external view returns (uint256);
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