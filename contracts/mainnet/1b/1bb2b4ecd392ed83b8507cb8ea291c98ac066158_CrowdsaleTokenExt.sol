// ---Trixchain Powered by POA Network---
pragma solidity ^0.4.11;
/*
Name         : Trixchain
Symbol       : TRIX
Total Supply : 1.000.000.000.000 TRIX
Decimals     : 18 
Contract     : 0x1bb2b4ecd392ed83b8507cb8ea291c98ac066158

Chat Group   : https://t.me/joinchat/Jc2Vrkb0C11mxRmFnVploQ
Channel      : https://t.me/trixchainchannel

TOKENSALE DETAILS

Total Supply ---------: 1.000.000.000.000 TRIX
Tokensale             : 250.000.000.000 TRIX
Future Project -------: 250.000.000.000 TRIX
Foundation            : 75.000.000.000 TRIX 
Team -----------------: 25.000.000.000 TRIX 
Monthly Holder Reward : 400.000.000.000 TRIX 

*With Our Mecanism , All TRIX Holder will get monthly reward for more than 20 Years* 
After Tokensale Finished TRIX will list on exchange, our first target TRIX will list on Okex , Hotbit , Cryptopia , Mercatox , idex 

Official website , Official twitter and official twitter will launch on December 2018 
-----------------------------
TOKENSALE PHASE 1 
TOKENSALE CONTRACT ADDRESS for PHASE 1 
"  0x5df18eF4055c807082797b44A09323e31e66AeF6  "

DATE : Oct 3,2018  to  Nov 3,2018
Rate 1 ETH = 50.000.000 TRIX + Bonus 100%
No Minimum Contribution
How to Contribute : 
Use Myetherwallet :
Send ETH to TOKENSALE CONTRACT ADDRESS for PHASE 1 
Example : Send 1 ETH to 0x5df18eF4055c807082797b44A09323e31e66AeF6 
Gas Price always check on ethgasstation.info
Gas Limits : 150.000
Data : 0xa6f2ae3a
Warning You Should input the Data "0xa6f2ae3a" or you will fail send the transaction 
Use Metamask :
Open Your Metamask and access the link below :
https://wizard.oracles.org/invest?addr=0x5df18eF4055c807082797b44A09323e31e66AeF6&networkID=1

------------------------------

TOKENSALE PHASE 2
TOKENSALE CONTRACT ADDRESS for PHASE 2 
"  0xba2D53ef55876F2247FBAA669c10bf9F2800D61E  "

DATE : Nov 4,2018 to Dec 15,2018 
Rate 1 ETH = 50.000.000 TRIX + Bonus 50%
No Minimum Contribution
How to Contribute : 
Use Myetherwallet :
Send ETH to TOKENSALE CONTRACT ADDRESS for PHASE 2 
Example : Send 1 ETH to 0xba2D53ef55876F2247FBAA669c10bf9F2800D61E 
Gas Price always check on ethgasstation.info
Gas Limits : 150.000
Data : 0xa6f2ae3a
Warning You Should input the Data "0xa6f2ae3a" or you will fail send the transaction 
Use Metamask :
Open Your Metamask and access the link below :
https://wizard.oracles.org/invest?addr=0xba2D53ef55876F2247FBAA669c10bf9F2800D61E&networkID=1

------------------------------

TOKENSALE PHASE 3 
TOKENSALE CONTRACT ADDRESS for PHASE 3 
"  0x1e1B917E8F1F882f481A1c7CFB0a5b1C75946Cef  "

DATE : Dec 16,2018  to  Jan 30,2019
Rate 1 ETH = 50.000.000 TRIX (no bonus)
No Minimum Contribution
How to Contribute : 
Use Myetherwallet :
Send ETH to TOKENSALE CONTRACT ADDRESS for PHASE 3 
Example : Send 1 ETH to 0x1e1B917E8F1F882f481A1c7CFB0a5b1C75946Cef 
Gas Price always check on ethgasstation.info
Gas Limits : 150.000
Data : 0xa6f2ae3a
Warning You Should input the Data "0xa6f2ae3a" or you will fail send the transaction 
Use Metamask :
Open Your Metamask and access the link below :
https://wizard.oracles.org/invest?addr=0x1e1B917E8F1F882f481A1c7CFB0a5b1C75946Cef&networkID=1

------------------------------

*/

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


contract UpgradeAgent {

  uint public originalSupply;

  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


/**
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. This can be the same as team multisig wallet, as what it is with its default value. */
  address public upgradeMaster;

  /** The next contract where the tokens will be migrated. */
  UpgradeAgent public upgradeAgent;

  /** How many tokens we have upgraded by now. */
  uint256 public totalUpgraded;

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
        // Called in a bad state
        throw;
      }

      // Validate input value.
      if (value == 0) throw;

      balances[msg.sender] = safeSub(balances[msg.sender], value);

      // Take tokens out from circulation
      totalSupply = safeSub(totalSupply, value);
      totalUpgraded = safeAdd(totalUpgraded, value);

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
        throw;
      }

      if (agent == 0x0) throw;
      // Only a master can designate the next agent
      if (msg.sender != upgradeMaster) throw;
      // Upgrade has already begun for an agent
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

      // Bad interface
      if(!upgradeAgent.isUpgradeAgent()) throw;
      // Make sure that token supplies match in source and target
      if (upgradeAgent.originalSupply() != totalSupply) throw;

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
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
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
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    releaseAgent = addr;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        throw;
    }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        throw;
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

library SafeMathLibExt {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divides(uint a, uint b) returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}




/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
contract MintableTokenExt is StandardToken, Ownable {

  using SafeMathLibExt for uint;

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

  /** inPercentageUnit is percents of tokens multiplied to 10 up to percents decimals.
  * For example, for reserved tokens in percents 2.54%
  * inPercentageUnit = 254
  * inPercentageDecimals = 2
  */
  struct ReservedTokensData {
    uint inTokens;
    uint inPercentageUnit;
    uint inPercentageDecimals;
    bool isReserved;
    bool isDistributed;
  }

  mapping (address => ReservedTokensData) public reservedTokensList;
  address[] public reservedTokensDestinations;
  uint public reservedTokensDestinationsLen = 0;
  bool reservedTokensDestinationsAreSet = false;

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  function finalizeReservedAddress(address addr) public onlyMintAgent canMint {
    ReservedTokensData storage reservedTokensData = reservedTokensList[addr];
    reservedTokensData.isDistributed = true;
  }

  function isAddressReserved(address addr) public constant returns (bool isReserved) {
    return reservedTokensList[addr].isReserved;
  }

  function areTokensDistributedForAddress(address addr) public constant returns (bool isDistributed) {
    return reservedTokensList[addr].isDistributed;
  }

  function getReservedTokens(address addr) public constant returns (uint inTokens) {
    return reservedTokensList[addr].inTokens;
  }

  function getReservedPercentageUnit(address addr) public constant returns (uint inPercentageUnit) {
    return reservedTokensList[addr].inPercentageUnit;
  }

  function getReservedPercentageDecimals(address addr) public constant returns (uint inPercentageDecimals) {
    return reservedTokensList[addr].inPercentageDecimals;
  }

  function setReservedTokensListMultiple(
    address[] addrs, 
    uint[] inTokens, 
    uint[] inPercentageUnit, 
    uint[] inPercentageDecimals
  ) public canMint onlyOwner {
    assert(!reservedTokensDestinationsAreSet);
    assert(addrs.length == inTokens.length);
    assert(inTokens.length == inPercentageUnit.length);
    assert(inPercentageUnit.length == inPercentageDecimals.length);
    for (uint iterator = 0; iterator < addrs.length; iterator++) {
      if (addrs[iterator] != address(0)) {
        setReservedTokensList(addrs[iterator], inTokens[iterator], inPercentageUnit[iterator], inPercentageDecimals[iterator]);
      }
    }
    reservedTokensDestinationsAreSet = true;
  }

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent).
   */
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = totalSupply.plus(amount);
    balances[receiver] = balances[receiver].plus(amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    Transfer(0, receiver, amount);
  }

  /**
   * Owner can allow a crowdsale contract to mint new tokens.
   */
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  function setReservedTokensList(address addr, uint inTokens, uint inPercentageUnit, uint inPercentageDecimals) private canMint onlyOwner {
    assert(addr != address(0));
    if (!isAddressReserved(addr)) {
      reservedTokensDestinations.push(addr);
      reservedTokensDestinationsLen++;
    }

    reservedTokensList[addr] = ReservedTokensData({
      inTokens: inTokens, 
      inPercentageUnit: inPercentageUnit, 
      inPercentageDecimals: inPercentageDecimals,
      isReserved: true,
      isDistributed: false
    });
  }
}


/**
 * A crowdsaled token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) or uncapped (crowdsale contract can mint new tokens)
 *
 */
contract CrowdsaleTokenExt is ReleasableToken, MintableTokenExt, UpgradeableToken {

  /** Name and symbol were updated. */
  event UpdatedTokenInformation(string newName, string newSymbol);

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

  string public name;

  string public symbol;

  uint public decimals;

  /* Minimum ammount of tokens every buyer can buy. */
  uint public minCap;

  /**
   * Construct the token.
   *
   * This token must be created through a team multisig wallet, so that it is owned by that wallet.
   *
   * @param _name Token name
   * @param _symbol Token symbol - should be all caps
   * @param _initialSupply How many tokens we start with
   * @param _decimals Number of decimal places
   * @param _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply? Note that when the token becomes transferable the minting always ends.
   */
  function CrowdsaleTokenExt(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable, uint _globalMinCap)
    UpgradeableToken(msg.sender) {

    // Create any address, can be transferred
    // to team multisig via changeOwner(),
    // also remember to call setUpgradeMaster()
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

    minCap = _globalMinCap;

    // Create initially all balance on the team multisig
    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

    // No more new supply allowed after the token creation
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw; // Cannot create a token without supply and no minting
      }
    }
  }

  /**
   * When token is released to be transferable, enforce no new tokens can be created.
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

  /**
   * Allow upgrade agent functionality kick in only if the crowdsale was success.
   */
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

  /**
   * Owner can update token information here.
   *
   * It is often useful to conceal the actual token association, until
   * the token operations, like central issuance or reissuance have been completed.
   *
   * This function allows the token owner to rename the token after the operations
   * have been completed and then point the audience to use the token contract.
   */
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

  /**
   * Claim tokens that were accidentally sent to this contract.
   *
   * @param _token The address of the token contract that you want to recover.
   */
  function claimTokens(address _token) public onlyOwner {
    require(_token != address(0));

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);

    ClaimedTokens(_token, owner, balance);
  }

}