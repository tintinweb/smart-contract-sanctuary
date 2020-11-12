pragma solidity 0.4.18;

import "./ConversionRates.sol";

/// @title ConversionRateEnhancedSteps contract - new ConversionRates contract with step function enhancement
/// Removed qty step function overhead
/// Also fixed following issues:
/// https://github.com/KyberNetwork/smart-contracts/issues/291
/// https://github.com/KyberNetwork/smart-contracts/issues/241
/// https://github.com/KyberNetwork/smart-contracts/issues/240


contract ConversionRateEnhancedSteps is ConversionRates {

    uint constant internal MAX_STEPS_IN_FUNCTION = 16;
    int constant internal MAX_IMBALANCE = 2 ** 255 - 1;
    uint constant internal POW_2_128 = 2 ** 128;
    int128 constant internal MAX_STEP_VALUE = 2 ** 127 - 1;
    int128 constant internal MIN_STEP_VALUE = -1 * 2 ** 127;
    int constant internal MAX_BPS_ADJUSTMENT = 100 * 100;

    function ConversionRateEnhancedSteps(address _admin) public ConversionRates(_admin)
        { } // solhint-disable-line no-empty-blocks

    // Blocking set qty step func as we won't use
    function setQtyStepFunction(
        ERC20,
        int[],
        int[],
        int[],
        int[]
    )
        public
        onlyOperator
    {
        revert();
    }

    function setImbalanceStepFunction(
        ERC20 token,
        int[] xBuy,
        int[] yBuy,
        int[] xSell,
        int[] ySell
    )
        public
        onlyOperator
    {
        require(xBuy.length + 1 == yBuy.length);
        require(xSell.length + 1 == ySell.length);
        require(yBuy.length <= MAX_STEPS_IN_FUNCTION);
        require(ySell.length <= MAX_STEPS_IN_FUNCTION);
        require(tokenData[token].listed);

        uint i;

        if (xBuy.length > 1) {
            // verify qty are increasing
            for(i = 0; i < xBuy.length - 1; i++) {
                require(xBuy[i] < xBuy[i + 1]);
            }
        }
        // only need to check last value as it's sorted array
        require(xBuy.length == 0 || xBuy[xBuy.length - 1] < MAX_STEP_VALUE);

        // verify yBuy
        for(i = 0; i < yBuy.length; i++) {
            require(yBuy[i] >= MIN_BPS_ADJUSTMENT);
            require(yBuy[i] <= MAX_BPS_ADJUSTMENT);
        }

        if (xSell.length > 1) {
            // verify qty are increasing
            for(i = 0; i < xSell.length - 1; i++) {
                require(xSell[i] < xSell[i + 1]);
            }
        }
        // only need to check last value as it's sorted array
        require(xSell.length == 0 || xSell[xSell.length - 1] < MAX_STEP_VALUE);

        // verify ySell
        for(i = 0; i < ySell.length; i++) {
            require(ySell[i] >= MIN_BPS_ADJUSTMENT);
            require(ySell[i] <= MAX_BPS_ADJUSTMENT);
        }

        int[] memory buyArray = new int[](yBuy.length);
        for(i = 0; i < yBuy.length; i++) {
            int128 xBuyVal = (i == yBuy.length - 1) ? MAX_STEP_VALUE : int128(xBuy[i]);
            buyArray[i] = encodeStepFunctionData(xBuyVal, int128(yBuy[i]));
        }

        int[] memory sellArray = new int[](ySell.length);
        for(i = 0; i < ySell.length; i++) {
            int128 xSellVal = (i == ySell.length - 1) ? MAX_STEP_VALUE : int128(xSell[i]);
            sellArray[i] = encodeStepFunctionData(xSellVal, int128(ySell[i]));
        }

        int[] memory emptyArr = new int[](0);
        tokenData[token].buyRateImbalanceStepFunction = StepFunction(buyArray, emptyArr);
        tokenData[token].sellRateImbalanceStepFunction = StepFunction(sellArray, emptyArr);
    }

    /* solhint-disable code-complexity */
    function getStepFunctionData(ERC20 token, uint command, uint param) public view returns(int) {
        if (command == 8) return int(tokenData[token].buyRateImbalanceStepFunction.x.length - 1);

        int stepXValue;
        int stepYValue;

        if (command == 9) {
            (stepXValue, stepYValue) = decodeStepFunctionData(tokenData[token].buyRateImbalanceStepFunction.x[param]);
            return stepXValue;
        }

        if (command == 10) return int(tokenData[token].buyRateImbalanceStepFunction.x.length);
        if (command == 11) {
            (stepXValue, stepYValue) = decodeStepFunctionData(tokenData[token].buyRateImbalanceStepFunction.x[param]);
            return stepYValue;
        }

        if (command == 12) return int(tokenData[token].sellRateImbalanceStepFunction.x.length - 1);
        if (command == 13) {
            (stepXValue, stepYValue) = decodeStepFunctionData(tokenData[token].sellRateImbalanceStepFunction.x[param]);
            return stepXValue;
        }

        if (command == 14) return int(tokenData[token].sellRateImbalanceStepFunction.x.length);
        if (command == 15) {
            (stepXValue, stepYValue) = decodeStepFunctionData(tokenData[token].sellRateImbalanceStepFunction.x[param]);
            return stepYValue;
        }

        revert();
    }

    /* solhint-disable function-max-lines */
    function getRate(ERC20 token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint) {
        // check if trade is enabled
        if (!tokenData[token].enabled) return 0;
        if (tokenControlInfo[token].minimalRecordResolution == 0) return 0; // token control info not set

        // get rate update block
        bytes32 compactData = tokenRatesCompactData[tokenData[token].compactDataArrayIndex];

        uint updateRateBlock = getLast4Bytes(compactData);
        if (currentBlockNumber >= updateRateBlock + validRateDurationInBlocks) return 0; // rate is expired
        // check imbalance
        int totalImbalance;
        int blockImbalance;
        (totalImbalance, blockImbalance) = getImbalance(token, updateRateBlock, currentBlockNumber);

        // calculate actual rate
        int imbalanceQty;
        int extraBps;
        int8 rateUpdate;
        uint rate;

        if (buy) {
            // start with base rate
            rate = tokenData[token].baseBuyRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, true);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            qty = getTokenQty(token, qty, rate);
            imbalanceQty = int(qty);

            // add imbalance overhead
            extraBps = executeStepFunction(
                tokenData[token].buyRateImbalanceStepFunction,
                totalImbalance,
                totalImbalance + imbalanceQty
            );
            rate = addBps(rate, extraBps);
            totalImbalance += imbalanceQty;
        } else {
            // start with base rate
            rate = tokenData[token].baseSellRate;

            // add rate update
            rateUpdate = getRateByteFromCompactData(compactData, token, false);
            extraBps = int(rateUpdate) * 10;
            rate = addBps(rate, extraBps);

            // compute token qty
            imbalanceQty = -1 * int(qty);

            // add imbalance overhead
            extraBps = executeStepFunction(
                tokenData[token].sellRateImbalanceStepFunction,
                totalImbalance + imbalanceQty,
                totalImbalance
            );
            rate = addBps(rate, extraBps);
            totalImbalance += imbalanceQty;
        }

        if (abs(totalImbalance) >= getMaxTotalImbalance(token)) return 0;
        if (abs(blockImbalance + imbalanceQty) >= getMaxPerBlockImbalance(token)) return 0;

        return rate;
    }

    // Override function getImbalance to fix #240
    function getImbalance(ERC20 token, uint rateUpdateBlock, uint currentBlock)
        internal view
        returns(int totalImbalance, int currentBlockImbalance)
    {
        int resolution = int(tokenControlInfo[token].minimalRecordResolution);

        (totalImbalance, currentBlockImbalance) =
            getImbalanceSinceRateUpdate(
                token,
                rateUpdateBlock,
                currentBlock);

        if (!checkMultOverflow(totalImbalance, resolution)) {
            totalImbalance *= resolution;
        } else {
            totalImbalance = MAX_IMBALANCE;
        }

        if (!checkMultOverflow(currentBlockImbalance, resolution)) {
            currentBlockImbalance *= resolution;
        } else {
            currentBlockImbalance = MAX_IMBALANCE;
        }
    }

    function getImbalancePerToken(ERC20 token, uint whichBlock)
        public view
        returns(int totalImbalance, int currentBlockImbalance)
    {
        uint rateUpdateBlock = getRateUpdateBlock(token);
        // if whichBlock = 0, use latest block, otherwise use whichBlock
        uint usedBlock = whichBlock == 0 ? block.number : whichBlock;
        return getImbalance(token, rateUpdateBlock, usedBlock);
    }

    function executeStepFunction(StepFunction storage f, int from, int to) internal view returns(int) {

        uint len = f.x.length;

        if (len == 0 || from == to) { return 0; }

        int fromVal = from; // avoid modifying function parameters
        int change = 0; // amount change from initial amount when applying bps for each step
        int stepXValue;
        int stepYValue;

        for(uint ind = 0; ind < len; ind++) {
            (stepXValue, stepYValue) = decodeStepFunctionData(f.x[ind]);
            if (stepXValue <= fromVal) { continue; }
            // if it falls into step with y <= -10000, rate must be 0
            if (stepYValue == MIN_BPS_ADJUSTMENT) { return MIN_BPS_ADJUSTMENT; }
            // from here, from < stepXValue,
            // if from < to <= stepXValue, take [from, to] and return, else take [from, stepXValue]
            if (stepXValue >= to) {
                change += (to - fromVal) * stepYValue;
                return change / (to - from);
            } else {
                change += (stepXValue - fromVal) * stepYValue;
                fromVal = stepXValue;
            }
        }

        return change / (to - from);
    }

    // first 128 bits is value for x, next 128 bits is value for y
    function encodeStepFunctionData(int128 x, int128 y) internal pure returns(int data) {
        require(x <= MAX_STEP_VALUE && x >= MIN_STEP_VALUE);
        require(y <= MAX_STEP_VALUE && y >= MIN_STEP_VALUE);
        data = int(uint(y) & (POW_2_128 - 1));
        data |= int((uint(x) & (POW_2_128 - 1)) * POW_2_128);
    }

    function decodeStepFunctionData(int val) internal pure returns (int x, int y) {
        y = int(int128(uint(val) & (POW_2_128 - 1)));
        x = int(int128((uint(val) / POW_2_128) & (POW_2_128 - 1)));
        // default to be max value
        if (x == int(MAX_STEP_VALUE)) { x = MAX_IMBALANCE; }
    }

    function checkMultOverflow(int x, int y) internal pure returns(bool) {
        if (y == 0) return false;
        return (((x*y) / y) != x);
    }
}
