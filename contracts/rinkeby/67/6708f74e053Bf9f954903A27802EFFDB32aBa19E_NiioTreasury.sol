/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


/**
 * @title Niio Treasury
 */
contract NiioTreasury {

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    receive() external payable {}

    fallback() external payable {}


    /**
     * @dev Moves `amount` Ethers from this contract to `to`.
     */
    function transferValue(address payable to, uint256 amount) 
    public
    payable
    onlyOwner {
        require(address(this).balance + msg.value >= amount, "Insufficient funds");
        (bool sent,) = to.call{value : amount}("");
        require(sent, "Failed to send value");
    }

}