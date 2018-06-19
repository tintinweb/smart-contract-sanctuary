pragma solidity 0.4.21;

// How fast can you get to 1000 points and win the prize?

contract RACEFORETH {
    // 1000 points to win!
    uint256 public SCORE_TO_WIN = 1000 finney;
    uint256 PRIZE;
    
    // 1000 points = 1 ether
    // Speed limit: 0.5 eth to prevent insta-win
    // Prevents people from going too fast!
    uint256 public speed_limit = 500 finney;
    
    // Keep track of everyone&#39;s score
    mapping (address => uint256) racerScore;
    mapping (address => uint256) racerSpeedLimit;
    
    uint256 latestTimestamp;
    address owner;
    
    function RACEFORETH () public payable {
        PRIZE = msg.value;
        owner = msg.sender;
    }
    
    function race() public payable {
        if (racerSpeedLimit[msg.sender] == 0) { racerSpeedLimit[msg.sender] = speed_limit; }
        require(msg.value <= racerSpeedLimit[msg.sender] && msg.value > 1 wei);
        
        racerScore[msg.sender] += msg.value;
        racerSpeedLimit[msg.sender] = (racerSpeedLimit[msg.sender] / 2);
        
        latestTimestamp = now;
    
        // YOU WON
        if (racerScore[msg.sender] >= SCORE_TO_WIN) {
            msg.sender.transfer(this.balance);
        }
    }
    
    function () public payable {
        race();
    }
    
    // Pull the prize if no one has raced in 3 days :(
    function endRace() public {
        require(msg.sender == owner);
        require(now > latestTimestamp + 3 days);
        
        msg.sender.transfer(this.balance);
    }
}