/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

}pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */


contract GemsToken is Ownable{
  
  using SafeMath for uint256;
  
  mapping(address => uint256) public balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  string public name = "Gems Of Power";
  string public symbol = "GOP";
  uint8 public decimals = 0;
  uint256 public totalSupply = 200000000 * 10 ** uint(decimals);
  address crowdsaleContract = address(0x0);
  bool flag = false;

  function GemsToken () public {
      balances[this] = totalSupply;
  }
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }
  
  /**
  * @dev getdecimals
  */
  function getdecimals() public view returns (uint8) {
      return decimals;
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[_to] = balances[_to].add(_value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  /**
 * public transfer, only can be called by this contract
 */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from].add(balances[_to]);
        // Subtract from the sender
        balances[_from] = balances[_from].sub(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
        return true;
    }
  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  
  function sendCrowdsaleBalance (address _address, uint256 _value) public {
      require (msg.sender == crowdsaleContract);
      require (_value <= balances[this]);
      totalSupply = totalSupply.sub(_value);
      balances[this] = balances[this].sub(_value);
      balances[_address] = balances[_address].add(_value);
      Transfer(this, _address, _value);
  }
  
  function sendOwnerBalance(address _address, uint _value) public onlyOwner {
     uint256 value = _value * 10 ** uint(decimals);
     require (value <= balances[this]);
     balances[this] = balances[this].sub(value);
     balances[_address] = balances[_address].add(value);
     Transfer(this, _address, value);
  }
  
  
  function setCrowdsaleContract(address _address) public onlyOwner {
     require(!flag);
     crowdsaleContract = _address;
     flag = true;
  }
  
  function removeCrowdsaleContract(address _address) public onlyOwner {
      require(flag);
      if(crowdsaleContract == _address) {
         crowdsaleContract = address(0x0);
         flag = false;
      }
  }
  
  function GetcrowdsaleContract() public view returns(address) {
      return crowdsaleContract;
  }
  
}