// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Admin.sol";
import "./Getters.sol";
import "./Operation.sol";
import "./Permission.sol";
import "./State.sol";
import "./lib/Storage.sol";

/**
 * Main contract that inherits from other contracts
 */

contract DxlnMargin is State, Admin, Getters, Operation, Permission {
    // ============ Constructor ============

    constructor(
        Storage.RiskParams memory riskParams,
        Storage.RiskLimits memory riskLimits
    ) {
        g_state.riskParams = riskParams;
        g_state.riskLimits = riskLimits;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "./SafeMath.sol";

// import "../lib/Require.sol";

/**
 * Library for non-standard Math functions
 */
library Math {
    using SafeMath for uint256;

    // ============ Constants ============

    //  bytes32 constant FILE = "Math";

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    /*
     * Return target * (numerator / denominator), but rounded up.
     */
    function getPartialRoundUp(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        if (target == 0 || numerator == 0) {
            // SafeMath will check for zero denominator
            return SafeMath.div(0, denominator);
        }
        return target.mul(numerator).sub(1).div(denominator).add(1);
    }

    function to128(uint256 number) internal pure returns (uint128) {
        uint128 result = uint128(number);
        require(result == number, "Unsafe cast to uint128");
        return result;
    }

    function to96(uint256 number) internal pure returns (uint96) {
        uint96 result = uint96(number);
        require(result == number, "Unsafe cast to uint96");
        return result;
    }

    function to32(uint256 number) internal pure returns (uint32) {
        uint32 result = uint32(number);
        require(result == number, "Unsafe cast to uint32");
        return result;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Math.sol";
import "../utils/SafeMath.sol";

/**
 * Library for interacting with the basic structs used in DxlnMargin
 */

library Types {
    using Math for uint256;

    // ============ AssetAmount ============

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par // the amount is denominated in par
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

    function zeroPar() internal pure returns (Par memory) {
        return Par({sign: false, value: 0});
    }

    function sub(Par memory a, Par memory b)
        internal
        pure
        returns (Par memory)
    {
        return add(a, negative(b));
    }

    function add(Par memory a, Par memory b)
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

    function equals(Par memory a, Par memory b) internal pure returns (bool) {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(Par memory a) internal pure returns (Par memory) {
        return Par({sign: !a.sign, value: a.value});
    }

    function isNegative(Par memory a) internal pure returns (bool) {
        return !a.sign && a.value > 0;
    }

    function isPositive(Par memory a) internal pure returns (bool) {
        return a.sign && a.value > 0;
    }

    function isZero(Par memory a) internal pure returns (bool) {
        return a.value == 0;
    }

    // ============ Wei (Token Amount) ============

    // Individual token amount for an account
    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    function zeroWei() internal pure returns (Wei memory) {
        return Wei({sign: false, value: 0});
    }

    function sub(Wei memory a, Wei memory b)
        internal
        pure
        returns (Wei memory)
    {
        return add(a, negative(b));
    }

    function add(Wei memory a, Wei memory b)
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

    function equals(Wei memory a, Wei memory b) internal pure returns (bool) {
        if (a.value == b.value) {
            if (a.value == 0) {
                return true;
            }
            return a.sign == b.sign;
        }
        return false;
    }

    function negative(Wei memory a) internal pure returns (Wei memory) {
        return Wei({sign: !a.sign, value: a.value});
    }

    function isNegative(Wei memory a) internal pure returns (bool) {
        return !a.sign && a.value > 0;
    }

    function isPositive(Wei memory a) internal pure returns (bool) {
        return a.sign && a.value > 0;
    }

    function isZero(Wei memory a) internal pure returns (bool) {
        return a.value == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../intf/IErc20.sol";
import "../lib/Require.sol";

/**
 * This library contains basic functions for interacting with ERC20 tokens. Modified to work with
 * tokens that don't adhere strictly to the ERC20 standard (for example tokens that don't return a
 * boolean value on success).
 */
library Token {
    // ============ Constants ============

    // bytes32 constant FILE = "Token";

    // ============ Library Functions ============

    function balanceOf(address token, address owner)
        internal
        view
        returns (uint256)
    {
        return IErc20(token).balanceOf(owner);
    }

    function allowance(
        address token,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IErc20(token).allowance(owner, spender);
    }

    function approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IErc20(token).approve(spender, amount);

        require(checkSuccess(), "Approve failed");
    }

    function approveMax(address token, address spender) internal {
        approve(token, spender, type(uint256).max);
    }

    function transfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || to == address(this)) {
            return;
        }

        IErc20(token).transfer(to, amount);

        require(checkSuccess(), "Transfer failed");
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0 || to == from) {
            return;
        }

        IErc20(token).transferFrom(from, to, amount);

        require(checkSuccess(), "TransferFrom failed");
    }

    // ============ Private Functions ============

    /**
     * Check the return value of the previous function up to 32 bytes. Return true if the previous
     * function returned 0 bytes or 32 bytes that are not all-zero.
     */
    function checkSuccess() private pure returns (bool) {
        uint256 returnValue = 0;

        /* solium-disable-next-line security/no-inline-assembly */
        assembly {
            // check number of bytes returned from last function call
            switch returndatasize()
            // no bytes returned: assume success
            case 0x0 {
                returnValue := 1
            }
            // 32 bytes returned: check if non-zero
            case 0x20 {
                // copy 32 bytes into scratch space
                returndatacopy(0x0, 0x0, 0x20)

                // load those bytes into returnValue
                returnValue := mload(0x0)
            }
            // not sure what was returned: don't mark as success
            default {

            }
        }

        return returnValue != 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Math.sol";

/**
 * Library for dealing with time, assuming timestamps fit within 32 bits (valid until year 2106)
 */

library Time {
    // ============ Library Functions ============

    function currentTime() internal view returns (uint32) {
        return Math.to32(block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "../utils/Math.sol";
// import "../lib/Require.sol";
import "../lib/Cache.sol";
import "./Time.sol";
import "./Token.sol";
import "../lib/Storage.sol";
import "../lib/Types.sol";
import "./Interest.sol";
import "./Account.sol";
import "./Monetary.sol";
import "../lib/Decimal.sol";
import "../intf/IPriceOracle.sol";
import "../intf/IInterestSetter.sol";

/**
 * Functions for reading, writing, and verifying state in DxlnMargin
 */
library Storage {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Math for uint256;
    using Types for Types.Par;
    using Types for Types.Wei;
    using SafeMath for uint256;

    // ============ Constants ============

    // bytes32 constant FILE = "Storage";

    // ============ Structs ============

    // All information necessary for tracking a market
    struct Market {
        // Contract address of the associated ERC20 token
        address token;
        // Total aggregated supply and borrow amount of the entire market
        Types.TotalPar totalPar;
        // Interest index of the market
        Interest.Index index;
        // Contract address of the price oracle for this market
        IPriceOracle priceOracle;
        // Contract address of the interest setter for this market
        IInterestSetter interestSetter;
        // Multiplier on the marginRatio for this market
        Decimal.D256 marginPremium;
        // Multiplier on the liquidationSpread for this market
        Decimal.D256 spreadPremium;
        // Whether additional borrows are allowed for this market
        bool isClosing;
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
        uint64 marginRatioMax;
        uint64 liquidationSpreadMax;
        uint64 earningsRateMax;
        uint64 marginPremiumMax;
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    // The entire storage state of DxlnMargin
    struct State {
        // number of markets
        uint256 numMarkets;
        // marketId => Market
        mapping(uint256 => Market) markets;
        // owner => account number => Account
        mapping(address => mapping(uint256 => Account.Storage)) accounts;
        // Addresses that can control other users accounts
        mapping(address => mapping(address => bool)) operators;
        // Addresses that can control all users accounts
        mapping(address => bool) globalOperators;
        // mutable risk parameters of the system
        RiskParams riskParams;
        // immutable risk limits of the system
        RiskLimits riskLimits;
    }

    // ============ Functions ============

    function getToken(Storage.State storage state, uint256 marketId)
        internal
        view
        returns (address)
    {
        return state.markets[marketId].token;
    }

    function getTotalPar(Storage.State storage state, uint256 marketId)
        internal
        view
        returns (Types.TotalPar memory)
    {
        return state.markets[marketId].totalPar;
    }

    function getIndex(Storage.State storage state, uint256 marketId)
        internal
        view
        returns (Interest.Index memory)
    {
        return state.markets[marketId].index;
    }

    function getNumExcessTokens(Storage.State storage state, uint256 marketId)
        internal
        view
        returns (Types.Wei memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        address token = state.getToken(marketId);

        Types.Wei memory balanceWei = Types.Wei({
            sign: true,
            value: Token.balanceOf(token, address(this))
        });

        (Types.Wei memory supplyWei, Types.Wei memory borrowWei) = Interest
            .totalParToWei(totalPar, index);

        // borrowWei is negative, so subtracting it makes the value more positive
        return balanceWei.sub(borrowWei).sub(supplyWei);
    }

    function getStatus(Storage.State storage state, Account.Info memory account)
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
    ) internal view returns (Types.Par memory) {
        return state.accounts[account.owner][account.number].balances[marketId];
    }

    function getWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId
    ) internal view returns (Types.Wei memory) {
        Types.Par memory par = state.getPar(account, marketId);

        if (par.isZero()) {
            return Types.zeroWei();
        }

        Interest.Index memory index = state.getIndex(marketId);
        return Interest.parToWei(par, index);
    }

    function getLiquidationSpreadForPair(
        Storage.State storage state,
        uint256 heldMarketId,
        uint256 owedMarketId
    ) internal view returns (Decimal.D256 memory) {
        uint256 result = state.riskParams.liquidationSpread.value;
        result = Decimal.mul(
            result,
            Decimal.onePlus(state.markets[heldMarketId].spreadPremium)
        );
        result = Decimal.mul(
            result,
            Decimal.onePlus(state.markets[owedMarketId].spreadPremium)
        );
        return Decimal.D256({value: result});
    }

    function fetchNewIndex(
        Storage.State storage state,
        uint256 marketId,
        Interest.Index memory index
    ) internal view returns (Interest.Index memory) {
        Interest.Rate memory rate = state.fetchInterestRate(marketId, index);

        return
            Interest.calculateNewIndex(
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
    ) internal view returns (Interest.Rate memory) {
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);
        (Types.Wei memory supplyWei, Types.Wei memory borrowWei) = Interest
            .totalParToWei(totalPar, index);

        Interest.Rate memory rate = state
            .markets[marketId]
            .interestSetter
            .getInterestRate(
                state.getToken(marketId),
                borrowWei.value,
                supplyWei.value
            );

        return rate;
    }

    function fetchPrice(Storage.State storage state, uint256 marketId)
        internal
        view
        returns (Monetary.Price memory)
    {
        IPriceOracle oracle = IPriceOracle(state.markets[marketId].priceOracle);
        Monetary.Price memory price = oracle.getPrice(state.getToken(marketId));
        require(price.value != 0,"Price cannot be zero");
        return price;
    }

    function getAccountValues(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool adjustForLiquidity
    ) internal view returns (Monetary.Value memory, Monetary.Value memory) {
        Monetary.Value memory supplyValue;
        Monetary.Value memory borrowValue;

        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 m = 0; m < numMarkets; m++) {
            if (!cache.hasMarket(m)) {
                continue;
            }

            Types.Wei memory userWei = state.getWei(account, m);

            if (userWei.isZero()) {
                continue;
            }

            uint256 assetValue = userWei.value.mul(cache.getPrice(m).value);
            Decimal.D256 memory adjust = Decimal.one();
            if (adjustForLiquidity) {
                adjust = Decimal.onePlus(state.markets[m].marginPremium);
            }

            if (userWei.sign) {
                supplyValue.value = supplyValue.value.add(
                    Decimal.div(assetValue, adjust)
                );
            } else {
                borrowValue.value = borrowValue.value.add(
                    Decimal.mul(assetValue, adjust)
                );
            }
        }

        return (supplyValue, borrowValue);
    }

    function isCollateralized(
        Storage.State storage state,
        Account.Info memory account,
        Cache.MarketCache memory cache,
        bool requireMinBorrow
    ) internal view returns (bool) {
        // get account values (adjusted for liquidity)
        (Monetary.Value memory supplyValue, Monetary.Value memory borrowValue) = state
            .getAccountValues(
                account,
                cache,
                /* adjustForLiquidity = */
                true
            );

        if (borrowValue.value == 0) {
            return true;
        }

        if (requireMinBorrow) {
            require(
                borrowValue.value >= state.riskParams.minBorrowedValue.value,
                "Borrow value too low"
            );
        }

        uint256 requiredMargin = Decimal.mul(
            borrowValue.value,
            state.riskParams.marginRatio
        );

        return supplyValue.value >= borrowValue.value.add(requiredMargin);
    }

    function isGlobalOperator(Storage.State storage state, address operator)
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
    ) internal view returns (bool) {
        return state.operators[owner][operator];
    }

    function requireIsOperator(
        Storage.State storage state,
        Account.Info memory account,
        address operator
    ) internal view {
        bool isValidOperator = operator == account.owner ||
            state.isGlobalOperator(operator) ||
            state.isLocalOperator(account.owner, operator);

        require(
            isValidOperator,
            "Unpermissioned operator"
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
    ) internal view returns (Types.Par memory, Types.Wei memory) {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (amount.value == 0 && amount.ref == Types.AssetReference.Delta) {
            return (oldPar, Types.zeroWei());
        }

        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = Interest.parToWei(oldPar, index);
        Types.Par memory newPar;
        Types.Wei memory deltaWei;

        if (amount.denomination == Types.AssetDenomination.Wei) {
            deltaWei = Types.Wei({sign: amount.sign, value: amount.value});
            if (amount.ref == Types.AssetReference.Target) {
                deltaWei = deltaWei.sub(oldWei);
            }
            newPar = Interest.weiToPar(oldWei.add(deltaWei), index);
        } else {
            // AssetDenomination.Par
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
    ) internal view returns (Types.Par memory, Types.Wei memory) {
        Types.Par memory oldPar = state.getPar(account, marketId);

        require(
            !oldPar.isPositive(),
            "Owed balance cannot be positive"
        );

        (Types.Par memory newPar, Types.Wei memory deltaWei) = state
            .getNewParAndDeltaWei(account, marketId, amount);

        // if attempting to over-repay the owed asset, bound it by the maximum
        if (newPar.isPositive()) {
            newPar = Types.zeroPar();
            deltaWei = state.getWei(account, marketId).negative();
        }

        require(
            !deltaWei.isNegative() && oldPar.value >= newPar.value,
            "Owed balance cannot increase"
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
    ) internal view returns (bool) {
        bool hasNegative = false;
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 m = 0; m < numMarkets; m++) {
            if (!cache.hasMarket(m)) {
                continue;
            }
            Types.Par memory par = state.getPar(account, m);
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

    function updateIndex(Storage.State storage state, uint256 marketId)
        internal
        returns (Interest.Index memory)
    {
        Interest.Index memory index = state.getIndex(marketId);
        if (index.lastUpdate == Time.currentTime()) {
            return index;
        }
        return
            state.markets[marketId].index = state.fetchNewIndex(
                marketId,
                index
            );
    }

    function setStatus(
        Storage.State storage state,
        Account.Info memory account,
        Account.Status status
    ) internal {
        state.accounts[account.owner][account.number].status = status;
    }

    function setPar(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Par memory newPar
    ) internal {
        Types.Par memory oldPar = state.getPar(account, marketId);

        if (Types.equals(oldPar, newPar)) {
            return;
        }

        // updateTotalPar
        Types.TotalPar memory totalPar = state.getTotalPar(marketId);

        // roll-back oldPar
        if (oldPar.sign) {
            totalPar.supply = uint256(totalPar.supply)
                .sub(oldPar.value)
                .to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow)
                .sub(oldPar.value)
                .to128();
        }

        // roll-forward newPar
        if (newPar.sign) {
            totalPar.supply = uint256(totalPar.supply)
                .add(newPar.value)
                .to128();
        } else {
            totalPar.borrow = uint256(totalPar.borrow)
                .add(newPar.value)
                .to128();
        }

        state.markets[marketId].totalPar = totalPar;
        state.accounts[account.owner][account.number].balances[
            marketId
        ] = newPar;
    }

    /**
     * Determine and set an account's balance based on a change in wei
     */
    function setParFromDeltaWei(
        Storage.State storage state,
        Account.Info memory account,
        uint256 marketId,
        Types.Wei memory deltaWei
    ) internal {
        if (deltaWei.isZero()) {
            return;
        }
        Interest.Index memory index = state.getIndex(marketId);
        Types.Wei memory oldWei = state.getWei(account, marketId);
        Types.Wei memory newWei = oldWei.add(deltaWei);
        Types.Par memory newPar = Interest.weiToPar(newWei, index);
        state.setPar(account, marketId, newPar);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

// /**
//  * Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
//  */

// library Require {
//     // ============ Constants ============

//     uint256 constant ASCII_ZERO = 48; // '0'
//     uint256 constant ASCII_RELATIVE_ZERO = 87; // 'a' - 10
//     uint256 constant ASCII_LOWER_EX = 120; // 'x'
//     bytes2 constant COLON = 0x3a20; // ': '
//     bytes2 constant COMMA = 0x2c20; // ', '
//     bytes2 constant LPAREN = 0x203c; // ' <'
//     bytes1 constant RPAREN = 0x3e; // '>'
//     uint256 constant FOUR_BIT_MASK = 0xf;

//     // ============ Library Functions ============

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(stringify(file), COLON, stringify(reason))
//                 )
//             );
//         }
//     }

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason,
//         uint256 payloadA
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(
//                         stringify(file),
//                         COLON,
//                         stringify(reason),
//                         LPAREN,
//                         stringify(payloadA),
//                         RPAREN
//                     )
//                 )
//             );
//         }
//     }

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason,
//         uint256 payloadA,
//         uint256 payloadB
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(
//                         stringify(file),
//                         COLON,
//                         stringify(reason),
//                         LPAREN,
//                         stringify(payloadA),
//                         COMMA,
//                         stringify(payloadB),
//                         RPAREN
//                     )
//                 )
//             );
//         }
//     }

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason,
//         address payloadA
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(
//                         stringify(file),
//                         COLON,
//                         stringify(reason),
//                         LPAREN,
//                         stringify(payloadA),
//                         RPAREN
//                     )
//                 )
//             );
//         }
//     }

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason,
//         address payloadA,
//         uint256 payloadB
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(
//                         stringify(file),
//                         COLON,
//                         stringify(reason),
//                         LPAREN,
//                         stringify(payloadA),
//                         COMMA,
//                         stringify(payloadB),
//                         RPAREN
//                     )
//                 )
//             );
//         }
//     }

//     function that(
//         bool must,
//         bytes32 file,
//         bytes32 reason,
//         address payloadA,
//         uint256 payloadB,
//         uint256 payloadC
//     ) internal pure {
//         if (!must) {
//             revert(
//                 string(
//                     abi.encodePacked(
//                         stringify(file),
//                         COLON,
//                         stringify(reason),
//                         LPAREN,
//                         stringify(payloadA),
//                         COMMA,
//                         stringify(payloadB),
//                         COMMA,
//                         stringify(payloadC),
//                         RPAREN
//                     )
//                 )
//             );
//         }
//     }

//     // ============ Private Functions ============

//     function stringify(bytes32 input) private pure returns (bytes memory) {
//         // put the input bytes into the result
//         bytes memory result = abi.encodePacked(input);

//         // determine the length of the input by finding the location of the last non-zero byte
//         for (uint256 i = 32; i > 0; ) {
//             // reverse-for-loops with unsigned integer
//             /* solium-disable-next-line security/no-modify-for-iter-var */
//             i--;

//             // find the last non-zero byte in order to determine the length
//             if (result[i] != 0) {
//                 uint256 length = i + 1;

//                 /* solium-disable-next-line security/no-inline-assembly */
//                 assembly {
//                     mstore(result, length) // r.length = length;
//                 }

//                 return result;
//             }
//         }

//         // all bytes are zero
//         return new bytes(0);
//     }

//     function stringify(uint256 input) private pure returns (bytes memory) {
//         if (input == 0) {
//             return "0";
//         }

//         // get the final string length
//         uint256 j = input;
//         uint256 length;
//         while (j != 0) {
//             length++;
//             j /= 10;
//         }

//         // allocate the string
//         bytes memory bstr = new bytes(length);

//         // populate the string starting with the least-significant character
//         j = input;
//         for (uint256 i = length; i > 0; ) {
//             // reverse-for-loops with unsigned integer
//             /* solium-disable-next-line security/no-modify-for-iter-var */
//             i--;

//             // take last decimal digit
//             bstr[i] = bytes1(uint8(ASCII_ZERO + (j % 10)));

//             // remove the last decimal digit
//             j /= 10;
//         }

//         return bstr;
//     }

//     function stringify(address input) private pure returns (bytes memory) {
//         uint256 z = uint256(uint160(address(input)));

//         // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
//         bytes memory result = new bytes(42);

//         // populate the result with "0x"
//         result[0] = bytes1(uint8(ASCII_ZERO));
//         result[1] = bytes1(uint8(ASCII_LOWER_EX));

//         // for each byte (starting from the lowest byte), populate the result with two characters
//         for (uint256 i = 0; i < 20; i++) {
//             // each byte takes two characters
//             uint256 shift = i * 2;

//             // populate the least-significant character
//             result[41 - shift] = char(z & FOUR_BIT_MASK);
//             z = z >> 4;

//             // populate the most-significant character
//             result[40 - shift] = char(z & FOUR_BIT_MASK);
//             z = z >> 4;
//         }

//         return result;
//     }

//     function char(uint256 input) private pure returns (bytes1) {
//         // return ASCII digit (0-9)
//         if (input < 10) {
//             return bytes1(uint8(input + ASCII_ZERO));
//         }

//         // return ASCII letter (a-f)
//         return bytes1(uint8(input + ASCII_RELATIVE_ZERO));
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * Library for types involving money
 */

library Monetary {
    /*
     * The price of a base-unit of an asset.
     */
    struct Price {
        uint256 value;
    }

    /*
     * Total value of an some amount of an asset. Equal to (price * amount).
     */
    struct Value {
        uint256 value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/Math.sol";
import "../utils/SafeMath.sol";
import "./Types.sol";
import "./Decimal.sol";
import "./Time.sol";

/**
 * Library for managing the interest rate and interest indexes of DxlnMargin
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
     * then prorated the across all suppliers.
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
    ) internal view returns (Index memory) {
        (
            Types.Wei memory supplyWei,
            Types.Wei memory borrowWei
        ) = totalParToWei(totalPar, index);

        // get interest increase for borrowers
        uint32 currentTime = Time.currentTime();
        uint256 borrowInterest = rate.value.mul(
            uint256(currentTime).sub(index.lastUpdate)
        );

        // get interest increase for suppliers
        uint256 supplyInterest;
        if (Types.isZero(supplyWei)) {
            supplyInterest = 0;
        } else {
            supplyInterest = Decimal.mul(borrowInterest, earningsRate);
            if (borrowWei.value < supplyWei.value) {
                supplyInterest = Math.getPartial(
                    supplyInterest,
                    borrowWei.value,
                    supplyWei.value
                );
            }
        }
        assert(supplyInterest <= borrowInterest);

        return
            Index({
                borrow: Math
                    .getPartial(index.borrow, borrowInterest, BASE)
                    .add(index.borrow)
                    .to96(),
                supply: Math
                    .getPartial(index.supply, supplyInterest, BASE)
                    .add(index.supply)
                    .to96(),
                lastUpdate: currentTime
            });
    }

    function newIndex() internal view returns (Index memory) {
        return
            Index({borrow: BASE, supply: BASE, lastUpdate: Time.currentTime()});
    }

    /*
     * Convert a principal amount to a token amount given an index.
     */
    function parToWei(Types.Par memory input, Index memory index)
        internal
        pure
        returns (Types.Wei memory)
    {
        uint256 inputValue = uint256(input.value);
        if (input.sign) {
            return
                Types.Wei({
                    sign: true,
                    value: inputValue.getPartial(index.supply, BASE)
                });
        } else {
            return
                Types.Wei({
                    sign: false,
                    value: inputValue.getPartialRoundUp(index.borrow, BASE)
                });
        }
    }

    /*
     * Convert a token amount to a principal amount given an index.
     */
    function weiToPar(Types.Wei memory input, Index memory index)
        internal
        pure
        returns (Types.Par memory)
    {
        if (input.sign) {
            return
                Types.Par({
                    sign: true,
                    value: input.value.getPartial(BASE, index.supply).to128()
                });
        } else {
            return
                Types.Par({
                    sign: false,
                    value: input
                        .value
                        .getPartialRoundUp(BASE, index.borrow)
                        .to128()
                });
        }
    }

    /*
     * Convert the total supply and borrow principal amounts of a market to total supply and borrow
     * token amounts.
     */
    function totalParToWei(Types.TotalPar memory totalPar, Index memory index)
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

// import "../lib/Require.sol";
import "./Token.sol";
import "./Types.sol";
import "../intf/IExchangeWrapper.sol";

/**
 * Library for transferring tokens and interacting with ExchangeWrappers by using the Wei struct
 */

library Exchange {
    using Types for Types.Wei;

    // ============ Constants ============

    // bytes32 constant FILE = "Exchange";

    // ============ Library Functions ============

    function transferOut(
        address token,
        address to,
        Types.Wei memory deltaWei
    ) internal {
        require(!deltaWei.isPositive(), "Cannot transferOut positive");

        Token.transfer(token, to, deltaWei.value);
    }

    function transferIn(
        address token,
        address from,
        Types.Wei memory deltaWei
    ) internal {
        require(!deltaWei.isNegative(), "Cannot transferIn negative");

        Token.transferFrom(token, from, address(this), deltaWei.value);
    }

    function getCost(
        address exchangeWrapper,
        address supplyToken,
        address borrowToken,
        Types.Wei memory desiredAmount,
        bytes memory orderData
    ) internal view returns (Types.Wei memory) {
        require(!desiredAmount.isNegative(), "Cannot getCost negative");

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
    ) internal returns (Types.Wei memory) {
        require(!requestedFillAmount.isPositive(), "Cannot exchange positive");

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Account.sol";
import "./Actions.sol";
import "./Interest.sol";
import "./Storage.sol";
import "./Types.sol";

/**
 * Library to parse and emit logs from which the state of all accounts and indexes can be followed
 */
 
library Events {
    using Types for Types.Wei;
    using Storage for Storage.State;

    // ============ Events ============

    event LogIndexUpdate(uint256 indexed market, Interest.Index index);

    event LogOperation(address sender);

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

    function logIndexUpdate(uint256 marketId, Interest.Index memory index)
        internal
    {
        emit LogIndexUpdate(marketId, index);
    }

    function logOperation() internal {
        emit LogOperation(msg.sender);
    }

    function logDeposit(
        Storage.State storage state,
        Actions.DepositArgs memory args,
        Types.Wei memory deltaWei
    ) internal {
        emit LogDeposit(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(state, args.account, args.market, deltaWei),
            args.from
        );
    }

    function logWithdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args,
        Types.Wei memory deltaWei
    ) internal {
        emit LogWithdraw(
            args.account.owner,
            args.account.number,
            args.market,
            getBalanceUpdate(state, args.account, args.market, deltaWei),
            args.to
        );
    }

    function logTransfer(
        Storage.State storage state,
        Actions.TransferArgs memory args,
        Types.Wei memory deltaWei
    ) internal {
        emit LogTransfer(
            args.accountOne.owner,
            args.accountOne.number,
            args.accountTwo.owner,
            args.accountTwo.number,
            args.market,
            getBalanceUpdate(state, args.accountOne, args.market, deltaWei),
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
    ) internal {
        emit LogBuy(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(state, args.account, args.takerMarket, takerWei),
            getBalanceUpdate(state, args.account, args.makerMarket, makerWei),
            args.exchangeWrapper
        );
    }

    function logSell(
        Storage.State storage state,
        Actions.SellArgs memory args,
        Types.Wei memory takerWei,
        Types.Wei memory makerWei
    ) internal {
        emit LogSell(
            args.account.owner,
            args.account.number,
            args.takerMarket,
            args.makerMarket,
            getBalanceUpdate(state, args.account, args.takerMarket, takerWei),
            getBalanceUpdate(state, args.account, args.makerMarket, makerWei),
            args.exchangeWrapper
        );
    }

    function logTrade(
        Storage.State storage state,
        Actions.TradeArgs memory args,
        Types.Wei memory inputWei,
        Types.Wei memory outputWei
    ) internal {
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

        emit LogTrade(
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

    function logCall(Actions.CallArgs memory args) internal {
        emit LogCall(args.account.owner, args.account.number, args.callee);
    }

    function logLiquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Types.Wei memory heldWei,
        Types.Wei memory owedWei
    ) internal {
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
    ) internal {
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
    ) private view returns (BalanceUpdate memory) {
        return
            BalanceUpdate({
                deltaWei: deltaWei,
                newPar: state.getPar(account, market)
            });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "../utils/Math.sol";

/**
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

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function onePlus(D256 memory d) internal pure returns (D256 memory) {
        return D256({value: d.value.add(BASE)});
    }

    function mul(uint256 target, D256 memory d)
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function div(uint256 target, D256 memory d)
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "./Storage.sol";
import "./Monetary.sol";

/**
 * Library for caching information about markets
 */
library Cache {
    using Cache for MarketCache;
    using Storage for Storage.State;

    // ============ Structs ============

    struct MarketInfo {
        bool isClosing;
        uint128 borrowPar;
        Monetary.Price price;
    }

    struct MarketCache {
        MarketInfo[] markets;
    }

    // ============ Setter Functions ============

    /**
     * Initialize an empty cache for some given number of total markets.
     */
    function create(uint256 numMarkets)
        internal
        pure
        returns (MarketCache memory)
    {
        return MarketCache({markets: new MarketInfo[](numMarkets)});
    }

    /**
     * Add market information (price and total borrowed par if the market is closing) to the cache.
     * Return true if the market information did not previously exist in the cache.
     */
    function addMarket(
        MarketCache memory cache,
        Storage.State storage state,
        uint256 marketId
    ) internal view returns (bool) {
        if (cache.hasMarket(marketId)) {
            return false;
        }
        cache.markets[marketId].price = state.fetchPrice(marketId);
        if (state.markets[marketId].isClosing) {
            cache.markets[marketId].isClosing = true;
            cache.markets[marketId].borrowPar = state
                .getTotalPar(marketId)
                .borrow;
        }
        return true;
    }

    // ============ Getter Functions ============

    function getNumMarkets(MarketCache memory cache)
        internal
        pure
        returns (uint256)
    {
        return cache.markets.length;
    }

    function hasMarket(MarketCache memory cache, uint256 marketId)
        internal
        pure
        returns (bool)
    {
        return cache.markets[marketId].price.value != 0;
    }

    function getIsClosing(MarketCache memory cache, uint256 marketId)
        internal
        pure
        returns (bool)
    {
        return cache.markets[marketId].isClosing;
    }

    function getPrice(MarketCache memory cache, uint256 marketId)
        internal
        pure
        returns (Monetary.Price memory)
    {
        return cache.markets[marketId].price;
    }

    function getBorrowPar(MarketCache memory cache, uint256 marketId)
        internal
        pure
        returns (uint128)
    {
        return cache.markets[marketId].borrowPar;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Account.sol";
import "./Types.sol";

/**
 * Library that defines and parses valid Actions
 */

library Actions {
    // ============ Constants ============

    bytes32 constant FILE = "Actions";

    // ============ Enums ============

    enum ActionType {
        Deposit, // supply tokens
        Withdraw, // borrow tokens
        Transfer, // transfer balance between accounts
        Buy, // buy an amount of some token (externally)
        Sell, // sell an amount of some token (externally)
        Trade, // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize, // use excess tokens to zero-out a completely negative account
        Call // send arbitrary data to an address
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
     * Arguments that are passed to DxlnMargin in an ordered list as part of a single operation.
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
     * Moves tokens from an address to DxlnMargin. Can either repay a borrow or provide additional supply.
     */
    struct DepositArgs {
        Types.AssetAmount amount;
        Account.Info account;
        uint256 market;
        address from;
    }

    /*
     * Moves tokens from DxlnMargin to another address. Can either borrow tokens or reduce the amount
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
     * This action does not require any token movement since the trade is done internally to DxlnMargin.
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
     * This action does not require any token movement since the trade is done internally to DxlnMargin.
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
     * Similar to liquidate, but vaporAccounts are accounts that have only negative balances
     * remaining. The arbitrageur pays back the negative asset (owedMarket) of the vaporAccount in
     * exchange for a collateral asset (heldMarket) at a favorable spread. However, since the
     * liquidAccount has no collateral assets, the collateral must come from DxlnMargin's excess tokens.
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

    function getMarketLayout(ActionType actionType)
        internal
        pure
        returns (MarketLayout)
    {
        if (
            actionType == Actions.ActionType.Deposit ||
            actionType == Actions.ActionType.Withdraw ||
            actionType == Actions.ActionType.Transfer
        ) {
            return MarketLayout.OneMarket;
        } else if (actionType == Actions.ActionType.Call) {
            return MarketLayout.ZeroMarkets;
        }
        return MarketLayout.TwoMarkets;
    }

    function getAccountLayout(ActionType actionType)
        internal
        pure
        returns (AccountLayout)
    {
        if (
            actionType == Actions.ActionType.Transfer ||
            actionType == Actions.ActionType.Trade
        ) {
            return AccountLayout.TwoPrimary;
        } else if (
            actionType == Actions.ActionType.Liquidate ||
            actionType == Actions.ActionType.Vaporize
        ) {
            return AccountLayout.PrimaryAndSecondary;
        }
        return AccountLayout.OnePrimary;
    }

    // ============ Parsing Functions ============

    function parseDepositArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    ) internal pure returns (DepositArgs memory) {
        assert(args.actionType == ActionType.Deposit);
        return
            DepositArgs({
                amount: args.amount,
                account: accounts[args.accountId],
                market: args.primaryMarketId,
                from: args.otherAddress
            });
    }

    function parseWithdrawArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    ) internal pure returns (WithdrawArgs memory) {
        assert(args.actionType == ActionType.Withdraw);
        return
            WithdrawArgs({
                amount: args.amount,
                account: accounts[args.accountId],
                market: args.primaryMarketId,
                to: args.otherAddress
            });
    }

    function parseTransferArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    ) internal pure returns (TransferArgs memory) {
        assert(args.actionType == ActionType.Transfer);
        return
            TransferArgs({
                amount: args.amount,
                accountOne: accounts[args.accountId],
                accountTwo: accounts[args.otherAccountId],
                market: args.primaryMarketId
            });
    }

    function parseBuyArgs(
        Account.Info[] memory accounts,
        ActionArgs memory args
    ) internal pure returns (BuyArgs memory) {
        assert(args.actionType == ActionType.Buy);
        return
            BuyArgs({
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
    ) internal pure returns (SellArgs memory) {
        assert(args.actionType == ActionType.Sell);
        return
            SellArgs({
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
    ) internal pure returns (TradeArgs memory) {
        assert(args.actionType == ActionType.Trade);
        return
            TradeArgs({
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
    ) internal pure returns (LiquidateArgs memory) {
        assert(args.actionType == ActionType.Liquidate);
        return
            LiquidateArgs({
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
    ) internal pure returns (VaporizeArgs memory) {
        assert(args.actionType == ActionType.Vaporize);
        return
            VaporizeArgs({
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
    ) internal pure returns (CallArgs memory) {
        assert(args.actionType == ActionType.Call);
        return
            CallArgs({
                account: accounts[args.accountId],
                callee: args.otherAddress,
                data: args.data
            });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Types.sol";

/**
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
        address owner; // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    // The complete storage for any account
    struct Storage {
        mapping(uint256 => Types.Par) balances; // Mapping from marketId to principal
        Status status;
    }

    // ============ Library Functions ============

    function equals(Info memory a, Info memory b) internal pure returns (bool) {
        return a.owner == b.owner && a.number == b.number;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/Monetary.sol";

/**
 * Interface that Price Oracles for DxlnMargin must implement in order to report prices.
 */
abstract contract IPriceOracle {
    // ============ Constants ============

    uint256 public constant ONE_DOLLAR = 10**36;

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
    function getPrice(address token)
        public
        view
        virtual
        returns (Monetary.Price memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/Interest.sol";

/**
 * Interface that Interest Setters for DxlnMargin must implement in order to report interest rates.
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
    ) external view returns (Interest.Rate memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * Interface that Exchange Wrappers for DxlnMargin must implement in order to trade ERC20 tokens.
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
     * @param  makerToken           Address of makerToken, the token to receive
     * @param  takerToken           Address of takerToken, the token to pay
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
    ) external returns (uint256);

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
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * Interface for using ERC20 Tokens. We have to use a special interface to call ERC20 functions so
 * that we don't automatically revert when calling non-compliant tokens that have no return value for
 * transfer(), transferFrom(), or approve().
 */
interface IErc20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function approve(address spender, uint256 value) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "../lib/Account.sol";

/**
 * Interface that Callees for DxlnMargin must implement in order to ingest data.
 */
abstract contract ICallee {
    // ============ Public Functions ============

    /**
     * Allows users to send this contract arbitrary data.
     *
     * @param  sender       The msg.sender to DxlnMargin
     * @param  accountInfo  The account from which the data is being sent
     * @param  data         Arbitrary data given by the sender
     */
    function callFunction(
        address sender,
        Account.Info memory accountInfo,
        bytes memory data
    ) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/Types.sol";
import "../lib/Account.sol";

/**
 * Interface that Auto-Traders for DxlnMargin must implement in order to approve trades.
 */

abstract contract IAutoTrader {
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
    ) public virtual returns (Types.AssetAmount memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../utils/SafeMath.sol";
import "../intf/IAutoTrader.sol";
import "../intf/ICallee.sol";
import "../lib/Account.sol";
import "../lib/Actions.sol";
import "../lib/Cache.sol";
import "../lib/Decimal.sol";
import "../lib/Events.sol";
import "../lib/Exchange.sol";
import "../utils/Math.sol";
import "../lib/Monetary.sol";
// import "../lib/Require.sol";
import "../lib/Storage.sol";
import "../lib/Types.sol";

/**
 * Logic for processing actions
 */
library OperationImpl {
    using Cache for Cache.MarketCache;
    using SafeMath for uint256;
    using Storage for Storage.State;
    using Types for Types.Par;
    using Types for Types.Wei;

    // ============ Constants ============

    // bytes32 constant FILE = "OperationImpl";

    // ============ Public Functions ============

    function operate(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) public {
        Events.logOperation();

        _verifyInputs(accounts, actions);

        (
            bool[] memory primaryAccounts,
            Cache.MarketCache memory cache
        ) = _runPreprocessing(state, accounts, actions);

        _runActions(state, accounts, actions, cache);

        _verifyFinalState(state, accounts, primaryAccounts, cache);
    }

    // ============ Helper Functions ============

    function _verifyInputs(
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) private pure {
        require(actions.length != 0, "Cannot have zero actions");

        require(accounts.length != 0, "Cannot have zero accounts");

        for (uint256 a = 0; a < accounts.length; a++) {
            for (uint256 b = a + 1; b < accounts.length; b++) {
                require(
                    !Account.equals(accounts[a], accounts[b]),
                    "Cannot duplicate accounts"
                );
            }
        }
    }

    function _runPreprocessing(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions
    ) private returns (bool[] memory, Cache.MarketCache memory) {
        uint256 numMarkets = state.numMarkets;
        bool[] memory primaryAccounts = new bool[](accounts.length);
        Cache.MarketCache memory cache = Cache.create(numMarkets);

        // keep track of primary accounts and indexes that need updating
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory arg = actions[i];
            Actions.ActionType actionType = arg.actionType;
            Actions.MarketLayout marketLayout = Actions.getMarketLayout(
                actionType
            );
            Actions.AccountLayout accountLayout = Actions.getAccountLayout(
                actionType
            );

            // parse out primary accounts
            if (accountLayout != Actions.AccountLayout.OnePrimary) {
                require(
                    arg.accountId != arg.otherAccountId,
                    "Duplicate accounts in action"
                );
                if (accountLayout == Actions.AccountLayout.TwoPrimary) {
                    primaryAccounts[arg.otherAccountId] = true;
                } else {
                    assert(
                        accountLayout ==
                            Actions.AccountLayout.PrimaryAndSecondary
                    );
                    require(
                        !primaryAccounts[arg.otherAccountId],
                        "Requires non-primary account"
                    );
                }
            }
            primaryAccounts[arg.accountId] = true;

            // keep track of indexes to update
            if (marketLayout == Actions.MarketLayout.OneMarket) {
                _updateMarket(state, cache, arg.primaryMarketId);
            } else if (marketLayout == Actions.MarketLayout.TwoMarkets) {
                require(
                    arg.primaryMarketId != arg.secondaryMarketId,
                    "Duplicate markets in action"
                );
                _updateMarket(state, cache, arg.primaryMarketId);
                _updateMarket(state, cache, arg.secondaryMarketId);
            } else {
                assert(marketLayout == Actions.MarketLayout.ZeroMarkets);
            }
        }

        // get any other markets for which an account has a balance
        for (uint256 m = 0; m < numMarkets; m++) {
            if (cache.hasMarket(m)) {
                continue;
            }
            for (uint256 a = 0; a < accounts.length; a++) {
                if (!state.getPar(accounts[a], m).isZero()) {
                    _updateMarket(state, cache, m);
                    break;
                }
            }
        }

        return (primaryAccounts, cache);
    }

    function _updateMarket(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 marketId
    ) private {
        bool updated = cache.addMarket(state, marketId);
        if (updated) {
            Events.logIndexUpdate(marketId, state.updateIndex(marketId));
        }
    }

    function _runActions(
        Storage.State storage state,
        Account.Info[] memory accounts,
        Actions.ActionArgs[] memory actions,
        Cache.MarketCache memory cache
    ) private {
        for (uint256 i = 0; i < actions.length; i++) {
            Actions.ActionArgs memory action = actions[i];
            Actions.ActionType actionType = action.actionType;

            if (actionType == Actions.ActionType.Deposit) {
                _deposit(state, Actions.parseDepositArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Withdraw) {
                _withdraw(state, Actions.parseWithdrawArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Transfer) {
                _transfer(state, Actions.parseTransferArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Buy) {
                _buy(state, Actions.parseBuyArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Sell) {
                _sell(state, Actions.parseSellArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Trade) {
                _trade(state, Actions.parseTradeArgs(accounts, action));
            } else if (actionType == Actions.ActionType.Liquidate) {
                _liquidate(
                    state,
                    Actions.parseLiquidateArgs(accounts, action),
                    cache
                );
            } else if (actionType == Actions.ActionType.Vaporize) {
                _vaporize(
                    state,
                    Actions.parseVaporizeArgs(accounts, action),
                    cache
                );
            } else {
                assert(actionType == Actions.ActionType.Call);
                _call(state, Actions.parseCallArgs(accounts, action));
            }
        }
    }

    function _verifyFinalState(
        Storage.State storage state,
        Account.Info[] memory accounts,
        bool[] memory primaryAccounts,
        Cache.MarketCache memory cache
    ) private {
        // verify no increase in borrowPar for closing markets
        uint256 numMarkets = cache.getNumMarkets();
        for (uint256 m = 0; m < numMarkets; m++) {
            if (cache.getIsClosing(m)) {
                require(
                    state.getTotalPar(m).borrow <= cache.getBorrowPar(m),
                    "Market is closing"
                );
            }
        }

        // verify account collateralization
        for (uint256 a = 0; a < accounts.length; a++) {
            Account.Info memory account = accounts[a];

            // validate minBorrowedValue
            bool collateralized = state.isCollateralized(account, cache, true);

            // don't check collateralization for non-primary accounts
            if (!primaryAccounts[a]) {
                continue;
            }

            // check collateralization for primary accounts
            require(collateralized, "Undercollateralized account");

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
    ) private {
        state.requireIsOperator(args.account, msg.sender);

        require(
            args.from == msg.sender || args.from == args.account.owner,
            "Invalid deposit source"
        );

        (Types.Par memory newPar, Types.Wei memory deltaWei) = state
            .getNewParAndDeltaWei(args.account, args.market, args.amount);

        state.setPar(args.account, args.market, newPar);

        // requires a positive deltaWei
        Exchange.transferIn(state.getToken(args.market), args.from, deltaWei);

        Events.logDeposit(state, args, deltaWei);
    }

    function _withdraw(
        Storage.State storage state,
        Actions.WithdrawArgs memory args
    ) private {
        state.requireIsOperator(args.account, msg.sender);

        (Types.Par memory newPar, Types.Wei memory deltaWei) = state
            .getNewParAndDeltaWei(args.account, args.market, args.amount);

        state.setPar(args.account, args.market, newPar);

        // requires a negative deltaWei
        Exchange.transferOut(state.getToken(args.market), args.to, deltaWei);

        Events.logWithdraw(state, args, deltaWei);
    }

    function _transfer(
        Storage.State storage state,
        Actions.TransferArgs memory args
    ) private {
        state.requireIsOperator(args.accountOne, msg.sender);
        state.requireIsOperator(args.accountTwo, msg.sender);

        (Types.Par memory newPar, Types.Wei memory deltaWei) = state
            .getNewParAndDeltaWei(args.accountOne, args.market, args.amount);

        state.setPar(args.accountOne, args.market, newPar);

        state.setParFromDeltaWei(
            args.accountTwo,
            args.market,
            deltaWei.negative()
        );

        Events.logTransfer(state, args, deltaWei);
    }

    function _buy(Storage.State storage state, Actions.BuyArgs memory args)
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (Types.Par memory makerPar, Types.Wei memory makerWei) = state
            .getNewParAndDeltaWei(args.account, args.makerMarket, args.amount);

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

        require(
            tokensReceived.value >= makerWei.value,
            "Buy amount less than promised"
        );

        state.setPar(args.account, args.makerMarket, makerPar);

        state.setParFromDeltaWei(args.account, args.takerMarket, takerWei);

        Events.logBuy(state, args, takerWei, makerWei);
    }

    function _sell(Storage.State storage state, Actions.SellArgs memory args)
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        address takerToken = state.getToken(args.takerMarket);
        address makerToken = state.getToken(args.makerMarket);

        (Types.Par memory takerPar, Types.Wei memory takerWei) = state
            .getNewParAndDeltaWei(args.account, args.takerMarket, args.amount);

        Types.Wei memory makerWei = Exchange.exchange(
            args.exchangeWrapper,
            args.account.owner,
            makerToken,
            takerToken,
            takerWei,
            args.orderData
        );

        state.setPar(args.account, args.takerMarket, takerPar);

        state.setParFromDeltaWei(args.account, args.makerMarket, makerWei);

        Events.logSell(state, args, takerWei, makerWei);
    }

    function _trade(Storage.State storage state, Actions.TradeArgs memory args)
        private
    {
        state.requireIsOperator(args.takerAccount, msg.sender);
        state.requireIsOperator(args.makerAccount, args.autoTrader);

        Types.Par memory oldInputPar = state.getPar(
            args.makerAccount,
            args.inputMarket
        );
        (Types.Par memory newInputPar, Types.Wei memory inputWei) = state
            .getNewParAndDeltaWei(
                args.makerAccount,
                args.inputMarket,
                args.amount
            );

        Types.AssetAmount memory outputAmount = IAutoTrader(args.autoTrader)
            .getTradeCost(
                args.inputMarket,
                args.outputMarket,
                args.makerAccount,
                args.takerAccount,
                oldInputPar,
                newInputPar,
                inputWei,
                args.tradeData
            );

        (Types.Par memory newOutputPar, Types.Wei memory outputWei) = state
            .getNewParAndDeltaWei(
                args.makerAccount,
                args.outputMarket,
                outputAmount
            );

        require(
            outputWei.isZero() ||
                inputWei.isZero() ||
                outputWei.sign != inputWei.sign,
            "Trades cannot be one-sided"
        );

        // set the balance for the maker
        state.setPar(args.makerAccount, args.inputMarket, newInputPar);
        state.setPar(args.makerAccount, args.outputMarket, newOutputPar);

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

        Events.logTrade(state, args, inputWei, outputWei);
    }

    function _liquidate(
        Storage.State storage state,
        Actions.LiquidateArgs memory args,
        Cache.MarketCache memory cache
    ) private {
        state.requireIsOperator(args.solidAccount, msg.sender);

        // verify liquidatable
        if (Account.Status.Liquid != state.getStatus(args.liquidAccount)) {
            require(
                !state.isCollateralized(
                    args.liquidAccount,
                    cache,
                    /* requireMinBorrow = */
                    false
                ),
                "Unliquidatable account"
            );
            state.setStatus(args.liquidAccount, Account.Status.Liquid);
        }

        Types.Wei memory maxHeldWei = state.getWei(
            args.liquidAccount,
            args.heldMarket
        );

        require(!maxHeldWei.isNegative(), "Collateral cannot be negative");

        (Types.Par memory owedPar, Types.Wei memory owedWei) = state
            .getNewParAndDeltaWeiForLiquidation(
                args.liquidAccount,
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

        Types.Wei memory heldWei = _owedWeiToHeldWei(
            owedWei,
            heldPrice,
            owedPrice
        );

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPrice);

            state.setPar(args.liquidAccount, args.heldMarket, Types.zeroPar());
            state.setParFromDeltaWei(
                args.liquidAccount,
                args.owedMarket,
                owedWei
            );
        } else {
            state.setPar(args.liquidAccount, args.owedMarket, owedPar);
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

        Events.logLiquidate(state, args, heldWei, owedWei);
    }

    function _vaporize(
        Storage.State storage state,
        Actions.VaporizeArgs memory args,
        Cache.MarketCache memory cache
    ) private {
        state.requireIsOperator(args.solidAccount, msg.sender);

        // verify vaporizable
        if (Account.Status.Vapor != state.getStatus(args.vaporAccount)) {
            require(
                state.isVaporizable(args.vaporAccount, cache),
                "Unvaporizable account"
            );
            state.setStatus(args.vaporAccount, Account.Status.Vapor);
        }

        // First, attempt to refund using the same token
        (bool fullyRepaid, Types.Wei memory excessWei) = _vaporizeUsingExcess(
            state,
            args
        );
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

        require(!maxHeldWei.isNegative(), "Excess cannot be negative");

        (Types.Par memory owedPar, Types.Wei memory owedWei) = state
            .getNewParAndDeltaWeiForLiquidation(
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

        Types.Wei memory heldWei = _owedWeiToHeldWei(
            owedWei,
            heldPrice,
            owedPrice
        );

        // if attempting to over-borrow the held asset, bound it by the maximum
        if (heldWei.value > maxHeldWei.value) {
            heldWei = maxHeldWei.negative();
            owedWei = _heldWeiToOwedWei(heldWei, heldPrice, owedPrice);

            state.setParFromDeltaWei(
                args.vaporAccount,
                args.owedMarket,
                owedWei
            );
        } else {
            state.setPar(args.vaporAccount, args.owedMarket, owedPar);
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

        Events.logVaporize(state, args, heldWei, owedWei, excessWei);
    }

    function _call(Storage.State storage state, Actions.CallArgs memory args)
        private
    {
        state.requireIsOperator(args.account, msg.sender);

        ICallee(args.callee).callFunction(msg.sender, args.account, args.data);

        Events.logCall(args);
    }

    // ============ Private Functions ============

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of heldWei
     * given owedWei and the (spread-adjusted) prices of each asset.
     */
    function _owedWeiToHeldWei(
        Types.Wei memory owedWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    ) private pure returns (Types.Wei memory) {
        return
            Types.Wei({
                sign: false,
                value: Math.getPartial(
                    owedWei.value,
                    owedPrice.value,
                    heldPrice.value
                )
            });
    }

    /**
     * For the purposes of liquidation or vaporization, get the value-equivalent amount of owedWei
     * given heldWei and the (spread-adjusted) prices of each asset.
     */
    function _heldWeiToOwedWei(
        Types.Wei memory heldWei,
        Monetary.Price memory heldPrice,
        Monetary.Price memory owedPrice
    ) private pure returns (Types.Wei memory) {
        return
            Types.Wei({
                sign: true,
                value: Math.getPartialRoundUp(
                    heldWei.value,
                    heldPrice.value,
                    owedPrice.value
                )
            });
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
    ) internal returns (bool, Types.Wei memory) {
        Types.Wei memory excessWei = state.getNumExcessTokens(args.owedMarket);

        // There are no excess funds, return zero
        if (!excessWei.isPositive()) {
            return (false, Types.zeroWei());
        }

        Types.Wei memory maxRefundWei = state.getWei(
            args.vaporAccount,
            args.owedMarket
        );
        maxRefundWei.sign = true;

        // The account is fully vaporizable using excess funds
        if (excessWei.value >= maxRefundWei.value) {
            state.setPar(args.vaporAccount, args.owedMarket, Types.zeroPar());
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
     * Return the (spread-adjusted) prices of two assets for the purposes of liquidation or
     * vaporization.
     */
    function _getLiquidationPrices(
        Storage.State storage state,
        Cache.MarketCache memory cache,
        uint256 heldMarketId,
        uint256 owedMarketId
    ) internal view returns (Monetary.Price memory, Monetary.Price memory) {
        uint256 originalPrice = cache.getPrice(owedMarketId).value;
        Decimal.D256 memory spread = state.getLiquidationSpreadForPair(
            heldMarketId,
            owedMarketId
        );

        Monetary.Price memory owedPrice = Monetary.Price({
            value: originalPrice.add(Decimal.mul(originalPrice, spread))
        });

        return (cache.getPrice(heldMarketId), owedPrice);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../intf/IInterestSetter.sol";
import "../intf/IPriceOracle.sol";
import "../lib/Decimal.sol";
import "../lib/Interest.sol";
import "../lib/Monetary.sol";
// import "../lib/Require.sol";
import "../lib/Storage.sol";
import "../lib/Token.sol";
import "../lib/Types.sol";

/**
 * Administrative functions to keep the protocol updated
 */
library AdminImpl {
    using Storage for Storage.State;
    using Token for address;
    using Types for Types.Wei;

    // ============ Constants ============

    // bytes32 constant FILE = "AdminImpl";

    // ============ Events ============

    event LogWithdrawExcessTokens(address token, uint256 amount);

    event LogAddMarket(uint256 marketId, address token);

    event LogSetIsClosing(uint256 marketId, bool isClosing);

    event LogSetPriceOracle(uint256 marketId, address priceOracle);

    event LogSetInterestSetter(uint256 marketId, address interestSetter);

    event LogSetMarginPremium(uint256 marketId, Decimal.D256 marginPremium);

    event LogSetSpreadPremium(uint256 marketId, Decimal.D256 spreadPremium);

    event LogSetMarginRatio(Decimal.D256 marginRatio);

    event LogSetLiquidationSpread(Decimal.D256 liquidationSpread);

    event LogSetEarningsRate(Decimal.D256 earningsRate);

    event LogSetMinBorrowedValue(Monetary.Value minBorrowedValue);

    event LogSetGlobalOperator(address operator, bool approved);

    // ============ Token Functions ============

    function ownerWithdrawExcessTokens(
        Storage.State storage state,
        uint256 marketId,
        address recipient
    ) public returns (uint256) {
        _validateMarketId(state, marketId);
        Types.Wei memory excessWei = state.getNumExcessTokens(marketId);

        require(!excessWei.isNegative(), "Negative excess");

        address token = state.getToken(marketId);

        uint256 actualBalance = token.balanceOf(address(this));
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
    ) public returns (uint256) {
        _requireNoMarket(state, token);

        uint256 balance = token.balanceOf(address(this));
        token.transfer(recipient, balance);

        emit LogWithdrawExcessTokens(token, balance);

        return balance;
    }

    // ============ Market Functions ============

    function ownerAddMarket(
        Storage.State storage state,
        address token,
        IPriceOracle priceOracle,
        IInterestSetter interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) public {
        _requireNoMarket(state, token);

        uint256 marketId = state.numMarkets;

        state.numMarkets++;
        state.markets[marketId].token = token;
        state.markets[marketId].index = Interest.newIndex();

        emit LogAddMarket(marketId, token);

        _setPriceOracle(state, marketId, priceOracle);
        _setInterestSetter(state, marketId, interestSetter);
        _setMarginPremium(state, marketId, marginPremium);
        _setSpreadPremium(state, marketId, spreadPremium);
    }

    function ownerSetIsClosing(
        Storage.State storage state,
        uint256 marketId,
        bool isClosing
    ) public {
        _validateMarketId(state, marketId);
        state.markets[marketId].isClosing = isClosing;
        emit LogSetIsClosing(marketId, isClosing);
    }

    function ownerSetPriceOracle(
        Storage.State storage state,
        uint256 marketId,
        IPriceOracle priceOracle
    ) public {
        _validateMarketId(state, marketId);
        _setPriceOracle(state, marketId, priceOracle);
    }

    function ownerSetInterestSetter(
        Storage.State storage state,
        uint256 marketId,
        IInterestSetter interestSetter
    ) public {
        _validateMarketId(state, marketId);
        _setInterestSetter(state, marketId, interestSetter);
    }

    function ownerSetMarginPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public {
        _validateMarketId(state, marketId);
        _setMarginPremium(state, marketId, marginPremium);
    }

    function ownerSetSpreadPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public {
        _validateMarketId(state, marketId);
        _setSpreadPremium(state, marketId, spreadPremium);
    }

    // ============ Risk Functions ============

    function ownerSetMarginRatio(
        Storage.State storage state,
        Decimal.D256 memory ratio
    ) public {
        require(
            ratio.value <= state.riskLimits.marginRatioMax,
            "Ratio too high"
        );
        require(
            ratio.value > state.riskParams.liquidationSpread.value,
            "Ratio cannot be <= spread"
        );
        state.riskParams.marginRatio = ratio;
        emit LogSetMarginRatio(ratio);
    }

    function ownerSetLiquidationSpread(
        Storage.State storage state,
        Decimal.D256 memory spread
    ) public {
        require(
            spread.value <= state.riskLimits.liquidationSpreadMax,
            "Spread too high"
        );
        require(
            spread.value < state.riskParams.marginRatio.value,
            "Spread cannot be >= ratio"
        );
        state.riskParams.liquidationSpread = spread;
        emit LogSetLiquidationSpread(spread);
    }

    function ownerSetEarningsRate(
        Storage.State storage state,
        Decimal.D256 memory earningsRate
    ) public {
        require(
            earningsRate.value <= state.riskLimits.earningsRateMax,
            "Rate too high"
        );
        state.riskParams.earningsRate = earningsRate;
        emit LogSetEarningsRate(earningsRate);
    }

    function ownerSetMinBorrowedValue(
        Storage.State storage state,
        Monetary.Value memory minBorrowedValue
    ) public {
        require(
            minBorrowedValue.value <= state.riskLimits.minBorrowedValueMax,
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
    ) public {
        state.globalOperators[operator] = approved;

        emit LogSetGlobalOperator(operator, approved);
    }

    // ============ Private Functions ============

    function _setPriceOracle(
        Storage.State storage state,
        uint256 marketId,
        IPriceOracle priceOracle
    ) private {
        // require oracle can return non-zero price
        address token = state.markets[marketId].token;

        require(
            priceOracle.getPrice(token).value != 0,
            "Invalid oracle price"
        );

        state.markets[marketId].priceOracle = priceOracle;

        emit LogSetPriceOracle(marketId, address(priceOracle));
    }

    function _setInterestSetter(
        Storage.State storage state,
        uint256 marketId,
        IInterestSetter interestSetter
    ) private {
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
    ) private {
        require(
            marginPremium.value <= state.riskLimits.marginPremiumMax,
            "Margin premium too high"
        );
        state.markets[marketId].marginPremium = marginPremium;

        emit LogSetMarginPremium(marketId, marginPremium);
    }

    function _setSpreadPremium(
        Storage.State storage state,
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) private {
        require(
            spreadPremium.value <= state.riskLimits.spreadPremiumMax,
            "Spread premium too high"
        );
        state.markets[marketId].spreadPremium = spreadPremium;

        emit LogSetSpreadPremium(marketId, spreadPremium);
    }

    function _requireNoMarket(Storage.State storage state, address token)
        private
        view
    {
        uint256 numMarkets = state.numMarkets;

        bool marketExists = false;

        for (uint256 m = 0; m < numMarkets; m++) {
            if (state.markets[m].token == token) {
                marketExists = true;
                break;
            }
        }

        require(!marketExists,"Market exists");
    }

    function _validateMarketId(Storage.State storage state, uint256 marketId)
        private
        view
    {
        require(marketId < state.numMarkets,"Market OOB");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./lib/Storage.sol";

/**
 * Base-level contract that holds the state of DxlnMargin
 */
contract State {
    Storage.State g_state;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./State.sol";

/**
 * Public function that allows other addresses to manage accounts
 */
contract Permission is State {
    // ============ Events ============

    event LogOperatorSet(address indexed owner, address operator, bool trusted);

    // ============ Structs ============

    struct OperatorArg {
        address operator;
        bool trusted;
    }

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
    function setOperators(OperatorArg[] memory args) public {
        for (uint256 i = 0; i < args.length; i++) {
            address operator = args[i].operator;
            bool trusted = args[i].trusted;
            g_state.operators[msg.sender][operator] = trusted;
            emit LogOperatorSet(msg.sender, operator, trusted);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./utils/ReentrancyGuard.sol";
import "./State.sol";
import "./impl/OperationImpl.sol";
import "./lib/Account.sol";
import "./lib/Actions.sol";

/**
 * Primary public function for allowing users and contracts to manage accounts within DxlnMargin
 */
contract Operation is State, ReentrancyGuard {
    // ============ Public Functions ============

    /**
     * The main entry-point to DxlnMargin that allows users and contracts to manage accounts.
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
    ) public nonReentrant {
        OperationImpl.operate(g_state, accounts, actions);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./State.sol";
import "./intf/IInterestSetter.sol";
import "./intf/IPriceOracle.sol";
import "./lib/Account.sol";
import "./lib/Cache.sol";
import "./lib/Decimal.sol";
import "./lib/Interest.sol";
import "./lib/Monetary.sol";
// import "./lib/Require.sol";
import "./lib/Storage.sol";
import "./lib/Token.sol";
import "./lib/Types.sol";

/**
 * Public read-only functions that allow transparency into the state of DxlnMargin
 */

contract Getters is State {
    using Cache for Cache.MarketCache;
    using Storage for Storage.State;
    using Types for Types.Par;

    // ============ Constants ============

    // bytes32 FILE = "Getters";

    // ============ Getters for Risk ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() public view returns (Decimal.D256 memory) {
        return g_state.riskParams.marginRatio;
    }

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() public view returns (Decimal.D256 memory) {
        return g_state.riskParams.liquidationSpread;
    }

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() public view returns (Decimal.D256 memory) {
        return g_state.riskParams.earningsRate;
    }

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DxlnMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() public view returns (Monetary.Value memory) {
        return g_state.riskParams.minBorrowedValue;
    }

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() public view returns (Storage.RiskParams memory) {
        return g_state.riskParams;
    }

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DxlnMargin.
     *
     * @return  All global risk parameter limnits
     */
    function getRiskLimits() public view returns (Storage.RiskLimits memory) {
        return g_state.riskLimits;
    }

    // ============ Getters for Markets ============

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() public view returns (uint256) {
        return g_state.numMarkets;
    }

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(uint256 marketId)
        public
        view
        returns (address)
    {
        _requireValidMarket(marketId);
        return g_state.getToken(marketId);
    }

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(uint256 marketId)
        public
        view
        returns (Types.TotalPar memory)
    {
        _requireValidMarket(marketId);
        return g_state.getTotalPar(marketId);
    }

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(uint256 marketId)
        public
        view
        returns (Interest.Index memory)
    {
        _requireValidMarket(marketId);
        return g_state.getIndex(marketId);
    }

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(uint256 marketId)
        public
        view
        returns (Interest.Index memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchNewIndex(marketId, g_state.getIndex(marketId));
    }

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(uint256 marketId)
        public
        view
        returns (IPriceOracle)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].priceOracle;
    }

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(uint256 marketId)
        public
        view
        returns (IInterestSetter)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].interestSetter;
    }

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(uint256 marketId)
        public
        view
        returns (Decimal.D256 memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].marginPremium;
    }

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(uint256 marketId)
        public
        view
        returns (Decimal.D256 memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].spreadPremium;
    }

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(uint256 marketId) public view returns (bool) {
        _requireValidMarket(marketId);
        return g_state.markets[marketId].isClosing;
    }

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(uint256 marketId)
        public
        view
        returns (Monetary.Price memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchPrice(marketId);
    }

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(uint256 marketId)
        public
        view
        returns (Interest.Rate memory)
    {
        _requireValidMarket(marketId);
        return g_state.fetchInterestRate(marketId, g_state.getIndex(marketId));
    }

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
    ) public view returns (Decimal.D256 memory) {
        _requireValidMarket(heldMarketId);
        _requireValidMarket(owedMarketId);
        return g_state.getLiquidationSpreadForPair(heldMarketId, owedMarketId);
    }

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Storage.Market struct with the current state of the market
     */
    function getMarket(uint256 marketId)
        public
        view
        returns (Storage.Market memory)
    {
        _requireValidMarket(marketId);
        return g_state.markets[marketId];
    }

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
    function getMarketWithInfo(uint256 marketId)
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

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated
     * by taking the current number of tokens held in DxlnMargin, adding the number of tokens owed to DxlnMargin
     * by borrowers, and subtracting the number of tokens owed to suppliers by DxlnMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(uint256 marketId)
        public
        view
        returns (Types.Wei memory)
    {
        _requireValidMarket(marketId);
        return g_state.getNumExcessTokens(marketId);
    }

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(Account.Info memory account, uint256 marketId)
        public
        view
        returns (Types.Par memory)
    {
        _requireValidMarket(marketId);
        return g_state.getPar(account, marketId);
    }

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(Account.Info memory account, uint256 marketId)
        public
        view
        returns (Types.Wei memory)
    {
        _requireValidMarket(marketId);
        return
            Interest.parToWei(
                g_state.getPar(account, marketId),
                g_state.fetchNewIndex(marketId, g_state.getIndex(marketId))
            );
    }

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(Account.Info memory account)
        public
        view
        returns (Account.Status)
    {
        return g_state.getStatus(account);
    }

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(Account.Info memory account)
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        return
            getAccountValuesInternal(
                account,
                /* adjustForLiquidity = */
                false
            );
    }

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
    function getAdjustedAccountValues(Account.Info memory account)
        public
        view
        returns (Monetary.Value memory, Monetary.Value memory)
    {
        return
            getAccountValuesInternal(
                account,
                /* adjustForLiquidity = */
                true
            );
    }

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(Account.Info memory account)
        public
        view
        returns (
            address[] memory,
            Types.Par[] memory,
            Types.Wei[] memory
        )
    {
        uint256 numMarkets = g_state.numMarkets;
        address[] memory tokens = new address[](numMarkets);
        Types.Par[] memory pars = new Types.Par[](numMarkets);
        Types.Wei[] memory weis = new Types.Wei[](numMarkets);

        for (uint256 m = 0; m < numMarkets; m++) {
            tokens[m] = getMarketTokenAddress(m);
            pars[m] = getAccountPar(account, m);
            weis[m] = getAccountWei(account, m);
        }

        return (tokens, pars, weis);
    }

    // ============ Getters for Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(address owner, address operator)
        public
        view
        returns (bool)
    {
        return g_state.isLocalOperator(owner, operator);
    }

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(address operator) public view returns (bool) {
        return g_state.isGlobalOperator(operator);
    }

    // ============ Private Helper Functions ============

    /**
     * Revert if marketId is invalid.
     */
    function _requireValidMarket(uint256 marketId) private view {
        require(marketId < g_state.numMarkets,"Market OOB");
    }

    /**
     * Private helper for getting the monetary values of an account.
     */
    function getAccountValuesInternal(
        Account.Info memory account,
        bool adjustForLiquidity
    ) private view returns (Monetary.Value memory, Monetary.Value memory) {
        uint256 numMarkets = g_state.numMarkets;

        // populate cache
        Cache.MarketCache memory cache = Cache.create(numMarkets);
        for (uint256 m = 0; m < numMarkets; m++) {
            if (!g_state.getPar(account, m).isZero()) {
                cache.addMarket(g_state, m);
            }
        }

        return g_state.getAccountValues(account, cache, adjustForLiquidity);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./utils/ReentrancyGuard.sol";
import "./utils/Ownable.sol";
import "./State.sol";
import "./impl/AdminImpl.sol";
import "./intf/IInterestSetter.sol";
import "./intf/IPriceOracle.sol";
import "./lib/Decimal.sol";
import "./lib/Interest.sol";
import "./lib/Monetary.sol";
import "./lib/Token.sol";

/**
 * Public functions that allow the privileged owner address to manage DxlnMargin
 */

contract Admin is State, Ownable, ReentrancyGuard {
    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be
     * withdrawn. The number of excess tokens is calculated by taking the current number of tokens
     * held in DxlnMargin, adding the number of tokens owed to DxlnMargin by borrowers, and subtracting the
     * number of tokens owed to suppliers by DxlnMargin.
     */
    function ownerWithdrawExcessTokens(uint256 marketId, address recipient)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return
            AdminImpl.ownerWithdrawExcessTokens(g_state, marketId, recipient);
    }

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(address token, address recipient)
        public
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        return
            AdminImpl.ownerWithdrawUnsupportedTokens(g_state, token, recipient);
    }

    // ============ Market Functions ============

    /**
     * Add a new market to DxlnMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IPriceOracle priceOracle,
        IInterestSetter interestSetter,
        Decimal.D256 memory marginPremium,
        Decimal.D256 memory spreadPremium
    ) public onlyOwner nonReentrant {
        AdminImpl.ownerAddMarket(
            g_state,
            token,
            priceOracle,
            interestSetter,
            marginPremium,
            spreadPremium
        );
    }

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot
     * increase while its status is "closing".
     */
    function ownerSetIsClosing(uint256 marketId, bool isClosing)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetIsClosing(g_state, marketId, isClosing);
    }

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(uint256 marketId, IPriceOracle priceOracle)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetPriceOracle(g_state, marketId, priceOracle);
    }

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IInterestSetter interestSetter
    ) public onlyOwner nonReentrant {
        AdminImpl.ownerSetInterestSetter(g_state, marketId, interestSetter);
    }

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions
     * that include this market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal.D256 memory marginPremium
    ) public onlyOwner nonReentrant {
        AdminImpl.ownerSetMarginPremium(g_state, marketId, marginPremium);
    }

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations
     * that include this market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal.D256 memory spreadPremium
    ) public onlyOwner nonReentrant {
        AdminImpl.ownerSetSpreadPremium(g_state, marketId, spreadPremium);
    }

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     */
    function ownerSetMarginRatio(Decimal.D256 memory ratio)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetMarginRatio(g_state, ratio);
    }

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     */
    function ownerSetLiquidationSpread(Decimal.D256 memory spread)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetLiquidationSpread(g_state, spread);
    }

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     */
    function ownerSetEarningsRate(Decimal.D256 memory earningsRate)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetEarningsRate(g_state, earningsRate);
    }

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DxlnMargin.
     */
    function ownerSetMinBorrowedValue(Monetary.Value memory minBorrowedValue)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetMinBorrowedValue(g_state, minBorrowedValue);
    }

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in
     * DxlnMargin. Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(address operator, bool approved)
        public
        onlyOwner
        nonReentrant
    {
        AdminImpl.ownerSetGlobalOperator(g_state, operator, approved);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 10000
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/contracts/protocol/impl/OperationImpl.sol": {
      "OperationImpl": "0x2bbF236B0Afc4112cf79CE028f7D8095b1961cDe"
    },
    "/contracts/protocol/impl/AdminImpl.sol": {
      "AdminImpl": "0xF1424E875B0518afE7F5cEb945002D72f3A79Fbb"
    }
  },
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