pragma solidity ^0.4.18;
/**
 * Overflow aware uint math functions.
 *
 * Inspired by https://github.com/MakerDAO/maker-otc/blob/master/contracts/simple_market.sol
 */
contract SafeMath {
  //internals

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * ERC 20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 */
contract StandardToken is Token {

    /**
     * Reviewed:
     * - Interger overflow = OK, checked
     */
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;

}


/*
* monechain token contract
*/

contract monechainToken is StandardToken, SafeMath {
  string public name = "monechain token";
  string public symbol = "MONE";
  uint public decimals = 18;
  uint crowdSalePrice = 300000;
  uint totalPeriod = 256 * 24 * 365; // unit: block count, estimate: 7 days
  /* uint public startBlock = 5275100; //crowdsale start block */
  uint public startBlock = 5278735; //crowdsale start block
  uint public endBlock = startBlock + totalPeriod; //crowdsale end block

  address public founder = 0x466ea8E1003273AE4471c903fBA7D8edF834970a;
  uint256 bountyAllocation =    4500000000 * 10**(decimals);  //pre-allocation tokens
  uint256 public crowdSaleCap = 1000000000 * 10**(decimals);  //max token sold during crowdsale
  uint256 public candyCap =     4500000000 * 10**(decimals);  //max token send as candy
  uint256 public candyPrice =   1000;  //candy amount per address
  uint256 public crowdSaleSoldAmount = 0;
  uint256 public candySentAmount = 0;

  mapping(address => bool) candyBook;  //candy require record book
  event Buy(address indexed sender, uint eth, uint fbt);

  function monechainToken() {
    // founder = msg.sender;
    balances[founder] = bountyAllocation;
    totalSupply = bountyAllocation;
    Transfer(address(0), founder, bountyAllocation);
  }

  function price() constant returns(uint) {
      if (block.number<startBlock || block.number > endBlock) return 0; //this will not happen according to the buyToken block check, but still set it to 0.
      else  return crowdSalePrice; // default-ICO
  }

  function() public payable  {
    if(msg.value == 0) {
      //candy
      sendCandy(msg.sender);
    }
    else {
      // crowdsale
      buyToken(msg.sender, msg.value);
    }
  }

  function sendCandy(address recipient) internal {
    // check the address to see Whether or not it already has a record in the dababase
    if (candyBook[recipient] || candySentAmount>=candyCap) revert();
    else {
      uint candies = candyPrice * 10**(decimals);
      candyBook[recipient] = true;
      balances[recipient] = safeAdd(balances[recipient], candies);
      candySentAmount = safeAdd(candySentAmount, candies);
      totalSupply = safeAdd(totalSupply, candies);
      Transfer(address(0), recipient, candies);
    }
  }

  function buyToken(address recipient, uint256 value) internal {
      if (block.number<startBlock || block.number>endBlock) throw;  //crowdsale period checked
      uint tokens = safeMul(value, price());

      if(safeAdd(crowdSaleSoldAmount, tokens)>crowdSaleCap) throw;   //crowdSaleCap checked

      balances[recipient] = safeAdd(balances[recipient], tokens);
      crowdSaleSoldAmount = safeAdd(crowdSaleSoldAmount, tokens);
      totalSupply = safeAdd(totalSupply, tokens);

      Transfer(address(0), recipient, tokens); //Transaction record for token perchaise
      if (!founder.call.value(value)()) throw; //immediately send Ether to founder address
      Buy(recipient, value, tokens); //Buy event
  }

  // check how many candies one can claim by now;
  function checkCandy(address recipient) constant returns (uint256 remaining) {
    if(candyBook[recipient]) return 0;
    else return candyPrice;
  }

  function changeFounder(address newFounder) {
    if (msg.sender!=founder) throw;
    founder = newFounder;
  }

}