/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Fitcoin {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner;
    uint64 public _totalSupply;
    
    mapping(address => uint64) public balances;
    mapping(string => uint64) public rewards;
    mapping(string => uint64) public price;
    
    constructor() {
        name = "fitcoin";
        symbol = "FIT";
        decimals = 0;
        owner = msg.sender;
        _totalSupply = 0;
        
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
        _totalSupply += rewards[exercise];
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
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint64 balance) {
        return balances[tokenOwner];
    }
    
}