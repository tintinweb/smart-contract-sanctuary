/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity ^0.6.7;

interface ExternallyFundedOSM {
    function updateResult() external;
}

interface OracleRelayer {
    function updateCollateralPrice(bytes32 collateralType) external;
}

interface CoinMedianizer {
    function updateResult(address feeReceiver) external;
}

interface RateSetter {
    function updateRate(address feeReceiver) external;
}

contract PingerBundledCall {
    ExternallyFundedOSM public osmEthA;
    OracleRelayer public oracleRelayer;
    CoinMedianizer public coinMedianizer;
    RateSetter public rateSetter;
    bytes32 ETH_A = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    
    constructor(address osmEthA_, address oracleRelayer_, address coinMedianizer_, address rateSetter_) public {
        osmEthA = ExternallyFundedOSM(osmEthA_);
        oracleRelayer = OracleRelayer(oracleRelayer_);
        rateSetter = RateSetter(rateSetter_);
        coinMedianizer = CoinMedianizer(coinMedianizer_);
    }

    function updateOsmAndEthAOracleRelayer() external {
        osmEthA.updateResult();
        oracleRelayer.updateCollateralPrice(ETH_A);
    }

    function updateOsmAndOracleRelayer(address osm, bytes32 collateralType) external {
        ExternallyFundedOSM(osm).updateResult();
        oracleRelayer.updateCollateralPrice(collateralType);
    }

    function updateCoinMedianizerAndRateSetter(address feeReceiver) external {
        coinMedianizer.updateResult(feeReceiver);
        rateSetter.updateRate(feeReceiver);
    }

}