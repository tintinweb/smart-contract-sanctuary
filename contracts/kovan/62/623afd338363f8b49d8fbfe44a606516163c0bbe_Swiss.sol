/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;


contract Swiss {

    
    struct participantData {
        string username;
        address userAddress;
        // this mapping indicates the result of this participantDatas match in the corresponsing round
        // 1 => won, 2 => lost, 3 => bye
        // e.g. roundResult[1] == 2 => this participantData won his match in the 2nd round
        mapping(uint32 => uint32) roundResult;
    }

    struct tournamentData {
        address admin;
        
        string game;                    // game of the tournament, e.g. CS GO
        string name;                    // name of the tournament
        uint32 rounds;                  // amount of rounds to be played in this tournament
        uint32 maxPlayerCount;          // maximum amount of allowed players
        uint32 participantCount;       // number of players currently registered for this tournament
        uint32 currentRound;            // index of the round currently being played

        bool isRegistrationOpen;        // a bool indicating whether it is still possible to (de)register
        bool isOver;                    // if the tournament is over only reading its attributes is possible

        uint balance;                   // balance currently held by this tournament
        uint fee;                       // fee required to enter the tournament


        //----------------------------
        // mappings

        // contains the participants and their data
        mapping(uint32 => participantData) participantList;

        // contains the current standings, position => partipantList index
        // i.e. standings[0] == 4 => participantList[4] is currently first place
        mapping(uint32 => uint32) standings;

        // contains the pairings of each round
        // i.e. pairingsHistory[0] => the pairings of the first round
        // the pairings are using the indexes of participantList 
        // i.e. pairingsHistory[0][2] == 4 => in the first round participantList[2] played participantList[4]
        mapping(uint32 => mapping(uint32 => uint32)) pairingsHistory;

        // keeping track of the participants that already got a bye
        mapping(uint32 => bool) alreadySkippedOnce;
    }

    // variable used for randomness
    uint randNonce;

    // a mapping containing the registered tournaments
    // tournaments are never removed
    mapping(uint => tournamentData) public tournaments;
    
    uint32 tournamentCount;
    
    constructor() {}

    // TODO: require statements, i.e. min 2 players, < players - 1 rounds etc.
    function initTournament(uint enterFee, uint32 maxPlayers, string memory game, string memory name,
        uint32 _rounds) external returns(uint32) {

            require(_rounds < maxPlayers-1,"if you want to play this many rounds play Group instead");
        
            tournamentData storage newTournament = tournaments[tournamentCount];
            tournamentCount++;
            
            newTournament.isOver = false;
            newTournament.isRegistrationOpen = true;
            
            newTournament.participantCount = 0;
            
            newTournament.admin = msg.sender;
            newTournament.maxPlayerCount = maxPlayers;
            newTournament.fee = enterFee * (1 ether);
            newTournament.name = name;
            newTournament.game = game;
            
            newTournament.currentRound = 0;
            newTournament.rounds = _rounds;

            return tournamentCount-1;
    }

    // Adds msg.sender at the end of participantsList
    function addParticipant(string memory username, uint32 tournamentId) payable external 
        tournamentExists(tournamentId) ongoing(tournamentId) registrationOpen(tournamentId) {
        
        (bool isParticipant,) = isParticipant_positionInList(msg.sender, tournamentId);
        require(!isParticipant, "you are already participating");

        tournamentData storage currentTournament = tournaments[tournamentId];
        require(msg.value >= currentTournament.fee, "you need to pay the fee");

        uint32 participantPosition = currentTournament.participantCount;
        currentTournament.participantList[participantPosition].username = username;
        currentTournament.participantList[participantPosition].userAddress = msg.sender;
        currentTournament.balance += msg.value;
        currentTournament.participantCount++;
    }

    function removeParticipant(uint32 tournamentId) external
        tournamentExists(tournamentId) ongoing(tournamentId) registrationOpen(tournamentId) {

        (bool isParticipant, uint32 position) = isParticipant_positionInList(msg.sender, tournamentId);
        require(isParticipant, "you are not a participant");

        tournamentData storage currentTournament = tournaments[tournamentId];
        // overwriting the sender with the last person in standings to delete them
        currentTournament.standings[position] = 
        currentTournament.standings[currentTournament.participantCount];

        currentTournament.participantCount--;

        // returning fee
        (bool sent,) = msg.sender.call{ value: currentTournament.fee }("");
        require(sent, "failed to payback after cancelRegistrationSelf");
        currentTournament.balance -= currentTournament.fee;
    }

    // TODO: require statements/modifiers
    function closeRegistration(uint32 tournamentId) external 
        tournamentExists(tournamentId) adminOnly(tournamentId) ongoing(tournamentId) registrationOpen(tournamentId){
        
        tournamentData storage currentTournament = tournaments[tournamentId];

        require(currentTournament.rounds < currentTournament.participantCount, 
            "not enough participants for this type of tournament");
        currentTournament.isRegistrationOpen = false;
        for(uint32 i; i < currentTournament.participantCount; i++) {
            currentTournament.standings[i] = i;
        }
        calculatePairings(tournamentId);
    }

    function cancelTournament(uint32 tournamentId) external
        tournamentExists(tournamentId) adminOnly(tournamentId) ongoing(tournamentId) registrationOpen(tournamentId) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        // returning the fee to those registered
        for(uint32 i; i < currentTournament.participantCount; i++) {
            (bool sent,) = currentTournament.participantList[i].userAddress.call{ value: currentTournament.fee }("");
            require(sent, "something went wrong returning the fee to a user");
        }
        currentTournament.isOver = true;
    }

    function sponsorTournament(uint32 tournamentId) external payable
        tournamentExists(tournamentId) registrationOpen(tournamentId) ongoing(tournamentId) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        currentTournament.balance += msg.value;
    }

    function calculatePairings(uint32 tournamentId) internal{
        
        tournamentData storage currentTournament = tournaments[tournamentId];
        uint32 thisRound = currentTournament.currentRound;
        // initialized as something never reached normally so checks for it fail properly
        uint32 currentBye = currentTournament.participantCount;
        // this is needed as checking for != 0 indicates the participant already has an enemy,
        // however this would not work for the enemy of participant 0, this variable fixes this
        uint32 pairingOfZero = currentTournament.participantCount;

        // if the number of participants is uneven someone random gets a bye
        // the matchhistory indicates this with a 3
        if(currentTournament.participantCount % 2 != 0) {
            currentBye = calculateCurrentBye(tournamentId);
            currentTournament.pairingsHistory[thisRound][currentBye] = 
                currentTournament.participantCount;
            currentTournament.participantList[currentBye].roundResult[thisRound] = 3;
        }
        for(uint32 i; i < currentTournament.participantCount; i++) {
            uint32 participant = currentTournament.standings[i];

            // skip this participant if he already has an enemy assigneds
            if(participant == currentBye) continue;
            if((currentTournament.pairingsHistory[thisRound][participant] != 0)
                || (participant == pairingOfZero)) continue;

            for(uint32 j = i + 1; j < currentTournament.participantCount; j++) {
                uint32 enemy = currentTournament.standings[j];

                // skip the enemy if he was already played
                bool haveWePlayedAlready;
                for(uint32 round; round < thisRound; round++) {
                    if(currentTournament.pairingsHistory[round][participant] == enemy) {
                        haveWePlayedAlready = true;
                        break;
                    }
                }
                if(haveWePlayedAlready) continue;
                // skip the enemy if he already has an enemy assigned himself
                if(currentTournament.pairingsHistory[thisRound][enemy] != 0
                    || enemy == pairingOfZero) continue;

                if(participant == 0) {
                    pairingOfZero = enemy;
                }
                currentTournament.pairingsHistory[thisRound][participant] = enemy;
                currentTournament.pairingsHistory[thisRound][enemy] = participant;
                break;
            }
        }
    }

    // require statements/modifiers
    function declareWinner(uint32 participant, uint32 tournamentId) external 
        tournamentExists(tournamentId) ongoing(tournamentId) adminOnly(tournamentId) {

        tournamentData storage currentTournament = tournaments[tournamentId];

        require(!currentTournament.isRegistrationOpen, "Tournament is still in registration phase");

        (bool isParticipant, uint32 winnerPositionInStandings) = 
            isParticipant_positionInStandings(currentTournament.participantList[participant].userAddress, tournamentId);
        require(isParticipant,"the supposed winner is not a participant in this tournament");

        uint32 thisRound = currentTournament.currentRound;
        // preventing submitting a match result twice
        require(currentTournament.participantList[participant].roundResult[thisRound] == 0, 
            "the result of this match has already been submitted");

        //  saving the match result
        currentTournament.participantList[participant].roundResult[thisRound] = 1;
        currentTournament.participantList[currentTournament.pairingsHistory[thisRound][participant]].roundResult[thisRound] = 2;

        // updating standings by swapping participant with the person above if participant has at least as many wins
        // swapping only possible if participant is not already first place
        // swapping until the person above participant does not have more wins anymore
        if(winnerPositionInStandings == 0) {} else {
            uint32 wincount_above;
            uint32 wincount_self;
            do {
                wincount_above = 0;
                wincount_self = 0;
                for(uint32 i; i <= currentTournament.currentRound; i++) {
                    // counting the wins of participant
                    if(currentTournament.participantList[currentTournament.standings[winnerPositionInStandings]].roundResult[i] == 1) {
                        wincount_self++;
                    }
                    // counting the wins of the person above participant in standings
                    if(currentTournament.participantList[currentTournament.standings[winnerPositionInStandings-1]].roundResult[i] == 1) {
                        wincount_above++;
                    }
                }
                // the swapping
                if(wincount_self >= wincount_above) {
                    uint32 temp = currentTournament.standings[winnerPositionInStandings];
                    currentTournament.standings[winnerPositionInStandings] = 
                        currentTournament.standings[winnerPositionInStandings-1];
                    currentTournament.standings[winnerPositionInStandings-1] = temp;

                }
                // preventing underflow
                if(winnerPositionInStandings == 1) {
                    break;
                }
                // decreasing the winnerPositionInStandings as the winner has been swapped
                winnerPositionInStandings--;
            } while(wincount_self >= wincount_above);

        }

        bool roundOver = true;
        for(uint32 i; i < currentTournament.participantCount; i++) {
            // 0 indicates the match still has to be played as the value is initialized as 0
            // but with win/lose/bye it is set to 1/2/3
            if(currentTournament.participantList[i].roundResult[thisRound] == 0) {
                roundOver = false;
            }
        }

        if(roundOver) {
            currentTournament.currentRound++;
            bool tempTournamentOver;
            if(currentTournament.currentRound == currentTournament.rounds) {
                tempTournamentOver = true;
            }
            if(!tempTournamentOver) {
                calculatePairings(tournamentId);
            } else {
                // sending the winner all the prize money
                (bool sent,) = 
                    currentTournament.participantList[currentTournament.standings[0]].userAddress.call{ value: currentTournament.balance }("");
                require(sent,"error while sending the prize");
                currentTournament.isOver = true;
            }
        }

    }







    //----------------------------------------------------------------------------------------------
    // utility functions

    // very basic function used for randomness
    function randMod(uint32 _modulo) internal returns(uint32) {
        randNonce++;
        return uint32(uint(keccak256(abi.encodePacked(block.timestamp, randNonce))) % _modulo);

    }

    // calculating the bye for the current round, no one gets it twice
    function calculateCurrentBye(uint32 tournamentId) internal returns(uint32) {
        tournamentData storage currentTournament = tournaments[tournamentId];
        bool searchingTheBye = true;
        // using a temporary uint in memory so it doesnt write to storage multiple times
        uint32 tempBye;
        while(searchingTheBye) {
            tempBye = randMod(currentTournament.participantCount);
            if(!currentTournament.alreadySkippedOnce[tempBye]) {
                currentTournament.alreadySkippedOnce[tempBye] = true;
                searchingTheBye = false;
            }
        }
        return tempBye;
    }

    function isParticipant_positionInList(address _address, uint32 tournamentId) internal view returns(bool, uint32) {
        tournamentData storage currentTournament = tournaments[tournamentId];
        for(uint32 i; i < currentTournament.participantCount; i++) {
            if(currentTournament.participantList[i].userAddress == _address) {
                return (true, i);
            }
        }
        return (false, currentTournament.participantCount);
    }

    function isParticipant_positionInStandings(address _address, uint32 tournamentId) internal view returns(bool, uint32) {
        tournamentData storage currentTournament = tournaments[tournamentId];
        for(uint32 i; i < currentTournament.participantCount; i++) {
            if(currentTournament.participantList[currentTournament.standings[i]].userAddress == _address) {
                return (true, i);
            }
        }        
        return (false, currentTournament.participantCount);
    }


    // -------------------------------------------------------------------------
    // getters

    function getStandings(uint32 tournamentId) external view tournamentExists(tournamentId)
        returns(uint32[] memory) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        uint32[] memory tempStandings = new uint32[](currentTournament.participantCount);
        for(uint32 i; i < currentTournament.participantCount; i++) {
            tempStandings[i] = currentTournament.standings[i];
        }
        return tempStandings;
    }

    function getParticipantAddresses(uint32 tournamentId) external view tournamentExists(tournamentId)
        returns(address[] memory) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        address[] memory participantAddresses = new address[](currentTournament.participantCount);
        for(uint32 i; i < currentTournament.participantCount; i++) {
            participantAddresses[i] = currentTournament.participantList[i].userAddress; 
        }
        return participantAddresses;
    }

    function getPairings(uint32 round,uint32 tournamentId) external view tournamentExists(tournamentId)
        returns(uint32[] memory) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        uint32[] memory tempPairings = new uint32[](currentTournament.participantCount);
        for(uint32 i; i < currentTournament.participantCount; i++) {
            tempPairings[i] = currentTournament.pairingsHistory[round][i];
        }
        return tempPairings;
    }

    function getMatchResult(uint32 round, uint32 participant, uint32 tournamentId) external view tournamentExists(tournamentId)
        returns(uint32) {

        tournamentData storage currentTournament = tournaments[tournamentId];
        return currentTournament.participantList[participant].roundResult[round];
    }



    // -------------------------------------------------------------------------
    // modifiers

    modifier tournamentExists(uint32 tournamentId) {
        require(tournamentId < tournamentCount, "this tournament does not exist");
        _;
    }

    modifier ongoing(uint32 tournamentId) {
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(!currentTournament.isOver, "this tournament is already over");
        _;
    }

    modifier registrationOpen(uint32 tournamentId) {
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(currentTournament.isRegistrationOpen, "the registration is not open anymore");
        _;
    }

    modifier adminOnly(uint32 tournamentId){
        tournamentData storage currentTournament = tournaments[tournamentId];
        require(msg.sender == currentTournament.admin, "you are not the admin");
        _;
    }

}