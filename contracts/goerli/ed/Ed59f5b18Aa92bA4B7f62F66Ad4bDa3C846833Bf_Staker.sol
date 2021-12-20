pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

 /**
   * @title Staker Dapp built with Scaffold-ETH
   * @dev Allows several users to fundraise without the need to export trust to a third party.
   * Users stake ETH with the goal of meeting a threshold amount by a deadline. If the threshold of ETH is met by 
   * the deadline, all funds are exported to an external contract. If the threshold is NOT met by the deadline,
   * users can withdraw their funds.
   */
contract Staker {

//=======CONSTANTS/VARIABLES/MAPPING=======//

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline;

  bool public openForWithdrawal = false;

//=======EVENTS=======//

  event Stake(address user, uint256 amount);

//=======MODIFIERS=======//

/**
   * @dev Tracks whether the external contract has already been called. 
   */
  modifier notCompleted() {
    require(!exampleExternalContract.completed(), 
      "Funds already sent to External Contract"
    );
    _;
  }

/**
   * @dev Allows withdrawals. 
   */
  modifier withdrawalAllowed() {
    require(address(this).balance < threshold && 
      block.timestamp >= deadline, 
      "Can't withdraw."
    );
    _;
  }

//=======CONSTRUCTOR=======//
/**
   * @dev Initializes the exampleExternalContract and the deadline. 
   */
  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 72 hours;
  }

//=======FUNCTIONS=======//
/**
   * @dev Allows user to stake ETH and updates user balance. Sends an event that can be used on the frontend.
   */
  function stake() public payable notCompleted {
    balances[msg.sender] += msg.value;

    emit Stake(msg.sender, msg.value);
  }

/**
   * @dev Allows user to change the state of the contract after the deadline has passed and the threshold reached.
   */
  function execute() public notCompleted  {
    require(address(this).balance >= threshold, "Threshold not met");
    exampleExternalContract.complete{value: address(this).balance}();
  }

/**
   * @dev If threshold not met at deadline, anyone can withdraw.
   */
  function withdraw(address payable) public withdrawalAllowed notCompleted { 
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "No funds here");

    balances[msg.sender] = 0;

    (bool success,) = msg.sender.call{value: userBalance}("");
    require(success, "Transaction failed"); 
  }

/**
   * @dev The amount of time remaining in seconds until the deadline.
   */
  function timeLeft() public view returns(uint256 time) {
    if(block.timestamp >= deadline){
      return 0;
    }
    return deadline - block.timestamp;
  } 

/**
   * @dev If ETH is sent to the contract address, stake() is called.
   */
  receive() external payable {
    stake();
  }
}