/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.6;

/**
 * @title ETHRelayer
 * @dev Ether relayer used to relay all ether received in this contract to the receiver address.
 * Receives ETH via legacy .transfer function using defualt 23000 gas limit and relay it using 100k gas limit to 
 * contracts that have enabled the fallback payable funciton.
 */
contract ETHRelayer{

    address payable public receiver;

    constructor(address payable _receiver) public {
        receiver = _receiver;
    }

    receive() external payable {}

    function relay() public {
      (bool success,) = receiver.call{gas: 100000, value: address(this).balance}("");
      require(success, "ETHRelayer: Relay transfer failed");
    }

}