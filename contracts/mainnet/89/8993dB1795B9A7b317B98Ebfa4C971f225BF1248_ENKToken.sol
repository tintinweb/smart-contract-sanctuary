pragma solidity ^0.4.20;

/**
 *  Standard Interface for ERC20 Contract
 */
contract IERC20 {
    function totalSupply() public constant returns (uint _totalSupply);
    function balanceOf(address _owner) public constant returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


/**
 * Checking overflows for various operations
 */
library SafeMathLib {

/**
* Issue: Change to internal constant
**/
  function minus(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

/**
* Issue: Change to internal constant
**/
  function plus(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}

/**
 * @title Ownable
 * @notice The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @notice The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @notice Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }
    
}

contract HasAddresses {
    address teamAddress = 0xb72D3a827c7a7267C0c8E14A1F4729bF38950887;
    address advisoryPoolAddress = 0x83a330c4A0f7b2bBe1B463F7a5a5eb6EA429E981;
    address companyReserveAddress = 0x6F221CFDdac264146DEBaF88DaaE7Bb811C29fB5;
    address freePoolAddress = 0x108102b4e6F92a7A140C38F3529c7bfFc950081B;
}


contract VestingPeriods{
    uint teamVestingTime = 1557360000;            // GMT: Thursday, 9 May 2019 00:00:00 
    uint advisoryPoolVestingTime = 1541721600;    // Human time (GMT): Friday, 9 November 2018 00:00:00
    uint companyReserveAmountVestingTime = 1541721600;    // Human time (GMT): Friday, 9 November 2018 00:00:00

}


contract Vestable {

    uint defaultVestingDate = 1526428800;  // timestamp after which transfers will be enabled,  Wednesday, 16 May 2018 00:00:00

    mapping(address => uint) vestedAddresses ;    // Addresses vested till date
    bool isVestingOver = false;

    function addVestingAddress(address vestingAddress, uint maturityTimestamp) internal{
        vestedAddresses[vestingAddress] = maturityTimestamp;
    }

    function checkVestingTimestamp(address testAddress) public constant returns(uint){
        return vestedAddresses[testAddress];

    }

    function checkVestingCondition(address sender) internal returns(bool) {
        uint vestingTimestamp = vestedAddresses[sender];
        if(vestingTimestamp == 0){
            vestingTimestamp = defaultVestingDate;
        }
        return now > vestingTimestamp;
    }
}

/**
 * @title ENKToken Token
 * @notice The ERC20 Token.
 */
contract ENKToken is IERC20, Ownable, Vestable, HasAddresses, VestingPeriods {
    
    using SafeMathLib for uint256;
    
    uint256 public constant totalTokenSupply = 1500000000 * 10**18;

    uint256 public burntTokens;

    string public constant name = "Enkidu";    // Enkidu
    string public constant symbol = "ENK";  // ENK
    uint8 public constant decimals = 18;
            
    mapping (address => uint256) public balances;
    //approved[owner][spender]
    mapping(address => mapping(address => uint256)) approved;
    
    function ENKToken() public {
        
        uint256 teamPoolAmount = 420 * 10**6 * 10**18;         // 420 million ENK
        uint256 advisoryPoolAmount = 19 * 10**5 * 10**18;      // 1.9 million ENK
        uint256 companyReserveAmount = 135 * 10**6 * 10**18;   // 135 million ENK
        
        uint256 freePoolAmmount = totalTokenSupply - teamPoolAmount - advisoryPoolAmount;     //   1.5 billion - ( 556.9 million )
        balances[teamAddress] = teamPoolAmount;
        balances[freePoolAddress] = freePoolAmmount;
        balances[advisoryPoolAddress] = advisoryPoolAmount;    
        balances[companyReserveAddress] = companyReserveAmount;
        emit Transfer(address(this), teamAddress, teamPoolAmount);
        emit Transfer(address(this), freePoolAddress, freePoolAmmount);
        emit Transfer(address(this), advisoryPoolAddress, advisoryPoolAmount);
        emit Transfer(address(this), companyReserveAddress, companyReserveAmount);
        addVestingAddress(teamAddress, teamVestingTime);            // GMT: Thursday, 9 May 2019 00:00:00 
        addVestingAddress(advisoryPoolAddress, advisoryPoolVestingTime);    // Human time (GMT): Friday, 9 November 2018 00:00:00
        addVestingAddress(companyReserveAddress, companyReserveAmountVestingTime);    // Human time (GMT): Friday, 9 November 2018 00:00:00
    }

    function burn(uint256 _value) public {
        require (balances[msg.sender] >= _value);                 // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].minus(_value);
        burntTokens += _value;
        emit BurnToken(msg.sender, _value);
    } 

    
    function totalSupply() constant public returns (uint256 _totalSupply) {
        return totalTokenSupply - burntTokens;
    }
    
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[_from] >= _value);                 // Check if the sender has enough
        require (balances[_to] + _value > balances[_to]);   // Check for overflows
        balances[_from] = balances[_from].minus(_value);    // Subtract from the sender
        balances[_to] = balances[_to].plus(_value);         // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /**
     * @notice Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(checkVestingCondition(msg.sender));
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * @notice Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_from));
        require (_value <= approved[_from][msg.sender]);     // Check allowance
        approved[_from][msg.sender] = approved[_from][msg.sender].minus(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    /**
     * @notice Approve `_value` tokens for `_spender`
     * @param _spender The address of the sender
     * @param _value the amount to send
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(checkVestingCondition(_spender));
        if(balances[msg.sender] >= _value) {
            approved[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        }
        return false;
    }
        
    /**
     * @notice Check `_value` tokens allowed to `_spender` by `_owner`
     * @param _owner The address of the Owner
     * @param _spender The address of the Spender
     */
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return approved[_owner][_spender];
    }
        
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event BurnToken(address _owner, uint256 _value);
    
}