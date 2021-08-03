/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.4.8;

// Utility contract for ownership functionality.
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/**
 * @author Ben Hodgson
 *
 * Sport Betting Contract
 *
 */
contract Betting is owned {
    using SafeMath for uint;

    bytes32 public test;
    bytes32 public verify;

    // store the authorized leagues
    mapping (bytes32 => uint) public leagueIndex;
    League[] public leagues;

    // constants that control contract functionality
    uint public stakeAmount = 10;

    struct League {
        address host;
        string name;
        // store the matches
        mapping (bytes32 => uint) matchIndex;
        Match[] matches;
        // store the authorized arbiters
        mapping(address => uint) arbiterIndex;
        Arbiter[] arbiters;
    }

    struct Bet {
        bytes32 matchHash;
        address owner;
        string betOnTeam;
        uint amount;
        bool withdrawn;
    }

    struct Team {
        string name;
        uint score;
    }

    struct Match {
        bytes32 hash;
        string homeTeam;
        string awayTeam;
        string league;
        uint startTime;
        uint commits;
        uint reveals;
        bool finalized;
        mapping (address => uint) betterIndex;
        Bet[] bets;
        mapping (address => bytes32) resultHash;
        mapping (address => bytes32) revealHash;
        mapping (bytes32 => uint) resultCountIndex;
        Count[] resultCount;
        uint betPool;
    }

    struct Result {
        bytes32 hash;
        bytes32 matchHash;
        Team homeTeam;
        Team awayTeam;
    }

    struct Count {
        uint value;
        Result matchResult;
    }

    struct Arbiter {
        address id;
        uint commits;
        uint reveals;
    }

    constructor() public {
        addLeague(owner, "Genesis");
    }

    /**
     * Add League
     *
     * Make `makerAddress` a league named `leagueName`
     *
     * @param makerAddress ethereum address to be added as the league host
     * @param leagueName public name for that league
     */
    function addLeague(
        address makerAddress,
        string leagueName
    ) onlyOwner public {
        bytes32 leagueHash = keccak256(abi.encodePacked(leagueName));
        // Check existence of league.
        uint index = leagueIndex[leagueHash];
        if (index == 0) {
            // Add league to ID list.
            leagueIndex[leagueHash] = leagues.length;
            // index gets leagues.length, then leagues.length++
            index = leagues.length++;
        }

        // Create and update storage
        League storage m = leagues[index];
        m.host = makerAddress;
        m.name = leagueName;
    }

    /**
     * Remove a league
     *
     * @notice Remove match maker designation from `makerAddress` address.
     *
     * @param leagueName the name of the league to be removed
     */
    function removeleague(string leagueName) onlyOwner public {
        bytes32 leagueHash = validateLeague(leagueName);

        // Rewrite the match maker storage to move the 'gap' to the end.
        for (uint i = leagueIndex[leagueHash];
                i < leagues.length - 1; i++) {
            leagues[i] = leagues[i+1];
            leagueIndex[keccak256(abi.encodePacked(leagues[i].name))] = i;
        }

        // Delete the last match maker
        delete leagueIndex[leagueHash];
        delete leagues[leagues.length-1];
        leagues.length--;
    }

    /**
     * Add an Arbiter to a specified League
     *
     * Make `arbiterAddress` an arbiter for league `leagueName`
     *
     * @param arbiterAddress ethereum address to be added as a league arbiter
     * @param leagueName public name for that league
     */
    function addLeagueArbiter(
        address arbiterAddress,
        string leagueName
    ) onlyOwner public {
        bytes32 leagueHash = validateLeague(leagueName);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        // Check existence of league arbiter
        uint index = thisLeague.arbiterIndex[arbiterAddress];
        if (index == 0) {
            // Add league arbiter to ID list.
            thisLeague.arbiterIndex[arbiterAddress] = thisLeague.arbiters.length;
            // index gets length, then length++
            index = thisLeague.arbiters.length++;
        }

        // Create and update storage
        Arbiter storage a = thisLeague.arbiters[index];
        a.id = arbiterAddress;
        a.commits = 0;
        a.reveals = 0;
    }

    /**
     * Remove an arbiter from a league
     *
     * @notice Remove arbiter designation from `arbiterAddress` address.
     *
     * @param arbiterAddress ethereum address to be removed as league arbiter
     * @param leagueName the name of the league
     */
    function removeLeagueArbiter(
        address arbiterAddress,
        string leagueName
    ) onlyOwner public {
        bytes32 leagueHash = validateLeagueArbiter(arbiterAddress, leagueName);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        uint index = thisLeague.arbiterIndex[arbiterAddress];

        // Rewrite storage to move the 'gap' to the end.
        for (uint i = index;
                i < thisLeague.arbiters.length - 1; i++) {
            thisLeague.arbiters[i] = thisLeague.arbiters[i+1];
            thisLeague.arbiterIndex[thisLeague.arbiters[i].id] = i;
        }

        // Delete the tail
        delete thisLeague.arbiterIndex[arbiterAddress];
        delete thisLeague.arbiters[thisLeague.arbiters.length-1];
        thisLeague.arbiters.length--;
    }

    /**
     * Allows only match makers to create a match
     *
     * @param homeTeam the home team competing in the match
     * @param awayTeam the away team competing in the match
     * @param league the match pertains to
     * @param startTime the time the match begins
     */
    function createMatch(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) public returns (bytes32 matchHash) {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        // require this is the league host
        require(thisLeague.host == msg.sender, "Sender is not the league host");

        // TODO require match hasn't already started
        //require(startTime > now + 1 hours, "Match already started");

        matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        uint index = thisLeague.matchIndex[matchHash];
        if (index == 0) {
            thisLeague.matchIndex[matchHash] = thisLeague.matches.length;
            index = thisLeague.matches.length++;
        }

        // Create and update storage
        Match storage newMatch = thisLeague.matches[index];
        newMatch.hash = matchHash;
        newMatch.homeTeam = homeTeam;
        newMatch.awayTeam = awayTeam;
        newMatch.league = league;
        newMatch.startTime = startTime;
        newMatch.finalized = false;
    }

    /**
     * Allows only match makers to remove a match. Refunds all bets placed
     * on the match.
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function removeMatch(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) public {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        // require this is the league host
        require(thisLeague.host == msg.sender, "Sender is not the league host");

        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        uint index = thisLeague.matchIndex[matchHash];
        require(thisLeague.matches[index].hash == matchHash, "Invalid match");

        // require the match hasn't started
        require(now < thisLeague.matches[index].startTime, "Match has started");

        // refund bets
        for (uint b = 0; b < thisLeague.matches[index].bets.length; b++) {
            if (!thisLeague.matches[index].bets[b].withdrawn) {
                Bet storage thisBet = thisLeague.matches[index].bets[b];
                thisBet.withdrawn = true;
                thisBet.owner.transfer(thisBet.amount);
            }
        }

        // Rewrite the matches storage to move the 'gap' to the end.
        for (uint i = thisLeague.matchIndex[matchHash];
                i < thisLeague.matches.length - 1; i++) {
            thisLeague.matches[i] = thisLeague.matches[i + 1];
            thisLeague.matchIndex[thisLeague.matches[i].hash] = i;
        }

        // Delete the last match
        delete thisLeague.matchIndex[matchHash];
        delete thisLeague.matches[thisLeague.matches.length - 1];
        thisLeague.matches.length--;
    }

    /**
     * Returns the match information that bears the hash generated with the user
     * input parameters
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the name of the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function getMatch(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) view public returns(bytes32, string, string, string, uint, bool) {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        uint index = thisLeague.matchIndex[matchHash];
        require(thisLeague.matches[index].hash == matchHash, "Invalid match");
        Match storage retMatch = thisLeague.matches[index];
        return (
            retMatch.hash,
            retMatch.homeTeam,
            retMatch.awayTeam,
            retMatch.league,
            retMatch.startTime,
            retMatch.finalized
        );
    }

    /**
     * Allow only arbiters for the specified 'league' to commit match results
     *
     * @param homeTeam the home team competing in the match
     * @param awayTeam the away team competing in the match
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     * @param resultHash the hash of the result entered by the arbiter
     */
    function commitMatchResult(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime,
        bytes32 resultHash
    ) public payable {
        bytes32 leagueHash = validateLeagueArbiter(msg.sender, league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // make sure match is valid
        require(thisMatch.hash == matchHash, "Invalid match");

        // require match is finished
        require(now > startTime + 95, "Match is not finished");

        // require match still needs more commits
        require(
            thisLeague.arbiters.length.mul(8).div(10) >= thisMatch.commits,
            "Match not accepting more commits"
        );

        // only allow one result submission per address
        require(thisMatch.resultHash[msg.sender] == 0, "Result already committed");

        // must stake 'stakeAmount' to commit result
        require(msg.value >= stakeAmount, "Must stake 10 Wei to commit result");

        storeMatchCommit(msg.sender, league, matchHash, resultHash);
    }

    /**
     * Allow only arbiters for the specified 'league' to reveal match results
     *
     * @param homeTeam the home team competing in the match
     * @param awayTeam the away team competing in the match
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     * @param salt the hash added in the msg.sender's result commit
     * @param homeScore the score for the home team
     * @param awayScore the score for the away team
     */
    function revealMatchResult(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime,
        bytes32 salt,
        uint homeScore,
        uint awayScore
    ) public {
        bytes32 leagueHash = validateLeagueArbiter(msg.sender, league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // make sure match is valid
        require(thisMatch.hash == matchHash, "Invalid match");

        // require match is finished
        require(now > startTime + 95, "Match is not finished");

        // require match doesn't need more commits
        require(
            thisLeague.arbiters.length.mul(8).div(10) < thisMatch.commits,
            "Match is still accepting commits"
        );

        // require msg.sender committed a result
        require(
            thisMatch.resultHash[msg.sender] != 0,
            "Result never committed or stake already withdrawn"
        );

        verifyMatchReveal(msg.sender, league, matchHash, salt, homeScore, awayScore);
    }

    /**
     * Allows only match makers that submitted a correct result for a match
     * withdraw a small reward taken from the bet pool for the match.
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function withdrawResult(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) public {
        bytes32 leagueHash = validateLeagueArbiter(msg.sender, league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // require the match is finalized
        require(thisMatch.finalized, "Match result is not finalized");
        bytes32 finalResultHash = findFinalResultHash(homeTeam, awayTeam, league, startTime);

        // require they revealed the correct result
        require(
            finalResultHash == thisMatch.revealHash[msg.sender],
            "You did not submit the correct result"
        );

        // reset storage to only allow one result withdrawal
        thisMatch.revealHash[msg.sender] = bytes32(0);

        uint countIndex = thisMatch.resultCountIndex[finalResultHash];
        Count storage resultCount = thisMatch.resultCount[countIndex];

        uint winningPool;
        if (resultCount.matchResult.homeTeam.score > resultCount.matchResult.awayTeam.score) {
            winningPool = calculateWinningPool(league, matchHash,
                                    resultCount.matchResult.homeTeam.name);
        }
        else if (resultCount.matchResult.homeTeam.score < resultCount.matchResult.awayTeam.score) {
            winningPool = calculateWinningPool(league, matchHash,
                                    resultCount.matchResult.awayTeam.name);
        }
        else {
            //handle tie
            winningPool = 0;
        }

        uint rewardPool = thisMatch.betPool.mul(99).div(100);

        // reward if there are enough losers to guarantee winners don't lose money
        if (rewardPool > winningPool) {
            uint arbiterPool = thisMatch.betPool.sub(rewardPool);
            uint reward = arbiterPool.div(resultCount.value);
            msg.sender.transfer(reward);
        }
    }

    /**
     * Allows anyone to get the final result information for the specified
     * match
     *
     * @param matchHash the identifying hash for the match
     * @param league the league the match pertains to
     */
    function getFinalResult(
        bytes32 matchHash,
        string league
    ) view public returns (bytes32, bytes32, string, uint, string, uint) {
        League storage thisLeague = leagues[leagueIndex[validateLeague(league)]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // require the match is finalized
        require(thisMatch.finalized, "Match result not finalized");

        // loop through result counter and determine most numerous result
        uint maxCounter = 0;
        Result storage maxResult = thisMatch.resultCount[0].matchResult;
        for (uint i = 0; i < thisMatch.resultCount.length; i++) {
            if (thisMatch.resultCount[i].value > maxCounter) {
                maxCounter = thisMatch.resultCount[i].value;
                maxResult = thisMatch.resultCount[i].matchResult;
            }
        }
        return (
            maxResult.hash,
            maxResult.matchHash,
            maxResult.homeTeam.name,
            maxResult.homeTeam.score,
            maxResult.awayTeam.name,
            maxResult.awayTeam.score
        );
    }

    /**
     * Allows anyone to place a bet on a match specified by the given
     * function arguments.
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     * @param betOnTeam the team that is bet to win the match
     */
    function placeBet(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime,
        string betOnTeam
    ) payable public {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        // make sure this is a valid bet
        uint index = validateBet(homeTeam, awayTeam, league,
                startTime, betOnTeam);
        Match storage matchBetOn = thisLeague.matches[index];
        uint betIndex = matchBetOn.betterIndex[msg.sender];
        if (betIndex == 0) {
            // Add bet owner to ID list.
            matchBetOn.betterIndex[msg.sender] = matchBetOn.bets.length;
            betIndex = matchBetOn.bets.length++;
        }

        // Create and update storage
        Bet storage b = matchBetOn.bets[betIndex];
        b.matchHash = matchBetOn.hash;
        b.owner = msg.sender;
        b.withdrawn = false;

        // place the bet on the correct team
        if (keccak256(abi.encodePacked(betOnTeam)) ==
                keccak256(abi.encodePacked(matchBetOn.homeTeam))) {
            b.betOnTeam = homeTeam;
        }
        else {
            b.betOnTeam = awayTeam;
        }
        b.amount = msg.value;
        matchBetOn.betPool = matchBetOn.betPool.add(msg.value);
    }

    /**
     * Allows anyone to remove a bet they placed on a match
     *
     * @notice msg.sender must have a bet placed on the match
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function removeBet(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) payable public {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);

        // make sure match is a valid match
        uint index = thisLeague.matchIndex[matchHash];
        require(index != 0 || thisLeague.matches[index].hash == matchHash, "Invalid match");

        // require the user has placed a bet on the match
        uint betIndex = thisLeague.matches[index].betterIndex[msg.sender];
        require(
            betIndex != 0 || thisLeague.matches[index].bets[betIndex].owner == msg.sender,
            "You did not place a bet on this match"
        );

        // require the match hasn't started
        require(now < thisLeague.matches[index].startTime, "Match already started");

        // save the bet amount for refunding purposes
        uint betAmount = thisLeague.matches[index].bets[betIndex].amount;
        uint expectedBalance = address(this).balance.sub(betAmount);

        // Rewrite the bets storage to move the 'gap' to the end.
        Bet[] storage addressBets = thisLeague.matches[index].bets;
        for (uint i = betIndex; i < addressBets.length - 1; i++) {
            addressBets[i] = addressBets[i+1];
            thisLeague.matches[index].betterIndex[addressBets[i].owner] = i;
        }

        // Delete the last bet
        delete thisLeague.matches[index].betterIndex[msg.sender];
        delete addressBets[addressBets.length-1];
        addressBets.length--;

        // refund and update match bet pool
        thisLeague.matches[index].betPool = thisLeague.matches[index].betPool.sub(betAmount);
        msg.sender.transfer(betAmount);
        assert(address(this).balance == expectedBalance);
    }

    /**
     * Allows anyone to retrieve the information about a bet they placed on
     * a specified match. Information returned includes the match hash for the
     * match the bet was placed on, the bet owner's address, the team bet on,
     * the amount bet, and whether the bet has been withdrawn.
     *
     * @notice msg.sender must have a bet placed on the match
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function getBet(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) view public returns (bytes32, address, string, uint, bool) {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];

        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        // require the bet is on a valid match
        uint index = thisLeague.matchIndex[matchHash];
        require(index != 0 || thisLeague.matches[index].hash == matchHash);
        // require the user has placed a bet on the match
        uint betIndex = thisLeague.matches[index].betterIndex[msg.sender];
        require(betIndex != 0 || thisLeague.matches[index].bets[betIndex].owner == msg.sender);
        // require this is the bet owner
        Bet storage userBet = thisLeague.matches[index].bets[betIndex];
        require(msg.sender == userBet.owner);
        return (
            matchHash,
            userBet.owner,
            userBet.betOnTeam,
            userBet.amount,
            userBet.withdrawn
        );
    }

    /**
     * Allows anyone to withdraw a bet. If the bet was correct, a reward is
     * calculated and transferred to the account of the msg.sender.
     *
     * @notice msg.sender must have a bet placed on the match
     *
     * @param homeTeam the home team competing in the match to be removed
     * @param awayTeam the away team competing in the match to be removed
     * @param league the league the match to be removed pertains to
     * @param startTime the time the match to be removed begins
     */
    function withdrawBet(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) public {
        League storage thisLeague = leagues[leagueIndex[validateLeague(league)]];
        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // require the match result is finalized
        require(thisMatch.finalized, "Match result not finalized");

        // require the bet hasn't been withdrawn and msg.sender owns a bet
        uint betIndex = thisMatch.betterIndex[msg.sender];
        Bet storage userBet = thisMatch.bets[betIndex];
        require(
            !userBet.withdrawn && userBet.owner == msg.sender,
            "Bet already withdrawn or never placed on the match"
        );

        bytes32 finalResultHash = findFinalResultHash(homeTeam, awayTeam, league, startTime);

        processBetWithdraw(msg.sender, league, matchHash, finalResultHash);
    }

    /***************************************************************************
     * Private functions
     **************************************************************************/

    /**
     * Verifies that 'leagueName' is a valid league
     */
    function validateLeague(string leagueName) view private returns (bytes32) {
        bytes32 leagueHash = keccak256(abi.encodePacked(leagueName));
        // require it's a valid league
        require(leagueIndex[leagueHash] != 0, "Invalid league");
        return leagueHash;
    }

    /**
     * Verifies that 'arbiterAddress' is a valid arbiter
     *
     * @notice Also verifies that 'leagueName' is a valid league
     */
    function validateLeagueArbiter(
        address arbiterAddress,
        string leagueName
    ) view private returns (bytes32) {
        bytes32 leagueHash = validateLeague(leagueName);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        uint index = thisLeague.arbiterIndex[arbiterAddress];
        require(thisLeague.arbiters[index].id == arbiterAddress, "Invalid league arbiter");
        return leagueHash;
    }

    /**
     * Validates that a bet can be placed on a valid match
     *
     * @notice assumes the 'league' has already been confirmed as valid
     *
     * @return index the match index for the match the bet is placed on
     */
    function validateBet(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime,
        string betOnTeam
    ) view private returns (uint index) {
        bytes32 leagueHash = keccak256(abi.encodePacked(league));
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        bytes32 matchHash = getMatchHash(homeTeam, awayTeam, league, startTime);
        index = thisLeague.matchIndex[matchHash];

        // require the match can still be bet on
        require(thisLeague.matches[index].hash == matchHash
            && now < thisLeague.matches[index].startTime);

        // require the bet is on a valid team
        require(keccak256(abi.encodePacked(betOnTeam)) ==
                    keccak256(abi.encodePacked(thisLeague.matches[index].homeTeam))
                || keccak256(abi.encodePacked(betOnTeam)) ==
                    keccak256(abi.encodePacked(thisLeague.matches[index].awayTeam)));
    }

    /**
     * Stores the result commit specified by the function parameters and
     * attributes the submission to the sender address.
     *
     * @notice assumes the 'league' has already been confirmed as valid
     * @notice assumes 'sender' has already been confirmed as a league arbiter
     *
     * @param sender the address that submitted this result
     * @param league the league the match to be removed pertains to
     * @param matchHash the unique hash that identifies the match
     * @param resultHash the hash of the result committed by the arbiter
     */
    function storeMatchCommit(
        address sender,
        string league,
        bytes32 matchHash,
        bytes32 resultHash
    ) private {
        League storage thisLeague = leagues[leagueIndex[keccak256(abi.encodePacked(league))]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];
        // map the sender's address to the hash of the result and the match hash
        bytes32 resultKey = keccak256(abi.encodePacked(resultHash, matchHash));
        thisMatch.resultHash[sender] = resultKey;
        thisMatch.commits.add(1);
        thisLeague.arbiters[thisLeague.arbiterIndex[sender]].commits.add(1);
    }

    /**
     * Verifies that the result revealed matches the result previously committed
     * by the address 'sender' for this match
     *
     * @notice assumes the 'league' has already been confirmed as valid
     * @notice assumes 'sender' has already been confirmed as a league arbiter
     *
     * @param sender the address that submitted this result
     * @param league the league the match to be removed pertains to
     * @param matchHash the unique hash that identifies the match
     * @param salt the hash added in the msg.sender's result commit
     * @param homeScore the score for the home team
     * @param awayScore the score for the away team
     */
    function verifyMatchReveal(
        address sender,
        string league,
        bytes32 matchHash,
        bytes32 salt,
        uint homeScore,
        uint awayScore
    ) private {
        League storage thisLeague = leagues[leagueIndex[keccak256(abi.encodePacked(league))]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];
        bytes32 commit = thisMatch.resultHash[sender];
        bytes32 result = keccak256(abi.encodePacked(salt, homeScore, awayScore));
        bytes32 verifyCommit = keccak256(abi.encodePacked(result, matchHash));
        if (commit == verifyCommit) {
            // overwrite mapping to allow only one reveal per address
            thisMatch.resultHash[sender] = bytes32(0);
            sender.transfer(stakeAmount);

            // store the result and increase reveal number if match isn't finalized
            if (!thisMatch.finalized) {
                bytes32 storeResult = keccak256(abi.encodePacked(matchHash, homeScore, awayScore));
                storeMatchReveal(sender, league, matchHash, storeResult, homeScore, awayScore);
            }
        }
    }

    /**
     * Verifies that the result revealed matches the result previously committed
     * by the address 'sender' for this match
     *
     * @notice assumes the 'league' has already been confirmed as valid
     * @notice assumes 'sender' has already been confirmed as a league arbiter
     *
     * @param sender the address that submitted this result
     * @param league the league the match to be removed pertains to
     * @param matchHash the unique hash that identifies the match
     * @param storeResult the hash to identify the result revealed
     * @param homeScore the score for the home team
     * @param awayScore the score for the away team
     */
    function storeMatchReveal(
        address sender,
        string league,
        bytes32 matchHash,
        bytes32 storeResult,
        uint homeScore,
        uint awayScore
    ) private {
        League storage thisLeague = leagues[leagueIndex[keccak256(abi.encodePacked(league))]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        // map the sender's address to the result hash
        thisMatch.revealHash[sender] = storeResult;

        // map the result hash to an index in the result counter array
        uint countIndex = thisMatch.resultCountIndex[storeResult];
        if (countIndex == 0
                && thisMatch.resultCount[countIndex].matchResult.hash != storeResult) {
            // Add result to ID list
            thisMatch.resultCountIndex[storeResult] = thisMatch.resultCount.length;
            countIndex = thisMatch.resultCount.length++;

            // identify the result
            thisMatch.resultCount[countIndex].matchResult = Result(
                storeResult,
                matchHash,
                Team(thisMatch.homeTeam, homeScore),
                Team(thisMatch.awayTeam, awayScore)
            );
        }
        // add 1 to the number of people who submitted this result
        Count storage thisCount = thisMatch.resultCount[countIndex];
        thisCount.value = thisCount.value.add(uint(1));

        // add to the number of reveals, check if match is finalized
        thisMatch.reveals.add(1);
        thisLeague.arbiters[thisLeague.arbiterIndex[sender]].reveals.add(1);
        if(thisMatch.commits.mul(9).div(10) < thisMatch.reveals) {
            thisMatch.finalized = true;
        }
    }

     /**
     * Distributes the bet reward if the user won the bet
     *
     * @notice assumes the 'league' has already been confirmed as valid
     *
     * @param sender the address that submitted a bet on this match
     * @param league the league the match to be removed pertains to
     * @param matchHash the unique hash that identifies the match
     * @param finalResultHash the hash of the finalized match result
     */
    function processBetWithdraw(
        address sender,
        string league,
        bytes32 matchHash,
        bytes32 finalResultHash
    ) private {
        League storage thisLeague = leagues[leagueIndex[validateLeague(league)]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];

        uint resultIndex = thisMatch.resultCountIndex[finalResultHash];
        Result storage finalResult = thisMatch.resultCount[resultIndex].matchResult;
        uint betIndex = thisMatch.betterIndex[msg.sender];
        Bet storage userBet = thisMatch.bets[betIndex];

        // withdraw Bet
        userBet.withdrawn = true;
        uint reward;
        if (finalResult.homeTeam.score == finalResult.awayTeam.score) {
            // handle tie
            reward = userBet.amount.mul(99).div(100);
            sender.transfer(reward);
        }
        else {
            // handle win
            uint winningPool;
            uint rewardPool = thisMatch.betPool.mul(99).div(100);
            if (finalResult.homeTeam.score > finalResult.awayTeam.score) {
                if (keccak256(abi.encodePacked(userBet.betOnTeam))
                        == keccak256(abi.encodePacked(finalResult.homeTeam.name))) {
                    winningPool = calculateWinningPool(league, matchHash,
                                            finalResult.homeTeam.name);
                    reward = rewardPool.mul(userBet.amount).div(winningPool);
                    sender.transfer(reward);
                }
            }
            else {
                if (keccak256(abi.encodePacked(userBet.betOnTeam))
                        == keccak256(abi.encodePacked(finalResult.awayTeam.name))) {
                    winningPool = calculateWinningPool(league, matchHash,
                                            finalResult.awayTeam.name);
                    reward = rewardPool.mul(userBet.amount).div(winningPool);
                    sender.transfer(reward);
                }
            }

        }
    }

    /**
     * Returns the hash of the final result for the specified match
     */
    function findFinalResultHash(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) view private returns (bytes32) {
        (bytes32 resultHash,
         bytes32 matchHash,
         string memory homeName,
         uint homeScore,
         string memory awayName,
         uint awayScore) = getFinalResult(
            getMatchHash(homeTeam, awayTeam, league, startTime),
            league
        );
        return resultHash;
    }

    /**
     * Calculates and returns the sum of the correct bet amounts
     *
     * @param matchHash the hash of the match the bets are for
     * @param league the league the match pertains to
     * @param winningTeam the team that won the match
     */
    function calculateWinningPool(
        string league,
        bytes32 matchHash,
        string winningTeam
    ) view private returns (uint winningPool) {
        bytes32 leagueHash = validateLeague(league);
        League storage thisLeague = leagues[leagueIndex[leagueHash]];
        Match storage thisMatch = thisLeague.matches[thisLeague.matchIndex[matchHash]];
        winningPool = 0;
        for (uint i = 0; i < thisMatch.bets.length; i++) {
            Bet storage thisBet = thisMatch.bets[i];
            if (keccak256(abi.encodePacked(thisBet.betOnTeam))
                    == keccak256(abi.encodePacked(winningTeam))) {
                winningPool = winningPool.add(thisBet.amount);
            }
        }
    }

    /**
     * Calculates the unique byte32 identifier hash for the specified match
     */
    function getMatchHash(
        string homeTeam,
        string awayTeam,
        string league,
        uint startTime
    ) pure private returns (bytes32 matchHash){
        matchHash = keccak256(abi.encodePacked(
            homeTeam,
            awayTeam,
            league,
            startTime
        ));
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}