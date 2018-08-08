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


/**
 * Automobile Cyberchain Token crowdsale ICO contract.
 *
 */
contract AutomobileCyberchainToken is StandardToken, SafeMath {

    string public name = "Automobile Cyberchain Token";
    string public symbol = "AMCC";
    uint public decimals = 18;
    uint preSalePrice  = 32000;
    uint crowSalePrice = 20000;
    uint prePeriod = 256 * 24 * 30;// unit: block count, estimate: 30 days, May 16 0:00, UTC-7
    uint totalPeriod = 256 * 24 * 95; // unit: block count, estimate: 95 days, July 20, 0:00, UTC-7
    uint public startBlock = 5455280; //crowdsale start block (set in constructor), April 16 0:00 UTC-7
    uint public endBlock = startBlock + totalPeriod; //crowdsale end block


    // Initial founder address (set in constructor)
    // All deposited ETH will be instantly forwarded to this address.
    // Address is a multisig wallet.
    address public founder = 0xfD16CDC79382F86303E2eE8693C7f50A4d8b937F;
    uint256 public preEtherCap = 15625 * 10**18; // max amount raised during pre-ICO
    uint256 public etherCap =    88125 * 10**18; //max amount raised during crowdsale
    uint256 public bountyAllocation = 1050000000 * 10**18;
    uint256 public maxToken = 3000000000 * 10**18;
    // uint public transferLockup = 256 * 0; //transfers are locked for this many blocks after endBlock (assuming 14 second blocks)
    // uint public founderLockup = 256 * 0; //founder allocation cannot be created until this many blocks after endBlock

    uint256 public presaleTokenSupply = 0; //this will keep track of the token supply created during the pre-crowdsale
    uint256 public totalEtherRaised = 0;
    bool public halted = false; //the founder address can set this to true to halt the crowdsale due to emergency

    event Buy(address indexed sender, uint eth, uint fbt);


    function AutomobileCyberchainToken() {
        balances[founder] = bountyAllocation;
        totalSupply = bountyAllocation;
        Transfer(address(0), founder, bountyAllocation);
    }


    function price() constant returns(uint) {
        if (block.number<startBlock || block.number > endBlock) return 0; //this will not happen according to the buyToken block check, but still set it to 0.
        else if (block.number>=startBlock && block.number<startBlock+prePeriod) return preSalePrice; //pre-ICO
        else  return crowSalePrice; // default-ICO
    }

   /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function() public payable  {
        buyToken(msg.sender, msg.value);
    }


    // Buy entry point
    function buy(address recipient, uint256 value) public payable {
        if (value> msg.value) throw;

        if (value < msg.value) {
            require(msg.sender.call.value(msg.value - value)()); //refund the extra ether
        }
        buyToken(recipient, value);
    }


    function buyToken(address recipient, uint256 value) internal {
        if (block.number<startBlock || block.number>endBlock || safeAdd(totalEtherRaised,value)>etherCap || halted) throw;
        if (block.number>=startBlock && block.number<=startBlock+prePeriod && safeAdd(totalEtherRaised,value) > preEtherCap) throw; //preSale Cap limitation
        uint tokens = safeMul(value, price());
        balances[recipient] = safeAdd(balances[recipient], tokens);
        totalSupply = safeAdd(totalSupply, tokens);
        totalEtherRaised = safeAdd(totalEtherRaised, value);

        if (block.number<=startBlock+prePeriod) {
            presaleTokenSupply = safeAdd(presaleTokenSupply, tokens);
        }
        Transfer(address(0), recipient, tokens); //Transaction record for token perchaise
        if (!founder.call.value(value)()) throw; //immediately send Ether to founder address
        Buy(recipient, value, tokens); //Buy event

    }


    /**
     * Emergency Stop ICO.
     *
     *  Applicable tests:
     *
     * - Test unhalting, buying, and succeeding
     */
    function halt() {
        if (msg.sender!=founder) throw;
        halted = true;
    }

    function unhalt() {
        if (msg.sender!=founder) throw;
        halted = false;
    }

    /**
     * Change founder address (where ICO ETH is being forwarded).
     *
     * Applicable tests:
     *
     * - Test founder change by hacker
     * - Test founder change
     * - Test founder token allocation twice
     *
     */
    function changeFounder(address newFounder) {
        if (msg.sender!=founder) throw;
        founder = newFounder;
    }

    function withdrawExtraToken(address recipient) public {
      require(msg.sender == founder && block.number > endBlock && totalSupply < maxToken);

      uint256 leftTokens = safeSub(maxToken, totalSupply);
      balances[recipient] = safeAdd(balances[recipient], leftTokens);
      totalSupply = maxToken;
      Transfer(address(0), recipient, leftTokens);
    }


    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     *
     * Applicable tests:
     *
     * - Test restricted early transfer
     * - Test transfer after restricted period
     */
    // function transfer(address _to, uint256 _value) returns (bool success) {
    //     if (block.number <= startBlock + transferLockup && msg.sender!=founder) throw;
    //     return super.transfer(_to, _value);
    // }


    /**
     * ERC 20 Standard Token interface transfer function
     *
     * Prevent transfers until freeze period is over.
     */
    // function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //     if (block.number <= startBlock + transferLockup && msg.sender!=founder) throw;
    //     return super.transferFrom(_from, _to, _value);
    // }
}