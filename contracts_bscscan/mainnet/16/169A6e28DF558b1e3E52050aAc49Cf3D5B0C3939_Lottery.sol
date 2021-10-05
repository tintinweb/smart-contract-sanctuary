/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



  interface IBEP20 {
      
   function balanceOf(address _owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
  

}

contract Lottery{
    
    address[] public  players;
    address public admin;
    uint256 public lastgame;
    address public lastwinner;
    uint256 public lastwin;
    
 


    
    constructor()
    {
        admin = msg.sender;
        lastgame = block.timestamp;
     
    }
    
    function buy() external {
        IBEP20 tokenContract = IBEP20(address(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd)); 

       
        require(
            tokenContract.transferFrom(
                msg.sender, 
                address(this), 
                1000 * (10 ** 18) 
            ) == true,
            'Could not transfer tokens from your address to this contract' 
        );
        
        players.push(msg.sender);
    }
    
    function balanceOf() public view returns (uint256) {
           
     address bankAddress = address(this);
     IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
     return UltPowContract.balanceOf(bankAddress);
     
    }

    
    function random() internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function pickWinner() public
    {
        require(block.timestamp > lastgame + 24 hours,"24 hours not passed");
       // require(block.timestamp > lastgame + 5 minutes,"24 hours not passed");
        require(players.length >= 3, "Not enough Players");
        IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
        
        if(msg.sender != admin)
        {
            uint256 reward = 2000000000000000000000;
            UltPowContract.transfer(msg.sender, reward);
        }
        
        address winner;
        
        winner = players[random() % players.length];
        lastwin = balanceOf();
        UltPowContract.transfer(winner, balanceOf());
        
        lastwinner = winner;
        players = new address[](0);
        lastgame = block.timestamp;
    }
    
    function getPlayerCount() public view returns(uint)
    {
        return players.length;
    }
  
}