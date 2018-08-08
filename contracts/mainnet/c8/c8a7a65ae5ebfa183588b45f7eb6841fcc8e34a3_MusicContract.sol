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

contract MusicContract {
    
    using SafeMath for uint256;
    
    struct Music {
      address musician;
      uint musicId;
      string musicLink;
      bool marketType;    //false for sponsor, true for votes
      uint totalAmountForUnlock;
      uint totalEarning;
      uint amountLeftForUnlock;
      uint amountToBePaid;
      bool isUnlocked;  
    }    
    
    struct Voter {
      address publicKey;
      uint amountEarned;  
    }
    
    struct Sponsor {
      address publicKey;
      uint amountEarned;
      uint amountPaid;
    }
    
    struct VoteMusicPayoutScheme {
      uint musicianPercentage; //57
      uint voterPercentage;// 35
      uint systemPercentage;// 8  
    }
    
    struct SponsorPayoutScheme {
      uint sponsorPercentage;// 45
      uint musicianPercentage;// 37
      uint voterPercentage; // 10
      uint systemPercentage; // 8
    }
    
    // The token that would be sold using this contract 
    ERC20Interface public token;
    //Objects for use within program
    VoteMusicPayoutScheme voteMusicPayoutSchemeObj;
    SponsorPayoutScheme sponsorPayoutSchemeObj;
    Music music;
    Sponsor sponsor;
    Voter voter;
    uint counter = 0;
    address public wallet;
    
    mapping (uint=>Voter[]) musicVoterList;
    mapping (uint=>Sponsor[]) musicSponsorList;
   
    mapping (uint=>Music) musicList;
    uint localIntAsPerNeed;
    address localAddressAsPerNeed;
    Voter[] voters;
    Sponsor[] sponsors;
   
    constructor(address _wallet,address _tokenAddress) public {
      wallet = _wallet;
      token = ERC20Interface(_tokenAddress);
      setup();
    }
        
    // fallback function can be used to buy tokens
    function () public payable {
        revert();
    }
    
    function setup() internal {
        voteMusicPayoutSchemeObj = VoteMusicPayoutScheme({musicianPercentage:57, voterPercentage:35, systemPercentage:8});
        sponsorPayoutSchemeObj = SponsorPayoutScheme({sponsorPercentage:45, musicianPercentage: 37, voterPercentage:10, systemPercentage:8});
    }
    
    function UploadMusic(uint muId, string lnk, address muPublicKey,bool unlocktype,uint amount, uint uploadTokenAmount) public
    {
        require(msg.sender == wallet);
        token.mint(muPublicKey,wallet,uploadTokenAmount*10**18);    //tokens deducted from advertiser&#39;s wallet
        
        require(musicList[muId].musicId == 0);
      //Add to music struct
      music = Music ({
          musician : muPublicKey,
          musicId : muId,
          musicLink : lnk,
          marketType : unlocktype,
          totalEarning : 0,
          totalAmountForUnlock : amount * 10 ** 18,
          amountLeftForUnlock : amount * 10 ** 18,
          amountToBePaid : uploadTokenAmount * 10 **18,
          isUnlocked : false
      });
      musicList[muId] = music;
    }

   function DownloadMusic(uint musId, address senderId, uint tokenAmount) public returns (bool goAhead)
    {
        require(msg.sender == wallet);
        require(musicList[musId].musicId == musId);
        require(musicList[musId].isUnlocked == true);
        token.mint(senderId,wallet,tokenAmount*10**18);
       
        musicList[musId].totalEarning = musicList[musId].totalEarning.add(tokenAmount);
        musicList[musId].amountToBePaid = musicList[musId].amountToBePaid.add(tokenAmount);
        goAhead = true;
    }
    
    function DoSponsorPayout(Music musicObj) private
    {
        
        //sponsor   
        localIntAsPerNeed = musicObj.musicId;
        sponsors = musicSponsorList[localIntAsPerNeed];
                    
        //calculating sponsor payout
        localIntAsPerNeed = sponsorPayoutSchemeObj.sponsorPercentage;
        uint sponsorPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        sponsorPayout = sponsorPayout.div(100);
        
        //calculating voter payout
        voters = musicVoterList[musicObj.musicId];
        localIntAsPerNeed = sponsorPayoutSchemeObj.voterPercentage;
        uint voterPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        voterPayout = voterPayout.div(100);
        
        //calculating musician payout
        localIntAsPerNeed = sponsorPayoutSchemeObj.musicianPercentage;
        uint musicianPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        musicianPayout = musicianPayout.div(100);
        
        //calculating system payout
        localIntAsPerNeed = sponsorPayoutSchemeObj.systemPercentage;
        uint systemPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        systemPayout = systemPayout.div(100);
        
        
        //doing sponsor payout            
        for (counter=0;counter<sponsors.length;counter++)
        {
            //Find the percentage
            localIntAsPerNeed = sponsors[counter].amountPaid.mul(100);
            localIntAsPerNeed = localIntAsPerNeed.div(musicObj.totalAmountForUnlock);
            uint amtToSend = sponsorPayout.mul(localIntAsPerNeed);
            amtToSend = amtToSend.div(100);
            token.mint(wallet, sponsors[counter].publicKey, amtToSend);
            sponsors[counter].amountEarned = sponsors[counter].amountEarned.add(amtToSend);
            musicObj.amountToBePaid = musicObj.amountToBePaid.sub(amtToSend);
        }     
        
        
        //doing voter payout
        if (voters.length>0)
        {
            uint perVoterPayout = voterPayout.div(voters.length);
               
            for (counter=0;counter<voters.length;counter++)
            {
                token.mint(wallet, voters[counter].publicKey, perVoterPayout);
                voters[counter].amountEarned = voters[counter].amountEarned.add(perVoterPayout);
                musicObj.amountToBePaid = musicObj.amountToBePaid.sub(perVoterPayout);
            }
        }
        else
        {
             musicObj.amountToBePaid = musicObj.amountToBePaid.sub(voterPayout);
        }
        
        
        //doing musician payout
        localAddressAsPerNeed = musicObj.musician;
        token.mint(wallet,localAddressAsPerNeed,musicianPayout);
        musicObj.amountToBePaid = musicObj.amountToBePaid.sub(musicianPayout);
                
        //catering for system payout - no token transfers as the tokens are already in the owner wallet
        musicObj.amountToBePaid = musicObj.amountToBePaid.sub(systemPayout);
        
        require(musicObj.amountToBePaid == 0);
    }
    function DoVoterPayout(Music musicObj) private
    {
        uint j = 0;
        //sponsor   
        
        //calculating voter payout
        voters = musicVoterList[musicObj.musicId];
        localIntAsPerNeed = voteMusicPayoutSchemeObj.voterPercentage;
        uint voterPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        voterPayout = voterPayout.div(100);
        uint perVoterPayout = voterPayout.div(voters.length);
        
        //calculating musician payout
        localIntAsPerNeed = voteMusicPayoutSchemeObj.musicianPercentage;
        uint musicianPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        musicianPayout = musicianPayout.div(100);
        
        //calculating system payout
        localIntAsPerNeed = voteMusicPayoutSchemeObj.systemPercentage;
        uint systemPayout = musicObj.amountToBePaid.mul(localIntAsPerNeed);
        systemPayout = systemPayout.div(100);
        
        //doing voter payout     
        for (j=0;j<voters.length;j++)
        {
            token.mint(wallet,voters[j].publicKey, perVoterPayout);
            voters[j].amountEarned = voters[j].amountEarned.add(perVoterPayout);
            musicObj.amountToBePaid = musicObj.amountToBePaid.sub(perVoterPayout);
        }
        
        //doing musician payout
        token.mint(wallet,musicObj.musician,musicianPayout);
        musicObj.amountToBePaid = musicObj.amountToBePaid.sub(musicianPayout);
        //logString("musician payout done");
        
        //catering for system payout - not doing manual transfer as all the tokens are already in the wallet
        musicObj.amountToBePaid = musicObj.amountToBePaid.sub(systemPayout);
        
        require(musicObj.amountToBePaid == 0);            
    }
    function DoMusicPayout (uint musId) public
    {
        require(msg.sender == wallet);
        require(musicList[musId].musicId == musId);
        require(musicList[musId].isUnlocked == true);
        require(musicList[musId].amountToBePaid > 0);
        require(token.balanceOf(wallet)>=musicList[musId].amountToBePaid);
        bool unlock = musicList[musId].marketType;
        if (unlock == false)
        {
            //unlock type is sponsor
            DoSponsorPayout(musicList[musId]);
            musicList[musId].amountToBePaid = 0;
        }
        else
        {
            //unlock type is voter
            DoVoterPayout(musicList[musId]);
            musicList[musId].amountToBePaid = 0;
        }
    }
    function SponsorMusic(uint musId, uint sponsorAmount, address sponsorAddress) public
    {
        //msg.sender is the sponsor
        sponsorAmount = sponsorAmount * 10 ** 18;
        require(token.balanceOf(sponsorAddress) > sponsorAmount);   
        require (musicList[musId].musicId == musId);
        require  (musicList[musId].isUnlocked == false);
        require(musicList[musId].marketType == false);
        require (musicList[musId].amountLeftForUnlock>=sponsorAmount);
        token.mint(sponsorAddress,wallet,sponsorAmount);
        
        musicList[musId].amountLeftForUnlock = musicList[musId].amountLeftForUnlock.sub(sponsorAmount);
        musicList[musId].amountToBePaid = musicList[musId].amountToBePaid.add(sponsorAmount);
        sponsor = Sponsor({
            publicKey : msg.sender,
            amountEarned : 0,
            amountPaid : sponsorAmount
        });
                  
        musicSponsorList[musId].push(sponsor);
        if (musicList[musId].amountLeftForUnlock == 0)
        {
            musicList[musId].isUnlocked = true;
        }
    }
    
    function VoteMusic(uint musId, address voterPublicKey) public 
    {
        require(musicList[musId].musicId == musId);
        require(musicList[musId].isUnlocked == false);
        //logString("music found");
        voter = Voter({publicKey: voterPublicKey, amountEarned : 0});
        musicVoterList[musId].push(voter);
        //logString("voter added");
    }
    function unlockVoterMusic(uint musId) public
    {
        require(msg.sender == wallet);
        require(musicList[musId].musicId == musId);
        musicList[musId].isUnlocked = true;
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