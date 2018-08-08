pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BVesting is Ownable {
  using SafeMath for uint256;

  address public teamWallet;
  address public earlyWallet;
  address public institutionWallet;
  
  uint256 public teamTimeLock = 1000 minutes;
  uint256 public earlyTimeLock = 5 * 30 minutes;
  uint256 public institutionTimeLock = 50 * 30 minutes;
  
  //amount of allocation
  uint256 public teamAllocation = 15 * (10 ** 7) * (10 ** 18);
  uint256 public earlyAllocation = 5 * (10 ** 7) * (10 ** 18);
  uint256 public institutionAllocation = 15 * (10 ** 7) * (10 ** 18);
  
  uint256 public totalAllocation = 35 * (10 ** 7) * (10 ** 18);
  
  uint256 public teamStageSetting = 34;
  uint256 public earlyStageSetting = 5;
  uint256 public institutionStageSetting = 50;
  ERC20Basic public token;
  //token开始时间
  uint256 public start;
  //锁仓开开始时间
  uint256 public lockStartTime; 
   /** Reserve allocations */
    mapping(address => uint256) public allocations;
    
    mapping(address => uint256) public stageSettings;
    
    mapping(address => uint256) public timeLockDurations;

    /** How many tokens each reserve wallet has claimed */
    mapping(address => uint256) public releasedAmounts;
    
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }
    function BVesting(ERC20Basic _token,
                          address _teamWallet,
                          address _earlyWallet,
                          address _institutionWallet,
                          uint256 _start,
                          uint256 _lockTime)public{
        require(_start > 0);
        require(_lockTime > 0);
        require(_start.add(_lockTime) > 0);
        require(_teamWallet != address(0));
        require(_earlyWallet != address(0));
        require(_institutionWallet != address(0));
        
        token = _token;
        teamWallet = _teamWallet;
        earlyWallet = _earlyWallet;
        institutionWallet = _institutionWallet;
        start = _start;
        lockStartTime = start.add(_lockTime);
    }
    
    function allocateToken() onlyOwner public{
        require(block.timestamp > lockStartTime);
        //only claim  once
        require(allocations[teamWallet] == 0);
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamWallet] = teamAllocation;
        allocations[earlyWallet] = earlyAllocation;
        allocations[institutionWallet] = institutionAllocation;
        
        stageSettings[teamWallet] = teamStageSetting;
        stageSettings[earlyWallet] = earlyStageSetting;
        stageSettings[institutionWallet] = institutionStageSetting;
        
        timeLockDurations[teamWallet] = teamTimeLock;
        timeLockDurations[earlyWallet] = earlyTimeLock;
        timeLockDurations[institutionWallet] = institutionTimeLock;
    }
    function releaseToken() onlyReserveWallets public{
        uint256 stage = vestStage();
        uint256 totalUnlocked = stage.mul(allocations[msg.sender]).div(stageSettings[msg.sender]);
        require(totalUnlocked < allocations[msg.sender]);
        require(releasedAmounts[msg.sender] < totalUnlocked);
        uint256 payment = totalUnlocked - releasedAmounts[msg.sender];
        
        releasedAmounts[msg.sender] = totalUnlocked;
        require(token.transfer(teamWallet, payment));
    }
    
    function vestStage() public view onlyReserveWallets returns(uint256){
        uint256 vestingMonths = timeLockDurations[msg.sender].div(stageSettings[msg.sender]);
        uint256 stage = (block.timestamp.sub(lockStartTime)).div(vestingMonths);
        
        if(stage > stageSettings[msg.sender]){
            stage = stageSettings[msg.sender];
        }
        return stage;
    }
}