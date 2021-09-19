/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity >=0.5.0 <0.6.0;

contract seansPoolTournament {

struct Player {
    address payable _address;
    uint _potting;
    uint _positioning;
    uint _safety;
    uint _stylepoints;
    uint _rungood;
    uint _score;
}

address payable[] public tournamentEntrants;
Player[] public tournamentPlayers;

event EntrantRegistered (address entrant, uint entrantCount);
event TournamentFinished (address winner);

function register() external payable {
    require(tournamentEntrants.length < 4, "Tournament full.");
    require(msg.value == 0.001 ether);
    address payable _newEntrant = msg.sender;
    tournamentEntrants.push(_newEntrant);
    emit EntrantRegistered(_newEntrant, tournamentEntrants.length);
}

function assignAttributes(address payable _entrant) private {
    uint randNonce = 0;
    uint randomPotting = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomPositioning = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomSafety = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomRungood = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomStylepoints = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 100;
    uint score = randomPotting + randomPositioning + randomSafety + randomRungood + randomStylepoints;
    tournamentPlayers.push(Player(_entrant, randomPotting, randomPositioning, randomSafety, randomStylepoints, randomRungood, score));
}

function setPlayers (address payable[] memory _tournamentEntrants) private {
    require(_tournamentEntrants.length == 4);
    for (uint i = 1; i < 5; i++) {
        assignAttributes(_tournamentEntrants[i-1]);
    }
}

function playRound(Player memory _p1, Player memory _p2) private pure returns(string memory) {
    if(_p1._score > _p2._score) {
        return "p1";
    } else if (_p1._score == _p2._score) {
        return "p1";
    } else {
        return "p2";
    }
}

function runTournament () public {
    setPlayers(tournamentEntrants);
    string memory round1a = playRound(tournamentPlayers[0], tournamentPlayers[1]);
    string memory round1b = playRound(tournamentPlayers[2], tournamentPlayers[3]);
    if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p1'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p1')))) {
        string memory round2 = playRound(tournamentPlayers[0], tournamentPlayers[2]);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[0]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[0]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[2]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[2]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p1'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p2')))) {
        string memory round2 = playRound(tournamentPlayers[0], tournamentPlayers[3]);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[0]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[0]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[3]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[3]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p2'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p1')))) {
        string memory round2 = playRound(tournamentPlayers[1], tournamentPlayers[2]);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[1]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[1]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[2]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[2]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p2'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p2')))) {
        string memory round2 = playRound(tournamentPlayers[1], tournamentPlayers[3]);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[1]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[1]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[3]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[3]._address);
        }
    }
    delete tournamentEntrants;
    delete tournamentPlayers;
}

}