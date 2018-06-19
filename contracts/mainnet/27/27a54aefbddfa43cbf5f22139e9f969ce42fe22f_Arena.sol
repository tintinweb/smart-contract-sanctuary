//Gladiate

pragma solidity ^0.4.21;

library gladiate {
    enum Weapon {None, Knife, Sword, Spear}
    enum GladiatorState {Null, Incoming, Active, Outgoing}
    
    struct Gladiator {
        GladiatorState state;
        uint stateTransitionBlock;
        uint8 x;
        uint8 y;
        Weapon weapon;
        uint8 coins;
    }
}

contract Arena {
    uint8 pseudoRandomNonce;
    function pseudoRandomUint8(uint8 limit)
    internal
    returns (uint8) {
        return uint8(keccak256(block.blockhash(block.number-1), pseudoRandomNonce)) % limit;
        pseudoRandomNonce++;
    }
    
    uint constant public coinValue = 50000000000000000; // 0.05 ETH
    
    uint constant spawnTime = 3;
    uint constant despawnTime = 2;
    
    address public emperor;
    mapping (address => gladiate.Gladiator) public gladiators;
    
    struct Tile {
        uint coins;
        gladiate.Weapon weapon;
        address gladiator;
    }
    
    Tile[10][10] tiles;
    
    function Arena()
    public {
        emperor = msg.sender;
    }
    
    modifier onlyEmporer() 
        {require(msg.sender == emperor); _;}
    modifier gladiatorExists(address owner) 
        {require(gladiators[owner].state != gladiate.GladiatorState.Null); _;}
    modifier gladiatorInState(address owner, gladiate.GladiatorState s) 
        {require(gladiators[owner].state == s); _;}
    
    function startGladiatorWithCoin(uint8 x, uint8 y, address owner)
    internal {
        gladiators[owner].state = gladiate.GladiatorState.Incoming;
        gladiators[owner].stateTransitionBlock = block.number + spawnTime;
        gladiators[owner].x = x;
        gladiators[owner].y = y;
        gladiators[owner].coins = 1;
        
        tiles[x][y].gladiator = owner;
    }
    
    function despawnGladiatorAndAwardCoins(address owner)
    internal {
        owner.transfer(gladiators[owner].coins * coinValue);
        
        gladiators[owner].state = gladiate.GladiatorState.Null;
    }
    
    function addCoins(uint8 x, uint8 y, uint amount)
    internal {
        tiles[x][y].coins += amount;
    }
    
    function throwIn()
    external
    payable 
    returns (bool) {
        require(gladiators[msg.sender].state == gladiate.GladiatorState.Null);
        require(msg.value == coinValue);
        
        uint8 lastX;
        uint8 lastY;
        for (uint8 i=0; i<3; i++) {
            uint8 x = pseudoRandomUint8(10);
            uint8 y = pseudoRandomUint8(10);
            lastX = x;
            lastY = y;
            
            if (tiles[x][y].gladiator == 0x0) {
                startGladiatorWithCoin(x, y, msg.sender);
                return true;
            }
        }
        //Couldn&#39;t find a place for the gladiator. Let&#39;s take the money anyway and put it in the Arena.
        //Ether is already in the contract unless we revert, so just have to put a coin somewhere
        addCoins(lastX, lastY, 1);
        return false;
    }
    
    function activateGladiator(address who)
    external
    gladiatorExists(who)
    gladiatorInState(who, gladiate.GladiatorState.Incoming) {
        require(gladiators[who].stateTransitionBlock <= block.number);
        
        gladiators[who].state = gladiate.GladiatorState.Active;
        gladiators[who].stateTransitionBlock = (uint(0) - 1);//max int
    }
    
    function imOut()
    external
    gladiatorInState(msg.sender, gladiate.GladiatorState.Active) {
        gladiators[msg.sender].state = gladiate.GladiatorState.Outgoing;
        gladiators[msg.sender].stateTransitionBlock = block.number + despawnTime;
    }
    
    function getOut()
    external
    gladiatorInState(msg.sender, gladiate.GladiatorState.Outgoing) {
        require(gladiators[msg.sender].stateTransitionBlock <= block.number);
        
        despawnGladiatorAndAwardCoins(msg.sender);
    }
    
    function nextBlock() 
    public {
        gladiators[0x0].coins ++;
    }
}