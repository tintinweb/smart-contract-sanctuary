/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    string myAwesomeString = "Hi";
    uint16 count;

    /**
     * @dev Store value in variable
     * @param s secret
     */
    function SayHi(string calldata s) public returns(string memory) {
        require(keccak256(abi.encodePacked(s)) == keccak256(abi.encodePacked(myAwesomeString)));
        count++;
        return "You are awesome";
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function Count() public view returns (uint256){
        return count;
    }
}