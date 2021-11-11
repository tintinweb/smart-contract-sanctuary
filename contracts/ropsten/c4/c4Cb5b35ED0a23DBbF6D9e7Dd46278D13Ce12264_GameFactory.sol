/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

pragma solidity >=0.7.0 <0.9.0;

contract GameFactory {
    
    struct User{
        address _address;
        uint amount;
        uint poolChoice;
    }
    
    struct Pool{
        uint amount;
        uint nbPlayers;
    }
    
    struct Game{
        uint fees;
        string team1;
        string team2;
        uint nbPools;
        uint totalAmount;
        uint winnerPool;
        bool joinLocked;
        bool rewardLocked;
        string category;
    }

    address private admin;
    Game[] private Games;

    mapping(uint => mapping(address => User)) private users;
    mapping(uint => mapping(uint => Pool)) private pools;

    constructor() public {
        admin = msg.sender;
    }
    
    // for a better understanding, team1 will always be home teams and team2 away teams.

    function initGame(string memory _team1, string memory _team2, string memory _category, uint _nbPools) public {
        require(msg.sender == admin, 'Only admin can initiate a game');
        Games.push(Game(0, _team1, _team2, _nbPools, 0, _nbPools+1, false, true, _category));
    }
    
    function join(uint idGame, uint poolChoice) public payable{
        require(msg.value > 0, 'You have to send some ether to play');
        require(idGame < Games.length, 'This Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(poolChoice < chosenGame.nbPools, 'Choice error : you should choose an existing pool');
        require(chosenGame.joinLocked == false, 'You can only join before the start of the game');
        
        users[idGame][msg.sender] = User(msg.sender, msg.value, poolChoice);
        pools[idGame][poolChoice].amount += msg.value;
        pools[idGame][poolChoice].nbPlayers += 1;
        Games[idGame].totalAmount += msg.value;
    }
    
    function reward(uint idGame) public{
        require(idGame < Games.length, 'This Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(chosenGame.rewardLocked == false, 'This match is not finish.');
        require(users[idGame][msg.sender].amount != 0, 'You did not participate or already use your reward.');
        require(users[idGame][msg.sender].poolChoice == chosenGame.winnerPool, 'Only winners can get rewards.');
        
        
        users[idGame][msg.sender].amount = (users[idGame][msg.sender].amount*chosenGame.totalAmount)/pools[idGame][chosenGame.winnerPool].amount;
        uint amount = users[idGame][msg.sender].amount;
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        users[idGame][msg.sender].amount = 0;
    }
    
    function rewardAdmin(uint idGame, address payable _address) public{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(Games[idGame].rewardLocked == false, 'Reward are not available actually.');
        (bool sent, bytes memory data) = _address.call{value: Games[idGame].fees}("");
        require(sent, "Failed to send Ether");
    }
    
    function currentMatchIsStarting(uint idGame) public{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(Games[idGame].joinLocked == false, 'Match has already started.');
        Games[idGame].joinLocked = true;
    }

    function updateWinnerPool(uint idGame, uint _winnerPool) public {
        require(idGame >= 0 && idGame < Games.length, 'This Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(chosenGame.joinLocked == true, 'Match has not already started.');
        require(msg.sender == admin, 'Only admin can use this method.');
        require(chosenGame.rewardLocked, 'Winner pool has already be chosen.');
        require(_winnerPool >= 0 && _winnerPool<chosenGame.nbPools, 'Choice error : you should choose an existing pool');
        
        chosenGame.rewardLocked = false;
        chosenGame.winnerPool = _winnerPool;
        chosenGame.fees = chosenGame.totalAmount/100; // 1% fee
        chosenGame.totalAmount -= chosenGame.fees;
    }
    
    function getGame(uint idGame) public view returns(Game memory){
        require(idGame < Games.length, 'Index out of range : try a right Game id.');
        return Games[idGame];
    }
    
    function getUserByIdGame(uint idGame, address _address) public view returns(User memory){
        require(idGame < Games.length, 'Index out of range : try a right Game id.');
        return users[idGame][_address];
    }
    
    function getPoolByIdGame(uint idGame, uint idPool) public view returns(Pool memory){
        require(idGame < Games.length, 'Index out of range : try a right Game id.');
        require(idPool < Games[idGame].nbPools, 'Index out of range : try a right pool id.');
        return pools[idGame][idPool];     
    }
}