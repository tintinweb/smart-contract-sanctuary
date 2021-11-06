/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

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
        string name;
        uint nbPools;
        uint totalAmount;
        uint winnerPool;
        bool joinLocked;
        bool rewardLocked;
    }

    address private admin;
    Game[] private Games;

    mapping(uint => mapping(address => User)) public users;
    mapping(uint => mapping(uint => Pool)) public pools;

    constructor() public {
        admin = msg.sender;
    }
    
    function initGame(string memory _name, uint _nbPools) public {
        require(msg.sender == admin, 'Only admin can initiate a game');
        
        Games.push(Game(0, _name, _nbPools, 0, _nbPools+1, false, true));
    }
    
    function join(uint idGame, uint poolChoix) public payable{
        require(msg.value > 0, 'You have to send some ether to play');
        require(idGame >= 0 && idGame < Games.length, 'this Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(poolChoix >= 0 && poolChoix<chosenGame.nbPools, "Choice error : you should choose an existing pool");
        require(chosenGame.joinLocked == false, 'You can only join before the start of the game');
        
        users[idGame][msg.sender] = User(msg.sender, msg.value, poolChoix);
        pools[idGame][poolChoix].amount += msg.value;
        pools[idGame][poolChoix].nbPlayers += 1;
        Games[idGame].totalAmount += msg.value;
    }
    
    function reward(uint idGame, address payable _address) public payable{
        require(idGame >= 0 && idGame < Games.length, 'this Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(chosenGame.rewardLocked == false, 'the match is not finish.');
        require(users[idGame][_address].poolChoice == chosenGame.winnerPool, 'Only winners can get rewards.');
        
        
        users[idGame][_address].amount = (users[idGame][_address].amount*chosenGame.totalAmount)/pools[idGame][chosenGame.winnerPool].amount;
        uint amount = users[idGame][_address].amount;
        (bool sent, bytes memory data) = _address.call{value: amount}("");
        require(sent, "Failed to send Ether");
        users[idGame][_address].amount = 0;
    }
    
    function rewardAdmin(uint idGame, address payable _address) public payable{
        require(msg.sender == admin, 'Only admin can use this method.');
        require(Games[idGame].rewardLocked == false, 'Reward are not available actually.');
        (bool sent, bytes memory data) = _address.call{value: Games[idGame].fees}("");
        require(sent, "Failed to send Ether");
    }
    
    function currentMatchIsStarting(uint idGame) public{
        require(msg.sender == admin, 'Only admin can use this method.');
        Games[idGame].joinLocked = true;
    }

    function updateWinnerPool(uint idGame, uint _winnerPool) public {
        require(idGame >= 0 && idGame < Games.length, 'this Game doesnt exists');
        Game storage chosenGame = Games[idGame];
        require(msg.sender == admin, 'Only admin can use this method.');
        require(chosenGame.rewardLocked, 'The winner has already be chosen.');
        require(_winnerPool >= 0 && _winnerPool<chosenGame.nbPools, "Choice error : you should choose an existing pool");
        
        chosenGame.rewardLocked = false;
        chosenGame.winnerPool = _winnerPool;
        chosenGame.fees = chosenGame.totalAmount/100; // 1% fee
        chosenGame.totalAmount -= chosenGame.fees;
        
        /*for(uint i=0; i < chosenGame.usersAddress.length; i++){
            if(users[idGame][chosenGame.usersAddress[i]].poolChoice == chosenGame.winnerPool){
                users[idGame][chosenGame.usersAddress[i]].amount = (users[idGame][chosenGame.usersAddress[i]].amount*chosenGame.totalAmount)/pools[idGame][chosenGame.winnerPool].amount;
            }else{
                users[idGame][chosenGame.usersAddress[i]].amount = 0;
            }
        }*/
    }
    
    function getGame(uint index) public view returns(Game memory){
        require(index < Games.length, 'index out of range : try a right Game id.');
        return Games[index];
    }
}