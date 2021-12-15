/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Loop {
    function loop() public {
        //  for loop
        for (uint i=0 ; i<10 ; i++) {
            if (i==3) {
                //  skip
                continue;
            }
            if (i==5) {
                //  exit
                break;
            }
        }

        uint j;
        while (j < 10) {
            j++;
        }
    }
}