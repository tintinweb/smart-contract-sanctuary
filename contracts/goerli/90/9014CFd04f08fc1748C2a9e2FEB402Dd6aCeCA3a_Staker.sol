pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;

  uint256 public treshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool isActive = false;


  event Stake(address user, uint256 amount);
  event Withdraw(address user, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }


  modifier deadlineReached(bool reached) {
    uint time = timeLeft();
    if ( reached ) {
      require (time == 0);
    } else {
    require(time > 0);
    }
  _;
  }


  modifier isNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed);
    _;
  }


  function stake() public payable deadlineReached(false) isNotCompleted {
    balances[msg.sender] = msg.value;

    if (address(this).balance >= treshold) {
      isActive = true;
    }
  }


  function execute() public isNotCompleted deadlineReached(false) {
    require(address(this).balance >= treshold, "Treshold not reached");
   

   
     (bool send,) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature("complete()"));
     require(send, "failed to send");
    
     
  }

  function withdraw(address payable to) public payable deadlineReached(true) isNotCompleted {
      uint amount = balances[msg.sender];
    
    require(amount > 0, "you have to deposit in order to withdraw");

      balances[msg.sender] = 0;
      

      to.transfer(amount);

      emit Withdraw(msg.sender, amount);
  }



  function timeLeft() public view returns(uint256) {
    if(block.timestamp >= deadline) {
      return 0; 
   } else {
    return deadline - block.timestamp;
   }
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  // Add the `receive()` special function that receives eth and calls stake()
}