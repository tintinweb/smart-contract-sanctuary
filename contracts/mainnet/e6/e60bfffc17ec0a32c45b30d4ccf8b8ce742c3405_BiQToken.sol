pragma solidity ^0.4.15;

//import &#39;./lib/safeMath.sol&#39;;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// import &#39;./ERC20.sol&#39;;
contract ERC20 {
  uint256 public totalSupply;
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function transfer(address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  function allowance(address owner, address spender) constant returns (uint256);
  function balanceOf(address who) constant returns (uint256);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// import &#39;./helpers/BasicToken.sol&#39;;
contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
/**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }
      return false;
}


  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
    function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


}

contract BiQToken is BasicToken {

  using SafeMath for uint256;

  string public name = "BurstIQ Token";              //name of the token
  string public symbol = "BiQ";                      // symbol of the token
  uint8 public decimals = 18;                        // decimals
  uint256 public totalSupply = 1000000000 * 10**18;  // total supply of BiQ Tokens

  // variables
  uint256 public keyEmployeesAllocatedFund;           // fund allocated to key employees
  uint256 public advisorsAllocation;                  // fund allocated to advisors
  uint256 public marketIncentivesAllocation;          // fund allocated to Market
  uint256 public vestingFounderAllocation;            // funds allocated to founders that in under vesting period
  uint256 public totalAllocatedTokens;                // variable to keep track of funds allocated
  uint256 public tokensAllocatedToCrowdFund;          // funds allocated to crowdfund
  uint256 public saftInvestorAllocation;              // funds allocated to private presales and instituational investors

  bool public isPublicTokenReleased = false;          // flag to track the release the public token

  // addresses

  address public founderMultiSigAddress;              // multi sign address of founders which hold
  address public advisorAddress;                      //  advisor address which hold advisorsAllocation funds
  address public vestingFounderAddress;               // address of founder that hold vestingFounderAllocation
  address public crowdFundAddress;                    // address of crowdfund contract

  // vesting period

  uint256 public preAllocatedTokensVestingTime;       // crowdfund start time + 6 months

  //events

  event ChangeFoundersWalletAddress(uint256  _blockTimeStamp, address indexed _foundersWalletAddress);
  event TransferPreAllocatedFunds(uint256  _blockTimeStamp , address _to , uint256 _value);
  event PublicTokenReleased(uint256 _blockTimeStamp);

  //modifiers

  modifier onlyCrowdFundAddress() {
    require(msg.sender == crowdFundAddress);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

  modifier onlyFounders() {
    require(msg.sender == founderMultiSigAddress);
    _;
  }

  modifier onlyVestingFounderAddress() {
    require(msg.sender == vestingFounderAddress);
    _;
  }

  modifier onlyAdvisorAddress() {
    require(msg.sender == advisorAddress);
    _;
  }

  modifier isPublicTokenNotReleased() {
    require(isPublicTokenReleased == false);
    _;
  }


  // creation of the token contract
  function BiQToken (address _crowdFundAddress, address _founderMultiSigAddress, address _advisorAddress, address _vestingFounderAddress) {
    crowdFundAddress = _crowdFundAddress;
    founderMultiSigAddress = _founderMultiSigAddress;
    vestingFounderAddress = _vestingFounderAddress;
    advisorAddress = _advisorAddress;

    // Token Distribution
    vestingFounderAllocation = 18 * 10 ** 25 ;        // 18 % allocation of totalSupply
    keyEmployeesAllocatedFund = 2 * 10 ** 25 ;        // 2 % allocation of totalSupply
    advisorsAllocation = 5 * 10 ** 25 ;               // 5 % allocation of totalSupply
    tokensAllocatedToCrowdFund = 60 * 10 ** 25 ;      // 60 % allocation of totalSupply
    marketIncentivesAllocation = 5 * 10 ** 25 ;       // 5 % allocation of totalSupply
    saftInvestorAllocation = 10 * 10 ** 25 ;          // 10 % alloaction of totalSupply

    // Assigned balances to respective stakeholders
    balances[founderMultiSigAddress] = keyEmployeesAllocatedFund + saftInvestorAllocation;
    balances[crowdFundAddress] = tokensAllocatedToCrowdFund;

    totalAllocatedTokens = balances[founderMultiSigAddress];
    preAllocatedTokensVestingTime = now + 180 * 1 days;                // it should be 6 months period for vesting
  }

  // function to keep track of the total token allocation
  function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
    totalAllocatedTokens = totalAllocatedTokens.add(_amount);
    tokensAllocatedToCrowdFund = tokensAllocatedToCrowdFund.sub(_amount);
  }

  // function to change founder multisig wallet address
  function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    founderMultiSigAddress = _newFounderMultiSigAddress;
    ChangeFoundersWalletAddress(now, founderMultiSigAddress);
  }

  // function for releasing the public tokens called once by the founder only
  function releaseToken() onlyFounders isPublicTokenNotReleased {
    isPublicTokenReleased = !isPublicTokenReleased;
    PublicTokenReleased(now);
  }

  // function to transfer market Incentives fund
  function transferMarketIncentivesFund(address _to, uint _value) onlyFounders nonZeroAddress(_to)  returns (bool) {
    if (marketIncentivesAllocation >= _value) {
      marketIncentivesAllocation = marketIncentivesAllocation.sub(_value);
      balances[_to] = balances[_to].add(_value);
      totalAllocatedTokens = totalAllocatedTokens.add(_value);
      TransferPreAllocatedFunds(now, _to, _value);
      return true;
    }
    return false;
  }


  // fund transferred to vesting Founders address after 6 months
  function getVestedFounderTokens() onlyVestingFounderAddress returns (bool) {
    if (now >= preAllocatedTokensVestingTime && vestingFounderAllocation > 0) {
      balances[vestingFounderAddress] = balances[vestingFounderAddress].add(vestingFounderAllocation);
      totalAllocatedTokens = totalAllocatedTokens.add(vestingFounderAllocation);
      vestingFounderAllocation = 0;
      TransferPreAllocatedFunds(now, vestingFounderAddress, vestingFounderAllocation);
      return true;
    }
    return false;
  }

  // fund transferred to vesting advisor address after 6 months
  function getVestedAdvisorTokens() onlyAdvisorAddress returns (bool) {
    if (now >= preAllocatedTokensVestingTime && advisorsAllocation > 0) {
      balances[advisorAddress] = balances[advisorAddress].add(advisorsAllocation);
      totalAllocatedTokens = totalAllocatedTokens.add(advisorsAllocation);
      advisorsAllocation = 0;
      TransferPreAllocatedFunds(now, advisorAddress, advisorsAllocation);
      return true;
    } else {
      return false;
    }
  }

  // overloaded transfer function to restrict the investor to transfer the token before the ICO sale ends
  function transfer(address _to, uint256 _value) returns (bool) {
    if (msg.sender == crowdFundAddress) {
      return super.transfer(_to,_value);
    } else {
      if (isPublicTokenReleased) {
        return super.transfer(_to,_value);
      }
      return false;
    }
  }

  // overloaded transferFrom function to restrict the investor to transfer the token before the ICO sale ends
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    if (msg.sender == crowdFundAddress) {
      return super.transferFrom(_from, _to, _value);
    } else {
      if (isPublicTokenReleased) {
        return super.transferFrom(_from, _to, _value);
      }
      return false;
    }
  }

  // fallback function to restrict direct sending of ether
  function () {
    revert();
  }

}