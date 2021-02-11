/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

pragma solidity >=0.7.0 <0.8.0;

contract test {
    address payable owner;
    
    mapping (string => uint256) games;
    mapping (string => uint256) gameIds;
    mapping (string => uint256) gameCost;
    mapping (address => mapping (string => uint256)) userGames;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner, "This can only be done by the owner of the contract!");
        _;
    }
    
    function addGame(string memory game, uint256 count, uint256 cost) public onlyOwner {
        games[game] += count;
        gameIds[game] = uint(keccak256(abi.encodePacked(msg.sender, game)));
        gameCost[game] = cost;
    }
    
    function withdrawCash() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function gameLeftCount(string memory game) public view returns (uint256) {
        return games[game];
    }
    
    function getGameCost(string memory game) public view returns (uint256) {
        return gameCost[game];
    }
    
    function buyGame(string memory game) public payable {
        if (gameLeftCount(game) > 0 && msg.value == gameCost[game]) {
            games[game]--;
            userGames[msg.sender][game] = gameIds[game];
        } else {
            msg.sender.transfer(msg.value);
        }
    }
    
    function getGameId(string memory game) public view returns (uint256) {
        return userGames[msg.sender][game];
    }
}