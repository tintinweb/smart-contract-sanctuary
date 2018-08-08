pragma solidity ^0.4.15;

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

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Token {

    /// @return total amount of tokens
    //function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


//name this contract whatever you&#39;d like
contract HOLODECKS is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        revert();
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customize the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H1.0&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

//
// CHANGE THESE VALUES FOR YOUR TOKEN
//

//make sure this function name matches the contract name above. So if you&#39;re token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token

    function HOLODECKS(
        ) {
        decimals = 18; 
        totalSupply = 1500000000 * (10 ** uint256(decimals));                        // Update total supply (100000 for example)
        balances[msg.sender] = totalSupply;               // Give the creator all initial tokens (100000 for example)
        name = "HOLODECKS";                                   // Set the name for display purposes
        symbol = "HDK";                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }
}


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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Token 
 * @dev API interface for interacting with the HOLODECKS contract
 * /
 interface Token {
 function transfer (address _to, uint256 _value) returns (bool);
 function balanceOf (address_owner) constant returns (uint256 balance);
}

/**
 * @title HDK_Crowdsale
 * @dev HDK_Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract HDK_Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  HOLODECKS public token;

  // start and end timestamps where investments are allowed (both inclusive)


  uint256 public startTime = 1523750400;
  uint256 public phase_1_Time = 1526342400 ;
  uint256 public phase_2_Time = 1529020800;
  uint256 public endTime = 1531612800;

  // Max amount of wei accepted in the crowdsale
  uint256 public cap;
  
  // Min amount of wei an investor can send
  uint256 public minInvest;
  
  
  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets. 1 ETH = 10000 HDK
  uint256 public phase_1_rate = 13000;
  uint256 public phase_2_rate = 12000;
  uint256 public phase_3_rate = 11000;
  
  
  // amount of raised money in wei
  uint256 public weiRaised;

  mapping (address => uint256) rates;

  function getRate() constant returns (uint256){
    uint256 current_time = now;

    if(current_time > startTime && current_time < phase_1_Time){
      return phase_1_rate;
    }
    else if(current_time > phase_1_Time && current_time < phase_2_Time){
      return phase_2_rate;
    }
      else if(current_time > phase_2_Time && current_time < endTime){
      return phase_3_rate;
    }
      
  }

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function HDK_Crowdsale() {
    wallet = msg.sender;
    token = createTokenContract();
    minInvest = 0.1 * 1 ether;
    cap = 100000 * 1 ether;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (HOLODECKS) {
    return new HOLODECKS();
  }


  // fallback function can be used to buy tokens
  function () payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(getRate());

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
/**
 * @notice Terminate contract and refund to owner
 */
 function destroy() onlyOwner {
     // Transfer tokens back to owner
     uint256 balance = token.balanceOf(this);
     assert (balance > 0);
     token.transfer(owner,balance);
     
     // There should be no ether in the contract but just in case
     selfdestruct(owner);
     
 }

}