pragma solidity ^0.4.11;




// ----------------------------------------------------------------------------------------------
// @title MatchPay Token (MPY)
// (c) Federico Capello.
// ----------------------------------------------------------------------------------------------

contract MPY {

    string public constant name = "MatchPay Token";
    string public constant symbol = "MPY";
    uint256 public constant decimals = 18;

    address owner;

    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public constant tokenExchangeRate = 10; // 1 MPY per 0.1 ETH
    uint256 public maxCap = 30 * (10**3) * (10**decimals); // Maximum part for offering
    uint256 public totalSupply; // Total part for offering
    uint256 public minCap = 10 * (10**2) * (10**decimals); // Minimum part for offering
    uint256 public ownerTokens = 3 * (10**2) * (10**decimals);

    bool public isFinalized = false;


    // Triggered when tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    // Triggered when _owner gets tokens
    event MPYCreation(address indexed _owner, uint256 _value);


    // Triggered when _owner gets refund
    event MPYRefund(address indexed _owner, uint256 _value);


    // -------------------------------------------------------------------------------------------


    // Check if ICO is open
    modifier is_live() { require(block.number >= fundingStartBlock && block.number <= fundingEndBlock); _; }


    // Only owmer
    modifier only_owner(address _who) { require(_who == owner); _; }


    // -------------------------------------------------------------------------------------------


    // safely add
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    // safely subtract
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    // safely multiply
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }


    // -------------------------------------------------------------------------------------------


    // Constructor
    function MPY(
      uint256 _fundingStartBlock,
      uint256 _fundingEndBlock
    ) {

        owner = msg.sender;

        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;

    }


    /// @notice Return the address balance
    /// @param _owner The owner
    function balanceOf(address _owner) constant returns (uint256) {
      return balances[_owner];
    }


    /// @notice Transfer tokens to account
    /// @param _to Beneficiary
    /// @param _amount Number of tokens
    function transfer(address _to, uint256 _amount) returns (bool success) {
      if (balances[msg.sender] >= _amount
          && _amount > 0
          && balances[_to] + _amount > balances[_to]) {

              balances[msg.sender] -= _amount;
              balances[_to] += _amount;

              Transfer(msg.sender, _to, _amount);

              return true;
      } else {
          return false;
      }
    }


    /// @notice Transfer tokens on behalf of _from
    /// @param _from From address
    /// @param _to To address
    /// @param _amount Amount of tokens
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
      if (balances[_from] >= _amount
          && allowed[_from][msg.sender] >= _amount
          && _amount > 0
          && balances[_to] + _amount > balances[_to]) {

              balances[_from] -= _amount;
              allowed[_from][msg.sender] -= _amount;
              balances[_to] += _amount;

              Transfer(_from, _to, _amount);

              return true;
          } else {
              return false;
          }
    }


    /// @notice Approve transfer of tokens on behalf of _from
    /// @param _spender Whom to approve
    /// @param _amount For how many tokens
    function approve(address _spender, uint256 _amount) returns (bool success) {
      allowed[msg.sender][_spender] = _amount;
      Approval(msg.sender, _spender, _amount);
      return true;
    }


    /// @notice Find allowance
    /// @param _owner The owner
    /// @param _spender The approved spender
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }


    // -------------------------------------------------------------------------------------------


    function getStats() constant returns (uint256, uint256, uint256, uint256) {
        return (minCap, maxCap, totalSupply, fundingEndBlock);
    }

    function getSupply() constant returns (uint256) {
        return totalSupply;
    }


    // -------------------------------------------------------------------------------------------


    /// @notice Get Tokens: 0.1 ETH per 1 MPY token
    function() is_live() payable {
        if (msg.value == 0) revert();
        if (isFinalized) revert();

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);   // calculate num of tokens purchased
        uint256 checkedSupply = safeAdd(totalSupply, tokens);      // calculate total supply if purchased

        if (maxCap < checkedSupply) revert();                         // if exceeding token max, cancel order

        totalSupply = checkedSupply;                               // update totalSupply
        balances[msg.sender] += tokens;                            // update token balance for payer
        MPYCreation(msg.sender, tokens);                           // logs token creation event
    }


    // generic function to pay this contract
    function emergencyPay() external payable {}


    // wrap up crowdsale after end block
    function finalize() external {
        if (msg.sender != owner) revert();                                         // check caller is ETH deposit address
        if (totalSupply < minCap) revert();                                        // check minimum is met
        if (block.number <= fundingEndBlock && totalSupply < maxCap) revert();     // check past end block unless at creation cap

        if (!owner.send(this.balance)) revert();                                   // send account balance to ETH deposit address

        balances[owner] += ownerTokens;
        totalSupply += ownerTokens;

        isFinalized = true;                                                     // update crowdsale state to true
    }


    // legacy code to enable refunds if min token supply not met (not possible with fixed supply)
    function refund() external {
        if (isFinalized) revert();                               // check crowdsale state is false
        if (block.number <= fundingEndBlock) revert();           // check crowdsale still running
        if (totalSupply >= minCap) revert();                     // check creation min was not met
        if (msg.sender == owner) revert();                       // do not allow dev refund

        uint256 mpyVal = balances[msg.sender];                // get callers token balance
        if (mpyVal == 0) revert();                               // check caller has tokens

        balances[msg.sender] = 0;                             // set callers tokens to zero
        totalSupply = safeSubtract(totalSupply, mpyVal);      // subtract callers balance from total supply
        uint256 ethVal = mpyVal / tokenExchangeRate;          // calculate ETH from token exchange rate
        MPYRefund(msg.sender, ethVal);                        // log refund event

        if (!msg.sender.send(ethVal)) revert();                  // send caller their refund
    }
}