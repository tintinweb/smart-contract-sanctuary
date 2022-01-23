/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

contract Lottery {
    address public owner;
    address payable[] public tickets;
    address public winner = address(0);

    uint256 public ticketPrice;

    event TicketSold(address indexed _to, uint256 _amount);
    event WinnerDrawn(address _winner);
    event FundsReleased(address indexed _winner, uint256 _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "SENDER_NOT_OWNER");
        _;
    }

    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }

    function buyTicket() public payable {
        require(msg.value == ticketPrice, "INCORRECT_AMOUNT_SENT");

        tickets.push(payable(msg.sender));

        emit TicketSold(msg.sender, msg.value);
    }

    function drawWinner(uint256 randomNumber) public onlyOwner {
        uint256 index = randomNumber % tickets.length;
        winner = tickets[index];

        emit WinnerDrawn(msg.sender);
    }

    function releaseFunds() public onlyOwner {
        require(winner != address(0), "NO_WINNER_DRAWN");

        uint256 balance = address(this).balance;
        payable(winner).transfer(balance);

        emit FundsReleased(winner, balance);
    }

    function prizePool() public view returns (uint256) {
        return address(this).balance;
    }

    function ticketsSold() public view returns (uint256) {
        return tickets.length;
    }

    function players() public view returns (address payable[] memory){
        return tickets;
    }
}