pragma solidity ^0.4.21;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Guess23 is owned {
    
    
    uint8 public maxnumber  = 100;
   // mapping (uint8 => address) players;
    mapping(address=>uint8[]) mynumbers;
    mapping(address => bool) isActuallyAnAddressOnMyList;
    mapping(uint8 => address[]) whosDaWinner;
    uint8[] allnumbers;
    address[]  allplayers;
    uint8 winningNumber;
    uint256 _lastPlayer;
    uint public maxplayers = 25;
    uint public roundnum  = 1;
    uint256 public myWinShare  = 5;
    uint256 public myLoseShare  = 0;
    address[] winnerlist;


    function Lottery() internal {
        state = LotteryState.Accepting;
    }
    
    uint8 number;
    
    enum LotteryState { Accepting, Finished }
    
    LotteryState state; 
    
    uint public minAmount = 10000000000000000;
    
    function isAddress(address check) public view returns(bool isIndeed) {
   return isActuallyAnAddressOnMyList[check];
}
  function getBalance() public view returns(uint256 balance) {
      return this.balance;
  }
   
   function play(uint8 mynumber) payable {
       require(msg.value == minAmount);
       require(mynumber >=0);
       require(mynumber <= maxnumber);
       require(state == LotteryState.Accepting);
      whosDaWinner[mynumber].push(msg.sender);
      mynumbers[msg.sender].push(mynumber);
       allnumbers.push(mynumber);
       if (!isAddress(msg.sender)){
           
           allplayers.push(msg.sender);
           isActuallyAnAddressOnMyList[msg.sender] = true;
       }
       if (allnumbers.length == maxplayers){
           state = LotteryState.Finished;
       }
       
   } 
   function seeMyNumbers()public view returns(uint8[], uint256) {
       return(mynumbers[msg.sender],mynumbers[msg.sender].length);
   }
   function seeAllNumbers() public view returns(uint8[]){
       return  allnumbers;
       //return numberlist;
   }
   function seeAllPlayers() public view returns(address[]){
       return allplayers;
   }

    function setMaxNumber(uint8 newNumber) public onlyOwner {
        maxnumber = newNumber;
    }
    
    function setMaxPlayers(uint8 newNumber) public onlyOwner {
        maxplayers = newNumber;
    }
    
    function setMinAmount(uint newNumber) public onlyOwner {
        minAmount = newNumber;
    }

      function sum(uint8[] data) private returns (uint) {
        uint S;
        for(uint i;i < data.length;i++){
            S += data[i];
        }
        return S;
    }
    
    function setMyCut(uint256 win, uint256 lose) public onlyOwner {
        myWinShare = win;
        myLoseShare = lose;
    }
    
    function determineNumber() private returns(uint8) {
        
        
        winningNumber = uint8(sum(allnumbers)/allnumbers.length/3*2);
       
    }
    
    function determineWinner() public onlyOwner returns(uint8, address[]){
        require (state == LotteryState.Finished);
        determineNumber();
       winnerlist = whosDaWinner[winningNumber];
       if (winnerlist.length > 0){
           owner.transfer(this.balance/100*myWinShare);
           uint256 numwinners = winnerlist.length;
           for (uint8 i =0; i<numwinners; i++){
               
               winnerlist[i].transfer(this.balance/numwinners);
           }
       } else {
           owner.transfer(this.balance/100*myLoseShare);
       }
         return (winningNumber, winnerlist);
        
        
    }
    
    function getNumAdd(uint8 num) public view returns(address[]) {
        return whosDaWinner[num];
        
    }
    
    function getResults() public view returns(uint8, address[]){
        return (winningNumber, winnerlist);
    }
    function startOver() public onlyOwner{
      //  uint8 i = number;
      for (uint8 i=0; i<allnumbers.length; i++){
        delete (whosDaWinner[allnumbers[i]]);
        //delete playerlist;
        }
    for (uint8 j=0;j<allplayers.length; j++){
        delete mynumbers[allplayers[j]];
        delete isActuallyAnAddressOnMyList[allplayers[j]];
    }
        delete allplayers;
        delete allnumbers;
        delete winnerlist;
        
        state = LotteryState.Accepting;
        roundnum ++;
        
        
}


}