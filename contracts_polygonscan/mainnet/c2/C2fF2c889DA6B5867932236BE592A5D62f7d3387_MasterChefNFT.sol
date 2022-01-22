/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]


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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]


pragma solidity ^0.8.0;

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


// File contracts/libs/INFT.sol

/*

 /$$$$$$$$ /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$   /$$ /$$$$$$$  /$$       /$$$$$$$$  /$$$$$$   /$$$$$$ 
|__  $$__/| $$  | $$| $$_____/      | $$_____/| $$$ | $$| $$__  $$| $$      | $$_____/ /$$__  $$ /$$__  $$
   | $$   | $$  | $$| $$            | $$      | $$$$| $$| $$  \ $$| $$      | $$      | $$  \__/| $$  \__/
   | $$   | $$$$$$$$| $$$$$         | $$$$$   | $$ $$ $$| $$  | $$| $$      | $$$$$   |  $$$$$$ |  $$$$$$ 
   | $$   | $$__  $$| $$__/         | $$__/   | $$  $$$$| $$  | $$| $$      | $$__/    \____  $$ \____  $$
   | $$   | $$  | $$| $$            | $$      | $$\  $$$| $$  | $$| $$      | $$       /$$  \ $$ /$$  \ $$
   | $$   | $$  | $$| $$$$$$$$      | $$$$$$$$| $$ \  $$| $$$$$$$/| $$$$$$$$| $$$$$$$$|  $$$$$$/|  $$$$$$/
   |__/   |__/  |__/|________/      |________/|__/  \__/|_______/ |________/|________/ \______/  \______/ 
                                                                                                          
*/

pragma solidity ^ 0.8.6;

interface  INFT {
    function setExperience(uint256 tokenId, uint256 _newExperience) external;
    function getCharacterStats(uint256 tokenId) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function getCharacterOverView(uint256 tokenId) external returns (string memory,uint256,uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/libs/ImergeAPI.sol

pragma solidity ^ 0.8.6;

interface  ImergeAPI {
    function getSkillCard(uint256 _nftID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/SandManTokenV3.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */

pragma solidity ^0.8.6;



/*
  TABLE ERROR REFERENCE:
  ERR1: The sender is on the blacklist. Please contact to support.
  ERR2: The recipient is on the blacklist. Please contact to support.
  ERR3: User cannot send more than allowed.
  ERR4: User is not operator.
  ERR5: User is excluded from antibot system.
  ERR6: Bot address is already on the blacklist.
  ERR7: The expiration time has to be greater than 0.
  ERR8: Bot address is not found on the blacklist.
  ERR9: Address cant be 0.
*/

// SandManToken
contract SandManTokenV3 is ERC20, Ownable {

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event HoldingAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event AntiBotWorkingStatus(address indexed operator, bool previousStatus, bool newStatus);
    event AddBotAddress(address indexed botAddress);
    event RemoveBotAddress(address indexed botAddress);
    event ExcludedOperatorsUpdated(address indexed operatorAddress, bool previousStatus, bool newStatus);
    event ExcludedHoldersUpdated(address indexed holderAddress, bool previousStatus, bool newStatus);
    

    using SafeMath for uint256;

    ///@dev Max transfer amount rate. (default is 3% of total supply)
    uint16 public maxUserTransferAmountRate = 300;
    
    ///@dev Max holding rate. (default is 9% of total supply)
    uint16 public maxUserHoldAmountRate = 900;

    ///@dev Length of blacklist addressess
    uint256 public blacklistLength;
 
    ///@dev Enable|Disable antiBot
    bool public antiBotWorking;
    
    ///@dev Exclude operators from antiBot system
    mapping(address => bool) private _excludedOperatorsFromAntiBot;

    ///@dev Exclude holders from antiBot system
    mapping(address => bool) private _excludedHoldersFromAntiBot;

    ///@dev mapping store blacklist. address=>ExpirationTime 
    mapping(address => uint256) private _blacklist;
    

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    // operator role
    address internal _operator;

    // MODIFIERS
    modifier antiBot(address _sender, address _recipient, uint256 _amount) { 
        //check blacklist
        require(!_blacklistCheck(_sender), "ERR1");
        require(!_blacklistCheck(_recipient), "ERR2");

        // This code will be disabled after launch and before farming
        if (antiBotWorking){
            // check  if sender|recipient has a tx amount is within the allowed limits
            if (_isNotOperatorExcludedFromAntiBot(_sender)){
                if(_isNotOperatorExcludedFromAntiBot(_recipient))
                    require(_amount <= _maxUserTransferAmount(), "ERR3");
            }
        }
        _;
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "ERR4");
        _;
    }
    
    constructor() 
        ERC20('DEATH TOKEN', 'DEATH')
    {
      // Exclude operator addresses, lps, etc from antibot system
        _excludedOperatorsFromAntiBot[msg.sender] = true;
        _excludedOperatorsFromAntiBot[address(0)] = true;
        _excludedOperatorsFromAntiBot[address(this)] = true;
        _excludedOperatorsFromAntiBot[BURN_ADDRESS] = true;

        _operator = _msgSender();
    }
    

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
    
    //INTERNALS
    
    /// @dev overrides transfer function to use antibot system
    function _transfer(address _sender, address _recipient, uint256 _amount) internal virtual override antiBot(_sender, _recipient, _amount) {
        // Autodetect is sender is a BOT
        // This code will be disabled after launch and before farming
        if (antiBotWorking){
            // check  if sender|recipient has a tx amount is within the allowed limits
            if (_isNotHolderExcludedFromAntiBot(_sender)){
                if(_isNotOperatorExcludedFromAntiBot(_sender)){
                    if (balanceOf(_sender) > _maxUserHoldAmount()) {
                        _addBotAddressToBlackList(_sender, type(uint256).max);
                        return;
                    }
                }
            }
        }
        
        super._transfer(_sender, _recipient, _amount);
    }

    /// @dev internal function to add address to blacklist.
    function _addBotAddressToBlackList(address _botAddress, uint256 _expirationTime) internal {
        require(_isNotHolderExcludedFromAntiBot(_botAddress), "ERR5");
        require(_isNotOperatorExcludedFromAntiBot(_botAddress), "ERR5");
        require(_blacklist[_botAddress] == 0, "ERR6");
        require(_expirationTime > 0, "ERR7");

        _blacklist[_botAddress] = _expirationTime;
        blacklistLength = blacklistLength.add(1);

        emit AddBotAddress(_botAddress);
    }
    
    ///@dev internal function to remove address from blacklist.
    function _removeBotAddressToBlackList(address _botAddress) internal {
        require(_blacklist[_botAddress] > 0, "ERR8");

        delete _blacklist[_botAddress];
        blacklistLength = blacklistLength.sub(1);

        emit RemoveBotAddress(_botAddress);
    }

    ///@dev Check if the address is excluded from antibot system.
    function _isNotHolderExcludedFromAntiBot(address _userAddress) internal view returns(bool) {
        return(!_excludedHoldersFromAntiBot[_userAddress]);
    }

    ///@dev Check if the address is excluded from antibot system.
    function _isNotOperatorExcludedFromAntiBot(address _userAddress) internal view returns(bool) {
        return(!_excludedOperatorsFromAntiBot[_userAddress]);
    }

    ///@dev Max user transfer allowed
    function _maxUserTransferAmount() internal view returns (uint256) {
        return totalSupply().mul(maxUserTransferAmountRate).div(10000);
    }

    ///@dev Max user Holding allowed
    function _maxUserHoldAmount() internal view returns (uint256) {
        return totalSupply().mul(maxUserHoldAmountRate).div(10000);
    }

    ///@dev check if the address is in the blacklist or expired
    function _blacklistCheck(address _botAddress) internal view returns(bool) {
        if(_blacklist[_botAddress] > 0)
            return _blacklist[_botAddress] > block.timestamp;
        else 
            return false;
    }

    // PUBLICS
 
    ///@dev Max user transfer allowed
    function maxUserTransferAmount() external view returns (uint256) {
        return _maxUserTransferAmount();
    }

    ///@dev Max user Holding allowed
    function maxUserHoldAmount() external view returns (uint256) {
        return _maxUserHoldAmount();
    }

     ///@dev check if the address is in the blacklist or expired
    function blacklistCheck(address _botAddress) external view returns(bool) {
        return _blacklistCheck(_botAddress);     
    }
    
    ///@dev check if the address is in the blacklist or not
    function blacklistCheckExpirationTime(address _botAddress) external view returns(uint256){
        return _blacklist[_botAddress];
    }


    // EXTERNALS

    ///@dev Update operator address status
    function updateOperatorsFromAntiBot(address _operatorAddress, bool _status) external onlyOwner {
        require(_operatorAddress != address(0), "ERR9");

        emit ExcludedOperatorsUpdated(_operatorAddress, _excludedOperatorsFromAntiBot[_operatorAddress], _status);

        _excludedOperatorsFromAntiBot[_operatorAddress] = _status;
    }

    ///@dev Update operator address status
    function updateHoldersFromAntiBot(address _holderAddress, bool _status) external onlyOwner {
        require(_holderAddress != address(0), "ERR9");

        emit ExcludedHoldersUpdated(_holderAddress, _excludedHoldersFromAntiBot[_holderAddress], _status);

        _excludedHoldersFromAntiBot[_holderAddress] = _status;
    }


    ///@dev Update operator address
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "ERR9");
        
        emit OperatorTransferred(_operator, newOperator);

        _operator = newOperator;
    }

    function operator() external view returns (address) {
        return _operator;
    }

     ///@dev Updates the max holding amount. 
    function updateMaxUserHoldAmountRate(uint16 _maxUserHoldAmountRate) external onlyOwner {
        require(_maxUserHoldAmountRate >= 500);
        require(_maxUserHoldAmountRate <= 10000);
        
        emit TransferTaxRateUpdated(_msgSender(), maxUserHoldAmountRate, _maxUserHoldAmountRate);

        maxUserHoldAmountRate = _maxUserHoldAmountRate;
    }

    ///@dev Updates the max user transfer amount. 
    function updateMaxUserTransferAmountRate(uint16 _maxUserTransferAmountRate) external onlyOwner {
        require(_maxUserTransferAmountRate >= 50);
        require(_maxUserTransferAmountRate <= 10000);
        
        emit HoldingAmountRateUpdated(_msgSender(), maxUserHoldAmountRate, _maxUserTransferAmountRate);

        maxUserTransferAmountRate = _maxUserTransferAmountRate;
    }

    
    ///@dev Update the antiBotWorking status: ENABLE|DISABLE.
    function updateStatusAntiBotWorking(bool _status) external onlyOwner {
        emit AntiBotWorkingStatus(_msgSender(), antiBotWorking, _status);

        antiBotWorking = _status;
    }

     ///@dev Add an address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
    function addBotAddress(address _botAddress, uint256 _expirationTime) external onlyOwner {
        _addBotAddressToBlackList(_botAddress, _expirationTime);
    }
    
    ///@dev Remove an address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
    function removeBotAddress(address botAddress) external onlyOperator {
        _removeBotAddressToBlackList(botAddress);
    }
    
    ///@dev Add multi address to the blacklist. Only the owner can add. Owner is the address of the Governance contract.
    function addBotAddressBatch(address[] memory _addresses, uint256 _expirationTime) external onlyOwner {
        require(_addresses.length > 0);

        for(uint i=0;i<_addresses.length;i++){
            _addBotAddressToBlackList(_addresses[i], _expirationTime);
        }
    }
    
    ///@dev Remove multi address from the blacklist. Only the owner can remove. Owner is the address of the Governance contract.
    function removeBotAddressBatch(address[] memory _addresses) external onlyOperator {
        require(_addresses.length > 0);

        for(uint i=0;i<_addresses.length;i++){
            _removeBotAddressToBlackList(_addresses[i]);
        }
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedOperatorFromAntiBot(address _userAddress) external view returns(bool) {
        return(_excludedOperatorsFromAntiBot[_userAddress]);
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedHolderFromAntiBot(address _userAddress) external view returns(bool) {
        return(_excludedHoldersFromAntiBot[_userAddress]);
    }
}


// File contracts/libs/Operator.sol


pragma solidity 0.8.6;

contract Operator {
    address public operatorAddress;

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "!operator");
        _;
    }

    function setGov(address _operatorAddress) external onlyOperator {
        operatorAddress = _operatorAddress;
    }
}


// File contracts/MasterChefNFT.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */

pragma solidity ^0.8.6;







/*
 * Errors Ref Table
 * E1: !nonzero
 * E2: nonDuplicated: duplicated
 * E3: add: invalid deposit fee basis points
 * E4: add: invalid harvest interval
 * E5: set: invalid deposit fee basis points
 * E6: we dont accept deposits of 0 size
 * E7: withdraw: not good
 * E8: safeSandManTransfer: transfer failed
 * E9: cannot change start block if sale has already commenced
 * E10: cannot set start block in the past
 * E11: user already added nft
 * E12: User is not owner of nft sent
 * E13: user no has nft
 * E14: we dont accept deposits of 0 size
 */

contract MasterChefNFT is Ownable, ReentrancyGuard, ERC721Holder, Operator {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 nextHarvestUntil;
        uint256 rewardLockedUp;
        uint256 nftID;
        bool hasNFT;
        uint256 powerStaking;
        uint256 experience;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accSandManPerShare;
        uint16 depositFeeBP;
        uint256 lpSupply;
        uint256 harvestInterval;
    }

    uint256 public constant sandManMaximumSupply = 50 * (10 ** 3) * (10 ** 18); // 50000 sandMan
    uint256 public constant MAX_EMISSION_RATE = 10 * (10 ** 18); // 10
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // The SANDMAN TOKEN!
    SandManTokenV3 public immutable sandMan;
    INFT public immutable iNFT;
    ImergeAPI public immutable iMergeAPI;

    // SANDMAN tokens created per second.
    uint256 public sandManPerSecond;
    uint256 public experienceRate;

    uint256 public experienceFactor;

    // Deposit Fee address
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SANDMAN mining starts.
    uint256 public startTime;
    // The block number when SANDMAN mining ends.
    uint256 public emmissionEndTime = type(uint256).max;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    mapping(uint256 => bool) nftIDs;

    mapping(address => bool) public harvestLockupWhiteList;

    // The harvest interval
    uint256 public harvestInterval;

    uint256 totalSupplyFarmed;

    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawNFT(address indexed user, uint256 indexed pid, uint256 nftID);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetEmissionRate(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetStartTime(uint256 indexed newStartTime);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event WithDrawNFTByIndex(uint256 indexed _nftID, address indexed _userAddress);

    constructor(
        SandManTokenV3 _sandMan,
        INFT _iNFT,
        ImergeAPI _iMergeAPI,
        address _feeAddress,
        uint256 _sandManPerSecond,
        uint256 _experienceRate,
        uint256 _startTime,
        uint256 _experienceFactor
    ) {
        require(_feeAddress != address(0), "E1");

        sandMan = _sandMan;
        iNFT = _iNFT;
        iMergeAPI = _iMergeAPI;
        feeAddress = _feeAddress;
        sandManPerSecond = _sandManPerSecond;
        experienceRate = _experienceRate;
        startTime = _startTime;
        experienceFactor = _experienceFactor;

        operatorAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(!poolExistence[_lpToken], "E2");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        // Make sure the provided token is ERC20
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 401, "E3");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "E4");

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
          lpToken : _lpToken,
          allocPoint : _allocPoint,
          lastRewardTime : lastRewardTime,
          depositFeeBP : _depositFeeBP,
          lpSupply: 0,
          accSandManPerShare : 0,
          harvestInterval: _harvestInterval
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's SANDMAN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 401, "E5");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to time.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // As we set the multiplier to 0 here after emmissionEndTime
        // deposits aren't blocked after farming ends.
        if (_from > emmissionEndTime) {
            return 0;
        }
        if (_to > emmissionEndTime) {
            return emmissionEndTime - _from;
        } else {
            return _to - _from;
        }
    }

    // View function to see pending SANDMANs on frontend.
    function pendingSandMan(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSandManPerShare = pool.accSandManPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;
            accSandManPerShare = accSandManPerShare + ((sandManReward * 1e18) / pool.lpSupply);
        }
        uint256 pending = ((user.amount * accSandManPerShare) /  1e18) - user.rewardDebt;

        return pending + user.rewardLockedUp;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;

        // This shouldn't happen, but just in case we stop rewards.
        if (totalSupplyFarmed > sandManMaximumSupply) {
            sandManReward = 0;
        } else if ((totalSupplyFarmed + sandManReward) > sandManMaximumSupply) {
            sandManReward = sandManMaximumSupply - totalSupplyFarmed;
        }

        if (sandManReward > 0) {
            sandMan.mint(address(this), sandManReward);
            totalSupplyFarmed = totalSupplyFarmed + sandManReward;
        }

        // The first time we reach SandMan max supply we solidify the end of farming.
        if (totalSupplyFarmed >= sandManMaximumSupply && emmissionEndTime == type(uint256).max) {
            emmissionEndTime = block.timestamp;
        }

        pool.accSandManPerShare = pool.accSandManPerShare + ((sandManReward * 1e18) / pool.lpSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for SANDMAN allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        payOrLockupPendingSandMan(_pid);
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            require(_amount > 0, "E6");

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_amount * pool.depositFeeBP) / 10000;
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount + _amount - depositFee;
                pool.lpSupply = pool.lpSupply + _amount - depositFee;
            } else {
                user.amount = user.amount + _amount;
                pool.lpSupply = pool.lpSupply + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "E7");
        updatePool(_pid);
        payOrLockupPendingSandMan(_pid);
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply - _amount;
        }
        user.rewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.lpSupply >=  amount) {
            pool.lpSupply = pool.lpSupply - amount;
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe sandMan transfer function, just in case if rounding error causes pool to not have enough SANDMANs.
    function safeSandManTransfer(address _to, uint256 _amount) internal {
        uint256 sandManBal = sandMan.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > sandManBal) {
            transferSuccess = sandMan.transfer(_to, sandManBal);
        } else {
            transferSuccess = sandMan.transfer(_to, _amount);
        }
        require(transferSuccess, "E8");
    }

    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "E1");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Update lastRewardTime variables for all pools.
    function _massUpdateLastRewardTimePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; ++_pid) {
            poolInfo[_pid].lastRewardTime = startTime;
        }
    }

    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "E9");
        require(block.timestamp < _newStartTime, "E10");

        startTime = _newStartTime;
        _massUpdateLastRewardTimePools();

        emit SetStartTime(startTime);
    }

    function setEmissionRate(uint256 _sandManPerSecond) external onlyOwner {
        require(_sandManPerSecond > 0);
        require(_sandManPerSecond < MAX_EMISSION_RATE);

        massUpdatePools();
        sandManPerSecond = _sandManPerSecond;

        emit SetEmissionRate(msg.sender, sandManPerSecond, _sandManPerSecond);
    }

    function setExperienceRate(uint256 _experienceRate) external onlyOperator {
        require(_experienceRate >= 0);

        experienceRate = _experienceRate;
    }

    function setExperienceFactor(uint256 _experienceFactor) external onlyOperator {
        require(_experienceFactor >= 0);

        experienceFactor = _experienceFactor;
    }

    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];

        return block.timestamp >= user.nextHarvestUntil;
    }

    function payOrLockupPendingSandMan(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            _updateHarvestLookup(_pid, msg.sender);
        }
        uint256 pending = ((user.amount * pool.accSandManPerShare) / 1e18) - user.rewardDebt;

        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending + user.rewardLockedUp;
                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards - user.rewardLockedUp;
                user.rewardLockedUp = 0;
                _updateHarvestLookup(_pid, msg.sender);

                // send rewards
                safeSandManTransfer(msg.sender, totalRewards);

                if (user.hasNFT) {
                    payNftBoost(_pid, msg.sender, totalRewards);
                    user.experience = user.experience + ((totalRewards * experienceRate) / 10000);
                    iNFT.setExperience(user.nftID, user.experience);
                }
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp + pending;
            totalLockedUpRewards = totalLockedUpRewards + pending;
        }

        emit RewardLockedUp(msg.sender, _pid, pending);
    }

    //NFT CODE
    function _getNFTPowerStaking(uint256 _nftID) internal view returns (uint256) {
        uint256 strength;
        uint256 agility;
        uint256 endurance;
        uint256 intelligence;
        uint256 wisdom;
        uint256 magic;

        (
            strength,
            agility,
            endurance,
            intelligence,
            magic,
            wisdom
        ) = iMergeAPI.getSkillCard(_nftID);

        if (strength == 0 && agility == 0 ) {
            (
                strength,
                agility,
                endurance,
                intelligence,
                wisdom,
                magic
            ) = iNFT.getCharacterStats(_nftID);
        }

        return (strength + agility + endurance + intelligence + magic + wisdom);
    }

    function _getNFTExperience(uint256 _nftID) internal returns (uint256) {
        (,uint256 experience,) = iNFT.getCharacterOverView(_nftID);

        return experience;
    }

    function _updateHarvestLookup(uint256 _pid, address _userAddress) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAddress];

        uint256 newHarvestInverval = harvestLockupWhiteList[_userAddress] ? 0 : pool.harvestInterval;

        if (user.hasNFT && newHarvestInverval > 0) {
            uint256 quarterInterval = (newHarvestInverval * 2500) / 10000;
            uint256 expBaseBoosted = quarterInterval;
            if (user.experience < experienceFactor) {
                expBaseBoosted = (((user.experience * 100) / experienceFactor) * expBaseBoosted) / 100;
            }
            newHarvestInverval = newHarvestInverval - quarterInterval - expBaseBoosted;
        }

        user.nextHarvestUntil = block.timestamp + newHarvestInverval;
    }

    function payNftBoost(uint256 _pid, address _userAddress, uint256 _pending) internal {
        UserInfo storage user = userInfo[_pid][_userAddress];

        uint256 expBaseBoosted = 400;
        if (user.experience < experienceFactor) {
            expBaseBoosted = (((user.experience * 100) / experienceFactor) * expBaseBoosted) / 100;
        }

        uint256 rewardBoosted = (_pending * (user.powerStaking + expBaseBoosted)) / 10000;
        if (rewardBoosted > 0) {
            sandMan.mint(_userAddress, rewardBoosted);
        }
    }

    function addNFT(uint256 _pid, uint256 _nftID) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(!user.hasNFT, "E11");
        require(iNFT.ownerOf(_nftID) == msg.sender, "E12");

        updatePool(_pid);
        payOrLockupPendingSandMan(_pid);

        //transfer nft to mc
        iNFT.safeTransferFrom(msg.sender, address(this), _nftID);

        user.hasNFT = true;
        user.nftID = _nftID;
        nftIDs[_nftID] = true;
        user.powerStaking = _getNFTPowerStaking(user.nftID);
        user.experience = _getNFTExperience(user.nftID);

        _updateHarvestLookup(_pid, msg.sender);

        user.rewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;
    }

    function withdrawNFT(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.hasNFT, "E13");

        updatePool(_pid);

        user.nextHarvestUntil = 1;
        payOrLockupPendingSandMan(_pid);

        iNFT.safeTransferFrom(address(this), msg.sender, user.nftID); 

        nftIDs[user.nftID] = false;

        user.hasNFT = false;
        user.nftID = 0;
        user.powerStaking = 0;
        user.experience = 0;

        _updateHarvestLookup(_pid, msg.sender);

        user.rewardDebt = (user.amount * pool.accSandManPerShare) / 1e18;

        emit WithdrawNFT(msg.sender, _pid, user.nftID);
    }

    function withDrawNFTByIndex(uint256 _nftID, address _userAddress) external onlyOperator {
        require(iNFT.ownerOf(_nftID) == address(this));

        iNFT.safeTransferFrom(address(this), _userAddress, _nftID);

        emit WithDrawNFTByIndex(_nftID, _userAddress);
    }

    function addHarvestLockupWhiteList(address[] memory _recipients) external onlyOperator {
        for(uint i = 0; i < _recipients.length; i++) {
            harvestLockupWhiteList[_recipients[i]] = true;
        }
    }

    function removeHarvestLockupWhiteList(address[] memory _recipients) external onlyOperator {
        for(uint i = 0; i < _recipients.length; i++) {
            harvestLockupWhiteList[_recipients[i]] = false;
        }
    }
}