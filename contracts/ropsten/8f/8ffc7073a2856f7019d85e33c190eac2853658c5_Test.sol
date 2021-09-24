/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Test {
    
    uint256 a;
    
    function requireF() public {
        require(1 == 2, 'Va a fallar');
        a = 1;
    }


    function assertF() public {
        assert(1 == 2);
        a = 2;
    }
    
    function revertF() public {
        revert();
        a = 3;
    }
    uint256 number;

}