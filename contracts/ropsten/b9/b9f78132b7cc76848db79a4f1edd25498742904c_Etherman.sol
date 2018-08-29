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
     * resume playing. stops the killing preparation.
     * */
    function resumePlaying() public onlyOwner{
        stopTS = 0;
    }
    
    /**
     * don&#39;t allow certain functions if playing has been stopped
     * */
    modifier active(){
        require(stopTS == 0, "playing has been stopped by the owner");
        _;
    }
}

contract Administrable is Mortal{
    uint public charityPot;
    uint public jackPot;
    uint public affiliatePot;
    uint public surprisePot;
    uint public developerPot;
    
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
    }
    
    /**
     * withdraw from the charity pot
     * */
    function donate(address charity) public onlyOwner validAddress(charity){
        uint value = charityPot;
        charityPot = 0;
        charity.transfer(value);
    }
    
    /**
     * withdraw from the jackpot
     * */
    function withdrawJackPot(address receiver) public onlyOwner validAddress(receiver){
        uint value = jackPot;
        jackPot = 0;
        receiver.transfer(value);
    }
    
    /**
     * withdraw from the affiliate pot
     * */
    function withdrawAffiliatePot(address receiver) public onlyOwner validAddress(receiver){
        uint value = affiliatePot;
        affiliatePot = 0;
        receiver.transfer(value);
    }
    
    /**
     * withdraw from the surprise pot
     * */
    function withdrawSurprisePot(address receiver) public onlyOwner validAddress(receiver){
        uint value = surprisePot;
        surprisePot = 0;
        receiver.transfer(value);
    }
}

contract Etherman is Administrable{
    struct game{
        uint32 timestamp;
        uint128 stake;
        address player1;
        address player2;
    }
    mapping (bytes32 => game) games;
    event NewGame(bytes32 gameId, address player1, uint stake);
    event GameStarted(bytes32 gameId, address player1, address player2, uint stake);
    event GameDestroyed(bytes32 gameId);
    event GameEnd(bytes32 gameId, address winner, uint value);
    
    /**
     * initiates a new game
     * */
    function initGame() public payable active{
        require(msg.value <= 10 ether, "stake needs to be lower than or equal to 10 ether");
        require(msg.value > 1 finney, "stake needs to be at least 1 finney");
        bytes32 gameId = keccak256(abi.encodePacked(msg.sender, block.number));
        games[gameId] = game(uint32(now), uint128(msg.value), msg.sender, 0x0);
        emit NewGame(gameId, msg.sender, msg.value);
    }
    
    /**
     * join a game
     * */
    function joinGame(bytes32 gameId) public payable active{
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
    function withdraw(bytes32 gameId) public{
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
     * The winner can claim his winnings, only with a signature from the contract owner.
     * we distribute the value of player1 and player2 like this:
     * 5% goes to Pot1 (charity)
     * 5% goes to Pot2 (developer-fee)
     * 5% goes to Pot3 (affiliate)
     * 5% goest to Pot4 (jackpot for tournaments)
     * 5% goest to Pot5 (surprise)
     * rest goes to Pot6 (for the winner)
     * */
    function claimWin(bytes32 gameId, uint8 v, bytes32 r, bytes32 s) public{
        game storage cGame = games[gameId];
        require(cGame.player2!=0x0, "game has not started yet");
        require(msg.sender == cGame.player1 || msg.sender == cGame.player2, "sender is not a player in this game");
        require(ecrecover(keccak256(abi.encodePacked(gameId, msg.sender)), v, r, s) == owner, "invalid signature");
        uint256 value = 2*cGame.stake;
        uint256 win = value*75/100;
        uint256 fivePercent = value * 5/100;
        delete games[gameId];
        msg.sender.transfer(win);//no overflow possible because stake is <= max uint128, but now we have 256 bit
        charityPot += fivePercent;
        jackPot += fivePercent;
        affiliatePot += fivePercent;
        surprisePot += fivePercent;
        developerPot += fivePercent;
        emit GameEnd(gameId, msg.sender, win);
    }
    
    /**
     * any directly sent ETH are considered a donation for development
     * */
    function() public payable{
        developerPot+=msg.value;
    }
    
}