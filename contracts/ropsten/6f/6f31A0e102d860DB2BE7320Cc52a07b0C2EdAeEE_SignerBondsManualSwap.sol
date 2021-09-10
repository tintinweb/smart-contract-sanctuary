// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @notice Implementation of [EIP-1167] based on [clone-factory]
/// source code.
///
/// EIP 1167: https://eips.ethereum.org/EIPS/eip-1167
// Original implementation: https://github.com/optionality/clone-factory
// Modified to use ^0.8.5; instead of ^0.4.23 solidity version.
/* solhint-disable no-inline-assembly */
abstract contract CloneFactory {
    /// @notice Creates EIP-1167 clone of the contract under the provided
    ///         `target` address. Returns address of the created clone.
    /// @dev In specific circumstances, such as the `target` contract destroyed,
    ///      create opcode may return 0x0 address. The code calling this
    ///      function should handle this corner case properly.
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    /// @notice Checks if the contract under the `query` address is a EIP-1167
    ///         clone of the contract under `target` address.
    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC20WithPermit.sol";
import "./IReceiveApproval.sol";

/// @title  ERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
contract ERC20WithPermit is IERC20WithPermit, Ownable {
    /// @notice The amount of tokens owned by the given account.
    mapping(address => uint256) public override balanceOf;

    /// @notice The remaining number of tokens that spender will be
    ///         allowed to spend on behalf of owner through `transferFrom` and
    ///         `burnFrom`. This is zero by default.
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    mapping(address => uint256) public override nonces;

    uint256 public immutable cachedChainId;
    bytes32 public immutable cachedDomainSeparator;

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    bytes32 public constant override PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @notice The amount of tokens in existence.
    uint256 public override totalSupply;

    /// @notice The name of the token.
    string public override name;

    /// @notice The symbol of the token.
    string public override symbol;

    /// @notice The decimals places of the token.
    uint8 public constant override decimals = 18;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        cachedChainId = block.chainid;
        cachedDomainSeparator = buildDomainSeparator();
    }

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///       - `recipient` cannot be the zero address,
    ///       - the caller must have a balance of at least `amount`.
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the
    ///         allowance mechanism. `amount` is then deducted from the caller's
    ///         allowance unless the allowance was made for `type(uint256).max`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///      - `sender` and `recipient` cannot be the zero address,
    ///      - `sender` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `sender`'s tokens of at least
    ///        `amount`.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Transfer amount exceeds allowance"
            );
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.  If the `amount` is set
    ///         to `type(uint256).max` then `transferFrom` and `burnFrom` will
    ///         not reduce an allowance.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Permission expired");

        // Validate `s` and `v` values for a malleability concern described in EIP2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order and `v` value of 27 or 28 are considered valid.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        amount,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Invalid signature"
        );
        _approve(owner, spender, amount);
    }

    /// @notice Creates `amount` tokens and assigns them to `account`,
    ///         increasing the total supply.
    /// @dev Requirements:
    ///      - `recipient` cannot be the zero address.
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Mint to the zero address");

        beforeTokenTransfer(address(0), recipient, amount);

        totalSupply += amount;
        balanceOf[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    /// @notice Destroys `amount` tokens from the caller.
    /// @dev Requirements:
    ///       - the caller must have a balance of at least `amount`.
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /// @notice Destroys `amount` of tokens from `account` using the allowance
    ///         mechanism. `amount` is then deducted from the caller's allowance
    ///         unless the allowance was made for `type(uint256).max`.
    /// @dev Requirements:
    ///      - `account` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `account`'s tokens of at least
    ///        `amount`.
    function burnFrom(address account, uint256 amount) external override {
        uint256 currentAllowance = allowance[account][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Burn amount exceeds allowance"
            );
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /// @notice Calls `receiveApproval` function on spender previously approving
    ///         the spender to withdraw from the caller multiple times, up to
    ///         the `amount` amount. If this function is called again, it
    ///         overwrites the current allowance with `amount`. Reverts if the
    ///         approval reverted or if `receiveApproval` call on the spender
    ///         reverted.
    /// @return True if both approval and `receiveApproval` calls succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external override returns (bool) {
        if (approve(spender, amount)) {
            IReceiveApproval(spender).receiveApproval(
                msg.sender,
                amount,
                address(this),
                extraData
            );
            return true;
        }
        return false;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's
    ///         tokens.
    /// @return True if the operation succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    ///      Beware that changing an allowance with this method brings the risk
    ///      that someone may use both the old and the new allowance by
    ///      unfortunate transaction ordering. One possible solution to mitigate
    ///      this race condition is to first reduce the spender's allowance to 0
    ///      and set the desired value afterwards:
    ///      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        // As explained in EIP-2612, if the DOMAIN_SEPARATOR contains the
        // chainId and is defined at contract deployment instead of
        // reconstructed for every signature, there is a risk of possible replay
        // attacks between chains in the event of a future chain split.
        // To address this issue, we check the cached chain ID against the
        // current one and in case they are different, we build domain separator
        // from scratch.
        if (block.chainid == cachedChainId) {
            return cachedDomainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    /// @dev Hook that is called before any transfer of tokens. This includes
    ///      minting and burning.
    ///
    /// Calling conditions:
    /// - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
    ///   will be to transferred to `to`.
    /// - when `from` is zero, `amount` tokens will be minted for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    /// - `from` and `to` are never both zero.
    // slither-disable-next-line dead-code
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _burn(address account, uint256 amount) internal {
        uint256 currentBalance = balanceOf[account];
        require(currentBalance >= amount, "Burn amount exceeds balance");

        beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] = currentBalance - amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(recipient != address(this), "Transfer to the token address");

        beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balanceOf[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        balanceOf[sender] = senderBalance - amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by tokens supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IApproveAndCall {
    /// @notice Executes `receiveApproval` function on spender as specified in
    ///         `IReceiveApproval` interface. Approves spender to withdraw from
    ///         the caller multiple times, up to the `amount`. If this
    ///         function is called again, it overwrites the current allowance
    ///         with `amount`. Reverts if the approval reverted or if
    ///         `receiveApproval` call on the spender reverted.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IApproveAndCall.sol";

/// @title  IERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
interface IERC20WithPermit is IERC20, IERC20Metadata, IApproveAndCall {
    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Destroys `amount` tokens from the caller.
    function burn(uint256 amount) external;

    /// @notice Destroys `amount` of tokens from `account`, deducting the amount
    ///         from caller's allowance.
    function burnFrom(address account, uint256 amount) external;

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    function nonces(address owner) external view returns (uint256);

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    /* solhint-disable-next-line func-name-mixedcase */
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by contracts supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IReceiveApproval {
    /// @notice Receives approval to spend tokens. Called as a result of
    ///         `approveAndCall` call on the token.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IAssetPool.sol";
import "./interfaces/IAssetPoolUpgrade.sol";
import "./RewardsPool.sol";
import "./UnderwriterToken.sol";
import "./GovernanceUtils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Asset Pool
/// @notice Asset pool is a component of a Coverage Pool. Asset Pool
///         accepts a single ERC20 token as collateral, and returns an
///         underwriter token. For example, an asset pool might accept deposits
///         in KEEP in return for covKEEP underwriter tokens. Underwriter tokens
///         represent an ownership share in the underlying collateral of the
///         Asset Pool.
contract AssetPool is Ownable, IAssetPool {
    using SafeERC20 for IERC20;
    using SafeERC20 for UnderwriterToken;

    IERC20 public immutable collateralToken;
    UnderwriterToken public immutable underwriterToken;

    RewardsPool public immutable rewardsPool;

    IAssetPoolUpgrade public newAssetPool;

    /// @notice The time it takes the underwriter to withdraw their collateral
    ///         and rewards from the pool. This is the time that needs to pass
    ///         between initiating and completing the withdrawal. During that
    ///         time, underwriter is still earning rewards and their share of
    ///         the pool is still a subject of a possible coverage claim.
    uint256 public withdrawalDelay = 21 days;
    uint256 public newWithdrawalDelay;
    uint256 public withdrawalDelayChangeInitiated;

    /// @notice The time the underwriter has after the withdrawal delay passed
    ///         to complete the withdrawal. During that time, underwriter is
    ///         still earning rewards and their share of the pool is still
    ///         a subject of a possible coverage claim.
    ///         After the withdrawal timeout elapses, tokens stay in the pool
    ///         and the underwriter has to initiate the withdrawal again and
    ///         wait for the full withdrawal delay to complete the withdrawal.
    uint256 public withdrawalTimeout = 2 days;
    uint256 public newWithdrawalTimeout;
    uint256 public withdrawalTimeoutChangeInitiated;

    mapping(address => uint256) public withdrawalInitiatedTimestamp;
    mapping(address => uint256) public pendingWithdrawal;

    event Deposited(
        address indexed underwriter,
        uint256 amount,
        uint256 covAmount
    );

    event CoverageClaimed(
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    event WithdrawalInitiated(
        address indexed underwriter,
        uint256 covAmount,
        uint256 timestamp
    );
    event WithdrawalCompleted(
        address indexed underwriter,
        uint256 amount,
        uint256 covAmount,
        uint256 timestamp
    );

    event ApprovedAssetPoolUpgrade(address newAssetPool);
    event CancelledAssetPoolUpgrade(address cancelledAssetPool);
    event AssetPoolUpgraded(
        address indexed underwriter,
        uint256 collateralAmount,
        uint256 covAmount,
        uint256 timestamp
    );

    event WithdrawalDelayUpdateStarted(
        uint256 withdrawalDelay,
        uint256 timestamp
    );
    event WithdrawalDelayUpdated(uint256 withdrawalDelay);
    event WithdrawalTimeoutUpdateStarted(
        uint256 withdrawalTimeout,
        uint256 timestamp
    );
    event WithdrawalTimeoutUpdated(uint256 withdrawalTimeout);

    /// @notice Reverts if the withdrawal governance delay has not passed yet or
    ///         if the change was not yet initiated.
    /// @param changeInitiatedTimestamp The timestamp at which the change has
    ///        been initiated
    modifier onlyAfterWithdrawalGovernanceDelay(
        uint256 changeInitiatedTimestamp
    ) {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - changeInitiatedTimestamp >=
                withdrawalGovernanceDelay(),
            "Governance delay has not elapsed"
        );
        _;
    }

    constructor(
        IERC20 _collateralToken,
        UnderwriterToken _underwriterToken,
        address rewardsManager
    ) {
        collateralToken = _collateralToken;
        underwriterToken = _underwriterToken;

        rewardsPool = new RewardsPool(
            _collateralToken,
            address(this),
            rewardsManager
        );
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints underwriter tokens representing pool's ownership.
    ///         Optional data in extraData may include a minimal amount of
    ///         underwriter tokens expected to be minted for a depositor. There
    ///         are cases when an amount of minted tokens matters for a
    ///         depositor, as tokens might be used in third party exchanges.
    /// @dev This function is a shortcut for approve + deposit.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external {
        require(msg.sender == token, "Only token caller allowed");
        require(
            token == address(collateralToken),
            "Unsupported collateral token"
        );

        uint256 toMint = _calculateTokensToMint(amount);
        if (extraData.length != 0) {
            require(extraData.length == 32, "Unexpected data length");
            uint256 minAmountToMint = abi.decode(extraData, (uint256));
            require(
                minAmountToMint <= toMint,
                "Amount to mint is smaller than the required minimum"
            );
        }

        _deposit(from, amount, toMint);
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints underwriter tokens representing pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @param amountToDeposit Collateral tokens amount that a user deposits to
    ///                        the asset pool
    /// @return The amount of minted underwriter tokens
    function deposit(uint256 amountToDeposit)
        external
        override
        returns (uint256)
    {
        uint256 toMint = _calculateTokensToMint(amountToDeposit);
        _deposit(msg.sender, amountToDeposit, toMint);
        return toMint;
    }

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints at least a minAmountToMint underwriter tokens representing
    ///         pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @param amountToDeposit Collateral tokens amount that a user deposits to
    ///                        the asset pool
    /// @param minAmountToMint Underwriter minimal tokens amount that a user
    ///                        expects to receive in exchange for the deposited
    ///                        collateral tokens
    /// @return The amount of minted underwriter tokens
    function depositWithMin(uint256 amountToDeposit, uint256 minAmountToMint)
        external
        override
        returns (uint256)
    {
        uint256 toMint = _calculateTokensToMint(amountToDeposit);

        require(
            minAmountToMint <= toMint,
            "Amount to mint is smaller than the required minimum"
        );

        _deposit(msg.sender, amountToDeposit, toMint);
        return toMint;
    }

    /// @notice Initiates the withdrawal of collateral and rewards from the
    ///         pool. Must be followed with completeWithdrawal call after the
    ///         withdrawal delay passes. Accepts the amount of underwriter
    ///         tokens representing the share of the pool that should be
    ///         withdrawn. Can be called multiple times increasing the pool share
    ///         to withdraw and resetting the withdrawal initiated timestamp for
    ///         each call. Can be called with 0 covAmount to reset the
    ///         withdrawal initiated timestamp if the underwriter has a pending
    ///         withdrawal. In practice 0 covAmount should be used only to
    ///         initiate the withdrawal again in case one did not complete the
    ///         withdrawal before the withdrawal timeout elapsed.
    /// @dev Before calling this function, underwriter token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    function initiateWithdrawal(uint256 covAmount) external override {
        uint256 pending = pendingWithdrawal[msg.sender];
        require(
            covAmount > 0 || pending > 0,
            "Underwriter token amount must be greater than 0"
        );

        pending += covAmount;
        pendingWithdrawal[msg.sender] = pending;
        /* solhint-disable not-rely-on-time */
        withdrawalInitiatedTimestamp[msg.sender] = block.timestamp;

        emit WithdrawalInitiated(msg.sender, pending, block.timestamp);
        /* solhint-enable not-rely-on-time */

        if (covAmount > 0) {
            underwriterToken.safeTransferFrom(
                msg.sender,
                address(this),
                covAmount
            );
        }
    }

    /// @notice Completes the previously initiated withdrawal for the
    ///         underwriter. Anyone can complete the withdrawal for the
    ///         underwriter. The withdrawal has to be completed before the
    ///         withdrawal timeout elapses. Otherwise, the withdrawal has to
    ///         be initiated again and the underwriter has to wait for the
    ///         entire withdrawal delay again before being able to complete
    ///         the withdrawal.
    /// @return The amount of collateral withdrawn
    function completeWithdrawal(address underwriter)
        external
        override
        returns (uint256)
    {
        /* solhint-disable not-rely-on-time */
        uint256 initiatedAt = withdrawalInitiatedTimestamp[underwriter];
        require(initiatedAt > 0, "No withdrawal initiated for the underwriter");

        uint256 withdrawalDelayEndTimestamp = initiatedAt + withdrawalDelay;
        require(
            withdrawalDelayEndTimestamp < block.timestamp,
            "Withdrawal delay has not elapsed"
        );

        require(
            withdrawalDelayEndTimestamp + withdrawalTimeout >= block.timestamp,
            "Withdrawal timeout elapsed"
        );

        uint256 covAmount = pendingWithdrawal[underwriter];
        uint256 covSupply = underwriterToken.totalSupply();
        delete withdrawalInitiatedTimestamp[underwriter];
        delete pendingWithdrawal[underwriter];

        // slither-disable-next-line reentrancy-events
        rewardsPool.withdraw();

        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        uint256 amountToWithdraw = (covAmount * collateralBalance) / covSupply;

        emit WithdrawalCompleted(
            underwriter,
            amountToWithdraw,
            covAmount,
            block.timestamp
        );
        collateralToken.safeTransfer(underwriter, amountToWithdraw);

        /* solhint-enable not-rely-on-time */
        underwriterToken.burn(covAmount);

        return amountToWithdraw;
    }

    /// @notice Transfers collateral tokens to a new Asset Pool which previously
    ///         was approved by the governance. Upgrade does not have to obey
    ///         withdrawal delay.
    ///         Old underwriter tokens are burned in favor of new tokens minted
    ///         in a new Asset Pool. New tokens are sent directly to the
    ///         underwriter from a new Asset Pool.
    /// @param covAmount Amount of underwriter tokens used to calculate collateral
    ///                  tokens which are transferred to a new asset pool
    /// @param _newAssetPool New Asset Pool address to check validity with the one
    ///                      that was approved by the governance
    function upgradeToNewAssetPool(uint256 covAmount, address _newAssetPool)
        external
    {
        /* solhint-disable not-rely-on-time */
        require(
            address(newAssetPool) != address(0),
            "New asset pool must be assigned"
        );

        require(
            address(newAssetPool) == _newAssetPool,
            "Addresses of a new asset pool must match"
        );

        require(
            covAmount > 0,
            "Underwriter token amount must be greater than 0"
        );

        uint256 covSupply = underwriterToken.totalSupply();

        // slither-disable-next-line reentrancy-events
        rewardsPool.withdraw();

        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        uint256 collateralToTransfer = (covAmount * collateralBalance) /
            covSupply;

        collateralToken.safeApprove(
            address(newAssetPool),
            collateralToTransfer
        );
        // old underwriter tokens are burned in favor of new minted in a new
        // asset pool
        underwriterToken.burnFrom(msg.sender, covAmount);
        // collateralToTransfer will be sent to a new AssetPool and new
        // underwriter tokens will be minted and transferred back to the underwriter
        newAssetPool.depositFor(msg.sender, collateralToTransfer);

        emit AssetPoolUpgraded(
            msg.sender,
            collateralToTransfer,
            covAmount,
            block.timestamp
        );
    }

    /// @notice Allows governance to set a new asset pool so the underwriters
    ///         can move their collateral tokens to a new asset pool without
    ///         having to wait for the withdrawal delay.
    function approveNewAssetPoolUpgrade(IAssetPoolUpgrade _newAssetPool)
        external
        onlyOwner
    {
        require(
            address(_newAssetPool) != address(0),
            "New asset pool can't be zero address"
        );

        newAssetPool = _newAssetPool;

        emit ApprovedAssetPoolUpgrade(address(_newAssetPool));
    }

    /// @notice Allows governance to cancel already approved new asset pool
    ///         in case of some misconfiguration.
    function cancelNewAssetPoolUpgrade() external onlyOwner {
        emit CancelledAssetPoolUpgrade(address(newAssetPool));

        newAssetPool = IAssetPoolUpgrade(address(0));
    }

    /// @notice Allows the coverage pool to demand coverage from the asset hold
    ///         by this pool and send it to the provided recipient address.
    function claim(address recipient, uint256 amount) external onlyOwner {
        emit CoverageClaimed(recipient, amount, block.timestamp);
        rewardsPool.withdraw();
        collateralToken.safeTransfer(recipient, amount);
    }

    /// @notice Lets the contract owner to begin an update of withdrawal delay
    ///         parameter value. Withdrawal delay is the time it takes the
    ///         underwriter to withdraw their collateral and rewards from the
    ///         pool. This is the time that needs to pass between initiating and
    ///         completing the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalDelayUpdate after the required
    ///         governance delay passes. It is up to the contract owner to
    ///         decide what the withdrawal delay value should be but it should
    ///         be long enough so that the possibility of having free-riding
    ///         underwriters escaping from a potential coverage claim by
    ///         withdrawing their positions from the pool is negligible.
    /// @param _newWithdrawalDelay The new value of withdrawal delay
    function beginWithdrawalDelayUpdate(uint256 _newWithdrawalDelay)
        external
        onlyOwner
    {
        newWithdrawalDelay = _newWithdrawalDelay;
        withdrawalDelayChangeInitiated = block.timestamp;
        emit WithdrawalDelayUpdateStarted(_newWithdrawalDelay, block.timestamp);
    }

    /// @notice Lets the contract owner to finalize an update of withdrawal
    ///         delay parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalDelayUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalDelayUpdate()
        external
        onlyOwner
        onlyAfterWithdrawalGovernanceDelay(withdrawalDelayChangeInitiated)
    {
        withdrawalDelay = newWithdrawalDelay;
        emit WithdrawalDelayUpdated(withdrawalDelay);
        newWithdrawalDelay = 0;
        withdrawalDelayChangeInitiated = 0;
    }

    /// @notice Lets the contract owner to begin an update of withdrawal timeout
    ///         parameter value. The withdrawal timeout is the time the
    ///         underwriter has - after the withdrawal delay passed - to
    ///         complete the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalTimeoutUpdate after the required
    ///         governance delay passes. It is up to the contract owner to
    ///         decide what the withdrawal timeout value should be but it should
    ///         be short enough so that the time of free-riding by being able to
    ///         immediately escape from the claim is minimal and long enough so
    ///         that honest underwriters have a possibility to finalize the
    ///         withdrawal. It is all about the right proportions with
    ///         a relation to withdrawal delay value.
    /// @param  _newWithdrawalTimeout The new value of the withdrawal timeout
    function beginWithdrawalTimeoutUpdate(uint256 _newWithdrawalTimeout)
        external
        onlyOwner
    {
        newWithdrawalTimeout = _newWithdrawalTimeout;
        withdrawalTimeoutChangeInitiated = block.timestamp;
        emit WithdrawalTimeoutUpdateStarted(
            _newWithdrawalTimeout,
            block.timestamp
        );
    }

    /// @notice Lets the contract owner to finalize an update of withdrawal
    ///         timeout parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalTimeoutUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalTimeoutUpdate()
        external
        onlyOwner
        onlyAfterWithdrawalGovernanceDelay(withdrawalTimeoutChangeInitiated)
    {
        withdrawalTimeout = newWithdrawalTimeout;
        emit WithdrawalTimeoutUpdated(withdrawalTimeout);
        newWithdrawalTimeout = 0;
        withdrawalTimeoutChangeInitiated = 0;
    }

    /// @notice Grants pool shares by minting a given amount of the underwriter
    ///         tokens for the recipient address. In result, the recipient
    ///         obtains part of the pool ownership without depositing any
    ///         collateral tokens. Shares are usually granted for notifiers
    ///         reporting about various contract state changes.
    /// @dev Can be called only by the contract owner.
    /// @param recipient Address of the underwriter tokens recipient
    /// @param covAmount Amount of the underwriter tokens which should be minted
    function grantShares(address recipient, uint256 covAmount)
        external
        onlyOwner
    {
        rewardsPool.withdraw();
        underwriterToken.mint(recipient, covAmount);
    }

    /// @notice Returns the remaining time that has to pass before the contract
    ///         owner will be able to finalize withdrawal delay update.
    ///         Bear in mind the contract owner may decide to wait longer and
    ///         this value is just an absolute minimum.
    /// @return The time left until withdrawal delay update can be finalized
    function getRemainingWithdrawalDelayUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                withdrawalDelayChangeInitiated,
                withdrawalGovernanceDelay()
            );
    }

    /// @notice Returns the remaining time that has to pass before the contract
    ///         owner will be able to finalize withdrawal timeout update.
    ///         Bear in mind the contract owner may decide to wait longer and
    ///         this value is just an absolute minimum.
    /// @return The time left until withdrawal timeout update can be finalized
    function getRemainingWithdrawalTimeoutUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                withdrawalTimeoutChangeInitiated,
                withdrawalGovernanceDelay()
            );
    }

    /// @notice Returns the current collateral token balance of the asset pool
    ///         plus the reward amount (in collateral token) earned by the asset
    ///         pool and not yet withdrawn to the asset pool.
    /// @return The total value of asset pool in collateral token.
    function totalValue() external view returns (uint256) {
        return collateralToken.balanceOf(address(this)) + rewardsPool.earned();
    }

    /// @notice The time it takes to initiate and complete the withdrawal from
    ///         the pool plus 2 days to make a decision. This governance delay
    ///         should be used for all changes directly affecting underwriter
    ///         positions. This time is a minimum and the governance may choose
    ///         to wait longer before finalizing the update.
    /// @return The withdrawal governance delay in seconds
    function withdrawalGovernanceDelay() public view returns (uint256) {
        return withdrawalDelay + withdrawalTimeout + 2 days;
    }

    /// @dev Calculates underwriter tokens to mint.
    function _calculateTokensToMint(uint256 amountToDeposit)
        internal
        returns (uint256)
    {
        rewardsPool.withdraw();

        uint256 covSupply = underwriterToken.totalSupply();
        uint256 collateralBalance = collateralToken.balanceOf(address(this));

        if (covSupply == 0) {
            return amountToDeposit;
        }

        return (amountToDeposit * covSupply) / collateralBalance;
    }

    function _deposit(
        address depositor,
        uint256 amountToDeposit,
        uint256 amountToMint
    ) internal {
        require(depositor != address(this), "Self-deposit not allowed");

        require(
            amountToMint > 0,
            "Minted tokens amount must be greater than 0"
        );

        emit Deposited(depositor, amountToDeposit, amountToMint);

        underwriterToken.mint(depositor, amountToMint);
        collateralToken.safeTransferFrom(
            depositor,
            address(this),
            amountToDeposit
        );
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IAuction.sol";
import "./Auctioneer.sol";
import "./CoveragePoolConstants.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Auction
/// @notice A contract to run a linear falling-price auction against a diverse
///         basket of assets held in a collateral pool. Auctions are taken using
///         a single asset. Over time, a larger and larger portion of the assets
///         are on offer, eventually hitting 100% of the backing collateral
///         pool. Auctions can be partially filled, and are meant to be amenable
///         to flash loans and other atomic constructions to take advantage of
///         arbitrage opportunities within a single block.
/// @dev  Auction contracts are not meant to be deployed directly, and are
///       instead cloned by an auction factory. Auction contracts clean up and
///       self-destruct on close. An auction that has run the entire length will
///       stay open, forever, or until priced fluctuate and it's eventually
///       profitable to close.
contract Auction is IAuction {
    using SafeERC20 for IERC20;

    struct AuctionStorage {
        IERC20 tokenAccepted;
        Auctioneer auctioneer;
        // the auction price, denominated in tokenAccepted
        uint256 amountOutstanding;
        uint256 amountDesired;
        uint256 startTime;
        uint256 startTimeOffset;
        uint256 auctionLength;
    }

    AuctionStorage public self;
    address public immutable masterContract;

    /// @notice Throws if called by any account other than the auctioneer.
    modifier onlyAuctioneer() {
        //slither-disable-next-line incorrect-equality
        require(
            msg.sender == address(self.auctioneer),
            "Caller is not the auctioneer"
        );

        _;
    }

    constructor() {
        masterContract = address(this);
    }

    /// @notice Initializes auction
    /// @dev At the beginning of an auction, velocity pool depleting rate is
    ///      always 1. It increases over time after a partial auction buy.
    /// @param _auctioneer    the auctioneer contract responsible for seizing
    ///                       funds from the backing collateral pool
    /// @param _tokenAccepted the token with which the auction can be taken
    /// @param _amountDesired the amount denominated in _tokenAccepted. After
    ///                       this amount is received, the auction can close.
    /// @param _auctionLength the amount of time it takes for the auction to get
    ///                       to 100% of all collateral on offer, in seconds.
    function initialize(
        Auctioneer _auctioneer,
        IERC20 _tokenAccepted,
        uint256 _amountDesired,
        uint256 _auctionLength
    ) external {
        require(!isMasterContract(), "Can not initialize master contract");
        //slither-disable-next-line incorrect-equality
        require(self.startTime == 0, "Auction already initialized");
        require(_amountDesired > 0, "Amount desired must be greater than zero");
        require(_auctionLength > 0, "Auction length must be greater than zero");
        self.auctioneer = _auctioneer;
        self.tokenAccepted = _tokenAccepted;
        self.amountOutstanding = _amountDesired;
        self.amountDesired = _amountDesired;
        /* solhint-disable-next-line not-rely-on-time */
        self.startTime = block.timestamp;
        self.startTimeOffset = 0;
        self.auctionLength = _auctionLength;
    }

    /// @notice Takes an offer from an auction buyer.
    /// @dev There are two possible ways to take an offer from a buyer. The first
    ///      one is to buy entire auction with the amount desired for this auction.
    ///      The other way is to buy a portion of an auction. In this case an
    ///      auction depleting rate is increased.
    ///      WARNING: When calling this function directly, it might happen that
    ///      the expected amount of tokens to seize from the coverage pool is
    ///      different from the actual one. There are a couple of reasons for that
    ///      such another bids taking this offer, claims or withdrawals on an
    ///      Asset Pool that are executed in the same block. The recommended way
    ///      for taking an offer is through 'AuctionBidder' contract with
    ///      'takeOfferWithMin' function, where a caller can specify the minimal
    ///      value to receive from the coverage pool in exchange for its amount
    ///      of tokenAccepted.
    /// @param amount the amount the taker is paying, denominated in tokenAccepted.
    ///               In the scenario when amount exceeds the outstanding tokens
    ///               for the auction to complete, only the amount outstanding will
    ///               be taken from a caller.
    function takeOffer(uint256 amount) external override {
        require(amount > 0, "Can't pay 0 tokens");
        uint256 amountToTransfer = Math.min(amount, self.amountOutstanding);
        uint256 amountOnOffer = _onOffer();

        //slither-disable-next-line reentrancy-no-eth
        self.tokenAccepted.safeTransferFrom(
            msg.sender,
            address(self.auctioneer),
            amountToTransfer
        );

        uint256 portionToSeize = (amountOnOffer * amountToTransfer) /
            self.amountOutstanding;

        if (!isAuctionOver() && amountToTransfer != self.amountOutstanding) {
            // Time passed since the auction start or the last takeOffer call
            // with a partial fill.


                uint256 timePassed /* solhint-disable-next-line not-rely-on-time */
             = block.timestamp - self.startTime - self.startTimeOffset;

            // Ratio of the auction's amount included in this takeOffer call to
            // the whole outstanding auction amount.
            uint256 ratioAmountPaid = (CoveragePoolConstants
            .FLOATING_POINT_DIVISOR * amountToTransfer) /
                self.amountOutstanding;
            // We will shift the start time offset and increase the velocity pool
            // depleting rate proportionally to the fraction of the outstanding
            // amount paid in this function call so that the auction can offer
            // no worse financial outcome for the next takers than the current
            // taker has.
            //
            //slither-disable-next-line divide-before-multiply
            self.startTimeOffset =
                self.startTimeOffset +
                ((timePassed * ratioAmountPaid) /
                    CoveragePoolConstants.FLOATING_POINT_DIVISOR);
        }

        self.amountOutstanding -= amountToTransfer;

        //slither-disable-next-line incorrect-equality
        bool isFullyFilled = self.amountOutstanding == 0;

        // inform auctioneer of proceeds and winner. the auctioneer seizes funds
        // from the collateral pool in the name of the winner, and controls all
        // proceeds
        //
        //slither-disable-next-line reentrancy-no-eth
        self.auctioneer.offerTaken(
            msg.sender,
            self.tokenAccepted,
            amountToTransfer,
            portionToSeize,
            isFullyFilled
        );

        //slither-disable-next-line incorrect-equality
        if (isFullyFilled) {
            harikari();
        }
    }

    /// @notice Tears down the auction manually, before its entire amount
    ///         is bought by takers.
    /// @dev Can be called only by the auctioneer which may decide to early
    //       close the auction in case it is no longer needed.
    function earlyClose() external onlyAuctioneer {
        require(self.amountOutstanding > 0, "Auction must be open");

        harikari();
    }

    /// @notice How much of the collateral pool can currently be purchased at
    ///         auction, across all assets.
    /// @dev _onOffer() / FLOATING_POINT_DIVISOR) returns a portion of the
    ///      collateral pool. Ex. if 35% available of the collateral pool,
    ///      then _onOffer() / FLOATING_POINT_DIVISOR) returns 0.35
    /// @return the ratio of the collateral pool currently on offer
    function onOffer() external view override returns (uint256, uint256) {
        return (_onOffer(), CoveragePoolConstants.FLOATING_POINT_DIVISOR);
    }

    function amountOutstanding() external view returns (uint256) {
        return self.amountOutstanding;
    }

    function amountTransferred() external view returns (uint256) {
        return self.amountDesired - self.amountOutstanding;
    }

    /// @dev Delete all storage and destroy the contract. Should only be called
    ///      after an auction has closed.
    function harikari() internal {
        require(!isMasterContract(), "Master contract can not harikari");
        selfdestruct(payable(address(self.auctioneer)));
    }

    function _onOffer() internal view returns (uint256) {
        // when the auction is over, entire pool is on offer
        if (isAuctionOver()) {
            // Down the road, for determining a portion on offer, a value returned
            // by this function will be divided by FLOATING_POINT_DIVISOR. To
            // return the entire pool, we need to return just this divisor in order
            // to get 1.0 ie. FLOATING_POINT_DIVISOR / FLOATING_POINT_DIVISOR = 1.0
            return CoveragePoolConstants.FLOATING_POINT_DIVISOR;
        }

        // How fast portions of the collateral pool become available on offer.
        // It is needed to calculate the right portion value on offer at the
        // given moment before the auction is over.
        // Auction length once set is constant and what changes is the auction's
        // "start time offset" once the takeOffer() call has been processed for
        // partial fill. The auction's "start time offset" is updated every takeOffer().
        // velocityPoolDepletingRate = auctionLength / (auctionLength - startTimeOffset)
        // velocityPoolDepletingRate always starts at 1.0 and then can go up
        // depending on partial offer calls over auction life span to maintain
        // the right ratio between the remaining auction time and the remaining
        // portion of the collateral pool.
        //slither-disable-next-line divide-before-multiply
        uint256 velocityPoolDepletingRate = (CoveragePoolConstants
        .FLOATING_POINT_DIVISOR * self.auctionLength) /
            (self.auctionLength - self.startTimeOffset);

        return
            /* solhint-disable-next-line not-rely-on-time */
            ((block.timestamp - (self.startTime + self.startTimeOffset)) *
                velocityPoolDepletingRate) / self.auctionLength;
    }

    function isAuctionOver() internal view returns (bool) {
        /* solhint-disable-next-line not-rely-on-time */
        return block.timestamp >= self.startTime + self.auctionLength;
    }

    function isMasterContract() internal view returns (bool) {
        return masterContract == address(this);
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./Auction.sol";
import "./CoveragePool.sol";

import "@thesis/solidity-contracts/contracts/clone/CloneFactory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Auctioneer
/// @notice Factory for the creation of new auction clones and receiving proceeds.
/// @dev  We avoid redeployment of auction contracts by using the clone factory.
///       Proxy delegates calls to Auction and therefore does not affect auction state.
///       This means that we only need to deploy the auction contracts once.
///       The auctioneer provides clean state for every new auction clone.
contract Auctioneer is CloneFactory {
    // Holds the address of the auction contract
    // which will be used as a master contract for cloning.
    address public immutable masterAuction;
    mapping(address => bool) public openAuctions;
    uint256 public openAuctionsCount;

    CoveragePool public immutable coveragePool;

    event AuctionCreated(
        address indexed tokenAccepted,
        uint256 amount,
        address auctionAddress
    );
    event AuctionOfferTaken(
        address indexed auction,
        address indexed offerTaker,
        address tokenAccepted,
        uint256 amount,
        uint256 portionToSeize // This amount should be divided by FLOATING_POINT_DIVISOR
    );
    event AuctionClosed(address indexed auction);

    constructor(CoveragePool _coveragePool, address _masterAuction) {
        coveragePool = _coveragePool;
        // slither-disable-next-line missing-zero-check
        masterAuction = _masterAuction;
    }

    /// @notice Informs the auctioneer to seize funds and log appropriate events
    /// @dev This function is meant to be called from a cloned auction. It logs
    ///      "offer taken" and "auction closed" events, seizes funds, and cleans
    ///      up closed auctions.
    /// @param offerTaker      The address of the taker of the auction offer,
    ///                        who will receive the pool's seized funds
    /// @param tokenPaid       The token this auction is denominated in
    /// @param tokenAmountPaid The amount of the token the taker paid
    /// @param portionToSeize  The portion of the pool the taker won at auction.
    ///                        This amount should be divided by FLOATING_POINT_DIVISOR
    ///                        to calculate how much of the pool should be set
    ///                        aside as the taker's winnings.
    /// @param fullyFilled     Indicates whether the auction was taken fully or
    ///                        partially. If auction was fully filled, it is
    ///                        closed. If auction was partially filled, it is
    ///                        sill open and waiting for remaining bids.
    function offerTaken(
        address offerTaker,
        IERC20 tokenPaid,
        uint256 tokenAmountPaid,
        uint256 portionToSeize,
        bool fullyFilled
    ) external {
        require(openAuctions[msg.sender], "Sender isn't an auction");

        emit AuctionOfferTaken(
            msg.sender,
            offerTaker,
            address(tokenPaid),
            tokenAmountPaid,
            portionToSeize
        );

        // actually seize funds, setting them aside for the taker to withdraw
        // from the coverage pool.
        // `portionToSeize` will be divided by FLOATING_POINT_DIVISOR which is
        // defined in Auction.sol
        //
        //slither-disable-next-line reentrancy-no-eth,reentrancy-events,reentrancy-benign
        coveragePool.seizeFunds(offerTaker, portionToSeize);

        Auction auction = Auction(msg.sender);
        if (fullyFilled) {
            onAuctionFullyFilled(auction);

            emit AuctionClosed(msg.sender);
            delete openAuctions[msg.sender];
            openAuctionsCount -= 1;
        } else {
            onAuctionPartiallyFilled(auction);
        }
    }

    /// @notice Opens a new auction against the coverage pool. The auction
    ///         will remain open until filled.
    /// @dev Calls `Auction.initialize` to initialize the instance.
    /// @param tokenAccepted The token with which the auction can be taken
    /// @param amountDesired The amount denominated in _tokenAccepted. After
    ///                      this amount is received, the auction can close.
    /// @param auctionLength The amount of time it takes for the auction to get
    ///                      to 100% of all collateral on offer, in seconds.
    function createAuction(
        IERC20 tokenAccepted,
        uint256 amountDesired,
        uint256 auctionLength
    ) internal returns (address) {
        address cloneAddress = createClone(masterAuction);
        require(cloneAddress != address(0), "Cloned auction address is 0");

        Auction auction = Auction(cloneAddress);
        //slither-disable-next-line reentrancy-benign,reentrancy-events
        auction.initialize(this, tokenAccepted, amountDesired, auctionLength);

        openAuctions[cloneAddress] = true;
        openAuctionsCount += 1;

        emit AuctionCreated(
            address(tokenAccepted),
            amountDesired,
            cloneAddress
        );

        return cloneAddress;
    }

    /// @notice Tears down an open auction with given address immediately.
    /// @dev Can be called by contract owner to early close an auction if it
    ///      is no longer needed. Bear in mind that funds from the early closed
    ///      auction last on the auctioneer contract. Calling code should take
    ///      care of them.
    /// @return Amount of funds transferred to this contract by the Auction
    ///         being early closed.
    function earlyCloseAuction(Auction auction) internal returns (uint256) {
        address auctionAddress = address(auction);

        require(openAuctions[auctionAddress], "Address is not an open auction");

        uint256 amountTransferred = auction.amountTransferred();

        //slither-disable-next-line reentrancy-no-eth,reentrancy-events,reentrancy-benign
        auction.earlyClose();

        emit AuctionClosed(auctionAddress);
        delete openAuctions[auctionAddress];
        openAuctionsCount -= 1;

        return amountTransferred;
    }

    /// @notice Auction lifecycle hook allowing to act on auction closed
    ///         as fully filled. This function is not executed when an auction
    ///         was partially filled. When this function is executed auction is
    ///         already closed and funds from the coverage pool are seized.
    /// @dev Override this function to act on auction closed as fully filled.
    function onAuctionFullyFilled(Auction auction) internal virtual {}

    /// @notice Auction lifecycle hook allowing to act on auction partially
    ///         filled. This function is not executed when an auction
    ///         was fully filled.
    /// @dev Override this function to act on auction partially filled.
    function onAuctionPartiallyFilled(Auction auction) internal view virtual {}
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IAssetPoolUpgrade.sol";
import "./AssetPool.sol";
import "./CoveragePoolConstants.sol";
import "./GovernanceUtils.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Coverage Pool
/// @notice A contract that manages a single asset pool. Handles approving and
///         unapproving of risk managers and allows them to seize funds from the
///         asset pool if they are approved.
/// @dev Coverage pool contract is owned by the governance. Coverage pool is the
///      owner of the asset pool contract.
contract CoveragePool is Ownable {
    AssetPool public immutable assetPool;
    IERC20 public immutable collateralToken;

    bool public firstRiskManagerApproved = false;

    // Currently approved risk managers
    mapping(address => bool) public approvedRiskManagers;
    // Timestamps of risk managers whose approvals have been initiated
    mapping(address => uint256) public riskManagerApprovalTimestamps;

    event RiskManagerApprovalStarted(address riskManager, uint256 timestamp);
    event RiskManagerApprovalCompleted(address riskManager, uint256 timestamp);
    event RiskManagerUnapproved(address riskManager, uint256 timestamp);

    /// @notice Reverts if called by a risk manager that is not approved
    modifier onlyApprovedRiskManager() {
        require(approvedRiskManagers[msg.sender], "Risk manager not approved");
        _;
    }

    constructor(AssetPool _assetPool) {
        assetPool = _assetPool;
        collateralToken = _assetPool.collateralToken();
    }

    /// @notice Approves the first risk manager
    /// @dev Can be called only by the contract owner. Can be called only once.
    ///      Does not require any further calls to any functions.
    /// @param riskManager Risk manager that will be approved
    function approveFirstRiskManager(address riskManager) external onlyOwner {
        require(
            !firstRiskManagerApproved,
            "The first risk manager was approved"
        );
        approvedRiskManagers[riskManager] = true;
        firstRiskManagerApproved = true;
    }

    /// @notice Begins risk manager approval process.
    /// @dev Can be called only by the contract owner and only when the first
    ///      risk manager is already approved. For a risk manager to be
    ///      approved, a call to `finalizeRiskManagerApproval` must follow
    ///      (after a governance delay).
    /// @param riskManager Risk manager that will be approved
    function beginRiskManagerApproval(address riskManager) external onlyOwner {
        require(
            firstRiskManagerApproved,
            "The first risk manager is not yet approved; Please use "
            "approveFirstRiskManager instead"
        );

        require(
            !approvedRiskManagers[riskManager],
            "Risk manager already approved"
        );

        /* solhint-disable-next-line not-rely-on-time */
        riskManagerApprovalTimestamps[riskManager] = block.timestamp;
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerApprovalStarted(riskManager, block.timestamp);
    }

    /// @notice Finalizes risk manager approval process.
    /// @dev Can be called only by the contract owner. Must be preceded with a
    ///      call to beginRiskManagerApproval and a governance delay must elapse.
    /// @param riskManager Risk manager that will be approved
    function finalizeRiskManagerApproval(address riskManager)
        external
        onlyOwner
    {
        require(
            riskManagerApprovalTimestamps[riskManager] > 0,
            "Risk manager approval not initiated"
        );
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - riskManagerApprovalTimestamps[riskManager] >=
                assetPool.withdrawalGovernanceDelay(),
            "Risk manager governance delay has not elapsed"
        );
        approvedRiskManagers[riskManager] = true;
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerApprovalCompleted(riskManager, block.timestamp);
        delete riskManagerApprovalTimestamps[riskManager];
    }

    /// @notice Unapproves an already approved risk manager or cancels the
    ///         approval process of a risk manager (the latter happens if called
    ///         between `beginRiskManagerApproval` and `finalizeRiskManagerApproval`).
    ///         The change takes effect immediately.
    /// @dev Can be called only by the contract owner.
    /// @param riskManager Risk manager that will be unapproved
    function unapproveRiskManager(address riskManager) external onlyOwner {
        require(
            riskManagerApprovalTimestamps[riskManager] > 0 ||
                approvedRiskManagers[riskManager],
            "Risk manager is neither approved nor with a pending approval"
        );
        delete riskManagerApprovalTimestamps[riskManager];
        delete approvedRiskManagers[riskManager];
        /* solhint-disable-next-line not-rely-on-time */
        emit RiskManagerUnapproved(riskManager, block.timestamp);
    }

    /// @notice Approves upgradeability to the new asset pool.
    ///         Allows governance to set a new asset pool so the underwriters
    ///         can move their collateral tokens to a new asset pool without
    ///         having to wait for the withdrawal delay.
    /// @param _newAssetPool New asset pool
    function approveNewAssetPoolUpgrade(IAssetPoolUpgrade _newAssetPool)
        external
        onlyOwner
    {
        assetPool.approveNewAssetPoolUpgrade(_newAssetPool);
    }

    /// @notice Lets the governance to begin an update of withdrawal delay
    ///         parameter value. Withdrawal delay is the time it takes the
    ///         underwriter to withdraw their collateral and rewards from the
    ///         pool. This is the time that needs to pass between initiating and
    ///         completing the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalDelayUpdate after the required
    ///         governance delay passes. It is up to the governance to
    ///         decide what the withdrawal delay value should be but it should
    ///         be long enough so that the possibility of having free-riding
    ///         underwriters escaping from a potential coverage claim by
    ///         withdrawing their positions from the pool is negligible.
    /// @param newWithdrawalDelay The new value of withdrawal delay
    function beginWithdrawalDelayUpdate(uint256 newWithdrawalDelay)
        external
        onlyOwner
    {
        assetPool.beginWithdrawalDelayUpdate(newWithdrawalDelay);
    }

    /// @notice Lets the governance to finalize an update of withdrawal
    ///         delay parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalDelayUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalDelayUpdate() external onlyOwner {
        assetPool.finalizeWithdrawalDelayUpdate();
    }

    /// @notice Lets the governance to begin an update of withdrawal timeout
    ///         parameter value. The withdrawal timeout is the time the
    ///         underwriter has - after the withdrawal delay passed - to
    ///         complete the withdrawal. The change needs to be finalized with
    ///         a call to finalizeWithdrawalTimeoutUpdate after the required
    ///         governance delay passes. It is up to the governance to
    ///         decide what the withdrawal timeout value should be but it should
    ///         be short enough so that the time of free-riding by being able to
    ///         immediately escape from the claim is minimal and long enough so
    ///         that honest underwriters have a possibility to finalize the
    ///         withdrawal. It is all about the right proportions with
    ///         a relation to withdrawal delay value.
    /// @param  newWithdrawalTimeout The new value of the withdrawal timeout
    function beginWithdrawalTimeoutUpdate(uint256 newWithdrawalTimeout)
        external
        onlyOwner
    {
        assetPool.beginWithdrawalTimeoutUpdate(newWithdrawalTimeout);
    }

    /// @notice Lets the governance to finalize an update of withdrawal
    ///         timeout parameter value. This call has to be preceded with
    ///         a call to beginWithdrawalTimeoutUpdate and the governance delay
    ///         has to pass.
    function finalizeWithdrawalTimeoutUpdate() external onlyOwner {
        assetPool.finalizeWithdrawalTimeoutUpdate();
    }

    /// @notice Seizes funds from the coverage pool and puts them aside for the
    ///         recipient to withdraw.
    /// @dev `portionToSeize` value was multiplied by `FLOATING_POINT_DIVISOR`
    ///      for calculation precision purposes. Further calculations in this
    ///      function will need to take this divisor into account.
    /// @param recipient Address that will receive the pool's seized funds
    /// @param portionToSeize Portion of the pool to seize in the range (0, 1]
    ///        multiplied by `FLOATING_POINT_DIVISOR`
    function seizeFunds(address recipient, uint256 portionToSeize)
        external
        onlyApprovedRiskManager
    {
        require(
            portionToSeize > 0 &&
                portionToSeize <= CoveragePoolConstants.FLOATING_POINT_DIVISOR,
            "Portion to seize is not within the range (0, 1]"
        );

        assetPool.claim(recipient, amountToSeize(portionToSeize));
    }

    /// @notice Grants asset pool shares by minting a given amount of the
    ///         underwriter tokens for the recipient address. In result, the
    ///         recipient obtains part of the pool ownership without depositing
    ///         any collateral tokens. Shares are usually granted for notifiers
    ///         reporting about various contract state changes.
    /// @dev Can be called only by an approved risk manager.
    /// @param recipient Address of the underwriter tokens recipient
    /// @param covAmount Amount of the underwriter tokens which should be minted
    function grantAssetPoolShares(address recipient, uint256 covAmount)
        external
        onlyApprovedRiskManager
    {
        assetPool.grantShares(recipient, covAmount);
    }

    /// @notice Returns the time remaining until the risk manager approval
    ///         process can be finalized
    /// @param riskManager Risk manager in the process of approval
    /// @return Remaining time in seconds.
    function getRemainingRiskManagerApprovalTime(address riskManager)
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                riskManagerApprovalTimestamps[riskManager],
                assetPool.withdrawalGovernanceDelay()
            );
    }

    /// @notice Calculates amount of tokens to be seized from the coverage pool.
    /// @param portionToSeize Portion of the pool to seize in the range (0, 1]
    ///        multiplied by FLOATING_POINT_DIVISOR
    function amountToSeize(uint256 portionToSeize)
        public
        view
        returns (uint256)
    {
        return
            (collateralToken.balanceOf(address(assetPool)) * portionToSeize) /
            CoveragePoolConstants.FLOATING_POINT_DIVISOR;
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

library CoveragePoolConstants {
    // This divisor is for precision purposes only. We use this divisor around
    // auction related code to get the precise values without rounding it down
    // when dealing with floating numbers.
    uint256 public constant FLOATING_POINT_DIVISOR = 1e18;
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

library GovernanceUtils {
    /// @notice Gets the time remaining until the governable parameter update
    ///         can be committed.
    /// @param changeTimestamp Timestamp indicating the beginning of the change.
    /// @param delay Governance delay.
    /// @return Remaining time in seconds.
    function getRemainingChangeTime(uint256 changeTimestamp, uint256 delay)
        internal
        view
        returns (uint256)
    {
        require(changeTimestamp > 0, "Change not initiated");
        /* solhint-disable-next-line not-rely-on-time */
        uint256 elapsed = block.timestamp - changeTimestamp;
        if (elapsed >= delay) {
            return 0;
        } else {
            return delay - elapsed;
        }
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Rewards Pool
/// @notice RewardsPool accepts a single reward token and releases it to the
///         AssetPool over time in one week reward intervals. The owner of this
///         contract is the reward distribution address funding it with reward
///         tokens.
contract RewardsPool is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant DURATION = 7 days;

    IERC20 public immutable rewardToken;
    address public immutable assetPool;

    // timestamp of the current reward interval end or the timestamp of the
    // last interval end in case a new reward interval has not been allocated
    uint256 public intervalFinish = 0;
    // rate per second with which reward tokens are unlocked
    uint256 public rewardRate = 0;
    // amount of rewards accumulated and not yet withdrawn from the previous
    // reward interval(s)
    uint256 public rewardAccumulated = 0;
    // the last time information in this contract was updated
    uint256 public lastUpdateTime = 0;

    event RewardToppedUp(uint256 amount);
    event RewardWithdrawn(uint256 amount);

    constructor(
        IERC20 _rewardToken,
        address _assetPool,
        address owner
    ) {
        rewardToken = _rewardToken;
        // slither-disable-next-line missing-zero-check
        assetPool = _assetPool;
        transferOwnership(owner);
    }

    /// @notice Transfers the provided reward amount into RewardsPool and
    ///         creates a new, one-week reward interval starting from now.
    ///         Reward tokens from the previous reward interval that unlocked
    ///         over the time will be available for withdrawal immediately.
    ///         Reward tokens from the previous interval that has not been yet
    ///         unlocked, are added to the new interval being created.
    /// @dev This function can be called only by the owner given that it creates
    ///      a new interval with one week length, starting from now.
    function topUpReward(uint256 reward) external onlyOwner {
        rewardAccumulated = earned();

        /* solhint-disable not-rely-on-time */
        if (block.timestamp >= intervalFinish) {
            // see https://github.com/crytic/slither/issues/844
            // slither-disable-next-line divide-before-multiply
            rewardRate = reward / DURATION;
        } else {
            uint256 remaining = intervalFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / DURATION;
        }
        intervalFinish = block.timestamp + DURATION;
        lastUpdateTime = block.timestamp;
        /* solhint-enable avoid-low-level-calls */

        emit RewardToppedUp(reward);
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
    }

    /// @notice Withdraws all unlocked reward tokens to the AssetPool.
    function withdraw() external {
        uint256 amount = earned();
        rewardAccumulated = 0;
        lastUpdateTime = lastTimeRewardApplicable();
        emit RewardWithdrawn(amount);
        rewardToken.safeTransfer(assetPool, amount);
    }

    /// @notice Returns the amount of earned and not yet withdrawn reward
    /// tokens.
    function earned() public view returns (uint256) {
        return
            rewardAccumulated +
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate);
    }

    /// @notice Returns the timestamp at which a reward was last time applicable.
    ///         When reward interval is pending, returns current block's
    ///         timestamp. If the last reward interval ended and no other reward
    ///         interval had been allocated, returns the last reward interval's
    ///         end timestamp.
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, intervalFinish);
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IRiskManagerV1.sol";
import "./Auctioneer.sol";
import "./Auction.sol";
import "./CoveragePoolConstants.sol";
import "./GovernanceUtils.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title tBTC v1 Deposit contract interface
/// @notice This is an interface with just a few function signatures of a main
///      Deposit contract from tBTC. tBTC deposit contract functions declared in
///      this interface are used by RiskManagerV1 contract to interact with tBTC
///      v1 deposits. For more information about tBTC Deposit please see:
///      https://github.com/keep-network/tbtc/blob/solidity/v1.1.0/solidity/contracts/deposit/Deposit.sol
interface IDeposit {
    function withdrawFunds() external;

    function purchaseSignerBondsAtAuction() external;

    function currentState() external view returns (uint256);

    function lotSizeTbtc() external view returns (uint256);

    function withdrawableAmount() external view returns (uint256);

    function auctionValue() external view returns (uint256);
}

/// @title tBTC v1 deposit token (TDT) interface
/// @notice This is an interface with just a few function signatures of a main
///      contract from tBTC. For more information about tBTC Deposit please see:
///      https://github.com/keep-network/tbtc/blob/solidity/v1.1.0/solidity/contracts/system/TBTCDepositToken.sol
interface ITBTCDepositToken {
    function exists(uint256 _tokenId) external view returns (bool);
}

/// @title Signer bonds swap strategy
/// @notice This interface is meant to abstract the underlying signer bonds
///         swap strategy and make it interchangeable for the governance.
///         Risk manager uses the strategy to swap ETH from tBTC deposit
///         purchased signer bonds back into collateral token accepted by
///         coverage pool.
interface ISignerBondsSwapStrategy {
    /// @notice Notifies the strategy about signer bonds purchase.
    /// @param amount Amount of purchased signer bonds.
    function onSignerBondsPurchased(uint256 amount) external;
}

/// @title Risk Manager for tBTC v1
/// @notice Risk Manager is a smart contract with the exclusive right to claim
///         coverage from the coverage pool. Demanding coverage is akin to
///         filing a claim in traditional insurance and processing your own
///         claim. The risk manager holds an incredibly privileged position,
///         because the ability to claim coverage of an arbitrarily large
///         position could bankrupt the coverage pool.
///         tBTC v1 risk manager demands coverage by opening an auction for TBTC
///         and liquidating portion of the coverage pool when tBTC v1 deposit is
///         in liquidation and signer bonds on offer reached the specific
///         threshold. In practice, it means no one is willing to purchase
///         signer bonds for that deposit on tBTC side.
contract RiskManagerV1 is IRiskManagerV1, Auctioneer, Ownable {
    using SafeERC20 for IERC20;
    using RiskManagerV1Rewards for RiskManagerV1Rewards.Storage;

    /// @notice Governance delay that needs to pass before any risk manager
    ///         parameter change initiated by the governance takes effect.
    uint256 public constant GOVERNANCE_DELAY = 12 hours;

    // See https://github.com/keep-network/tbtc/blob/v1.1.0/solidity/contracts/deposit/DepositStates.sol
    uint256 public constant DEPOSIT_FRAUD_LIQUIDATION_IN_PROGRESS_STATE = 9;
    uint256 public constant DEPOSIT_LIQUIDATION_IN_PROGRESS_STATE = 10;
    uint256 public constant DEPOSIT_LIQUIDATED_STATE = 11;

    /// @notice Coverage pool auction will not be opened if the deposit's bond
    ///         auction offers a bond percentage lower than this threshold.
    ///         Risk manager should open a coverage pool auction for only those
    //          tBTC deposits that nobody else is willing to purchase bonds
    ///         from. The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    uint256 public bondAuctionThreshold; // percentage
    uint256 public newBondAuctionThreshold;
    uint256 public bondAuctionThresholdChangeInitiated;

    /// @notice The length with which every new auction is opened. Auction length
    ///         is the amount of time it takes for the auction to get to 100%
    ///         of all collateral on offer, in seconds. This parameter value
    ///         should be updated and kept up to date based on the coverage pool
    ///         TVL and tBTC v1 minimum lot size allowed so that a new auction
    ///         does not liquidate too much too early. Auction length is the
    ///         same, no matter tBTC deposit lot size.
    ///         The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    uint256 public auctionLength;
    uint256 public newAuctionLength;
    uint256 public auctionLengthChangeInitiated;

    /// @notice The strategy used to swap ETH from tBTC deposit purchased signer
    ///         bonds into an asset accepted by coverage pool as collateral.
    ///         The value can be updated by the governance in two steps.
    ///         First step is to begin the update process with the new value
    ///         and the second step is to finalize it after
    ///         `GOVERNANCE_DELAY` has passed.
    ISignerBondsSwapStrategy public signerBondsSwapStrategy;
    ISignerBondsSwapStrategy public newSignerBondsSwapStrategy;
    uint256 public signerBondsSwapStrategyInitiated;

    IERC20 public immutable tbtcToken;
    ITBTCDepositToken public immutable tbtcDepositToken;

    /// @notice TBTC surplus collected from early closed auctions.
    ///         When tBTC deposit gets liquidated outside of coverage pools and
    ///         an auction was opened earlier by the risk manager for that
    ///         deposit, it might happen that the auction was partially filled
    ///         and some TBTC from that auction has accumulated. In such a case,
    ///         TBTC surplus left on the risk manager can be used to purchase
    ///         signer bonds from another liquidating tBTC deposit in the future
    ///         assuming enough surplus will accumulate up to that point.
    uint256 public tbtcSurplus;

    /// @notice Keeps track of notifier rewards for those calling
    ///         `notifyLiquidation` and `notifyLiquidated`.
    RiskManagerV1Rewards.Storage public rewards;

    // deposit in liquidation => opened coverage pool auction
    mapping(address => address) public depositToAuction;
    // opened coverage pool auction => deposit in liquidation
    mapping(address => address) public auctionToDeposit;

    event NotifiedLiquidated(address indexed deposit, address notifier);
    event NotifiedLiquidation(address indexed deposit, address notifier);

    event BondAuctionThresholdUpdateStarted(
        uint256 bondAuctionThreshold,
        uint256 timestamp
    );
    event BondAuctionThresholdUpdated(uint256 bondAuctionThreshold);

    event AuctionLengthUpdateStarted(uint256 auctionLength, uint256 timestamp);
    event AuctionLengthUpdated(uint256 auctionLength);

    event SignerBondsSwapStrategyUpdateStarted(
        address indexed signerBondsSwapStrategy,
        uint256 timestamp
    );
    event SignerBondsSwapStrategyUpdated(
        address indexed signerBondsSwapStrategy
    );

    event LiquidationNotifierRewardUpdateStarted(
        uint256 liquidationNotifierReward,
        uint256 timestamp
    );
    event LiquidationNotifierRewardUpdated(uint256 liquidationNotifierReward);

    event LiquidatedNotifierRewardUpdateStarted(
        uint256 liquidatedNotifierReward,
        uint256 timestamp
    );
    event LiquidatedNotifierRewardUpdated(uint256 liquidatedNotifierReward);

    /// @notice Reverts if called before the governance delay elapses.
    /// @param changeInitiatedTimestamp Timestamp indicating the beginning
    ///        of the change.
    modifier onlyAfterGovernanceDelay(uint256 changeInitiatedTimestamp) {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - changeInitiatedTimestamp >= GOVERNANCE_DELAY,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Reverts if called by any account other than the current signer
    ///         bonds swap strategy.
    modifier onlySignerBondsSwapStrategy() {
        require(
            msg.sender == address(signerBondsSwapStrategy),
            "Caller is not the signer bonds swap strategy"
        );
        _;
    }

    constructor(
        IERC20 _tbtcToken,
        ITBTCDepositToken _tbtcDepositToken,
        CoveragePool _coveragePool,
        ISignerBondsSwapStrategy _signerBondsSwapStrategy,
        address _masterAuction,
        uint256 _auctionLength,
        uint256 _bondAuctionThreshold
    ) Auctioneer(_coveragePool, _masterAuction) {
        tbtcToken = _tbtcToken;
        tbtcDepositToken = _tbtcDepositToken;
        signerBondsSwapStrategy = _signerBondsSwapStrategy;
        auctionLength = _auctionLength;
        bondAuctionThreshold = _bondAuctionThreshold;
    }

    /// @notice Receives ETH from tBTC for purchasing and withdrawing deposit
    ///         signer bonds.
    //slither-disable-next-line locked-ether
    receive() external payable {}

    /// @notice Notifies the risk manager about tBTC deposit in liquidation
    ///         state for which signer bonds on offer passed the threshold
    ///         expected by the risk manager. In practice, it means no one else
    ///         is willing to purchase signer bonds from that deposit so the
    ///         risk manager should open an auction to collect TBTC and purchase
    ///         those bonds liquidating part of the coverage pool. If there is
    ///         enough TBTC surplus from earlier auctions accumulated by the
    ///         risk manager, bonds are purchased right away without opening an
    ///         auction. Notifier calling this function receives a share in the
    ///         coverage pool as a reward - underwriter tokens are transferred
    ///         to the notifier's address.
    /// @param  depositAddress liquidating tBTC deposit address
    function notifyLiquidation(address depositAddress) external override {
        require(
            tbtcDepositToken.exists(uint256(uint160(depositAddress))),
            "Address is not a deposit contract"
        );

        IDeposit deposit = IDeposit(depositAddress);
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit is not in liquidation state"
        );

        require(
            depositToAuction[depositAddress] == address(0),
            "Already notified on the deposit in liquidation"
        );

        require(
            deposit.auctionValue() >=
                (address(deposit).balance * bondAuctionThreshold) / 100,
            "Deposit bond auction percentage is below the threshold level"
        );

        uint256 lotSizeTbtc = deposit.lotSizeTbtc();

        emit NotifiedLiquidation(depositAddress, msg.sender);

        // Reward the notifier by giving them some share of the pool.
        if (rewards.liquidationNotifierReward > 0) {
            // slither-disable-next-line reentrancy-benign
            coveragePool.grantAssetPoolShares(
                msg.sender,
                rewards.liquidationNotifierReward
            );
        }

        // If the surplus can cover the deposit liquidation cost, liquidate
        // that deposit directly without the auction process.
        if (tbtcSurplus >= lotSizeTbtc) {
            tbtcSurplus -= lotSizeTbtc;
            liquidateDeposit(deposit);
            return;
        }

        // slither-disable-next-line reentrancy-no-eth
        address auctionAddress = createAuction(
            tbtcToken,
            lotSizeTbtc,
            auctionLength
        );
        depositToAuction[depositAddress] = auctionAddress;
        auctionToDeposit[auctionAddress] = depositAddress;
    }

    /// @notice Notifies the risk manager about tBTC deposit liquidated outside
    ///         the coverage pool for which the risk manager opened an auction
    ///         earlier (as a result of `notifyLiquidation` call). Function
    ///         closes the auction early and collects TBTC surplus from the
    ///         auction in case the auction was partially taken before the
    ///         deposit got liquidated. Notifier calling this function receives
    ///         a share in the coverage pool as a reward - underwriter tokens
    ///         are transferred to the notifier's address.
    /// @param  depositAddress liquidated tBTC Deposit address
    function notifyLiquidated(address depositAddress) external override {
        require(
            depositToAuction[depositAddress] != address(0),
            "No auction for given deposit"
        );

        IDeposit deposit = IDeposit(depositAddress);
        require(
            deposit.currentState() == DEPOSIT_LIQUIDATED_STATE,
            "Deposit is not in liquidated state"
        );
        emit NotifiedLiquidated(depositAddress, msg.sender);

        Auction auction = Auction(depositToAuction[depositAddress]);

        delete depositToAuction[depositAddress];
        delete auctionToDeposit[address(auction)];
        uint256 amountTransferred = earlyCloseAuction(auction);

        // Add auction's transferred amount to the surplus pool.
        // slither-disable-next-line reentrancy-benign
        tbtcSurplus += amountTransferred;

        // Reward the notifier by giving them some share of the pool.
        if (rewards.liquidatedNotifierReward > 0) {
            coveragePool.grantAssetPoolShares(
                msg.sender,
                rewards.liquidatedNotifierReward
            );
        }
    }

    /// @notice Begins the bond auction threshold update process. The value of
    ///         the threshold must not be greater than 100. The threshold should
    ///         be high enough so that the possibility of purchasing signer
    ///         bonds outside of coverage pools after opening an auction is
    ///         minimal.
    /// @dev Can be called only by the contract owner.
    /// @param _newBondAuctionThreshold New bond auction threshold in percent
    function beginBondAuctionThresholdUpdate(uint256 _newBondAuctionThreshold)
        external
        onlyOwner
    {
        require(
            _newBondAuctionThreshold <= 100,
            "Bond auction threshold must be lower or equal to 100"
        );
        newBondAuctionThreshold = _newBondAuctionThreshold;
        /* solhint-disable-next-line not-rely-on-time */
        bondAuctionThresholdChangeInitiated = block.timestamp;
        /* solhint-disable not-rely-on-time */
        emit BondAuctionThresholdUpdateStarted(
            _newBondAuctionThreshold,
            block.timestamp
        );
    }

    /// @notice Finalizes the bond auction threshold update process.
    /// @dev Can be called only by the contract owner, after the the
    ///      governance delay elapses.
    function finalizeBondAuctionThresholdUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(bondAuctionThresholdChangeInitiated)
    {
        bondAuctionThreshold = newBondAuctionThreshold;
        emit BondAuctionThresholdUpdated(bondAuctionThreshold);
        bondAuctionThresholdChangeInitiated = 0;
        newBondAuctionThreshold = 0;
    }

    /// @notice Begins the auction length update process. The auction length
    ///         should be adjusted very carefully. Total value locked of the
    ///         coverage pool and minimum possible auction amount need to be
    ///         taken into account. The goal is to find a "sweet spot" for
    ///         auction length, not making it too short (which leads to big
    ///         sums of coverage pool become available in a short time) and not
    ///         making it too long (which leads to bidders waiting for too long
    ///         until it will makes sense for them to bid on an auction).
    /// @dev Can be called only by the contract owner.
    /// @param _newAuctionLength New auction length in seconds
    function beginAuctionLengthUpdate(uint256 _newAuctionLength)
        external
        onlyOwner
    {
        newAuctionLength = _newAuctionLength;
        /* solhint-disable-next-line not-rely-on-time */
        auctionLengthChangeInitiated = block.timestamp;
        /* solhint-disable-next-line not-rely-on-time */
        emit AuctionLengthUpdateStarted(_newAuctionLength, block.timestamp);
    }

    /// @notice Finalizes the auction length update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeAuctionLengthUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(auctionLengthChangeInitiated)
    {
        auctionLength = newAuctionLength;
        emit AuctionLengthUpdated(newAuctionLength);
        newAuctionLength = 0;
        auctionLengthChangeInitiated = 0;
    }

    /// @notice Begins the liquidation notifier reward update process.
    ///         Total value locked of the coverage pool and the cost of calling
    ///         `notifyLiquidation` needs to be taken into account so that the
    ///         call incentive is attractive enough and at the same time it does
    ///         not offer to much value held the coverage pool.
    /// @dev Can be called only by the contract owner.
    /// @param _newLiquidationNotifierReward New liquidation notifier reward
    function beginLiquidationNotifierRewardUpdate(
        uint256 _newLiquidationNotifierReward
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        emit LiquidationNotifierRewardUpdateStarted(
            _newLiquidationNotifierReward,
            block.timestamp
        );

        rewards.beginLiquidationNotifierRewardUpdate(
            _newLiquidationNotifierReward
        );
    }

    /// @notice Finalizes the liquidation notifier reward update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeLiquidationNotifierRewardUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            rewards.liquidationNotifierRewardChangeInitiated
        )
    {
        emit LiquidationNotifierRewardUpdated(
            rewards.newLiquidationNotifierReward
        );

        rewards.finalizeLiquidationNotifierRewardUpdate();
    }

    /// @notice Begins the liquidated notifier reward update process.
    ///         Total value locked of the coverage pool and the cost of calling
    ///         `notifyLiquidated` needs to be taken into account so that the
    ///         call incentive is attractive enough and at the same time it does
    ///         not offer to much value held the coverage pool.
    /// @param _newLiquidatedNotifierReward New liquidated notifier reward
    function beginLiquidatedNotifierRewardUpdate(
        uint256 _newLiquidatedNotifierReward
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        emit LiquidatedNotifierRewardUpdateStarted(
            _newLiquidatedNotifierReward,
            block.timestamp
        );

        rewards.beginLiquidatedNotifierRewardUpdate(
            _newLiquidatedNotifierReward
        );
    }

    /// @notice Finalizes the liquidated notifier reward update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses
    function finalizeLiquidatedNotifierRewardUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            rewards.liquidatedNotifierRewardChangeInitiated
        )
    {
        emit LiquidatedNotifierRewardUpdated(
            rewards.newLiquidatedNotifierReward
        );

        rewards.finalizeLiquidatedNotifierRewardUpdate();
    }

    /// @notice Begins the signer bonds swap strategy update process.
    /// @dev Must be followed by a finalizeSignerBondsSwapStrategyUpdate after
    ///      the governance delay elapses.
    /// @param _newSignerBondsSwapStrategy The new signer bonds swap strategy
    function beginSignerBondsSwapStrategyUpdate(
        ISignerBondsSwapStrategy _newSignerBondsSwapStrategy
    ) external onlyOwner {
        require(
            address(_newSignerBondsSwapStrategy) != address(0),
            "Invalid signer bonds swap strategy address"
        );
        newSignerBondsSwapStrategy = _newSignerBondsSwapStrategy;
        /* solhint-disable-next-line not-rely-on-time */
        signerBondsSwapStrategyInitiated = block.timestamp;
        emit SignerBondsSwapStrategyUpdateStarted(
            address(_newSignerBondsSwapStrategy),
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp
        );
    }

    /// @notice Finalizes the signer bonds swap strategy update.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeSignerBondsSwapStrategyUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(signerBondsSwapStrategyInitiated)
    {
        signerBondsSwapStrategy = newSignerBondsSwapStrategy;
        emit SignerBondsSwapStrategyUpdated(
            address(newSignerBondsSwapStrategy)
        );
        delete newSignerBondsSwapStrategy;
        signerBondsSwapStrategyInitiated = 0;
    }

    /// @notice Withdraws the given amount of accumulated signer bonds.
    /// @dev Can be called only by the signer bonds swap strategy itself.
    ///      This method should typically be used as part of the swap logic.
    ///      Third-party calls may block funds on the strategy contract in case
    ///      that strategy is not able to perform the swap.
    /// @param amount Amount of signer bonds being withdrawn
    function withdrawSignerBonds(uint256 amount)
        external
        override
        onlySignerBondsSwapStrategy
    {
        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls
        (bool success, ) = address(signerBondsSwapStrategy).call{value: amount}(
            ""
        );
        require(success, "Failed to send Ether");
        /* solhint-enable avoid-low-level-calls */
    }

    /// @notice Get the time remaining until the bond auction threshold
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingBondAuctionThresholdUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                bondAuctionThresholdChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the auction length parameter
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingAuctionLengthUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                auctionLengthChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the liquidation notifier reward
    ///         parameter can be updated.
    /// @return Remaining time in seconds.
    function getRemainingLiquidationNotifierRewardUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                rewards.liquidationNotifierRewardChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the liquidated notifier reward
    ///         amount parameter can be updated.
    /// @return Remaining time in seconds.
    function getRemainingLiquidatedNotifierRewardUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                rewards.liquidatedNotifierRewardChangeInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @notice Get the time remaining until the signer bonds swap strategy
    ///         can be changed.
    /// @return Remaining time in seconds.
    function getRemainingSignerBondsSwapStrategyChangeTime()
        external
        view
        returns (uint256)
    {
        return
            GovernanceUtils.getRemainingChangeTime(
                signerBondsSwapStrategyInitiated,
                GOVERNANCE_DELAY
            );
    }

    /// @return True if there are open auctions managed by the risk manager.
    ///         Returns false otherwise.
    function hasOpenAuctions() external view override returns (bool) {
        return openAuctionsCount > 0;
    }

    /// @return Current value of the liquidation notifier reward.
    function liquidationNotifierReward() external view returns (uint256) {
        return rewards.liquidationNotifierReward;
    }

    /// @return Current value of the liquidated notifier reward.
    function liquidatedNotifierReward() external view returns (uint256) {
        return rewards.liquidatedNotifierReward;
    }

    /// @notice Cleans up auction and deposit data and executes deposit liquidation.
    /// @dev This function is invoked when Auctioneer determines that an auction
    ///      is eligible to be closed. It cannot be called on-demand outside
    ///      the Auctioneer contract. By the time this function is called, all
    ///      the TBTC tokens for the coverage pool auction should be transferred
    ///      to this contract in order to buy signer bonds.
    /// @param auction Coverage pool auction
    function onAuctionFullyFilled(Auction auction) internal override {
        IDeposit deposit = IDeposit(auctionToDeposit[address(auction)]);
        // Make sure the deposit was not liquidated outside of Coverage Pool
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit liquidation is not in progress"
        );

        delete depositToAuction[address(deposit)];
        delete auctionToDeposit[address(auction)];

        liquidateDeposit(deposit);
    }

    /// @notice Purchases ETH from signer bonds and swaps obtained funds
    ///         using the underlying signer bonds swap strategy.
    /// @dev By the time this function is called, TBTC token balance for this
    ///      contract should be enough to buy signer bonds.
    /// @param deposit TBTC deposit which should be liquidated.
    function liquidateDeposit(IDeposit deposit) internal {
        uint256 approvedAmount = deposit.lotSizeTbtc();
        tbtcToken.safeApprove(address(deposit), approvedAmount);

        // Purchase signers bonds ETH with TBTC acquired from the auction or
        // taken from the surplus pool.
        deposit.purchaseSignerBondsAtAuction();

        uint256 withdrawableAmount = deposit.withdrawableAmount();
        deposit.withdrawFunds();

        signerBondsSwapStrategy.onSignerBondsPurchased(withdrawableAmount);
    }

    /// @notice Reverts if the deposit for which the auction was created is no
    ///         longer in the liquidation state. This could happen if signer
    ///         bonds were purchased from tBTC deposit directly, outside of
    ///         coverage pool auction.
    /// @dev This function is invoked when the auctioneer is informed about the
    ///      results of an auction and the auction was partially filled.
    /// @param auction Address of an auction whose deposit needs to be checked.
    function onAuctionPartiallyFilled(Auction auction) internal view override {
        IDeposit deposit = IDeposit(auctionToDeposit[address(auction)]);
        // Make sure the deposit was not liquidated outside of Coverage Pool
        require(
            isDepositLiquidationInProgress(deposit),
            "Deposit liquidation is not in progress"
        );
    }

    function isDepositLiquidationInProgress(IDeposit deposit)
        internal
        view
        returns (bool)
    {
        uint256 state = deposit.currentState();

        return (state == DEPOSIT_LIQUIDATION_IN_PROGRESS_STATE ||
            state == DEPOSIT_FRAUD_LIQUIDATION_IN_PROGRESS_STATE);
    }
}

/// @title RiskManagerV1Rewards
/// @notice Contains logic responsible for calculating notifier rewards for
///         both deposit liquidation start and deposit liquidated events.
///         All parameters can be updated using a two-phase process.
/// @dev The client contract should take care of authorizations or governance
///      delays according to their needs.
/* solhint-disable-next-line ordering */
library RiskManagerV1Rewards {
    struct Storage {
        // Amount of COV tokens which should be given as reward for the
        // notifier reporting about the start of deposit liquidation process.
        uint256 liquidationNotifierReward;
        uint256 newLiquidationNotifierReward;
        uint256 liquidationNotifierRewardChangeInitiated;
        // Amount of COV tokens which should be given as reward for the
        // notifier reporting about a deposit being liquidated outside of the
        // coverage pool.
        uint256 liquidatedNotifierReward;
        uint256 newLiquidatedNotifierReward;
        uint256 liquidatedNotifierRewardChangeInitiated;
    }

    /// @notice Begins the liquidation notifier reward update process.
    /// @param _newLiquidationNotifierReward New liquidation notifier reward.
    function beginLiquidationNotifierRewardUpdate(
        Storage storage self,
        uint256 _newLiquidationNotifierReward
    ) internal {
        /* solhint-disable not-rely-on-time */
        self.newLiquidationNotifierReward = _newLiquidationNotifierReward;
        self.liquidationNotifierRewardChangeInitiated = block.timestamp;
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the liquidation notifier reward update process.
    function finalizeLiquidationNotifierRewardUpdate(Storage storage self)
        internal
    {
        self.liquidationNotifierReward = self.newLiquidationNotifierReward;
        self.newLiquidationNotifierReward = 0;
        self.liquidationNotifierRewardChangeInitiated = 0;
    }

    /// @notice Begins the liquidated notifier reward update process.
    /// @param _newLiquidatedNotifierReward New liquidated notifier reward
    function beginLiquidatedNotifierRewardUpdate(
        Storage storage self,
        uint256 _newLiquidatedNotifierReward
    ) internal {
        /* solhint-disable not-rely-on-time */
        self.newLiquidatedNotifierReward = _newLiquidatedNotifierReward;
        self.liquidatedNotifierRewardChangeInitiated = block.timestamp;
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the liquidated notifier reward update process.
    function finalizeLiquidatedNotifierRewardUpdate(Storage storage self)
        internal
    {
        self.liquidatedNotifierReward = self.newLiquidatedNotifierReward;
        self.newLiquidatedNotifierReward = 0;
        self.liquidatedNotifierRewardChangeInitiated = 0;
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./interfaces/IRiskManagerV1.sol";
import "./RiskManagerV1.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SignerBondsManualSwap
/// @notice ETH purchased by the risk manager from tBTC signer bonds needs to be
///         swapped and deposited back to the coverage pool as collateral.
///         SignerBondsManualSwap strategy allows the governance to withdraw
///         the bonds from the risk manager and do the swap manually.
contract SignerBondsManualSwap is ISignerBondsSwapStrategy, Ownable {
    /// @notice Receive ETH upon withdrawal of risk manager's signer bonds.
    receive() external payable {}

    /// @notice Notifies the strategy about signer bonds purchase.
    /// @param amount Amount of purchased signer bonds.
    function onSignerBondsPurchased(uint256 amount) external override {}

    /// @notice Withdraws collected bonds to the given target address.
    /// @dev Can be called by the governance only.
    /// @param recipient Arbitrary recipient address chosen by the governance
    ///        that will be responsible for swapping ETH and depositing
    ///        collateral to the coverage pool.
    function withdrawSignerBonds(
        IRiskManagerV1 riskManager,
        uint256 amount,
        address payable recipient
    ) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(
            amount <= address(riskManager).balance,
            "Amount exceeds risk manager balance"
        );
        require(recipient != address(0), "Invalid recipient address");

        riskManager.withdrawSignerBonds(amount);

        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,arbitrary-send
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to send Ether");
        /* solhint-enable avoid-low-level-calls */
    }
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "@thesis/solidity-contracts/contracts/token/ERC20WithPermit.sol";

/// @title  UnderwriterToken
/// @notice Underwriter tokens represent an ownership share in the underlying
///         collateral of the asset-specific pool. Underwriter tokens are minted
///         when a user deposits ERC20 tokens into asset-specific pool and they
///         are burned when a user exits the position. Underwriter tokens
///         natively support meta transactions. Users can authorize a transfer
///         of their underwriter tokens with a signature conforming EIP712
///         standard instead of an on-chain transaction from their address.
///         Anyone can submit this signature on the user's behalf by calling the
///         permit function, as specified in EIP2612 standard, paying gas fees,
///         and possibly performing other actions in the same transaction.
contract UnderwriterToken is ERC20WithPermit {
    constructor(string memory _name, string memory _symbol)
        ERC20WithPermit(_name, _symbol)
    {}
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/// @title Asset Pool interface
/// @notice Asset Pool accepts a single ERC20 token as collateral, and returns
///         an underwriter token. For example, an asset pool might accept deposits
///         in KEEP in return for covKEEP underwriter tokens. Underwriter tokens
///         represent an ownership share in the underlying collateral of the
///         Asset Pool.
interface IAssetPool {
    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints underwriter tokens representing pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @return The amount of minted underwriter tokens
    function deposit(uint256 amount) external returns (uint256);

    /// @notice Accepts the given amount of collateral token as a deposit and
    ///         mints at least a minAmountToMint underwriter tokens representing
    ///         pool's ownership.
    /// @dev Before calling this function, collateral token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    /// @return The amount of minted underwriter tokens
    function depositWithMin(uint256 amountToDeposit, uint256 minAmountToMint)
        external
        returns (uint256);

    /// @notice Initiates the withdrawal of collateral and rewards from the pool.
    /// @dev Before calling this function, underwriter token needs to have the
    ///      required amount accepted to transfer to the asset pool.
    function initiateWithdrawal(uint256 covAmount) external;

    /// @notice Completes the previously initiated withdrawal for the
    ///         underwriter.
    /// @return The amount of collateral withdrawn
    function completeWithdrawal(address underwriter) external returns (uint256);
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/// @title Asset Pool upgrade interface
/// @notice Interface that has to be implemented by an Asset Pool accepting
///         upgrades from another asset pool.
interface IAssetPoolUpgrade {
    /// @notice Accepts the given underwriter with collateral tokens amount as a
    ///         deposit. In exchange new underwriter tokens will be calculated,
    ///         minted and then transferred back to the underwriter.
    function depositFor(address underwriter, uint256 amount) external;
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/// @title Auction interface
/// @notice Auction runs a linear falling-price auction against a diverse
///         basket of assets held in a collateral pool. Auctions are taken using
///         a single asset. Over time, a larger and larger portion of the assets
///         are on offer, eventually hitting 100% of the backing collateral
interface IAuction {
    /// @notice Takes an offer from an auction buyer. There are two possible
    ///         ways to take an offer from a buyer. The first one is to buy
    ///         entire auction with the amount desired for this auction.
    ///         The other way is to buy a portion of an auction. In this case an
    ///         auction depleting rate is increased.
    /// @dev The implementation is not guaranteed to be protecting against
    ///      frontrunning. See `AuctionBidder` for an example protection.
    function takeOffer(uint256 amount) external;

    /// @notice How much of the collateral pool can currently be purchased at
    ///         auction, across all assets.
    /// @return The ratio of the collateral pool currently on offer and divisor
    ///         for precision purposes.
    function onOffer() external view returns (uint256, uint256);
}

// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

/// @title Interface for tBTC v1 Risk Manager
/// @notice Risk Manager is a smart contract with the exclusive right to claim
///         coverage from the coverage pool. Demanding coverage is akin to
///         filing a claim in traditional insurance and processing your own
///         claim. The risk manager holds an incredibly privileged position,
///         because the ability to claim coverage of an arbitrarily large
///         position could bankrupt the coverage pool.
///         tBTC v1 risk manager demands coverage by opening an auction for TBTC
///         and liquidating portion of the coverage pool when tBTC v1 deposit is
///         in liquidation and signer bonds on offer reached the specific
///         threshold. In practice, it means no one is willing to purchase
///         signer bonds for that deposit on tBTC side.
interface IRiskManagerV1 {
    /// @notice Notifies the risk manager about tBTC deposit in liquidation
    ///         state for which signer bonds on offer passed the threshold
    ///         expected by the risk manager. In practice, it means no one else
    ///         is willing to purchase signer bonds from that deposit so the
    ///         risk manager should open an auction to collect TBTC and purchase
    ///         those bonds liquidating part of the coverage pool. If there is
    ///         enough TBTC surplus from earlier auctions accumulated by the
    ///         risk manager, bonds are purchased right away without opening an
    ///         auction. Notifier calling this function receives a share in the
    ///         coverage pool as a reward - underwriter tokens are transferred
    ///         to the notifier's address.
    /// @param  depositAddress liquidating tBTC deposit address
    function notifyLiquidation(address depositAddress) external;

    /// @notice Notifies the risk manager about tBTC deposit liquidated outside
    ///         the coverage pool for which the risk manager opened an auction
    ///         earlier (as a result of `notifyLiquidation` call). Function
    ///         closes the auction early and collects TBTC surplus from the
    ///         auction in case the auction was partially taken before the
    ///         deposit got liquidated. Notifier calling this function receives
    ///         a share in the coverage pool as a reward - underwriter tokens
    ///         are transferred to the notifier's address.
    /// @param  depositAddress liquidated tBTC Deposit address
    function notifyLiquidated(address depositAddress) external;

    /// @notice Withdraws the given amount of accumulated signer bonds.
    /// @dev Usually used by `ISignerBondsSwapStrategy` implementations.
    /// @param amount Amount of signer bonds being withdrawn.
    function withdrawSignerBonds(uint256 amount) external;

    /// @notice Returns true if there are open auctions managed by the risk
    ///         manager. Returns false otherwise.
    /// @dev Usually used by `ISignerBondsSwapStrategy` implementations.
    function hasOpenAuctions() external view returns (bool);
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}