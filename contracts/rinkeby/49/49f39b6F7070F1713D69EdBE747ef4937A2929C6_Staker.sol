// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleExternalContract {
    bool public completed;

    function complete() public payable {
        completed = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    mapping(address => uint256) public balances;
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool openForWithdraw = false;

    event Stake(address indexed sender, uint256 amount);

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable beforeDeadline {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    modifier afterDeadline() {
        require(block.timestamp > deadline, "wait for deadline");
        _;
    }

    modifier beforeDeadline() {
        require(block.timestamp < deadline, "deadline crossed");
        _;
    }

    modifier notCompleted() {
        require(
            !exampleExternalContract.completed() && !openForWithdraw,
            "contract not completed"
        );
        _;
    }

    modifier canWithdraw() {
        require(openForWithdraw, "funds cannot be withdrawn");
        _;
    }

    modifier completed() {
        require(
            exampleExternalContract.completed() || openForWithdraw,
            "contract not completed yet"
        );
        _;
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
    function execute() public notCompleted afterDeadline {
        uint256 balance = address(this).balance;
        if ((balance < threshold)) {
            // if the `threshold` was not met, allow everyone to call a `withdraw()` function
            openForWithdraw = true;
        } else {
            exampleExternalContract.complete{value: balance}();
        }
    }

    // Add a `withdraw(address payable)` function lets users withdraw their balance
    function withdraw(address payable addr) public canWithdraw {
        require(balances[addr] > 0, "you have no funds to withdraw");
        addr.transfer(balances[addr]);
        balances[addr] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp < deadline) {
            return deadline - block.timestamp;
        }
        return 0;
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}