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

interface StakingPool {
    function addStakingFromSaler(address , uint256) external returns (bool);
}

contract TokenVesting is onlyOwner {
  using SafeMath for uint256;
  Token token;
  
  uint256 public constant totalSupply = 8888888888 * 10**18; // Initial number of tokens available
  
  bool public initialized = false;
  
  address public reserved_fund_account = 0x689DBd5A8F6b91c41f427B16d7e5A711829c5BE4;
  address public team_fund_account = 0xa4F6877908CAD54A3e64845376E9D268910E7E04;
  address public partners_fund_account = 0x6a9307652d93CaB45634cAD19cf9E60b0D7504E7;
  address public saler_account = 0x0f22F0f1C70b0277dEE7F0FF1ac480CB594Ca450;
  address public airdropper_account = 0xAb0F7F79d62da5fD735903af67DDb8039fd8058a;
  address public staking_pool_contract = 0x45fDbAF69f4f89BB69e66e85E62efa45D32D70Cc;
  StakingPool staking_pool = StakingPool(staking_pool_contract);
  uint256 public start_time = 0;
  
  struct VestingStage {
    uint256 date;
    uint256 tokensPercentage;
    uint256 saled;
  }

  VestingStage[3] public stages;    
  
  event PrivateSaled(address indexed to, uint256 value);
  
  modifier isSaler() {
    require(msg.sender == saler_account);
    _;
  }

  modifier whenSaleIsActiveInStage(uint stage) {
    // Check if sale is active
    assert(isActive(stage));
    _;
  }
  
  constructor (address _tokenAddr) public {
      require(_tokenAddr != 0);
      token = Token(_tokenAddr);
  }
  
  function initialize() public isOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() == totalSupply); // Must have all tokens to be allocated
      initialized = true;
      start_time = now;
      initDistribution();
      initVestingStages();
  }
  
  function initDistribution() internal {
      token.transfer(reserved_fund_account, totalSupply.mul(5).div(100));   // 5% - reserved fund
      token.transfer(team_fund_account, totalSupply.mul(14).div(100));   // 14% - team fund
      token.transfer(partners_fund_account, totalSupply.mul(6).div(100));   // 6% - team fund
      token.transfer(airdropper_account, totalSupply.mul(20).div(100));   // 20% - airdropping
  }
  
  function initVestingStages () internal {
    uint256 oneMonth = 30 days;
    // uint256 halfOfYear = 183 days;
    // uint256 year = halfOfYear * 2;
    stages[0].date = start_time;   // private sale
    stages[1].date = start_time + oneMonth;   // pre-public sale
    stages[2].date = start_time + oneMonth * 2;   // public sale
    
    stages[0].tokensPercentage = 10; // private sale
    stages[1].tokensPercentage = 15; // pre-public sale
    stages[2].tokensPercentage = 30; // public sale
    
    stages[0].saled = 0;
    stages[1].saled = 0;
    stages[2].saled = 0;
  }
  
  function changeSaler(address _saler) isOwner public{
      saler_account = _saler;
  } 
  
  function getStageAttributes (uint8 index) public view returns (uint256 date, uint256 tokensPercentage, uint256 saled) {
    return (stages[index].date, stages[index].tokensPercentage, stages[index].saled);
  }

  function isActive(uint step) public view returns (bool) {
    return (
        initialized == true &&
        now >= stages[step].date && // Must be after the START date
        now <= stages[step+1].date && // Must be before the end date
        goalReached(step) == false // Goal must not already be reached
    );
  }

  function goalReached(uint step) public view returns (bool) {
    return (stages[step].saled >= totalSupply.mul(stages[step].tokensPercentage).div(100));
  }

  function privateSaled(address buyer, uint256 amount) isSaler public whenSaleIsActiveInStage(0) {
    require(staking_pool.addStakingFromSaler(buyer, amount) == true);
    stages[0].saled.add(amount); 
  }
  
  function prePublicSaled(address buyer, uint256 amount) isSaler public whenSaleIsActiveInStage(1) {
    require(staking_pool.addStakingFromSaler(buyer, amount) == true);
    stages[1].saled.add(amount); 
  }
  
  function publicSaled(address buyer, uint256 amount) isSaler public whenSaleIsActiveInStage(2) {
    require(staking_pool.addStakingFromSaler(buyer, amount) == true);
    stages[2].saled.add(amount); 
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
}