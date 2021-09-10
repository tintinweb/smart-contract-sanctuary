/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

contract HalsFavoriteEngineer {
    
    string engineerName;
    
    constructor() {
        engineerName = "Alen";
    }
    
    function get() external view returns(string memory) {
        return engineerName;
    }
    
    function set(string calldata _engineerName) external {
        engineerName = _engineerName;
    }
    
}