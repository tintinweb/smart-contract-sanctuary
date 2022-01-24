// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ripLibrary.sol";

contract RIPLottery is Ownable{
    address[] private players;
    uint public maxPlayers = 10;
    uint public ticketPrice = 1e8 gwei;
    bool public paused = false;

    event TicketPriceChanged(uint previous, uint current);
    event Winner(address winnerAddress, uint amount);

    //function renounceOwnership() public pure override {
    //    revert("Doesn't make sense to renounce ownership");
    //}

    constructor() Ownable() {}

    function setMaxPlayers(uint i_maxPlayers) public onlyOwner {
        require(i_maxPlayers > 1, "Max Players must be at least 2");
        maxPlayers = i_maxPlayers;
        if (getNumPlayers() >= maxPlayers) {
            pickWinner();
        }
    }

    function setTicketPrice(uint i_price) public onlyOwner {
        require (players.length == 0, "you can't change ticket price during a lottery");
        emit TicketPriceChanged(ticketPrice, i_price);
        ticketPrice = i_price;
    }

    function setPause(bool p) public onlyOwner {
        paused = p;
    }

    function getNumPlayers() public view returns(uint){
        return players.length;
    }

    function enter() public payable {
        require(!paused || players.length > 0, "Sorry, can't join the new lottery: contract paused");
        uint num_tickets = msg.value/ticketPrice;
        require(num_tickets > 0, "Sorry, not enough ether to buy a ticket");
        for (uint i = 0; i < num_tickets; i++) {
            players.push(msg.sender);
        }
        if (getNumPlayers() >= maxPlayers) {
            pickWinner();
        }
    }

    function pickWinner() private {
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players, owner())));
        uint numb = rand % (getNumPlayers()*10 + 1);
        uint winner = numb/10;
        players.push(owner());
        address payable winnerAddress = payable(players[winner]);
        uint amount = address(this).balance;
        winnerAddress.transfer(amount);
        emit Winner(winnerAddress, amount);
        delete players;
    }
}