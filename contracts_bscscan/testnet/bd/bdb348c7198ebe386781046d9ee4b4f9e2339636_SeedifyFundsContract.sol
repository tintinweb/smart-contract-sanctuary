/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

/*
*Seedify.fund
*Decentralized Incubator
*A disruptive blockchain incubator program / decentralized seed stage fund, empowered through DAO based community-involvement mechanisms
*/
pragma solidity ^0.6.0;

// SPDX-License-Identifier: MIT

//OWnABLE contract that define owning functionality
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
    require(msg.sender == owner, "Only owner has the right to perform this action");
    _;
  }

  /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

//SeedifyFundsContract

contract SeedifyFundsContract is Ownable {

  //token attributes
  string public constant NAME = "Seedify.funds"; //name of the contract
  uint public  maxCap; // Max cap in BNB
  uint256 public immutable saleStartTime; // start sale time
  uint256 public immutable saleEndTime; // end sale time
  uint256 public totalBnbReceivedInAllTier; // total bnd received
  uint256 public totalBnbInTierOne; // total bnb for tier one
  uint256 public totalBnbInTierTwo; // total bnb for tier Tier
  uint256 public totalBnbInTierThree; // total bnb for tier Three
  uint256 public totalBnbInTierFour;  // total bnb for tier Four
  uint256 public totalBnbInTierFive;  // total bnb for tier Five
  uint256 public totalBnbInTierSix;  // total bnb for tier Six
  uint256 public totalBnbInTierSeven;  // total bnb for tier Seven
  uint256 public totalBnbInTierEight;  // total bnb for tier Eight
  uint256 public totalBnbInTierNine;  // total bnb for tier Nine
  uint public totalparticipants; // total participants in ido
  address payable public projectOwner; // project Owner
  
  // max cap per tier
  uint public tierOneMaxCap;
  uint public tierTwoMaxCap;
  uint public tierThreeMaxCap;
  uint public tierFourMaxCap; 
  uint public tierFiveMaxCap;
  uint public tierSixMaxCap;
  uint public tierSevenMaxCap;
  uint public tierEightMaxCap;
  uint public tierNineMaxCap;
        
  
  //total users per tier
  uint public totalUserInTierOne;
  uint public totalUserInTierTwo;
  uint public totalUserInTierThree;
  uint public totalUserInTierFour;
  uint public totalUserInTierFive;
  uint public totalUserInTierSix;
  uint public totalUserInTierSeven;
  uint public totalUserInTierEight;
  uint public totalUserInTierNine;
  
  //max allocations per user in a tier
  uint public maxAllocaPerUserTierOne;
  uint public maxAllocaPerUserTierTwo; 
  uint public maxAllocaPerUserTierThree;
  uint public maxAllocaPerUserTierFour;
  uint public maxAllocaPerUserTierFive;
  uint public maxAllocaPerUserTierSix;
  uint public maxAllocaPerUserTierSeven;
  uint public maxAllocaPerUserTierEight;
  uint public maxAllocaPerUserTierNine;
 
  // address array for tier one whitelist
  address[] private whitelistTierOne; 
  
  // address array for tier two whitelist
  address[] private whitelistTierTwo; 
  
  // address array for tier three whitelist
  address[] private whitelistTierThree; 
  
    // address array for tier Four whitelist
  address[] private whitelistTierFour;
  
    // address array for tier three whitelist
  address[] private whitelistTierFive; 
  
    // address array for tier three whitelist
  address[] private whitelistTierSix; 
  
    // address array for tier three whitelist
  address[] private whitelistTierSeven;
  
    // address array for tier three whitelist
  address[] private whitelistTierEight;
  
    // address array for tier three whitelist
  address[] private whitelistTierNine; 

  //mapping the user purchase per tier
  mapping(address => uint) public buyInOneTier;
  mapping(address => uint) public buyInTwoTier;
  mapping(address => uint) public buyInThreeTier;
  mapping(address => uint) public buyInFourTier;
  mapping(address => uint) public buyInFiveTier;
  mapping(address => uint) public buyInSixTier;
  mapping(address => uint) public buyInSevenTier;
  mapping(address => uint) public buyInEightTier;
  mapping(address => uint) public buyInNineTier;
  
  // CONSTRUCTOR  
  constructor(uint _maxCap, uint256 _saleStartTime, uint256 _saleEndTime, address payable _projectOwner, uint256 _tierOneValue, 
  uint256 _tierTwoValue, uint256 _tierThreeValue ,uint256 _tierFourValue, uint256 _tierFiveValue,uint256 _tierSixValue,
  uint256 _tierSevenValue,uint256 _tierEightValue ,uint256 _tierNineValue ,uint256 _totalparticipants   ) public {
    maxCap = _maxCap;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
    projectOwner = _projectOwner;
    tierOneMaxCap =_tierOneValue;
    tierTwoMaxCap = _tierTwoValue;
    tierThreeMaxCap =_tierThreeValue;
    tierFourMaxCap = _tierFourValue;
    tierFiveMaxCap =_tierFiveValue;
    tierSixMaxCap =_tierSixValue;
    tierSevenMaxCap  =  _tierSevenValue;
    tierEightMaxCap=  _tierEightValue;
    tierNineMaxCap  =  _tierNineValue;
    totalUserInTierOne =2 ;
    totalUserInTierTwo = 2;
    totalUserInTierThree = 3;
    totalUserInTierFour = 2;
    totalUserInTierFive = 3;
    totalUserInTierSix = 2;
    totalUserInTierSeven = 2;
    totalUserInTierEight = 2;
    totalUserInTierNine = 3;
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    maxAllocaPerUserTierFour =tierFourMaxCap / totalUserInTierFour;
    maxAllocaPerUserTierFive =tierFiveMaxCap / totalUserInTierFive;
    maxAllocaPerUserTierSix = tierSixMaxCap / totalUserInTierSix;
    maxAllocaPerUserTierSeven = tierSevenMaxCap / totalUserInTierSeven;
    maxAllocaPerUserTierEight = tierEightMaxCap / totalUserInTierEight;
    maxAllocaPerUserTierNine =tierNineMaxCap / totalUserInTierNine;
    totalparticipants = _totalparticipants;
  }

  // function to update the tiers value manually
  function updateTierValues(uint256 _tierOneValue, uint256 _tierTwoValue, uint256 _tierThreeValue, uint256 _tierFourValue ,
                            uint256 _tierFiveValue, uint256 _tierSixValue , uint256 _tierSevenValue , uint256 _tierEightValue,
                             uint256 _tierNineValue) external onlyOwner {
    tierOneMaxCap =_tierOneValue;
    tierTwoMaxCap = _tierTwoValue;
    tierThreeMaxCap =_tierThreeValue;
    tierFourMaxCap = _tierFourValue;
    tierFiveMaxCap = _tierFiveValue;
    tierSixMaxCap = _tierSixValue;
    tierSevenMaxCap = _tierSevenValue;
    tierEightMaxCap = _tierEightValue;
    tierNineMaxCap = _tierNineValue;
    
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    maxAllocaPerUserTierFour =tierFourMaxCap / totalUserInTierFour;
    maxAllocaPerUserTierFive =tierFiveMaxCap / totalUserInTierFive;
    maxAllocaPerUserTierSix = tierSixMaxCap / totalUserInTierSix;
    maxAllocaPerUserTierSeven = tierSevenMaxCap / totalUserInTierSeven;
    maxAllocaPerUserTierEight = tierEightMaxCap / totalUserInTierEight;
    maxAllocaPerUserTierNine =tierNineMaxCap / totalUserInTierNine;
    maxCap = tierOneMaxCap + tierTwoMaxCap + tierThreeMaxCap + tierFourMaxCap + tierFiveMaxCap + tierSixMaxCap  
              + tierSevenMaxCap + tierEightMaxCap +tierNineMaxCap;
  }
  
  // function to update the tiers users value manually
  function updateTierUsersValue(uint256 _tierOneUsersValue, uint256 _tierTwoUsersValue, uint256 _tierThreeUsersValue ,
                                uint256 _tierFourUsersValue ,uint256 _tierFiveUsersValue ,uint256 _tierSixUsersValue ,
                                uint256 _tierSevenUsersValue,uint256 _tierEightUsersValue,uint256 _tierNineUsersValue) external onlyOwner {
    totalUserInTierOne =_tierOneUsersValue;
    totalUserInTierTwo = _tierTwoUsersValue;
    totalUserInTierThree =_tierThreeUsersValue;
    totalUserInTierFour = _tierFourUsersValue;
    totalUserInTierFive = _tierFiveUsersValue;
    totalUserInTierSix = _tierSixUsersValue ;
    totalUserInTierSeven = _tierSevenUsersValue;
    totalUserInTierEight = _tierEightUsersValue;
    totalUserInTierNine = _tierNineUsersValue ;
    
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    maxAllocaPerUserTierFour =tierFourMaxCap / totalUserInTierFour;
    maxAllocaPerUserTierFive =tierFiveMaxCap / totalUserInTierFive;
    maxAllocaPerUserTierSix = tierSixMaxCap / totalUserInTierSix;
    maxAllocaPerUserTierSeven = tierSevenMaxCap / totalUserInTierSeven;
    maxAllocaPerUserTierEight = tierEightMaxCap / totalUserInTierEight;
    maxAllocaPerUserTierNine =tierNineMaxCap / totalUserInTierNine;
    
    totalparticipants = totalUserInTierOne + totalUserInTierTwo + totalUserInTierThree + totalUserInTierFour + 
        totalUserInTierFive + totalUserInTierSix + totalUserInTierSeven + totalUserInTierEight+ totalUserInTierNine ; 
  }

  //add the address in Whitelist tier One to invest
  function addWhitelistOne(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierOne.push(_address);
  }

  //add the address in Whitelist tier two to invest
  function addWhitelistTwo(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierTwo.push(_address);
  }

  //add the address in Whitelist tier three to invest
  function addWhitelistThree(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierThree.push(_address);
  }

 //add the address in Whitelist tier Four to invest
  function addWhitelistFour(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierFour.push(_address);
  }
  
   //add the address in Whitelist tier three to invest
  function addWhitelistFive(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierFive.push(_address);
  }
  
   //add the address in Whitelist tier three to invest
  function addWhitelistSix(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierSix.push(_address);
  }
  
   //add the address in Whitelist tier three to invest
  function addWhitelistSeven(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierSeven.push(_address);
  }
  
   //add the address in Whitelist tier three to invest
  function addWhitelistEight(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierEight.push(_address);
  }
  
   //add the address in Whitelist tier three to invest
  function addWhitelistNine(address _address) external onlyOwner {
    require(_address != address(0), "Invalid address");
    whitelistTierNine.push(_address);
  }
  
  // check the address in whitelist tier one
  function getWhitelistOne(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierOne.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierOne[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier two
  function getWhitelistTwo(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierTwo.length;
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierTwo[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }

  // check the address in whitelist tier three
  function getWhitelistThree(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierThree.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierThree[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
    // check the address in whitelist tier Four
  function getWhitelistFour(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierFour.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierFour[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
    // check the address in whitelist tier Five
  function getWhitelistFive(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierFive.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierFive[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
      // check the address in whitelist tier Six
  function getWhitelistSix(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierSix.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierSix[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
      // check the address in whitelist tier Seven
  function getWhitelistSeven(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierSeven.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierSeven[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
      // check the address in whitelist tier Eight
  function getWhitelistEight(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierEight.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierEight[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
      // check the address in whitelist tier Nine
  function getWhitelistNine(address _address) public view returns(bool) {
    uint i;
    uint length = whitelistTierNine.length; 
    for (i = 0; i < length; i++) {
      address _addressArr = whitelistTierNine[i];
      if (_addressArr == _address) {
        return true;
      }
    }
    return false;
  }
  
  
    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
  // send bnb to the contract address
  receive() external payable {
     require(now >= saleStartTime, "The sale is not started yet "); // solhint-disable
     require(now <= saleEndTime, "The sale is closed"); // solhint-disable
     require(totalBnbReceivedInAllTier + msg.value <= maxCap, "buyTokens: purchase would exceed max cap");
     
    if (getWhitelistOne(msg.sender)) { 
      require(totalBnbInTierOne + msg.value <= tierOneMaxCap, "buyTokens: purchase would exceed Tier one max cap");
      require(buyInOneTier[msg.sender] + msg.value <= maxAllocaPerUserTierOne ,"buyTokens:You are investing more than your tier-1 limit!");
      buyInOneTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierOne += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getWhitelistTwo(msg.sender)) {
      require(totalBnbInTierTwo + msg.value <= tierTwoMaxCap, "buyTokens: purchase would exceed Tier two max cap");
      require(buyInTwoTier[msg.sender] + msg.value <= maxAllocaPerUserTierTwo ,"buyTokens:You are investing more than your tier-2 limit!");
      buyInTwoTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierTwo += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getWhitelistThree(msg.sender)) { 
      require(totalBnbInTierThree + msg.value <= tierThreeMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      require(buyInThreeTier[msg.sender] + msg.value <= maxAllocaPerUserTierThree ,"buyTokens:You are investing more than your tier-3 limit!");
      buyInThreeTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierThree += msg.value;
      sendValue(projectOwner, address(this).balance);
    
    } else if (getWhitelistFour(msg.sender)) { 
      require(totalBnbInTierFour + msg.value <= tierFourMaxCap, "buyTokens: purchase would exceed Tier Four max cap");
      require(buyInFourTier[msg.sender] + msg.value <= maxAllocaPerUserTierFour ,"buyTokens:You are investing more than your tier-4 limit!");
      buyInFourTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierFour += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else if (getWhitelistFive(msg.sender)) { 
      require(totalBnbInTierFive + msg.value <= tierFiveMaxCap, "buyTokens: purchase would exceed Tier Five max cap");
      require(buyInFiveTier[msg.sender] + msg.value <= maxAllocaPerUserTierFive ,"buyTokens:You are investing more than your tier-5 limit!");
      buyInFiveTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierFive += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else if (getWhitelistSix(msg.sender)) { 
      require(totalBnbInTierSix + msg.value <= tierSixMaxCap, "buyTokens: purchase would exceed Tier Six max cap");
      require(buyInSixTier[msg.sender] + msg.value <= maxAllocaPerUserTierSix ,"buyTokens:You are investing more than your tier-6 limit!");
      buyInSixTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierSix += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else if (getWhitelistSeven(msg.sender)) { 
      require(totalBnbInTierSeven + msg.value <= tierSevenMaxCap, "buyTokens: purchase would exceed Tier Seven max cap");
      require(buyInSevenTier[msg.sender] + msg.value <= maxAllocaPerUserTierSeven ,"buyTokens:You are investing more than your tier-7 limit!");
      buyInSevenTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierSeven += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else if (getWhitelistEight(msg.sender)) { 
      require(totalBnbInTierEight + msg.value <= tierEightMaxCap, "buyTokens: purchase would exceed Tier Eight max cap");
      require(buyInEightTier[msg.sender] + msg.value <= maxAllocaPerUserTierEight ,"buyTokens:You are investing more than your tier-8 limit!");
      buyInEightTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierEight += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else if (getWhitelistNine(msg.sender)) { 
      require(totalBnbInTierNine + msg.value <= tierNineMaxCap, "buyTokens: purchase would exceed Tier Nine max cap");
      require(buyInNineTier[msg.sender] + msg.value <= maxAllocaPerUserTierNine ,"buyTokens:You are investing more than your tier-9 limit!");
      buyInNineTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierNine += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    }else {
      revert();
    }
  }
}