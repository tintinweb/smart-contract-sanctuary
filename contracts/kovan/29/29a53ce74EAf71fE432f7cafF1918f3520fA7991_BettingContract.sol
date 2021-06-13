/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol


pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: betting_main.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.7;


contract BettingContract {

    AggregatorV3Interface internal priceFeed;
    uint256 public contractCreationTime;
    mapping(uint256 => int) public dayPrice;
    mapping(uint256 => bet) public bets;
    uint public counter;
    uint lastUpdateTimeStamp;
    
    struct bet{
        uint creationTime;
        uint endTime;
        uint betAmount;
        address userUp;
        address userDown;
        int prediction;
        bool open;
    }
    
    constructor() public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        contractCreationTime = block.timestamp;
        lastUpdateTimeStamp = block.timestamp;
    }

    function createBet(int prediction, bool trueIfUp, uint endTime) updatePrices public payable{
        
        require(msg.value>0,'Bet cannot be of 0 Amount');
        counter += 1;
        
        if(trueIfUp==true){
            bet memory newBet = bet(block.timestamp, endTime, msg.value, msg.sender, address(0x0), prediction, true);
            bets[counter] = newBet;
        }
        else{
            bet memory newBet = bet(block.timestamp, endTime, msg.value, address(0x0), msg.sender, prediction, true);
            bets[counter] = newBet;
        }
        
    }
    
    function participateInBet(uint betId) updatePrices payable public{
        require(bets[betId].creationTime!=0,'Bet Does not Exist');
        require(bets[betId].endTime>block.timestamp,'Bet ended');
        require(bets[betId].open==true,'Bet is full');
        require(msg.value==bets[betId].betAmount,'BetAmount does not match');
        
        if(bets[betId].userUp==address(0x0)){
            bets[betId].userUp = msg.sender;
        }
        else{
            bets[betId].userDown = msg.sender;
        }
        bets[betId].open = false;
    }
    
    function getResult(uint betId) updatePrices public{
        require(bets[betId].creationTime!=0,'Bet Does not Exist');
        require(bets[betId].endTime<block.timestamp,'Bet not ended');
        require(bets[betId].open==false,'Bet had no oponent. cancel the bet');
        require(bets[betId].betAmount!=0, 'Bet result already announced');
        int endPrice = dayPrice[(bets[betId].endTime)/86400];
        if(endPrice==0){
            
        }
        require(endPrice>0,'Day price not yet announced');
        if(endPrice>bets[betId].prediction){
            payable(bets[betId].userUp).transfer(18*bets[betId].betAmount/10);
        }
        else{
            payable(bets[betId].userDown).transfer(18*bets[betId].betAmount/10);
        }
        bets[betId].betAmount=0;
        
    }
    
    function cancelBet(uint betId) updatePrices public{
        require(bets[betId].open==true, 'Bet has oponent');
        require(bets[betId].userUp==msg.sender || bets[betId].userDown==msg.sender, 'Not your bet!');
    
        payable(msg.sender).transfer(bets[betId].betAmount);
        bets[betId].betAmount=0;
        
    }
    
    modifier updatePrices(){
        if((block.timestamp-lastUpdateTimeStamp)/60/60 > 1){
            int price = getThePrice();
            if(dayPrice[block.timestamp/86400]!=0){
                dayPrice[block.timestamp/86400] = price;
            }
        lastUpdateTimeStamp = block.timestamp;
        }
        _;
    }
    
    
    function update() updatePrices public{
        
    }
    
    function getThePrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price/100000000;
    }
    
    receive() external payable {
        
  }
}