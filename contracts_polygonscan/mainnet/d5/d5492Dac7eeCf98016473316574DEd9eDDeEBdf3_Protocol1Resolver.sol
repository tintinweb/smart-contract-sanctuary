//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Protocol1Resolver {
    using SafeMath for uint;

    IProtocolModule internal constant protocolModule = IProtocolModule(0x67c22EA335ABDb7B9a687C8006559e589173188d);
    ILiquidity internal constant liquidity = ILiquidity(0xAFA64764FE83E6796df18De44b739074D68Fd715);
    
    struct ITokenInfo {
        address token;
        address itoken;
        string name;
        string symbol;
        uint256 decimals;
        uint256 exchangePrice;
    }

    struct RewardInfos {
        address[] rewardTokens;
        uint256[] rewardAmounts;
    }

    struct PositionInfo {
        address token;
        uint256 amount;
        uint256 iTokenAmount;
        RewardInfos rewardInfos;
    }

    function getITokenDetails() public view returns (ITokenInfo[] memory iTokens_) {
        address[] memory markets_ = protocolModule.markets();
        iTokens_ = new ITokenInfo[](markets_.length);
        for(uint i = 0; i < markets_.length; i++) {
            iTokens_[i].token = markets_[i];
            iTokens_[i].itoken = protocolModule.tokenToItoken(markets_[i]);
            TokenInterface iToken = TokenInterface(iTokens_[i].token);
            iTokens_[i].name = iToken.name();
            iTokens_[i].symbol = iToken.symbol();
            iTokens_[i].decimals = iToken.decimals();
            (iTokens_[i].exchangePrice,) = liquidity.updateInterest(markets_[i]);
        }
    }

    function getUserInfo(address user) public returns (PositionInfo[] memory positions_, ITokenInfo[] memory iTokens_) {
        iTokens_ = getITokenDetails();
        positions_ = new PositionInfo[](iTokens_.length);
        for(uint i = 0; i < iTokens_.length; i++) {
            TokenInterface iToken_ = TokenInterface(iTokens_[i].itoken);
            positions_[i].iTokenAmount = iToken_.balanceOf(user);
            positions_[i].amount = positions_[i].iTokenAmount.mul(iTokens_[i].exchangePrice).div(1e18);
            positions_[i].token = iTokens_[i].token;
            positions_[i].rewardInfos.rewardTokens = protocolModule.rewardTokens(iTokens_[i].token);
            positions_[i].rewardInfos.rewardAmounts = protocolModule.updateUserReward(user, iTokens_[i].token);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../liquidity/interfaces.sol";

interface IProtocolModule {

    function updateUserReward(address user_, address token_) external returns (uint[] memory);

    function tokenEnabled(address token_) external view returns (bool);

    function markets() external view returns (address[] memory);

    function marketsLength() external view returns (uint256 length_);

    function tokenToItoken(address token_) external view returns (address);

    function itokenToToken(address itoken_) external view returns (address);

    function rates(address token_)
        external
        view
        returns (uint64 supplyRate_, uint64 lastUpdateTime_);

    function exchangePrice(address token_) external view returns (uint256);

    function rewardTokens(address token_)
        external
        view
        returns (address[] memory);

    function rewardRate(address token_, address rewardToken_)
        external
        view
        returns (uint256);

    function rewardPrice(address token_, address rewardToken_)
        external
        view
        returns (uint256 rewardPrice_, uint256 lastUpdateTime_);

    function userRewards(
        address user_,
        address token_,
        address rewardToken_
    ) external view returns (uint256 lastRewardPrice_, uint256 reward_);
    
}

interface TokenInterface {

    function name() external view returns (string memory name_);

    function symbol() external view returns (string memory symbol_);

    function decimals() external view returns (uint256 decimals_);

    function balanceOf(address user_) external view returns (uint256 balance_);
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


interface ILiquidity {

    function supply(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function withdraw(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function borrow(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function payback(
        address token_,
        uint amount_
    ) external returns (
        uint newSupplyRate_,
        uint newBorrowRate_,
        uint newSupplyExchangePrice_,
        uint newBorrowExchangePrice_
    );

    function updateInterest(
        address token_
    ) external view returns (
        uint newSupplyExchangePrice,
        uint newBorrowExchangePrice
    );

    function isProtocol(address protocol_) external view returns (bool);

    function protocolSupplyLimit(address protocol_, address token_) external view returns (uint256);

    function protocolBorrowLimit(address protocol_, address token_) external view returns (uint256);

    function totalSupplyRaw(address token_) external view returns (uint256);

    function totalBorrowRaw(address token_) external view returns (uint256);

    function protocolRawSupply(address protocol_, address token_) external view returns (uint256);

    function protocolRawBorrow(address protocol_, address token_) external view returns (uint256);

    struct Rates {
        uint96 lastSupplyExchangePrice; // last stored exchange price. Increases overtime.
        uint96 lastBorrowExchangePrice; // last stored exchange price. Increases overtime.
        uint48 lastUpdateTime; // in sec
        uint16 utilization; // utilization. 10000 = 100%
    }

    function rate(address token_) external view returns (Rates memory);

}