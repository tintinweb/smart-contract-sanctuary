/**
 *Submitted for verification at Etherscan.io on 2021-05-07
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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, basic interface
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * Note: The ERC-165 identifier for this interface is 0x36372b07.
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
     * @return The total token supply.
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
     * @dev Emits an {IERC20-Transfer} event.
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
     * @dev Emits an {IERC20-Transfer} event.
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
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, optional extension: Detailed
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xa219a025.
 */
interface IERC20Detailed {
    /**
     * Returns the name of the token. E.g. "My Token".
     * Note: the ERC-165 identifier for this interface is 0x06fdde03.
     * @return The name of the token.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol of the token. E.g. "HIX".
     * Note: the ERC-165 identifier for this interface is 0x95d89b41.
     * @return The symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * Returns the number of decimals used to display the balances.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract.
     * Note: the ERC-165 identifier for this interface is 0x313ce567.
     * @return The number of decimals used to display the balances.
     */
    function decimals() external view returns (uint8);
}


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, optional extension: Allowance
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0xd5b86388.
 */
interface IERC20Allowance {
    /**
     * Increases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender`'s allowance overflows.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being increased by the message caller.
     * @param value The allowance amount increase.
     * @return True if the allowance increase succeeds, false otherwise.
     */
    function increaseAllowance(address spender, uint256 value) external returns (bool);

    /**
     * Decreases the allowance granted by the sender to `spender` by `value`.
     *  This is an alternative to {approve} that can be used as a mitigation for
     *  problems described in {IERC20-approve}.
     * @dev Reverts if `spender` is the zero address.
     * @dev Reverts if `spender` has an allowance with the message caller for less than `value`.
     * @dev Emits an {IERC20-Approval} event with an updated allowance for `spender`.
     * @param spender The account whose allowance is being decreased by the message caller.
     * @param value The allowance amount decrease.
     * @return True if the allowance decrease succeeds, false otherwise.
     */
    function decreaseAllowance(address spender, uint256 value) external returns (bool);
}


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, optional extension: Safe Transfers
 * Note: the ERC-165 identifier for this interface is 0x53f41a97.
 */
interface IERC20SafeTransfers {
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, optional extension: Multi Transfers
 * Note: the ERC-165 identifier for this interface is 0xd5b86388.
 */
interface IERC20MultiTransfers {
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, ERC1046 optional extension: Metadata
 * See https://eips.ethereum.org/EIPS/eip-1046
 * Note: the ERC-165 identifier for this interface is 0x3c130d90.
 */
interface IERC20Metadata {
    /**
     * Returns a distinct Uniform Resource Identifier (URI) for the token metadata.
     * @return a distinct Uniform Resource Identifier (URI) for the token metadata.
     */
    function tokenURI() external view returns (string memory);
}


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, ERC2612 optional extension: permit – 712-signed approvals
 * @dev Interface for allowing ERC20 approvals to be made via ECDSA `secp256k1` signatures.
 * See https://eips.ethereum.org/EIPS/eip-2612
 * Note: the ERC-165 identifier for this interface is 0x9d8ff7da.
 */
interface IERC20Permit {
    /**
     * Sets `value` as the allowance of `spender` over the tokens of `owner`, given `owner` account's signed permit.
     * @dev WARNING: The standard ERC-20 race condition for approvals applies to `permit()` as well: https://swcregistry.io/docs/SWC-114
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
     * Returns the current permit nonce of `owner`.
     * @param owner the address to check the nonce of.
     * @return the current permit nonce of `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * Returns the EIP-712 encoded hash struct of the domain-specific information for permits.
     *
     * @dev A common ERC-20 permit implementation choice for the `DOMAIN_SEPARATOR` is:
     *
     *  keccak256(
     *      abi.encode(
     *          keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
     *          keccak256(bytes(name)),
     *          keccak256(bytes(version)),
     *          chainId,
     *          address(this)))
     *
     *  where
     *   - `name` (string) is the ERC-20 token name.
     *   - `version` (string) refers to the ERC-20 token contract version.
     *   - `chainId` (uint256) is the chain ID to which the ERC-20 token contract is deployed to.
     *   - `verifyingContract` (address) is the ERC-20 token contract address.
     *
     * @return the EIP-712 encoded hash struct of the domain-specific information for permits.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, Receiver
 * See https://eips.ethereum.org/EIPS/eip-20
 * Note: the ERC-165 identifier for this interface is 0x4fc35859.
 */
interface IERC20Receiver {
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;












/**
 * @dev Implementation of the {IERC20} interface.
 */
contract ERC20 is IERC165, Context, IERC20, IERC20Detailed, IERC20Metadata, IERC20Allowance, IERC20MultiTransfers, IERC20SafeTransfers, IERC20Permit {
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
    string internal _tokenURI;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version,
        string memory tokenURI
    ) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _tokenURI = tokenURI;

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

    /////////////////////////////////////////// ERC165 ///////////////////////////////////////

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Detailed).interfaceId ||
            interfaceId == 0x06fdde03 || // bytes4(keccak256("name()"))
            interfaceId == 0x95d89b41 || // bytes4(keccak256("symbol()"))
            interfaceId == 0x313ce567 || // bytes4(keccak256("decimals()"))
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC20Allowance).interfaceId ||
            interfaceId == type(IERC20MultiTransfers).interfaceId ||
            interfaceId == type(IERC20SafeTransfers).interfaceId ||
            interfaceId == type(IERC20Permit).interfaceId;
    }

    /////////////////////////////////////////// ERC20Detailed ///////////////////////////////////////

    /// @dev See {IERC20Detailed-name}.
    function name() public view override returns (string memory) {
        return _name;
    }

    /// @dev See {IERC20Detailed-symbol}.
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /// @dev See {IERC20Detailed-decimals}.
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /////////////////////////////////////////// ERC20Metadata ///////////////////////////////////////

    /// @dev See {IERC20Metadata-tokenURI}.
    function tokenURI() public view override returns (string memory) {
        return _tokenURI;
    }

    /////////////////////////////////////////// ERC20 ///////////////////////////////////////

    /// @dev See {IERC20-totalSupply}.
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev See {IERC20-balanceOf}.
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @dev See {IERC20-allowance}.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        if (owner == spender) {
            return type(uint256).max;
        }
        return _allowances[owner][spender];
    }

    /// @dev See {IERC20-approve}.
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

    /////////////////////////////////////////// ERC20 Allowance ///////////////////////////////////////

    /// @dev See {IERC20Allowance-increaseAllowance}.
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

    /// @dev See {IERC20Allowance-decreaseAllowance}.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        require(spender != address(0), "ERC20: zero address");
        _decreaseAllowance(_msgSender(), spender, subtractedValue);
        return true;
    }

    /// @dev See {IERC20-transfer}.
    function transfer(address to, uint256 value) public virtual override returns (bool) {
        _transfer(_msgSender(), to, value);
        return true;
    }

    /// @dev See {IERC20-transferFrom}.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        _transferFrom(_msgSender(), from, to, value);
        return true;
    }

    /////////////////////////////////////////// ERC20MultiTransfer ///////////////////////////////////////

    /// @dev See {IERC20MultiTransfer-multiTransfer(address[],uint256[])}.
    function multiTransfer(address[] calldata recipients, uint256[] calldata amounts) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == amounts.length, "ERC20: inconsistent arrays");
        address sender = _msgSender();
        for (uint256 i = 0; i != length; ++i) {
            _transfer(sender, recipients[i], amounts[i]);
        }
        return true;
    }

    /// @dev See {IERC20MultiTransfer-multiTransferFrom(address,address[],uint256[])}.
    function multiTransferFrom(
        address from,
        address[] calldata recipients,
        uint256[] calldata values
    ) external virtual override returns (bool) {
        uint256 length = recipients.length;
        require(length == values.length, "ERC20: inconsistent arrays");
        uint256 total;
        for (uint256 i = 0; i != length; ++i) {
            uint256 value = values[i];
            _transfer(from, recipients[i], value);
            total += value; // cannot overflow, else it would mean thann from's balance underflowed first
        }

        _decreaseAllowance(from, _msgSender(), total);

        return true;
    }

    /////////////////////////////////////////// ERC20SafeTransfers ///////////////////////////////////////

    /// @dev See {IERC20Safe-safeTransfer(address,uint256,bytes)}.
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

    /// @dev See {IERC20Safe-safeTransferFrom(address,address,uint256,bytes)}.
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

    /// @dev See {IERC2612-permit(address,address,uint256,uint256,uint8,bytes32,bytes32)}.
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
        if (owner == spender) return;

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
        _decreaseAllowance(from, sender, value);
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

    function _burn(address from, uint256 value) internal virtual {
        uint256 balance = _balances[from];
        require(balance >= value, "ERC20: insufficient balance");
        _balances[from] = balance - value;
        _totalSupply -= value; // will not underflow if balance does not
        emit Transfer(from, address(0), value);
    }

    function _burnFrom(address from, uint256 value) internal virtual {
        _decreaseAllowance(from, _msgSender(), value);
        _burn(from, value);
    }
}


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;

/**
 * @title ERC20 Token Standard, optional extension: Burnable
 * Note: the ERC-165 identifier for this interface is 0x3b5a0bf8.
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


// File @animoca/ethereum-contracts-erc20_base-5.1.0/contracts/token/ERC20/[email protected]

pragma solidity 0.6.8;


/**
 * @title ERC20 Fungible Token Contract, burnable version.
 */
contract ERC20Burnable is ERC20, IERC20Burnable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version,
        string memory tokenURI
    ) public ERC20(name, symbol, decimals, version, tokenURI) {}

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20Burnable).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC20Burnable-burn(uint256)}.
    function burn(uint256 amount) public virtual override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    /// @dev See {IERC20Burnable-burnFrom(address,uint256)}.
    function burnFrom(address from, uint256 value) public virtual override returns (bool) {
        _burnFrom(from, value);
        return true;
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
contract TOWERChest is ERC20Burnable, Ownable {
    /**
     * Constructor.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param decimals Number of decimals the token uses.
     * @param version Signing domain version used for IERC2612 permit signatures.
     * @param tokenURI The URI for the token metadata.
     * @param holder Account to mint the initial total supply to.
     * @param totalSupply Total supply amount to mint to the message caller.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version,
        string memory tokenURI,
        address holder,
        uint256 totalSupply
    ) public ERC20Burnable(name, symbol, decimals, version, tokenURI) {
        _mint(holder, totalSupply);
    }

    /**
     * Updates the token metadata URI.
     * @dev Reverts if the sender is not the contract owner.
     * @param tokenURI_ the new token metdata URI.
     */
    function updateTokenURI(string calldata tokenURI_) external {
        require(_msgSender() == owner(), "TOWERChest: not the owner");
        _tokenURI = tokenURI_;
    }
}