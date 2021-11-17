/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.8.9;

contract BetGame {

    struct KnownPlayer {
        uint commitment;
        uint number;
        uint pledge;
        uint gasUsed;
        bool isKnown;
        uint position;
        bool isRevealed;
    }

    mapping(address => KnownPlayer) knownPlayers;
    address[] private players;
    address private winner;
    uint numberReveals;
    uint numberPlayers;
    address private manager;

    constructor(uint _numberPlayers) {
        numberPlayers = _numberPlayers;
        numberReveals = 0;
        manager = msg.sender;
    }

    event Commitment(address playerAddress, uint commtment);
    event Reveal(address playerAddress, uint number, string secret);
    event ReturnPledge(address playerAddress, uint returnAmount);
    event WinnerSelected(address _from, uint position);

    modifier onlyManager() {
        require(manager == msg.sender, "Only manager can change contract parameters");
        _;
    }

    function isKnownPlayer(address playerAddress) private view returns (bool isKnown) {
        return knownPlayers[playerAddress].isKnown;
    }

    function secretRevealed(address playerAddress) private view returns (bool isRevealed) {
        return knownPlayers[playerAddress].isRevealed;
    }

    function getCommitment(address playerAddress) private view returns (uint commitment) {
        return knownPlayers[playerAddress].commitment;
    }

    function addPlayer(address playerAddress, uint commitment, uint pledge) private {
        require(!isKnownPlayer(playerAddress), "Player already exists");
        knownPlayers[playerAddress].isKnown = true;
        knownPlayers[playerAddress].isRevealed = false;
        knownPlayers[playerAddress].commitment = commitment;
        knownPlayers[playerAddress].pledge = pledge;
        players.push(playerAddress);
        knownPlayers[playerAddress].position = players.length - 1;
    }

    function updatePlayer(address playerAddress, uint number, uint gasSpent) private {
        knownPlayers[playerAddress].isRevealed = true;
        knownPlayers[playerAddress].number = number;
        knownPlayers[playerAddress].gasUsed = gasSpent;
    }

    function generateCommitment(uint number, string memory secret) public pure returns (uint) {
        return uint(keccak256(abi.encodePacked(number, secret)));
    }

    function commit(uint commitment, uint bet, uint pledge) public payable {
        require(!isKnownPlayer(msg.sender), "Player may not place multiple bets");
        require(msg.value == (bet + pledge), "Value must be equal to the sum of the bet and the pledge");
        require(!(players.length == numberPlayers), "Maximum number of plaers reached");
        emit Commitment(msg.sender, commitment);
        addPlayer(msg.sender, commitment, pledge);
    }

    function reveal(uint number, string memory secret) public {
        require(players.length == numberPlayers, "Game incomplete");
        require(isKnownPlayer(msg.sender), "Unknown user can not reveal secret");
        require(!secretRevealed(msg.sender), "Player has already revealed");
        require(generateCommitment(number, secret) == getCommitment(msg.sender), "Wrong commitment");
        uint startGas = gasleft();
        emit Reveal(msg.sender, number, secret);
        if(numberReveals != players.length - 1) {
            updatePlayer(msg.sender, number, startGas - gasleft());
            numberReveals += 1;
        } else {
            uint winnerIndex = pickWinner();
            updatePlayer(msg.sender, number, startGas - gasleft());
            payOuPledge(startGas - gasleft(), winnerIndex);
        }
    }

    function pickWinner() private returns (uint winnerIndex) {
        uint value = 0;
        for(uint idx = 0; idx < players.length; ++idx) {
            value += knownPlayers[players[idx]].number;
        }
        winner = players[value % players.length];
        emit WinnerSelected(winner, value % players.length);
        return value % players.length;
    }

    function payOuPledge(uint gasSpent, uint winnerIndex) private {
        uint startGas = gasleft();
        uint otherPlayerGasCost = gasSpent;
        for(uint idx = 0; idx < players.length; ++idx) {
            if(otherPlayerGasCost < knownPlayers[players[idx]].gasUsed && idx != winnerIndex) {
                otherPlayerGasCost = knownPlayers[players[idx]].gasUsed;
            }
        }

        uint moreCostWinner = (gasSpent + startGas - gasleft()) / (players.length - 1);
        for(uint idx = 0; idx < players.length; ++idx) {
            uint returnAmount = 0;
            if(idx != winnerIndex) {
                returnAmount = knownPlayers[players[idx]].pledge - moreCostWinner;
            } else {
                returnAmount = knownPlayers[players[idx]].pledge;
            }
            emit ReturnPledge(players[idx], returnAmount);
            payable(players[idx]).transfer(returnAmount);
        }
    }

    function payOutWin() public {
        require(msg.sender == winner, "Only winner can be paid");
        payable(winner).transfer(address(this).balance);
        // Reset game
        numberReveals = 0;
        for(uint idx = 0; idx < players.length; ++idx) {
            knownPlayers[players[idx]].isKnown = false;
        }
        players = new address[](0);
        winner = address(0);
    }

    function setPlayersNumber(uint playersNumber) public onlyManager {
        numberPlayers = playersNumber;
    }
}