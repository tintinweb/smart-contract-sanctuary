/**
 *Submitted for verification at Etherscan.io on 2021-11-26
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
        uint256 endTimestamp;
        uint256 priceEnd;
    }

    address public admin;
    Game[] public Games;
    uint public feesAmount;
    uint public feesRate;
    uint public currentGameId;
    uint public intervalSeconds;

    mapping(uint => mapping(address => User)) public users;
    mapping(address => uint[]) public userGames;
    
    event _initCycle();
    event _joinUp(address indexed _from, uint indexed _game, uint _value);
    event _joinDown(address indexed _from, uint indexed _game, uint _value);
    event _changeCurrentGame(uint indexed _lastGame, uint indexed _game);
    event _reward(address indexed _from, uint[] indexed _game, uint _value);
    event _updateTreasury(uint indexed _game);
    event _rewardAdmin(address indexed _address, uint _value);
    
    event _setIntervalTime(uint indexed update);
    
    constructor() public {
        admin = msg.sender;
        feesRate = 50; // 2% fees
        intervalSeconds = 1800;
    }
    
    // for a better understanding: 
        // 1 : Up et 0 : Down.
        // Current Pair : USDC/ETH => if the price of the pair goes up, then ETH is going down
        // and if the price of the pair goes down, then ETH is going up
        
    function initCycle() external{
        require(msg.sender == admin, 'Only admin can initiate a game.');
        
        Games.push(Game(0, 0, 0, 0, 0, false, block.timestamp+intervalSeconds, 0)); // gameId : 0
        addGameInQueue();
        
        emit _initCycle();
    }

    function addGameInQueue() private {
        Game storage currentGame = Games[currentGameId];
        
        Games.push(Game(0, 0, 0, 0, 0, false, currentGame.endTimestamp+intervalSeconds+intervalSeconds, 0));
    }
    
    function NextCurrentGame() external {
        Game storage game1 = Games[currentGameId];

        require(block.timestamp >= game1.endTimestamp && game1.rewardCalculated == false, 'This game is not finish.');

        uint256 lockPrice = getCurrentPrice();
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
        Game storage currentGame = Games[currentGameId];
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        users[currentGameId+1][msg.sender] = User(msg.sender, msg.value, 1, false);
        nextGame.totalAmount += msg.value;
        nextGame.upAmount += msg.value;
        userGames[msg.sender].push(currentGameId+1);
        
        emit _joinUp(msg.sender, currentGameId+1, msg.value);
    }
    
    function joinDown() external payable{
        require(msg.value > 0, 'You have to send some ether to play');
        Game storage nextGame = Games[currentGameId+1];
        Game storage currentGame = Games[currentGameId];
        
        require(block.timestamp < currentGame.endTimestamp, 'You can only join before the start of the game');
        require(users[currentGameId+1][msg.sender].amount == 0, 'You already join this game');
        
        users[currentGameId+1][msg.sender] = User(msg.sender, msg.value, 0, false);
        nextGame.totalAmount += msg.value;
        nextGame.downAmount += msg.value;
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

    function updateTreasury() private {
        Game storage currentGame = Games[currentGameId];
        require(block.timestamp >= currentGame.endTimestamp, 'Match is not already started.');

        uint256 rewardPoolAmountTmp; // amount(winnerPool)
        uint256 feesTmp; // fees(currentGame)
        uint256 rewardAmountTmp; // totalAmount(currentGame)

        if(currentGameId != 0){
            Game storage lastGame = Games[currentGameId-1];
            if (currentGame.priceEnd > lastGame.priceEnd) {
                rewardPoolAmountTmp = currentGame.downAmount;
                feesTmp = currentGame.totalAmount/feesRate; // 2% fee
                rewardAmountTmp = currentGame.totalAmount - feesTmp;
            }
            else if (currentGame.priceEnd < lastGame.priceEnd) {
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
        require(idGame > 0, 'Game 0 does not count');

        Game storage game = Games[idGame];
        Game storage lastGame = Games[idGame-1];

        require(game.endTimestamp < block.timestamp, 'This game is not finish.');
        require(game.rewardCalculated, 'rewards had not been calculated');
        
        User memory user = users[idGame][_address];
        
        return
            (lastGame.priceEnd != game.priceEnd) &&
            ((lastGame.priceEnd > game.priceEnd && user.poolChoice == 1) || // priceStart > priceEnd => sqrtPriceX96 decreased => ETH increased : because ETH is token1
                (lastGame.priceEnd < game.priceEnd && user.poolChoice == 0)); // priceStart < priceEnd => sqrtPriceX96 increased => ETH decreased : because ETH is token1
    }
    
    function getCurrentPrice() public view returns(uint256){
        //uint112[5] memory tab = [1229290056317128799135294879156141, 1229532543710816023845524457067642, 1222395350047539400173143296531789, 1222293434801171797756659293816224, 1231421516487407107686672961557180];
        
        return block.timestamp;
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
    
}