// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFeesCalculator.sol";

contract FeesCalculator is IFeesCalculator, Ownable {

    uint256 private constant PRECISION_DECIMALS = 1e10;

    uint256 private constant FUNDING_FEE_MIN_RATE = 2000;
    uint256 private constant FUNDING_FEE_MAX_RATE = 100000;
    uint256 private constant FUNDING_FEE_BASE_PERIOD = 1 days;

    uint256 private constant MAX_FUNDING_FEE_PERCENTAGE = 1000000;
    uint16 private constant CVI_DECIMALS = 100;

    uint16 private constant MAX_FUNDING_FEE_CVI_THRESHOLD = 55;
    uint16 private constant MIN_FUDNING_FEE_CVI_THRESHOLD = 150;
    uint16 private constant FUNDING_FEE_DIVISION_FACTOR = 5;

    uint16 private constant MAX_PERCENTAGE = 10000;

    uint16 private constant COLATERAL_VALUES_NUM = 101; // From 0.00 to 1.00 inclusive

    uint16 public maxCVIValue;

    uint16 public override depositFeePercent = 0;
    uint16 public override withdrawFeePercent = 0;
    uint16 public override openPositionFeePercent = 15;
    uint16 public override openPositionLPFeePercent = 15;
    uint16 public override closePositionLPFeePercent = 0;
    uint16 public buyingPremiumFeeMaxPercent = 1000;
    uint16 public closingPremiumFeeMaxPercent = 1000;
    uint16 public override closePositionFeePercent = 30;

    uint16 public buyingPremiumThreshold = 6500; // 1.0 is MAX_PERCENTAGE = 10000

    uint16 public closePositionMaxFeePercent = 300;

    uint16 public maxTurbulenceFeePercentToTrim = 100;
    uint16 public turbulenceStepPercent = 1000;
    uint16 public override turbulenceIndicatorPercent = 0;

    uint32 public adjustedVolumeTimestamp;
    uint16 public volumeTimeWindow = 2 hours;
    uint16 public volumeFeeTimeWindow = 1 hours;
    uint16 public maxVolumeFeeDeltaCollateral = 400; // 100% is MAX_PERCENTAGE = 10000
    uint16 public midVolumeFee = 0; // 100% is MAX_PERCENTAGE = 10000
    uint16 public maxVolumeFee = 130; // 100% is MAX_PERCENTAGE = 10000

    uint32 public closeAdjustedVolumeTimestamp;
    uint16 public closeVolumeTimeWindow = 2 hours;
    uint16 public closeVolumeFeeTimeWindow = 1 hours;
    uint16 public closeMaxVolumeFeeDeltaCollateral = 400; // 100% is MAX_PERCENTAGE = 10000
    uint16 public closeMidVolumeFee = 0; // 100% is MAX_PERCENTAGE = 10000
    uint16 public closeMaxVolumeFee = 80; // 100% is MAX_PERCENTAGE = 10000

    uint256 public oracleHeartbeatPeriod = 55 minutes;
    uint256 public closePositionFeeDecayPeriod = 24 hours;
    uint256 public fundingFeeConstantRate = 3000;

    uint16 public turbulenceDeviationThresholdPercent = 7000; // 1.0 is MAX_PERCENTAGE = 10000
    uint16 public turbulenceDeviationPercentage = 500; // 1.0 is MAX_PERCENTAGE = 10000

    uint16[] public collateralToBuyingPremiumMapping = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 8, 9, 11, 14, 16, 20, 24, 29, 35, 42, 52, 63, 77, 94, 115, 140, 172, 212, 261, 323, 399, 495, 615, 765, 953, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000];

    ICVIOracle public cviOracle;
    address public stateUpdator;

    modifier onlyStateUpdator {
        require(msg.sender == stateUpdator, "Not allowed");
        _;
    }

    constructor(ICVIOracle _cviOracle, uint16 _maxCVIValue) {
        maxCVIValue = _maxCVIValue;
        cviOracle = _cviOracle;
    }

    function updateTurbulenceIndicatorPercent(uint256 _totalTime, uint256 _newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) external override onlyStateUpdator {
        uint16 updatedTurbulenceIndicatorPercent = calculateTurbulenceIndicatorPercent(_totalTime, _newRounds, _lastCVIValue, _currCVIValue);

        if (updatedTurbulenceIndicatorPercent != turbulenceIndicatorPercent) {
            turbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent;
        }
    }

    function updateAdjustedTimestamp(uint256 _collateralRatio, uint256 _lastCollateralRatio) external override onlyStateUpdator {
        uint256 deltaCollateral = _collateralRatio - _lastCollateralRatio; // Note: must be greater than 0
        adjustedVolumeTimestamp = getAdjustedTimestamp(adjustedVolumeTimestamp, deltaCollateral, volumeTimeWindow, maxVolumeFeeDeltaCollateral);
    }

    function updateCloseAdjustedTimestamp(uint256 _collateralRatio, uint256 _lastCollateralRatio) external override onlyStateUpdator {
        uint256 deltaCollateral = _lastCollateralRatio - _collateralRatio; // Note: must be greater than 0
        closeAdjustedVolumeTimestamp = getAdjustedTimestamp(closeAdjustedVolumeTimestamp, deltaCollateral, closeVolumeTimeWindow, closeMaxVolumeFeeDeltaCollateral);
    }

    function setOracle(ICVIOracle _cviOracle) external override onlyOwner {
        cviOracle = _cviOracle;
    }

    function setStateUpdator(address _newUpdator) external override onlyOwner {
        stateUpdator = _newUpdator;
    }

    function setDepositFee(uint16 _newDepositFeePercentage) external override onlyOwner {
        require(_newDepositFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        depositFeePercent = _newDepositFeePercentage;
    }

    function setWithdrawFee(uint16 _newWithdrawFeePercentage) external override onlyOwner {
        require(_newWithdrawFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        withdrawFeePercent = _newWithdrawFeePercentage;
    }

    function setOpenPositionFee(uint16 _newOpenPositionFeePercentage) external override onlyOwner {
        require(_newOpenPositionFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        openPositionFeePercent = _newOpenPositionFeePercentage;
    }

    function setClosePositionFee(uint16 _newClosePositionFeePercentage) external override onlyOwner {
        require(_newClosePositionFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        require(_newClosePositionFeePercentage <= closePositionMaxFeePercent, "Min fee above max fee");
        closePositionFeePercent = _newClosePositionFeePercentage;
    }

    function setOpenPositionLPFee(uint16 _newOpenPositionLPFeePercent) external override onlyOwner {
        require(_newOpenPositionLPFeePercent < MAX_PERCENTAGE, "Fee exceeds maximum");
        openPositionLPFeePercent = _newOpenPositionLPFeePercent;
    }

    function setClosePositionLPFee(uint16 _newClosePositionLPFeePercent) external override onlyOwner {
        require(_newClosePositionLPFeePercent < MAX_PERCENTAGE, "Fee exceeds maximum");
        closePositionLPFeePercent = _newClosePositionLPFeePercent;
    }

    function setClosePositionMaxFee(uint16 _newClosePositionMaxFeePercentage) external override onlyOwner {
        require(_newClosePositionMaxFeePercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        require(_newClosePositionMaxFeePercentage >= closePositionFeePercent, "Max fee below min fee");
        closePositionMaxFeePercent = _newClosePositionMaxFeePercentage;
    }

    function setClosePositionFeeDecay(uint256 _newClosePositionFeeDecayPeriod) external override onlyOwner {
        require(_newClosePositionFeeDecayPeriod > 0, "Period must be positive");
        closePositionFeeDecayPeriod = _newClosePositionFeeDecayPeriod;
    }

    function setOracleHeartbeatPeriod(uint256 _newOracleHeartbeatPeriod) external override onlyOwner {
        require(_newOracleHeartbeatPeriod > 0, "Heartbeat must be positive");
        oracleHeartbeatPeriod = _newOracleHeartbeatPeriod;
    }

    function setBuyingPremiumFeeMax(uint16 _newBuyingPremiumFeeMaxPercentage) external override onlyOwner {
        require(_newBuyingPremiumFeeMaxPercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        buyingPremiumFeeMaxPercent = _newBuyingPremiumFeeMaxPercentage;
    }

    function setBuyingPremiumThreshold(uint16 _newBuyingPremiumThreshold) external override onlyOwner {
        require(_newBuyingPremiumThreshold < MAX_PERCENTAGE, "Threshold exceeds maximum");
        buyingPremiumThreshold = _newBuyingPremiumThreshold;   
    }

    function setClosingPremiumFeeMax(uint16 _newClosingPremiumFeeMaxPercentage) external override onlyOwner {
        require(_newClosingPremiumFeeMaxPercentage < MAX_PERCENTAGE, "Fee exceeds maximum");
        closingPremiumFeeMaxPercent = _newClosingPremiumFeeMaxPercentage;
    }

    function setCollateralToBuyingPremiumMapping(uint16[] calldata _newCollateralToBuyingPremiumMapping) external override onlyOwner {
        require(_newCollateralToBuyingPremiumMapping.length == COLATERAL_VALUES_NUM, "Bad mapping size");
        collateralToBuyingPremiumMapping = _newCollateralToBuyingPremiumMapping;
    }

    function setFundingFeeConstantRate(uint16 _newfundingFeeConstantRate) external override onlyOwner {
        require(_newfundingFeeConstantRate < FUNDING_FEE_MAX_RATE, "Fee exceeds maximum");
        fundingFeeConstantRate = _newfundingFeeConstantRate;
    }

    function setTurbulenceStep(uint16 _newTurbulenceStepPercentage) external override onlyOwner {
        require(_newTurbulenceStepPercentage < MAX_PERCENTAGE, "Step exceeds maximum");
        turbulenceStepPercent = _newTurbulenceStepPercentage;
    }
    
    function setMaxTurbulenceFeePercentToTrim(uint16 _newMaxTurbulenceFeePercentToTrim) external override onlyOwner {
        require(_newMaxTurbulenceFeePercentToTrim < MAX_PERCENTAGE, "Fee exceeds maximum");
        maxTurbulenceFeePercentToTrim = _newMaxTurbulenceFeePercentToTrim;
    }

     function setTurbulenceDeviationThresholdPercent(uint16 _newTurbulenceDeviationThresholdPercent) external override onlyOwner {
        require(_newTurbulenceDeviationThresholdPercent < MAX_PERCENTAGE, "Threshold exceeds maximum");
        turbulenceDeviationThresholdPercent = _newTurbulenceDeviationThresholdPercent;
    }

    function setTurbulenceDeviationPercent(uint16 _newTurbulenceDeviationPercentage) external override onlyOwner {
        require(_newTurbulenceDeviationPercentage < MAX_PERCENTAGE, "Deviation exceeds maximum");
        turbulenceDeviationPercentage = _newTurbulenceDeviationPercentage;
    }

    function setVolumeTimeWindow(uint16 _newVolumeTimeWindow) external override onlyOwner {
        volumeTimeWindow = _newVolumeTimeWindow;
    }

    function setVolumeFeeTimeWindow(uint16 _newVolumeFeeTimeWindow) external override onlyOwner {
        volumeFeeTimeWindow = _newVolumeFeeTimeWindow;
    }

    function setMaxVolumeFeeDeltaCollateral(uint16 _newMaxVolumeFeeDeltaCollateral) external override onlyOwner {
        maxVolumeFeeDeltaCollateral = _newMaxVolumeFeeDeltaCollateral;
    }

    function setMidVolumeFee(uint16 _newMidVolumeFee) external override onlyOwner {
        midVolumeFee = _newMidVolumeFee;
    }

    function setMaxVolumeFee(uint16 _newMaxVolumeFee) external override onlyOwner {
        maxVolumeFee = _newMaxVolumeFee;
    }

    function setCloseVolumeTimeWindow(uint16 _newCloseVolumeTimeWindow) external override onlyOwner {
        closeVolumeTimeWindow = _newCloseVolumeTimeWindow;
    }

    function setCloseVolumeFeeTimeWindow(uint16 _newCloseVolumeFeeTimeWindow) external override onlyOwner {
        closeVolumeFeeTimeWindow = _newCloseVolumeFeeTimeWindow;
    }

    function setCloseMaxVolumeFeeDeltaCollateral(uint16 _newCloseMaxVolumeFeeDeltaCollateral) external override onlyOwner {
        closeMaxVolumeFeeDeltaCollateral = _newCloseMaxVolumeFeeDeltaCollateral;
    }

    function setCloseMidVolumeFee(uint16 _newCloseMidVolumeFee) external override onlyOwner {
        closeMidVolumeFee = _newCloseMidVolumeFee;
    }

    function setCloseMaxVolumeFee(uint16 _newCloseMaxVolumeFee) external override onlyOwner {
        closeMaxVolumeFee = _newCloseMaxVolumeFee;
    }

    function calculateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) public view override returns (uint16) {
        uint16 updatedTurbulenceIndicatorPercent = turbulenceIndicatorPercent;

        uint256 CVIDeltaPercent = uint256(_currCVIValue > _lastCVIValue ? (_currCVIValue - _lastCVIValue) : (_lastCVIValue - _currCVIValue)) * MAX_PERCENTAGE / _lastCVIValue;
        uint256 maxAllowedTurbulenceTimes = CVIDeltaPercent * MAX_PERCENTAGE / (uint256(turbulenceDeviationThresholdPercent) * turbulenceDeviationPercentage);

        uint256 decayTimes = 0;
        uint256 turbulenceTimes = 0;
        uint256 totalHeartbeats = totalTime / oracleHeartbeatPeriod;
        if (newRounds > totalHeartbeats) {
            turbulenceTimes = newRounds - totalHeartbeats;
            turbulenceTimes = turbulenceTimes >  maxAllowedTurbulenceTimes ? maxAllowedTurbulenceTimes : turbulenceTimes;
            decayTimes = newRounds - turbulenceTimes;
        } else {
            decayTimes = newRounds;
        }

        for (uint256 i = 0; i < decayTimes; i++) {
            updatedTurbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent / 2;
        }

        if (updatedTurbulenceIndicatorPercent < maxTurbulenceFeePercentToTrim) {
            updatedTurbulenceIndicatorPercent = 0;
        }

        for (uint256 i = 0; i < turbulenceTimes; i++) {
            updatedTurbulenceIndicatorPercent = updatedTurbulenceIndicatorPercent + uint16(uint256(buyingPremiumFeeMaxPercent) * turbulenceStepPercent / MAX_PERCENTAGE);
        }

        if (updatedTurbulenceIndicatorPercent > buyingPremiumFeeMaxPercent) {
            updatedTurbulenceIndicatorPercent = buyingPremiumFeeMaxPercent;
        }

        return updatedTurbulenceIndicatorPercent;
    }

    function calculateBuyingPremiumFee(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio, uint256 _lastCollateralRatio, bool _withVolumeFee) external view override returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        (buyingPremiumFee, combinedPremiumFeePercentage) =  _calculateBuyingPremiumFeeWithParameters(_tokenAmount, _leverage, _collateralRatio, _lastCollateralRatio, _withVolumeFee, turbulenceIndicatorPercent, adjustedVolumeTimestamp);
    }
    
    function calculateBuyingPremiumFeeWithAddendum(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio, uint256 _lastCollateralRatio, bool _withVolumeFee, uint16 _turbulenceIndicatorPercent) external view override returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        (buyingPremiumFee, combinedPremiumFeePercentage) = _calculateBuyingPremiumFeeWithParameters(_tokenAmount, _leverage, _collateralRatio, _lastCollateralRatio, _withVolumeFee, 
            _turbulenceIndicatorPercent, getAdjustedTimestamp(adjustedVolumeTimestamp, _collateralRatio - _lastCollateralRatio, volumeTimeWindow, maxVolumeFeeDeltaCollateral));
    }

    function calculateClosingPremiumFee(uint256 /*_tokenAmount*/, uint256 /*_collateralRatio*/, uint256 /*_lastCollateralRatio*/, bool _withVolumeFee) external view override returns (uint16 combinedPremiumFeePercentage) {
        return _calculateClosingPremiumFee(_withVolumeFee, closeAdjustedVolumeTimestamp);
    }

    function calculateClosingPremiumFeeWithAddendum(uint256 _collateralRatio, uint256 _lastCollateralRatio, bool _withVolumeFee) external view override returns (uint16 combinedPremiumFeePercentage) {
        return _calculateClosingPremiumFee(_withVolumeFee,
            getAdjustedTimestamp(closeAdjustedVolumeTimestamp, _lastCollateralRatio - _collateralRatio, closeVolumeTimeWindow, closeMaxVolumeFeeDeltaCollateral));
    }

    function calculateSingleUnitFundingFee(CVIValue[] memory _cviValues) public override view returns (uint256 fundingFee) {
        for (uint8 i = 0; i < _cviValues.length; i++) {
            fundingFee = fundingFee + calculateSingleUnitPeriodFundingFee(_cviValues[i]);
        }
    }

    function updateSnapshots(uint256 _latestTimestamp, uint256 _blockTimestampSnapshot, uint256 _latestTimestampSnapshot, uint80 latestOracleRoundId) external override view returns (SnapshotUpdate memory snapshotUpdate) {
        (uint16 cviValue, uint80 periodEndRoundId, uint256 periodEndTimestamp) = cviOracle.getCVILatestRoundData();
        snapshotUpdate.cviValue = cviValue;
        snapshotUpdate.cviValueTimestamp = periodEndTimestamp;

        snapshotUpdate.latestSnapshot = _blockTimestampSnapshot;
        if (snapshotUpdate.latestSnapshot != 0) { // Block was already updated
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        if (_latestTimestamp == 0) { // For first recorded block
            snapshotUpdate.latestSnapshot = PRECISION_DECIMALS;
            snapshotUpdate.updatedSnapshot = true;
            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;
            snapshotUpdate.updatedLatestTimestamp = true;
            snapshotUpdate.singleUnitFundingFee = 0;
            return snapshotUpdate;
        }

        uint80 periodStartRoundId = latestOracleRoundId;
        require(periodEndRoundId >= periodStartRoundId, "Bad round id");

        snapshotUpdate.totalRounds = periodEndRoundId - periodStartRoundId;

        uint256 cviValuesNum = snapshotUpdate.totalRounds > 0 ? 2 : 1;
        IFeesCalculator.CVIValue[] memory cviValues = new IFeesCalculator.CVIValue[](cviValuesNum);
        
        if (snapshotUpdate.totalRounds > 0) {
            (uint16 periodStartCVIValue, uint256 periodStartTimestamp) = cviOracle.getCVIRoundData(periodStartRoundId);
            cviValues[0] = IFeesCalculator.CVIValue(periodEndTimestamp - _latestTimestamp, periodStartCVIValue);
            cviValues[1] = IFeesCalculator.CVIValue(block.timestamp - periodEndTimestamp, cviValue);

            snapshotUpdate.newLatestRoundId = periodEndRoundId;
            snapshotUpdate.updatedLatestRoundId = true;

            snapshotUpdate.totalTime = periodEndTimestamp - periodStartTimestamp;
            snapshotUpdate.updatedTurbulenceData = true;
        } else {
            cviValues[0] = IFeesCalculator.CVIValue(block.timestamp - _latestTimestamp, cviValue);
        }

        snapshotUpdate.singleUnitFundingFee = calculateSingleUnitFundingFee(cviValues);
        snapshotUpdate.latestSnapshot = _latestTimestampSnapshot + snapshotUpdate.singleUnitFundingFee;
        snapshotUpdate.updatedSnapshot = true;
        snapshotUpdate.updatedLatestTimestamp = true;
    }

    function calculateClosePositionFeePercent(uint256 _creationTimestamp, bool _isNoLockPositionAddress) external view override returns (uint16) {
        if (block.timestamp - _creationTimestamp >= closePositionFeeDecayPeriod || _isNoLockPositionAddress) {
            return closePositionFeePercent;
        }

        uint16 decay = uint16((closePositionMaxFeePercent - closePositionFeePercent) * (block.timestamp - _creationTimestamp) / 
            closePositionFeeDecayPeriod);
        return closePositionMaxFeePercent - decay;
    }

    function calculateWithdrawFeePercent(uint256) external view override returns (uint16) {
        return withdrawFeePercent;
    }

    function openPositionFees() external view override returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult) {
        openPositionFeePercentResult = openPositionFeePercent;
        buyingPremiumFeeMaxPercentResult = buyingPremiumFeeMaxPercent;
    }

    function calculateSingleUnitPeriodFundingFee(CVIValue memory _cviValue) private view returns (uint256 fundingFee) {
        if (_cviValue.cviValue == 0 || _cviValue.period == 0) {
            return 0;
        }

        uint256 fundingFeeRatePercents = FUNDING_FEE_MAX_RATE;
        uint16 integerCVIValue = _cviValue.cviValue / CVI_DECIMALS;
        if (integerCVIValue > MAX_FUNDING_FEE_CVI_THRESHOLD) {
            if (integerCVIValue >= MIN_FUDNING_FEE_CVI_THRESHOLD) {
                fundingFeeRatePercents = FUNDING_FEE_MIN_RATE;
            } else {
                // Defining as memory to keep function pure and save storage space + reads
                uint24[5] memory fundingFeeCoefficients = [100000, 114869, 131950, 151571, 174110];

                uint256 exponent = (integerCVIValue - MAX_FUNDING_FEE_CVI_THRESHOLD) / FUNDING_FEE_DIVISION_FACTOR;
                uint256 coefficientIndex = (integerCVIValue - MAX_FUNDING_FEE_CVI_THRESHOLD) % FUNDING_FEE_DIVISION_FACTOR;

                // Note: overflow is not possible as the exponent can only get larger, and other parts are constants
                // However, 2 ** exponent can overflow if cvi value is wrong

                require(exponent < 256, "exponent overflow");
                fundingFeeRatePercents = PRECISION_DECIMALS / (2 ** exponent) / fundingFeeCoefficients[coefficientIndex] + fundingFeeConstantRate;

                if (fundingFeeRatePercents > FUNDING_FEE_MAX_RATE) {
                    fundingFeeRatePercents = FUNDING_FEE_MAX_RATE;
                }
            }
        }

        return PRECISION_DECIMALS * _cviValue.cviValue * fundingFeeRatePercents * _cviValue.period /
            FUNDING_FEE_BASE_PERIOD / maxCVIValue / MAX_FUNDING_FEE_PERCENTAGE;
    }

    function _calculateBuyingPremiumFeeWithParameters(uint168 _tokenAmount, uint8 _leverage, uint256 _collateralRatio, uint256 _lastCollateralRatio, bool _withVolumeFee, uint16 _turbulenceIndicatorPercent, uint32 _adjustedVolumeTimestamp) private view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage) {
        require(_collateralRatio >= _lastCollateralRatio);

        uint16 buyingPremiumFeePercentage = 0;
        if (_collateralRatio >= PRECISION_DECIMALS) {
            buyingPremiumFeePercentage = calculateRelativePercentage(buyingPremiumFeeMaxPercent, _collateralRatio, _lastCollateralRatio);
        } else {
            if (_collateralRatio >= buyingPremiumThreshold * PRECISION_DECIMALS / MAX_PERCENTAGE) {
                buyingPremiumFeePercentage = calculateRelativePercentage(collateralToBuyingPremiumMapping[_collateralRatio * 10**2 / PRECISION_DECIMALS], _collateralRatio, _lastCollateralRatio);
            }
        }

        uint16 volumeFeePercentage = calculateVolumeFee(_withVolumeFee, _adjustedVolumeTimestamp, volumeTimeWindow, volumeFeeTimeWindow, midVolumeFee, maxVolumeFee);

        combinedPremiumFeePercentage = openPositionLPFeePercent + _turbulenceIndicatorPercent + buyingPremiumFeePercentage + volumeFeePercentage;
        if (combinedPremiumFeePercentage > buyingPremiumFeeMaxPercent) {
            combinedPremiumFeePercentage = buyingPremiumFeeMaxPercent;
        }

        uint256 __buyingPremiumFee = uint256(_tokenAmount) * _leverage * combinedPremiumFeePercentage / MAX_PERCENTAGE;
        buyingPremiumFee = uint168(__buyingPremiumFee);
        require(__buyingPremiumFee == buyingPremiumFee, "Too much tokens");
    }

    function _calculateClosingPremiumFee(bool _withVolumeFee, uint32 _adjustedCloseVolumeTimestamp) private view returns (uint16 combinedPremiumFeePercentage) {
        uint16 closingPremiumFeePercentage = calculateVolumeFee(_withVolumeFee, _adjustedCloseVolumeTimestamp, closeVolumeTimeWindow, closeVolumeFeeTimeWindow, closeMidVolumeFee, closeMaxVolumeFee);

        combinedPremiumFeePercentage = closePositionLPFeePercent + closingPremiumFeePercentage;
        if (combinedPremiumFeePercentage > closingPremiumFeeMaxPercent) {
            combinedPremiumFeePercentage = closingPremiumFeeMaxPercent;
        }
    }

    function calculateVolumeFee(bool _withVolumeFee, uint32 _adjustedVolumeTimestamp, uint16 _volumeTimeWindow, uint16 _volumeFeeTimeWindow, uint16 _midVolumeFee, uint16 _maxVolumeFee) private view returns (uint16 volumeFeePercentage) {
        if (_withVolumeFee) {
            if (_adjustedVolumeTimestamp < block.timestamp - _volumeFeeTimeWindow) {
                volumeFeePercentage = uint16(uint256(_midVolumeFee) * (_adjustedVolumeTimestamp - (block.timestamp - _volumeTimeWindow)) / (_volumeTimeWindow - _volumeFeeTimeWindow));
            } else {
                volumeFeePercentage = uint16(uint256(_midVolumeFee) + (_maxVolumeFee - _midVolumeFee) * (_adjustedVolumeTimestamp - (block.timestamp - _volumeFeeTimeWindow)) / _volumeFeeTimeWindow);
            }
        }
    }

    function calculateRelativePercentage(uint16 _percentage, uint256 _collateralRatio, uint256 _lastCollateralRatio) private view returns (uint16) {
        if (_lastCollateralRatio >= buyingPremiumThreshold * PRECISION_DECIMALS / MAX_PERCENTAGE || _collateralRatio == _lastCollateralRatio) {
            return _percentage;
        }

        return uint16(_percentage * (_collateralRatio - buyingPremiumThreshold * PRECISION_DECIMALS / MAX_PERCENTAGE) / (_collateralRatio - _lastCollateralRatio));
    }

    function getAdjustedTimestamp(uint32 _currAdjustedTimetamp, uint256 _deltaCollateral, uint16 _volumeTimeWindow, uint16 _maxVolumeFeeDeltaCollateral) private view returns (uint32 newAdjustedTimestamp) {
        newAdjustedTimestamp = _currAdjustedTimetamp;

        if (newAdjustedTimestamp < block.timestamp - _volumeTimeWindow) {
            newAdjustedTimestamp = uint32(block.timestamp) - _volumeTimeWindow;
        }

        newAdjustedTimestamp = uint32(newAdjustedTimestamp + uint256(_volumeTimeWindow) * _deltaCollateral / (_maxVolumeFeeDeltaCollateral * PRECISION_DECIMALS / MAX_PERCENTAGE));

        if (newAdjustedTimestamp > block.timestamp) {
            newAdjustedTimestamp = uint32(block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import "./ICVIOracle.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint16 cviValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 totalTime;
        uint256 totalRounds;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint16 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
        bool updatedTurbulenceData;
    }

    function updateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint16 lastCVIValue, uint16 currCVIValue) external;
    function updateAdjustedTimestamp(uint256 collateralRatio, uint256 lastCollateralRatio) external;
    function updateCloseAdjustedTimestamp(uint256 collateralRatio, uint256 lastCollateralRatio) external;

    function setOracle(ICVIOracle cviOracle) external;

    function setStateUpdator(address newUpdator) external;

    function setDepositFee(uint16 newDepositFeePercentage) external;
    function setWithdrawFee(uint16 newWithdrawFeePercentage) external;
    function setOpenPositionFee(uint16 newOpenPositionFeePercentage) external;
    function setOpenPositionLPFee(uint16 newOpenPositionLPFeePercent) external;
    function setClosePositionLPFee(uint16 newClosePositionLPFeePercent) external;
    function setClosePositionFee(uint16 newClosePositionFeePercentage) external;
    function setClosePositionMaxFee(uint16 newClosePositionMaxFeePercentage) external;
    function setClosePositionFeeDecay(uint256 newClosePositionFeeDecayPeriod) external;
    
    function setOracleHeartbeatPeriod(uint256 newOracleHeartbeatPeriod) external;
    function setBuyingPremiumFeeMax(uint16 newBuyingPremiumFeeMaxPercentage) external;
    function setBuyingPremiumThreshold(uint16 newBuyingPremiumThreshold) external;
    function setClosingPremiumFeeMax(uint16 newClosingPremiumFeeMaxPercentage) external;
    function setCollateralToBuyingPremiumMapping(uint16[] calldata newCollateralToBuyingPremiumMapping) external;
    function setFundingFeeConstantRate(uint16 newfundingFeeConstantRate) external;
    function setTurbulenceStep(uint16 newTurbulenceStepPercentage) external;
    function setMaxTurbulenceFeePercentToTrim(uint16 newMaxTurbulenceFeePercentToTrim) external;
    function setTurbulenceDeviationThresholdPercent(uint16 newTurbulenceDeviationThresholdPercent) external;
    function setTurbulenceDeviationPercent(uint16 newTurbulenceDeviationPercentage) external;

    function setVolumeTimeWindow(uint16 newVolumeTimeWindow) external;
    function setVolumeFeeTimeWindow(uint16 newVolumeFeeTimeWindow) external;
    function setMaxVolumeFeeDeltaCollateral(uint16 newMaxVolumeFeeDeltaCollateral) external;
    function setMidVolumeFee(uint16 newMidVolumeFee) external;
    function setMaxVolumeFee(uint16 newMaxVolumeFee) external;

    function setCloseVolumeTimeWindow(uint16 newCloseVolumeTimeWindow) external;
    function setCloseVolumeFeeTimeWindow(uint16 newCloseVolumeFeeTimeWindow) external;
    function setCloseMaxVolumeFeeDeltaCollateral(uint16 newCloseMaxVolumeFeeDeltaCollateral) external;
    function setCloseMidVolumeFee(uint16 newCloseMidVolumeFee) external;
    function setCloseMaxVolumeFee(uint16 newCloseMaxVolumeFee) external;

    function calculateTurbulenceIndicatorPercent(uint256 totalTime, uint256 newRounds, uint16 _lastCVIValue, uint16 _currCVIValue) external view returns (uint16);

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint256 lastCollateralRatio, bool withVolumeFee) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);
    function calculateBuyingPremiumFeeWithAddendum(uint168 tokenAmount, uint8 leverage, uint256 collateralRatio, uint256 lastCollateralRatio, bool withVolumeFee, uint16 _turbulenceIndicatorPercent) external view returns (uint168 buyingPremiumFee, uint16 combinedPremiumFeePercentage);

    function calculateClosingPremiumFee(uint256 tokenAmount, uint256 collateralRatio, uint256 lastCollateralRatio, bool withVolumeFee) external view returns (uint16 combinedPremiumFeePercentage);
    function calculateClosingPremiumFeeWithAddendum(uint256 collateralRatio, uint256 lastCollateralRatio, bool withVolumeFee) external view returns (uint16 combinedPremiumFeePercentage);

    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues) external view returns (uint256 fundingFee);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateClosePositionFeePercent(uint256 creationTimestamp, bool isNoLockPositionAddress) external view returns (uint16);
    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint16);

    function depositFeePercent() external view returns (uint16);
    function withdrawFeePercent() external view returns (uint16);
    function openPositionFeePercent() external view returns (uint16);
    function closePositionFeePercent() external view returns (uint16);
    function openPositionLPFeePercent() external view returns (uint16);
    function closePositionLPFeePercent() external view returns (uint16);

    function openPositionFees() external view returns (uint16 openPositionFeePercentResult, uint16 buyingPremiumFeeMaxPercentResult);

    function turbulenceIndicatorPercent() external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint16 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint16 cviValue, uint80 cviRoundId, uint256 cviTimestamp);

    function setDeviationCheck(bool newDeviationCheck) external;
    function setMaxDeviation(uint16 newMaxDeviation) external;
}