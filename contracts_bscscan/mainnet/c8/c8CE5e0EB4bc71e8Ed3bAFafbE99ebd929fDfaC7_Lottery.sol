/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

    interface IBEP20 {
    // mind the `view` modifier
    function balanceOf(address _owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Lottery{
    
    address payable[] public players;
    address payable public admin;
    uint256 public lastgame;
    address public lastwinner;
    uint256 public lastwin;
    
    IBEP20 private _token;
    
    event DoneStuff(address from);


    
    constructor()
    {
        admin = payable(msg.sender);
        lastgame = block.timestamp;
        _token = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
    }
    
    
function buylotteryticket() external
{
    address from = msg.sender;
    _token.approve(address(this), 1000000);
     _token.transferFrom(from, address(this), 1000000);
    emit DoneStuff(from);
}

    
    
    
/*    function transferToLottery() public payable{
    IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);    
        
    UltPowContract.approve(address(this),1000000000000000000000);
    //IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd).approve(msg.sender,1000000000000000000000);
    UltPowContract.transferFrom(msg.sender, address(this), 1000000000000000000000);
    players.push(payable(msg.sender));
    }
    
*/
    

    //receive() external payable
 //   {
        //IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
        //require(UltPowContract.transfer(msg.sender,1000000000000000000000 ) == true);
        //require(msg.value == 1 ether,"Must be at least 10000 UltPow");
        //require(msg.sender != admin, "No Admins allowed");
        
        //IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
       // uint yeah = UltPowContract.allowance(msg.sender, address(this));
        //require(yeah == 1 ether,"Must be at least 10000 UltPow");
        //players.push(payable(msg.sender));
        
        //players.push(payable(msg.sender));
   // }
    
   // function enter() public
   // {
        
    //    transferToLottery
        
     //   IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
        //uint tokenAmount = UltPowContract.allowance(msg.sender, address(this));
     //   require(UltPowContract.approve(address(this), 100000000000000000000));
    //    
        //require(UltPowContract.allowance(msg.sender, address(this)) > 0);
     //   require(UltPowContract.transferFrom(msg.sender,address(this),100000000000000000000));

        
       // uint tokenAmount = UltPowContract.allowance(msg.sender, address(this));
       // require(UltPowContract.transferFrom(msg.sender,address(this), 100000000000000000000));
    
        
        
        //bool transferred = UltPowContract.transferFrom(msg.sender, address(this), 100000000000000000000);
       // require(transferred == true,"You need 1000 ultpow to send");
        //uint yeah = UltPowContract.allowance(msg.sender, address(this));
        //require(yeah == 1 ether,"Must be at least 10000 UltPow");
    //    players.push(payable(msg.sender));
   // }
    
    function balanceOf() public view returns (uint256) {
           
     address bankAddress = address(this);
     IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
     return UltPowContract.balanceOf(bankAddress);
     
    }

    
    function random() internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function pickWinner() internal
    {
       // require(block.timestamp > lastgame + 24 hours,"24 hours not passed");
        require(block.timestamp > lastgame + 5 minutes,"24 hours not passed");
        require(players.length >= 3, "Not enough Players");
        IBEP20 UltPowContract = IBEP20(0xA78fD59D898B54E5D7bAc783B43ef45Bb87Ec9cd);
        
        address payable winner;
        
        winner = players[random() % players.length];
        lastwin = balanceOf();
        UltPowContract.transferFrom(address(this), winner, balanceOf());
        
        lastwinner = winner;
        players = new address payable[](0);
        lastgame = block.timestamp;
    }
    
    function lotterypicker() public
    {
        pickWinner();
    }
}