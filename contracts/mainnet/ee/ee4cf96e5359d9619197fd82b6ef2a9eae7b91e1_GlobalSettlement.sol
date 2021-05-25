/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/// GlobalSettlement.sol

// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
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

pragma solidity 0.6.7;

abstract contract SAFEEngineLike {
    function coinBalance(address) virtual public view returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        uint256 debtAmount,        // [wad]
        uint256 accumulatedRate,   // [ray]
        uint256 safetyPrice,       // [ray]
        uint256 debtCeiling,       // [rad]
        uint256 debtFloor,         // [rad]
        uint256 liquidationPrice   // [ray]
    );
    function safes(bytes32,address) virtual public view returns (
        uint256 lockedCollateral, // [wad]
        uint256 generatedDebt     // [wad]
    );
    function globalDebt() virtual public returns (uint256);
    function transferInternalCoins(address src, address dst, uint256 rad) virtual external;
    function approveSAFEModification(address) virtual external;
    function transferCollateral(bytes32 collateralType, address src, address dst, uint256 wad) virtual external;
    function confiscateSAFECollateralAndDebt(bytes32 collateralType, address safe, address collateralSource, address debtDestination, int256 deltaCollateral, int256 deltaDebt) virtual external;
    function createUnbackedDebt(address debtDestination, address coinDestination, uint256 rad) virtual external;
    function disableContract() virtual external;
}
abstract contract LiquidationEngineLike {
    function collateralTypes(bytes32) virtual public view returns (
        address collateralAuctionHouse,
        uint256 liquidationPenalty,     // [wad]
        uint256 liquidationQuantity     // [rad]
    );
    function disableContract() virtual external;
}
abstract contract StabilityFeeTreasuryLike {
    function disableContract() virtual external;
}
abstract contract AccountingEngineLike {
    function disableContract() virtual external;
}
abstract contract CoinSavingsAccountLike {
    function disableContract() virtual external;
}
abstract contract CollateralAuctionHouseLike {
    function bidAmount(uint256 id) virtual public view returns (uint256);
    function raisedAmount(uint256 id) virtual public view returns (uint256);
    function remainingAmountToSell(uint256 id) virtual public view returns (uint256);
    function forgoneCollateralReceiver(uint256 id) virtual public view returns (address);
    function amountToRaise(uint256 id) virtual public view returns (uint256);
    function terminateAuctionPrematurely(uint256 auctionId) virtual external;
}
abstract contract OracleLike {
    function read() virtual public view returns (uint256);
}
abstract contract OracleRelayerLike {
    function redemptionPrice() virtual public returns (uint256);
    function collateralTypes(bytes32) virtual public view returns (
        OracleLike orcl,
        uint256 safetyCRatio,
        uint256 liquidationCRatio
    );
    function disableContract() virtual external;
}

/*
    This is the Global Settlement module. It is an
    involved, stateful process that takes place over nine steps.
    First we freeze the system and lock the prices for each collateral type.
    1. `shutdownSystem()`:
        - freezes user entrypoints
        - starts cooldown period
    2. `freezeCollateralType(collateralType)`:
       - set the final price for each collateralType, reading off the price feed
    We must process some system state before it is possible to calculate
    the final coin / collateral price. In particular, we need to determine:
      a. `collateralShortfall` (considers under-collateralised SAFEs)
      b. `outstandingCoinSupply` (after including system surplus / deficit)
    We determine (a) by processing all under-collateralised SAFEs with
    `processSAFE`
    3. `processSAFE(collateralType, safe)`:
       - cancels SAFE debt
       - any excess collateral remains
       - backing collateral taken
    We determine (b) by processing ongoing coin generating processes,
    i.e. auctions. We need to ensure that auctions will not generate any
    further coin income. In the two-way auction model this occurs when
    all auctions are in the reverse (`decreaseSoldAmount`) phase. There are two ways
    of ensuring this:
    4.  i) `shutdownCooldown`: set the cooldown period to be at least as long as the
           longest auction duration, which needs to be determined by the
           shutdown administrator.
           This takes a fairly predictable time to occur but with altered
           auction dynamics due to the now varying price of the system coin.
       ii) `fastTrackAuction`: cancel all ongoing auctions and seize the collateral.
           This allows for faster processing at the expense of more
           processing calls. This option allows coin holders to retrieve
           their collateral faster.
           `fastTrackAuction(collateralType, auctionId)`:
            - cancel individual collateral auctions in the `increaseBidSize` (forward) phase
            - retrieves collateral and returns coins to bidder
            - `decreaseSoldAmount` (reverse) phase auctions can continue normally
    Option (i), `shutdownCooldown`, is sufficient for processing the system
    settlement but option (ii), `fastTrackAuction`, will speed it up. Both options
    are available in this implementation, with `fastTrackAuction` being enabled on a
    per-auction basis.
    When a SAFE has been processed and has no debt remaining, the
    remaining collateral can be removed.
    5. `freeCollateral(collateralType)`:
        - remove collateral from the caller's SAFE
        - owner can call as needed
    After the processing period has elapsed, we enable calculation of
    the final price for each collateral type.
    6. `setOutstandingCoinSupply()`:
       - only callable after processing time period elapsed
       - assumption that all under-collateralised SAFEs are processed
       - fixes the total outstanding supply of coin
       - may also require extra SAFE processing to cover system surplus
    7. `calculateCashPrice(collateralType)`:
        - calculate `collateralCashPrice`
        - adjusts `collateralCashPrice` in the case of deficit / surplus
    At this point we have computed the final price for each collateral
    type and coin holders can now turn their coin into collateral. Each
    unit coin can claim a fixed basket of collateral.
    Coin holders must first `prepareCoinsForRedeeming` into a `coinBag`. Once prepared,
    coins cannot be transferred out of the bag. More coin can be added to a bag later.
    8. `prepareCoinsForRedeeming(coinAmount)`:
        - put some coins into a bag in order to 'redeemCollateral'. The bigger the bag, the more collateral the user can claim.
    9. `redeemCollateral(collateralType, collateralAmount)`:
        - exchange some coin from your bag for tokens from a specific collateral type
        - the amount of collateral available to redeem is limited by how big your bag is
*/

contract GlobalSettlement {
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
        require(authorizedAccounts[msg.sender] == 1, "GlobalSettlement/account-not-authorized");
        _;
    }

    // --- Data ---
    SAFEEngineLike           public safeEngine;
    LiquidationEngineLike    public liquidationEngine;
    AccountingEngineLike     public accountingEngine;
    OracleRelayerLike        public oracleRelayer;
    CoinSavingsAccountLike   public coinSavingsAccount;
    StabilityFeeTreasuryLike public stabilityFeeTreasury;

    // Flag that indicates whether settlement has been triggered or not
    uint256  public contractEnabled;
    // The timestamp when settlement was triggered
    uint256  public shutdownTime;
    // The amount of time post settlement during which no processing takes place
    uint256  public shutdownCooldown;
    // The outstanding supply of system coins computed during the setOutstandingCoinSupply() phase
    uint256  public outstandingCoinSupply;                                      // [rad]

    // The amount of collateral that a system coin can redeem
    mapping (bytes32 => uint256) public finalCoinPerCollateralPrice;            // [ray]
    // Total amount of bad debt in SAFEs with different collateral types
    mapping (bytes32 => uint256) public collateralShortfall;                    // [wad]
    // Total debt backed by every collateral type
    mapping (bytes32 => uint256) public collateralTotalDebt;                    // [wad]
    // Mapping of collateral prices in terms of system coins after taking into account system surplus/deficit and finalCoinPerCollateralPrices
    mapping (bytes32 => uint256) public collateralCashPrice;                    // [ray]

    // Bags of coins ready to be used for collateral redemption
    mapping (address => uint256)                      public coinBag;           // [wad]
    // Amount of coins already used for collateral redemption by every address and for different collateral types
    mapping (bytes32 => mapping (address => uint256)) public coinsUsedToRedeem; // [wad]

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 parameter, uint256 data);
    event ModifyParameters(bytes32 parameter, address data);
    event ShutdownSystem();
    event FreezeCollateralType(bytes32 indexed collateralType, uint256 finalCoinPerCollateralPrice);
    event FastTrackAuction(bytes32 indexed collateralType, uint256 auctionId, uint256 collateralTotalDebt);
    event ProcessSAFE(bytes32 indexed collateralType, address safe, uint256 collateralShortfall);
    event FreeCollateral(bytes32 indexed collateralType, address sender, int256 collateralAmount);
    event SetOutstandingCoinSupply(uint256 outstandingCoinSupply);
    event CalculateCashPrice(bytes32 indexed collateralType, uint256 collateralCashPrice);
    event PrepareCoinsForRedeeming(address indexed sender, uint256 coinBag);
    event RedeemCollateral(bytes32 indexed collateralType, address indexed sender, uint256 coinsAmount, uint256 collateralAmount);

    // --- Init ---
    constructor() public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        emit AddAuthorization(msg.sender);
    }

    // --- Math ---
    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x, "GlobalSettlement/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "GlobalSettlement/sub-underflow");
    }
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "GlobalSettlement/mul-overflow");
    }
    function minimum(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    function rmultiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "GlobalSettlement/rdiv-by-zero");
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "GlobalSettlement/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }

    // --- Administration ---
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data The new address for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        if (parameter == "safeEngine") safeEngine = SAFEEngineLike(data);
        else if (parameter == "liquidationEngine") liquidationEngine = LiquidationEngineLike(data);
        else if (parameter == "accountingEngine") accountingEngine = AccountingEngineLike(data);
        else if (parameter == "oracleRelayer") oracleRelayer = OracleRelayerLike(data);
        else if (parameter == "coinSavingsAccount") coinSavingsAccount = CoinSavingsAccountLike(data);
        else if (parameter == "stabilityFeeTreasury") stabilityFeeTreasury = StabilityFeeTreasuryLike(data);
        else revert("GlobalSettlement/modify-unrecognized-parameter");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data The new value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        if (parameter == "shutdownCooldown") shutdownCooldown = data;
        else revert("GlobalSettlement/modify-unrecognized-parameter");
        emit ModifyParameters(parameter, data);
    }

    // --- Settlement ---
    /**
     * @notice Freeze the system and start the cooldown period
     */
    function shutdownSystem() external isAuthorized {
        require(contractEnabled == 1, "GlobalSettlement/contract-not-enabled");
        contractEnabled = 0;
        shutdownTime = now;
        safeEngine.disableContract();
        liquidationEngine.disableContract();
        // treasury must be disabled before the accounting engine so that all surplus is gathered in one place
        if (address(stabilityFeeTreasury) != address(0)) {
          stabilityFeeTreasury.disableContract();
        }
        accountingEngine.disableContract();
        oracleRelayer.disableContract();
        if (address(coinSavingsAccount) != address(0)) {
          coinSavingsAccount.disableContract();
        }
        emit ShutdownSystem();
    }
    /**
     * @notice Calculate a collateral type's final price according to the latest system coin redemption price
     * @param collateralType The collateral type to calculate the price for
     */
    function freezeCollateralType(bytes32 collateralType) external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        require(finalCoinPerCollateralPrice[collateralType] == 0, "GlobalSettlement/final-collateral-price-already-defined");
        (collateralTotalDebt[collateralType],,,,,) = safeEngine.collateralTypes(collateralType);
        (OracleLike orcl,,) = oracleRelayer.collateralTypes(collateralType);
        // redemptionPrice is a ray, orcl returns a wad
        finalCoinPerCollateralPrice[collateralType] = wdivide(oracleRelayer.redemptionPrice(), uint256(orcl.read()));
        emit FreezeCollateralType(collateralType, finalCoinPerCollateralPrice[collateralType]);
    }
    /**
     * @notice Fast track an ongoing collateral auction
     * @param collateralType The collateral type associated with the auction contract
     * @param auctionId The ID of the auction to be fast tracked
     */
    function fastTrackAuction(bytes32 collateralType, uint256 auctionId) external {
        require(finalCoinPerCollateralPrice[collateralType] != 0, "GlobalSettlement/final-collateral-price-not-defined");

        (address auctionHouse_,,)       = liquidationEngine.collateralTypes(collateralType);
        CollateralAuctionHouseLike collateralAuctionHouse = CollateralAuctionHouseLike(auctionHouse_);
        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);

        uint256 bidAmount                 = collateralAuctionHouse.bidAmount(auctionId);
        uint256 raisedAmount              = collateralAuctionHouse.raisedAmount(auctionId);
        uint256 collateralToSell          = collateralAuctionHouse.remainingAmountToSell(auctionId);
        address forgoneCollateralReceiver = collateralAuctionHouse.forgoneCollateralReceiver(auctionId);
        uint256 amountToRaise             = collateralAuctionHouse.amountToRaise(auctionId);

        safeEngine.createUnbackedDebt(address(accountingEngine), address(accountingEngine), subtract(amountToRaise, raisedAmount));
        safeEngine.createUnbackedDebt(address(accountingEngine), address(this), bidAmount);
        safeEngine.approveSAFEModification(address(collateralAuctionHouse));
        collateralAuctionHouse.terminateAuctionPrematurely(auctionId);

        uint256 debt_ = subtract(amountToRaise, raisedAmount) / accumulatedRate;
        collateralTotalDebt[collateralType] = addition(collateralTotalDebt[collateralType], debt_);
        require(int256(collateralToSell) >= 0 && int256(debt_) >= 0, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(collateralType, forgoneCollateralReceiver, address(this), address(accountingEngine), int256(collateralToSell), int256(debt_));
        emit FastTrackAuction(collateralType, auctionId, collateralTotalDebt[collateralType]);
    }
    /**
     * @notice Cancel a SAFE's debt and leave any extra collateral in it
     * @param collateralType The collateral type associated with the SAFE
     * @param safe The SAFE to be processed
     */
    function processSAFE(bytes32 collateralType, address safe) external {
        require(finalCoinPerCollateralPrice[collateralType] != 0, "GlobalSettlement/final-collateral-price-not-defined");
        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, safe);

        uint256 amountOwed = rmultiply(rmultiply(safeDebt, accumulatedRate), finalCoinPerCollateralPrice[collateralType]);
        uint256 minCollateral = minimum(safeCollateral, amountOwed);
        collateralShortfall[collateralType] = addition(
            collateralShortfall[collateralType],
            subtract(amountOwed, minCollateral)
        );

        require(minCollateral <= 2**255 && safeDebt <= 2**255, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(
            collateralType,
            safe,
            address(this),
            address(accountingEngine),
            -int256(minCollateral),
            -int256(safeDebt)
        );

        emit ProcessSAFE(collateralType, safe, collateralShortfall[collateralType]);
    }
    /**
     * @notice Remove collateral from the caller's SAFE
     * @param collateralType The collateral type to free
     */
    function freeCollateral(bytes32 collateralType) external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        (uint256 safeCollateral, uint256 safeDebt) = safeEngine.safes(collateralType, msg.sender);
        require(safeDebt == 0, "GlobalSettlement/safe-debt-not-zero");
        require(safeCollateral <= 2**255, "GlobalSettlement/overflow");
        safeEngine.confiscateSAFECollateralAndDebt(
          collateralType,
          msg.sender,
          msg.sender,
          address(accountingEngine),
          -int256(safeCollateral),
          0
        );
        emit FreeCollateral(collateralType, msg.sender, -int256(safeCollateral));
    }
    /**
     * @notice Set the final outstanding supply of system coins
     * @dev There must be no remaining surplus in the accounting engine
     */
    function setOutstandingCoinSupply() external {
        require(contractEnabled == 0, "GlobalSettlement/contract-still-enabled");
        require(outstandingCoinSupply == 0, "GlobalSettlement/outstanding-coin-supply-not-zero");
        require(safeEngine.coinBalance(address(accountingEngine)) == 0, "GlobalSettlement/surplus-not-zero");
        require(now >= addition(shutdownTime, shutdownCooldown), "GlobalSettlement/shutdown-cooldown-not-finished");
        outstandingCoinSupply = safeEngine.globalDebt();
        emit SetOutstandingCoinSupply(outstandingCoinSupply);
    }
    /**
     * @notice Calculate a collateral's price taking into consideration system surplus/deficit and the finalCoinPerCollateralPrice
     * @param collateralType The collateral whose cash price will be calculated
     */
    function calculateCashPrice(bytes32 collateralType) external {
        require(outstandingCoinSupply != 0, "GlobalSettlement/outstanding-coin-supply-zero");
        require(collateralCashPrice[collateralType] == 0, "GlobalSettlement/collateral-cash-price-already-defined");

        (, uint256 accumulatedRate,,,,) = safeEngine.collateralTypes(collateralType);
        uint256 redemptionAdjustedDebt = rmultiply(
          rmultiply(collateralTotalDebt[collateralType], accumulatedRate), finalCoinPerCollateralPrice[collateralType]
        );
        collateralCashPrice[collateralType] =
          multiply(subtract(redemptionAdjustedDebt, collateralShortfall[collateralType]), RAY) / (outstandingCoinSupply / RAY);

        emit CalculateCashPrice(collateralType, collateralCashPrice[collateralType]);
    }
    /**
     * @notice Add coins into a 'bag' so that you can use them to redeem collateral
     * @param coinAmount The amount of internal system coins to add into the bag
     */
    function prepareCoinsForRedeeming(uint256 coinAmount) external {
        require(outstandingCoinSupply != 0, "GlobalSettlement/outstanding-coin-supply-zero");
        safeEngine.transferInternalCoins(msg.sender, address(accountingEngine), multiply(coinAmount, RAY));
        coinBag[msg.sender] = addition(coinBag[msg.sender], coinAmount);
        emit PrepareCoinsForRedeeming(msg.sender, coinBag[msg.sender]);
    }
    /**
     * @notice Redeem a specific collateral type using an amount of internal system coins from your bag
     * @param collateralType The collateral type to redeem
     * @param coinsAmount The amount of internal coins to use from your bag
     */
    function redeemCollateral(bytes32 collateralType, uint256 coinsAmount) external {
        require(collateralCashPrice[collateralType] != 0, "GlobalSettlement/collateral-cash-price-not-defined");
        uint256 collateralAmount = rmultiply(coinsAmount, collateralCashPrice[collateralType]);
        safeEngine.transferCollateral(
          collateralType,
          address(this),
          msg.sender,
          collateralAmount
        );
        coinsUsedToRedeem[collateralType][msg.sender] = addition(coinsUsedToRedeem[collateralType][msg.sender], coinsAmount);
        require(coinsUsedToRedeem[collateralType][msg.sender] <= coinBag[msg.sender], "GlobalSettlement/insufficient-bag-balance");
        emit RedeemCollateral(collateralType, msg.sender, coinsAmount, collateralAmount);
    }
}