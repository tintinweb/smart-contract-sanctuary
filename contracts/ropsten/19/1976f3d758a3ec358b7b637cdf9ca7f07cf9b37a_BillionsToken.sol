pragma solidity ^0.4.21;

/* Functions from Billions Token main contract to be used by sale contract */
contract BillionsCoin {
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

contract BillionsToken is Ownable {
    BillionsCoin public billionContract;
    uint8 public dropNumber;
    uint256 public billionsDroppedToTheWorld;
    uint256 public billionsRemainingToDrop;
    uint256 public holderAmount;
    uint256 public basicReward;
    uint256 public holderReward;
    mapping (uint8 => uint256[]) donatorReward;
    uint8 donatorRewardLevels;
    uint8 public totalDropTransactions;
    mapping (address => uint8) participants;
    
    
    // Initialize the cutest contract in the world
    function BillionsToken () {
        address c = 0x984BE40aC273dC74Fb6827ae7041DBC7778fD9e2; // set Billions Coin contract address
        billionContract = BillionsCoin(c); 
        dropNumber = 1;
        billionsDroppedToTheWorld = 0;
        billionsRemainingToDrop = 0;
        basicReward = 50000000000000; // set initial basic reward to 500,000 Billions Coins
        holderReward = 50000000000000; // set initial holder reward to 500,000 Billions Coins
        holderAmount = 50000000000000; // set initial hold amount to 500,000 Billions Coins for extra reward
        donatorReward[0]=[1,10000000000]; // set initial donator reward to 100 Billions Coins from 1 wei
        donatorReward[1]=[2000000000000000,500000000000000]; // set initial donator reward to 5,000,000 Billions Coins from 0.001 ETH
        donatorReward[2]=[20000000000000000,5000000000000000]; // set initial donator reward to 50,000,000 Billions Coins from 0.01 ETH
        donatorRewardLevels = 3;
        totalDropTransactions = 0;
    }
    
    
    // Drop some wonderful Billions Coins to sender every time contract is called without function
    function() payable {
        require (participants[msg.sender] < dropNumber && billionsRemainingToDrop > basicReward);
        uint256 tokensIssued = basicReward;
        // Send extra Billions Coins bonus if participant is donating Ether
        if (msg.value > donatorReward[0][0])
            tokensIssued += donatorBonus(msg.value);
        // Send extra Billions Coins bonus if participant holds at least holderAmount
        if (billionContract.balanceOf(msg.sender) >= holderAmount)
            tokensIssued += holderReward;
        // Check if number of Billions Coins to issue is higher than coins remaining for airdrop (last transaction of airdrop)
        if (tokensIssued > billionsRemainingToDrop)
            tokensIssued = billionsRemainingToDrop;
        
        // Give away these so Billions Coins to contributor
        billionContract.transfer(msg.sender, tokensIssued);
        participants[msg.sender] = dropNumber;
        billionsRemainingToDrop -= tokensIssued;
        billionsDroppedToTheWorld += tokensIssued;
        totalDropTransactions += 1;
    }
    
    
    function participant(address part) public constant returns (uint8 participationCount) {
        return participants[part];
    }
    
    
    // Increase the airdrop count to allow sweet humans asking for more beautiful Billions Coins
    function setDropNumber(uint8 dropN) public onlyOwner {
        dropNumber = dropN;
        billionsRemainingToDrop = billionContract.balanceOf(this);
    }
    
    
    // Define amount of Billions Coins to hold in order to get holder reward
    function setHolderAmount(uint256 amount) public onlyOwner {
        holderAmount = amount;
    }
    
    
    // Define how many wonderful Billions Coins will be issued for participating the selfdrop : basic and holder reward
    function setRewards(uint256 basic, uint256 holder) public onlyOwner {
        basicReward = basic;
        holderReward = holder;
    }
    
    // Define how many wonderful Billions Coins will be issued for donators participating the selfdrop
    function setDonatorReward(uint8 index, uint256[] values, uint8 levels) public onlyOwner {
        donatorReward[index] = values;
        donatorRewardLevels = levels;
    }
    
    // Sends all ETH contributions to lovely Billions owner
    function withdrawAll() public onlyOwner {
        owner.transfer(this.balance);
    }
    
    
    // Sends all remaining Billions Coins to owner, just in case of emergency
    function withdrawBillionsCoins() public onlyOwner {
        billionContract.transfer(owner, billionContract.balanceOf(this));
        billionsRemainingToDrop = 0;
    }
    
    
    // Sends all other tokens that would have been sent to owner
    function withdrawToken(address token) public onlyOwner {
        Token(token).transfer(owner, Token(token).balanceOf(this));
    }
    
    
    // Update number of Billions remaining for drop, just in case it is needed
    function updateBillionsCoinsRemainingToDrop() public {
        billionsRemainingToDrop = billionContract.balanceOf(this);
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