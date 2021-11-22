/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract testbinopt {
    
    struct User{
        address _address;
        uint amount;
        uint poolChoice;
        bool claimed;
    }
    
    struct Game{
        uint upAmount;
        uint downAmount;
        uint totalAmount;
        uint rewardAmount;
        uint rewardPoolAmount;
        bool rewardCalculated;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint160 priceStart;
        uint160 priceEnd;
        bool canceled;
    }

    address public admin;
    Game[] public Games;
    uint public feesAmount;
    uint public feesRate;
    uint public currentGameId;
    uint public intervalSeconds;
    uint public transactionTime;

    mapping(uint => mapping(address => User)) public users;
    mapping(address => uint[]) public userGames;
    
    event _initCycle();
    event _joinUp(address indexed _from, uint indexed _game, uint _value);
    event _joinDown(address indexed _from, uint indexed _game, uint _value);
    event _changeCurrentGame(uint indexed _game, uint indexed _nextGame);
    event _reward(address indexed _from, uint[] indexed _game, uint _value);
    event _updateTreasury(uint indexed _game);
    event _rewardAdmin(address indexed _address, uint _value);
    
    event _setIntervalTime(uint indexed update);
    event _setTransactionTime(uint indexed update);
    
    constructor() public {
        admin = msg.sender;
        feesRate = 50; // 2% fees
        intervalSeconds = 300;
        transactionTime = 30;
    }
    
    // for a better understanding: 
        // 1 : Up et 0 : Down.
        // Current Pair : USDC/ETH => if the price of the pair goes up, then ETH is going down
        // and if the price of the pair goes down, then ETH is going up
        
    function initCycle() external{
        require(msg.sender == admin, 'Only admin can initiate a game.');
        
        Games.push(Game(0, 0, 0, 0, 0, false, block.timestamp, block.timestamp+intervalSeconds, 0, 0, false)); // gameId : 0
        addGameInQueue();
        
        emit _initCycle();
    }

    function addGameInQueue() private {
        uint160 currentprice = getCurrentPrice();
        Games.push(Game(0, 0, 0, 0, 0, false, block.timestamp+intervalSeconds+transactionTime, block.timestamp+transactionTime+intervalSeconds+intervalSeconds, currentprice, 0, false));
    }
    
    function NextCurrentGame() external {
        require(msg.sender == admin, 'Only admin can initiate a game.');
        require(block.timestamp >= Games[currentGameId].endTimestamp, 'This game is not finish.');

        Game storage game = Games[currentGameId];
        require(game.rewardCalculated == false);
        
        uint160 currentprice = getCurrentPrice();
        game.priceEnd = currentprice;
        
        updateTreasury(currentGameId);
        require(game.rewardCalculated, 'rewardCalculated failed');
        
        currentGameId += 1;
        addGameInQueue();
        
        emit _changeCurrentGame(currentGameId-1, currentGameId);
    }
    
    function NextCurrentGameChecker() external view returns (bool available){
        return block.timestamp >= Games[currentGameId].endTimestamp && Games[currentGameId].rewardCalculated == false;
    }
    
    function joinUp() external payable{
        require(msg.value > 0, 'You have to send some ether to play');
        Game storage game = Games[currentGameId+1];
        
        require(block.timestamp < game.startTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        users[currentGameId+1][msg.sender] = User(msg.sender, msg.value, 1, false);
        game.totalAmount += msg.value;
        game.upAmount += msg.value;
        userGames[msg.sender].push(currentGameId+1);
        
        emit _joinUp(msg.sender, currentGameId+1, msg.value);
    }
    
    function joinDown() external payable{
        require(msg.value > 0, 'You have to send some ether to play');
        Game storage game = Games[currentGameId+1];
        
        require(block.timestamp < game.startTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        users[currentGameId+1][msg.sender] = User(msg.sender, msg.value, 0, false);
        game.totalAmount += msg.value;
        game.downAmount += msg.value;
        userGames[msg.sender].push(currentGameId+1);
        
        emit _joinDown(msg.sender, currentGameId+1, msg.value);
    }
    
    function reward(uint[] memory idGames) external{
        uint reward = 0;
        for(uint i=0; i < idGames.length; i++){
            uint idGame = idGames[i];
            User storage user = users[idGame][msg.sender];
            
            require(user.claimed == false, 'You already claim your rewards on this game');
            require(Games[idGame].endTimestamp < block.timestamp, 'This game is not finish.');
            require(user.amount > 0, 'amount = 0');
            require(isWinner(idGame, msg.sender), 'You lost this game.');
            
            reward += (user.amount*Games[idGame].rewardAmount)/Games[idGame].rewardPoolAmount;
            user.claimed = true;
        }
        
        (bool sent, bytes memory data) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send Ether");
        
        emit _reward(msg.sender, idGames, reward);
    }
    
    function rewardAdmin(address payable _address) external{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(feesAmount > 0, 'Empty treasury.');
        
        (bool sent, bytes memory data) = _address.call{value: feesAmount}("");
        require(sent, "Failed to send Ether");
        
        emit _rewardAdmin(_address, feesAmount);
    }

    function updateTreasury(uint idGame) private {
        Game storage currentGame = Games[idGame];
        require(block.timestamp >= Games[currentGameId].startTimestamp, 'Match has not already started.');

        uint256 rewardPoolAmountTmp; // amount(winnerPool)
        uint256 feesTmp; // fees(currentGame)
        uint256 rewardAmountTmp; // totalAmount(currentGame)

        if (currentGame.priceEnd > currentGame.priceStart) {
            rewardPoolAmountTmp = currentGame.upAmount;
            feesTmp = currentGame.totalAmount/feesRate; // 2% fee
            rewardAmountTmp = currentGame.totalAmount - feesTmp;
        }
        else if (currentGame.priceEnd < currentGame.priceStart) {
            rewardPoolAmountTmp = currentGame.downAmount;
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
        currentGame.rewardCalculated = true;
        
        emit _updateTreasury(idGame);
    }
    
    function isWinner(uint idGame, address _address) public view returns(bool){
        Game memory game = Games[idGame];
        require(Games[idGame].endTimestamp < block.timestamp, 'This game is not finish.');
        require(game.rewardCalculated, 'rewards had not been calculated');
        User memory user = users[idGame][_address];
        
        return
            (game.priceStart != game.priceEnd) &&
            ((game.priceStart > game.priceEnd && user.poolChoice == 1) || // priceStart > priceEnd => sqrtPriceX96 decreased => ETH increased : because ETH is token1
                (game.priceStart < game.priceEnd && user.poolChoice == 0)); // priceStart < priceEnd => sqrtPriceX96 increased => ETH decreased : because ETH is token1
    }
    
    function getCurrentPrice() public view returns(uint160){
        //uint112[5] memory tab = [1229290056317128799135294879156141, 1229532543710816023845524457067642, 1222395350047539400173143296531789, 1222293434801171797756659293816224, 1231421516487407107686672961557180];
        
        return uint160(currentGameId);
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
        
        if(cpt > 0){
            uint[] memory rewardablesGames = new uint[](cpt);
            
            for(uint i=0; i < cpt; i++){
                rewardablesGames[i] = tmpRewardablesGames[i];
            }
            
            return tmpRewardablesGames;
        }
        
        return new uint[](1); // if [0] => no rewardable game
    }
    
    function setIntervalSeconds(uint _intervalSeconds) external {
        require(msg.sender == admin, 'Only admin can use this method.');
        intervalSeconds = _intervalSeconds;
        
        emit _setIntervalTime(_intervalSeconds);
    }
    
    function setTransactionTime(uint _transactionTime) external {
        require(msg.sender == admin, 'Only admin can use this method.');
        transactionTime = _transactionTime;
        
        emit _setTransactionTime(_transactionTime);
    }
    
}