// @author Unstoppable Domains, Inc.
// @date August 19th, 2021

pragma solidity ^0.8.0;

import './../cns/ICNSRegistry.sol';
import './IForwarder.sol';
import './BaseRoutingForwarder.sol';

/**
 * @title ResolverForwarder
 * @dev ResolverForwarder simplifies operation with legacy meta-transactions.
 * It works on top of existing Resolver contracts.
 */
contract ResolverForwarder is BaseRoutingForwarder {
    ICNSRegistry private _cnsRegistry;
    address private _defaultCnsResolver;

    constructor(ICNSRegistry cnsRegistry, address defaultCnsResolver) {
        _cnsRegistry = cnsRegistry;
        _defaultCnsResolver = defaultCnsResolver;
        _addRoute('reset(uint256)', 'resetFor(uint256,bytes)');
        _addRoute('set(string,string,uint256)', 'setFor(string,string,uint256,bytes)');
        _addRoute('setMany(string[],string[],uint256)', 'setManyFor(string[],string[],uint256,bytes)');
        _addRoute('reconfigure(string[],string[],uint256)', 'reconfigureFor(string[],string[],uint256,bytes)');
    }

    function nonceOf(uint256 tokenId) public view override returns (uint256) {
        address resolver = _defaultCnsResolver;
        try _cnsRegistry.resolverOf(tokenId) returns (address _resolver) {
            resolver = _resolver;
        } catch { }
        IForwarder target = IForwarder(resolver);
        return target.nonceOf(tokenId);
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) external view override returns (bool) {
        address target = _cnsRegistry.resolverOf(req.tokenId);
        return _verify(req, target, signature);
    }

    function execute(ForwardRequest calldata req, bytes calldata signature) external override returns (bytes memory) {
        uint256 gas = gasleft();
        address target = _cnsRegistry.resolverOf(req.tokenId);
        return _execute(req.from, target, req.tokenId, gas, req.data, signature);
    }

    /**
     * 0xb87abc11 = bytes4(keccak256('resetFor(uint256,bytes)'))
     * 0xc5974073 = bytes4(keccak256('setFor(string,string,uint256,bytes)'))
     * 0x8f69c188 = bytes4(keccak256('setManyFor(string[],string[],uint256,bytes)'))
     * 0xa3557e6c = bytes4(keccak256('reconfigureFor(string[],string[],uint256,bytes)'))
     */
    function _buildRouteData(
        bytes4 selector,
        bytes memory data,
        bytes memory signature
    ) internal pure override returns (bytes memory routeData) {
        if(selector == 0xb87abc11) {
            (uint256 p1) = abi.decode(data, (uint256));
            routeData = abi.encodeWithSelector(selector, p1, signature);
        } else if(selector == 0xc5974073) {
            (string memory p1, string memory p2, uint256 p3) = abi.decode(data, (string, string, uint256));
            routeData = abi.encodeWithSelector(selector, p1, p2, p3, signature);
        } else if(selector == 0x8f69c188) {
            (string[] memory p1, string[] memory p2, uint256 p3) = abi.decode(data, (string[], string[], uint256));
            routeData = abi.encodeWithSelector(selector, p1, p2, p3, signature);
        } else if(selector == 0xa3557e6c) {
            (string[] memory p1, string[] memory p2, uint256 p3) = abi.decode(data, (string[], string[], uint256));
            routeData = abi.encodeWithSelector(selector, p1, p2, p3, signature);
        }
    }
}

// @author Unstoppable Domains, Inc.
// @date June 16th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol';

interface ICNSRegistry is IERC721MetadataUpgradeable {
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

    function resolverOf(uint256 tokenId) external view returns (address);

    function childIdOf(uint256 tokenId, string calldata label) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

// @author Unstoppable Domains, Inc.
// @date August 11th, 2021

pragma solidity ^0.8.0;

interface IForwarder {
    struct ForwardRequest {
        address from;
        uint256 nonce;
        uint256 tokenId;
        bytes data;
    }

    function nonceOf(uint256 tokenId) external view returns (uint256);

    function verify(ForwardRequest calldata req, bytes calldata signature) external view returns (bool);

    function execute(ForwardRequest calldata req, bytes calldata signature) external returns (bytes memory);
}

// @author Unstoppable Domains, Inc.
// @date August 12th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import './IForwarder.sol';
import './BaseForwarder.sol';

/**
 * @title BaseRoutingForwarder
 * @dev BaseRoutingForwarder simplifies operation with legacy meta-transactions by routing calls
 */
abstract contract BaseRoutingForwarder is BaseForwarder {
    mapping(bytes4 => bytes4) private _routes;

    function _buildRouteData(
        bytes4 selector,
        bytes memory data,
        bytes memory signature
    ) internal view virtual returns (bytes memory);

    function _verify(
        ForwardRequest memory req,
        address target,
        bytes memory signature
    ) internal view override returns (bool) {
        return super._verify(req, target, signature) && _isKnownRoute(req.data);
    }

    function _buildData(
        address, /* from */
        uint256, /* tokenId */
        bytes memory data,
        bytes memory signature
    ) internal view override returns (bytes memory) {
        bytes4 route = _getRoute(data);
        require(route != 0, 'BaseRoutingForwarder: ROUTE_UNKNOWN');

        bytes memory _data;
        assembly {
            _data := add(data, 4)
            mstore(_data, sub(mload(data), 4))
        }

        return _buildRouteData(route, _data, signature);
    }

    function _addRoute(bytes memory from, bytes memory to) internal {
        _routes[bytes4(keccak256(from))] = bytes4(keccak256(to));
    }

    function _getRoute(bytes memory data) internal view returns (bytes4) {
        bytes4 selector;
        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            selector := mload(add(data, add(0x20, 0)))
        }

        return _routes[selector];
    }

    function _isKnownRoute(bytes memory data) internal view returns (bool) {
        bytes4 route = _getRoute(data);
        return route != 0;
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

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

// @author Unstoppable Domains, Inc.
// @date August 12th, 2021

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './IForwarder.sol';

abstract contract BaseForwarder is IForwarder {
    using ECDSAUpgradeable for bytes32;

    function _verify(
        ForwardRequest memory req,
        address target,
        bytes memory signature
    ) internal view virtual returns (bool) {
        uint256 nonce = this.nonceOf(req.tokenId);
        address signer = _recover(keccak256(req.data), target, nonce, signature);
        return nonce == req.nonce && signer == req.from;
    }

    function _recover(
        bytes32 digest,
        address target,
        uint256 nonce,
        bytes memory signature
    ) internal pure virtual returns (address signer) {
        return keccak256(abi.encodePacked(digest, target, nonce)).toEthSignedMessageHash().recover(signature);
    }

    function _execute(
        address from,
        address to,
        uint256 tokenId,
        uint256 gas,
        bytes memory data,
        bytes memory signature
    ) internal virtual returns (bytes memory) {
        _invalidateNonce(tokenId);

        (bool success, bytes memory returndata) = to.call{gas: gas}(_buildData(from, tokenId, data, signature));
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > gas / 63);

        return _verifyCallResult(success, returndata, 'BaseForwarder: CALL_FAILED');
    }

    function _invalidateNonce(
        uint256 /* tokenId */
    ) internal virtual {}

    function _buildData(
        address from,
        uint256 tokenId,
        bytes memory data,
        bytes memory /* signature */
    ) internal view virtual returns (bytes memory) {
        return abi.encodePacked(data, from, tokenId);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                //solhint-disable-next-line no-inline-assembly
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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}