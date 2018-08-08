pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Interface {
     function totalSupply() public constant returns (uint);
     function balanceOf(address tokenOwner) public constant returns (uint balance);
     function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
     function transfer(address to, uint tokens) public returns (bool success);
     function approve(address spender, uint tokens) public returns (bool success);
     function transferFrom(address from, address to, uint tokens) public returns (bool success);
     function mint(address from, address to, uint tokens) public;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract AdvertisementContract {
    
    using SafeMath for uint256;
    
    struct Advertisement {
      address advertiser;
      uint advertisementId;
      string advertisementLink;
      uint amountToBePaid;
      //Voter[] voterList;
      bool isUnlocked;    
    }

    struct Voter {
      address publicKey;
      uint amountEarned;  
    }
    
    
    struct VoteAdvertisementPayoutScheme {
      uint voterPercentage; 
      uint systemPercentage;  
    }
    
    // The token that would be sold using this contract 
    ERC20Interface public token;
    //Objects for use within program
    
    VoteAdvertisementPayoutScheme voteAdvertismentPayoutSchemeObj;
    Advertisement advertisement;
    Voter voter;
    uint counter = 0;
    address public wallet;
    
    mapping (uint=>Voter[]) advertisementVoterList;
    
    mapping (uint=>Advertisement) advertisementList;
    
    uint localIntAsPerNeed;
    address localAddressAsPerNeed;
    Voter[] voters;
   
    constructor(address _wallet,address _tokenAddress) public {
      wallet = _wallet;
      token = ERC20Interface(_tokenAddress);
      setup();
    }
        

    function () public payable {
        revert();
    }
    
   
    function setup() internal {
        voteAdvertismentPayoutSchemeObj = VoteAdvertisementPayoutScheme({voterPercentage: 79, systemPercentage: 21});
    }
    
    function uploadAdvertisement(uint adId,string advLink, address advertiserAddress, uint uploadTokenAmount) public
    {
        require(msg.sender == wallet);
        token.mint(advertiserAddress,wallet,uploadTokenAmount*10**18);    //tokens deducted from advertiser&#39;s wallet
        advertisement = Advertisement({
            advertiser : advertiserAddress,
            advertisementId : adId,
            advertisementLink : advLink,
            amountToBePaid : uploadTokenAmount*10**18,
            isUnlocked : false
        });
        advertisementList[adId] = advertisement;
    }
    
    function AdvertisementPayout (uint advId) public
    {
        require(msg.sender == wallet);
        require(token.balanceOf(wallet)>=advertisementList[advId].amountToBePaid);
        require(advertisementList[advId].advertisementId == advId);
        require(advertisementList[advId].isUnlocked == true);
        require(advertisementList[advId].amountToBePaid > 0);
        uint j = 0;
        
        //calculating voters payout
        voters = advertisementVoterList[advertisementList[advId].advertisementId];
        localIntAsPerNeed = voteAdvertismentPayoutSchemeObj.voterPercentage;
        uint voterPayout = advertisementList[advId].amountToBePaid.mul(localIntAsPerNeed);
        voterPayout = voterPayout.div(100);
        uint perVoterPayout = voterPayout.div(voters.length);
        
        //calculating system payout
        localIntAsPerNeed = voteAdvertismentPayoutSchemeObj.systemPercentage;
        uint systemPayout = advertisementList[advId].amountToBePaid.mul(localIntAsPerNeed);
        systemPayout = systemPayout.div(100);
        
        
        //doing voter payout
        for (j=0;j<voters.length;j++)
        {
            token.mint(wallet,voters[j].publicKey,perVoterPayout);
            voters[j].amountEarned = voters[j].amountEarned.add(perVoterPayout);
            advertisementList[advId].amountToBePaid = advertisementList[advId].amountToBePaid.sub(perVoterPayout);
        }
        //logString("Voter payout done");
        
        //catering for system payout (not trnasferring tokens as the wallet is where all tokens are already)
        advertisementList[advId].amountToBePaid = advertisementList[advId].amountToBePaid.sub(systemPayout);
        //logString("System payout done");     
                 
        require(advertisementList[advId].amountToBePaid == 0);
                
    }
    
   function VoteAdvertisement(uint adId, address voterPublicKey) public 
   {
        require(advertisementList[adId].advertisementId == adId);
        require(advertisementList[adId].isUnlocked == false);
        //logString("advertisement found");
        voter = Voter({publicKey: voterPublicKey, amountEarned : 0});
        advertisementVoterList[adId].push(voter);
        //logString("Vote added");
    }
    function unlockAdvertisement(uint adId) public
    {
        require(msg.sender == wallet);
        require(advertisementList[adId].advertisementId == adId);
        advertisementList[adId].isUnlocked = true;
    }
    function getTokenBalance() public constant returns (uint) {
        return token.balanceOf(msg.sender);
    }

    function changeWalletAddress(address newWallet) public  
    {
        require(msg.sender == wallet);
        wallet = newWallet;
    }
}