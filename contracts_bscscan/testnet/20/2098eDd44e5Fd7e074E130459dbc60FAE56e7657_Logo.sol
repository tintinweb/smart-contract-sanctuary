/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Logo {
    uint public logoCount = 30;
    
    event logoCountChanged(uint _logoCount);
    
    function setLogoCount(uint _logoCount) public {
        logoCount = _logoCount;
        emit logoCountChanged(_logoCount);
    }
}