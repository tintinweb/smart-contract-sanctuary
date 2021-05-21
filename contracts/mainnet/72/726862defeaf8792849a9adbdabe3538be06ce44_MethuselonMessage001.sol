/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title MethuselonMessage001
 * @dev Store a message sent by Methuselon from the future.
 */
contract MethuselonMessage001 {

    address public immutable methuselon;
    string public messageFromFuture;
    
    /**
     * @dev Dogelon deploys the contract on behalf of Methuselon.
     */
    constructor(address methuselah) {
        methuselon = methuselah;
    }
    
    /**
     * @dev Receive a message from the future.
     * @param message message to store.
     */
    function receiveMessageFromFuture(string memory message) public {
        require(methuselon == msg.sender, "not methuselon");
        messageFromFuture = message;
    }
}