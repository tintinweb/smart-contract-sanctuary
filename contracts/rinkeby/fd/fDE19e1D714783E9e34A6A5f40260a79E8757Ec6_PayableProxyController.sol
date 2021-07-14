/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-28
*/

/**
 * SPDX-License-Identifier: UNLICENSED
 */

pragma solidity 0.6.10;

pragma experimental ABIEncoderV2;


// File: contracts/external/canonical-weth/WETH9.sol

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

/**
 * @title WETH contract
 * @author Opyn Team
 * @dev A wrapper to use ETH as collateral
 */
contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    /// @notice emits an event when a sender approves WETH
    event Approval(address indexed src, address indexed guy, uint256 wad);
    /// @notice emits an event when a sender transfers WETH
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    /// @notice emits an event when a sender deposits ETH into this contract
    event Deposit(address indexed dst, uint256 wad);
    /// @notice emits an event when a sender withdraws ETH from this contract
    event Withdrawal(address indexed src, uint256 wad);

    /// @notice mapping between address and WETH balance
    mapping(address => uint256) public balanceOf;
    /// @notice mapping between addresses and allowance amount
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @notice fallback function that receives ETH
     * @dev will get called in a tx with ETH
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice wrap deposited ETH into WETH
     */
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice withdraw ETH from contract
     * @dev Unwrap from WETH to ETH
     * @param _wad amount WETH to unwrap and withdraw
     */
    function withdraw(uint256 _wad) public {
        require(balanceOf[msg.sender] >= _wad, "WETH9: insufficient sender balance");
        balanceOf[msg.sender] -= _wad;
        msg.sender.transfer(_wad);
        emit Withdrawal(msg.sender, _wad);
    }

    /**
     * @notice get ETH total supply
     * @return total supply
     */
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice approve transfer
     * @param _guy address to approve
     * @param _wad amount of WETH
     * @return True if tx succeeds, False if not
     */
    function approve(address _guy, uint256 _wad) public returns (bool) {
        allowance[msg.sender][_guy] = _wad;
        emit Approval(msg.sender, _guy, _wad);
        return true;
    }

    /**
     * @notice transfer WETH
     * @param _dst destination address
     * @param _wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transfer(address _dst, uint256 _wad) public returns (bool) {
        return transferFrom(msg.sender, _dst, _wad);
    }

    /**
     * @notice transfer from address
     * @param _src source address
     * @param _dst destination address
     * @param _wad amount to transfer
     * @return True if tx succeeds, False if not
     */
    function transferFrom(
        address _src,
        address _dst,
        uint256 _wad
    ) public returns (bool) {
        require(balanceOf[_src] >= _wad, "WETH9: insufficient source balance");

        if (_src != msg.sender && allowance[_src][msg.sender] != uint256(-1)) {
            require(allowance[_src][msg.sender] >= _wad, "WETH9: invalid allowance");
            allowance[_src][msg.sender] -= _wad;
        }

        balanceOf[_src] -= _wad;
        balanceOf[_dst] += _wad;

        emit Transfer(_src, _dst, _wad);

        return true;
    }
}

// File: contracts/packages/oz/ReentrancyGuard.sol


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
contract ReentrancyGuard {
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

    constructor() internal {
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

// File: contracts/interfaces/ERC20Interface.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ERC20Interface {
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

    function decimals() external view returns (uint8);

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

// File: contracts/packages/oz/SafeMath.sol


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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

// File: contracts/packages/oz/Address.sol

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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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

// File: contracts/packages/oz/SafeERC20.sol




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20Interface;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        ERC20Interface token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        ERC20Interface token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {ERC20Interface-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        ERC20Interface token,
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        ERC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        ERC20Interface token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(ERC20Interface token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/libs/MarginVault.sol



/**
 * @title MarginVault
 * @author Opyn Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVault {
    using SafeMath for uint256;

    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }

    /**
     * @dev increase the short oToken balance in a vault when a new oToken is minted
     * @param _vault vault to add or increase the short position in
     * @param _shortOtoken address of the _shortOtoken being minted from the user's vault
     * @param _amount number of _shortOtoken being minted from the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function addShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid short otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.shortOtokens.length) && (_index == _vault.shortAmounts.length)) {
            _vault.shortOtokens.push(_shortOtoken);
            _vault.shortAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.shortOtokens.length) && (_index < _vault.shortAmounts.length),
                "MarginVault: invalid short otoken index"
            );
            require(
                (_vault.shortOtokens[_index] == _shortOtoken) || (_vault.shortOtokens[_index] == address(0)),
                "MarginVault: short otoken address mismatch"
            );

            _vault.shortAmounts[_index] = _vault.shortAmounts[_index].add(_amount);
            _vault.shortOtokens[_index] = _shortOtoken;
        }
    }

    /**
     * @dev decrease the short oToken balance in a vault when an oToken is burned
     * @param _vault vault to decrease short position in
     * @param _shortOtoken address of the _shortOtoken being reduced in the user's vault
     * @param _amount number of _shortOtoken being reduced in the user's vault
     * @param _index index of _shortOtoken in the user's vault.shortOtokens array
     */
    function removeShort(
        Vault storage _vault,
        address _shortOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed short oToken exists in the vault at the specified index
        require(_index < _vault.shortOtokens.length, "MarginVault: invalid short otoken index");
        require(_vault.shortOtokens[_index] == _shortOtoken, "MarginVault: short otoken address mismatch");

        _vault.shortAmounts[_index] = _vault.shortAmounts[_index].sub(_amount);

        if (_vault.shortAmounts[_index] == 0) {
            delete _vault.shortOtokens[_index];
        }
    }

    /**
     * @dev increase the long oToken balance in a vault when an oToken is deposited
     * @param _vault vault to add a long position to
     * @param _longOtoken address of the _longOtoken being added to the user's vault
     * @param _amount number of _longOtoken the protocol is adding to the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function addLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid long otoken amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.longOtokens.length) && (_index == _vault.longAmounts.length)) {
            _vault.longOtokens.push(_longOtoken);
            _vault.longAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.longOtokens.length) && (_index < _vault.longAmounts.length),
                "MarginVault: invalid long otoken index"
            );
            require(
                (_vault.longOtokens[_index] == _longOtoken) || (_vault.longOtokens[_index] == address(0)),
                "MarginVault: long otoken address mismatch"
            );

            _vault.longAmounts[_index] = _vault.longAmounts[_index].add(_amount);
            _vault.longOtokens[_index] = _longOtoken;
        }
    }

    /**
     * @dev decrease the long oToken balance in a vault when an oToken is withdrawn
     * @param _vault vault to remove a long position from
     * @param _longOtoken address of the _longOtoken being removed from the user's vault
     * @param _amount number of _longOtoken the protocol is removing from the user's vault
     * @param _index index of _longOtoken in the user's vault.longOtokens array
     */
    function removeLong(
        Vault storage _vault,
        address _longOtoken,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed long oToken exists in the vault at the specified index
        require(_index < _vault.longOtokens.length, "MarginVault: invalid long otoken index");
        require(_vault.longOtokens[_index] == _longOtoken, "MarginVault: long otoken address mismatch");

        _vault.longAmounts[_index] = _vault.longAmounts[_index].sub(_amount);

        if (_vault.longAmounts[_index] == 0) {
            delete _vault.longOtokens[_index];
        }
    }

    /**
     * @dev increase the collateral balance in a vault
     * @param _vault vault to add collateral to
     * @param _collateralAsset address of the _collateralAsset being added to the user's vault
     * @param _amount number of _collateralAsset being added to the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function addCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        require(_amount > 0, "MarginVault: invalid collateral amount");

        // valid indexes in any array are between 0 and array.length - 1.
        // if adding an amount to an preexisting short oToken, check that _index is in the range of 0->length-1
        if ((_index == _vault.collateralAssets.length) && (_index == _vault.collateralAmounts.length)) {
            _vault.collateralAssets.push(_collateralAsset);
            _vault.collateralAmounts.push(_amount);
        } else {
            require(
                (_index < _vault.collateralAssets.length) && (_index < _vault.collateralAmounts.length),
                "MarginVault: invalid collateral token index"
            );
            require(
                (_vault.collateralAssets[_index] == _collateralAsset) ||
                    (_vault.collateralAssets[_index] == address(0)),
                "MarginVault: collateral token address mismatch"
            );

            _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].add(_amount);
            _vault.collateralAssets[_index] = _collateralAsset;
        }
    }

    /**
     * @dev decrease the collateral balance in a vault
     * @param _vault vault to remove collateral from
     * @param _collateralAsset address of the _collateralAsset being removed from the user's vault
     * @param _amount number of _collateralAsset being removed from the user's vault
     * @param _index index of _collateralAsset in the user's vault.collateralAssets array
     */
    function removeCollateral(
        Vault storage _vault,
        address _collateralAsset,
        uint256 _amount,
        uint256 _index
    ) external {
        // check that the removed collateral exists in the vault at the specified index
        require(_index < _vault.collateralAssets.length, "MarginVault: invalid collateral asset index");
        require(_vault.collateralAssets[_index] == _collateralAsset, "MarginVault: collateral token address mismatch");

        _vault.collateralAmounts[_index] = _vault.collateralAmounts[_index].sub(_amount);

        if (_vault.collateralAmounts[_index] == 0) {
            delete _vault.collateralAssets[_index];
        }
    }
}

// File: contracts/libs/Actions.sol


/**
 * @title Actions
 * @author Opyn Team
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 */
library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an open vault action
     * @param _args general action arguments structure
     * @return arguments for a open vault action
     */
    function _parseOpenVaultArgs(ActionArgs memory _args) internal pure returns (OpenVaultArgs memory) {
        require(_args.actionType == ActionType.OpenVault, "Actions: can only parse arguments for open vault actions");
        require(_args.owner != address(0), "Actions: cannot open vault for an invalid account");

        return OpenVaultArgs({owner: _args.owner, vaultId: _args.vaultId});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a mint action
     * @param _args general action arguments structure
     * @return arguments for a mint action
     */
    function _parseMintArgs(ActionArgs memory _args) internal pure returns (MintArgs memory) {
        require(_args.actionType == ActionType.MintShortOption, "Actions: can only parse arguments for mint actions");
        require(_args.owner != address(0), "Actions: cannot mint from an invalid account");

        return
            MintArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a burn action
     * @param _args general action arguments structure
     * @return arguments for a burn action
     */
    function _parseBurnArgs(ActionArgs memory _args) internal pure returns (BurnArgs memory) {
        require(_args.actionType == ActionType.BurnShortOption, "Actions: can only parse arguments for burn actions");
        require(_args.owner != address(0), "Actions: cannot burn from an invalid account");

        return
            BurnArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                otoken: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a deposit action
     * @param _args general action arguments structure
     * @return arguments for a deposit action
     */
    function _parseDepositArgs(ActionArgs memory _args) internal pure returns (DepositArgs memory) {
        require(
            (_args.actionType == ActionType.DepositLongOption) || (_args.actionType == ActionType.DepositCollateral),
            "Actions: can only parse arguments for deposit actions"
        );
        require(_args.owner != address(0), "Actions: cannot deposit to an invalid account");

        return
            DepositArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                from: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a withdraw action
     * @param _args general action arguments structure
     * @return arguments for a withdraw action
     */
    function _parseWithdrawArgs(ActionArgs memory _args) internal pure returns (WithdrawArgs memory) {
        require(
            (_args.actionType == ActionType.WithdrawLongOption) || (_args.actionType == ActionType.WithdrawCollateral),
            "Actions: can only parse arguments for withdraw actions"
        );
        require(_args.owner != address(0), "Actions: cannot withdraw from an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw to an invalid account");

        return
            WithdrawArgs({
                owner: _args.owner,
                vaultId: _args.vaultId,
                to: _args.secondAddress,
                asset: _args.asset,
                index: _args.index,
                amount: _args.amount
            });
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for an redeem action
     * @param _args general action arguments structure
     * @return arguments for a redeem action
     */
    function _parseRedeemArgs(ActionArgs memory _args) internal pure returns (RedeemArgs memory) {
        require(_args.actionType == ActionType.Redeem, "Actions: can only parse arguments for redeem actions");
        require(_args.secondAddress != address(0), "Actions: cannot redeem to an invalid account");

        return RedeemArgs({receiver: _args.secondAddress, otoken: _args.asset, amount: _args.amount});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a settle vault action
     * @param _args general action arguments structure
     * @return arguments for a settle vault action
     */
    function _parseSettleVaultArgs(ActionArgs memory _args) internal pure returns (SettleVaultArgs memory) {
        require(
            _args.actionType == ActionType.SettleVault,
            "Actions: can only parse arguments for settle vault actions"
        );
        require(_args.owner != address(0), "Actions: cannot settle vault for an invalid account");
        require(_args.secondAddress != address(0), "Actions: cannot withdraw payout to an invalid account");

        return SettleVaultArgs({owner: _args.owner, vaultId: _args.vaultId, to: _args.secondAddress});
    }

    /**
     * @notice parses the passed in action arguments to get the arguments for a call action
     * @param _args general action arguments structure
     * @return arguments for a call action
     */
    function _parseCallArgs(ActionArgs memory _args) internal pure returns (CallArgs memory) {
        require(_args.actionType == ActionType.Call, "Actions: can only parse arguments for call actions");
        require(_args.secondAddress != address(0), "Actions: target address cannot be address(0)");

        return CallArgs({callee: _args.secondAddress, data: _args.data});
    }
}

// File: contracts/packages/oz/upgradeability/Initializable.sol

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// File: contracts/packages/oz/upgradeability/ContextUpgradeSafe.sol


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: contracts/packages/oz/upgradeability/OwnableUpgradeSafe.sol

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init(address _sender) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(_sender);
    }

    function __Ownable_init_unchained(address _sender) internal initializer {
        _owner = _sender;
        emit OwnershipTransferred(address(0), _sender);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: contracts/packages/oz/upgradeability/ReentrancyGuardUpgradeSafe.sol



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
contract ReentrancyGuardUpgradeSafe is Initializable {
    bool private _notEntered;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    uint256[49] private __gap;
}

// File: contracts/interfaces/AddressBookInterface.sol


interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracleImpl(address _otokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// File: contracts/interfaces/OtokenInterface.sol


interface OtokenInterface {
    function addressBook() external view returns (address);

    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

// File: contracts/interfaces/MarginCalculatorInterface.sol



interface MarginCalculatorInterface {
    function addressBook() external view returns (address);

    function getExpiredPayoutRate(address _otoken) external view returns (uint256);

    function getExcessCollateral(MarginVault.Vault calldata _vault)
        external
        view
        returns (uint256 netValue, bool isExcess);
}

// File: contracts/interfaces/OracleInterface.sol


interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

// File: contracts/interfaces/WhitelistInterface.sol


interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOtoken(address _otoken) external;

    function blacklistOtoken(address _otoken) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}

// File: contracts/interfaces/MarginPoolInterface.sol


interface MarginPoolInterface {
    /* Getters */
    function addressBook() external view returns (address);

    function farmer() external view returns (address);

    function getStoredBalance(address _asset) external view returns (uint256);

    /* Admin-only functions */
    function setFarmer(address _farmer) external;

    function farm(
        address _asset,
        address _receiver,
        uint256 _amount
    ) external;

    /* Controller-only functions */
    function transferToPool(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function transferToUser(
        address _asset,
        address _user,
        uint256 _amount
    ) external;

    function batchTransferToPool(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;

    function batchTransferToUser(
        address[] calldata _asset,
        address[] calldata _user,
        uint256[] calldata _amount
    ) external;
}

// File: contracts/interfaces/CalleeInterface.sol


/**
 * @dev Contract interface that can be called from Controller as a call action.
 */
interface CalleeInterface {
    /**
     * Allows users to send this contract arbitrary data.
     * @param _sender The msg.sender to Controller
     * @param _data Arbitrary data given by the sender
     */
    function callFunction(address payable _sender, bytes memory _data) external;
}

// File: contracts/Controller.sol

/**














/**
 * @title Controller
 * @author Opyn Team
 * @notice Contract that controls the Gamma Protocol and the interaction of all sub contracts
 */
contract Controller is Initializable, OwnableUpgradeSafe, ReentrancyGuardUpgradeSafe {
    using MarginVault for MarginVault.Vault;
    using SafeMath for uint256;

    AddressBookInterface public addressbook;
    WhitelistInterface public whitelist;
    OracleInterface public oracle;
    MarginCalculatorInterface public calculator;
    MarginPoolInterface public pool;

    ///@dev scale used in MarginCalculator
    uint256 internal constant BASE = 8;

    /// @notice address that has permission to partially pause the system, where system functionality is paused
    /// except redeem and settleVault
    address public partialPauser;

    /// @notice address that has permission to fully pause the system, where all system functionality is paused
    address public fullPauser;

    /// @notice True if all system functionality is paused other than redeem and settle vault
    bool public systemPartiallyPaused;

    /// @notice True if all system functionality is paused
    bool public systemFullyPaused;

    /// @notice True if a call action can only be executed to a whitelisted callee
    bool public callRestricted;

    /// @dev mapping between an owner address and the number of owner address vaults
    mapping(address => uint256) internal accountVaultCounter;
    /// @dev mapping between an owner address and a specific vault using a vault id
    mapping(address => mapping(uint256 => MarginVault.Vault)) internal vaults;
    /// @dev mapping between an account owner and their approved or unapproved account operators
    mapping(address => mapping(address => bool)) internal operators;

    /// @notice emits an event when an account operator is updated for a specific account owner
    event AccountOperatorUpdated(address indexed accountOwner, address indexed operator, bool isSet);
    /// @notice emits an event when a new vault is opened
    event VaultOpened(address indexed accountOwner, uint256 vaultId);
    /// @notice emits an event when a long oToken is deposited into a vault
    event LongOtokenDeposited(
        address indexed otoken,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a long oToken is withdrawn from a vault
    event LongOtokenWithdrawed(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is deposited into a vault
    event CollateralAssetDeposited(
        address indexed asset,
        address indexed accountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a collateral asset is withdrawn from a vault
    event CollateralAssetWithdrawed(
        address indexed asset,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short oToken is minted from a vault
    event ShortOtokenMinted(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed to,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when a short oToken is burned
    event ShortOtokenBurned(
        address indexed otoken,
        address indexed AccountOwner,
        address indexed from,
        uint256 vaultId,
        uint256 amount
    );
    /// @notice emits an event when an oToken is redeemed
    event Redeem(
        address indexed otoken,
        address indexed redeemer,
        address indexed receiver,
        address collateralAsset,
        uint256 otokenBurned,
        uint256 payout
    );
    /// @notice emits an event when a vault is settled
    event VaultSettled(
        address indexed AccountOwner,
        address indexed to,
        address indexed otoken,
        uint256 vaultId,
        uint256 payout
    );
    /// @notice emits an event when a call action is executed
    event CallExecuted(address indexed from, address indexed to, bytes data);
    /// @notice emits an event when the fullPauser address changes
    event FullPauserUpdated(address indexed oldFullPauser, address indexed newFullPauser);
    /// @notice emits an event when the partialPauser address changes
    event PartialPauserUpdated(address indexed oldPartialPauser, address indexed newPartialPauser);
    /// @notice emits an event when the system partial paused status changes
    event SystemPartiallyPaused(bool isPaused);
    /// @notice emits an event when the system fully paused status changes
    event SystemFullyPaused(bool isPaused);
    /// @notice emits an event when the call action restriction changes
    event CallRestricted(bool isRestricted);

    /**
     * @notice modifier to check if the system is not partially paused, where only redeem and settleVault is allowed
     */
    modifier notPartiallyPaused {
        _isNotPartiallyPaused();

        _;
    }

    /**
     * @notice modifier to check if the system is not fully paused, where no functionality is allowed
     */
    modifier notFullyPaused {
        _isNotFullyPaused();

        _;
    }

    /**
     * @notice modifier to check if sender is the fullPauser address
     */
    modifier onlyFullPauser {
        require(msg.sender == fullPauser, "Controller: sender is not fullPauser");

        _;
    }

    /**
     * @notice modifier to check if the sender is the partialPauser address
     */
    modifier onlyPartialPauser {
        require(msg.sender == partialPauser, "Controller: sender is not partialPauser");

        _;
    }

    /**
     * @notice modifier to check if the sender is the account owner or an approved account operator
     * @param _sender sender address
     * @param _accountOwner account owner address
     */
    modifier onlyAuthorized(address _sender, address _accountOwner) {
        _isAuthorized(_sender, _accountOwner);

        _;
    }

    /**
     * @notice modifier to check if the called address is a whitelisted callee address
     * @param _callee called address
     */
    modifier onlyWhitelistedCallee(address _callee) {
        if (callRestricted) {
            require(_isCalleeWhitelisted(_callee), "Controller: callee is not a whitelisted address");
        }

        _;
    }

    /**
     * @dev check if the system is not in a partiallyPaused state
     */
    function _isNotPartiallyPaused() internal view {
        require(!systemPartiallyPaused, "Controller: system is partially paused");
    }

    /**
     * @dev check if the system is not in an fullyPaused state
     */
    function _isNotFullyPaused() internal view {
        require(!systemFullyPaused, "Controller: system is fully paused");
    }

    /**
     * @dev check if the sender is an authorized operator
     * @param _sender msg.sender
     * @param _accountOwner owner of a vault
     */
    function _isAuthorized(address _sender, address _accountOwner) internal view {
        require(
            (_sender == _accountOwner) || (operators[_accountOwner][_sender]),
            "Controller: msg.sender is not authorized to run action"
        );
    }

    /**
     * @notice initalize the deployed contract
     * @param _addressBook addressbook module
     * @param _owner account owner address
     */
    function initialize(address _addressBook, address _owner) external initializer {
        require(_addressBook != address(0), "Controller: invalid addressbook address");
        require(_owner != address(0), "Controller: invalid owner address");

        __Ownable_init(_owner);
        __ReentrancyGuard_init_unchained();

        addressbook = AddressBookInterface(_addressBook);
        _refreshConfigInternal();
    }

    /**
     * @notice allows the partialPauser to toggle the systemPartiallyPaused variable and partially pause or partially unpause the system
     * @dev can only be called by the partialPauser
     * @param _partiallyPaused new boolean value to set systemPartiallyPaused to
     */
    function setSystemPartiallyPaused(bool _partiallyPaused) external onlyPartialPauser {
        require(systemPartiallyPaused != _partiallyPaused, "Controller: invalid input");

        systemPartiallyPaused = _partiallyPaused;

        emit SystemPartiallyPaused(systemPartiallyPaused);
    }

    /**
     * @notice allows the fullPauser to toggle the systemFullyPaused variable and fully pause or fully unpause the system
     * @dev can only be called by the fullPauser
     * @param _fullyPaused new boolean value to set systemFullyPaused to
     */
    function setSystemFullyPaused(bool _fullyPaused) external onlyFullPauser {
        require(systemFullyPaused != _fullyPaused, "Controller: invalid input");

        systemFullyPaused = _fullyPaused;

        emit SystemFullyPaused(systemFullyPaused);
    }

    /**
     * @notice allows the owner to set the fullPauser address
     * @dev can only be called by the owner
     * @param _fullPauser new fullPauser address
     */
    function setFullPauser(address _fullPauser) external onlyOwner {
        require(_fullPauser != address(0), "Controller: fullPauser cannot be set to address zero");
        require(fullPauser != _fullPauser, "Controller: invalid input");

        emit FullPauserUpdated(fullPauser, _fullPauser);

        fullPauser = _fullPauser;
    }

    /**
     * @notice allows the owner to set the partialPauser address
     * @dev can only be called by the owner
     * @param _partialPauser new partialPauser address
     */
    function setPartialPauser(address _partialPauser) external onlyOwner {
        require(_partialPauser != address(0), "Controller: partialPauser cannot be set to address zero");
        require(partialPauser != _partialPauser, "Controller: invalid input");

        emit PartialPauserUpdated(partialPauser, _partialPauser);

        partialPauser = _partialPauser;
    }

    /**
     * @notice allows the owner to toggle the restriction on whitelisted call actions and only allow whitelisted
     * call addresses or allow any arbitrary call addresses
     * @dev can only be called by the owner
     * @param _isRestricted new call restriction state
     */
    function setCallRestriction(bool _isRestricted) external onlyOwner {
        require(callRestricted != _isRestricted, "Controller: invalid input");

        callRestricted = _isRestricted;

        emit CallRestricted(callRestricted);
    }

    /**
     * @notice allows a user to give or revoke privileges to an operator which can act on their behalf on their vaults
     * @dev can only be updated by the vault owner
     * @param _operator operator that the sender wants to give privileges to or revoke them from
     * @param _isOperator new boolean value that expresses if the sender is giving or revoking privileges for _operator
     */
    function setOperator(address _operator, bool _isOperator) external {
        require(operators[msg.sender][_operator] != _isOperator, "Controller: invalid input");

        operators[msg.sender][_operator] = _isOperator;

        emit AccountOperatorUpdated(msg.sender, _operator, _isOperator);
    }

    /**
     * @dev updates the configuration of the controller. can only be called by the owner
     */
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /**
     * @notice execute a number of actions on specific vaults
     * @dev can only be called when the system is not fully paused
     * @param _actions array of actions arguments
     */
    function operate(Actions.ActionArgs[] memory _actions) external nonReentrant notFullyPaused {
        (bool vaultUpdated, address vaultOwner, uint256 vaultId) = _runActions(_actions);
        if (vaultUpdated) _verifyFinalState(vaultOwner, vaultId);
    }

    /**
     * @notice check if a specific address is an operator for an owner account
     * @param _owner account owner address
     * @param _operator account operator address
     * @return True if the _operator is an approved operator for the _owner account
     */
    function isOperator(address _owner, address _operator) external view returns (bool) {
        return operators[_owner][_operator];
    }

    /**
     * @notice returns the current controller configuration
     * @return whitelist, the address of the whitelist module
     * @return oracle, the address of the oracle module
     * @return calculator, the address of the calculator module
     * @return pool, the address of the pool module
     */
    function getConfiguration()
        external
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        return (address(whitelist), address(oracle), address(calculator), address(pool));
    }

    /**
     * @notice return a vault's proceeds pre or post expiry, the amount of collateral that can be removed from a vault
     * @param _owner account owner of the vault
     * @param _vaultId vaultId to return balances for
     * @return amount of collateral that can be taken out
     */
    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256) {
        MarginVault.Vault memory vault = getVault(_owner, _vaultId);

        (uint256 netValue, ) = calculator.getExcessCollateral(vault);
        return netValue;
    }

    /**
     * @notice get an oToken's payout/cash value after expiry, in the collateral asset
     * @param _otoken oToken address
     * @param _amount amount of the oToken to calculate the payout for, always represented in 1e8
     * @return amount of collateral to pay out
     */
    function getPayout(address _otoken, uint256 _amount) public view returns (uint256) {
        uint256 rate = calculator.getExpiredPayoutRate(_otoken);
        return rate.mul(_amount).div(10**BASE);
    }

    /**
     * @dev return if an expired oToken contract’s settlement price has been finalized
     * @param _otoken address of the oToken
     * @return True if the oToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function isSettlementAllowed(address _otoken) public view returns (bool) {
        OtokenInterface otoken = OtokenInterface(_otoken);

        address underlying = otoken.underlyingAsset();
        address strike = otoken.strikeAsset();
        address collateral = otoken.collateralAsset();

        uint256 expiry = otoken.expiryTimestamp();

        bool isUnderlyingFinalized = oracle.isDisputePeriodOver(underlying, expiry);
        bool isStrikeFinalized = oracle.isDisputePeriodOver(strike, expiry);
        bool isCollateralFinalized = oracle.isDisputePeriodOver(collateral, expiry);

        return isUnderlyingFinalized && isStrikeFinalized && isCollateralFinalized;
    }

    /**
     * @notice get the number of vaults for a specified account owner
     * @param _accountOwner account owner address
     * @return number of vaults
     */
    function getAccountVaultCounter(address _accountOwner) external view returns (uint256) {
        return accountVaultCounter[_accountOwner];
    }

    /**
     * @notice check if an oToken has expired
     * @param _otoken oToken address
     * @return True if the otoken has expired, False if not
     */
    function hasExpired(address _otoken) external view returns (bool) {
        uint256 otokenExpiryTimestamp = OtokenInterface(_otoken).expiryTimestamp();

        return now >= otokenExpiryTimestamp;
    }

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner
     */
    function getVault(address _owner, uint256 _vaultId) public view returns (MarginVault.Vault memory) {
        return vaults[_owner][_vaultId];
    }

    /**
     * @notice execute a variety of actions
     * @dev for each action in the action array, execute the corresponding action, only one vault can be modified
     * for all actions except SettleVault, Redeem, and Call
     * @param _actions array of type Actions.ActionArgs[], which expresses which actions the user wants to execute
     * @return vaultUpdated, indicates if a vault has changed
     * @return owner, the vault owner if a vault has changed
     * @return vaultId, the vault Id if a vault has changed
     */
    function _runActions(Actions.ActionArgs[] memory _actions)
        internal
        returns (
            bool,
            address,
            uint256
        )
    {
        address vaultOwner;
        uint256 vaultId;
        bool vaultUpdated;

        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];
            Actions.ActionType actionType = action.actionType;

            if (
                (actionType != Actions.ActionType.SettleVault) &&
                (actionType != Actions.ActionType.Redeem) &&
                (actionType != Actions.ActionType.Call)
            ) {
                // check if this action is manipulating the same vault as all other actions, if a vault has already been updated
                if (vaultUpdated) {
                    require(vaultOwner == action.owner, "Controller: can not run actions for different owners");
                    require(vaultId == action.vaultId, "Controller: can not run actions on different vaults");
                }
                vaultUpdated = true;
                vaultId = action.vaultId;
                vaultOwner = action.owner;
            }

            if (actionType == Actions.ActionType.OpenVault) {
                _openVault(Actions._parseOpenVaultArgs(action));
            } else if (actionType == Actions.ActionType.DepositLongOption) {
                _depositLong(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawLongOption) {
                _withdrawLong(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.DepositCollateral) {
                _depositCollateral(Actions._parseDepositArgs(action));
            } else if (actionType == Actions.ActionType.WithdrawCollateral) {
                _withdrawCollateral(Actions._parseWithdrawArgs(action));
            } else if (actionType == Actions.ActionType.MintShortOption) {
                _mintOtoken(Actions._parseMintArgs(action));
            } else if (actionType == Actions.ActionType.BurnShortOption) {
                _burnOtoken(Actions._parseBurnArgs(action));
            } else if (actionType == Actions.ActionType.Redeem) {
                _redeem(Actions._parseRedeemArgs(action));
            } else if (actionType == Actions.ActionType.SettleVault) {
                _settleVault(Actions._parseSettleVaultArgs(action));
            } else if (actionType == Actions.ActionType.Call) {
                _call(Actions._parseCallArgs(action));
            }
        }

        return (vaultUpdated, vaultOwner, vaultId);
    }

    /**
     * @notice verify the vault final state after executing all actions
     * @param _owner account owner address
     * @param _vaultId vault id of the final vault
     */
    function _verifyFinalState(address _owner, uint256 _vaultId) internal view {
        MarginVault.Vault memory _vault = getVault(_owner, _vaultId);
        (, bool isValidVault) = calculator.getExcessCollateral(_vault);

        require(isValidVault, "Controller: invalid final vault state");
    }

    /**
     * @notice open a new vault inside an account
     * @dev only the account owner or operator can open a vault, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args OpenVaultArgs structure
     */
    function _openVault(Actions.OpenVaultArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        accountVaultCounter[_args.owner] = accountVaultCounter[_args.owner].add(1);

        require(
            _args.vaultId == accountVaultCounter[_args.owner],
            "Controller: can not run actions on inexistent vault"
        );

        emit VaultOpened(_args.owner, accountVaultCounter[_args.owner]);
    }

    /**
     * @notice deposit a long oToken into a vault
     * @dev only the account owner or operator can deposit a long oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositLong(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require(
            (_args.from == msg.sender) || (_args.from == _args.owner),
            "Controller: cannot deposit long otoken from this address"
        );

        require(
            whitelist.isWhitelistedOtoken(_args.asset),
            "Controller: otoken is not whitelisted to be used as collateral"
        );

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "Controller: otoken used as collateral is already expired");

        vaults[_args.owner][_args.vaultId].addLong(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit LongOtokenDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a long oToken from a vault
     * @dev only the account owner or operator can withdraw a long oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawLong(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        OtokenInterface otoken = OtokenInterface(_args.asset);

        require(now < otoken.expiryTimestamp(), "Controller: can not withdraw an expired otoken");

        vaults[_args.owner][_args.vaultId].removeLong(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit LongOtokenWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice deposit a collateral asset into a vault
     * @dev only the account owner or operator can deposit collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args DepositArgs structure
     */
    function _depositCollateral(Actions.DepositArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require(
            (_args.from == msg.sender) || (_args.from == _args.owner),
            "Controller: cannot deposit collateral from this address"
        );

        require(
            whitelist.isWhitelistedCollateral(_args.asset),
            "Controller: asset is not whitelisted to be used as collateral"
        );

        vaults[_args.owner][_args.vaultId].addCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToPool(_args.asset, _args.from, _args.amount);

        emit CollateralAssetDeposited(_args.asset, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice withdraw a collateral asset from a vault
     * @dev only the account owner or operator can withdraw collateral, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args WithdrawArgs structure
     */
    function _withdrawCollateral(Actions.WithdrawArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        MarginVault.Vault memory vault = getVault(_args.owner, _args.vaultId);
        if (_isNotEmpty(vault.shortOtokens)) {
            OtokenInterface otoken = OtokenInterface(vault.shortOtokens[0]);

            require(
                now < otoken.expiryTimestamp(),
                "Controller: can not withdraw collateral from a vault with an expired short otoken"
            );
        }

        vaults[_args.owner][_args.vaultId].removeCollateral(_args.asset, _args.amount, _args.index);

        pool.transferToUser(_args.asset, _args.to, _args.amount);

        emit CollateralAssetWithdrawed(_args.asset, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice mint short oTokens from a vault which creates an obligation that is recorded in the vault
     * @dev only the account owner or operator can mint an oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _mintOtoken(Actions.MintArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        require(whitelist.isWhitelistedOtoken(_args.otoken), "Controller: otoken is not whitelisted to be minted");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now < otoken.expiryTimestamp(), "Controller: can not mint expired otoken");

        vaults[_args.owner][_args.vaultId].addShort(_args.otoken, _args.amount, _args.index);

        otoken.mintOtoken(_args.to, _args.amount);

        emit ShortOtokenMinted(_args.otoken, _args.owner, _args.to, _args.vaultId, _args.amount);
    }

    /**
     * @notice burn oTokens to reduce or remove the minted oToken obligation recorded in a vault
     * @dev only the account owner or operator can burn an oToken, cannot be called when system is partiallyPaused or fullyPaused
     * @param _args MintArgs structure
     */
    function _burnOtoken(Actions.BurnArgs memory _args)
        internal
        notPartiallyPaused
        onlyAuthorized(msg.sender, _args.owner)
    {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");
        require((_args.from == msg.sender) || (_args.from == _args.owner), "Controller: cannot burn from this address");

        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(now < otoken.expiryTimestamp(), "Controller: can not burn expired otoken");

        vaults[_args.owner][_args.vaultId].removeShort(_args.otoken, _args.amount, _args.index);

        otoken.burnOtoken(_args.from, _args.amount);

        emit ShortOtokenBurned(_args.otoken, _args.owner, _args.from, _args.vaultId, _args.amount);
    }

    /**
     * @notice redeem an oToken after expiry, receiving the payout of the oToken in the collateral asset
     * @dev cannot be called when system is fullyPaused
     * @param _args RedeemArgs structure
     */
    function _redeem(Actions.RedeemArgs memory _args) internal {
        OtokenInterface otoken = OtokenInterface(_args.otoken);

        require(whitelist.isWhitelistedOtoken(_args.otoken), "Controller: otoken is not whitelisted to be redeemed");

        require(now >= otoken.expiryTimestamp(), "Controller: can not redeem un-expired otoken");

        require(isSettlementAllowed(_args.otoken), "Controller: asset prices not finalized yet");

        uint256 payout = getPayout(_args.otoken, _args.amount);

        otoken.burnOtoken(msg.sender, _args.amount);

        pool.transferToUser(otoken.collateralAsset(), _args.receiver, payout);

        emit Redeem(_args.otoken, msg.sender, _args.receiver, otoken.collateralAsset(), _args.amount, payout);
    }

    /**
     * @notice settle a vault after expiry, removing the net proceeds/collateral after both long and short oToken payouts have settled
     * @dev deletes a vault of vaultId after net proceeds/collateral is removed, cannot be called when system is fullyPaused
     * @param _args SettleVaultArgs structure
     */
    function _settleVault(Actions.SettleVaultArgs memory _args) internal onlyAuthorized(msg.sender, _args.owner) {
        require(_checkVaultId(_args.owner, _args.vaultId), "Controller: invalid vault id");

        MarginVault.Vault memory vault = getVault(_args.owner, _args.vaultId);
        bool hasShort = _isNotEmpty(vault.shortOtokens);
        bool hasLong = _isNotEmpty(vault.longOtokens);

        require(hasShort || hasLong, "Controller: Can't settle vault with no otoken");

        OtokenInterface otoken = hasShort
            ? OtokenInterface(vault.shortOtokens[0])
            : OtokenInterface(vault.longOtokens[0]);

        require(now >= otoken.expiryTimestamp(), "Controller: can not settle vault with un-expired otoken");
        require(isSettlementAllowed(address(otoken)), "Controller: asset prices not finalized yet");

        (uint256 payout, ) = calculator.getExcessCollateral(vault);

        if (hasLong) {
            OtokenInterface longOtoken = OtokenInterface(vault.longOtokens[0]);

            longOtoken.burnOtoken(address(pool), vault.longAmounts[0]);
        }

        delete vaults[_args.owner][_args.vaultId];

        pool.transferToUser(otoken.collateralAsset(), _args.to, payout);

        emit VaultSettled(_args.owner, _args.to, address(otoken), _args.vaultId, payout);
    }

    /**
     * @notice execute arbitrary calls
     * @dev cannot be called when system is partiallyPaused or fullyPaused
     * @param _args Call action
     */
    function _call(Actions.CallArgs memory _args)
        internal
        notPartiallyPaused
        onlyWhitelistedCallee(_args.callee)
        returns (uint256)
    {
        CalleeInterface(_args.callee).callFunction(msg.sender, _args.data);

        emit CallExecuted(msg.sender, _args.callee, _args.data);
    }

    /**
     * @notice check if a vault id is valid for a given account owner address
     * @param _accountOwner account owner address
     * @param _vaultId vault id to check
     * @return True if the _vaultId is valid, False if not
     */
    function _checkVaultId(address _accountOwner, uint256 _vaultId) internal view returns (bool) {
        return ((_vaultId > 0) && (_vaultId <= accountVaultCounter[_accountOwner]));
    }

    function _isNotEmpty(address[] memory _array) internal pure returns (bool) {
        return (_array.length > 0) && (_array[0] != address(0));
    }

    /**
     * @notice return if a callee address is whitelisted or not
     * @param _callee callee address
     * @return True if callee address is whitelisted, False if not
     */
    function _isCalleeWhitelisted(address _callee) internal view returns (bool) {
        return whitelist.isWhitelistedCallee(_callee);
    }

    /**
     * @dev updates the internal configuration of the controller
     */
    function _refreshConfigInternal() internal {
        whitelist = WhitelistInterface(addressbook.getWhitelist());
        oracle = OracleInterface(addressbook.getOracle());
        calculator = MarginCalculatorInterface(addressbook.getMarginCalculator());
        pool = MarginPoolInterface(addressbook.getMarginPool());
    }
}

// File: contracts/external/proxies/PayableProxyController.sol









/**
 * @title PayableProxyController
 * @author Opyn Team
 * @dev Contract for wrapping/unwrapping ETH before/after interacting with the Gamma Protocol
 */
contract PayableProxyController is ReentrancyGuard {
    using SafeERC20 for ERC20Interface;
    using Address for address payable;

    WETH9 public weth;
    Controller public controller;

    constructor(
        address _controller,
        address _marginPool,
        address payable _weth
    ) public {
        controller = Controller(_controller);
        weth = WETH9(_weth);
        ERC20Interface(address(weth)).safeApprove(_marginPool, uint256(-1));
    }

    /**
     * @notice fallback function which disallows ETH to be sent to this contract without data except when unwrapping WETH
     */
    fallback() external payable {
        require(msg.sender == address(weth), "PayableProxyController: Cannot receive ETH");
    }

    /**
     * @notice execute a number of actions
     * @dev a wrapper for the Controller operate function, to wrap WETH and the beginning and unwrap WETH at the end of the execution
     * @param _actions array of actions arguments
     * @param _sendEthTo address to send the remaining eth to
     */
    function operate(Actions.ActionArgs[] memory _actions, address payable _sendEthTo) external payable nonReentrant {
        // create WETH from ETH
        if (msg.value != 0) {
            weth.deposit{value: msg.value}();
        }

        // verify sender
        for (uint256 i = 0; i < _actions.length; i++) {
            Actions.ActionArgs memory action = _actions[i];

            // check that msg.sender is an owner or operator
            if (action.owner != address(0)) {
                require(
                    (msg.sender == action.owner) || (controller.isOperator(action.owner, msg.sender)),
                    "PayableProxyController: cannot execute action "
                );
            }

            if (action.actionType == Actions.ActionType.Call) {
                // our PayableProxy could ends up approving amount > total eth received.
                ERC20Interface(address(weth)).safeIncreaseAllowance(action.secondAddress, msg.value);
            }
        }

        controller.operate(_actions);

        // return all remaining WETH to the sendEthTo address as ETH
        uint256 remainingWeth = weth.balanceOf(address(this));
        if (remainingWeth != 0) {
            require(_sendEthTo != address(0), "PayableProxyController: cannot send ETH to address zero");

            weth.withdraw(remainingWeth);
            _sendEthTo.sendValue(remainingWeth);
        }
    }
}