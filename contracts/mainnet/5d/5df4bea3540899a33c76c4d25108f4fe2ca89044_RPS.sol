pragma solidity ^0.4.11;

contract RPS {
    enum State { Unrealized, Created, Joined, Ended }
    enum Result { Unfinished, Draw, Win, Loss, Forfeit } // From the perspective of player 1
    struct Game {
        address player1;
        address player2;
        uint value;
        bytes32 hiddenMove1;
        uint8 move1; // 0 = not set, 1 = Rock, 2 = Paper, 3 = Scissors
        uint8 move2;
        uint gameStart;
        State state;
        Result result;
    }
    
    address public owner1;
    address public owner2;
    uint8 constant feeDivisor = 100;
    uint constant revealTime = 7 days; // TODO: dynamic reveal times?
    bool paused;
    bool expired;
    uint gameIdCounter;
    
    uint constant minimumNameLength = 1;
    uint constant maximumNameLength = 25;
    
    event NewName(address indexed player, string name);
    event Donate(address indexed player, uint amount);
    event Deposit(address indexed player, uint amount);
    event Withdraw(address indexed player, uint amount);
    event GameCreated(address indexed player1, address indexed player2, uint indexed gameId, uint value, bytes32 hiddenMove1);
    event GameJoined(address indexed player1, address indexed player2, uint indexed gameId, uint value, uint8 move2, uint gameStart);
    event GameEnded(address indexed player1, address indexed player2, uint indexed gameId, uint value, Result result);
    
    mapping(address => uint) public balances;
    mapping(address => uint) public totalWon;
    mapping(address => uint) public totalLost;
    
    Game [] public games;
    mapping(address => string) public playerNames;
    mapping(uint => bool) public nameTaken;
    mapping(bytes32 => bool) public secretTaken;
    
    modifier onlyOwner { require(msg.sender == owner1 || msg.sender == owner2); _; }
    modifier notPaused { require(!paused); _; }
    modifier notExpired { require(!expired); _; }
    

    function RPS(address otherOwner) {
        owner1 = msg.sender;
        owner2 = otherOwner;
        paused = true;
    }
    
    // UTILIY FUNCTIONS
    //
    // FOR DOING BORING REPETITIVE TASKS
    
    function getGames() constant internal returns (Game []) {
        return games;
    }
    
    function totalProfit(address player) constant returns (int) {
        if (totalLost[player] > totalWon[player]) {
            return -int(totalLost[player] - totalWon[player]);
        }
        else {
            return int(totalWon[player] - totalLost[player]);
        }
    }
    // Fuzzy hash and name validation taken from King of the Ether Throne
    // https://github.com/kieranelby/KingOfTheEtherThrone/blob/v1.0/contracts/KingOfTheEtherThrone.sol
    
    function computeNameFuzzyHash(string _name) constant internal
    returns (uint fuzzyHash) {
        bytes memory nameBytes = bytes(_name);
        uint h = 0;
        uint len = nameBytes.length;
        if (len > maximumNameLength) {
            len = maximumNameLength;
        }
        for (uint i = 0; i < len; i++) {
            uint mul = 128;
            byte b = nameBytes[i];
            uint ub = uint(b);
            if (b >= 48 && b <= 57) {
                // 0-9
                h = h * mul + ub;
            } else if (b >= 65 && b <= 90) {
                // A-Z
                h = h * mul + ub;
            } else if (b >= 97 && b <= 122) {
                // fold a-z to A-Z
                uint upper = ub - 32;
                h = h * mul + upper;
            } else {
                // ignore others
            }
        }
        return h;
    }
    /// @return True if-and-only-if `_name_` meets the criteria
    /// below, or false otherwise:
    ///   - no fewer than 1 character
    ///   - no more than 25 characters
    ///   - no characters other than:
    ///     - "roman" alphabet letters (A-Z and a-z)
    ///     - western digits (0-9)
    ///     - "safe" punctuation: ! ( ) - . _ SPACE
    ///   - at least one non-punctuation character
    /// Note that we deliberately exclude characters which may cause
    /// security problems for websites and databases if escaping is
    /// not performed correctly, such as < > " and &#39;.
    /// Apologies for the lack of non-English language support.
    function validateNameInternal(string _name) constant internal
    returns (bool allowed) {
        bytes memory nameBytes = bytes(_name);
        uint lengthBytes = nameBytes.length;
        if (lengthBytes < minimumNameLength ||
            lengthBytes > maximumNameLength) {
            return false;
        }
        bool foundNonPunctuation = false;
        for (uint i = 0; i < lengthBytes; i++) {
            byte b = nameBytes[i];
            if (
                (b >= 48 && b <= 57) || // 0 - 9
                (b >= 65 && b <= 90) || // A - Z
                (b >= 97 && b <= 122)   // a - z
            ) {
                foundNonPunctuation = true;
                continue;
            }
            if (
                b == 32 || // space
                b == 33 || // !
                b == 40 || // (
                b == 41 || // )
                b == 45 || // -
                b == 46 || // .
                b == 95    // _
            ) {
                continue;
            }
            return false;
        }
        return foundNonPunctuation;
    }
    
    
    /// if you want to donate, please use the donate function
    function() { require(false); }
    
    // PLAYER FUNCTIONS
    //
    // FOR PLAYERS
    
    /// Name must only include upper and lowercase English letters,
    /// numbers, and certain characters: ! ( ) - . _ SPACE
    /// Function will return false if the name is not valid
    /// or if it&#39;s too similar to a name that&#39;s already taken.
    function setName(string name) returns (bool success) {
        require (validateNameInternal(name));
        uint fuzzyHash = computeNameFuzzyHash(name);
        uint oldFuzzyHash;
        string storage oldName = playerNames[msg.sender];
        bool oldNameEmpty = bytes(oldName).length == 0;
        if (nameTaken[fuzzyHash]) {
            require(!oldNameEmpty);
            oldFuzzyHash = computeNameFuzzyHash(oldName);
            require(fuzzyHash == oldFuzzyHash);
        }
        else {
            if (!oldNameEmpty) {
                oldFuzzyHash = computeNameFuzzyHash(oldName);
                nameTaken[oldFuzzyHash] = false;
            }
            nameTaken[fuzzyHash] = true;
        }
        playerNames[msg.sender] = name;

        NewName(msg.sender, name);
        return true;
    }
    
    //{
    /// Create a game that may be joined only by the address provided.
    /// If no address is provided, the game is open to anyone.
    /// Your bet is equal to the value sent together
    /// with this transaction. If the game is a draw,
    /// your bet will be available for withdrawal.
    /// If you win, both bets minus the fee will be send to you.
    /// The first argument should be the number
    /// of your move (rock: 1, paper: 2, scissors: 3)
    /// encrypted with keccak256(uint move, string secret) and
    /// save the secret so you can reveal your move
    /// after your game is joined.
    /// It&#39;s very easy to mess up the padding and stuff,
    /// so you should just use the website.
    //}
    function createGame(bytes32 move, uint val, address player2)
    payable notPaused notExpired returns (uint gameId) {
        deposit();
        require(balances[msg.sender] >= val);
        require(!secretTaken[move]);
        secretTaken[move] = true;
        balances[msg.sender] -= val;
        gameId = gameIdCounter;
        games.push(Game(msg.sender, player2, val, move, 0, 0, 0, State.Created, Result(0)));

        GameCreated(msg.sender, player2, gameId, val, move);
        gameIdCounter++;
    }
    
    function abortGame(uint gameId) notPaused returns (bool success) {
        Game storage thisGame = games[gameId];
        require(thisGame.player1 == msg.sender);
        require(thisGame.state == State.Created);
        thisGame.state = State.Ended;

        GameEnded(thisGame.player1, thisGame.player2, gameId, thisGame.value, Result(0));

        msg.sender.transfer(thisGame.value);
        return true;
    }
    
    function joinGame(uint gameId, uint8 move) payable notPaused returns (bool success) {
        Game storage thisGame = games[gameId];
        require(thisGame.state == State.Created);
        require(move > 0 && move <= 3);
        if (thisGame.player2 == 0x0) {
            thisGame.player2 = msg.sender;
        }
        else {
            require(thisGame.player2 == msg.sender);
        }
        require(thisGame.value == msg.value);
        thisGame.gameStart = now;
        thisGame.state = State.Joined;
        thisGame.move2 = move;

        GameJoined(thisGame.player1, thisGame.player2, gameId, thisGame.value, thisGame.move2, thisGame.gameStart);
        return true;
    }
    
    function revealMove(uint gameId, uint8 move, string secret) notPaused returns (Result result) {
        Game storage thisGame = games[gameId];
        require(thisGame.state == State.Joined);
        require(thisGame.player1 == msg.sender);
        require(thisGame.gameStart + revealTime >= now); // It&#39;s not too late to reveal
        require(thisGame.hiddenMove1 == keccak256(uint(move), secret));
        thisGame.move1 = move;
        if (move > 0 && move <= 3) {
            result = Result(((3 + move - thisGame.move2) % 3) + 1); // It works trust me (it&#39;s &#39;cause of math)
        }
        else { // Player 1 submitted invalid move
            result = Result.Loss;
        }
        thisGame.state = State.Ended;
        address winner;
        if (result == Result.Draw) {
            balances[thisGame.player1] += thisGame.value;
            balances[thisGame.player2] += thisGame.value;
        }
        else {
            if (result == Result.Win) {
                winner = thisGame.player1;
                totalLost[thisGame.player2] += thisGame.value;
            }
            else {
                winner = thisGame.player2;
                totalLost[thisGame.player1] += thisGame.value;
            }
            uint fee = (thisGame.value) / feeDivisor; // 0.5% fee taken once for each owner
            balances[owner1] += fee;
            balances[owner2] += fee;
            totalWon[winner] += thisGame.value - fee*2;
            // No re-entrancy attack is possible because
            // the state has already been set to State.Ended
            winner.transfer((thisGame.value*2) - fee*2);
        }
        thisGame.result = result;

        GameEnded(thisGame.player1, thisGame.player2, gameId, thisGame.value, result);
    }
    
    /// Use this when you know you&#39;ve lost as player 1 and
    /// you don&#39;t want to bother with revealing your move.
    function forfeitGame(uint gameId) notPaused returns (bool success) {
        Game storage thisGame = games[gameId];
        require(thisGame.state == State.Joined);
        require(thisGame.player1 == msg.sender);
        
        uint fee = (thisGame.value) / feeDivisor; // 0.5% fee taken once for each owner
        balances[owner1] += fee;
        balances[owner2] += fee;
        totalLost[thisGame.player1] += thisGame.value;
        totalWon[thisGame.player2] += thisGame.value - fee*2;
        thisGame.state = State.Ended;
        thisGame.result = Result.Forfeit; // Loss for player 1

        GameEnded(thisGame.player1, thisGame.player2, gameId, thisGame.value, thisGame.result);
        
        thisGame.player2.transfer((thisGame.value*2) - fee*2);
        return true;
    }
    
    function claimGame(uint gameId) notPaused returns (bool success) {
        Game storage thisGame = games[gameId];
        require(thisGame.state == State.Joined);
        require(thisGame.player2 == msg.sender);
        require(thisGame.gameStart + revealTime < now); // Player 1 has failed to reveal in time
        
        uint fee = (thisGame.value) / feeDivisor; // 0.5% fee taken once for each owner
        balances[owner1] += fee;
        balances[owner2] += fee;
        totalLost[thisGame.player1] += thisGame.value;
        totalWon[thisGame.player2] += thisGame.value - fee*2;
        thisGame.state = State.Ended;
        thisGame.result = Result.Forfeit; // Loss for player 1
        
        GameEnded(thisGame.player1, thisGame.player2, gameId, thisGame.value, thisGame.result);

        thisGame.player2.transfer((thisGame.value*2) - fee*2);
        return true;
    }
    
    // FUNDING FUNCTIONS
    //
    // FOR FUNDING
    function donate() payable returns (bool success) {
        require(msg.value != 0);
        balances[owner1] += msg.value/2;
        balances[owner2] += msg.value - msg.value/2;

        Donate(msg.sender, msg.value);
        return true;
    }
    function deposit() payable returns (bool success) {
        require(msg.value != 0);
        balances[msg.sender] += msg.value;

        Deposit(msg.sender, msg.value);
        return true;
    }
    function withdraw() returns (bool success) {
        uint amount = balances[msg.sender];
        if (amount == 0) return false;
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);

        Withdraw(msg.sender, amount);
        return true;
    }
    
    // ADMIN FUNCTIONS
    //
    // FOR ADMINISTRATING
    
    // Pause all gameplay
    function pause(bool pause) onlyOwner {
        paused = pause;
    }
    
    // Prevent new games from being created
    // To be used when switching to a new contract
    function expire(bool expire) onlyOwner {
        expired = expire;
    }
    
    function setOwner1(address newOwner) {
        require(msg.sender == owner1);
        owner1 = newOwner;
    }
    
    function setOwner2(address newOwner) {
        require(msg.sender == owner2);
        owner2 = newOwner;
    }
    
}