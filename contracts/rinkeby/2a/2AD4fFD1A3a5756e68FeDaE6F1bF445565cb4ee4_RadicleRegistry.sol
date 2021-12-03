/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/registry.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-only
pragma solidity >=0.8.0 <0.9.0 >=0.8.7 <0.9.0;

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
}

////// lib/openzeppelin-contracts/contracts/proxy/Clones.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/security/Pausable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

////// lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC721.sol"; */

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

////// lib/openzeppelin-contracts/contracts/utils/Strings.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC721.sol"; */
/* import "./IERC721Receiver.sol"; */
/* import "./extensions/IERC721Metadata.sol"; */
/* import "../../utils/Address.sol"; */
/* import "../../utils/Context.sol"; */
/* import "../../utils/Strings.sol"; */
/* import "../../utils/introspection/ERC165.sol"; */

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

////// lib/radicle-drips-hub/src/DripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {Ownable} from "openzeppelin-contracts/access/Ownable.sol"; */
/* import {Pausable} from "openzeppelin-contracts/security/Pausable.sol"; */

struct DripsReceiver {
    address receiver;
    uint128 amtPerSec;
}

struct SplitsReceiver {
    address receiver;
    uint32 weight;
}

/// @notice Drips hub contract. Automatically drips and splits funds between users.
///
/// The user can transfer some funds to their drips balance in the contract
/// and configure a list of receivers, to whom they want to drip these funds.
/// As soon as the drips balance is enough to cover at least 1 second of dripping
/// to the configured receivers, the funds start dripping automatically.
/// Every second funds are deducted from the drips balance and moved to their receivers' accounts.
/// The process stops automatically when the drips balance is not enough to cover another second.
///
/// The user can have any number of independent configurations and drips balances by using accounts.
/// An account is identified by the user address and an account identifier.
/// Accounts of different users are separate entities, even if they have the same identifiers.
/// An account can be used to drip or give, but not to receive funds.
///
/// Every user has a receiver balance, in which they have funds received from other users.
/// The dripped funds are added to the receiver balances in global cycles.
/// Every `cycleSecs` seconds the drips hub adds dripped funds to the receivers' balances,
/// so recently dripped funds may not be collectable immediately.
/// `cycleSecs` is a constant configured when the drips hub is deployed.
/// The receiver balance is independent from the drips balance,
/// to drip received funds they need to be first collected and then added to the drips balance.
///
/// The user can share collected funds with other users by using splits.
/// When collecting, the user gives each of their splits receivers a fraction of the received funds.
/// Funds received from splits are available for collection immediately regardless of the cycle.
/// They aren't exempt from being split, so they too can be split when collected.
/// Users can build chains and networks of splits between each other.
/// Anybody can request collection of funds for any user,
/// which can be used to enforce the flow of funds in the network of splits.
///
/// The concept of something happening periodically, e.g. every second or every `cycleSecs` are
/// only high-level abstractions for the user, Ethereum isn't really capable of scheduling work.
/// The actual implementation emulates that behavior by calculating the results of the scheduled
/// events based on how many seconds have passed and only when the user needs their outcomes.
///
/// The contract assumes that all amounts in the system can be stored in signed 128-bit integers.
/// It's guaranteed to be safe only when working with assets with supply lower than `2 ^ 127`.
abstract contract DripsHub is Ownable, Pausable {
    /// @notice On every timestamp `T`, which is a multiple of `cycleSecs`, the receivers
    /// gain access to drips collected during `T - cycleSecs` to `T - 1`.
    uint64 public immutable cycleSecs;
    /// @notice Timestamp at which all drips must be finished
    uint64 internal constant MAX_TIMESTAMP = type(uint64).max - 2;
    /// @notice Maximum number of drips receivers of a single user.
    /// Limits cost of changes in drips configuration.
    uint32 public constant MAX_DRIPS_RECEIVERS = 100;
    /// @notice Maximum number of splits receivers of a single user.
    /// Limits cost of collecting.
    uint32 public constant MAX_SPLITS_RECEIVERS = 200;
    /// @notice The total splits weight of a user
    uint32 public constant TOTAL_SPLITS_WEIGHT = 1_000_000;

    /// @notice Emitted when drips from a user to a receiver are updated.
    /// Funds are being dripped on every second between the event block's timestamp (inclusively)
    /// and`endTime` (exclusively) or until the timestamp of the next drips update (exclusively).
    /// @param user The dripping user
    /// @param receiver The receiver of the updated drips
    /// @param amtPerSec The new amount per second dripped from the user
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop,
    /// always larger than the block timestamp or equal to it if the drips are stopped
    event Dripping(
        address indexed user,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when drips from a user's account to a receiver are updated.
    /// Funds are being dripped on every second between the event block's timestamp (inclusively)
    /// and`endTime` (exclusively) or until the timestamp of the next drips update (exclusively).
    /// @param user The user
    /// @param account The dripping account
    /// @param receiver The receiver of the updated drips
    /// @param amtPerSec The new amount per second dripped from the user's account
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop,
    /// always larger than the block timestamp or equal to it if the drips are stopped
    event Dripping(
        address indexed user,
        uint256 indexed account,
        address indexed receiver,
        uint128 amtPerSec,
        uint64 endTime
    );

    /// @notice Emitted when the drips configuration of a user is updated.
    /// @param user The user
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    /// @param receivers The new list of the drips receivers.
    event DripsUpdated(address indexed user, uint128 balance, DripsReceiver[] receivers);

    /// @notice Emitted when the drips configuration of a user's account is updated.
    /// @param user The user
    /// @param account The account
    /// @param balance The new drips balance. These funds will be dripped to the receivers.
    /// @param receivers The new list of the drips receivers.
    event DripsUpdated(
        address indexed user,
        uint256 indexed account,
        uint128 balance,
        DripsReceiver[] receivers
    );

    /// @notice Emitted when the user's splits are updated.
    /// @param user The user
    /// @param receivers The list of the user's splits receivers.
    event SplitsUpdated(address indexed user, SplitsReceiver[] receivers);

    /// @notice Emitted when a user collects funds
    /// @param user The user
    /// @param collected The collected amount
    /// @param split The amount split to the user's splits receivers
    event Collected(address indexed user, uint128 collected, uint128 split);

    /// @notice Emitted when funds are split from a user to a receiver.
    /// This is caused by the user collecting received funds.
    /// @param user The user
    /// @param receiver The splits receiver
    /// @param amt The amount split to the receiver
    event Split(address indexed user, address indexed receiver, uint128 amt);

    /// @notice Emitted when funds are given from the user to the receiver.
    /// @param user The address of the user
    /// @param receiver The receiver
    /// @param amt The given amount
    event Given(address indexed user, address indexed receiver, uint128 amt);

    /// @notice Emitted when funds are given from the user's account to the receiver.
    /// @param user The address of the user
    /// @param account The user's account
    /// @param receiver The receiver
    /// @param amt The given amount
    event Given(
        address indexed user,
        uint256 indexed account,
        address indexed receiver,
        uint128 amt
    );

    struct ReceiverState {
        // The amount collectable independently from cycles
        uint128 collectable;
        // The next cycle to be collected
        uint64 nextCollectedCycle;
        // --- SLOT BOUNDARY
        // The changes of collected amounts on specific cycle.
        // The keys are cycles, each cycle `C` becomes collectable on timestamp `C * cycleSecs`.
        // Values for cycles before `nextCollectedCycle` are guaranteed to be zeroed.
        // This means that the value of `amtDeltas[nextCollectedCycle].thisCycle` is always
        // relative to 0 or in other words it's an absolute value independent from other cycles.
        mapping(uint64 => AmtDelta) amtDeltas;
    }

    struct AmtDelta {
        // Amount delta applied on this cycle
        int128 thisCycle;
        // Amount delta applied on the next cycle
        int128 nextCycle;
    }

    struct UserOrAccount {
        bool isAccount;
        address user;
        uint256 account;
    }

    /// @notice Users' splits configuration hashes, see `hashSplits`.
    /// The key is the user address.
    mapping(address => bytes32) public splitsHash;
    /// @notice Users' drips configuration hashes, see `hashDrips`.
    /// The key is the user address.
    mapping(address => bytes32) internal userDripsHashes;
    /// @notice Users' accounts' configuration hashes, see `hashDrips`.
    /// The key are the user address and the account.
    mapping(address => mapping(uint256 => bytes32)) internal accountDripsHashes;
    /// @notice Users' receiver states.
    /// The key is the user address.
    mapping(address => ReceiverState) internal receiverStates;

    /// @param _cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being collectable by their receivers.
    /// High value makes collecting cheaper by making it process less cycles for a given time range.
    /// @param owner The initial owner of the contract with managerial abilities.
    constructor(uint64 _cycleSecs, address owner) {
        cycleSecs = _cycleSecs;
        transferOwnership(owner);
    }

    /// @notice Pauses any functions changing the state of the contract.
    /// Callable only by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses any functions changing the state of the contract.
    /// Callable only by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Returns amount of received funds available for collection for a user.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function collectable(address user, SplitsReceiver[] memory currReceivers)
        public
        view
        returns (uint128 collected, uint128 split)
    {
        ReceiverState storage receiver = receiverStates[user];
        _assertCurrSplits(user, currReceivers);

        // Collectable independently from cycles
        collected = receiver.collectable;

        // Collectable from cycles
        uint64 collectedCycle = receiver.nextCollectedCycle;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        if (collectedCycle != 0 && collectedCycle <= currFinishedCycle) {
            int128 cycleAmt = 0;
            for (; collectedCycle <= currFinishedCycle; collectedCycle++) {
                cycleAmt += receiver.amtDeltas[collectedCycle].thisCycle;
                collected += uint128(cycleAmt);
                cycleAmt += receiver.amtDeltas[collectedCycle].nextCycle;
            }
        }

        // split when collected
        if (collected > 0 && currReceivers.length > 0) {
            uint32 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
            }
            split = uint128((uint160(collected) * splitsWeight) / TOTAL_SPLITS_WEIGHT);
            collected -= split;
        }
    }

    /// @notice Collects all received funds available for the user
    /// and transfers them out of the drips hub contract to that user's wallet.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function collect(address user, SplitsReceiver[] memory currReceivers)
        public
        whenNotPaused
        returns (uint128 collected, uint128 split)
    {
        (collected, split) = _collectInternal(user, currReceivers);
        _transfer(user, int128(collected));
    }

    /// @notice Counts cycles which will need to be analyzed when collecting or flushing.
    /// This function can be used to detect that there are too many cycles
    /// to analyze in a single transaction and flushing is needed.
    /// @param user The user
    /// @return flushable The number of cycles which can be flushed
    function flushableCycles(address user) public view returns (uint64 flushable) {
        uint64 nextCollectedCycle = receiverStates[user].nextCollectedCycle;
        if (nextCollectedCycle == 0) return 0;
        uint64 currFinishedCycle = _currTimestamp() / cycleSecs;
        return currFinishedCycle + 1 - nextCollectedCycle;
    }

    /// @notice Flushes uncollected cycles of the user.
    /// Flushed cycles won't need to be analyzed when the user collects from them.
    /// Calling this function does not collect and does not affect the collectable amount.
    ///
    /// This function is needed when collecting funds received over a period so long, that the gas
    /// needed for analyzing all the uncollected cycles can't fit in a single transaction.
    /// Calling this function allows spreading the analysis cost over multiple transactions.
    /// A cycle is never flushed more than once, even if this function is called many times.
    /// @param user The user
    /// @param maxCycles The maximum number of flushed cycles.
    /// If too low, flushing will be cheap, but will cut little gas from the next collection.
    /// If too high, flushing may become too expensive to fit in a single transaction.
    /// @return flushable The number of cycles which can be flushed
    function flushCycles(address user, uint64 maxCycles)
        public
        whenNotPaused
        returns (uint64 flushable)
    {
        flushable = flushableCycles(user);
        uint64 cycles = maxCycles < flushable ? maxCycles : flushable;
        flushable -= cycles;
        uint128 collected = _flushCyclesInternal(user, cycles);
        if (collected > 0) receiverStates[user].collectable += collected;
    }

    /// @notice Collects all received funds available for the user,
    /// but doesn't transfer them to the user's wallet.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function _collectInternal(address user, SplitsReceiver[] memory currReceivers)
        internal
        returns (uint128 collected, uint128 split)
    {
        ReceiverState storage receiver = receiverStates[user];
        _assertCurrSplits(user, currReceivers);

        // Collectable independently from cycles
        collected = receiver.collectable;
        if (collected > 0) receiver.collectable = 0;

        // Collectable from cycles
        uint64 cycles = flushableCycles(user);
        collected += _flushCyclesInternal(user, cycles);

        // split when collected
        if (collected > 0 && currReceivers.length > 0) {
            uint32 splitsWeight = 0;
            for (uint256 i = 0; i < currReceivers.length; i++) {
                splitsWeight += currReceivers[i].weight;
                uint128 splitsAmt = uint128(
                    (uint160(collected) * splitsWeight) / TOTAL_SPLITS_WEIGHT - split
                );
                split += splitsAmt;
                address splitsReceiver = currReceivers[i].receiver;
                receiverStates[splitsReceiver].collectable += splitsAmt;
                emit Split(user, splitsReceiver, splitsAmt);
            }
            collected -= split;
        }
        emit Collected(user, collected, split);
    }

    /// @notice Collects and clears user's cycles
    /// @param user The user
    /// @param count The number of flushed cycles.
    /// @return collectedAmt The collected amount
    function _flushCyclesInternal(address user, uint64 count)
        internal
        returns (uint128 collectedAmt)
    {
        if (count == 0) return 0;
        ReceiverState storage receiver = receiverStates[user];
        uint64 cycle = receiver.nextCollectedCycle;
        int128 cycleAmt = 0;
        for (uint256 i = 0; i < count; i++) {
            cycleAmt += receiver.amtDeltas[cycle].thisCycle;
            collectedAmt += uint128(cycleAmt);
            cycleAmt += receiver.amtDeltas[cycle].nextCycle;
            delete receiver.amtDeltas[cycle];
            cycle++;
        }
        // The next cycle delta must be relative to the last collected cycle, which got zeroed.
        // In other words the next cycle delta must be an absolute value.
        if (cycleAmt != 0) receiver.amtDeltas[cycle].thisCycle += cycleAmt;
        receiver.nextCollectedCycle = cycle;
    }

    /// @notice Gives funds from the user or their account to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the user's wallet to the drips hub contract.
    /// @param userOrAccount The user or their account
    /// @param receiver The receiver
    /// @param amt The given amount
    function _give(
        UserOrAccount memory userOrAccount,
        address receiver,
        uint128 amt
    ) internal {
        receiverStates[receiver].collectable += amt;
        if (userOrAccount.isAccount) {
            emit Given(userOrAccount.user, userOrAccount.account, receiver, amt);
        } else {
            emit Given(userOrAccount.user, receiver, amt);
        }
        _transfer(userOrAccount.user, -int128(amt));
    }

    /// @notice Current user's drips hash, see `hashDrips`.
    /// @param user The user
    /// @return currDripsHash The current user's drips hash
    function dripsHash(address user) public view returns (bytes32 currDripsHash) {
        return userDripsHashes[user];
    }

    /// @notice Current user account's drips hash, see `hashDrips`.
    /// @param user The user
    /// @param account The account
    /// @return currDripsHash The current user account's drips hash
    function dripsHash(address user, uint256 account) public view returns (bytes32 currDripsHash) {
        return accountDripsHashes[user][account];
    }

    /// @notice Sets the user's or the account's drips configuration.
    /// Transfers funds between the user's wallet and the drips hub contract
    /// to fulfill the change of the drips balance.
    /// @param userOrAccount The user or their account
    /// @param lastUpdate The timestamp of the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the user or the account to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the user or the account.
    /// Pass it as `lastBalance` when updating that user or the account for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    function _setDrips(
        UserOrAccount memory userOrAccount,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) internal returns (uint128 newBalance, int128 realBalanceDelta) {
        _assertCurrDrips(userOrAccount, lastUpdate, lastBalance, currReceivers);
        uint128 newAmtPerSec = _assertDripsReceiversValid(newReceivers);
        uint128 currAmtPerSec = _totalDripsAmtPerSec(currReceivers);
        uint64 currEndTime = _dripsEndTime(lastUpdate, lastBalance, currAmtPerSec);
        (newBalance, realBalanceDelta) = _updateDripsBalance(
            lastUpdate,
            lastBalance,
            currEndTime,
            currAmtPerSec,
            balanceDelta
        );
        uint64 newEndTime = _dripsEndTime(_currTimestamp(), newBalance, newAmtPerSec);
        _updateDripsReceiversStates(
            userOrAccount,
            currReceivers,
            currEndTime,
            newReceivers,
            newEndTime
        );
        _storeCurrDrips(userOrAccount, newBalance, newReceivers);
        _emitDripsUpdated(userOrAccount, newBalance, newReceivers);
        _transfer(userOrAccount.user, -realBalanceDelta);
    }

    /// @notice Validates a list of drips receivers.
    /// @param receivers The list of drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return totalAmtPerSec The total amount per second of all drips receivers.
    function _assertDripsReceiversValid(DripsReceiver[] memory receivers)
        internal
        pure
        returns (uint128 totalAmtPerSec)
    {
        require(receivers.length <= MAX_DRIPS_RECEIVERS, "Too many drips receivers");
        uint256 amtPerSec = 0;
        address prevReceiver;
        for (uint256 i = 0; i < receivers.length; i++) {
            uint128 amt = receivers[i].amtPerSec;
            require(amt != 0, "Drips receiver amtPerSec is zero");
            amtPerSec += amt;
            address receiver = receivers[i].receiver;
            if (i > 0) {
                require(prevReceiver != receiver, "Duplicate drips receivers");
                require(prevReceiver < receiver, "Drips receivers not sorted by address");
            }
            prevReceiver = receiver;
        }
        require(amtPerSec <= type(uint128).max, "Total drips receivers amtPerSec too high");
        return uint128(amtPerSec);
    }

    /// @notice Calculates the total amount per second of all the drips receivers.
    /// @param receivers The list of the receivers.
    /// It must have passed `_assertDripsReceiversValid` in the past.
    /// @return totalAmtPerSec The total amount per second of all the drips receivers
    function _totalDripsAmtPerSec(DripsReceiver[] memory receivers)
        internal
        pure
        returns (uint128 totalAmtPerSec)
    {
        uint256 length = receivers.length;
        uint256 i = 0;
        while (i < length) {
            // Safe, because `receivers` passed `_assertDripsReceiversValid` in the past
            unchecked {
                totalAmtPerSec += receivers[i++].amtPerSec;
            }
        }
    }

    /// @notice Updates drips balance.
    /// @param lastUpdate The timestamp of the last drips update.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update.
    /// If this is the first update, pass zero.
    /// @param currEndTime Time when drips were supposed to end according to the last drips update.
    /// @param currAmtPerSec The total amount per second of all drips receivers
    /// according to the last drips update.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @return newBalance The new drips balance.
    /// Pass it as `lastBalance` when updating for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    /// If positive, this is the amount which should be transferred from the user to the drips hub,
    /// or if negative, from the drips hub to the user.
    function _updateDripsBalance(
        uint64 lastUpdate,
        uint128 lastBalance,
        uint64 currEndTime,
        uint128 currAmtPerSec,
        int128 balanceDelta
    ) internal view returns (uint128 newBalance, int128 realBalanceDelta) {
        if (currEndTime > _currTimestamp()) currEndTime = _currTimestamp();
        uint128 dripped = (currEndTime - lastUpdate) * currAmtPerSec;
        int128 currBalance = int128(lastBalance - dripped);
        int136 balance = currBalance + int136(balanceDelta);
        if (balance < 0) balance = 0;
        return (uint128(uint136(balance)), int128(balance - currBalance));
    }

    /// @notice Emit an event when drips are updated.
    /// @param userOrAccount The user or their account
    /// @param balance The new drips balance.
    /// @param receivers The new list of the drips receivers.
    function _emitDripsUpdated(
        UserOrAccount memory userOrAccount,
        uint128 balance,
        DripsReceiver[] memory receivers
    ) internal {
        if (userOrAccount.isAccount) {
            emit DripsUpdated(userOrAccount.user, userOrAccount.account, balance, receivers);
        } else {
            emit DripsUpdated(userOrAccount.user, balance, receivers);
        }
    }

    /// @notice Updates the user's or the account's drips receivers' states.
    /// It applies the effects of the change of the drips configuration.
    /// @param userOrAccount The user or their account
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    /// @param currEndTime Time when drips were supposed to end according to the last drips update.
    /// @param newReceivers  The list of the drips receivers of the user or the account to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @param newEndTime Time when drips will end according to the new drips configuration.
    function _updateDripsReceiversStates(
        UserOrAccount memory userOrAccount,
        DripsReceiver[] memory currReceivers,
        uint64 currEndTime,
        DripsReceiver[] memory newReceivers,
        uint64 newEndTime
    ) internal {
        // Skip iterating over `currReceivers` if dripping has run out
        uint256 currIdx = currEndTime > _currTimestamp() ? 0 : currReceivers.length;
        // Skip iterating over `newReceivers` if no new dripping is started
        uint256 newIdx = newEndTime > _currTimestamp() ? 0 : newReceivers.length;
        while (true) {
            // Each iteration gets the next drips update and applies it on the receiver state.
            // A drips update is composed of two drips receiver configurations,
            // one current and one new, or from a single drips receiver configuration
            // if the drips receiver is being added or removed.
            bool pickCurr = currIdx < currReceivers.length;
            bool pickNew = newIdx < newReceivers.length;
            if (!pickCurr && !pickNew) break;
            if (pickCurr && pickNew) {
                // There are two candidate drips receiver configurations to create a drips update.
                // Pick both if they describe the same receiver or the one with a lower address.
                // The one with a higher address won't be used in this iteration.
                // Because drips receivers lists are sorted by addresses and deduplicated,
                // all matching pairs of drips receiver configurations will be found.
                address currReceiver = currReceivers[currIdx].receiver;
                address newReceiver = newReceivers[newIdx].receiver;
                pickCurr = currReceiver <= newReceiver;
                pickNew = newReceiver <= currReceiver;
            }
            // The drips update parameters
            address receiver;
            int128 currAmtPerSec = 0;
            int128 newAmtPerSec = 0;
            if (pickCurr) {
                receiver = currReceivers[currIdx].receiver;
                currAmtPerSec = int128(currReceivers[currIdx].amtPerSec);
                // Clear the obsolete drips end
                _setDelta(receiver, currEndTime, currAmtPerSec);
                currIdx++;
            }
            if (pickNew) {
                receiver = newReceivers[newIdx].receiver;
                newAmtPerSec = int128(newReceivers[newIdx].amtPerSec);
                // Apply the new drips end
                _setDelta(receiver, newEndTime, -newAmtPerSec);
                newIdx++;
            }
            // Apply the drips update since now
            _setDelta(receiver, _currTimestamp(), newAmtPerSec - currAmtPerSec);
            _emitDripping(userOrAccount, receiver, uint128(newAmtPerSec), newEndTime);
            // The receiver has never been used, initialize it
            if (!pickCurr && receiverStates[receiver].nextCollectedCycle == 0) {
                receiverStates[receiver].nextCollectedCycle = _currTimestamp() / cycleSecs + 1;
            }
        }
    }

    /// @notice Emit an event when drips from a user to a receiver are updated.
    /// @param userOrAccount The user or their account
    /// @param receiver The receiver
    /// @param amtPerSec The new amount per second dripped from the user or the account
    /// to the receiver or 0 if the drips are stopped
    /// @param endTime The timestamp when dripping will stop
    function _emitDripping(
        UserOrAccount memory userOrAccount,
        address receiver,
        uint128 amtPerSec,
        uint64 endTime
    ) internal {
        if (amtPerSec == 0) endTime = _currTimestamp();
        if (userOrAccount.isAccount) {
            emit Dripping(userOrAccount.user, userOrAccount.account, receiver, amtPerSec, endTime);
        } else {
            emit Dripping(userOrAccount.user, receiver, amtPerSec, endTime);
        }
    }

    /// @notice Calculates the timestamp when dripping will end.
    /// @param startTime Time when dripping is started.
    /// @param startBalance The drips balance when dripping is started.
    /// @param totalAmtPerSec The total amount per second of all the drips receivers
    /// @return dripsEndTime The dripping end time.
    function _dripsEndTime(
        uint64 startTime,
        uint128 startBalance,
        uint128 totalAmtPerSec
    ) internal pure returns (uint64 dripsEndTime) {
        if (totalAmtPerSec == 0) return startTime;
        uint256 endTime = startTime + uint256(startBalance / totalAmtPerSec);
        return endTime > MAX_TIMESTAMP ? MAX_TIMESTAMP : uint64(endTime);
    }

    /// @notice Asserts that the drips configuration is the currently used one.
    /// @param userOrAccount The user or their account
    /// @param lastUpdate The timestamp of the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the user or the account.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the user or the account.
    /// If this is the first update, pass an empty array.
    function _assertCurrDrips(
        UserOrAccount memory userOrAccount,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers
    ) internal view {
        bytes32 expectedHash;
        if (userOrAccount.isAccount) {
            expectedHash = accountDripsHashes[userOrAccount.user][userOrAccount.account];
        } else {
            expectedHash = userDripsHashes[userOrAccount.user];
        }
        bytes32 actualHash = hashDrips(lastUpdate, lastBalance, currReceivers);
        require(actualHash == expectedHash, "Invalid current drips configuration");
    }

    /// @notice Stores the hash of the current drips configuration to be used in `_assertCurrDrips`.
    /// @param userOrAccount The user or their account
    /// @param newBalance The user or the account drips balance.
    /// @param newReceivers The list of the drips receivers of the user or the account.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    function _storeCurrDrips(
        UserOrAccount memory userOrAccount,
        uint128 newBalance,
        DripsReceiver[] memory newReceivers
    ) internal {
        bytes32 currDripsHash = hashDrips(_currTimestamp(), newBalance, newReceivers);
        if (userOrAccount.isAccount) {
            accountDripsHashes[userOrAccount.user][userOrAccount.account] = currDripsHash;
        } else {
            userDripsHashes[userOrAccount.user] = currDripsHash;
        }
    }

    /// @notice Calculates the hash of the drips configuration.
    /// It's used to verify if drips configuration is the previously set one.
    /// @param update The timestamp of the drips update.
    /// If the drips have never been updated, pass zero.
    /// @param balance The drips balance.
    /// If the drips have never been updated, pass zero.
    /// @param receivers The list of the drips receivers.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// If the drips have never been updated, pass an empty array.
    /// @return dripsConfigurationHash The hash of the drips configuration
    function hashDrips(
        uint64 update,
        uint128 balance,
        DripsReceiver[] memory receivers
    ) public pure returns (bytes32 dripsConfigurationHash) {
        if (update == 0 && balance == 0 && receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers, update, balance));
    }

    /// @notice Collects funds received by the user and sets their splits.
    /// The collected funds are split according to `currReceivers`.
    /// @param user The user
    /// @param currReceivers The list of the user's splits receivers which is currently in use.
    /// If this function is called for the first time for the user, should be an empty array.
    /// @param newReceivers The new list of the user's splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function _setSplits(
        address user,
        SplitsReceiver[] memory currReceivers,
        SplitsReceiver[] memory newReceivers
    ) internal returns (uint128 collected, uint128 split) {
        (collected, split) = _collectInternal(user, currReceivers);
        _assertSplitsValid(newReceivers);
        splitsHash[user] = hashSplits(newReceivers);
        emit SplitsUpdated(user, newReceivers);
        _transfer(user, int128(collected));
    }

    /// @notice Validates a list of splits receivers
    /// @param receivers The list of splits receivers
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    function _assertSplitsValid(SplitsReceiver[] memory receivers) internal pure {
        require(receivers.length <= MAX_SPLITS_RECEIVERS, "Too many splits receivers");
        uint64 totalWeight = 0;
        address prevReceiver;
        for (uint256 i = 0; i < receivers.length; i++) {
            uint32 weight = receivers[i].weight;
            require(weight != 0, "Splits receiver weight is zero");
            totalWeight += weight;
            address receiver = receivers[i].receiver;
            if (i > 0) {
                require(prevReceiver != receiver, "Duplicate splits receivers");
                require(prevReceiver < receiver, "Splits receivers not sorted by address");
            }
            prevReceiver = receiver;
        }
        require(totalWeight <= TOTAL_SPLITS_WEIGHT, "Splits weights sum too high");
    }

    /// @notice Asserts that the list of splits receivers is the user's currently used one.
    /// @param user The user
    /// @param currReceivers The list of the user's current splits receivers.
    function _assertCurrSplits(address user, SplitsReceiver[] memory currReceivers) internal view {
        require(hashSplits(currReceivers) == splitsHash[user], "Invalid current splits receivers");
    }

    /// @notice Calculates the hash of the list of splits receivers.
    /// @param receivers The list of the splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// @return receiversHash The hash of the list of splits receivers.
    function hashSplits(SplitsReceiver[] memory receivers)
        public
        pure
        returns (bytes32 receiversHash)
    {
        if (receivers.length == 0) return bytes32(0);
        return keccak256(abi.encode(receivers));
    }

    /// @notice Called when funds need to be transferred between the user and the drips hub.
    /// The function must be called no more than once per transaction.
    /// @param user The user
    /// @param amt The transferred amount.
    /// Positive to transfer funds to the user, negative to transfer from them.
    function _transfer(address user, int128 amt) internal virtual;

    /// @notice Sets amt delta of a user on a given timestamp
    /// @param user The user
    /// @param timestamp The timestamp from which the delta takes effect
    /// @param amtPerSecDelta Change of the per-second receiving rate
    function _setDelta(
        address user,
        uint64 timestamp,
        int128 amtPerSecDelta
    ) internal {
        if (amtPerSecDelta == 0) return;
        mapping(uint64 => AmtDelta) storage amtDeltas = receiverStates[user].amtDeltas;
        // In order to set a delta on a specific timestamp it must be introduced in two cycles.
        // The cycle delta is split proportionally based on how much this cycle is affected.
        // The next cycle has the rest of the delta applied, so the update is fully completed.
        uint64 thisCycle = timestamp / cycleSecs + 1;
        uint64 nextCycleSecs = timestamp % cycleSecs;
        uint64 thisCycleSecs = cycleSecs - nextCycleSecs;
        amtDeltas[thisCycle].thisCycle += int128(uint128(thisCycleSecs)) * amtPerSecDelta;
        amtDeltas[thisCycle].nextCycle += int128(uint128(nextCycleSecs)) * amtPerSecDelta;
    }

    function _userOrAccount(address user) internal pure returns (UserOrAccount memory) {
        return UserOrAccount({isAccount: false, user: user, account: 0});
    }

    function _userOrAccount(address user, uint256 account)
        internal
        pure
        returns (UserOrAccount memory)
    {
        return UserOrAccount({isAccount: true, user: user, account: account});
    }

    function _currTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}

////// lib/radicle-drips-hub/src/ERC20DripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {SplitsReceiver, DripsHub, DripsReceiver} from "./DripsHub.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

/// @notice Drips hub contract for any ERC-20 token.
/// See the base `DripsHub` contract docs for more details.
contract ERC20DripsHub is DripsHub {
    /// @notice The address of the ERC-20 contract which tokens the drips hub works with
    IERC20 public immutable erc20;

    /// @param cycleSecs The length of cycleSecs to be used in the contract instance.
    /// Low value makes funds more available by shortening the average time of funds being frozen
    /// between being taken from the users' drips balances and being collectable by their receivers.
    /// High value makes collecting cheaper by making it process less cycles for a given time range.
    /// @param owner The initial owner of the contract with managerial abilities.
    /// @param _erc20 The address of an ERC-20 contract which tokens the drips hub will work with.
    /// The supply of the tokens must be lower than `2 ^ 127`.
    constructor(
        uint64 cycleSecs,
        address owner,
        IERC20 _erc20
    ) DripsHub(cycleSecs, owner) {
        erc20 = _erc20;
    }

    /// @notice Sets the drips configuration of the `msg.sender`.
    /// Transfers funds to or from the sender to fulfill the update of the drips balance.
    /// The sender must first grant the contract a sufficient allowance.
    /// @param lastUpdate The timestamp of the last drips update of the `msg.sender`.
    /// If this is the first update, pass zero.
    /// @param lastBalance The drips balance after the last drips update of the `msg.sender`.
    /// If this is the first update, pass zero.
    /// @param currReceivers The list of the drips receivers set in the last drips update
    /// of the `msg.sender`.
    /// If this is the first update, pass an empty array.
    /// @param balanceDelta The drips balance change to be applied.
    /// Positive to add funds to the drips balance, negative to remove them.
    /// @param newReceivers The list of the drips receivers of the `msg.sender` to be set.
    /// Must be sorted by the receivers' addresses, deduplicated and without 0 amtPerSecs.
    /// @return newBalance The new drips balance of the `msg.sender`.
    /// Pass it as `lastBalance` when updating that user or the account for the next time.
    /// @return realBalanceDelta The actually applied drips balance change.
    function setDrips(
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        return
            _setDrips(
                _userOrAccount(msg.sender),
                lastUpdate,
                lastBalance,
                currReceivers,
                balanceDelta,
                newReceivers
            );
    }

    /// @notice Sets the drips configuration of an account of the `msg.sender`.
    /// See `setDrips` for more details
    /// @param account The account
    function setDrips(
        uint256 account,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        return
            _setDrips(
                _userOrAccount(msg.sender, account),
                lastUpdate,
                lastBalance,
                currReceivers,
                balanceDelta,
                newReceivers
            );
    }

    /// @notice Gives funds from the `msg.sender` to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the sender's wallet to the drips hub contract.
    /// @param receiver The receiver
    /// @param amt The given amount
    function give(address receiver, uint128 amt) public whenNotPaused {
        _give(_userOrAccount(msg.sender), receiver, amt);
    }

    /// @notice Gives funds from the account of the `msg.sender` to the receiver.
    /// The receiver can collect them immediately.
    /// Transfers the funds to be given from the sender's wallet to the drips hub contract.
    /// @param account The account
    /// @param receiver The receiver
    /// @param amt The given amount
    function give(
        uint256 account,
        address receiver,
        uint128 amt
    ) public whenNotPaused {
        _give(_userOrAccount(msg.sender, account), receiver, amt);
    }

    /// @notice Collects funds received by the `msg.sender` and sets their splits.
    /// The collected funds are split according to `currReceivers`.
    /// @param currReceivers The list of the user's splits receivers which is currently in use.
    /// If this function is called for the first time for the user, should be an empty array.
    /// @param newReceivers The new list of the user's splits receivers.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / TOTAL_SPLITS_WEIGHT`
    /// share of the funds collected by the user.
    /// @return collected The collected amount
    /// @return split The amount split to the user's splits receivers
    function setSplits(SplitsReceiver[] memory currReceivers, SplitsReceiver[] memory newReceivers)
        public
        whenNotPaused
        returns (uint128 collected, uint128 split)
    {
        return _setSplits(msg.sender, currReceivers, newReceivers);
    }

    function _transfer(address user, int128 amt) internal override {
        if (amt > 0) erc20.transfer(user, uint128(amt));
        else if (amt < 0) erc20.transferFrom(user, address(this), uint128(-amt));
    }
}

////// lib/radicle-drips-hub/src/DaiDripsHub.sol
/* pragma solidity ^0.8.7; */

/* import {ERC20DripsHub, DripsReceiver, SplitsReceiver} from "./ERC20DripsHub.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */

interface IDai is IERC20 {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

struct PermitArgs {
    uint256 nonce;
    uint256 expiry;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @notice Drips hub contract for DAI token.
/// See the base `DripsHub` contract docs for more details.
contract DaiDripsHub is ERC20DripsHub {
    /// @notice The address of the Dai contract which tokens the drips hub works with.
    /// Always equal to `erc20`, but more strictly typed.
    IDai public immutable dai;

    /// @notice See `ERC20DripsHub` constructor documentation for more details.
    constructor(
        uint64 cycleSecs,
        address owner,
        IDai _dai
    ) ERC20DripsHub(cycleSecs, owner, _dai) {
        dai = _dai;
    }

    /// @notice Sets the drips configuration of the `msg.sender`
    /// and permits spending their Dai by the drips hub.
    /// This function is an extension of `setDrips`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function setDripsAndPermit(
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        PermitArgs calldata permitArgs
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        _permit(permitArgs);
        return setDrips(lastUpdate, lastBalance, currReceivers, balanceDelta, newReceivers);
    }

    /// @notice Sets the drips configuration of an account of the `msg.sender`
    /// and permits spending their Dai by the drips hub.
    /// This function is an extension of `setDrips`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function setDripsAndPermit(
        uint256 account,
        uint64 lastUpdate,
        uint128 lastBalance,
        DripsReceiver[] memory currReceivers,
        int128 balanceDelta,
        DripsReceiver[] memory newReceivers,
        PermitArgs calldata permitArgs
    ) public whenNotPaused returns (uint128 newBalance, int128 realBalanceDelta) {
        _permit(permitArgs);
        return
            setDrips(account, lastUpdate, lastBalance, currReceivers, balanceDelta, newReceivers);
    }

    /// @notice Gives funds from the `msg.sender` to the receiver
    /// and permits spending sender's Dai by the drips hub.
    /// This function is an extension of `give`, see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function giveAndPermit(
        address receiver,
        uint128 amt,
        PermitArgs calldata permitArgs
    ) public whenNotPaused {
        _permit(permitArgs);
        give(receiver, amt);
    }

    /// @notice Gives funds from the account of the `msg.sender` to the receiver
    /// and permits spending sender's Dai by the drips hub.
    /// This function is an extension of `give` see its documentation for more details.
    ///
    /// The user must sign a Dai permission document allowing the drips hub to spend their funds.
    /// These parameters will be passed to the Dai contract by this function.
    /// @param permitArgs The Dai permission arguments.
    function giveAndPermit(
        uint256 account,
        address receiver,
        uint128 amt,
        PermitArgs calldata permitArgs
    ) public whenNotPaused {
        _permit(permitArgs);
        give(account, receiver, amt);
    }

    /// @notice Permits the drips hub to spend the message sender's Dai.
    /// @param permitArgs The Dai permission arguments.
    function _permit(PermitArgs calldata permitArgs) internal {
        dai.permit(
            msg.sender,
            address(this),
            permitArgs.nonce,
            permitArgs.expiry,
            true,
            permitArgs.v,
            permitArgs.r,
            permitArgs.s
        );
    }
}

////// src/builder/interface.sol
/* pragma solidity ^0.8.7; */

interface IBuilder {
    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerCycle,
        bool active
    ) external view returns (string memory);

    function buildMetaData(
        string memory projectName,
        uint128 tokenId,
        uint128 nftType,
        bool streaming,
        uint128 amtPerCycle,
        bool active,
        string memory ipfsHash
    ) external view returns (string memory);
}

////// src/token.sol
/* pragma solidity ^0.8.7; */

/* import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol"; */
/* import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol"; */
/* import "openzeppelin-contracts/access/Ownable.sol"; */
/* import {DaiDripsHub, DripsReceiver, IDai, SplitsReceiver} from "drips-hub/DaiDripsHub.sol"; */
/* import {IBuilder} from "./builder/interface.sol"; */

struct InputType {
    uint128 nftTypeId;
    uint64 limit;
    // minimum amtPerSecond or minGiveAmt
    uint128 minAmt;
    bool streaming;
    string ipfsHash;
}

contract DripsToken is ERC721, Ownable {
    address public immutable deployer;
    DaiDripsHub public immutable hub;
    IDai public immutable dai;
    uint64 public immutable cycleSecs;
    IBuilder public builder;

    string internal _name;
    string internal _symbol;
    string public contractURI;
    bool public initialized;

    struct Type {
        uint64 limit;
        uint64 minted;
        uint128 minAmt;
        bool streaming;
        string ipfsHash;
    }

    struct Token {
        uint64 timeMinted;
        // amtPerSec if the Token is streaming otherwise the amt given at mint
        uint128 amt;
        uint128 lastBalance;
        uint64 lastUpdate;
    }

    mapping(uint128 => Type) public nftTypes;
    mapping(uint256 => Token) public nfts;

    // events
    event NewType(uint128 indexed nftType, uint64 limit, uint128 minAmt, bool streaming);
    event NewStreamingToken(
        uint256 indexed tokenId,
        address indexed receiver,
        uint128 indexed typeId,
        uint128 topUp,
        uint128 amtPerSec
    );
    event NewToken(
        uint256 indexed tokenId,
        address indexed receiver,
        uint128 indexed typeId,
        uint128 giveAmt
    );

    event NewContractURI(string contractURI);
    event NewBuilder(IBuilder builder);
    event SplitsUpdated(SplitsReceiver[] splits);

    constructor(DaiDripsHub hub_) ERC721("", "") {
        deployer = msg.sender;
        hub = hub_;
        dai = hub_.dai();
        cycleSecs = hub_.cycleSecs();
    }

    modifier onlyTokenHolder(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "not-nft-owner");
        _;
    }

    function init(
        string calldata name_,
        string calldata symbol_,
        address owner,
        string calldata contractURI_,
        InputType[] memory inputTypes,
        IBuilder builder_,
        SplitsReceiver[] memory splits
    ) public {
        require(!initialized, "already-initialized");
        initialized = true;
        require(msg.sender == deployer, "not-deployer");
        require(owner != address(0), "owner-address-is-zero");
        _name = name_;
        _symbol = symbol_;
        _changeBuilder(builder_);
        _addTypes(inputTypes);
        _changeContractURI(contractURI_);
        _transferOwnership(owner);
        if (splits.length > 0) {
            _changeSplitsReceivers(new SplitsReceiver[](0), splits);
        }
        dai.approve(address(hub), type(uint256).max);
    }

    function changeContractURI(string calldata contractURI_) public onlyOwner {
        _changeContractURI(contractURI_);
    }

    function _changeContractURI(string calldata contractURI_) internal {
        contractURI = contractURI_;
        emit NewContractURI(contractURI_);
    }

    function _changeBuilder(IBuilder newBuilder) internal {
        builder = newBuilder;
        emit NewBuilder(newBuilder);
    }

    function addTypes(InputType[] memory inputTypes) public onlyOwner {
        _addTypes(inputTypes);
    }

    function _addTypes(InputType[] memory inputTypes) internal {
        for (uint256 i = 0; i < inputTypes.length; i++) {
            _addType(
                inputTypes[i].nftTypeId,
                inputTypes[i].limit,
                inputTypes[i].minAmt,
                inputTypes[i].ipfsHash,
                inputTypes[i].streaming
            );
        }
    }

    function addStreamingType(
        uint128 newTypeId,
        uint64 limit,
        uint128 minAmtPerSec,
        string memory ipfsHash
    ) public onlyOwner {
        _addType(newTypeId, limit, minAmtPerSec, ipfsHash, true);
    }

    function addType(
        uint128 newTypeId,
        uint64 limit,
        uint128 minGiveAmt,
        string memory ipfsHash
    ) public onlyOwner {
        _addType(newTypeId, limit, minGiveAmt, ipfsHash, false);
    }

    function _addType(
        uint128 newTypeId,
        uint64 limit,
        uint128 minAmt,
        string memory ipfsHash,
        bool streaming_
    ) internal {
        require(nftTypes[newTypeId].limit == 0, "nft-type-already-exists");
        require(limit > 0, "zero-limit-not-allowed");

        nftTypes[newTypeId].minAmt = minAmt;
        nftTypes[newTypeId].limit = limit;
        nftTypes[newTypeId].ipfsHash = ipfsHash;
        nftTypes[newTypeId].streaming = streaming_;
        emit NewType(newTypeId, limit, minAmt, streaming_);
    }

    function createTokenId(uint128 id, uint128 nftType) public pure returns (uint256 tokenId) {
        return uint256((uint256(nftType) << 128)) | id;
    }

    function tokenType(uint256 tokenId) public pure returns (uint128 nftType) {
        return uint128(tokenId >> 128);
    }

    function mintStreaming(
        address nftReceiver,
        uint128 typeId,
        uint128 topUpAmt,
        uint128 amtPerSec,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        return mintStreaming(nftReceiver, typeId, topUpAmt, amtPerSec);
    }

    function mint(
        address nftReceiver,
        uint128 typeId,
        uint128 amtGive,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        return mint(nftReceiver, typeId, amtGive);
    }

    function mint(
        address nftReceiver,
        uint128 typeId,
        uint128 giveAmt
    ) public returns (uint256 newTokenId) {
        require(giveAmt > nftTypes[typeId].minAmt, "giveAmt-too-low");
        require(nftTypes[typeId].streaming == false, "type-is-streaming");
        newTokenId = _mintInternal(nftReceiver, typeId, giveAmt);
        // one time give instead of streaming
        hub.give(newTokenId, address(this), giveAmt);
        nfts[newTokenId].amt = giveAmt;
        emit NewToken(newTokenId, nftReceiver, typeId, giveAmt);
    }

    function _mintInternal(
        address nftReceiver,
        uint128 typeId,
        uint128 topUpAmt
    ) internal returns (uint256 newTokenId) {
        require(nftTypes[typeId].minted++ < nftTypes[typeId].limit, "nft-type-reached-limit");
        newTokenId = createTokenId(nftTypes[typeId].minted, typeId);
        _mint(nftReceiver, newTokenId);
        nfts[newTokenId].timeMinted = uint64(block.timestamp);
        // transfer currency to Token registry
        dai.transferFrom(nftReceiver, address(this), topUpAmt);
    }

    function mintStreaming(
        address nftReceiver,
        uint128 typeId,
        uint128 topUpAmt,
        uint128 amtPerSec
    ) public returns (uint256 newTokenId) {
        require(amtPerSec >= nftTypes[typeId].minAmt, "amt-per-sec-too-low");
        require(nftTypes[typeId].streaming, "nft-type-not-streaming");
        require(topUpAmt >= amtPerSec * cycleSecs, "toUp-too-low");

        newTokenId = _mintInternal(nftReceiver, typeId, topUpAmt);
        // start streaming
        hub.setDrips(newTokenId, 0, 0, _receivers(0), int128(topUpAmt), _receivers(amtPerSec));
        nfts[newTokenId].amt = amtPerSec;
        nfts[newTokenId].lastUpdate = uint64(block.timestamp);
        nfts[newTokenId].lastBalance = topUpAmt;
        emit NewStreamingToken(newTokenId, nftReceiver, typeId, topUpAmt, amtPerSec);
    }

    function collect(SplitsReceiver[] calldata currSplits)
        public
        onlyOwner
        returns (uint128 collected, uint128 split)
    {
        (, split) = hub.collect(address(this), currSplits);
        collected = uint128(dai.balanceOf(address(this)));
        dai.transfer(owner(), collected);
    }

    function collectable(SplitsReceiver[] calldata currSplits)
        public
        view
        returns (uint128 toCollect, uint128 toSplit)
    {
        (toCollect, toSplit) = hub.collectable(address(this), currSplits);
        toCollect += uint128(dai.balanceOf(address(this)));
    }

    function topUp(
        uint256 tokenId,
        uint128 topUpAmt,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        dai.permit(msg.sender, address(this), nonce, expiry, true, v, r, s);
        topUp(tokenId, topUpAmt);
    }

    function topUp(uint256 tokenId, uint128 topUpAmt) public onlyTokenHolder(tokenId) {
        require(nftTypes[tokenType(tokenId)].streaming, "not-a-streaming-nft");
        dai.transferFrom(msg.sender, address(this), topUpAmt);
        DripsReceiver[] memory receivers = _tokenReceivers(tokenId);
        (uint128 newBalance, ) = hub.setDrips(
            tokenId,
            nfts[tokenId].lastUpdate,
            nfts[tokenId].lastBalance,
            receivers,
            int128(topUpAmt),
            receivers
        );
        nfts[tokenId].lastUpdate = uint64(block.timestamp);
        nfts[tokenId].lastBalance = newBalance;
    }

    function withdraw(uint256 tokenId, uint128 withdrawAmt)
        public
        onlyTokenHolder(tokenId)
        returns (uint128 withdrawn)
    {
        uint128 withdrawableAmt = withdrawable(tokenId);
        if (withdrawAmt > withdrawableAmt) {
            withdrawAmt = withdrawableAmt;
        }
        DripsReceiver[] memory receivers = _tokenReceivers(tokenId);
        (uint128 newBalance, int128 realBalanceDelta) = hub.setDrips(
            tokenId,
            nfts[tokenId].lastUpdate,
            nfts[tokenId].lastBalance,
            receivers,
            -int128(withdrawAmt),
            receivers
        );
        nfts[tokenId].lastUpdate = uint64(block.timestamp);
        nfts[tokenId].lastBalance = newBalance;
        withdrawn = uint128(-realBalanceDelta);
        dai.transfer(msg.sender, withdrawn);
    }

    function changeSplitsReceivers(
        SplitsReceiver[] memory currSplits,
        SplitsReceiver[] memory newSplits
    ) public onlyOwner {
        _changeSplitsReceivers(currSplits, newSplits);
    }

    function _changeSplitsReceivers(
        SplitsReceiver[] memory currSplits,
        SplitsReceiver[] memory newSplits
    ) internal {
        hub.setSplits(currSplits, newSplits);
        emit SplitsUpdated(newSplits);
    }

    function withdrawable(uint256 tokenId) public view returns (uint128) {
        require(_exists(tokenId), "nonexistent-token");
        if (nftTypes[tokenType(tokenId)].streaming == false) return 0;
        Token storage nft = nfts[tokenId];
        uint64 spentUntil = uint64(block.timestamp);
        uint64 minSpentUntil = nft.timeMinted + cycleSecs;
        if (spentUntil < minSpentUntil) spentUntil = minSpentUntil;
        uint192 spent = (spentUntil - nft.lastUpdate) * uint192(nft.amt);
        if (nft.lastBalance < spent) return nft.lastBalance % nft.amt;
        return nft.lastBalance - uint128(spent);
    }

    function activeUntil(uint256 tokenId) public view returns (uint128) {
        require(_exists(tokenId), "nonexistent-token");
        Type storage nftType = nftTypes[tokenType(tokenId)];
        if (nftType.streaming == false || nftType.minAmt == 0) {
            return type(uint128).max;
        }
        Token storage nft = nfts[tokenId];
        return nft.lastUpdate + nft.lastBalance / nft.amt - 1;
    }

    function active(uint256 tokenId) public view returns (bool) {
        return activeUntil(tokenId) >= block.timestamp;
    }

    function streaming(uint256 tokenId) public view returns (bool) {
        return nftTypes[tokenType(tokenId)].streaming;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function changeBuilder(IBuilder newBuilder) public onlyOwner {
        _changeBuilder(newBuilder);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "nonexistent-token");
        string memory ipfsHash = nftTypes[tokenType(tokenId)].ipfsHash;
        uint128 amtPerCycle = nfts[tokenId].amt * cycleSecs;
        if (bytes(ipfsHash).length == 0) {
            return
                builder.buildMetaData(
                    name(),
                    uint128(tokenId),
                    tokenType(tokenId),
                    nftTypes[tokenType(tokenId)].streaming,
                    amtPerCycle,
                    active(tokenId)
                );
        }
        return
            builder.buildMetaData(
                name(),
                uint128(tokenId),
                tokenType(tokenId),
                nftTypes[tokenType(tokenId)].streaming,
                amtPerCycle,
                active(tokenId),
                ipfsHash
            );
    }

    function currLeftSecsInCycle() public view returns (uint64) {
        return cycleSecs - (uint64(block.timestamp) % cycleSecs);
    }

    function influence(uint256 tokenId) public view returns (uint256 influenceScore) {
        if (active(tokenId)) {
            if (streaming(tokenId) == false) {
                return nfts[tokenId].amt;
            }
            return nfts[tokenId].amt * (block.timestamp - nfts[tokenId].timeMinted);
        }
        return 0;
    }

    function _tokenReceivers(uint256 tokenId)
        internal
        view
        returns (DripsReceiver[] memory receivers)
    {
        return _receivers(nfts[tokenId].amt);
    }

    function _receivers(uint128 amtPerSec)
        internal
        view
        returns (DripsReceiver[] memory receivers)
    {
        if (amtPerSec == 0) return new DripsReceiver[](0);
        receivers = new DripsReceiver[](1);
        receivers[0] = DripsReceiver(address(this), amtPerSec);
    }
}

////// src/registry.sol
/* pragma solidity ^0.8.7; */

/* import {DripsToken, InputType, SplitsReceiver} from "./token.sol"; */
/* import {DaiDripsHub} from "drips-hub/DaiDripsHub.sol"; */
/* import {Clones} from "openzeppelin-contracts/proxy/Clones.sol"; */
/* import {IBuilder} from "./builder/interface.sol"; */
/* import {Ownable} from "openzeppelin-contracts/access/Ownable.sol"; */

contract RadicleRegistry is Ownable {
    address public governance;
    IBuilder public builder;

    event NewProject(DripsToken indexed fundingToken, address indexed projectOwner, string name);
    event NewBuilder(IBuilder builder);

    DripsToken public immutable dripTokenTemplate;
    uint256 public nextId;

    constructor(
        DaiDripsHub hub_,
        IBuilder builder_,
        address owner_
    ) {
        _transferOwnership(owner_);
        changeBuilder(builder_);
        dripTokenTemplate = new DripsToken(hub_);
    }

    function newProject(
        string calldata name,
        string calldata symbol,
        address projectOwner,
        string calldata contractURI,
        InputType[] calldata inputTypes,
        SplitsReceiver[] memory splits
    ) public returns (DripsToken) {
        bytes32 salt = bytes32(nextId++);
        DripsToken fundingToken = DripsToken(
            Clones.cloneDeterministic(address(dripTokenTemplate), salt)
        );
        fundingToken.init(name, symbol, projectOwner, contractURI, inputTypes, builder, splits);
        emit NewProject(fundingToken, projectOwner, name);
        return fundingToken;
    }

    function projectAddr(uint256 id) public view returns (DripsToken) {
        if (id >= nextId) {
            return DripsToken(address(0x0));
        }
        return
            DripsToken(Clones.predictDeterministicAddress(address(dripTokenTemplate), bytes32(id)));
    }

    function changeBuilder(IBuilder newBuilder) public onlyOwner {
        builder = newBuilder;
        emit NewBuilder(newBuilder);
    }
}