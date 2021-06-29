/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity =0.6.6;

contract NoViewTest {
    uint private _seed = 66;

    function getSeed() external returns(uint) {
        if (false) {
            _seed = _seed;
        }
        return _seed;
    }
}