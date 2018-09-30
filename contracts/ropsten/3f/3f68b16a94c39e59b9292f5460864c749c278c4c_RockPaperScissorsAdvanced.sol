/**
 *  @title Rock Paper Scissors Advanced
 *  @author Vitali Grabovski
 *  @author u/ikiirch
 */

pragma solidity ^0.4.24;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

contract FeeControl is SafeMath{

    uint public tip_total = 0;
    /// @dev fee value
    uint public fee_ = 3000000000000000;

    function () public payable{
        tip_total = safeAdd(tip_total, msg.value);
    }

    /// @dev Count amount of tip.
    /// @param amount The totalAmount
    function takeFee(uint amount) internal returns(uint){
        uint myfee = fee_ * 2;//safeSub(amount, fee_ * 2);
        tip_total = safeAdd(tip_total, myfee);
        return safeSub(amount, myfee);
    }

}

contract CustomArray {
   uint[] private items;

   constructor () public {
       //
   }

   function pushElement(uint value) internal {
      items.push(value);
   }

   function popElementWithPos(uint pos_) internal returns (uint []){
      delete items[pos_];
      items.length--;
      return items;
   }

   function popElement() internal returns (uint []){
      delete items[items.length-1];
      items.length--;
      return items;
   }

   function deleteElementWithValue (uint value_) internal returns (uint []){
        for (uint position=0; position<getArrayLength(); position++) {
          if (items[position] == value_) {
            items[position] = items[items.length-1];
            popElement();
            break;
          }
        }
        return items;
   }

   function getArrayLength() public view returns (uint) {
      return items.length;
   }

   function getAnyElementByIndex(uint index) internal view returns (uint) {
      require( index < (getArrayLength() ) );
      return items[index];
   }

   function getFirstElement() private view returns (uint) {
      return items[0];
   }

   function getAllElement()  private view returns (uint[]) {
      return items;
   }
}


contract RockPaperScissorsAdvanced is SafeMath ,FeeControl, CustomArray {

    /// @dev owner
    address public ceoAddress;

    //// @dev constant bet
    uint public game_bet = 10000000000000000;

    /// @dev Constant definition
    uint8 constant public NONE = 0;
    uint8 constant public ROCK = 10;
    uint8 constant public PAPER = 20;
    uint8 constant public SCISSORS = 30;
    uint8 constant public DEALERWIN = 1;
    uint8 constant public PLAYER2WIN = 2;
    uint8 constant public DRAW = 5;

    /// @dev Emited when contract is upgraded
    event CreateGame(uint gameid, address dealer, uint amount);
    event JoinGame(uint gameid, address dealer, address player, uint amount);
    event Reveal(uint gameid, address player, uint8 choice);
    event CloseGame(uint gameid,address dealer,address player, uint8 result);
    event CloseGameByAdmin(bool isSuccess, address dealer, address player2, uint gameid);
    event JoinGameRandomEv(bool isSuccess, address dealer, address player2, int gameid);

    //// @dev admin access
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev struct of a game
    struct Game {
        uint expireTime;
        address dealer;//// owner
        uint dealerValue;
        bytes32 dealerHash;
        uint8 dealerMove;
        address player;//// player2
        uint8 playerMove;
        uint playerValue;
        uint8 result;
        bool closed;
    }

    /// @dev struct of a game
    mapping (uint => mapping(uint => uint8)) public payoffStates;
    mapping (uint => Game) public games;//// games list
    mapping (address => uint[]) public gameidsOf;//// games of user


    /// @dev Current game maximum id
    uint public maxgame = 0;
    uint public expireTimeLimit = 5 minutes;

    /// @dev Initialization contract
    function RockPaperScissorsAdvanced() {
        payoffStates[ROCK][ROCK] = DRAW;
        payoffStates[ROCK][PAPER] = PLAYER2WIN;
        payoffStates[ROCK][SCISSORS] = DEALERWIN;
        payoffStates[PAPER][ROCK] = DEALERWIN;
        payoffStates[PAPER][PAPER] = DRAW;
        payoffStates[PAPER][SCISSORS] = PLAYER2WIN;
        payoffStates[SCISSORS][ROCK] = PLAYER2WIN;
        payoffStates[SCISSORS][PAPER] = DEALERWIN;
        payoffStates[SCISSORS][SCISSORS] = DRAW;
        payoffStates[NONE][NONE] = DRAW;
        payoffStates[ROCK][NONE] = DEALERWIN;
        payoffStates[PAPER][NONE] = DEALERWIN;
        payoffStates[SCISSORS][NONE] = DEALERWIN;
        payoffStates[NONE][ROCK] = PLAYER2WIN;
        payoffStates[NONE][PAPER] = PLAYER2WIN;
        payoffStates[NONE][SCISSORS] = PLAYER2WIN;

        ceoAddress = msg.sender;
    }

    /// @dev Create a game
    function createGame(uint8 move, bytes32 secret) public payable  returns (uint){
        require( checkChoice(move) );

        maxgame += 1;
        Game storage game = games[maxgame];
        game.dealer = msg.sender;
        //// game.player is 0x0 until someone joined
        //game.player = player;
        game.dealerHash = getProof(msg.sender, move, secret);
        game.dealerMove = NONE;
        game.playerMove = NONE;
        game.dealerValue = msg.value;
        game.expireTime = expireTimeLimit + now;

        gameidsOf[msg.sender].push(maxgame);
        pushElement(maxgame);

        emit CreateGame(maxgame, game.dealer, game.dealerValue);

        return maxgame;
    }

    /// @dev Join a game
    function joinGame(uint gameid, uint8 choice) public payable  returns (uint){
        Game storage game = games[gameid];

        require(msg.value == game.dealerValue && game.dealer != address(0) && game.dealer != msg.sender && game.playerMove==NONE);
        require(game.player == address(0) || game.player == msg.sender);
        require(!game.closed);
        require(now < game.expireTime);
        require(checkChoice(choice));

        game.player = msg.sender;
        game.playerMove = choice;
        game.playerValue = msg.value;
        game.expireTime = expireTimeLimit + now;

        gameidsOf[msg.sender].push(gameid);
        deleteElementWithValue(gameid);

        emit JoinGame(gameid, game.dealer, game.player, game.playerValue);

        return gameid;
    }

    /// @dev Join game by chance
    function joinGameRandom(uint8 choice) public payable  returns (int){
        if (getArrayLength()==0) {
            //// no available games to join;
            emit JoinGameRandomEv(false,address(0),msg.sender,-6);
            msg.sender.send(msg.value);
            return -6;
        }
        uint gameRandomIndexID = random( getArrayLength() );
        uint gameRandomID = getAnyElementByIndex(gameRandomIndexID);
        Game storage game = games[gameRandomID];
        if (game.player != address(0) || game.closed !=false 
            || (now > game.expireTime) || game.dealer == msg.sender) {
            //// game already closed or has player or timed, try again
            emit JoinGameRandomEv(false,address(0),msg.sender,-5);
            msg.sender.send(msg.value);
            return -5;
        }
        else {
            emit JoinGameRandomEv(true,game.dealer, msg.sender, int(gameRandomID) );
            joinGame(gameRandomID, choice);
        }
        
    }

    /// @dev Creator reveals game choice
    function reveal(uint gameid, uint8 choice, bytes32 randomSecret) public returns (bool) {
        Game storage curr_game = games[gameid];
        bytes32 proof = getProof(msg.sender, choice, randomSecret);

        require(!curr_game.closed);
        require(now < curr_game.expireTime);
        require(curr_game.dealerHash != 0x0);
        require(checkChoice(choice));
        require(checkChoice(curr_game.playerMove));
        require(curr_game.dealer == msg.sender && proof == curr_game.dealerHash );

        curr_game.dealerMove = choice;

        Reveal(gameid, msg.sender, choice);

        close(gameid);

        return true;
    }

    /// @dev Close game, rewards settlement
    function close(uint gameid) public returns(bool) {
        Game storage curr_game = games[gameid];

        require(!curr_game.closed);
        require(now > curr_game.expireTime || (curr_game.dealerMove != NONE && curr_game.playerMove != NONE));

        uint8 result = payoffStates[curr_game.dealerMove][curr_game.playerMove];

        if(result == DEALERWIN){
            require(curr_game.dealer.send( takeFee(safeAdd(curr_game.dealerValue, curr_game.playerValue))) );
        }else if(result == PLAYER2WIN){
            require(curr_game.player.send( takeFee(safeAdd(curr_game.dealerValue, curr_game.playerValue))) );
        }else if(result == DRAW){
            require(curr_game.dealer.send(curr_game.dealerValue) && curr_game.player.send(curr_game.playerValue));
        }

        curr_game.closed = true;
        curr_game.result = result;

        emit CloseGame(gameid, curr_game.dealer, curr_game.player, result);

        return curr_game.closed;
    }

    //// Generates a number in [0 .. size_-1] range
    function random(uint size_) private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty))%size_);
    }

    function getProof(address sender, uint8 choice, bytes32 random_secret) public view returns (bytes32){
        return sha3(sender, choice, random_secret);
    }

    function gameCountOf(address owner) public view returns (uint){
        return gameidsOf[owner].length;
    }

    function getGameStatus(uint gameid) public view returns (int) {
       Game storage curr_game = games[gameid];
       if (!curr_game.closed && curr_game.player != address(0) 
            && now<curr_game.expireTime) {return 41;}
       if (curr_game.closed) {return 11;}
       if (now > curr_game.expireTime && !curr_game.closed) {return 21;}
       if (curr_game.player == address(0)) {return 31;}
       //
       return 51;//// should not happen
    }
    
    //// Check if game is expired
    function getGameExpired(uint gameid) public view returns(bool) {
        Game storage curr_game = games[gameid];
        return ( now > curr_game.expireTime );
    }
    
    //// Player1 or player2 can check remaining time. If game is expired result is: 1
    function getTimeRemaining(uint gameid) public view returns(uint) {
        Game storage curr_game = games[gameid];
        require(curr_game.dealerMove == msg.sender || curr_game.player == msg.sender);
        if ( now < curr_game.expireTime ) return (curr_game.expireTime-now);
        else return 1;
    }

    function checkChoice(uint8 choice) public view returns (bool){
        return choice==ROCK||choice==PAPER||choice==SCISSORS;
    }
    
    //// Admin can send all fees to any account
    function sendAllFeesToAddress(address addr) onlyCEO public {
        require(address(this).balance >= tip_total);
        addr.send(tip_total);
    }
    
    //// Admin can close any game if game is expired and not closed yet
    function closeAnyGame(uint gameid) onlyCEO public returns (bool) {
        Game storage curr_game = games[gameid];
        if (now>curr_game.expireTime && !curr_game.closed) {
            
            uint8 result = payoffStates[curr_game.dealerMove][curr_game.playerMove];
            if(result == DEALERWIN){
                require(curr_game.dealer.send( takeFee(safeAdd(curr_game.dealerValue, curr_game.playerValue))) );
            }else if(result == PLAYER2WIN){
                require(curr_game.player.send( takeFee(safeAdd(curr_game.dealerValue, curr_game.playerValue))) );
            }else if(result == DRAW){
                require(curr_game.dealer.send(curr_game.dealerValue) && curr_game.player.send(curr_game.playerValue));
            }
            
            curr_game.closed = true;
            curr_game.result = result;
            emit CloseGameByAdmin(true, curr_game.dealer, curr_game.player, gameid);
            return true;
        }
        else {
            emit CloseGameByAdmin(false, curr_game.dealer, curr_game.player, gameid);
            return false;
        }
    }


}