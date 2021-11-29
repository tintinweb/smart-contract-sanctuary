/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract Counter{
    uint public count = 100;


    function incrementCount() public {
        count++;
    }

}