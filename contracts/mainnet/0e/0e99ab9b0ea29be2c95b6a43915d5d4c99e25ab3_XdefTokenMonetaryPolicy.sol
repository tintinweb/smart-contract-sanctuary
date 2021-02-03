pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
 
import "./lib/SafeMathInt.sol";
import "./lib/UInt256Lib.sol";
import "./XdefToken.sol";

interface IOracle {
    function getData() external view returns (uint256, bool);
    function update() external;
}

interface ISync {
    function sync() external;
}

/*
interface IGulp {
    function gulp(address token) external;
}
*/

/**
 * @title XdefToken Monetary Supply Policy
 * @dev This is an implementation of the XdefToken Index Fund protocol.
 *      XdefToken operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable unit price.
 *
 *      This component regulates the token supply of the XdefToken ERC20 token in response to
 *      market oracles.
 */
contract XdefTokenMonetaryPolicy is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 tvl,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );
    event Incentivization(address indexed account, uint256 amount);

    XdefToken public Xdef;

    uint256 public incentiveLimit = 300 * 1e9;

    // Provides the current market cap, as an 18 decimal fixed point number.
    IOracle public tvlOracle;

    // Market oracle provides the token/USD exchange rate as an 18 decimal fixed point number.
    // (eg) An oracle value of 1.5e18 it would mean 1 Xdef is trading for $1.50.
    IOracle public tokenPriceOracle;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // The rebase lag parameter, used to dampen the applied supply adjustment by 1 / rebaseLag
    // Check setRebaseLag comments for more details.
    // Natural number, no decimal places.
    uint256 public rebaseLag;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    // The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    address[] public unipairs;

    function setXdefToken(address _Xdef)
        external
        onlyOwner
    {
        Xdef = XdefToken(_Xdef);
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (TokenPriceOracleRate - targetPrice) / targetPrice
     *      and targetPrice is TvlOracleRate / xdefTvl
     */
    function rebase() external {
        //require(msg.sender == orchestrator, "you are not the orchestrator");
        require(inRebaseWindow(), "the rebase window is closed");

        // This comparison also ensures there is no reentrancy.
        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now, "cannot rebase yet");


        uint256 incentive = calcIncentive();

        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now.sub(now.mod(minRebaseTimeIntervalSec)).add(rebaseWindowOffsetSec);

         if (incentive > 0) {
            Xdef.transfer(msg.sender, incentive); // before rebase()
            emit Incentivization(msg.sender, incentive);
        }

        epoch = epoch.add(1);

        (int256 supplyDelta, uint256 tvl, uint256 tokenPrice) = getNextSupplyDelta();

        tokenPriceOracle.update();

        if (supplyDelta == 0) {
            emit LogRebase(epoch, tokenPrice, tvl, supplyDelta, now);
            return;
        }

        if (supplyDelta > 0 && Xdef.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(Xdef.totalSupply())).toInt256Safe();
        }

        uint256 supplyAfterRebase = Xdef.rebase(epoch, supplyDelta);
        assert(supplyAfterRebase <= MAX_SUPPLY);
        
        sync();
        
        emit LogRebase(epoch, tokenPrice, tvl, supplyDelta, now);
    }


    function calcIncentive() public view returns (uint256 incentive) {
        if (inRebaseWindow() && now > lastRebaseTimestampSec.add(minRebaseTimeIntervalSec)) {
            uint256 xdefBalance = Xdef.balanceOf(address(this));
            uint256 realLimit = xdefBalance <= incentiveLimit ? xdefBalance : incentiveLimit;
            uint256 auction_price = now.mod(minRebaseTimeIntervalSec).sub(rebaseWindowOffsetSec).div(5).mul(1e9); 
            incentive = auction_price <= realLimit ? auction_price : realLimit;
        } else { 
            incentive = 0;
        }
        return incentive;
    }

    function withdrawTokens (uint256 amount) 
        external 
        onlyOwner 
    {   
        Xdef.transfer(msg.sender, amount);
    }

    function getNextSupplyDelta()
        public view
        returns (int256 supplyDelta, uint256 tvl, uint256 tokenPrice)
    {
        uint256 tvl;
        bool tvlValid;
        (tvl, tvlValid) = tvlOracle.getData();
        require(tvlValid, "invalid tvl");

        uint256 tokenPrice;
        bool tokenPriceValid;
        (tokenPrice, tokenPriceValid) = tokenPriceOracle.getData();
        require(tokenPriceValid, "invalid token price");

        if (tokenPrice > MAX_RATE) {
            tokenPrice = MAX_RATE;
        }

        supplyDelta = computeSupplyDelta(tokenPrice, tvl);

        // Apply the Dampening factor.
        supplyDelta = supplyDelta.div(rebaseLag.toInt256Safe());
        return (supplyDelta, tvl, tokenPrice);
    }

    function addUniPair(address addr)
        external
        onlyOwner
    {
        unipairs.push(addr);
    }

    function removeUniPair(address addr)
        external
        onlyOwner
    {
        for (uint i = 0; i < unipairs.length; i++) {
            if (unipairs[i] == addr) {
                unipairs[i] = unipairs[unipairs.length - 1];
                unipairs.pop();
                break;
            }
        }
    }

    function sync() public {
        for (uint i = 0; i < unipairs.length; i++) {
            ISync(unipairs[i]).sync(); 
        }
    }
    
    /**
     * @notice Sets the reference to the market cap oracle.
     * @param tvlOracle_ The address of the tvl oracle contract.
     */
    function setTvlOracle(IOracle tvlOracle_)
        external
        onlyOwner
    {
        tvlOracle = tvlOracle_;
    }

    /**
     * @notice Sets the reference to the token price oracle.
     * @param tokenPriceOracle_ The address of the token price oracle contract.
     */
    function setTokenPriceOracle(IOracle tokenPriceOracle_)
        external
        onlyOwner
    {
        tokenPriceOracle = tokenPriceOracle_;
    }

    function setIncentiveLimit(uint256 newIncentiveLimit)
        external
        onlyOwner
    {
        incentiveLimit = newIncentiveLimit;
    }

    /**
     * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
     *         oracle is within this fractional distance from the targetRate, then no supply
     *         modifications are made. DECIMALS fixed point number.
     * @param deviationThreshold_ The new exchange rate threshold fraction.
     */
    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyOwner
    {
        deviationThreshold = deviationThreshold_;
    }

    /**
     * @notice Sets the rebase lag parameter.
               It is used to dampen the applied supply adjustment by 1 / rebaseLag
               If the rebase lag R, equals 1, the smallest value for R, then the full supply
               correction is applied on each rebase cycle.
               If it is greater than 1, then a correction of 1/R of is applied on each rebase.
     * @param rebaseLag_ The new rebase lag parameter.
     */
    function setRebaseLag(uint256 rebaseLag_)
        external
        onlyOwner
    {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }

    /**
     * @notice Sets the parameters which control the timing and frequency of
     *         rebase operations.
     *         a) the minimum time period that must elapse between rebase cycles.
     *         b) the rebase window offset parameter.
     *         c) the rebase window length parameter.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     * @param rebaseWindowOffsetSec_ The number of seconds from the beginning of
              the rebase interval, where the rebase window begins.
     * @param rebaseWindowLengthSec_ The length of the rebase window in seconds.
     */
    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_,
        uint256 rebaseWindowLengthSec_)
        external
        onlyOwner
    {
        require(minRebaseTimeIntervalSec_ > 0, "minRebaseTimeIntervalSec cannot be 0");
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_, "rebaseWindowOffsetSec_ >= minRebaseTimeIntervalSec_");

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    constructor (XdefToken Xdef_, IOracle tokenPriceOracle_, IOracle tvlOracle_, address[] memory unipairs_)
        public
    {
        deviationThreshold = 0;
        rebaseLag = 1;
        minRebaseTimeIntervalSec = 1 days;
        rebaseWindowOffsetSec = 36000;  // 10:00 UTC
        rebaseWindowLengthSec = 60 minutes;
        lastRebaseTimestampSec = 0;
        deviationThreshold = 50000000000000000; // 5%
        epoch = 0;

        Xdef = Xdef_;
        tokenPriceOracle = tokenPriceOracle_;
        tvlOracle = tvlOracle_;
        unipairs = unipairs_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {
        return (
            now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
            now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec))
        );
    }

    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 price, uint256 tvl)
        private
        view
        returns (int256)
    {
        if (withinDeviationThreshold(price, tvl.div(100000000000))) {
            return 0;
        }

        // supplyDelta = totalSupply * (price - targetPrice) / targetPrice
        int256 pricex1T       = price.mul(100000000000).toInt256Safe();
        int256 targetPricex1T = tvl.toInt256Safe();
        return Xdef.totalSupply().toInt256Safe()
            .mul(pricex1T.sub(targetPricex1T))
            .div(targetPricex1T);
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @param targetRate The target exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        private
        view
        returns (bool)
    {
        if (deviationThreshold == 0) {
            return false;
        }

        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold).div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
}