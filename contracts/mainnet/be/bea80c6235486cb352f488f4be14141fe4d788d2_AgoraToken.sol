pragma solidity ^0.4.8;

contract ERC20Interface {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AgoraToken is ERC20Interface {

  string public constant name = "Agora";
  string public constant symbol = "AGO";
  uint8  public constant decimals = 18;

  uint256 constant minimumToRaise = 1000 ether;
  uint256 constant icoStartBlock = 4116800;
  uint256 constant icoPremiumEndBlock = icoStartBlock + 78776; // Two weeks
  uint256 constant icoEndBlock = icoStartBlock + 315106; // Two months

  address owner;
  uint256 raised = 0;
  uint256 created = 0;

  struct BalanceSnapshot {
    bool initialized;
    uint256 value;
  }

  mapping(address => uint256) shares;
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(uint256 => mapping (address => BalanceSnapshot)) balancesAtBlock;

  function AgoraToken() {
    owner = msg.sender;
  }

  // ==========================
  // ERC20 Logic Implementation
  // ==========================

  // Returns the balance of an address.
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  // Make a transfer of AGO between two addresses.
  function transfer(address _to, uint256 _value) returns (bool success) {
    // Freeze for dev team
    require(msg.sender != owner);

    if (balances[msg.sender] >= _value &&
        _value > 0 &&
        balances[_to] + _value > balances[_to]) {
      // We need to register the balance known for the last reference block.
      // That way, we can be sure that when the Claimer wants to check the balance
      // the system can be protected against double-spending AGO tokens claiming.
      uint256 referenceBlockNumber = latestReferenceBlockNumber();
      registerBalanceForReference(msg.sender, referenceBlockNumber);
      registerBalanceForReference(_to, referenceBlockNumber);

      // Standard transfer stuff
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if(balances[_from] >= _value &&
       _value > 0 &&
       allowed[_from][msg.sender] >= _value &&
       balances[_to] + _value > balances[_to]) {
      // Same as `transfer` :
      // We need to register the balance known for the last reference block.
      // That way, we can be sure that when the Claimer wants to check the balance
      // the system can be protected against double-spending AGO tokens claiming.
      uint256 referenceBlockNumber = latestReferenceBlockNumber();
      registerBalanceForReference(_from, referenceBlockNumber);
      registerBalanceForReference(_to, referenceBlockNumber);

      // Standard transferFrom stuff
      balances[_from] -= _value;
      balances[_to] += _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  // Approve a payment from msg.sender account to another one.
  function approve(address _spender, uint256 _value) returns (bool success) {
    // Freeze for dev team
    require(msg.sender != owner);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  // Checks the allowance of an account against another one. (Works with approval).
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Returns the total supply of token issued.
  function totalSupply() constant returns (uint256 totalSupply) { return created; }

  // ========================
  // ICO Logic Implementation
  // ========================

  // ICO Status overview. Used for Agora landing page
  function icoOverview() constant returns(
    uint256 currentlyRaised,
    uint256 tokensCreated,
    uint256 developersTokens
  ){
    currentlyRaised = raised;
    tokensCreated = created;
    developersTokens = balances[owner];
  }

  // Get Agora tokens with a Ether payment.
  function() payable {
    require(block.number > icoStartBlock && block.number < icoEndBlock);

    uint256 tokenAmount = msg.value * ((block.number < icoPremiumEndBlock) ? 550 : 500);

    shares[msg.sender] += msg.value;
    balances[msg.sender] += tokenAmount;
    balances[owner] += tokenAmount / 6;

    raised += msg.value;
    created += tokenAmount;
  }

  // Method use by the creators. Requires the ICO to be a success.
  // Used to retrieve the Ethers raised from the ICO.
  // That way, Agora is becoming possible :).
  function withdraw(uint256 amount) {
    require(block.number > icoEndBlock && raised >= minimumToRaise && msg.sender == owner);
    owner.transfer(amount);
  }

  // Methods use by the ICO investors. Requires the ICO to be a fail.
  function refill() {
    require(block.number > icoEndBlock && raised < minimumToRaise);
    uint256 share = shares[msg.sender];
    shares[msg.sender] = 0;
    msg.sender.transfer(share);
  }

  // ============================
  // Claimer Logic Implementation
  // ============================
  // This part is used by the claimer.
  // The claimer can ask the balance of an user at a reference block.
  // That way, the claimer is protected against double-spending AGO claimings.

  // This method is triggered by `transfer` and `transferFrom`.
  // It saves the balance known at a reference block only if there is no balance
  // saved for this block yet.
  // Meaning that this is a the first transaction since the last reference block,
  // so this balance can be uses as the reference.
  function registerBalanceForReference(address _owner, uint256 referenceBlockNumber) private {
    if (balancesAtBlock[referenceBlockNumber][_owner].initialized) { return; }
    balancesAtBlock[referenceBlockNumber][_owner].initialized = true;
    balancesAtBlock[referenceBlockNumber][_owner].value = balances[_owner];
  }

  // What is the latest reference block number ?
  function latestReferenceBlockNumber() constant returns (uint256 blockNumber) {
    return (block.number - block.number % 157553);
  }

  // What is the balance of an user at a block ?
  // If the user have made (or received) a transfer of AGO token since the
  // last reference block, its balance will be written in the `balancesAtBlock`
  // mapping. So we can retrieve it from here.
  // Otherwise, if the user havn&#39;t made a transaction since the last reference
  // block, the balance of AGO token is still good.
  function balanceAtBlock(address _owner, uint256 blockNumber) constant returns (uint256 balance) {
    if(balancesAtBlock[blockNumber][_owner].initialized) {
      return balancesAtBlock[blockNumber][_owner].value;
    }
    return balances[_owner];
  }
}