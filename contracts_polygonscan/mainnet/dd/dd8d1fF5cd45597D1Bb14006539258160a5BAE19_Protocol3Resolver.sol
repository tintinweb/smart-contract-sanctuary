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

    function getPoolInfo(address[] calldata pools_) public view returns (PoolInfo[] memory poolInfos_) {
        uint256 length_ = pools_.length;
        poolInfos_ = new PoolInfo[](length_);
        for(uint i = 0; i < length_; i++) {
            poolInfos_[i].isEnabled = protocolModule.poolEnabled(pools_[i]);
            if (poolInfos_[i].isEnabled) {
                (poolInfos_[i].borrowLimit.normal, poolInfos_[i].borrowLimit.extended) = protocolModule.borrowLimit(pools_[i]);
                poolInfos_[i].markets = protocolModule.poolMarkets(pools_[i]);
                poolInfos_[i].minTick = protocolModule.minTick(pools_[i]);
                poolInfos_[i].priceSlippage = protocolModule.priceSlippage(pools_[i]);
                poolInfos_[i].tickCheck = protocolModule.tickCheck(pools_[i]);
            }
        }
    }

    function getPositionInfo(uint256[] memory NFTIDs_) public view returns (Position[] memory positions_) {
        positions_ = new Position[](NFTIDs_.length);
        for(uint256 i = 0; i < NFTIDs_.length; i++) {
            positions_[i].pool = getPoolAddress(NFTIDs_[i]);
            positions_[i].tokens = protocolModule.poolMarkets(positions_[i].pool);
            (
                positions_[i].collateralsWithoutFeeAccrued[0],
                positions_[i].collaterals[0],
                positions_[i].collateralsWithoutFeeAccrued[1],
                positions_[i].collaterals[1]
            ) = getCollaterals(NFTIDs_[i], positions_[i].pool);
            positions_[i].debts = protocolModule.getNetNFTDebt(NFTIDs_[i], positions_[i].pool);
            positions_[i].isStaked = protocolModule.isStaked(NFTIDs_[i]);
            (positions_[i].borrowLimit.normal, positions_[i].borrowLimit.extended) = protocolModule.borrowLimit(positions_[i].pool);
            (positions_[i].status, positions_[i].normalizedStatus) = getStatus(NFTIDs_[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


import "./interfaces.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Constants {

    IProtocolModule internal constant protocolModule = IProtocolModule(0x78c90DB55296b8338A09D31BFdcaE1E6DB16A134);
    ILiquidity internal constant liquidity = ILiquidity(0xAFA64764FE83E6796df18De44b739074D68Fd715);
    INonfungiblePositionManager public constant nftManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

}

contract UniswapHelpers is Constants {

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function computeAddress(address factory_, PoolKey memory key_)
        internal
        pure
        returns (address pool_)
    {
        require(key_.token0 < key_.token1);
        pool_ = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory_,
                            keccak256(
                                abi.encode(key_.token0, key_.token1, key_.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev returns pool address.
     * @param token0_ token 0 address
     * @param token1_ token 1 address
     * @param fee_ fee of pool
     * @return poolAddr_ pool address
     */
    function _getPoolAddress(
        address token0_,
        address token1_,
        uint24 fee_
    ) internal view returns (address poolAddr_) {
        poolAddr_ = computeAddress(
            nftManager.factory(),
            PoolKey({token0: token0_, token1: token1_, fee: fee_})
        );
    }

}


contract Helpers is UniswapHelpers {
    using SafeMath for uint;

    function getPoolAddress(uint256 NFTID_) internal view returns (address poolAddr_) {
        (
            ,
            ,
            address token0_,
            address token1_,
            uint24 fee_,
            ,
            ,
            ,
            ,
            ,
            ,
        ) = nftManager.positions(NFTID_);
        poolAddr_ = _getPoolAddress(token0_, token1_, fee_);
    }

    function getNFTdata(uint256 NFTID_) internal view returns (int24 tickLower_, int24 tickUpper_, uint128 liquidity_) {
        (,,,,,
            tickLower_,
            tickUpper_,
            liquidity_,
            ,,,) = nftManager.positions(NFTID_);
    }

    function getCollateralsWithoutFee(uint256 NFTID_, address pool_) internal view returns (uint256 amount0WithoutFeeAccrued_, uint256 amount1WithoutFeeAccrued_) {
        (int24 tickLower_, int24 tickUpper_, uint128 liquidity_) = getNFTdata(NFTID_);
        (amount0WithoutFeeAccrued_, amount1WithoutFeeAccrued_) = protocolModule.getNetNFTLiquidity(pool_, tickLower_, tickUpper_, liquidity_);
    }

    function getCollaterals(uint256 NFTID_, address pool_) internal view returns (uint256 amount0WithoutFeeAccrued_, uint256 amount0_, uint256 amount1WithoutFeeAccrued_, uint256 amount1_) {
        (uint256 fee0_, uint256 fee1_) = protocolModule.getFeeAccruedWrapper(NFTID_, pool_);
        (amount0WithoutFeeAccrued_, amount1WithoutFeeAccrued_) = getCollateralsWithoutFee(NFTID_, pool_);
        amount0_ = amount0WithoutFeeAccrued_.add(fee0_);
        amount1_ = amount1WithoutFeeAccrued_.add(fee1_);
    }

    function getStatus(uint256 NFTID_) internal view returns (uint256 status_, uint256 normalizedStatus_) {
        (
            ,
            ,
            ,
            ,
            uint256 totalSupplyInUsd_,
            uint256 totalNormalizedSupplyInUsd_,
            uint256 totalBorrowInUsd_,
            uint256 totalNormalizedBorrowInUsd_
        ) = protocolModule.getOverallPosition(NFTID_);
        status_ = totalSupplyInUsd_.div(totalBorrowInUsd_).mul(1e18);
        normalizedStatus_ = totalNormalizedSupplyInUsd_.div(totalNormalizedBorrowInUsd_).mul(1e18);
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
    function positions(uint256 tokenId_)
        external
        view
        returns (
            uint96 nonce_,
            address operator_,
            address token0_,
            address token1_,
            uint24 fee_,
            int24 tickLower_,
            int24 tickUpper_,
            uint128 liquidity_,
            uint256 feeGrowthInside0LastX128_,
            uint256 feeGrowthInside1LastX128_,
            uint128 tokensOwed0_,
            uint128 tokensOwed1_
        );
    
    function factory() external view returns (address);
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