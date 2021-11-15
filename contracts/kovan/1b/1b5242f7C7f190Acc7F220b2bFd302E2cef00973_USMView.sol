// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "./IUSM.sol";

/**
 * @title USM view-only proxy
 * @author Alberto Cuesta Cañada, Jacob Eliosoff, Alex Roan
 */
contract USMView {
    IUSM public immutable usm;

    constructor(IUSM usm_)
    {
        usm = usm_;
    }

    // ____________________ External informational view functions ____________________

    /**
     * @notice Calculate the amount of ETH in the buffer.
     * @return buffer ETH buffer
     */
    function ethBuffer(bool roundUp) external view returns (int buffer) {
        (uint price, ) = usm.latestPrice();
        buffer = usm.ethBuffer(price, usm.ethPool(), usm.totalSupply(), roundUp);
    }

    /**
     * @notice Convert ETH amount to USM using the latest oracle ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return usmOut The amount of USM
     */
    function ethToUsm(uint ethAmount, bool roundUp) external view returns (uint usmOut) {
        (uint price, ) = usm.latestPrice();
        usmOut = usm.ethToUsm(price, ethAmount, roundUp);
    }

    /**
     * @notice Convert USM amount to ETH using the latest oracle ETH/USD price.
     * @param usmAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function usmToEth(uint usmAmount, bool roundUp) external view returns (uint ethOut) {
        (uint price, ) = usm.latestPrice();
        ethOut = usm.usmToEth(price, usmAmount, roundUp);
    }

    /**
     * @notice Convert ETH amount to FUM using the latest oracle ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return fumOut The amount of FUM
     */
    function ethToFum(uint ethAmount) external view returns (uint fumOut) {
        (uint price, ) = usm.latestPrice();
        fumOut = usm.ethToFum(price, ethAmount);
    }

    /**
     * @notice Convert USM amount to ETH using the latest oracle ETH/USD price.
     * @param fumAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function fumToEth(uint fumAmount) external view returns (uint ethOut) {
        ethOut = usm.fumToEth(fumAmount);
    }

    /**
     * @notice Calculate debt ratio.
     * @return ratio Debt ratio
     */
    function debtRatio() external view returns (uint ratio) {
        (uint price, ) = usm.latestPrice();
        ratio = usm.debtRatio(price, usm.ethPool(), usm.totalSupply());
    }

    /**
     * @notice Calculate the *marginal* price of USM (in ETH terms) - that is, of the next unit, before price start sliding.
     * @return price USM price in ETH terms
     */
    function usmPrice(IUSM.Side side) external view returns (uint price) {
        (uint ethUsdPrice, ) = usm.latestPrice();
        IUSM.Side ethSide = (side == IUSM.Side.Buy ? IUSM.Side.Sell : IUSM.Side.Buy);   // Buying USM = selling ETH
        uint adjustedPrice = usm.adjustedEthUsdPrice(ethSide, ethUsdPrice, usm.bidAskAdjustment());
        price = usm.usmPrice(side, adjustedPrice);
    }

    /**
     * @notice Calculate the *marginal* price of FUM (in ETH terms) - that is, of the next unit, before price start sliding.
     * @return price FUM price in ETH terms
     */
    function fumPrice(IUSM.Side side) external view returns (uint price) {
        (uint ethUsdPrice, ) = usm.latestPrice();
        uint adjustedPrice = usm.adjustedEthUsdPrice(side, ethUsdPrice, usm.bidAskAdjustment());
        uint ethPool = usm.ethPool();
        uint usmSupply = usm.totalSupply();
        uint oldTimeUnderwater = usm.timeSystemWentUnderwater();
        if (side == IUSM.Side.Buy) {
            (, usmSupply, ) = usm.checkIfUnderwater(usmSupply, ethPool, ethUsdPrice, oldTimeUnderwater, block.timestamp);
        }
        price = usm.fumPrice(side, adjustedPrice, ethPool, usmSupply, usm.fumTotalSupply());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "acc-erc20/contracts/IERC20.sol";

abstract contract IUSM is IERC20 {
    event UnderwaterStatusChanged(bool underwater);
    event BidAskAdjustmentChanged(uint adjustment);
    event PriceChanged(uint timestamp, uint price);

    enum Side {Buy, Sell}

    // ____________________ External transactional functions ____________________

    /**
     * @notice Mint new USM, sending it to the given address, and only if the amount minted >= `minUsmOut`.  The amount of ETH
     * is passed in as `msg.value`.
     * @param to address to send the USM to.
     * @param minUsmOut Minimum accepted USM for a successful mint.
     */
    function mint(address to, uint minUsmOut) external virtual payable returns (uint usmOut);

    /**
     * @dev Burn USM in exchange for ETH.
     * @param from address to deduct the USM from.
     * @param to address to send the ETH to.
     * @param usmToBurn Amount of USM to burn.
     * @param minEthOut Minimum accepted ETH for a successful burn.
     */
    function burn(address from, address payable to, uint usmToBurn, uint minEthOut) external virtual returns (uint ethOut);

    /**
     * @notice Funds the pool with ETH, minting new FUM and sending it to the given address, but only if the amount minted >=
     * `minFumOut`.  The amount of ETH is passed in as `msg.value`.
     * @param to address to send the FUM to.
     * @param minFumOut Minimum accepted FUM for a successful fund.
     */
    function fund(address to, uint minFumOut) external virtual payable returns (uint fumOut);

    /**
     * @notice Defunds the pool by redeeming FUM in exchange for equivalent ETH from the pool.
     * @param from address to deduct the FUM from.
     * @param to address to send the ETH to.
     * @param fumToBurn Amount of FUM to burn.
     * @param minEthOut Minimum accepted ETH for a successful defund.
     */
    function defund(address from, address payable to, uint fumToBurn, uint minEthOut) external virtual returns (uint ethOut);

    // ____________________ Public transactional functions ____________________

    function refreshPrice() public virtual returns (uint price, uint updateTime);

    // ____________________ Public Oracle view functions ____________________

    /**
     * @return price the USM system's latest internal (mid) ETH/USD price, which may have been pushed up (by long-ETH
     * operations, ie, burn() or fund()) or down (by short-ETH operations, mint() or defund()) since the last oracle update.
     * Note that this may be a different value from `USM.oracle.latestPrice()`, which is not moved by USM user operations.
     * @return updateTime the time as of which the price was updated.  This is not as simple as "the last time the returned
     * price changed"; see the comment in `OurUniswapV2TWAPOracle._latestPrice()`.
     */
    function latestPrice() public virtual view returns (uint price, uint updateTime);

    function latestOraclePrice() public virtual view returns (uint price, uint updateTime);

    // ____________________ Public informational view functions ____________________

    /**
     * @notice Total amount of ETH in the pool (ie, in the contract).
     * @return pool ETH pool
     */
    function ethPool() public virtual view returns (uint pool);

    /**
     * @notice Total amount of ETH in the pool (ie, in the contract).
     * @return supply the total supply of FUM.  Users of this `IUSM` interface, like `USMView`, need to call this rather than
     * `usm.fum().totalSupply()` directly, because `IUSM` doesn't (and shouldn't) know about the `FUM` type.
     */
    function fumTotalSupply() public virtual view returns (uint supply);

    /**
     * @notice The current bid/ask adjustment, equal to the stored value decayed over time towards its stable value, 1.  This
     * adjustment is intended as a measure of "how long-ETH recent user activity has been", so that we can slide price
     * accordingly: if recent activity was mostly long-ETH (`fund()` and `burn()`), raise FUM buy price/reduce USM sell price;
     * if recent activity was short-ETH (`defund()` and `mint()`), reduce FUM sell price/raise USM buy price.
     * @return adjustment The sliding-price bid/ask adjustment
     */
    function bidAskAdjustment() public virtual view returns (uint adjustment);

    function timeSystemWentUnderwater() public virtual view returns (uint timestamp);

    // ____________________ Public helper pure functions (for functions above) ____________________

    /**
     * @notice Calculate the amount of ETH in the buffer.
     * @return buffer ETH buffer
     */
    function ethBuffer(uint ethUsdPrice, uint ethInPool, uint usmSupply, bool roundUp) public virtual pure returns (int buffer);

    /**
     * @notice Calculate debt ratio for a given eth to USM price: ratio of the outstanding USM (amount of USM in total supply),
     * to the current ETH pool value in USD (ETH qty * ETH/USD price).
     * @return ratio Debt ratio (or 0 if there's currently 0 ETH in the pool/price = 0: these should never happen after launch)
     */
    function debtRatio(uint ethUsdPrice, uint ethInPool, uint usmSupply) public virtual pure returns (uint ratio);

    /**
     * @notice Convert ETH amount to USM using a ETH/USD price.
     * @param ethAmount The amount of ETH to convert
     * @return usmOut The amount of USM
     */
    function ethToUsm(uint ethUsdPrice, uint ethAmount, bool roundUp) public virtual pure returns (uint usmOut);

    /**
     * @notice Convert USM amount to ETH using a ETH/USD price.
     * @param usmAmount The amount of USM to convert
     * @return ethOut The amount of ETH
     */
    function usmToEth(uint ethUsdPrice, uint usmAmount, bool roundUp) public virtual pure returns (uint ethOut);

    /**
     * @notice Convert USM amount to ETH using a ETH/USD price.
     * @param ethUsdPrice The amount of USM to convert
     * @param ethAmount The amount of USM to convert
     * @return fumOut The amount of ETH
     */
    function ethToFum(uint ethUsdPrice, uint ethAmount) external virtual view returns (uint fumOut);

    /**
     * @notice Convert FUM amount to ETH using a ETH/USD price.
     * @param fumAmount The amount of FUM to convert
     * @return ethOut The amount of ETH
     */
    function fumToEth(uint fumAmount) external virtual view returns (uint ethOut);

    /**
     * @return price The ETH/USD price, adjusted by the `bidAskAdjustment` (if applicable) for the given buy/sell side.
     */
    function adjustedEthUsdPrice(Side side, uint ethUsdPrice, uint adjustment) public virtual pure returns (uint price);

    /**
     * @notice Calculate the *marginal* price of USM (in ETH terms): that is, of the next unit, before the price start sliding.
     * @return price USM price in ETH terms
     */
    function usmPrice(Side side, uint ethUsdPrice) public virtual pure returns (uint price);

    /**
     * @notice Calculate the *marginal* price of FUM (in ETH terms): that is, of the next unit, before the price starts rising.
     * @param usmEffectiveSupply should be either the actual current USM supply, or, when calculating the FUM *buy* price, the
     * return value of `usmSupplyForFumBuys()`.
     * @return price FUM price in ETH terms
     */
    function fumPrice(Side side, uint ethUsdPrice, uint ethInPool, uint usmEffectiveSupply, uint fumSupply) public virtual pure returns (uint price);

    /**
     * @return timeSystemWentUnderwater_ The time at which we first detected the system was underwater (debt ratio >
     * `MAX_DEBT_RATIO`), based on the current oracle price and pool ETH and USM; or 0 if we're not currently underwater.
     * @return usmSupplyForFumBuys The current supply of USM *for purposes of calculating the FUM buy price,* and therefore
     * for `fumFromFund()`.  The "supply for FUM buys" is the *lesser* of the actual current USM supply, and the USM amount
     * that would make debt ratio = `MAX_DEBT_RATIO`.  Example:
     *
     * 1. Suppose the system currently contains 50 ETH at price $1,000 (total pool value: $50,000), with an actual USM supply
     *    of 30,000 USM.  Then debt ratio = 30,000 / $50,000 = 60%: < MAX 80%, so `usmSupplyForFumBuys` = 30,000.
     * 2. Now suppose ETH/USD halves to $500.  Then pool value halves to $25,000, and debt ratio doubles to 120%.  Now
     *    `usmSupplyForFumBuys` instead = 20,000: the USM quantity at which debt ratio would equal 80% (20,000 / $25,000).
     *    (Call this the "80% supply".)
     * 3. ...Except, we also gradually increase the supply over time while we remain underwater.  This has the effect of
     *    *reducing* the FUM buy price inferred from that supply (higher JacobUSM supply -> smaller buffer -> lower FUM price).
     *    The math we use gradually increases the supply from its initial "80% supply" value, where debt ratio =
     *    `MAX_DEBT_RATIO` (20,000 above), to a theoretical maximum "100% supply" value, where debt ratio = 100% (in the $500
     *    example above, this would be 25,000).  (Or the actual supply, whichever is lower: we never increase
     *    `usmSupplyForFumBuys` above `usmActualSupply`.)  The climb from the initial 80% supply (20,000) to the 100% supply
     *    (25,000) is at a rate that brings it "halfway closer per `MIN_FUM_BUY_PRICE_HALF_LIFE` (eg, 1 day)": so three days
     *    after going underwater, the supply returned will be 25,000 - 0.5**3 * (25,000 - 20,000) = 24,375.
     */
    function checkIfUnderwater(uint usmActualSupply, uint ethPool_, uint ethUsdPrice, uint oldTimeUnderwater, uint currentTime) public virtual pure returns (uint timeSystemWentUnderwater_, uint usmSupplyForFumBuys, uint debtRatio_);
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

