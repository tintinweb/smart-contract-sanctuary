pragma solidity ^0.4.23;

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

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract BasicToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier nonZeroEth(uint _value) {
      require(_value > 0);
      _;
    }

    modifier onlyPayloadSize() {
      require(msg.data.length >= 68);
      _;
    }


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Allocate(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */

    function transfer(address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]){
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        }else{
            return false;
        }
    }


    /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

    function transferFrom(address _from, address _to, uint256 _value) nonZeroEth(_value) onlyPayloadSize returns (bool) {
      if(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]){
        uint256 _allowance = allowed[_from][msg.sender];
        allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        Transfer(_from, _to, _value);
        return true;
      }else{
        return false;
      }
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



contract DexAgeTest is BasicToken, Ownable{

using SafeMath for uint256;

//token attributes

string public name = "DexAge Test";             

string public symbol = "DXGT";                      

uint8 public decimals = 18;

uint256 public totalSupply = 5000000000 * 10**uint256(decimals); 

uint256 private constant decimalFactor = 10**uint256(decimals);

bool public transfersAreLocked = true;

mapping (address => Allocation) public allocations;

// Allocation with vesting information
// 25% Released at Token Distribution +0.5 year -> 100% at Token Distribution +2 years
struct Allocation {
  uint256 startTime;
  uint256 endCliff;       // Tokens are locked until
  uint256 endVesting;     // This is when the tokens are fully unvested
  uint256 totalAllocated; // Total tokens allocated
  uint256 amountClaimed;  // Total tokens claimed
}

uint256 public grandTotalClaimed = 0;
uint256 tokensForDistribution = totalSupply.div(2);
uint256 ethPrice = 1000;
uint256 tokenPrice = 4;

//events
event LogNewAllocation(address indexed _recipient, uint256 _totalAllocated);
event LogBoonReleased(address indexed _recipient, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);

///////////////////////////////////////// CONSTRUCTOR for Distribution //////////////////////////////////////////////////

  function DexAgeTest () {
    balances[msg.sender] = totalSupply;
  }

///////////////////////////////////////// MODIFIERS /////////////////////////////////////////////////

// Checks whether it can transfer or otherwise throws.
  modifier canTransfer() {
    require(transfersAreLocked == false);
    _;
  }

  modifier nonZeroAddress(address _to) {
    require(_to != 0x0);
    _;
  }

////////////////////////////////////////// FUNCTIONS //////////////////////////////////////////////

// Returns current token Owner

  function tokenOwner() public view returns (address) {
    return owner;
  }

// Checks modifier and allows transfer if tokens are not locked.
  function transfer(address _to, uint _value) canTransfer() public returns (bool success) {
    return super.transfer(_to, _value);
  }

  // Checks modifier and allows transfer if tokens are not locked.
  function transferFrom(address _from, address _to, uint _value) canTransfer() public returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  // lock/unlock transfers
  function transferLock() onlyOwner public{
        transfersAreLocked = true;
  }
  function transferUnlock() onlyOwner public{
        transfersAreLocked = false;
  }

  function setFounderAllocation(address _recipient, uint256 _totalAllocated) onlyOwner public {
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_recipient != address(0));

    allocations[_recipient] = Allocation(now, now + 0.5 years, now + 2 years, _totalAllocated, 0);
    //allocations[_recipient] = Allocation(now, now + 2 minutes, now + 4 minutes, _totalAllocated, 0);

    LogNewAllocation(_recipient, _totalAllocated);
  }


  function releaseVestedTokens(address _tokenAddress) onlyOwner public{
    require(allocations[_tokenAddress].amountClaimed < allocations[_tokenAddress].totalAllocated);
    require(now >= allocations[_tokenAddress].endCliff);
    require(now >= allocations[_tokenAddress].startTime);
    uint256 newAmountClaimed;
    if (allocations[_tokenAddress].endVesting > now) {
      // Transfer available amount based on vesting schedule and allocation
      newAmountClaimed = allocations[_tokenAddress].totalAllocated.mul(now.sub(allocations[_tokenAddress].startTime)).div(allocations[_tokenAddress].endVesting.sub(allocations[_tokenAddress].startTime));
    } else {
      // Transfer total allocated (minus previously claimed tokens)
      newAmountClaimed = allocations[_tokenAddress].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_tokenAddress].amountClaimed);
    allocations[_tokenAddress].amountClaimed = newAmountClaimed;
    if(transfersAreLocked == true){
      transfersAreLocked = false;
      require(transfer(_tokenAddress, tokensToTransfer * decimalFactor));
      transfersAreLocked = true;
    }else{
      require(transfer(_tokenAddress, tokensToTransfer * decimalFactor));
    }
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    LogBoonReleased(_tokenAddress, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }

  function distributeToken(address[] _addresses, uint256[] _value) onlyOwner public {
     for (uint i = 0; i < _addresses.length; i++) {
         transfersAreLocked = false;
         require(transfer(_addresses[i], _value[i] * decimalFactor));
         transfersAreLocked = true;
     }

  }

    // Buy token function call only in duration of crowdfund active
  function getNoOfTokensTransfer(uint32 _exchangeRate , uint256 _amount) internal returns (uint256) {
       uint256 noOfToken = _amount.mul(_exchangeRate);
       uint256 noOfTokenWithBonus =(100 * noOfToken ) / 100;
       return noOfTokenWithBonus;
  }

  function setEthPrice(uint256 value)
    external
    onlyOwner
    {
      ethPrice = value;

    }
  function calcToken(uint256 value)
      internal
      returns(uint256 amount){
           amount =  ethPrice.mul(100).mul(value).div(tokenPrice);
           return amount;
      }
   function buyTokens()
          external
          payable
          returns (uint256 amount)
          {
              amount = calcToken(msg.value);
              require(msg.value > 0);
              require(balanceOf(owner) >= amount);
              balances[owner] = balances[owner].sub(msg.value);
              balances[msg.sender] = balances[msg.sender].add(msg.value);
              return amount;
  }
}