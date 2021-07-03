/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Fitcoin {
    
    string public name;
    string public symbol;
    address public owner;
    
    mapping(address => uint64) public balances;
    mapping(string => uint64) public rewards;
    mapping(string => uint64) public price;
    
    constructor() {
        name = "fitcoin";
        symbol = "FIT";
        owner = msg.sender;
        
        rewards["sitUp"] = 1;
        rewards["bicepCurl"] = 2;
        rewards["benchPress"] = 3;
        rewards["chinUp"] = 4;
        rewards["squat"] = 5;
        
        price["waterBottle"] = 5;
        price["granolaBar"] = 6;
        price["personalTrainer"] = 10;
        
    }
    
    function rewardUser(address user, string memory exercise) public {
        // only owner can reward users
        require(owner == msg.sender, "You don't have rewarding privileges");
        
        balances[user] += rewards[exercise];
    }
    
    function buy(string memory item) public {
        // assert user has enough fitcoin for transaction
        require(balances[msg.sender] >= price[item], "Insufficient Funds");
        
        balances[msg.sender] -= price[item];
    }
    
    function chargeUser(address user, string memory item) public {
        // assert user has enough fitcoin for transaction
        require(balances[user] >= price[item], "Insufficient Funds");
        // only owner can charge users
        require(owner == msg.sender, "You don't have charging privileges");
        
        balances[user] -= price[item];
    }
    
}