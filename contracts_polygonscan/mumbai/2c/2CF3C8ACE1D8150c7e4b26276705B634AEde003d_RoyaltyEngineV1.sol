// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./libraries/SuperRareContracts.sol";

import "./specs/IManifold.sol";
import "./specs/IRarible.sol";
import "./specs/IFoundation.sol";
import "./specs/ISuperRare.sol";
import "./specs/IEIP2981.sol";
import "./specs/IZoraOverride.sol";
import "./specs/IArtBlocksOverride.sol";
import "./IRoyaltyEngineV1.sol";
import "./IRoyaltyRegistry.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyEngineV1 is ERC165, OwnableUpgradeable, IRoyaltyEngineV1 {
    using AddressUpgradeable for address;

    // Use int16 for specs to support future spec additions
    // When we add a spec, we also decrement the NONE value
    // Anything > NONE and <= NOT_CONFIGURED is considered not configured
    int16 constant private NONE = -1;
    int16 constant private NOT_CONFIGURED = 0;
    int16 constant private MANIFOLD = 1;
    int16 constant private RARIBLEV1 = 2;
    int16 constant private RARIBLEV2 = 3;
    int16 constant private FOUNDATION = 4;
    int16 constant private EIP2981 = 5;
    int16 constant private SUPERRARE = 6;
    int16 constant private ZORA = 7;
    int16 constant private ARTBLOCKS = 8;

    mapping (address => int16) _specCache;

    address public royaltyRegistry;

    function initialize(address royaltyRegistry_) public initializer {
        __Ownable_init_unchained();
        require(ERC165Checker.supportsInterface(royaltyRegistry_, type(IRoyaltyRegistry).interfaceId));
        royaltyRegistry = royaltyRegistry_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IRoyaltyEngineV1).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyalty}
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) public override returns(address payable[] memory recipients, uint256[] memory amounts) {
        int16 spec;
        address royaltyAddress;
        bool addToCache;

        (recipients, amounts, spec, royaltyAddress, addToCache) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        if (addToCache) _specCache[royaltyAddress] = spec;
        return (recipients, amounts);
    }

    /**
     * @dev See {IRoyaltyEngineV1-getRoyaltyView}.
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) public view override returns(address payable[] memory recipients, uint256[] memory amounts) {
        (recipients, amounts, , , ) = _getRoyaltyAndSpec(tokenAddress, tokenId, value);
        return (recipients, amounts);
    }

    /**
     * @dev Get the royalty and royalty spec for a given token
     * 
     * returns recipieints array, amounts array, royalty spec, royalty address, whether or not to add to cache
     */
    function _getRoyaltyAndSpec(address tokenAddress, uint256 tokenId, uint256 value) private view returns(address payable[] memory recipients, uint256[] memory amounts, int16 spec, address royaltyAddress, bool addToCache) {

        royaltyAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(tokenAddress);
        spec = _specCache[royaltyAddress];

        if (spec <= NOT_CONFIGURED && spec > NONE) {
            // No spec configured yet, so we need to detect the spec
            addToCache = true;

            // SuperRare handling
            if (tokenAddress == SuperRareContracts.SUPERRARE_V1 || tokenAddress == SuperRareContracts.SUPERRARE_V2) {
                try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId) returns(address payable creator) {
                    try ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(tokenAddress, tokenId, value) returns(uint256 amount) {
                        recipients = new address payable[](1);
                        amounts = new uint256[](1);
                        recipients[0] = creator;
                        amounts[0] = amount;
                        return (recipients, amounts, SUPERRARE, royaltyAddress, addToCache);                        
                    } catch {}
                } catch {}
            }
            try IManifold(royaltyAddress).getRoyalties(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Supports manifold interface.  Compute amounts
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), MANIFOLD, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId) returns(IRaribleV2.Part[] memory royalties) {
                // Supports rarible v2 interface. Compute amounts
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value*royalties[i].value/10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, RARIBLEV2, royaltyAddress, addToCache);
            } catch {}
            try IRaribleV1(royaltyAddress).getFeeRecipients(tokenId) returns(address payable[] memory recipients_) {
                // Supports rarible v1 interface. Compute amounts
                recipients_ = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                try IRaribleV1(royaltyAddress).getFeeBps(tokenId) returns (uint256[] memory bps) {
                    require(recipients_.length == bps.length);
                    return (recipients_, _computeAmounts(value, bps), RARIBLEV1, royaltyAddress, addToCache);
                } catch {}
            } catch {}
            try IFoundation(royaltyAddress).getFees(tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Supports foundation interface.  Compute amounts
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), FOUNDATION, royaltyAddress, addToCache);
            } catch {}
            try IEIP2981(royaltyAddress).royaltyInfo(tokenId, value) returns(address recipient, uint256 amount) {
                // Supports EIP2981.  Return amounts
                require(amount < value, "Invalid royalty amount");
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, EIP2981, royaltyAddress, addToCache);
            } catch {}
            try IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Support Zora override
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), ZORA, royaltyAddress, addToCache);
            } catch {}
            try IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId) returns(address payable[] memory recipients_, uint256[] memory bps) {
                // Support Art Blocks override
                require(recipients_.length == bps.length);
                return (recipients_, _computeAmounts(value, bps), ARTBLOCKS, royaltyAddress, addToCache);
            } catch {}

            // No supported royalties configured
            return (recipients, amounts, NONE, royaltyAddress, addToCache);
        } else {
            // Spec exists, just execute the appropriate one
            addToCache = false;
            if (spec == NONE) {
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == MANIFOLD) {
                // Manifold spec
                uint256[] memory bps;
                (recipients, bps) = IManifold(royaltyAddress).getRoyalties(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV2) {
                // Rarible v2 spec
                IRaribleV2.Part[] memory royalties;
                royalties = IRaribleV2(royaltyAddress).getRaribleV2Royalties(tokenId);
                recipients = new address payable[](royalties.length);
                amounts = new uint256[](royalties.length);
                uint256 totalAmount;
                for (uint i = 0; i < royalties.length; i++) {
                    recipients[i] = royalties[i].account;
                    amounts[i] = value*royalties[i].value/10000;
                    totalAmount += amounts[i];
                }
                require(totalAmount < value, "Invalid royalty amount");
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == RARIBLEV1) {
                // Rarible v1 spec
                uint256[] memory bps;
                recipients = IRaribleV1(royaltyAddress).getFeeRecipients(tokenId);
                bps = IRaribleV1(royaltyAddress).getFeeBps(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == FOUNDATION) {
                // Foundation spec
                uint256[] memory bps;
                (recipients, bps) = IFoundation(royaltyAddress).getFees(tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            } else if (spec == EIP2981) {
                // EIP2981 spec
                (address recipient, uint256 amount) = IEIP2981(royaltyAddress).royaltyInfo(tokenId, value);
                require(amount < value, "Invalid royalty amount");
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);
            } else if (spec == SUPERRARE) {
                // SUPERRARE spec
                address payable creator = ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).tokenCreator(tokenAddress, tokenId);
                uint256 amount = ISuperRareRegistry(SuperRareContracts.SUPERRARE_REGISTRY).calculateRoyaltyFee(tokenAddress, tokenId, value);
                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = creator;
                amounts[0] = amount;
                return (recipients, amounts, spec, royaltyAddress, addToCache);            
            } else if (spec == ZORA) {
                // Zora spec
                uint256[] memory bps;
                (recipients, bps) = IZoraOverride(royaltyAddress).convertBidShares(tokenAddress, tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);          
            } else if (spec == ARTBLOCKS) {
                // Art Blocks spec
                uint256[] memory bps;
                (recipients, bps) = IArtBlocksOverride(royaltyAddress).getRoyalties(tokenAddress, tokenId);
                require(recipients.length == bps.length);
                return (recipients, _computeAmounts(value, bps), spec, royaltyAddress, addToCache);
            }
        }
    }

    /**
     * Compute royalty amounts
     */
    function _computeAmounts(uint256 value, uint256[] memory bps) private pure returns(uint256[] memory amounts) {
        amounts = new uint256[](bps.length);
        uint256 totalAmount;
        for (uint i = 0; i < bps.length; i++) {
            amounts[i] = value*bps[i]/10000;
            totalAmount += amounts[i];
        }
        require(totalAmount < value, "Invalid royalty amount");
        return amounts;
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SuperRareContracts {
    address public constant SUPERRARE_REGISTRY = 0x17B0C8564E53f22364A6C8de6F7ca5CE9BEa4e5D;
    address public constant SUPERRARE_V1 = 0x41A322b28D0fF354040e2CbC676F0320d8c8850d;
    address public constant SUPERRARE_V2 = 0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}


interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }
    function getRaribleV2Royalties(uint256 id) external view returns (Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISuperRareRegistry {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Get the token creator which will receive royalties of the given token
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     */
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Paired down version of the Zora Market interface
 */
interface IZoraMarket {
    struct ZoraDecimal {
        uint256 value;
    }

    struct ZoraBidShares {
        // % of sale value that goes to the _previous_ owner of the nft
        ZoraDecimal prevOwner;
        // % of sale value that goes to the original creator of the nft
        ZoraDecimal creator;
        // % of sale value that goes to the seller (current owner) of the nft
        ZoraDecimal owner;
    }

    function bidSharesForToken(uint256 tokenId) external view returns (ZoraBidShares memory);
}

/**
 * Paired down version of the Zora Media interface
 */
interface IZoraMedia {

    /**
     * Auto-generated accessors of public variables
     */
    function marketContract() external view returns(address);
    function previousTokenOwners(uint256 tokenId) external view returns(address);
    function tokenCreators(uint256 tokenId) external view returns(address);

    /**
     * ERC721 function
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Interface for a Zora media override
 */
interface IZoraOverride {

    /**
     * @dev Convert bid share configuration of a Zora Media token into an array of receivers and bps values
     *      Does not support prevOwner and sell-on amounts as that is specific to Zora marketplace implementation
     *      and requires updates on the Zora Media and Marketplace to update the sell-on amounts/previous owner values.
     *      An off-Zora marketplace sale will break the sell-on functionality.
     */
    function convertBidShares(address media, uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 *  Interface for an Art Blocks override
 */
interface IArtBlocksOverride {
    /**
     * @dev Get royalites of a token at a given tokenAddress.
     *      Returns array of receivers and basisPoints.
     *
     *  bytes4(keccak256('getRoyalties(address,uint256)')) == 0x9ca7dc7a
     *
     *  => 0x9ca7dc7a = 0x9ca7dc7a
     */
    function getRoyalties(address tokenAddress, uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {

     event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     * 
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external;

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns(address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns(bool);
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