/**
 *Submitted for verification at arbiscan.io on 2021-12-23
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/AuctionHouse.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity >=0.8.0 >=0.8.0 <0.9.0 >=0.8.10 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

////// lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol

/* pragma solidity ^0.8.0; */

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

/* pragma solidity ^0.8.0; */

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

////// lib/openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC721Receiver.sol"; */

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

////// lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC165.sol"; */

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

////// lib/solmate/src/tokens/ERC20.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

////// lib/solmate/src/utils/SafeTransferLib.sol
/* pragma solidity >=0.8.0; */

/* import {ERC20} from "../tokens/ERC20.sol"; */

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

////// src/IAuctionHouse.sol
/* pragma solidity ^0.8.10; */

/// @title Interface for the Auclantis auction house.
/// @notice The auction house is a collection of auction rooms, each room
/// contains multiple auctions. Users bids on auctions to win the NFT.
/// Users can also stake on an auction to receive part of the auction value,
/// with a commission specified by the seller at the beginning of the auction.
///
/// @dev
/// ## Auction duration and last chance
///
/// Auctions on Auclantis run until the end time of the room they belong to.
/// This creates an issue since bidders are encouraged to bid at the last possible
/// moment. We solve this issue by introducing the concept of _last chance_.
/// For a period before the end of a room (for example, 1 hour), only users that
/// previously bid on the auction can bid, but only one more time. This encourages
/// them to bid their "true price" to avoid being outbid.
///
/// ## Curation
///
/// Users can signal that they like an auction by "stacking" some tokens into it.
/// At the end of the auction they receive a commission based on the amount of tokens
/// they staked.
///
///  - The commission (in percentage) is set by the seller at the beginning of the
///    auction and cannot be changed.
///  - Users that stake early receive a larger proportien of commission for their tokens.
///
/// Rewarding users more for their tokens means we cannot use a linear function to compute
/// commission vs number of tokens staked.
///
/// For each stake `S_i`, we define the following derived quantities:
///
///  - `T_0 := S_0` and `T_i := S_i + T_{i-1}` . This is the total amount of tokens staked.
///  - `P(x)`, a penalty function. This function should be an increasing concave function, for
///    example `sqrt(x)`.
///  - `DP_i := P(T_i) - P(T_{i-1})`: the difference in the penalized stakes after stake `S_i`.
///  - `U(a) := {i : owner(S_i) == a}`: the set of user's `a` stakes.
///  - `N`: the number of stakes at the end of the auction.
///
/// The final share of the commission `SC(a)` for each user is then:
///
///  SC(a) := sum(DP_i for i in U(a)) / P(T_N)
///
/// In other words, each user commission equals their accumulated penalized stake `sum(DP_i for i in U(a))`
/// over the total penalized staked amount `P(T_N)`.
///
/// We can visualize the relationship between users stakes and their penalized stakes:
///
///   P(T_1) -+-----------o
///         ^ |         / |
///   DP_1  | |       /   |
///         v |     /     |
///   P(T_0) -+---o       |
///           |  /|       |
///           | / |       |
///           |/  |       |
///           +---+-------+
///             T_0 <-+->T_1
///               |   |
///             S_0  S_1
///
interface IAuctionHouse {
    /// @notice info stored for each auction.
    struct Auction {
        /// @notice which room this auction belongs to.
        uint256 roomId;
        /// @notice the account that created the auction and will receive the sale share.
        address payable owner;
        /// @notice auction currency. ERC-20 token address, or 0x0 for ETH.
        address currencyAddress;
        /// @notice ERC-721 contract address.
        address tokenAddress;
        /// @notice ERC-721 token id.
        uint256 tokenId;
        /// @notice the original owner of the ERC-721 token.
        address tokenOwner;
        /// @notice the reserve price (minimum bid).
        uint256 reservePrice;
        /// @notice current (highest) bid.
        uint256 currentBid;
        /// @notice current (highest) bidder.
        address payable currentBidder;
        /// @notice the commission paid to the community.
        uint8 commissionSharePct;
        /// @notice the amount staked by the seller.
        uint256 stakeAmount;
    }

    /// @notice Emitted when the auction house is created.
    /// @param stakeTokenAddress the address of the ERC-20 token used for staking.
    /// @param epoch the unix timestamp of when the auction house time starts.
    /// @param maximumAuctionDuration the maximum auction duration, in seconds.
    /// @param lastChanceDuration the last chance period duration.
    /// @param minBidIncrementPct the minimum bid increment, in percentage (e.g. 5%).
    /// @param maxLastChanceBids the maximum number of last chance bids.
    /// @param createAuctionStake the amount of stake token needed to create an auction.
    event AuctionHouseCreated(
        address indexed stakeTokenAddress,
        uint256 epoch,
        uint256 maximumAuctionDuration,
        uint256 lastChanceDuration,
        uint256 minBidIncrementPct,
        uint8 maxLastChanceBids,
        uint256 createAuctionStake
    );

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Termination                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Set the timestamp after which no auction can end.
    /// @dev Auctions that are already running and end after the termination date
    /// are not affected by this. It's good practice to set the termination date
    /// further than `maximumAuctionDuration` seconds in the future.
    ///
    /// Users can still claim their nfts/profits/stakes after the auction
    /// house terminated. This is an orderly shutdown meant for rolling to an
    /// updated smart contract.
    /// @param terminationTimestamp the timestamp after which no auction can be created.
    function terminateAfterTimestamp(uint256 terminationTimestamp) external;

    /// @notice Emitted when the auction house is set to terminate.
    /// @param terminationTimestamp the timestamp after which no auction can be created.
    event Terminated(uint256 terminationTimestamp);

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Recoverable                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Stop the auction house because of an emergency.
    /// @dev All functions in the auction house will stop working until the situation
    /// is assessed.
    /// Operators can move to the recovery state by calling `recover`.
    function stop() external;

    /// @notice Emitted when the auction house is stopped in an emergency.
    event Stopped();

    /// @notice Enter recovery state.
    /// @dev While in recovery state, users can interact with the auction house in a
    /// limited fashion.
    function recover() external;

    /// @notice Emitted when the auction house enters the recovery state.
    event Recovered();

    /// @notice Claim back nft token after emergency shutdown.
    /// @dev The auction must end after the emergency shutdown time.
    /// @param auctionId the auction id.
    function emergencyClaimToken(uint256 auctionId) external;

    /// @notice Emitted when auction token is claimed after emergency shutdown.
    event AuctionTokenClaimedInEmergency(uint256 indexed auctionId);

    /// @notice Claim back the highest bid after emergency shutdown.
    /// @dev The auction must end after the emergency shutdown time.
    /// @param auctionId the auction id.
    function emergencyClaimHighestBid(uint256 auctionId) external;

    /// @notice Emitted when auction highest bid is claimed after emergency shutdown.
    event AuctionHighestBidClaimedInEmergency(uint256 indexed auctionId);

    /// @notice Claim back stake after emergency shutdown.
    /// @dev The auction must end after the emergency shutdown time.
    /// @param auctionId the auction id.
    /// @param user the user claiming back the stake.
    function emergencyClaimStake(uint256 auctionId, address payable user) external;

    /// @notice Emitted when user's auction stake is claimed after emergency shutdown.
    event AuctionStakeClaimedInEmergency(uint256 indexed auctionId, address indexed user);

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Configuration                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Add currency to the list of allowed currencies for auctions.
    /// @dev Notice that currencies are checked only when creating the auction,
    /// this means it's possible to have running auctions that use a currency
    /// that was later forbidden.
    /// All currencies are disabled by default so that they can be tested before
    /// being allowed in the auction house. This means the auction house does
    /// not have to worry about ill-behaving currencies
    /// @param currency the currency address.
    /// @param allowed true if currency can be used on the auction house.
    function allowCurrency(address currency, bool allowed) external;

    /// @notice Emitted when the currency allowed status is updated.
    /// @param currency the address of the ERC-20 token, 0 if ETH.
    /// @param allowed true if the currency can be used in the auction house.
    event CurrencyAllowedUpdated(address indexed currency, bool allowed);

    /// @notice Change the minimum bid increment (in percentage).
    /// @param newMinBidIncrement the new minimum bid increment.
    function updateMinBidIncrement(uint256 newMinBidIncrement) external;

    /// @notice Emitted when the minimum bid increment is updated.
    /// @param newMinBidIncrement the new minimum bid increment, in percentage.
    event MinBidIncrementPctUpdated(uint256 newMinBidIncrement);

    /// @notice Change the amount of tokens sellers need to stake.
    /// @dev We may require sellers to stake some tokens (which are returned at
    /// the end of the auction) to reduce spam listings.
    /// @param newCreateAuctionStake the new stake required by sellers.
    function updateCreateAuctionStake(uint256 newCreateAuctionStake) external;

    /// @notice Emitted when the seller stake is updated.
    /// @param newCreateAuctionStake the new seller stake.
    event CreateAuctionStakeUpdated(uint256 newCreateAuctionStake);

    /// @notice Change the maximum auction duration.
    /// @param newDuration the new duration in seconds.
    function updateMaximumAuctionDuration(uint256 newDuration) external;

    /// @notice Emitted when the maximum auction duration is updated.
    /// @param newDuration the new duration in seconds.
    event MaximumAuctionDurationUpdated(uint256 newDuration);

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                       Volume Information                             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total volume bought by user in the specified currency.
    /// @param currencyAddress the currency address.
    /// @param user the user.
    function getVolumeSold(address currencyAddress, address user)
        external
        returns (uint256);

    /// @notice Returns the total volume sold by user in the specified currency.
    /// @param currencyAddress the currency address.
    /// @param user the user.
    function getVolumeBought(address currencyAddress, address user)
        external
        returns (uint256);

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Room Information                             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the time when the given room ends.
    /// @param roomId the room.
    function roomEndTime(uint256 roomId) external returns (uint256);

    /// @notice Returns the time when last chance starts for the given room.
    /// @param roomId the room.
    function roomLastChanceStartTime(uint256 roomId) external returns (uint256);

    /// @notice Returns the id of the first room ending after the specified time.
    /// @param time the unix timestamp.
    function firstRoomEndingAfter(uint256 time) external returns (uint256);

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                      Auction Management                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the total number of auctions in the auction house.
    function totalAuctions() external view returns (uint256);

    /// @notice Create a new auction in the given room.
    /// @dev
    /// The implementation must forbid users from creating auctions after a
    /// room's last chance period starts.
    ///
    /// Users can specify which currency they want to accept, this currency
    /// must be one of the allowed currencies in the auction house.
    ///
    /// The user must have the permission to transfer the token, but they don't
    /// have to be the owners of it.
    ///
    /// The token's current owner is stored in the auction, if the auction is
    /// not successful the token is returned to the original owner.
    ///
    /// Users specify the commission they want to share with the curators, this
    /// commission must be a non negative number below 50%.
    /// @param roomId the room id.
    /// @param tokenAddress the ERC-721 token address.
    /// @param tokenId the ERC-721 token id.
    /// @param currencyAddress the ERC-20 token address.
    /// @param reservePrice the reserve price (minimum bid).
    /// @param commissionSharePct the commission paid to the community.
    /// @param stakeAmount the stake amount.
    function createAuction(
        uint256 roomId,
        address tokenAddress,
        uint256 tokenId,
        address currencyAddress,
        uint256 reservePrice,
        uint8 commissionSharePct,
        uint256 stakeAmount
    ) external returns (uint256);

    /// @notice Emitted when a new auction is started.
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param owner the account that created the auction and that will receive
    /// the sale share.
    /// @param tokenAddress the ERC-721 token address.
    /// @param tokenId the ERC-721 token id.
    /// @param currencyAddress the ERC-20 token address, used for payments.
    /// @param reservePrice the reserve price (minimum bid).
    /// @param commissionSharePct the commission paid to the community.
    /// @param stakeAmount the stake amount submitted by the seller.
    event AuctionStarted(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        address payable owner,
        address tokenAddress,
        uint256 tokenId,
        address currencyAddress,
        uint256 reservePrice,
        uint8 commissionSharePct,
        uint256 stakeAmount
    );

    /// @notice Claim the auction net value and send it to the auction's owner.
    /// @dev The net value is the amount the highest bidder bid, minus the community
    /// commission.
    ///
    /// If the community commission is 0%, then it follows that the net value equals
    /// the highest bid.
    /// Otherwise the net value is given by:
    ///
    ///   netValue := highestBid * (100% - commission%)
    ///
    /// Anyone can invoke this method since it sends the value to the auction's owner.
    /// @param auctionId the auction id.
    function claimAuctionNetValue(uint256 auctionId) external;

    /// @notice Emitted when the seller claims the auction net value (if any).
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param saleAmount the amount the auction owner received.
    event AuctionNetValueClaimed(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        uint256 saleAmount
    );

    /// @notice Claim the auction NFT token and send it to the auction's winner, if any.
    /// @dev This method transfers the NFT to the auction's highest bidder.
    ///
    /// Anyone can invoke this method since it transefrs the token to the highest bidder.
    /// @param auctionId the auction id.
    function claimAuctionToken(uint256 auctionId) external;

    /// @notice Emitted when the buyer claims the NFT token.
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param winner the user that won the auction.
    event AuctionTokenClaimed(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        address winner
    );

    /// @notice Claim an auction commission and send it to the given user.
    /// @dev This method computes the user's share and transfers it to them,
    /// together with the tokens they staked.
    ///
    /// If the auction was not successful, this method returns the tokens to
    /// the user.
    ///
    /// A user share is given by the commission formula (see above).
    /// @param auctionId the auction id.
    /// @param user the user that receives the commission.
    function claimAuctionCommission(uint256 auctionId, address payable user)
        external;

    /// @notice Emitted when a user claims their commission.
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param user the user claiming the commission.
    /// @param userShare the commission paid to user.
    event AuctionCommissionClaimed(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        address indexed user,
        uint256 userShare
    );

    /// @notice Bid amount on an auction.
    /// @dev The amount the user bids must be at least the minimum bid increment
    /// above the previous high bid. If this is the first bid on the auction,
    /// the bid can equal the reserve price.
    ///
    /// If the reserve price is 0, the bid amount must be strictly higher than the
    /// reserve price.
    ///
    /// The auction's highest bidder is updated to be the msg.sender of this method.
    ///
    /// This method transfers the specified amount of currency to the auction house,
    /// and returns the previous high bid to the previous highest bidder.
    /// @param auctionId the auction id.
    /// @param amount the amount of the auction accepted currency to bid.
    function bid(uint256 auctionId, uint256 amount) external payable;

    /// @notice Emitted when an auction receives a new valid bid.
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param bidder the bidder address.
    /// @param bidAmount the bid amount.
    event AuctionBid(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount
    );

    /// @notice Stake amount of token for the given auction.
    /// @dev Users can stake multiple times on the same auction,
    /// their stake value is updated every time.
    ///
    /// The amount of tokens will be locked until the end of the
    /// auction, at which point users can start claiminig their
    /// tokens back together with the commission (if any).
    ///
    /// See the section above to know more about staking.
    /// @param auctionId the auction id.
    /// @param amount the amount of staking token to stake.
    function stake(uint256 auctionId, uint256 amount) external;

    /// @notice Emitted when a user stakes.
    /// @param roomId the room to which the auction belongs to.
    /// @param auctionId the auction unique id.
    /// @param user the user staking.
    /// @param amount the amount of staking token staked.
    /// @param stakeShare quantity used to compute user share of commission.
    /// @param totalShare total quantity used to compute user share of commission.
    event AuctionStake(
        uint256 indexed roomId,
        uint256 indexed auctionId,
        address indexed user,
        uint256 amount,
        uint256 stakeShare,
        uint256 totalShare
    );
}

////// src/interfaces/IERC2981.sol
/* pragma solidity ^0.8.0; */

///
/// @dev Interface for the NFT Royalty Standard
/// https://eips.ethereum.org/EIPS/eip-2981
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

////// src/NftLib.sol
/* pragma solidity ^0.8.10; */

/* import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; */
/* import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; */

/* import "./interfaces/IERC2981.sol"; */

/// @notice Emitted when a function is called with an invalid NFT standard.
error NftLib__InvalidNftStandard();

/// @notice Emitted if the account is not the owner of the nft.
error NftLib__NotNftOwner();

/// @notice NftLib is used to interact with ERC-721 and ERC-1155 contracts.
library NftLib {
    bytes4 private constant _interfaceIdERC721 = 0x80ac58cd;
    bytes4 private constant _interfaceIdERC2981 = 0x2a55205a;

    /// @notice Enum to signal the NFT standard in use.
    enum NftStandard {
        Unknown,
        Erc721
    }

    /// @notice Check which NFT standard the contract supports.
    /// @param account the address of the NFT contract.
    function checkStandard(address account)
        internal
        view
        returns (NftStandard)
    {
        if (ERC165Checker.supportsInterface(account, _interfaceIdERC721)) {
            return NftStandard.Erc721;
        }

        return NftStandard.Unknown;
    }

    /// @notice Check if sender can transfer the NFT.
    /// @dev This checks that the sender is the owner of the NFT.
    /// @param sender the address sending the NFT.
    /// @param tokenAddress the NFT contract address.
    /// @param tokenId the NFT id.
    /// @param tokenStandard the NFT standard used.
    function checkCanTransfer(
        address sender,
        address tokenAddress,
        uint256 tokenId,
        NftStandard tokenStandard
    ) internal view {
        if (tokenStandard == NftStandard.Erc721) {
            address owner = IERC721(tokenAddress).ownerOf(tokenId);
            if (sender != owner) {
                revert NftLib__NotNftOwner();
            }
        } else {
            revert NftLib__InvalidNftStandard();
        }
    }

    /// @notice Transfer NFT token.
    /// @param tokenAddress the NFT contract address.
    /// @param sender the address sending the NFT.
    /// @param destination the address receiving the NFT.
    /// @param tokenId the NFT id.
    /// @param tokenStandard the NFT standard used.
    function safeTransferFrom(
        address tokenAddress,
        address sender,
        address destination,
        uint256 tokenId,
        NftStandard tokenStandard
    ) internal {
        if (tokenStandard == NftStandard.Erc721) {
            IERC721(tokenAddress).safeTransferFrom(
                sender,
                destination,
                tokenId
            );
        } else {
            revert NftLib__InvalidNftStandard();
        }
    }

    function royaltyInfo(
        address tokenAddress,
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address receiver, uint256 royaltyAmount) {
        if (
            ERC165Checker.supportsInterface(tokenAddress, _interfaceIdERC2981)
        ) {
            (receiver, royaltyAmount) = IERC2981(tokenAddress).royaltyInfo(
                tokenId,
                salePrice
            );
        } else {
            receiver = address(0);
            royaltyAmount = 0;
        }
    }
}

////// src/StakeHouse.sol
/* pragma solidity ^0.8.10; */

/// @notice Emitted when the given address is invalid.
error StakeHouse__InvalidAddress();

/// @notice Emitted when the staked amount is zero.
error StakeHouse__ZeroStake();

/// @notice StakeHouse contains stake-related functions
library StakeHouse {
    // info stored for each user's stake
    struct Stake {
        // amount of token staked
        uint256 amount;
        // amount used for share computation
        uint256 share;
    }

    // info about an auction's staking
    struct Info {
        // total amount staked
        uint256 totalStakedAmount;
        // total amount staked (square root)
        uint256 totalStakedAmountSqrt;
        // users stakes
        mapping(address => Stake) stakes;
    }

    function addStake(
        Info storage self,
        address user,
        uint256 amount
    )
        internal
        returns (
            bool,
            uint256,
            uint256
        )
    {
        // checks: address not zero
        if (user == address(0)) {
            revert StakeHouse__InvalidAddress();
        }

        // checks: amount is not zero
        if (amount == 0) {
            revert StakeHouse__ZeroStake();
        }

        // compute: new user share
        uint256 newTotalStakedAmount = self.totalStakedAmount + amount;
        uint256 newTotalStakedAmountSqrt = _penalty(newTotalStakedAmount);
        uint256 _userShare = newTotalStakedAmountSqrt -
            self.totalStakedAmountSqrt;

        // effects: update user stake
        Stake storage stake = self.stakes[user];
        bool isNew = stake.amount == 0;
        stake.amount = stake.amount + amount;
        stake.share = stake.share + _userShare;

        self.stakes[user] = stake;

        // effects: update global stake state
        self.totalStakedAmount = newTotalStakedAmount;
        self.totalStakedAmountSqrt = newTotalStakedAmountSqrt;

        return (isNew, _userShare, newTotalStakedAmountSqrt);
    }

    function userShare(
        Info storage self,
        address user,
        uint256 amount
    ) internal view returns (uint256 shareAmount) {
        // compute: user share of amount
        Stake memory stake = self.stakes[user];
        if (stake.amount == 0) {
            return 0;
        }

        return (amount * stake.share) / self.totalStakedAmountSqrt;
    }

    /// @notice compute the penalized stake amount
    /// @param amount the amount the user staked
    function _penalty(uint256 amount) internal pure returns (uint256) {
        return _sqrt(amount);
    }

    /// @notice compute square root of num
    /// @dev Adapted from pbr-math version at
    /// https://github.com/hifi-finance/prb-math/blob/42f98250ba6b412abd9b13d57a9b1ea9932250dc/contracts/PRBMath.sol
    /// @param num the number
    // solhint-disable-next-line code-complexity
    function _sqrt(uint256 num) internal pure returns (uint256 result) {
        if (num == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(num);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1;
            result = (result + num / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = num / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

////// src/utils/Recoverable.sol
/* pragma solidity ^0.8.10; */

/// @notice Emitted when the contract is expected to be running, but it's not.
error Recoverable__NotRunning();

/// @notice Emitted when the contract is expected to be stopped, but it's not.
error Recoverable__NotStopped();

/// @notice Emitted when the contract is expected to NOT be stopped, but it is.
error Recoverable__Stopped();

/// @notice Emitted when the contract is expected to be recovering, but it's not.
error Recoverable__NotRecovering();

/// @notice Contract module used to add emergency shutdown and recovery
/// to smart contracts.
///
/// Recoverable smart contracts are state machines with the following state
/// transitions:
///
/// [Running] -- _stop --> (Stopped) -- _recover --> [Recovering]
///
/// This module is used through inheritance. Developers should use the modifiers
/// `whenRunning`, `whenStopped`, and `whenRecovering` in their contract functions.
///
/// Developers should also implement external functions to call the `_stop` and
/// `_recover` with proper access control.
///
/// @dev This module is similar to Pausable, but the contract cannot transition
/// back to a normal running status.
abstract contract Recoverable {
    /// @notice Emitted when the contract is stopped by `account`.
    event Stopped(address account);

    /// @notice Emitted when the contract is recovered by `account`.
    event Recovered(address account);

    enum State {
        Running,
        Stopped,
        Recovering
    }

    State private _state;

    /// @notice Initialize contract to the running state.
    constructor() {
        _state = State.Running;
    }

    /// @notice Returns `true` if the contract is in the running state.
    function running() public view virtual returns (bool) {
        return _state == State.Running;
    }

    /// @notice Returns `true` if the contract is in the stopped state.
    function stopped() public view virtual returns (bool) {
        return _state == State.Stopped;
    }

    /// @notice Returns `true` if the contract is in the recovering state.
    function recovering() public view virtual returns (bool) {
        return _state == State.Recovering;
    }

    /// @notice Modifier to make a function callable only when the contract is running.
    modifier whenRunning() {
        if (_state != State.Running) {
            revert Recoverable__NotRunning();
        }

        _;
    }

    /// @notice Modifier to make a function callable only when the contract is stopped.
    modifier whenStopped() {
        if (_state != State.Stopped) {
            revert Recoverable__NotStopped();
        }

        _;
    }

    /// @notice Modifier to make a function callable only when the contract is NOT stopped.
    modifier whenNotStopped() {
        if (_state == State.Stopped) {
            revert Recoverable__Stopped();
        }

        _;
    }

    /// @notice Modifier to make a function callable only when the contract is recovering.
    modifier whenRecovering() {
        if (_state != State.Recovering) {
            revert Recoverable__NotRecovering();
        }

        _;
    }

    /// @notice Trigger state transition to the stopped state.
    /// @dev Contract must be in running state.
    function _stop() internal virtual whenRunning {
        // effects: update state
        _state = State.Stopped;

        emit Stopped(msg.sender);
    }

    /// @notice Trigger state transition to the recovering state.
    /// @dev Contract must be in stopped state.
    function _recover() internal virtual whenStopped {
        // effects: update state
        _state = State.Recovering;

        emit Recovered(msg.sender);
    }
}

////// src/AuctionHouse.sol
/* pragma solidity ^0.8.10; */

/* import "@openzeppelin/contracts/access/Ownable.sol"; */
/* import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; */
/* import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; */
/* import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; */
/* import "@solmate/tokens/ERC20.sol"; */
/* import "@solmate/utils/SafeTransferLib.sol"; */

/* import "./IAuctionHouse.sol"; */
/* import "./StakeHouse.sol"; */
/* import "./NftLib.sol"; */
/* import "./utils/Recoverable.sol"; */

/// @notice Emitted if the auction does not exist.
error AuctionHouse__AuctionDoesNotExist(uint256 auctionId);

/// @notice Emitted if user interacts with an auction after last chance started.
error AuctionHouse__AfterLastChance(uint256 roomId);

/// @notice Emitted when interacting with a currency that charges fees on transfers.
error AuctionHouse__FeeChargingCurrencyNotSupported(address currency);

/// @notice Emitted when the stake token is an invalid address.
error AuctionHouse__InvalidStakeTokenAddress();

/// @notice Emitted when the new minimum bid increment is out of the allowed range.
error AuctionHouse__MinimumBidIncrementOutOfBounds(uint256 bidIncrement);

/// @notice Emitted when the new maximum auction duration is too short.
error AuctionHouse__MaximumAuctionDurationTooShort(uint256 duration);

/// @notice Emitted if the computed end time is invalid.
error AuctionHouse__InvalidRoomEndTimeComputation(
    uint256 time,
    uint256 endTime
);

/// @notice Emitted when the user creates an auction with an unsupported currency.
error AuctionHouse__AuctionCurrencyNotAllowed(address currency);

/// @notice Emitted if the auction ends in the past.
error AuctionHouse__AuctionEndsInThePast(uint256 endTime);

/// @notice Emitted if the auction ends after the auction house shuts down.
error AuctionHouse__AuctionEndsAfterTermination(uint256 endTime);

/// @notice Emitted if the auction ends too late.
error AuctionHouse__AuctionDurationTooLong(uint256 endTime);

/// @notice Emitted if the auction commission is too high (it can be 0).
error AuctionHouse__AuctionCommissionShareOutOfBounds(uint256 commission);

/// @notice Emitted when user creates auction with an nft that doesn't follow any supported standard.
error AuctionHouse__AuctionInvalidNftStandard();

/// @notice Emitted if the user didn't stake enough to create auction.
error AuctionHouse__AuctionStakeTooLow();

/// @notice Emitted if the user doesn't have enough stake token to create auction.
error AuctionHouse__AuctionNotEnoughStakeToken();

/// @notice Emitted if the user allowance is too low.
error AuctionHouse__AuctionNotEnoughAllowance();

/// @notice Emitted if the user specified a stake amount even if not needed.
error AuctionHouse__AuctionStakeNotNeeded();

/// @notice Emitted if the user tries to claim net value too early.
error AuctionHouse__ClaimNetValueTooEarly();

/// @notice Emitted if the user tries to claim net value after the auction house was stopped.
error AuctionHouse__ClaimNetValueAfterAuctionHouseStopped();

/// @notice Emitted if the user claims an already claimed auction.
error AuctionHouse__ClaimNetValueAlreadyClaimed();

/// @notice Emitted if user claims nft too early.
error AuctionHouse__ClaimTokenTooEarly();

/// @notice Emitted if user claims nft after the auction house was stopped.
error AuctionHouse__ClaimTokenAfterAuctionHouseStopped();

/// @notice Emitted if the user claims an already claimed nft.
error AuctionHouse__ClaimTokenAlreadyClaimed();

/// @notice Emitted if user claims commission too early.
error AuctionHouse__ClaimCommissionTooEarly();

/// @notice Emitted if user claims commission after auction house was stopped.
error AuctionHouse__ClaimCommissionAfterAuctionHouseStopped();

/// @notice Emitted if user doesn't have enough token to stake.
error AuctionHouse__StakeNotEnoughToken();

/// @notice Emitted if user is staking after last chance start.
error AuctionHouse__StakeTooLate();

/// @notice Emitted if user bids after auction end time.
error AuctionHouse__BidTooLate();

/// @notice Emitted if user bid is below reserve price.
error AuctionHouse__BidBelowReservePrice();

/// @notice Emitted if the user bid is not sufficiently high.
error AuctionHouse__BidIncrementTooLow();

/// @notice Emitted if user bids during last chance, without a previous bid.
error AuctionHouse__BidWithoutBidBeforeLastChance();

/// @notice Emitted if user bids too many times during last chance.
error AuctionHouse__BidOverLastChanceLimit();

/// @notice Emitted if user did not send enough native token with bid.
error AuctionHouse__BidInvalidValue();

/// @notice Emitted if user doesn't have enough tokens to bid.
error AuctionHouse__BidNotEnoughToken();

/// @notice Emitted if user allowance is too low.
error AuctionHouse__BidNotEnoughAllowance();

/// @notice Emitted if the highest bidder has a zero bid.
error AuctionHouse__HighestBidderWithNoBid();

/// @notice Emitted if user tries to claim stake for auction ending
/// before emergency stop.
error AuctionHouse__EmergencyClaimStakeInvalidAuction();

/// @notice Emitted if user tries to claim the highest bid twice (during recovery).
error AuctionHouse__EmergencyClaimHighestBidAlreadyClaimed();

/// @notice Emitted if user tries to claim the highest bid for an auction
/// ending before emergency stop.
error AuctionHouse__EmergencyClaimHighestBidInvalidAuction();

/// @notice Emitted if user tries to claim their nft twice (during recovery).
error AuctionHouse__EmergencyClaimTokenAlreadyClaimed();

/// @notice Emitted if user tries emergency claim nft for an auction
/// ending before emergency stop.
error AuctionHouse__EmergencyClaimTokenInvalidAuction();

/// @notice Emitted if terminated after being already terminated.
error AuctionHouse__AlreadyTerminated();

/// @notice Emitted if the given termination timestamp is in the past.
error AuctionHouse__InvalidTerminationTimestamp();

/// @notice Auclantis decentralised auction house.
/// @dev The contract is:
///  - `IAuctionHouse`: users can interact with it to buy/sell NFT through
///     auctions.
///  - `Recoverable`: the auction house can be stopped and enter recovery mode
///    in case of emergency.
///  - `ERC721Holder`: it needs to be able to receive ERC-721 tokens when
///    starting the auction.
///  - `Ownable`: the owner can change some parameters of how the auction house
///    works.
///  - `ReentrancyGuard`: dealing with tokens, avoid reentracy attacks.
///
/// See IAuctionHouse documentation for more information about how the auction
/// house works.
contract AuctionHouse is
    IAuctionHouse,
    Recoverable,
    ERC721Holder,
    Ownable,
    ReentrancyGuard
{
    using ERC165Checker for address;
    using StakeHouse for StakeHouse.Info;

    /// @notice keep track of last chance status
    struct LastChanceState {
        /// @notice number of last chance bids for each auction and bidder, plus one (used as flag)
        mapping(address => uint8) bidCountPlusOne;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                            Storage                                   //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice last chance duration, in number of seconds.
    uint256 public immutable lastChanceDuration;

    /// @notice the address of the ERC-20 token used for staking.
    address public immutable stakeTokenAddress;

    /// @notice minimum bid increment, in percentage (e.g. 5).
    uint256 public minBidIncrementPct;

    /// @notice auctions by id.
    mapping(uint256 => Auction) internal auctions;

    /// @notice track if auctions have been claimed by seller.
    mapping(uint256 => bool) internal auctionsNetValueClaimed;

    /// @notice track if auctions have been claimed by buyer.
    mapping(uint256 => bool) internal auctionsTokenClaimed;

    /// @notice information about stakes for each auction.
    mapping(uint256 => StakeHouse.Info) internal stakeHouse;

    /// @notice keep track of last chance status.
    mapping(uint256 => LastChanceState) internal lastChance;

    /// @notice currencies allowed in auctions.
    mapping(address => bool) public allowedCurrencies;

    /// @notice volume sold by currency and user.
    mapping(address => mapping(address => uint256)) public volumeSold;

    /// @notice volume bought by currency and user.
    mapping(address => mapping(address => uint256)) public volumeBought;

    /// @dev auction id generator.
    uint256 private _auctionId;

    /// @notice interval between rooms
    uint256 public immutable roomInterval;

    /// @notice the auction house epoch.
    uint256 public epoch;

    /// @notice the amount of tokens sellers need to stake to create an auction.
    uint256 public createAuctionStake;

    /// @notice the maximum duration of an auction, in seconds.
    uint256 public maximumAuctionDuration;

    /// @notice the timestamp when the auction was stopped for an emergency.
    /// @dev this value is equal to `type(uint256).max` if the auction house
    /// is running.
    uint256 public emergencyStopTimestamp;

    /// @notice the timestamp before which all auctions must end.
    /// @dev this value is equal to `type(uint256).max` if the auction house
    /// doesn't have a termination date.
    uint256 public terminationTimestamp;

    /// @notice maximum number of last chance bids
    uint8 public immutable maxLastChanceBids;

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Constructor                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice create auction house.
    /// @param _stakeTokenAddress the stake token address.
    /// @param _epoch the auction house start time.
    /// @param _lastChanceDuration the duration of the last chance period, in seconds.
    constructor(
        address _stakeTokenAddress,
        uint256 _epoch,
        uint256 _lastChanceDuration
    ) {
        // checks: stake token address is not zero
        if (_stakeTokenAddress == address(0)) {
            revert AuctionHouse__InvalidStakeTokenAddress();
        }

        // effects: initialize auction house configuration
        stakeTokenAddress = _stakeTokenAddress;
        epoch = _epoch;
        lastChanceDuration = _lastChanceDuration;
        maximumAuctionDuration = 1 weeks;
        roomInterval = 8 hours;
        minBidIncrementPct = 5;
        maxLastChanceBids = 1;
        createAuctionStake = 0;
        emergencyStopTimestamp = type(uint256).max;
        terminationTimestamp = type(uint256).max;

        emit AuctionHouseCreated(
            _stakeTokenAddress,
            _epoch,
            maximumAuctionDuration,
            _lastChanceDuration,
            minBidIncrementPct,
            maxLastChanceBids,
            createAuctionStake
        );
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Termination                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function terminateAfterTimestamp(uint256 _terminationTimestamp)
        external
        override
        onlyOwner
    {
        // checks: not terminated already
        if (terminationTimestamp != type(uint256).max) {
            revert AuctionHouse__AlreadyTerminated();
        }

        if (_terminationTimestamp <= block.timestamp) {
            revert AuctionHouse__InvalidTerminationTimestamp();
        }

        terminationTimestamp = _terminationTimestamp;

        emit Terminated(_terminationTimestamp);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Recoverable                                //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function stop()
        external
        override
        onlyOwner
    {
        // checks: will fail if state is not running
        _stop();

        // effects: update emergency stop timestamp
        emergencyStopTimestamp = block.timestamp;

        emit Stopped();
    }

    /// @inheritdoc IAuctionHouse
    function recover()
        external
        override
        onlyOwner
    {
        _recover();

        emit Recovered();
    }

    /// @inheritdoc IAuctionHouse
    function emergencyClaimToken(uint256 auctionId)
        external
        override
        auctionExists(auctionId)
        whenRecovering
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: auction ends after emergency stop
        uint256 endTime = _roomEndTime(auction.roomId);
        if (endTime < emergencyStopTimestamp) {
            revert AuctionHouse__EmergencyClaimTokenInvalidAuction();
        }

        // checks: seller did not already claim back their nft
        if (auctionsNetValueClaimed[auctionId]) {
            revert AuctionHouse__EmergencyClaimTokenAlreadyClaimed();
        }

        // effects: update nft token claimed status
        auctionsNetValueClaimed[auctionId] = true;

        // interactions: transfer nft back to owner
        NftLib.NftStandard tokenStandard = NftLib.checkStandard(
            auction.tokenAddress
        );

        NftLib.safeTransferFrom(
            auction.tokenAddress,
            address(this),
            auction.tokenOwner,
            auction.tokenId,
            tokenStandard
        );

        emit AuctionTokenClaimedInEmergency(auctionId);
    }

    /// @inheritdoc IAuctionHouse
    function emergencyClaimHighestBid(uint256 auctionId)
        external
        override
        auctionExists(auctionId)
        whenRecovering
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: auction ends after emergency stop
        uint256 endTime = _roomEndTime(auction.roomId);
        if (endTime < emergencyStopTimestamp) {
            revert AuctionHouse__EmergencyClaimHighestBidInvalidAuction();
        }

        // checks: highest bidder exists
        if (auction.currentBidder == address(0)) {
            return;
        }

        // checks: highest bid is not zero
        if (auction.currentBid == 0) {
            revert AuctionHouse__HighestBidderWithNoBid();
        }

        // checks: bidder did not already claim their bid back
        if (auctionsTokenClaimed[auctionId]) {
            revert AuctionHouse__EmergencyClaimHighestBidAlreadyClaimed();
        }

        auctionsTokenClaimed[auctionId] = true;

        // interactions: transfer token back to highest bidder
        _safeTransfer(
            auction.currencyAddress,
            auction.currentBidder,
            auction.currentBid
        );

        emit AuctionHighestBidClaimedInEmergency(auctionId);
    }

    /// @inheritdoc IAuctionHouse
    function emergencyClaimStake(uint256 auctionId, address payable user)
        external
        override
        auctionExists(auctionId)
        whenRecovering
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: auction ends after emergency stop
        uint256 endTime = _roomEndTime(auction.roomId);
        if (endTime < emergencyStopTimestamp) {
            revert AuctionHouse__EmergencyClaimStakeInvalidAuction();
        }

        StakeHouse.Info storage stakeInfo = stakeHouse[auctionId];
        uint256 userStakedAmount = stakeInfo.stakes[user].amount;

        if (userStakedAmount == 0) {
            return;
        }

        // effects: delete user stake information to avoid double claim
        delete stakeInfo.stakes[user];

        // interactions: send token back to user
        _safeTransferStakeToken(user, userStakedAmount);

        emit AuctionStakeClaimedInEmergency(auctionId, user);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Update Options                               //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function allowCurrency(address currency, bool allowed)
        external
        override
        onlyOwner
        whenRunning
    {
        // note: currency == address(0) is used to represent the native token

        // effects: update if currency is allowed in auction house
        allowedCurrencies[currency] = allowed;

        emit CurrencyAllowedUpdated(currency, allowed);
    }

    /// @inheritdoc IAuctionHouse
    function updateMinBidIncrement(uint256 newMinBidIncrement)
        external
        override
        onlyOwner
        whenRunning
    {
        // checks: bid increment is greater than zero but less than 100%
        if (newMinBidIncrement == 0 || newMinBidIncrement >= 100) {
            revert AuctionHouse__MinimumBidIncrementOutOfBounds({
                bidIncrement: newMinBidIncrement
            });
        }

        // effects: update minimum bid increment
        minBidIncrementPct = newMinBidIncrement;

        emit MinBidIncrementPctUpdated(newMinBidIncrement);
    }

    /// @inheritdoc IAuctionHouse
    function updateCreateAuctionStake(uint256 newCreateAuctionStake)
        external
        override
        onlyOwner
        whenRunning
    {
        // note: stake can be 0

        // effects: update required stake to create auction
        createAuctionStake = newCreateAuctionStake;

        emit CreateAuctionStakeUpdated(newCreateAuctionStake);
    }

    /// @inheritdoc IAuctionHouse
    function updateMaximumAuctionDuration(uint256 newDuration)
        external
        override
        onlyOwner
        whenRunning
    {
        // checks: new duration must be at least as long as the previous duration
        if (newDuration <= maximumAuctionDuration) {
            revert AuctionHouse__MaximumAuctionDurationTooShort({
                duration: newDuration
            });
        }

        // effects: update maximum auction duration
        maximumAuctionDuration = newDuration;

        emit MaximumAuctionDurationUpdated(newDuration);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                       Volume Information                             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function getVolumeSold(address currencyAddress, address user)
        external
        view
        override
        returns (uint256)
    {
        return volumeSold[currencyAddress][user];
    }

    /// @inheritdoc IAuctionHouse
    function getVolumeBought(address currencyAddress, address user)
        external
        view
        override
        returns (uint256)
    {
        return volumeBought[currencyAddress][user];
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Room Information                             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function roomEndTime(uint256 roomId)
        external
        view
        override
        returns (uint256)
    {
        return _roomEndTime(roomId);
    }

    /// @inheritdoc IAuctionHouse
    function roomLastChanceStartTime(uint256 roomId)
        external
        view
        override
        returns (uint256)
    {
        return _roomLastChanceStartTime(roomId);
    }

    /// @inheritdoc IAuctionHouse
    function firstRoomEndingAfter(uint256 time)
        external
        view
        override
        returns (uint256)
    {
        if (time <= epoch) {
            return 0;
        }

        uint256 elapsedRooms = (time - epoch) / roomInterval;
        // double check to make sure it's correct
        uint256 endTime = _roomEndTime(elapsedRooms);

        // checks: the computed end time is after the given time
        if (endTime < time) {
            revert AuctionHouse__InvalidRoomEndTimeComputation({
                time: time,
                endTime: endTime
            });
        }

        return elapsedRooms;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                      Auction Management                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IAuctionHouse
    function totalAuctions() external view override returns (uint256) {
        return _auctionId;
    }

    /// @inheritdoc IAuctionHouse
    /// @dev Users can create auctions only when the auction house is running.
    // solhint-disable-next-line code-complexity
    function createAuction(
        uint256 roomId,
        address tokenAddress,
        uint256 tokenId,
        address currencyAddress,
        uint256 reservePrice,
        uint8 commissionSharePct,
        uint256 stakeAmount
    )
        external
        override
        beforeLastChanceStart(roomId)
        whenRunning
        nonReentrant
        returns (uint256)
    {
        {
            // checks: currency is supported by the auction house
            if (!allowedCurrencies[currencyAddress]) {
                revert AuctionHouse__AuctionCurrencyNotAllowed({
                    currency: currencyAddress
                });
            }

            uint256 endTime = _roomEndTime(roomId);

            // checks: end time is in the future
            if (block.timestamp >= endTime) {
                revert AuctionHouse__AuctionEndsInThePast({endTime: endTime});
            }

            // checks: end time is before auction house termination
            if (endTime >= terminationTimestamp) {
                revert AuctionHouse__AuctionEndsAfterTermination({
                    endTime: endTime
                });
            }

            // checks: auction duration is within maximum allowed
            if (endTime - block.timestamp >= maximumAuctionDuration) {
                revert AuctionHouse__AuctionDurationTooLong({endTime: endTime});
            }

            // checks: auction commission is less than 100%, it can be 0%
            if (commissionSharePct > 100) {
                revert AuctionHouse__AuctionCommissionShareOutOfBounds({
                    commission: commissionSharePct
                });
            }
        }

        // checks: token supports any standard we support
        NftLib.NftStandard tokenStandard = NftLib.checkStandard(tokenAddress);

        if (tokenStandard == NftLib.NftStandard.Unknown) {
            revert AuctionHouse__AuctionInvalidNftStandard();
        }

        // checks: msg.sender can transfer the nft token
        NftLib.checkCanTransfer(
            msg.sender,
            tokenAddress,
            tokenId,
            tokenStandard
        );

        address payable tokenOwner = payable(msg.sender);

        if (createAuctionStake > 0) {
            // checks: specified stake amount is enough to create auction
            if (stakeAmount < createAuctionStake) {
                revert AuctionHouse__AuctionStakeTooLow();
            }

            // checks: user stake token balance is high enough
            if (ERC20(stakeTokenAddress).balanceOf(tokenOwner) < stakeAmount) {
                revert AuctionHouse__AuctionNotEnoughStakeToken();
            }

            // checks: allowance is high enough to stake
            if (
                ERC20(stakeTokenAddress).allowance(tokenOwner, address(this)) <
                stakeAmount
            ) {
                revert AuctionHouse__AuctionNotEnoughAllowance();
            }
        } else {
            // checks: user did not try to stake
            if (stakeAmount != 0) {
                revert AuctionHouse__AuctionStakeNotNeeded();
            }
        }

        // effects: create auction
        uint256 auctionId = _createAuction(
            roomId,
            tokenOwner,
            tokenOwner,
            tokenAddress,
            tokenId,
            currencyAddress,
            reservePrice,
            commissionSharePct,
            stakeAmount
        );

        // interactions: transfer the nft
        NftLib.safeTransferFrom(
            tokenAddress,
            tokenOwner,
            address(this),
            tokenId,
            tokenStandard
        );

        // interactions: transfer stake (token only if necessary)
        if (createAuctionStake > 0) {
            _safeTransferStakeTokenFrom(tokenOwner, address(this), stakeAmount);
        }

        // all done
        emit AuctionStarted(
            roomId,
            auctionId,
            tokenOwner,
            tokenAddress,
            tokenId,
            currencyAddress,
            reservePrice,
            commissionSharePct,
            stakeAmount
        );

        return auctionId;
    }

    /// @inheritdoc IAuctionHouse
    /// @dev Users can claim net value only if:
    ///
    ///  - the auction house is running, OR
    ///  - the auction house was stopped after the auction ended, and
    ///    then resumed.
    ///
    /// If no user staked on this auction, the community commission
    /// is ignored to avoid burning tokens.
    function claimAuctionNetValue(uint256 auctionId)
        external
        override
        auctionExists(auctionId)
        whenNotStopped
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: after auction end time
        uint256 endTime = _roomEndTime(auction.roomId);
        if (block.timestamp <= endTime) {
            revert AuctionHouse__ClaimNetValueTooEarly();
        }

        // checks: end time before auction house stopped
        if (endTime >= emergencyStopTimestamp) {
            revert AuctionHouse__ClaimNetValueAfterAuctionHouseStopped();
        }

        // checks: auction net value not already claimed
        if (auctionsNetValueClaimed[auctionId]) {
            revert AuctionHouse__ClaimNetValueAlreadyClaimed();
        }

        // effects: update auction net value claimed status
        auctionsNetValueClaimed[auctionId] = true;

        uint256 saleAmount = 0;

        if (auction.currentBidder != address(0)) {
            // effects: update volume sold by auction owner
            volumeSold[auction.currencyAddress][auction.owner] += auction
                .currentBid;

            uint256 saleAmountAfterFees = auction.currentBid;

            // interactions: check amount due for royalty
            (address royaltyReceiver, uint256 royaltyAmount) = NftLib
                .royaltyInfo(
                    auction.tokenAddress,
                    auction.tokenId,
                    saleAmountAfterFees
                );

            // underflows if royaltyAmount is greater than the bid.
            saleAmountAfterFees -= royaltyAmount;

            // check if any user staked on this auction. If not, don't
            // compute community commission and simply sell whole amount.
            StakeHouse.Info storage stakeInfo = stakeHouse[auctionId];

            if (stakeInfo.totalStakedAmount > 0) {
                // compute net value amount
                (
                    ,
                    /* community share */
                    saleAmount
                ) = _communitySellerShare(
                    saleAmountAfterFees,
                    auction.commissionSharePct
                );
            } else {
                saleAmount = saleAmountAfterFees;
            }

            // interactions: transfer net value to auction's owner
            _safeTransfer(auction.currencyAddress, auction.owner, saleAmount);

            // interactions: transfer royalty to receiver
            if (royaltyAmount > 0) {
                _safeTransfer(
                    auction.currencyAddress,
                    payable(royaltyReceiver),
                    royaltyAmount
                );
            }
        } else {
            // interactions: transfer nft back to auction's owner
            NftLib.NftStandard tokenStandard = NftLib.checkStandard(
                auction.tokenAddress
            );

            NftLib.safeTransferFrom(
                auction.tokenAddress,
                address(this),
                auction.tokenOwner,
                auction.tokenId,
                tokenStandard
            );
        }

        // interactions: transfer back staked tokens (if any)
        if (auction.stakeAmount > 0) {
            _safeTransferStakeToken(auction.owner, auction.stakeAmount);
        }

        // effects: free up storage
        delete lastChance[auctionId];

        // all done
        emit AuctionNetValueClaimed(auction.roomId, auctionId, saleAmount);
    }

    /// @inheritdoc IAuctionHouse
    function claimAuctionToken(uint256 auctionId)
        external
        override
        auctionExists(auctionId)
        whenNotStopped
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: now is after auction end
        uint256 endTime = _roomEndTime(auction.roomId);
        if (block.timestamp <= endTime) {
            revert AuctionHouse__ClaimTokenTooEarly();
        }

        // checks: end time before auction house stopped
        if (endTime >= emergencyStopTimestamp) {
            revert AuctionHouse__ClaimTokenAfterAuctionHouseStopped();
        }

        // checks: not already claimed
        if (auctionsTokenClaimed[auctionId]) {
            revert AuctionHouse__ClaimTokenAlreadyClaimed();
        }

        // effects: updated claimed status
        auctionsTokenClaimed[auctionId] = true;

        address winner = address(0);
        if (auction.currentBidder != address(0)) {
            winner = auction.currentBidder;

            // effects: update volume bought by winner
            volumeBought[auction.currencyAddress][winner] += auction.currentBid;

            NftLib.NftStandard tokenStandard = NftLib.checkStandard(
                auction.tokenAddress
            );

            // interactions: transfer nft to winner
            NftLib.safeTransferFrom(
                auction.tokenAddress,
                address(this),
                winner,
                auction.tokenId,
                tokenStandard
            );
        }

        emit AuctionTokenClaimed(auction.roomId, auctionId, winner);
    }

    /// @inheritdoc IAuctionHouse
    function claimAuctionCommission(uint256 auctionId, address payable user)
        external
        override
        auctionExists(auctionId)
        whenNotStopped
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];

        // checks: now after end time
        uint256 endTime = _roomEndTime(auction.roomId);
        if (block.timestamp <= endTime) {
            revert AuctionHouse__ClaimCommissionTooEarly();
        }

        // checks: end time before auction house stopped
        if (endTime >= emergencyStopTimestamp) {
            revert AuctionHouse__ClaimCommissionAfterAuctionHouseStopped();
        }

        StakeHouse.Info storage stakeInfo = stakeHouse[auctionId];

        uint256 userStakedAmount = stakeInfo.stakes[user].amount;

        // user did not stake. nothing to return, nothing to claim.
        if (userStakedAmount == 0) {
            return;
        }

        uint256 userShare = 0;

        // compute user share
        if (auction.currentBidder != address(0)) {
            if (auction.currentBid == 0) {
                revert AuctionHouse__HighestBidderWithNoBid();
            }

            uint256 saleAmountAfterFees = auction.currentBid;

            // interactions: check amount due for royalty
            (
                ,
                /* receiver */
                uint256 royaltyAmount
            ) = NftLib.royaltyInfo(
                    auction.tokenAddress,
                    auction.tokenId,
                    saleAmountAfterFees
                );

            // underflows if royaltyAmount is greater than the bid.
            saleAmountAfterFees -= royaltyAmount;

            (
                uint256 communityShare, /* seller share */

            ) = _communitySellerShare(
                    saleAmountAfterFees,
                    auction.commissionSharePct
                );

            userShare = stakeInfo.userShare(user, communityShare);
        }

        // effects: free up storage and avoid double claim
        delete stakeInfo.stakes[user];

        // interactions: send token (only if share is positive)
        if (userShare > 0) {
            _safeTransfer(auction.currencyAddress, user, userShare);
        }

        // interactions: in any case, return staked token
        _safeTransferStakeToken(user, userStakedAmount);

        emit AuctionCommissionClaimed(
            auction.roomId,
            auctionId,
            user,
            userShare
        );
    }

    /// @inheritdoc IAuctionHouse
    function stake(uint256 auctionId, uint256 amount)
        external
        override
        auctionExists(auctionId)
        whenRunning
        nonReentrant
    {
        if (ERC20(stakeTokenAddress).balanceOf(msg.sender) < amount) {
            revert AuctionHouse__StakeNotEnoughToken();
        }

        Auction storage auction = auctions[auctionId];

        // checks: last chance not started yet
        uint256 lastChanceStart = _roomLastChanceStartTime(auction.roomId);
        if (block.timestamp >= lastChanceStart) {
            revert AuctionHouse__StakeTooLate();
        }

        uint256 stakeShare;
        uint256 totalShare;
        (
            ,
            /* is new */
            stakeShare,
            totalShare
        ) = stakeHouse[auctionId].addStake(msg.sender, amount);

        // interactions: transfer token to auction house
        _safeTransferStakeTokenFrom(msg.sender, address(this), amount);

        // all done
        emit AuctionStake(
            auction.roomId,
            auctionId,
            msg.sender,
            amount,
            stakeShare,
            totalShare
        );
    }

    /// @inheritdoc IAuctionHouse
    // solhint-disable-next-line code-complexity
    function bid(uint256 auctionId, uint256 amount)
        external
        payable
        override
        auctionExists(auctionId)
        whenRunning
        nonReentrant
    {
        Auction storage auction = auctions[auctionId];
        uint256 endTime = _roomEndTime(auction.roomId);
        uint256 lastChanceStart = _roomLastChanceStartTime(auction.roomId);
        // checks: auction not ended yet
        if (block.timestamp >= endTime) {
            revert AuctionHouse__BidTooLate();
        }

        // checks: bid at least reserve price
        if (amount < auction.reservePrice) {
            revert AuctionHouse__BidBelowReservePrice();
        }

        // checks: need to be at least minBidIncrementPct higher than existing bid
        uint256 minimumBidIncrement = (auction.currentBid *
            minBidIncrementPct) / 100;
        if (amount - auction.currentBid < minimumBidIncrement) {
            revert AuctionHouse__BidIncrementTooLow();
        }

        bool isLastChanceBid = block.timestamp >= lastChanceStart;

        LastChanceState storage lastChanceState = lastChance[auctionId];
        if (isLastChanceBid) {
            uint256 bidsCount = lastChanceState.bidCountPlusOne[msg.sender];

            // checks: users need to have bid at least once before last chance
            if (bidsCount == 0) {
                revert AuctionHouse__BidWithoutBidBeforeLastChance();
            }

            // checks: but cannot have voted more than the maximum number of times in last chance
            if (bidsCount - 1 >= maxLastChanceBids) {
                revert AuctionHouse__BidOverLastChanceLimit();
            }
        }

        if (isLastChanceBid) {
            // effects: increment number of last chance bids for user
            lastChanceState.bidCountPlusOne[msg.sender] += 1;
        } else {
            // effects: if it's not last chance, simply set flag to show user bid
            lastChanceState.bidCountPlusOne[msg.sender] = 1;
        }

        // remember previous bidder and bid
        address payable previousBidder = auction.currentBidder;
        uint256 previousBid = auction.currentBid;

        // effects: update highest bid and bidder
        auction.currentBid = amount;
        auction.currentBidder = payable(msg.sender);

        // interactions: refund previous bidder if any
        if (previousBidder != address(0)) {
            _safeTransfer(auction.currencyAddress, previousBidder, previousBid);
        }

        if (auction.currencyAddress == address(0)) {
            // checks: bid native token amount
            if (msg.value != amount) {
                revert AuctionHouse__BidInvalidValue();
            }
        } else {
            // checks: has enough tokens to bid
            if (ERC20(auction.currencyAddress).balanceOf(msg.sender) < amount) {
                revert AuctionHouse__BidNotEnoughToken();
            }

            // checks: enough allowance left
            if (
                ERC20(auction.currencyAddress).allowance(
                    msg.sender,
                    address(this)
                ) < amount
            ) {
                revert AuctionHouse__BidNotEnoughAllowance();
            }

            // interactions: transfer token to auction house
            _safeTransferFrom(
                auction.currencyAddress,
                msg.sender,
                address(this),
                amount
            );
        }

        // all done
        emit AuctionBid(
            auction.roomId,
            auctionId,
            auction.currentBidder,
            auction.currentBid
        );
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Modifiers                                  //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev requires that the current time is before the room last chance starts.
    modifier beforeLastChanceStart(uint256 roomId) {
        // checks: now is before last chance start time
        uint256 lastChanceStart = _roomLastChanceStartTime(roomId);
        if (block.timestamp >= lastChanceStart) {
            revert AuctionHouse__AfterLastChance({roomId: roomId});
        }

        _;
    }

    /// @dev requires that an auction with the given id exists
    modifier auctionExists(uint256 auctionId) {
        // checks: auction exists
        if (auctions[auctionId].tokenAddress == address(0)) {
            revert AuctionHouse__AuctionDoesNotExist({auctionId: auctionId});
        }

        _;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                       Private Functions                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    function _roomEndTime(uint256 roomId) internal view returns (uint256) {
        return epoch + (roomInterval * (1 + roomId));
    }

    function _roomLastChanceStartTime(uint256 roomId)
        internal
        view
        returns (uint256)
    {
        uint256 endTime = _roomEndTime(roomId);
        return endTime - lastChanceDuration;
    }

    function _createAuction(
        uint256 roomId,
        address payable owner,
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId,
        address currencyAddress,
        uint256 reservePrice,
        uint8 commissionSharePct,
        uint256 stakeAmount
    ) internal returns (uint256) {
        // effects: increment auction id
        uint256 auctionId = _auctionId;
        _auctionId += 1;

        // effects: store new auction values
        Auction storage auction = auctions[auctionId];
        auction.roomId = roomId;
        auction.owner = owner;
        auction.tokenOwner = tokenOwner;
        auction.reservePrice = reservePrice;
        auction.currencyAddress = currencyAddress;
        auction.tokenAddress = tokenAddress;
        auction.tokenId = tokenId;
        auction.commissionSharePct = commissionSharePct;
        auction.stakeAmount = stakeAmount;

        return auctionId;
    }

    function _communitySellerShare(uint256 amount, uint8 commissionSharePct)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 sharePct = uint256(commissionSharePct);
        uint256 communityShare = (amount * sharePct) / 100;
        uint256 sellerShare = amount - communityShare;
        return (communityShare, sellerShare);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                  !!! Token Transfer Functions !!!                    //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    function _safeTransferStakeTokenFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        _safeTransferFrom(stakeTokenAddress, from, to, amount);
    }

    function _safeTransferStakeToken(address payable to, uint256 amount)
        internal
    {
        _safeTransfer(stakeTokenAddress, to, amount);
    }

    function _safeTransferFrom(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        // tokens could charge a transfer fee, so the amount received is less than amount
        // don't support them for now
        uint256 balanceBeforeTransfer = ERC20(currency).balanceOf(to);
        SafeTransferLib.safeTransferFrom(ERC20(currency), from, to, amount);
        uint256 balanceAfterTransfer = ERC20(currency).balanceOf(to);

        if (balanceBeforeTransfer + amount != balanceAfterTransfer) {
            revert AuctionHouse__FeeChargingCurrencyNotSupported({
                currency: currency
            });
        }
    }

    function _safeTransfer(
        address currency,
        address payable to,
        uint256 amount
    ) internal {
        if (currency == address(0)) {
            SafeTransferLib.safeTransferETH(to, amount);
        } else {
            // as with _safeTransferFrom, revert if token charges a fee
            uint256 balanceBeforeTransfer = ERC20(currency).balanceOf(to);
            SafeTransferLib.safeTransfer(ERC20(currency), to, amount);
            uint256 balanceAfterTransfer = ERC20(currency).balanceOf(to);

            if (balanceBeforeTransfer + amount != balanceAfterTransfer) {
                revert AuctionHouse__FeeChargingCurrencyNotSupported({
                    currency: currency
                });
            }
        }
    }
}