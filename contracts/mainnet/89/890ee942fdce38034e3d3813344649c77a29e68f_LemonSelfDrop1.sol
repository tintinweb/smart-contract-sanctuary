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

contract LemonSelfDrop1 is Ownable {
    LemonToken public LemonContract;
    uint8 public dropNumber;
    uint256 public LemonsDroppedToTheWorld;
    uint256 public LemonsRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public holderReward;
    mapping (uint8 => uint256[]) donatorReward;
    uint8 donatorRewardLevels;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
    // Initialize the cutest contract in the world
    function LemonSelfDrop1 () {
        address c = 0x2089899d03607b2192afb2567874a3f287f2f1e4; 
        LemonContract = LemonToken(c); 
        dropNumber = 1;
        LemonsDroppedToTheWorld = 0;
        LemonsRemainingToDrop = 0;
        basicReward = 500;
       donatorRewardLevels = 1;
        totalDropTransactions = 0;
    }
    
    
    // Drop some wonderful cutest Lemon Token to sender every time contract is called without function
    function() payable {
        require (participants[msg.sender] < dropNumber && LemonsRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
        // Send extra Lemon token bonus if participant is donating Ether
        if (msg.value > donatorReward[0][0])
            tokensIssued += donatorBonus(msg.value);
        // Send extra Lemon token bonus if participant holds at least holderAmount
        if (LemonContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
        // Check if number of Kitten Coins to issue is higher than coins remaining for airdrop (last transaction of airdrop)
        if (tokensIssued > LemonsRemainingToDrop)
            tokensIssued = LemonsRemainingToDrop;
        
        // Give away these so cute Kitten Coins to contributor
        LemonContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        LemonsRemainingToDrop -= tokensIssued;
        LemonsDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
    // Increase the airdrop count to allow sweet humans asking for more beautiful Kitten Coins
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
    }
    
    
    function setHolderAmount(uint256 amount) public onlyOwner {
        holderAmount = amount;
    }
    
    
    function setRewards(uint256 basic, uint256 holder) public onlyOwner {
        basicReward = basic;
        holderReward = holder;
    }
    
    function setDonatorReward(uint8 index, uint256[] values, uint8 levels) public onlyOwner {
        donatorReward[index] = values;
        donatorRewardLevels = levels;
    }
    
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    function withdrawKittenCoins() public onlyOwner {
        LemonContract.transfer(owner, LemonContract.balanceOf(this));
        LemonsRemainingToDrop = 0;
    }
    
    
    // Sends all other tokens that would have been sent to owner (why people do that? We don&#39;t meow)
    function withdrawToken(address token) public onlyOwner {
        Token(token).transfer(owner, Token(token).balanceOf(this));
    }
    
    
    function updateKittenCoinsRemainingToDrop() public {
        LemonsRemainingToDrop = LemonContract.balanceOf(this);
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