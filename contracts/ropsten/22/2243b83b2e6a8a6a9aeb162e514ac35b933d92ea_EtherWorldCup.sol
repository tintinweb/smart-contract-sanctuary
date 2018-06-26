pragma solidity ^0.4.24;

/*

ETHEREUM WORLD CUP : 14th June - 15th July 2018 [Russia]
    - designed and implemented by Norsefire.

Rules are as follows:
    * Entry to the game costs 0.2018 Ether. Sending exactly 0.2018 Ether to the contract is sufficient.
        - Any larger or smaller amount of Ether, will be rejected.
    * 90% of the entry fee will go towards the prize fund, with 10% forming a developer fee.
        The entry fee is the only Ether you will need to send for the duration of the 
        tournament, barring the gas you spend for placing predictions.
    * Buying an entry allows the sender to place predictions on each game in the World Cup,
        barring those which have already kicked off prior to the time a participant enters.
    * Predictions can be made at any point up until midnight in UTC on the day of the game.
        This prevents predictions from being made mid-game.
    * Selecting the correct result for any given game awards the player one point.
        In the first stage, a participant can also select a draw. This is not available from the RO16 onwards.
    * If a participant reaches a streak of three or more correct predictions in a row, they receive two points
        for every correct prediction from the third game until the streak is broken.
    * If a participant reaches a streak of *five* or more correct predictions in a row, they receive four points
        for every correct prediction from the fifth game until the streak is broken.
    * In the event of a tie, the following algorithm is used to decide rankings:
        - Compare the sum totals of the scores over the last 32 games.
        - If this produces a draw as well, compare results of the last 16 games.
        - This repeats until comparing the results of the final.
        - If it&#39;s a dead heat throughout, a contract using an off-chain call will &#39;draw lots&#39;.
        
Prizes:
    FIRST  PLACE: 40% of Ether contained within the pot.
    SECOND PLACE: 30% of Ether contained within the pot.
    THIRD  PLACE: 20% of Ether contained within the pot.
    FOURTH PLACE: 10% of Ether contained within the pot.
    
Participant Teams and Groups:

[Group D] AR - Argentina
[Group C] AU - Australia
[Group G] BE - Belgium
[Group E] BR - Brazil
[Group E] CH - Switzerland
[Group H] CO - Colombia
[Group E] CR - Costa Rica
[Group E] CS - Serbia
[Group F] DE - Germany
[Group C] DK - Denmark
[Group A] EG - Egypt
[Group G] EN - England
[Group B] ES - Spain
[Group C] FR - France
[Group D] HR - Croatia
[Group B] IR - Iran
[Group D] IS - Iceland
[Group H] JP - Japan
[Group F] KR - Republic of Korea
[Group B] MA - Morocco
[Group F] MX - Mexico
[Group D] NG - Nigeria
[Group G] PA - Panama
[Group C] PE - Peru
[Group H] PL - Poland
[Group B] PT - Portugal
[Group A] RU - Russia
[Group A] SA - Saudi Arabia
[Group F] SE - Sweden
[Group H] SN - Senegal
[Group G] TN - Tunisia
[Group A] UY - Uruguay

*/

contract EtherWorldCup {
    using SafeMath for uint;
    
    /* CONSTANTS */

    address internal constant administrator = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;

    string name   = &quot;EtherWorldCup&quot;;
    string symbol = &quot;EWC&quot;;
    
    /* VARIABLES */
    
    mapping (string =>  int8)                     worldCupGameID;
    mapping (int8   =>  bool)                     gameFinished;
    // Is a game no longer available for predictions to be made?
    mapping (int8   =>  uint)                     gameLocked;
    // A result is either the two digit code of a country, or the word &quot;DRAW&quot;.
    // Country codes are listed above.
    mapping (int8   =>  string)                   gameResult;
    int8 internal                                 latestGameFinished;
    uint internal                                 prizePool;
    int                                           registeredPlayers;
 
    mapping (address => bool)                     disqualifiedPlayers;
    mapping (address => bool)                     playerRegistered;
    mapping (address => mapping (int8 => bool))   playerMadePrediction;
    mapping (address => mapping (int8 => string)) playerPredictions;
    mapping (address => int8[64])                 playerPointArray;
    mapping (address => int8)                     playerGamesScored;
    mapping (address => uint)                     playerStreak;

    /* DEBUG EVENTS */
    
    event Registration(
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
    
    event Comparison(
        address _player,
        uint    _gameID,
        string  _myGuess,
        string  _result,
        bool    _correct
    );
    
    event PlayerPointGain(
        address _player,
        uint _gameID,
        uint _points
    );
    
    event StartScoring(
        address _player,
        uint    _gameID
    );
    
    event DidNotPredict(
        address _player,
        uint    _gameID
    );
    
    /* CONSTRUCTOR */
    
    constructor ()
        public
    {
        // First stage games: these are known in advance.
        
        // Thursday 14th June, 2018
        worldCupGameID[&quot;RU-SA&quot;] = 1;   // Russia       vs Saudi Arabia
        gameLocked[1]           = 1528988400;
        
        // Friday 15th June, 2018
        worldCupGameID[&quot;EG-UY&quot;] = 2;   // Egypt        vs Uruguay
        worldCupGameID[&quot;MA-IR&quot;] = 3;   // Morocco      vs Iran
        worldCupGameID[&quot;PT-ES&quot;] = 4;   // Portugal     vs Spain
        gameLocked[2]           = 1529064000;
        gameLocked[3]           = 1529074800;
        gameLocked[4]           = 1529085600;
        
        // Saturday 16th June, 2018
        worldCupGameID[&quot;FR-AU&quot;] = 5;   // France       vs Australia
        worldCupGameID[&quot;AR-IS&quot;] = 6;   // Argentina    vs Iceland
        worldCupGameID[&quot;PE-DK&quot;] = 7;   // Peru         vs Denmark
        worldCupGameID[&quot;HR-NG&quot;] = 8;   // Croatia      vs Nigeria
        gameLocked[5]           = 1529143200;
        gameLocked[6]           = 1529154000;
        gameLocked[7]           = 1529164800;
        gameLocked[8]           = 1529175600;
        
        // Sunday 17th June, 2018
        worldCupGameID[&quot;CR-CS&quot;] = 9;   // Costa Rica   vs Serbia
        worldCupGameID[&quot;DE-MX&quot;] = 10;  // Germany      vs Mexico
        worldCupGameID[&quot;BR-CH&quot;] = 11;  // Brazil       vs Switzerland
        gameLocked[9]           = 1529236800;
        gameLocked[10]          = 1529247600;
        gameLocked[11]          = 1529258400;
        
        // Monday 18th June, 2018
        worldCupGameID[&quot;SE-KR&quot;] = 12;  // Sweden       vs Korea
        worldCupGameID[&quot;BE-PA&quot;] = 13;  // Belgium      vs Panama
        worldCupGameID[&quot;TN-EN&quot;] = 14;  // Tunisia      vs England
        gameLocked[12]          = 1529323200;
        gameLocked[13]          = 1529334000;
        gameLocked[14]          = 1529344800;
        
        // Tuesday 19th June, 2018
        worldCupGameID[&quot;CO-JP&quot;] = 15;  // Colombia     vs Japan
        worldCupGameID[&quot;PL-SN&quot;] = 16;  // Poland       vs Senegal
        worldCupGameID[&quot;RU-EG&quot;] = 17;  // Russia       vs Egypt
        gameLocked[15]          = 1529409600;
        gameLocked[16]          = 1529420400;
        gameLocked[17]          = 1529431200;
        
        // Wednesday 20th June, 2018
        worldCupGameID[&quot;PT-MA&quot;] = 18;  // Portugal     vs Morocco
        worldCupGameID[&quot;UR-SA&quot;] = 19;  // Uruguay      vs Saudi Arabia
        worldCupGameID[&quot;IR-ES&quot;] = 20;  // Iran         vs Spain
        gameLocked[18]          = 1529496000;
        gameLocked[19]          = 1529506800;
        gameLocked[20]          = 1529517600;
        
        // Thursday 21st June, 2018
        worldCupGameID[&quot;DK-AU&quot;] = 21;  // Denmark      vs Australia
        worldCupGameID[&quot;FR-PE&quot;] = 22;  // France       vs Peru
        worldCupGameID[&quot;AR-HR&quot;] = 23;  // Argentina    vs Croatia
        gameLocked[21]          = 1529582400;
        gameLocked[22]          = 1529593200;
        gameLocked[23]          = 1529604000;
        
        // Friday 22nd June, 2018
        worldCupGameID[&quot;BR-CR&quot;] = 24;  // Brazil       vs Costa Rica
        worldCupGameID[&quot;NG-IS&quot;] = 25;  // Nigeria      vs Iceland
        worldCupGameID[&quot;CS-CH&quot;] = 26;  // Serbia       vs Switzerland
        gameLocked[24]          = 1529668800;
        gameLocked[25]          = 1529679600;
        gameLocked[26]          = 1529690400;
        
        // Saturday 23rd June, 2018
        worldCupGameID[&quot;BE-TN&quot;] = 27;  // Belgium      vs Tunisia
        worldCupGameID[&quot;KR-MX&quot;] = 28;  // Korea        vs Mexico
        worldCupGameID[&quot;DE-SE&quot;] = 29;  // Germany      vs Sweden
        gameLocked[27]          = 1529755200;
        gameLocked[28]          = 1529766000;
        gameLocked[29]          = 1529776800;
        
        // Sunday 24th June, 2018
        worldCupGameID[&quot;EN-PA&quot;] = 30;  // England      vs Panama
        worldCupGameID[&quot;JP-SN&quot;] = 31;  // Japan        vs Senegal
        worldCupGameID[&quot;PL-CO&quot;] = 32;  // Poland       vs Colombia
        gameLocked[30]          = 1529841600;
        gameLocked[31]          = 1529852400;
        gameLocked[32]          = 1529863200;
        
        // Monday 25th June, 2018
        worldCupGameID[&quot;UR-RU&quot;] = 33;  // Uruguay      vs Russia
        worldCupGameID[&quot;SA-EG&quot;] = 34;  // Saudi Arabia vs Egypt
        worldCupGameID[&quot;ES-MA&quot;] = 35;  // Spain        vs Morocco
        worldCupGameID[&quot;IR-PT&quot;] = 36;  // Iran         vs Portugal
        gameLocked[33]          = 1529935200;
        gameLocked[34]          = 1529935200;
        gameLocked[35]          = 1529949600;
        gameLocked[36]          = 1529949600;
        
        // Tuesday 26th June, 2018
        worldCupGameID[&quot;AU-PE&quot;] = 37;  // Australia    vs Peru
        worldCupGameID[&quot;DK-FR&quot;] = 38;  // Denmark      vs France
        worldCupGameID[&quot;NG-AR&quot;] = 39;  // Nigeria      vs Argentina
        worldCupGameID[&quot;IS-HR&quot;] = 40;  // Iceland      vs Croatia
        gameLocked[37]          = 1530021600;
        gameLocked[38]          = 1530021600;
        gameLocked[39]          = 1530036000;
        gameLocked[40]          = 1530036000;
        
        // Wednesday 27th June, 2018
        worldCupGameID[&quot;MX-SE&quot;] = 41;  // Mexico       vs Sweden
        worldCupGameID[&quot;KR-DE&quot;] = 42;  // Korea        vs Germany
        worldCupGameID[&quot;CS-BR&quot;] = 43;  // Serbia       vs Brazil
        worldCupGameID[&quot;CH-CR&quot;] = 44;  // Switzerland  vs Costa Rica
        gameLocked[41]          = 1530108000;
        gameLocked[42]          = 1530108000;
        gameLocked[43]          = 1530122400;
        gameLocked[44]          = 1530122400;
        
        // Thursday 28th June, 2018
        worldCupGameID[&quot;JP-PL&quot;] = 45;  // Japan        vs Poland
        worldCupGameID[&quot;SN-CO&quot;] = 46;  // Senegal      vs Colombia
        worldCupGameID[&quot;PA-TN&quot;] = 47;  // Panama       vs Tunisia
        worldCupGameID[&quot;EN-BE&quot;] = 48;  // England      vs Belgium
        gameLocked[45]          = 1530194400;
        gameLocked[46]          = 1530194400;
        gameLocked[47]          = 1530208800;
        gameLocked[48]          = 1530208800;
        
        // Second stage games and onwards. The string values for these will be overwritten
        //   as the tournament progresses. This is the order that will be followed for the
        //   purposes of calculating winning streaks, as per the World Cup website.
        
        // Round of 16
        // Saturday 30th June, 2018
        worldCupGameID[&quot;1C-2D&quot;]   = 49;  // 1C         vs 2D
        worldCupGameID[&quot;1A-2B&quot;]   = 50;  // 1A         vs 2B
        gameLocked[49]            = 1530367200;
        gameLocked[50]            = 1530381600;
        
        // Sunday 1st July, 2018
        worldCupGameID[&quot;1B-2A&quot;]   = 51;  // 1B         vs 2A
        worldCupGameID[&quot;1D-2C&quot;]   = 52;  // 1D         vs 2C
        gameLocked[51]            = 1530453600;
        gameLocked[52]            = 1530468000;
        
        // Monday 2nd July, 2018
        worldCupGameID[&quot;1E-2F&quot;]   = 53;  // 1E         vs 2F
        worldCupGameID[&quot;1G-2H&quot;]   = 54;  // 1G         vs 2H
        gameLocked[53]            = 1530540000;
        gameLocked[54]            = 1530554400;
        
        // Tuesday 3rd July, 2018
        worldCupGameID[&quot;1F-2E&quot;]   = 55;  // 1F         vs 2E
        worldCupGameID[&quot;1H-2G&quot;]   = 56;  // 1H         vs 2G
        gameLocked[55]            = 1530626400;
        gameLocked[56]            = 1530640800;
        
        // Quarter Finals
        // Friday 6th July, 2018
        worldCupGameID[&quot;W49-W50&quot;] = 57; // W49         vs W50
        worldCupGameID[&quot;W53-W54&quot;] = 58; // W53         vs W54
        gameLocked[57]            = 1530885600;
        gameLocked[58]            = 1530900000;
        
        // Saturday 7th July, 2018
        worldCupGameID[&quot;W55-W56&quot;] = 59; // W55         vs W56
        worldCupGameID[&quot;W51-W52&quot;] = 60; // W51         vs W52
        gameLocked[59]            = 1530972000;
        gameLocked[60]            = 1530986400;
        
        // Semi Finals
        // Tuesday 10th July, 2018
        worldCupGameID[&quot;W57-W58&quot;] = 61; // W57         vs W58
        gameLocked[61]            = 1531245600;
        
        // Wednesday 11th July, 2018
        worldCupGameID[&quot;W59-W60&quot;] = 62; // W59         vs W60
        gameLocked[62]            = 1531332000;
        
        // Third Place Playoff
        // Saturday 14th July, 2018
        worldCupGameID[&quot;L61-L62&quot;] = 63; // L61         vs L62
        gameLocked[63]            = 1531576800;
        
        // Grand Final
        // Sunday 15th July, 2018
        worldCupGameID[&quot;W61-W62&quot;] = 64; // W61         vs W62
        gameLocked[64]            = 1531666800;
        
        // Set initial variables.
        latestGameFinished = 0;
        
    }
    
    /* PUBLIC-FACING COMPETITION INTERACTIONS */

    function register()
        public
        payable
    {
        address _customerAddress = msg.sender;
        require(   tx.origin == _customerAddress
                && !playerRegistered[_customerAddress]
                && _isCorrectBuyin (msg.value));
        // Initialise the results and predictions for every game.
        for (int8 i = 0; i < 64; i++) {
            uint j = uint(i);
            playerPointArray[_customerAddress][j]  = 0;
            playerPredictions[_customerAddress][i] = &quot;&quot;;
        }
        registeredPlayers = SafeMath.addint256(registeredPlayers, 1);
        playerRegistered[_customerAddress] = true;
        uint devFee    = 0.02018 ether;
        uint prizeEth  = msg.value - devFee;
        require(playerRegistered[_customerAddress]);
        administrator.send(devFee);
        prizePool = SafeMath.add(prizePool, prizeEth);
        emit Registration(_customerAddress);
    }
    
    function makePrediction(int8 _gameID, string _prediction) 
        public {
        address _customerAddress             = msg.sender;
        uint    predictionTime               = now;
        require(playerRegistered[_customerAddress] 
                && !disqualifiedPlayers[_customerAddress]
                && !gameFinished[_gameID]
                && predictionTime < gameLocked[_gameID]);
        // No draws allowed after the qualification stage.
        if (_gameID > 48 && equalStrings(_prediction, &quot;DRAW&quot;)) {
            revert();
        } else {
            playerPredictions[_customerAddress][_gameID]    = _prediction;
            playerMadePrediction[_customerAddress][_gameID] = true;
            emit PlayerLoggedPrediction(_customerAddress, _gameID, _prediction);
        }
    }
    
    function showPlayerScores(address _participant)
        view
        public
        returns (int8[64])
    {
        return playerPointArray[_participant];
    }
    
    function gameResultsLogged()
        view
        public
        returns (int)
    {
        return latestGameFinished;
    }
    
    function calculateScore(address _participant)
        view
        public
        returns (int16)
    {
        int16 finalScore = 0;
        for (int8 i = 0; i < latestGameFinished; i++) {
            uint j = uint(i);
            int16 gameScore = playerPointArray[_participant][j];
            finalScore = SafeMath.addint16(finalScore, gameScore);
        }
        return finalScore;
    }
    
    function countParticipants()
        public
        view
        returns (int) 
    {
        return registeredPlayers;
    }
    
    // Keeping this open for anyone to update anyone else so that at the end of
    // the tournament we can force a score update for everyone using a script.
    function updateScore(address _participant) 
        public 
    {
        int8                     lastPlayed     = latestGameFinished;
        require(!disqualifiedPlayers[_participant]
             && lastPlayed > 0);
        // Most recent game scored for this participant.
        int8                     lastScored     = playerGamesScored[_participant];
        // Most recent game played in the tournament (sets bounds for scoring iteration).
        mapping (int8 => bool)   madePrediction = playerMadePrediction[_participant];
        uint                     streak         = playerStreak[_participant];
        mapping (int8 => string) playerGuesses  = playerPredictions[_participant];
        for (int8 i = lastScored; i < lastPlayed; i++) {
            uint j = uint(i);
            uint k = j.add(1);
            emit StartScoring(_participant, k);
            if (!madePrediction[int8(k)]) {
                playerPointArray[_participant][k] = 0;
                playerStreak[_participant]        = 0;
                emit DidNotPredict(_participant, k);
            } else {
                string storage playerResult = playerGuesses[int8(k)];
                string storage actualResult = gameResult[int8(k)];
                bool correctGuess = equalStrings(playerResult, actualResult);
                emit Comparison(_participant, k, playerResult, actualResult, correctGuess);
                 if (!correctGuess) {
                     // The guess was wrong.
                     playerPointArray[_participant][j] = 0;
                     playerStreak[_participant]        = 0;
                     emit PlayerPointGain(_participant, k, 0);
                 } else {
                     // The guess was right.
                     streak = SafeMath.add(streak, 1);
                     playerStreak[_participant] = streak;
                     if (streak >= 5) {
                         // On a long streak - four points.
                        playerPointArray[_participant][j] = 4;
                        emit PlayerPointGain(_participant, k, 4);
                     } else {
                         if (streak >= 3) {
                            // On a short streak - two points.
                            playerPointArray[_participant][j] = 2;
                            emit PlayerPointGain(_participant, k, 2);
              }
                         // Not yet at a streak - standard one point.
                         else { playerPointArray[_participant][j] = 1;
                                emit PlayerPointGain(_participant, k, 1);
                              }
                     }
                 }
            }
        }
        playerGamesScored[_participant] = lastPlayed;
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

    // As new fixtures become known through progression or elimination, they&#39;re added here.
    function addNewGame(string _opponents, int8 _gameID)
        isAdministrator
        public {
            worldCupGameID[_opponents] = _gameID;
    }

    // When the result of a game is known, enter the result.
    function logResult(int8 _gameID, string _winner) 
        isAdministrator
        public {
        require((int8(0) < _gameID) && (_gameID <= 64)
             && _gameID == latestGameFinished + 1);
        // No draws allowed after the qualification stage.
        if (_gameID > 48 && equalStrings(_winner, &quot;DRAW&quot;)) {
            revert();
        } else {
            require(!gameFinished[_gameID]);
            gameFinished [_gameID] = true;
            gameResult   [_gameID] = _winner;
            latestGameFinished     = _gameID;
            assert(gameFinished[_gameID]);
        }
    }
    
    // Concludes the tournament and issues the prizes, then self-destructs.
    function concludeTournament(address _first   // 40% Ether.
                              , address _second  // 30% Ether.
                              , address _third   // 20% Ether.
                              , address _fourth) // 10% Ether.
        isAdministrator
        public 
    {
        // Don&#39;t hand out prizes until the final&#39;s... actually been played.
        require(gameFinished[64]);
        // Also ensure that all addresses are registered and that their scores are
        // in descending order.
        uint potEther = prizePool;
        uint tenth    = SafeMath.div(potEther, 10);
        _first.send (SafeMath.mul(tenth, 4));
        _second.send(SafeMath.mul(tenth, 3));
        _third.send (SafeMath.mul(tenth, 2));
        _fourth.send(tenth);
        // Thanks for playing, everyone.
        selfdestruct(administrator);
    }

    // I hope to never have to use this. I can&#39;t imagine a situation where
    //   I would have to, thankfully. Even so, better safe than sorry.
    function disqualify(address _toRemove) 
        isAdministrator
        public {
            disqualifiedPlayers [_toRemove] = true;
    }
   
   /* INTERNAL FUNCTIONS */
   
    function _isCorrectBuyin(uint _buyin) 
        private
        pure
        returns (bool) {
        return _buyin == 0.2018 ether;
    }
    
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
}