// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


/**
  * @dev AMM that is designed for assets with stable price to each other e.g. USDC and USDT.
  * It utilizes constant sum price curve x + y = const but fee is variable depending on the token balances.
  * In most cases fee is equal to 1 bip. But when balances are at extreme ends it either lowers to 0
  * or increases to 20 bip.
  * Fee calculations are explained in more details in `getReturn` method.
  * Note that AMM does not support token with fees.
  * Note that tokens decimals are required to be the same.
 */
contract FixedRateSwap is ERC20 {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    event Swap(
        address indexed trader,
        int256 token0Amount,
        int256 token1Amount
    );

    event Deposit(
        address indexed user,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 share
    );

    event Withdrawal(
        address indexed user,
        uint256 token0Amount,
        uint256 token1Amount,
        uint256 share
    );

    IERC20 immutable public token0;
    IERC20 immutable public token1;

    uint8 immutable private _decimals;

    uint256 constant private _ONE = 1e18;
    uint256 constant private _C1 = 0.9999e18;
    uint256 constant private _C2 = 3.382712334998325432e18;
    uint256 constant private _C3 = 0.456807350974663119e18;
    uint256 constant private _THRESHOLD = 1;
    uint256 constant private _LOWER_BOUND_NUMERATOR = 998;
    uint256 constant private _UPPER_BOUND_NUMERATOR = 1002;
    uint256 constant private _DENOMINATOR = 1000;

    constructor(
        IERC20 _token0,
        IERC20 _token1,
        string memory name,
        string memory symbol,
        uint8 decimals_
    )
        ERC20(name, symbol)
    {
        token0 = _token0;
        token1 = _token1;
        _decimals = decimals_;
        require(IERC20Metadata(address(_token0)).decimals() == decimals_, "token0 decimals mismatch");
        require(IERC20Metadata(address(_token1)).decimals() == decimals_, "token1 decimals mismatch");
    }

    function decimals() public view override returns(uint8) {
        return _decimals;
    }

    /**
     * @notice estimates return value of the swap
     * @param tokenFrom token that user wants to sell
     * @param tokenTo token that user wants to buy
     * @param inputAmount amount of `tokenFrom` that user wants to sell
     * @return outputAmount amount of `tokenTo` that user will receive after the trade
     *
     * @dev
     * `getReturn` at point `x = inputBalance / (inputBalance + outputBalance)`:
     * `getReturn(x) = 0.9999 + (0.5817091329374359 - x * 1.2734233188154198)^17`
     * When balance is changed from `inputBalance` to `inputBalance + amount` we should take
     * integral of getReturn to calculate proper amount:
     * `getReturn(x0, x1) = (integral (0.9999 + (0.5817091329374359 - x * 1.2734233188154198)^17) dx from x=x0 to x=x1) / (x1 - x0)`
     * `getReturn(x0, x1) = (0.9999 * x - 3.3827123349983306 * (x - 0.4568073509746632) ** 18 from x=x0 to x=x1) / (x1 - x0)`
     * `getReturn(x0, x1) = (0.9999 * (x1 - x0) + 3.3827123349983306 * ((x0 - 0.4568073509746632) ** 18 - (x1 - 0.4568073509746632) ** 18)) / (x1 - x0)`
     * C0 = 0.9999
     * C2 = 3.3827123349983306
     * C3 = 0.4568073509746632
     * `getReturn(x0, x1) = (C0 * (x1 - x0) + C2 * ((x0 - C3) ** 18 - (x1 - C3) ** 18)) / (x1 - x0)`
     */
    function getReturn(IERC20 tokenFrom, IERC20 tokenTo, uint256 inputAmount) public view returns(uint256 outputAmount) {
        require(inputAmount > 0, "Input amount should be > 0");
        uint256 fromBalance = tokenFrom.balanceOf(address(this));
        uint256 toBalance = tokenTo.balanceOf(address(this));
        // require is needed to be sure that _getReturn math won't overflow
        require(inputAmount <= toBalance, "Input amount is too big");
        outputAmount = _getReturn(fromBalance, toBalance, inputAmount);
    }

    /**
     * @notice makes a deposit of both tokens to the AMM
     * @param token0Amount amount of token0 to deposit
     * @param token1Amount amount of token1 to deposit
     * @param minShare minimal required amount of LP tokens received
     * @return share amount of LP tokens received
     */
    function deposit(uint256 token0Amount, uint256 token1Amount, uint256 minShare) external returns(uint256 share) {
        share = depositFor(token0Amount, token1Amount, msg.sender, minShare);
    }

    /**
     * @notice makes a deposit of both tokens to the AMM and transfers LP tokens to the specified address
     * @param token0Amount amount of token0 to deposit
     * @param token1Amount amount of token1 to deposit
     * @param to address that will receive tokens
     * @param minShare minimal required amount of LP tokens received
     * @return share amount of LP tokens received
     *
     * @dev fully balanced deposit happens when ratio of amounts of deposit matches ratio of balances.
     * To make a fair deposit when ratios do not match the contract finds the amount that is needed to swap to
     * equalize ratios and makes that swap virtually to capture the swap fees. Then final share is calculated from
     * fair deposit of virtual amounts.
     */
    function depositFor(uint256 token0Amount, uint256 token1Amount, address to, uint256 minShare) public returns(uint256 share) {
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));
        (uint256 token0VirtualAmount, uint256 token1VirtualAmount) = _getVirtualAmountsForDeposit(token0Amount, token1Amount, token0Balance, token1Balance);

        uint256 inputAmount = token0VirtualAmount + token1VirtualAmount;
        require(inputAmount > 0, "Empty deposit is not allowed");
        require(to != address(this), "Deposit to this is forbidden");
        // _mint also checks require(to != address(0))

        uint256 _totalSupply = totalSupply();
        if (_totalSupply > 0) {
            uint256 totalBalance = token0Balance + token1Balance + token0Amount + token1Amount - inputAmount;
            share = inputAmount * _totalSupply / totalBalance;
        } else {
            share = inputAmount;
        }

        require(share >= minShare, "Share is not enough");
        _mint(to, share);
        emit Deposit(to, token0Amount, token1Amount, share);

        if (token0Amount > 0) {
            token0.safeTransferFrom(msg.sender, address(this), token0Amount);
        }
        if (token1Amount > 0) {
            token1.safeTransferFrom(msg.sender, address(this), token1Amount);
        }
    }

    /**
     * @notice makes a proportional withdrawal of both tokens
     * @param amount amount of LP tokens to burn
     * @param minToken0Amount minimal required amount of token0
     * @param minToken1Amount minimal required amount of token1
     * @return token0Amount amount of token0 received
     * @return token1Amount amount of token1 received
     */
    function withdraw(uint256 amount, uint256 minToken0Amount, uint256 minToken1Amount) external returns(uint256 token0Amount, uint256 token1Amount) {
        (token0Amount, token1Amount) = withdrawFor(amount, msg.sender, minToken0Amount, minToken1Amount);
    }

    /**
     * @notice makes a proportional withdrawal of both tokens and transfers them to the specified address
     * @param amount amount of LP tokens to burn
     * @param to address that will receive tokens
     * @param minToken0Amount minimal required amount of token0
     * @param minToken1Amount minimal required amount of token1
     * @return token0Amount amount of token0 received
     * @return token1Amount amount of token1 received
     */
    function withdrawFor(uint256 amount, address to, uint256 minToken0Amount, uint256 minToken1Amount) public returns(uint256 token0Amount, uint256 token1Amount) {
        require(amount > 0, "Empty withdrawal is not allowed");
        require(to != address(this), "Withdrawal to this is forbidden");
        require(to != address(0), "Withdrawal to zero is forbidden");

        uint256 _totalSupply = totalSupply();
        _burn(msg.sender, amount);
        token0Amount = token0.balanceOf(address(this)) * amount / _totalSupply;
        token1Amount = token1.balanceOf(address(this)) * amount / _totalSupply;
        _handleWithdraw(to, amount, token0Amount, token1Amount, minToken0Amount, minToken1Amount);
    }

    /**
     * @notice makes a withdrawal with custom ratio
     * @param amount amount of LP tokens to burn
     * @param token0Share percentage of token0 to receive with 100% equals to 1e18
     * @param minToken0Amount minimal required amount of token0
     * @param minToken1Amount minimal required amount of token1
     * @return token0Amount amount of token0 received
     * @return token1Amount amount of token1 received
     */
    function withdrawWithRatio(uint256 amount, uint256 token0Share, uint256 minToken0Amount, uint256 minToken1Amount) external returns(uint256 token0Amount, uint256 token1Amount) {
        return withdrawForWithRatio(amount, msg.sender, token0Share, minToken0Amount, minToken1Amount);
    }

    /**
     * @notice makes a withdrawal with custom ratio and transfers tokens to the specified address
     * @param amount amount of LP tokens to burn
     * @param to address that will receive tokens
     * @param token0Share percentage of token0 to receive with 100% equals to 1e18
     * @param minToken0Amount minimal required amount of token0
     * @param minToken1Amount minimal required amount of token1
     * @return token0Amount amount of token0 received
     * @return token1Amount amount of token1 received
     *
     * @dev withdrawal with custom ratio is semantically equal to proportional withdrawal with extra swap afterwards to
     * get to the specified ratio. The contract does exactly this by making virtual proportional withdrawal and then
     * finds the amount needed for an extra virtual swap to achieve specified ratio.
     */
    function withdrawForWithRatio(uint256 amount, address to, uint256 token0Share, uint256 minToken0Amount, uint256 minToken1Amount) public returns(uint256 token0Amount, uint256 token1Amount) {
        require(amount > 0, "Empty withdrawal is not allowed");
        require(to != address(this), "Withdrawal to this is forbidden");
        require(to != address(0), "Withdrawal to zero is forbidden");
        require(token0Share <= _ONE, "Ratio should be in [0, 1]");

        uint256 _totalSupply = totalSupply();
        // burn happens before amounts calculations intentionally — to validate amount
        _burn(msg.sender, amount);
        (token0Amount, token1Amount) = _getRealAmountsForWithdraw(amount, token0Share, _totalSupply);
        _handleWithdraw(to, amount, token0Amount, token1Amount, minToken0Amount, minToken1Amount);
    }

    /**
     * @notice swaps token0 for token1
     * @param inputAmount amount of token0 to sell
     * @param minReturnAmount minimal required amount of token1 to buy
     * @return outputAmount amount of token1 bought
     */
    function swap0To1(uint256 inputAmount, uint256 minReturnAmount) external returns(uint256 outputAmount) {
        outputAmount = _swap(token0, token1, inputAmount, msg.sender, minReturnAmount);
        emit Swap(msg.sender, inputAmount.toInt256(), -outputAmount.toInt256());
    }

    /**
     * @notice swaps token1 for token0
     * @param inputAmount amount of token1 to sell
     * @param minReturnAmount minimal required amount of token0 to buy
     * @return outputAmount amount of token0 bought
     */
    function swap1To0(uint256 inputAmount, uint256 minReturnAmount) external returns(uint256 outputAmount) {
        outputAmount = _swap(token1, token0, inputAmount, msg.sender, minReturnAmount);
        emit Swap(msg.sender, -outputAmount.toInt256(), inputAmount.toInt256());
    }

    /**
     * @notice swaps token0 for token1 and transfers them to specified receiver address
     * @param inputAmount amount of token0 to sell
     * @param to address that will receive tokens
     * @param minReturnAmount minimal required amount of token1 to buy
     * @return outputAmount amount of token1 bought
     */
    function swap0To1For(uint256 inputAmount, address to, uint256 minReturnAmount) external returns(uint256 outputAmount) {
        require(to != address(this), "Swap to this is forbidden");
        require(to != address(0), "Swap to zero is forbidden");

        outputAmount = _swap(token0, token1, inputAmount, to, minReturnAmount);
        emit Swap(msg.sender, inputAmount.toInt256(), -outputAmount.toInt256());
    }

    /**
     * @notice swaps token1 for token0 and transfers them to specified receiver address
     * @param inputAmount amount of token1 to sell
     * @param to address that will receive tokens
     * @param minReturnAmount minimal required amount of token0 to buy
     * @return outputAmount amount of token0 bought
     */
    function swap1To0For(uint256 inputAmount, address to, uint256 minReturnAmount) external returns(uint256 outputAmount) {
        require(to != address(this), "Swap to this is forbidden");
        require(to != address(0), "Swap to zero is forbidden");

        outputAmount = _swap(token1, token0, inputAmount, to, minReturnAmount);
        emit Swap(msg.sender, -outputAmount.toInt256(), inputAmount.toInt256());
    }

    function _getVirtualAmountsForDeposit(uint256 token0Amount, uint256 token1Amount, uint256 token0Balance, uint256 token1Balance)
        private pure returns(uint256 token0VirtualAmount, uint256 token1VirtualAmount)
    {
        int256 shift = _checkVirtualAmountsFormula(token0Amount, token1Amount, token0Balance, token1Balance);
        if (shift > 0) {
            (token0VirtualAmount, token1VirtualAmount) = _getVirtualAmountsForDepositImpl(token0Amount, token1Amount, token0Balance, token1Balance);
        } else if (shift < 0) {
            (token1VirtualAmount, token0VirtualAmount) = _getVirtualAmountsForDepositImpl(token1Amount, token0Amount, token1Balance, token0Balance);
        } else {
            (token0VirtualAmount, token1VirtualAmount) = (token0Amount, token1Amount);
        }
    }

    function _getRealAmountsForWithdraw(uint256 amount, uint256 token0Share, uint256 _totalSupply) private view returns(uint256 token0RealAmount, uint256 token1RealAmount) {
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));
        uint256 token0VirtualAmount = token0Balance * amount / _totalSupply;
        uint256 token1VirtualAmount = token1Balance * amount / _totalSupply;

        uint256 currentToken0Share = token0VirtualAmount * _ONE / (token0VirtualAmount + token1VirtualAmount);
        if (token0Share < currentToken0Share) {
            (token0RealAmount, token1RealAmount) = _getRealAmountsForWithdrawImpl(token0VirtualAmount, token1VirtualAmount, token0Balance - token0VirtualAmount, token1Balance - token1VirtualAmount, token0Share);
        } else if (token0Share > currentToken0Share) {
            (token1RealAmount, token0RealAmount) = _getRealAmountsForWithdrawImpl(token1VirtualAmount, token0VirtualAmount, token1Balance - token1VirtualAmount, token0Balance - token0VirtualAmount, _ONE - token0Share);
        } else {
            (token0RealAmount, token1RealAmount) = (token0VirtualAmount, token1VirtualAmount);
        }
    }

    function _getReturn(uint256 fromBalance, uint256 toBalance, uint256 inputAmount) private pure returns(uint256 outputAmount) {
        unchecked {
            uint256 totalBalance = fromBalance + toBalance;
            uint256 x0 = _ONE * fromBalance / totalBalance;
            uint256 x1 = _ONE * (fromBalance + inputAmount) / totalBalance;
            uint256 scaledInputAmount = _ONE * inputAmount;
            uint256 amountMultiplier = (
                _C1 * scaledInputAmount / totalBalance +
                _C2 * _powerHelper(x0) -
                _C2 * _powerHelper(x1)
            ) * totalBalance / scaledInputAmount;
            outputAmount = inputAmount * Math.min(amountMultiplier, _ONE) / _ONE;
        }
    }

    function _handleWithdraw(address to, uint256 amount, uint256 token0Amount, uint256 token1Amount, uint256 minToken0Amount, uint256 minToken1Amount) private {
        require(token0Amount >= minToken0Amount, "Min token0Amount is not reached");
        require(token1Amount >= minToken1Amount, "Min token1Amount is not reached");

        emit Withdrawal(msg.sender, token0Amount, token1Amount, amount);
        if (token0Amount > 0) {
            token0.safeTransfer(to, token0Amount);
        }
        if (token1Amount > 0) {
            token1.safeTransfer(to, token1Amount);
        }
    }

    function _swap(IERC20 tokenFrom, IERC20 tokenTo, uint256 inputAmount, address to, uint256 minReturnAmount) private returns(uint256 outputAmount) {
        outputAmount = getReturn(tokenFrom, tokenTo, inputAmount);
        require(outputAmount > 0, "Empty swap is not allowed");
        require(outputAmount >= minReturnAmount, "Min return not reached");
        tokenFrom.safeTransferFrom(msg.sender, address(this), inputAmount);
        tokenTo.safeTransfer(to, outputAmount);
    }

    /**
     * @dev We utilize binary search to find proper to swap
     *
     * Inital approximation of dx is taken from the same equation by assuming dx ~ dy
     *
     * x - dx     xBalance + dx
     * ------  =  ------------
     * y + dx     yBalance - dx
     *
     * dx = (x * yBalance - xBalance * y) / (xBalance + yBalance + x + y)
     */
    function _getVirtualAmountsForDepositImpl(uint256 x, uint256 y, uint256 xBalance, uint256 yBalance) private pure returns(uint256, uint256) {
        uint256 dx = (x * yBalance - y * xBalance) / (xBalance + yBalance + x + y);
        if (dx == 0) {
            return (x, y);
        }
        uint256 dy;
        uint256 left = dx * _LOWER_BOUND_NUMERATOR / _DENOMINATOR;
        uint256 right = Math.min(Math.min(dx * _UPPER_BOUND_NUMERATOR / _DENOMINATOR, yBalance), x);

        while (left + _THRESHOLD < right) {
            dy = _getReturn(xBalance, yBalance, dx);
            int256 shift = _checkVirtualAmountsFormula(x - dx, y + dy, xBalance + dx, yBalance - dy);
            if (shift > 0) {
                left = dx;
                dx = (dx + right) / 2;
            } else if (shift < 0) {
                right = dx;
                dx = (left + dx) / 2;
            } else {
                break;
            }
        }

        return (x - dx, y + dy);
    }

    /**
     * @dev We utilize binary search to find proper amount to swap
     *
     * Inital approximation of dx is taken from the same equation by assuming dx ~ dy
     *
     * x - dx        firstTokenShare
     * ------  =  ----------------------
     * y + dx     _ONE - firstTokenShare
     *
     * dx = (x * (_ONE - firstTokenShare) - y * firstTokenShare) / _ONE
     */
    function _getRealAmountsForWithdrawImpl(uint256 virtualX, uint256 virtualY, uint256 balanceX, uint256 balanceY, uint256 firstTokenShare) private pure returns(uint256, uint256) {
        require(balanceX != 0 || balanceY != 0, "Amount exceeds total balance");
        if (firstTokenShare == 0) {
            return (0, virtualY + _getReturn(balanceX, balanceY, virtualX));
        }

        uint256 secondTokenShare = _ONE - firstTokenShare;
        uint256 dx = (virtualX * secondTokenShare - virtualY * firstTokenShare) / _ONE;
        uint256 dy;
        uint256 left = dx * _LOWER_BOUND_NUMERATOR / _DENOMINATOR;
        uint256 right = Math.min(dx * _UPPER_BOUND_NUMERATOR / _DENOMINATOR, virtualX);

        while (left + _THRESHOLD < right) {
            dy = _getReturn(balanceX, balanceY, dx);
            int256 shift = _checkVirtualAmountsFormula(virtualX - dx, virtualY + dy, firstTokenShare, secondTokenShare);
            if (shift > 0) {
                left = dx;
                dx = (dx + right) / 2;
            } else if (shift < 0) {
                right = dx;
                dx = (left + dx) / 2;
            } else {
                break;
            }
        }

        return (virtualX - dx, virtualY + dy);
    }

    /**
     * @dev
     *
     * Equilibrium is when ratio of amounts equals to ratio of balances
     *
     *  x      xBalance
     * --- == ----------
     *  y      yBalance
     *
     */
    function _checkVirtualAmountsFormula(uint256 x, uint256 y, uint256 xBalance, uint256 yBalance) private pure returns(int256) {
        unchecked {
            return int256(x * yBalance - y * xBalance);
        }
    }

    function _powerHelper(uint256 x) private pure returns(uint256 p) {
        unchecked {
            if (x > _C3) {
                p = x - _C3;
            } else {
                p = _C3 - x;
            }
            p = p * p / _ONE;  // p ^ 2
            uint256 pp = p * p / _ONE;  // p ^ 4
            pp = pp * pp / _ONE;  // p ^ 8
            pp = pp * pp / _ONE;  // p ^ 16
            p = p * pp / _ONE;  // p ^ 18
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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