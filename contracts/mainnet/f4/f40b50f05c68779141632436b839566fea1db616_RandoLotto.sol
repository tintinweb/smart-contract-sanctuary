pragma solidity 0.4.24;

// Random lottery
// Smart contracts can&#39;t bet

// Pay 0.001 to get a random number
// If your random number is the highest so far you&#39;re in the lead
// If no one beats you in 1 day you can claim your winnnings - half of the pot.

// Three pots total - hour long, day long, and week long.
// Successfully getting the highest value on one of them resets only that one.

// When you bet, you bet for ALL THREE pots. (each is a different random number)

contract RandoLotto {
    
    bool activated;
    address internal owner;
    uint256 internal devFee;
    uint256 internal seed;
    
    uint256 public totalBids;
    
    // Three pots
    uint256 public hourPot;
    uint256 public dayPot;
    uint256 public weekPot;
    
    // Each put has a current winner
    address public hourPotLeader;
    address public dayPotLeader;
    address public weekPotLeader;
    
    // Each pot has a current high score
    uint256 public hourPotHighscore;
    uint256 public dayPotHighscore;
    uint256 public weekPotHighscore;
    
    // Each pot has an expiration - reset when someone else takes leader of that pot
    uint256 public hourPotExpiration;
    uint256 public dayPotExpiration;
    uint256 public weekPotExpiration;
    
    struct threeUints {
        uint256 a;
        uint256 b; 
        uint256 c;
    }
    
    mapping (address => threeUints) playerLastScores;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        
        activated = false;
        totalBids = 0;
        
        hourPotHighscore = 0;
        dayPotHighscore = 0;
        weekPotHighscore = 0;
        
        hourPotLeader = msg.sender;
        dayPotLeader = msg.sender;
        weekPotLeader = msg.sender;
    }
    
    function activate() public payable onlyOwner {
        require(!activated);
        require(msg.value >= 0 ether);
        
        hourPotExpiration = now + 1 hours;
        dayPotExpiration = now + 1 days;
        weekPotExpiration = now + 1 weeks;
        
        hourPot = msg.value / 3;
        dayPot = msg.value / 3;
        weekPot = msg.value - hourPot - dayPot;
        
        activated = true;
    }
    
    // Fallback function calls bid.
    function () public payable {
        bid();
    }
    
    // Bid function.
    function bid() public payable returns (uint256, uint256, uint256) {
        // Humans only unlike F3D
        require(msg.sender == tx.origin);
        require(msg.value == 0.001 ether);

        checkRoundEnd();

        // Add monies to pot
        devFee = devFee + (msg.value / 100);
        uint256 toAdd = msg.value - devFee;
        hourPot = hourPot + (toAdd / 3);
        dayPot = dayPot + (toAdd / 3);
        weekPot = weekPot + (toAdd - ((toAdd/3) + (toAdd/3)));

        // Random number via blockhash    
        seed = uint256(keccak256(blockhash(block.number - 1), seed, now));
        uint256 seed1 = seed;
        
        if (seed > hourPotHighscore) {
            hourPotLeader = msg.sender;
            hourPotExpiration = now + 1 hours;
            hourPotHighscore = seed;
        }
        
        seed = uint256(keccak256(blockhash(block.number - 1), seed, now));
        uint256 seed2 = seed;
        
        if (seed > dayPotHighscore) {
            dayPotLeader = msg.sender;
            dayPotExpiration = now + 1 days;
            dayPotHighscore = seed;
        }
        
        seed = uint256(keccak256(blockhash(block.number - 1), seed, now));
        uint256 seed3 = seed;
        
        if (seed > weekPotHighscore) {
            weekPotLeader = msg.sender;
            weekPotExpiration = now + 1 weeks;
            weekPotHighscore = seed;
        }
        
        totalBids++;
        
        playerLastScores[msg.sender] = threeUints(seed1, seed2, seed3);
        return (seed1, seed2, seed3);
    }
    
    function checkRoundEnd() internal {
        if (now > hourPotExpiration) {
            uint256 hourToSend = hourPot / 2;
            hourPot = hourPot - hourToSend;
            hourPotLeader.transfer(hourToSend);
            hourPotLeader = msg.sender;
            hourPotHighscore = 0;
            hourPotExpiration = now + 1 hours;
        }
        
        if (now > dayPotExpiration) {
            uint256 dayToSend = dayPot / 2;
            dayPot = dayPot - dayToSend;
            dayPotLeader.transfer(dayToSend);
            dayPotLeader = msg.sender;
            dayPotHighscore = 0;
            dayPotExpiration = now + 1 days;
        }
        
        if (now > weekPotExpiration) {
            uint256 weekToSend = weekPot / 2;
            weekPot = weekPot - weekToSend;
            weekPotLeader.transfer(weekToSend);
            weekPotLeader = msg.sender;
            weekPotHighscore = 0;
            weekPotExpiration = now + 1 weeks;
        }
    }
    
    function claimWinnings() public {
        checkRoundEnd();
    }
    
    function getMyLastScore() public view returns (uint256, uint256, uint256) {
        return (playerLastScores[msg.sender].a, playerLastScores[msg.sender].b, playerLastScores[msg.sender].c);
    }
    
    function devWithdraw() public onlyOwner {
        uint256 toSend = devFee;
        devFee = 0;
        owner.transfer(toSend);
    }
}