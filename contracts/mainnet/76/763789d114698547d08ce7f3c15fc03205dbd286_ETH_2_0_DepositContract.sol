pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

contract ETH_2_0_DepositContract {
    
     // all ETH get burned to this address
     address public burnAddress = 0x0000000000000000000000000000000000000000;
     
     // owner, mainly just for the lpp announcements and has no other rights
     address public owner = msg.sender;
     
     // mapping of all ETH 2.0 balances
     mapping(address => uint256) public burns;
     
     // Finalization date
     uint256 public endDate = block.timestamp + (64*24*60*60); // 64 days
     
     // Lpp Announcement via log event
     struct AnnouncementStruct {
         address accountLpp;
     }
     event Announcement(AnnouncementStruct);
     
     function() external payable {
         deposit();
     }
     
     // deposit eth for eth 2.0
     function deposit() public payable {

         // record amount of ETH 2.0 token
         if( block.timestamp < endDate)
            burns[msg.sender] = msg.value;
         
         // burn all ether after endDate to unrecoverable 0x0000.. address
         else
            burnAddress.transfer(address(this).balance);
     }
     
       // an option to burn prematurely
     function burnBalance() external {
         
         require(msg.sender == owner);
         burnAddress.transfer(address(this).balance);
         
     }
     
     // lpp broadcasts via log events
     function log(address lpp) external {
         
         require(msg.sender == owner);
         AnnouncementStruct s;
         s.accountLpp = lpp;
         emit Announcement(s);
         
     }
     
   
}