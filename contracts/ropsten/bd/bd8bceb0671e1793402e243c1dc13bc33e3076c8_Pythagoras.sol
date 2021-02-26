/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Pythagoras
 * @dev Set interest rate per year and get interest 
 * obtained for the number of years entered
 */
contract Pythagoras {

    uint256 side1;
    uint256 side2;

    /**
     * @dev Store values in variables
     * @param s1 value to store
     * @param s2 value to store
     */
    function set_param(uint256 s1, uint256 s2) public {
        require(0 < side1 && side2 > 0);
        side1 = s1;
        side2 = s2;
    }
    
    function sqrt(uint x)private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Return value 
     * @return estimation of third side of triangle
     */
    function perform_pythagoras_estimation() public view returns (uint256){
        return sqrt(side1**2+side2**2);
    }
}