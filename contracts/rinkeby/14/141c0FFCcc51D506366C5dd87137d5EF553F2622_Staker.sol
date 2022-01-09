// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {
    bool public completed;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function complete() public payable {
        require(msg.sender == owner, "Not an owner!");
        completed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    event Stake(address indexed _staker, uint256 _amount);
    mapping(address => uint256) stakerToBalance;

    event ContractCreated(address addr);

    address public owner;
    uint256 public deadline;
    uint256 public threshold = 0.08 ether;
    bool public openForWithdraw = false;

    constructor() {
        exampleExternalContract = new ExampleExternalContract();
        emit ContractCreated(address(exampleExternalContract));
        owner = msg.sender;
        deadline = block.timestamp + 30 seconds;
    }

    // function setExternalContract(address _contractAddress)
    //     public
    //     onlyOwner(msg.sender)
    // {
    //     require(_contractAddress != address(0), "Invalid contract address!");
    // }

    function stake() public payable notCompleted beforeDeadline {
        require(msg.value > 0, "Invalid stake.");
        stakerToBalance[msg.sender] += msg.value;

        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public afterDeadline notCompleted {
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            // if the `threshold` was not met, allow everyone to call a `withdraw()` function
            openForWithdraw = true;
        }
    }

    // Add a `withdraw(address payable)` function lets users withdraw their balance
    function withdraw(address payable _staker)
        public
        notCompleted
        afterDeadline
    {
        require(openForWithdraw, "Withdraw not allowed");
        require(_staker == msg.sender, "Stake not owned");

        (bool sent, ) = _staker.call{value: stakerToBalance[_staker]}("");
        require(sent, "Failed to send ETH");
        stakerToBalance[_staker] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeleft() public view returns (uint256) {
        uint256 unixTimeLeft = deadline - block.timestamp;
        if (unixTimeLeft < 0) {
            return 0;
        } else {
            return unixTimeLeft;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable beforeDeadline {
        stake();
    }

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Already completed!");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp <= deadline, "Should be before deadline.");
        _;
    }

    modifier afterDeadline() {
        require(block.timestamp > deadline, "Should be after deadline.");
        _;
    }

    modifier onlyOwner(address _sender) {
        require(owner == _sender, "Not an owner!");
        _;
    }
}