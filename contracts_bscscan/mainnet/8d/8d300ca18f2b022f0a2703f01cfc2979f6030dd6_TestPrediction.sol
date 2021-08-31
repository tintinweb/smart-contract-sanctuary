/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface Prediction {
    function currentEpoch() external view returns (uint);
    function ledger(uint256 epoch, address user) external view returns (uint8, uint256, bool);
}

contract TestPrediction  {
    address private constant PCS_PREDICTION = 0x18B2A687610328590Bc8F2e5fEdDe3b582A49cdA;

    enum Position {
        Bull,
        Bear
    }

    function getPrediction(address[] memory adds_ok, uint[] memory weights) public view returns (uint[] memory result) {
        uint downs = 0;
        uint ups = 0;
        uint downs_q = 0;
        uint ups_q = 0;

        result = new uint[](4);

        uint currentEpoch = Prediction(PCS_PREDICTION).currentEpoch();
        for (uint i = 0; i < adds_ok.length; i++) {
            (uint8 side, uint256 amount,) = Prediction(PCS_PREDICTION).ledger(currentEpoch, adds_ok[i]);
            if ( amount > 0 ) {
                if (side == 1) {
                    downs = downs + 1;
                    downs_q = downs_q + weights[i];
                }
                else {
                    ups = ups + 1;
                    ups_q = ups_q + weights[i];
                }
            }
        }
        result[0] = downs;
        result[1] = ups;
        result[2] = downs_q;
        result[3] = ups_q;
    }

}