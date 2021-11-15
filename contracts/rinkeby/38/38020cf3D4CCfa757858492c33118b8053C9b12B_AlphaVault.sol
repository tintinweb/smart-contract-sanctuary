// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "../interface/alpha/ICToken.sol";
import "../interface/alpha/ISafeBoxETH.sol";
import "../interface/IVault.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AlphaVault is IVault, Ownable, ReentrancyGuard {
    ISafeBoxETH internal immutable safeBox;
    ICToken internal immutable cToken;

    event ETHDeposited(uint256 amount, uint256 tokensMinted);
    event ETHWithdrawn(uint256 amount, uint256 tokensBurned);

    constructor(address safeBoxAddr) Ownable() {
        safeBox = ISafeBoxETH(safeBoxAddr);
        cToken = ICToken(ISafeBoxETH(safeBoxAddr).cToken());
    }

    receive() external payable {}

    function deposit() external payable override onlyOwner nonReentrant returns (uint256) {
        // Get amount of tokens before and after to determine how many were minted
        uint256 balBefore = safeBox.balanceOf(address(this));
        safeBox.deposit{ value: msg.value }();
        uint256 balAfter = safeBox.balanceOf(address(this));
        uint256 amountMinted = balAfter - balBefore;

        emit ETHDeposited(msg.value, amountMinted);

        return amountMinted;
    }

    function withdraw(uint256 amountEth, address payable recipient) external override onlyOwner nonReentrant {
        // Get the conversion rate
        // todo determine if we want stored or current
        uint256 exchangeRate = cToken.exchangeRateStored();

        // ibEthv2 is redeemable 1 for 1 with the underlying cToken
        // amount of ibEthv2 = Amount of Eth desired / exchange Rate
        (MathError mathErr, uint256 redeemTokens) = _divScalarByExpTruncate(amountEth, Exp({ mantissa: exchangeRate }));
        require(mathErr == MathError.NO_ERROR, "Internal error redeeming tokens");
        require(safeBox.balanceOf(address(this)) >= redeemTokens, "Not enough tokens to withdraw");

        uint256 balBefore = address(this).balance;
        safeBox.withdraw(redeemTokens);
        uint256 balAfter = address(this).balance;

        (bool success, ) = payable(recipient).call{ value: balAfter - balBefore }("");
        require(success, "Transaction failed.");
    }

    function getMaxWithdrawable() external view override returns (uint256) {
        // todo Need to figure out utilization rate, for now assume everything is withdrawable

        // Get the conversion rate from ibEthv2 to Eth
        // Does not account for interest accrued
        uint256 exchangeRate = cToken.exchangeRateStored();

        // ibEthv2 is redeemable 1 for 1 with the underlying cToken
        // amount of eth = Amount of ibethv2 * exchange Rate
        (MathError mathErr, uint256 redeemEth) = _mulScalarTruncate(
            Exp({ mantissa: exchangeRate }),
            safeBox.balanceOf(address(this))
        );
        require(mathErr == MathError.NO_ERROR, "Internal error redeeming tokens");

        return redeemEth;
    }

    /* ============ Compound Math Utils ============ */

    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    struct Exp {
        uint256 mantissa;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function _mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = _mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, _truncate(product));
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function _divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory fraction) = _divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, _truncate(fraction));
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function _truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / 1e18;
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function _mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledMantissa) = _mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: scaledMantissa }));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function _divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)
          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint256 numerator) = _mulUInt(1e18, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }
        return _getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function _getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = _mulUInt(num, 1e18);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (MathError err1, uint256 rational) = _divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Multiplies two numbers, returns an error on overflow.
     */
    function _mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint256 c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function _divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

interface ICToken {
    /*** User Interface ***/

    function totalBorrowsCurrent() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISafeBoxETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function cToken() external view returns (address);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

// Not sure this is even necessary but I think it makes sense
interface IVault {
    function deposit() external payable returns (uint256);

    function withdraw(uint256 amount, address payable recipient) external;

    function getMaxWithdrawable() external view returns (uint256);
}

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
        return msg.data;
    }
}

