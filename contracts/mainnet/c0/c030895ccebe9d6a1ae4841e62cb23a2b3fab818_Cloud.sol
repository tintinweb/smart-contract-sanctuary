pragma solidity ^0.4.16;

library Math {
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
    /// total amount of tokens
    uint256 public totalSupply;

    uint256 public decimals;                
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
contract Cloud is Token {

    using Math for uint256;
	bool trading=false;

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    function transfer(address _to, uint256 _value) canTrade returns (bool success) {
        require(_value > 0);
        require(!frozenAccount[msg.sender]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) canTrade returns (bool success) {
        require(_value > 0);
        require(!frozenAccount[_from]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        //require(balances[_from] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
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

	modifier canTrade {
    	require(trading==true ||(canRelease==true && msg.sender==owner));
    	_;
    }
    
    function setTrade(bool allow) onlyOwner {
    	trading=allow;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    
    /* Public variables of the token */
    event Invested(address investor, uint256 tokens);

    uint256 public employeeShare=8;
    // Wallets - 4 employee
    address[4] employeeWallets = [0x9caeD53A6C6E91546946dD866dFD66c0aaB9f347,0xf1Df495BE71d1E5EdEbCb39D85D5F6b620aaAF47,0xa3C38bc8dD6e26eCc0D64d5B25f5ce855bb57Cd5,0x4d67a23b62399eDec07ad9c0f748D89655F0a0CB];

    string public name;                 
    string public symbol;               
    address public owner;				
    uint256 public tokensReleased=0;
    bool canRelease=false;

    /* Initializes contract with initial supply tokens to the owner of the contract */
    function Cloud(
        uint256 _initialAmount,
        uint256 _decimalUnits,
        string _tokenName,
        string _tokenSymbol,
        address ownerWallet
        ) {
        owner=ownerWallet;
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        totalSupply = _initialAmount*(10**decimals);         // Update total supply
        balances[owner] = totalSupply;                       // Give the creator all initial tokens
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    /* Freezing tokens */
    function freezeAccount(address target, bool freeze) onlyOwner{
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /* Authenticating owner */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    /* Allow and restrict of release of tokens */
    function releaseTokens(bool allow) onlyOwner {
        canRelease=allow;
    }
    /// @param receiver The address of the account which will receive the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the token transfer was successful or not was successful or not
    function invest(address receiver, uint256 _value) onlyOwner returns (bool success) {
        require(canRelease);
        require(_value > 0);
        uint256 numTokens = _value*(10**decimals);
        uint256 employeeTokens = 0;
        uint256 employeeTokenShare=0;
        // divide employee tokens by 4 shares
        employeeTokens = numTokens.mul(employeeShare).div(100);
        employeeTokenShare = employeeTokens.div(employeeWallets.length);
        //split tokens for different wallets of employees and company
        approve(owner,employeeTokens.add(numTokens));
        for(uint i = 0; i < employeeWallets.length; i++)
        {
            require(transferFrom(owner, employeeWallets[i], employeeTokenShare));
        }
        require(transferFrom(owner, receiver, numTokens));
        tokensReleased = tokensReleased.add(numTokens).add(employeeTokens.mul(4));
        Invested(receiver,numTokens);
        return true;
    }
}