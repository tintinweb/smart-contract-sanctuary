/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function transferInternalCoins(address,address,uint256) virtual external;
    function transferCollateral(bytes32,address,address,uint256) virtual external;
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
}
abstract contract OracleLike {
    function priceSource() virtual public view returns (address);
    function getResultWithValidity() virtual public view returns (uint256, bool);
}
abstract contract LiquidationEngineLike {
    function removeCoinsFromAuction(uint256) virtual public;
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
    function modifyParameters(bytes32,bytes32,address) external virtual;
    function collateralTypes(bytes32) virtual public view returns (
        IncreasingDiscountCollateralAuctionHouse collateralAuctionHouse,
        uint256 liquidationPenalty,     // [wad]
        uint256 liquidationQuantity     // [rad]
    );
}

/// IncreasingDiscountCollateralAuctionHouse.sol

// Copyright (C) 2018 Rain <[email protected]>, 2020 Reflexer Labs, INC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*
   This thing lets you sell some collateral at an increasing discount in order to instantly recapitalize the system
*/

contract IncreasingDiscountCollateralAuctionHouse {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "IncreasingDiscountCollateralAuctionHouse/account-not-authorized");
        _;
    }

    // --- Data ---
    struct Bid {
        // How much collateral is sold in an auction
        uint256 amountToSell;                                                                                         // [wad]
        // Total/max amount of coins to raise
        uint256 amountToRaise;                                                                                        // [rad]
        // Current discount
        uint256 currentDiscount;                                                                                      // [wad]
        // Max possibe discount
        uint256 maxDiscount;                                                                                          // [wad]
        // Rate at which the discount is updated every second
        uint256 perSecondDiscountUpdateRate;                                                                          // [ray]
        // Last time when the current discount was updated
        uint256 latestDiscountUpdateTime;                                                                             // [unix timestamp]
        // Deadline after which the discount cannot increase anymore
        uint48  discountIncreaseDeadline;                                                                             // [unix epoch time]
        // Who (which SAFE) receives leftover collateral that is not sold in the auction; usually the liquidated SAFE
        address forgoneCollateralReceiver;
        // Who receives the coins raised by the auction; usually the accounting engine
        address auctionIncomeRecipient;
    }

    // Bid data for each separate auction
    mapping (uint256 => Bid) public bids;

    // SAFE database
    SAFEEngineLike public safeEngine;
    // Collateral type name
    bytes32        public collateralType;

    // Minimum acceptable bid
    uint256  public   minimumBid = 5 * WAD;                                                                           // [wad]
    // Total length of the auction. Kept to adhere to the same interface as the English auction but redundant
    uint48   public   totalAuctionLength = uint48(-1);                                                                // [seconds]
    // Number of auctions started up until now
    uint256  public   auctionsStarted = 0;
    // The last read redemption price
    uint256  public   lastReadRedemptionPrice;
    // Minimum discount (compared to the system coin's current redemption price) at which collateral is being sold
    uint256  public   minDiscount = 0.95E18;                      // 5% discount                                      // [wad]
    // Maximum discount (compared to the system coin's current redemption price) at which collateral is being sold
    uint256  public   maxDiscount = 0.95E18;                      // 5% discount                                      // [wad]
    // Rate at which the discount will be updated in an auction
    uint256  public   perSecondDiscountUpdateRate = RAY;                                                              // [ray]
    // Max time over which the discount can be updated
    uint256  public   maxDiscountUpdateRateTimeline  = 1 hours;                                                       // [seconds]
    // Max lower bound deviation that the collateral median can have compared to the FSM price
    uint256  public   lowerCollateralMedianDeviation = 0.90E18;   // 10% deviation                                    // [wad]
    // Max upper bound deviation that the collateral median can have compared to the FSM price
    uint256  public   upperCollateralMedianDeviation = 0.95E18;   // 5% deviation                                     // [wad]
    // Max lower bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   lowerSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Max upper bound deviation that the system coin oracle price feed can have compared to the systemCoinOracle price
    uint256  public   upperSystemCoinMedianDeviation = WAD;       // 0% deviation                                     // [wad]
    // Min deviation for the system coin median result compared to the redemption price in order to take the median into account
    uint256  public   minSystemCoinMedianDeviation   = 0.999E18;                                                      // [wad]

    OracleRelayerLike     public oracleRelayer;
    OracleLike            public collateralFSM;
    OracleLike            public systemCoinOracle;
    LiquidationEngineLike public liquidationEngine;

    bytes32 public constant AUCTION_HOUSE_TYPE = bytes32("COLLATERAL");
    bytes32 public constant AUCTION_TYPE       = bytes32("INCREASING_DISCOUNT");

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event StartAuction(
        uint256 id,
        uint256 auctionsStarted,
        uint256 amountToSell,
        uint256 initialBid,
        uint256 indexed amountToRaise,
        uint256 startingDiscount,
        uint256 maxDiscount,
        uint256 perSecondDiscountUpdateRate,
        uint48  discountIncreaseDeadline,
        address indexed forgoneCollateralReceiver,
        address indexed auctionIncomeRecipient
    );
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event BuyCollateral(uint256 indexed id, uint256 wad, uint256 boughtCollateral);
    event SettleAuction(uint256 indexed id, uint256 leftoverCollateral);
    event TerminateAuctionPrematurely(uint256 indexed id, address sender, uint256 collateralAmount);

    // --- Init ---
    constructor(address safeEngine_, address liquidationEngine_, bytes32 collateralType_) public {
        safeEngine = SAFEEngineLike(safeEngine_);
        liquidationEngine = LiquidationEngineLike(liquidationEngine_);
        collateralType = collateralType_;
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addUint48(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x, "IncreasingDiscountCollateralAuctionHouse/add-uint48-overflow");
    }
    function addUint256(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "IncreasingDiscountCollateralAuctionHouse/add-uint256-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "IncreasingDiscountCollateralAuctionHouse/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "IncreasingDiscountCollateralAuctionHouse/mul-overflow");
    }
    uint256 constant WAD = 10 ** 18;
    function wmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / WAD;
    }
    uint256 constant RAY = 10 ** 27;
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "IncreasingDiscountCollateralAuctionHouse/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x, "IncreasingDiscountCollateralAuctionHouse/rmul-overflow");
        z = z / RAY;
    }
    function wdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "IncreasingDiscountCollateralAuctionHouse/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x <= y) ? x : y;
    }
    function maximum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x >= y) ? x : y;
    }
    function rpower(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }

    // --- General Utils ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Admin ---
    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "minDiscount") {
            require(both(data >= maxDiscount, data < WAD), "IncreasingDiscountCollateralAuctionHouse/invalid-min-discount");
            minDiscount = data;
        }
        else if (parameter == "maxDiscount") {
            require(both(both(data <= minDiscount, data < WAD), data > 0), "IncreasingDiscountCollateralAuctionHouse/invalid-max-discount");
            maxDiscount = data;
        }
        else if (parameter == "perSecondDiscountUpdateRate") {
            require(data <= RAY, "IncreasingDiscountCollateralAuctionHouse/invalid-discount-update-rate");
            perSecondDiscountUpdateRate = data;
        }
        else if (parameter == "maxDiscountUpdateRateTimeline") {
            require(both(data > 0, uint256(uint48(-1)) > addUint256(now, data)), "IncreasingDiscountCollateralAuctionHouse/invalid-update-rate-time");
            maxDiscountUpdateRateTimeline = data;
        }
        else if (parameter == "lowerCollateralMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-lower-collateral-median-deviation");
            lowerCollateralMedianDeviation = data;
        }
        else if (parameter == "upperCollateralMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-upper-collateral-median-deviation");
            upperCollateralMedianDeviation = data;
        }
        else if (parameter == "lowerSystemCoinMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-lower-system-coin-median-deviation");
            lowerSystemCoinMedianDeviation = data;
        }
        else if (parameter == "upperSystemCoinMedianDeviation") {
            require(data <= WAD, "IncreasingDiscountCollateralAuctionHouse/invalid-upper-system-coin-median-deviation");
            upperSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minSystemCoinMedianDeviation") {
            minSystemCoinMedianDeviation = data;
        }
        else if (parameter == "minimumBid") {
            minimumBid = data;
        }
        else revert("IncreasingDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /**
     * @notice Modify an addres parameter
     * @param parameter The parameter name
     * @param data New address for the parameter
     */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike(data);
        else if (parameter == "collateralFSM") {
          collateralFSM = OracleLike(data);
          // Check that priceSource() is implemented
          collateralFSM.priceSource();
        }
        else if (parameter == "systemCoinOracle") systemCoinOracle = OracleLike(data);
        else if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike(data);
        else revert("IncreasingDiscountCollateralAuctionHouse/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Private Auction Utils ---
    /*
    * @notify Get the amount of bought collateral from a specific auction using custom collateral price feeds, a system
    *         coin price feed and a custom discount
    * @param id The ID of the auction to bid in and get collateral from
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin market price fetched from the oracle
    * @param adjustedBid The system coin bid
    * @param customDiscount The discount offered
    */
    function getBoughtCollateral(
        uint256 id,
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 adjustedBid,
        uint256 customDiscount
    ) private view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        uint256 discountedCollateralPrice =
          getDiscountedCollateralPrice(
            collateralFsmPriceFeedValue,
            collateralMedianPriceFeedValue,
            systemCoinPriceFeedValue,
            customDiscount
          );
        // calculate the amount of collateral bought
        uint256 boughtCollateral = wdivide(adjustedBid, discountedCollateralPrice);
        // if the calculated collateral amount exceeds the amount still up for sale, adjust it to the remaining amount
        boughtCollateral = (boughtCollateral > bids[id].amountToSell) ? bids[id].amountToSell : boughtCollateral;

        return boughtCollateral;
    }
    /*
    * @notice Update the discount used in a particular auction
    * @param id The id of the auction to update the discount for
    * @returns The newly computed currentDiscount for the targeted auction
    */
    function updateCurrentDiscount(uint256 id) private returns (uint256) {
        // Work directly with storage
        Bid storage auctionBidData              = bids[id];
        auctionBidData.currentDiscount          = getNextCurrentDiscount(id);
        auctionBidData.latestDiscountUpdateTime = now;
        return auctionBidData.currentDiscount;
    }

    // --- Public Auction Utils ---
    /*
    * @notice Fetch the collateral median price (from the oracle, not FSM)
    * @returns The collateral price from the oracle median; zero if the address of the collateralMedian (as fetched from the FSM) is null
    */
    function getCollateralMedianPrice() public view returns (uint256 priceFeed) {
        // Fetch the collateral median address from the collateral FSM
        address collateralMedian;
        try collateralFSM.priceSource() returns (address median) {
          collateralMedian = median;
        } catch (bytes memory revertReason) {}

        if (collateralMedian == address(0)) return 0;

        // wrapped call toward the collateral median
        try OracleLike(collateralMedian).getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price);
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Fetch the system coin market price
    * @returns The system coin market price fetch from the oracle
    */
    function getSystemCoinMarketPrice() public view returns (uint256 priceFeed) {
        if (address(systemCoinOracle) == address(0)) return 0;

        // wrapped call toward the system coin oracle
        try systemCoinOracle.getResultWithValidity()
          returns (uint256 price, bool valid) {
          if (valid) {
            priceFeed = uint256(price) * 10 ** 9; // scale to RAY
          }
        } catch (bytes memory revertReason) {
          return 0;
        }
    }
    /*
    * @notice Get the smallest possible price that's at max lowerSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinFloorDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 floorPrice) {
        uint256 minFloorDeviatedPrice = wmultiply(redemptionPrice, minSystemCoinMedianDeviation);
        floorPrice = wmultiply(redemptionPrice, lowerSystemCoinMedianDeviation);
        floorPrice = (floorPrice <= minFloorDeviatedPrice) ? floorPrice : redemptionPrice;
    }
    /*
    * @notice Get the highest possible price that's at max upperSystemCoinMedianDeviation deviated from the redemption price and at least
    *         minSystemCoinMedianDeviation deviated
    */
    function getSystemCoinCeilingDeviatedPrice(uint256 redemptionPrice) public view returns (uint256 ceilingPrice) {
        uint256 minCeilingDeviatedPrice = wmultiply(redemptionPrice, subtract(2 * WAD, minSystemCoinMedianDeviation));
        ceilingPrice = wmultiply(redemptionPrice, subtract(2 * WAD, upperSystemCoinMedianDeviation));
        ceilingPrice = (ceilingPrice >= minCeilingDeviatedPrice) ? ceilingPrice : redemptionPrice;
    }
    /*
    * @notice Get the collateral price from the FSM and the final system coin price that will be used when bidding in an auction
    * @param systemCoinRedemptionPrice The system coin redemption price
    * @returns The collateral price from the FSM and the final system coin price used for bidding (picking between redemption and market prices)
    */
    function getCollateralFSMAndFinalSystemCoinPrices(uint256 systemCoinRedemptionPrice) public view returns (uint256, uint256) {
        require(systemCoinRedemptionPrice > 0, "IncreasingDiscountCollateralAuctionHouse/invalid-redemption-price-provided");
        (uint256 collateralFsmPriceFeedValue, bool collateralFsmHasValidValue) = collateralFSM.getResultWithValidity();
        if (!collateralFsmHasValidValue) {
          return (0, 0);
        }

        uint256 systemCoinAdjustedPrice  = systemCoinRedemptionPrice;
        uint256 systemCoinPriceFeedValue = getSystemCoinMarketPrice();

        if (systemCoinPriceFeedValue > 0) {
          uint256 floorPrice   = getSystemCoinFloorDeviatedPrice(systemCoinAdjustedPrice);
          uint256 ceilingPrice = getSystemCoinCeilingDeviatedPrice(systemCoinAdjustedPrice);

          if (uint(systemCoinPriceFeedValue) < systemCoinAdjustedPrice) {
            systemCoinAdjustedPrice = maximum(uint256(systemCoinPriceFeedValue), floorPrice);
          } else {
            systemCoinAdjustedPrice = minimum(uint256(systemCoinPriceFeedValue), ceilingPrice);
          }
        }

        return (uint256(collateralFsmPriceFeedValue), systemCoinAdjustedPrice);
    }
    /*
    * @notice Get the collateral price used in bidding by picking between the raw FSM and the oracle median price and taking into account
    *         deviation limits
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the median attached to the FSM
    */
    function getFinalBaseCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue
    ) public view returns (uint256) {
        uint256 floorPrice   = wmultiply(collateralFsmPriceFeedValue, lowerCollateralMedianDeviation);
        uint256 ceilingPrice = wmultiply(collateralFsmPriceFeedValue, subtract(2 * WAD, upperCollateralMedianDeviation));

        uint256 adjustedMedianPrice = (collateralMedianPriceFeedValue == 0) ?
          collateralFsmPriceFeedValue : collateralMedianPriceFeedValue;

        if (adjustedMedianPrice < collateralFsmPriceFeedValue) {
          return maximum(adjustedMedianPrice, floorPrice);
        } else {
          return minimum(adjustedMedianPrice, ceilingPrice);
        }
    }
    /*
    * @notice Get the discounted collateral price (using a custom discount)
    * @param collateralFsmPriceFeedValue The collateral price fetched from the FSM
    * @param collateralMedianPriceFeedValue The collateral price fetched from the oracle median
    * @param systemCoinPriceFeedValue The system coin price fetched from the oracle
    * @param customDiscount The custom discount used to calculate the collateral price offered
    */
    function getDiscountedCollateralPrice(
        uint256 collateralFsmPriceFeedValue,
        uint256 collateralMedianPriceFeedValue,
        uint256 systemCoinPriceFeedValue,
        uint256 customDiscount
    ) public view returns (uint256) {
        // calculate the collateral price in relation to the latest system coin price and apply the discount
        return wmultiply(
          rdivide(getFinalBaseCollateralPrice(collateralFsmPriceFeedValue, collateralMedianPriceFeedValue), systemCoinPriceFeedValue),
          customDiscount
        );
    }
    /*
    * @notice Get the upcoming discount that will be used in a specific auction
    * @param id The ID of the auction to calculate the upcoming discount for
    * @returns The upcoming discount that will be used in the targeted auction
    */
    function getNextCurrentDiscount(uint256 id) public view returns (uint256) {
        if (bids[id].forgoneCollateralReceiver == address(0)) return RAY;
        uint256 nextDiscount = bids[id].currentDiscount;

        // If the increase deadline hasn't been passed yet and the current discount is not at or greater than max
        if (both(uint48(now) < bids[id].discountIncreaseDeadline, bids[id].currentDiscount > bids[id].maxDiscount)) {
            // Calculate the new current discount
            nextDiscount = rmultiply(
              rpower(bids[id].perSecondDiscountUpdateRate, subtract(now, bids[id].latestDiscountUpdateTime), RAY),
              bids[id].currentDiscount
            );

            // If the new discount is greater than the max one
            if (nextDiscount <= bids[id].maxDiscount) {
              nextDiscount = bids[id].maxDiscount;
            }
        } else {
            // Determine the conditions when we can instantly set the current discount to max
            bool currentZeroMaxNonZero = both(bids[id].currentDiscount == 0, bids[id].maxDiscount > 0);
            bool doneUpdating          = both(uint48(now) >= bids[id].discountIncreaseDeadline, bids[id].currentDiscount != bids[id].maxDiscount);

            if (either(currentZeroMaxNonZero, doneUpdating)) {
              nextDiscount = bids[id].maxDiscount;
            }
        }

        return nextDiscount;
    }
    /*
    * @notice Get the actual bid that will be used in an auction (taking into account the bidder input)
    * @param id The id of the auction to calculate the adjusted bid for
    * @param wad The initial bid submitted
    * @returns Whether the bid is valid or not and the adjusted bid
    */
    function getAdjustedBid(
        uint256 id, uint256 wad
    ) public view returns (bool, uint256) {
        if (either(
          either(bids[id].amountToSell == 0, bids[id].amountToRaise == 0),
          either(wad == 0, wad < minimumBid)
        )) {
          return (false, wad);
        }

        uint256 remainingToRaise = bids[id].amountToRaise;

        // bound max amount offered in exchange for collateral
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > remainingToRaise) {
            adjustedBid = addUint256(remainingToRaise / RAY, 1);
        }

        remainingToRaise = (multiply(adjustedBid, RAY) > remainingToRaise) ? 0 : subtract(bids[id].amountToRaise, multiply(adjustedBid, RAY));
        if (both(remainingToRaise > 0, remainingToRaise < RAY)) {
            return (false, adjustedBid);
        }

        return (true, adjustedBid);
    }

    // --- Core Auction Logic ---
    /**
     * @notice Start a new collateral auction
     * @param forgoneCollateralReceiver Who receives leftover collateral that is not auctioned
     * @param auctionIncomeRecipient Who receives the amount raised in the auction
     * @param amountToRaise Total amount of coins to raise (rad)
     * @param amountToSell Total amount of collateral available to sell (wad)
     * @param initialBid Unused
     */
    function startAuction(
        address forgoneCollateralReceiver,
        address auctionIncomeRecipient,
        uint256 amountToRaise,
        uint256 amountToSell,
        uint256 initialBid
    ) public isAuthorized returns (uint256 id) {
        require(auctionsStarted < uint256(-1), "IncreasingDiscountCollateralAuctionHouse/overflow");
        require(amountToSell > 0, "IncreasingDiscountCollateralAuctionHouse/no-collateral-for-sale");
        require(amountToRaise > 0, "IncreasingDiscountCollateralAuctionHouse/nothing-to-raise");
        require(amountToRaise >= RAY, "IncreasingDiscountCollateralAuctionHouse/dusty-auction");
        id = ++auctionsStarted;

        uint48 discountIncreaseDeadline      = addUint48(uint48(now), uint48(maxDiscountUpdateRateTimeline));

        bids[id].currentDiscount             = minDiscount;
        bids[id].maxDiscount                 = maxDiscount;
        bids[id].perSecondDiscountUpdateRate = perSecondDiscountUpdateRate;
        bids[id].discountIncreaseDeadline    = discountIncreaseDeadline;
        bids[id].latestDiscountUpdateTime    = now;
        bids[id].amountToSell                = amountToSell;
        bids[id].forgoneCollateralReceiver   = forgoneCollateralReceiver;
        bids[id].auctionIncomeRecipient      = auctionIncomeRecipient;
        bids[id].amountToRaise               = amountToRaise;

        safeEngine.transferCollateral(collateralType, msg.sender, address(this), amountToSell);

        emit StartAuction(
          id,
          auctionsStarted,
          amountToSell,
          initialBid,
          amountToRaise,
          minDiscount,
          maxDiscount,
          perSecondDiscountUpdateRate,
          discountIncreaseDeadline,
          forgoneCollateralReceiver,
          auctionIncomeRecipient
        );
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the last read redemption price and the old current
     *         discount associated with the auction
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getApproximateCollateralBought(uint256 id, uint256 wad) external view returns (uint256, uint256) {
        if (lastReadRedemptionPrice == 0) return (0, wad);

        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid,
          bids[id].currentDiscount
        ), adjustedBid);
    }
    /**
     * @notice Calculate how much collateral someone would buy from an auction using the latest redemption price fetched from the
     *         OracleRelayer and the latest updated discount associated with the auction
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted
     */
    function getCollateralBought(uint256 id, uint256 wad) external returns (uint256, uint256) {
        (bool validAuctionAndBid, uint256 adjustedBid) = getAdjustedBid(id, wad);
        if (!validAuctionAndBid) {
            return (0, adjustedBid);
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the oracle doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        if (collateralFsmPriceFeedValue == 0) {
          return (0, adjustedBid);
        }

        return (getBoughtCollateral(
          id,
          collateralFsmPriceFeedValue,
          getCollateralMedianPrice(),
          systemCoinPriceFeedValue,
          adjustedBid,
          updateCurrentDiscount(id)
        ), adjustedBid);
    }
    /**
     * @notice Buy collateral from an auction at an increasing discount
     * @param id ID of the auction to buy collateral from
     * @param wad New bid submitted (as a WAD which has 18 decimals)
     */
    function buyCollateral(uint256 id, uint256 wad) external {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "IncreasingDiscountCollateralAuctionHouse/inexistent-auction");
        require(both(wad > 0, wad >= minimumBid), "IncreasingDiscountCollateralAuctionHouse/invalid-bid");

        // bound max amount offered in exchange for collateral (in case someone offers more than it's necessary)
        uint256 adjustedBid = wad;
        if (multiply(adjustedBid, RAY) > bids[id].amountToRaise) {
            adjustedBid = addUint256(bids[id].amountToRaise / RAY, 1);
        }

        // Read the redemption price
        lastReadRedemptionPrice = oracleRelayer.redemptionPrice();

        // check that the collateral FSM doesn't return an invalid value
        (uint256 collateralFsmPriceFeedValue, uint256 systemCoinPriceFeedValue) = getCollateralFSMAndFinalSystemCoinPrices(lastReadRedemptionPrice);
        require(collateralFsmPriceFeedValue > 0, "IncreasingDiscountCollateralAuctionHouse/collateral-fsm-invalid-value");

        // get the amount of collateral bought
        uint256 boughtCollateral = getBoughtCollateral(
            id, collateralFsmPriceFeedValue, getCollateralMedianPrice(), systemCoinPriceFeedValue, adjustedBid, updateCurrentDiscount(id)
        );
        // check that the calculated amount is greater than zero
        require(boughtCollateral > 0, "IncreasingDiscountCollateralAuctionHouse/null-bought-amount");
        // update the amount of collateral to sell
        bids[id].amountToSell = subtract(bids[id].amountToSell, boughtCollateral);

        // update remainingToRaise in case amountToSell is zero (everything has been sold)
        uint256 remainingToRaise = (either(multiply(wad, RAY) >= bids[id].amountToRaise, bids[id].amountToSell == 0)) ?
            bids[id].amountToRaise : subtract(bids[id].amountToRaise, multiply(wad, RAY));

        // update leftover amount to raise in the bid struct
        bids[id].amountToRaise = (multiply(adjustedBid, RAY) > bids[id].amountToRaise) ?
            0 : subtract(bids[id].amountToRaise, multiply(adjustedBid, RAY));

        // check that the remaining amount to raise is either zero or higher than RAY
        require(
          either(bids[id].amountToRaise == 0, bids[id].amountToRaise >= RAY),
          "IncreasingDiscountCollateralAuctionHouse/invalid-left-to-raise"
        );

        // transfer the bid to the income recipient and the collateral to the bidder
        safeEngine.transferInternalCoins(msg.sender, bids[id].auctionIncomeRecipient, multiply(adjustedBid, RAY));
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, boughtCollateral);

        // Emit the buy event
        emit BuyCollateral(id, adjustedBid, boughtCollateral);

        // Remove coins from the liquidation buffer
        bool soldAll = either(bids[id].amountToRaise == 0, bids[id].amountToSell == 0);
        if (soldAll) {
            liquidationEngine.removeCoinsFromAuction(remainingToRaise);
        } else {
            liquidationEngine.removeCoinsFromAuction(multiply(adjustedBid, RAY));
        }

        // If the auction raised the whole amount or all collateral was sold,
        // send remaining collateral to the forgone receiver
        if (soldAll) {
            safeEngine.transferCollateral(collateralType, address(this), bids[id].forgoneCollateralReceiver, bids[id].amountToSell);
            delete bids[id];
            emit SettleAuction(id, bids[id].amountToSell);
        }
    }
    /**
     * @notice Settle/finish an auction
     * @param id ID of the auction to settle
     */
    function settleAuction(uint256 id) external {
        return;
    }
    /**
     * @notice Terminate an auction prematurely. Usually called by Global Settlement.
     * @param id ID of the auction to settle
     */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        require(both(bids[id].amountToSell > 0, bids[id].amountToRaise > 0), "IncreasingDiscountCollateralAuctionHouse/inexistent-auction");
        liquidationEngine.removeCoinsFromAuction(bids[id].amountToRaise);
        safeEngine.transferCollateral(collateralType, address(this), msg.sender, bids[id].amountToSell);
        delete bids[id];
        emit TerminateAuctionPrematurely(id, msg.sender, bids[id].amountToSell);
    }

    // --- Getters ---
    function bidAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function remainingAmountToSell(uint256 id) public view returns (uint256) {
        return bids[id].amountToSell;
    }
    function forgoneCollateralReceiver(uint256 id) public view returns (address) {
        return bids[id].forgoneCollateralReceiver;
    }
    function raisedAmount(uint256 id) public view returns (uint256) {
        return 0;
    }
    function amountToRaise(uint256 id) public view returns (uint256) {
        return bids[id].amountToRaise;
    }
}

contract DeployIncreasingDiscountCollateralHouse {
    function execute(address safeEngine, LiquidationEngineLike liquidationEngine, bytes32 collateralType, address globalSettlement) public returns (address) {
        // get old collateral house
        (IncreasingDiscountCollateralAuctionHouse oldCollateralAuctionHouse,,) = liquidationEngine.collateralTypes(collateralType);

        // deploy new auction house
        IncreasingDiscountCollateralAuctionHouse auctionHouse =
            new IncreasingDiscountCollateralAuctionHouse(safeEngine, address(liquidationEngine), collateralType);
        // set the new collateral auction house in liquidation engine
        liquidationEngine.modifyParameters(collateralType, "collateralAuctionHouse", address(auctionHouse));
        // Approve the auction house in order to reduce the currentOnAuctionSystemCoins
        liquidationEngine.addAuthorization(address(auctionHouse));
        // Remove the old auction house
        liquidationEngine.removeAuthorization(address(oldCollateralAuctionHouse));
        // Internal auth
        auctionHouse.addAuthorization(address(liquidationEngine));
        auctionHouse.addAuthorization(globalSettlement);
        // Params
        auctionHouse.modifyParameters("oracleRelayer", address(oldCollateralAuctionHouse.oracleRelayer()));
        auctionHouse.modifyParameters("collateralFSM", address(oldCollateralAuctionHouse.collateralFSM()));
        auctionHouse.modifyParameters("systemCoinOracle", address(oldCollateralAuctionHouse.systemCoinOracle()));
        auctionHouse.modifyParameters("maxDiscount", 0.88E18);
        auctionHouse.modifyParameters("minDiscount", 0.92E18);
        auctionHouse.modifyParameters("perSecondDiscountUpdateRate", 999983536519757434476050304);
        auctionHouse.modifyParameters("maxDiscountUpdateRateTimeline", 2700);
        auctionHouse.modifyParameters("lowerCollateralMedianDeviation", 0.80E18);
        auctionHouse.modifyParameters("lowerSystemCoinMedianDeviation", 1 ether);
        auctionHouse.modifyParameters("upperCollateralMedianDeviation", 0.80E18);
        auctionHouse.modifyParameters("upperSystemCoinMedianDeviation", 1 ether);
        auctionHouse.modifyParameters("minSystemCoinMedianDeviation", 0.96E18);
        auctionHouse.modifyParameters("minimumBid", 25 ether);

        return address(auctionHouse);
    }
}