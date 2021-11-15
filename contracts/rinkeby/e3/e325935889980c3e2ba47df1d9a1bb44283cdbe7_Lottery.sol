/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

pragma solidity ^0.8.9;

contract Lottery {
    // Whoever creates the contract
    address public manager;

    address[] participants;

    constructor() {
        manager = msg.sender;
    }

    modifier mustBeManager() {
        require(msg.sender == manager, "Can only be called by the manager!");
        _;
    }

    function enterLottery() public payable {
        require(msg.value > .01 ether, "Please send at least 0.1 ETH");
        participants.push(msg.sender);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participants
                    )
                )
            );
    }

    function pickWinner() public payable mustBeManager {
        payable(participants[random() % participants.length]).transfer(
            address(this).balance
        );

        // resetting the participants array
        participants = new address[](0);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}