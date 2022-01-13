//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./helpers.sol";

contract Protocol3Resolver is Helpers {
    using SafeMath for uint;

    struct BorrowLimit {
        uint128 normal;
        uint128 extended;
    }

    struct PoolInfo {
        bool isEnabled;
        BorrowLimit borrowLimit;
        address[] markets;
        uint256 minTick;
        uint256 priceSlippage;
        TickCheck tickCheck;
    }

    struct Position {
        address pool;
        address[] tokens;
        uint256[2] collateralsWithoutFeeAccrued;
        uint256[2] collaterals;
        uint256[] debts;
        bool isStaked;
        BorrowLimit borrowLimit;
        uint256 status;
        uint256 normalizedStatus;
    }

    function getPoolInfo(address[] calldata pools) public view returns (PoolInfo[] memory poolInfos) {
        uint256 length_ = pools.length;
        poolInfos = new PoolInfo[](length_);
        for(uint i = 0; i < length_; i++) {
            poolInfos[i].isEnabled = protocolModule.poolEnabled(pools[i]);
            if (poolInfos[i].isEnabled) {
                (poolInfos[i].borrowLimit.normal, poolInfos[i].borrowLimit.extended) = protocolModule.borrowLimit(pools[i]);
                poolInfos[i].markets = protocolModule.poolMarkets(pools[i]);
                poolInfos[i].minTick = protocolModule.minTick(pools[i]);
                poolInfos[i].priceSlippage = protocolModule.priceSlippage(pools[i]);
                poolInfos[i].tickCheck = protocolModule.tickCheck(pools[i]);
            }
        }
    }

    function getPositionInfo(uint256[] memory NFTIDs) public view returns (Position[] memory positions) {
        positions = new Position[](NFTIDs.length);
        for(uint256 i = 0; i < NFTIDs.length; i++) {
            positions[i].pool = getPoolAddress(NFTIDs[i]);
            positions[i].tokens = protocolModule.poolMarkets(positions[i].pool);
            (
                positions[i].collateralsWithoutFeeAccrued[0],
                positions[i].collaterals[0],
                positions[i].collateralsWithoutFeeAccrued[1],
                positions[i].collaterals[1]
            ) = getCollaterals(NFTIDs[i], positions[i].pool);
            positions[i].debts = protocolModule.getNetNFTDebt(NFTIDs[i], positions[i].pool);
            positions[i].isStaked = protocolModule.isStaked(NFTIDs[i]);
            (positions[i].borrowLimit.normal, positions[i].borrowLimit.extended) = protocolModule.borrowLimit(positions[i].pool);
            (positions[i].status, positions[i].normalizedStatus) = getStatus(NFTIDs[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Helpers {
    using SafeMath for uint;

    IProtocolModule internal constant protocolModule = IProtocolModule(0x5f76E4BFf40C6d4c656AcFee4FFd41c717b5115f);
    ILiquidity internal constant liquidity = ILiquidity(0xb5C272b5D0D0E3Bd3f20f32d3836e7Ce4e9Cfbdf);
    INonfungiblePositionManager public constant nftManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function getPoolAddress(uint256 NFTID) internal view returns (address poolAddr) {
        (address token0, address token1, uint24 fee) = protocolModule.getNftTokenPairAddresses(NFTID);
        poolAddr = protocolModule.getPoolAddress(token0, token1, fee);
    }

    function getNFTdata(uint256 NFTID) internal view returns (int24 tickLower, int24 tickUpper, uint128 liquidity_) {
        (,,,,,
            tickLower,
            tickUpper,
            liquidity_,
            ,,,) = nftManager.positions(NFTID);
    }

    function getCollateralsWithoutFee(uint256 NFTID, address pool) internal view returns (uint256 amount0WithoutFeeAccrued, uint256 amount1WithoutFeeAccrued) {
        (int24 tickLower_, int24 tickUpper_, uint128 liquidity_) = getNFTdata(NFTID);
        (amount0WithoutFeeAccrued, amount1WithoutFeeAccrued) = protocolModule.getNetNFTLiquidity(pool, tickLower_, tickUpper_, liquidity_);
    }

    function getCollaterals(uint256 NFTID, address pool) internal view returns (uint256 amount0WithoutFeeAccrued, uint256 amount0, uint256 amount1WithoutFeeAccrued, uint256 amount1) {
        (uint256 fee0, uint256 fee1) = protocolModule.getFeeAccruedWrapper(NFTID, pool);
        (amount0WithoutFeeAccrued, amount1WithoutFeeAccrued) = getCollateralsWithoutFee(NFTID, pool);
        amount0 = amount0WithoutFeeAccrued.add(fee0);
        amount1 = amount1WithoutFeeAccrued.add(fee1);
    }

    function getStatus(uint256 NFTID) internal view returns (uint256 status, uint256 normalizedStatus) {
        (
            ,
            ,
            ,
            ,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalizedSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalizedBorrowInUsd_
        ) = protocolModule.getOverallPosition(NFTID);
        status = totalSupplyInUsd_.div(totalBorrowInUsd_).mul(1e18);
        normalizedStatus = totalNormalizedSupplyInUsd_.div(totalNormalizedBorrowInUsd_).mul(1e18);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../../liquidity/interfaces.sol";

struct TickCheck {
    uint24 tickSlippage1;
    uint24 secsAgo1;
    uint24 tickSlippage2;
    uint24 secsAgo2;
    uint24 tickSlippage3;
    uint24 secsAgo3;
    uint24 tickSlippage4;
    uint24 secsAgo4;
    uint24 tickSlippage5;
    uint24 secsAgo5;
}

interface IProtocolModule {

    function getPoolAddress(address, address, uint24) external view returns (address);

    function getNftTokenPairAddresses(uint256) external view returns (address, address, uint24);

    function getFeeAccruedWrapper(uint256, address) external view returns (uint256, uint256);

    function getNetNFTLiquidity(address, int24, int24, uint128) external view returns (uint256, uint256);

    function getNetNFTDebt(uint256, address) external view returns (uint256[] memory);

    function getOverallPosition(uint256 NFTID_)
        external
        view
        returns (
            address poolAddr_,
            address token0_,
            address token1_,
            uint128 liquidity_,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalBorrowInUsd_
        );

    function poolEnabled(address) external view returns (bool);

    // Return true if the NFT is deposited and the owner is the owner_
    function position(address, uint) external view returns (bool);

    function isStaked(uint) external view returns (bool);

    function minTick(address) external view returns (uint);

    function borrowBalRaw(uint, address) external view returns (uint);

    function borrowAllowed(address, address) external view returns (bool);

    function poolMarkets(address) external view returns (address[] memory);

    function borrowLimit(address) external view returns (uint128, uint128);

    function priceSlippage(address) external view returns (uint);

    function tickCheck(address) external view returns (TickCheck memory);
    
}

interface INonfungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
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