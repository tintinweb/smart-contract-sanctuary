/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract beta_test {
  address owner = 0x11c501c573D1E47FAF2DA5838F83aCE5B440C1F4;

  uint reward_pool;
  address[]  player_pool;
   
   
      function check_reward()public view returns(uint){
      return reward_pool;
}




      function Buy_Ticket() public payable {
        require(msg.value == 500000  , "not enough money");
      reward_pool += msg.value;
      player_pool.push(msg.sender);
        
        
}
   
   

      function Check_player() public view returns (uint){
      return player_pool.length;
            
    }   
 
  
      function countdigit(uint sumNplay)private pure returns (uint){
      uint n =0;
      uint y = 1;
      uint x;
      uint a = sumNplay;
      for (uint i = 0; y!=0;i++){
      x = 10**i;
      y = a/x;
      n = n+1;
}
      return n-1;
}
      function random(uint digit)private view returns(uint){
      uint Rand;
      Rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
      uint Digi = 10**digit;
      uint Q = Rand%Digi;
      return Q;
   

}




      function getN(uint N) private view returns (uint){
      uint winner;
      uint B;
      uint A ;
      A = countdigit(N);
      B = random(A);
      winner = B;
      return winner;
}


      function whowin()private view returns(address){
      uint Maxplayer = Check_player();
  
      uint w = getN(Maxplayer);
      address win = player_pool[w];

      return win ;

}

      function GameStart()public payable {
      require(msg.sender == owner , "You are not authorized");
      address winner = whowin();
      payable(winner).transfer(reward_pool*9/10);
      reward_pool -= reward_pool*9/10;
      payable(owner).transfer(reward_pool*1/10);
      reward_pool -= reward_pool*1/10;
  

}



}