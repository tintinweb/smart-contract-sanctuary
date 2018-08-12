pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// &#39;Stake POS&#39; CROWDSALE token contract
//
// Deployed to : 0x59714ef9e589810e74e0351814c79817cd5efd52
// Symbol      : STAKE19
// Name        : STAKE19 Token
// Initial Funding supply: 30,000,000
// Decimals    : 18


contract IMigrationContract {
    function migrate(address addr, uint256 nas) public returns (bool success);
}

/* taking ideas from FirstBlood token */
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSubtract(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMult(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token, SafeMath {


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSubtract(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSubtract(balances[from], tokens);
        allowed[from][msg.sender] = safeSubtract(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract stake19Token is StandardToken {

    // metadata
    string  public constant name = "STAKE19 Token";
    string  public constant symbol = "STAKE19";
    uint256 public constant decimals = 18;
    string  public version = "1.0";

    // contracts
    address public ethFundDeposit;          // deposit address for ETH for STAKE Team.
    address public newContractAddr;         // the new contract for stake token updates;

    // crowdsale parameters
    bool    public isFunding;                   // switched to true in operational state
    bool    public allowRefunds;                // only true if ICO goals is not meet 
    uint256 public fundingStartBlock;
    uint256 public fundingStopBlock;

    uint256 public tokenRaised = 0;         // the number of total sold token
  
    uint256 public ETHRefunded = 0;         // the number of ETH refunded 
    uint256 public tokenRefunded = 0;     // the number of total tokens refunded    
    uint256 public tokenMigrated = 0;     // the number of total transferted token
    uint256 public tokenExchangeRate = 400;             // 400 Stake tokens per 1 ETH

    // events
    event AllocateToken(address indexed _to, uint256 _value);   // allocate token for private sale;
    event IssueToken(address indexed _to, uint256 _value);      // issue token for public sale;
    event IncreaseTotalSupply(uint256 _value);
    event DecreaseTotalSupply(uint256 _value);
    event LogRefund(address indexed _to, uint256 _ETHvalue);
    event LogTokenRefundBurn(address indexed _to, uint256 _value);
    event Migrate(address indexed _to, uint256 _value);

    mapping (address => uint256) ETHbalances;


    // format decimals.
    function formatDecimals(uint256 _value) internal pure returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    // constructor
    constructor () public
    {
        ethFundDeposit = msg.sender;
        allowRefunds = false;
        isFunding = false;                           //controls pre through crowdsale state
        fundingStartBlock = 0;
        fundingStopBlock = 0;

        totalSupply = formatDecimals(30000000);
    }

    modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

    /// @dev set the token&#39;s tokenExchangeRate,
    function setTokenExchangeRate(uint256 _tokenExchangeRate) isOwner external {
        require (_tokenExchangeRate != 0);
        require (_tokenExchangeRate != tokenExchangeRate);

        tokenExchangeRate = _tokenExchangeRate;
    }

    /// @dev increase the token&#39;s current supply
    function increaseTotalSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        totalSupply = safeAdd(totalSupply, value);
        emit IncreaseTotalSupply(value);
    }

    /// @dev decrease the token&#39;s current supply
    function decreaseTotalSupply (uint256 _value) isOwner external {
        uint256 value = formatDecimals(_value);
        require(value + tokenRaised <= totalSupply);
        totalSupply = safeSubtract(totalSupply, value);
        emit DecreaseTotalSupply(value);
    }


    /// @dev turn on the funding state
    function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
        require (!isFunding);
        require (_fundingStartBlock <= _fundingStopBlock);
        require (block.number <= _fundingStartBlock);

        fundingStartBlock = _fundingStartBlock;
        fundingStopBlock = _fundingStopBlock;
        isFunding = true;
    }

    /// @dev turn off the funding state
    function stopFunding() isOwner external {
        require(isFunding);
        isFunding = false;
    }

    /// @dev enable/disable refunds
    function allowRefunds(bool _state) isOwner external {
        allowRefunds = _state;
    }

    //ETH Balance of what was submitted
    function ETHbalanceOf(address _owner) constant public returns (uint256 ETHbalance) {
        return ETHbalances[_owner];
    }

    /// @dev set a new contract for recieve the tokens (for update contract)
    function setMigrateContract(address _newContractAddr) isOwner external {
        require(_newContractAddr != newContractAddr);
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
    //    require (tokens != 0);
          require (tokens > 0);

        balances[msg.sender] = 0;
        tokenMigrated = safeAdd(tokenMigrated, tokens);

        IMigrationContract newContract = IMigrationContract(newContractAddr);
        require (newContract.migrate(msg.sender, tokens));

        emit Migrate(msg.sender, tokens);               // log it
    }

    /// @dev sends ETH to STAKE team
    function transferETH() isOwner external {
    //    require (this.balance != 0);
        require (address(this).balance != 0);
    
    //    require (ethFundDeposit.send(this.balance));
    //    require (ethFundDeposit.send(address(this).balance));

          ethFundDeposit.transfer(address(this).balance);
     
    }

    /// @dev allocates tokens to pre-sell address, no decimal formatting.
    function allocateTokenETHConvert (address _addr, uint256 _eth) isOwner external {
    //    require (_eth != 0);
        require (_eth > 0);
        require (_addr != address(0x0));

    //    uint256 tokens = safeMult(formatDecimals(_eth), tokenExchangeRate);
        uint256 tokens = safeMult(_eth, tokenExchangeRate);
        require (tokens + tokenRaised <= totalSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit Transfer(address(0), _addr, tokens);
        emit AllocateToken(_addr, tokens);  // logs token issued
    }

    /// @dev allocates tokens to pre-sell address, no ETH conversion
    function allocateNominalToken (address _addr, uint256 tokens) isOwner external {
        require (tokens > 0);
        require (_addr != address(0x0));

        require (tokens + tokenRaised <= totalSupply);

        tokenRaised = safeAdd(tokenRaised, tokens);
        balances[_addr] += tokens;

        emit Transfer(address(0), _addr, tokens);
        emit AllocateToken(_addr, tokens);  // logs token issued
    }


    /// buys the tokens
    function () payable public{
        require (isFunding);
        require (msg.value != 0);

        require (block.number >= fundingStartBlock);
        require (block.number <= fundingStopBlock);
         
         // ICO participants will recieve token issuance for payment, not owner
         if ( msg.sender != ethFundDeposit ) {

            uint256 tokens = safeMult(msg.value, tokenExchangeRate);
            require (tokens + tokenRaised <= totalSupply);

            tokenRaised = safeAdd(tokenRaised, tokens);

            balances[msg.sender] += tokens;

            //Add for refunds
            ETHbalances[msg.sender] += msg.value;

            emit Transfer(address(0), msg.sender, tokens);
            emit IssueToken(msg.sender, tokens);  // logs token issued
        }
    }

    function refund() public returns(bool success) {
        require(allowRefunds);
        uint256 amtRequested = ETHbalances[msg.sender];
        require(amtRequested > 0);
        require(address(this).balance >= amtRequested);


        uint256 tokens = balances[msg.sender];
        require (tokens > 0);

        // Send Refund
        msg.sender.transfer(amtRequested);

        ETHRefunded = safeAdd(ETHRefunded, amtRequested);

        // Zero out original ETH sent
        ETHbalances[msg.sender] = 0;

        emit LogRefund(msg.sender, amtRequested );               // log it
        
        tokenRefunded = safeAdd(tokenRefunded, tokens);
        
        //burn tokens
        totalSupply = safeSubtract(totalSupply, tokens);

        balances[msg.sender] = 0;

        emit LogTokenRefundBurn(msg.sender, tokens);               // log it

        emit DecreaseTotalSupply(tokens);               // log it

        return true;
    }



}