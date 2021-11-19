// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Basic_Lottery_By_Moiz {
    
address payable public  Lottery_Owner;
address payable[] private players_list;


  constructor ()
{
    Lottery_Owner = payable (msg.sender); // contract deployer is the Lottery Owner
}


  function getPlayerAddressAtIndex(uint index) public view returns(address player) {
        return players_list[index];
    }

    function getTotalPlayerCount() public view returns(uint count) {
        return players_list.length;
    }


  function Pay_For_Being_Part_of_Lottery() payable public {
    
    require (msg.value == 2 ether, "Participants need to deposit 2 Ether for being part of this Lottery." );
    require (msg.sender != Lottery_Owner, "Alert! Lottery Owner can't play.");
    players_list.push(payable(msg.sender)); 
}

   function Get_Total_Balance_Of_The_Contract() public view returns (uint)
{
    return address(this).balance;
}
 
   function Randomly_Generate_A_Number_To_Select_A_Player () internal view returns (uint) // no externally owned account or contract address can call this function, as its scope is internal and being called in pickWinnner function.
{
    return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp ,players_list.length)));
}
    
   function PickWinnerOFtheLottery () public returns(address)
{
    
    require (msg.sender == Lottery_Owner, "Alert! Only Lottery Owner can call this function");
    require (players_list.length >= 3, "Alert! There are not enough number of players right now");
    
    address payable Winner = players_list[Randomly_Generate_A_Number_To_Select_A_Player() % players_list.length]; // gives us a number from "0" to "players_list.length -1", if "players_list.length = 3" it will give us a number "2".
    
    Winner.transfer(Get_Total_Balance_Of_The_Contract()); // transfer all the money lock in the contract to the Winner of the lottery
    
    players_list = new address payable[] (0);  // Reset the lottery from the start, by removing all the players.
    return Winner;
    
}    
    
    
}// end of contract