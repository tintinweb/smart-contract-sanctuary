/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

//SPDX-License-Identifier: UNLICENSED


pragma solidity = 0.8.7;


contract BabyBased{
    
    uint256 block_deployed_at;
    uint256 hunger = 10;
    uint256 health = 10;
    uint256 enjoyment = 10;
    address payable boss = payable(address(0xCc8849e85dBE69bCdaf5c63FD6a4f758D8D46326));
    address player1 = 0xCc8849e85dBE69bCdaf5c63FD6a4f758D8D46326;
    address player2 = 0xd76f1b5e1C0cA5A219b2afa57c7eF8E445BA6F1C;
    address player3 = 0xc28fA76F1985821eb20456c8F2cE67543f881CbC;
    address player4 = 0xEB7d0bE769Cf857aFa5626B5F8208528F034b1Da;

    function feed() public returns(bool){ //sneed feed and seed
       if(msg.sender== player1 || msg.sender== player2 || msg.sender== player3 || msg.sender==player4) hunger++;
    }
    
        function  getHunger() public view returns (uint256){
            
            return hunger;
        }
    
    
    
    
    function heal() public returns(bool){
        if(msg.sender== player1 || msg.sender== player2 || msg.sender== player3 || msg.sender==player4) health++;
    }
     
        function  getHealth() public view returns (uint256){
          
          return health;
      }
    
    
     
       
    function play() public returns(bool){
        if(msg.sender== player1 || msg.sender== player2 || msg.sender== player3 || msg.sender==player4) enjoyment++;
    }
     

    function  getEnjoyment() public view returns (uint256){
        
        return enjoyment;
    }
       
       
    
    function kill() public payable returns(string memory){
        
        if(msg.sender== player1 || msg.sender== player2 || msg.sender== player3 || msg.sender==player4) selfdestruct(boss);
        return("you monster.");
    }  
       
       
}