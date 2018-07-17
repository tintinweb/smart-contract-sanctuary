pragma solidity ^0.4.24;
 
/*
 
ETHEREUM PREMIER LEAGUE : 11th August 2018 - 5th May 2019
    - designed and implemented by Norsefire.
    - special thanks to oguzhanox for his invaluable assistance on the front-end.
 
Rules are as follows:
 
    * Entry to the game costs 1 Ether for the entire season, or 0.25 for a quarter-season.
        - Use the registerFull or registerSeason functions when sending this.
        - Any larger or smaller amounts of Ether, will be rejected.
    * 90% of the entry fee will go towards the prize fund, with 10% forming a cut.
        Of this cut, half goes to the developer, and half goes directly to Giveth (giveth.io/donate).
        The entry fee is the only Ether you will need to send for the duration of the
        season, barring the gas you spend for placing predictions.
    * Buying an entry allows the sender to place predictions on each fixture in the English Premier League,
        barring those which have already kicked off prior to the time a participant enters.
        - Registration for the full season entitles you to predict all 380 fixtures.
        - Registration for a quarter season entitles you to the current set of matchdays in progress
            [1-10, 11-20, 21-30, 31-41] comprising 100, 90, 85 and 105 games respectively.
    * Predictions can be made (or changed!) at any point up until *midnight UTC* on a given matchday.
        - This is because in a handful of cases, fixtures kick off at different times, and I would
          rather there be a consistent deadline for all fixtures on a matchday.
    * Selecting the correct result for any given game awards the player one point.
    * If a participant reaches a streak of three or more correct predictions in a row, they receive two points
        for every correct prediction from the third game until the streak is broken.
    * If a participant reaches a streak of *five* or more correct predictions in a row, they receive four points
        for every correct prediction from the fifth game until the streak is broken.
 
Prizes:
 
    Depending on whether you are playing in the full season or a quarter-season, your prize pool will be separate.
    (i.e. full season players compete for Pool X, quarter-season players for Pool Y.)
 
    At the end of a quarter-season or full season, the total score aggregated by the top half of players will be
    computed (rounded down if the number of players is odd). Those players who fall within that top half will then
    be able to claim Ether from the relevant prize pool proportional to their percentage of the total score.
 
    e.g. At the end of the first quarter-season, the prize pool is 22.5 Ether (with 100 participants). Of that, the top
    50 scores add up to 20,000. Assuming you placed in the top half of players with 350 points, your reward would be:
 
        22.5 Ether * (350 / 20,000) = 0.3925 Ether.
 
    e.g. At the end of the entire season, the prize pool was 180 Ether (with 200 participants) with the top 100 scores
    adding up to 65,000. Assuming you placed in the top half of players with 900 points, your reward would be:
 
        180 Ether  * (900 / 65,000) = 2.4923 Ether.
 
Participant Teams and Groups:
 
    AR - Arsenal
    BN - Bournemouth
    BR - Brighton & Hove Albion
    BY - Burnley
    CD - Cardiff City
    CH - Chelsea
    CP - Crystal Palace
    EV - Everton
    FL - Fulham
    HD - Huddersfield Town
    LE - Leicester City
    LV - Liverpool
    MC - Manchester City
    MU - Manchester United
    NC - Newcastle United
    SH - Southampton
    TH - Tottenham Hotspur
    WA - Watford
    WH - West Ham United
    WL - Wolverhampton Wolves
 
*/
 
contract EtherPremierLeague {
    using SafeMath for uint;
    using strings  for *;
 
    /* CONSTANTS */
 
    address internal constant administrator = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
    address internal constant givethAddress = 0x5ADF43DD006c6C36506e2b2DFA352E60002d22Dc;
 
    string name   = &quot;EtherPremierLeague&quot;;
    string symbol = &quot;EPL&quot;;
 
    /* VARIABLES */
   
    // List of addresses with permissions to score games in the administrator&#39;s absence.
    mapping(address => bool)                       referees;
   
    // Is a two digit mapping a valid entry? [including &quot;--&quot; for draws and &quot;XX&quot; for non-prediction]
    mapping (string => bool)                       validTeamID;
 
    // Has the game been scored?
    mapping (int16  =>  bool)                      gameFinished;
 
    // Which of the four seasons is currently active?
    int8                                           seasonActive;
 
    // Is a game no longer available for predictions to be made?
    mapping (int16  =>  uint)                      gameLocked;
 
    // A result is either the two character code of a team or &#39;--&#39; for a draw.
    mapping (int16  =>  string)                    gameResult;
 
    // Which game was most recently scored?
    int16                                          latestGameFinished;
 
    // How much Ether is in the prize pool for players currently available to ddraw from?
    mapping (int8 => uint)                         seasonPrizePool;
    uint                                           fullPrizePool;
    
    // What was the final prize pool amount, so that winners can claim their fair stake?
    mapping (int8 => uint)                         seasonFinalPrizePool;
    uint                                           fullFinalPrizePool;
 
    // How much Ether is in the pool to be donated to Giveth?
    uint                                           givethPool;
 
    // How many players are registered (either for the full season or any of the quarters)?
    int                                            registeredPlayers;
 
    // What is the total score accrued by all full season players?
    int                                            totalScore;
 
    // What is the total score accrued by all players of the currently active quarter season?
    int                                            seasonScore;
 
    // Is a player registered for a quarter/full season?
    // Note: you cannot be registered for the full season and a quarter season on the same address!
    mapping (int8 => mapping (address => bool))    playerSeasonRegistered;
    mapping (address => bool)                      playerFullRegistered;
 
    // Has a player made a prediction for a particular gameID?
    mapping (address => mapping (int16 => bool))   playerMadePrediction;
 
    // What prediction did a player make for a given gameID?
    mapping (address => mapping (int16 => string)) playerPredictions;
 
    // What is the overall list of points scored by a player, either for full or quarter seasons?
    mapping (address => uint[380])                 playerPointArray;
 
    // How many games has a player had scored (either by themselves or via a global invocation)?
    mapping (address => int16)                     playerGamesScored;
 
    // For a given matchday, what is the first gameID associated with it?
    // (Note: the end game IDs can be inferred vi the matchdayGames mapping)
    mapping (int16   => int16)                     matchdayStartGameID;
 
    // For a given matchday, how many games are in it? (Used for mass prediction setting)
    mapping (int16   => int16)                     matchdayGames;
 
    // What is the deadline for making a prediction for games in a given matchday?
    // Note: this is 00.00 UTC on the matchday, NOT the time of kick-off.
    mapping (int16   => uint)                      matchdayPredictionDeadline;
 
    // For a quarter season, which gameID marks its beginning?
    mapping (int16   => int16)                     seasonStartGameID;
 
    // For a quarter season, which gameID marks its end?
    mapping (int16   => int16)                     seasonEndGameID;
 
    // How many correct consecutive predictions has a player made?
    mapping (address => uint)                      playerStreak;
 
    // List all players registered for any aspect of the game.
    mapping(int8 => address[])                     playerSeasonList;
    address[]                                      playerFullList;
   
    // What is the total score for the top 50% of players participating in a quarter/full season?
    mapping(int8 => uint)                          seasonPoolTopHalfScore;
    uint                                           fullPoolTopHalfScore;
   
    // What score does a player need to have to qualify for a quarter/season prize?
    mapping(int8 => uint)                          seasonCutoffScore;
    uint                                           fullCutoffScore;
   
    // Did a quarter/full season player place in the top 50% of participants?
    mapping(int8 => mapping(address => bool))      playerQuarterPrizeWinner;
    mapping(address => bool)                       playerSeasonPrizeWinner;
   
    // Are quarter/full season players allowed to withdraw their winnings yet?
    mapping(int8 => bool)                          canClaimSeasonPrize;
    bool                                           canClaimFullPrize;
   
    // Has a quarter/full season player withdrawn their winnings yet?
    mapping(int8 => mapping (address => bool))     hasClaimedSeasonrPrize;
    mapping(address => bool)                       hasClaimedFullPrize;
 
    /* DEBUG EVENTS */
 
    event FullRegistration(
        address _player
    );
 
    event SeasonRegistration(
        int8 _quarter,
        address _player
    );
 
    event PlayerLoggedPrediction(
        address _player,
        int     _gameID,
        string  _prediction
    );
 
    event PlayerUpdatedScore(
        address _player,
        int     _lastGamePlayed
    );
    
    event WithdrawnSeasonPrize(
        address _player,
        int8    _season,
        uint    _winnings
    );
    
    event WithdrawnFullPrize(
        address _player,
        uint    _winnings
    );
 
    /* CONSTRUCTOR */
 
    constructor ()
        public
    {
 
        matchdayStartGameID[1]  = 1;
        matchdayStartGameID[2]  = 11;
        matchdayStartGameID[3]  = 21;
        matchdayStartGameID[4]  = 31;
        matchdayStartGameID[5]  = 41;
        matchdayStartGameID[6]  = 51;
        matchdayStartGameID[7]  = 61;
        matchdayStartGameID[8]  = 71;
        matchdayStartGameID[9]  = 81;
        matchdayStartGameID[10] = 91;
        matchdayStartGameID[11] = 101;
        matchdayStartGameID[12] = 111;
        matchdayStartGameID[13] = 121;
        matchdayStartGameID[14] = 131;
        matchdayStartGameID[15] = 141;
        matchdayStartGameID[16] = 149;
        matchdayStartGameID[17] = 151;
        matchdayStartGameID[18] = 161;
        matchdayStartGameID[19] = 171;
        matchdayStartGameID[20] = 181;
        matchdayStartGameID[21] = 191;
        matchdayStartGameID[22] = 201;
        matchdayStartGameID[23] = 211;
        matchdayStartGameID[24] = 221;
        matchdayStartGameID[25] = 231;
        matchdayStartGameID[26] = 237;
        matchdayStartGameID[27] = 241;
        matchdayStartGameID[28] = 251;
        matchdayStartGameID[29] = 261;
        matchdayStartGameID[30] = 271;
        matchdayStartGameID[31] = 276;
        matchdayStartGameID[32] = 281;
        matchdayStartGameID[33] = 291;
        matchdayStartGameID[34] = 301;
        matchdayStartGameID[35] = 311;
        matchdayStartGameID[36] = 321;
        matchdayStartGameID[37] = 331;
        matchdayStartGameID[38] = 341;
        matchdayStartGameID[39] = 351;
        matchdayStartGameID[40] = 361;
        matchdayStartGameID[41] = 371;
 
        matchdayGames[1] = 10;
        matchdayGames[2] = 10;
        matchdayGames[3] = 10;
        matchdayGames[4] = 10;
        matchdayGames[5] = 10;
        matchdayGames[6] = 10;
        matchdayGames[7] = 10;
        matchdayGames[8] = 10;
        matchdayGames[9] = 10;
        matchdayGames[10] = 10;
        matchdayGames[11] = 10;
        matchdayGames[12] = 10;
        matchdayGames[13] = 10;
        matchdayGames[14] = 10;
        matchdayGames[15] = 8;
        matchdayGames[16] = 2;
        matchdayGames[17] = 10;
        matchdayGames[18] = 10;
        matchdayGames[19] = 10;
        matchdayGames[20] = 10;
        matchdayGames[21] = 10;
        matchdayGames[22] = 10;
        matchdayGames[23] = 10;
        matchdayGames[24] = 10;
        matchdayGames[25] = 6;
        matchdayGames[26] = 4;
        matchdayGames[27] = 10;
        matchdayGames[28] = 10;
        matchdayGames[29] = 10;
        matchdayGames[30] = 5;
        matchdayGames[31] = 5;
        matchdayGames[32] = 10;
        matchdayGames[33] = 10;
        matchdayGames[34] = 10;
        matchdayGames[35] = 10;
        matchdayGames[36] = 10;
        matchdayGames[37] = 10;
        matchdayGames[38] = 10;
        matchdayGames[39] = 10;
        matchdayGames[40] = 10;
        matchdayGames[41] = 10;
 
        matchdayPredictionDeadline[1]  = 1533945600; // 00.00 UTC, 11 August 2018
        matchdayPredictionDeadline[2]  = 1534550400; // 00.00 UTC, 18 August 2018
        matchdayPredictionDeadline[3]  = 1535155200; // 00.00 UTC, 25 August 2018
        matchdayPredictionDeadline[4]  = 1535760000;
        matchdayPredictionDeadline[5]  = 1536969600;
        matchdayPredictionDeadline[6]  = 1537574400;
        matchdayPredictionDeadline[7]  = 1538179200;
        matchdayPredictionDeadline[8]  = 1538784000;
        matchdayPredictionDeadline[9]  = 1539993600;
        matchdayPredictionDeadline[10] = 1540598400;
        matchdayPredictionDeadline[11] = 1541203200;
        matchdayPredictionDeadline[12] = 1541808000;
        matchdayPredictionDeadline[13] = 1543017600;
        matchdayPredictionDeadline[14] = 1543622400;
        matchdayPredictionDeadline[15] = 1543968000;
        matchdayPredictionDeadline[16] = 1544054400;
        matchdayPredictionDeadline[17] = 1544227200;
        matchdayPredictionDeadline[18] = 1544832000;
        matchdayPredictionDeadline[19] = 1545436800;
        matchdayPredictionDeadline[20] = 1545782400;
        matchdayPredictionDeadline[21] = 1546041600;
        matchdayPredictionDeadline[22] = 1546300800;
        matchdayPredictionDeadline[23] = 1547251200;
        matchdayPredictionDeadline[24] = 1547856000;
        matchdayPredictionDeadline[25] = 1548806400;
        matchdayPredictionDeadline[26] = 1548892800;
        matchdayPredictionDeadline[27] = 1549065600;
        matchdayPredictionDeadline[28] = 1549670400;
        matchdayPredictionDeadline[29] = 1550880000;
        matchdayPredictionDeadline[30] = 1551225600;
        matchdayPredictionDeadline[31] = 1551312000;
        matchdayPredictionDeadline[32] = 1551484800;
        matchdayPredictionDeadline[33] = 1552089600;
        matchdayPredictionDeadline[34] = 1552694400;
        matchdayPredictionDeadline[35] = 1553904000;
        matchdayPredictionDeadline[36] = 1554508800;
        matchdayPredictionDeadline[37] = 1555113600;
        matchdayPredictionDeadline[38] = 1555718400;
        matchdayPredictionDeadline[39] = 1556323200;
        matchdayPredictionDeadline[40] = 1556928000;
        matchdayPredictionDeadline[41] = 1557014400;
 
        seasonStartGameID[1]   = 1;
        seasonStartGameID[2]   = 101;
        seasonStartGameID[3]   = 191;
        seasonStartGameID[4]   = 276;
 
        seasonEndGameID[1]     = 100;
        seasonEndGameID[2]     = 190;
        seasonEndGameID[3]     = 275;
        seasonEndGameID[4]     = 380;
 
        // Explicitly set which two digit string entries are considered valid.
        validTeamID[&quot;AR&quot;] = true;
        validTeamID[&quot;BN&quot;] = true;
        validTeamID[&quot;BR&quot;] = true;
        validTeamID[&quot;BY&quot;] = true;
        validTeamID[&quot;CD&quot;] = true;
        validTeamID[&quot;CH&quot;] = true;
        validTeamID[&quot;CP&quot;] = true;
        validTeamID[&quot;EV&quot;] = true;
        validTeamID[&quot;FL&quot;] = true;
        validTeamID[&quot;HD&quot;] = true;
        validTeamID[&quot;LE&quot;] = true;
        validTeamID[&quot;LV&quot;] = true;
        validTeamID[&quot;MC&quot;] = true;
        validTeamID[&quot;MU&quot;] = true;
        validTeamID[&quot;NC&quot;] = true;
        validTeamID[&quot;SH&quot;] = true;
        validTeamID[&quot;TH&quot;] = true;
        validTeamID[&quot;WA&quot;] = true;
        validTeamID[&quot;WH&quot;] = true;
        validTeamID[&quot;WL&quot;] = true;
        validTeamID[&quot;--&quot;] = true;
        validTeamID[&quot;XX&quot;] = true;
       
        // Adding referees to enter results in the event administrator is unavailable.
        referees[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = true; // Norsefire
        referees[0x8537aa2911b193e5B377938A723D805bb0865670] = true; // oguzhanox
        referees[0x91f24ca45c8e8Dd6e2E620A0d2aF0366dd5214f0] = true; // babagoose
       
        changeQuarterSeason(1);
 
        latestGameFinished = 0;
 
    }
 
    /* PUBLIC-FACING COMPETITION INTERACTIONS */
 
    // Register to participate in the competition. Apart from gas costs from
    //   making predictions and updating your score if necessary, this is the
    //   only Ether you will need to spend throughout the tournament.
    function registerFull()
        public
        payable
    {
        address _player = msg.sender;
        require( !playerFullRegistered[_player]
              && _isCorrectFullBuyin (msg.value));
        logNewPlayer(_player);
        playerFullRegistered[_player] = true;
        playerGamesScored[_player] = 0;
        playerFullList.push(_player);
        uint fivePercent = 0.05 ether;
        uint tenPercent  = 0.1  ether;
        uint prizeEth    = (msg.value).sub(tenPercent);
        fullPrizePool    = fullPrizePool.add(prizeEth);
        givethPool = givethPool.add(fivePercent);
        administrator.send(fivePercent);
        emit FullRegistration(_player);
    }
 
    function registerQuarterSeason(int8 _season)
        public
        payable
    {
        address _player = msg.sender;
        require(    seasonActive == _season
                && !playerCurrentlyRegistered(_player)
                && _isCorrectQuarterBuyin (msg.value));
        logNewPlayer(_player);
        playerSeasonRegistered[_season][_player] = true;
        playerGamesScored[_player] = 0;
        playerSeasonList[_season].push(_player);
        uint fivePercent = 0.0125 ether;
        uint tenPercent  = 0.025  ether;
        uint prizeEth    = (msg.value).sub(tenPercent);
        uint seasonPool = seasonPrizePool[_season];
        seasonPool  = seasonPool.add(prizeEth);
        givethPool = givethPool.add(fivePercent);
        administrator.send(fivePercent);
        hasClaimedSeasonrPrize[_season][_player] = false;
        emit SeasonRegistration(_season, _player);
    }
   
    function logNewPlayer(address _player)
        internal
    {
        if (!playerFullRegistered[_player]
            && !playerSeasonRegistered[1][_player]
            && !playerSeasonRegistered[2][_player]
            && !playerSeasonRegistered[3][_player]
            && !playerSeasonRegistered[4][_player])
        {
            registeredPlayers = SafeMath.addint256(registeredPlayers, 1);
            
        }
    }
 
    // Make a set of prediction for a matchday. Note that NOT making a prediction
    // for a particular game will be represented by XX: a result that will always fail
    // when compared against.
    function makePredictions(int16 _matchday, string _predictions)
        public
    {
        require(playerCurrentlyRegistered(msg.sender)
                && now < matchdayPredictionDeadline[_matchday]);
        setPredictions(_matchday, _predictions);
    }
 
    // What is the current score of a given tournament player?
    function showPlayerFullScores(address _player)
        view
        public
        returns (uint[380])
    {
        return playerPointArray[_player];
    }
   
    // What is the current score of a given season player?
    function showPlayerSeasonScores(address _player, int8 _season)
        view
        public
        returns (uint[100]) // Yes, not all seasons are 100 games, but this captures them all.
    {
        uint[100] memory quarterScore; // Not bothering initialising this.
        int16 startIx = SafeMath.sub16(seasonStartGameID[_season], 1);
        int16 endIx   = SafeMath.sub16(seasonEndGameID[_season], 1);
        for (int16 i = startIx; i <= endIx; i++) {
            uint j = uint(i);
            quarterScore[j] = playerPointArray[_player][j];
        }
        return quarterScore;
    }   
 
    // What was the last game ID that has had an official score registered for it?
    function gameResultsLogged()
        view
        public
        returns (int)
    {
        return latestGameFinished;
    }
   
    function calculateSubscore(address _player, int16 _startGame, int16 _endGame)
        view
        public
        returns (uint)
    {
        uint finalScore = 0;
        for (int16 i = _startGame; i <= _endGame; i++) {
            uint j = uint(i);
            uint gameScore = playerPointArray[_player][j];
            finalScore = SafeMath.add(finalScore, gameScore);
        }
        return finalScore;
       
    }
   
    function calculateSeasonScore(address _player, int8 _season)
        view
        public
        returns (uint)
    {
        int16 _startIx = SafeMath.sub16(seasonStartGameID[_season], 1);
        int16 _endIx   = SafeMath.sub16(seasonEndGameID[_season], 1);
        calculateSubscore(_player, _startIx, _endIx);
    }
 
    // Sum up the individual scores throughout the season and produce a final result.
    function calculateScore(address _player)
        view
        public
        returns (uint)
    {
        calculateSubscore(_player, 0, latestGameFinished);
    }
 
    // How many people are taking part in the game? (Unique address, either quarter or full season).
    function countParticipants()
        public
        view
        returns (int)
    {
        return registeredPlayers;
    }
 
    // Keeping this open for anyone to update anyone else so that at the end of
    // the tournament we can force a score update for everyone using a script.
    function updateScore(address _player)
        public
    {
        int16                     lastPlayed     = latestGameFinished;
        require(lastPlayed > 0);
        // Most recent game scored for this participant.
        int16                     lastScored     = playerGamesScored[_player];
        // Most recent game played in the tournament (sets bounds for scoring iteration).
        mapping (int16 => bool)   madePrediction = playerMadePrediction[_player];
        mapping (int16 => string) playerGuesses  = playerPredictions[_player];
        for (int16 i = lastScored; i < lastPlayed; i++) {
            uint j = uint(i);
            uint k = j.add(1);
            uint streak = playerStreak[_player];
            if (!madePrediction[int8(k)]) {
                playerPointArray[_player][j] = 0;
                playerStreak[_player]        = 0;
            } else {
                string storage playerResult = playerGuesses[int8(k)];
                string storage actualResult = gameResult[int8(k)];
                bool correctGuess = equalStrings(playerResult, actualResult);
                 if (!correctGuess) {
                     // The guess was wrong.
                     playerPointArray[_player][j] = 0;
                     playerStreak[_player]        = 0;
                 } else {
                     // The guess was right.
                     streak = streak.add(1);
                     playerStreak[_player] = streak;
                     if (streak >= 5) {
                         // On a long streak - four points.
                        playerPointArray[_player][j] = 4;
                     } else {
                         if (streak >= 3) {
                            // On a short streak - two points.
                            playerPointArray[_player][j] = 2;
              }
                         // Not yet at a streak - standard one point.
                         else { playerPointArray[_player][j] = 1; }
                     }
                 }
            }
        }
        playerGamesScored[_player] = lastPlayed;
    }
 
    // Which game ID has a player last computed their score up to
    //   using the updateScore function?
    function playerLastScoredGame(address _player)
        public
        view
        returns (int16)
    {
        return playerGamesScored[_player];
    }
 
    // Is a player currently registered? (i.e. either for the full season or the active quarter)
    function playerCurrentlyRegistered(address _player)
        public
        view
        returns (bool)
    {
        int8 _season = seasonActive;
        return playerFullRegistered[_player] || playerSeasonRegistered[_season][_player];
    }
 
    // What was the official result of a game?
    function correctResult(int16 _gameID)
        public
        view
        returns (string)
    {
        return gameResult[_gameID];
    }
 
    // What was the players prediction for a given game?
    function playerGuess(address _player, int16 _gameID)
        public
        view
        returns (string)
    {
        return playerPredictions[_player][_gameID];
    }

    function claimSeasonPrize(address _player, int8 _season)
        public
    {
        require(playerSeasonRegistered[_season][_player]
            && !playerFullRegistered[_player]
            && !hasClaimedSeasonrPrize[_season][_player]);
        uint playerScore = calculateSeasonScore(_player, _season);
        require(playerScore >= seasonCutoffScore[_season]);
        uint qtrScore = seasonPoolTopHalfScore[_season];
        uint winnings = SafeMath.div(playerScore, SafeMath.mul(seasonFinalPrizePool[_season], qtrScore));
        seasonPrizePool[_season] = SafeMath.sub(seasonPrizePool[_season], winnings);
        hasClaimedSeasonrPrize[_season][_player] = true;
        _player.send(winnings);
        emit WithdrawnSeasonPrize(_player, _season, winnings);
    }
    
     function claimFullPrize(address _player)
        public
    {
        require(playerFullRegistered[_player]
            && !hasClaimedFullPrize[_player]);
        uint playerScore = calculateScore(_player);
        require(playerScore >= fullCutoffScore);
        uint fullScore = fullPoolTopHalfScore;
        uint winnings = SafeMath.div(playerScore, SafeMath.mul(fullFinalPrizePool, fullScore));
        fullPrizePool = SafeMath.sub(fullPrizePool, winnings);
        hasClaimedFullPrize[_player] = true;
        _player.send(winnings);
        emit WithdrawnFullPrize(_player, winnings);
    }
 
    /* ADMINISTRATOR FUNCTIONS FOR COMPETITION MAINTENANCE */
 
    modifier isAdministrator() {
        address _sender = msg.sender;
        if (_sender == administrator) {
            _;
        } else {
            revert();
        }
    }
 
    modifier isReferee() {
        address _sender = msg.sender;
        if (referees[_sender]) {
            _;
        } else {
            revert();
        }
    }
 
    function changeQuarterSeason(int8 _season)
        isAdministrator
        public
    {
        seasonActive = _season;
        seasonScore = 0;
    }
   
    function concludeSeason(int8 _season, uint _topHalfScore, uint _qualifyingScore)
        isAdministrator
        public
    {
        seasonPoolTopHalfScore[_season] = _topHalfScore;
        seasonCutoffScore[_season]      = _qualifyingScore;
        canClaimSeasonPrize[_season]    = true;
        seasonFinalPrizePool[_season]   = seasonPrizePool[_season];
        seasonPrizePool[_season]        = 0;
        if (_season < 4) {
            int8 _nextSeason = SafeMath.addint8(_season, 1);
            changeQuarterSeason(_nextSeason);
        } else { changeQuarterSeason(0); } // Set to lock out all further registration
    }
   
    function concludeTournament(uint _topFullHalfScore, uint _qualifyingFullScore)
        isAdministrator
        public
    {
        fullPoolTopHalfScore = _topFullHalfScore;
        fullCutoffScore      = _qualifyingFullScore;
        fullFinalPrizePool   = fullPrizePool;
        fullPrizePool        = 0;
        sendToGiveth();
        canClaimFullPrize = true;
    }
    
    // When the results of a matchday are known, enter the results.
    // NOTE: parameters will read as logResults(1, &quot;AR.--.CP.--&quot;...) for a given matchday.
    // Stringutil functionality splits the input string up into an array of two character codes.
    function logMatchdayResults(int16 _matchday, string _results)
        isReferee
        public
    {
        require((int16(0) < _matchday) && (_matchday <= 41));
        int16 startIndex = matchdayStartGameID[_matchday];
        int16 numGames   = matchdayGames[_matchday];
        int16 gamesToLog = SafeMath.addint16(startIndex, numGames);
        strings.slice memory s = _results.toSlice();
        strings.slice memory delim = &quot;.&quot;.toSlice();
        for (int16 i = startIndex; i <= gamesToLog; i++){
            string memory _result = s.split(delim).toString();
            gameResult[i] = _result;
        }
        if (latestGameFinished < gamesToLog)
           { latestGameFinished = gamesToLog; }
    }
   
    // Used to override a single result in the event that one is incorrectly
    // entered. Note that this will by necessity have to move everyone&#39;s &#39;latestGameScored&#39;
    // AND their streaks back to zero so that `correct&#39; scores can be generated.
    // Ideally this function will never have to be used!
    function amendSingleResult(int16 _gameID, string _result)
        public
    {
        require((int16(0) <= _gameID) && (_gameID <= 380));
        gameResult[_gameID] = _result;
        // TODO: move everyone&#39;s ticker&#39;s back to zero
    }
 
   /* INTERNAL FUNCTIONS */
  
    function sendToGiveth()
        isAdministrator
        private
    {
        givethAddress.transfer(givethPool);
        // Reset the pooled donation balance, else we&#39;ll unbalance things.
        givethPool = 0;
    }
 
    // Gateway checks - did you send exactly the right amount?
    function _isCorrectFullBuyin(uint _buyin)
        private
        pure
        returns (bool) {
        return _buyin == 1 ether;
    }
 
    function _isCorrectQuarterBuyin(uint _buyin)
        private
        pure
        returns (bool) {
        return _buyin == 0.25 ether;
    }
 
    // Internal comparison between strings, returning 0 if equal, 1 otherwise.
    function compare(string _a, string _b)
        private
        pure
        returns (int)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
 
    function setPredictions(int16 _matchday, string massPredictions)
        internal
    {
        address _player = msg.sender;
        int16 startIndex = matchdayStartGameID[_matchday];
        int16 numGames   = matchdayGames[_matchday];
        int16 gamesToLog = SafeMath.addint16(startIndex, numGames);
        strings.slice memory s = massPredictions.toSlice();
        strings.slice memory delim = &quot;.&quot;.toSlice();
        for (int16 i = startIndex; i < gamesToLog; i++){
            string memory _prediction = s.split(delim).toString();
            require(validTeamID[_prediction]);
            playerPredictions[_player][i] = _prediction;
            emit PlayerLoggedPrediction(_player, i, _prediction);
        }
    }
 
    /// Compares two strings and returns true if and only if they are equal.
    function equalStrings(string _a, string _b) pure private returns (bool) {
        return compare(_a, _b) == 0;
    }
 
}
 
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
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
   
    function addint8(int8 a, int8 b) internal pure returns (int8) {
        int8 c = a + b;
        assert(c >= a);
        return c;
    }
 
    function addint16(int16 a, int16 b) internal pure returns (int16) {
        int16 c = a + b;
        assert(c >= a);
        return c;
    }
 
    function addint256(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        assert(c >= a);
        return c;
    }
   
    function sub16(int16 a, int16 b) internal pure returns (int16) {
        assert(b <= a);
        return a - b;
    }   
   
    function mul16(int16 a, int16 b) internal pure returns (int16) {
        if (a == 0) {
            return 0;
        }
        int16 c = a * b;
        assert(c / a == b);
        return c;
    }
}
 
library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }
 
    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }
 
        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
 
    function toSlice(string self) internal pure returns (slice) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }
 
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (self & 0xffffffffffffffffffffffffffffffff == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (self & 0xffffffffffffffff == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (self & 0xffffffff == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (self & 0xffff == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (self & 0xff == 0) {
            ret += 1;
        }
        return 32 - ret;
    }
 
    function copy(slice self) internal pure returns (slice) {
        return slice(self._len, self._ptr);
    }
 
    function toString(slice self) internal pure returns (string) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
 
        memcpy(retptr, self._ptr, self._len);
        return ret;
    }
 
    function len(slice self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }
 
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;
 
        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
 
                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }
 
                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }
 
                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
 
                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }
 
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;
 
        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
 
                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }
 
                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }
 
                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := sha3(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := sha3(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }
 
    function split(slice self, slice needle, slice token) internal pure returns (slice) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }
 
    function split(slice self, slice needle) internal pure returns (slice token) {
        split(self, needle, token);
    }
 
    function rsplit(slice self, slice needle, slice token) internal pure returns (slice) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }
 
}