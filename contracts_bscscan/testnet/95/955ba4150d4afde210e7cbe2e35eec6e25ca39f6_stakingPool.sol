/**
 *Submitted for verification at BscScan.com on 2021-07-30
*/

pragma solidity 0.4.24;

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function balanceOf(address _owner) external constant returns (uint256 balance);
}

contract onlyOwner {
  address public owner;
  /** 
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor() public {
    owner = msg.sender;
  }
  modifier isOwner {
    require(msg.sender == owner);
    _;
  }
}

/**
 * Math operations with safety checks that throw on overflows.
 */
library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
}

contract stakingPool is onlyOwner {
  using SafeMath for uint256;
  
  uint256 public constant stakingLockPeriod = 183 days;  // halfOfYear
  uint256 public constant airdropSupply = 8888888888 * 10**16 * 20; // Initial number of tokens available 20%
  
  address public token_saler_contract;
  uint256 public totalStaking;
  uint256 public totalStaked;
  bool private locked = true;
  Token token;  
  
  struct stakingInfo {
    uint256 staking_amount;
    uint256 reward_amount;
    uint256 unlockDate;
    uint status; // 0 : opened,  1: closed 
  }
  
  mapping (address => mapping(uint => stakingInfo)) public StakeMap;
  mapping (address => uint) public lastStakedIds;
  mapping (address => uint) public userLevels;
  
  event CreatedStaking(
    address indexed sender,
    uint256 indexed id,
    uint256 amount,
    uint256 unlockDate
  );
  
  event ClaimedStaking(
    address indexed sender,
    uint256 indexed id,
    uint256 withdraw_amount,
    uint256 reward_amount
  );
  
  constructor(address _tokenContract) public{
    token = Token(_tokenContract);
  }
  
    /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public constant returns (uint256) {
    return token.balanceOf(this);
  }
  
    /**
   * destroy
   * @notice Terminate contract and refund to owner
   **/
  function destroy() isOwner public {
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    assert(balance > 0);
    token.transfer(owner, balance);
    // There should be no ether in the contract but just in case
    selfdestruct(owner);
  }
  
  function initStakingPool(address _token_saler_contract) isOwner public {
      require(tokensAvailable() == airdropSupply); // Must have all airdrop tokens to be allocated
      token_saler_contract = _token_saler_contract;
      locked = false;
      totalStaked = 0;
      totalStaking = 0;
  }
  
  function setUserLevel(address _user, uint level) isOwner public {
      userLevels[_user] = level;  // 0: Ambassador 1000, 1: Affilate 5000, 2: Associate 10000, 3: Merchant 5000
  }
  
  function getMinStakeAmount(address _user) public view returns (uint256) {
    if (userLevels[_user] == 1)  return 5000 * 10**18;
    else if (userLevels[_user] == 2)  return 10000 * 10**18;
    else if (userLevels[_user] == 3)  return 5000 * 10**18;
    else return 1000 * 10 ** 18;    
  }
  
  function staking(uint256 _amount) public {
    require(locked == false, "Staking Pool should be unlock");  
    createStaking(++lastStakedIds[msg.sender], _amount);
  }
  
  function createStaking(uint256 _stakingId, uint256 _amount) internal {
    require(_amount >= getMinStakeAmount(msg.sender), "staking amount should be min amount");
    require(_stakingId > 0 && _stakingId <= lastStakedIds[msg.sender], "wrong staking id");
    require(token.transferFrom(msg.sender, address(this), _amount), "transfer failed");
    _createStaking(msg.sender, _stakingId, _amount);
  }
  
     
  function _createStaking(address _sender, uint256 _stakingId, uint256 _amount) internal  {
    totalStaking = totalStaking.add(_amount);
    StakeMap[_sender][_stakingId].staking_amount = _amount;
    StakeMap[_sender][_stakingId].unlockDate = now + stakingLockPeriod;
    StakeMap[_sender][_stakingId].status = 0;
    emit CreatedStaking(_sender, _stakingId, _amount, StakeMap[_sender][_stakingId].unlockDate);
  }    

  function addStakingFromSaler(address _sender, uint256 _amount) external returns (bool) {
    require(msg.sender == address(token_saler_contract), "only token saler contract is allowed");
    require(locked == false, "Staking Pool should be unlock");  
    _createStaking(_sender, ++lastStakedIds[_sender], _amount);
    return true;
  }


  function claimStaking(address _claimer, uint256 _stakingId) public {
    require(_stakingId > 0 && _stakingId <= lastStakedIds[msg.sender], "wrong staking id");
    require(StakeMap[_claimer][_stakingId].status == 0, "Not opened staking");
    require(StakeMap[_claimer][_stakingId].unlockDate >= now, "Staking is still in Locked period");
    require(token.transfer(_claimer, StakeMap[_claimer][_stakingId].staking_amount.div(100).mul(5)), "trasfer failed");
    _claimStaking(_claimer, _stakingId);
  }
  
  function _claimStaking(address _claimer, uint256 _stakingId) internal {
    StakeMap[_claimer][_stakingId].status = 1;
    StakeMap[_claimer][_stakingId].reward_amount = StakeMap[_claimer][_stakingId].staking_amount.div(100).mul(5);
    totalStaked = totalStaked.add(StakeMap[_claimer][_stakingId].reward_amount);
    totalStaking = totalStaking.sub(StakeMap[_claimer][_stakingId].staking_amount);
    emit ClaimedStaking(_claimer, _stakingId, StakeMap[_claimer][_stakingId].staking_amount, StakeMap[_claimer][_stakingId].reward_amount);
  }
  
  function getStakingInfo (address _staker, uint _stakingId) public view returns (uint256 staking_amount, uint256 status, uint256 unlockDate, uint256 reward_amount) {
    return (StakeMap[_staker][_stakingId].staking_amount, StakeMap[_staker][_stakingId].status, StakeMap[_staker][_stakingId].unlockDate, StakeMap[_staker][_stakingId].reward_amount);
  }
}