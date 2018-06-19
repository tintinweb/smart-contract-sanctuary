pragma solidity ^0.4.15;

contract Fibonzi{

    address owner;
    
    uint8 public poolCount = 0;
    uint8 public playersCount = 0;
    uint8 public transactionsCount = 0;
    uint8 public fibonacciIndex = 0;
    uint8 public fibokenCreatedCount = 0;
    uint8 public fibokenUsedCount = 0;
    uint fibonacciMax = 18;
    uint public poolsToCreate = 0;
    address[] public playersList;
    
    struct Player{
        address wallet;
        uint balance;
    }
    
    struct Pool{
        uint8 poolId;
        uint price;
        address owner;
    }
    
    struct Fiboken{
        uint8 fibokenId;
        address owner;
        bool isUsed;
    }
    
    mapping(address => Player) players;
    mapping(address => Fiboken[]) playersFibokens;
    mapping(address => uint) playersBalance;
    mapping(uint8 => Pool) pools;
    
    event PlayerCreated(address indexed wallet, uint timestamp);
    event PlayerBalance(address playerWallet, uint playerBalance, uint timestamp);
    event FibokenCreated(uint8 tokenId, address wallet, uint timestamp);
    event FibokenUsed(uint8 tokenId,address wallet, uint timestamp);
    event PoolCreated(uint8 indexed poolId,uint price,uint timestamp);
    event PoolJoined(uint8 indexed poolId, address indexed wallet,uint price,uint timestamp);
    
    
    function Fibonzi(){
        owner = msg.sender;
        createPlayer();
        createPool();
        fibonacciIndex++;
    }
    
    function openPool(uint8 poolId) payable{
        assert(poolCount >= poolId);
        assert(isPlayer());
        assert(msg.value >= pools[poolId].price);
        assert(getUsablePlayerFibokens(msg.sender) > 0);
        assert(usePlayerFiboken());
        
        uint price = pools[poolId].price;
        owner.transfer(price);
        pools[poolId].owner = msg.sender;
        
        if(msg.value > pools[poolId].price){
            msg.sender.transfer(msg.value - pools[poolId].price);
        }
        
        pools[poolId].price = 4*price;
        PoolJoined(poolId,msg.sender,pools[poolId].price,now);
        ++transactionsCount;
        
        if(fibonacciIndex <= fibonacciMax){
            createPoolsIfNeeded();
        }
        getPoolPrices();
    }
    
    function joinPool(uint8 poolId) payable{
        assert(poolCount >= poolId);
        assert(msg.sender != pools[poolId].owner);
        assert(msg.value >= pools[poolId].price);
        assert( ( pools[poolId].owner == owner && poolCount == 1) || (pools[poolId].owner != owner) );
        
        //Register the player if not registered
        if(!isPlayer()){
            createPlayer();   
        }
        
        if(msg.value > pools[poolId].price){
            msg.sender.transfer(msg.value - pools[poolId].price);
        }
        
        uint price = pools[poolId].price;
        pools[poolId].owner.transfer((price * 80)/100);
        
        splitComissions((price *20)/100);
        pools[poolId].owner = msg.sender;
        pools[poolId].price = 2*price;
        
        PoolJoined(poolId,msg.sender,pools[poolId].price,now);
        ++transactionsCount;
        
        if(fibonacciIndex <= fibonacciMax){
            createPoolsIfNeeded();
        }
        
        rewardFiboken();
        getPoolPrices();
    }
    
    function withdrawComission(){
        assert(isPlayer());
        assert(players[msg.sender].balance > 0);
        assert(getUsablePlayerFibokens(msg.sender) >= 10);
        
        for(uint i=0;i<10;i++){
            usePlayerFiboken();
        }
        
        msg.sender.transfer(players[msg.sender].balance);
        players[msg.sender].balance = 0;
        PlayerBalance(msg.sender,players[msg.sender].balance,now);
    }
    
    function isPlayer() internal returns (bool){
        bool isPlayerFlag = false;
        for(uint8 i=0; i< playersCount;i++){
            if(playersList[i] == msg.sender){
                isPlayerFlag = true;
            }
        }
        return isPlayerFlag;
    }
    
    function createPlayer() internal{
        if(!isPlayer()){
            playersCount++;
            players[msg.sender] = Player(msg.sender,0);
            PlayerCreated(msg.sender,now);
            playersList.push(msg.sender);
        }
        getFibonziPlayers();   
    }
    
    function createPool() internal{
        poolCount++;
        pools[poolCount] = Pool(poolCount, 1e15,owner);
        PoolCreated(poolCount,1e15,now);
    }
    
    function createPoolsIfNeeded() internal{
        uint currentFibonacci = getFibonacci(fibonacciIndex);
        if(transactionsCount == currentFibonacci){
            if(currentFibonacci > poolCount){
                poolsToCreate = currentFibonacci - poolCount;
                for(uint8 i =0; i < poolsToCreate; i++ ){
                    createPool();
                    rewardFiboken();
                }
            }
        }
        else if(transactionsCount > currentFibonacci){
            fibonacciIndex++;
            createPoolsIfNeeded();
        }
    }
    
    function splitComissions(uint price) internal{
        if(fibokenCreatedCount > fibokenUsedCount){
            uint share = price/(fibokenCreatedCount - fibokenUsedCount);
            for(uint8 i=0; i< playersCount;i++){
                uint8 usableTokens = getUsablePlayerFibokens(playersList[i]);
                if(usableTokens > 0){
                    players[playersList[i]].balance += share*usableTokens;
                    PlayerBalance(playersList[i],players[playersList[i]].balance,now);
                }
            }
        }
        else{
            players[owner].balance += price;
            PlayerBalance(owner,players[owner].balance,now);
        }
    }
    
    function rewardFiboken() internal{
        fibokenCreatedCount++;
        playersFibokens[msg.sender].push(Fiboken(fibokenCreatedCount,msg.sender,false));
        FibokenCreated(fibokenCreatedCount,msg.sender,now);
        if(fibokenCreatedCount % 9 == 0){
            ++fibokenCreatedCount;
            playersFibokens[owner].push(Fiboken(fibokenCreatedCount,owner,false));
            FibokenCreated(fibokenCreatedCount,owner,now);
        }
    }
    
    function usePlayerFiboken() internal returns (bool){
        var used = false;
        for(uint8 i=0; i<playersFibokens[msg.sender].length;i++){
            if(!playersFibokens[msg.sender][i].isUsed && !used){
                playersFibokens[msg.sender][i].isUsed = true;
                used = true;
                ++fibokenUsedCount;
                FibokenUsed(playersFibokens[msg.sender][i].fibokenId,msg.sender,now);
            }
        }
        
        return used;
    }
    
    function getUsablePlayerFibokens(address someAddress) internal returns (uint8){
        uint8 playerFibokens = 0;
        for(uint8 i=0; i< playersFibokens[someAddress].length;i++){
            if(!playersFibokens[someAddress][i].isUsed){
                ++playerFibokens;       
            }
        }
        return playerFibokens;
    }
    
    function getFibonacci(uint n) internal returns (uint){
        if(n<=1){
            return n;
        }
        else{
            return getFibonacci(n-1) + getFibonacci(n-2);
        }
    }
    
    function getPoolIds() constant returns(uint8[]){
        uint8[] memory poolIds = new uint8[](poolCount);
        for(uint8 i = 1; i< poolCount+1; i++){
            poolIds[i-1] = pools[i].poolId;
        }
        return poolIds;
    }
    
    function getPoolPrices() constant returns(uint[]){
        uint[] memory poolPrices = new uint[](poolCount);
        for(uint8 i = 1; i< poolCount+1; i++){
            poolPrices[i-1] = pools[i].price;
        }
        return poolPrices;
    }
    
    function getPoolOwners() constant returns(address[]){
        address[] memory poolOwners = new address[](poolCount);
        for(uint8 i = 1; i< poolCount+1; i++){
            poolOwners[i-1] = pools[i].owner;
        }
        return poolOwners;
    }
    
    function getFibonziPlayers() constant returns(address[]){
        address[] memory fibonziPlayers = new address[](playersCount);
        for(uint8 i = 0; i< playersCount ; i++){
            fibonziPlayers[i] = playersList[i];
        }
        return fibonziPlayers;
    }
    
    function getPlayersBalances() constant returns(uint[]){
        uint[] memory playersBalances = new uint[](playersCount);
        for(uint8 i = 0; i< playersCount ; i++){
            playersBalances[i] = players[playersList[i]].balance;
        }
        return playersBalances;
    }
    
    function getPlayersFibokens() constant returns(uint[]){
        uint[] memory playersTokens = new uint[](playersCount);
        for(uint8 i = 0; i< playersCount ; i++){
            uint sum = 0;
            for(uint j = 0; j <playersFibokens[playersList[i]].length;j++){
                if(!playersFibokens[playersList[i]][j].isUsed){
                    sum++;
                }
            }
            playersTokens[i] = sum;
        }
        return playersTokens;
    }
    
}