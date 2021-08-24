/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// File contracts/ExampleExternalContract.sol

pragma solidity >=0.6.0 <0.7.0;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  function withdraw() public {
    msg.sender.transfer(address(this).balance);
  }

}


// File contracts/Staker.sol

pragma solidity >=0.6.0 <0.7.0;

//import "hardhat/console.sol";

contract Staker {

  /**
   * @dev Emitted when a user stake some ether
   */
  event Stake(address from, uint256 value);

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public total;
  uint256 public deadline = now + 3 days;
  bool public openForWithdraw = false;

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Stake completed");
    _;
  }

  modifier deadlineReached() {
    require(now >= deadline, "Deadline not reached");
    _;
  }

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
    require(msg.value > 0, "You need to send some ether");
    balances[msg.sender] += msg.value;
    total += msg.value;

    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public deadlineReached notCompleted {
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable _to) public notCompleted {
    require(openForWithdraw, "Not open for withdraw");
    require(balances[_to] > 0, "No funds to withdraw");
    uint256 amount = balances[_to];
    total -= amount;
    balances[_to] = 0;
    _to.transfer(amount);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (now >= deadline) {
      return 0;
    }
    return deadline - now;
  }

}