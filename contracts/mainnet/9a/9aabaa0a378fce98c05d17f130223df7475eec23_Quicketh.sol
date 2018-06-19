pragma solidity ^0.4.18;

contract Quicketh {
   // Bet 0.001 ETH.
   // Get a 10% change to win 0.008
   address public owner;                            // Who&#39;s the boss?
   uint public players;                             // How many are playing?
   address[] public playedWallets;                  // These can win
   address[] public winners;                        // These have won
   uint playPrice = 0.001 * 1000000000000000000;    // 0.001 ETH
   uint public rounds;                              // How long have we been going?

   event WinnerWinnerChickenDinner(address winner, uint amount);
   event AnotherPlayer(address player);


   function Quicketh() public payable{
       owner = msg.sender;
       players = 0;
       rounds = 0;
   }
   function play()  payable public{
       require (msg.value == playPrice);
       playedWallets.push(msg.sender);
       players += 1;
       AnotherPlayer(msg.sender);
       if (players > 9){
           uint random_number = uint(block.blockhash(block.number-1))%10 + 1;    // Get random winner
           winners.push(playedWallets[random_number]);                           // Add to winner list
           playedWallets[random_number].transfer(8*playPrice);                   // Send price to winner
           WinnerWinnerChickenDinner(playedWallets[random_number], 8*playPrice); // Notify the world
           owner.transfer(this.balance);                                         // Let&#39;s get the profits :)
           rounds += 1;                                                          // See how long we&#39;ve been going
           players = 0;                                                          // reset players
           delete playedWallets;                                                 // get rid of the player addresses
       }
   }
}