/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


contract Storage {
    
    uint public tournamentCount = 0;
    mapping(uint => tournamentData) public tournaments;
    
    struct participantData{                             //struct holding all the data of a participant
        address account;
        bool out;
    }
    
    struct winnerData{                                  //struct holding all the data of a participant
        uint id;
        bool updated;
    }
    
    struct tournamentData{
        //--------------------------------------
        //participant data
        uint evenCount;        
        uint participantCount;
        mapping(uint => participantData) participants;  //"array" of participants adresses + id for tournament management
        //--------------------------------------
        //tournament data constants
        uint256 price;                                  
        address admin;                                  //is this adress registered
        //--------------------------------------
        //tournament management data
        uint round;                                     //current round, first game is in round 1
        mapping(uint => uint) pairings;                 //whats the current opponent of id, pairings[x] == y && pairings[y] == x
        uint openPairings;                              //open pairings in the current round 
        mapping(uint => winnerData) winners;            //for managing the persisting participants
    }
    
    constructor() {
    }
    
    //-------------------------------------
    //functions mutating the contract state
    
    function initTournament(address[] memory cachedParticipants) external payable returns (uint){
        uint tournamentId = tournamentCount++;
        tournamentData storage newTournament = tournaments[tournamentId];
        newTournament.evenCount = 1;
        newTournament.price = msg.value;
        newTournament.admin = msg.sender;
        newTournament.round = 1;
        newTournament.participantCount = cachedParticipants.length;
        
        for(uint i = 0; i < cachedParticipants.length; i++){
            newTournament.participants[i] = participantData(cachedParticipants[i], false);
        }
        
        //calc "odd" games
        //next bigger power of 2
        for(; newTournament.evenCount < newTournament.participantCount; newTournament.evenCount = newTournament.evenCount * 2){}
        uint byes = newTournament.evenCount - newTournament.participantCount;
        //init "odd" 1st round, fill games from start e.g.: participats 01234; 0-1, 2, 3, 4 | participats 0123456; 0-1, 2-3, 4-5, 6
        newTournament.openPairings = (newTournament.evenCount / 2) - byes;
        
        //construct pairings
        uint nextI;
        for(uint i = 0; i < newTournament.participantCount - byes; i++){
            if(i % 2 == 0){
                nextI = i + 1;
            }else{
                nextI = i - 1;
            }
            newTournament.pairings[i] = nextI;
        }
        
        //enter byes as winners
        uint games = (newTournament.participantCount - byes)/2;//games played in round 1
        for(uint i = newTournament.participantCount - byes; i < newTournament.participantCount; i++){
            newTournament.winners[i - games] = winnerData(i, true);
        }
        
        //push tournament and return index
        return tournamentId;
    }
    
    function declareWinner(uint participant, uint tournamentId) external {
        require(msg.sender == tournaments[tournamentId].admin, "you need to be admin");
        require(!tournaments[tournamentId].participants[participant].out, "the participant is allready out");
        
        uint winnerId = (participant/(2**tournaments[tournamentId].round));
        
        require(!tournaments[tournamentId].winners[winnerId].updated, "a winner is allready declared");
        
        tournaments[tournamentId].participants[tournaments[tournamentId].pairings[participant]].out = true;
        tournaments[tournamentId].openPairings--;
        tournaments[tournamentId].winners[winnerId] = winnerData(participant, true);
        //round over, init new one
        if(tournaments[tournamentId].openPairings == 0){
            tournaments[tournamentId].round++;
            //games this round
            tournaments[tournamentId].openPairings = tournaments[tournamentId].evenCount / (2**tournaments[tournamentId].round);
            //if no games, its over
            if(tournaments[tournamentId].openPairings == 0){
                payable(tournaments[tournamentId].participants[tournaments[tournamentId].winners[0].id].account).call{value: tournaments[tournamentId].price}("");
                return;   
            }
            //new pairings
            for(uint i = 0; i < tournaments[tournamentId].openPairings * 2; i++){
                uint nextI;
                if(i%2 == 0){
                    nextI = i + 1;
                }else{
                    nextI = i - 1;
                }
                tournaments[tournamentId].pairings[tournaments[tournamentId].winners[i].id] = tournaments[tournamentId].winners[nextI].id;
                tournaments[tournamentId].winners[i].updated = false;
            }
        }
    }

    //-------------------------------------
    //getter functions for web3 VM
    
    function getParticipant(uint id, uint tournamentId) public view returns (address, bool){
        return (tournaments[tournamentId].participants[id].account, tournaments[tournamentId].participants[id].out);
    }
    
    function getWinner(uint id, uint tournamentId) public view returns (uint, bool){
        return (tournaments[tournamentId].winners[id].id, tournaments[tournamentId].winners[id].updated);
    }
    
    function getPairing(uint id, uint tournamentId) public view returns (uint){
        return tournaments[tournamentId].pairings[id];
    }
}