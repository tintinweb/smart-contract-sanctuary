/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity 0.5.1;

contract BettingApp {
    
    
    uint256 gameId = 0;
    uint256 lastGameId = 0;
    string winner = "TIE";
    uint256 gamingTime;
    address payable admin;
    
    mapping(uint256 => Game) games;
    
    struct Game {
        
        uint256 id;
        string user;
        string colour;
        uint256 amount;
        address payable player;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not an admin.");
        _;
    }
    
    modifier onlyPlayer() {
        require(msg.sender != admin, "You're not a player.");
        _;
    }
    
    modifier isGamingTime() {
        require(block.timestamp <= gamingTime, "Wait for next the next Game.");
        _;
    }
    
    event Result(uint256 id, string user, string colour, uint256 amount, address player, uint256 reward, string result, uint256 time);
    
    constructor() public {
        admin = msg.sender;
    }
    
    function initGame(uint256 _timestamp) public payable onlyAdmin {
        gamingTime = _timestamp;
    }
    
    function betGame(string memory _user, string memory _colour) public payable isGamingTime onlyPlayer returns(bool) {
        
        require((keccak256(abi.encodePacked(_colour)) == keccak256(abi.encodePacked("RED"))) || (keccak256(abi.encodePacked(_colour)) == keccak256(abi.encodePacked("GREEN"))), "Colour must be RED or GREEN");
        
        games[gameId] = Game(gameId, _user, _colour, msg.value, msg.sender);
        gameId += 1;
        return true;
    }
    
    function playGame() public payable onlyAdmin {
        
        uint256 redAmount = 0;
        uint256 greenAmount = 0;
        
        for(uint256 i=lastGameId; i<gameId; i++) {
            
            if(keccak256(abi.encodePacked(games[i].colour)) == keccak256(abi.encodePacked("RED"))) {
                redAmount += games[i].amount;
            } else {
                greenAmount += games[i].amount;
            }
        }
        
        if(redAmount < greenAmount) {
            winner = "RED";
        } else if(greenAmount < redAmount) {
            winner = "GREEN";
        } else if(greenAmount == redAmount){
            winner = "TIE";
        }
        
    }
    
    function sendReward() public payable onlyAdmin {
        
        for(uint256 i=lastGameId; i<gameId; i++) {
            
            uint256 reward = 0;
            string memory result = "Lose";
            
            if(keccak256(abi.encodePacked(winner)) == keccak256(abi.encodePacked(games[i].colour))) {

                reward = games[i].amount * 2;
                result = "Win";
                games[i].player.transfer(reward);
            }
            
            if(keccak256(abi.encodePacked(winner)) == keccak256(abi.encodePacked("TIE"))) {

                reward = games[i].amount;
                result = "Tie";
                games[i].player.transfer(reward);
            }
            emit Result(games[i].id, games[i].user, games[i].colour, games[i].amount, games[i].player, reward, result, block.timestamp);
        }
        
        lastGameId = gameId;
    }
    
    function getBalance() public view onlyAdmin returns(uint256) {
        
        return address(this).balance;
    }
    
    function withdrawAmount() public payable onlyAdmin {
        
        admin.transfer(address(this).balance);
    }
    
}