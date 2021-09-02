/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity >=0.4.22 <0.7.0;

contract sampleContract {
    function get () public {
        aLib.doStuff();
    }
}

library aLib {
    function doStuff() public {
    }
}