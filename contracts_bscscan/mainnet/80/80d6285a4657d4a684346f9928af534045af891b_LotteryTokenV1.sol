/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


abstract contract Ownable {

  address owner;


  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
      require(owner == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
      owner = newOwner;
  }
  
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

/*
    This lottery uses a random number from the future to determine ticket placement for winnings.
    
    
    When the lotter is stopped, it means that the seed will come from the next block's hash which
    is a value that no one can predict.

    We then use that seed to generate a random lucky number for each ticket.

    By ording the tickets based on their lucky number, we are able to determine what position
    each ticket finished.

    This implementation is the most fair and efficient form of lottery smart contract.
*/

contract LotteryTokenV1 is Ownable {

  enum Status { NOT_INITIALIZED, PENDING, RUNNING, FINISHED }

  event TicketSold(address playerAddress, uint256 ticketId);
  event Payment(address to, uint256 value);
  
  mapping(uint256=>address) public ticketOwnerAddress;
  
  Status public status;
  
  uint256 public totalTicketsSold;
  uint256 public ticketPrice;
  uint256 public rakePer100k;
  uint256 public seedBlockNumber;

  IERC20 public token;

  function setStatus(Status value) internal {
    if(value != status) {
      status = value;
    }
  }

  function start() public onlyOwner {
    require(status == Status.PENDING);
    setStatus(Status.RUNNING);
  }


  function init(uint256 _ticketPrice, uint256 _rakePer100k, bool autoStart) public onlyOwner {
    ticketPrice = _ticketPrice;
    rakePer100k = _rakePer100k;
    totalTicketsSold = 0;
    setStatus(Status.PENDING);
    if(autoStart) start();
  }
  
  constructor() {
    token = IERC20(0x3C00F8FCc8791fa78DAA4A480095Ec7D475781e2);
    init(0.5 ether, 0, true); // 500,000,000 
  }

  function purchaseTickets(uint amt) public {
    purchaseTicketsForAddress(amt, msg.sender);
  }

  function purchaseTicketsForAddress(uint amt, address addr) public {
    require(status == Status.RUNNING, "not running");
    token.transferFrom(msg.sender, address(this), ticketPrice * amt);
    for(uint i = 0; i < amt; ++i) {
      ++totalTicketsSold;
      ticketOwnerAddress[totalTicketsSold] = msg.sender;
      emit TicketSold(addr, totalTicketsSold);
    }
  }

  function stop() public onlyOwner {
    require(status == Status.RUNNING, "not running");
    setStatus(Status.FINISHED);
    seedBlockNumber = block.number + 1;
  }

  function pay(address payable to, uint256 value) public onlyOwner {
    require(status == Status.FINISHED);
    token.transfer(to, value);
    emit Payment(to, value);
  }

  function getPot() public view returns (uint256) {
    return ticketPrice * totalTicketsSold;
  }

  function getRake() public view returns (uint256) {
    return getPot() * rakePer100k / 100000;
  }

  function getTotalPrizes() public view returns (uint256) {
    return getPot() - getRake();
  }

  function getLuckyNumbers() public view returns(uint256[] memory luckyNumbers) {
    require(status == Status.FINISHED, "not finished");
    require(seedBlockNumber < block.number, "wait one more block");
    bytes32 currSeed = blockhash(seedBlockNumber);
    luckyNumbers = new uint256[](totalTicketsSold);
    for(uint256 i = 0; i < totalTicketsSold; ++i) {
      luckyNumbers[i] = uint256(currSeed);
      currSeed = keccak256(abi.encodePacked(currSeed));
    }
  }

}