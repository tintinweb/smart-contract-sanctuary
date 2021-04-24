// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./USMTemplate.sol";
import "./oracles/DiaOracleAdapter.sol";

contract USMDIA is USMTemplate{
    constructor(DiaOracleAdapter oracle_, address[] memory optOut_, string memory syntheticFeed_) 
        USMTemplate(
            oracle_,
            optOut_,
            string(abi.encodePacked("DIA synthetic for ", syntheticFeed_)),
            string(abi.encodePacked("DIA-", syntheticFeed_)),
            string(abi.encodePacked("DIA funding token for ", syntheticFeed_)),
            string(abi.encodePacked("FUM-", syntheticFeed_))
        )
        {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "erc20permit/contracts/ERC20Permit.sol";
import "./IUSM.sol";
import "./WithOptOut.sol";
import "./oracles/Oracle.sol";
import "./Address.sol";
import "./Delegable.sol";
import "./WadMath.sol";
import "./FUM.sol";
import "./MinOut.sol";


/**
 * @title USM
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 * @notice Concept by Jacob Eliosoff (@jacob-eliosoff).
 *
 * This abstract USM contract must be inherited by a concrete implementation, that also adds an Oracle implementation - eg, by
 * also inheriting a concrete Oracle implementation.  See USM (and MockUSM) for an example.
 *
 * We use this inheritance-based design (rather than the more natural, and frankly normally more correct, composition-based
 * design of storing the Oracle here as a variable), because inheriting the Oracle makes all the latestPrice()/refreshPrice()
 * calls *internal* rather than calls to a separate oracle contract (or multiple contracts) - which leads to a significant
 * saving in gas.
 */
contract USMTemplate is IUSM, Oracle, ERC20Permit, WithOptOut, Delegable {
    using Address for address payable;
    using WadMath for uint;

    event UnderwaterStatusChanged(bool underwater);
    event BidAskAdjustmentChanged(uint adjustment);
    event PriceChanged(uint timestamp, uint price);

    uint public constant WAD = 10 ** 18;
    uint public constant HALF_WAD = WAD / 2;
    uint public constant BILLION = 10 ** 9;
    uint public constant HALF_BILLION = BILLION / 2;
    uint public constant MAX_DEBT_RATIO = WAD * 8 / 10;                 // 80%
    uint public constant MIN_FUM_BUY_PRICE_HALF_LIFE = 1 days;          // Solidity for 1 * 24 * 60 * 60
    uint public constant BID_ASK_ADJUSTMENT_HALF_LIFE = 1 minutes;      // Solidity for 1 * 60

    FUM public immutable fum;
    Oracle public immutable oracle;
    uint256 immutable deadline; // Second at which the trial expires and `mint` and `fund` get disabled.

    struct StoredState {
        uint32 timeSystemWentUnderwater;    // Time at which (we noticed) debt ratio went > MAX, or 0 if it's currently < MAX
        uint32 ethUsdPriceTimestamp;
        uint80 ethUsdPrice;                 // Stored in billionths, not WADs: so 123.456 is stored as 123,456,000,000
        uint32 bidAskAdjustmentTimestamp;
        uint80 bidAskAdjustment;            // Stored in billionths, not WADs
    }

    struct LoadedState {
        uint timeSystemWentUnderwater;
        uint ethUsdPriceTimestamp;
        uint ethUsdPrice;                   // This one is in WADs, not billionths
        uint bidAskAdjustmentTimestamp;
        uint bidAskAdjustment;              // WADs, not billionths
        uint ethPool;
        uint usmTotalSupply;
    }

    StoredState public storedState = StoredState({
        timeSystemWentUnderwater: 0, ethUsdPriceTimestamp: 0, ethUsdPrice: 0,
        bidAskAdjustmentTimestamp: 0, bidAskAdjustment: uint80(BILLION)         // Initialize adjustment to 1.0 (scaled by 1b)
    });

    constructor(Oracle oracle_, address[] memory optedOut_, string memory name, string memory symbol, string memory fundingName, string memory fundingSymbol)
        ERC20Permit(name, symbol)
        WithOptOut(optedOut_)
    {
        oracle = oracle_;
        fum = new FUM(this, optedOut_, fundingName, fundingSymbol);
        deadline = block.timestamp + (60 * 60 * 24 * 28); // Four weeks into the future
    }

    // ____________________ Modifiers ____________________

    /**
     * @dev Sometimes we want to give FUM privileged access
     */
    modifier onlyHolderOrDelegateOrFUM(address owner, string memory errorMessage) {
        require(
            msg.sender == owner || delegated[owner][msg.sender] || msg.sender == address(fum),
            errorMessage
        );
        _;
    }

    // ____________________ External transactional functions ____________________

    /**
     * @notice Mint new USM, sending it to the given address, and only if the amount minted >= minUsmOut.  The amount of ETH is
     * passed in as msg.value.
     * @param to address to send the USM to.
     * @param minUsmOut Minimum accepted USM for a successful mint.
     */
    function mint(address to, uint minUsmOut) external payable override returns (uint usmOut) {
        usmOut = _mintUsm(to, minUsmOut);
    }

    /**
     * @dev Burn USM in exchange for ETH.
     * @param from address to deduct the USM from.
     * @param to address to send the ETH to.
     * @param usmToBurn Amount of USM to burn.
     * @param minEthOut Minimum accepted ETH for a successful burn.
     */
    function burn(address from, address payable to, uint usmToBurn, uint minEthOut)
        external override
        onlyHolderOrDelegate(from, "Only holder or delegate")
        returns (uint ethOut)
    {
        ethOut = _burnUsm(from, to, usmToBurn, minEthOut);
    }

    /**
     * @notice Funds the pool with ETH, minting new FUM and sending it to the given address, but only if the amount minted >=
     * minFumOut.  The amount of ETH is passed in as msg.value.
     * @param to address to send the FUM to.
     * @param minFumOut Minimum accepted FUM for a successful fund.
     */
    function fund(address to, uint minFumOut) external payable override returns (uint fumOut) {
        fumOut = _fundFum(to, minFumOut);
    }

    /**
     * @notice Defunds the pool by redeeming FUM in exchange for equivalent ETH from the pool.
     * @param from address to deduct the FUM from.
     * @param to address to send the ETH to.
     * @param fumToBurn Amount of FUM to burn.
     * @param minEthOut Minimum accepted ETH for a successful defund.
     */
    function defund(address from, address payable to, uint fumToBurn, uint minEthOut)
        external override
        onlyHolderOrDelegateOrFUM(from, "Only holder or delegate or FUM")
        returns (uint ethOut)
    {
        ethOut = _defundFum(from, to, fumToBurn, minEthOut);
    }

    /**
     * @notice If anyone sends ETH here, assume they intend it as a `mint`.
     * If decimals 8 to 11 (included) of the amount of Ether received are `0000` then the next 7 will
     * be parsed as the minimum Ether price accepted, with 2 digits before and 5 digits after the comma.
     */
    receive() external payable {
        _mintUsm(msg.sender, MinOut.parseMinTokenOut(msg.value));
    }

    // ____________________ Public transactional functions ____________________

    function refreshPrice() public virtual override(IUSM, Oracle) returns (uint price, uint updateTime) {
        LoadedState memory ls = loadState();
        bool priceChanged;
        (price, updateTime, ls.bidAskAdjustment, priceChanged) = _refreshPrice(ls);
        if (priceChanged) {
            (ls.ethUsdPrice, ls.ethUsdPriceTimestamp) = (price, updateTime);
            _storeState(ls);
        }
    }

    // ____________________ Internal ERC20 transactional functions ____________________

    /**
     * @notice If a user sends USM tokens directly to this contract (or to the FUM contract), assume they intend it as a `burn`.
     * If using `transfer`/`transferFrom` as `burn`, and if decimals 8 to 11 (included) of the amount transferred received
     * are `0000` then the next 7 will be parsed as the maximum USM price accepted, with 5 digits before and 2 digits after the comma.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override noOptOut(recipient) returns (bool) {
        if (recipient == address(this) || recipient == address(fum) || recipient == address(0)) {
            _burnUsm(sender, payable(sender), amount, MinOut.parseMinEthOut(amount));
        } else {
            super._transfer(sender, recipient, amount);
        }
        return true;
    }

    // ____________________ Internal helper transactional functions (for functions above) ____________________

    function _mintUsm(address to, uint minUsmOut) internal returns (uint usmOut)
    {
        // 1. Load the stored state:
        LoadedState memory ls = loadState();
        ls.ethPool -= msg.value;    // Backing out the ETH just received, which our calculations should ignore

        // 2. Check that fund() has been called first - no minting before funding:
        require(ls.ethPool > 0, "Fund before minting");

        // 3. Refresh the oracle price (if available - see _refreshPrice() below):
        (ls.ethUsdPrice, ls.ethUsdPriceTimestamp, ls.bidAskAdjustment, ) = _refreshPrice(ls);

        // 4. Calculate usmOut:
        uint adjShrinkFactor;
        (usmOut, adjShrinkFactor) = usmFromMint(ls, msg.value);
        require(usmOut >= minUsmOut, "Limit not reached");

        // 5. Update the in-memory LoadedState's bidAskAdjustment and price:
        ls.bidAskAdjustment = ls.bidAskAdjustment.wadMulDown(adjShrinkFactor);
        ls.ethUsdPrice = ls.ethUsdPrice.wadMulDown(adjShrinkFactor);

        // 6. Store the updated state and mint the user's new USM:
        _storeState(ls);
        _mint(to, usmOut);

        require(block.timestamp <= deadline, "Trial expired, remove assets");
        require(msg.value <= WAD, "Capped at 1 ETH per tx");
        require(ethPool() <= 100*WAD, "Capped at 100 pooled ETH");
    }

    function _burnUsm(address from, address payable to, uint usmToBurn, uint minEthOut) internal returns (uint ethOut)
    {
        // 1. Load the stored state:
        LoadedState memory ls = loadState();

        // 2. Refresh the oracle price:
        (ls.ethUsdPrice, ls.ethUsdPriceTimestamp, ls.bidAskAdjustment, ) = _refreshPrice(ls);

        // 3. Calculate ethOut:
        uint adjGrowthFactor;
        (ethOut, adjGrowthFactor) = ethFromBurn(ls, usmToBurn);
        require(ethOut >= minEthOut, "Limit not reached");

        // 4. Update the in-memory LoadedState's bidAskAdjustment and price:
        ls.bidAskAdjustment = ls.bidAskAdjustment.wadMulUp(adjGrowthFactor);
        ls.ethUsdPrice = ls.ethUsdPrice.wadMulUp(adjGrowthFactor);

        // 5. Check that the burn didn't leave debt ratio > 100%:
        uint newDebtRatio = debtRatio(ls.ethUsdPrice, ls.ethPool - ethOut, ls.usmTotalSupply - usmToBurn);
        require(newDebtRatio <= WAD, "Debt ratio > 100%");

        // 6. Burn the input USM, store the updated state, and return the user's ETH:
        _burn(from, usmToBurn);
        _storeState(ls);
        to.sendValue(ethOut);
    }

    function _fundFum(address to, uint minFumOut) internal returns (uint fumOut)
    {
        // 1. Load the stored state:
        LoadedState memory ls = loadState();
        ls.ethPool -= msg.value;    // Backing out the ETH just received, which our calculations should ignore

        // 2. Refresh the oracle price:
        (ls.ethUsdPrice, ls.ethUsdPriceTimestamp, ls.bidAskAdjustment, ) = _refreshPrice(ls);

        // 3. Refresh timeSystemWentUnderwater, and replace ls.usmTotalSupply with the *effective* USM supply for FUM buys:
        (ls.timeSystemWentUnderwater, ls.usmTotalSupply) =
            checkIfUnderwater(ls.usmTotalSupply, ls.ethPool, ls.ethUsdPrice, ls.timeSystemWentUnderwater, block.timestamp);

        // 4. Calculate fumOut:
        uint fumSupply = fum.totalSupply();
        uint adjGrowthFactor;
        (fumOut, adjGrowthFactor) = fumFromFund(ls, fumSupply, msg.value);
        require(fumOut >= minFumOut, "Limit not reached");

        // 5. Update the in-memory LoadedState's bidAskAdjustment and price:
        ls.bidAskAdjustment = ls.bidAskAdjustment.wadMulUp(adjGrowthFactor);
        ls.ethUsdPrice = ls.ethUsdPrice.wadMulUp(adjGrowthFactor);

        // 6. Update the stored state and mint the user's new FUM:
        _storeState(ls);
        fum.mint(to, fumOut);

        require(block.timestamp <= deadline, "Trial expired, remove assets");
        require(msg.value <= WAD, "Capped at 1 ETH per tx");
        require(ethPool() <= 100*WAD, "Capped at 100 pooled ETH");
    }

    function _defundFum(address from, address payable to, uint fumToBurn, uint minEthOut) internal returns (uint ethOut)
    {
        // 1. Load the stored state:
        LoadedState memory ls = loadState();

        // 2. Refresh the oracle price:
        (ls.ethUsdPrice, ls.ethUsdPriceTimestamp, ls.bidAskAdjustment, ) = _refreshPrice(ls);

        // 3. Calculate ethOut:
        uint fumSupply = fum.totalSupply();
        uint adjShrinkFactor;
        (ethOut, adjShrinkFactor) = ethFromDefund(ls, fumSupply, fumToBurn);
        require(ethOut >= minEthOut, "Limit not reached");

        // 4. Update the in-memory LoadedState's bidAskAdjustment and price:
        ls.bidAskAdjustment = ls.bidAskAdjustment.wadMulDown(adjShrinkFactor);
        ls.ethUsdPrice = ls.ethUsdPrice.wadMulDown(adjShrinkFactor);

        // 5. Check that the defund didn't leave debt ratio > MAX_DEBT_RATIO:
        uint newDebtRatio = debtRatio(ls.ethUsdPrice, ls.ethPool - ethOut, ls.usmTotalSupply);
        require(newDebtRatio <= MAX_DEBT_RATIO, "Debt ratio > max");

        // 6. Burn the input FUM, store the updated state, and return the user's ETH:
        fum.burn(from, fumToBurn);
        _storeState(ls);
        to.sendValue(ethOut);
    }

    /**
     * @notice Checks the external oracle for a fresh ETH/USD price.  If it has one, we take it as the new USM system price
     * (and update bidAskAdjustment as described below); if no fresh oracle price is available, we stick with our existing
     * system price, `ls.ethUsdPrice`, which may have been nudged around by mint/burn operations since the last oracle update.
     *
     * Note that our definition of whether an oracle price is "fresh" (`priceChanged == true`) isn't quite as trivial as
     * "whether it's changed since our last call."  Eg, we only consider a Uniswap TWAP price "fresh" when the *older* of the
     * two TWAP records it's based on changes (every few minutes), not when the *newer* TWAP record changes (typically every
     * time we call `latestPrice()`).  See the comment in `OurUniswapV2TWAPOracle._latestPrice()`.
     */
    function _refreshPrice(LoadedState memory ls)
        internal returns (uint price, uint updateTime, uint adjustment, bool priceChanged)
    {
        (price, updateTime) = oracle.refreshPrice();

        // The rest of this fn should be non-transactional: only the oracle.refreshPrice() call above may affect storage.
        adjustment = ls.bidAskAdjustment;
        priceChanged = updateTime > ls.ethUsdPriceTimestamp;

        if (!priceChanged) {                // If the price isn't fresher than our old one, scrap it and stick to the old one
            (price, updateTime) = (ls.ethUsdPrice, ls.ethUsdPriceTimestamp);
        } else if (ls.ethUsdPrice != 0) {   // If the old price is 0, don't try to use it to adjust the bidAskAdjustment...
            /**
             * This is a bit subtle.  We want to update the mid stored price to the oracle's fresh value, while updating
             * bidAskAdjustment in such a way that the currently adjusted (more expensive than mid) side gets no cheaper/more
             * favorably priced for users.  Example:
             *
             * 1. storedPrice = $1,000, and bidAskAdjustment = 1.02.  So, our current ETH buy price is $1,020, and our current
             *    ETH sell price is $1,000 (mid).
             * 2. The oracle comes back with a fresh price (newer updateTime) of $990.
             * 3. The currently adjusted price is buy price (ie, adj > 1).  So, we want to:
             *    a) Update storedPrice (mid) to $990.
             *    b) Update bidAskAdj to ensure that buy price remains >= $1,020.
             * 4. We do this by upping bidAskAdj 1.02 -> 1.0303.  Then the new buy price will remain $990 * 1.0303 = $1,020.
             *    The sell price will remain the unadjusted mid: formerly $1,000, now $990.
             *
             * Because the bidAskAdjustment reverts to 1 in a few minutes, the new 3.03% buy premium is temporary: buy price
             * will revert to the $990 mid soon - unless the new mid is egregiously low, in which case buyers should push it
             * back up.  Eg, suppose the oracle gives us a glitchy price of $99.  Then new mid = $99, bidAskAdj = 10.303, buy
             * price = $1,020, and the buy price will rapidly drop towards $99; but as it does so, users are incentivized to
             * step in and buy, eventually pushing mid back up to the real-world ETH market price (eg $990).
             *
             * In cases like this, our bidAskAdj update has protected the system, by preventing users from getting any chance
             * to buy at the bogus $99 price.
             */
            if (adjustment > WAD) {
                // max(1, old buy price / new mid price):
                adjustment = WAD.wadMax(ls.ethUsdPrice * adjustment / price);
            } else if (adjustment < WAD) {
                // min(1, old sell price / new mid price):
                adjustment = WAD.wadMin(ls.ethUsdPrice * adjustment / price);
            }
        }
    }

    /**
     * @notice Stores the current price, `bidAskAdjustment`, and `timeSystemWentUnderwater`.  Note that whereas most calls to
     * this function store a fresh `bidAskAdjustmentTimestamp`, most calls do *not* store a fresh `ethUsdPriceTimestamp`: the
     * latter isn't updated every time this is called with a new price, but only when the *oracle's* price is refreshed.  The
     * oracle price being "refreshed" is itself a subtle idea: see the comment in `OurUniswapV2TWAPOracle._latestPrice()`.
     */
    function _storeState(LoadedState memory ls) internal {
        if (ls.timeSystemWentUnderwater != storedState.timeSystemWentUnderwater) {
            require(ls.timeSystemWentUnderwater <= type(uint32).max, "timeSystemWentUnderwater overflow");
            bool isUnderwater = (ls.timeSystemWentUnderwater != 0);
            bool wasUnderwater = (storedState.timeSystemWentUnderwater != 0);
            // timeSystemWentUnderwater should only change between 0 and non-0, never from one non-0 to another:
            require(isUnderwater != wasUnderwater, "Unexpected timeSystemWentUnderwater change");
            emit UnderwaterStatusChanged(isUnderwater);
        }

        require(ls.ethUsdPriceTimestamp <= type(uint32).max, "ethUsdPriceTimestamp overflow");

        uint priceToStore = ls.ethUsdPrice + HALF_BILLION;
        unchecked { priceToStore /= BILLION; }
        if (priceToStore != storedState.ethUsdPrice) {
            require(priceToStore <= type(uint80).max, "ethUsdPrice overflow");
            unchecked { emit PriceChanged(ls.ethUsdPriceTimestamp, priceToStore * BILLION); }
        }

        require(ls.bidAskAdjustmentTimestamp <= type(uint32).max, "bidAskAdjustmentTimestamp overflow");

        uint adjustmentToStore = ls.bidAskAdjustment + HALF_BILLION;
        unchecked { adjustmentToStore /= BILLION; }
        if (adjustmentToStore != storedState.bidAskAdjustment) {
            require(adjustmentToStore <= type(uint80).max, "bidAskAdjustment overflow");
            unchecked { emit BidAskAdjustmentChanged(adjustmentToStore * BILLION); }
        }

        (storedState.timeSystemWentUnderwater,
         storedState.ethUsdPriceTimestamp, storedState.ethUsdPrice,
         storedState.bidAskAdjustmentTimestamp, storedState.bidAskAdjustment) =
            (uint32(ls.timeSystemWentUnderwater),
             uint32(ls.ethUsdPriceTimestamp), uint80(priceToStore),
             uint32(ls.bidAskAdjustmentTimestamp), uint80(adjustmentToStore));
    }

    // ____________________ Public Oracle view functions ____________________

    function latestPrice() public virtual override(IUSM, Oracle) view returns (uint price, uint updateTime) {
        (price, updateTime) = (storedState.ethUsdPrice * BILLION, storedState.ethUsdPriceTimestamp);
    }

    // ____________________ Public informational view functions ____________________

    function latestOraclePrice() public virtual override view returns (uint price, uint updateTime) {
        (price, updateTime) = oracle.latestPrice();
    }

    /**
     * @notice Total amount of ETH in the pool (ie, in the contract).
     * @return pool ETH pool
     */
    function ethPool() public override view returns (uint pool) {
        pool = address(this).balance;
    }

    function fumTotalSupply() public override view returns (uint supply) {
        supply = fum.totalSupply();
    }

    /**
     * @notice The current bid/ask adjustment, equal to the stored value decayed over time towards its stable value, 1.  This
     * adjustment is intended as a measure of "how long-ETH recent user activity has been", so that we can slide price
     * accordingly: if recent activity was mostly long-ETH (fund() and burn()), raise FUM buy price/reduce USM sell price; if
     * recent activity was short-ETH (defund() and mint()), reduce FUM sell price/raise USM buy price.
     * @return adjustment The sliding-price bid/ask adjustment
     */
    function bidAskAdjustment() public override view returns (uint adjustment) {
        adjustment = loadState().bidAskAdjustment;      // Not just from storedState, b/c need to update it - see loadState()
    }

    function timeSystemWentUnderwater() public override view returns (uint timestamp) {
        timestamp = storedState.timeSystemWentUnderwater;
    }

    // ____________________ Public helper view functions (for functions above) ____________________

    function loadState() public view returns (LoadedState memory ls) {
        ls.timeSystemWentUnderwater = storedState.timeSystemWentUnderwater;
        ls.ethUsdPriceTimestamp = storedState.ethUsdPriceTimestamp;
        ls.ethUsdPrice = storedState.ethUsdPrice * BILLION;     // Converting stored BILLION (10**9) format to WAD (10**18)

        // Bring bidAskAdjustment up to the present - it gravitates towards 1 over time, so the stored value is obsolete:
        ls.bidAskAdjustmentTimestamp = block.timestamp;
        ls.bidAskAdjustment = bidAskAdjustment(storedState.bidAskAdjustmentTimestamp,
                                               storedState.bidAskAdjustment * BILLION,
                                               block.timestamp);

        ls.ethPool = ethPool();
        ls.usmTotalSupply = totalSupply();
    }

    // ____________________ Public helper pure functions (for functions above) ____________________

    /**
     * @notice Calculate the amount of ETH in the buffer.
     * @return buffer ETH buffer
     */
    function ethBuffer(uint ethUsdPrice, uint ethInPool, uint usmSupply, WadMath.Round upOrDown)
        public override pure returns (int buffer)
    {
        // Reverse the input upOrDown, since we're using it for usmToEth(), which will be *subtracted* from ethInPool below:
        WadMath.Round downOrUp = (upOrDown == WadMath.Round.Down ? WadMath.Round.Up : WadMath.Round.Down);
        buffer = int(ethInPool) - int(usmToEth(ethUsdPrice, usmSupply, downOrUp));
        require(buffer <= int(ethInPool), "Underflow error");
    }

    /**
     * @notice Calculate debt ratio for a given eth to USM price: ratio of the outstanding USM (amount of USM in total supply),
     * to the current ETH pool value in USD (ETH qty * ETH/USD price).
     * @return ratio Debt ratio (or 0 if there's currently 0 ETH in the pool/price = 0: these should never happen after launch)
     */
    function debtRatio(uint ethUsdPrice, uint ethInPool, uint usmSupply) public override pure returns (uint ratio) {
        uint ethPoolValueInUsd = ethInPool.wadMulDown(ethUsdPrice);
        ratio = (ethPoolValueInUsd == 0 ? 0 : usmSupply.wadDivUp(ethPoolValueInUsd));
    }

    /**
     * @notice Convert ETH amount to USM using a ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return usmOut The amount of USM
     */
    function ethToUsm(uint ethUsdPrice, uint ethAmount, WadMath.Round upOrDown) public override pure returns (uint usmOut) {
        usmOut = ethAmount.wadMul(ethUsdPrice, upOrDown);
    }

    /**
     * @notice Convert USM amount to ETH using a ETH/USD price.
     * @param usmAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function usmToEth(uint ethUsdPrice, uint usmAmount, WadMath.Round upOrDown) public override pure returns (uint ethOut) {
        ethOut = usmAmount.wadDiv(ethUsdPrice, upOrDown);
    }

    /**
     * @notice Calculate the *marginal* price of USM (in ETH terms): that is, of the next unit, before the price start sliding.
     * @return price USM price in ETH terms
     */
    function usmPrice(IUSM.Side side, uint ethUsdPrice, uint adjustment) public override pure returns (uint price) {
        WadMath.Round upOrDown = (side == IUSM.Side.Buy ? WadMath.Round.Up : WadMath.Round.Down);
        price = usmToEth(ethUsdPrice, WAD, upOrDown);

        // Apply the adjustment if (side == Buy and adj < 1), or (side == Sell and adj > 1).  You may be thinking "Wait!  I
        // thought the way the adjustment worked was, an adj > 1 was applied when we're *buying,* not selling."  And your
        // understanding was correct: the catch is that here we're "buying" USM, which is economically like *selling* ETH.
        if (side == IUSM.Side.Buy ? (adjustment < WAD) : (adjustment > WAD)) {
            price = price.wadDiv(adjustment, upOrDown);
        }
    }

    /**
     * @notice Calculate the *marginal* price of FUM (in ETH terms): that is, of the next unit, before the price start sliding.
     * @param usmEffectiveSupply should be either the actual current USM supply, or, when calculating the FUM *buy* price, the
     * `usmSupplyForFumBuys` return value from `checkIfUnderwater()`.
     * @return price FUM price in ETH terms
     */
    function fumPrice(IUSM.Side side, uint ethUsdPrice, uint ethInPool, uint usmEffectiveSupply, uint fumSupply,
                      uint adjustment)
        public override pure returns (uint price)
    {
        WadMath.Round upOrDown = (side == IUSM.Side.Buy ? WadMath.Round.Up : WadMath.Round.Down);
        if (fumSupply == 0) {
            price = usmToEth(ethUsdPrice, WAD, upOrDown);   // if no FUM issued yet, default fumPrice to 1 USD (in ETH terms)
        } else {
            // Using usmEffectiveSupply here, rather than just the raw actual supply, has the effect of bumping the FUM price
            // up to the minFumBuyPrice when needed (ie, when debt ratio > MAX_DEBT_RATIO):
            int buffer = ethBuffer(ethUsdPrice, ethInPool, usmEffectiveSupply, upOrDown);
            price = (buffer <= 0 ? 0 : uint(buffer).wadDiv(fumSupply, upOrDown));

            // Unlike the counterintuitive case in usmPrice() above, here "Buy" = buying FUM = economically buying ETH:
            if (side == IUSM.Side.Buy ? (adjustment > WAD) : (adjustment < WAD)) {
                price = price.wadMul(adjustment, upOrDown);
            }
        }
    }

    /**
     * @return timeSystemWentUnderwater_ The time at which we first detected the system was underwater (debt ratio >
     * MAX_DEBT_RATIO), based on the current oracle price and pool ETH and USM; or 0 if we're not currently underwater.
     * @return usmSupplyForFumBuys The current supply of USM *for purposes of calculating the FUM buy price,* and therefore
     * for `fumFromFund()`.  The "supply for FUM buys" is the *lesser* of the actual current USM supply, and the USM amount
     * that would make debt ratio = MAX_DEBT_RATIO.  Example:
     *
     * 1. Suppose the system currently contains 50 ETH at price $1,000 (total pool value: $50,000), with an actual USM supply
     *    of 30,000 USM.  Then debt ratio = 30,000 / $50,000 = 60%: < MAX 80%, so `usmSupplyForFumBuys` = 30,000.
     * 2. Now suppose ETH/USD halves to $500.  Then pool value halves to $25,000, and debt ratio doubles to 120%.  Now
     *    `usmSupplyForFumBuys` instead = 20,000: the USM quantity at which debt ratio would equal 80% (20,000 / $25,000).
     *    (Call this the "80% supply".)
     * 3. ...Except, we also gradually increase the supply over time while we remain underwater.  This has the effect of
     *    *reducing* the FUM buy price inferred from that supply (higher JacobUSM supply -> smaller buffer -> lower FUM price).
     *    The math we use gradually increases the supply from its initial "80% supply" value, where debt ratio = MAX_DEBT_RATIO
     *    (20,000 above), to a theoretical maximum "100% supply" value, where debt ratio = 100% (in the $500 example above,
     *    this would be 25,000).  (Or the actual supply, whichever is lower: we never increase `usmSupplyForFumBuys` above
     *    `usmActualSupply`.)  The climb from the initial 80% supply (20,000) to the 100% supply (25,000) is at a rate that
     *    brings it "halfway closer per MIN_FUM_BUY_PRICE_HALF_LIFE (eg, 1 day)": so three days after going underwater, the
     *    supply returned will be 25,000 - 0.5**3 * (25,000 - 20,000) = 24,375.
     */
    function checkIfUnderwater(uint usmActualSupply, uint ethPool_, uint ethUsdPrice, uint oldTimeUnderwater, uint currentTime)
        public override pure returns (uint timeSystemWentUnderwater_, uint usmSupplyForFumBuys)
    {
        uint debtRatio_ = debtRatio(ethUsdPrice, ethPool_, usmActualSupply);
        if (debtRatio_ <= MAX_DEBT_RATIO) {            // We're not underwater, so leave timeSystemWentUnderwater_ as 0
            usmSupplyForFumBuys = usmActualSupply;     // When not underwater, USM supply for FUM buys is just actual supply
        } else {                                       // We're underwater
            // Set timeSystemWentUnderwater_ to currentTime, if it wasn't already set:
            timeSystemWentUnderwater_ = (oldTimeUnderwater != 0 ? oldTimeUnderwater : currentTime);

            // Calculate usmSupplyForFumBuys:
            uint maxEffectiveDebtRatio = debtRatio_.wadMin(WAD);    // min(actual debt ratio, 100%)
            uint numHalvings = (currentTime - timeSystemWentUnderwater_).wadDivDown(MIN_FUM_BUY_PRICE_HALF_LIFE);
            uint decayFactor = numHalvings.wadHalfExp();
            uint effectiveDebtRatio = maxEffectiveDebtRatio - decayFactor.wadMulUp(maxEffectiveDebtRatio - MAX_DEBT_RATIO);
            usmSupplyForFumBuys = effectiveDebtRatio.wadMulDown(ethPool_.wadMulDown(ethUsdPrice));
        }
    }

    /**
     * @notice Returns the given stored bidAskAdjustment value, updated (decayed towards 1) to the current time.
     */
    function bidAskAdjustment(uint storedTime, uint storedAdjustment, uint currentTime) public pure returns (uint adjustment) {
        uint numHalvings = (currentTime - storedTime).wadDivDown(BID_ASK_ADJUSTMENT_HALF_LIFE);
        uint decayFactor = numHalvings.wadHalfExp(10);
        // Here we use the idea that for any b and 0 <= p <= 1, we can crudely approximate b**p by 1 + (b-1)p = 1 + bp - p.
        // Eg: 0.6**0.5 pulls 0.6 "about halfway" to 1 (0.8); 0.6**0.25 pulls 0.6 "about 3/4 of the way" to 1 (0.9).
        // So b**p =~ b + (1-p)(1-b) = b + 1 - b - p + bp = 1 + bp - p.
        // (Don't calculate it as 1 + (b-1)p because we're using uints, b-1 can be negative!)
        adjustment = WAD + storedAdjustment.wadMulDown(decayFactor) - decayFactor;
    }

    /**
     * @notice How much USM a minter currently gets back for ethIn ETH, accounting for adjustment and sliding prices.
     * @param ethIn The amount of ETH passed to mint()
     * @return usmOut The amount of USM to receive in exchange
     */
    function usmFromMint(LoadedState memory ls, uint ethIn)
        public pure returns (uint usmOut, uint adjShrinkFactor)
    {
        // The USM buy price we pay, in ETH terms, "slides up" as we buy, proportional to the ETH in the pool: if the pool
        // starts with 100 ETH, and ethIn = 5, so we're increasing it to 105, then our USM buy price increases smoothly by 5%
        // during the mint operation.  (Buying USM with ETH is economically equivalent to selling ETH for USD: so this is
        // equivalent to saying that the ETH price used to price our USM *decreases* smoothly by 5% during the operation.)  Of
        // that 5%, "half" (in log space) is the ETH *mid* price dropping, and the other half is the bidAskAdjustment (ETH sell
        // price discount) dropping.  Calculating the total amount of USM minted then involves summing an integral over
        // 1 / usmBuyPrice, which gives the simple logarithm below.
        uint usmBuyPrice0 = usmPrice(IUSM.Side.Buy, ls.ethUsdPrice, ls.bidAskAdjustment);
        uint ethPool1 = ls.ethPool + ethIn;

        //adjShrinkFactor = ls.ethPool.wadDivDown(ethPool1).wadSqrt();      // Another possible fn we could use (same result)
        adjShrinkFactor = ls.ethPool.wadDivDown(ethPool1).wadExp(HALF_WAD);

        // The integral part - calculating the amount of USM minted at our sliding-up USM price:
        int log = ethPool1.wadDivDown(ls.ethPool).wadLog();
        require(log >= 0, "log underflow");
        usmOut = ls.ethPool.wadDivDown(usmBuyPrice0).wadMulDown(uint(log));
    }

    /**
     * @notice How much ETH a burner currently gets from burning usmIn USM, accounting for adjustment and sliding prices.
     * @param usmIn The amount of USM passed to burn()
     * @return ethOut The amount of ETH to receive in exchange
     */
    function ethFromBurn(LoadedState memory ls, uint usmIn)
        public pure returns (uint ethOut, uint adjGrowthFactor)
    {
        // Burn USM at a sliding-down USM price (ie, a sliding-up ETH price).  This is just the mirror image of the math in
        // usmFromMint() above, but because we're calculating output ETH from input USM rather than the other way around, we
        // end up with an exponent (exponent.wadExp() below, aka e**exponent) rather than a logarithm.
        uint usmSellPrice0 = usmPrice(IUSM.Side.Sell, ls.ethUsdPrice, ls.bidAskAdjustment);

        // The integral - calculating the amount of ETH yielded by burning the USM at our sliding-down USM price:
        uint exponent = usmIn.wadMulDown(usmSellPrice0).wadDivDown(ls.ethPool);
        uint ethPool1 = ls.ethPool.wadDivUp(exponent.wadExp());
        ethOut = ls.ethPool - ethPool1;

        // In this case we back out the adjGrowthFactor (change in mid price and bidAskAdj) from the change in the ETH pool:
        adjGrowthFactor = ls.ethPool.wadDivUp(ethPool1).wadExp(HALF_WAD);
    }

    /**
     * @notice How much FUM a funder currently gets back for ethIn ETH, accounting for adjustment and sliding prices.  Note
     * that we expect `ls.usmTotalSupply` of the LoadedState passed in to not necessarily be the actual current total USM
     * supply, but the *effective* USM supply for purposes of this operation - which can be a lower number, artificially
     * increasing the FUM price.  This is our "minFumBuyPrice" logic, used to prevent FUM buyers from paying tiny or negative
     * prices when the system is underwater or near it.
     * @param ethIn The amount of ETH passed to fund()
     * @return fumOut The amount of FUM to receive in exchange
     */
    function fumFromFund(LoadedState memory ls, uint fumSupply, uint ethIn)
        public pure returns (uint fumOut, uint adjGrowthFactor)
    {
        if (ls.ethPool == 0) {
            // No ETH in the system yet, which breaks our adjGrowthFactor calculation below - skip sliding-prices this time:
            adjGrowthFactor = WAD;
            uint fumBuyPrice0 = fumPrice(IUSM.Side.Buy, ls.ethUsdPrice, ls.ethPool, ls.usmTotalSupply, fumSupply,
                                         ls.bidAskAdjustment);
            fumOut = ethIn.wadDivDown(fumBuyPrice0);
        } else {
            // Create FUM at a sliding-up FUM price.  We follow the same broad strategy as in usmFromMint(): the effective ETH
            // price increases smoothly during the fund() operation, proportionally to the fraction by which the ETH pool
            // grows.  But there are a couple of extra nuances in the FUM case:
            //
            // 1. FUM is "leveraged"/"higher-delta" ETH, so minting 1 ETH worth of FUM should move the price by more than
            //    minting 1 ETH worth of USM does.  (More by a "FUM delta" factor.)
            // 2. The theoretical FUM price is based on the ETH buffer (excess ETH beyond what's needed to cover the oustanding
            //    USM), which is itself affected by/during this fund operation...
            //
            // The code below uses a "reasonable approximation" to deal with those complications.  See also the discussion in:
            // https://jacob-eliosoff.medium.com/usm-minimalist-decentralized-stablecoin-part-4-fee-math-decisions-a5be6ecfdd6f
            uint ethPool1 = ls.ethPool + ethIn;

            // 1. Start by calculating the "FUM delta" described above - the factor by which this operation will move the ETH
            // price more than a simple mint() operation.  Calculating the pure theoretical delta is a mess: we calculate the
            // initial delta and pretend it stays fixed thereafter.
            uint effectiveDebtRatio = debtRatio(ls.ethUsdPrice, ls.ethPool, ls.usmTotalSupply);
            uint effectiveFumDelta = WAD.wadDivUp(WAD - effectiveDebtRatio);

            // 2. Given the delta, we can calculate the adjGrowthFactor (price impact): for mint() (delta 1), the factor was
            // poolChangeFactor**(1 / 2); now instead we use poolChangeFactor**(fumDelta / 2).
            adjGrowthFactor = ethPool1.wadDivUp(ls.ethPool).wadExp(effectiveFumDelta / 2);

            // 3. Here we use a simplifying trick: we pretend our entire FUM purchase is done at a single fixed price.  For
            // that FUM price, we use the price we would get if we combined 1. the *initial* bidAskAdjustment (ie, before it's
            // increased by this fund operation), with the *ending* mid FUM price (ie, the mid FUM price implied by our
            // post-adjGrowthFactor ETH mid price).  This composite FUM price is guaranteed to be bounded below by our starting
            // FUM buy price calculated above, and bounded above by the FUM buy price we would start at if we immediately did
            // another fund operation, which are the key bounds we need to satisfy to avoid weird stuff like "The ETH price
            // increased but my FUM buy got cheaper."
            uint ethUsdPrice1 = ls.ethUsdPrice.wadMulUp(adjGrowthFactor);
            uint avgFumBuyPrice = ls.bidAskAdjustment.wadMulUp(
                (ls.ethPool - ls.usmTotalSupply.wadDivDown(ethUsdPrice1)).wadDivUp(fumSupply));
            fumOut = ethIn.wadDivDown(avgFumBuyPrice);
        }
    }

    /**
     * @notice How much ETH a defunder currently gets back for fumIn FUM, accounting for adjustment and sliding prices.
     * @param fumIn The amount of FUM passed to defund()
     * @return ethOut The amount of ETH to receive in exchange
     */
    function ethFromDefund(LoadedState memory ls, uint fumSupply, uint fumIn)
        public pure returns (uint ethOut, uint adjShrinkFactor)
    {
        // Burn FUM at a sliding-down FUM price.  Our approximation technique here resembles the one in fumFromFund() above,
        // but we need to be even more clever this time...

        // 1. Calculating the initial FUM sell price we start from is no problem:
        uint fumSellPrice0 = fumPrice(IUSM.Side.Sell, ls.ethUsdPrice, ls.ethPool, ls.usmTotalSupply, fumSupply,
                                      ls.bidAskAdjustment);

        // 2. Once again calculate the initial fumDelta, which we'll then keep fixed as a calculation convenience:
        //uint debtRatio0 = debtRatio(ls.ethUsdPrice, ls.ethPool, ls.usmTotalSupply);
        //uint fumDelta = WAD.wadDivUp(WAD - debtRatio0);
        uint fumDelta = WAD.wadDivUp(WAD - debtRatio(ls.ethUsdPrice, ls.ethPool, ls.usmTotalSupply));

        // 3. Now we want a "pessimistic" lower bound on the ending ETH pool qty.  We can get this by supposing the entire burn
        // happened at our initial fumSellPrice0: this is "optimistic" in terms of how much ETH we'd get back, but
        // "pessimistic" in the sense we want - how much ETH would be left in the pool:
        //uint lowerBoundEthQty1 = ls.ethPool - fumIn.wadMulUp(fumSellPrice0);  // Optimized away due to "stack too deep"...

        // 4. From this "pessimistic" lower bound on the ending ETH qty, we can calculate a "pessimistic" lower bound on our
        // ending adjShrinkFactor, ie, overstating how large an impact our burn could have on the ETH mid price:
        //uint lowerBoundAdjShrinkFactor = lowerBoundEthQty1.wadDivDown(ls.ethPool).wadExp(fumDelta / 2);
        uint lowerBoundAdjShrinkFactor = (ls.ethPool - fumIn.wadMulUp(fumSellPrice0)).wadDivDown(ls.ethPool).wadExp(
            fumDelta / 2);

        // 5. From the "pessimistic" lowerBoundAdjShrinkFactor, we can easily infer a lower bound on what the ETH mid price
        // can end up at:
        uint lowerBoundEthUsdPrice1 = ls.ethUsdPrice.wadMulDown(lowerBoundAdjShrinkFactor);

        // 6. This ending ETH mid price lowerBoundEthUsdPrice1 implies a FUM price (initial ETH buffer value based on that
        // price, divided by initial FUM qty).  So we just use this FUM price as our average FUM sell price for the entire
        // burn, and use that to calculate ethOut by a simple multiplication.  For small trades this will still equate to a
        // 0-fee op: for larger trades the pessimism has a larger impact (lower proportional ethOut, higher implicit fee).
        uint avgFumSellPrice = fumPrice(IUSM.Side.Sell, lowerBoundEthUsdPrice1, ls.ethPool, ls.usmTotalSupply, fumSupply,
                                        ls.bidAskAdjustment);
        ethOut = fumIn.wadMulDown(avgFumSellPrice);

        // 7. And now that we know the ending amount of ETH in the pool, we can back out the adjShrinkFactor:
        uint ethPool1 = ls.ethPool - ethOut;
        adjShrinkFactor = ethPool1.wadDivDown(ls.ethPool).wadExp(fumDelta / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../external/DiaOracle.sol";
import "./Oracle.sol";

/**
 * @title DiaOracleAdapter
 */
contract DiaOracleAdapter is Oracle {
    using SafeMath for uint;
    uint public constant WAD = 10 ** 18;
    uint256 public constant DECIMAL_CORRECTION = 10**13;

    DiaOracle public immutable oracle;
    string public syntheticFeed;
    string public collateralFeed;

    constructor(DiaOracle oracle_, string memory syntheticFeed_, string memory collateralFeed_) {
        oracle = oracle_;
        syntheticFeed = syntheticFeed_;
        collateralFeed = collateralFeed_;
    }

    /**
     * @notice Retrieve the latest price of the price oracle.
     * @return price
     */
    function latestPrice() public virtual override view returns (uint price, uint updateTime) {
        (uint256 collateralPrice, uint256 collateralUpdateTime) = getDiaPrice(collateralFeed);
        (uint256 syntheticPrice, uint256 syntheticUpdateTime) = getDiaPrice(syntheticFeed);
        price = collateralPrice.mul(WAD).div(syntheticPrice);
        // TODO return time
        updateTime = Math.max(collateralUpdateTime, syntheticUpdateTime);
    }

    /**
     * @notice Retrieve the latest price of the price oracle.
     * @return price
     */
    function getDiaPrice(string memory ticker) private view returns(uint256, uint256) {
      (uint256 price, uint256 time) = oracle.getValue(ticker);
      return (price.mul(DECIMAL_CORRECTION), time);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/53516bc555a454862470e7860a9b5254db4d00f5/contracts/token/ERC20/ERC20Permit.sol
pragma solidity ^0.8.0;

import "acc-erc20/contracts/ERC20.sol";
import "./IERC2612.sol";

/**
 * @author Georgios Konstantopoulos
 * @dev Extension of {ERC20} that allows token holders to use their tokens
 * without sending any transactions by setting {IERC20-allowance} with a
 * signature using the {permit} method, and then spend them via
 * {IERC20-transferFrom}.
 *
 * The {permit} signature mechanism conforms to the {IERC2612} interface.
 */
abstract contract ERC20Permit is ERC20, IERC2612 {
    mapping (address => uint256) public override nonces;

    bytes32 public immutable PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name_)),
                keccak256(bytes(version())),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Setting the version as a function so that it can be overriden
    function version() public pure virtual returns(string memory) { return "1"; }

    /**
     * @dev See {IERC2612-permit}.
     *
     * In cases where the free option is not a concern, deadline can simply be
     * set to uint(-1), so it should be seen as an optional parameter
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        require(deadline >= block.timestamp, "ERC20Permit: expired deadline");

        bytes32 hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                amount,
                nonces[owner]++,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(
            signer != address(0) && signer == owner,
            "ERC20Permit: invalid signature"
        );

        _approve(owner, spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "acc-erc20/contracts/IERC20.sol";
import "./WadMath.sol";

abstract contract IUSM is IERC20 {
    enum Side {Buy, Sell}

    function mint(address to, uint minUsmOut) external virtual payable returns (uint);
    function burn(address from, address payable to, uint usmToBurn, uint minEthOut) external virtual returns (uint);
    function fund(address to, uint minFumOut) external virtual payable returns (uint);
    function defund(address from, address payable to, uint fumToBurn, uint minEthOut) external virtual returns (uint);

    function refreshPrice() public virtual returns (uint price, uint updateTime);

    function latestPrice() public virtual view returns (uint price, uint updateTime);
    function latestOraclePrice() public virtual view returns (uint price, uint updateTime);
    function ethPool() public virtual view returns (uint pool);
    function fumTotalSupply() public virtual view returns (uint supply);
    function bidAskAdjustment() public virtual view returns (uint adjustment);
    function timeSystemWentUnderwater() public virtual view returns (uint timestamp);

    function ethBuffer(uint ethUsdPrice, uint ethInPool, uint usmSupply, WadMath.Round upOrDown) public virtual pure returns (int buffer);
    function debtRatio(uint ethUsdPrice, uint ethInPool, uint usmSupply) public virtual pure returns (uint ratio);
    function ethToUsm(uint ethUsdPrice, uint ethAmount, WadMath.Round upOrDown) public virtual pure returns (uint usmOut);
    function usmToEth(uint ethUsdPrice, uint usmAmount, WadMath.Round upOrDown) public virtual pure returns (uint ethOut);
    function usmPrice(Side side, uint ethUsdPrice, uint debtRatio_) public virtual pure returns (uint price);
    function fumPrice(Side side, uint ethUsdPrice, uint ethInPool, uint usmEffectiveSupply, uint fumSupply, uint adjustment) public virtual pure returns (uint price);
    function checkIfUnderwater(uint usmActualSupply, uint ethPool_, uint ethUsdPrice, uint oldTimeUnderwater, uint currentTime) public virtual pure returns (uint timeSystemWentUnderwater_, uint usmSupplyForFumBuys);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


abstract contract WithOptOut {
    mapping(address => bool) public optedOut;  // true = address opted out of something

    constructor(address[] memory optedOut_) {
        for (uint i = 0; i < optedOut_.length; i++) {
            optedOut[optedOut_[i]] = true;
        }
    }

    modifier noOptOut(address target) {
        require(!optedOut[target], "Target opted out");
        _;
    }

    function optOut() public virtual {
        optedOut[msg.sender] = true;
    }

    function optBackIn() public virtual {
        optedOut[msg.sender] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

abstract contract Oracle {
    function latestPrice() public virtual view returns (uint price, uint updateTime);    // Prices WAD-scaled - 18 dec places

    function refreshPrice() public virtual returns (uint price, uint updateTime) {
        (price, updateTime) = latestPrice();    // Default implementation doesn't do any cacheing.  But override as needed
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


/// @dev Delegable enables users to delegate their account management to other users.
/// Delegable implements addDelegateBySignature, to add delegates using a signature instead of a separate transaction.
contract Delegable {
    event Delegate(address indexed user, address indexed delegate, bool enabled);

    // keccak256("Signature(address user,address delegate,uint256 nonce,uint256 deadline)");
    bytes32 public constant SIGNATURE_TYPEHASH = 0x0d077601844dd17f704bafff948229d27f33b57445915754dfe3d095fda2beb7;
    bytes32 public immutable DELEGABLE_DOMAIN;
    mapping(address => uint) public signatureCount;

    mapping(address => mapping(address => bool)) public delegated;

    constructor () {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DELEGABLE_DOMAIN = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("USMFUM")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @dev Require that msg.sender is the account holder or a delegate
    modifier onlyHolderOrDelegate(address holder, string memory errorMessage) {
        require(
            msg.sender == holder || delegated[holder][msg.sender],
            errorMessage
        );
        _;
    }

    /// @dev Enable a delegate to act on the behalf of caller
    function addDelegate(address delegate) public {
        _addDelegate(msg.sender, delegate);
    }

    /// @dev Stop a delegate from acting on the behalf of caller
    function revokeDelegate(address delegate) public {
        _revokeDelegate(msg.sender, delegate);
    }

    /// @dev Add a delegate through an encoded signature
    function addDelegateBySignature(address user, address delegate, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        require(deadline >= block.timestamp, "Delegable: Signature expired");

        bytes32 hashStruct = keccak256(
            abi.encode(
                SIGNATURE_TYPEHASH,
                user,
                delegate,
                signatureCount[user]++,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DELEGABLE_DOMAIN,
                hashStruct
            )
        );
        address signer = ecrecover(digest, v, r, s);
        require(
            signer != address(0) && signer == user,
            "Delegable: Invalid signature"
        );

        _addDelegate(user, delegate);
    }

    /// @dev Enable a delegate to act on the behalf of an user
    function _addDelegate(address user, address delegate) internal {
        require(!delegated[user][delegate], "Delegable: Already delegated");
        delegated[user][delegate] = true;
        emit Delegate(user, delegate, true);
    }

    /// @dev Stop a delegate from acting on the behalf of an user
    function _revokeDelegate(address user, address delegate) internal {
        require(delegated[user][delegate], "Delegable: Already undelegated");
        delegated[user][delegate] = false;
        emit Delegate(user, delegate, false);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;


/**
 * @title Fixed point arithmetic library
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 */
library WadMath {
    enum Round {Down, Up}

    uint public constant WAD = 10 ** 18;
    uint public constant WAD_MINUS_1 = WAD - 1;
    uint public constant WAD_OVER_10 = WAD / 10;
    uint public constant WAD_OVER_20 = WAD / 20;
    uint public constant HALF_TO_THE_ONE_TENTH = 933032991536807416;
    uint public constant LOG_2_WAD_SCALED = 158961593653514369813532673448321674075;   // log_2(10**18) * 2**121
    uint public constant LOG_2_E_SCALED_OVER_WAD = 3835341275459348170;                // log_2(e) * 2**121 / 10**18

    function wadMul(uint x, uint y, Round upOrDown) internal pure returns (uint z) {
        z = (upOrDown == Round.Down ? wadMulDown(x, y) : wadMulUp(x, y));
    }

    function wadMulDown(uint x, uint y) internal pure returns (uint z) {
        z = x * y;                  // Rounds down, truncating the last 18 digits.  So (imagining 2 dec places rather than 18):
        unchecked { z /= WAD; }     // 369 (3.69) * 271 (2.71) -> 99999 (9.9999) -> 999 (9.99).
    }

    function wadMulUp(uint x, uint y) internal pure returns (uint z) {
        z = x * y + WAD_MINUS_1;    // Rounds up.  So (again imagining 2 decimal places):
        unchecked { z /= WAD; }     // 383 (3.83) * 235 (2.35) -> 90005 (9.0005), + 99 (0.0099) -> 90104, / 100 -> 901 (9.01).
    }

    function wadDiv(uint x, uint y, Round upOrDown) internal pure returns (uint z) {
        z = (upOrDown == Round.Down ? wadDivDown(x, y) : wadDivUp(x, y));
    }

    function wadDivDown(uint x, uint y) internal pure returns (uint z) {
        z = (x * WAD) / y;          // Rounds down: 199 (1.99) / 1000 (10) -> (199 * 100) / 1000 -> 19 (0.19: 0.199 truncated).
    }

    function wadDivUp(uint x, uint y) internal pure returns (uint z) {
        z = x * WAD + y;            // 101 (1.01) / 1000 (10) -> (101 * 100 + 1000 - 1) / 1000 -> 11 (0.11 = 0.101 rounded up).
        unchecked { z -= 1; }       // Can do unchecked subtraction since division in next line will catch y = 0 case anyway
        z /= y;
    }

    function wadMax(uint x, uint y) internal pure returns (uint z) {
        z = (x > y ? x : y);
    }

    function wadMin(uint x, uint y) internal pure returns (uint z) {
        z = (x < y ? x : y);
    }

    /**
     * @return exp Just returns `wadHalfExp(power, MAX_VALUE)`, ie, an approximation of 0.5**`power`, with `power` uncapped.
     */
    function wadHalfExp(uint power) internal pure returns (uint exp) {
        exp = wadHalfExp(power, type(uint).max);
    }

    /**
     * @return exp a loose but "gas-efficient" approximation of 0.5**power, where power is rounded to the nearest 0.1, and is
     * capped at maxPower.  Note power is WAD-scaled (eg, 2.7364 * WAD), but maxPower is just a plain unscaled uint (eg, 10).
     * Negative powers are not handled (as implied by power being a uint).
     */
    function wadHalfExp(uint power, uint maxPower) internal pure returns (uint exp) {
        uint powerInTenthsUnscaled = power + WAD_OVER_20;       // Rounds 2.7499 -> 2.7, 2.7500 -> 2.8
        unchecked { powerInTenthsUnscaled /= WAD_OVER_10; }
        uint powerUnscaled;
        unchecked { powerUnscaled = powerInTenthsUnscaled / 10; }
        if (powerUnscaled <= maxPower) {    // If not, then 0.5**power is (more or less) tiny, so we just return exp = 0
            exp = wadPow(HALF_TO_THE_ONE_TENTH, powerInTenthsUnscaled);
        }
    }

    /**
     * @notice Adapted from rpow() in https://github.com/dapphub/ds-math/blob/master/src/math.sol - thank you!
     *
     * This famous algorithm is called "exponentiation by squaring" and calculates x^n with x as fixed-point and n as regular
     * unsigned.
     *
     * It's O(log n), instead of O(n) for naive repeated multiplication.
     *
     * These facts are why it works:
     *
     * - If n is even, then x^n = (x^2)^(n/2).
     * - If n is odd,  then x^n = x * x^(n-1),
     *   and applying the equation for even x gives
     *   x^n = x * (x^2)^((n-1) / 2).
     *
     * Also, EVM division is flooring and floor[(n-1) / 2] = floor[n / 2].
     */
    function wadPow(uint x, uint n) internal pure returns (uint z) {
        unchecked { z = n % 2 != 0 ? x : WAD; }

        unchecked { n /= 2; }
        bool divide;
        while (n != 0) {
            x = wadMulDown(x, x);

            unchecked { divide = n % 2 != 0; }
            if (divide) {
                z = wadMulDown(z, x);
            }
            unchecked { n /= 2; }
        }
    }

    /**
     * @return z The (approximate!) natural logarithm of x, where both x and the return value are in WAD fixed-point form.
     * @dev We're given X = x * 10**18 (WAD-formatted); we want to return Z = z * 10**18, where z =~ ln(x); and we have
     * `log_2(x)` below, which returns Y = y * 2**121, where y =~ log2(x).  So the math we use is:
     *
     *     K1 = log2(10**18) * 2**121
     *     K2 = log2(e) * 2**121 / 10**18
     *     Z = (`log_2(X)` - K1) / K2
     *       = (`log_2(x * 10**18)` - log2(10**18) * 2**121) / (log2(e) * 2**121 / 10**18)
     *       = (log2(x * 10**18) * 2**121 - log2(10**18) * 2**121) / (log2(e) * 2**121 / 10**18)
     *       = (log2(x * 10**18) - log2(10**18)) / (log2(e) / 10**18)
     *       = (log2(x) / log2(e)) * 10**18
     *       = ln(x) * 10**18
     */
    function wadLog(uint x) internal pure returns (int z) {
        require(x <= type(uint128).max, "x overflow");
        z = int(log_2(uint128(x)));
        unchecked { z = (z - int(LOG_2_WAD_SCALED)) / int(LOG_2_E_SCALED_OVER_WAD); }
    }

    /**
     * @return z e raised to the given power `y` (approximately!), specified in WAD 18-digit fixed-point form, and in, again,
     * WAD form.
     * @notice This library works only on positive uint inputs.  If you have a negative exponent (y < 0), you can calculate it
     * using this identity:
     *
     *     wadExp(y < 0) = 1 / wadExp(-y > 0) = WAD.div(wadExp(-y > 0))
     *
     * @dev We're given Y = y * 10**18 (WAD-formatted); we want to return Z = z * 10**18, where z =~ e**y; and we have
     * `pow_2(X = x * 2**121)` below, which returns y =~ 2**x = 2**(X / 2**121).  So the math we use is:
     *
     *     K1 = log2(10**18) * 2**121
     *     K2 = log2(e) * 2**121 / 10**18
     *     Z = `pow_2(K1 + K2 * Y)`
     *       = 2**((K1 + K2 * Y) / 2**121)
     *       = 2**((log2(10**18) * 2**121 + (log2(e) * 2**121 / 10**18) * (y * 10**18)) / 2**121)
     *       = 2**(log2(10**18) + log2(e) * y)
     *       = 2**(log2(10**18)) * 2**(log2(e) * y)
     *       = 10**18 * (2**log2(e))**y
     *       = e**y * 10**18
     */
    function wadExp(uint y) internal pure returns (uint z) {
        uint exponent = LOG_2_WAD_SCALED + LOG_2_E_SCALED_OVER_WAD * y;
        require(exponent <= type(uint128).max, "exponent overflow");
        z = pow_2(uint128(exponent));
    }

    /**
     * @return z The given number `x` raised to power `y` (approximately!), with all of `x`, `y` and `z` in WAD 18-digit
     * fixed-point form.
     * @notice This library works only on positive uint inputs.  If you have a negative base (x < 0) or a negative exponent
     * (y < 0), you can calculate them using these identities:
     *
     *     wadExp(x < 0, y) = -wadExp(-x > 0, y)
     *     wadExp(x, y < 0) = 1 / wadExp(x, -y > 0) = WAD.div(wadExp(x, -y > 0))
     *
     * @dev We're given X = x * 10**18, and Y = y * 10**18 (both WAD-formatted); we want Z = z * 10**18, where z =~ x**y; and
     * we have `log_2(x)`, which returns log2(x) * 2**121, and `pow_2(X = x * 2**121)`, which returns 2**x = 2**(X / 2**121).
     * The math we use is (essentially):
     *
     *     K = log2(10**18) * 2**121
     *     Z = `pow_2(K + (log_2(X) - K) * Y / 10**18)`
     *       = 2**((K + (log2(X) * 2**121 - K) * Y / 10**18) / 2**121)
     *       = 2**((log2(10**18) * 2**121 + (log2(x * 10**18) * 2**121 - log2(10**18) * 2**121) * (y * 10**18) / 10**18) / 2**121)
     *       = 2**(log2(10**18) + (log2(x * 10**18) - log2(10**18)) * y)
     *       = 2**(log2(10**18) + log2(x) * y)
     *       = 2**(log2(10**18)) * 2**(log2(x) * y)
     *       = 10**18 * (2**log2(x))**y
     *       = x**y * 10**18
     *
     * Except, because we're working with unsigned numbers, we need to be careful to handle two cases separately:
     * log_2(X) >= K, and log_2(X) < K.
     */
    function wadExp(uint x, uint y) internal pure returns (uint z) {
        require(x <= type(uint128).max, "x overflow");
        uint logX = log_2(uint128(x));
        uint exponent;
        if (logX >= LOG_2_WAD_SCALED) {
            // Case 1: Z = pow_2(LOG_2_WAD_SCALED + (log_2(X) - LOG_2_WAD_SCALED) * Y / WAD):
            unchecked { exponent = logX - LOG_2_WAD_SCALED; }
            exponent = LOG_2_WAD_SCALED + wadMulDown(exponent, y);
            require(exponent <= type(uint128).max, "exponent overflow");
            z = pow_2(uint128(exponent));
        } else {
            // Case 2: Z = pow_2(LOG_2_WAD_SCALED - (LOG_2_WAD_SCALED - log_2(X)) * Y / WAD):
            uint exponentSubtrahend;
            unchecked { exponentSubtrahend = LOG_2_WAD_SCALED - logX; }
            exponentSubtrahend = wadMulDown(exponentSubtrahend, y);
            if (exponentSubtrahend <= LOG_2_WAD_SCALED) {
                unchecked { exponent = LOG_2_WAD_SCALED - exponentSubtrahend; }
                z = pow_2(uint128(exponent));   // Needn't check for overflow since exp <= LOG_2_WAD_SCALED < type(uint128).max
            } else {
                // z = 0: exponent would be < 0, so pow_2(exponent) is vanishingly small (as a WAD-formatted num) - call it 0
            }
        }
    }

    /* ____________________ Exponential/logarithm fns borrowed from Yield Protocol ____________________
     *
     * See https://github.com/yieldprotocol/yieldspace-v1/blob/master/contracts/YieldMath.sol for Yield's code, originally
     * developed by the math gurus at https://www.abdk.consulting/.
     */

    /**
     * Calculate base 2 logarithm of an unsigned 128-bit integer number.  Revert in case x is zero.
     *
     * @param x number to calculate base 2 logarithm of
     * @return z base 2 logarithm of x, multiplied by 2^121
     */
    function log_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            require (x != 0, "x = 0");

            uint b = x;

            uint l = 0xFE000000000000000000000000000000;

            if (b < 0x10000000000000000) {l -= 0x80000000000000000000000000000000; b <<= 64;}
            if (b < 0x1000000000000000000000000) {l -= 0x40000000000000000000000000000000; b <<= 32;}
            if (b < 0x10000000000000000000000000000) {l -= 0x20000000000000000000000000000000; b <<= 16;}
            if (b < 0x1000000000000000000000000000000) {l -= 0x10000000000000000000000000000000; b <<= 8;}
            if (b < 0x10000000000000000000000000000000) {l -= 0x8000000000000000000000000000000; b <<= 4;}
            if (b < 0x40000000000000000000000000000000) {l -= 0x4000000000000000000000000000000; b <<= 2;}
            if (b < 0x80000000000000000000000000000000) {l -= 0x2000000000000000000000000000000; b <<= 1;}

            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000000;}
            /* Precision reduced to 64 bits
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x1000;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x800;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x400;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x200;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x100;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x80;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x40;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x20;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x10;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x8;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x4;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) {b >>= 1; l |= 0x2;}
            b = b * b >> 127; if (b >= 0x100000000000000000000000000000000) l |= 0x1;
            */

            z = uint128(l);
        }
    }

    /**
     * Calculate 2 raised into given power.
     *
     * @param x power to raise 2 into, multiplied by 2^121
     * @return z 2 raised into given power
     */
    function pow_2(uint128 x)
        internal pure returns (uint128 z)
    {
        unchecked {
            uint r = 0x80000000000000000000000000000000;
            if (x & 0x1000000000000000000000000000000 > 0) r = r * 0xb504f333f9de6484597d89b3754abe9f >> 127;
            if (x & 0x800000000000000000000000000000 > 0) r = r * 0x9837f0518db8a96f46ad23182e42f6f6 >> 127;
            if (x & 0x400000000000000000000000000000 > 0) r = r * 0x8b95c1e3ea8bd6e6fbe4628758a53c90 >> 127;
            if (x & 0x200000000000000000000000000000 > 0) r = r * 0x85aac367cc487b14c5c95b8c2154c1b2 >> 127;
            if (x & 0x100000000000000000000000000000 > 0) r = r * 0x82cd8698ac2ba1d73e2a475b46520bff >> 127;
            if (x & 0x80000000000000000000000000000 > 0) r = r * 0x8164d1f3bc0307737be56527bd14def4 >> 127;
            if (x & 0x40000000000000000000000000000 > 0) r = r * 0x80b1ed4fd999ab6c25335719b6e6fd20 >> 127;
            if (x & 0x20000000000000000000000000000 > 0) r = r * 0x8058d7d2d5e5f6b094d589f608ee4aa2 >> 127;
            if (x & 0x10000000000000000000000000000 > 0) r = r * 0x802c6436d0e04f50ff8ce94a6797b3ce >> 127;
            if (x & 0x8000000000000000000000000000 > 0) r = r * 0x8016302f174676283690dfe44d11d008 >> 127;
            if (x & 0x4000000000000000000000000000 > 0) r = r * 0x800b179c82028fd0945e54e2ae18f2f0 >> 127;
            if (x & 0x2000000000000000000000000000 > 0) r = r * 0x80058baf7fee3b5d1c718b38e549cb93 >> 127;
            if (x & 0x1000000000000000000000000000 > 0) r = r * 0x8002c5d00fdcfcb6b6566a58c048be1f >> 127;
            if (x & 0x800000000000000000000000000 > 0) r = r * 0x800162e61bed4a48e84c2e1a463473d9 >> 127;
            if (x & 0x400000000000000000000000000 > 0) r = r * 0x8000b17292f702a3aa22beacca949013 >> 127;
            if (x & 0x200000000000000000000000000 > 0) r = r * 0x800058b92abbae02030c5fa5256f41fe >> 127;
            if (x & 0x100000000000000000000000000 > 0) r = r * 0x80002c5c8dade4d71776c0f4dbea67d6 >> 127;
            if (x & 0x80000000000000000000000000 > 0) r = r * 0x8000162e44eaf636526be456600bdbe4 >> 127;
            if (x & 0x40000000000000000000000000 > 0) r = r * 0x80000b1721fa7c188307016c1cd4e8b6 >> 127;
            if (x & 0x20000000000000000000000000 > 0) r = r * 0x8000058b90de7e4cecfc487503488bb1 >> 127;
            if (x & 0x10000000000000000000000000 > 0) r = r * 0x800002c5c8678f36cbfce50a6de60b14 >> 127;
            if (x & 0x8000000000000000000000000 > 0) r = r * 0x80000162e431db9f80b2347b5d62e516 >> 127;
            if (x & 0x4000000000000000000000000 > 0) r = r * 0x800000b1721872d0c7b08cf1e0114152 >> 127;
            if (x & 0x2000000000000000000000000 > 0) r = r * 0x80000058b90c1aa8a5c3736cb77e8dff >> 127;
            if (x & 0x1000000000000000000000000 > 0) r = r * 0x8000002c5c8605a4635f2efc2362d978 >> 127;
            if (x & 0x800000000000000000000000 > 0) r = r * 0x800000162e4300e635cf4a109e3939bd >> 127;
            if (x & 0x400000000000000000000000 > 0) r = r * 0x8000000b17217ff81bef9c551590cf83 >> 127;
            if (x & 0x200000000000000000000000 > 0) r = r * 0x800000058b90bfdd4e39cd52c0cfa27c >> 127;
            if (x & 0x100000000000000000000000 > 0) r = r * 0x80000002c5c85fe6f72d669e0e76e411 >> 127;
            if (x & 0x80000000000000000000000 > 0) r = r * 0x8000000162e42ff18f9ad35186d0df28 >> 127;
            if (x & 0x40000000000000000000000 > 0) r = r * 0x80000000b17217f84cce71aa0dcfffe7 >> 127;
            if (x & 0x20000000000000000000000 > 0) r = r * 0x8000000058b90bfc07a77ad56ed22aaa >> 127;
            if (x & 0x10000000000000000000000 > 0) r = r * 0x800000002c5c85fdfc23cdead40da8d6 >> 127;
            if (x & 0x8000000000000000000000 > 0) r = r * 0x80000000162e42fefc25eb1571853a66 >> 127;
            if (x & 0x4000000000000000000000 > 0) r = r * 0x800000000b17217f7d97f692baacded5 >> 127;
            if (x & 0x2000000000000000000000 > 0) r = r * 0x80000000058b90bfbead3b8b5dd254d7 >> 127;
            if (x & 0x1000000000000000000000 > 0) r = r * 0x8000000002c5c85fdf4eedd62f084e67 >> 127;
            if (x & 0x800000000000000000000 > 0) r = r * 0x800000000162e42fefa58aef378bf586 >> 127;
            if (x & 0x400000000000000000000 > 0) r = r * 0x8000000000b17217f7d24a78a3c7ef02 >> 127;
            if (x & 0x200000000000000000000 > 0) r = r * 0x800000000058b90bfbe9067c93e474a6 >> 127;
            if (x & 0x100000000000000000000 > 0) r = r * 0x80000000002c5c85fdf47b8e5a72599f >> 127;
            if (x & 0x80000000000000000000 > 0) r = r * 0x8000000000162e42fefa3bdb315934a2 >> 127;
            if (x & 0x40000000000000000000 > 0) r = r * 0x80000000000b17217f7d1d7299b49c46 >> 127;
            if (x & 0x20000000000000000000 > 0) r = r * 0x8000000000058b90bfbe8e9a8d1c4ea0 >> 127;
            if (x & 0x10000000000000000000 > 0) r = r * 0x800000000002c5c85fdf4745969ea76f >> 127;
            if (x & 0x8000000000000000000 > 0) r = r * 0x80000000000162e42fefa3a0df5373bf >> 127;
            if (x & 0x4000000000000000000 > 0) r = r * 0x800000000000b17217f7d1cff4aac1e1 >> 127;
            if (x & 0x2000000000000000000 > 0) r = r * 0x80000000000058b90bfbe8e7db95a2f1 >> 127;
            if (x & 0x1000000000000000000 > 0) r = r * 0x8000000000002c5c85fdf473e61ae1f8 >> 127;
            if (x & 0x800000000000000000 > 0) r = r * 0x800000000000162e42fefa39f121751c >> 127;
            if (x & 0x400000000000000000 > 0) r = r * 0x8000000000000b17217f7d1cf815bb96 >> 127;
            if (x & 0x200000000000000000 > 0) r = r * 0x800000000000058b90bfbe8e7bec1e0d >> 127;
            if (x & 0x100000000000000000 > 0) r = r * 0x80000000000002c5c85fdf473dee5f17 >> 127;
            if (x & 0x80000000000000000 > 0) r = r * 0x8000000000000162e42fefa39ef5438f >> 127;
            if (x & 0x40000000000000000 > 0) r = r * 0x80000000000000b17217f7d1cf7a26c8 >> 127;
            if (x & 0x20000000000000000 > 0) r = r * 0x8000000000000058b90bfbe8e7bcf4a4 >> 127;
            if (x & 0x10000000000000000 > 0) r = r * 0x800000000000002c5c85fdf473de72a2 >> 127;
            /* Precision reduced to 64 bits
            if (x & 0x8000000000000000 > 0) r = r * 0x80000000000000162e42fefa39ef3765 >> 127;
            if (x & 0x4000000000000000 > 0) r = r * 0x800000000000000b17217f7d1cf79b37 >> 127;
            if (x & 0x2000000000000000 > 0) r = r * 0x80000000000000058b90bfbe8e7bcd7d >> 127;
            if (x & 0x1000000000000000 > 0) r = r * 0x8000000000000002c5c85fdf473de6b6 >> 127;
            if (x & 0x800000000000000 > 0) r = r * 0x800000000000000162e42fefa39ef359 >> 127;
            if (x & 0x400000000000000 > 0) r = r * 0x8000000000000000b17217f7d1cf79ac >> 127;
            if (x & 0x200000000000000 > 0) r = r * 0x800000000000000058b90bfbe8e7bcd6 >> 127;
            if (x & 0x100000000000000 > 0) r = r * 0x80000000000000002c5c85fdf473de6a >> 127;
            if (x & 0x80000000000000 > 0) r = r * 0x8000000000000000162e42fefa39ef35 >> 127;
            if (x & 0x40000000000000 > 0) r = r * 0x80000000000000000b17217f7d1cf79a >> 127;
            if (x & 0x20000000000000 > 0) r = r * 0x8000000000000000058b90bfbe8e7bcd >> 127;
            if (x & 0x10000000000000 > 0) r = r * 0x800000000000000002c5c85fdf473de6 >> 127;
            if (x & 0x8000000000000 > 0) r = r * 0x80000000000000000162e42fefa39ef3 >> 127;
            if (x & 0x4000000000000 > 0) r = r * 0x800000000000000000b17217f7d1cf79 >> 127;
            if (x & 0x2000000000000 > 0) r = r * 0x80000000000000000058b90bfbe8e7bc >> 127;
            if (x & 0x1000000000000 > 0) r = r * 0x8000000000000000002c5c85fdf473de >> 127;
            if (x & 0x800000000000 > 0) r = r * 0x800000000000000000162e42fefa39ef >> 127;
            if (x & 0x400000000000 > 0) r = r * 0x8000000000000000000b17217f7d1cf7 >> 127;
            if (x & 0x200000000000 > 0) r = r * 0x800000000000000000058b90bfbe8e7b >> 127;
            if (x & 0x100000000000 > 0) r = r * 0x80000000000000000002c5c85fdf473d >> 127;
            if (x & 0x80000000000 > 0) r = r * 0x8000000000000000000162e42fefa39e >> 127;
            if (x & 0x40000000000 > 0) r = r * 0x80000000000000000000b17217f7d1cf >> 127;
            if (x & 0x20000000000 > 0) r = r * 0x8000000000000000000058b90bfbe8e7 >> 127;
            if (x & 0x10000000000 > 0) r = r * 0x800000000000000000002c5c85fdf473 >> 127;
            if (x & 0x8000000000 > 0) r = r * 0x80000000000000000000162e42fefa39 >> 127;
            if (x & 0x4000000000 > 0) r = r * 0x800000000000000000000b17217f7d1c >> 127;
            if (x & 0x2000000000 > 0) r = r * 0x80000000000000000000058b90bfbe8e >> 127;
            if (x & 0x1000000000 > 0) r = r * 0x8000000000000000000002c5c85fdf47 >> 127;
            if (x & 0x800000000 > 0) r = r * 0x800000000000000000000162e42fefa3 >> 127;
            if (x & 0x400000000 > 0) r = r * 0x8000000000000000000000b17217f7d1 >> 127;
            if (x & 0x200000000 > 0) r = r * 0x800000000000000000000058b90bfbe8 >> 127;
            if (x & 0x100000000 > 0) r = r * 0x80000000000000000000002c5c85fdf4 >> 127;
            if (x & 0x80000000 > 0) r = r * 0x8000000000000000000000162e42fefa >> 127;
            if (x & 0x40000000 > 0) r = r * 0x80000000000000000000000b17217f7d >> 127;
            if (x & 0x20000000 > 0) r = r * 0x8000000000000000000000058b90bfbe >> 127;
            if (x & 0x10000000 > 0) r = r * 0x800000000000000000000002c5c85fdf >> 127;
            if (x & 0x8000000 > 0) r = r * 0x80000000000000000000000162e42fef >> 127;
            if (x & 0x4000000 > 0) r = r * 0x800000000000000000000000b17217f7 >> 127;
            if (x & 0x2000000 > 0) r = r * 0x80000000000000000000000058b90bfb >> 127;
            if (x & 0x1000000 > 0) r = r * 0x8000000000000000000000002c5c85fd >> 127;
            if (x & 0x800000 > 0) r = r * 0x800000000000000000000000162e42fe >> 127;
            if (x & 0x400000 > 0) r = r * 0x8000000000000000000000000b17217f >> 127;
            if (x & 0x200000 > 0) r = r * 0x800000000000000000000000058b90bf >> 127;
            if (x & 0x100000 > 0) r = r * 0x80000000000000000000000002c5c85f >> 127;
            if (x & 0x80000 > 0) r = r * 0x8000000000000000000000000162e42f >> 127;
            if (x & 0x40000 > 0) r = r * 0x80000000000000000000000000b17217 >> 127;
            if (x & 0x20000 > 0) r = r * 0x8000000000000000000000000058b90b >> 127;
            if (x & 0x10000 > 0) r = r * 0x800000000000000000000000002c5c85 >> 127;
            if (x & 0x8000 > 0) r = r * 0x80000000000000000000000000162e42 >> 127;
            if (x & 0x4000 > 0) r = r * 0x800000000000000000000000000b1721 >> 127;
            if (x & 0x2000 > 0) r = r * 0x80000000000000000000000000058b90 >> 127;
            if (x & 0x1000 > 0) r = r * 0x8000000000000000000000000002c5c8 >> 127;
            if (x & 0x800 > 0) r = r * 0x800000000000000000000000000162e4 >> 127;
            if (x & 0x400 > 0) r = r * 0x8000000000000000000000000000b172 >> 127;
            if (x & 0x200 > 0) r = r * 0x800000000000000000000000000058b9 >> 127;
            if (x & 0x100 > 0) r = r * 0x80000000000000000000000000002c5c >> 127;
            if (x & 0x80 > 0) r = r * 0x8000000000000000000000000000162e >> 127;
            if (x & 0x40 > 0) r = r * 0x80000000000000000000000000000b17 >> 127;
            if (x & 0x20 > 0) r = r * 0x8000000000000000000000000000058b >> 127;
            if (x & 0x10 > 0) r = r * 0x800000000000000000000000000002c5 >> 127;
            if (x & 0x8 > 0) r = r * 0x80000000000000000000000000000162 >> 127;
            if (x & 0x4 > 0) r = r * 0x800000000000000000000000000000b1 >> 127;
            if (x & 0x2 > 0) r = r * 0x80000000000000000000000000000058 >> 127;
            if (x & 0x1 > 0) r = r * 0x8000000000000000000000000000002c >> 127;
            */

            r >>= 127 - (x >> 121);

            z = uint128(r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "erc20permit/contracts/ERC20Permit.sol";
import "./IUSM.sol";
import "./WithOptOut.sol";
import "./Ownable.sol";
import "./MinOut.sol";
import "./IUSM.sol";


/**
 * @title FUM Token
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 *
 * @notice This should be owned by the stablecoin.
 */
contract FUM is ERC20Permit, WithOptOut, Ownable {
    IUSM public immutable usm;

    constructor(IUSM usm_, address[] memory optedOut_, string memory name, string memory symbol)
        ERC20Permit(name, symbol)
        WithOptOut(optedOut_)
    {
        usm = usm_;
    }

    /**
     * @notice If anyone sends ETH here, assume they intend it as a `fund`.
     * If decimals 8 to 11 (included) of the amount of Ether received are `0000` then the next 7 will
     * be parsed as the minimum Ether price accepted, with 2 digits before and 5 digits after the comma.
     */
    receive() external payable {
        usm.fund{ value: msg.value }(msg.sender, MinOut.parseMinTokenOut(msg.value));
    }

    /**
     * @notice If a user sends FUM tokens directly to this contract (or to the USM contract), assume they intend it as a `defund`.
     * If using `transfer`/`transferFrom` as `defund`, and if decimals 8 to 11 (included) of the amount transferred received
     * are `0000` then the next 7 will be parsed as the maximum FUM price accepted, with 5 digits before and 2 digits after the comma.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override noOptOut(recipient) returns (bool) {
        if (recipient == address(this) || recipient == address(usm) || recipient == address(0)) {
            usm.defund(sender, payable(sender), amount, MinOut.parseMinEthOut(amount));
        } else {
            super._transfer(sender, recipient, amount);
        }
        return true;
    }

    /**
     * @notice Mint new FUM to the _recipient
     *
     * @param _recipient address to mint to
     * @param _amount amount to mint
     */
    function mint(address _recipient, uint _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }

    /**
     * @notice Burn FUM from _holder
     *
     * @param _holder address to burn from
     * @param _amount amount to burn
     */
    function burn(address _holder, uint _amount) external onlyOwner {
        _burn(_holder, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library MinOut {
    function parseMinTokenOut(uint ethIn) internal pure returns (uint minTokenOut) {
        uint minPrice = ethIn % 100000000000;
        if (minPrice != 0 && minPrice < 10000000) {
            minTokenOut = ethIn * minPrice / 100;
        }
    }

    function parseMinEthOut(uint tokenIn) internal pure returns (uint minEthOut) {
        uint maxPrice = tokenIn % 100000000000;
        if (maxPrice != 0 && maxPrice < 10000000) {
            minEthOut = tokenIn * 100 / maxPrice;
        }
    }
}

// SPDX-License-Identifier: MIT
// Inspired on token.sol from DappHub

pragma solidity  ^0.8.0;
import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256                                           internal  _totalSupply;
    mapping (address => uint256)                      internal  _balanceOf;
    mapping (address => mapping (address => uint256)) internal  _allowance;
    string                                            public    symbol;
    uint256                                           public    decimals = 18; // standard token precision. override to customize
    string                                            public    name = "";     // Optional token name

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address guy) public view virtual override returns (uint256) {
        return _balanceOf[guy];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint wad) public virtual override returns (bool) {
        return _approve(msg.sender, spender, wad);
    }

    function transfer(address dst, uint wad) public virtual override returns (bool) {
        return _transfer(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public virtual override returns (bool) {
        uint256 allowed = _allowance[src][msg.sender];
        if (src != msg.sender && allowed != type(uint).max) {
            require(allowed >= wad, "ERC20: Insufficient approval");
            _approve(src, msg.sender, allowed - wad);
        }

        return _transfer(src, dst, wad);
    }

    function _transfer(address src, address dst, uint wad) internal virtual returns (bool) {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _balanceOf[dst] = _balanceOf[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function _approve(address owner, address spender, uint wad) internal virtual returns (bool) {
        _allowance[owner][spender] = wad;
        emit Approval(owner, spender, wad);
        return true;
    }

    function _mint(address dst, uint wad) internal virtual {
        _balanceOf[dst] = _balanceOf[dst] + wad;
        _totalSupply = _totalSupply + wad;
        emit Transfer(address(0), dst, wad);
    }

    function _burn(address src, uint wad) internal virtual {
        require(_balanceOf[src] >= wad, "ERC20: Insufficient balance");
        _balanceOf[src] = _balanceOf[src] - wad;
        _totalSupply = _totalSupply - wad;
        emit Transfer(src, address(0), wad);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// Original from OpenZeppelin

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract DiaOracle {
    mapping (string => uint256) public values;
    address oracleUpdater;
    
    event OracleUpdate(string key, uint128 value, uint128 timestamp);
    event UpdaterAddressChange(address newUpdater);
    
    constructor() {
        oracleUpdater = msg.sender;
    }
    
    function setValue(string memory key, uint128 value, uint128 timestamp) public {
        require(msg.sender == oracleUpdater);
        uint256 cValue = (((uint256)(value)) << 128) + timestamp;
        values[key] = cValue;
        emit OracleUpdate(key, value, timestamp);
    }
    
    function getValue(string memory key) public view returns (uint128, uint128) {
        uint256 cValue = values[key];
        uint128 timestamp = (uint128)(cValue % 2**128);
        uint128 value = (uint128)(cValue >> 128);
        return (value, timestamp);
    }
    
    function updateOracleUpdaterAddress(address newOracleUpdaterAddress) public {
        require(msg.sender == oracleUpdater);
        oracleUpdater = newOracleUpdaterAddress;
        emit UpdaterAddressChange(newOracleUpdaterAddress);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}