/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Group {
    
    uint32 public tournamentCount;
    mapping(uint => tournamentData) public tournaments;

    struct pairingData{
        uint32 opponent;
        uint32 status;                                    //3 no game this round, 2 lost, 1 won, 0 undecided
    }
    
    struct participantData{                             //struct holding all the data of a participant
        address account;
        string username;
        uint32 wins;
    }

    struct tournamentData{
        //--------------------------------------
        //tournament status
        uint price;                                         //curent sum of fees/entrys
        bool over;                                          //tournament is over, there is a winner
        bool open;                                          //tournament is open for registration
        //--------------------------------------
        //participant data
        mapping(address => uint256) entry;                  //how much did this adress enter into the price pool
        mapping(address => bool) status;                    //is this adress registered
        uint32 participantsCount;                             //how many participants, valid after !open, length of participants
        uint32 realParticipantsCount;                         //how many participants, allways valid
        mapping(uint32 => participantData) participants;      //"array" of participants adresses + id for tournament management
        //--------------------------------------
        //tournament data constants
        address admin;
        uint32 maxPlayerCount;
        string name;
        uint minFee;
        string game;                                        //game of tournament
        //--------------------------------------
        //tournament management data
        uint32 round;                                         //current round, first game is in round 1
        mapping(uint32 => pairingData) pairings;              //whats the current opponent of id, pairings[x] == y && pairings[y] == x
        uint32 openPairings;                                  //open pairings in the current round 
    }
    
    constructor() {
    }

    
    //-------------------------------------
    //functions mutating the contract state
    
    function initTournament(uint enterFee, uint32 maxPlayers, string memory game, string memory name) external returns(uint32){
        require(maxPlayers > 1,"Atleast two partys are needed");
        
        uint32 tournamentId = tournamentCount++;
        tournamentData storage newTournament = tournaments[tournamentId];
        
        newTournament.over = false;
        newTournament.open = true;
        
        newTournament.maxPlayerCount = maxPlayers;
        newTournament.name = name;
        newTournament.game = game;
        newTournament.admin = msg.sender;
        newTournament.minFee = enterFee;
        
        newTournament.round = 1;
        
        return tournamentId;
    }

    function addParticipant(string memory username, uint tournamentId) payable external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        
        require(!currentTournament.status[msg.sender],"You are already participating" );
        require(msg.value >= currentTournament.minFee, "You need to pay to join");
        require(currentTournament.maxPlayerCount > currentTournament.realParticipantsCount,"The are no tournament slots left");
        require(currentTournament.open && !currentTournament.over, "not in registration");
        
        //check if reregistering or new
        bool needsParticipants = true;
        for(uint32 i; i < currentTournament.participantsCount; i++){
            if(currentTournament.participants[i].account == msg.sender){
                needsParticipants = false;
                break;
            }
        }
        if(needsParticipants){
            currentTournament.participants[currentTournament.participantsCount] = participantData(msg.sender, username, 0);
            currentTournament.participantsCount++;
        }
        //register
        currentTournament.realParticipantsCount++;
        currentTournament.entry[msg.sender] = msg.value;
        currentTournament.status[msg.sender] = true;
        currentTournament.price += msg.value;
    }
    
    function removeParticipant(uint tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        
        require(currentTournament.status[msg.sender],"You are not participating");
        require(currentTournament.open && !currentTournament.over, "not in registration");
        
        //unregister
        currentTournament.status[msg.sender]=false;
        currentTournament.realParticipantsCount--;
        //send back entry
        payable(msg.sender).call{value: currentTournament.entry[msg.sender]}("");
        currentTournament.price -= currentTournament.entry[msg.sender];
    }
    
    function closeRegistration(uint tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        
        require(currentTournament.admin == msg.sender, "You need to be admin to call that");
        require(currentTournament.open && !currentTournament.over, "not in registration");
        
        currentTournament.open = false;
        uint32 j;
        for(uint32 i; i < currentTournament.participantsCount; i++){
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
        uint randNonce;
        for(uint32 i; i < currentTournament.realParticipantsCount; i++){
			randNonce++;
			uint randomNumber = (uint(keccak256(abi.encodePacked(block.timestamp, randNonce))) % (currentTournament.realParticipantsCount-i)) + 1;

			for(uint32 j; j < currentTournament.realParticipantsCount; j++){
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
        for(uint32 a; a < currentTournament.realParticipantsCount; a++){
            currentTournament.participants[a] = randomParticipants[a];
        }
        
        //init first round
        currentTournament.openPairings = currentTournament.participantsCount/2;
        uint32 length = currentTournament.participantsCount + (currentTournament.participantsCount % 2);
        for(uint32 i; i < currentTournament.participantsCount; i++){
            
            uint32 circledIndex = 0;
            if(i != 0){
                circledIndex = (i - 1) % (length - 1) + 1;
            }
            uint32 oponentIndex = length - circledIndex - 1;
            if(oponentIndex == 0){
                currentTournament.pairings[i] = pairingData(0, 0);
            }else{
                currentTournament.pairings[i] = pairingData((oponentIndex + length - 2) % (length - 1) + 1, 0);
                if(currentTournament.pairings[i].opponent == currentTournament.participantsCount){
		            currentTournament.pairings[i].status = 3;
		        }
            }
        }
    }
    
    function declareWinner(uint32 participant, uint32 tournamentId) external {
        tournamentData storage currentTournament = tournaments[tournamentId];
        
        require(currentTournament.admin == msg.sender, "You need to be admin to call that");
        require(!currentTournament.open && !currentTournament.over);
        
        uint32 pairingOffset = (currentTournament.round-1) * currentTournament.participantsCount;
        require(currentTournament.pairings[pairingOffset + participant].status == uint32(0), "Game decided allready");
        
        currentTournament.participants[participant].wins++;
        currentTournament.pairings[pairingOffset + participant].status = uint32(1);
        currentTournament.pairings[pairingOffset + currentTournament.pairings[pairingOffset + participant].opponent].status = 2;
        currentTournament.openPairings--;
        
        //round over, init new one
        if(currentTournament.openPairings == 0){
            currentTournament.openPairings = currentTournament.participantsCount/2;
            currentTournament.round++;
            uint32 length = currentTournament.participantsCount + (currentTournament.participantsCount % 2);
            //games this round
            if(currentTournament.round == length){
                uint32 winnersCount;
                uint32 max;
                uint32 currentWinner;
                for(uint32 i; i < currentTournament.participantsCount;i++){
                    if(currentTournament.participants[i].wins > max){
                        max = currentTournament.participants[i].wins;
                        currentWinner = i;
                        winnersCount = 1;
                    }
                    if(currentTournament.participants[i].wins == max){
                        winnersCount++;
                    }
                }
                if(winnersCount == 1){
                    payable(currentTournament.participants[currentWinner].account).call{value: currentTournament.price}("");
                }
                else{
                    for(uint32 i; i < currentTournament.participantsCount;i++){
                        if(currentTournament.participants[i].wins == max){
                            payable(currentTournament.participants[i].account).call{value: (currentTournament.price/winnersCount)}("");
                        }
                    }
                }
                currentTournament.over = true;
                return;   
            }
            //new pairings
            pairingOffset += currentTournament.participantsCount;
            for(uint32 i; i < currentTournament.participantsCount; i++){
                uint32 circledIndex = 0;
                if(i != 0){
                    circledIndex = (i + currentTournament.round - 2) % (length - 1) + 1;
                }
                uint32 oponentIndex = length - circledIndex - 1;
                if(oponentIndex == 0){
                    currentTournament.pairings[pairingOffset + i] = pairingData(0, 0);
                }else{
                    currentTournament.pairings[pairingOffset + i] = pairingData((oponentIndex + length - 1 - currentTournament.round) % (length - 1) + 1, 0);
                    if(currentTournament.pairings[pairingOffset + i].opponent == currentTournament.participantsCount){
		                currentTournament.pairings[pairingOffset + i].status = 3;
		            }
                }
            }   
        }
    }
    
    /*function whoWon(uint player1, uint player2) public view returns (uint){
        require(winRecord[player1][player2]||winRecord[player2][player1],"The Match wasnt played yet");
        return (winRecord[player1][player2]?player1:player2);
    }*/
    
    //-------------------------------------
    //getter functions for web3 VM
    
    function getParticipant(uint32 id, uint32 tournamentId) public view returns (address, string memory, uint32){
        return (tournaments[tournamentId].participants[id].account, tournaments[tournamentId].participants[id].username, tournaments[tournamentId].participants[id].wins);
    }
    
    function getPairing(uint32 id, uint32 tournamentId, uint32 round) public view returns (uint32, uint32){
        return (tournaments[tournamentId].pairings[id + round * tournaments[tournamentId].realParticipantsCount].opponent, tournaments[tournamentId].pairings[id + round * tournaments[tournamentId].realParticipantsCount].status);
    }
    
    function getEntry(address account, uint32 tournamentId) public view returns (uint){
        return tournaments[tournamentId].entry[account];
    }
    
    function getStatus(address account, uint32 tournamentId) public view returns (bool){
        return tournaments[tournamentId].status[account];
    }
}