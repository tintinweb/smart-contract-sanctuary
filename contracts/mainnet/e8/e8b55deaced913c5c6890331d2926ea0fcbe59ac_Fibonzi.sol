pragma solidity ^0.4.15;

contract Fibonzi{
    
    address owner;
    uint8 poolCount = 0;
    uint8 playerCount = 0;
    uint8 poolJoinedCount = 0;
    uint fiboIndex = 0;
    uint poolToCreate = 0;
    uint8 tokenCount = 0;
    uint8 tokenUsed = 0;
    uint8 fiboMax = 0;
    uint8 tokenToReward = 0;
    uint currentShare = 0;
    
    struct Player{
        uint8 playerId;
        address wallet;
        uint playerBalance;
    }
    
    struct Pool{
        uint8 poolId;
        uint price;
        uint8 owner;
    }
    
    struct Token{
        uint8 tokenId;
        uint8 playerId;
        bool used;
    }

    mapping(uint8 => Player) players;
    mapping(uint8 => Pool) pools;
    mapping(address => uint8) playersWallets;
    mapping(address => Token[]) playersToken;
    mapping(address => uint) playersBalance;
    
    event PlayerCreated(uint8 indexed playerId, address indexed wallet,uint timestamp);
    event PlayerBalance(uint8 indexed playerId, uint playerBalance, uint timestamp);
    event PoolCreated(uint8 indexed poolId,uint price, uint timestamp);
    event PoolJoined(uint8 indexed poolId, uint8 indexed playerId, uint256 price, uint timestamp);
    event PoolPrize(uint8 indexed poolId, uint8 indexed playerId, uint prize, uint timestamp);
    event TokenCreated(uint8 indexed tokenId, uint8 indexed playerId);
    event TokenUsed(uint8 indexed tokenId, uint8 indexed playerId);
    
    function Fibonzi(){
        owner = msg.sender;
        createPlayer();
        createPool();
        fiboIndex++;
        fiboMax = 18;
    }
    
    function openPool(uint8 poolId) payable{
        assert(poolCount >= poolId);
        assert(playersWallets[msg.sender] > 0);
        assert(msg.sender == players[playersWallets[msg.sender]].wallet);
        assert(msg.value >= pools[poolId].price);
        assert(getPlayerUsableTokensCount() > 0);
        assert(usePlayerToken());
        
        var price = pools[poolId].price;
        owner.transfer(price);
        PoolPrize(poolId,pools[poolId].owner,2*price,now);
        //change the owner of the pool as the current player
        pools[poolId].owner = players[playersWallets[msg.sender]].playerId;
        
        //return the change if any
        if(msg.value > pools[poolId].price){
            players[playersWallets[msg.sender]].wallet.transfer(msg.value - pools[poolId].price);
        }
        
        //double the price of the pool
        pools[poolId].price = 2*price;
        PoolJoined(poolId,playersWallets[msg.sender],pools[poolId].price,now);
        poolJoinedCount++;
        
        if(fiboIndex <= fiboMax){
            createPoolIfNeeded();
        }
    }
    
    function joinPool(uint8 poolId) payable{
        assert(poolCount >= poolId);
        assert(playersWallets[msg.sender] > 0);
        assert(msg.sender == players[playersWallets[msg.sender]].wallet);
        assert(players[playersWallets[msg.sender]].playerId != pools[poolId].owner);
        assert(msg.value >= pools[poolId].price);
        assert( (pools[poolId].owner == owner && poolCount == 1) || (pools[poolId].owner != players[0].playerId));
        
        //send the amount to the owner
        uint price = pools[poolId].price;
        players[pools[poolId].owner].wallet.transfer((price * 80)/100);
        //distribute the 20% to all token holders
        distributeReward(price);
        
        PoolPrize(poolId,pools[poolId].owner,2*price,now);
        //change the owner of the pool as the current player
        pools[poolId].owner = players[playersWallets[msg.sender]].playerId;
        
        //return the change if any
        if(msg.value > pools[poolId].price){
            players[playersWallets[msg.sender]].wallet.transfer(msg.value - pools[poolId].price);
        }
        
        //double the price of the pool
        pools[poolId].price = 2*price;
        PoolJoined(poolId,playersWallets[msg.sender],pools[poolId].price,now);
        poolJoinedCount++;
        
        if(fiboIndex <= fiboMax){
            createPoolIfNeeded();
        }
        //give token to the current player
        createPlayerToken();
    }
    
    function distributeReward(uint price) internal{
        if(tokenCount - tokenUsed > 0){
            tokenToReward = tokenCount - tokenUsed;
            uint share = (price*20/100)/(tokenCount - tokenUsed);
            currentShare = share;
            for(uint8 i=0; i< playerCount;i++){
                uint count = 0;
                for(uint8 j=0;j< playersToken[players[i+1].wallet].length;j++){
                    if(!playersToken[players[i+1].wallet][j].used){
                       count++; 
                    }
                }
                if(count > 0){
                    players[i+1].playerBalance += share*count;
                    playersBalance[players[i+1].wallet] = players[i+1].playerBalance;
                    PlayerBalance(players[i+1].playerId,players[i+1].playerBalance,now);   
                }
            }
        }
        else{
            // no token owner => send to owner
            players[playersWallets[owner]].playerBalance += (price*20/100);
            playersBalance[owner] = players[playersWallets[owner]].playerBalance;
            PlayerBalance(players[playersWallets[owner]].playerId,players[playersWallets[owner]].playerBalance,now);   
        }
    }
    
    function withdraw(){
        assert(playersWallets[msg.sender] > 0);
        assert(getPlayerUsableTokensCount()>10);
        assert(playersBalance[msg.sender] >0);
        
        players[playersWallets[msg.sender]].wallet.transfer(playersBalance[msg.sender]);
        for(uint i=0;i<10;i++){
            usePlayerToken();
        }
        players[playersWallets[msg.sender]].playerBalance = 0;
        playersBalance[players[playersWallets[msg.sender]].wallet] = 0;
        PlayerBalance(players[playersWallets[msg.sender]].playerId,0,now);   
    }
    
    //someone has to call create pool
    function createPool() internal{
        poolCount++;
        pools[poolCount] = Pool(poolCount,1e16,players[1].playerId);
        PoolCreated(poolCount,1e16,now);
        
    }
    
    function createPlayer() returns (uint256){
        for(uint8 i=0; i< playerCount;i++){
            assert(players[i+1].wallet != msg.sender);
        }
        
        playerCount++;
        players[playerCount] = Player(playerCount,msg.sender,0);
        playersWallets[msg.sender] = playerCount;
        PlayerCreated(playersWallets[msg.sender],msg.sender,now);
        return playerCount;
    }
    
    function createPoolIfNeeded() internal{
        var currentFibo = getFibo(fiboIndex);
        if(poolJoinedCount > currentFibo){
            fiboIndex++;
            createPoolIfNeeded();
        }
        else if(poolJoinedCount == currentFibo){
            if(currentFibo > poolCount){
                poolToCreate = currentFibo - poolCount;
                for(uint i=0; i< poolToCreate; i++){
                    createPool();
                    //add Token to the player who generates the pools
                    createPlayerToken();
                }
                poolToCreate = 0;
            }
        }
    }
    
    function createPlayerToken() internal{
        tokenCount++;
        playersToken[msg.sender].push(Token(tokenCount,players[playersWallets[msg.sender]].playerId,false));
        TokenCreated(tokenCount,players[playersWallets[msg.sender]].playerId);
        if(tokenCount % 9 == 0){
            tokenCount++;
            playersToken[owner].push(Token(tokenCount,players[playersWallets[owner]].playerId,false));
            TokenCreated(tokenCount,players[playersWallets[owner]].playerId);
        }
    }
    
    function getFibo(uint n) internal returns (uint){
        if(n<=1){
            return n;
        }
        else{
            return getFibo(n-1) + getFibo(n-2);
        }
    }
    
    function getPlayerUsableTokensCount() internal returns (uint8){
        uint8 count = 0;
        for(uint8 i=0;i< playersToken[msg.sender].length;i++){
            if(!playersToken[msg.sender][i].used){
               count++; 
            }
        }
        return count;
    }
    
    function usePlayerToken() internal returns (bool){
        var used = false;
        for(uint8 i=0;i< playersToken[msg.sender].length;i++){
            if(!playersToken[msg.sender][i].used && !used){
                playersToken[msg.sender][i].used = true;
                used = true;
                tokenUsed++;
                TokenUsed(playersToken[msg.sender][i].tokenId,playersToken[msg.sender][i].playerId);
            }
        }
        return used;
    }
}