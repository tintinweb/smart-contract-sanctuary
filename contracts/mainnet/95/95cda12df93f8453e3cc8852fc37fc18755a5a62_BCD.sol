pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal pure returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal pure returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal pure returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract ERC20Basic {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public constant decimals = 18;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  // used for airdrop
  uint256 airdropTotalSupply;
  uint256 airdropCurrentSupply;
  uint256 airdropNum; // airdrop number for each account
  // store if the address is touched for airdrop
  mapping(address => bool) touched; 

  /**
   * Internal transfer, only can be called by this contract
   */
  function _transfer(address _from, address _to, uint _value) internal {
    // add airdrop to address _from
    initialize(_from);
    require(_to != address(0));
    require(_value <= balances[_from]);

    // add airdrop to address _to
    initialize(_to);

    // SafeMath.sub will throw if there is not enough balance.
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
  }
  
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);

    // in any transfer function, emit should be done manually
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return getBalance(_owner);
  }

  // internal privats
  function initialize(address _address) internal returns (bool success) {
    if (airdropCurrentSupply < airdropTotalSupply && !touched[_address]) {
      touched[_address] = true;
      airdropCurrentSupply = airdropCurrentSupply.add(airdropNum);
      balances[_address] = balances[_address].add(airdropNum);
      totalSupply = totalSupply.add(airdropNum);
    }
    return true;
  }

  function getBalance(address _address) internal view returns (uint256) {
    if (airdropCurrentSupply < airdropTotalSupply && !touched[_address]) {
      return balances[_address].add(airdropNum);
    } else {
      return balances[_address];
    }
  }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_value <= allowed[_from][msg.sender]);

    _transfer(_from, _to, _value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    // in any transfer function, emit should be done manually
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * Set allowance for other address and notify
   *
   * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
   *
   * @param _spender The address authorized to spend
   * @param _value the max amount they can spend
   * @param _extraData some extra information to send to the approved contract
   */
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  /**
   * Destroy tokens
   * 
   * Remove `_value` tokens from the system irreversibly
   * 
   * @param _value the amount of money to burn
   */
  function burn(uint256 _value) public returns (bool success) {
    require(balanceOf(msg.sender) >= _value); // Check if the sender has enough
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }

  /**
   * Destroy tokens from other account
   *
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   *
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(balanceOf(_from) >= _value); // Check if the targeted balance is enough
    require(_value <= allowance(_from, msg.sender)); // Check allowance
    balances[_from] = balances[_from].sub(_value); // Subtract from the targeted balance
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // Subtract from the sender&#39;s allowance
    totalSupply = totalSupply.sub(_value); // Update totalSupply
    emit Burn(_from, _value);
    return true;
  }
}

contract BCD is StandardToken {

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor(
    uint256 _initialSupply,
    string _tokenName, 
    string _tokenSymbol, 
    uint _airdropTotalSupply, 
    uint256 _airdropNum 
  ) public {
    touched[msg.sender] = true; // ignore airdrop to owner

    totalSupply = _initialSupply * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
    name = _tokenName;
    symbol = _tokenSymbol;
    airdropTotalSupply = _airdropTotalSupply * 10 ** uint256(decimals);
    airdropNum = _airdropNum * 10 ** uint256(decimals);
  }

}