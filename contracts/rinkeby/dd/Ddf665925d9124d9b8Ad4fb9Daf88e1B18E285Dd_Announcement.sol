/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Announcement {
   
   string public announcement;
   
   event AnnouncementChanged(address changer, string newAnnouncement);
   
   function setAnnouncment(string memory _announcement) public{
       announcement = _announcement;
       emit AnnouncementChanged(msg.sender, announcement);
   }
}