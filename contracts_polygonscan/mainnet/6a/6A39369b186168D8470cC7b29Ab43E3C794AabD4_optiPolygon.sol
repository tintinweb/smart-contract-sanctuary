/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

pragma solidity ^0.8.7;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract optiPolygon {
    
    struct User{
        uint amount;
        uint8 poolChoice;
        bool claimed;
    }
    
    struct Game{
        uint upAmount;
        uint downAmount;
        uint totalAmount;
        uint rewardAmount;
        uint rewardPoolAmount;
        bool rewardCalculated;
        uint256 endTimestamp;
        int priceEnd;
    }

    address public admin;
    uint public feesAmount;
    uint public feesRate;
    uint public currentGameId;
    uint256 public intervalSeconds;
    AggregatorV3Interface internal priceFeed;
    bool internal cycleIsSet;

    mapping(uint => mapping(address => User)) public users;
    mapping(address => uint[]) public userGames;
    mapping(uint => Game) public Games;
    
    event _initCycle();
    event _joinUp(address indexed _from, uint indexed _game, uint _value);
    event _joinDown(address indexed _from, uint indexed _game, uint _value);
    event _changeCurrentGame(uint indexed _lastGame, uint indexed _game);
    event _reward(address indexed _from, uint[] indexed _game, uint _value);
    event _updateTreasury(uint indexed _game);
    event _rewardAdmin(address indexed _address, uint _value);
    
    event _setIntervalTime(uint indexed update);
    
    constructor() {
        admin = msg.sender;
        feesRate = 50; // 2% fees
        intervalSeconds = 300;
        priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945); // ETH/USD
    }
    
    // for a better understanding: 
        // 1 : Up et 0 : Down.
        // Current Pair : ETH/USD => if the price of the pair goes up, then ETH is going up
        // and if the price of the pair goes down, then ETH is going down
        
    function initCycle() external{
        require(msg.sender == admin, 'Only admin can initiate a game.');
        require(!cycleIsSet, 'Cycle is already set');
        
        Game memory game;
        game.endTimestamp = block.timestamp+intervalSeconds;

        Games[currentGameId] = game;
        addGameInQueue();
        
        cycleIsSet = true;
        emit _initCycle();
    }

    function addGameInQueue() private {        
        Game memory nextGame;       

        Games[currentGameId+1] = nextGame;
    }
    
    function NextCurrentGame() external {
        Game storage game1 = Games[currentGameId];

        require(block.timestamp >= game1.endTimestamp && !game1.rewardCalculated, 'This game is not finish.');

        int lockPrice = getCurrentPrice();
        game1.priceEnd = lockPrice;
        
        updateTreasury();

        currentGameId += 1;

        Game storage game2 = Games[currentGameId];
        game2.endTimestamp = block.timestamp + intervalSeconds;

        addGameInQueue();
        emit _changeCurrentGame(currentGameId-1, currentGameId);
    }
    
    function joinUp() external payable{
        require(msg.value > 0, 'You have to send some ether to play');
        Game storage nextGame = Games[currentGameId+1];
        Game memory currentGame = Games[currentGameId];
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        User memory user;
        user.amount = msg.value;
        user.poolChoice = 1;

        users[currentGameId+1][msg.sender] = user;
        nextGame.upAmount += msg.value;
        nextGame.totalAmount += msg.value;
        userGames[msg.sender].push(currentGameId+1);
        
        emit _joinUp(msg.sender, currentGameId+1, msg.value);
    }
    
    function joinDown() external payable{
        require(msg.value > 0, 'You have to send some ether to play');
        Game storage nextGame = Games[currentGameId+1];
        Game memory currentGame = Games[currentGameId];
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        User memory user;
        user.amount = msg.value;
        user.poolChoice = 0;

        users[currentGameId+1][msg.sender] = user;
        nextGame.downAmount += msg.value;
        nextGame.totalAmount += msg.value;
        userGames[msg.sender].push(currentGameId+1);
        
        emit _joinDown(msg.sender, currentGameId+1, msg.value);
    }
    
    function reward(uint[] memory idGames) external{
        uint varReward;
        for(uint i=0; i < idGames.length; i++){
            uint idGame = idGames[i];
            User storage user = users[idGame][msg.sender];
            
            require(user.claimed == false, 'You already claim your rewards on this game');
            require(Games[idGame].endTimestamp < block.timestamp, 'This game is not finish.');
            require(user.amount > 0, 'amount = 0');
            require(isWinner(idGame, msg.sender), 'You lost this game.');
            
            varReward += (user.amount*Games[idGame].rewardAmount)/Games[idGame].rewardPoolAmount;
            user.claimed = true;
        }
        
        (bool sent, ) = msg.sender.call{value: varReward}("");
        require(sent, "Failed to send");
        
        emit _reward(msg.sender, idGames, varReward);
    }
    
    function rewardAdmin(address payable _address) external{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(feesAmount > 0, 'Empty treasury.');
        
        (bool sent, ) = _address.call{value: feesAmount}("");
        require(sent, "Failed to send");
        
        feesAmount = 0;
        emit _rewardAdmin(_address, feesAmount);
    }

    function updateTreasury() private {
        Game storage currentGame = Games[currentGameId];
        require(block.timestamp >= currentGame.endTimestamp, 'Match is not already started.');

        uint256 rewardPoolAmountTmp; // amount(winnerPool)
        uint256 feesTmp; // fees(currentGame)
        uint256 rewardAmountTmp; // totalAmount(currentGame)

        if(currentGameId != 0){
            Game storage lastGame = Games[currentGameId-1];
            if (currentGame.priceEnd < lastGame.priceEnd) {
                rewardPoolAmountTmp = currentGame.downAmount;
                feesTmp = currentGame.totalAmount/feesRate; // 2% fee
                rewardAmountTmp = currentGame.totalAmount - feesTmp;
            }
            else if (currentGame.priceEnd > lastGame.priceEnd) {
                rewardPoolAmountTmp = currentGame.upAmount;
                feesTmp = currentGame.totalAmount/feesRate; // 2% fee
                rewardAmountTmp = currentGame.totalAmount - feesTmp;
            }
            else {
                rewardPoolAmountTmp = 0;
                rewardAmountTmp = 0;
                feesTmp = currentGame.totalAmount;
            }
            currentGame.rewardPoolAmount = rewardPoolAmountTmp;
            currentGame.rewardAmount = rewardAmountTmp;

            feesAmount += feesTmp;
        }
        currentGame.rewardCalculated = true;
        
        emit _updateTreasury(currentGameId);
    }
    
    function isWinner(uint idGame, address _address) public view returns(bool){

        Game memory game = Games[idGame];
        Game memory lastGame = Games[idGame-1];

        if(block.timestamp < game.endTimestamp || !game.rewardCalculated || idGame == 0)    return false;

        User memory user = users[idGame][_address];
        
        return
            (lastGame.priceEnd != game.priceEnd) && 
            ((lastGame.priceEnd > game.priceEnd && user.poolChoice == 0) || 
                (lastGame.priceEnd < game.priceEnd && user.poolChoice == 1)); 
    }
    
    function getCurrentPrice() public view returns(int){
        (
            ,
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }
    
    function getUserRewardableGames(address _user) external view returns(uint[] memory _rewardablesGames){
        uint[] memory games = userGames[_user];
        require(games.length > 0, 'No game found.');
        
        uint[] memory tmpRewardablesGames = new uint[](games.length);
        uint cpt = 0;
        
        for(uint i=0; i < games.length; i++){
            
            User memory user = users[games[i]][_user];
            if(!user.claimed && isWinner(games[i], _user)){
                cpt++;
                tmpRewardablesGames[i] = games[i];
            }
        }
        uint j;
        if(cpt > 0){
            uint[] memory rewardablesGames = new uint[](cpt);
            
            for(uint i=0; i < cpt; i++){
                if(tmpRewardablesGames[i] != 0){
                    rewardablesGames[j] = tmpRewardablesGames[i];
                    j++;
                }
            }
            
            return rewardablesGames;
        }
        
        return new uint[](1); // if [0] => no rewardable game
    }

    function setIntervalSeconds(uint _intervalSeconds) external {
        require(msg.sender == admin, 'Only admin can use this method.');
        intervalSeconds = _intervalSeconds;
        
        emit _setIntervalTime(_intervalSeconds);
    }
    
}