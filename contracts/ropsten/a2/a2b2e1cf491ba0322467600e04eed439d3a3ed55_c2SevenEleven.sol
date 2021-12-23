/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title c2 seven/eleven
 * @dev holds solutionCode, which can be read by everyone (and set by owner, but only once)
 */
contract c2SevenEleven {

    string solutionCode;
    uint256 solutionCodeInitialized;
    address owner;

    constructor ()  {
        solutionCodeInitialized = 0;
        solutionCode = 'empty';
        owner = msg.sender;
    }

    function getSolution() public view returns (string memory) {
        return solutionCode;
    }

    function setSolution(string memory _solutionCode) public returns (uint256) {
        require(msg.sender == owner);
        if (solutionCodeInitialized == 1) {
            return 0;
        }
        solutionCodeInitialized = 1;
        solutionCode = _solutionCode;
        return 1;
    }
   
}