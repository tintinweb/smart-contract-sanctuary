//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Token {
  function balanceOf(address) external view returns (uint);
  function transfer(address, uint) external returns (bool);
  function transferFrom(address, address, uint) external returns(bool);
}

// Let's assume token scale 1e6
interface Oracle {
  function getEthPriceInTokens() external view returns (uint);
}

// This was done as a toy contract deliberately, use cautiosly and with skepticism
contract AsteroidRaffle {

    enum RaffleState { Active, Finished }
    RaffleState public state;

    // Raffle governor
    address public immutable governor;
    // Accept payment in this token as well in addition to Eth
    Token public immutable token;
    // Allows to get price of eth in tokens
    Oracle public immutable oracle;
    // Ticket price in wei
    uint public ticketPrice;
    // All current round participants
    address[] public players;

    /*** Events ***/
    event NewPlayer(bool isToken, address participant, uint ticketPrice);
    event NewWinner(address winner, uint ethPrizeAmount, uint tokenPrizeAmount);
    event RaffleRestarted(address governor, uint ticketPrice);

    constructor(uint ticketPrice_, Token token_, Oracle oracle_) {
        governor = msg.sender;
        state = RaffleState.Active;
        ticketPrice = ticketPrice_;
        token = token_;
        oracle = oracle_;
    }

    function enterWithEth() external payable {
        require(state == RaffleState.Active, "Raffle is not active");
        require(msg.value == ticketPrice, "Incorrect ticket price");
        players.push(msg.sender);

        emit NewPlayer(false, msg.sender, ticketPrice);
    }

    function enterWithToken() external {
      uint tokenTicketPrice = (ticketPrice * oracle.getEthPriceInTokens()) / 1e18;
      require(token.transferFrom(msg.sender, address(this), tokenTicketPrice), "Token transfer failed");
      players.push(msg.sender);

      emit NewPlayer(true, msg.sender, tokenTicketPrice);
    }

    function determineWinner() external {
        require(msg.sender == governor, "Only owner can determine winner");
        // Finish the raffle
        state = RaffleState.Finished;
        // Pseudo-randolmly pick winner
        address winner = players[random() % players.length];

        // Distribute Eth prize pool to the winner
        uint ethPrizeAmount = address(this).balance;
        payable(winner).transfer(ethPrizeAmount);
        // (bool sent, bytes memory data) = winner.call{value: ethPrizeAmount}("");
        // require(sent, "Failed to send Ether");

        // Distribute token prize pool to the winner
        uint tokenPrizeAmount = token.balanceOf(address(this));
        require(token.transfer(winner, tokenPrizeAmount), "Token transfer failed");

        emit NewWinner(winner, ethPrizeAmount, tokenPrizeAmount);
    }

    function restartRaffle(uint newTicketPrice) external {
        require(state == RaffleState.Finished, "Raffle is already active");
        require(msg.sender == governor, "Only owner can restart raffle");
        state = RaffleState.Active;
        ticketPrice = newTicketPrice;

        // Delete previous players
        delete players;

        emit RaffleRestarted(governor, ticketPrice);
    }

    function random() internal view returns (uint) {
      return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }
}