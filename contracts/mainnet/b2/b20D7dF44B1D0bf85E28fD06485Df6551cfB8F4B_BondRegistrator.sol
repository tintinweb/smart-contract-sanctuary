/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

// File: contracts/BondToken_and_GDOTC/util/TransferETHInterface.sol




interface TransferETHInterface {
    receive() external payable;

    event LogTransferETH(address indexed from, address indexed to, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol





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

// File: contracts/BondToken_and_GDOTC/bondToken/BondTokenInterface.sol






interface BondTokenInterface is IERC20 {
    event LogExpire(uint128 rateNumerator, uint128 rateDenominator, bool firstTime);

    function mint(address account, uint256 amount) external returns (bool success);

    function expire(uint128 rateNumerator, uint128 rateDenominator)
        external
        returns (bool firstTime);

    function simpleBurn(address account, uint256 amount) external returns (bool success);

    function burn(uint256 amount) external returns (bool success);

    function burnAll() external returns (uint256 amount);

    function getRate() external view returns (uint128 rateNumerator, uint128 rateDenominator);
}

// File: contracts/BondToken_and_GDOTC/oracle/LatestPriceOracleInterface.sol




/**
 * @dev Interface of the price oracle.
 */
interface LatestPriceOracleInterface {
    /**
     * @dev Returns `true`if oracle is working.
     */
    function isWorking() external returns (bool);

    /**
     * @dev Returns the last updated price. Decimals is 8.
     **/
    function latestPrice() external returns (uint256);

    /**
     * @dev Returns the timestamp of the last updated price.
     */
    function latestTimestamp() external returns (uint256);
}

// File: contracts/BondToken_and_GDOTC/oracle/PriceOracleInterface.sol





/**
 * @dev Interface of the price oracle.
 */
interface PriceOracleInterface is LatestPriceOracleInterface {
    /**
     * @dev Returns the latest id. The id start from 1 and increments by 1.
     */
    function latestId() external returns (uint256);

    /**
     * @dev Returns the historical price specified by `id`. Decimals is 8.
     */
    function getPrice(uint256 id) external returns (uint256);

    /**
     * @dev Returns the timestamp of historical price specified by `id`.
     */
    function getTimestamp(uint256 id) external returns (uint256);
}

// File: contracts/BondToken_and_GDOTC/bondMaker/BondMakerInterface.sol






interface BondMakerInterface {
    event LogNewBond(
        bytes32 indexed bondID,
        address indexed bondTokenAddress,
        uint256 indexed maturity,
        bytes32 fnMapID
    );

    event LogNewBondGroup(
        uint256 indexed bondGroupID,
        uint256 indexed maturity,
        uint64 indexed sbtStrikePrice,
        bytes32[] bondIDs
    );

    event LogIssueNewBonds(uint256 indexed bondGroupID, address indexed issuer, uint256 amount);

    event LogReverseBondGroupToCollateral(
        uint256 indexed bondGroupID,
        address indexed owner,
        uint256 amount
    );

    event LogExchangeEquivalentBonds(
        address indexed owner,
        uint256 indexed inputBondGroupID,
        uint256 indexed outputBondGroupID,
        uint256 amount
    );

    event LogLiquidateBond(bytes32 indexed bondID, uint128 rateNumerator, uint128 rateDenominator);

    function registerNewBond(uint256 maturity, bytes calldata fnMap)
        external
        returns (
            bytes32 bondID,
            address bondTokenAddress,
            bytes32 fnMapID
        );

    function registerNewBondGroup(bytes32[] calldata bondIDList, uint256 maturity)
        external
        returns (uint256 bondGroupID);

    function reverseBondGroupToCollateral(uint256 bondGroupID, uint256 amount)
        external
        returns (bool success);

    function exchangeEquivalentBonds(
        uint256 inputBondGroupID,
        uint256 outputBondGroupID,
        uint256 amount,
        bytes32[] calldata exceptionBonds
    ) external returns (bool);

    function liquidateBond(uint256 bondGroupID, uint256 oracleHintID)
        external
        returns (uint256 totalPayment);

    function collateralAddress() external view returns (address);

    function oracleAddress() external view returns (PriceOracleInterface);

    function feeTaker() external view returns (address);

    function decimalsOfBond() external view returns (uint8);

    function decimalsOfOraclePrice() external view returns (uint8);

    function maturityScale() external view returns (uint256);

    function nextBondGroupID() external view returns (uint256);

    function getBond(bytes32 bondID)
        external
        view
        returns (
            address bondAddress,
            uint256 maturity,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        );

    function getFnMap(bytes32 fnMapID) external view returns (bytes memory fnMap);

    function getBondGroup(uint256 bondGroupID)
        external
        view
        returns (bytes32[] memory bondIDs, uint256 maturity);

    function generateFnMapID(bytes calldata fnMap) external view returns (bytes32 fnMapID);

    function generateBondID(uint256 maturity, bytes calldata fnMap)
        external
        view
        returns (bytes32 bondID);
}

// File: contracts/Interfaces/BondRegistratorInterface.sol






interface BondRegistratorInterface {
    struct Points {
        uint64 x1;
        uint64 y1;
        uint64 x2;
        uint64 y2;
    }

    function getFnMap(Points[] memory points) external pure returns (bytes memory fnMap);

    function registerSBT(
        BondMakerInterface bondMaker,
        uint64 sbtStrikePrice,
        uint64 maturity
    ) external returns (bytes32);

    function registerBondGroup(
        BondMakerInterface bondMaker,
        uint256 callStrikePrice,
        uint64 sbtStrikePrice,
        uint64 maturity,
        bytes32 SBTId
    ) external returns (uint256 bondGroupId);

    function registerBond(
        BondMakerInterface bondMaker,
        Points[] memory points,
        uint256 maturity
    ) external returns (bytes32);
}

// File: contracts/SimpleAggregator/BondRegistrator.sol







contract BondRegistrator is BondRegistratorInterface {
    function getFnMap(Points[] memory points) public pure override returns (bytes memory) {
        uint256[] memory polyline = _zipLines(points);
        return abi.encode(polyline);
    }

    function _zipLines(Points[] memory points) internal pure returns (uint256[] memory lines) {
        lines = new uint256[](points.length);
        for (uint256 i = 0; i < points.length; i++) {
            uint256 x1U256 = uint256(points[i].x1) << (64 + 64 + 64); // uint64
            uint256 y1U256 = uint256(points[i].y1) << (64 + 64); // uint64
            uint256 x2U256 = uint256(points[i].x2) << 64; // uint64
            uint256 y2U256 = uint256(points[i].y2); // uint64
            uint256 zip = x1U256 | y1U256 | x2U256 | y2U256;
            lines[i] = zip;
        }
    }

    /**
     * @notice Create SBT function mapping and register new SBT
     */
    function registerSBT(
        BondMakerInterface bondMaker,
        uint64 sbtStrikePrice,
        uint64 maturity
    ) public override returns (bytes32) {
        Points[] memory SBTPoints = new Points[](2);
        SBTPoints[0] = Points(0, 0, sbtStrikePrice, sbtStrikePrice);
        SBTPoints[1] = Points(sbtStrikePrice, sbtStrikePrice, sbtStrikePrice * 2, sbtStrikePrice);
        return registerBond(bondMaker, SBTPoints, maturity);
    }

    /**
     * @notice Create exotic option function mappings and register bonds, then register new bond group
     * @param SBTId SBT should be already registered and use SBT bond ID
     */
    function registerBondGroup(
        BondMakerInterface bondMaker,
        uint256 callStrikePrice,
        uint64 sbtStrikePrice,
        uint64 maturity,
        bytes32 SBTId
    ) public override returns (uint256 bondGroupId) {
        bytes32[] memory bondIds = new bytes32[](4);
        uint64 lev2EndPoint = uint64(callStrikePrice * 2) - sbtStrikePrice;
        uint64 maxProfitVolShort = uint64((callStrikePrice - sbtStrikePrice) / 2);
        bondIds[0] = SBTId;
        {
            Points[] memory CallPoints = new Points[](2);
            CallPoints[0] = Points(0, 0, uint64(callStrikePrice), 0);
            CallPoints[1] = Points(
                uint64(callStrikePrice),
                0,
                uint64(callStrikePrice * 2),
                uint64(callStrikePrice)
            );
            bondIds[1] = registerBond(bondMaker, CallPoints, maturity);
        }
        {
            Points[] memory Lev2Points = new Points[](3);
            Lev2Points[0] = Points(0, 0, sbtStrikePrice, 0);
            Lev2Points[1] = Points(
                sbtStrikePrice,
                0,
                lev2EndPoint,
                uint64(callStrikePrice - sbtStrikePrice)
            );
            Lev2Points[2] = Points(
                lev2EndPoint,
                uint64(callStrikePrice - sbtStrikePrice),
                lev2EndPoint + sbtStrikePrice,
                uint64(callStrikePrice - sbtStrikePrice)
            );
            bondIds[2] = registerBond(bondMaker, Lev2Points, maturity);
        }

        {
            Points[] memory VolShortPoints = new Points[](4);
            VolShortPoints[0] = Points(0, 0, sbtStrikePrice, 0);
            VolShortPoints[1] = Points(
                sbtStrikePrice,
                0,
                uint64(callStrikePrice),
                maxProfitVolShort
            );
            VolShortPoints[2] = Points(uint64(callStrikePrice), maxProfitVolShort, lev2EndPoint, 0);
            VolShortPoints[3] = Points(lev2EndPoint, 0, lev2EndPoint + sbtStrikePrice, 0);

            bondIds[3] = registerBond(bondMaker, VolShortPoints, maturity);
        }
        return bondMaker.registerNewBondGroup(bondIds, uint256(maturity));
    }

    /**
     * @notice Register bond token if same bond does not exist. If exists, return bondID
     */
    function registerBond(
        BondMakerInterface bondMaker,
        Points[] memory points,
        uint256 maturity
    ) public override returns (bytes32) {
        bytes memory fnMap = getFnMap(points);
        bytes32 bondId = bondMaker.generateBondID(maturity, fnMap);
        (address bondAddress, , , ) = bondMaker.getBond(bondId);
        if (bondAddress != address(0)) {
            return bondId;
        }
        bondMaker.registerNewBond(maturity, fnMap);
        return bondId;
    }
}