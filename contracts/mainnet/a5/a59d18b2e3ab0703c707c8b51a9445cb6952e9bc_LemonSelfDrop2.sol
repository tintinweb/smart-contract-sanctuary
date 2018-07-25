pragma solidity ^0.4.21;

/* Functions from Lemon Token main contract to be used by sale contract */
contract LemonToken {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

contract Token {
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

contract LemonSelfDrop2 is Ownable {
    LemonToken public lemonContract;
    uint8 public dropNumber;
    uint256 public lemonsDroppedToTheWorld;
    uint256 public lemonsRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public holderReward;
    mapping (uint8 => uint256[]) donatorReward;
    uint8 donatorRewardLevels;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
    // Initialize the cutest contract in the world
    function LemonSelfDrop2 () {
        address c = 0x2089899d03607b2192afb2567874a3f287f2f1e4; // set Lemon Token contract address
        lemonContract = LemonToken(c); 
        dropNumber = 1;
        lemonsDroppedToTheWorld = 0;
        lemonsRemainingToDrop = 0;
        basicReward = 1000; // set initial basic reward to 500 Lemon Tokens
        holderReward = 500000; // set initial holder reward to 500 Lemon Tokens
        holderAmount = 10000000; // set initial hold amount to 50000 Lemon Tokens for extra reward
        donatorReward[0]=[1,2000]; // set initial donator reward to 100 Lemon Tokens from 1 wei
        donatorReward[1]=[1000000000000000,11111]; // set initial donator reward to 1000 Lemon Tokens from 0.001 ETH
        donatorReward[2]=[10000000000000000,111111]; // set initial donator reward to 5000 Lemon Tokens from 0.01 ETH
        donatorRewardLevels = 3;
        totalDropTransactions = 0;
    }
    
    
    // Drop some wonderful cutest Lemon Tokens to sender every time contract is called without function
    function() payable {
        require (participants[msg.sender] < dropNumber && lemonsRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
        // Send extra Lemon Tokens bonus if participant is donating Ether
        if (msg.value > donatorReward[0][0])
            tokensIssued += donatorBonus(msg.value);
        // Send extra Lemon Tokens bonus if participant holds at least holderAmount
        if (lemonContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
        // Check if number of Lemon Tokens to issue is higher than coins remaining for airdrop (last transaction of airdrop)
        if (tokensIssued > lemonsRemainingToDrop)
            tokensIssued = lemonsRemainingToDrop;
        
        // Give away these so cute Lemon Tokens to contributor
        lemonContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        lemonsRemainingToDrop -= tokensIssued;
        lemonsDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
    // Increase the airdrop count to allow sweet humans asking for more beautiful lemon Tokens
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        lemonsRemainingToDrop = lemonContract.balanceOf(this);
    }
    
    
    // Define amount of Lemon Tokens to hold in order to get holder reward
    function setHolderAmount(uint256 amount) public onlyOwner {
        holderAmount = amount;
    }
    
    
    // Define how many wonderful Lemon Tokens will be issued for participating the selfdrop : basic and holder reward
    function setRewards(uint256 basic, uint256 holder) public onlyOwner {
        basicReward = basic;
        holderReward = holder;
    }
    
    // Define how many wonderful Lemon Tokens will be issued for donators participating the selfdrop
    function setDonatorReward(uint8 index, uint256[] values, uint8 levels) public onlyOwner {
        donatorReward[index] = values;
        donatorRewardLevels = levels;
    }
    
    // Sends all ETH contributions to lovely Lemon owner
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    // Sends all remaining Lemon Tokens to owner, just in case of emergency
    function withdrawLemontokens() public onlyOwner {
        lemonContract.transfer(owner, lemonContract.balanceOf(this));
        lemonsRemainingToDrop = 0;
    }
    
    
    // Sends all other tokens that would have been sent to owner (why people do that? We don&#39;t meow)
    function withdrawToken(address token) public onlyOwner {
        Token(token).transfer(owner, Token(token).balanceOf(this));
    }
    
    
    // Update number of Lemon Tokens remaining for drop, just in case it is needed
    function updateLemontokensRemainingToDrop() public {
        lemonsRemainingToDrop = lemonContract.balanceOf(this);
    }
    
    
    // Defines donator bonus to receive
    function donatorBonus(uint256 amount) public returns (uint256) {
        for(uint8 i = 1; i < donatorRewardLevels; i++) {
            if(amount < donatorReward[i][0])
                return (donatorReward[i-1][1]);
        }
        return (donatorReward[i-1][1]);
    }
    
}