/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

pragma solidity 0.5.0;


contract checks {
    uint256 mintingRateNoonerCoin;
    uint256 _randomValue;
    uint256 weekStartTime = now;

    function mintToken() public  returns(uint256){
        if(now-weekStartTime > 60) {
            _randomValue = 150;
            weekStartTime = now;
        }
        uint256 ok = 12;
        return ok;

    }
    function check() public view returns(uint256, uint256) {
        return (_randomValue, weekStartTime);
      
    }
}