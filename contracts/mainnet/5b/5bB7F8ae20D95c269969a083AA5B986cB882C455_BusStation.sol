/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: BusStation.sol

contract BusStation {
    /* ==== Variables ===== */

    mapping(address => uint256) public _seats;
    bool public _hasBusLeft;
    uint256 public _ticketTotalValue;
    uint256 public _minTicketValue = 0;
    uint256 public _maxTicketValue;
    uint256 public _minWeiToLeave;
    address payable private _destination;

    uint256 public _timelockDuration;
    uint256 public _endOfTimelock;

    /* ==== Events ===== */

    /* 
    Removed for not being necessary and inflating gas costs
    event TicketPurchased(address indexed _from, uint256 _value); 
    event Withdrawal(address indexed _from, uint256 _value);
    event BusDeparts(uint256 _value);
    */

    /* ==== Constructor ===== */

    // Set up a one-way bus ride to a destination, with reserve price, time of departure, and cap on ticket prices for fairness
    constructor(
        address payable destination,
        uint256 minWeiToLeave,
        uint256 timelockSeconds,
        uint256 maxTicketValue
    ) {
        _hasBusLeft = false;
        _minWeiToLeave = minWeiToLeave;
        _maxTicketValue = maxTicketValue;
        _destination = destination;
        _timelockDuration = timelockSeconds;
        _endOfTimelock = block.timestamp + _timelockDuration;
    }

    /* ==== Functions ===== */

    // Purchase a bus ticket if eligible
    function buyBusTicket() external payable canPurchaseTicket {
        uint256 seatvalue = _seats[msg.sender];
        require(
            msg.value + seatvalue <= _maxTicketValue,
            "Cannot exceed max ticket value."
        );
        _seats[msg.sender] = msg.value + seatvalue;
        _ticketTotalValue += msg.value;
        /* emit TicketPurchased(msg.sender, msg.value); */
    }

    // If bus is eligible, anybody can trigger the bus ride
    function triggerBusRide() external isReadyToRide {
        uint256 amount = _ticketTotalValue;
        _ticketTotalValue = 0;
        _hasBusLeft = true;
        _destination.transfer(amount);
        /* emit BusDeparts(amount); */
    }

    // If eligible to withdraw, then pull money out
    function withdraw() external {
        // Cannot withdraw after bus departs
        require(_hasBusLeft == false, "Bus has already left.");

        // Retrieve user balance
        uint256 amount = _seats[msg.sender];
        require(amount > 0, "Address does not have a ticket.");

        // Write data before transfer to guard against re-entrancy
        _seats[msg.sender] = 0;
        _ticketTotalValue -= amount;
        payable(msg.sender).transfer(amount);
        /* emit Withdrawal(msg.sender, amount); */
    }

    /* === Modifiers === */

    // Can only purchase ticket if bus has not left and ticket purchase amount is small
    modifier canPurchaseTicket() {
        require(_hasBusLeft == false, "The bus already left.");
        require(msg.value > _minTicketValue, "Need to pay more for ticket.");
        _;
    }

    // Bus can ride if timelock is passed and tickets exceed reserve price
    modifier isReadyToRide() {
        require(_endOfTimelock <= block.timestamp, "Function is timelocked.");
        require(_hasBusLeft == false, "Bus is already gone.");
        require(_ticketTotalValue >= _minWeiToLeave, "Not enough wei to leave.");
        _;
    }
}