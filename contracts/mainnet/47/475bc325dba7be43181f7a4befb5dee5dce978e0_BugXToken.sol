pragma solidity 0.4.24;

contract IMigrationContract {
    function migrate(address addr, uint256 nas) public returns (bool success);
}

/* taking ideas from FirstBlood token */
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal pure returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining); 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { 
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract BugXToken is StandardToken, SafeMath {

    // metadata
    string  public constant name = "BUGX Token";
    string  public constant symbol = "BUGX";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

    // contracts
    address public ethFundDeposit;          // deposit address for ETH for BUGX Team.
    address public newContractAddr;         // the new contract for BUGX token updates;

    // crowdsale parameters
    bool    public isFunding;                // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public currentSupply;           // current supply tokens for sell
    uint256 public tokenRaised = 0;         // the number of total sold token
    uint256 public tokenIssued = 0;         // the number of total issued token
    uint256 public tokenMigrated = 0;     // the number of total transferted token
    uint256 public tokenExchangeRate = 6000;             // 6000 BXT tokens per 1 ETH

    // events
    event AllocateToken(address indexed _to, uint256 _value);   // issue token to buyer;
    event IssueToken(address indexed _to, uint256 _value);      // record token issue info;
    event IncreaseSupply(uint256 _value);
    event DecreaseSupply(uint256 _value);
    event Migrate(address indexed _to, uint256 _value);

    // format decimals.
    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    // constructor
    constructor(
        address _ethFundDeposit,
        uint256 _currentSupply) public
    {
        ethFundDeposit = _ethFundDeposit;

        isFunding = false;                           //controls pre through crowdsale state
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        currentSupply = formatDecimals(_currentSupply);
        totalSupply = formatDecimals(1500000000);    //1,500,000,000 total supply
        require(currentSupply <= totalSupply);
    }

    modifier isOwner()  {require(msg.sender == ethFundDeposit); _;}

    /// @dev set the token&#39;s tokenExchangeRate,
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        require (_tokenExchangeRate != 0);
        require (_tokenExchangeRate != tokenExchangeRate);

        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev increase the token&#39;s supply
    function increaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require (value + currentSupply <= totalSupply);
        currentSupply = safeAdd(currentSupply, value);
        emit IncreaseSupply(value);
    }

    /// @dev decrease the token&#39;s supply
    function decreaseSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require (value + tokenRaised <= currentSupply);

        currentSupply = safeSubtract(currentSupply, value);
        emit DecreaseSupply(value);
    }

    /// @dev turn on the funding state
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        require (!isFunding);
        require (_fundingStartBlock < _fundingStopBlock);
        require (block.number < _fundingStartBlock);

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    /// @dev turn off the funding state
    function stopFunding() isOwner external {
        require (isFunding);
        isFunding = false;
    }

    /// @dev set a new contract for recieve the tokens (for update contract)
    function setMigrateContract(address _newContractAddr) isOwner external {
        require (_newContractAddr != newContractAddr);
        newContractAddr = _newContractAddr;
    }

    /// @dev set a new owner.
    function changeOwner(address _newFundDeposit) isOwner() external {
        require (_newFundDeposit != address(0x0));
        ethFundDeposit = _newFundDeposit;
    }

    /// sends the tokens to new contract
    function migrate() external {
        require(!isFunding);
        require(newContractAddr != address(0x0));

        uint256 tokens = balances[msg.sender];
        require (tokens != 0);

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        require (newContract.migrate(msg.sender, tokens));

        emit Migrate(msg.sender, tokens);               // log it
    }

    /// @dev sends ETH to BUGX team
    function transferETH() isOwner external {
        require (address(this).balance != 0);
        require (ethFundDeposit.send(address(this).balance));
    }

    /// @dev allocates BXT tokens to buyers. 25% per 3 months.
    function allocateToken (address _addr, uint256 _eth) isOwner external {
        require (_eth != 0);
        require (_addr != address(0x0));

        uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);

        tokenIssued = safeAdd(tokenIssued, tokens);
        balances[_addr] += tokens;

        emit AllocateToken(_addr, tokens);  // logs token issued
    }

    function () public payable {
        require (isFunding);
        require (msg.value != 0);

        require (block.number >= fundingStartBlock);
        require (block.number <= fundingStopBlock);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);
        require (tokens + tokenRaised <= currentSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[msg.sender] += tokens;

        emit IssueToken(msg.sender, msg.value);  // logs token issued
    }
}