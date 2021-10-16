/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract SeansPoolTournamentv86 {

struct Player {
    address payable _address;
    uint _potting;
    uint _positioning;
    uint _composure;
    uint _stylepoints;
    uint _rungood;
    uint _score;
}

mapping (address => bool) public registered;

address payable[] public tournamentEntrants;
Player[] public tournamentPlayers;

event EntrantRegistered (address entrant, uint entrantCount);
event TournamentFinished (address winner);
event AttributesDefined (address entrant, uint randomPotting, uint randomPositioning, uint randomComposure, uint randomStylepoints, uint randomRungood, uint score);
event RoundOver (address p1, address p2, uint p1Score, uint p2Score, string winner);

function register() external payable {
    require(tournamentEntrants.length < 4, "Tournament full.");
    require(msg.value == 0.001 ether, "Pay up.");
    require(registered[msg.sender] == false, "You've already registered.");
    address payable _newEntrant = payable(msg.sender);
    tournamentEntrants.push(_newEntrant);
    registered[msg.sender] = true;
    emit EntrantRegistered(_newEntrant, tournamentEntrants.length);
}

uint randNonce;

function setRandNonce (uint num) public {
    randNonce = num;
}

function getRandNonce () public view returns (uint _randNonce) {
    return randNonce;
}

function clearTournamentEntrants () public {
    delete tournamentEntrants;
    registered[tournamentEntrants[0]] = false;
    registered[tournamentEntrants[1]] = false;
    registered[tournamentEntrants[2]] = false;
    registered[tournamentEntrants[3]] = false;
}

function assignAttributes(address payable _entrant) private {
    randNonce++;
    uint randomPotting = uint(keccak256(abi.encodePacked(block.timestamp, _entrant, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomPositioning = uint(keccak256(abi.encodePacked(block.timestamp, _entrant, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomComposure = uint(keccak256(abi.encodePacked(block.timestamp, _entrant, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomRungood = uint(keccak256(abi.encodePacked(block.timestamp, _entrant, msg.sender, randNonce))) % 100;
    randNonce++;
    uint randomStylepoints = uint(keccak256(abi.encodePacked(block.timestamp, _entrant, msg.sender, randNonce))) % 100;
    randNonce++;
    uint score = randomPotting + randomPositioning + randomComposure + randomRungood + randomStylepoints;
    tournamentPlayers.push(Player(_entrant, randomPotting, randomPositioning, randomComposure, randomStylepoints, randomRungood, score));
    emit AttributesDefined(_entrant, randomPotting, randomPositioning, randomComposure, randomStylepoints, randomRungood, score);
}

function setPlayers (address payable[] memory _tournamentEntrants) private {
    require(_tournamentEntrants.length == 4);
    for (uint i = 1; i < 5; i++) {
        assignAttributes(_tournamentEntrants[i-1]);
        randNonce++;
        registered[_tournamentEntrants[i-1]] = false;
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
    emit RoundOver (tournamentPlayers[0]._address, tournamentPlayers[1]._address, tournamentPlayers[0]._score, tournamentPlayers[1]._score, round1a);
    string memory round1b = playRound(tournamentPlayers[2], tournamentPlayers[3]);
    emit RoundOver (tournamentPlayers[2]._address, tournamentPlayers[3]._address, tournamentPlayers[2]._score, tournamentPlayers[3]._score, round1b);
    if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p1'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p1')))) {
        string memory round2 = playRound(tournamentPlayers[0], tournamentPlayers[2]);
        emit RoundOver (tournamentPlayers[0]._address, tournamentPlayers[2]._address, tournamentPlayers[0]._score, tournamentPlayers[2]._score, round2);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[0]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[0]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[2]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[2]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p1'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p2')))) {
        string memory round2 = playRound(tournamentPlayers[0], tournamentPlayers[3]);
        emit RoundOver (tournamentPlayers[0]._address, tournamentPlayers[3]._address, tournamentPlayers[0]._score, tournamentPlayers[3]._score, round2);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[0]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[0]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[3]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[3]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p2'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p1')))) {
        string memory round2 = playRound(tournamentPlayers[1], tournamentPlayers[2]);
        emit RoundOver (tournamentPlayers[1]._address, tournamentPlayers[2]._address, tournamentPlayers[1]._score, tournamentPlayers[2]._score, round2);
        if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p1')))) {
            tournamentPlayers[1]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[1]._address);
        } else if((keccak256(abi.encodePacked(round2))) == (keccak256(abi.encodePacked('p2')))) {
            tournamentPlayers[2]._address.transfer(0.004 ether);
            emit TournamentFinished(tournamentPlayers[2]._address);
        }
    } else if((keccak256(abi.encodePacked(round1a))) == (keccak256(abi.encodePacked('p2'))) && (keccak256(abi.encodePacked(round1b))) == (keccak256(abi.encodePacked('p2')))) {
        string memory round2 = playRound(tournamentPlayers[1], tournamentPlayers[3]);
        emit RoundOver (tournamentPlayers[1]._address, tournamentPlayers[3]._address, tournamentPlayers[1]._score, tournamentPlayers[3]._score, round2);
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