//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LiquidityResolver {
    using SafeMath for uint;

    ILiquidity internal constant liquidity = ILiquidity(0xAFA64764FE83E6796df18De44b739074D68Fd715);

    struct TokenInfo {
        address token;
        uint256 supplyExchangePrice;
        uint256 borrowExchangePrice;
        uint256 totalRawSupply;
        uint256 totalSupply;
        uint256 totalRawBorrow;
        uint256 totalBorrow;
        ProtocolTokenInfo[] protocolTokenInfos;
    }

    struct ProtocolTokenInfo {
        address protocol;
        bool isProtocol;
        uint256 protocolTokenRawSupply;
        uint256 protocolTokenSupply;
        uint256 protocolTokenRawBorrow;
        uint256 protocolTokenBorrow;
        uint256 protocolTokenRawSupplyLimit;
        uint256 protocolTokenSupplyLimit;
        uint256 protocolTokenRawBorrowLimit;
        uint256 protocolTokenBorrowLimit;
    }

    function getInfo(address[] memory protocols_, address[] memory tokens_) public view returns (TokenInfo[] memory tokenInfos_) {
        tokenInfos_ = new TokenInfo[](tokens_.length);
        for(uint256 i = 0; i < tokens_.length; i++) {
            tokenInfos_[i].token = tokens_[i];
            (tokenInfos_[i].supplyExchangePrice, tokenInfos_[i].borrowExchangePrice) = liquidity.updateInterest(tokens_[i]);

            tokenInfos_[i].totalRawSupply = liquidity.totalSupplyRaw(tokens_[i]);
            tokenInfos_[i].totalSupply = tokenInfos_[i].totalRawSupply.mul(tokenInfos_[i].supplyExchangePrice).div(1e18);

            tokenInfos_[i].totalRawBorrow = liquidity.totalBorrowRaw(tokens_[i]);
            tokenInfos_[i].totalBorrow = tokenInfos_[i].totalRawBorrow.mul(tokenInfos_[i].borrowExchangePrice).div(1e18);

            tokenInfos_[i].protocolTokenInfos = new ProtocolTokenInfo[](protocols_.length);
            for(uint256 j = 0; j < protocols_.length; j++) {
                tokenInfos_[i].protocolTokenInfos[j].protocol = protocols_[j];
                tokenInfos_[i].protocolTokenInfos[j].isProtocol = liquidity.isProtocol(protocols_[j]);

                if (tokenInfos_[i].protocolTokenInfos[j].isProtocol) {
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawSupply = liquidity.protocolRawSupply(protocols_[j], tokens_[i]);
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenSupply = tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawSupply.mul(tokenInfos_[i].supplyExchangePrice).div(1e18);

                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawBorrow = liquidity.protocolRawBorrow(protocols_[j], tokens_[i]);
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenBorrow = tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawBorrow.mul(tokenInfos_[i].borrowExchangePrice).div(1e18);

                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawSupplyLimit = liquidity.protocolSupplyLimit(protocols_[j], tokens_[i]);
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenSupplyLimit = tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawSupplyLimit.mul(tokenInfos_[i].supplyExchangePrice).div(1e18);
        
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawBorrowLimit = liquidity.protocolBorrowLimit(protocols_[j], tokens_[i]);
                    tokenInfos_[i].protocolTokenInfos[j].protocolTokenBorrowLimit = tokenInfos_[i].protocolTokenInfos[j].protocolTokenRawBorrowLimit.mul(tokenInfos_[i].borrowExchangePrice).div(1e18);
                }
            }
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