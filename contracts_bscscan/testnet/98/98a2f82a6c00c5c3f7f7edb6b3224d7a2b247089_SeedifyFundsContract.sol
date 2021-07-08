/**
 *Submitted for verification at BscScan.com on 2021-07-08
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
  uint public immutable maxCap; // Max cap in BNB
  uint256 public immutable saleStartTime; // start sale time
  uint256 public immutable saleEndTime; // end sale time
  uint256 public totalBnbReceivedInAllTier; // total bnd received
  uint256 public totalBnbInTierOne; // total bnb for tier one
  uint256 public totalBnbInTierTwo; // total bnb for tier Tier
  uint256 public totalBnbInTierThree; // total bnb for tier Three
  uint public totalparticipants; // total participants in ido
  address payable public projectOwner; // project Owner
  
  // max cap per tier
  uint public tierOneMaxCap;
  uint public tierTwoMaxCap;
  uint public tierThreeMaxCap;
  
  //total users per tier
  uint public totalUserInTierOne;
  uint public totalUserInTierTwo;
  uint public totalUserInTierThree;
  
  //max allocations per user in a tier
  uint public maxAllocaPerUserTierOne;
  uint public maxAllocaPerUserTierTwo; 
  uint public maxAllocaPerUserTierThree;
 
  // address array for tier one whitelist
  address[] private whitelistTierOne; 
  
  // address array for tier two whitelist
  address[] private whitelistTierTwo; 
  
  // address array for tier three whitelist
  address[] private whitelistTierThree; 
  

  //mapping the user purchase per tier
  mapping(address => uint) public buyInOneTier;
  mapping(address => uint) public buyInTwoTier;
  mapping(address => uint) public buyInThreeTier;

  // CONSTRUCTOR  
  constructor(uint _maxCap, uint256 _saleStartTime, uint256 _saleEndTime, address payable _projectOwner, uint256 _tierOneValue, uint256 _tierTwoValue, uint256 _tierThreeValue, uint256 _tierOneUsersValue, uint256 _tierTwoUsersValue, uint256 _tierThreeUsersValue,uint _totalparticipants) public {
    maxCap = _maxCap;
    saleStartTime = _saleStartTime;
    saleEndTime = _saleEndTime;
    projectOwner = _projectOwner;
    tierOneMaxCap =_tierOneValue;
    tierTwoMaxCap = _tierTwoValue;
    tierThreeMaxCap =_tierThreeValue;
    totalUserInTierOne =_tierOneUsersValue;
    totalUserInTierTwo = _tierTwoUsersValue;
    totalUserInTierThree =_tierThreeUsersValue;
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    totalparticipants = _totalparticipants;
  }

  // function to update the tiers value manually
  function updateTierValues(uint256 _tierOneValue, uint256 _tierTwoValue, uint256 _tierThreeValue) external onlyOwner {
    tierOneMaxCap =_tierOneValue;
    tierTwoMaxCap = _tierTwoValue;
    tierThreeMaxCap =_tierThreeValue;
    
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
  }
  
  // function to update the tiers users value manually
  function updateTierUsersValue(uint256 _tierOneUsersValue, uint256 _tierTwoUsersValue, uint256 _tierThreeUsersValue) external onlyOwner {
    totalUserInTierOne =_tierOneUsersValue;
    totalUserInTierTwo = _tierTwoUsersValue;
    totalUserInTierThree =_tierThreeUsersValue;
    
    maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
    maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo; 
    maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
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
      require(buyInOneTier[msg.sender] + msg.value <= maxAllocaPerUserTierOne ,"buyTokens:your purchase limit got over");
      buyInOneTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierOne += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getWhitelistTwo(msg.sender)) {
      require(totalBnbInTierTwo + msg.value <= tierTwoMaxCap, "buyTokens: purchase would exceed Tier two max cap");
      require(buyInTwoTier[msg.sender] + msg.value <= maxAllocaPerUserTierTwo ,"buyTokens:your purchase limit got over");
      buyInTwoTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierTwo += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else if (getWhitelistThree(msg.sender)) { 
      require(totalBnbInTierThree + msg.value <= tierThreeMaxCap, "buyTokens: purchase would exceed Tier three max cap");
      require(buyInThreeTier[msg.sender] + msg.value <= maxAllocaPerUserTierThree ,"buyTokens:your purchase limit got over");
      buyInThreeTier[msg.sender] += msg.value;
      totalBnbReceivedInAllTier += msg.value;
      totalBnbInTierThree += msg.value;
      sendValue(projectOwner, address(this).balance);
      
    } else {
      revert();
    }
  }
}