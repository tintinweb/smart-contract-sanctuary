/**
 *Submitted for verification at polygonscan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Lottery {
    struct Ticket {
        uint256 id;
        uint256 createDateTime;
        address member;
        bool win;
    }

    address public owner;
    mapping(uint256 => Ticket) public tickets;
    uint256 ticketPrice = 1;
    uint256 ticketCode = 0;
    uint256 invested = 0;
    uint256 public startDate;
    uint16 public day;

    bool isLotteryDone;

    event BuyTicket(address indexed addr, uint256 amount, uint256 ticketCode);
    event Winner(address indexed addr, uint256 amount, uint256 ticketCode);

    constructor(uint16 _day) public {
        day = _day;
        owner = msg.sender;
        startDate = block.timestamp;
    }

    function buyTicket() public payable returns (uint256) {
        require(msg.value == ticketPrice);
        require(block.timestamp < startDate + (day * 84600));
        payable(owner).transfer(msg.value / 10);
        ticketCode++;
        invested += (msg.value * 90) / 100;
        tickets[ticketCode] = Ticket(
            ticketCode,
            block.timestamp,
            msg.sender,
            false
        );
        emit BuyTicket(msg.sender, msg.value, ticketCode);
        return ticketCode;
    }

    function startLottery() public {
        require(msg.sender == owner);
        require(block.timestamp > startDate + (day * 84600));
        require(isLotteryDone == false);
        uint256 winnerIndex = random(ticketCode);
        tickets[winnerIndex].win = true;
        payable(tickets[winnerIndex].member).transfer(invested);
        isLotteryDone = true;
        emit Winner(tickets[winnerIndex].member, invested, winnerIndex);
    }

    function random(uint256 count) private view returns (uint256) {
        uint256 rand = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) % count;
        return rand;
    }
}