/**
 *Submitted for verification at polygonscan.com on 2021-12-09
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

contract ObEthUsd {
    
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
        intervalSeconds = 300; // 5 mins
        priceFeed = AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945); // ETH/USD
    }
    
    // for a better understanding: 
        // 1 : Up et 0 : Down.
        // Current Pair : ETH/USD => if the price goes up, then ETH is going up
        // and if the price goes down, then ETH is going down
        
    function initCycle() external{
        require(msg.sender == admin, 'Only admin can initiate a game.');
        require(!cycleIsSet, 'Cycle is already set.');
        
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

        require(block.timestamp >= game1.endTimestamp && !game1.rewardCalculated, 'Game in progress.');

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
        require(msg.value > 0, 'The amount should be greater than 0.');
        Game storage nextGame = Games[currentGameId+1];
        Game memory currentGame = Games[currentGameId];
        bool joined;
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game.');
        
        if(users[currentGameId+1][msg.sender].amount != 0) {
            require(users[currentGameId+1][msg.sender].poolChoice == 1, 'You already bet on down this game.');
            joined = true;
        }

        if(!joined){
            User memory user;
            user.amount = msg.value;
            user.poolChoice = 1;

            users[currentGameId+1][msg.sender] = user;
            userGames[msg.sender].push(currentGameId+1);
        }
        else users[currentGameId+1][msg.sender].amount += msg.value;

        nextGame.upAmount += msg.value;
        nextGame.totalAmount += msg.value;
        
        emit _joinUp(msg.sender, currentGameId+1, msg.value);
    }
    
    function joinDown() external payable{
        require(msg.value > 0, 'The amount should be greater than 0.');
        Game storage nextGame = Games[currentGameId+1];
        Game memory currentGame = Games[currentGameId];
        bool joined;
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game.');
        
        if(users[currentGameId+1][msg.sender].amount != 0) {
            require(users[currentGameId+1][msg.sender].poolChoice == 0, 'You already bet on up this game.');
            joined = true;
        }

        if(!joined){
            User memory user;
            user.amount = msg.value;
            user.poolChoice = 0;

            users[currentGameId+1][msg.sender] = user;
            userGames[msg.sender].push(currentGameId+1);
        }
        else users[currentGameId+1][msg.sender].amount += msg.value;

        nextGame.downAmount += msg.value;
        nextGame.totalAmount += msg.value;
                
        emit _joinDown(msg.sender, currentGameId+1, msg.value);
    }
    
    function reward(uint[] memory idGames) external{
        uint varReward;
        for(uint i=0; i < idGames.length; i++){
            uint idGame = idGames[i];
            User storage user = users[idGame][msg.sender];
            
            require(user.claimed == false, 'You already claim your rewards on this game.');
            require(Games[idGame].endTimestamp < block.timestamp, 'Game in progress.');
            require(user.amount > 0, 'amount = 0.');
            require(isWinner(idGame, msg.sender), 'You lost this game.');
            
            varReward += (user.amount*Games[idGame].rewardAmount)/Games[idGame].rewardPoolAmount;
            user.claimed = true;
        }
        
        (bool sent, ) = msg.sender.call{value: varReward}("");
        require(sent, "Failed to send.");
        
        emit _reward(msg.sender, idGames, varReward);
    }
    
    function rewardAdmin(address payable _address) external{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(feesAmount > 0, 'Empty treasury.');
        
        (bool sent, ) = _address.call{value: feesAmount}("");
        require(sent, "Failed to send.");
        
        feesAmount = 0;
        emit _rewardAdmin(_address, feesAmount);
    }

    function updateTreasury() private {
        Game storage currentGame = Games[currentGameId];
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
    
    function isWinner(uint idGame, address _address) public view returns(bool _isWinner){

        Game memory game = Games[idGame];
        Game memory lastGame = Games[idGame-1];

        if(block.timestamp < game.endTimestamp || !game.rewardCalculated || idGame == 0)    return false;

        User memory user = users[idGame][_address];
        
        return
            (lastGame.priceEnd != game.priceEnd) && 
            ((lastGame.priceEnd > game.priceEnd && user.poolChoice == 0) || 
                (lastGame.priceEnd < game.priceEnd && user.poolChoice == 1)); 
    }
    
    function getCurrentPrice() public view returns(int _price){
        (
            ,
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getUserGames(address _user) public view returns(uint[] memory games){
        return userGames[_user];
    }
    
    function getUserAvailableWins(address _user) public view returns(uint[] memory _winGames){
        uint[] memory games = userGames[_user];        
        uint[] memory tmpWinGames = new uint[](games.length);
        uint cpt = 0;
        
        for(uint i=0; i < games.length; i++){
            
            User memory user = users[games[i]][_user];
            if(!user.claimed && isWinner(games[i], _user)){
                tmpWinGames[cpt] = games[i];
                cpt++;
            }
        }

        if(cpt > 0){
            uint[] memory winGames = new uint[](cpt);
            for(uint i=0; i<cpt; i++){
                winGames[i] = tmpWinGames[i];
            }
            return winGames;
        }

        return new uint[](1);
    }

    function getUserWins(address _user) public view returns(uint[] memory _winGames){
        uint[] memory games = userGames[_user];        
        uint[] memory tmpWinGames = new uint[](games.length);
        uint cpt = 0;
        
        for(uint i=0; i < games.length; i++){
            
            if(isWinner(games[i], _user)){
                tmpWinGames[cpt] = games[i];
                cpt++;
            }
        }

        if(cpt > 0){
            uint[] memory winGames = new uint[](cpt);
            for(uint i=0; i<cpt; i++){
                winGames[i] = tmpWinGames[i];
            }
            return winGames;
        }

        return new uint[](1);
    }

    function getUserTotalAmount(address _user) public view returns(uint amountGames){
        uint[] memory games = userGames[_user];        
        
        for(uint i=0; i < games.length; i++){
            User memory user = users[games[i]][_user];
            amountGames += user.amount;
        }

        return amountGames;
    }

    function getUserWinAmount(address _user) public view returns(uint _winAmount){
        uint[] memory games = getUserWins(_user);      
                
        for(uint i=0; i < games.length; i++){
            User memory user = users[games[i]][_user];
            if(isWinner(games[i], _user)){
                _winAmount += (user.amount*Games[games[i]].rewardAmount)/Games[games[i]].rewardPoolAmount;
            }
        }

        return _winAmount;
    }

    function setIntervalSeconds(uint _intervalSeconds) external {
        require(msg.sender == admin, 'Admin only.');
        intervalSeconds = _intervalSeconds;
        
        emit _setIntervalTime(_intervalSeconds);
    }
    
}