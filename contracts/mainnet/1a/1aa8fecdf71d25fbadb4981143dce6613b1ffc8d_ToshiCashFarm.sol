/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-01
*/

pragma solidity ^0.6.0;

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

pragma solidity ^0.6.0;

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

pragma solidity >=0.6.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(
            isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract CanTransferRole is Context {
    using Roles for Roles.Role;

    event CanTransferAdded(address indexed account);
    event CanTransferRemoved(address indexed account);

    Roles.Role private _canTransfer;

    constructor() internal {
        _addCanTransfer(_msgSender());
    }

    modifier onlyCanTransfer() {
        require(
            canTransfer(_msgSender()),
            "CanTransferRole: caller does not have the CanTransfer role"
        );
        _;
    }

    function canTransfer(address account) public view returns (bool) {
        return _canTransfer.has(account);
    }

    function addCanTransfer(address account) public onlyCanTransfer {
        _addCanTransfer(account);
    }

    function renounceCanTransfer() public {
        _removeCanTransfer(_msgSender());
    }

    function _addCanTransfer(address account) internal {
        _canTransfer.add(account);
        emit CanTransferAdded(account);
    }

    function _removeCanTransfer(address account) internal {
        _canTransfer.remove(account);
        emit CanTransferRemoved(account);
    }
}


// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// File: node_modules\@openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// File: node_modules\@openzeppelin\contracts\token\ERC1155\IERC1155MetadataURI.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: node_modules\@openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}



// File: node_modules\@openzeppelin\contracts\introspection\ERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}





// File: @openzeppelin\contracts\token\ERC1155\ERC1155.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;








/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substition, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri) public {
        _setURI(uri);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: node_modules\@openzeppelin\contracts\utils\EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: @openzeppelin\contracts\access\AccessControl.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) internal virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts\common\AccessControlMixin.sol

pragma solidity 0.6.6;


contract AccessControlMixin is AccessControl {
    string private _revertMsg;
    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            _revertMsg
        );
        _;
    }
}




library Strings {
  // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d,
    string memory _e
  ) internal pure returns (string memory) {
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(
      _ba.length + _bb.length + _bc.length + _bd.length + _be.length
    );
    bytes memory babcde = bytes(abcde);
    uint256 k = 0;
    for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
  }

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c,
    string memory _d
  ) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, _d, '');
  }

  function strConcat(
    string memory _a,
    string memory _b,
    string memory _c
  ) internal pure returns (string memory) {
    return strConcat(_a, _b, _c, '', '');
  }

  function strConcat(string memory _a, string memory _b)
    internal
    pure
    returns (string memory)
  {
    return strConcat(_a, _b, '', '', '');
  }

  function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
  {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
      bstr[k--] = bytes1(uint8(48 + (_i % 10)));
      _i /= 10;
    }
    return string(bstr);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC1155Tradable is
  ERC1155,
  AccessControlMixin
{
  using Strings for string;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");

  address proxyRegistryAddress;
  uint256 internal _currentTokenID = 0;
  mapping(uint256 => address) public creators;
  mapping(uint256 => uint256) public tokenSupply;
  mapping(uint256 => uint256) public tokenMaxSupply;
  // Contract name
  string public name;
  // Contract symbol
  string public symbol;

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  ) public ERC1155('https://api.toshimon.io/cards/') {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function addWhitelistAdmin(address account) public virtual only(DEFAULT_ADMIN_ROLE) {
    grantRole(WHITELIST_ADMIN_ROLE,account);
  }

  function addMinter(address account) public virtual only(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE,account);
  }

  function removeWhitelistAdmin(address account) public virtual only(DEFAULT_ADMIN_ROLE) {
    revokeRole(WHITELIST_ADMIN_ROLE,account);
  }

  function removeMinter(address account) public virtual only(DEFAULT_ADMIN_ROLE) {
    revokeRole(MINTER_ROLE,account);
  }

  function uri(uint256 _id) public  view virtual override returns (string memory) {
    require(_exists(_id), 'ERC721Tradable#uri: NONEXISTENT_TOKEN');
    return Strings.strConcat(uri(_id), Strings.uint2str(_id));
  }

  /**
   * @dev Returns the total quantity for a token ID
   * @param _id uint256 ID of the token to query
   * @return amount of token in existence
   */
  function totalSupply(uint256 _id) public view virtual returns (uint256) {
    return tokenSupply[_id];
  }


  /**
   * @dev Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI)
    public
    virtual
     only(WHITELIST_ADMIN_ROLE)
  {
    _setURI(_newBaseMetadataURI);
  }

  function setMaxSupply(uint256 _id, uint256 _maxSupply)
    public
    only(WHITELIST_ADMIN_ROLE)
  {
    tokenMaxSupply[_id] = _maxSupply;
  }

  function create(
    uint256 _maxSupply,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external virtual only(WHITELIST_ADMIN_ROLE) returns (uint256 tokenId) {
    require(
      _initialSupply <= _maxSupply,
      'Initial supply cannot be more than max supply'
    );
    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;

    if (bytes(_uri).length > 0) {
      emit URI(_uri, _id);
    }

    if (_initialSupply != 0) _mint(msg.sender, _id, _initialSupply, _data);
    tokenSupply[_id] = _initialSupply;
    tokenMaxSupply[_id] = _maxSupply;
    return _id;
  }
  
  function createBatch(
    uint256  _timesCreated,   
    uint256  _maxSupply
  
  ) external virtual only(WHITELIST_ADMIN_ROLE){
    uint256 _id;
    for (uint i = 0; i < _timesCreated; i++) {

        _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        tokenMaxSupply[_id] = _maxSupply;
    }
  }

  /**
   * @dev Mints some amount of tokens to an address
   * @param _to          Address of the future owner of the token
   * @param _id          Token ID to mint
   * @param _quantity    Amount of tokens to mint
   * @param _data        Data to pass if receiver is contract
   */
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public virtual only(MINTER_ROLE) {
    uint256 tokenId = _id;
    uint256 newSupply = tokenSupply[tokenId].add(_quantity);
    require(newSupply <= tokenMaxSupply[tokenId], 'Max supply reached');
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] = tokenSupply[_id].add(_quantity);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings - The Beano of NFTs
   */
  function isApprovedForAll(address _owner, address _operator)
    public
    view
    virtual
    override
    returns (bool isOperator)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  /**
   * @dev Returns whether the specified token exists by checking to see if it has a creator
   * @param _id uint256 ID of the token to query the existence of
   * @return bool whether the token exists
   */
  function _exists(uint256 _id) internal view virtual returns (bool) {
    return creators[_id] != address(0);
  }

  /**
   * @dev calculates the next token ID based on value of _currentTokenID
   * @return uint256 for the next token ID
   */
  function _getNextTokenID() internal virtual view returns (uint256) {
    return _currentTokenID.add(1);
  }

  /**
   * @dev increments the value of _currentTokenID
   */
  function _incrementTokenTypeId() internal virtual {
    _currentTokenID++;
  }
    /**
   * @dev Returns the max quantity for a token ID
   * @param _id uint256 ID of the token to query
   * @return amount of token in existence
   */
  function maxSupply(uint256 _id) public view returns (uint256) {
    return tokenMaxSupply[_id];
  }
}

// File: contracts\child\ChildToken\ChildERC1155.sol

pragma solidity 0.6.6;






contract ToshimonMinter is ERC1155Tradable
{
    using Strings for string;
    string private _contractURI;
    

    constructor(address _proxyRegistryAddress)
        public
        ERC1155Tradable('Toshimon Minter', 'ToshimonMinter', _proxyRegistryAddress)
    {

        proxyRegistryAddress = _proxyRegistryAddress;
        _setupContractId("ChildERC1155");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(WHITELIST_ADMIN_ROLE, _msgSender());
        
        _contractURI = 'https://api.toshimon.io/toshimon-erc1155';

    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead


    function setBaseMetadataURI(string memory newURI) public only(WHITELIST_ADMIN_ROLE) {
        _setBaseMetadataURI(newURI);
    }

    function mintBatch(address user, uint256[] calldata ids, uint256[] calldata amounts)
        external
        only(MINTER_ROLE)
    {
        _mintBatch(user, ids, amounts, '');
    }
 function setContractURI(string memory newURI) public only(WHITELIST_ADMIN_ROLE) {
    _contractURI = newURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }
  /**
   * @dev Ends minting of token
   * @param _id Token ID for which minting will end
   */
  function endMinting(uint256 _id) external only(WHITELIST_ADMIN_ROLE) {
    tokenMaxSupply[_id] = tokenSupply[_id];
  }

  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) 
    external
    only(MINTER_ROLE) {
    require(
      balanceOf(_account, _id) >= _amount,
      'Cannot burn more than addres has'
    );
    _burn(_account, _id, _amount);
  }

  /**
   * Mint NFT and send those to the list of given addresses
   */
  function airdrop(uint256 _id, address[] calldata _addresses)  
        external
        only(MINTER_ROLE)  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _mint(_addresses[i], _id, 1, '');
    }
  }
    /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public only(DEFAULT_ADMIN_ROLE) {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    grantRole(DEFAULT_ADMIN_ROLE,newOwner);
    revokeRole(DEFAULT_ADMIN_ROLE,getRoleMember(DEFAULT_ADMIN_ROLE,0));
  }
  function isMinter(address account) public view returns (bool) {
    return hasRole(MINTER_ROLE,account);
  }
  function isOwner(address account) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE,account);
  }
  function isWhitelistAdmin(address account) public view returns (bool) {
    return hasRole(WHITELIST_ADMIN_ROLE,account);
  }
  function owner() public view returns (address) {
    return getRoleMember(DEFAULT_ADMIN_ROLE,0);
  }
 
}



contract ToshiCoinNonTradable is Ownable, MinterRole, CanTransferRole {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _balances;

    string public name = "ToshiCoin - Non Tradable";
    string public symbol = "ToshiCoin";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public totalClaimed;
    uint256 public totalMinted;

    uint256 public remainingToshiCoinForSale = 4000 * (1e18);
    uint256 public priceInTOSHI = 3;

    IERC20 public toshi;
    address public toshiTreasury;

    constructor(IERC20 _toshi, address _toshiTreasury) public {
        toshi = _toshi;
        toshiTreasury = _toshiTreasury;
    }

    function addClaimed(uint256 amount) internal {
        totalClaimed = totalClaimed.add(amount);
    }

    function addMinted(uint256 amount) internal {
        totalMinted = totalMinted.add(amount);
    }

    function setRemainingToshiCoinForSale(uint256 _remainingToshiCoinForSale)
        external
        onlyMinter
    {
        remainingToshiCoinForSale = _remainingToshiCoinForSale;
    }

    function setPriceInToshi(uint256 _priceInTOSHI) external onlyMinter {
        priceInTOSHI = _priceInTOSHI;
    }

    function setToshiTreasury(address _toshiTreasury) external onlyMinter {
        toshiTreasury = _toshiTreasury;
    }

    /**
     * @dev Anyone can purchase ToshiCoin for TOSHI until it is sold out.
     */
    function purchase(uint256 amount) external {
        uint256 price = priceInTOSHI.mul(amount);
        uint256 balance = toshi.balanceOf(msg.sender);

        require(balance >= price, "ToshiCoin: Not enough TOSHI in wallet.");
        require(
            remainingToshiCoinForSale >= amount,
            "ToshiCoin: Not enough ToshiCoin for sale."
        );

        safeToshiTransferFrom(msg.sender, toshiTreasury, price);

        remainingToshiCoinForSale = remainingToshiCoinForSale.sub(amount);

        _mint(msg.sender, amount);
        addMinted(amount);
    }

    /**
     * @dev Claiming is white-listed to specific minter addresses for now to limit transfers.
     */
    function claim(address to, uint256 amount) public onlyCanTransfer {
        transfer(to, amount);
        addClaimed(amount);
    }

    /**
     * @dev Transferring is white-listed to specific minter addresses for now.
     */
    function transfer(address to, uint256 amount)
        public
        onlyCanTransfer
        returns (bool)
    {
        require(
            amount <= _balances[msg.sender],
            "ToshiCoin: Cannot transfer more than balance"
        );

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /**
     * @dev Transferring is white-listed to specific minter addresses for now.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public onlyCanTransfer returns (bool) {
        require(
            amount <= _balances[from],
            "ToshiCoin: Cannot transfer more than balance"
        );

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Minting is white-listed to specific minter addresses for now.
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
        addMinted(amount);
    }

    /**
     * @dev Burning is white-listed to specific minter addresses for now.
     */
    function burn(address from, uint256 value) public onlyCanTransfer {
        require(
            _balances[from] >= value,
            "ToshiCoin: Cannot burn more than the address balance"
        );

        _burn(from, value);
    }

    /**
     * @dev Internal function that creates an amount of the token and assigns it to an account.
     * This encapsulates the modification of balances such that the proper events are emitted.
     * @param to The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ToshiCoin: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Internal function that destroys an amount of the token of a given address.
     * @param from The account whose tokens will be destroyed.
     * @param amount The amount that will be destroyed.
     */
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ToshiCoin: burn from the zero address");

        totalSupply = totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev Safe token transfer from to prevent over-transfers.
     */
    function safeToshiTransferFrom(
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 tokenBalance = toshi.balanceOf(address(from));
        uint256 transferAmount = amount > tokenBalance ? tokenBalance : amount;

        toshi.transferFrom(from, to, transferAmount);
    }
}

pragma solidity >=0.6.0;


contract ToshiCoinFarm is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amountInPool;
        uint256 coinsReceivedToDate;
        /*
         *  At any point in time, the amount of ToshiCoin earned by a user waiting to be claimed is:
         *
         *    Pending claim = (user.amountInPool * pool.coinsEarnedPerToken) - user.coinsReceivedToDate
         *
         *  Whenever a user deposits or withdraws tokens to a pool, the following occurs:
         *   1. The pool's `coinsEarnedPerToken` is rebalanced to account for the new shares in the pool.
         *   2. The `lastRewardBlock` is updated to the latest block.
         *   3. The user receives the pending claim sent to their address.
         *   4. The user's `amountInPool` and `coinsReceivedToDate` get updated for this pool.
         */
    }

    struct PoolInfo {
        IERC20 token;
        uint256 lastUpdateTime;
        uint256 coinsPerDay;
        uint256 coinsEarnedPerToken;
    }

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public tokenPoolIds;

    ToshiCoinNonTradable public ToshiCoin;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    constructor(ToshiCoinNonTradable toshiCoinAddress) public {
        ToshiCoin = toshiCoinAddress;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function pendingCoins(uint256 poolId, address user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][user];

        uint256 tokenSupply = pool.token.balanceOf(address(this));
        uint256 coinsEarnedPerToken = pool.coinsEarnedPerToken;

        if (block.timestamp > pool.lastUpdateTime && tokenSupply > 0) {
            uint256 pendingCoins = block
                .timestamp
                .sub(pool.lastUpdateTime)
                .mul(pool.coinsPerDay)
                .div(86400);

            coinsEarnedPerToken = coinsEarnedPerToken.add(
                pendingCoins.mul(1e18).div(tokenSupply)
            );
        }

        return
            user.amountInPool.mul(coinsEarnedPerToken).div(1e18).sub(
                user.coinsReceivedToDate
            );
    }

    function totalPendingCoins(address user) public view returns (uint256) {
        uint256 total = 0;
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; ++poolId) {
            total = total.add(pendingCoins(poolId, user));
        }

        return total;
    }

    /**
     * @dev Add new pool to the farm. Cannot add the same token more than once.
     */
    function addPool(IERC20 token, uint256 _coinsPerDay) public onlyOwner {
        require(
            tokenPoolIds[address(token)] == 0,
            "ToshiCoinFarm: Added duplicate token pool"
        );
        require(
            address(token) != address(ToshiCoin),
            "ToshiCoinFarm: Cannot add ToshiCoin pool"
        );

        poolInfo.push(
            PoolInfo({
                token: token,
                coinsPerDay: _coinsPerDay,
                lastUpdateTime: block.timestamp,
                coinsEarnedPerToken: 0
            })
        );

        tokenPoolIds[address(token)] = poolInfo.length;
    }

    function setCoinsPerDay(uint256 poolId, uint256 amount) public onlyOwner {
        require(amount >= 0, "ToshiCoinFarm: Coins per day cannot be negative");

        updatePool(poolId);

        poolInfo[poolId].coinsPerDay = amount;
    }

    /**
     * @dev Claim all pending rewards in all pools.
     */
    function claimAll(uint256[] memory poolIds) public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; poolId++) {
            withdraw(poolIds[poolId], 0);
        }
    }

    /**
     * @dev Update pending rewards in all pools.
     */
    function updateAllPools() public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; poolId++) {
            updatePool(poolId);
        }
    }

    /**
     * @dev Update pending rewards for a pool.
     */
    function updatePool(uint256 poolId) public {
        PoolInfo storage pool = poolInfo[poolId];

        if (block.timestamp <= pool.lastUpdateTime) {
            return;
        }

        uint256 tokenSupply = pool.token.balanceOf(address(this));

        if (pool.coinsPerDay == 0 || tokenSupply == 0) {
            pool.lastUpdateTime = block.timestamp;
            return;
        }

        uint256 pendingCoins = block
            .timestamp
            .sub(pool.lastUpdateTime)
            .mul(pool.coinsPerDay)
            .div(86400);

        ToshiCoin.mint(address(this), pendingCoins);

        pool.lastUpdateTime = block.timestamp;
        pool.coinsEarnedPerToken = pool.coinsEarnedPerToken.add(
            pendingCoins.mul(1e18).div(tokenSupply)
        );
    }

    /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function deposit(uint256 poolId, uint256 amount) public {
        require(
            amount > 0,
            "ToshiCoinFarm: Cannot deposit non-positive amount into pool"
        );

        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        updatePool(poolId);

        uint256 pending = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18)
            .sub(user.coinsReceivedToDate);

        if (pending > 0) {
            safeToshiCoinClaim(msg.sender, pending);
        }

        user.amountInPool = user.amountInPool.add(amount);
        user.coinsReceivedToDate = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18);

        safePoolTransferFrom(msg.sender, address(this), amount, pool);

        emit Deposit(msg.sender, poolId, amount);
    }

    /**
     * @dev Withdraw tokens from a pool and claim pending reward.
     */
    function withdraw(uint256 poolId, uint256 amount) public {
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        require(
            user.amountInPool >= amount,
            "ToshiCoinFarm: User does not have enough funds to withdraw from this pool"
        );

        updatePool(poolId);

        uint256 pending = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18)
            .sub(user.coinsReceivedToDate);

        if (pending > 0) {
            safeToshiCoinClaim(msg.sender, pending);
        }

        user.amountInPool = user.amountInPool.sub(amount);
        user.coinsReceivedToDate = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18);

        if (amount > 0) {
            safePoolTransfer(msg.sender, amount, pool);
        }

        emit Withdraw(msg.sender, poolId, amount);
    }

    /**
     * @dev Emergency withdraw withdraws funds without claiming rewards.
     *      This should only be used in emergencies.
     */
    function emergencyWithdraw(uint256 poolId) public {
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        require(
            user.amountInPool > 0,
            "ToshiCoinFarm: User has no funds to withdraw from this pool"
        );

        uint256 amount = user.amountInPool;

        user.amountInPool = 0;
        user.coinsReceivedToDate = 0;

        safePoolTransfer(msg.sender, amount, pool);

        emit EmergencyWithdraw(msg.sender, poolId, amount);
    }

    /**
     * @dev Safe ToshiCoin transfer to prevent over-transfers.
     */
    function safeToshiCoinClaim(address to, uint256 amount) internal {
        uint256 coinsBalance = ToshiCoin.balanceOf(address(this));
        uint256 claimAmount = amount > coinsBalance ? coinsBalance : amount;

        ToshiCoin.claim(to, claimAmount);
    }

    /**
     * @dev Safe pool token transfer to prevent over-transfers.
     */
    function safePoolTransfer(
        address to,
        uint256 amount,
        PoolInfo storage pool
    ) internal {
        uint256 tokenBalance = pool.token.balanceOf(address(this));
        uint256 transferAmount = amount > tokenBalance ? tokenBalance : amount;

        pool.token.transfer(to, transferAmount);
    }

    /**
     * @dev Safe pool token transfer from to prevent over-transfers.
     */
    function safePoolTransferFrom(
        address from,
        address to,
        uint256 amount,
        PoolInfo storage pool
    ) internal {
        uint256 tokenBalance = pool.token.balanceOf(from);
        uint256 transferAmount = amount > tokenBalance ? tokenBalance : amount;

        pool.token.transferFrom(from, to, transferAmount);
    }
}

contract ToshiCash is Ownable, MinterRole, CanTransferRole {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _balances;

    string public name = "ToshiCash";
    string public symbol = "ToshiCash";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public totalClaimed;
    uint256 public totalMinted;



    constructor() public {

    }

    function addClaimed(uint256 amount) internal {
        totalClaimed = totalClaimed.add(amount);
    }

    function addMinted(uint256 amount) internal {
        totalMinted = totalMinted.add(amount);
    }

    /**
     * @dev Claiming is white-listed to specific minter addresses for now to limit transfers.
     */
    function claim(address to, uint256 amount) public onlyCanTransfer {
        transfer(to, amount);
        addClaimed(amount);
    }

    /**
     * @dev Transferring is white-listed to specific minter addresses for now.
     */
    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        require(
            amount <= _balances[msg.sender],
            "ToshiCash: Cannot transfer more than balance"
        );

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /**
     * @dev Transferring is white-listed to specific minter addresses for now.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public onlyCanTransfer returns (bool) {
        require(
            amount <= _balances[from],
            "ToshiCash: Cannot transfer more than balance"
        );

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Minting is white-listed to specific minter addresses for now.
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
        addMinted(amount);
    }

    /**
     * @dev Burning is white-listed to specific minter addresses for now.
     */
    function burn(address from, uint256 value) public onlyCanTransfer {
        require(
            _balances[from] >= value,
            "ToshiCash: Cannot burn more than the address balance"
        );

        _burn(from, value);
    }

    /**
     * @dev Internal function that creates an amount of the token and assigns it to an account.
     * This encapsulates the modification of balances such that the proper events are emitted.
     * @param to The account that will receive the created tokens.
     * @param amount The amount that will be created.
     */
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ToshiCash: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);

        emit Transfer(address(0), to, amount);
    }

    /**
     * @dev Internal function that destroys an amount of the token of a given address.
     * @param from The account whose tokens will be destroyed.
     * @param amount The amount that will be destroyed.
     */
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ToshiCash: burn from the zero address");

        totalSupply = totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        emit Transfer(from, address(0), amount);
    }


}

contract ToshiCashFarm is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amountInPool;
        uint256 coinsReceivedToDate;
        /*
         *  At any point in time, the amount of ToshiCoin earned by a user waiting to be claimed is:
         *
         *    Pending claim = (user.amountInPool * pool.coinsEarnedPerToken) - user.coinsReceivedToDate
         *
         *  Whenever a user deposits or withdraws tokens to a pool, the following occurs:
         *   1. The pool's `coinsEarnedPerToken` is rebalanced to account for the new shares in the pool.
         *   2. The `lastRewardBlock` is updated to the latest block.
         *   3. The user receives the pending claim sent to their address.
         *   4. The user's `amountInPool` and `coinsReceivedToDate` get updated for this pool.
         */
    }
    struct UserInfoERC1155 {
        uint256 amountInPool;
        
        /*
         *  At any point in time, the amount of ToshiCoin earned by a user waiting to be claimed is:
         *
         *    Pending claim = (user.amountInPool * pool.coinsEarnedPerToken) - user.coinsReceivedToDate
         *
         *  Whenever a user deposits or withdraws tokens to a pool, the following occurs:
         *   1. The pool's `coinsEarnedPerToken` is rebalanced to account for the new shares in the pool.
         *   2. The `lastRewardBlock` is updated to the latest block.
         *   3. The user receives the pending claim sent to their address.
         *   4. The user's `amountInPool` and `coinsReceivedToDate` get updated for this pool.
         */
    }
    

    struct PoolInfo {
        IERC20 token;
        uint256 lastUpdateTime;
        uint256 coinsPerDay;
        uint256 coinsEarnedPerToken;
    }
    struct ERC1155Multiplier {
        uint256 id;
        uint256 percentBoost;
       
    }
    struct ERC1155MultiplierUserInfo {
        uint256 multiplier;
        uint256 total;
       
    }

    PoolInfo[] public poolInfo;
    ERC1155Multiplier[] public eRC1155Multiplier;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(address => UserInfoERC1155)) public userInfoERC1155;
    mapping(address => uint256) public tokenPoolIds;
    mapping(uint256 => uint256) public eRC1155MultiplierIds;
    mapping(address => ERC1155MultiplierUserInfo) public userMultiplier;

    ToshiCoinFarm public toshiCoinFarm;
    ToshiCash public toshiCash;
    ToshimonMinter public toshimonMinter;
    address public toshiCoinFarmDelegate;

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event DepositERC1155(address indexed user, uint256 indexed erc1155);
    event WithdrawERC1155(
        address indexed user,
        uint256 indexed erc1155
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    constructor(ToshiCoinFarm toshiCoinFarmAddress, address toshiCoinFarmDelegateAddress, ToshiCash toshiCashAddress, ToshimonMinter toshimonMinterAddress) public {
        toshiCash = toshiCashAddress;
        toshiCoinFarm = toshiCoinFarmAddress;
        toshiCoinFarmDelegate = toshiCoinFarmDelegateAddress;
        toshimonMinter = toshimonMinterAddress;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function pendingCoins(uint256 poolId, address user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][user];

        uint256 tokenSupply = pool.token.balanceOf(address(this));
        uint256 coinsEarnedPerToken = pool.coinsEarnedPerToken;

        if (block.timestamp > pool.lastUpdateTime && tokenSupply > 0) {
            uint256 pendingCoins = block
                .timestamp
                .sub(pool.lastUpdateTime)
                .mul(pool.coinsPerDay)
                .div(86400);

            coinsEarnedPerToken = coinsEarnedPerToken.add(
                pendingCoins.mul(1e18).div(tokenSupply)
            );
        }

        return
            user.amountInPool.mul(coinsEarnedPerToken).div(1e18).sub(
                user.coinsReceivedToDate
            );
    }


    function pendingCoinsBonus(address user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        (uint256 amountInPool, uint256 coinsReceivedToDate) = toshiCoinFarm.userInfo(0,msg.sender);

        uint256 tokenSupply = pool.token.balanceOf(address(toshiCoinFarm));
        uint256 coinsEarnedPerToken = pool.coinsEarnedPerToken;

        if (block.timestamp > pool.lastUpdateTime && tokenSupply > 0) {
            uint256 pendingCoins = block
                .timestamp
                .sub(pool.lastUpdateTime)
                .mul(pool.coinsPerDay)
                .div(86400);

            coinsEarnedPerToken = coinsEarnedPerToken.add(
                pendingCoins.mul(1e18).div(tokenSupply)
            );
        }

        return
            amountInPool.mul(coinsEarnedPerToken).div(1e18).sub(
                user.coinsReceivedToDate
            );
    }

    function totalPendingCoins(address user) public view returns (uint256) {
        uint256 total = 0;
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; ++poolId) {
            total = total.add(pendingCoins(poolId, user));
        }

        return total;
    }
    function userMultiplierValue(address user) public view returns (uint256) {

        return userMultiplier[msg.sender].multiplier;
    }
    
    function userERC155StakedTotal(address user) public view returns (uint256) {

        return userMultiplier[msg.sender].total;
    }

    /**
     * @dev Add new pool to the farm. Cannot add the same token more than once.
     */
    function addPool(IERC20 token, uint256 _coinsPerDay) public onlyOwner {

       require(
            address(token) != address(toshiCash),
            "ToshiCashFarm: Cannot add ToshiCash pool"
        );

        poolInfo.push(
            PoolInfo({
                token: token,
                coinsPerDay: _coinsPerDay,
                lastUpdateTime: block.timestamp,
                coinsEarnedPerToken: 0
            })
        );

        tokenPoolIds[address(token)] = poolInfo.length;
    }

    function addERC1155Multiplier(uint256 _id, uint256 _percentBoost) public onlyOwner {
        require(
            eRC1155MultiplierIds[_id] == 0,
            "ToshiCashFarm: Cannot add duplicate Toshimon E%C1155"
        );

        eRC1155Multiplier.push(
            ERC1155Multiplier({
                id:_id,
                percentBoost: _percentBoost
            })
        );

        eRC1155MultiplierIds[_id] = poolInfo.length;
    }

    function setCoinsPerDay(uint256 poolId, uint256 amount) public onlyOwner {
        require(amount >= 0, "ToshiCoinFarm: Coins per day cannot be negative");

        updatePool(poolId);

        poolInfo[poolId].coinsPerDay = amount;
    }

    /**
     * @dev Claim all pending rewards in all pools.
     */
    function claimAll(uint256[] memory poolIds) public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 0; poolId < length; poolId++) {
            withdraw(poolIds[poolId], 0);
        }
    }

    /**
     * @dev Update pending rewards in all pools.
     */
    function updateAllPools() public {
        uint256 length = poolInfo.length;

        for (uint256 poolId = 1; poolId < length; poolId++) {
            updatePool(poolId);
        }
    }

    /**
     * @dev Update pending rewards for a pool.
     */
    function updatePool(uint256 poolId) public {
        PoolInfo storage pool = poolInfo[poolId];
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        if (block.timestamp <= pool.lastUpdateTime) {
            return;
        }

        uint256 tokenSupply = pool.token.balanceOf(address(toshiCoinFarm));

        if (pool.coinsPerDay == 0 || tokenSupply == 0) {
            pool.lastUpdateTime = block.timestamp;
            return;
        }

        uint256 pendingCoins = block
            .timestamp
            .sub(pool.lastUpdateTime)
            .mul(pool.coinsPerDay)
            .div(86400);

        toshiCash.mint(address(this), pendingCoins.mul(multiplier.multiplier.add(100)).div(100));

        pool.lastUpdateTime = block.timestamp;
        pool.coinsEarnedPerToken = pool.coinsEarnedPerToken.add(
            pendingCoins.mul(1e18).div(tokenSupply)
        );
    }


  /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function depositERC1155(uint256 poolId) public {

        ERC1155Multiplier storage erc1155 = eRC1155Multiplier[poolId];
        UserInfoERC1155 storage user = userInfoERC1155[poolId][msg.sender];
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        
        require(
            user.amountInPool == 0,
            "ToshiCoinFarm: User can only stake one of each erc1155 type"
        );
        withdraw(1,0);
        
        user.amountInPool = user.amountInPool.add(1);
        multiplier.multiplier = multiplier.multiplier.add(erc1155.percentBoost);
        multiplier.total = multiplier.total.add(erc1155.percentBoost);
        if(multiplier.multiplier > 100){
            multiplier.multiplier = 100;
        }

        toshimonMinter.burn(msg.sender,erc1155.id, 1);

        emit DepositERC1155(msg.sender, erc1155.id);
    }
      /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function withdrawERC1155(uint256 poolId) public {

        ERC1155Multiplier storage erc1155 = eRC1155Multiplier[poolId];
        UserInfoERC1155 storage user = userInfoERC1155[poolId][msg.sender];
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        
        
        require(
            user.amountInPool >= 1,
            "ToshiCoinFarm: User does not have enough funds to withdraw from this pool"
        );
        withdraw(1,0);
        
        user.amountInPool = user.amountInPool.sub(1);
        
        
        multiplier.total = multiplier.total.sub(erc1155.percentBoost);
        multiplier.multiplier = multiplier.total;
        if(multiplier.multiplier > 100){
            multiplier.multiplier = 100;
        }
        
          toshimonMinter.mint(msg.sender,erc1155.id, 1,"");
        

        emit WithdrawERC1155(msg.sender, erc1155.id);
    }

    function claimBonus() public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        (uint256 amountInPool, uint256 coinsReceivedToDate) = toshiCoinFarm.userInfo(0,msg.sender);
        

        
        updatePool(0);

        uint256 pending = amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18)
            .sub(user.coinsReceivedToDate);

        if (pending > 0) {
            safeToshiCashClaim(msg.sender, pending);
        }

        user.coinsReceivedToDate = pending;

        emit Withdraw(msg.sender, pending, amountInPool);
    }


   //
 /**
     * @dev Deposit tokens into a pool and claim pending reward.
     */
    function deposit(uint256 poolId, uint256 amount) public {
        require(
            amount > 0,
            "ToshiCashFarm: Cannot deposit non-positive amount into pool"
        );
        require(
            poolId != 0,
            "ToshiCashFarm: There is no pool 0"
        );
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        updatePool(poolId);

        uint256 pending = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18)
            .sub(user.coinsReceivedToDate);

        if (pending > 0) {
            safeToshiCashClaim(msg.sender, pending.mul(multiplier.multiplier.add(100)).div(100));
        }

        user.amountInPool = user.amountInPool.add(amount);
        user.coinsReceivedToDate = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18);

        safePoolTransferFrom(msg.sender, address(this), amount, pool);

        emit Deposit(msg.sender, poolId, amount);
    }

    /**
     * @dev Withdraw tokens from a pool and claim pending reward.
     */
    function withdraw(uint256 poolId, uint256 amount) public {
        ERC1155MultiplierUserInfo storage multiplier = userMultiplier[msg.sender];
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        require(
            user.amountInPool >= amount,
            "ToshiCashFarm: User does not have enough funds to withdraw from this pool"
        );
        
        require(
            poolId != 0,
            "ToshiCashFarm: There is no pool 0"
        );

        updatePool(poolId);

        uint256 pending = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18)
            .sub(user.coinsReceivedToDate);

        if (pending > 0) {
            safeToshiCashClaim(msg.sender, pending.mul(multiplier.multiplier.add(100)).div(100));
        }

        user.amountInPool = user.amountInPool.sub(amount);
        user.coinsReceivedToDate = user
            .amountInPool
            .mul(pool.coinsEarnedPerToken)
            .div(1e18);

        if (amount > 0) {
            safePoolTransfer(msg.sender, amount, pool);
        }

        emit Withdraw(msg.sender, poolId, amount);
    }

    /**
     * @dev Emergency withdraw withdraws funds without claiming rewards.
     *      This should only be used in emergencies.
     */
    function emergencyWithdraw(uint256 poolId) public {
        PoolInfo storage pool = poolInfo[poolId];
        UserInfo storage user = userInfo[poolId][msg.sender];

        require(
            user.amountInPool > 0,
            "ToshiCashFarm: User has no funds to withdraw from this pool"
        );

        uint256 amount = user.amountInPool;

        user.amountInPool = 0;
        user.coinsReceivedToDate = 0;

        safePoolTransfer(msg.sender, amount, pool);

        emit EmergencyWithdraw(msg.sender, poolId, amount);
    }

   

    /**
     * @dev Safe pool token transfer to prevent over-transfers.
     */
    function safePoolTransfer(
        address to,
        uint256 amount,
        PoolInfo storage pool
    ) internal {
        uint256 tokenBalance = pool.token.balanceOf(address(this));
        uint256 transferAmount = amount > tokenBalance ? tokenBalance : amount;

        pool.token.transfer(to, transferAmount);
    }

    /**
     * @dev Safe pool token transfer from to prevent over-transfers.
     */
    function safePoolTransferFrom(
        address from,
        address to,
        uint256 amount,
        PoolInfo storage pool
    ) internal {
        uint256 tokenBalance = pool.token.balanceOf(from);
        uint256 transferAmount = amount > tokenBalance ? tokenBalance : amount;

        pool.token.transferFrom(from, to, transferAmount);
    }
    /**
     * @dev Safe ToshiCoin transfer to prevent over-transfers.
     */
    function safeToshiCashClaim(address to, uint256 amount) internal {
       uint256 coinsBalance = toshiCash.balanceOf(address(this));
       uint256 claimAmount = amount > coinsBalance ? coinsBalance : amount;

       toshiCash.claim(to, claimAmount);
    }
    

   
}