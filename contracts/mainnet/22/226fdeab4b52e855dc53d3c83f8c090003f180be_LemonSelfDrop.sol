pragma solidity ^0.4.19;

/* Functions from Lemon Token main contract to be used by sale contract */
contract LemonToken {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  function Ownable() {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract LemonSelfDrop is Ownable {
    LemonToken public LemonContract;
    uint8 public dropNumber;
    uint256 public LemonsDroppedToTheWorld;
    uint256 public LemonsRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public donatorReward;
    uint256 public holderReward;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
    // Initialize the cutest contract in the world
    function LemonSelfDrop () {
        address c = 0x2089899d03607b2192afb2567874a3f287f2f1e4; // set Lemon Coin contract address
        LemonContract = LemonToken(c); 
        dropNumber = 1;
        LemonsDroppedToTheWorld = 0;
        LemonsRemainingToDrop = 0;
        basicReward = 50000000000; // set initial basic reward to 500 Lemon Tokens
        donatorReward = 50000000000; // set initial donator reward to 500 Lemon Tokens
        holderReward = 50000000000; // set initial holder reward to 500 Lemon Tokens
        holderAmount = 5000000000000; // set initial hold amount to 50000 Lemon Tokens for extra reward
        totalDropTransactions = 0;
    }
    
    
    // Drop some wonderful cutest Lemon Tokens to sender every time contract is called without function
    function() payable {
        require (participants[msg.sender] < dropNumber && LemonsRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
        // Send extra Lemon Tokens bonus if participant is donating Ether
        if (msg.value > 0)
            tokensIssued += donatorReward;
        // Send extra Lemon Token bonus if participant holds at least holderAmount
        if (LemonContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
        // Check if number of Lemon Tokens to issue is higher than coins remaining for airdrop (last transaction of airdrop)
        if (tokensIssued > LemonsRemainingToDrop)
            tokensIssued = LemonsRemainingToDrop;
        
        // Give away these so cute Lemon Token to contributor
        LemonContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        LemonsRemainingToDrop -= tokensIssued;
        LemonsDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
    // Increase the airdrop count to allow sweet humans asking for more beautiful Lemon Tokens
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
    }
    
    
    // Define amount of Lemon Tokens to hold in order to get holder reward
    function setHolderAmount(uint256 amount) public onlyOwner {
        holderAmount = amount;
    }
    
    
    // Define how many wonderful Lemon Tokens contributors will receive for participating the selfdrop
    function setRewards(uint256 basic, uint256 donator, uint256 holder) public onlyOwner {
        basicReward = basic;
        donatorReward = donator;
        holderReward = holder;
    }
    
    
    // Sends all ETH contributions to lovely Lemon owner
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    // Sends all remaining Lemon Tokens to owner, just in case of emergency
    function withdrawLemonCoins() public onlyOwner {
        LemonContract.transfer(owner, LemonContract.balanceOf(this));
        LemonsRemainingToDrop = 0;
    }
    
    
    // Update number of Lemon Tokens remaining for drop, just in case it is needed
    function updateLemonCoinsRemainingToDrop() public {
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
    }
    
}