/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;

contract ProjectContent {

    string public leafletHash;
    string public date;


    function projectContent(string memory initialLeafletHash, string memory initialDate) public {
        leafletHash = initialLeafletHash;
        date = initialDate;
    }

    function setContract(string memory newLeafletHash, string memory newInitialDate) public {
        leafletHash = newLeafletHash;
        date = newInitialDate;
    }

    function getLeafletHash() public view returns ( string memory) {
      return leafletHash;
    }

    function getDate() public view returns ( string memory) {
      return date;
    }
}