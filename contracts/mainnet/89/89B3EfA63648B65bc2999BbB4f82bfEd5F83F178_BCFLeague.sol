contract BCFBaseCompetition {
    address public owner;
    address public referee;

    bool public paused = false;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setReferee(address newReferee) public onlyOwner {
        require(newReferee != address(0));
        referee = newReferee;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
    }
}

contract BCFMain {
    function isOwnerOfAllPlayerCards(uint256[], address) public pure returns (bool) {}
    function implementsERC721() public pure returns (bool) {}
    function getPlayerForCard(uint) 
        external
        pure
        returns (
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        bytes,
        string,
        uint8
    ) {}
}

// TODO: Validate that the user has sent the correct ENTRY_FEE and refund them if more, revert if less
// TODO: Validate formation type
// TODO: Validate that there&#39;s at least 1 goalkeeper?
// TODO: Validate the team name is under a certain number of characters?
// TODO: Do we need to copy these values across to the contract storage?
// TODO: Should the frontend do the sorting and league tables? We still need the business logic to determine final positions, 
//       but we don&#39;t need to calculate this every round, not doing so would reduce gas consumption
// TODO: Need to work out whether it&#39;s more gas effecient to read player info every round or store it once and have it?
contract BCFLeague is BCFBaseCompetition {
    
    struct Team {
        address manager;
        bytes name;
        uint[] cardIds;
        uint gkCardId;
        uint8 wins;
        uint8 losses;
        uint8 draws;
        uint16 goalsFor;
        uint16 goalsAgainst;
    }

    struct Match {
        uint8 homeTeamId;
        uint8 awayTeamId;
        uint[] homeScorerIds;
        uint[] awayScorerIds;
        bool isFinished;
    }

    // Configuration - this will be set in the constructor, hence not being constants
    uint public TEAMS_TOTAL;
    uint public ENTRY_FEE;
    uint public SQUAD_SIZE;
    uint public TOTAL_ROUNDS;
    uint public MATCHES_PER_ROUND;
    uint public SECONDS_BETWEEN_ROUNDS;

    // Status
    enum CompetitionStatuses { Upcoming, OpenForEntry, PendingStart, Started, Finished, Settled }
    CompetitionStatuses public competitionStatus;
    uint public startedAt;
    uint public nextRoundStartsAt;
    int public currentRoundId = -1; // As we may have a round 0 so we don&#39;t want to default there

    // Local Data Lookups
    Team[] public teams;
    mapping(address => uint) internal managerToTeamId;
    mapping(uint => bool) internal cardIdToEntryStatus;
    mapping(uint => Match[]) internal roundIdToMatches;

    // Data Source
    BCFMain public mainContract;

    // Prize Pool
    uint public constant PRIZE_POT_PERCENTAGE_MAX = 10000; // 10,000 = 100% so we get 2 digits of precision, 375 = 3.75%
    uint public prizePool; // Holds the total prize pool
    uint[] public prizeBreakdown; // Max 10,000 across all indexes. Holds breakdown by index, e.g. [0] 5000 = 50%, [1] 3500 = 35%, [2] 1500 = 15%
    address[] public winners; // Corresponding array of winners for the prize pot, [0] = first placed winner

    function BCFLeague(address dataStoreAddress, uint teamsTotal, uint entryFee, uint squadSize, uint roundTimeSecs) public {
        require(teamsTotal % 2 == 0); // We only allow an even number of teams, this reduces complexity
        require(teamsTotal > 0);
        require(roundTimeSecs > 30 seconds && roundTimeSecs < 60 minutes);
        require(entryFee >= 0);
        require(squadSize > 0);
        
        // Initial state
        owner = msg.sender;
        referee = msg.sender;
        
        // League configuration
        TEAMS_TOTAL = teamsTotal;
        ENTRY_FEE = entryFee;
        SQUAD_SIZE = squadSize;
        TOTAL_ROUNDS = TEAMS_TOTAL - 1;
        MATCHES_PER_ROUND = TEAMS_TOTAL / 2;
        SECONDS_BETWEEN_ROUNDS = roundTimeSecs;

        // Always start it as an upcoming league
        competitionStatus = CompetitionStatuses.Upcoming;

        // Set the data source
        BCFMain candidateDataStoreContract = BCFMain(dataStoreAddress);
        require(candidateDataStoreContract.implementsERC721());
        mainContract = candidateDataStoreContract;
    }

    // **Gas guzzler**
    // CURRENT GAS CONSUMPTION: 6339356
    function generateFixtures() external onlyOwner {
        require(competitionStatus == CompetitionStatuses.Upcoming);

        // Generate the fixtures using a cycling algorithm:
        for (uint round = 0; round < TOTAL_ROUNDS; round++) {
            for (uint matchIndex = 0; matchIndex < MATCHES_PER_ROUND; matchIndex++) {
                uint home = (round + matchIndex) % (TEAMS_TOTAL - 1);
                uint away = (TEAMS_TOTAL - 1 - matchIndex + round) % (TEAMS_TOTAL - 1);

                if (matchIndex == 0) {
                    away = TEAMS_TOTAL - 1;
                }

                 Match memory _match;
                 _match.homeTeamId = uint8(home);
                 _match.awayTeamId = uint8(away);

                roundIdToMatches[round].push(_match);
            }
        }
    }

    function createPrizePool(uint[] prizeStructure) external payable onlyOwner {
        require(competitionStatus == CompetitionStatuses.Upcoming);
        require(msg.value > 0 && msg.value <= 2 ether); // Set some sensible top and bottom values
        require(prizeStructure.length > 0); // Can&#39;t create a prize pool with no breakdown structure

        uint allocationTotal = 0;
        for (uint i = 0; i < prizeStructure.length; i++) {
            allocationTotal += prizeStructure[i];
        }

        require(allocationTotal > 0 && allocationTotal <= PRIZE_POT_PERCENTAGE_MAX); // Make sure we don&#39;t allocate more than 100% of the prize pool or 0%
        prizePool += msg.value;
        prizeBreakdown = prizeStructure;
    }

    function openCompetition() external onlyOwner whenNotPaused {
        competitionStatus = CompetitionStatuses.OpenForEntry;
    }

    function startCompetition() external onlyReferee whenNotPaused {
        require(competitionStatus == CompetitionStatuses.PendingStart);

        // Move the status into Started
        competitionStatus = CompetitionStatuses.Started;
        
        // Mark the startedAt to now
        startedAt = now;
        nextRoundStartsAt = now + 60 seconds;
    }

    function calculateMatchOutcomesForRoundId(int roundId) external onlyReferee whenNotPaused {
        require(competitionStatus == CompetitionStatuses.Started);
        require(nextRoundStartsAt > 0);
        require(roundId == currentRoundId + 1); // We&#39;re only allowed to process the next round, we can&#39;t skip ahead
        require(now > nextRoundStartsAt);

        // Increment the round counter
        // We complete the below first as during the calculateScorersForTeamIds we go off to another contract to fetch the 
        // current player attributes so to avoid re-entrancy we bump this first 
        currentRoundId++;

        // As the total rounds aren&#39;t index based we need to compare it to the index+1
        // this should never overrun as the gas cost of generating a league with more 20 teams makes this impossible
        if (TOTAL_ROUNDS == uint(currentRoundId + 1)) {
            competitionStatus = CompetitionStatuses.Finished;
        } else {
            nextRoundStartsAt = now + SECONDS_BETWEEN_ROUNDS;
        }

        // Actually calculate some of the outcomes 
        Match[] memory matches = roundIdToMatches[uint(roundId)];
        for (uint i = 0; i < matches.length; i++) {
            Match memory _match = matches[i];
            var (homeScorers, awayScorers) = calculateScorersForTeamIds(_match.homeTeamId, _match.awayTeamId);

            // Adjust the table values
            updateTeamsTableAttributes(_match.homeTeamId, homeScorers.length, _match.awayTeamId, awayScorers.length);

            // Save the goal scorers for this match and mark as finished
            roundIdToMatches[uint(roundId)][i].isFinished = true;
            roundIdToMatches[uint(roundId)][i].homeScorerIds = homeScorers;
            roundIdToMatches[uint(roundId)][i].awayScorerIds = awayScorers;
        }
    }

    function updateTeamsTableAttributes(uint homeTeamId, uint homeGoals, uint awayTeamId, uint awayGoals) internal {

        // GOALS FOR
        teams[homeTeamId].goalsFor += uint16(homeGoals);
        teams[awayTeamId].goalsFor += uint16(awayGoals);

        // GOALS AGAINST
        teams[homeTeamId].goalsAgainst += uint16(awayGoals);
        teams[awayTeamId].goalsAgainst += uint16(homeGoals);

        // WINS / LOSSES / DRAWS
        if (homeGoals == awayGoals) {            
            teams[homeTeamId].draws++;
            teams[awayTeamId].draws++;
        } else if (homeGoals > awayGoals) {
            teams[homeTeamId].wins++;
            teams[awayTeamId].losses++;
        } else {
            teams[awayTeamId].wins++;
            teams[homeTeamId].losses++;
        }
    }

    function getAllMatchesForRoundId(uint roundId) public view returns (uint[], uint[], bool[]) {
        Match[] memory matches = roundIdToMatches[roundId];
        
        uint[] memory _homeTeamIds = new uint[](matches.length);
        uint[] memory _awayTeamIds = new uint[](matches.length);
        bool[] memory matchStates = new bool[](matches.length);

        for (uint i = 0; i < matches.length; i++) {
            _homeTeamIds[i] = matches[i].homeTeamId;
            _awayTeamIds[i] = matches[i].awayTeamId;
            matchStates[i] = matches[i].isFinished;
        }

        return (_homeTeamIds, _awayTeamIds, matchStates);
    }

    function getMatchAtRoundIdAtIndex(uint roundId, uint index) public view returns (uint, uint, uint[], uint[], bool) {
        Match[] memory matches = roundIdToMatches[roundId];
        Match memory _match = matches[index];
        return (_match.homeTeamId, _match.awayTeamId, _match.homeScorerIds, _match.awayScorerIds, _match.isFinished);
    }

    function getPlayerCardIdsForTeam(uint teamId) public view returns (uint[]) {
        Team memory _team = teams[teamId];
        return _team.cardIds;
    }

    function enterLeague(uint[] cardIds, uint gkCardId, bytes teamName) public payable whenNotPaused {
        require(mainContract != address(0)); // Must have a valid data store to check card ownership
        require(competitionStatus == CompetitionStatuses.OpenForEntry); // Competition must be open for entry
        require(cardIds.length == SQUAD_SIZE); // Require a valid number of players
        require(teamName.length > 3 && teamName.length < 18); // Require a valid team name
        require(!hasEntered(msg.sender)); // Make sure the address hasn&#39;t already entered
        require(!hasPreviouslyEnteredCardIds(cardIds)); // Require that none of the players have previously entered, avoiding managers swapping players between accounts
        require(mainContract.isOwnerOfAllPlayerCards(cardIds, msg.sender)); // User must actually own these cards
        require(teams.length < TEAMS_TOTAL); // We shouldn&#39;t ever hit this as the state should be managed, but just as a fallback
        require(msg.value >= ENTRY_FEE); // User must have paid a valid entry fee

        // Create a team and hold the teamId
        Team memory _team;
        _team.name = teamName;
        _team.manager = msg.sender;
        _team.cardIds = cardIds;
        _team.gkCardId = gkCardId;
        uint teamId = teams.push(_team) - 1;

        // Keep track of who the manager is managing
        managerToTeamId[msg.sender] = teamId;

        // Track which team each card plays for
        for (uint i = 0; i < cardIds.length; i++) {
            cardIdToEntryStatus[cardIds[i]] = true;
        }

        // If we&#39;ve hit the team limit we can move the contract into the PendingStart status
        if (teams.length == TEAMS_TOTAL) {
            competitionStatus = CompetitionStatuses.PendingStart;
        }
    }

    function hasPreviouslyEnteredCardIds(uint[] cardIds) view internal returns (bool) {
        if (teams.length == 0) {
            return false;
        }

        // This should only ever be a maximum of 5 iterations or 11
        for (uint i = 0; i < cardIds.length; i++) {
            uint cardId = cardIds[i];
            bool hasEnteredCardPreviously = cardIdToEntryStatus[cardId];
            if (hasEnteredCardPreviously) {
                return true;
            }
        }

        return false;
    }

    function hasEntered(address manager) view internal returns (bool) {
        if (teams.length == 0) {
            return false;
        }

        // We have to lookup the team AND check the fields because of some of the workings of solidity
        // 1. We could have a team at index 0, so we CAN&#39;T just check the index is > 0
        // 2. Solidity intializes with an empty set of struct values, so we need to do equality on the manager field
        uint teamIndex = managerToTeamId[manager];
        Team memory team = teams[teamIndex];
        if (team.manager == manager) {
            return true;
        }

        return false;
    }

    function setMainContract(address _address) external onlyOwner {
        BCFMain candidateContract = BCFMain(_address);
        require(candidateContract.implementsERC721());
        mainContract = candidateContract;
    }

    // ** Match Simulator **
    function calculateScorersForTeamIds(uint homeTeamId, uint awayTeamId) internal view returns (uint[], uint[]) {
        
        var (homeTotals, homeCardsShootingAttributes) = calculateAttributeTotals(homeTeamId);
        var (awayTotals, awayCardsShootingAttributes) = calculateAttributeTotals(awayTeamId); 
        
        uint startSeed = now;
        var (homeGoals, awayGoals) = calculateGoalsFromAttributeTotals(homeTeamId, awayTeamId, homeTotals, awayTotals, startSeed);

        uint[] memory homeScorers = new uint[](homeGoals);
        uint[] memory awayScorers = new uint[](awayGoals);

        // Home Scorers
        for (uint i = 0; i < homeScorers.length; i++) {
            homeScorers[i] = determineGoalScoringCardIds(teams[homeTeamId].cardIds, homeCardsShootingAttributes, i);
        }

        // Away Scorers
        for (i = 0; i < awayScorers.length; i++) {
            awayScorers[i] = determineGoalScoringCardIds(teams[awayTeamId].cardIds, awayCardsShootingAttributes, i);
        }

        return (homeScorers, awayScorers);
    }

    function calculateGoalsFromAttributeTotals(uint homeTeamId, uint awayTeamId, uint[] homeTotals, uint[] awayTotals, uint startSeed) internal view returns (uint _homeGoals, uint _awayGoals) {

        uint[] memory atkAttributes = new uint[](3); // 0 = possession, 1 = chance, 2 = shooting
        uint[] memory defAttributes = new uint[](3); // 0 = regain posession, 1 = prevent chance, 3 = save shot

        uint attackingTeamId = 0;
        uint defendingTeamId = 0;
        uint outcome = 0;
        uint seed = startSeed * homeTotals[0] * awayTotals[0];

        for (uint i = 0; i < 45; i++) {
            
            attackingTeamId = determineAttackingOrDefendingOutcomeForAttributes(homeTeamId, awayTeamId, homeTotals[0], awayTotals[0], seed+now);
            seed++;

            if (attackingTeamId == homeTeamId) {
                defendingTeamId = awayTeamId;
                atkAttributes[0] = homeTotals[3]; // Passing
                atkAttributes[1] = homeTotals[4]; // Dribbling
                atkAttributes[2] = homeTotals[2]; // Shooting
                defAttributes[0] = awayTotals[1]; // Pace
                defAttributes[1] = awayTotals[6]; // Physical
                defAttributes[2] = awayTotals[5]; // Defending
            } else {
                defendingTeamId = homeTeamId;
                atkAttributes[0] = awayTotals[3]; // Passing
                atkAttributes[1] = awayTotals[4]; // Dribbling
                atkAttributes[2] = awayTotals[2]; // Shooting
                defAttributes[0] = homeTotals[1]; // Pace
                defAttributes[1] = homeTotals[6]; // Physical
                defAttributes[2] = homeTotals[5]; // Defending
            }

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[0], defAttributes[0], seed);
			if (outcome == defendingTeamId) {
                // Attack broken up
				continue;
			}
            seed++;

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[1], defAttributes[1], seed);
			if (outcome == defendingTeamId) {
                // Chance prevented
				continue;
			}
            seed++;

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[2], defAttributes[2], seed);
			if (outcome == defendingTeamId) {
                // Shot saved
				continue;
			}

            // GOAL - determine whether it was the home team who scored or the away team
            if (attackingTeamId == homeTeamId) {
                // Home goal
                _homeGoals += 1;
            } else {
                // Away goal
                _awayGoals += 1;
            }
        }
    }

    function calculateAttributeTotals(uint teamId) internal view returns (uint[], uint[]) {
        
        // NOTE: We store these in an array because of stack too deep errors from Solidity, 
        // We could seperate these out but in the end it will end up being uniweildly
        // this is the case in subsquent arrays too, while not perfect does give us a bit more flexibility
        uint[] memory totals = new uint[](7);
        uint[] memory cardsShootingAttributes = new uint[](SQUAD_SIZE);
        Team memory _team = teams[teamId];
        
        for (uint i = 0; i < SQUAD_SIZE; i++) {
            var (overall,pace,shooting,passing,dribbling,defending,physical,,,,) = mainContract.getPlayerForCard(_team.cardIds[i]);

            // If it&#39;s a goalie we forego attack for increased shot stopping avbility
            if (_team.cardIds[i] == _team.gkCardId && _team.gkCardId > 0) {
                totals[5] += (overall * 5);
                totals[6] += overall;
                cardsShootingAttributes[i] = 1; // Almost no chance for the GK to score
            } else {
                totals[0] += overall;
                totals[1] += pace;
                totals[2] += shooting;
                totals[3] += passing;
                totals[4] += dribbling;
                totals[5] += defending;
                totals[6] += physical;

                cardsShootingAttributes[i] = shooting + dribbling; // Chance to score by combining shooting and dribbling
            }
        }

        return (totals, cardsShootingAttributes);
    }

    function determineAttackingOrDefendingOutcomeForAttributes(uint attackingTeamId, uint defendingTeamId, uint atkAttributeTotal, uint defAttributeTotal, uint seed) internal view returns (uint) {
        
        uint max = atkAttributeTotal + defAttributeTotal;
        uint randValue = uint(keccak256(block.blockhash(block.number-1), seed))%max;

        if (randValue <= atkAttributeTotal) {
		    return attackingTeamId;
	    }

	    return defendingTeamId;
    }

    function determineGoalScoringCardIds(uint[] cardIds, uint[] shootingAttributes, uint seed) internal view returns(uint) {

        uint max = 0;
        uint min = 0;
        for (uint i = 0; i < shootingAttributes.length; i++) {
            max += shootingAttributes[i];
        }

        bytes32 randHash = keccak256(seed, now, block.blockhash(block.number - 1));
        uint randValue = uint(randHash) % max + min;

        for (i = 0; i < cardIds.length; i++) {
            uint cardId = cardIds[i];
            randValue -= shootingAttributes[i];

            // We do the more than to handle wrap arounds on uint
            if (randValue <= 0 || randValue >= max) {
                return cardId;
            }
        }

        return cardIds[0];
    }

    // ** Settlement **
    function calculateWinningEntries() external onlyReferee {
        require(competitionStatus == CompetitionStatuses.Finished);

        address[] memory winningAddresses = new address[](prizeBreakdown.length);
        uint[] memory winningTeamIds = new uint[](prizeBreakdown.length);
        uint[] memory winningTeamPoints = new uint[](prizeBreakdown.length);

        // League table position priority
        // 1. Most Points
        // 2. Biggest Goal Difference
        // 3. Most Goals Scored
        // 4. Number of Wins
        // 5. First to Enter

        // 1. Loop over all teams
        bool isReplacementWinner = false;
        for (uint i = 0; i < teams.length; i++) {
            Team memory _team = teams[i];

            // 2. Grab their current points
            uint currPoints = (_team.wins * 3) + _team.draws;

            // 3. Compare the points to each team in the winning team points array
            for (uint x = 0; x < winningTeamPoints.length; x++) {
                
                // 4. Check if the current entry is more
                isReplacementWinner = false;
                if (currPoints > winningTeamPoints[x]) {
                    isReplacementWinner = true;
                // 5. We need to handle tie-break rules if 2 teams have the same number of points
                } else if (currPoints == winningTeamPoints[x]) {
                    
                    // 5a. Unfortunately in this scenario we need to refetch the team we&#39;re comparing
                    Team memory _comparisonTeam = teams[winningTeamIds[x]];

                    int gdTeam = _team.goalsFor - _team.goalsAgainst;
                    int gdComparedTeam = _comparisonTeam.goalsFor - _comparisonTeam.goalsAgainst;

                    // 5b. GOAL DIFFERENCE
                    if (gdTeam > gdComparedTeam) {
                        isReplacementWinner = true;
                    } else if (gdTeam == gdComparedTeam) {

                        // 5c. MOST GOALS
                        if (_team.goalsFor > _comparisonTeam.goalsFor) {
                            isReplacementWinner = true;
                        } else if (_team.goalsFor == _comparisonTeam.goalsFor) {

                            // 5d. NUMBER OF WINS
                            if (_team.wins > _comparisonTeam.wins) {
                                isReplacementWinner = true;
                            } else if (_team.wins == _comparisonTeam.wins) {

                                // 5e. FIRST TO ENTER (LOWER INDEX)
                                if (i < winningTeamIds[x]) {
                                    isReplacementWinner = true;
                                }
                            }
                        }
                    }
                }

                // 6. Now we need to shift all elements down for the "paid places" for winning entries
                if (isReplacementWinner) {
                    
                    // 7. We need to start by copying the current index into next one down, assuming it exists
                    for (uint y = winningAddresses.length - 1; y > x; y--) {
                        winningAddresses[y] = winningAddresses[y-1];
                        winningTeamPoints[y] = winningTeamPoints[y-1];
                        winningTeamIds[y] = winningTeamIds[y-1];
                    }
                    
                    // 8. Set the current team and points as a replacemenet for the current entry
                    winningAddresses[x] = _team.manager;
                    winningTeamPoints[x] = currPoints;
                    winningTeamIds[x] = i;
                    break; // We don&#39;t need to compare values further down the chain
                }
            }
        }

        // Set the winning entries
        winners = winningAddresses;
    }

    function settleLeague() external onlyOwner {
        require(competitionStatus == CompetitionStatuses.Finished);
        require(winners.length > 0);
        require(prizeBreakdown.length == winners.length);
        require(prizePool >= this.balance);

        // Mark the contest as settled
        competitionStatus = CompetitionStatuses.Settled;
        
        // Payout each winner
        for (uint i = 0; i < winners.length; i++) {
            address winner = winners[i];
            uint percentageCut = prizeBreakdown[i]; // We can assume this index exists as we&#39;ve checked the lengths in the require

            uint winningAmount = calculateWinnerCut(prizePool, percentageCut);
            winner.transfer(winningAmount);
        }
    }

    function calculateWinnerCut(uint totalPot, uint cut) internal pure returns (uint256) {
        // PRIZE_POT_PERCENTAGE_MAX = 10,000 = 100%, required&#39;d <= PRIZE_POT_PERCENTAGE_MAX in the constructor so no requirement to validate here
        uint finalCut = totalPot * cut / PRIZE_POT_PERCENTAGE_MAX;
        return finalCut;
    }  

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }

    // Utils
    function hasStarted() external view returns (bool) {
        if (competitionStatus == CompetitionStatuses.Upcoming || competitionStatus == CompetitionStatuses.OpenForEntry || competitionStatus == CompetitionStatuses.PendingStart) {
            return false;
        }

        return true;
    }

    function winningTeamId() external view returns (uint) {
        require(competitionStatus == CompetitionStatuses.Finished || competitionStatus == CompetitionStatuses.Settled);

        uint winningTeamId = 0;
        for (uint i = 0; i < teams.length; i++) {
            if (teams[i].manager == winners[0]) {
                winningTeamId = i;
                break;
            }
        }

        return winningTeamId;
    }
}