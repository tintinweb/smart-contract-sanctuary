// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/*
  ______      ()  ,                   __           
    //        /`-'|           _/_    /  )        / 
 --//_  _    /   / . . _  _   /     /--<  __ __ /_ 
(_// /_</_  /__-<_(_/_</_/_)_<__   /___/_(_)(_)/ <_
*/

/*
 bWljcm9kb3NlIHVudGlsIHRoZSBjb2RlIHdvcmtz 
*/


/// @notice The Guest Book Contract
contract TheGuestBook {
    /// @notice total guests
    uint256 public guestCount;

    // metadata
    struct Guest {
        address guest; // The address of the guest.
        string message; // The message the guest sent.
        uint256 timestamp; // The timestamp when the guest visited.
    }

    event NewGuest(
        address indexed from, 
        string message,
        uint256 timestamp
    );

    Guest[] private guests;

    /// @notice returns all guests
    function getAllGuests() public view returns (Guest[] memory) {
        return guests;
    }

    // guestbook functions
    /// @notice sign the guest book
    function signTheGuestBook(string memory message) public {
        Guest memory g = Guest(msg.sender, message, block.number);
        guests.push(g);
        emit NewGuest(msg.sender, message, block.number);
        guestCount += 1;
    } 
}