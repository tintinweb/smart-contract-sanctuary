// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

interface IReflectionsDataChannel {
    function postMessage(string memory message) external;
    function updateOwner(address newOwner) external;
}

contract FateVsFreeWill {
    
    uint16 private FREE_WILL = 16595;
    uint16 private FATE = 12587;
    
    IReflectionsDataChannel private channel = IReflectionsDataChannel(0xFEEDa52dc1c570533B68eFC9a6DaA2D212bCC836);
    address public owner;
    event Decided(string decision, uint256 randomNum);


    constructor() {
        owner = msg.sender;
    }

    function decide() public {
        require(msg.sender == owner, "not owner");
        
        // Generate a random integer between 0 and our total amount of Corruption(s*) voting for options 1 or 2
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    block.timestamp,
                    msg.sender
                )
            )
        ) % (FREE_WILL + FATE);

        // Send the appropriate message based on the random number
        if (random < FREE_WILL) {
            channel.postMessage("Free Will");
            emit Decided("Free Will", random);
        } else {
            channel.postMessage("Fate");
            emit Decided("Fate", random);
        }

        // Transfer back to the community wallet
        channel.updateOwner(owner);
    }

    // Backup method just in case
    function restoreOwner() public {
        require(msg.sender == owner, "not owner");
        channel.updateOwner(owner);
    }
}