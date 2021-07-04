/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Gas {
    uint public i = 0;

    //using up all of the gas of a transaction causes it to fail
    //state changes are reversed
    //gas spent is lost

    function forever() public {
        //Here we run a loop until all the fas is spent
        //transaction then fails
        while(true) {
            i += 1;
        }
    }
}