/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity 0.8.4;

contract Test{
    uint var1;
    
    function set() public {
        var1 = 1;
        delete var1;
    }
}