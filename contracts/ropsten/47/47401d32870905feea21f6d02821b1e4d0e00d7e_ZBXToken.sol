pragma solidity ^0.4.24;

// File: contracts/ERC20-token.sol

/**
 * @title ERC20 interface 
 * 
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () internal {
      _owner = msg.sender;
      emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns (address) {
      return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
      require(isOwner());
      _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns (bool) {
      return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
  }

}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
      // benefit is lost if &#39;b&#39; is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
      if (a == 0) {
          return 0;
      }

      uint256 c = a * b;
      require(c / a == b);

      return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

      return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      uint256 c = a - b;

      return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);

      return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b != 0);
      return a % b;
  }
 

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }
 
  
}

// File: contracts/ZBX/ZBXToken.sol

/**
 * @title Zillion Bits Token  
 *
 */
contract ZBXToken is ERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "Zillion Bits";  // The Token&#39;s name
  string public constant symbol = "XT";    // Identifier 
  uint8 public constant decimals = 18;      // Number of decimals  


  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  //Total amount of tokens is 500,000,000 - 500 million + 18 decimals
  uint256 public hardcap = 500000000 * (10**uint256(18));
 

  /**
   * @dev Constructor
   */
  constructor() public {

    //Set total supply to hardcap
    _totalSupply = hardcap;

    //Transfer total supply to owner
    _balances[owner()] = _totalSupply;
    emit Transfer(address(0), owner(), _totalSupply);

  }


  /**
   * @dev onlyPayloadSize
   * @notice Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  } 
 

  /**
   * @dev total number of tokens in existence
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Gets the balance of the specified address.
   * @param _owner The address to query the the balance of.
   * @return An uint256 representing the amount owned by the passed address.
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }
 
 
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    return _transfer(msg.sender, _to, _value); 
  }


  /**
   * @dev Internal transfer, only can be called by this contract  
   * @param _from is msg.sender The address to transfer from.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function _transfer(address _from, address _to, uint _value) internal returns (bool){
      require(_to != address(0)); // Prevent transfer to 0x0 address.
      require(_value <= _balances[msg.sender]);  // Check if the sender has enough      

      // SafeMath.sub will throw if there is not enough balance.
      _balances[_from] = _balances[_from].sub(_value);
      _balances[_to] = _balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {

    require(_to != address(0));                     // Prevent transfer to 0x0 address. Use burn() instead
    require(_value <= _balances[_from]);             // Check if the sender has enough
    require(_value <= _allowed[_from][msg.sender]);  // Check if the sender is _allowed to send


    // SafeMath.sub will throw if there is not enough balance.
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true; 
  }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:  
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }



  /**
   * @dev Function to check the amount of tokens that an owner _allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowed[_owner][_spender];
  }



  /**
   * @dev Increase the amount of tokens that an owner _allowed to a spender.
   *
   * approve should be called when _allowed[_spender] == 0. To increment
   * _allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)   
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
  }



  /**
   * @dev Decrease the amount of tokens that an owner _allowed to a spend.
   *
   * approve should be called when _allowed[_spender] == 0. To decrement
   * _allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)   
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = _allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      _allowed[msg.sender][_spender] = 0;
    } else {
      _allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
  }

 
  /**
   * @dev Burns a specific amount of tokens.
   * @param _account The account whose tokens will be burnt.
   * @param _value The amount of token to be burned.
   */
  function burn(address _account, uint256 _value) onlyOwner public {
      require(_account != address(0));

      _totalSupply = _totalSupply.sub(_value);
      _balances[_account] = _balances[_account].sub(_value);
      emit Transfer(_account, address(0), _value);
  }

  /**
   * @dev Function to mint tokens
   * @param _account The address that will receive the minted tokens.
   * @param _value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _account, uint256 _value) onlyOwner public {
      require(_account != address(0));
      require(_totalSupply.add(_value) <= hardcap);

      _totalSupply = _totalSupply.add(_value);
      _balances[_account] = _balances[_account].add(_value);
      emit Transfer(address(0), _account, _value);
  }


  /**
   * @dev Owner can transfer tokens that are sent to the contract by mistake
   * 
   */
  function refundTokens(address _recipient, ERC20 _token)  onlyOwner public {
    require(_token.transfer(_recipient, _token.balanceOf(this)));
  }


  /**
   * @dev transfer balance to owner
   * 
   */
  function withdrawEther(uint256 amount) onlyOwner public {
    owner().transfer(amount);
  }
  
  /**
   * @dev accept ether
   * 
   */
  function() public payable {
  }

 
}