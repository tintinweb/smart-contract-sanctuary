//SourceUnit: Tronman.sol

// type your code...pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Mortal is Ownable{
    uint public stopTS;
    uint public minimumWait = 1 hours;
    bool public killed;

    /**
     * keep people from joining games or initiating new ones
     * */
    function stopPlaying() public onlyOwner{
        stopTS = now;
    }

    /**
     * kills the contract if enough time has passed. time to pass = twice the waiting time for withdrawal of funds of a running game.
     * */
    function kill() public onlyOwner{
        require(stopTS > 0 && stopTS + 2 * minimumWait <= now, "before killing, playing needs to be stopped and sufficient time has to pass");
        selfdestruct(owner);
    }

    /**
     * like killing, because playing will no longer be possible and funds are withdrawn, but keeps the data available on the blockchain
     * (especially scores)
     * */
    function permaStop() public onlyOwner{
        require(stopTS > 0 && stopTS + 2 * minimumWait <= now, "before killing, playing needs to be stopped and sufficient time has to pass");
        killed = true;
        owner.transfer(address(this).balance);
    }

    /**
     * resume playing. stops the killing preparation.
     * */
    function resumePlaying() public onlyOwner{
        require(!killed, "killed contract cannot be reactivated");
        stopTS = 0;
    }

    /**
     * don't allow certain functions if playing has been stopped
     * */
    modifier active(){
        require(stopTS == 0, "playing has been stopped by the owner");
        _;
    }
}

contract Administrable is Mortal{
    /** the different pots */
    uint public charityPot;
    uint public highscorePot;
    uint public affiliatePot;
    uint public surprisePot;
    uint public developerPot;
    /** the Percentage of the game stake which go into a pot with one decimal (25 => 2.5%) */
    uint public charityPercent = 25;
    uint public highscorePercent = 50;
    uint public affiliatePercent = 50;
    uint public surprisePercent = 25;
    uint public developerPercent = 50;
    uint public winnerPercent = 800;
    /** the current highscore holder **/
    address public highscoreHolder;
    address public signer;
    /** balance of affiliate partners */
    mapping (address => uint) public affiliateBalance;

    uint public minStake;
    uint public maxStake;

    /** tells if a hash has already been used for withdrawal **/
    mapping (bytes32 => bool) public used;
    event Withdrawal(uint8 pot, address receiver, uint value);

    modifier validAddress(address receiver){
        require(receiver != 0x0, "invalid receiver");
        _;
    }


    /**
     * set the minimum waiting time for withdrawal of funds of a started but not-finished game
     * */
    function setMinimumWait(uint newMin) public onlyOwner{
        minimumWait = newMin;
    }

    /**
     * withdraw from the developer pot
     * */
    function withdrawDeveloperPot(address receiver) public onlyOwner validAddress(receiver){
        uint value = developerPot;
        developerPot = 0;
        receiver.transfer(value);
        emit Withdrawal(0, receiver, value);
    }

    /**
     * withdraw from the charity pot
     * */
    function donate(address charity) public onlyOwner validAddress(charity){
        uint value = charityPot;
        charityPot = 0;
        charity.transfer(value);
        emit Withdrawal(1, charity, value);
    }

    /**
     * withdraw from the highscorePot
     * */
    function withdrawHighscorePot(address receiver) public validAddress(receiver){
        require(msg.sender == highscoreHolder);
        uint value = highscorePot;
        highscorePot = 0;
        receiver.transfer(value);
        emit Withdrawal(2, receiver, value);
    }

    /**
     * withdraw from the affiliate pot
     * */
    function withdrawAffiliateBalance(address receiver) public validAddress(receiver){
        uint value = affiliateBalance[msg.sender];
        require(value > 0);
        affiliateBalance[msg.sender] = 0;
        receiver.transfer(value);
        emit Withdrawal(3, receiver, value);
    }

    /**
     * withdraw from the surprise pot
     * */
    function withdrawSurprisePot(address receiver) public onlyOwner validAddress(receiver){
        uint value = surprisePot;
        surprisePot = 0;
        receiver.transfer(value);
        emit Withdrawal(4, receiver, value);
    }

    /**
     * allows an user to withdraw from the surprise pot with a valid signature
     * */
    function withdrawSurprisePotUser(uint value, uint expiry, uint8 v, bytes32 r, bytes32 s) public{
        require(expiry >= now, "signature expired");
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, value, expiry));
        require(!used[hash], "same signature was used before");
        require(ecrecover(hash, v, r, s) == signer, "invalid signer");
        require(value <= surprisePot, "not enough in the pot");
        surprisePot -= value;
        used[hash] = true;
        msg.sender.transfer(value);
        emit Withdrawal(4, msg.sender, value);
    }

    /**
     * sets the signing address
     * */
    function setSigner(address signingAddress) public onlyOwner{
        signer = signingAddress;
    }

    /**
     * sets the pot Percentages
     * */
    function setPercentages(uint affiliate, uint charity, uint dev, uint highscore, uint surprise) public onlyOwner{
        uint sum =  affiliate + charity + highscore + surprise + dev;
        require(sum < 500, "winner should not lose money");
        charityPercent = charity;
        affiliatePercent = affiliate;
        highscorePercent = highscore;
        surprisePercent = surprise;
        developerPercent = dev;
        winnerPercent = 1000 - sum;
    }

    function setMinMax(uint newMin, uint newMax) public onlyOwner{
        minStake = newMin;
        maxStake = newMax;
    }
}

contract Tronman is Administrable{

    struct game{
        uint32 timestamp;
        uint128 stake;
        address player1;
        address player2;
    }

    struct player{
        uint8 team;
        uint64 score;
        address referrer;
    }

    mapping (bytes12 => game) public games;
    mapping (address => player) public players;

    event NewGame(bytes32 gameId, address player1, uint stake);
    event GameStarted(bytes32 gameId, address player1, address player2, uint stake);
    event GameDestroyed(bytes32 gameId);
    event GameEnd(bytes32 gameId, address winner, uint value);
    event NewHighscore(address holder, uint score, uint lastPot);

    modifier onlyHuman(){
        require(msg.sender == tx.origin, "contract calling");
        _;
    }

    constructor(address signingAddress, uint min, uint max) public{
        setSigner(signingAddress);
        minStake = min;
        maxStake = max;
    }

    /**
     * sets the referrer for the lifetime affiliate program and initiates a new game
     * */
    function initGameReferred(bytes12 gameId, address referrer, uint8 team) public payable active onlyHuman validAddress(referrer){
        //new player which does not have a referrer set yet
        if(players[msg.sender].referrer == 0x0 && players[msg.sender].score == 0)
            players[msg.sender] = player(team, 0, referrer);
        initGame(gameId);
    }

    /**
     * sets the team and initiates a game
     * */
    function initGameTeam(bytes12 gameId, uint8 team) public payable active onlyHuman {
        if(players[msg.sender].score == 0)
            players[msg.sender].team = team;
        initGame(gameId);
    }

    /**
     * initiates a new game
     * */
    function initGame(bytes12 gameId) public payable active onlyHuman {
        require(msg.value <= maxStake, "stake needs to be lower than or equal to the max stake");
        require(msg.value >= minStake, "stake needs to be at least the min stake");
        require(games[gameId].stake == 0, "game with the given id already exists");
        games[gameId] = game(uint32(now), uint128(msg.value), msg.sender, 0x0);
        emit NewGame(gameId, msg.sender, msg.value);
    }

    /**
     * sets the referrer for the lifetime affiliate program and joins a game
     * */
    function joinGameReferred(bytes12 gameId, address referrer, uint8 team) public payable active onlyHuman validAddress(referrer){
        //new player which does not have a referrer set yet
        if(players[msg.sender].referrer == 0x0 && players[msg.sender].score == 0)
            players[msg.sender] = player(team, 0, referrer);
        joinGame(gameId);
    }

    /**
     * sets the team and joins a game
     * */
    function joinGameTeam(bytes12 gameId, uint8 team) public payable active onlyHuman{
        if(players[msg.sender].score == 0)
            players[msg.sender].team = team;
        joinGame(gameId);
    }

    /**
     * join a game
     * */
    function joinGame(bytes12 gameId) public payable active onlyHuman{
        game storage cGame = games[gameId];
        require(cGame.player1!=0x0, "game id unknown");
        require(cGame.player1 != msg.sender, "cannot play with one self");
        require(msg.value >= cGame.stake, "value does not suffice to join the game");
        cGame.player2 = msg.sender;
        cGame.timestamp = uint32(now);
        emit GameStarted(gameId, cGame.player1, msg.sender, cGame.stake);
        if(msg.value > cGame.stake) developerPot += msg.value - cGame.stake;
    }

    /**
     * withdraw from the game stake in case no second player joined or the game was not ended within the
     * minimum waiting time
     * */
    function withdraw(bytes12 gameId) public onlyHuman{
        game storage cGame = games[gameId];
        uint128 value = cGame.stake;
        if(msg.sender == cGame.player1){
            if(cGame.player2 == 0x0){
                delete games[gameId];
                msg.sender.transfer(value);
            }
            else if(cGame.timestamp + minimumWait <= now){
                address player2 = cGame.player2;
                delete games[gameId];
                msg.sender.transfer(value);
                player2.transfer(value);
            }
            else{
                revert("minimum waiting time has not yet passed");
            }
        }
        else if(msg.sender == cGame.player2){
            if(cGame.timestamp + minimumWait <= now){
                address player1 = cGame.player1;
                delete games[gameId];
                msg.sender.transfer(value);
                player1.transfer(value);
            }
            else{
                revert("minimum waiting time has not yet passed");
            }
        }
        else{
            revert("sender is not a player in this game");
        }
        emit GameDestroyed(gameId);
    }

    /**
     * The winner can claim his winnings, only with a signature from a contract owners allowed address.
     * the pot is distributed amongst the winner, the developers, the affiliate partner, a charity and the surprise pot
     * */
    function claimWin(bytes12 gameId, uint8 v, bytes32 r, bytes32 s) public onlyHuman{
        game storage cGame = games[gameId];
        require(cGame.player2!=0x0, "game has not started yet");
        require(msg.sender == cGame.player1 || msg.sender == cGame.player2, "sender is not a player in this game");
        require(ecrecover(keccak256(abi.encodePacked(gameId, msg.sender)), v, r, s) == signer, "invalid signature");
        uint256 value = 2*cGame.stake;
        uint256 win = winnerPercent * value / 1000;
        addScore(msg.sender, cGame.stake);
        delete games[gameId];
        charityPot += value * charityPercent / 1000;
        //players of the leading team do not pay tributes
        if(players[highscoreHolder].team == players[msg.sender].team){
            win += value * highscorePercent / 1000;
        }
        else{
            highscorePot += value * highscorePercent / 1000;
        }
        surprisePot += value * surprisePercent / 1000;
        if(players[msg.sender].referrer == 0x0){
            developerPot += value * (developerPercent + affiliatePercent) / 1000;
        }
        else{
            developerPot += value * developerPercent / 1000;
            affiliateBalance[players[msg.sender].referrer] += value * affiliatePercent / 1000;
        }
        msg.sender.transfer(win);//no overflow possible because stake is <= max uint128, but now we have 256 bit
        emit GameEnd(gameId, msg.sender, win);
    }

    /**
     * adds the score to the player.
     * computed by ceiling(60x/(x+100))
     * 20% bonus points if the winner does not belong to the leading team. minimum 1 point extra.
     * */
    function addScore(address receiver, uint stake) private{
        player storage rec = players[receiver];
        player storage hsh = players[highscoreHolder];
        uint64 x = uint64(stake/(1 trx));//convert from SUN to TRX
        uint64 score = (61 * x + 100) / ( x + 100); //adding +1 to the formula above to be able to round up
        if(rec.team != hsh.team){
            uint64 extra = score * 25 / 100;
            if (extra == 0) extra = 1;
            score += extra;
        }
        rec.score += score;
        if(rec.score > hsh.score){
            uint pot = highscorePot;
            if(pot > 0){
                highscorePot = 0;
                highscoreHolder.transfer(pot);
            }
            highscoreHolder = receiver;
            emit NewHighscore(receiver, rec.score, pot);
        }
    }

    /**
     * any directly sent ETH are considered a donation for development
     * */
    function() public payable{
        developerPot+=msg.value;
    }

    /**
     * sets the score of an user. only after contract update.
     * */
    function setScore(address user, uint64 score, uint8 team, address referrer) public onlyOwner{
        players[user].score = score;
        players[user].team = team;
        players[user].referrer = referrer;
    }

}