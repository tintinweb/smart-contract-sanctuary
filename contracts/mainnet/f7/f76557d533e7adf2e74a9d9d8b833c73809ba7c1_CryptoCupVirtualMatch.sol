pragma solidity ^0.4.21;

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract CryptoCupVirtualMatch {

    // evsoftware.co.uk
    // cryptocup.online

    /*****------ EVENTS -----*****/
    event MatchCreated(uint256 indexed id, uint256 playerEntryPrice, uint256 homeTeam, uint256 awayTeam, uint256 kickOff, uint256 fullTime);
    event MatchFinished(uint256 indexed id, uint256 homeTeam, uint256 awayTeam, uint256 winningTeam, uint256 teamAllocation);
    event PlayerJoined(uint256 indexed id, uint256 team, string playerName, address account);
    event TeamOwnerPaid(uint256 indexed id, uint256 amount);

    /*****------- STORAGE -------******/
    CryptoCupToken cryptoCupTokenContract;
    address public contractModifierAddress;
    address public developerAddress;
    mapping (uint256 => Match) public matches;
    mapping (address => Player) public players;
    mapping (uint256 => Team) public teams;
    uint256 private developerBalance;
    bool private allowInPlayJoining = true;
    bool private allowPublicMatches = true;
    uint256 private entryPrice = 0.05 ether; 
    uint256 private startInSeconds = 300;
    uint256 private durationInSeconds = 120;
    uint256 private dataVisibleWindow = 21600; // Initial 6 hours
    uint256 private matchCounter;
    uint256 private playerCounter;
    uint256 private teamCounter;
    bool private commentating = false;
    
    /*****------- DATATYPES -------******/
    struct Match {
        uint256 id;
        uint256 playerEntryPrice;
        uint256 homeTeam;
        mapping (uint256 => Player) homeTeamPlayers;
        uint256 homeTeamPlayersCount;
        uint256 awayTeam;
        mapping (uint256 => Player) awayTeamPlayers;
        uint256 awayTeamPlayersCount;
        uint256 kickOff;
        uint256 fullTime;
        uint256 prize;
        uint256 homeScore;
        uint256 awayScore;
        uint256 winningTeam;
        uint256 winningTeamBonus;
        bool reported;
    }

    struct Player {
        uint256 id;
        string name;
        address account;
        uint256 balance;
    }
    
    struct Team {
        uint256 id;
        address owner;
        uint256 balance;
        bool init;
    }

    /*****------- MODIFIERS -------******/
    modifier onlyContractModifier() {
        require(msg.sender == contractModifierAddress);
        _;
    }
    
    /*****------- CONSTRUCTOR -------******/
    constructor() public {
        contractModifierAddress = msg.sender;
        developerAddress = msg.sender;
    }

	function destroy() public onlyContractModifier {
		selfdestruct(contractModifierAddress);
    }

    function setDeveloper(address _newDeveloperAddress) public onlyContractModifier {
        require(_newDeveloperAddress != address(0));
        developerAddress = _newDeveloperAddress;
    }

    function setCryptoCupTokenContractAddress(address _cryptoCupTokenAddress) public onlyContractModifier {
        cryptoCupTokenContract = CryptoCupToken(_cryptoCupTokenAddress);
    }
    
    function togglePublicMatches() public onlyContractModifier {
        // If we find an issue with people creating matches
        allowPublicMatches = !allowPublicMatches;
    }
    
    function toggleInPlayJoining() public onlyContractModifier {
        // If we find an issue with people trying to join games that are in progress, we can change the logic to not allow this and they can only join before a game starts
        allowInPlayJoining = !allowInPlayJoining;
    }
    
    function toggleMatchStartEnd(uint256 _startInSeconds, uint256 _durationInSeconds) public onlyContractModifier {
        startInSeconds = _startInSeconds;
        durationInSeconds = _durationInSeconds;
    }
    
    function toggleDataViewWindow(uint256 _periodInSeconds) public onlyContractModifier {
        dataVisibleWindow = _periodInSeconds;
    }

    function doubleEntryPrice() public onlyContractModifier {
        // May want to ramp up during knockouts
        entryPrice = SafeMath.mul(entryPrice,2);
    }
    
    function halveEntryPrice() public onlyContractModifier {
        // Ability to ramp down
        entryPrice = SafeMath.div(entryPrice,2);
    }
    
    function developerPrizeClaim() public onlyContractModifier {
        developerAddress.transfer(developerBalance);
        developerBalance = 0;
    }
    
    function getBalance()  public constant returns(uint256) {
        return address(this).balance;
    }
    
    function getTotalMatches() public constant returns(uint256) {
        return matchCounter;
    }
    
    function getTotalPlayers() public constant returns(uint256) {
        return playerCounter;
    }
    
    function getCryptoCupTokenContractAddress() public view returns (address contractAddress) {
        return cryptoCupTokenContract;
    }
    
    function getTeamOwner(uint256 _tokenId) public view returns(address owner)
    {
        owner = cryptoCupTokenContract.ownerOf(_tokenId);
    }

    function getEntryPrice() public constant returns(uint256) {
        return entryPrice;
    }
    
    function createPlayerMatch(uint256 _homeTeam, uint256 _awayTeam, uint256 _entryPrice, uint256 _startInSecondsTime, uint256 _matchDuration) public {
        require(allowPublicMatches);
        require(_homeTeam != _awayTeam);
        require(_homeTeam < 32 && _awayTeam < 32);
        require(_entryPrice >= entryPrice);
        require(_startInSecondsTime > 0);
        require(_matchDuration >= durationInSeconds);
        
        // Does home team exist?
        if (!teams[_homeTeam].init) {
            teams[_homeTeam] = Team(_homeTeam, cryptoCupTokenContract.ownerOf(_homeTeam), 0, true);
        }
        
        // Does away team exist?
        if (!teams[_awayTeam].init) {
            teams[_awayTeam] = Team(_awayTeam, cryptoCupTokenContract.ownerOf(_awayTeam), 0, true);
        }
        
        // Does the user own one of these teams?
        require(teams[_homeTeam].owner == msg.sender || teams[_awayTeam].owner == msg.sender);

        uint256 _kickOff = now + _startInSecondsTime;
        uint256 _fullTime = _kickOff + _matchDuration;
        matchCounter++;
        matches[matchCounter] = Match(matchCounter, _entryPrice, _homeTeam, 0, _awayTeam, 0, _kickOff, _fullTime, 0, 0, 0, 0, 0, false);
        emit MatchCreated(matchCounter, entryPrice, _homeTeam, _awayTeam, _kickOff, _fullTime);
    }

    function createMatch(uint256 _homeTeam, uint256 _awayTeam) public onlyContractModifier {
        require(_homeTeam != _awayTeam);
        
        // Does home team exist?
        if (!teams[_homeTeam].init) {
            teams[_homeTeam] = Team(_homeTeam, cryptoCupTokenContract.ownerOf(_homeTeam), 0, true);
        }
        
        // Does away team exist?
        if (!teams[_awayTeam].init) {
            teams[_awayTeam] = Team(_awayTeam, cryptoCupTokenContract.ownerOf(_awayTeam), 0, true);
        }
        
        // match starts in five mins, lasts for 3 mins
        uint256 _kickOff = now + startInSeconds;
        uint256 _fullTime = _kickOff + durationInSeconds;
        matchCounter++;
        matches[matchCounter] = Match(matchCounter, entryPrice, _homeTeam, 0, _awayTeam, 0, _kickOff, _fullTime, 0, 0, 0, 0, 0, false);
        emit MatchCreated(matchCounter, entryPrice, _homeTeam, _awayTeam, _kickOff, _fullTime);
    }

    function joinMatch(uint256 _matchId, uint256 _team, string _playerName) public payable {

        // Does player exist?
        if (players[msg.sender].id == 0) {
            players[msg.sender] = Player(playerCounter++, _playerName, msg.sender, 0);
        } else {
            players[msg.sender].name = _playerName;
        }
        
        // Get match
        Match storage theMatch = matches[_matchId];
        
        // Validation
        require(theMatch.id != 0); 
        require(msg.value >= theMatch.playerEntryPrice);
	    require(_addressNotNull(msg.sender));

        // Match status
        if (allowInPlayJoining) {
            require(now < theMatch.fullTime);    
        } else {
            require(now < theMatch.kickOff);
        }

        // Spaces left on team
        if (theMatch.homeTeam == _team)
        {
            require(theMatch.homeTeamPlayersCount < 11);
            theMatch.homeTeamPlayers[theMatch.homeTeamPlayersCount++] = players[msg.sender];
        } else {
            require(theMatch.awayTeamPlayersCount < 11);
            theMatch.awayTeamPlayers[theMatch.awayTeamPlayersCount++] = players[msg.sender];
        }

        theMatch.prize += theMatch.playerEntryPrice;

        // Overpayments are refunded
        uint256 purchaseExcess = SafeMath.sub(msg.value, theMatch.playerEntryPrice);
	    msg.sender.transfer(purchaseExcess);
	    
        emit PlayerJoined(_matchId, _team, players[msg.sender].name, msg.sender);
    }
    
    function getMatchHomePlayers(uint256 matchId) public constant returns(address[]) {
        if(matchCounter == 0) {
            return new address[](0x0);
        }
        
        // We only return matches that are in play
        address[] memory matchPlayers = new address[](matches[matchId].homeTeamPlayersCount);
        for (uint256 i = 0; i < matches[matchId].homeTeamPlayersCount; i++) {
            matchPlayers[i] =  matches[matchId].homeTeamPlayers[i].account;
        }
        return (matchPlayers);
    }
        
    function getMatchAwayPlayers(uint256 matchId) public constant returns(address[]) {
        if(matchCounter == 0) {
            return new address[](0x0);
        }
        
        // We only return matches that are in play
        address[] memory matchPlayers = new address[](matches[matchId].awayTeamPlayersCount);
        for (uint256 i = 0; i < matches[matchId].awayTeamPlayersCount; i++) {
            matchPlayers[i] =  matches[matchId].awayTeamPlayers[i].account;
        }
        return (matchPlayers);
    }

    function getFixtures() public constant returns(uint256[]) {
        if(matchCounter == 0) {
            return new uint[](0);
        }

        uint256[] memory matchIds = new uint256[](matchCounter);
        uint256 numberOfMatches = 0;
        for (uint256 i = 1; i <= matchCounter; i++) {
            if (now < matches[i].kickOff) {
                matchIds[numberOfMatches] = matches[i].id;
                numberOfMatches++;
            }
        }

        // copy it to a shorter array
        uint[] memory smallerArray = new uint[](numberOfMatches);
        for (uint j = 0; j < numberOfMatches; j++) {
            smallerArray[j] = matchIds[j];
        }
        return (smallerArray);
    }
    
    function getInPlayGames() public constant returns(uint256[]) {
        if(matchCounter == 0) {
            return new uint[](0);
        }
        
        // We only return matches that are in play
        uint256[] memory matchIds = new uint256[](matchCounter);
        uint256 numberOfMatches = 0;
        for (uint256 i = 1; i <= matchCounter; i++) {
            if (now > matches[i].kickOff && now < matches[i].fullTime) {
                matchIds[numberOfMatches] = matches[i].id;
                numberOfMatches++;
            }
        }

        // copy it to a shorter array
        uint[] memory smallerArray = new uint[](numberOfMatches);
        for (uint j = 0; j < numberOfMatches; j++) {
            smallerArray[j] = matchIds[j];
        }
        return (smallerArray);
    }
    
    function getUnReportedMatches() public constant returns(uint256[]) {
        if(matchCounter == 0) {
            return new uint[](0);
        }
        
        // We only return matches that are finished and unreported that had players
        uint256[] memory matchIds = new uint256[](matchCounter);
        uint256 numberOfMatches = 0;
        for (uint256 i = 1; i <= matchCounter; i++) {
            if (!matches[i].reported && now > matches[i].fullTime && (matches[i].homeTeamPlayersCount + matches[i].awayTeamPlayersCount) > 0) {
                matchIds[numberOfMatches] = matches[i].id;
                numberOfMatches++;
            }
        }

        // copy it to a shorter array
        uint[] memory smallerArray = new uint[](numberOfMatches);
        for (uint j = 0; j < numberOfMatches; j++) {
            smallerArray[j] = matchIds[j];
        }
        return (smallerArray);
    }

    function getMatchReport(uint256 _matchId) public {
        
        Match storage theMatch = matches[_matchId];
        
        require(theMatch.id > 0 && !theMatch.reported);
        
        uint256 index;
        // if a match was one sided, refund all players
        if (theMatch.homeTeamPlayersCount == 0 || theMatch.awayTeamPlayersCount == 0)
        {
            for (index = 0; index < theMatch.homeTeamPlayersCount; index++) {
                players[theMatch.homeTeamPlayers[index].account].balance += theMatch.playerEntryPrice;
            }

            for (index = 0; index < theMatch.awayTeamPlayersCount; index++) {
                players[theMatch.awayTeamPlayers[index].account].balance += theMatch.playerEntryPrice;
            }

        } else {
            
            // Get the account balances of each team, NOT the in game balance.
            uint256 htpBalance = 0;
            for (index = 0; index < theMatch.homeTeamPlayersCount; index++) {
               htpBalance += theMatch.homeTeamPlayers[index].account.balance;
            }
            
            uint256 atpBalance = 0;
            for (index = 0; index < theMatch.awayTeamPlayersCount; index++) {
               atpBalance += theMatch.awayTeamPlayers[index].account.balance;
            }
            
            theMatch.homeScore = htpBalance % 5;
            theMatch.awayScore = atpBalance % 5;
            
            // We want a distinct winner
            if (theMatch.homeScore == theMatch.awayScore)
            {
                if(block.timestamp % 2 == 0){
                  theMatch.homeScore += 1;
                } else {
                  theMatch.awayScore += 1;
                }
            }
    
            uint256 prizeMoney = 0;
            if(theMatch.homeScore > theMatch.awayScore){
              // home wins
              theMatch.winningTeam = theMatch.homeTeam;
              prizeMoney = SafeMath.mul(theMatch.playerEntryPrice, theMatch.awayTeamPlayersCount);
            } else {
              // away wins
              theMatch.winningTeam = theMatch.awayTeam;
              prizeMoney = SafeMath.mul(theMatch.playerEntryPrice, theMatch.homeTeamPlayersCount);
            }
            
    	    uint256 onePercent = SafeMath.div(prizeMoney, 100);
            uint256 developerAllocation = SafeMath.mul(onePercent, 1);
            uint256 teamOwnerAllocation = SafeMath.mul(onePercent, 9);
            uint256 playersProfit = SafeMath.mul(onePercent, 90);
            
            uint256 playersProfitShare = 0;
            
            // Allocate funds to players
            if (theMatch.winningTeam == theMatch.homeTeam)
            {
                playersProfitShare = SafeMath.add(SafeMath.div(playersProfit, theMatch.homeTeamPlayersCount), theMatch.playerEntryPrice);
                
                for (index = 0; index < theMatch.homeTeamPlayersCount; index++) {
                    players[theMatch.homeTeamPlayers[index].account].balance += playersProfitShare;
                }
                
            } else {
                playersProfitShare = SafeMath.add(SafeMath.div(playersProfit, theMatch.awayTeamPlayersCount), theMatch.playerEntryPrice);
                
                for (index = 0; index < theMatch.awayTeamPlayersCount; index++) {
                    players[theMatch.awayTeamPlayers[index].account].balance += playersProfitShare;
                }
            }
    
            // Allocate to team owner
            teams[theMatch.winningTeam].balance += teamOwnerAllocation;
            theMatch.winningTeamBonus = teamOwnerAllocation;

            // Allocate to developer
	        developerBalance += developerAllocation;
            
            emit MatchFinished(theMatch.id, theMatch.homeTeam, theMatch.awayTeam, theMatch.winningTeam, teamOwnerAllocation);
        }
        
        theMatch.reported = true;
    }

    function getReportedMatches() public constant returns(uint256[]) {
        if(matchCounter == 0) {
            return new uint[](0);
        }
        
        // We only return matches for the last x hours - everything else is on chain
        uint256[] memory matchIds = new uint256[](matchCounter);
        uint256 numberOfMatches = 0;
        for (uint256 i = 1; i <= matchCounter; i++) {
            if (matches[i].reported && now > matches[i].fullTime && matches[i].fullTime + dataVisibleWindow > now) {
                matchIds[numberOfMatches] = matches[i].id;
                numberOfMatches++;
            }
        }

        // copy it to a shorter array
        uint[] memory smallerArray = new uint[](numberOfMatches);
        for (uint j = 0; j < numberOfMatches; j++) {
            smallerArray[j] = matchIds[j];
        }
        return (smallerArray);
    }
    
    function playerPrizeClaim() public {
        require(_addressNotNull(msg.sender));
        require(players[msg.sender].account != address(0));
        
        msg.sender.transfer(players[msg.sender].balance);
        players[msg.sender].balance = 0;
    }
    
    function teamPrizeClaim(uint256 _teamId) public {
        require(_addressNotNull(msg.sender));
        require(teams[_teamId].init);
        
        // This allows for sniping of teams. If a balance increases because teams have won games with bets on them
        // then it is down to the owner to claim the prize. If someone spots a build up of balance on a team
        // and then buys the team they can claim the prize. This is the intent.
        teams[_teamId].owner = cryptoCupTokenContract.ownerOf(_teamId);
        
        // This way the claimant either gets the balance because he sniped the team
        // Or he initiates the transfer to the rightful owner
        teams[_teamId].owner.transfer(teams[_teamId].balance);
        emit TeamOwnerPaid(_teamId, teams[_teamId].balance);
        teams[_teamId].balance = 0;
    }

    /********----------- PRIVATE FUNCTIONS ------------********/
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }  
}

contract CryptoCupToken {
    function ownerOf(uint256 _tokenId) public view returns (address addr);
}