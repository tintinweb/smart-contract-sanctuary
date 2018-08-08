// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.10;

contract Token {
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

contract IMigrationContract {
    function migrate(address addr, uint256 uip) returns (bool success);
}

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}

/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
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

contract UnlimitedIPToken is StandardToken, SafeMath {

    // metadata
    string  public constant name = "UnlimitedIP Token";
    string  public constant symbol = "UIP";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

    // contracts
    address public ethFundDeposit;          // deposit address for ETH for UnlimitedIP Team.
    address public newContractAddr;         // the new contract for UnlimitedIP token updates;

    // crowdsale parameters
    bool    public isFunding;                // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;           // current supply tokens for sell
    uint256 public tokenRaised = 0;         // the number of total sold token
    uint256 public tokenMigrated = 0;     // the number of total transferted token
    uint256 public tokenExchangeRate = 1000;             // 1000 UIP tokens per 1 ETH

    // events
    event IssueToken(address indexed _to, uint256 _value);      // issue token for public sale;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);
    event Burn(address indexed from, uint256 _value);
    // format decimals.
    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    // constructor
    function UnlimitedIPToken()
    {
        ethFundDeposit = 0xBbf91Cf4cf582600BEcBb63d5BdB8D969F21779C;

        isFunding = false;                           //controls pre through crowdsale state
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(0);
        totalSupply = formatDecimals(3000000000);
        require(currentSupply <= totalSupply);
        balances[ethFundDeposit] = totalSupply-currentSupply;
    }

    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

    /// @dev set the token&#39;s tokenExchangeRate,
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        require(_tokenExchangeRate > 0);
        require(_tokenExchangeRate != tokenExchangeRate);
        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev increase the token&#39;s supply
    function increaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require (value + currentSupply <= totalSupply);
        require (balances[msg.sender] >= value && value>0);
        balances[msg.sender] -= value;
        currentSupply = safeAdd(currentSupply, value);
        IncreaseSupply(value);
    }

    /// @dev decrease the token&#39;s supply
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require (value + tokenRaised <= currentSupply);
        currentSupply = safeSubtract(currentSupply, value);
        balances[msg.sender] += value;
        DecreaseSupply(value);
    }

    /// @dev turn on the funding state
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        require(!isFunding);
        require(_fundingStartBlock < _fundingStopBlock);
        require(block.number < _fundingStartBlock) ;
        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    /// @dev turn off the funding state
    function stopFunding() isOwner external {
        require(isFunding);
        isFunding = false;
    }

    /// @dev set a new contract for recieve the tokens (for update contract)
    function setMigrateContract(address _newContractAddr) isOwner external {
        require(_newContractAddr != newContractAddr);
        newContractAddr = _newContractAddr;
    }

    /// @dev set a new owner.
    function changeOwner(address _newFundDeposit) isOwner() external {
        require(_newFundDeposit != address(0x0));
        ethFundDeposit = _newFundDeposit;
    }

    /// sends the tokens to new contract
    function migrate() external {
        require(!isFunding);
        require(newContractAddr != address(0x0));

        uint256 tokens = balances[msg.sender];
        require (tokens > 0);

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        require(newContract.migrate(msg.sender, tokens));

        Migrate(msg.sender, tokens);               // log it
    }

    /// @dev withdraw ETH from contract to UnlimitedIP team address
    function transferETH() isOwner external {
        require(this.balance > 0);
        require(ethFundDeposit.send(this.balance));
    }

    function burn(uint256 _value) isOwner returns (bool success){
        uint256 value = formatDecimals(_value);
        require(balances[msg.sender] >= value && value>0);
        balances[msg.sender] -= value;
        totalSupply -= value;
        Burn(msg.sender,value);
        return true;
    }

    /// buys the tokens
    function () payable {
        require (isFunding);
        require(msg.value > 0);

        require(block.number >= fundingStartBlock);
        require(block.number <= fundingStopBlock);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        require(tokens + tokenRaised <= currentSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        IssueToken(msg.sender, tokens);  // logs token issued
    }
}