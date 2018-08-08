pragma solidity ^0.4.19;


// "Proof of Commitment" fun pre-launch competition for NBAOnline!

//  Full details and game smart contract will shortly be able:
//  ~~ https://nbaonline.io ~~

//  This contest will award some of the keen NBAOnline players

//  ALL ETHER DEPOSITED INTO THIS PROMO CAN BE WITHDRAWN BY PLAYER AT ANY
//  TIME BUT PRIZES WILL BE DRAWN: SATURDAY 14TH APRIL (LAUNCH)
//  AT WHICH POINT ALL ETHER WILL ALSO BE REFUNDED TO PLAYERS


//  PRIZES:
//  0.5 ether (top eth deposit)
//  0.35 ether (1 random deposit)
//  0.15 ether (1 random deposit)

contract NBAOnlineLaunchPromotion {
    
    // First Goo Players!
    mapping(address => uint256) public deposits;
    mapping(address => bool) depositorAlreadyStored;
    address[] public depositors;

    // To trigger contest end only
    address public ownerAddress;
    
    // Flag so can only be awarded once
    bool public prizesAwarded = false;
    
    // Ether to be returned to depositor on launch
	// 1day = 86400
    uint256 public constant LAUNCH_DATE = 1523678400; // Saturday, 14 April 2018 00:00:00 (seconds) ET
    
    // Proof of Commitment contest prizes
    uint256 private constant TOP_DEPOSIT_PRIZE = 0.5 ether;
    uint256 private constant RANDOM_DEPOSIT_PRIZE1 = 0.35 ether;
    uint256 private constant RANDOM_DEPOSIT_PRIZE2 = 0.15 ether;
    
    function NBAOnlineLaunchPromotion() public payable {
        require(msg.value == 1 ether); // Owner must provide enough for prizes
        ownerAddress = msg.sender;
    }
    
    
    function deposit() external payable {
        uint256 existing = deposits[msg.sender];
        
        // Safely store the ether sent
        deposits[msg.sender] = SafeMath.add(msg.value, existing);
        
        // Finally store contest details
        if (msg.value >= 0.01 ether && !depositorAlreadyStored[msg.sender]) {
            depositors.push(msg.sender);
            depositorAlreadyStored[msg.sender] = true;
        }
    }
    
    function refund() external {
        // Safely transfer players deposit back
        uint256 depositAmount = deposits[msg.sender];
        deposits[msg.sender] = 0; // Can&#39;t withdraw twice obviously
        msg.sender.transfer(depositAmount);
    }
    
    
    function refundPlayer(address depositor) external {
        require(msg.sender == ownerAddress);
        
        // Safely transfer back to player
        uint256 depositAmount = deposits[depositor];
        deposits[depositor] = 0; // Can&#39;t withdraw twice obviously
        
        // Sends back to correct depositor
        depositor.transfer(depositAmount);
    }
    
    
    function awardPrizes() external {
        require(msg.sender == ownerAddress);
        require(now >= LAUNCH_DATE);
        require(!prizesAwarded);
        
        // Ensure only ran once
        prizesAwarded = true;
        
        uint256 highestDeposit;
        address highestDepositWinner;
        
        for (uint256 i = 0; i < depositors.length; i++) {
            address depositor = depositors[i];
            
            // No tie allowed!
            if (deposits[depositor] > highestDeposit) {
                highestDeposit = deposits[depositor];
                highestDepositWinner = depositor;
            }
        }
        
        uint256 numContestants = depositors.length;
        uint256 seed1 = numContestants + block.timestamp;
        uint256 seed2 = seed1 + (numContestants*2);
        
        address randomDepositWinner1 = depositors[randomContestant(numContestants, seed1)];
        address randomDepositWinner2 = depositors[randomContestant(numContestants, seed2)];
        
        // Just incase
        while(randomDepositWinner2 == randomDepositWinner1) {
            seed2++;
            randomDepositWinner2 = depositors[randomContestant(numContestants, seed2)];
        }
        
        highestDepositWinner.transfer(TOP_DEPOSIT_PRIZE);
        randomDepositWinner1.transfer(RANDOM_DEPOSIT_PRIZE1);
        randomDepositWinner2.transfer(RANDOM_DEPOSIT_PRIZE2);
    }
    
    
    // Random enough for small contest
    function randomContestant(uint256 contestants, uint256 seed) constant internal returns (uint256 result){
        return addmod(uint256(block.blockhash(block.number-1)), seed, contestants);   
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}