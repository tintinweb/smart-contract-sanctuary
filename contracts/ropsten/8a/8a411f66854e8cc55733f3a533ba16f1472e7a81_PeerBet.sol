pragma solidity ^0.4.24;

contract PeerBet {
    enum GameStatus { Open, Locked, Scored, Verified }
    // BookType.None exists because parsing a log index for a value of 0 
    // returns all values. It should not be used.
    enum BookType { None, Spread, MoneyLine, OverUnder }
    enum BetStatus { Open, Paid }

    // indexing on a string causes issues with web3, so category has to be an int
    event GameCreated(bytes32 indexed id, address indexed creator, string home, 
        string away, uint16 indexed category, uint64 locktime);
    event BidPlaced(bytes32 indexed game_id, BookType book, 
        address bidder, uint amount, bool home, int32 line);
    event BetPlaced(bytes32 indexed game_id, BookType indexed book, 
        address indexed user, bool home, uint amount, int32 line);
    event GameScored(bytes32 indexed game_id, int homeScore, int awayScore, uint timestamp);
    event GameVerified(bytes32 indexed game_id);
    event Withdrawal(address indexed user, uint amount, uint timestamp);

    struct Bid {
        address bidder;
        uint amount; /* in wei */
        bool home; /* true=home, false=away */
        int32 line;
    }

    struct Bet {
        address home;
        address away;
        uint amount; /* in wei */
        int32 line;
        BetStatus status;
    }

    struct Book {
        Bid[] homeBids;
        Bid[] awayBids;
        Bet[] bets;
    }

    struct GameResult {
        int home;
        int away;
        uint timestamp; // when the game was scored
    }

    struct Game {
        bytes32 id;
        address creator;
        string home;
        string away;
        uint16 category;
        uint64 locktime;
        GameStatus status;
        mapping(uint => Book) books;
        GameResult result;
    }

    address public owner;
    Game[] games;
    mapping(address => uint) public balances;

    function PeerBetting() public {
        owner = msg.sender;
    }

	function createGame (string home, string away, uint16 category, uint64 locktime) public returns (int) {
        bytes32 id = getGameId(msg.sender, home, away, category, locktime);
        Game memory game = Game(id, msg.sender, home, away, category, locktime, GameStatus.Open, GameResult(0,0,0));
        games.push(game);
        GameCreated(id, game.creator, home, away, category, locktime);
        return -1;
    }
    
    function cancelOpenBids(Book storage book) private returns (int) {
        for (uint i=0; i < book.homeBids.length; i++) {
            Bid bid = book.homeBids[i];
            if (bid.amount == 0)
                continue;
            balances[bid.bidder] += bid.amount;
        }
        delete book.homeBids;
        for (i=0; i < book.awayBids.length; i++) {
            bid = book.awayBids[i];
            if (bid.amount == 0)
                continue;
            balances[bid.bidder] += bid.amount;
        }
        delete book.awayBids;

        return -1;
    }

    function cancelBets(Book storage book, BookType book_type) private returns (int) {
        for (uint i=0; i < book.bets.length; i++) {
            Bet bet = book.bets[i];
            if (bet.status == BetStatus.Paid)
                continue;
            uint awayBetAmount;
            if (book_type == BookType.MoneyLine) {
                if (bet.line < 0)
                    awayBetAmount = bet.amount * 100 / uint(bet.line);
                else
                    awayBetAmount = bet.amount * uint(bet.line) / 100;
            }
            else
                awayBetAmount = bet.amount;
            balances[bet.home] += bet.amount;
            balances[bet.away] += awayBetAmount;
        }
        delete book.bets;

        return -1;
    }

    function deleteGame(bytes32 game_id) returns (int) {
        Game game = getGameById(game_id);
        if (msg.sender != game.creator && (game.locktime + 86400*4) > now) return 1;

        for (uint i=1; i < 4; i++) {
            Book book = game.books[i];
            cancelOpenBids(book);
            cancelBets(book, BookType(i));
        }
        for (i=0; i < games.length; i++) {
            if (games[i].id == game_id) {
                games[i] = games[games.length - 1];
                games.length -= 1;
                break;
            }
        }
        return -1;
    }

    function payBets(bytes32 game_id) private returns (int) {
        Game game = getGameById(game_id);

        Bet[] spreadBets = game.books[uint(BookType.Spread)].bets;
        Bet[] moneyLineBets = game.books[uint(BookType.MoneyLine)].bets;
        Bet[] overUnderBets = game.books[uint(BookType.OverUnder)].bets;

        // Spread
        int resultSpread = game.result.away - game.result.home;
        resultSpread *= 10; // because bet.line is 10x the actual line
        for (uint i = 0; i < spreadBets.length; i++) {
            Bet bet = spreadBets[i];
            if (bet.status == BetStatus.Paid)
                continue;
            if (resultSpread > bet.line) 
                balances[bet.away] += bet.amount * 2;
            else if (resultSpread < bet.line)
                balances[bet.home] += bet.amount * 2;
            else { // draw
                balances[bet.away] += bet.amount;
                balances[bet.home] += bet.amount;
            }
            bet.status = BetStatus.Paid;
        }

        // MoneyLine
        bool tie = game.result.home == game.result.away;
        bool homeWin = game.result.home > game.result.away;
        for (i=0; i < moneyLineBets.length; i++) {
            bet = moneyLineBets[i];
            if (bet.status == BetStatus.Paid)
                continue;
            uint awayAmount;
            if (bet.line < 0)
                awayAmount = bet.amount * 100 / uint(-bet.line);
            else
                awayAmount = bet.amount * uint(bet.line) / 100;
            if (tie) {
                balances[bet.home] += bet.amount;
                balances[bet.away] += awayAmount;
            }
            else if (homeWin)
                balances[bet.home] += (bet.amount + awayAmount);
            else
                balances[bet.away] += (bet.amount + awayAmount);
            bet.status = BetStatus.Paid;
        }

        // OverUnder - bet.line is 10x the actual line to allow half-point spreads
        int totalPoints = (game.result.home + game.result.away) * 10;
        for (i=0; i < overUnderBets.length; i++) {
            bet = overUnderBets[i];
            if (bet.status == BetStatus.Paid)
                continue;
            if (totalPoints > bet.line)
                balances[bet.home] += bet.amount * 2;
            else if (totalPoints < bet.line)
                balances[bet.away] += bet.amount * 2;
            else {
                balances[bet.away] += bet.amount;
                balances[bet.home] += bet.amount;
            }
            bet.status = BetStatus.Paid;
        }

        return -1;
    }

    function verifyGameResult(bytes32 game_id) returns (int) {
        Game game = getGameById(game_id);
        if (msg.sender != game.creator) return 1;
        if (game.status != GameStatus.Scored) return 2;
        if (now < game.result.timestamp + 12*3600) return 3; // must wait 12 hours to verify 

        payBets(game_id);
        game.status = GameStatus.Verified;
        GameVerified(game_id);

        return -1;
    }

    function setGameResult(bytes32 game_id, int homeScore, int awayScore) returns (int) {
        Game game = getGameById(game_id);
        if (msg.sender != game.creator) return 1;
        if (game.locktime > now) return 2;
        if (game.status == GameStatus.Verified) return 3;

        for (uint i = 1; i < 4; i++)
            cancelOpenBids(game.books[i]);

        game.result.home = homeScore;
        game.result.away = awayScore;
        game.result.timestamp = now;
        game.status = GameStatus.Scored;
        GameScored(game_id, homeScore, awayScore, now);

        return -1;
    }

    // line is actually 10x the line to allow for half-point spreads
    function bid(bytes32 game_id, BookType book_type, bool home, int32 line) payable returns (int) {
        if (book_type == BookType.None)
            return 5;

        Game game = getGameById(game_id);
        Book book = game.books[uint(book_type)];
        Bid memory bid = Bid(msg.sender, msg.value, home, line);

        // validate inputs: game status, gametime, line amount
        if (game.status != GameStatus.Open)
            return 1;
        if (now > game.locktime) {
            game.status = GameStatus.Locked;    
            for (uint i = 1; i < 4; i++)
                cancelOpenBids(game.books[i]);
            return 2;
        }
        if ((book_type == BookType.Spread || book_type == BookType.OverUnder)
            && line % 5 != 0)
            return 3;
        else if (book_type == BookType.MoneyLine && line < 100 && line >= -100)
            return 4;

        Bid memory remainingBid = matchExistingBids(bid, game_id, book_type);

        // Use leftover funds to place open bids (maker)
        if (bid.amount > 0) {
            Bid[] bidStack = home ? book.homeBids : book.awayBids;
            if (book_type == BookType.OverUnder && home)
                addBidToStack(remainingBid, bidStack, true);
            else
                addBidToStack(remainingBid, bidStack, false);
            BidPlaced(game_id, book_type, remainingBid.bidder, remainingBid.amount, home, line);
        }

        return -1;
    }

    // returning an array of structs is not allowed, so its time for a hackjob
    // that returns a raw bytes dump of the combined home and away bids
    // clients will have to parse the hex dump to get the bids out
    // This function is for DEBUGGING PURPOSES ONLY. Using it in a production
    // setting will return very large byte arrays that will consume your bandwidth
    // if you are not running a full node  
    function getOpenBids(bytes32 game_id, BookType book_type) view returns (bytes) {
        Game game = getGameById(game_id);
        Book book = game.books[uint(book_type)];
        uint nBids = book.homeBids.length + book.awayBids.length;
        bytes memory s = new bytes(57 * nBids);
        uint k = 0;
        for (uint i=0; i < nBids; i++) {
            if (i < book.homeBids.length)
                Bid bid = book.homeBids[i];
            else
                bid = book.awayBids[i - book.homeBids.length];
            bytes20 bidder = bytes20(bid.bidder);
            bytes32 amount = bytes32(bid.amount);
            byte home = bid.home ? byte(1) : byte(0);
            bytes4 line = bytes4(bid.line);

            for (uint j=0; j < 20; j++) { s[k] = bidder[j]; k++; }
            for (j=0; j < 32; j++) { s[k] = amount[j]; k++; }
            s[k] = home; k++;
            for (j=0; j < 4; j++) { s[k] = line[j]; k++; }

        }

        return s;
    }

    // for functions throwing a stack too deep error, this helper will free up 2 local variable spots
    function getBook(bytes32 game_id, BookType book_type) view private returns (Book storage) {
        Game game = getGameById(game_id);
        Book book = game.books[uint(book_type)];
        return book;
    }

    
    // for over/under bids, the home boolean is equivalent to the over
    function matchExistingBids(Bid bid, bytes32 game_id, BookType book_type) private returns (Bid) {
        Book book = getBook(game_id, book_type);
        bool home = bid.home;
        Bid[] matchStack = home ?  book.awayBids : book.homeBids;
        int i = int(matchStack.length) - 1;
        while (i >= 0 && bid.amount > 0) {
            uint j = uint(i);
            if (matchStack[j].amount == 0) { // deleted bids
                i--;
                continue;
            }
            if (book_type == BookType.OverUnder) {
                if (home && bid.line < matchStack[j].line 
                || !home && bid.line > matchStack[j].line)
                break;
            }
            else if (-bid.line < matchStack[j].line)
                break;

            // determined required bet amount to match stack bid
            uint requiredBet;
            if (book_type == BookType.Spread || book_type == BookType.OverUnder)
                requiredBet = matchStack[j].amount;
            else if (matchStack[j].line > 0) { // implied MoneyLine
                requiredBet = matchStack[j].amount * uint(matchStack[j].line) / 100;
            }
            else { // implied MoneyLine and negative line
                requiredBet = matchStack[j].amount * 100 / uint(-matchStack[j].line);
            }

            // determine bet amounts on both sides
            uint betAmount;
            uint opposingBetAmount;
            if (bid.amount < requiredBet) {
                betAmount = bid.amount;
                if (book_type == BookType.Spread || book_type == BookType.OverUnder)
                    opposingBetAmount = bid.amount;
                else if (matchStack[j].line > 0)
                    opposingBetAmount = betAmount * 100 / uint(matchStack[j].line);
                else
                    opposingBetAmount = bid.amount * uint(-matchStack[j].line) / 100;
            }
            else {
                betAmount = requiredBet;
                opposingBetAmount = matchStack[j].amount;
            }
            bid.amount -= betAmount;
            matchStack[j].amount -= opposingBetAmount;

            int32 myLine;
            if (book_type == BookType.OverUnder)
                myLine = matchStack[j].line;
            else
                myLine = -matchStack[j].line;
            Bet memory bet = Bet(
                home ? bid.bidder : matchStack[j].bidder,
                home ? matchStack[j].bidder : bid.bidder,
                home ? betAmount : opposingBetAmount,
                home ? myLine : matchStack[j].line,
                BetStatus.Open
            );
            book.bets.push(bet);
            BetPlaced(game_id, book_type, bid.bidder, home, betAmount, myLine);
            BetPlaced(game_id, book_type, matchStack[j].bidder, 
                !home, opposingBetAmount, matchStack[j].line);
            i--;
        }
        return bid;
    }

    function cancelBid(bytes32 game_id, BookType book_type, int32 line, bool home) returns (int) {
        Book book = getBook(game_id, book_type);
        Bid[] stack = home ? book.homeBids : book.awayBids;
        address bidder = msg.sender;

        // Delete bid in stack, refund amount to user
        for (uint i=0; i < stack.length; i++) {
            if (stack[i].amount > 0 && stack[i].bidder == bidder && stack[i].line == line) {
                balances[bidder] += stack[i].amount;
                delete stack[i];
                return -1;
            }
        }
        return 1;
    }

    function kill () {
        if (msg.sender == owner) selfdestruct(owner);
    }

    function getGameId (address creator, string home, string away, uint16 category, uint64 locktime) view returns (bytes32) {
        uint i = 0;
        bytes memory a = bytes(home);
        bytes memory b = bytes(away);
        bytes2 c = bytes2(category);
        bytes8 d = bytes8(locktime);
        bytes20 e = bytes20(creator);

        uint length = a.length + b.length + c.length + d.length + e.length;
        bytes memory toHash = new bytes(length);
        uint k = 0;
        for (i = 0; i < a.length; i++) { toHash[k] = a[i]; k++; }
        for (i = 0; i < b.length; i++) { toHash[k] = b[i]; k++; }
        for (i = 0; i < c.length; i++) { toHash[k] = c[i]; k++; }
        for (i = 0; i < d.length; i++) { toHash[k] = d[i]; k++; }
        for (i = 0; i < e.length; i++) { toHash[k] = e[i]; k++; }
        return sha3(toHash);
    }
    
    function getActiveGames () view returns (bytes32[]) {
        bytes32[] memory game_ids = new bytes32[](games.length);
        for (uint i=0; i < games.length; i++) {
            game_ids[i] = (games[i].id);
        }
        return game_ids;
    }
        
    function addBidToStack(Bid bid, Bid[] storage stack, bool reverse) private returns (int) {
        if (stack.length == 0) {
            stack.push(bid);
            return -1;
        }
        
        // determine position of new bid in stack
        uint insertIndex = stack.length;
        if (reverse) {
            while (insertIndex > 0 && bid.line <= stack[insertIndex-1].line)
                insertIndex--;
        }
        else {
            while (insertIndex > 0 && bid.line >= stack[insertIndex-1].line)
                insertIndex--;
        }
        
        // try to find deleted slot to fill
        if (insertIndex > 0 && stack[insertIndex - 1].amount == 0) {
            stack[insertIndex - 1] = bid;
            return -1;
        }
        uint shiftEndIndex = insertIndex;
        while (shiftEndIndex < stack.length && stack[shiftEndIndex].amount > 0) {
            shiftEndIndex++;
        }
        
        // shift bids down (up to deleted index if one exists)
        if (shiftEndIndex == stack.length)
            stack.length += 1;
        for (uint i = shiftEndIndex; i > insertIndex; i--) {
            stack[i] = stack[i-1];
        } 

        stack[insertIndex] = bid;
        

        return -1;
    }

    function getGameById(bytes32 game_id) view private returns (Game storage) {
        bool game_exists = false;
        for (uint i = 0; i < games.length; i++) {
            if (games[i].id == game_id) {
                Game game = games[i];
                game_exists = true;
                break;
            }
        }
        if (!game_exists)
            throw;
        return game;
    }


    function withdraw() returns (int) {
        var balance = balances[msg.sender];
        balances[msg.sender] = 0;
        if (!msg.sender.send(balance)) {
            balances[msg.sender] = balance;
            return 1;
        }
        Withdrawal(msg.sender, balance, now);
        return -1;
    }

}