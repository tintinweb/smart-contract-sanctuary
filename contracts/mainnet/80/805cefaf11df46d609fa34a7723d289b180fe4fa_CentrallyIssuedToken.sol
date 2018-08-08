/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */
pragma solidity ^0.4.11;

/**
 * Centrally issued Ethereum token.
 *
 * We mix in burnable and upgradeable traits.
 *
 * Token supply is created in the token contract creation and allocated to owner.
 * The owner can then transfer from its supply to crowdsale participants.
 * The owner, or anybody, can burn any excessive tokens they are holding.
 *
 */

/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool success);
  function approve(address spender, uint256 value) returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */

contract ErrorHandler {
    bool public isInTestMode = false;
    event evRecord(address msg_sender, uint msg_value, string message);

    function doThrow(string message) internal {
        evRecord(msg.sender, msg.value, message);
        if (!isInTestMode) {
        	throw;
		}
    }
}

/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}


/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */


/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract NTRYStandardToken is ERC20, ErrorHandler {
  address public owner;

  /* NTRY functional is paused if there is any emergency */
  bool public emergency = false;

  using SafeMath for uint;

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;
  
  /* freezeAccount() frozen() */
  mapping (address => bool) frozenAccount;

  /* Notify account frozen activity */
  event FrozenFunds(address target, bool frozen);

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    if (msg.sender != owner) {
      doThrow("Only Owner!");
    }
    _;
  }

  /**
   * Fix for the ERC20 short address attack
   *
   * http://vessenes.com/the-erc20-short-address-attack-explained/
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       doThrow("Short address attack!");
     }
     _;
  }

  modifier stopInEmergency {
    if (emergency){
        doThrow("Emergency state!");
    }
    _;
  }
  
  function transfer(address _to, uint _value) stopInEmergency onlyPayloadSize(2 * 32) returns (bool success) {
    // Check if frozen //
    if (frozenAccount[msg.sender]) doThrow("Account freezed!");  
                  
    balances[msg.sender] = balances[msg.sender].sub( _value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) stopInEmergency returns (bool success) {
    // Check if frozen //
    if (frozenAccount[_from]) doThrow("Account freezed!");

    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) stopInEmergency returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) doThrow("Allowance race condition!");

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }


  /**
  * It is called Circuit Breakers (Pause contract functionality), it stop execution if certain conditions are met, 
  * and can be useful when new errors are discovered. For example, most actions may be suspended in a contract if a 
  * bug is discovered, so the most feasible option to stop and updated migration message about launching an updated version of contract. 
  * @param _stop Switch the circuite breaker on or off
  */
  function emergencyStop(bool _stop) onlyOwner {
      emergency = _stop;
  }

  /**
  * Owner can set any account into freeze state. It is helpful in case if account holder has 
  * lost his key and he want administrator to freeze account until account key is recovered
  * @param target The account address
  * @param freeze The state of account
  */
  function freezeAccount(address target, bool freeze) onlyOwner {
      frozenAccount[target] = freeze;
      FrozenFunds(target, freeze);
  }

  function frozen(address _target) constant returns (bool frozen) {
    return frozenAccount[_target];
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      balances[newOwner] = balances[owner];
      balances[owner] = 0;
      owner = newOwner;
      Transfer(owner, newOwner,balances[newOwner]);
    }
  }

}


/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */

/**
 * Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 */
contract UpgradeAgent {

  uint public originalSupply;

  /** Interface marker */
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is NTRYStandardToken {

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint256 public totalUpgraded;

  /**
   * Upgrade states.
   *
   * - NotAllowed: The child contract has not reached a condition where the upgrade can bgun
   * - WaitingForAgent: Token allows upgrade, but we don&#39;t have a new agent yet
   * - ReadyToUpgrade: The agent is set, but not a single token has been upgraded yet
   * - Upgrading: Upgrade agent is set and the balance holders can upgrade their tokens
   *
   */
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

  /**
   * Somebody has upgraded some of his tokens.
   */
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

  /**
   * New upgrade agent available.
   */
  event UpgradeAgentSet(address agent);

  /**
   * Do not allow construction without upgrade master set.
   */
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

  /**
   * Allow the token holder to upgrade some of their tokens to a new contract.
   */
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
        doThrow("Called in a bad state!");
      }

      // Validate input value.
      if (value == 0) doThrow("Value to upgrade is zero!");

      balances[msg.sender] = balances[msg.sender].sub(value);

      // Take tokens out from circulation
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

      // Upgrade agent reissues the tokens
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {
        // The token is not yet in a state that we could think upgrading
        doThrow("Token state is not feasible for upgrading yet!");
      }

      if (agent == 0x0) doThrow("Invalid address!");
      // Only a master can designate the next agent
      if (msg.sender != upgradeMaster) doThrow("Only upgrade master!");
      // Upgrade has already begun for an agent
      if (getUpgradeState() == UpgradeState.Upgrading) doThrow("Upgrade started already!");

      upgradeAgent = UpgradeAgent(agent);

      // Bad interface
      if(!upgradeAgent.isUpgradeAgent()) doThrow("Bad interface!");
      // Make sure that token supplies match in source and target
      if (upgradeAgent.originalSupply() != totalSupply) doThrow("Total supply source is not equall to target!");

      UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

  /**
   * Change the upgrade master.
   *
   * This allows us to set a new owner for the upgrade mechanism.
   */
  function setUpgradeMaster(address master) public {
      if (master == 0x0) doThrow("Invalid address of upgrade master!");
      if (msg.sender != upgradeMaster) doThrow("Only upgrade master!");
      upgradeMaster = master;
  }

  /**
   * Child contract can enable to provide the condition when the upgrade can begun.
   */
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

/**
 *  NTRY Cointract contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts
 *  https://github.com/TokenMarketNet/ico/blob/master/contracts
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts
 */


contract BurnableToken is NTRYStandardToken {

  address public constant BURN_ADDRESS = 0;

  /** How many tokens we burned */
  event Burned(address burner, uint burnedAmount);

  /**
   * Burn extra tokens from a balance.
   *
   */
  function burn(uint burnAmount) {
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(burnAmount);
    totalSupply = totalSupply.sub(burnAmount);
    Burned(burner, burnAmount);
  }
}


contract CentrallyIssuedToken is BurnableToken, UpgradeableToken {

  string public name;
  string public symbol;
  uint public decimals;

  function CentrallyIssuedToken() UpgradeableToken(owner) {
    name = "Notary Platform Token";
    symbol = "NTRY";
    decimals = 18;
    owner = 0x1538EF80213cde339A333Ee420a85c21905b1b2D;

    totalSupply = 150000000 * 1 ether;
    
    // Allocate initial balance to the owner //
    balances[owner] = 150000000 * 1 ether;

    // Freeze notary team funds for one year (One month with pre ico already passed)//
    unlockedAt =  now + 330 * 1 days;
  }

  uint256 public constant teamAllocations = 15000000 * 1 ether;
  uint256 public unlockedAt;
  mapping (address => uint256) allocations;
  function allocate() public {
      allocations[0xab1cb1740344A9280dC502F3B8545248Dc3045eA] = 2500000 * 1 ether;
      allocations[0x330709A59Ab2D1E1105683F92c1EE8143955a357] = 2500000 * 1 ether;
      allocations[0xAa0887fc6e8896C4A80Ca3368CFd56D203dB39db] = 2500000 * 1 ether;
      allocations[0x1fbA1d22435DD3E7Fa5ba4b449CC550a933E72b3] = 2500000 * 1 ether;
      allocations[0xC9d5E2c7e40373ae576a38cD7e62E223C95aBFD4] = 500000 * 1 ether;
      allocations[0xabc0B64a38DE4b767313268F0db54F4cf8816D9C] = 500000 * 1 ether;
      allocations[0x5d85bCDe5060C5Bd00DBeDF5E07F43CE3Ccade6f] = 250000 * 1 ether;
      allocations[0xecb1b0231CBC0B04015F9e5132C62465C128B578] = 250000 * 1 ether;
      allocations[0xF9b1Cfc7fe3B63bEDc594AD20132CB06c18FD5F2] = 250000 * 1 ether;
      allocations[0xDbb89a87d9f91EA3f0Ab035a67E3A951A05d0130] = 250000 * 1 ether;
      allocations[0xC1530645E21D27AB4b567Bac348721eE3E244Cbd] = 200000 * 1 ether;
      allocations[0xcfb44162030e6CBca88e65DffA21911e97ce8533] = 200000 * 1 ether;
      allocations[0x64f748a5C5e504DbDf61d49282d6202Bc1311c3E] = 200000 * 1 ether;
      allocations[0xFF22FA2B3e5E21817b02a45Ba693B7aC01485a9C] = 200000 * 1 ether;
      allocations[0xC9856112DCb8eE449B83604438611EdCf61408AF] = 200000 * 1 ether;
      allocations[0x689CCfEABD99081D061aE070b1DA5E1f6e4B9fB2] = 2000000 * 1 ether;
  }

  function withDraw() public {
      if(now < unlockedAt){ 
          doThrow("Allocations are freezed!");
      }
      if (allocations[msg.sender] == 0){
          doThrow("No allocation found!");
      }
      balances[owner] -= allocations[msg.sender];
      balances[msg.sender] += allocations[msg.sender];
      Transfer(owner, msg.sender, allocations[msg.sender]);
      allocations[msg.sender] = 0;
      
  }
  
   function () {
        //if ether is sent to this address, send it back.
        throw;
    }
  
}