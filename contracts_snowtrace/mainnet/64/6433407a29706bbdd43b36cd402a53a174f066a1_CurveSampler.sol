/**
 *Submitted for verification at snowtrace.io on 2021-12-23
*/

// File: contracts/SmartRoute/intf/ICurve.sol

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // solium-disable-next-line mixedcase
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    // view coins address
    function underlying_coins(int128 arg0) external view returns(address out);
    function coins(int128 arg0) external view returns(address out);

}

// File: contracts/SmartRoute/sampler/CurveSample.sol




contract CurveSampler {
   
    function sampleFromCurve(
        address curveAddress,
        int128 fromTokenIdx,
        int128 toTokenIdx,
        uint256[] memory takerTokenAmounts,
        bool noLending
    )
        public
        view
        returns (uint256[] memory makerTokenAmounts)
    {
        uint256 numSamples = takerTokenAmounts.length;
        makerTokenAmounts = new uint256[](numSamples);
        for (uint256 i = 0; i < numSamples; i++) {
            uint256 buyAmount;
            if(noLending) {
                buyAmount = ICurve(curveAddress).get_dy(fromTokenIdx, toTokenIdx, takerTokenAmounts[i]);
            } else {
                buyAmount = ICurve(curveAddress).get_dy_underlying(fromTokenIdx, toTokenIdx, takerTokenAmounts[i]);
            }
              
            makerTokenAmounts[i] = buyAmount;
            // Break early if there are 0 amounts
            if (makerTokenAmounts[i] == 0) {
                break;
            }
        }
        return makerTokenAmounts;
    }
}