/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/GSN/[email protected]

pragma solidity >=0.6.0 <0.8.0;


// File @openzeppelin/contracts/introspection/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/math/[email protected]

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

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


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * Note: The ERC-165 identifier for this interface is 0x.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return (uint256) The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if the message caller's account balance does not have enough tokens to spend.
     * @dev Emits the {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The account where the transferred tokens will be deposited to.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to` via the approval mechanism.
     * @dev Reverts if the caller has not been approved by `from` for at least `value`.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Emits the {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The account where the transferred tokens will be withdrawn from.
     * @param to The account where the transferred tokens will be deposited to.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title Interface for commonly used additional ERC20 interfaces.
 */
interface IERC20Detailed {
    /**
     * Returns the name of the token. E.g. "My Token".
     * @return The name of the token.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol of the token. E.g. "HIX".
     */
    function symbol() external view returns (string memory);

    /**
     * Returns the number of decimals the token uses. E.g. `8`, means to divide the token amount by `100000000` to get its user representation.
     * @return The number of decimals the token uses.
     */
    function decimals() external view returns (uint8);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

/*
The MIT License (MIT)

Copyright (c) 2021 Corporation Limited

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.
*/

pragma solidity 0.6.8;

/**
 * @title Interface for additional ERC20 allowance features.
 */
interface IERC20Allowance {
    /**
     * @notice Increases the allowance granted by the message caller to `_spender` by `_value`.
     * @dev Reverts if `_spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event with an updated allowance for `_spender`.
     * @param _spender (address) The account whose allowance is being increased by the message caller.
     * @param _value (uint256) The allowance amount increase.
     * @return (bool) True if the allowance increase succeeds, false otherwise.
     */
    function increaseAllowance(address _spender, uint256 _value) external returns (bool);

    /**
     * @notice Decreases the allowance granted by the message caller to `_spender` by `_value`.
     * @dev Reverts if `_spender` is the zero address.
     * @dev Reverts if `_spender` has an allowance with the message caller for less than `_value`.
     * @dev Emits the {IERC20-Approval} event with an updated allowance for `_spender`.
     * @param _spender (address) The account whose allowance is being decreased by the message caller.
     * @param _value (uint256) The allowance amount decrease.
     * @return (bool) True if the allowance decrease succeeds, false otherwise.
     */
    function decreaseAllowance(address _spender, uint256 _value) external returns (bool);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/* is ERC20, ERC165 */
interface IERC20SafeTransfers {
    /*
     * Note: the ERC-165 identifier for this interface is 0x.
     * 0x ===
     *   bytes4(keccak256('safeTransfer(address,uint256,bytes)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) ^
     */

    /**
     * Transfers tokens from the caller to `to`. If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than the sender's balance.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * Transfers tokens from `from` to another address, using the allowance mechanism.
     *  If this address is a contract, then calls `onERC20Received(address,address,uint256,bytes)` on it.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `value` is greater than `from`'s balance.
     * @dev Reverts if the sender does not have at least `value` allowance by `from`.
     * @dev Reverts if `to` is a contract which does not implement `onERC20Received(address,address,uint256,bytes)`.
     * @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` returns a wrong value.
     * @dev Emits an {IERC20-Transfer} event.
     * @param from The address which owns the tokens to be transferred.
     * @param to The address for the tokens to be transferred to.
     * @param amount The amount of tokens to be transferred.
     * @param data Optional additional data with no specified format, to be passed to the receiver contract.
     * @return true.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @dev Interface for ERC20 with multi transfer
 */
interface IERC20MultiTransfer {
    /**
     * Moves multiple `amounts` tokens from the caller's account to each of `recipients`.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if the caller has an insufficient balance.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function multiTransfer(address[] calldata recipients, uint256[] calldata amounts) external returns (bool);

    /**
     * Moves multiple `amounts` tokens from an account to each of `recipients`, using the approval mechanism.
     * @dev Reverts if `recipients` and `amounts` have different lengths.
     * @dev Reverts if one of `recipients` is the zero address.
     * @dev Reverts if `from` has an insufficient balance.
     * @dev Reverts if the sender does not have at least the sum of all `amounts` as allowance by `from`.
     * @dev Emits an {IERC20-Transfer} event for each individual transfer.
     * @dev Emits an {IERC20-Approval} event.
     * @param from The address which owns the tokens to be transferred.
     * @param recipients the list of recipients to transfer the tokens to.
     * @param amounts the amounts of tokens to transfer to each of `recipients`.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function multiTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external returns (bool);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @dev Interface for allowing approvals to be made via ECDSA `secp256k1` signatures.
 * See https://eips.ethereum.org/EIPS/eip-2612
 */
interface IERC2612 {
    /**
     * Note: the ERC-165 identifier for this interface is 0x.
     * 0x ===
     *   bytes4(keccak256('permit(address,address,uint256,uint256,uint8,bytes32,bytes32)')) ^
     *   bytes4(keccak256('nonces(address)')) ^
     *   bytes4(keccak256('DOMAIN_SEPARATOR()'))
     */

    /**
     * @dev Sets `value` as the allowance of `spender` over the tokens of `owner`, given `owner` account's signed approval
     *  (permit signature).
     *
     * IMPORTANT: The standard ERC-20 race condition for approvals applies to `permit()` as well:
     * https://swcregistry.io/docs/SWC-114
     *
     * @dev Reverts if `owner` is the zero address.
     * @dev Reverts if the current blocktime is > `deadline`.
     * @dev Reverts if `r`, `s`, and `v` is not a valid `secp256k1` signature from `owner`.
     * @dev Emits an {IERC20-Approval} event.
     * @param owner The token owner granting the allowance to `spender`.
     * @param spender The token spender being granted the allowance by `owner`.
     * @param value The token amount of the allowance.
     * @param deadline The deadline from which the permit signature is no longer valid.
     * @param v Permit signature v parameter
     * @param r Permit signature r parameter.
     * @param s Permis signature s parameter.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current permit signature nonce of `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns a 256-bit EIP-712 encoded hash struct of domain-specific information, used to distinguish permit
     *  signatures across different contracts and chains. It is designed to prevent replay attacks from other domains.
     *
     * A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:
     *
     *  keccak256(
     *      abi.encode(
     *          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
     *          keccak256(bytes(name)),
     *          keccak256(bytes(version)),
     *          chainId,
     *          address(this)))
     *
     * where
     *  - `name` (string) is the ERC-20 token name.
     *  - `version` (string) refers to the ERC-20 token contract version.
     *  - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.
     *  - `verifyingContract` (address) is the ERC-20 token contract address.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/* is ERC165 */
interface IERC20Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x.
     * 0x ===
     *   bytes4(keccak256('onERC20Received(address,address,uint256,bytes)')) ^
     */

    /**
     * Handles the receipt of ERC20 tokens.
     * @param sender The initiator of the transfer.
     * @param from The address which transferred the tokens.
     * @param value The amount of tokens transferred.
     * @param data Optional additional data with no specified format.
     * @return bytes4 `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`
     */
    function onERC20Received(
        address sender,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;











/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is IERC165, Context, IERC20, IERC20Detailed, IERC20Allowance, IERC20MultiTransfer, IERC20SafeTransfers, IERC2612 {
    // using SafeMath for uint256;
    using Address for address;

    // bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))
    bytes4 internal constant _ERC20_RECEIVED = 0x4fc35859;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable override DOMAIN_SEPARATOR;

    mapping(address => uint256) public override nonces;

    string internal _name;
    string internal _symbol;
    uint8 internal immutable _decimals;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Detailed).interfaceId ||
            interfaceId == 0x06fdde03 || // bytes4(keccak256("name()"))
            interfaceId == 0x95d89b41 || // bytes4(keccak256("symbol()"))
            interfaceId == 0x313ce567 || // bytes4(keccak256("decimals()"))
            interfaceId == type(IERC20Allowance).interfaceId ||
            interfaceId == type(IERC20MultiTransfer).interfaceId ||
            interfaceId == type(IERC20SafeTransfers).interfaceId ||
            interfaceId == type(IERC2612).interfaceId;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /////////////////////////////////////////// ERC20 ///////////////////////////////////////

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     * - `spender` cannot be the zero address. // TODO update
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /**
     * @dev See {IERC20Allowance-increaseAllowance}.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address");
        address owner = _msgSender();
        uint256 allowance_ = _allowances[owner][spender];
        uint256 newAllowance = allowance_ + addedValue;
        require(newAllowance >= allowance_, "ERC20: allowance overflow");
        _allowances[owner][spender] = newAllowance;
        emit Approval(owner, spender, newAllowance);
        return true;
    }

    /**
     * @dev See {IERC20Allowance-decreaseAllowance}.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address");
        _decreaseAllowance(_msgSender(), spender, subtractedValue);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        _transferFrom(_msgSender(), from, to, value);
        return true;
    }

    /////////////////////////////////////////// ERC20MultiTransfer ///////////////////////////////////////

    /**
     * See {IERC20MultiTransfer-multiTransfer(address[],uint256[])}.
     */
    function multiTransfer(address[] calldata recipients, uint256[] calldata amounts) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == amounts.length, "ERC20: inconsistent arrays");
        address sender = _msgSender();
        for (uint256 i = 0; i != length; ++i) {
            _transfer(sender, recipients[i], amounts[i]);
        }
        return true;
    }

    /**
     * See {IERC20MultiTransfer-multiTransferFrom(address,address[],uint256[])}.
     */
    function multiTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata values
    ) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");
        address sender = _msgSender();
        for (uint256 i = 0; i != length; ++i) {
            _transferFrom(sender, from, recipients[i], values[i]);
        }
        return true;
    }

    /////////////////////////////////////////// ERC20SafeTransfers ///////////////////////////////////////

    /**
     * See {IERC20Safe-safeTransfer(address,uint256,bytes)}.
     */
    function safeTransfer(
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, sender, amount, data) == _ERC20_RECEIVED, "ERC20: transfer refused");
        }
        return true;
    }

    /**
     * See {IERC20Safe-safeTransferFrom(address,address,uint256,bytes)}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        _transferFrom(sender, from, to, amount);
        if (to.isContract()) {
            require(IERC20Receiver(to).onERC20Received(sender, from, amount, data) == _ERC20_RECEIVED, "ERC20: transfer refused");
        }
        return true;
    }

    /////////////////////////////////////////// ERC20Permit ///////////////////////////////////////

    /**
     * See {IERC2612-permit(address,address,uint256,uint256,uint8,bytes32,bytes32)}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override {
        require(owner != address(0), "ERC20: zero address owner");
        require(block.timestamp <= deadline, "ERC20: expired permit");
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "ERC20: invalid permit");
        _approve(owner, spender, value);
    }

    /////////////////////////////////////////// Internal Functions ///////////////////////////////////////

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(0), "ERC20: zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 subtractedValue
    ) internal {
        uint256 allowance_ = _allowances[owner][spender];
        if (allowance_ != type(uint256).max && subtractedValue != 0) {
            // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
            uint256 newAllowance = allowance_ - subtractedValue;
            require(newAllowance <= allowance_, "ERC20: insufficient allowance");
            _allowances[owner][spender] = newAllowance;
            allowance_ = newAllowance;
        }
        emit Approval(owner, spender, allowance_);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        require(to != address(0), "ERC20: zero address");
        uint256 balance = _balances[from];
        require(balance >= value, "ERC20: insufficient balance");
        _balances[from] = balance - value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _transferFrom(
        address sender,
        address from,
        address to,
        uint256 value
    ) internal {
        if (sender != from) {
            _decreaseAllowance(from, sender, value);
        }
        _transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal virtual {
        require(to != address(0), "ERC20: zero address");
        uint256 supply = _totalSupply;
        uint256 newSupply = supply + value;
        require(newSupply >= supply, "ERC20: supply overflow");
        _totalSupply = newSupply;
        _balances[to] += value; // balance cannot overflow if supply does not
        emit Transfer(address(0), to, value);
    }

    function _batchMint(address[] memory recipients, uint256[] memory values) internal virtual {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");
        uint256 supply = _totalSupply;
        for (uint256 i = 0; i != length; ++i) {
            address to = recipients[i];
            require(to != address(0), "ERC20: zero address");
            uint256 value = values[i];
            uint256 newSupply = supply + value;
            require(newSupply >= supply, "ERC20: supply overflow");
            supply = newSupply;
            _balances[to] += value; // balance cannot overflow if supply does not
            emit Transfer(address(0), to, value);
        }
        _totalSupply = supply;
    }
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @dev Interface for burnable ERC20
 */
interface IERC20Burnable {
    /**
     * Burns `value` tokens from the message sender, decreasing the total supply.
     * @dev Reverts if the sender owns less than `value` tokens.
     * @dev Emits a {IERC20-Transfer} event with `_to` set to the zero address.
     * @param value the amount of tokens to burn.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function burn(uint256 value) external returns (bool);

    /**
     * Burns `value` tokens from `from`, using the allowance mechanism and decreasing the total supply.
     * @dev Reverts if `from` owns less than `value` tokens.
     * @dev Reverts if the message sender is not approved by `from` for at least `value` tokens.
     * @dev Emits a {IERC20-Transfer} event with `_to` set to the zero address.
     * @dev Emits a {IERC20-Approval} event (non-standard).
     * @param from the account to burn the tokens from.
     * @param value the amount of tokens to burn.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function burnFrom(address from, uint256 value) external returns (bool);
}


// File @animoca/ethereum-contracts-erc20_base-5.0.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;


/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20Burnable is ERC20, IERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version
    ) public ERC20(name, symbol, decimals, version) {}

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Burns `amount` tokens, decreasing the total supply.
     * @dev Reverts if the sender owns less than `amount` tokens.
     * @dev Emits a {IERC20-Transfer} event with `to` set to the zero address.
     * @param amount the amount of tokens to burn.
     */
    function burn(uint256 amount) public virtual override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /**
     * Burns `amount` tokens from `sender`, decreasing the total supply.
     * @dev Reverts if `sender` is the zero address.
     * @dev Reverts if `sender` owns less than `amount` tokens.
     * @dev Reverts if the message sender is not approved by `sender` for at least `amount` tokens.
     * @dev Emits a {IERC20-Transfer} event with `to` set to the zero address.
     * @dev Emits a {IERC20-Approval} event (non-standard).
     * @param from the account to burn the tokens from.
     * @param value the amount of tokens to burn.
     */
    function burnFrom(address from, uint256 value) public virtual override returns (bool) {
        address sender = _msgSender();
        if (sender != from) {
            _decreaseAllowance(from, sender, value);
        }
        _burn(from, value);
        return true;
    }

    function _burn(address from, uint256 value) internal virtual {
        uint256 balance = _balances[from];
        require(balance >= value, "ERC20: insufficient balance");
        _balances[from] = balance - value;
        _totalSupply -= value; // will not underflow if balance does not
        emit Transfer(from, address(0), value);
    }
}


// File contracts/solc-0.6/token/ERC20/TOWERChest.sol

pragma solidity 0.6.8;

/**
 * @title TOWERChest
 * A burnable ERC-20 token contract for Crazy Defense Heroes (CDH). TOWER Chests are tokens that can be burned to obtain CDH NFTs.
 * @dev TWR.BRNZ for Bronze chests.
 * @dev TWR.SLVR for Silver chests.
 * @dev TWR.GOLD for Gold chests.
 */
contract TOWERChest is ERC20Burnable {
    /**
     * Constructor.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Number of decimals the token uses.
     * @param version Signing domain version used for IERC2612 permit signatures.
     * @param holder Account to mint the initial total supply to.
     * @param totalSupply Total supply amount to mint to the message caller.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version,
        address holder,
        uint256 totalSupply
    ) public ERC20Burnable(name, symbol, decimals, version) {
        _mint(holder, totalSupply);
    }
}