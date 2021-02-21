/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

pragma solidity ^0.4.26;

contract Lottery100Places {

    event LotteryTicketPurchased(address indexed _purchaser, uint256 _ticketID);
    event LotteryAmountPaid(address indexed _winner, uint64 _ticketID, uint256 _amount);
    event LotteryAmountPaid2(address indexed _winner2, uint64 _ticketID2, uint256 _amount2);
    event LotteryAmountPaid3(address indexed _winner3, uint64 _ticketID3, uint256 _amount3);
    event LotteryAmountPaid4(address indexed _winner4, uint64 _ticketID4, uint256 _amount4);
    event LotteryAmountPaid5(address indexed _winner5, uint64 _ticketID5, uint256 _amount5);

    uint64 public ticketPrice = 100 finney;
    uint64 public ticketMax = 9;

    address[10] public ticketMapping;
    uint256 public ticketsBought = 0;

    address private marketingAddress;
    address private projectAddress;

    modifier allTicketsSold() {
      require(ticketsBought >= ticketMax);
      _;
    }

    constructor(address marketingAddr, address projectAddr)
        public payable
    {
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
    }
    function() payable public {
      revert();
    }

    function buyTicket(uint16 _ticket) payable public returns (bool) {
      require(msg.value >= ticketPrice, 'ERROR VALUE SENDED');
      require(_ticket > 0 && _ticket < ticketMax + 1, 'CANT USE TICKET NUMBER < 0 AND > 5');
      require(ticketMapping[_ticket] == address(0), 'OH! OH! YOU OWNER OF CONTRACT');
      require(ticketsBought < ticketMax,'ALL TIKETS SOLD');

      projectAddress.transfer((msg.value * 3) / 100);
      marketingAddress.transfer((msg.value * 3) / 100);
      
      address purchaser = msg.sender;
      ticketsBought += 1;
      ticketMapping[_ticket] = purchaser;
      emit LotteryTicketPurchased(purchaser, _ticket);


      if (ticketsBought>=ticketMax) {
        sendReward();
      }

      return true;
    }

    function sendReward() public allTicketsSold returns (address) {
      uint64 winningNumber = lotteryPicker();
      uint64 winningNumber2 = winningNumber / 2;
      uint64 winningNumber3 = winningNumber / 3;
      uint64 winningNumber4 = winningNumber - 1;
      uint64 winningNumber5 = winningNumber / 2 + 1;
      

      address winner = ticketMapping[winningNumber];
      address winner2 = ticketMapping[winningNumber2];
      address winner3 = ticketMapping[winningNumber3];
      address winner4 = ticketMapping[winningNumber4];
      address winner5 = ticketMapping[winningNumber5];


      uint256 totalAmount = ticketMax * ticketPrice / 2;

      require(winner != address(0));
      require(winner2 != address(0));
      require(winner3 != address(0));
      require(winner4 != address(0));
      require(winner5 != address(0));

      // Prevent reentrancy
      reset();
        for(uint i=1; i<5; i++){
            
        }
      winner.transfer(totalAmount);
      emit LotteryAmountPaid(winner, winningNumber, totalAmount);
      winner2.transfer(totalAmount);
      emit LotteryAmountPaid2(winner2, winningNumber2, totalAmount);
      winner3.transfer(totalAmount);
      emit LotteryAmountPaid3(winner3, winningNumber3, totalAmount);
      winner4.transfer(totalAmount);
      emit LotteryAmountPaid4(winner4, winningNumber4, totalAmount);
      winner5.transfer(totalAmount);
      emit LotteryAmountPaid2(winner5, winningNumber5, totalAmount);
    //   return {winner, winner2};
    }
  
    /* @return a random number based off of current block information */
    function lotteryPicker() public view allTicketsSold returns (uint64) {
      bytes memory entropy = abi.encodePacked(block.timestamp, block.number);
      bytes32 hash = sha256(entropy);
      return uint64(hash) % ticketMax;
    }
    
    function lotteryPicker2() public view allTicketsSold returns (uint64) {
      bytes memory entropy = abi.encodePacked(block.timestamp / 2, block.number);
      bytes32 hash = sha256(entropy);
      return uint64(hash) % ticketMax;
    }

    function reset() private allTicketsSold returns (bool) {
      ticketsBought = 0;
      for(uint x = 0; x < ticketMax+1; x++) {
        delete ticketMapping[x];
      }
      return true;
    }

    function getTicketsPurchased() public view returns(address[10]) {
      return ticketMapping;
    }
}