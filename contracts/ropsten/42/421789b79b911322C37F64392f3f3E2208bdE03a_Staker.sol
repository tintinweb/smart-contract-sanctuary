// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address=>uint) public balances;
  uint256 public constant threshold= 1 ether;
  uint256 public deadline= block.timestamp + 72 hours;
  event Stake(address,uint256);
  bool public openForWithdraw;
  
  
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }
  function stake() public Timeover payable{
    balances[msg.sender] +=msg.value;
    emit Stake(msg.sender,msg.value);
  } 

  modifier Timeover() {
    require(block.timestamp<deadline,"timeover");
    _;
  }


  function withdraw(address payable _to)  notCompleted public {
    require(openForWithdraw == true);
    _to.transfer(balances[_to]);
    balances[msg.sender]--;
  }

  modifier notCompleted() {
    require(exampleExternalContract.completed()==false,"Transfer to contract completed already");
    _;
  }

  receive() external payable {
    stake();
  }
  modifier Maxcall() {
    require(i<1,"maxcalls done");
    _;
  }
  uint8 i=0;
  function execute() public notCompleted Maxcall{
    if (address(this).balance >= threshold){
      i++;
      exampleExternalContract.complete{value:address(this).balance}();

      
    }

    else if (block.timestamp >deadline) {
      i++; 
      openForWithdraw = true;
    }
    
      
  }
    

  
    function timeLeft() public view returns(uint) {
      return (deadline- block.timestamp);
    }

    


  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()


}