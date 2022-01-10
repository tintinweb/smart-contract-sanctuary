// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Treasury {
    address private treasuryOwner;

    constructor () {
        treasuryOwner = msg.sender;
    }
    
    modifier onlyTreasuryOwner {
        require(msg.sender == treasuryOwner, "Access denied");
        _;
    }

    receive() external payable {}

    function _treasuryOwner() external view returns(address) {
        return treasuryOwner;
    }

    function getTreasuryBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyTreasuryOwner {
        payable(treasuryOwner).transfer(address(this).balance);
    }
}