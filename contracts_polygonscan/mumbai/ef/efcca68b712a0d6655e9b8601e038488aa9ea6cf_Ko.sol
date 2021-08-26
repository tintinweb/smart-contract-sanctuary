/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Ko {
    
    uint32 public tournamentCount = 0;
    mapping(uint => tournamentData) public tournaments;
    
    struct winnerData{                                  //struct holding all the data of a participant
        uint32 id;
        bool updated;
    }
    
    struct participantData{                             //struct holding all the data of a participant
        address account;
        string username;
        bool out;
    }
    
    struct tournamentData{
        //--------------------------------------
        //tournament status
        uint price;                                      //curent sum of fees/entrys
        bool over;                                      //tournament is over, there is a winner
        bool open;                                      //tournament is open for registration
        //--------------------------------------
        //participant data
        mapping(address => uint256) entry;              //how much did this adress enter into the price pool
        mapping(address => bool) status;                //is this adress registered
        uint32 evenCount;                                 //next bigger number of 2, layout of tree
        uint32 participantsCount;                         //how many participants, valid after !open, length of participants
        uint32 realParticipantsCount;                     //how many participants, allways valid
        mapping(uint32 => participantData) participants;  //"array" of participants adresses + id for tournament management
        //--------------------------------------
        //tournament data constants
        address admin;                                  //is this adress registered
        uint32 maxPlayerCount;                            //slots
        uint minFee;                                    //fee per participant
        string name;                                    //tournament name
        string game;
        //game of tournament
        //--------------------------------------
        //tournament management data
        uint32 round;                                     //current round, first game is in round 1
        mapping(uint32 => uint32) pairings;                 //whats the current opponent of id, pairings[x] == y && pairings[y] == x
        uint32 openPairings;                              //open pairings in the current round 
        mapping(uint32 => winnerData) winners;            //for managing the persisting participants
        uint32 winnersOffset;
    }
    
    constructor() {
    }
    
    //-------------------------------------
    //functions mutating the contract state
    
    function initTournament(uint enterFee, uint32 maxPlayers, string memory game, string memory name) external returns(uint32){
        require(maxPlayers>1,"Atleast two partys are needed");
        //setup constants and inits
        uint32 tournamentId = tournamentCount++;
        tournamentData storage newTournament = tournaments[tournamentId];
        
        newTournament.price = 0;
        newTournament.over = false;
        newTournament.open = true;
        
        newTournament.evenCount = 1;
        newTournament.participantsCount = 0;
        newTournament.realParticipantsCount = 0;
        
        newTournament.admin = msg.sender;
        newTournament.maxPlayerCount = maxPlayers;
        newTournament.minFee = enterFee;
        newTournament.name = name;
        newTournament.game = game;
        
        newTournament.round = 1;
        newTournament.winnersOffset = 0;
        
        return tournamentId;
    }

    function addParticipant(string memory username, uint tournamentId) payable external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(currentTournament.open && !currentTournament.over, "tournament not in registration");
        require(!currentTournament.status[msg.sender],"You are allready participating");
        require(msg.value >= currentTournament.minFee, "You need to pay to join");
        require(currentTournament.maxPlayerCount > currentTournament.realParticipantsCount,"The are no tournament slots left");
        
        //check if reregistering or new
        bool needsParticipants = true;
        for(uint32 i = 0; i < currentTournament.participantsCount; i++){
            if(currentTournament.participants[i].account == msg.sender){
                needsParticipants = false;
                break;
            }
        }
        if(needsParticipants){
            currentTournament.participants[currentTournament.participantsCount] = participantData(msg.sender, username, false);
            currentTournament.participantsCount++;
        }
        //register
        currentTournament.entry[msg.sender] = msg.value;
        currentTournament.price += msg.value;
        currentTournament.status[msg.sender]=true;
        currentTournament.realParticipantsCount++;
    }
    
    function removeParticipant(uint tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(currentTournament.open && !currentTournament.over, "tournament not in registration");
        require(currentTournament.status[msg.sender], "You are not participating" );
        
        //unregister
        currentTournament.status[msg.sender]=false;
        currentTournament.realParticipantsCount--;
        //send back entry
        payable(msg.sender).call{value: currentTournament.entry[msg.sender]}("");
        currentTournament.price -= currentTournament.entry[msg.sender];
    }
    
    function closeRegistration(uint tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(currentTournament.open && !currentTournament.over, "tournament not in registration");
        require(currentTournament.admin == msg.sender, "You need to be admin to call that");
        
        currentTournament.open = false;
        //"delete" unregisted participants
        uint32 j = 0;//remaining participants
        for(uint32 i = 0; i < currentTournament.participantsCount; i++){
            if(currentTournament.status[currentTournament.participants[i].account]){
                currentTournament.participants[j] = currentTournament.participants[i];
                j++;
            }
        }
        currentTournament.participantsCount = j;
        
        //shuffleParticipants
        bool[] memory isInUse = new bool[](currentTournament.realParticipantsCount);
        //mapping(uint => participantData) storage randomParticipants;
        participantData[] memory randomParticipants = new participantData[](currentTournament.realParticipantsCount);
        uint randNonce = 0;
        for(uint32 i = 0; i < currentTournament.realParticipantsCount; i++){
			randNonce++;
			uint randomNumber = (uint(keccak256(abi.encodePacked(block.timestamp, randNonce))) % (currentTournament.realParticipantsCount-i)) + 1;

			for(uint32 j = 0; j < currentTournament.realParticipantsCount; j++){
				if(!isInUse[j]){
					randomNumber--;
				}
				
				if(randomNumber == 0){
					isInUse[j] = true;
					randomParticipants[i] = currentTournament.participants[j];
					break;
				}
			}
        }
        for(uint32 a = 0; a < currentTournament.realParticipantsCount; a++){
            currentTournament.participants[a] = randomParticipants[a];
        }
        
        //calc "odd" games
        //next bigger power of 2
        for(; currentTournament.evenCount < currentTournament.participantsCount; currentTournament.evenCount = currentTournament.evenCount * 2){}
        uint32 byes = currentTournament.evenCount - currentTournament.participantsCount;
        //init "odd" 1st round, fill games from start e.g.: participats 01234; 0-1, 2, 3, 4 | participats 0123456; 0-1, 2-3, 4-5, 6
        currentTournament.openPairings = (currentTournament.evenCount / 2) - byes;
        //construct pairings
        for(uint32 i = 0; i < currentTournament.participantsCount-byes; i++){
            uint32 nextI;
            if(i % 2 == 0){
                nextI = i + 1;
            }else{
                nextI = i - 1;
            }
            currentTournament.pairings[i] = nextI;
        }
        //enter byes as winners
        uint32 games = (currentTournament.participantsCount - byes)/2;//games played in round 1
        for(uint32 i = currentTournament.participantsCount - byes; i < currentTournament.participantsCount; i++){
            currentTournament.winners[i - games] = winnerData(i, true);
        }
    }
    
    function declareWinner(uint32 participant, uint32 tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        
        require(currentTournament.admin == msg.sender, "You need to be admin to call that");
        require(!currentTournament.open && !currentTournament.over, "play did not start yet or is over");
        require(!currentTournament.participants[participant].out, "This participant is out");
        
        uint32 winnerId = (participant/(uint32(2)**currentTournament.round)) + currentTournament.winnersOffset;
        
        require(!currentTournament.winners[winnerId].updated, "This matchup was allready declared");
        
        currentTournament.participants[currentTournament.pairings[participant]].out = true;
        currentTournament.openPairings--;
        currentTournament.winners[winnerId] = winnerData(participant, true);
        //round over, init new one
        if(currentTournament.openPairings == 0){
            currentTournament.round++;
            //games this round
            currentTournament.openPairings = currentTournament.evenCount / (uint32(2)**currentTournament.round);
            //if no games, its over
            if(currentTournament.openPairings == 0){
                currentTournament.over = true;
                payable(currentTournament.participants[currentTournament.winners[currentTournament.winnersOffset].id].account).call{value: currentTournament.price}("");
                return;   
            }
            //new pairings
            for(uint32 i = currentTournament.winnersOffset; i < currentTournament.openPairings * 2 + currentTournament.winnersOffset; i++){
                uint32 nextI;
                if(i%2 == 0){
                    nextI = i + 1;
                }else{
                    nextI = i - 1;
                }
                currentTournament.pairings[currentTournament.winners[i].id] = currentTournament.winners[nextI].id;
            }
            currentTournament.winnersOffset += currentTournament.openPairings * 2;
        }
    }

    //-------------------------------------
    //getter functions for VM
    
    function getEntry(address account, uint32 tournamentId) public view returns (uint){
        return tournaments[tournamentId].entry[account];
    }
    
    function getStatus(address account, uint32 tournamentId) public view returns (bool){
        return tournaments[tournamentId].status[account];
    }
    
    function getParticipant(uint32 id, uint32 tournamentId) public view returns (address, string memory, bool){
        return (tournaments[tournamentId].participants[id].account, tournaments[tournamentId].participants[id].username, tournaments[tournamentId].participants[id].out);
    }
    
    function getWinner(uint32 id, uint32 tournamentId) public view returns (uint, bool){
        return (tournaments[tournamentId].winners[id].id, tournaments[tournamentId].winners[id].updated);
        //0 ~ evenCount/2 - 1 == round 1 --- evenCount/2 ~ evenCount/2 + evenCount/4 - 1 == round 2  --- evenCount/2 + evenCount/4 ~ evenCount/2 + evenCount/4  + evenCount/8 - 1 == round 3
    }
    
    function getPairing(uint32 id, uint32 tournamentId) public view returns (uint){
        return tournaments[tournamentId].pairings[id];
    }
}