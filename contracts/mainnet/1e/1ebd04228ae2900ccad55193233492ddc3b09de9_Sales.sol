pragma solidity ^0.4.11;

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

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

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

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
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
}

contract HumanStandardToken is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    function HumanStandardToken(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
        ) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

contract Locked {
  uint public period;

  function Locked(uint _period) public {
    period = _period;
  }
}

contract Owned {
    function Owned() { owner = msg.sender; }
    address owner;

    // This contract only defines a modifier but does not use
    // it - it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // "_;" in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Sales is Owned {
  address public wallet;
  HumanStandardToken public token;
  Locked public locked;
  uint public price;
  uint public startBlock;
  uint public freezeBlock;
  bool public frozen = false;
  uint256 public cap = 0;
  uint256 public sold = 0;
  uint created;

  event PurchasedTokens(address indexed purchaser, uint amount);

  modifier saleHappening {
    require(block.number >= startBlock);
    require(block.number <= freezeBlock);
    require(!frozen);
    require(sold < cap);
    _;
  }

  function Sales(
    address _wallet,
    uint256 _tokenSupply,
    string _tokenName,
    uint8 _tokenDecimals,
    string _tokenSymbol,
    uint _price,
    uint _startBlock,
    uint _freezeBlock,
    uint256 _cap,
    uint _locked
  ) {
    wallet = _wallet;
    token = new HumanStandardToken(_tokenSupply, _tokenName, _tokenDecimals, _tokenSymbol);
    locked = new Locked(_locked);
    price = _price;
    startBlock = _startBlock;
    freezeBlock = _freezeBlock;
    cap = _cap;
    created = now;

    uint256 ownersValue = SafeMath.div(SafeMath.mul(token.totalSupply(), 20), 100);
    assert(token.transfer(wallet, ownersValue));

    uint256 saleValue = SafeMath.div(SafeMath.mul(token.totalSupply(), 60), 100);
    assert(token.transfer(this, saleValue));

    uint256 lockedValue = SafeMath.sub(token.totalSupply(), SafeMath.add(ownersValue, saleValue));
    assert(token.transfer(locked, lockedValue));
  }

  function purchaseTokens()
    payable
    saleHappening {
    uint excessAmount = msg.value % price;
    uint purchaseAmount = SafeMath.sub(msg.value, excessAmount);
    uint tokenPurchase = SafeMath.div(purchaseAmount, price);

    require(tokenPurchase <= token.balanceOf(this));

    if (excessAmount > 0) {
      msg.sender.transfer(excessAmount);
    }

    sold = SafeMath.add(sold, tokenPurchase);
    assert(sold <= cap);
    wallet.transfer(purchaseAmount);
    assert(token.transfer(msg.sender, tokenPurchase));
    PurchasedTokens(msg.sender, tokenPurchase);
  }

  /* owner only functions */
  function changeBlocks(uint _newStartBlock, uint _newFreezeBlock)
    onlyOwner {
    require(_newStartBlock != 0);
    require(_newFreezeBlock >= _newStartBlock);
    startBlock = _newStartBlock;
    freezeBlock = _newFreezeBlock;
  }

  function changePrice(uint _newPrice) 
    onlyOwner {
    require(_newPrice > 0);
    price = _newPrice;
  }

  function changeCap(uint256 _newCap)
    onlyOwner {
    require(_newCap > 0);
    cap = _newCap;
  }

  function unlockEscrow()
    onlyOwner {
    assert((now - created) > locked.period());
    assert(token.transfer(wallet, token.balanceOf(locked)));
  }

  function toggleFreeze()
    onlyOwner {
      frozen = !frozen;
  }
}