pragma solidity ^0.4.11;

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

  function safeDiv(uint a, uint b) internal returns (uint) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
  }
}

// ERC 20 Token
// https://github.com/ethereum/EIPs/issues/20

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


/**
 * MoldCoin crowdsale contract.
 *
 */
contract MoldCoin is StandardToken, SafeMath {

    string public name = "Mold";
    string public symbol = "MLD";
    uint public decimals = 18;

    uint public startDatetime; //crowdsale start datetime seconds
    uint public firstStageDatetime; //first 120 hours crowdsale in seconds
    uint public secondStageDatetime; //second stage, 240 hours of crowsale in seconds.
    uint public endDatetime; //crowdsale end datetime seconds (set in constructor)

    // Initial founder address (set in constructor)
    // All deposited ETH will be instantly forwarded to this address.
    address public founder;

    // administrator address
    address public admin;

    uint public coinAllocation = 20 * 10**8 * 10**decimals; //2000M tokens supply for crowdsale
    uint public angelAllocation = 2 * 10**8 * 10**decimals; // 200M of token supply allocated angel investor
    uint public founderAllocation = 3 * 10**8 * 10**decimals; //300M of token supply allocated for the founder allocation

    bool public founderAllocated = false; //this will change to true when the founder fund is allocated

    uint public saleTokenSupply = 0; //this will keep track of the token supply created during the crowdsale
    uint public amountRaised = 0; //this will keep track of the Ether raised during the crowdsale

    uint public angelTokenSupply = 0; //this will keep track of the token angel supply

    bool public halted = false; //the admin address can set this to true to halt the crowdsale due to emergency

    event Buy(address indexed sender, uint eth, uint tokens);
    event AllocateFounderTokens(address indexed sender, uint tokens);
    event AllocateAngelTokens(address indexed sender, address to, uint tokens);
    event AllocateUnsoldTokens(address indexed sender, address holder, uint tokens);

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier duringCrowdSale {
        require(block.timestamp >= startDatetime && block.timestamp <= endDatetime);
        _;
    }

    /**
     *
     * Integer value representing the number of seconds since 1 January 1970 00:00:00 UTC
     */
    function MoldCoin(uint startDatetimeInSeconds, address founderWallet) {

        admin = msg.sender;
        founder = founderWallet;
        startDatetime = startDatetimeInSeconds;
        firstStageDatetime = startDatetime + 120 * 1 hours;
        secondStageDatetime = firstStageDatetime + 240 * 1 hours;
        endDatetime = secondStageDatetime + 2040 * 1 hours;

    }

    /**
     * Price for crowdsale by time
     */
    function price(uint timeInSeconds) constant returns(uint) {
        if (timeInSeconds < startDatetime) return 0;
        if (timeInSeconds <= firstStageDatetime) return 15000; //120 hours
        if (timeInSeconds <= secondStageDatetime) return 12000; //240 hours
        if (timeInSeconds <= endDatetime) return 10000; //2040 hours
        return 0;
    }

    /**
     * allow anyone sends funds to the contract
     */
    function buy() payable {
        buyRecipient(msg.sender);
    }

    function() payable {
        buyRecipient(msg.sender);
    }

    /**
     * Main token buy function.
     * Buy for the sender itself or buy on the behalf of somebody else (third party address).
     */
    function buyRecipient(address recipient) duringCrowdSale payable {
        require(!halted);

        uint tokens = safeMul(msg.value, price(block.timestamp));
        require(safeAdd(saleTokenSupply,tokens)<=coinAllocation );

        balances[recipient] = safeAdd(balances[recipient], tokens);

        totalSupply = safeAdd(totalSupply, tokens);
        saleTokenSupply = safeAdd(saleTokenSupply, tokens);
        amountRaised = safeAdd(amountRaised, msg.value);

        if (!founder.call.value(msg.value)()) revert(); //immediately send Ether to founder address

        Buy(recipient, msg.value, tokens);
    }

    /**
     * Set up founder address token balance.
     */
    function allocateFounderTokens() onlyAdmin {
        require( block.timestamp > endDatetime );
        require(!founderAllocated);

        balances[founder] = safeAdd(balances[founder], founderAllocation);
        totalSupply = safeAdd(totalSupply, founderAllocation);
        founderAllocated = true;

        AllocateFounderTokens(msg.sender, founderAllocation);
    }

    /**
     * Set up angel address token balance.
     */
    function allocateAngelTokens(address angel, uint tokens) onlyAdmin {

        require(safeAdd(angelTokenSupply,tokens) <= angelAllocation );

        balances[angel] = safeAdd(balances[angel], tokens);
        angelTokenSupply = safeAdd(angelTokenSupply, tokens);
        totalSupply = safeAdd(totalSupply, tokens);

        AllocateAngelTokens(msg.sender, angel, tokens);
    }

    /**
     * Emergency Stop crowdsale.
     */
    function halt() onlyAdmin {
        halted = true;
    }

    function unhalt() onlyAdmin {
        halted = false;
    }

    /**
     * Change admin address.
     */
    function changeAdmin(address newAdmin) onlyAdmin  {
        admin = newAdmin;
    }

    /**
     * arrange unsold coins
     */
    function arrangeUnsoldTokens(address holder, uint256 tokens) onlyAdmin {
        require( block.timestamp > endDatetime );
        require( safeAdd(saleTokenSupply,tokens) <= coinAllocation );
        require( balances[holder] >0 );

        balances[holder] = safeAdd(balances[holder], tokens);
        saleTokenSupply = safeAdd(saleTokenSupply, tokens);
        totalSupply = safeAdd(totalSupply, tokens);

        AllocateUnsoldTokens(msg.sender, holder, tokens);

    }

}