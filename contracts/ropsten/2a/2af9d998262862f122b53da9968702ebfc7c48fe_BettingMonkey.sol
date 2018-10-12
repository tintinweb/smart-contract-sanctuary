pragma solidity ^0.4.18;

// Define smart contract of a basic betting DApp
// Players bet on the winner of a sport match: team One vs team Two.
// The winning amount can be presented with this simple formula:
// win = bet + (bet/totalBetOnYourTeam * totalBetOnTheOtherTeam)
// Developers: Amir Rahafrouz - An Pham - Sunnat Samadov
// Course: Networking Programming
// Lule&#229; University of Technology, Skellefte&#229;, Sweden.
contract Owned {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
       require(msg.sender == owner);
       _;
    }
}


contract BettingMonkey is Owned {
    address public owner; // The address of the contract owner, which is me.
    uint public minimumBet; // Player should meet the minimumBet
    uint public totalBetOne; // This is for the stake of the first team (uint)
    uint public totalBetTwo; // This is for the stake of the second team (uint)
    // uint public numberOfBets;
    uint public constant maxAmountOfBets = 100;

    struct Player {
      uint amountBet;
      uint selectedTeam;
    }
     // Address of the player and => the user info
    mapping(address => Player) public playerInfo;
    address payable[] public players; // To keep a list of all players

    constructor() public {
        minimumBet = 1 finney; // = 0.001 ether
    }

    event betInfo(
       uint team,
       uint betAmount
    );

    event gameEnded(uint winnerTeam, uint betAmount, uint winnerAmount);
    event gameSummary(uint winnerTeam, uint totalBetOne, uint totalBetTwo);

    function kill() onlyOwner public {
        if(msg.sender == owner) selfdestruct(msg.sender);
    }

    // To check if a player has already played
    function checkPlayerExists(address _player) public view returns (bool) {
    //   return playerInfo[player].amountBet != 0;
        for(uint i = 0; i < players.length; i++) {
            if (players[i] == _player) return true;
        }
        return false;
    }

    function bet(uint _selectedTeam) public payable {
        // Condition 1. One can play if has never played before
        require(!checkPlayerExists(msg.sender));
        // Condition 2. bet > minimumBet
        require(msg.value >= minimumBet);
        // Make sure _selectedTeam is ether 1 or 2
        require(_selectedTeam == 1 || _selectedTeam == 2);

        // We set the player informations : amount of the bet and selected team
        Player memory player = Player(msg.value, _selectedTeam);
        playerInfo[msg.sender] = player;
        // info.amountBet = msg.value;
        // info.selectedTeam = _selectedTeam;

        // Add the address of the player to the players array
        // to indicate that this player has already bet.
        players.push(msg.sender) -1;

        // Increase the stake of the selected team
        if ( _selectedTeam == 1) {
            totalBetOne += msg.value;
        } else {
            totalBetTwo += msg.value;
        }
        emit betInfo(_selectedTeam, msg.value);
    }

    function payTheWinner(uint _teamWinner) public payable {
        // Create a fixed array to keep all the winners.
        address payable[maxAmountOfBets] memory winners;

        uint winnerCount = 0;
        // Suppose winner team = 1
        uint loserBet = totalBetTwo;
        uint winnerBet = totalBetOne;

        // Update bet if winnerTeam = 2
        if (_teamWinner == 2) {
            loserBet = totalBetOne;
            winnerBet = totalBetTwo;
        }

        // We loop through the player array to check who selected the winner team
        for(uint i = 0; i < players.length; i++) {
            // address payable playerAddr = players[i];

            // If the player selected the winner team -> add his address to the winners array
            if (playerInfo[players[i]].selectedTeam == _teamWinner) {
                winners[winnerCount] = players[i];
                // winners.push(players[i]);
                winnerCount++;
            }
        }


        // Pay ethers to the winners
        for (uint j = 0; j < winnerCount; j++) {
            // Check that the address in this fixed array is not empty
            if (winners[j] != address(0)) {
                // address addr = winners[j];
                uint256 bet = playerInfo[winners[j]].amountBet;
                 // Transfer the money to the user
                uint256 transferAmount = bet + bet*loserBet/winnerBet;
                // send(addr, transferAmount);
                winners[j].transfer(transferAmount);
                emit gameEnded(_teamWinner, bet, transferAmount);
            }
        }

        // delete playerInfo;
        players.length = 0; // Delete all the players array
        loserBet = 0;
        winnerBet = 0;
        totalBetOne = 0;
        totalBetTwo = 0;

        emit gameSummary(_teamWinner, totalBetOne, totalBetTwo);
    }

    function send(address _receiver, uint _amount) public payable {
        _receiver.call.value(_amount);
    }

    function endGame() onlyOwner public payable {
        // Choose the winner team as a random_number 1 or 2
        uint teamWinner = uint(blockhash(block.number-1))%2 + 1;
        payTheWinner(teamWinner);
    }

    function betSummary() public view returns (uint, uint, uint) {
        // uint percentTeam1 = totalBetOne/(totalBetOne+totalBetTwo) * 100;
        uint percentTeam1 = percent (totalBetOne, totalBetOne+totalBetTwo, 3);
        uint count = players.length;
        return (percentTeam1, 1000-percentTeam1, count);
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getPlayerInfo(address _addr) public view returns (uint, uint) {
        return (playerInfo[_addr].amountBet, playerInfo[_addr].selectedTeam);
    }

    function percent(uint numerator, uint denominator, uint precision) public view returns(uint quotient) {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }
}