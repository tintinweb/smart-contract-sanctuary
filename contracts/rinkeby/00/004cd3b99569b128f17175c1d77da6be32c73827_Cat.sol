/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.8.0;

/**
 * @title Some constact sample
 */
contract Cat {
    uint name;
    
    // Set name of the cat
    function setName(uint _name) public {
        name = _name;
    }
    
    // Get name of the cat
    function getName() public view returns (uint){
        return name;
    }
}