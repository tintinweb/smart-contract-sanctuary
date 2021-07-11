/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

pragma solidity ^0.4.25;

///@dev Simple onchain referral storage
contract BuddySystem {

    event onUpdateBuddy(address indexed player, address indexed buddy);

    mapping(address => address) private buddies;

    function() payable external {
        require(false, "Don't send funds to this contract");
    }

    ///@dev Updated the buddy of the sender
    function updateBuddy(address buddy) public {
        buddies[msg.sender] = buddy;
        emit onUpdateBuddy(msg.sender, buddy);
    }

    ///@dev Return the buddy of the sender
    function myBuddy() public view returns (address){
        return buddyOf(msg.sender);
    }

    ///@dev Return the buddy of a player
    function buddyOf(address player) public view returns (address) {
        return buddies[player];
    }

}