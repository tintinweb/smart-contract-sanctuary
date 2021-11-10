// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./NiftyEntity.sol";
import "./ERC2981.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract ERC2981Factory is NiftyEntity {
    address public immutable tokenImplementation;

    event ERC2981Created(address newERC2981Address);

    constructor(address _niftyRegistryContract) NiftyEntity(_niftyRegistryContract) {
        tokenImplementation = address(new ERC2981(_niftyRegistryContract));
    }

    function createGlobalRoyaltyInfo(
        address _recipient,
        uint256 _value,
        address _tokenAddress
    ) public onlyValidSender returns (address) {
        address clone = Clones.clone(tokenImplementation);
        ERC2981(clone).initialize(_recipient, _value, _tokenAddress);
        emit ERC2981Created(clone);
        return clone;
    }

    function createTokenRoyaltyInfo(address _tokenAddress) public onlyValidSender returns (address) {
        address clone = Clones.clone(tokenImplementation);
        ERC2981(clone).initialize(address(0), 0, _tokenAddress);
        emit ERC2981Created(clone);
        return clone;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./registry/INiftyRegistry.sol";

abstract contract NiftyEntity {
    address internal immutable niftyRegistryContract;

    constructor(address _niftyRegistryContract) {
        niftyRegistryContract = _niftyRegistryContract;
    }

    /**
     * @dev Determines whether accounts are allowed to invoke state mutating operations on child contracts.
     */
    modifier onlyValidSender() {
        bool isValid = INiftyRegistry(niftyRegistryContract).isValidNiftySender(msg.sender);
        require(isValid, "unauthorized");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./NiftyEntity.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ERC2981 is ERC165, IERC2981, Initializable, NiftyEntity {
    GlobalRoyaltyInfo private _globalRoyaltyInfo;

    RoyaltyRange[] public royaltyRanges;
    bool public contractEnabled;
    address public tokenAddress;

    struct GlobalRoyaltyInfo {
        bool enabled;
        uint24 amount;
        address recipient;
    }

    struct RoyaltyRange {
        uint256 startTokenId;
        uint256 endTokenId;
        address recipient;
        uint16 amount;
    }

    constructor(address _niftyRegistryContract) NiftyEntity(_niftyRegistryContract) {}

    function initialize(
        address _recipient,
        uint256 _value,
        address _tokenAddress
    ) public initializer {
        tokenAddress = _tokenAddress;
        contractEnabled = true;
        if (_value != 0) {
            _setGlobalRoyalties(_recipient, _value);
        }
    }

    /**
     * @dev Function responsible for updating existing token level royalties.
     * @param rangeIdx int256 represents the royaltyRanges index to delete. If writing a new range
     * then this value is set to '-1'. Deleting elements results in a gas refund.
     * @param startTokenId uint256 that is the first token in a RoyaltyRange
     * @param endTokenId uint256 that is the last token in a RoyaltyRange
     * @param recipient address of who should be sent the royalty payment
     * @param amount uint256 value for percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function updateTokenRoyaltyRange(
        int256 rangeIdx,
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) public onlyValidSender {
        RoyaltyRange storage r = royaltyRanges[uint256(rangeIdx)];
        if (r.startTokenId == startTokenId && r.endTokenId == endTokenId) {
            delete royaltyRanges[uint256(rangeIdx)];
        }
        _setTokenRoyaltyRange(startTokenId, endTokenId, recipient, amount);
    }

    /**
     * @dev Function responsible for setting token level royalties. To be gas efficient
     * this function provides the ability to set royalty information in ranges. It is
     * the responsibility of the caller to determine what these ranges are and to invoke
     * this function accordingly e.g. 'setTokenRoyaltyRange(0, 4, addressX, 250)' -
     * will set the the first 5 tokens to have 'addressX' and '250' as their royalty info.
     *
     * When reading royaltyInfo, the latest write for a token in a royalty range gets selected.
     * @param startTokenId uint256 that is the first token in a RoyaltyRange
     * @param endTokenId uint256 that is the last token in a RoyaltyRange
     * @param recipient address of who should be sent the royalty payment
     * @param amount uint256 value for percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setTokenRoyaltyRange(
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) public onlyValidSender {
        _setTokenRoyaltyRange(startTokenId, endTokenId, recipient, amount);
    }

    function _setTokenRoyaltyRange(
        uint256 startTokenId,
        uint256 endTokenId,
        address recipient,
        uint256 amount
    ) internal {
        require(contractEnabled, "Contract disabled");
        require(amount <= 10000, "Royalties too high");
        require(startTokenId <= endTokenId && startTokenId >= 0, "Bad tokenId range values");
        royaltyRanges.push(RoyaltyRange(startTokenId, endTokenId, recipient, uint16(amount)));
    }

    function royaltyRangeCount() external view returns (uint256) {
        return royaltyRanges.length;
    }

    function globalRoyaltiesEnabled() external view returns (bool) {
        return _globalRoyaltyInfo.enabled;
    }

    function setGlobalRoyalties(address recipient, uint256 value) public onlyValidSender {
        require(contractEnabled, "Contract disabled");
        _setGlobalRoyalties(recipient, value);
    }

    function _setGlobalRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "Royalties too high");
        _globalRoyaltyInfo = GlobalRoyaltyInfo(true, uint24(value), recipient);
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(contractEnabled, "Contract disabled");
        uint256 basis;
        GlobalRoyaltyInfo memory globalInfo = _globalRoyaltyInfo;
        if (globalInfo.enabled) {
            receiver = globalInfo.recipient;
            basis = globalInfo.amount;
        } else {
            if (royaltyRanges.length > 0) {
                uint256 i = royaltyRanges.length;
                while (i > 0) {
                    RoyaltyRange memory r = royaltyRanges[--i];
                    if (_tokenId >= r.startTokenId && _tokenId <= r.endTokenId) {
                        receiver = r.recipient;
                        basis = r.amount;
                        break;
                    }
                }
            }
        }
        royaltyAmount = (_salePrice * basis) / 10000;
    }

    function setContractEnabled(bool _contractEnabled) public onlyValidSender {
        contractEnabled = _contractEnabled;
    }

    function setGlobalRoyaltiesEnabled(bool _globalRoyaltiesEnabled) public onlyValidSender {
        _globalRoyaltyInfo.enabled = _globalRoyaltiesEnabled;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @dev Nifty registry
 */
interface INiftyRegistry {
    /**
     * @dev function to see if sending key is valid
     */
    function isValidNiftySender(address sending_key) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

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

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

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