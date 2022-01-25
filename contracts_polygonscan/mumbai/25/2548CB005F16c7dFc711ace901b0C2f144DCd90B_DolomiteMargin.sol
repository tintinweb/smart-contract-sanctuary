/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Admin } from "./Admin.sol";
import { Getters } from "./Getters.sol";
import { Operation } from "./Operation.sol";
import { Permission } from "./Permission.sol";
import { State } from "./State.sol";
import { Storage } from "./lib/Storage.sol";
import { IDolomiteMargin } from "./interfaces/IDolomiteMargin.sol";


/**
 * @title DolomiteMargin
 * @author dYdX
 *
 * Main contract that inherits from other contracts
 */
contract DolomiteMargin is
    IDolomiteMargin,
    State,
    Admin,
    Getters,
    Operation,
    Permission
{
    // ============ Constructor ============

    constructor(
        Storage.RiskParams memory riskParams,
        Storage.RiskLimits memory riskLimits
    )
        public
    {
        g_state.riskParams = riskParams;
        g_state.riskLimits = riskLimits;
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
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
}

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Math } from "./Math.sol";


/**
 * @title Types
 * @author dYdX
 *
 * Library for interacting with the basic structs used in DolomiteMargin
 */
library Types {
    using Math for uint256;

    // ============ Permission ============

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    // ============ Par (Principal Amount) ============

    // Total borrow and supply values for a market
    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    // Individual principal amount for an account
    struct Par {
        bool sign; // true if positive
        uint128 value;
    }

    function zeroPar()
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: false,
            value: 0
        });
    }

    function sub(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (Par memory)
    {
        Par memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value).to128();
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value).to128();
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value).to128();
            }
        }
        return result;
    }

    function equals(
        Par memory a,
        Par memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Par memory a
    )
        internal
        pure
        returns (Par memory)
    {
        return Par({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }

    function isLessThanZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value > 0 && !a.sign;
    }

    function isGreaterThanOrEqualToZero(
        Par memory a
    )
        internal
        pure
        returns (bool)
    {
        return isZero(a) || a.sign;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function zeroWei()
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: false,
            value: 0
        });
    }

    function sub(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (Wei memory)
    {
        Wei memory result;
        if (a.sign == b.sign) {
            result.sign = a.sign;
            result.value = SafeMath.add(a.value, b.value);
        } else {
            if (a.value >= b.value) {
                result.sign = a.sign;
                result.value = SafeMath.sub(a.value, b.value);
            } else {
                result.sign = b.sign;
                result.value = SafeMath.sub(b.value, a.value);
            }
        }
        return result;
    }

    function equals(
        Wei memory a,
        Wei memory b
    )
        internal
        pure
        returns (bool)
    {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(
        Wei memory a
    )
        internal
        pure
        returns (Wei memory)
    {
        return Wei({
            sign: !a.sign,
            value: a.value
        });
    }

    function isNegative(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return !a.sign && a.value > 0;
    }

    function isPositive(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.sign && a.value > 0;
    }

    function isZero(
        Wei memory a
    )
        internal
        pure
        returns (bool)
    {
        return a.value == 0;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";


/**
 * @title Token
 * @author dYdX
 *
 * This library contains basic functions for interacting with ERC20 tokens. Modified to work with
 * tokens that don't adhere strictly to the ERC20 standard (for example tokens that don't return a
 * boolean value on success).
 */
library Token {

    // ============ Library Functions ============

    function transfer(
        address token,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == address(this)) {
            return;
        }

        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transfer.selector, to, amount),
            "Token: transfer failed"
        );
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
        if (amount == 0 || to == from) {
            return;
        }

        // solium-disable arg-overflow
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(IERC20Detailed(token).transferFrom.selector, from, to, amount),
            "Token: transferFrom failed"
        );
        // solium-enable arg-overflow
    }

    // ============ Private Functions ============

    function _callOptionalReturn(address token, bytes memory data, string memory error) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        // 1. The target address is checked to contain contract code. Not needed since tokens are manually added
        // 2. The call itself is made, and success asserted
        // 3. The return value is decoded, which in turn checks the size of the returned data.

        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory returnData) = token.call(data);
        require(success, error);

        if (returnData.length > 0) {
            // Return data is optional
            require(abi.decode(returnData, (bool)), error);
        }
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Math } from "./Math.sol";


/**
 * @title Time
 * @author dYdX
 *
 * Library for dealing with time, assuming timestamps fit within 32 bits (valid until year 2106)
 */
library Time {

    // ============ Library Functions ============

    function currentTime()
        internal
        view
        returns (uint32)
    {
        return Math.to32(block.timestamp);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Account } from "./Account.sol";
import { Bits } from "./Bits.sol";
import { Cache } from "./Cache.sol";
import { Decimal } from "./Decimal.sol";
import { Interest } from "./Interest.sol";
import { EnumerableSet } from "./EnumerableSet.sol";
import { Math } from "./Math.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";
import { Time } from "./Time.sol";
import { Token } from "./Token.sol";
import { Types } from "./Types.sol";
import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";


/**
 * @title Storage
 * @author dYdX
 *
 * Functions for reading, writing, and verifying state in DolomiteMargin
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Math for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Set;

    // ============ Constants ============

    bytes32 internal constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;

        // Interest index of the market
        Interest.Index index;

        // Contract address of the price oracle for this market
        IPriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal.D256 marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal.D256 spreadPremium;
    }

    // The global risk parameters that govern the health and security of the system
    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal.D256 marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal.D256 liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal.D256 earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        Monetary.Value minBorrowedValue;
    }

    // The maximum RiskParam values that can be set
    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of DolomiteMargin
    struct State {
        // number of markets
        uint256 numMarkets;

        // marketId => Market
        mapping (uint256 => Market) markets;
        mapping (address => uint256) tokenToMarketId;
        mapping(uint256 => uint256) recycledMarketIds;

        // owner => account number => Account
        mapping (address => mapping (uint256 => Account.Storage)) accounts;

        // Addresses that can control other users accounts
        mapping (address => mapping (address => bool)) operators;

        // Addresses that can control all users accounts
        mapping (address => bool) globalOperators;

        // mutable risk parameters of the system
        RiskParams riskParams;

        // immutable risk limits of the system
        RiskLimits riskLimits;
    }

    // ============ Functions ============

    function getToken(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (address)
    {
        return state.markets[marketId].token;
    }

    function getTotalPar(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.TotalPar memory)
    {
        return state.markets[marketId].totalPar;
    }

    function getIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Interest.Index memory)
    {
        return state.markets[marketId].index;
    }

    function getNumExcessTokens(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        address token = state.getToken(marketId);

        Types.Wei memory balanceWei = Types.Wei({
            sign: true,
            value: IERC20Detailed(token).balanceOf(address(this))
        });

        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        // borrowWei is negative, so subtracting it makes the value more positive
        return balanceWei.sub(borrowWei).sub(supplyWei);
    }

    function getStatus(
        Storage.State storage state,
        Account.Info memory account
    )
        internal
        view
        returns (Account.Status)
    {
        return state.accounts[account.owner][account.number].status;
    }

    function getPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
        internal
        view
        returns (Types.Par memory)
    {
        return state.accounts[account.owner][account.number].balances[marketId];
    }

    function getWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Types.Par memory par = state.getPar(account, marketId);

        if (par.isZero()) {
            return Types.zeroWei();
        }

        Interest.Index memory index = state.getIndex(marketId);
        return Interest.parToWei(par, index);
    }

    function getMarketsWithBalancesSet(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (EnumerableSet.Set storage)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet;
    }

    function getMarketsWithBalances(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256[] memory)
    {
        return state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.values();
    }

    function getNumberOfMarketsWithBorrow(
        Storage.State storage state,
        Account.Info memory account
    )
    internal
    view
    returns (uint256)
    {
        return state.accounts[account.owner][account.number].numberOfMarketsWithBorrow;
    }

    function getLiquidationSpreadForPair(
        Storage.State storage state,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
        internal
        view
        returns (Decimal.D256 memory)
    {
        uint256 result = state.riskParams.liquidationSpread.value;
        result = Decimal.mul(result, Decimal.onePlus(state.markets[heldMarketId].spreadPremium));
        result = Decimal.mul(result, Decimal.onePlus(state.markets[owedMarketId].spreadPremium));
        return Decimal.D256({
            value: result
        });
    }

    function fetchNewIndex(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Index memory)
    {
        Interest.Rate memory rate = state.fetchInterestRate(marketId, index);

        return Interest.calculateNewIndex(
            index,
            rate,
            state.getTotalPar(marketId),
            state.riskParams.earningsRate
        );
    }

    function fetchInterestRate(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    )
        internal
        view
        returns (Interest.Rate memory)
    {
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = Interest.totalParToWei(totalPar, index);

        Interest.Rate memory rate = state.markets[marketId].interestSetter.getInterestRate(
            state.getToken(marketId),
            borrowWei.value,
            supplyWei.value
        );

        return rate;
    }

    function fetchPrice(
        Storage.State storage state,
        uint256 marketId,
        address token
    )
        internal
        view
        returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(token);
        Require.that(
            price.value != 0,
            FILE,
            "Price cannot be zero",
            marketId
        );
        return price;
    }

    function getAccountValues(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool adjustForLiquidity
    )
        internal
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Wei memory userWei = state.getWei(account, cache.getAtIndex(i).marketId);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getAtIndex(i).price.value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[cache.getAtIndex(i).marketId].marginPremium);
            }

            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(Decimal.div(assetValue, adjust));
            } else {
                borrowValue.value = borrowValue.value.add(Decimal.mul(assetValue, adjust));
            }
        }

        return (supplyValue, borrowValue);
    }

    function isCollateralized(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool requireMinBorrow
    )
        internal
        view
        returns (bool)
    {
        if (state.getNumberOfMarketsWithBorrow(account) == 0) {
            // The user does not have a balance with a borrow amount, so they must be collateralized
            return true;
        }

        // get account values (adjusted for liquidity)
        (
            Monetary.Value memory supplyValue,
            Monetary.Value memory borrowValue
        ) = state.getAccountValues(account, cache, /* adjustForLiquidity = */ true);

        if (borrowValue.value == 0) {
            return true;
        }

        if (requireMinBorrow) {
            Require.that(
                borrowValue.value >= state.riskParams.minBorrowedValue.value,
                FILE,
                "Borrow value too low",
                account.owner,
                account.number
            );
        }

        uint256 requiredMargin = Decimal.mul(borrowValue.value, state.riskParams.marginRatio);

        return supplyValue.value >= borrowValue.value.add(requiredMargin);
    }

    function isGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.globalOperators[operator];
    }

    function isLocalOperator(
        Storage.State storage state,
        address owner,
        address operator
    )
        internal
        view
        returns (bool)
    {
        return state.operators[owner][operator];
    }

    function requireIsGlobalOperator(
        Storage.State storage state,
        address operator
    )
        internal
        view
    {
        bool isValidOperator = state.isGlobalOperator(operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned global operator",
            operator
        );
    }

    function requireIsOperator(
        Storage.State storage state,
        Account.Info memory account,
        address operator
    )
        internal
        view
    {
        bool isValidOperator =
            operator == account.owner
            || state.isGlobalOperator(operator)
            || state.isLocalOperator(account.owner, operator);

        Require.that(
            isValidOperator,
            FILE,
            "Unpermissioned operator",
            operator
        );
    }

    /**
     * Determine and set an account's balance based on the intended balance change. Return the
     * equivalent amount in wei
     */
    function getNewParAndDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (amount.value == 0 && amount.ref == Types.AssetReference.Delta) {
            return (oldPar, Types.zeroWei());
        }

        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = Interest.parToWei(oldPar, index);
        Types.Par memory newPar;
        Types.Wei memory deltaWei;

        if (amount.denomination == Types.AssetDenomination.Wei) {
            deltaWei = Types.Wei({
                sign: amount.sign,
                value: amount.value
            });
            if (amount.ref == Types.AssetReference.Target) {
                deltaWei = deltaWei.sub(oldWei);
            }
            newPar = Interest.weiToPar(oldWei.add(deltaWei), index);
        } else { // AssetDenomination.Par
            newPar = Types.Par({
                sign: amount.sign,
                value: amount.value.to128()
            });
            if (amount.ref == Types.AssetReference.Delta) {
                newPar = oldPar.add(newPar);
            }
            deltaWei = Interest.parToWei(newPar, index).sub(oldWei);
        }

        return (newPar, deltaWei);
    }

    function getNewParAndDeltaWeiForLiquidation(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.AssetAmount memory amount
    )
        internal
        view
        returns (Types.Par memory, Types.Wei memory)
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        Require.that(
            !oldPar.isPositive(),
            FILE,
            "Owed balance cannot be positive",
            account.owner,
            account.number
        );

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            account,
            marketId,
            amount
        );

        // if attempting to over-repay the owed asset, bound it by the maximum
        if (newPar.isPositive()) {
            newPar = Types.zeroPar();
            deltaWei = state.getWei(account, marketId).negative();
        }

        Require.that(
            !deltaWei.isNegative() && oldPar.value >= newPar.value,
            FILE,
            "Owed balance cannot increase",
            account.owner,
            account.number
        );

        // if not paying back enough wei to repay any par, then bound wei to zero
        if (oldPar.equals(newPar)) {
            deltaWei = Types.zeroWei();
        }

        return (newPar, deltaWei);
    }

    function isVaporizable(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache
    )
        internal
        view
        returns (bool)
    {
        bool hasNegative = false;
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            Types.Par memory par = state.getPar(account, cache.getAtIndex(i).marketId);
            if (par.isZero()) {
                continue;
            } else if (par.sign) {
                return false;
            } else {
                hasNegative = true;
            }
        }
        return hasNegative;
    }

    // =============== Setter Functions ===============

    function updateIndex(
        Storage.State storage state,
        uint256 marketId
    )
        internal
        returns (Interest.Index memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        if (index.lastUpdate == Time.currentTime()) {
            return index;
        }
        return state.markets[marketId].index = state.fetchNewIndex(marketId, index);
    }

    function setStatus(
        Storage.State storage state,
        Account.Info memory account,
        Account.Status status
    )
        internal
    {
        state.accounts[account.owner][account.number].status = status;
    }

    function setPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Par memory newPar
    )
        internal
    {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (Types.equals(oldPar, newPar)) {
            // GUARD statement
            return;
        }

        // updateTotalPar
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        // roll-back oldPar
        if (oldPar.sign) {
            totalPar.supply = uint256(totalPar.supply).sub(oldPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).sub(oldPar.value).to128();
        }

        // roll-forward newPar
        if (newPar.sign) {
            totalPar.supply = uint256(totalPar.supply).add(newPar.value).to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow).add(newPar.value).to128();
        }

        if (oldPar.isLessThanZero() && newPar.isGreaterThanOrEqualToZero()) {
            // user went from borrowing to repaying or positive
            state.accounts[account.owner][account.number].numberOfMarketsWithBorrow -= 1;
        } else if (oldPar.isGreaterThanOrEqualToZero() && newPar.isLessThanZero()) {
            // user went from zero or positive to borrowing
            state.accounts[account.owner][account.number].numberOfMarketsWithBorrow += 1;
        }

        if (newPar.isZero() && (!oldPar.isZero())) {
            // User went from a non-zero balance to zero. Remove the market from the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.remove(marketId);
        } else if ((!newPar.isZero()) && oldPar.isZero()) {
            // User went from zero to non-zero. Add the market to the set.
            state.accounts[account.owner][account.number].marketsWithNonZeroBalanceSet.add(marketId);
        }

        state.markets[marketId].totalPar = totalPar;
        state.accounts[account.owner][account.number].balances[marketId] = newPar;
    }

    /**
     * Determine and set an account's balance based on a change in wei
     */
    function setParFromDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Wei memory deltaWei
    )
        internal
    {
        if (deltaWei.isZero()) {
            return;
        }
        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = state.getWei(account, marketId);
        Types.Wei memory newWei = oldWei.add(deltaWei);
        Types.Par memory newPar = Interest.weiToPar(newWei, index);
        state.setPar(
            account,
            marketId,
            newPar
        );
    }

    function initializeCache(
        Storage.State storage state,
        Cache.MarketCache memory cache
    ) internal view {
        cache.markets = new Cache.MarketInfo[](cache.marketsLength);
        uint counter = 0;

        // Really neat byproduct of iterating through a bitmap using the least significant bit, where each set flag
        // represents the marketId, --> the initialized `cache.markets` array is sorted in O(n)!!!!!!
        // Meaning, this function call is O(n) where `n` is the number of markets in the cache
        for (uint i = 0; i < cache.marketBitmaps.length; i++) {
            uint bitmap = cache.marketBitmaps[i];
            while (bitmap != 0) {
                uint nextSetBit = Bits.getLeastSignificantBit(bitmap);
                uint marketId = Bits.getMarketIdFromBit(i, nextSetBit);
                address token = state.getToken(marketId);
                if (state.markets[marketId].isClosing) {
                    cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: true,
                    borrowPar: state.getTotalPar(marketId).borrow,
                    price: state.fetchPrice(marketId, token)
                    });
                } else {
                    // don't need the borrowPar if the market is not closing
                    cache.markets[counter++] = Cache.MarketInfo({
                    marketId: marketId,
                    token: token,
                    isClosing: false,
                    borrowPar: 0,
                    price: state.fetchPrice(marketId, token)
                    });
                }

                // unset the set bit
                bitmap = Bits.unsetBit(bitmap, nextSetBit);
            }
            if (counter == cache.marketsLength) {
                break;
            }
        }

        Require.that(
            cache.marketsLength == counter,
            FILE,
            "cache initialized improperly",
            cache.marketsLength,
            cache.markets.length
        );
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Require
 * @author dYdX
 *
 * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 constant ASCII_ZERO = 48; // '0'
    uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 constant ASCII_LOWER_EX = 120; // 'x'
    bytes2 constant COLON = 0x3a20; // ': '
    bytes2 constant COMMA = 0x2c20; // ', '
    bytes2 constant LPAREN = 0x203c; // ' <'
    byte constant RPAREN = 0x3e; // '>'
    uint256 constant FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason)
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        RPAREN
                    )
                )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
        internal
        pure
    {
        if (!must) {
            revert(
                string(
                    abi.encodePacked(
                        stringifyTruncated(file),
                        COLON,
                        stringifyTruncated(reason),
                        LPAREN,
                        stringify(payloadA),
                        COMMA,
                        stringify(payloadB),
                        COMMA,
                        stringify(payloadC),
                        RPAREN
                    )
                )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solium-disable-next-line security/no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function stringify(
        uint256 input
    )
        private
        pure
        returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            /* solium-disable-next-line security/no-modify-for-iter-var */
            i--;

            // take last decimal digit
            bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function stringify(
        address input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function stringify(
        bytes32 input
    )
        private
        pure
        returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = byte(uint8(ASCII_ZERO));
        result[1] = byte(uint8(ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = char(z & FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function char(
        uint256 input
    )
        private
        pure
        returns (byte)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return byte(uint8(input + ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return byte(uint8(input + ASCII_RELATIVE_ZERO));
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title Monetary
 * @author dYdX
 *
 * Library for types involving money
 */
library Monetary {

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount). Has 36 decimals.
     */
    struct Value {
        uint256 value;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Require } from "./Require.sol";


/**
 * @title Math
 * @author dYdX
 *
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Math";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.1 rounds to 102
     * instead of 101.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    /*
     * Return target * (numerator / denominator), but rounded half-up. Meaning, a result of 101.5 rounds to 102
     * instead of 101.
     */
    function getPartialRoundHalfUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        uint result = target.mul(numerator);
        // round the denominator comparator up to ensure a fair comparison is done on the `result`'s modulo.
        // For example, 51 / 103 == 0; 51 % 103 == 51; ((103 - 1) / 2) + 1 == 52; 51 < 52, therefore no round up
        return result.div(denominator).add(result.mod(denominator) >= denominator.sub(1).div(2).add(1) ? 1 : 0);
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint128",
            number
        );
        return result;
    }

    function to96(
        uint256 number
    )
        internal
        pure
        returns (uint96)
    {
        uint96 result = uint96(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint96",
            number
        );
        return result;
    }

    function to32(
        uint256 number
    )
        internal
        pure
        returns (uint32)
    {
        uint32 result = uint32(number);
        Require.that(
            result == number,
            FILE,
            "Unsafe cast to uint32",
            number
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Decimal } from "./Decimal.sol";
import { Math } from "./Math.sol";
import { Time } from "./Time.sol";
import { Types } from "./Types.sol";


/**
 * @title Interest
 * @author dYdX
 *
 * Library for managing the interest rate and interest indexes of DolomiteMargin
 */
library Interest {
    using Math for uint256;
    using SafeMath for uint256;

    // ============ Constants ============

    bytes32 constant FILE = "Interest";
    uint64 constant BASE = 10**18;

    // ============ Structs ============

    struct Rate {
        uint256 value;
    }

    struct Index {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    // ============ Library Functions ============

    /**
     * Get a new market Index based on the old index and market interest rate.
     * Calculate interest for borrowers by using the formula rate * time. Approximates
     * continuously-compounded interest when called frequently, but is much more
     * gas-efficient to calculate. For suppliers, the interest rate is adjusted by the earningsRate,
     * then prorated across all suppliers.
     *
     * @param  index         The old index for a market
     * @param  rate          The current interest rate of the market
     * @param  totalPar      The total supply and borrow par values of the market
     * @param  earningsRate  The portion of the interest that is forwarded to the suppliers
     * @return               The updated index for a market
     */
    function calculateNewIndex(
        Index memory index,
        Rate memory rate,
        Types.TotalPar memory totalPar,
        Decimal.D256 memory earningsRate
    )
        internal
        view
        returns (Index memory)
    {
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

        // get interest increase for borrowers
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(uint256(currentTime).sub(index.lastUpdate));

        // get interest increase for suppliers
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                supplyInterest = Math.getPartial(supplyInterest, borrowWei.value, supplyWei.value);
            }
        }
        assert(supplyInterest <= borrowInterest);

        return Index({
            borrow: Math.getPartial(index.borrow, borrowInterest, BASE).add(index.borrow).to96(),
            supply: Math.getPartial(index.supply, supplyInterest, BASE).add(index.supply).to96(),
            lastUpdate: currentTime
        });
    }

    function newIndex()
        internal
        view
        returns (Index memory)
    {
        return Index({
            borrow: BASE,
            supply: BASE,
            lastUpdate: Time.currentTime()
        });
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(
        Types.Par memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return Types.Wei({
                sign: true,
                value: inputValue.getPartialRoundHalfUp(index.supply, BASE)
            });
        } else {
            return Types.Wei({
                sign: false,
                value: inputValue.getPartialRoundHalfUp(index.borrow, BASE)
            });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(
        Types.Wei memory input,
        Index memory index
    )
        internal
        pure
        returns (Types.Par memory)
    {
        if (input.sign) {
            return Types.Par({
                sign: true,
                value: input.value.getPartialRoundHalfUp(BASE, index.supply).to128()
            });
        } else {
            return Types.Par({
                sign: false,
                value: input.value.getPartialRoundHalfUp(BASE, index.borrow).to128()
            });
        }
    }

    /*
     * Convert the total supply and borrow principal amounts of a market to total supply and borrow
     * token amounts.
     */
    function totalParToWei(
        Types.TotalPar memory totalPar,
        Index memory index
    )
        internal
        pure
        returns (Types.Wei memory, Types.Wei memory)
    {
        Types.Par memory supplyPar = Types.Par({
            sign: true,
            value: totalPar.supply
        });
        Types.Par memory borrowPar = Types.Par({
            sign: false,
            value: totalPar.borrow
        });
        Types.Wei memory supplyWei = parToWei(supplyPar, index);
        Types.Wei memory borrowWei = parToWei(borrowPar, index);
        return (supplyWei, borrowWei);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "./Require.sol";
import { Token } from "./Token.sol";
import { Types } from "./Types.sol";
import { IExchangeWrapper } from "../interfaces/IExchangeWrapper.sol";


/**
 * @title Exchange
 * @author dYdX
 *
 * Library for transferring tokens and interacting with ExchangeWrappers by using the Wei struct
 */
library Exchange {
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "Exchange";

    // ============ Library Functions ============

    function transferOut(
        address token,
        address to,
        Types.Wei memory deltaWei
    )
        internal
    {
        Require.that(
            !deltaWei.isPositive(),
            FILE,
            "Cannot transferOut positive",
            deltaWei.value
        );

        Token.transfer(
            token,
            to,
            deltaWei.value
        );
    }

    function transferIn(
        address token,
        address from,
        Types.Wei memory deltaWei
    )
        internal
    {
        Require.that(
            !deltaWei.isNegative(),
            FILE,
            "Cannot transferIn negative",
            deltaWei.value
        );

        Token.transferFrom(
            token,
            from,
            address(this),
            deltaWei.value
        );
    }

    function getCost(
        address exchangeWrapper,
        address supplyToken,
        address borrowToken,
        Types.Wei memory desiredAmount,
        bytes memory orderData
    )
        internal
        view
        returns (Types.Wei memory)
    {
        Require.that(
            !desiredAmount.isNegative(),
            FILE,
            "Cannot getCost negative",
            desiredAmount.value
        );

        Types.Wei memory result;
        result.sign = false;
        result.value = IExchangeWrapper(exchangeWrapper).getExchangeCost(
            supplyToken,
            borrowToken,
            desiredAmount.value,
            orderData
        );

        return result;
    }

    function exchange(
        address exchangeWrapper,
        address accountOwner,
        address supplyToken,
        address borrowToken,
        Types.Wei memory requestedFillAmount,
        bytes memory orderData
    )
        internal
        returns (Types.Wei memory)
    {
        Require.that(
            !requestedFillAmount.isPositive(),
            FILE,
            "Cannot exchange positive",
            requestedFillAmount.value
        );

        transferOut(borrowToken, exchangeWrapper, requestedFillAmount);

        Types.Wei memory result;
        result.sign = true;
        result.value = IExchangeWrapper(exchangeWrapper).exchange(
            accountOwner,
            address(this),
            supplyToken,
            borrowToken,
            requestedFillAmount.value,
            orderData
        );

        transferIn(supplyToken, exchangeWrapper, result);

        return result;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Actions } from "./Actions.sol";
import { Interest } from "./Interest.sol";
import { Storage } from "./Storage.sol";
import { Types } from "./Types.sol";


/**
 * @title Events
 * @author dYdX
 *
 * Library to parse and emit logs from which the state of all accounts and indexes can be followed
 */
library Events {
    using Types for Types.Wei;
    using Storage for Storage.State;

    // ============ Events ============

    event LogIndexUpdate(
        uint256 indexed market,
        Interest.Index index
    );

    event LogOperation(
        address sender
    );

    event LogDeposit(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address from
    );

    event LogWithdraw(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 market,
        BalanceUpdate update,
        address to
    );

    event LogTransfer(
        address indexed accountOneOwner,
        uint256 accountOneNumber,
        address indexed accountTwoOwner,
        uint256 accountTwoNumber,
        uint256 market,
        BalanceUpdate updateOne,
        BalanceUpdate updateTwo
    );

    event LogBuy(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogSell(
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 takerMarket,
        uint256 makerMarket,
        BalanceUpdate takerUpdate,
        BalanceUpdate makerUpdate,
        address exchangeWrapper
    );

    event LogTrade(
        address indexed takerAccountOwner,
        uint256 takerAccountNumber,
        address indexed makerAccountOwner,
        uint256 makerAccountNumber,
        uint256 inputMarket,
        uint256 outputMarket,
        BalanceUpdate takerInputUpdate,
        BalanceUpdate takerOutputUpdate,
        BalanceUpdate makerInputUpdate,
        BalanceUpdate makerOutputUpdate,
        address autoTrader
    );

    event LogCall(
        address indexed accountOwner,
        uint256 accountNumber,
        address callee
    );

    event LogLiquidate(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed liquidAccountOwner,
        uint256 liquidAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate liquidHeldUpdate,
        BalanceUpdate liquidOwedUpdate
    );

    event LogVaporize(
        address indexed solidAccountOwner,
        uint256 solidAccountNumber,
        address indexed vaporAccountOwner,
        uint256 vaporAccountNumber,
        uint256 heldMarket,
        uint256 owedMarket,
        BalanceUpdate solidHeldUpdate,
        BalanceUpdate solidOwedUpdate,
        BalanceUpdate vaporOwedUpdate
    );

    // ============ Structs ============

    struct BalanceUpdate {
        Types.Wei deltaWei;
        Types.Par newPar;
    }

    // ============ Internal Functions ============

    function logIndexUpdate(
        uint256 marketId,
        Interest.Index memory index
    )
        internal
    {
        emit LogIndexUpdate(
            marketId,
            index
        );
    }

    function logOperation()
        internal
    {
        emit LogOperation(msg.sender);
    }

    function logDeposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogDeposit(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.from
        );
    }

    function logWithdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogWithdraw(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(
                state,
                args.account,
                args.market,
                deltaWei
            ),
            args.to
        );
    }

    function logTransfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Types.Wei memory deltaWei
    )
        internal
    {
        emit LogTransfer(
            args.accountOne.owner,
            args.accountOne.number,
            args.accountTwo.owner,
            args.accountTwo.number,
            args.market,
            getBalanceUpdate(
                state,
                args.accountOne,
                args.market,
                deltaWei
            ),
            getBalanceUpdate(
                state,
                args.accountTwo,
                args.market,
                deltaWei.negative()
            )
        );
    }

    function logBuy(
        Storage.State storage state,
        Actions.BuyArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogBuy(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logSell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    )
        internal
    {
        emit LogSell(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(
                state,
                args.account,
                args.takerMarket,
                takerWei
            ),
            getBalanceUpdate(
                state,
                args.account,
                args.makerMarket,
                makerWei
            ),
            args.exchangeWrapper
        );
    }

    function logTrade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Types.Wei memory inputWei,
        Types.Wei memory outputWei
    )
        internal
    {
        BalanceUpdate[4] memory updates = [
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.inputMarket,
                inputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.takerAccount,
                args.outputMarket,
                outputWei.negative()
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.inputMarket,
                inputWei
            ),
            getBalanceUpdate(
                state,
                args.makerAccount,
                args.outputMarket,
                outputWei
            )
        ];

        emit          LogTrade(
            args.takerAccount.owner,
            args.takerAccount.number,
            args.makerAccount.owner,
            args.makerAccount.number,
            args.inputMarket,
            args.outputMarket,
            updates[0],
            updates[1],
            updates[2],
            updates[3],
            args.autoTrader
        );
    }

    function logCall(
        Actions.CallArgs memory args
    )
        internal
    {
        emit LogCall(
            args.account.owner,
            args.account.number,
            args.callee
        );
    }

    function logLiquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory liquidHeldUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.heldMarket,
            heldWei
        );
        BalanceUpdate memory liquidOwedUpdate = getBalanceUpdate(
            state,
            args.liquidAccount,
            args.owedMarket,
            owedWei
        );

        emit LogLiquidate(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.liquidAccount.owner,
            args.liquidAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            liquidHeldUpdate,
            liquidOwedUpdate
        );
    }

    function logVaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei,
        Types.Wei memory excessWei
    )
        internal
    {
        BalanceUpdate memory solidHeldUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );
        BalanceUpdate memory solidOwedUpdate = getBalanceUpdate(
            state,
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        BalanceUpdate memory vaporOwedUpdate = getBalanceUpdate(
            state,
            args.vaporAccount,
            args.owedMarket,
            owedWei.add(excessWei)
        );

        emit LogVaporize(
            args.solidAccount.owner,
            args.solidAccount.number,
            args.vaporAccount.owner,
            args.vaporAccount.number,
            args.heldMarket,
            args.owedMarket,
            solidHeldUpdate,
            solidOwedUpdate,
            vaporOwedUpdate
        );
    }

    // ============ Private Functions ============

    function getBalanceUpdate(
        Storage.State storage state,
        Account.Info memory account,
        uint256 market,
        Types.Wei memory deltaWei
    )
        private
        view
        returns (BalanceUpdate memory)
    {
        return BalanceUpdate({
            deltaWei: deltaWei,
            newPar: state.getPar(account, market)
        });
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


library EnumerableSet {

    struct Set {
        // Storage of set values
        uint256[] _values;
        // Value to the index in `_values` array, plus 1 because index 0 means a value is not in the set.
        mapping(uint256 => uint256) _valueToIndexMap;
    }

    /**
    * @dev Add a value to a set. O(1).
     *
     * @return true if the value was added to the set, that is if it was not already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._valueToIndexMap[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * @return true if the value was removed from the set, that is if it was present.
     */
    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._valueToIndexMap[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                uint256 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._valueToIndexMap[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored, which is the last index
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._valueToIndexMap[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._valueToIndexMap[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (uint256[] memory) {
        return set._values;
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Math } from "./Math.sol";


/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Bits } from "./Bits.sol";
import { Monetary } from "./Monetary.sol";
import { Require } from "./Require.sol";


/**
 * @title Cache
 * @author dYdX
 *
 * Library for caching information about markets
 */
library Cache {

    // ============ Constants ============

    bytes32 internal constant FILE = "Cache";

    // ============ Structs ============

    struct MarketInfo {
        uint marketId;
        address token;
        bool isClosing;
        uint128 borrowPar;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
        uint256[] marketBitmaps;
        uint256 marketsLength;
    }

    // ============ Setter Functions ============

    /**
     * Initialize an empty cache for some given number of total markets.
     */
    function create(
        uint256 numMarkets
    )
        internal
        pure
        returns (MarketCache memory)
    {
        return MarketCache({
            markets: new MarketInfo[](0),
            marketBitmaps: Bits.createBitmaps(numMarkets),
            marketsLength: 0
        });
    }

    // ============ Getter Functions ============

    function getNumMarkets(
        MarketCache memory cache
    )
        internal
        pure
        returns (uint256)
    {
        return cache.markets.length;
    }

    function hasMarket(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (bool)
    {
        return Bits.hasBit(cache.marketBitmaps, marketId);
    }

    function get(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            cache.markets.length > 0,
            FILE,
            "not initialized"
        );
        return _getInternal(
            cache.markets,
            0,
            cache.marketsLength,
            marketId
        );
    }

    function set(
        MarketCache memory cache,
        uint256 marketId
    )
        internal
        pure
    {
        // Devs should not be able to call this function once the `markets` array has been initialized (non-zero length)
        Require.that(
            cache.markets.length == 0,
            FILE,
            "already initialized"
        );

        Bits.setBit(cache.marketBitmaps, marketId);

        cache.marketsLength += 1;
    }

    function getAtIndex(
        MarketCache memory cache,
        uint256 index
    )
        internal
        pure
        returns (MarketInfo memory)
    {
        Require.that(
            index < cache.markets.length,
            FILE,
            "invalid index",
            index,
            cache.markets.length
        );
        return cache.markets[index];
    }

    // ============ Private Functions ============

    function _getInternal(
        MarketInfo[] memory data,
        uint beginInclusive,
        uint endExclusive,
        uint marketId
    ) private pure returns (MarketInfo memory) {
        uint len = endExclusive - beginInclusive;
        if (len == 0 || (len == 1 && data[beginInclusive].marketId != marketId)) {
            revert("Cache: item not found");
        }

        uint mid = beginInclusive + len / 2;
        uint midMarketId = data[mid].marketId;
        if (marketId < midMarketId) {
            return _getInternal(
                data,
                beginInclusive,
                mid,
                marketId
            );
        } else if (marketId > midMarketId) {
            return _getInternal(
                data,
                mid + 1,
                endExclusive,
                marketId
            );
        } else {
            return data[mid];
        }
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Require } from "./Require.sol";


/**
 * @title Bits
 * @author Dolomite
 *
 * Library for caching information about markets
 */
library Bits {

    // ============ Constants ============

    uint internal constant ONE = 1;
    uint256 internal constant MAX_UINT_BITS = 256;

    // ============ Functions ============

    function createBitmaps(uint maxLength) internal pure returns (uint[] memory) {
        return new uint[]((maxLength / MAX_UINT_BITS) + ONE);
    }

    function getMarketIdFromBit(
        uint index,
        uint bit
    ) internal pure returns (uint) {
        return (MAX_UINT_BITS * index) + bit;
    }

    function setBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        bitmaps[bucketIndex] |= (ONE << indexFromRight);
    }

    function hasBit(
        uint[] memory bitmaps,
        uint marketId
    ) internal pure returns (bool) {
        uint bucketIndex = marketId / MAX_UINT_BITS;
        uint indexFromRight = marketId % MAX_UINT_BITS;
        uint bit = bitmaps[bucketIndex] & (ONE << indexFromRight);
        return bit > 0;
    }

    function unsetBit(
        uint bitmap,
        uint bit
    ) internal pure returns (uint) {
        return bitmap - (ONE << bit);
    }

    // solium-disable security/no-assign-params
    function getLeastSignificantBit(uint256 x) internal pure returns (uint) {
        // gas usage peaks at 350 per call

        uint lsb = 255;

        if (x & uint128(-1) > 0) {
            lsb -= 128;
        } else {
            x >>= 128;
        }

        if (x & uint64(-1) > 0) {
            lsb -= 64;
        } else {
            x >>= 64;
        }

        if (x & uint32(-1) > 0) {
            lsb -= 32;
        } else {
            x >>= 32;
        }

        if (x & uint16(-1) > 0) {
            lsb -= 16;
        } else {
            x >>= 16;
        }

        if (x & uint8(-1) > 0) {
            lsb -= 8;
        } else {
            x >>= 8;
        }

        if (x & 0xf > 0) {
            lsb -= 4;
        } else {
            x >>= 4;
        }

        if (x & 0x3 > 0) {
            lsb -= 2;
        } else {
            x >>= 2;
            // solium-enable security/no-assign-params
        }

        if (x & 0x1 > 0) {
            lsb -= 1;
        }

        return lsb;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "./Account.sol";
import { Types } from "./Types.sol";


/**
 * @title Actions
 * @author dYdX
 *
 * Library that defines and parses valid Actions
 */
library Actions {

    // ============ Constants ============

    bytes32 constant FILE = "Actions";

    // ============ Enums ============

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AccountLayout {
        OnePrimary,
        TwoPrimary,
        PrimaryAndSecondary
    }

    enum MarketLayout {
        ZeroMarkets,
        OneMarket,
        TwoMarkets
    }

    // ============ Structs ============

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    // ============ Action Types ============

    /*
     * Moves tokens from an address to DolomiteMargin. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from DolomiteMargin to another address. Can either borrow tokens or reduce the amount
     * previously supplied.
     */
    struct WithdrawArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address to;
    }

    /*
     * Transfers balance between two accounts. The msg.sender must be an operator for both accounts.
     * The amount field applies to accountOne.
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TransferArgs {
        Types.AssetAmount amount;
        Account.Info accountOne;
        Account.Info accountTwo;
        uint256 market;
    }

    /*
     * Acquires a certain amount of tokens by spending other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper contract and expects makerMarket tokens in return. The amount field
     * applies to the makerMarket.
     */
    struct BuyArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 makerMarket;
        uint256 takerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Spends a certain amount of tokens to acquire other tokens. Sends takerMarket tokens to the
     * specified exchangeWrapper and expects makerMarket tokens in return. The amount field applies
     * to the takerMarket.
     */
    struct SellArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 takerMarket;
        uint256 makerMarket;
        address exchangeWrapper;
        bytes orderData;
    }

    /*
     * Trades balances between two accounts using any external contract that implements the
     * AutoTrader interface. The AutoTrader contract must be an operator for the makerAccount (for
     * which it is trading on-behalf-of). The amount field applies to the makerAccount and the
     * inputMarket. This proposed change to the makerAccount is passed to the AutoTrader which will
     * quote a change for the makerAccount in the outputMarket (or will disallow the trade).
     * This action does not require any token movement since the trade is done internally to DolomiteMargin.
     */
    struct TradeArgs {
        Types.AssetAmount amount;
        Account.Info takerAccount;
        Account.Info makerAccount;
        uint256 inputMarket;
        uint256 outputMarket;
        address autoTrader;
        bytes tradeData;
    }

    /*
     * Each account must maintain a certain margin-ratio (specified globally). If the account falls
     * below this margin-ratio, it can be liquidated by any other account. This allows anyone else
     * (arbitrageurs) to repay any borrowed asset (owedMarket) of the liquidating account in
     * exchange for any collateral asset (heldMarket) of the liquidAccount. The ratio is determined
     * by the price ratio (given by the oracles) plus a spread (specified globally). Liquidating an
     * account also sets a flag on the account that the account is being liquidated. This allows
     * anyone to continue liquidating the account until there are no more borrows being taken by the
     * liquidating account. Liquidators do not have to liquidate the entire account all at once but
     * can liquidate as much as they choose. The liquidating flag allows liquidators to continue
     * liquidating the account even if it becomes collateralized through partial liquidation or
     * price movement.
     */
    struct LiquidateArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info liquidAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances remaining. The arbitrageur
     * pays back the negative asset (owedMarket) of the vaporAccount in exchange for a collateral asset (heldMarket) at
     * a favorable spread. However, since the liquidAccount has no collateral assets, the collateral must come from
     * DolomiteMargin's excess tokens.
     */
    struct VaporizeArgs {
        Types.AssetAmount amount;
        Account.Info solidAccount;
        Account.Info vaporAccount;
        uint256 owedMarket;
        uint256 heldMarket;
    }

    /*
     * Passes arbitrary bytes of data to an external contract that implements the Callee interface.
     * Does not change any asset amounts. This function may be useful for setting certain variables
     * on layer-two contracts for certain accounts without having to make a separate Ethereum
     * transaction for doing so. Also, the second-layer contracts can ensure that the call is coming
     * from an operator of the particular account.
     */
    struct CallArgs {
        Account.Info account;
        address callee;
        bytes data;
    }

    // ============ Helper Functions ============

    function getMarketLayout(
        ActionType actionType
    )
        internal
        pure
        returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit
            || actionType == Actions.ActionType.Withdraw
            || actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        }
        else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(
        ActionType actionType
    )
        internal
        pure
        returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer
            || actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate
            || actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

    // ============ Parsing Functions ============

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (DepositArgs memory)
    {
        return DepositArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            from: args.otherAddress
        });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (WithdrawArgs memory)
    {
        return WithdrawArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            market: args.primaryMarketId,
            to: args.otherAddress
        });
    }

    function parseTransferArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TransferArgs memory)
    {
        return TransferArgs({
            amount: args.amount,
            accountOne: accounts[args.accountId],
            accountTwo: accounts[args.otherAccountId],
            market: args.primaryMarketId
        });
    }

    function parseBuyArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (BuyArgs memory)
    {
        return BuyArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            makerMarket: args.primaryMarketId,
            takerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseSellArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (SellArgs memory)
    {
        return SellArgs({
            amount: args.amount,
            account: accounts[args.accountId],
            takerMarket: args.primaryMarketId,
            makerMarket: args.secondaryMarketId,
            exchangeWrapper: args.otherAddress,
            orderData: args.data
        });
    }

    function parseTradeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (TradeArgs memory)
    {
        return TradeArgs({
            amount: args.amount,
            takerAccount: accounts[args.accountId],
            makerAccount: accounts[args.otherAccountId],
            inputMarket: args.primaryMarketId,
            outputMarket: args.secondaryMarketId,
            autoTrader: args.otherAddress,
            tradeData: args.data
        });
    }

    function parseLiquidateArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (LiquidateArgs memory)
    {
        return LiquidateArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            liquidAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseVaporizeArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (VaporizeArgs memory)
    {
        return VaporizeArgs({
            amount: args.amount,
            solidAccount: accounts[args.accountId],
            vaporAccount: accounts[args.otherAccountId],
            owedMarket: args.primaryMarketId,
            heldMarket: args.secondaryMarketId
        });
    }

    function parseCallArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    )
        internal
        pure
        returns (CallArgs memory)
    {
        return CallArgs({
            account: accounts[args.accountId],
            callee: args.otherAddress,
            data: args.data
        });
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Types } from "./Types.sol";
import { EnumerableSet } from "./EnumerableSet.sol";


/**
 * @title Account
 * @author dYdX
 *
 * Library of structs and functions that represent an account
 */
library Account {
    // ============ Enums ============

    /*
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum Status {
        Normal,
        Liquid,
        Vapor
    }

    // ============ Structs ============

    // Represents the unique key that specifies an account
    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    // The complete storage for any account
    struct Storage {
        Status status;
        uint32 numberOfMarketsWithBorrow;
        EnumerableSet.Set marketsWithNonZeroBalanceSet;
        mapping (uint256 => Types.Par) balances; // Mapping from marketId to principal
    }

    // ============ Library Functions ============

    function equals(
        Info memory a,
        Info memory b
    )
        internal
        pure
        returns (bool)
    {
        return a.owner == b.owner && a.number == b.number;
    }
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Account } from "../lib/Account.sol";
import { Types } from "../lib/Types.sol";


/**
 * @title IRecyclable
 * @author Dolomite
 *
 * Interface that recyclable tokens/markets must implement
 */
contract IRecyclable {

    // ============ Public State Variables ============

    /**
     * @notice The max timestamp at which tokens represented by this contract should be expired, allowing liquidators
     *          to close margin positions involving this token, so this contract can be recycled.
     */
    uint public MAX_EXPIRATION_TIMESTAMP;

    // ============ Public Functions ============

    /**
     * @return  The token around which this recycle contract wraps.
     */
    function TOKEN() external view returns (IERC20);

    /**
     * A callback for the recyclable market that allows it to perform any cleanup logic, preventing its usage with
     * DolomiteMargin once this transaction completes. #isRecycled  should return `true` after this function is called.
     */
    function recycle() external;

    /**
     * Called when the market is initialized in DolomiteMargin
     */
    function initialize() external;

    /**
     * @return The account number used to index into the account for this user
     */
    function getAccountNumber(Account.Info calldata account) external pure returns (uint256);

    function getAccountPar(Account.Info calldata account) external view returns (Types.Par memory);

    /**
     * @return  True if this contract is recycled, disallowing further deposits/interactions with DolomiteMargin and freeing this
     *          token's `MARKET_ID`.
     */
    function isRecycled() external view returns (bool);

    /**
     * @dev Deposits the underlying token into this smart contract and adds to the user's balance with DolomiteMargin. The user
     *      must set an allowance for `TOKEN`, using this contract as the `spender`.
     */
    function depositIntoDolomiteMargin(uint accountNumber, uint amount) external;

    /**
     * @dev Withdraws a specific amount of a user's balance from the smart contract to `msg.sender`
     */
    function withdrawFromDolomiteMargin(uint accountNumber, uint amount) external;

    /**
     * @dev Withdraws the user's remaining balance from the smart contract, after this contract has been recycled.
     */
    function withdrawAfterRecycle(uint accountNumber) external;

    /**
     * @dev Performs a trade between a user and the specified `IExchangeWrapper` to open or a close a margin position
     *      involving this market. Specifying `isOpen` will change the taker amount from borrowAmount (if true) to
     *      `supplyAmount` (if false). Keep in mind, this taker amount is passed through as `requestedFillAmount` to
     *      `IExchangeWrapper`.
     */
    function trade(
        uint accountNumber,
        Types.AssetAmount calldata supplyAmount, // equivalent to amounts[amounts.length - 1]
        address borrowToken,
        Types.AssetAmount calldata borrowAmount,
        address exchangeWrapper,
        uint expirationTimestamp,
        bool isOpen,
        bytes calldata tradeData
    )
        external;

    /**
     * @return  true if this recyclable contract is expired, or false if it's not yet.
     */
    function isExpired() public view returns (bool) {
        return MAX_EXPIRATION_TIMESTAMP < block.timestamp;
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Monetary } from "../lib/Monetary.sol";


/**
 * @title IPriceOracle
 * @author dYdX
 *
 * Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
contract IPriceOracle {

    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10 ** 36;

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^36.
     *                So a USD-stable coin with 18 decimal places would return 10^18.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
        public
        view
        returns (Monetary.Price memory);
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "../lib/Types.sol";

interface ILiquidationCallback {

    /**
     * A callback function to notify the smart contract that it is being liquidated. This function is called before the
     * new balances are set in state, so calling `getAccountPar/Wei` will return this liquidated account's balance
     * before `heldDeltaWei` or `owedDeltaWei` are applied.
     *
     * @param accountNumber The account number being liquidated
     * @param heldMarketId  The market that was positive for this account, whose collateral is being seized
     * @param heldDeltaWei  The amount of seized collateral; always negative or 0
     * @param owedMarketId  The borrowed balance that is being forcefully repaid
     * @param owedDeltaWei  The amount of borrowed assets to be repaid. Always 0 or positive, since the user's balance
     *                      is going from negative to 0.
     */
    function onLiquidate(
        uint accountNumber,
        uint heldMarketId,
        Types.Wei calldata heldDeltaWei,
        uint owedMarketId,
        Types.Wei calldata owedDeltaWei
    ) external;
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Interest } from "../lib/Interest.sol";


/**
 * @title IInterestSetter
 * @author dYdX
 *
 * Interface that Interest Setters for DolomiteMargin must implement in order to report interest rates.
 */
interface IInterestSetter {

    // ============ Public Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
        external
        view
        returns (Interest.Rate memory);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;


/**
 * @title IExchangeWrapper
 * @author dYdX
 *
 * Interface that Exchange Wrappers for DolomiteMargin must implement in order to trade ERC20 tokens.
 */
interface IExchangeWrapper {

    // ============ Public Functions ============

    /**
     * Exchange some amount of takerToken for makerToken.
     *
     * @param  tradeOriginator      Address of the initiator of the trade (however, this value
     *                              cannot always be trusted as it is set at the discretion of the
     *                              msg.sender)
     * @param  receiver             Address to set allowance on once the trade has completed
     * @param  makerToken           Address of makerToken, the token to receive (target asset; IE path[path.length - 1])
     * @param  takerToken           Address of takerToken, the token to pay (originator asset; IE path[0])
     * @param  requestedFillAmount  Amount of takerToken being paid
     * @param  orderData            Arbitrary bytes data for any information to pass to the exchange
     * @return                      The amount of makerToken received
     */
    function exchange(
        address tradeOriginator,
        address receiver,
        address makerToken,
        address takerToken,
        uint256 requestedFillAmount,
        bytes calldata orderData
    )
        external
        returns (uint256);

    /**
     * Get amount of takerToken required to buy a certain amount of makerToken for a given trade.
     * Should match the takerToken amount used in exchangeForAmount. If the order cannot provide
     * exactly desiredMakerToken, then it must return the price to buy the minimum amount greater
     * than desiredMakerToken
     *
     * @param  makerToken         Address of makerToken, the token to receive
     * @param  takerToken         Address of takerToken, the token to pay
     * @param  desiredMakerToken  Amount of makerToken requested
     * @param  orderData          Arbitrary bytes data for any information to pass to the exchange
     * @return                    Amount of takerToken the needed to complete the exchange
     */
    function getExchangeCost(
        address makerToken,
        address takerToken,
        uint256 desiredMakerToken,
        bytes calldata orderData
    )
        external
        view
        returns (uint256);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title IERC20
 * @author dYdX
 *
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
contract IERC20Detailed is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

/*

    Copyright 2021 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Decimal } from "../lib/Decimal.sol";
import { Interest } from "../lib/Interest.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";

interface IDolomiteMargin {

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (Monetary.Price memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (Types.TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (Interest.Index memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IPriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (Interest.Rate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Storage.Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Storage.Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Storage.Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Storage.Market memory,
        Interest.Index memory,
        Monetary.Price memory,
        Interest.Rate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Types.Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        Account.Info calldata account,
        uint256 marketId
    ) external view returns (Types.Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        Account.Info calldata account
    ) external view returns (Account.Status);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithNonZeroBalances(
        Account.Info calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getNumberOfMarketsWithBorrow(
        Account.Info calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        Account.Info calldata account
    ) external view returns (Monetary.Value memory, Monetary.Value memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        Account.Info calldata account
    ) external view returns (uint[] memory, address[] memory, Types.Par[] memory, Types.Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal.D256 memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal.D256 memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal.D256 memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal.D256 memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (Monetary.Value memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (Storage.RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (Storage.RiskLimits memory);

    // ============ Write Functions ============

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        Account.Info[] calldata accounts,
        Actions.ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        Types.OperatorArg[] calldata args
    ) external;

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../lib/Account.sol";


/**
 * @title ICallee
 * @author dYdX
 *
 * Interface that Callees for DolomiteMargin must implement in order to ingest data.
 */
contract ICallee {

    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to DolomiteMargin
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    )
        public;
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Account } from "../lib/Account.sol";
import { Types } from "../lib/Types.sol";


/**
 * @title IAutoTrader
 * @author dYdX
 *
 * Interface that Auto-Traders for DolomiteMargin must implement in order to approve trades.
 */
contract IAutoTrader {

    // ============ Public Functions ============

    /**
     * Allows traders to make trades approved by this smart contract. The active trader's account is
     * the takerAccount and the passive account (for which this contract approves trades
     * on-behalf-of) is the makerAccount.
     *
     * @param  inputMarketId   The market for which the trader specified the original amount
     * @param  outputMarketId  The market for which the trader wants the resulting amount specified
     * @param  makerAccount    The account for which this contract is making trades
     * @param  takerAccount    The account requesting the trade
     * @param  oldInputPar     The old principal amount for the makerAccount for the inputMarketId
     * @param  newInputPar     The new principal amount for the makerAccount for the inputMarketId
     * @param  inputWei        The change in token amount for the makerAccount for the inputMarketId
     * @param  data            Arbitrary data passed in by the trader
     * @return                 The AssetAmount for the makerAccount for the outputMarketId
     */
    function getTradeCost(
        uint256 inputMarketId,
        uint256 outputMarketId,
        Account.Info memory makerAccount,
        Account.Info memory takerAccount,
        Types.Par memory oldInputPar,
        Types.Par memory newInputPar,
        Types.Wei memory inputWei,
        bytes memory data
    )
        public
        returns (Types.AssetAmount memory);
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IAutoTrader } from "../interfaces/IAutoTrader.sol";
import { ICallee } from "../interfaces/ICallee.sol";
import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Decimal } from "../lib/Decimal.sol";
import { EnumerableSet } from "../lib/EnumerableSet.sol";
import { Events } from "../lib/Events.sol";
import { Exchange } from "../lib/Exchange.sol";
import { Math } from "../lib/Math.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";
import { LiquidateOrVaporizeImpl } from "./LiquidateOrVaporizeImpl.sol";


/**
 * @title OperationImpl
 * @author dYdX
 *
 * Logic for processing actions
 */
library OperationImpl {
    using Cache for Cache.MarketCache;
    using EnumerableSet for EnumerableSet.Set;
    using SafeMath for uint256;
    using Storage for Storage.State;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "OperationImpl";

    // ============ Public Functions ============

    function operate(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public
    {
        Events.logOperation();

        _verifyInputs(accounts, actions);

        (
            bool[] memory primaryAccounts,
            Cache.MarketCache memory cache
        ) = _runPreprocessing(
            state,
            accounts,
            actions
        );

        _runActions(
            state,
            accounts,
            actions,
            cache
        );

        _verifyFinalState(
            state,
            accounts,
            primaryAccounts,
            cache
        );
    }

    // ============ Helper Functions ============

    function _verifyInputs(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        private
        pure
    {
        Require.that(
            accounts.length != 0,
            FILE,
            "Cannot have zero accounts"
        );
        Require.that(
            actions.length != 0,
            FILE,
            "Cannot have zero actions"
        );

        for (uint256 a = 0; a < accounts.length; a++) {
            for (uint256 b = a + 1; b < accounts.length; b++) {
                Require.that(
                    !Account.equals(accounts[a], accounts[b]),
                    FILE,
                    "Cannot duplicate accounts",
                    accounts[a].owner,
                    accounts[a].number
                );
            }
        }
    }

    function _runPreprocessing(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        private
        returns (
            bool[] memory,
            Cache.MarketCache memory
        )
    {
        uint256 numMarkets = state.numMarkets;
        bool[] memory primaryAccounts = new bool[](accounts.length);
        Cache.MarketCache memory cache = Cache.create(numMarkets);

        // keep track of primary accounts and indexes that need updating
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory arg = actions[i];
            Actions.ActionType actionType = arg.actionType;
            Actions.MarketLayout marketLayout = Actions.getMarketLayout(actionType);
            Actions.AccountLayout accountLayout = Actions.getAccountLayout(actionType);

            // parse out primary accounts
            if (accountLayout != Actions.AccountLayout.OnePrimary) {
                Require.that(
                    arg.accountId != arg.otherAccountId,
                    FILE,
                    "Duplicate accounts in action",
                    i
                );
                if (accountLayout == Actions.AccountLayout.TwoPrimary) {
                    primaryAccounts[arg.otherAccountId] = true;
                } else {
                    // accountLayout == Actions.AccountLayout.PrimaryAndSecondary
                    Require.that(
                        !primaryAccounts[arg.otherAccountId],
                        FILE,
                        "Requires non-primary account",
                        arg.otherAccountId
                    );
                }
            }
            primaryAccounts[arg.accountId] = true;

            // keep track of indexes to update
            if (marketLayout == Actions.MarketLayout.OneMarket) {
                _updateMarket(state, cache, arg.primaryMarketId);
            } else if (marketLayout == Actions.MarketLayout.TwoMarkets) {
                Require.that(
                    arg.primaryMarketId != arg.secondaryMarketId,
                    FILE,
                    "Duplicate markets in action",
                    i
                );
                _updateMarket(state, cache, arg.primaryMarketId);
                _updateMarket(state, cache, arg.secondaryMarketId);
            }
        }

        // get any other markets for which an account has a balance
        for (uint256 a = 0; a < accounts.length; a++) {
            uint[] memory marketIdsWithBalance = state.getMarketsWithBalances(accounts[a]);
            for (uint256 i = 0; i < marketIdsWithBalance.length; i++) {
                _updateMarket(state, cache, marketIdsWithBalance[i]);
            }
        }

        state.initializeCache(cache);

        return (primaryAccounts, cache);
    }

    function _updateMarket(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 marketId
    )
        private
    {
        if (!cache.hasMarket(marketId)) {
            cache.set(marketId);
            Events.logIndexUpdate(marketId, state.updateIndex(marketId));
        }
    }

    function _runActions(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Cache.MarketCache memory cache
    )
        private
    {
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory action = actions[i];
            Actions.ActionType actionType = action.actionType;


            if (actionType == Actions.ActionType.Deposit) {
                _deposit(state, Actions.parseDepositArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Withdraw) {
                _withdraw(state, Actions.parseWithdrawArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Transfer) {
                _transfer(state, Actions.parseTransferArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Buy) {
                _buy(state, Actions.parseBuyArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Sell) {
                _sell(state, Actions.parseSellArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Trade) {
                _trade(state, Actions.parseTradeArgs(accounts, action));
            }
            else if (actionType == Actions.ActionType.Liquidate) {
                LiquidateOrVaporizeImpl.liquidate(state, Actions.parseLiquidateArgs(accounts, action), cache);
            }
            else if (actionType == Actions.ActionType.Vaporize) {
                // use the library to save space since this function is rarely ever called
                LiquidateOrVaporizeImpl.vaporize(state, Actions.parseVaporizeArgs(accounts, action), cache);
            }
            else if (actionType == Actions.ActionType.Call) {
                _call(state, Actions.parseCallArgs(accounts, action));
            }
        }
    }

    function _verifyFinalState(
        Storage.State storage state,
        Account.Info[] memory accounts,
        bool[] memory primaryAccounts,
        Cache.MarketCache memory cache
    )
        private
    {
        // verify no increase in borrowPar for closing markets
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 i = 0; i < numMarkets; i++) {
            uint256 marketId = cache.getAtIndex(i).marketId;
            if (cache.getAtIndex(i).isClosing) {
                Require.that(
                    state.getTotalPar(marketId).borrow <= cache.getAtIndex(i).borrowPar,
                    FILE,
                    "Market is closing",
                    marketId
                );
            }
            if (state.markets[marketId].isRecyclable) {
                // This market is recyclable. Check that only the `token` is the owner
                for (uint256 a = 0; a < accounts.length; a++) {
                    if (accounts[a].owner != cache.getAtIndex(i).token) {
                        // If the owner of the recyclable token isn't the TokenProxy,
                        // THEN check that the account doesn't have a balance for this recyclable `marketId`
                        Require.that(
                            !state.getMarketsWithBalancesSet(accounts[a]).contains(marketId),
                            FILE,
                            "invalid recyclable owner",
                            accounts[a].owner,
                            accounts[a].number,
                            marketId
                        );
                    }
                }
            }
        }

        // verify account collateralization
        for (uint256 a = 0; a < accounts.length; a++) {
            Account.Info memory account = accounts[a];

            // don't check collateralization for non-primary accounts
            if (!primaryAccounts[a]) {
                continue;
            }

            // validate minBorrowedValue
            bool collateralized = state.isCollateralized(account, cache, /* requireMinBorrow = */ true);

            // check collateralization for primary accounts
            Require.that(
                collateralized,
                FILE,
                "Undercollateralized account",
                account.owner,
                account.number
            );

            // ensure status is normal for primary accounts
            if (state.getStatus(account) != Account.Status.Normal) {
                state.setStatus(account, Account.Status.Normal);
            }
        }
    }

    // ============ Action Functions ============

    function _deposit(
        Storage.State storage state,
        Actions.DepositArgs memory args
    )
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        Require.that(
            args.from == msg.sender || args.from == args.account.owner,
            FILE,
            "Invalid deposit source",
            args.from
        );

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.market,
            args.amount
        );

        state.setPar(
            args.account,
            args.market,
            newPar
        );

        // requires a positive deltaWei
        Exchange.transferIn(
            state.getToken(args.market),
            args.from,
            deltaWei
        );

        Events.logDeposit(
            state,
            args,
            deltaWei
        );
    }

    function _withdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args
    )
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.market,
            args.amount
        );

        state.setPar(
            args.account,
            args.market,
            newPar
        );

        // requires a negative deltaWei
        Exchange.transferOut(
            state.getToken(args.market),
            args.to,
            deltaWei
        );

        Events.logWithdraw(
            state,
            args,
            deltaWei
        );
    }

    function _transfer(
        Storage.State storage state,
        Actions.TransferArgs memory args
    )
        private
    {
        state.requireIsOperator(args.accountOne, msg.sender);
        state.requireIsOperator(args.accountTwo, msg.sender);

        (
            Types.Par memory newPar,
            Types.Wei memory deltaWei
        ) = state.getNewParAndDeltaWei(
            args.accountOne,
            args.market,
            args.amount
        );

        state.setPar(
            args.accountOne,
            args.market,
            newPar
        );

        state.setParFromDeltaWei(
            args.accountTwo,
            args.market,
            deltaWei.negative()
        );

        Events.logTransfer(
            state,
            args,
            deltaWei
        );
    }

    function _buy(
        Storage.State storage state,
        Actions.BuyArgs memory args
    )
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (
            Types.Par memory makerPar,
            Types.Wei memory makerWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.makerMarket,
            args.amount
        );

        Types.Wei memory takerWei = Exchange.getCost(
            args.exchangeWrapper,
            makerToken,
            takerToken,
            makerWei,
            args.orderData
        );

        Types.Wei memory tokensReceived = Exchange.exchange(
            args.exchangeWrapper,
            args.account.owner,
            makerToken,
            takerToken,
            takerWei,
            args.orderData
        );

        Require.that(
            tokensReceived.value >= makerWei.value,
            FILE,
            "Buy amount less than promised",
            tokensReceived.value
        );

        state.setPar(
            args.account,
            args.makerMarket,
            makerPar
        );

        state.setParFromDeltaWei(
            args.account,
            args.takerMarket,
            takerWei
        );

        Events.logBuy(
            state,
            args,
            takerWei,
            makerWei
        );
    }

    function _sell(
        Storage.State storage state,
        Actions.SellArgs memory args
    )
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (
            Types.Par memory takerPar,
            Types.Wei memory takerWei
        ) = state.getNewParAndDeltaWei(
            args.account,
            args.takerMarket,
            args.amount
        );

        Types.Wei memory makerWei = Exchange.exchange(
            args.exchangeWrapper,
            args.account.owner,
            makerToken,
            takerToken,
            takerWei,
            args.orderData
        );

        state.setPar(
            args.account,
            args.takerMarket,
            takerPar
        );

        state.setParFromDeltaWei(
            args.account,
            args.makerMarket,
            makerWei
        );

        Events.logSell(
            state,
            args,
            takerWei,
            makerWei
        );
    }

    function _trade(
        Storage.State storage state,
        Actions.TradeArgs memory args
    )
        private
    {
        state.requireIsOperator(args.takerAccount, msg.sender);
        state.requireIsOperator(args.makerAccount, args.autoTrader);

        Types.Par memory oldInputPar = state.getPar(
            args.makerAccount,
            args.inputMarket
        );
        (
            Types.Par memory newInputPar,
            Types.Wei memory inputWei
        ) = state.getNewParAndDeltaWei(
            args.makerAccount,
            args.inputMarket,
            args.amount
        );

        Types.AssetAmount memory outputAmount = IAutoTrader(args.autoTrader).getTradeCost(
            args.inputMarket,
            args.outputMarket,
            args.makerAccount,
            args.takerAccount,
            oldInputPar,
            newInputPar,
            inputWei,
            args.tradeData
        );

        (
            Types.Par memory newOutputPar,
            Types.Wei memory outputWei
        ) = state.getNewParAndDeltaWei(
            args.makerAccount,
            args.outputMarket,
            outputAmount
        );

        Require.that(
            outputWei.isZero() || inputWei.isZero() || outputWei.sign != inputWei.sign,
            FILE,
            "Trades cannot be one-sided",
            args.autoTrader
        );

        // set the balance for the maker
        state.setPar(
            args.makerAccount,
            args.inputMarket,
            newInputPar
        );
        state.setPar(
            args.makerAccount,
            args.outputMarket,
            newOutputPar
        );

        // set the balance for the taker
        state.setParFromDeltaWei(
            args.takerAccount,
            args.inputMarket,
            inputWei.negative()
        );
        state.setParFromDeltaWei(
            args.takerAccount,
            args.outputMarket,
            outputWei.negative()
        );

        Events.logTrade(
            state,
            args,
            inputWei,
            outputWei
        );
    }

    function _call(
        Storage.State storage state,
        Actions.CallArgs memory args
    )
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        ICallee(args.callee).callFunction(
            msg.sender,
            args.account,
            args.data
        );

        Events.logCall(args);
    }

}

/*

    Copyright 2021 Dolomite

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ILiquidationCallback } from "../interfaces/ILiquidationCallback.sol";
import { Account } from "../lib/Account.sol";
import { Actions } from "../lib/Actions.sol";
import { Cache } from "../lib/Cache.sol";
import { Decimal } from "../lib/Decimal.sol";
import { Events } from "../lib/Events.sol";
import { Math } from "../lib/Math.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Types } from "../lib/Types.sol";


library LiquidateOrVaporizeImpl {
    using Address for address;
    using Cache for Cache.MarketCache;
    using SafeMath for uint256;
    using Storage for Storage.State;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "LiquidateOrVaporizeImpl";

    // ============ Events ============

    event LogLiquidationCallbackSuccess(address indexed liquidAccountOwner, uint liquidAccountNumber);

    event LogLiquidationCallbackFailure(address indexed liquidAccountOwner, uint liquidAccountNumber, string reason);

    // ============ Account Functions ============

    function liquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Cache.MarketCache memory cache
    )
    public
    {
        state.requireIsGlobalOperator(msg.sender);

        // verify liquidatable
        if (Account.Status.Liquid != state.getStatus(args.liquidAccount)) {
            Require.that(
                !state.isCollateralized(args.liquidAccount, cache, /* requireMinBorrow = */ false),
                FILE,
                "Unliquidatable account",
                args.liquidAccount.owner,
                args.liquidAccount.number
            );
            state.setStatus(args.liquidAccount, Account.Status.Liquid);
        }

        Types.Wei memory maxHeldWei = state.getWei(
            args.liquidAccount,
            args.heldMarket
        );

        Require.that(
            !maxHeldWei.isNegative(),
            FILE,
            "Collateral cannot be negative",
            args.heldMarket
        );

        (
            Types.Par memory owedPar,
            Types.Wei memory owedWei
        ) = state.getNewParAndDeltaWeiForLiquidation(
            args.liquidAccount,
            args.owedMarket,
            args.amount
        );

        (
            Monetary.Price memory heldPrice,
            Monetary.Price memory owedPriceAdj
        ) = _getLiquidationPrices(
            state,
            cache,
            args.heldMarket,
            args.owedMarket
        );

        Types.Wei memory heldWei = _owedWeiToHeldWei(owedWei, heldPrice, owedPriceAdj);

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPriceAdj);

            _callLiquidateCallbackIfNecessary(
                args.liquidAccount,
                args.heldMarket,
                heldWei,
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.liquidAccount,
                args.heldMarket,
                Types.zeroPar()
            );
            state.setParFromDeltaWei(
                args.liquidAccount,
                args.owedMarket,
                owedWei
            );
        } else {
            _callLiquidateCallbackIfNecessary(
                args.liquidAccount,
                args.heldMarket,
                heldWei,
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.liquidAccount,
                args.owedMarket,
                owedPar
            );
            state.setParFromDeltaWei(
                args.liquidAccount,
                args.heldMarket,
                heldWei
            );
        }

        // set the balances for the solid account
        state.setParFromDeltaWei(
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        state.setParFromDeltaWei(
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );

        Events.logLiquidate(
            state,
            args,
            heldWei,
            owedWei
        );
    }

    function vaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Cache.MarketCache memory cache
    )
    public
    {
        state.requireIsOperator(args.solidAccount, msg.sender);

        // verify vaporizable
        if (Account.Status.Vapor != state.getStatus(args.vaporAccount)) {
            Require.that(
                state.isVaporizable(args.vaporAccount, cache),
                FILE,
                "Unvaporizable account",
                args.vaporAccount.owner,
                args.vaporAccount.number
            );
            state.setStatus(args.vaporAccount, Account.Status.Vapor);
        }

        // First, attempt to refund using the same token
        (
            bool fullyRepaid,
            Types.Wei memory excessWei
        ) = _vaporizeUsingExcess(state, args);
        if (fullyRepaid) {
            Events.logVaporize(
                state,
                args,
                Types.zeroWei(),
                Types.zeroWei(),
                excessWei
            );
            return;
        }

        Types.Wei memory maxHeldWei = state.getNumExcessTokens(args.heldMarket);

        Require.that(
            !maxHeldWei.isNegative(),
            FILE,
            "Excess cannot be negative",
            args.heldMarket
        );

        (
        Types.Par memory owedPar,
        Types.Wei memory owedWei
        ) = state.getNewParAndDeltaWeiForLiquidation(
            args.vaporAccount,
            args.owedMarket,
            args.amount
        );

        (
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
        ) = _getLiquidationPrices(
            state,
            cache,
            args.heldMarket,
            args.owedMarket
        );

        Types.Wei memory heldWei = _owedWeiToHeldWei(owedWei, heldPrice, owedPrice);

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPrice);

            _callLiquidateCallbackIfNecessary(
                args.vaporAccount,
                args.heldMarket,
                Types.zeroWei(),
                args.owedMarket,
                owedWei
            );

            state.setParFromDeltaWei(
                args.vaporAccount,
                args.owedMarket,
                owedWei
            );
        } else {
            _callLiquidateCallbackIfNecessary(
                args.vaporAccount,
                args.heldMarket,
                Types.zeroWei(),
                args.owedMarket,
                owedWei
            );

            state.setPar(
                args.vaporAccount,
                args.owedMarket,
                owedPar
            );
        }

        // set the balances for the solid account
        state.setParFromDeltaWei(
            args.solidAccount,
            args.owedMarket,
            owedWei.negative()
        );
        state.setParFromDeltaWei(
            args.solidAccount,
            args.heldMarket,
            heldWei.negative()
        );

        Events.logVaporize(
            state,
            args,
            heldWei,
            owedWei,
            excessWei
        );
    }

    /**
     * Attempt to vaporize an account's balance using the excess tokens in the protocol. Return a
     * bool and a wei value. The boolean is true if and only if the balance was fully vaporized. The
     * Wei value is how many excess tokens were used to partially or fully vaporize the account's
     * negative balance.
     */
    function _vaporizeUsingExcess(
        Storage.State storage state,
        Actions.VaporizeArgs memory args
    )
    internal
    returns (bool, Types.Wei memory)
    {
        Types.Wei memory excessWei = state.getNumExcessTokens(args.owedMarket);

        // There are no excess funds, return zero
        if (!excessWei.isPositive()) {
            return (false, Types.zeroWei());
        }

        Types.Wei memory maxRefundWei = state.getWei(args.vaporAccount, args.owedMarket);
        maxRefundWei.sign = true;

        // The account is fully vaporizable using excess funds
        if (excessWei.value >= maxRefundWei.value) {
            state.setPar(
                args.vaporAccount,
                args.owedMarket,
                Types.zeroPar()
            );
            return (true, maxRefundWei);
        }

        // The account is only partially vaporizable using excess funds
        else {
            state.setParFromDeltaWei(
                args.vaporAccount,
                args.owedMarket,
                excessWei
            );
            return (false, excessWei);
        }
    }

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of owedWei
     * given heldWei and the (spread-adjusted) prices of each asset.
     */
    function _heldWeiToOwedWei(
        Types.Wei memory heldWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    )
    internal
    pure
    returns (Types.Wei memory)
    {
        return Types.Wei({
        sign: true,
        value: Math.getPartialRoundUp(heldWei.value, heldPrice.value, owedPrice.value)
        });
    }

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of heldWei
     * given owedWei and the (spread-adjusted) prices of each asset.
     */
    function _owedWeiToHeldWei(
        Types.Wei memory owedWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    )
    internal
    pure
    returns (Types.Wei memory)
    {
        return Types.Wei({
        sign: false,
        value: Math.getPartial(owedWei.value, owedPrice.value, heldPrice.value)
        });
    }

    /**
     * Return the (spread-adjusted) prices of two assets for the purposes of liquidation or
     * vaporization.
     */
    function _getLiquidationPrices(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 heldMarketId,
        uint256 owedMarketId
    )
    internal
    view
    returns (
        Monetary.Price memory,
        Monetary.Price memory
    )
    {
        uint256 owedPrice = cache.get(owedMarketId).price.value;
        Decimal.D256 memory spread = state.getLiquidationSpreadForPair(
            heldMarketId,
            owedMarketId
        );

        Monetary.Price memory owedPriceAdj = Monetary.Price({
        value: owedPrice.add(Decimal.mul(owedPrice, spread))
        });

        return (cache.get(heldMarketId).price, owedPriceAdj);
    }

    function _callLiquidateCallbackIfNecessary(
        Account.Info memory liquidAccount,
        uint heldMarket,
        Types.Wei memory heldDeltaWei,
        uint owedMarket,
        Types.Wei memory owedDeltaWei
    ) internal {
        if (liquidAccount.owner.isContract()) {
            // solium-disable-next-line security/no-low-level-calls
            (bool isCallSuccessful, bytes memory result) = liquidAccount.owner.call(
                abi.encodeWithSelector(
                    ILiquidationCallback(liquidAccount.owner).onLiquidate.selector,
                    liquidAccount.number,
                    heldMarket,
                    heldDeltaWei,
                    owedMarket,
                    owedDeltaWei
                )
            );

            if (isCallSuccessful) {
                emit LogLiquidationCallbackSuccess(liquidAccount.owner, liquidAccount.number);
            } else {
                if (result.length < 68) {
                    result = bytes("");
                } else {
                    // solium-disable-next-line security/no-inline-assembly
                    assembly {
                        result := add(result, 0x04)
                    }
                    result = bytes(abi.decode(result, (string)));
                }
                emit LogLiquidationCallbackFailure(liquidAccount.owner, liquidAccount.number, string(result));
            }
        }
    }

}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { IERC20Detailed } from "../interfaces/IERC20Detailed.sol";
import { IInterestSetter } from "../interfaces/IInterestSetter.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IRecyclable } from "../interfaces/IRecyclable.sol";
import { Decimal } from "../lib/Decimal.sol";
import { Interest } from "../lib/Interest.sol";
import { Monetary } from "../lib/Monetary.sol";
import { Require } from "../lib/Require.sol";
import { Storage } from "../lib/Storage.sol";
import { Token } from "../lib/Token.sol";
import { Types } from "../lib/Types.sol";


/**
 * @title AdminImpl
 * @author dYdX
 *
 * Administrative functions to keep the protocol updated
 */
library AdminImpl {
    using Storage for Storage.State;
    using Token for address;
    using Types for Types.Wei;

    // ============ Constants ============

    bytes32 constant FILE = "AdminImpl";

    uint256 constant HEAD_POINTER = uint(-1);

    uint256 constant ONE_WEEK = 86400 * 7;

    // ============ Events ============

    event LogWithdrawExcessTokens(
        address token,
        uint256 amount
    );

    event LogWithdrawUnsupportedTokens(
        address token,
        uint256 amount
    );

    event LogAddMarket(
        uint256 marketId,
        address token
    );

    event LogRemoveMarket(
        uint256 marketId,
        address token
    );

    event LogSetIsClosing(
        uint256 marketId,
        bool isClosing
    );

    event LogSetPriceOracle(
        uint256 marketId,
        address priceOracle
    );

    event LogSetInterestSetter(
        uint256 marketId,
        address interestSetter
    );

    event LogSetMarginPremium(
        uint256 marketId,
        Decimal.D256 marginPremium
    );

    event LogSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 spreadPremium
    );

    event LogSetMarginRatio(
        Decimal.D256 marginRatio
    );

    event LogSetLiquidationSpread(
        Decimal.D256 liquidationSpread
    );

    event LogSetEarningsRate(
        Decimal.D256 earningsRate
    );

    event LogSetMinBorrowedValue(
        Monetary.Value minBorrowedValue
    );

    event LogSetGlobalOperator(
        address operator,
        bool approved
    );

    // ============ Token Functions ============

    function ownerWithdrawExcessTokens(
        Storage.State storage state,
        uint256 marketId,
        address recipient
    )
    public
    returns (uint256)
    {
        _validateMarketId(state, marketId);
        Types.Wei memory excessWei = state.getNumExcessTokens(marketId);

        Require.that(
            !excessWei.isNegative(),
            FILE,
            "Negative excess"
        );

        address token = state.getToken(marketId);

        uint256 actualBalance = IERC20Detailed(token).balanceOf(address(this));
        if (excessWei.value > actualBalance) {
            excessWei.value = actualBalance;
        }

        token.transfer(recipient, excessWei.value);

        emit LogWithdrawExcessTokens(token, excessWei.value);

        return excessWei.value;
    }

    function ownerWithdrawUnsupportedTokens(
        Storage.State storage state,
        address token,
        address recipient
    )
    public
    returns (uint256)
    {
        _requireNoMarket(state, token);

        uint256 balance = IERC20Detailed(token).balanceOf(address(this));
        token.transfer(recipient, balance);

        emit LogWithdrawUnsupportedTokens(token, balance);

        return balance;
    }

    // ============ Market Functions ============

    function ownerAddMarket(
        Storage.State storage state,
        address token,
        IPriceOracle priceOracle,
        IInterestSetter interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium,
        bool isClosing,
        bool isRecyclable
    )
    public
    {
        _requireNoMarket(state, token);

        uint256 marketId = state.recycledMarketIds[HEAD_POINTER];
        if (marketId == 0) {
            // we can't recycle a marketId, so we get a new ID and increment the number of markets
            marketId = state.numMarkets;
            state.numMarkets++;
        } else {
            // we successfully recycled the market ID.
            // reset the head pointer to the next item in the linked list
            state.recycledMarketIds[HEAD_POINTER] = state.recycledMarketIds[marketId];
        }

        state.markets[marketId].token = token;
        state.markets[marketId].index = Interest.newIndex();
        state.markets[marketId].isClosing = isClosing;
        state.markets[marketId].isRecyclable = isRecyclable;
        state.tokenToMarketId[token] = marketId;

        emit LogAddMarket(marketId, token);
        if (isClosing) {
            emit LogSetIsClosing(marketId, isClosing);
        }

        _setPriceOracle(state, marketId, priceOracle);
        _setInterestSetter(state, marketId, interestSetter);
        _setMarginPremium(state, marketId, marginPremium);
        _setSpreadPremium(state, marketId, spreadPremium);

        if (isRecyclable) {
            IRecyclable(token).initialize();
        }
    }

    function ownerRemoveMarkets(
        Storage.State storage state,
        uint[] memory marketIds,
        address salvager
    )
    public
    {
        for (uint i = 0; i < marketIds.length; i++) {
            address token = state.markets[marketIds[i]].token;
            Require.that(
                token != address(0),
                FILE,
                "market does not exist",
                marketIds[i]
            );
            Require.that(
                state.markets[marketIds[i]].isRecyclable,
                FILE,
                "market is not recyclable",
                marketIds[i]
            );
            Require.that(
                state.getTotalPar(marketIds[i]).borrow == 0,
                FILE,
                "market has active borrows",
                marketIds[i]
            );
            uint expirationTimestamp = IRecyclable(state.getToken(marketIds[i])).MAX_EXPIRATION_TIMESTAMP();
            Require.that(
                expirationTimestamp < block.timestamp,
                FILE,
                "market is not expired",
                marketIds[i],
                expirationTimestamp
            );
            Require.that(
                (expirationTimestamp + ONE_WEEK) < block.timestamp, // give the expiration timestamp a 7-day buffer
                FILE,
                "expiration must pass buffer",
                marketIds[i],
                expirationTimestamp
            );

            Token.transfer(token, salvager, state.getTotalPar(marketIds[i]).supply);

            delete state.markets[marketIds[i]];
            delete state.tokenToMarketId[token];

            uint previousHead = state.recycledMarketIds[HEAD_POINTER];
            state.recycledMarketIds[HEAD_POINTER] = marketIds[i];
            if (previousHead != 0) {
                // marketId=0 is not recyclable so we can assume previousHead == 0 means the null case
                state.recycledMarketIds[marketIds[i]] = previousHead;
            }

            IRecyclable(token).recycle();

            emit LogRemoveMarket(marketIds[i], token);
        }
    }

    function ownerSetIsClosing(
        Storage.State storage state,
        uint256 marketId,
        bool isClosing
    )
    public
    {
        _validateMarketId(state, marketId);
        state.markets[marketId].isClosing = isClosing;
        emit LogSetIsClosing(marketId, isClosing);
    }

    function ownerSetPriceOracle(
        Storage.State storage state,
        uint256 marketId,
        IPriceOracle priceOracle
    )
    public
    {
        _validateMarketId(state, marketId);
        _setPriceOracle(state, marketId, priceOracle);
    }

    function ownerSetInterestSetter(
        Storage.State storage state,
        uint256 marketId,
        IInterestSetter interestSetter
    )
    public
    {
        _validateMarketId(state, marketId);
        _setInterestSetter(state, marketId, interestSetter);
    }

    function ownerSetMarginPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory marginPremium
    )
    public
    {
        _validateMarketId(state, marketId);
        _setMarginPremium(state, marketId, marginPremium);
    }

    function ownerSetSpreadPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    )
    public
    {
        _validateMarketId(state, marketId);
        _setSpreadPremium(state, marketId, spreadPremium);
    }

    // ============ Risk Functions ============

    function ownerSetMarginRatio(
        Storage.State storage state,
        Decimal.D256 memory ratio
    )
    public
    {
        Require.that(
            ratio.value <= state.riskLimits.marginRatioMax,
            FILE,
            "Ratio too high"
        );
        Require.that(
            ratio.value > state.riskParams.liquidationSpread.value,
            FILE,
            "Ratio cannot be <= spread"
        );
        state.riskParams.marginRatio = ratio;
        emit LogSetMarginRatio(ratio);
    }

    function ownerSetLiquidationSpread(
        Storage.State storage state,
        Decimal.D256 memory spread
    )
    public
    {
        Require.that(
            spread.value <= state.riskLimits.liquidationSpreadMax,
            FILE,
            "Spread too high"
        );
        Require.that(
            spread.value < state.riskParams.marginRatio.value,
            FILE,
            "Spread cannot be >= ratio"
        );
        state.riskParams.liquidationSpread = spread;
        emit LogSetLiquidationSpread(spread);
    }

    function ownerSetEarningsRate(
        Storage.State storage state,
        Decimal.D256 memory earningsRate
    )
    public
    {
        Require.that(
            earningsRate.value <= state.riskLimits.earningsRateMax,
            FILE,
            "Rate too high"
        );
        state.riskParams.earningsRate = earningsRate;
        emit LogSetEarningsRate(earningsRate);
    }

    function ownerSetMinBorrowedValue(
        Storage.State storage state,
        Monetary.Value memory minBorrowedValue
    )
    public
    {
        Require.that(
            minBorrowedValue.value <= state.riskLimits.minBorrowedValueMax,
            FILE,
            "Value too high"
        );
        state.riskParams.minBorrowedValue = minBorrowedValue;
        emit LogSetMinBorrowedValue(minBorrowedValue);
    }

    // ============ Global Operator Functions ============

    function ownerSetGlobalOperator(
        Storage.State storage state,
        address operator,
        bool approved
    )
    public
    {
        state.globalOperators[operator] = approved;

        emit LogSetGlobalOperator(operator, approved);
    }

    // ============ Private Functions ============

    function _setPriceOracle(
        Storage.State storage state,
        uint256 marketId,
        IPriceOracle priceOracle
    )
    private
    {
        // require oracle can return non-zero price
        address token = state.markets[marketId].token;

        Require.that(
            priceOracle.getPrice(token).value != 0,
            FILE,
            "Invalid oracle price"
        );

        state.markets[marketId].priceOracle = priceOracle;

        emit LogSetPriceOracle(marketId, address(priceOracle));
    }

    function _setInterestSetter(
        Storage.State storage state,
        uint256 marketId,
        IInterestSetter interestSetter
    )
    private
    {
        // ensure interestSetter can return a value without reverting
        address token = state.markets[marketId].token;
        interestSetter.getInterestRate(token, 0, 0);

        state.markets[marketId].interestSetter = interestSetter;

        emit LogSetInterestSetter(marketId, address(interestSetter));
    }

    function _setMarginPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory marginPremium
    )
    private
    {
        Require.that(
            marginPremium.value <= state.riskLimits.marginPremiumMax,
            FILE,
            "Margin premium too high"
        );
        state.markets[marketId].marginPremium = marginPremium;

        emit LogSetMarginPremium(marketId, marginPremium);
    }

    function _setSpreadPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    )
    private
    {
        Require.that(
            spreadPremium.value <= state.riskLimits.spreadPremiumMax,
            FILE,
            "Spread premium too high"
        );
        state.markets[marketId].spreadPremium = spreadPremium;

        emit LogSetSpreadPremium(marketId, spreadPremium);
    }

    function _requireNoMarket(
        Storage.State storage state,
        address token
    )
    private
    view
    {
        // not-found case is marketId of 0. 0 is a valid market ID so we need to check market ID 0's token equality.
        uint marketId = state.tokenToMarketId[token];
        bool marketExists = token == state.markets[marketId].token;

        Require.that(
            !marketExists,
            FILE,
            "Market exists"
        );
    }

    function _validateMarketId(
        Storage.State storage state,
        uint256 marketId
    )
    private
    view
    {
        Require.that(
            marketId < state.numMarkets && state.markets[marketId].token != address(0),
            FILE,
            "Invalid market",
            marketId
        );
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Storage } from "./lib/Storage.sol";


/**
 * @title State
 * @author dYdX
 *
 * Base-level contract that holds the state of DolomiteMargin
 */
contract State
{
    Storage.State internal g_state;
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { State } from "./State.sol";
import { Types } from "./lib/Types.sol";


/**
 * @title Permission
 * @author dYdX
 *
 * Public function that allows other addresses to manage accounts
 */
contract Permission is
    State
{
    // ============ Events ============

    event LogOperatorSet(
        address indexed owner,
        address operator,
        bool trusted
    );

    // ============ Public Functions ============

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        Types.OperatorArg[] memory args
    )
        public
    {
        for (uint256 i = 0; i < args.length; i++) {
            address operator = args[i].operator;
            bool trusted = args[i].trusted;
            g_state.operators[msg.sender][operator] = trusted;
            emit LogOperatorSet(msg.sender, operator, trusted);
        }
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { State } from "./State.sol";
import { OperationImpl } from "./impl/OperationImpl.sol";
import { Account } from "./lib/Account.sol";
import { Actions } from "./lib/Actions.sol";


/**
 * @title Operation
 * @author dYdX
 *
 * Primary public function for allowing users and contracts to manage accounts within DolomiteMargin
 */
contract Operation is
    State,
    ReentrancyGuard
{
    // ============ Public Functions ============

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    )
        public
        nonReentrant
    {
        OperationImpl.operate(
            g_state,
            accounts,
            actions
        );
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { State } from "./State.sol";
import { IInterestSetter } from "./interfaces/IInterestSetter.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";
import { Account } from "./lib/Account.sol";
import { Cache } from "./lib/Cache.sol";
import { Decimal } from "./lib/Decimal.sol";
import { EnumerableSet } from "./lib/EnumerableSet.sol";
import { Interest } from "./lib/Interest.sol";
import { Monetary } from "./lib/Monetary.sol";
import { Require } from "./lib/Require.sol";
import { Storage } from "./lib/Storage.sol";
import { Token } from "./lib/Token.sol";
import { Types } from "./lib/Types.sol";


/**
 * @title Getters
 * @author dYdX
 *
 * Public read-only functions that allow transparency into the state of DolomiteMargin
 */
contract Getters is
    State
{
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Types for Types.Par;
    using EnumerableSet for EnumerableSet.Set;

    // ============ Constants ============

    bytes32 FILE = "Getters";

    // ============ Getters for Risk ============

    function getMarginRatio()
        public
        view
        returns (Decimal.D256 memory)
    {
        return g_state.riskParams.marginRatio;
    }

    function getLiquidationSpread()
        public
        view
        returns (Decimal.D256 memory)
    {
        return g_state.riskParams.liquidationSpread;
    }

    function getEarningsRate()
        public
        view
        returns (Decimal.D256 memory)
    {
        return g_state.riskParams.earningsRate;
    }

    function getMinBorrowedValue()
        public
        view
        returns (Monetary.Value memory)
    {
        return g_state.riskParams.minBorrowedValue;
    }

    function getRiskParams()
        public
        view
        returns (Storage.RiskParams memory)
    {
        return g_state.riskParams;
    }

    function getRiskLimits()
        public
        view
        returns (Storage.RiskLimits memory)
    {
        return g_state.riskLimits;
    }

    // ============ Getters for Markets ============

    function getNumMarkets()
        public
        view
        returns (uint256)
    {
        return g_state.numMarkets;
    }

    function getMarketTokenAddress(
        uint256 marketId
    )
        public
        view
        returns (address)
    {
        _requireValidMarket(marketId);
        return g_state.getToken(marketId);
    }

    function getMarketIdByTokenAddress(
        address token
    )
        public
        view
        returns (uint256)
    {
        _requireValidToken(token);
        return g_state.tokenToMarketId[token];
    }

    function getMarketTotalPar(
        uint256 marketId
    )
        public
        view
        returns (Types.TotalPar memory)
    {
        _requireValidMarket(marketId);
        return g_state.getTotalPar(marketId);
    }

    function getMarketCachedIndex(
        uint256 marketId
    )
        public
        view
        returns (Interest.Index memory)
    {
        _requireValidMarket(marketId);
        return g_state.getIndex(marketId);
    }

    function getMarketCurrentIndex(
        uint256 marketId
    )
        public
        view
        returns (Interest.Index memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchNewIndex(marketId, g_state.getIndex(marketId));
    }

    function getMarketPriceOracle(
        uint256 marketId
    )
        public
        view
        returns (IPriceOracle)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].priceOracle;
    }

    function getMarketInterestSetter(
        uint256 marketId
    )
        public
        view
        returns (IInterestSetter)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].interestSetter;
    }

    function getMarketMarginPremium(
        uint256 marketId
    )
        public
        view
        returns (Decimal.D256 memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].marginPremium;
    }

    function getMarketSpreadPremium(
        uint256 marketId
    )
        public
        view
        returns (Decimal.D256 memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].spreadPremium;
    }

    function getMarketIsClosing(
        uint256 marketId
    )
        public
        view
        returns (bool)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].isClosing;
    }

    function getMarketIsRecyclable(
        uint256 marketId
    )
        public
        view
        returns (bool)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].isRecyclable;
    }

    function getRecyclableMarkets(
        uint256 n
    )
        public
        view
        returns (uint[] memory)
    {
        uint counter = 0;
        uint[] memory markets = new uint[](n);
        uint pointer = g_state.recycledMarketIds[uint(-1)]; // uint(-1) is the HEAD_POINTER
        while (pointer != 0 && counter < n) {
            markets[counter++] = pointer;
            pointer = g_state.recycledMarketIds[pointer];
        }
        return markets;
    }

    function getMarketPrice(
        uint256 marketId
    )
        public
        view
        returns (Monetary.Price memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchPrice(marketId, g_state.getToken(marketId));
    }

    function getMarketInterestRate(
        uint256 marketId
    )
        public
        view
        returns (Interest.Rate memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchInterestRate(
            marketId,
            g_state.getIndex(marketId)
        );
    }

    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    )
        public
        view
        returns (Decimal.D256 memory)
    {
        _requireValidMarket(heldMarketId);
        _requireValidMarket(owedMarketId);
        return g_state.getLiquidationSpreadForPair(heldMarketId, owedMarketId);
    }

    function getMarket(
        uint256 marketId
    )
        public
        view
        returns (Storage.Market memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId];
    }

    function getMarketWithInfo(
        uint256 marketId
    )
        public
        view
        returns (
            Storage.Market memory,
            Interest.Index memory,
            Monetary.Price memory,
            Interest.Rate memory
        )
    {
        _requireValidMarket(marketId);
        return (
            getMarket(marketId),
            getMarketCurrentIndex(marketId),
            getMarketPrice(marketId),
            getMarketInterestRate(marketId)
        );
    }

    function getNumExcessTokens(
        uint256 marketId
    )
        public
        view
        returns (Types.Wei memory)
    {
        _requireValidMarket(marketId);
        return g_state.getNumExcessTokens(marketId);
    }

    function getAccountPar(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (Types.Par memory)
    {
        _requireValidMarket(marketId);
        return g_state.getPar(account, marketId);
    }

    function getAccountParNoMarketCheck(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (Types.Par memory)
    {
        return g_state.getPar(account, marketId);
    }

    function getAccountWei(
        Account.Info memory account,
        uint256 marketId
    )
        public
        view
        returns (Types.Wei memory)
    {
        _requireValidMarket(marketId);
        return Interest.parToWei(
            g_state.getPar(account, marketId),
            g_state.fetchNewIndex(marketId, g_state.getIndex(marketId))
        );
    }

    function getAccountStatus(
        Account.Info memory account
    )
        public
        view
        returns (Account.Status)
    {
        return g_state.getStatus(account);
    }

    function getAccountMarketsWithNonZeroBalances(
        Account.Info memory account
    )
        public
        view
        returns (uint256[] memory)
    {
        return g_state.getMarketsWithBalances(account);
    }

    function getNumberOfMarketsWithBorrow(
        Account.Info memory account
    )
        public
        view
        returns (uint256)
    {
        return g_state.getNumberOfMarketsWithBorrow(account);
    }

    function getAccountValues(
        Account.Info memory account
    )
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        return _getAccountValuesInternal(account, /* adjustForLiquidity = */ false);
    }

    function getAdjustedAccountValues(
        Account.Info memory account
    )
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        return _getAccountValuesInternal(account, /* adjustForLiquidity = */ true);
    }

    function getAccountBalances(
        Account.Info memory account
    )
        public
        view
        returns (
            uint[] memory,
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        )
    {
        uint256[] memory markets = g_state.getMarketsWithBalances(account);
        address[] memory tokens = new address[](markets.length);
        Types.Par[] memory pars = new Types.Par[](markets.length);
        Types.Wei[] memory weis = new Types.Wei[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            tokens[i] = getMarketTokenAddress(markets[i]);
            pars[i] = getAccountPar(account, markets[i]);
            weis[i] = getAccountWei(account, markets[i]);
        }

        return (
            markets,
            tokens,
            pars,
            weis
        );
    }

    function getIsLocalOperator(
        address owner,
        address operator
    )
        public
        view
        returns (bool)
    {
        return g_state.isLocalOperator(owner, operator);
    }

    function getIsGlobalOperator(
        address operator
    )
        public
        view
        returns (bool)
    {
        return g_state.isGlobalOperator(operator);
    }

    // ============ Internal/Private Helper Functions ============

    /**
     * Revert if marketId is invalid.
     */
    function _requireValidMarket(
        uint256 marketId
    )
        internal
        view
    {
        Require.that(
            marketId < g_state.numMarkets && g_state.markets[marketId].token != address(0),
            FILE,
            "Invalid market"
        );
    }

    function _requireValidToken(
        address token
    )
        private
        view
    {
        Require.that(
            token == g_state.markets[g_state.tokenToMarketId[token]].token,
            FILE,
            "Invalid token"
        );
    }

    /**
     * Private helper for getting the monetary values of an account.
     */
    function _getAccountValuesInternal(
        Account.Info memory account,
        bool adjustForLiquidity
    )
        private
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        uint256[] memory markets = g_state.getMarketsWithBalances(account);

        // populate cache
        Cache.MarketCache memory cache = Cache.create(markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            cache.set(markets[i]);
        }
        g_state.initializeCache(cache);

        return g_state.getAccountValues(account, cache, adjustForLiquidity);
    }
}

/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import { Ownable } from "@openzeppelin/contracts/ownership/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { State } from "./State.sol";
import { AdminImpl } from "./impl/AdminImpl.sol";
import { IInterestSetter } from "./interfaces/IInterestSetter.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";
import { Decimal } from "./lib/Decimal.sol";
import { Interest } from "./lib/Interest.sol";
import { Monetary } from "./lib/Monetary.sol";
import { Token } from "./lib/Token.sol";


/**
 * @title Admin
 * @author dYdX
 *
 * Public functions that allow the privileged owner address to manage DolomiteMargin
 */
contract Admin is
    State,
    Ownable,
    ReentrancyGuard
{
    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be
     * withdrawn. The number of excess tokens is calculated by taking the current number of tokens
     * held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and subtracting the
     * number of tokens owed to suppliers by DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return AdminImpl.ownerWithdrawExcessTokens(
            g_state,
            marketId,
            recipient
        );
    }

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return AdminImpl.ownerWithdrawUnsupportedTokens(
            g_state,
            token,
            recipient
        );
    }

    // ============ Market Functions ============

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IPriceOracle priceOracle,
        IInterestSetter interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium,
        bool isClosing,
        bool isRecyclable
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerAddMarket(
            g_state,
            token,
            priceOracle,
            interestSetter,
            marginPremium,
            spreadPremium,
            isClosing,
            isRecyclable
        );
    }

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the recyclable
     * callback
     */
    function ownerRemoveMarkets(
        uint[] memory marketIds,
        address salvager
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerRemoveMarkets(
            g_state,
            marketIds,
            salvager
        );
    }

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot
     * increase while its status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetIsClosing(
            g_state,
            marketId,
            isClosing
        );
    }

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IPriceOracle priceOracle
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetPriceOracle(
            g_state,
            marketId,
            priceOracle
        );
    }

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IInterestSetter interestSetter
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetInterestSetter(
            g_state,
            marketId,
            interestSetter
        );
    }

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions
     * that include this market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetMarginPremium(
            g_state,
            marketId,
            marginPremium
        );
    }

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations
     * that include this market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetSpreadPremium(
            g_state,
            marketId,
            spreadPremium
        );
    }

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     */
    function ownerSetMarginRatio(
        Decimal.D256 memory ratio
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetMarginRatio(
            g_state,
            ratio
        );
    }

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal.D256 memory spread
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetLiquidationSpread(
            g_state,
            spread
        );
    }

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal.D256 memory earningsRate
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetEarningsRate(
            g_state,
            earningsRate
        );
    }

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        Monetary.Value memory minBorrowedValue
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetMinBorrowedValue(
            g_state,
            minBorrowedValue
        );
    }

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in
     * DolomiteMargin. Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetGlobalOperator(
            g_state,
            operator,
            approved
        );
    }
}