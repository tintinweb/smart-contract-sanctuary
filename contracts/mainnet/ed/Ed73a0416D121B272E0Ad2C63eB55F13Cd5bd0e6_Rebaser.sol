// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import './IUniswapV2Pair.sol';
import "./UniswapV2OracleLibrary.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IXAUToken.sol";
import "./AggregatorV3Interface.sol";

// https://docs.balancer.finance/api/api#gulp
interface BAL {
    function gulp(address token) external;
}

contract Rebaser is Context, Ownable {

    using SafeMath for uint256;

    AggregatorV3Interface public targetRateOracle1;
    AggregatorV3Interface public targetRateOracle2;
    uint256 public targetRateOracleScale;
    
    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    /// @notice an event emitted when a transaction fails
    event TransactionFailed(address indexed destination, uint index, bytes data);

    /// @notice an event emitted when deviationThreshold is changed
    event NewDeviationThreshold(uint256 oldDeviationThreshold, uint256 newDeviationThreshold);

    /// @notice an event emitted when maxRebaseRatio is changed
    event NewMaxRebaseRatio(uint256 oldMaxRebaseRatio, uint256 newMaxRebaseRatio);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    /// @notice Spreads out getting to the target price
    uint256 public rebaseLag;

    /// @notice Peg target
    uint256 public targetRate;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    uint256 public deviationThreshold;

    /// @notice Max scalingFactor change ratio per one rebase iteration
    uint256 public maxRebaseRatio;

    /// @notice More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    /// @notice Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    /// @notice The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    uint256 public rebaseWindowOffsetSec;

    /// @notice The length of the time window where a rebase operation is allowed to execute, in seconds.
    uint256 public rebaseWindowLengthSec;

    /// @notice The number of rebase cycles since inception
    uint256 public epoch;

    // rebasing is not active initially. It can be activated at T+12 hours from
    // deployment time
    ///@notice boolean showing rebase activation status
    bool public rebasingActive;

    /// @notice delays rebasing activation to facilitate liquidity
    uint256 public rebaseDelay; 

    /// @notice Time of TWAP initialization
    uint256 public timeOfTWAPInit;

    /// @notice XAU token address
    address public xauToken;

    /// @notice reserve token
    address public reserveToken;

    /// @notice pair for reserveToken <> xauToken
    address public uniswapPair;

    /// @notice list of uniswap pairs to sync
    address[] public uniSyncPairs;

    /// @notice list of balancer pairs to gulp
    address[] public balGulpPairs;

    /// @notice last TWAP update time
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price;
    uint256 public priceCumulativeLast;

    /// @notice Whether or not this token is first in uniswap YAM<>Reserve pair
    bool public isToken0;

    uint256 public constant BASE = 10**18;

    constructor(
        address xauToken_,
        address reserveToken_,
        address uniswapPair_,
        address targetRateOracle1Address_,
        address targetRateOracle2Address_,
        uint256 targetRateOracleDecimals_,
        uint256 _minRebaseTimeIntervalSec,
        uint256 _rebaseWindowOffsetSec,
        uint256 _rebaseWindowLengthSec,
        uint256 _rebaseDelay
    )
        public
    {
          minRebaseTimeIntervalSec = _minRebaseTimeIntervalSec;
          rebaseWindowOffsetSec = _rebaseWindowOffsetSec; // 8am/8pm UTC rebases

          (address token0, ) = sortTokens(xauToken_, reserveToken_);

          targetRateOracle1 = AggregatorV3Interface(targetRateOracle1Address_);
          targetRateOracle2 = AggregatorV3Interface(targetRateOracle2Address_);
          targetRateOracleScale = 10**targetRateOracleDecimals_;

          // used for interacting with uniswap
          if (token0 == xauToken_) {
              isToken0 = true;
          } else {
              isToken0 = false;
          }

          uniswapPair = uniswapPair_;

          uniSyncPairs.push(uniswapPair);

          xauToken = xauToken_;

          // Reserve token is not mutable. Must deploy a new rebaser to update it
          reserveToken = reserveToken_;

          // 1 YYCRV
          targetRate = BASE;

          // twice daily rebase, with targeting reaching peg in 5 days
          rebaseLag = 5;

          // 5%
          deviationThreshold = 5 * 10**16;

          // 2.0x (we can rebase up to 2.0x or down to 0.5x in one step)
          maxRebaseRatio = 2 * 10**18;

          // 60 minutes
          rebaseWindowLengthSec = _rebaseWindowLengthSec;

          // 3 days
          rebaseDelay = _rebaseDelay;
    }

    function removeUniPair(uint256 index) public onlyOwner {
        if (index >= uniSyncPairs.length) return;

        uint256 totalUniPairs = uniSyncPairs.length;

        for (uint256 i = index; i < totalUniPairs - 1; i++) {
            uniSyncPairs[i] = uniSyncPairs[i + 1];
        }
        // uniSyncPairs.length--;
        delete uniSyncPairs[totalUniPairs.sub(1)];
    }

    function removeBalPair(uint256 index) public onlyOwner {
        if (index >= balGulpPairs.length) return;

        uint256 totalGulpPairs = balGulpPairs.length;

        for (uint256 i = index; i < totalGulpPairs - 1; i++) {
            balGulpPairs[i] = balGulpPairs[i + 1];
        }
        // uniSyncPairs.length--;
        delete balGulpPairs[totalGulpPairs.sub(1)];
    }

    /**
    @notice Adds pairs to sync
    *
    */
    function addUniSyncPairs(address[] memory uniSyncPairs_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < uniSyncPairs_.length; i++) {
            uniSyncPairs.push(uniSyncPairs_[i]);
        }
    }

    /**
    @notice Adds pairs to sync
    *
    */
    function addGulpSyncPairs(address[] memory balGulpPairs_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < balGulpPairs_.length; i++) {
            balGulpPairs.push(balGulpPairs_[i]);
        }
    }

    /**
    @notice Uniswap synced pairs
    *
    */
    function getUniSyncPairs()
        public
        view
        returns (address[] memory)
    {
        address[] memory pairs = uniSyncPairs;
        return pairs;
    }

    /**
    @notice Uniswap synced pairs
    *
    */
    function getBalGulpPairs()
        public
        view
        returns (address[] memory)
    {
        address[] memory pairs = balGulpPairs;
        return pairs;
    }

    /** @notice Initializes TWAP start point, starts countdown to first rebase
    *
    */
    function initTWAP()
        public
    {
        require(timeOfTWAPInit == 0, "already activated");
        (uint priceCumulative, uint32 blockTimestamp) =
           UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair, isToken0);
        require(blockTimestamp > 0, "no trades");
        blockTimestampLast = blockTimestamp;
        priceCumulativeLast = priceCumulative;
        timeOfTWAPInit = blockTimestamp;
    }

    /** @notice Activates rebasing
    *   @dev One way function, cannot be undone, callable by anyone
    */
    function activateRebasing()
        public
    {
        require(timeOfTWAPInit > 0, "twap wasnt intitiated, call initTWAP()");
        // cannot enable prior to end of rebaseDelay
        require(now >= timeOfTWAPInit + rebaseDelay, "!end_delay");

        rebasingActive = true;
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     *      and targetRate is 1e18
     */
    function rebase()
        public
    {
        // EOA only or gov
        require(msg.sender == tx.origin || msg.sender == owner()); 

        // ensure rebasing at correct time
        _inRebaseWindow(); 

        // This comparison also ensures there is no reentrancy.
        require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) <= now);  // FIX: [<] -> [<=] to allow rebase from 0th second of each window

        require(updateTargetRate(), "Target rate was not defined");

        
        // Snap the rebase time to the start of this window.
        lastRebaseTimestampSec = now.sub( 
            now.mod(minRebaseTimeIntervalSec)).add(rebaseWindowOffsetSec); 

        epoch = epoch.add(1); 

        // get twap from uniswap v2;
        uint256 exchangeRate = getTWAP();

        // calculates % change to supply
        (uint256 offPegPerc, bool positive) = computeOffPegPerc(exchangeRate); // 999999452912662667

        uint256 indexDelta = offPegPerc;

        // Apply the Dampening factor.
        indexDelta = indexDelta.div(rebaseLag);

        // Clip indexDelta to stay within interval of [1/maxRebaseRatio - 1, maxRebaseRatio - 1] so that
        // scalingFactor will get multiplied/divided up to maxRebaseRatio times.
        indexDelta = obeyMaxRebaseRatio(indexDelta, positive);

        IXAUToken xau = IXAUToken(xauToken);

        if (positive) {
            require(xau.scalingFactor().mul(BASE.add(indexDelta)).div(BASE) < xau.maxScalingFactor(), "new scaling factor will be too big");
        }

        // rebase, ignore returned var
        xau.rebase(epoch, indexDelta, positive);

        // perform actions after rebase
        afterRebase(offPegPerc); 
    }

    function afterRebase(
        uint256 /* offPegPerc */
    )
        internal
    {
        // update uniswap pairs
        for (uint256 i = 0; i < uniSyncPairs.length; i++) {
            IUniswapV2Pair(uniSyncPairs[i]).sync();
        }

        // update balancer pairs
        for (uint256 i = 0; i < balGulpPairs.length; i++) {
            BAL(balGulpPairs[i]).gulp(xauToken);
        }

        // call any extra functions
        for (uint i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result =
                    externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
    }

    /**
     * @notice Calculates TWAP from uniswap
     *
     * @dev When liquidity is low, this can be manipulated by an end of block -> next block
     *      attack. We delay the activation of rebases 12 hours after liquidity incentives
     *      to reduce this attack vector. Additional there is very little supply
     *      to be able to manipulate this during that time period of highest vuln.
     */
    function getTWAP()
        internal
        returns (uint256)
    {
        (uint priceCumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair, isToken0);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // no period check as is done in isRebaseWindow


        // overflow is desired
        uint256 priceAverage = uint256(uint224((priceCumulative - priceCumulativeLast) / timeElapsed));

        priceCumulativeLast = priceCumulative;
        blockTimestampLast = blockTimestamp;

        // BASE is on order of 1e18, which takes 2^60 bits
        // multiplication will revert if priceAverage > 2^196
        // (which it can because it overflows intentially)
        if (priceAverage > uint192(-1)) {
           // eat loss of precision
           // effectively: (x / 2**112) * 1e18
           return (priceAverage >> 112) * BASE;
        }
        // cant overflow
        // effectively: (x * 1e18 / 2**112)
        return (priceAverage * BASE) >> 112;
    }

    /**
     * @notice Calculates current TWAP from uniswap
     * 
     * @dev Has to be called in context, where blockTimestamp > blockTimestampLast, 
     *      i.e. in different block after last initTWAP()/getTWAP() call.
     *
     */
    function getCurrentTWAP()
        public
        view
        returns (uint256)
    {
        (uint priceCumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair, isToken0);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // no period check as is done in isRebaseWindow

        // overflow is desired
        uint256 priceAverage = uint256(uint224((priceCumulative - priceCumulativeLast) / timeElapsed));

        // BASE is on order of 1e18, which takes 2^60 bits
        // multiplication will revert if priceAverage > 2^196
        // (which it can because it overflows intentially)
        if (priceAverage > uint192(-1)) {
            // eat loss of precision
            // effectively: (x / 2**112) * 1e18
            return (priceAverage >> 112) * BASE;
        }
        // cant overflow
        // effectively: (x * 1e18 / 2**112)
        return (priceAverage * BASE) >> 112;
    }

    /**
     * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
     *         oracle is within this fractional distance from the targetRate, then no supply
     *         modifications are made.
     * @param deviationThreshold_ The new exchange rate threshold fraction.
     */
    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyOwner
    {
        require(deviationThreshold_ > 0);  // FIX: fixed YAM bug: require should validate argument, not member
        uint256 oldDeviationThreshold = deviationThreshold;
        deviationThreshold = deviationThreshold_;
        emit NewDeviationThreshold(oldDeviationThreshold, deviationThreshold_);
    }

    /**
     * @notice Sets the deviation threshold fraction. If the exchange rate given by the market
     *         oracle is within this fractional distance from the targetRate, then no supply
     *         modifications are made.
     * @param maxRebaseRatio_ The new exchange rate threshold fraction.
     */
    function setMaxRebaseRatio(uint256 maxRebaseRatio_)
        external
        onlyOwner
    {
        require(maxRebaseRatio_ > 1 * 10**18);
        uint256 oldMaxRebaseRatio = maxRebaseRatio;
        maxRebaseRatio = maxRebaseRatio_;
        emit NewMaxRebaseRatio(oldMaxRebaseRatio, maxRebaseRatio_);
    }

    /**
     * @param indexDelta The indexDelta to be clipped using maxRebaseRatio.
     * @param positive Sign of indexDelta.
     * @return unchanged indexDelta if resulting scalingFactor will stay within
     *         [scalingFactor / maxRebaseRatio, scalingFactor * maxRebaseRatio] interval,
     *         or maxIndexDelta derived from direction and maxRebaseRatio (saturation)
     */
    function obeyMaxRebaseRatio(uint256 indexDelta, bool positive)
        internal
        view
        returns (uint256)
    {
        uint256 maxIndexDelta = (positive ? maxRebaseRatio.sub(BASE) : BASE.sub((BASE*BASE).div(maxRebaseRatio)));
        return (indexDelta <= maxIndexDelta ? indexDelta : maxIndexDelta);
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
     * @notice Sets the targetRate parameter.
     * @param targetRate_ The new target rate parameter.
     */
    function setTargetRate(uint256 targetRate_)
        external
        onlyOwner
    {
        require(targetRate_ > 0);
        targetRate = targetRate_;
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
        require(minRebaseTimeIntervalSec_ > 0);
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);
        require(rebaseWindowOffsetSec_ + rebaseWindowLengthSec_ <= minRebaseTimeIntervalSec_);  // FIX: [<] -> [<=] to allow window length to span whole interval if needed
        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
        rebaseWindowOffsetSec = rebaseWindowOffsetSec_;
        rebaseWindowLengthSec = rebaseWindowLengthSec_;
    }

    /**
     * @return If the latest block timestamp is within the rebase time window it, returns true.
     *         Otherwise, returns false.
     */
    function inRebaseWindow() public view returns (bool) {

        // rebasing is delayed until there is a liquid market
        _inRebaseWindow();
        return true;
    }

    function _inRebaseWindow() internal view {

        // rebasing is delayed until there is a liquid market
        require(rebasingActive, "rebasing not active");

        require(now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec, "too early");
        require(now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)), "too late");
    }

    function isRebaseEffective() external view returns (bool) {
        return        
            rebasingActive && 
            now.mod(minRebaseTimeIntervalSec) >= rebaseWindowOffsetSec &&
            now.mod(minRebaseTimeIntervalSec) < (rebaseWindowOffsetSec.add(rebaseWindowLengthSec)) &&
            lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) <= now &&
            !withinDeviationThreshold(getCurrentTWAP(), getCurrentTargetRate())
            ;
    }

    /**
     * @return Computes in % how far off market is from peg
     */
    function computeOffPegPerc(uint256 rate)
        internal
        view
        returns (uint256, bool)
    {
        if (withinDeviationThreshold(rate, targetRate)) {
            return (0, false);
        }

        // indexDelta =  (rate - targetRate) / targetRate
        if (rate > targetRate) {
            return (rate.sub(targetRate).mul(BASE).div(targetRate), true);
        } else {
            return (targetRate.sub(rate).mul(BASE).div(targetRate), false);
        }
    }

    /**
     * @param _currentRate The current exchange rate, an 18 decimal fixed point number.
     * @param _targetRate The current target rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 _currentRate, uint256 _targetRate)
        internal
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = _targetRate.mul(deviationThreshold)
            .div(10 ** 18);

        return (_currentRate >= _targetRate && _currentRate.sub(_targetRate) < absoluteDeviationThreshold)
            || (_currentRate < _targetRate && _targetRate.sub(_currentRate) < absoluteDeviationThreshold);
    }

    /* - Constructor Helpers - */

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address token0,
        address token1
    )
        internal
        pure
        returns (address pair)
    {
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    )
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    /* -- Rebase helpers -- */

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes calldata data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            enabled: true,
            destination: destination,
            data: data
        }));
    }


    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        // transactions.length--;
        transactions.pop();
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                // 34710 is the value that solidity is currently emitting
                // It includes callGas (700) + callVeryLow (3, to pay for SUB)
                // + callValueTransferGas (9000) + callNewAccountGas
                // (25000, in case the destination address does not exist and needs creating)
                sub(gas(), 34710),


                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
    
    // Gives governance ability to recover any ERC20 tokens mistakenly sent to this contract address.
    function recoverERC20(
        address token,
        address to,
        uint256 amount
    )
        external
        onlyOwner
        returns (bool)
    {
        return IERC20(token).transfer(to, amount);
    }

    function setTargetRateOracle1(AggregatorV3Interface oracleAddress_) public onlyOwner {
        targetRateOracle1 = oracleAddress_;
    }

    function setTargetRateOracle2(AggregatorV3Interface oracleAddress_) public onlyOwner {
        targetRateOracle2 = oracleAddress_;
    }

    function setTargetRateOracleDecimals(uint256 targetRateOracleDecimals_) public onlyOwner {
        targetRateOracleScale = 10**targetRateOracleDecimals_;
    }

    function getTargetRateOracle1Price() public view returns (uint256) {
        return getChainLinkOraclePrice(targetRateOracle1);
    }

    function getTargetRateOracle2Price() public view returns (uint256) {
        return getChainLinkOraclePrice(targetRateOracle2);
    }

    function getUniswapPairAddress() public view returns (address) {
        return uniswapPair;
    }

    function getChainLinkOraclePrice(AggregatorV3Interface chainLinkOracle) internal view returns (uint256) {
        (
            , // uint80 roundID, 
            uint price,
            , // uint startedAt,
            uint timeStamp,
              // uint80 answeredInRound
        ) = chainLinkOracle.latestRoundData();        
        require(timeStamp > 0, "Round not complete");  // If the round is not complete yet, timestamp is 0
        return price;
    }

    function getCurrentTargetRate() public view returns (uint256) {
        if (address(targetRateOracle1) != address(0)) {
            if (address(targetRateOracle2) != address(0)) {
                // Two oracle mode (i.e.: 1: [comodity/USD], 2: [ETH/USD]; [base/quote])
                return getChainLinkOraclePrice(targetRateOracle1).mul(BASE).div(getChainLinkOraclePrice(targetRateOracle2));  // [comodity/USD] / [ETH/USD] = [comodity/USD] * [USD/ETH] = [comodity/ETH])
            } else {
                // Single oracle mode (direct), scale is important
                return getChainLinkOraclePrice(targetRateOracle1).mul(BASE).div(targetRateOracleScale);
            }
        } else if (address(targetRateOracle2) != address(0)) {
            // Single oracle mode (inverted), scale is important
            return BASE.mul(targetRateOracleScale).div(getChainLinkOraclePrice(targetRateOracle2));
        } else {
            // No oracle mode, fixed targetRate
            return targetRate;
        }
    }
    
    function updateTargetRate() public returns (bool) {
        AggregatorV3Interface _targetRateOracle1 = targetRateOracle1;  // cache storage values to save duplicit SLOAD gas
        AggregatorV3Interface _targetRateOracle2 = targetRateOracle2;
        if (address(_targetRateOracle1) != address(0)) {
            if (address(_targetRateOracle2) != address(0)) {
                // Two oracle mode (i.e.: 1: [comodity/USD], 2: [ETH/USD]; [base/quote])
                targetRate = getChainLinkOraclePrice(_targetRateOracle1).mul(BASE).div(getChainLinkOraclePrice(_targetRateOracle2));  // [comodity/USD] / [ETH/USD] = [comodity/USD] * [USD/ETH] = [comodity/ETH])
            } else {
                // Single oracle mode (direct), scale is important
                targetRate = getChainLinkOraclePrice(_targetRateOracle1).mul(BASE).div(targetRateOracleScale);
            }
        } else if (address(_targetRateOracle2) != address(0)) {
            // Single oracle mode (inverted), scale is important
            targetRate = BASE.mul(targetRateOracleScale).div(getChainLinkOraclePrice(_targetRateOracle2));
        } else {
            // No oracle mode, fixed targetRate
        }
        return true;
    }

}