pragma solidity ^0.4.11;

/* taking ideas from FirstBlood token */
contract SafeMath {

    /* function assert(bool assertion) internal { */
    /*   if (!assertion) { */
    /*     throw; */
    /*   } */
    /* }      // assert no longer needed once solidity is on 0.4.10 */

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSub(uint256 x, uint256 y) internal returns(uint256) {
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

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract Token is owned {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is SafeMath, Token {
    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) returns (bool success) {
        assert((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* This creates an array with all balances */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract XPAToken is StandardToken {

    // metadata
    string public constant name = "XPlay Token";
    string public constant symbol = "XPA";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public ethFundDeposit;      // deposit address of ETH for XPlay Ltd.
    address public xpaFundDeposit;      // deposit address for XPlay Ltd. use and XPA User Fund

    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public crowdsaleSupply = 0;         // crowdsale supply
    uint256 public tokenExchangeRate = 23000;   // 23000 XPA tokens per 1 ETH
    uint256 public constant tokenCreationCap =  10 * (10**9) * 10**decimals;
    uint256 public tokenCrowdsaleCap =  4 * (10**8) * 10**decimals;

    // events
    event CreateXPA(address indexed _to, uint256 _value);

    // constructor
    function XPAToken(
        address _ethFundDeposit,
        address _xpaFundDeposit,
        uint256 _tokenExchangeRate,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
        isFinalized = false;                   //controls pre through crowdsale state
        ethFundDeposit = _ethFundDeposit;
        xpaFundDeposit = _xpaFundDeposit;
        tokenExchangeRate = _tokenExchangeRate;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        totalSupply = tokenCreationCap;
        balances[xpaFundDeposit] = tokenCreationCap;    // deposit all XPA to XPlay Ltd.
        CreateXPA(xpaFundDeposit, tokenCreationCap);    // logs deposit of XPlay Ltd. fund
    }

    function () payable {
        assert(!isFinalized);
        require(block.number >= fundingStartBlock);
        require(block.number < fundingEndBlock);
        require(msg.value > 0);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);    // check that we&#39;re not over totals
        crowdsaleSupply = safeAdd(crowdsaleSupply, tokens);

        // return money if something goes wrong
        require(tokenCrowdsaleCap >= crowdsaleSupply);

        balances[msg.sender] += tokens;     // add amount of XPA to sender
        balances[xpaFundDeposit] = safeSub(balances[xpaFundDeposit], tokens); // subtracts amount from XPlay&#39;s balance
        CreateXPA(msg.sender, tokens);      // logs token creation

    }
    /// @dev Accepts ether and creates new XPA tokens.
    function createTokens() payable external {
        assert(!isFinalized);
        require(block.number >= fundingStartBlock);
        require(block.number < fundingEndBlock);
        require(msg.value > 0);

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);    // check that we&#39;re not over totals
        crowdsaleSupply = safeAdd(crowdsaleSupply, tokens);

        // return money if something goes wrong
        require(tokenCrowdsaleCap >= crowdsaleSupply);

        balances[msg.sender] += tokens;     // add amount of XPA to sender
        balances[xpaFundDeposit] = safeSub(balances[xpaFundDeposit], tokens); // subtracts amount from XPlay&#39;s balance
        CreateXPA(msg.sender, tokens);      // logs token creation
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    /// @dev Update crowdsale parameter
    function updateParams(
        uint256 _tokenExchangeRate,
        uint256 _tokenCrowdsaleCap,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock) onlyOwner external 
    {
        assert(block.number < fundingStartBlock);
        assert(!isFinalized);
      
        // update system parameters
        tokenExchangeRate = _tokenExchangeRate;
        tokenCrowdsaleCap = _tokenCrowdsaleCap;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
    }
    /// @dev Ends the funding period and sends the ETH home
    function finalize() onlyOwner external {
        assert(!isFinalized);
      
        // move to operational
        isFinalized = true;
        assert(ethFundDeposit.send(this.balance));              // send the eth to XPlay ltd.
    }
}