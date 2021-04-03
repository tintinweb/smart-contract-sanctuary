/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity 0.7.0;

contract LotteryContract {
    
  address payable owner;
  uint endDate;
  uint internal counterDaily = 0;
  uint internal counterWeekly = 0;
  uint internal counterMonthly = 0;
  uint public ownerCommission = 10;
  
  struct Lottery {
    uint nTickets;     // number of tickets
    uint ticket_price; // ticket pice
    uint prize;        // winner prize
    uint counter;      // current ticket
    uint aTickets;     // number of available tickets
    bool finished;
    uint endDate;
  }
  
  mapping (lotteryType => Lottery) internal lotteries;
  mapping (uint => address) internal playersDaily;
  mapping (address => bool) internal addressesDaily;   
  mapping (uint => address) internal playersWeekly;
  mapping (address => bool) internal addressesWeekly;   
  mapping (uint => address) internal playersMonthly;
  mapping (address => bool) internal addressesMonthly;   


  event winner(uint indexed counter, address winner, string message);
  
  event drawException(string message);
  
  enum lotteryType {
      DAILY,
      WEEKLY,
      MONTHLY
  }
  
  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
 
  function startLottery(lotteryType _lotteryType, uint tickets, uint price, uint lotteryPrize, uint endDateTime) public payable onlyOwner{
    require(lotteries[_lotteryType].aTickets == 0 && lotteries[_lotteryType].nTickets == 0, "Previous Lottery should close before start new Lottery");
    require (price > 0 && tickets > 1,
    "Ticket Number should greater than 1 OR Price should greater than zero.");
    lotteries[_lotteryType].nTickets = tickets;
    lotteries[_lotteryType].ticket_price = price;
    lotteries[_lotteryType].aTickets = tickets;
    lotteries[_lotteryType].prize = lotteryPrize;
    lotteries[_lotteryType].finished = false;
    lotteries[_lotteryType].endDate = endDateTime;
  }
  
  
  // Function to buy a ticket
  function buyTicket(lotteryType _lotteryType) public payable onlyOwner {
      if(_lotteryType == lotteryType.DAILY){
          require (lotteries[_lotteryType].aTickets != 0 && msg.value == lotteries[_lotteryType].ticket_price && lotteries[_lotteryType].endDate > block.timestamp && !addressesDaily[msg.sender], "Ticket Price should equal to the Sender value or Available Ticket should not equal to zero.");
          lotteries[_lotteryType].aTickets = lotteries[_lotteryType].aTickets - 1;
          playersDaily[++counterDaily] = msg.sender;
          addressesDaily[msg.sender] = true;
      }
      if(_lotteryType == lotteryType.WEEKLY){
          require (lotteries[_lotteryType].aTickets != 0 && msg.value == lotteries[_lotteryType].ticket_price && lotteries[_lotteryType].endDate > block.timestamp && !addressesWeekly[msg.sender], "Ticket Price should equal to the Sender value or Available Ticket should not equal to zero.");
          lotteries[_lotteryType].aTickets = lotteries[_lotteryType].aTickets - 1;
          playersWeekly[++counterWeekly] = msg.sender;
          addressesWeekly[msg.sender] = true;
      }
      if(_lotteryType == lotteryType.MONTHLY){
          require (lotteries[_lotteryType].aTickets != 0 && msg.value == lotteries[_lotteryType].ticket_price && lotteries[_lotteryType].endDate > block.timestamp && !addressesMonthly[msg.sender], "Ticket Price should equal to the Sender value or Available Ticket should not equal to zero.");
          lotteries[_lotteryType].aTickets = lotteries[_lotteryType].aTickets - 1;
          playersMonthly[++counterMonthly] = msg.sender;
          addressesMonthly[msg.sender] = true;
      }
      
  }
  
  
  function drawWinner(lotteryType _lotteryType) public onlyOwner{
       if (lotteries[_lotteryType].aTickets == 0 && !lotteries[_lotteryType].finished && lotteries[_lotteryType].endDate > block.timestamp) {
      endLottery(_lotteryType);
    }else {
        emit drawException("Lottery is not completed yet or End Date is completed.");
        revert();
    }
  }
  
  
  // Return the current status
  function status(lotteryType _lotteryType) public view onlyOwner returns(uint, uint, uint, uint, uint) {
    return (lotteries[_lotteryType].nTickets, lotteries[_lotteryType].aTickets, lotteries[_lotteryType].ticket_price, lotteries[_lotteryType].prize, lotteries[_lotteryType].endDate);
  }

 
  // End the contract and to find a winner
  function endLottery(lotteryType _lotteryType) internal{
      if (!lotteries[_lotteryType].finished) {
        getWinner(_lotteryType);
      }
      lotteries[_lotteryType].finished = true;
      lotteries[_lotteryType].prize = 0;
      lotteries[_lotteryType].nTickets = 0;
      lotteries[_lotteryType].aTickets = 0;
      lotteries[_lotteryType].ticket_price = 0;
      lotteries[_lotteryType].endDate = 0;
      if(_lotteryType == lotteryType.DAILY){
          counterDaily = 0;
      }
      if(_lotteryType == lotteryType.WEEKLY){
          counterWeekly = 0;
      }
      if(_lotteryType == lotteryType.MONTHLY){
          counterMonthly = 0;
      }
  }
  
  function random() private view returns (uint){
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
  }
  
  function setOwnerCommission(uint _newCommission) public onlyOwner {
      require(_newCommission>0 && _newCommission<50, "Commission should be between 0 to 50%");
      ownerCommission = _newCommission;
  }

  // Generate the winner and transfer the prize to his address
  function getWinner(lotteryType _lotteryType) internal onlyOwner {
    uint index = random() % lotteries[_lotteryType].nTickets;
    address payable winnerAddr;
    if(_lotteryType == lotteryType.DAILY){
         winnerAddr  = address(uint160(playersDaily[index]));
      }
      if(_lotteryType == lotteryType.WEEKLY){
          winnerAddr = address(uint160(playersWeekly[index]));
      }
      if(_lotteryType == lotteryType.MONTHLY){
          winnerAddr = address(uint160(playersMonthly[index]));
      }
    emit winner(index, winnerAddr, "The Lottery Winner found!!");
    owner.transfer(lotteries[_lotteryType].prize * ownerCommission/100);
    winnerAddr.transfer(lotteries[_lotteryType].prize * (100-ownerCommission)/100);
  }
  
  function transferOwner(address payable _newOwner) public onlyOwner {
      owner = _newOwner;
  }
  
  function viewOwner() public view returns(address payable){
      return owner;
  }
  
}