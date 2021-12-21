/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

// File: contracts/interfaces/OracleInterface.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/RPS.sol


pragma solidity ^0.8.0;







contract RPS is Ownable, Initializable {
    using SafeMath for uint256;
    // action 0 = rock, 1 = paper, 2 = scissor

   uint256 constant public DAY_IN_SECONDS = 86400;

    IERC721 public RPSleague;
    IERC20 public RPSToken;
    AggregatorV3Interface public oracle;

    address public vault;
    address public pool;

    enum Rarity {Common, Uncommon, Rare, Legendary, Mythic}
    enum Accessory {None, Ring, Bracelet, Gold_Bracelet, Watch}

    uint256[6] public BetAmount; //PVP mode
    uint256[3] public LockTime; //7 , 15, 30 days
    uint256[3] public LockAmount; //19,38,76
    uint256[5] public RewardAmount; // $1.5, $2, $2.5, $3, $4
    uint256[5] public RewardCollection; //Reward Collected for each land from land tax
    uint256[5] public LandTax; //2,3,4,5,5
    uint256[4] public MergeFee; //$10,$15,$20,$25
    uint256 public acclandtax;
    uint256 public minTax;
    uint256 public dailyPenaltyFee; // in % (default 2%)
    uint256 public penaltyTime; // in days (default 15 days)

    struct Player {
        uint128 balance;
        uint128 withdrawableAmount;
        uint64 claimCount;
        uint56 lastClaimCount;
    }

    struct Team {
        address owner;
        uint96 left_energy;
        uint64 total_energy;
        uint64 play;
        uint56 isAvailable;
        bool isTraining;
        Rarity rarity;
        uint256[3] nftIds;
        address[3] nftAddresses;
    }

    //need to add wearables nft addresses
    struct NFTs {
        uint128 action;
        uint64 wearable1;
        uint64 wearable2;
        bytes32 teamName;
        Rarity rarity;
        address[2] wearableAddresses;
        address[2] attachedBy;
    }

    struct Reward {
        uint128 amount;
        uint128 time;
    }

    struct Wearable {
        Accessory accessory;
        address mergedBy;
        uint96 attachedTo;
    }


    mapping(address => bool) public isWhitelisted; //list of nft contracts
    mapping(address => bool) public isOperator;
    mapping(address => mapping(uint256 => Wearable)) public wearables; //tokenId to Wearable
    mapping(address => mapping(uint256 => Reward)) public withdrawableReward;
    mapping(address => uint256) public teamCount; //user => number of teams
    mapping(address => mapping(uint256 => bytes32)) public teamList; //user => list of all team names
    mapping(address => mapping(uint256 => NFTs)) public nft; //TokenId => NFT
    mapping(address => Player) public players; //msg.sender => Player
    mapping(bytes32 => Team) public teams; //teamID => Team

    event Migrated(address indexed _nft, uint256 _tokenId, uint256 indexed _type);
    event CreatTeam(address[3] _nft, address indexed player, bytes32 team, uint256[3] tokenIDs, uint256 timestamp);
    event SuccessPvP(address[2] _players, bytes32[2] _teams, bool _winner, uint8 _betID, uint256 _landTokenId, uint256 timestamp);
    event SuccessPvE(address indexed player, bytes32 indexed team, bool win, uint256 landTokenId, uint256 timestamp);
    event LandReward(uint256 indexed landRarity, uint256 amount, uint256 timestamp);
    event PlayerReward(address indexed player, uint256 amount, uint256 count,uint256 timestamp);
    event ClaimReward(address indexed player, uint256 amount, uint256 fee, uint256 timestamp);
    event TrainTeam(address indexed player, bytes32 indexed team, uint256 trainTime, uint256 amount, uint256 timestamp);
    event NFTMerged(address indexed _mergedBy, address[3] _nft, uint256 _hand, uint256 _wearable1, uint256 _wearable2, uint256 timestamp);

    modifier checkWhitelist(address[3] memory _nft) {
        for (uint256 i; i < 3; i++) {
            require(isWhitelisted[_nft[i]], "Unregistered");
        }
        _;
    }

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Not operator");
        _;
    }


    function initialize(address _owner, IERC721 _rpsLeague, IERC20 _rpsToken, AggregatorV3Interface _oracle, address _vault, address _pool) public initializer {
        RPSleague = _rpsLeague;
        RPSToken = _rpsToken;
        oracle = _oracle;
        _transferOwnership(_owner);
        LockTime = [7 * DAY_IN_SECONDS, 15 * DAY_IN_SECONDS, 30 * DAY_IN_SECONDS]; //in seconds
        LockAmount = [19,39,75];
        BetAmount = [5,10,20,30,50];
        LandTax = [2,3,4,5,5];
        RewardAmount = [15,20,25,30,40];
        MergeFee = [10,15,20,25];
        minTax = 10 * (10^18);
        dailyPenaltyFee = 2;
        penaltyTime = 15;
        vault = _vault;
        pool = _pool;
        isWhitelisted[address(_rpsLeague)] = true;
    }

    /**
     * @dev register() - For adding information about each hand nft and land nft.
     * @param _nft set as address of ERC721 contract to which the tokens belong to.
     * @param _tokenIDs set as list of token Ids.
     * @param _energies set as list of energy for each token.
     * @param _actions set as list of action for each token.
     */
    function register(address _nft, uint256[] memory _tokenIDs, uint256[] memory _energies, uint256[] memory _actions) public onlyOwner {
        require(isWhitelisted[_nft], "Unregistered");
        require(_tokenIDs.length == _energies.length,"Mismatch");
        require(_energies.length == _actions.length,"Mismatch");

        for(uint256 i; i < _tokenIDs.length; i++) {
            add_NFT(_nft, _tokenIDs[i], _energies[i], _actions[i]);
        }
    }

    /**
     * @dev registerWearables() - For adding information about each wearable nft.
     * @param _nft set as the address of ERC721 contract to which tokens belong to.
     * @param _tokenIDs set as list of token Ids for each wearable.
     * @param _accessory set as list of accessory type for each wearable token.
     */
    function registerWearables(address _nft, uint256[] memory _tokenIDs, uint256[] memory _accessory) public onlyOwner {
        require(_tokenIDs.length == _accessory.length, "mismatch");


        for(uint i = 0; i < _tokenIDs.length; i++) {
            wearables[_nft][_tokenIDs[i]].accessory = Accessory(_accessory[i]);
            emit Migrated(_nft, _tokenIDs[i], 2);
        }
    }

    /**
     * @dev add_NFT() - For adding information about each nft.
     * @param _nft set as the address of ERC721 contract to which tokens belong to.
     * @param _tokenID set as tokenId of the nft.
     * @param _rarity set as rarity of the nft.
     * @param _action set as the action of the nft
     */
    function add_NFT(address _nft, uint256 _tokenID, uint256 _rarity, uint256 _action) internal {
        NFTs storage temp = nft[_nft][_tokenID];

        temp.rarity = Rarity(_rarity);
        temp.action = uint128(_action);

        emit Migrated(_nft, _tokenID, 1);
    }

    /**
     * @dev create_Team() - For creating a team with three hand nft.
     * @param _nft set as the address of ERC721 contract to which tokens belong to.
     * @param _tokenIDs set as list of tokenId of each hand nft.
     * @param _teamName set as name of the team
     */
    function create_Team(address[3] memory _nft, uint256[3] memory _tokenIDs, bytes32 _teamName) public checkWhitelist(_nft) {        
        require(_teamName != "", "Empty");

        Team storage team = teams[_teamName];

        require(team.owner == address(0), "taken");
        require(nft[_nft[0]][_tokenIDs[0]].action != nft[_nft[1]][_tokenIDs[1]].action, "matched");
        require(nft[_nft[1]][_tokenIDs[1]].action != nft[_nft[2]][_tokenIDs[2]].action, "matched");
        require(nft[_nft[0]][_tokenIDs[0]].action != nft[_nft[2]][_tokenIDs[2]].action, "matched");

        for (uint256 i; i < 3; i++) {
            require(nft[_nft[i]][_tokenIDs[i]].teamName == "", "In team");
            require(IERC721(_nft[i]).ownerOf(_tokenIDs[i]) == msg.sender,"Invalid");
            team.nftIds[i] = _tokenIDs[i];
            team.nftAddresses[i] = _nft[i];
            nft[_nft[i]][_tokenIDs[i]].teamName = _teamName;
        }
        

        team.owner = msg.sender;
        team.rarity = Rarity(getRarity(_nft, _tokenIDs));
        team.total_energy = uint64(8 + (2 * getRarity(_nft, _tokenIDs)) + getWearableEnergy(msg.sender, _nft, _tokenIDs));

        team.isAvailable = uint56(block.timestamp);
        team.play = uint64(block.timestamp - (block.timestamp % DAY_IN_SECONDS));

        teamCount[msg.sender]++;

        teamList[msg.sender][teamCount[msg.sender]] = _teamName;

        emit CreatTeam(_nft, msg.sender, _teamName, _tokenIDs, block.timestamp);
    }

    /**
     * @dev playPVP() - will do the calculation after PvP match.
     * @param _players set as the addresses of players that played PvP.
     * @param _teams set as team names that were used.
     * @param _winner if the first team was winner.
     * @param _betID ID for the bet amount selected in the match.
     * @param _landTokenId tokenId of the land that was selected for the match.
     */
    function playPVP(address[2] memory _players, bytes32[2] memory _teams, bool _winner, uint8 _betID, uint256 _landTokenId) public onlyOperator {
        require(teams[_teams[0]].owner == _players[0], "Invalid");
        require(teams[_teams[1]].owner == _players[1], "Invalid");

        //calculate BetAmount in RPS token
        uint256 bet = getAmountOut(BetAmount[_betID] * (10**18));

        for (uint256 i; i < 2; i++) {
            Team storage team = teams[_teams[i]];
            for (uint256 j; j < 3; j++) {
                require(IERC721(team.nftAddresses[j]).ownerOf(team.nftIds[j]) == _players[i], "Invalid");
            }

            checkTraining(_teams[i]);
            players[_players[i]].balance =  uint128(uint256(players[_players[i]].balance).sub(bet, "Insufficient"));

        }
        
        uint256 totalAmount = 2 * bet;
        //land fee
        uint256 fee = totalAmount.mul(LandTax[uint256(nft[address(RPSleague)][_landTokenId].rarity)]).div(100);
        acclandtax = acclandtax + fee;

        if(acclandtax >= minTax) {
        	RPSToken.transfer(vault, acclandtax);
        	acclandtax = 0;
        }

        totalAmount = totalAmount.sub(fee.add((totalAmount.mul(2)).div(100))); // subtracting land tax and platform commission

        if(_winner) {
            setReward(_players[0], totalAmount);
        } else {
            setReward(_players[1], totalAmount);
        }
        
        emit LandReward(uint256(nft[address(RPSleague)][_landTokenId].rarity), fee, block.timestamp);
        emit SuccessPvP(_players, _teams, _winner, _betID, _landTokenId, block.timestamp);
    }
    
    /**
     * @dev playPVE() - will do the calculation after PvE match.
     * @param _player set as the address of player that played PvE.
     * @param _team set as team name that was used.
     * @param _winner if the team was winner.
     * @param _landTokenId tokenId of the land that was selected for the match.
     */
    function playPVE(address _player, bytes32 _team, bool _winner, uint256 _landTokenId) public onlyOperator {
        Team storage team = teams[_team];

        for (uint i; i < 3; i++) {
            if (IERC721(team.nftAddresses[i]).ownerOf(teams[_team].nftIds[i]) != _player) {
                return;
            }
        }

        if (teams[_team].owner != _player) {
            return;
        }
        

        checkTraining(_team);

        if (uint256(teams[_team].left_energy) == 0) {
            return;
        }

        teams[_team].left_energy = uint96(uint256(teams[_team].left_energy).sub(1,"Insufficient"));

        if(_winner) {            
            uint256 _rarity = uint256(team.rarity);
            uint256 rewardUSD = RewardAmount[_rarity] * 10**17;
        
            uint256 reward = getAmountOut(rewardUSD);
            uint256 fee = reward.mul(LandTax[uint256(nft[address(RPSleague)][_landTokenId].rarity)]).div(100);
            acclandtax = acclandtax + fee;

            if(acclandtax >= minTax) {
        	    RPSToken.transfer(vault, acclandtax);
        	    acclandtax = 0;
            }

            emit LandReward(uint256(nft[address(RPSleague)][_landTokenId].rarity), fee, block.timestamp);

            if (reward > fee) {
                setReward(_player, reward.sub(fee,"High fee"));
            }
        }
        
        emit SuccessPvE( _player, _team, _winner, _landTokenId, block.timestamp);
    }

    /**
     * @dev train() - set the msg.senders' team into training for selected time period.
     * @param teamId set as team name that was used.
     * @param lockTimeID Id of the training time that was selected.
     */
    function train(bytes32 teamId, uint256 lockTimeID) public {
    	require(teams[teamId].owner == msg.sender, "not owner");
        uint256 fee = getAmountOut(LockAmount[lockTimeID] * (10**18));
        players[msg.sender].balance = uint128(uint256(players[msg.sender].balance).sub(fee,"Insufficient"));
        teams[teamId].isAvailable = uint56(block.timestamp + uint256(LockTime[lockTimeID]));
        teams[teamId].isTraining = true;
        teams[teamId].left_energy = teams[teamId].total_energy;
        emit TrainTeam(msg.sender, teamId, uint256(LockTime[lockTimeID]),fee, block.timestamp);
    }

    /**
     * @dev add_Balance() - for adding the balance in the game.
     * @param _amount set as amount added to balance.
     */
    function add_Balance(uint256 _amount) public {
        RPSToken.transferFrom(msg.sender, address(this), _amount);
        players[msg.sender].balance = uint128(uint256(players[msg.sender].balance).add(_amount));
    }

    /**
     * @dev withdrawBalance() - for withdrawing the balance in the game.
     * @param _amount set as amount removed from balance.
     */
    function withdrawBalance(address _player, uint256 _amount) public {
        players[_player].balance = uint128(uint256(players[_player].balance).sub(_amount,"Insufficient"));
        RPSToken.transfer(_player,_amount);
    }

    /**
     * @dev claim() - for claiming the rewards in the game.
     * @param _player set as the address of player whose reward are being claimed.
     */
    function claim(address _player) public {
        Player storage player = players[_player];
        (uint256 claimReward, uint256 fee) = getTotalReward(_player);
        player.lastClaimCount = uint56(player.claimCount);
        player.balance = uint128(uint256(player.balance).add(claimReward.sub(fee)));
        emit ClaimReward(_player, claimReward, fee, block.timestamp);
    }

    /**
     * @dev claimByOperator() - for setting reward by operator.
     * @param _player set as the address of player whose reward is being set.
     * @param _reward set as the amount of the reward.
     */
    function setClaimByOperator(address _player, uint _reward) external onlyOperator {
        require(_reward > 0, "Invalid");
        setReward(_player, _reward);
    }

    /**
     * @dev disbandTeam() - for disintegrate a team owned by msg.sender.
     * @param _teamName set as name of the team that will be disintegrated.
     * @param _teamCount set as count number of the team.
     */
    function disbandTeam(bytes32 _teamName, uint256 _teamCount) public {
        require(teams[_teamName].owner == msg.sender,"not owner");

        Team storage team = teams[_teamName];

        for (uint i; i < 3; i++) {
            nft[team.nftAddresses[i]][team.nftIds[i]].teamName = "";
        }

        delete teams[_teamName];
        delete teamList[msg.sender][_teamCount];
    }

    /**
     * @dev mergeNfts() - for merging wearable with a hand.
     * @param _nft set as addresses of hand and both wearables.
     * @param _hand set as ctokenId of hand.
     * @param _wearable1 set as tokenId of ring(if attached).
     * @param _wearable2 set as tokenId of either bracelet, gold bracelet or watch(if attached).
     */
    function mergeNfts(address[3] memory _nft, uint256 _hand, uint256 _wearable1, uint256 _wearable2) public checkWhitelist(_nft) {      
        require(IERC721(_nft[0]).ownerOf(_hand) == msg.sender, "not owner");

        //cost of merge Nfts
        uint256 cost;

        NFTs storage target = nft[_nft[0]][_hand];

        if(_wearable1 != 0) {
            Wearable storage wear1 = wearables[_nft[1]][_wearable1];

            require(IERC721(_nft[1]).ownerOf(_wearable1) == msg.sender, "not owner");
            require(uint256(wear1.accessory) == 1,"Not ring");
            require(target.attachedBy[0] != msg.sender && wear1.mergedBy != msg.sender,"attached");            

            target.wearable1 = uint64(_wearable1);
            target.wearableAddresses[0] = _nft[1];
            target.attachedBy[0] = msg.sender;
            wear1.attachedTo = uint96(_hand);
            wear1.mergedBy = msg.sender;

            uint256 fee1 = getAmountOut(MergeFee[uint256(wear1.accessory) - 1] * (10**18));
            cost += fee1;
            teams[target.teamName].total_energy += uint64(checkEnergy(uint256(wear1.accessory)));

            if(teams[target.teamName].isTraining == true)
                teams[target.teamName].left_energy += uint96(checkEnergy(uint256(wear1.accessory)));
        }

        if(_wearable2 != 0) {
            Wearable storage wear2 = wearables[_nft[2]][_wearable2];

            require(IERC721(_nft[2]).ownerOf(_wearable2) == msg.sender, "not owner");
            require(uint256(wear2.accessory) != 1,"ring");
            require(target.attachedBy[1] != msg.sender && wear2.mergedBy != msg.sender,"attached");

            target.wearable2 = uint64(_wearable2); 
            target.wearableAddresses[1] = _nft[2];
            target.attachedBy[1] = msg.sender;
            wear2.attachedTo = uint96(_hand);
            wear2.mergedBy = msg.sender;

            uint256 fee2 = getAmountOut(MergeFee[uint256(wear2.accessory) - 1] * (10**18));
            cost += fee2;

            if(uint256(wear2.accessory) == 4) {
                target.rarity = uint256(target.rarity) < 3 ? Rarity(uint256(target.rarity)+1) : Rarity(4);
                teams[target.teamName].rarity = Rarity(getRarity(teams[target.teamName].nftAddresses, teams[target.teamName].nftIds));
            }
            else {
                teams[target.teamName].total_energy += uint64(checkEnergy(uint256(wear2.accessory)));
                if(teams[target.teamName].isTraining == true)
                    teams[target.teamName].left_energy += uint96(checkEnergy(uint256(wear2.accessory)));
        	}
        }

        require(players[msg.sender].balance >= cost, "balance");
        players[address(msg.sender)].balance -= uint64(cost);
        emit NFTMerged(msg.sender, _nft, _hand, _wearable1, _wearable2, block.timestamp);
    }

    /**
     * @dev checkTraining() - for checking if team is still in training.
     * @param _team set as the name of the team.
     */
    function checkTraining(bytes32 _team) internal {
        Team storage team = teams[_team];
        if(team.play < (block.timestamp - DAY_IN_SECONDS) && team.isTraining == true) {
            uint256 quotient = (block.timestamp - team.play) / DAY_IN_SECONDS;
            team.play += uint64(quotient * DAY_IN_SECONDS);
            team.left_energy = uint96(team.total_energy);
        }
    }

    /**
     * @dev setReward() - for setting the reward of a player.
     * @param _player set as address of the player.
     * @param _amount set as reward amount .
     */
    function setReward(address _player, uint256 _amount) internal {
        uint256 wait = penaltyTime * DAY_IN_SECONDS;
        uint256 _count = players[_player].claimCount;
        //creating batch of rewards
        if(withdrawableReward[_player][_count].time >= (block.timestamp - wait)) {
            withdrawableReward[_player][_count].amount += uint128(_amount);
        } else {
            Reward memory temp;
            temp.amount = uint64(_amount);
            temp.time = uint64(block.timestamp.add(wait));
            withdrawableReward[_player][_count++] = temp;
            players[_player].claimCount++;
        }
        emit PlayerReward(_player, _amount, _count ,block.timestamp);
    }

    /**
     * @dev setLockAmount() - for changing the fee for training.
     * @param _lockAmount set as the changed amount.
     * @param _index set as the index of amount to be changed.
     */
    function setLockAmount(uint256 _lockAmount, uint256 _index) external onlyOwner {
        require(_index < 3);
        LockAmount[_index] = _lockAmount;
    }

    /**
     * @dev setRewardAmount() - for changing the reward amount for each rarity in PvE matches.
     * @param _rewardAmount set as changed amount.
     * @param _index set as index of the amount to be changed.
     */
    function setRewardAmount(uint256 _rewardAmount, uint256 _index) external onlyOwner {
        require(_index < 5);
        RewardAmount[_index] = _rewardAmount;
    }

    /**
     * @dev setLandTax() - for changing the tax percentage of each land rarity.
     * @param _tax set as tax percent for land rarity.
     * @param _index set as index for tax to be changed.
     */
    function setLandTax(uint256 _tax, uint256 _index) external onlyOwner {
        require(_tax <= 100);
        require(_index < 5);
        LandTax[_index] = _tax;
    }

    /**
     * @dev setBetAmount() - for changing the bet amount for PvP matches(in $).
     * @param _amount set as changed amount.
     * @param _index set as index to be changed.
     */
    function setBetAmount(uint256 _amount, uint256 _index) public onlyOwner {
        require(_index < 6);
        BetAmount[_index] = _amount;
    }

    /**
     * @dev setLockTime() - for mchanging time for training a team.
     * @param _time set as changed time for training.
     * @param _index set as index for time to be changed.
     */
    function setLockTime(uint256 _time, uint256 _index) external onlyOwner {
        require(_index < 3);
        LockTime[_index] = _time;
    }

    /**
     * @dev setMergeFee() - for changing merge fees(in $).
     * @param _amount set as changed amount.
     * @param _index set as index of amount to be changed.
     */
    function setMergeFee(uint256 _amount, uint256 _index) external onlyOwner {
        require(_index < 4);
        MergeFee[_index] = _amount;
    }

    /**
     * @dev setOperatorAllowance() - for giving infinite allowance to operator.
     * @param _operator set as address of the operator.
     */
    function setOperatorAllowance(address _operator) external onlyOwner {
        RPSToken.approve(_operator, (2**256 - 1));
    }

    /**
     * @dev whitelistNFT() - for setting status of whitelist contracts
     * @param _nft set as addresses of nft contract.
     * @param _value set the status of the contract.
     */
    function whitelistNFT(address _nft, bool _value) external onlyOwner {
        require(_nft != address(0));
        require(isWhitelisted[_nft] != _value);
        isWhitelisted[_nft] = _value;
    }

    /**
     * @dev whitelistOperator() - for whitelisting an operator.
     * @param _operator set as address of the operator.
     * @param _value set the status.
     */
    function whitelistOperator(address _operator, bool _value) external onlyOwner {
        require(_operator != address(0));
        require(isOperator[_operator] != _value);
        isOperator[_operator] = _value;
    }

    /**
     * @dev setRPSLeague() - for changing RPS league contract address.
     * @param _rpsleague set as address of RPS league contract.
     */
    function setRPSLeague(IERC721 _rpsleague) external onlyOwner {
        RPSleague = _rpsleague;
    }

    /**
     * @dev setMinTax() - for changing minimum tax amount.
     * @param _amount set as the changed amount.
     */
    function setMinTax(uint256 _amount) external onlyOwner {
        require(_amount >= 100000);
        minTax = _amount;
    }

    function setOracleAddress(AggregatorV3Interface _newAddress) external onlyOwner {
        require(address(_newAddress) != address(0));
        oracle = _newAddress;
    }


    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0));
        vault = _vault;
    }

    function setPool(address _pool) external onlyOwner {
        require(_pool != address(0));
        pool = _pool;
    }

    // getter and setter functions
    function getRarity(address[3] memory _nft, uint256[3] memory _tokenIDs) view public returns(uint256){
        uint256 rarity1 = uint256(nft[_nft[0]][_tokenIDs[0]].rarity);
        uint256 rarity2 = uint256(nft[_nft[1]][_tokenIDs[1]].rarity);
        uint256 rarity3 = uint256(nft[_nft[2]][_tokenIDs[2]].rarity);

        if(rarity1 == rarity2 && rarity2 == rarity3)
            return rarity1;
        else if(rarity1 == rarity2)
            return rarity1;
        else if(rarity1 == rarity3)
            return rarity1;
        else if(rarity2 == rarity3)
            return rarity2;
        else {
            if(
                (rarity1 > rarity2 &&
                  rarity1 < rarity3) || 
                (rarity1 > rarity3 &&
                  rarity1 < rarity2)
                ) {
                    return rarity1;
            } else if(
                (rarity2 > rarity1 &&
                  rarity2 < rarity3) || 
                (rarity2 > rarity3 &&
                  rarity2 < rarity1)
                ) {
                    return rarity2;
            } else {
                return rarity3;
            }
        }
    }

    function getClaimAmount(address _player, uint256 _claimNumber) internal view returns(uint256, uint256) {
        Reward storage reward = withdrawableReward[_player][_claimNumber];
        
        if(reward.time <= block.timestamp) {
            return (reward.amount, 0);
        } else {
            uint256 daysPassed = ((uint256(reward.time).sub(block.timestamp)).div(DAY_IN_SECONDS));
            uint256 taxAmount = (uint256(reward.amount).mul(dailyPenaltyFee.mul(daysPassed))).div(100);
            return (uint256(reward.amount), taxAmount);
        }
    }

    function getTotalReward(address _player) public view returns(uint256, uint256) {
        Player storage player = players[_player];
        uint256 reward;
        uint256 totalReward;
        uint256 fee;
        uint256 totalFee;

        for(uint256 i = player.lastClaimCount; i < player.claimCount; i++) {
            (reward, fee) = getClaimAmount(_player, i);
            totalReward = totalReward.add(reward);
            totalFee = totalFee.add(fee);
        }

        return (totalReward, totalFee);
    }

    function getTeamsByUser(address user) public view returns(Team[] memory){
        uint256 _count = teamCount[user];
        Team[] memory _temp = new Team[](_count);


        for(uint i=0; i<_count; i++) {

           _temp[i] = teams[teamList[user][i+1]];
        }
        return _temp;
    }

    function getTeamNFTByName(bytes32 _teamName) public view returns(uint256[3] memory) {
        return teams[_teamName].nftIds;
    }

    function getTeamNames(address user) public view returns(bytes32[] memory) {
        uint256 _count = teamCount[user];
        bytes32[] memory _temp = new bytes32[](_count);

        for(uint i=0; i<_count; i++) {
            _temp[i] = teamList[user][i+1];
        }

        return _temp;
    }

    function getPlayerDetails(address _player) public view returns(Player memory) {
        return players[_player];
    }

    function getOcuupiedNfts(address _player) public view returns(uint256[] memory) {
        uint256 _count = teamCount[_player];
        uint256 tempCount;
        uint256[] memory temp = new uint256[](3 * _count);

        for(uint i=0; i<_count; i++) {
            for(uint j=0; j<3; j++) {
                temp[tempCount] = teams[teamList[_player][i+1]].nftIds[j];
                tempCount++;
            }
        }

        return temp;    
    }

    function getAttachedWearable(address _nft, uint256 _tokenId) public view returns(uint256, uint256, address[2] memory) {
        NFTs storage target = nft[_nft][_tokenId];
        return (uint256(target.wearable1), uint256(target.wearable2), target.wearableAddresses);
    }

    function getWearableList(address _nft, uint256[] memory _tokenIDs) public view returns(Wearable[] memory){
        uint256 size = _tokenIDs.length;
        Wearable[] memory temp = new Wearable[](size);
        
        for(uint256 i=0; i< size; i++) {
            temp[i] = wearables[_nft][_tokenIDs[i]];
        }
        return temp;
    }

    function getWearableEnergy(address _user, address[3] memory _nft, uint256[3] memory _tokenIDs) public view returns(uint256) {
        uint256[6] memory list;
        uint256 totalEnergy;

        NFTs storage nft0 = nft[_nft[0]][_tokenIDs[0]];
        NFTs storage nft1 = nft[_nft[1]][_tokenIDs[1]];
        NFTs storage nft2 = nft[_nft[2]][_tokenIDs[2]];

        if (nft0.attachedBy[0] == _user)
        list[0] = uint256(wearables[_nft[0]][nft0.wearable1].accessory);
        if (nft0.attachedBy[1] == _user)
        list[1] = uint256(wearables[_nft[0]][nft0.wearable2].accessory);
        if (nft1.attachedBy[0] == _user)
        list[2] = uint256(wearables[_nft[1]][nft1.wearable1].accessory);
        if (nft1.attachedBy[1] == _user)
        list[3] = uint256(wearables[_nft[1]][nft1.wearable2].accessory);
        if (nft2.attachedBy[0] == _user)
        list[4] = uint256(wearables[_nft[2]][nft2.wearable1].accessory);
        if (nft2.attachedBy[1] == _user)
        list[5] = uint256(wearables[_nft[2]][nft2.wearable2].accessory);

        for(uint256 i; i < 6; i++) {
            totalEnergy = totalEnergy + checkEnergy(list[i]);
        }

        return totalEnergy;
    }

    function checkEnergy(uint256 _id) internal pure returns(uint256 _energy) {
        if(_id == 1)
            _energy = 2;
        else if(_id == 2)
            _energy = 4;
        else if(_id == 3)
            _energy = 0;
    }

    function getLeftEnergy(bytes32 _team) external view returns(uint256) {
        if(teams[_team].play < (block.timestamp - DAY_IN_SECONDS) && teams[_team].isTraining == true)
            return teams[_team].total_energy;
        else 
            return teams[_team].left_energy;
    }

    function getAmountOut(uint256 forAmount) public view returns(uint256) {
        (,int256 price,,,) = oracle.latestRoundData();
        uint256 output = (forAmount.mul((10 ** oracle.decimals()))).div(uint256(price));
        return output;

    }

    function emergencyWithdraw(address _to) public onlyOwner {
        uint256 bal = RPSToken.balanceOf(address(this));
        require(bal > 0);
        RPSToken.transfer(_to, bal);
    }
}