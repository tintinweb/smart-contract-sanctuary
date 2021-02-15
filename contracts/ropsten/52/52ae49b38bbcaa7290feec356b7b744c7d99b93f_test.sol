pragma solidity >= 0.6.1 < 0.7.0;
import "./provableAPI_0.6.sol";

contract test is usingProvable {
    address payable owner;
    string res;
    bytes32 id;
    
    mapping (string => uint256) games;
    mapping (string => uint256) gameIds;
    mapping (string => uint256) gameCost;
    mapping (address => mapping (string => uint256)) userGames;
    
    event LogMessage(string message);
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function __callback(bytes32 myId, string memory result) public override {
        emit LogMessage("Callback work!");
        if (msg.sender != provable_cbAddress()) revert();
        res = result;
        emit LogMessage(result);
    }
    
    function getGames(string memory url) public {
        if (provable_getPrice("URL") > address(this).balance) {
            emit LogMessage("Contract balance is low!");
        } else {
            emit LogMessage("Request started!");
            id = provable_query("URL", url);
        }
    }
    
    modifier onlyOwner {
        require (msg.sender == owner, "This can only be done by the owner of the contract!");
        _;
    }
    
    function getResult() public view returns (string memory) {
        return res;
    }
    
    function upContractBalance() payable public {
        emit LogMessage("Contract balance is upped!");
    }
    
    function addGame(string memory game, uint256 count, uint256 cost) public onlyOwner {
        games[game] += count;
        gameIds[game] = uint(keccak256(abi.encodePacked(msg.sender, game)));
        gameCost[game] = cost;
    }
    
    function withdrawCash() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function getId() public view returns (bytes32) {
        return id;
    }
    
    function gameLeftCount(string memory game) public view returns (uint256) {
        return games[game];
    }
    
    function getGameCost(string memory game) public view returns (uint256) {
        return gameCost[game];
    }
    
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
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