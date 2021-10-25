// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "ISett.sol";
import "IGeyser.sol";
import "IUniswapV2Pair.sol";
import "ICToken.sol";

import "SafeMath.sol";

contract DiggVotingShare {
    using SafeMath for uint256;

    IERC20 constant digg = IERC20(0x798D1bE841a82a273720CE31c822C61a67a601C3);
    ISett constant sett_digg =
        ISett(0x7e7E112A68d8D2E221E11047a72fFC1065c38e1a);

    //Digg is token1
    IUniswapV2Pair constant digg_wBTC_UniV2 =
        IUniswapV2Pair(0xE86204c4eDDd2f70eE00EAd6805f917671F56c52);
    ISett constant sett_digg_wBTC_UniV2 =
        ISett(0xC17078FDd324CC473F8175Dc5290fae5f2E84714);
    IGeyser constant geyser_digg_wBTC_UniV2 =
        IGeyser(0x0194B5fe9aB7e0C43a08aCbb771516fc057402e7);

    //Digg is token1
    IUniswapV2Pair constant digg_wBTC_SLP =
        IUniswapV2Pair(0x9a13867048e01c663ce8Ce2fE0cDAE69Ff9F35E3);
    ISett constant sett_digg_wBTC_SLP =
        ISett(0x88128580ACdD9c04Ce47AFcE196875747bF2A9f6);
    IGeyser constant geyser_digg_wBTC_SLP =
        IGeyser(0x7F6FE274e172AC7d096A7b214c78584D99ca988B);

    // Rari pool - fDIGG-22
    ICToken constant fDIGG =
        ICToken(0x792a676dD661E2c182435aaEfC806F1d4abdC486);

    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "Digg Voting Share";
    }

    function symbol() external pure returns (string memory) {
        return "Digg VS";
    }

    function totalSupply() external view returns (uint256) {
        return digg.totalSupply();
    }

    function uniswapBalanceOf(address _voter) external view returns(uint256) {
        return _uniswapBalanceOf(_voter);
    }
    function sushiswapBalanceOf(address _voter) external view returns(uint256) {
        return _sushiswapBalanceOf(_voter);
    }
    function diggBalanceOf(address _voter) external view returns(uint256) {
        return _diggBalanceOf(_voter);
    }
    function rariBalanceOf(address _voter) external view returns(uint256) {
        return _rariBalanceOf(_voter);
    }

    /*
        The voter can have Digg in Uniswap in 3 configurations:
         * Staked bUni-V2 in Geyser
         * Unstaked bUni-V2 (same as staked Uni-V2 in Sett)
         * Unstaked Uni-V2
        The top two correspond to more than 1 Uni-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much DIGG it corresponds to using the pool's reserves.
    */
    function _uniswapBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bUniV2PricePerShare = sett_digg_wBTC_UniV2
            .getPricePerFullShare();
        (, uint112 reserve1, ) = digg_wBTC_UniV2.getReserves();
        uint256 totalUniBalance = digg_wBTC_UniV2.balanceOf(_voter) +
            (sett_digg_wBTC_UniV2.balanceOf(_voter) * bUniV2PricePerShare) /
            1e18 +
            (geyser_digg_wBTC_UniV2.totalStakedFor(_voter) *
                bUniV2PricePerShare) /
            1e18;
        return (totalUniBalance * reserve1) / digg_wBTC_UniV2.totalSupply();
    }

    /*
        The voter can have Digg in Sushiswap in 3 configurations:
         * Staked bSushi-V2 in Geyser
         * Unstaked bSushi-V2 (same as staked Sushi-V2 in Sett)
         * Unstaked Sushi-V2
        The top two correspond to more than 1 Sushi-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much DIGG it corresponds to using the pool's reserves.
    */
    function _sushiswapBalanceOf(address _voter)
        internal
        view
        returns (uint256)
    {
        uint256 bSLPPricePerShare = sett_digg_wBTC_SLP.getPricePerFullShare();
        (, uint112 reserve1, ) = digg_wBTC_SLP.getReserves();
        uint256 totalSLPBalance = digg_wBTC_SLP.balanceOf(_voter) +
            (sett_digg_wBTC_SLP.balanceOf(_voter) * bSLPPricePerShare) /
            1e18 +
            (geyser_digg_wBTC_SLP.totalStakedFor(_voter) *
                bSLPPricePerShare) /
            1e18;
        return (totalSLPBalance * reserve1) / digg_wBTC_SLP.totalSupply();
    }

    /*
        The voter can have regular Digg in 2 configurations (There is no Digg or bDigg geyser):
         * Unstaked bDigg (same as staked Digg in Sett)
         * Unstaked Digg
    */
    function _diggBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bDiggPricePerShare = sett_digg.balance().mul(1e18).div(sett_digg.totalSupply());
        return
            digg.balanceOf(_voter) +
            (sett_digg.balanceOf(_voter) * bDiggPricePerShare) /
            1e18;
    }

    /*
        The voter may have deposited DIGG into the rari pool:
         * check current rate
         * balanceOf fDigg
    */
    function _rariBalanceOf(address _voter) internal view returns (uint256) {
        uint256 rate = fDIGG.exchangeRateStored();
        return (fDIGG.balanceOf(_voter) * rate) / 1e18;
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return
            _diggBalanceOf(_voter) +
            _uniswapBalanceOf(_voter) +
            _sushiswapBalanceOf(_voter) +
            _rariBalanceOf(_voter);
    }

    constructor() {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISett {
    function totalSupply() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeyser {
    function totalStakedFor(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);
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