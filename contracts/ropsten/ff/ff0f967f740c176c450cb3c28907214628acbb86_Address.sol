/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.5.10;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: eth-token-recover/contracts/TokenRecover.sol

/**
 * @title TokenRecover
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Allow to recover any ERC20 sent into the contract for error
 */
contract TokenRecover is Ownable {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

// File: openzeppelin-solidity/contracts/introspection/ERC165Checker.sol

/**
 * @dev Library used to query support of an interface declared via `IERC165`.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the `IERC165` interface,
     */
    function _supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for `IERC165` itself is queried automatically.
     *
     * See `IERC165.supportsInterface`.
     */
    function _supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return _supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for `IERC165` itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * `IERC165` support.
     *
     * See `IERC165.supportsInterface`.
     */
    function _supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!_supportsERC165(account)) {
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
     * with the `supportsERC165` method in this library.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool success, bool result)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encodedParams_data := add(0x20, encodedParams)
            let encodedParams_size := mload(encodedParams)

            let output := mload(0x40)    // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)

            success := staticcall(
                30000,                   // 30k gas
                account,                 // To addr
                encodedParams_data,
                encodedParams_size,
                output,
                0x20                     // Outputs are 32 bytes long
            )

            result := mload(output)      // Load the result
        }
    }
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
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
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363.sol

/**
 * @title IERC1363 Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for a Payable Token contract as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363 is IERC20, ERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) public returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value, bytes memory data) public returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value) public returns (bool);


    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) public returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value) public returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(address spender, uint256 value, bytes memory data) public returns (bool);
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public returns (bytes4); // solhint-disable-line  max-line-length
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol

/**
 * @title IERC1363Spender Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://github.com/ethereum/EIPs/issues/1363
 */
contract IERC1363Spender {
    /*
     * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
     * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
     */

    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
     *  unless throwing
     */
    function onApprovalReceived(address owner, uint256 value, bytes memory data) public returns (bytes4);
}

// File: erc-payable-token/contracts/payment/ERC1363Payable.sol

/**
 * @title ERC1363Payable
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation proposal of a contract that wants to accept ERC1363 payments
 */
contract ERC1363Payable is IERC1363Receiver, IERC1363Spender, ERC165 {
    using ERC165Checker for address;

    /**
     * @dev Magic value to be returned upon successful reception of ERC1363 tokens
     *  Equals to `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`,
     *  which can be also obtained as `IERC1363Receiver(0).onTransferReceived.selector`
     */
    bytes4 internal constant _INTERFACE_ID_ERC1363_RECEIVER = 0x88a7ca5c;

    /**
     * @dev Magic value to be returned upon successful approval of ERC1363 tokens.
     * Equals to `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`,
     * which can be also obtained as `IERC1363Spender(0).onApprovalReceived.selector`
     */
    bytes4 internal constant _INTERFACE_ID_ERC1363_SPENDER = 0x7b04a2d0;

    /*
     * Note: the ERC-165 identifier for the ERC1363 token transfer
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */
    bytes4 private constant _INTERFACE_ID_ERC1363_TRANSFER = 0x4bbee2df;

    /*
     * Note: the ERC-165 identifier for the ERC1363 token approval
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */
    bytes4 private constant _INTERFACE_ID_ERC1363_APPROVE = 0xfb9ec8ce;

    event TokensReceived(
        address indexed operator,
        address indexed from,
        uint256 value,
        bytes data
    );

    event TokensApproved(
        address indexed owner,
        uint256 value,
        bytes data
    );

    // The ERC1363 token accepted
    IERC1363 private _acceptedToken;

    /**
     * @param acceptedToken Address of the token being accepted
     */
    constructor(IERC1363 acceptedToken) public {
        require(address(acceptedToken) != address(0));
        require(
            acceptedToken.supportsInterface(_INTERFACE_ID_ERC1363_TRANSFER) &&
            acceptedToken.supportsInterface(_INTERFACE_ID_ERC1363_APPROVE)
        );

        _acceptedToken = acceptedToken;

        // register the supported interface to conform to IERC1363Receiver and IERC1363Spender via ERC165
        _registerInterface(_INTERFACE_ID_ERC1363_RECEIVER);
        _registerInterface(_INTERFACE_ID_ERC1363_SPENDER);
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     */
    function onTransferReceived(address operator, address from, uint256 value, bytes memory data) public returns (bytes4) { // solhint-disable-line  max-line-length
        require(msg.sender == address(_acceptedToken));

        emit TokensReceived(operator, from, value, data);

        _transferReceived(operator, from, value, data);

        return _INTERFACE_ID_ERC1363_RECEIVER;
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     */
    function onApprovalReceived(address owner, uint256 value, bytes memory data) public returns (bytes4) {
        require(msg.sender == address(_acceptedToken));

        emit TokensApproved(owner, value, data);

        _approvalReceived(owner, value, data);

        return _INTERFACE_ID_ERC1363_SPENDER;
    }

    /**
     * @dev The ERC1363 token accepted
     */
    function acceptedToken() public view returns (IERC1363) {
        return _acceptedToken;
    }

    /**
     * @dev Called after validating a `onTransferReceived`. Override this method to
     * make your stuffs within your contract.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     */
    function _transferReceived(address operator, address from, uint256 value, bytes memory data) internal {
        // solhint-disable-previous-line no-empty-blocks

        // optional override
    }

    /**
     * @dev Called after validating a `onApprovalReceived`. Override this method to
     * make your stuffs within your contract.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     */
    function _approvalReceived(address owner, uint256 value, bytes memory data) internal {
        // solhint-disable-previous-line no-empty-blocks

        // optional override
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
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
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: dao-smartcontracts/contracts/access/roles/DAORoles.sol

/**
 * @title DAORoles
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev It identifies the DAO roles
 */
contract DAORoles is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    event DappAdded(address indexed account);
    event DappRemoved(address indexed account);

    Roles.Role private _operators;
    Roles.Role private _dapps;

    constructor () internal {} // solhint-disable-line no-empty-blocks

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    modifier onlyDapp() {
        require(isDapp(msg.sender));
        _;
    }

    /**
     * @dev Check if an address has the `operator` role
     * @param account Address you want to check
     */
    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    /**
     * @dev Check if an address has the `dapp` role
     * @param account Address you want to check
     */
    function isDapp(address account) public view returns (bool) {
        return _dapps.has(account);
    }

    /**
     * @dev Add the `operator` role from address
     * @param account Address you want to add role
     */
    function addOperator(address account) public onlyOwner {
        _addOperator(account);
    }

    /**
     * @dev Add the `dapp` role from address
     * @param account Address you want to add role
     */
    function addDapp(address account) public onlyOperator {
        _addDapp(account);
    }

    /**
     * @dev Remove the `operator` role from address
     * @param account Address you want to remove role
     */
    function removeOperator(address account) public onlyOwner {
        _removeOperator(account);
    }

    /**
     * @dev Remove the `operator` role from address
     * @param account Address you want to remove role
     */
    function removeDapp(address account) public onlyOperator {
        _removeDapp(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _addDapp(address account) internal {
        _dapps.add(account);
        emit DappAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }

    function _removeDapp(address account) internal {
        _dapps.remove(account);
        emit DappRemoved(account);
    }
}

// File: dao-smartcontracts/contracts/dao/Organization.sol

/**
 * @title Organization
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Library for managing organization
 */
library Organization {
    using SafeMath for uint256;

    // structure defining a member
    struct Member {
        uint256 id;
        address account;
        bytes9 fingerprint;
        uint256 creationDate;
        uint256 stakedTokens;
        uint256 usedTokens;
        bytes32 data;
        bool approved;
    }

    // structure defining members status
    struct Members {
        uint256 count;
        uint256 totalStakedTokens;
        uint256 totalUsedTokens;
        mapping(address => uint256) addressMap;
        mapping(uint256 => Member) list;
    }

    /**
     * @dev Returns if an address is member or not
     * @param members Current members struct
     * @param account Address of the member you are looking for
     * @return bool
     */
    function isMember(Members storage members, address account) internal view returns (bool) {
        return members.addressMap[account] != 0;
    }

    /**
     * @dev Get creation date of a member
     * @param members Current members struct
     * @param account Address you want to check
     * @return uint256 Member creation date, zero otherwise
     */
    function creationDateOf(Members storage members, address account) internal view returns (uint256) {
        Member storage member = members.list[members.addressMap[account]];

        return member.creationDate;
    }

    /**
     * @dev Check how many tokens staked for given address
     * @param members Current members struct
     * @param account Address you want to check
     * @return uint256 Member staked tokens
     */
    function stakedTokensOf(Members storage members, address account) internal view returns (uint256) {
        Member storage member = members.list[members.addressMap[account]];

        return member.stakedTokens;
    }

    /**
     * @dev Check how many tokens used for given address
     * @param members Current members struct
     * @param account Address you want to check
     * @return uint256 Member used tokens
     */
    function usedTokensOf(Members storage members, address account) internal view returns (uint256) {
        Member storage member = members.list[members.addressMap[account]];

        return member.usedTokens;
    }

    /**
     * @dev Check if an address has been approved
     * @param members Current members struct
     * @param account Address you want to check
     * @return bool
     */
    function isApproved(Members storage members, address account) internal view returns (bool) {
        Member storage member = members.list[members.addressMap[account]];

        return member.approved;
    }

    /**
     * @dev Returns the member structure
     * @param members Current members struct
     * @param memberId Id of the member you are looking for
     * @return Member
     */
    function getMember(Members storage members, uint256 memberId) internal view returns (Member storage) {
        Member storage structure = members.list[memberId];

        require(structure.account != address(0));

        return structure;
    }

    /**
     * @dev Generate a new member and the member structure
     * @param members Current members struct
     * @param account Address you want to make member
     * @return uint256 The new member id
     */
    function addMember(Members storage members, address account) internal returns (uint256) {
        require(account != address(0));
        require(!isMember(members, account));

        uint256 memberId = members.count.add(1);
        bytes9 fingerprint = getFingerprint(account, memberId);

        members.addressMap[account] = memberId;
        members.list[memberId] = Member(
            memberId,
            account,
            fingerprint,
            block.timestamp, // solhint-disable-line not-rely-on-time
            0,
            0,
            "",
            false
        );

        members.count = memberId;

        return memberId;
    }

    /**
     * @dev Add tokens to member stack
     * @param members Current members struct
     * @param account Address you want to stake tokens
     * @param amount Number of tokens to stake
     */
    function stake(Members storage members, address account, uint256 amount) internal {
        require(isMember(members, account));

        Member storage member = members.list[members.addressMap[account]];

        member.stakedTokens = member.stakedTokens.add(amount);
        members.totalStakedTokens = members.totalStakedTokens.add(amount);
    }

    /**
     * @dev Remove tokens from member stack
     * @param members Current members struct
     * @param account Address you want to unstake tokens
     * @param amount Number of tokens to unstake
     */
    function unstake(Members storage members, address account, uint256 amount) internal {
        require(isMember(members, account));

        Member storage member = members.list[members.addressMap[account]];

        require(member.stakedTokens >= amount);

        member.stakedTokens = member.stakedTokens.sub(amount);
        members.totalStakedTokens = members.totalStakedTokens.sub(amount);
    }

    /**
     * @dev Use tokens from member stack
     * @param members Current members struct
     * @param account Address you want to use tokens
     * @param amount Number of tokens to use
     */
    function use(Members storage members, address account, uint256 amount) internal {
        require(isMember(members, account));

        Member storage member = members.list[members.addressMap[account]];

        require(member.stakedTokens >= amount);

        member.stakedTokens = member.stakedTokens.sub(amount);
        members.totalStakedTokens = members.totalStakedTokens.sub(amount);

        member.usedTokens = member.usedTokens.add(amount);
        members.totalUsedTokens = members.totalUsedTokens.add(amount);
    }

    /**
     * @dev Set the approved status for a member
     * @param members Current members struct
     * @param account Address you want to update
     * @param status Bool the new status for approved
     */
    function setApproved(Members storage members, address account, bool status) internal {
        require(isMember(members, account));

        Member storage member = members.list[members.addressMap[account]];

        member.approved = status;
    }

    /**
     * @dev Set data for a member
     * @param members Current members struct
     * @param account Address you want to update
     * @param data bytes32 updated data
     */
    function setData(Members storage members, address account, bytes32 data) internal {
        require(isMember(members, account));

        Member storage member = members.list[members.addressMap[account]];

        member.data = data;
    }

    /**
     * @dev Generate a member fingerprint
     * @param account Address you want to make member
     * @param memberId The member id
     * @return bytes9 It represents member fingerprint
     */
    function getFingerprint(address account, uint256 memberId) private pure returns (bytes9) {
        return bytes9(keccak256(abi.encodePacked(account, memberId)));
    }
}

// File: dao-smartcontracts/contracts/dao/DAO.sol

/**
 * @title DAO
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev It identifies the DAO and Organization logic
 */
contract DAO is ERC1363Payable, DAORoles {
    using SafeMath for uint256;

    using Organization for Organization.Members;
    using Organization for Organization.Member;

    event MemberAdded(
        address indexed account,
        uint256 id
    );

    event MemberStatusChanged(
        address indexed account,
        bool approved
    );

    event TokensStaked(
        address indexed account,
        uint256 value
    );

    event TokensUnstaked(
        address indexed account,
        uint256 value
    );

    event TokensUsed(
        address indexed account,
        address indexed dapp,
        uint256 value
    );

    Organization.Members private _members;

    constructor (IERC1363 acceptedToken) public ERC1363Payable(acceptedToken) {} // solhint-disable-line no-empty-blocks

    /**
     * @dev fallback. This function will create a new member
     */
    function () external payable { // solhint-disable-line no-complex-fallback
        require(msg.value == 0);

        _newMember(msg.sender);
    }

    /**
     * @dev Generate a new member and the member structure
     */
    function join() external {
        _newMember(msg.sender);
    }

    /**
     * @dev Generate a new member and the member structure
     * @param account Address you want to make member
     */
    function newMember(address account) external onlyOperator {
        _newMember(account);
    }

    /**
     * @dev Set the approved status for a member
     * @param account Address you want to update
     * @param status Bool the new status for approved
     */
    function setApproved(address account, bool status) external onlyOperator {
        _members.setApproved(account, status);

        emit MemberStatusChanged(account, status);
    }

    /**
     * @dev Set data for a member
     * @param account Address you want to update
     * @param data bytes32 updated data
     */
    function setData(address account, bytes32 data) external onlyOperator {
        _members.setData(account, data);
    }

    /**
     * @dev Use tokens from a specific account
     * @param account Address to use the tokens from
     * @param amount Number of tokens to use
     */
    function use(address account, uint256 amount) external onlyDapp {
        _members.use(account, amount);

        IERC20(acceptedToken()).transfer(msg.sender, amount);

        emit TokensUsed(account, msg.sender, amount);
    }

    /**
     * @dev Remove tokens from member stack
     * @param amount Number of tokens to unstake
     */
    function unstake(uint256 amount) public {
        _members.unstake(msg.sender, amount);

        IERC20(acceptedToken()).transfer(msg.sender, amount);

        emit TokensUnstaked(msg.sender, amount);
    }

    /**
     * @dev Returns the members number
     * @return uint256
     */
    function membersNumber() public view returns (uint256) {
        return _members.count;
    }

    /**
     * @dev Returns the total staked tokens number
     * @return uint256
     */
    function totalStakedTokens() public view returns (uint256) {
        return _members.totalStakedTokens;
    }

    /**
     * @dev Returns the total used tokens number
     * @return uint256
     */
    function totalUsedTokens() public view returns (uint256) {
        return _members.totalUsedTokens;
    }

    /**
     * @dev Returns if an address is member or not
     * @param account Address of the member you are looking for
     * @return bool
     */
    function isMember(address account) public view returns (bool) {
        return _members.isMember(account);
    }

    /**
     * @dev Get creation date of a member
     * @param account Address you want to check
     * @return uint256 Member creation date, zero otherwise
     */
    function creationDateOf(address account) public view returns (uint256) {
        return _members.creationDateOf(account);
    }

    /**
     * @dev Check how many tokens staked for given address
     * @param account Address you want to check
     * @return uint256 Member staked tokens
     */
    function stakedTokensOf(address account) public view returns (uint256) {
        return _members.stakedTokensOf(account);
    }

    /**
     * @dev Check how many tokens used for given address
     * @param account Address you want to check
     * @return uint256 Member used tokens
     */
    function usedTokensOf(address account) public view returns (uint256) {
        return _members.usedTokensOf(account);
    }

    /**
     * @dev Check if an address has been approved
     * @param account Address you want to check
     * @return bool
     */
    function isApproved(address account) public view returns (bool) {
        return _members.isApproved(account);
    }

    /**
     * @dev Returns the member structure
     * @param memberAddress Address of the member you are looking for
     * @return array
     */
    function getMemberByAddress(address memberAddress)
        public
        view
        returns (
            uint256 id,
            address account,
            bytes9 fingerprint,
            uint256 creationDate,
            uint256 stakedTokens,
            uint256 usedTokens,
            bytes32 data,
            bool approved
        )
    {
        return getMemberById(_members.addressMap[memberAddress]);
    }

    /**
     * @dev Returns the member structure
     * @param memberId Id of the member you are looking for
     * @return array
     */
    function getMemberById(uint256 memberId)
        public
        view
        returns (
            uint256 id,
            address account,
            bytes9 fingerprint,
            uint256 creationDate,
            uint256 stakedTokens,
            uint256 usedTokens,
            bytes32 data,
            bool approved
        )
    {
        Organization.Member storage structure = _members.getMember(memberId);

        id = structure.id;
        account = structure.account;
        fingerprint = structure.fingerprint;
        creationDate = structure.creationDate;
        stakedTokens = structure.stakedTokens;
        usedTokens = structure.usedTokens;
        data = structure.data;
        approved = structure.approved;
    }

    /**
     * @dev Allow to recover tokens from contract
     * @param tokenAddress address The token contract address
     * @param tokenAmount uint256 Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyOwner {
        if (tokenAddress == address(acceptedToken())) {
            uint256 currentBalance = IERC20(acceptedToken()).balanceOf(address(this));
            require(currentBalance.sub(_members.totalStakedTokens) >= tokenAmount);
        }

        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    /**
     * @dev Called after validating a `onTransferReceived`
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     */
    function _transferReceived(
        address operator, // solhint-disable-line no-unused-vars
        address from,
        uint256 value,
        bytes memory data // solhint-disable-line no-unused-vars
    )
        internal
    {
        _stake(from, value);
    }

    /**
     * @dev Called after validating a `onApprovalReceived`
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     */
    function _approvalReceived(
        address owner,
        uint256 value,
        bytes memory data // solhint-disable-line no-unused-vars
    )
        internal
    {
        IERC20(acceptedToken()).transferFrom(owner, address(this), value);

        _stake(owner, value);
    }

    /**
     * @dev Generate a new member and the member structure
     * @param account Address you want to make member
     * @return uint256 The new member id
     */
    function _newMember(address account) internal {
        uint256 memberId = _members.addMember(account);

        emit MemberAdded(account, memberId);
    }

    /**
     * @dev Add tokens to member stack
     * @param account Address you want to stake tokens
     * @param amount Number of tokens to stake
     */
    function _stake(address account, uint256 amount) internal {
        if (!isMember(account)) {
            _newMember(account);
        }

        _members.stake(account, amount);

        emit TokensStaked(account, amount);
    }
}

// File: contracts/faucet/TokenFaucet.sol

/**
 * @title TokenFaucet
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of a TokenFaucet
 */
contract TokenFaucet is TokenRecover {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event FaucetCreated(address indexed token);

    // struct representing the enabled faucet
    struct FaucetDetail {
        bool exists;
        bool enabled;
        uint256 dailyRate;
        uint256 referralRate;
        uint256 totalDistributedTokens;
    }

    // struct representing the faucet status for an account
    struct RecipientDetail {
        bool exists;
        mapping(address => uint256) tokens;
        mapping(address => uint256) lastUpdate;
        address referral;
    }

    // struct representing the referral status
    struct ReferralDetail {
        mapping(address => uint256) tokens;
        address[] recipients;
    }

    // the time between two tokens claim
    uint256 private _pauseTime = 1 days;

    // the DAO smart contract
    DAO private _dao;

    // list of addresses who received tokens
    address[] private _recipients;

    // map of address and faucet details
    mapping(address => FaucetDetail) private _faucetList;

    // map of address and received token amount
    mapping(address => RecipientDetail) private _recipientList;

    // map of address and referred addresses
    mapping(address => ReferralDetail) private _referralList;

    /**
     * @param dao DAO the decentralized organization address
     */
    constructor(address payable dao) public {
        require(dao != address(0), "TokenFaucet: dao is the zero address");

        _dao = DAO(dao);
    }

    /**
     * @return the DAO smart contract
     */
    function dao() public view returns (DAO) {
        return _dao;
    }

    /**
     * @param token The token address to check
     * @return if faucet is enabled or not
     */
    function isEnabled(address token) public view returns (bool) {
        return _faucetList[token].enabled;
    }

    /**
     * @param token The token address to check
     * @return the daily rate of tokens distributed
     */
    function getDailyRate(address token) public view returns (uint256) {
        return _faucetList[token].dailyRate;
    }

    /**
     * @param token The token address to check
     * @return the value earned by referral for each recipient
     */
    function getReferralRate(address token) public view returns (uint256) {
        return _faucetList[token].referralRate;
    }

    /**
     * @param token The token address to check
     * @return the sum of distributed tokens
     */
    function totalDistributedTokens(address token) public view returns (uint256) {
        return _faucetList[token].totalDistributedTokens;
    }

    /**
     * @dev return the number of remaining tokens to distribute
     * @param token The token address to check
     * @return uint256
     */
    function remainingTokens(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @return address of a recipient by list index
     */
    function getRecipientAddress(uint256 index) public view returns (address) {
        return _recipients[index];
    }

    /**
     * @dev return the recipients length
     * @return uint
     */
    function getRecipientsLength() public view returns (uint) {
        return _recipients.length;
    }

    /**
     * @param account The address to check
     * @param token The token address to check
     * @return received token amount for the given address
     */
    function receivedTokens(address account, address token) public view returns (uint256) {
        return _recipientList[account].tokens[token];
    }

    /**
     * @param account The address to check
     * @param token The token address to check
     * @return last tokens received timestamp
     */
    function lastUpdate(address account, address token) public view returns (uint256) {
        return _recipientList[account].lastUpdate[token];
    }

    /**
     * @param account The address to check
     * @return referral for given address
     */
    function getReferral(address account) public view returns (address) {
        return _recipientList[account].referral;
    }

    /**
     * @param account The address to check
     * @param token The token address to check
     * @return earned tokens by referrals
     */
    function earnedByReferral(address account, address token) public view returns (uint256) {
        return _referralList[account].tokens[token];
    }

    /**
     * @param account The address to check
     * @return referred addresses for given address
     */
    function getReferredAddresses(address account) public view returns (address[] memory) {
        return _referralList[account].recipients;
    }

    /**
     * @param account The address to check
     * @return referred addresses for given address
     */
    function getReferredAddressesLength(address account) public view returns (uint) {
        return _referralList[account].recipients.length;
    }

    /**
     * @param account The address to check
     * @param token The token address to check
     * @return time of next available claim or zero
     */
    function nextClaimTime(address account, address token) public view returns (uint256) {
        return lastUpdate(account, token) == 0 ? 0 : lastUpdate(account, token) + _pauseTime;
    }

    /**
     * @param token Address of the token being distributed
     * @param dailyRate Daily rate of tokens distributed
     * @param referralRate The value earned by referral
     */
    function createFaucet(address token, uint256 dailyRate, uint256 referralRate) public onlyOwner {
        require(!_faucetList[token].exists, "TokenFaucet: token faucet already exists");
        require(token != address(0), "TokenFaucet: token is the zero address");
        require(dailyRate > 0, "TokenFaucet: dailyRate is 0");
        require(referralRate > 0, "TokenFaucet: referralRate is 0");

        _faucetList[token].exists = true;
        _faucetList[token].enabled = true;
        _faucetList[token].dailyRate = dailyRate;
        _faucetList[token].referralRate = referralRate;

        emit FaucetCreated(token);
    }

    /**
     * @dev change daily referral rate
     * @param token Address of tokens being updated
     * @param newDailyRate Daily rate of tokens distributed
     * @param newReferralRate The value earned by referral
     */
    function setFaucetRates(address token, uint256 newDailyRate, uint256 newReferralRate) public onlyOwner {
        require(_faucetList[token].exists, "TokenFaucet: token faucet does not exist");
        require(newDailyRate > 0, "TokenFaucet: dailyRate is 0");
        require(newReferralRate > 0, "TokenFaucet: referralRate is 0");

        _faucetList[token].dailyRate = newDailyRate;
        _faucetList[token].referralRate = newReferralRate;
    }

    /**
     * @dev disable a faucet
     * @param token Address of tokens being updated
     */
    function disableFaucet(address token) public onlyOwner {
        require(_faucetList[token].exists, "TokenFaucet: token faucet does not exist");

        _faucetList[token].enabled = false;
    }

    /**
     * @dev enable a faucet
     * @param token Address of tokens being updated
     */
    function enableFaucet(address token) public onlyOwner {
        require(_faucetList[token].exists, "TokenFaucet: token faucet does not exist");

        _faucetList[token].enabled = true;
    }

    /**
     * @dev function to be called to receive tokens
     * @param token The token address to distribute
     */
    function getTokens(address token) public {
        require(_faucetList[token].exists, "TokenFaucet: token faucet does not exist");
        require(_dao.isMember(msg.sender), "TokenFaucet: message sender is not dao member");

        // distribute tokens
        _distributeTokens(token, msg.sender, address(0));
    }

    /**
     * @dev function to be called to receive tokens
     * @param token The token address to distribute
     * @param referral Address to an account that is referring
     */
    function getTokensWithReferral(address token, address referral) public {
        require(_faucetList[token].exists, "TokenFaucet: token faucet does not exist");
        require(_dao.isMember(msg.sender), "TokenFaucet: message sender is not dao member");
        require(referral != msg.sender, "TokenFaucet: referral cannot be message sender");

        // distribute tokens
        _distributeTokens(token, msg.sender, referral);
    }

    /**
     * @dev The way in which faucet tokens rate is calculated for recipient
     * @param token Address of tokens being distributed
     * @param account Address receiving the tokens
     * @return Number of tokens that can be received
     */
    function _getRecipientTokenAmount(address token, address account) internal view returns (uint256) {
        uint256 tokenAmount = getDailyRate(token);

        if (_dao.stakedTokensOf(account) > 0) {
            tokenAmount = tokenAmount.mul(2);
        }

        if (_dao.usedTokensOf(account) > 0) {
            tokenAmount = tokenAmount.mul(2);
        }

        return tokenAmount;
    }

    /**
     * @dev The way in which faucet tokens rate is calculated for referral
     * @param token Address of tokens being distributed
     * @param account Address receiving the tokens
     * @return Number of tokens that can be received
     */
    function _getReferralTokenAmount(address token, address account) internal view returns (uint256) {
        uint256 tokenAmount = 0;

        if (_dao.isMember(account)) {
            tokenAmount = getReferralRate(token);

            if (_dao.stakedTokensOf(account) > 0) {
                tokenAmount = tokenAmount.mul(2);
            }

            if (_dao.usedTokensOf(account) > 0) {
                tokenAmount = tokenAmount.mul(2);
            }
        }

        return tokenAmount;
    }

    /**
     * @dev distribute tokens
     * @param token The token being distributed
     * @param account Address being distributing
     * @param referral Address to an account that is referring
     */
    function _distributeTokens(address token, address account, address referral) internal {
        // solhint-disable-next-line not-rely-on-time
        require(nextClaimTime(account, token) <= block.timestamp, "TokenFaucet: next claim date is not passed");

        // check if recipient exists
        if (!_recipientList[account].exists) {
            _recipients.push(account);
            _recipientList[account].exists = true;

            // check if valid referral
            if (referral != address(0)) {
                _recipientList[account].referral = referral;
                _referralList[referral].recipients.push(account);
            }
        }

        uint256 recipientTokenAmount = _getRecipientTokenAmount(token, account);

        // update recipient status

        // solhint-disable-next-line not-rely-on-time
        _recipientList[account].lastUpdate[token] = block.timestamp;
        _recipientList[account].tokens[token] = _recipientList[account].tokens[token].add(recipientTokenAmount);

        // update faucet status
        _faucetList[token].totalDistributedTokens = _faucetList[token].totalDistributedTokens.add(recipientTokenAmount);

        // transfer tokens to recipient
        IERC20(token).safeTransfer(account, recipientTokenAmount);

        // check referral

        if (_recipientList[account].referral != address(0)) {
            // referral is only the first one referring
            address firstReferral = _recipientList[account].referral;

            uint256 referralTokenAmount = _getReferralTokenAmount(token, firstReferral);

            // referral can earn only if it is dao member
            if (referralTokenAmount > 0) {
                // update referral status
                _referralList[firstReferral].tokens[token] = _referralList[firstReferral].tokens[token].add(referralTokenAmount);

                // update faucet status
                _faucetList[token].totalDistributedTokens = _faucetList[token].totalDistributedTokens.add(referralTokenAmount);

                // transfer tokens to referral
                IERC20(token).safeTransfer(firstReferral, referralTokenAmount);
            }
        }
    }
}