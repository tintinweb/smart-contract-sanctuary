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
  address contractOwner;
  string public constant name = "Agora";
  string public constant symbol = "AGO";
  uint8 public constant decimals = 0;

  struct BalanceSnapshot {
    bool initialized;
    uint256 value;
  }

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(uint256 => mapping (address => BalanceSnapshot)) balancesAtBlock;

  uint256 public constant creatorSupply = 30000000;
  uint256 public constant seriesASupply = 10000000;
  uint256 public constant seriesBSupply = 30000000;
  uint256 public constant seriesCSupply = 60000000;

  uint256 public currentlyReleased = 0;
  uint256 public valueRaised = 0;

  // When building the contract, we release 30,000,000 tokens
  // to the creator address.
  function AgoraToken() {
    contractOwner = msg.sender;
    balances[contractOwner] = creatorSupply;
    currentlyReleased += creatorSupply;
  }

  // ERC20 Logic Implementation

  // Returns the balance of an address.
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  // Make a transfer of AGO between two addresses.
  function transfer(address _to, uint256 _value) returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
      // We need to register the balance known for the last reference block.
      // That way, we can be sure that when the Claimer wants to check the balance
      // the system can be protected against double-spending AGO tokens claiming.
      registerBalanceForReference(msg.sender);
      registerBalanceForReference(_to);

      // Standard transfer stuff
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    if(balances[_from] >= _value && _value > 0 && allowed[_from][msg.sender] >= _value) {
      // Same as `transfer` :
      // We need to register the balance known for the last reference block.
      // That way, we can be sure that when the Claimer wants to check the balance
      // the system can be protected against double-spending AGO tokens claiming.
      registerBalanceForReference(_from);
      registerBalanceForReference(_to);

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
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  // Checks the allowance of an account against another one. (Works with approval).
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Returns the total supply of token issued.
  function totalSupply() constant returns (uint256 totalSupply) {
    return creatorSupply + seriesASupply + seriesBSupply + seriesCSupply;
  }

  // ICO Logic Implementation

  // Get tokens with a Ether payment.
  function() payable {
    // Require to be after block 4116800 to start the ICO.
    require(block.number > 4116800);

    // Require a value to be sent.
    require(msg.value >= 0);

    // Retrieve the current round information
    var(pricePerThousands, supplyRemaining) = currentRoundInformation();

    // Require a round to be started (currentRoundInformation return 0,0 if no
    // round is in progress).
    require(pricePerThousands > 0);

    // Make the calculation : how many AGO token for this Ether value.
    uint256 tokenToReceive = (msg.value * 1000 / pricePerThousands);

    // Require there is enough token remaining in the supply.
    require(tokenToReceive <= supplyRemaining);

    // Credits the user balance with this tokens.
    balances[msg.sender] += tokenToReceive;
    currentlyReleased += tokenToReceive;
    valueRaised += msg.value;
  }

  // Returns the current ICO round information.
  // pricePerThousands is the current X ether = 1000 AGO
  // supplyRemaining is the remaining supply of ether at this price
  function currentRoundInformation() constant returns (uint256 pricePerThousands, uint256 supplyRemaining) {
    if(currentlyReleased >= 30000000 && currentlyReleased < 40000000) {
      return(0.75 ether, 40000000-currentlyReleased);
    } else if(currentlyReleased >= 40000000 && currentlyReleased < 70000000) {
      return(1.25 ether, 70000000-currentlyReleased);
    } else if(currentlyReleased >= 70000000 && currentlyReleased < 130000000) {
      return(1.5 ether, 130000000-currentlyReleased);
    } else {
      return(0,0);
    }
  }

  // Method use by the creators. Used to retrieve the Ethers raised from the ICO.
  // That way, Agora is becoming possible :).
  function withdrawICO(uint256 amount) {
    require(msg.sender == contractOwner);
    contractOwner.transfer(amount);
  }

  // Claiming Logic Implementation
  // This part is used by the claimer.
  // The claimer can ask the balance of an user at a reference block.
  // That way, the claimer is protected against double-spending AGO claimings.

  // This method is triggered by `transfer` and `transferFrom`.
  // It saves the balance known at a reference block only if there is no balance
  // saved for this block yet.
  // Meaning that this is a the first transaction since the last reference block,
  // so this balance can be uses as the reference.
  function registerBalanceForReference(address _owner) private {
    uint256 referenceBlockNumber = latestReferenceBlockNumber();
    if (balancesAtBlock[referenceBlockNumber][_owner].initialized) { return; }
    balancesAtBlock[referenceBlockNumber][_owner].initialized = true;
    balancesAtBlock[referenceBlockNumber][_owner].value = balances[_owner];
  }

  // What is the latest reference block number ?
  function latestReferenceBlockNumber() constant returns (uint256 blockNumber) {
    return (block.number - block.number % 157553);
  }

  // What is the valance of an user at a block ?
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