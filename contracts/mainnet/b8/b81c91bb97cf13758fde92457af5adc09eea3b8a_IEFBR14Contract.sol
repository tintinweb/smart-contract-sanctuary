pragma solidity ^0.4.18;

//    88 88888888888 88888888888 88888888ba  88888888ba      88         ,d8  
//    88 88          88          88      "8b 88      "8b   ,d88       ,d888  
//    88 88          88          88      ,8P 88      ,8P 888888     ,d8" 88  
//    88 88aaaaa     88aaaaa     88aaaaaa8P&#39; 88aaaaaa8P&#39;     88   ,d8"   88  
//    88 88"""""     88"""""     88""""""8b, 88""""88&#39;       88 ,d8"     88  
//    88 88          88          88      `8b 88    `8b       88 8888888888888
//    88 88          88          88      a8P 88     `8b      88          88  
//    88 88888888888 88          88888888P"  88      `8b     88          88  
//    
//            THE SMART CONTRACT THAT DOESNT REALLY DO ANYTHING

contract IEFBR14Contract {
   address public owner;       // I made dis :)
   address[] public users;     // We use it
   address[] public sponsors;  // Yeah we sponsor...
   
   event IEF403I(address submitter);
   event IEF404I(address submitter);
   event S222(address operator);
   event IEE504I(address sponsor, uint value);

   function IEFBR14Contract() public payable{
       owner = msg.sender;
   }

   function IEFBR14()  public{
       // Ok, it does a little bit more than nothing :)
       IEF403I(msg.sender);
       users.push(msg.sender);
       IEF404I(msg.sender);       
   }

   function Cancel() public{
       // Let&#39;s make it possible to kill this contract
       require(msg.sender == owner);
       selfdestruct(owner);
       S222(msg.sender);
   }

   function Sponsor() payable public{
       // You never know, we might get some sponsors...
       IEE504I(msg.sender, msg.value);
       sponsors.push(msg.sender);
       owner.transfer(msg.value);
   }
}