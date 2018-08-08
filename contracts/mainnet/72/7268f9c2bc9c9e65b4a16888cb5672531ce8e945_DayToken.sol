pragma solidity ^0.4.13; 


////////////////// >>>>> Wallet Contract <<<<< ///////////////////


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<span class="__cf_email__" data-cfemail="b5c6c1d0d3d4db9bd2d0dac7d2d0f5d6dadbc6d0dbc6ccc69bdbd0c1">[email&#160;protected]</span>>
contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            throw;
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                throw;
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of new owner.
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner to be replaced.
    /// @param owner Address of new owner.
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction tx = transactions[transactionId];
            tx.executed = true;
            if (tx.destination.call.value(tx.value)(tx.data))
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
                tx.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        Submission(transactionId);
    }

    /*
     * Web3 call functions
     */
    /// @dev Returns number of confirmations of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        constant
        returns (uint count)
    {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
        public
        constant
        returns (address[])
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        constant
        returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

    /// @dev Returns list of transaction IDs in defined range.
    /// @param from Index start position of transaction array.
    /// @param to Index end position of transaction array.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}


////////////////// >>>>> Library Contracts <<<<< ///////////////////


contract SafeMathLib {
  function safeMul(uint a, uint b) constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) constant returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address _newOwner) onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


////////////////// >>>>> Token Contracts <<<<< ///////////////////

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address _owner) constant returns (uint balance);
  function transfer(address _to, uint _value) returns (bool success);
  event Transfer(address indexed _from, address indexed _to, uint _value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender) constant returns (uint remaining);
  function transferFrom(address _from, address _to, uint _value) returns (bool success);
  function approve(address _spender, uint _value) returns (bool success);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}



/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMathLib {
  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {
    if (balances[msg.sender] >= _value 
        && _value > 0 
        && balances[_to] + _value > balances[_to]
        ) {
      balances[msg.sender] = safeSub(balances[msg.sender],_value);
      balances[_to] = safeAdd(balances[_to],_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else{
      return false;
    }
    
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    if (balances[_from] >= _value   // From a/c has balance
        && _allowance >= _value    // Transfer approved
        && _value > 0              // Non-zero transfer
        && balances[_to] + _value > balances[_to]  // Overflow check
        ){
    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
        }
    else {
      return false;
    }
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}


    

/**
 * A token that can increase its supply by another contract.
 *
 * This allows uncapped crowdsale by dynamically increasing the supply when money pours in.
 * Only mint agents, contracts whitelisted by owner, can mint new tokens.
 *
 */
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

  /** List of agents that are allowed to create new tokens */
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );

  /**
   * Create new tokens and allocate them to an address..
   *
   * Only callably by a crowdsale contract (mint agent).
   */
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);
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

  modifier onlyMintAgent() {
    // Only crowdsale contracts are allowed to mint new tokens
    require(mintAgents[msg.sender]);
    _;
  }

  /** Make sure we are not done yet. */
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}



/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is ERC20, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. 
   * If false we are are in transfer lock up period.
   */
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. 
   * These are crowdsale contracts and possible the team multisig itself. 
   */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   */
  modifier canTransfer(address _sender) {

    if (!released) {
        require(transferAgents[_sender]);
    }

    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
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
   * Can be called only from the release agent that is the final ICO contract. 
   * It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
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
 * A token upgrade mechanism where users can opt-in amount of tokens to the next smart contract revision.
 *
 * First envisioned by Golem and Lunyr projects.
 */
contract UpgradeableToken is StandardToken {

  /** Contract / person who can set the upgrade path. 
   * This can be the same as team multisig wallet, as what it is with its default value. 
   */
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
   * Somebody has upgraded some of their tokens.
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
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));
    // Validate input value.
    require(value!=0);

    balances[msg.sender] = safeSub(balances[msg.sender],value);

    // Take tokens out from circulation
    totalSupply = safeSub(totalSupply,value);
    totalUpgraded = safeAdd(totalUpgraded,value);

    // Upgrade agent reissues the tokens
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

  /**
   * Set an upgrade agent that handles
   */
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());
    require(agent != 0x0);
    // Only a master can designate the next agent
    require(msg.sender == upgradeMaster);
    // Upgrade has already begun for an agent
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

    // Bad interface
    require(upgradeAgent.isUpgradeAgent());
    // Make sure that token supplies match in source and target
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

  /**
   * Get the state of the token upgrade.
   */
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
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
    require(master != 0x0);
    require(msg.sender == upgradeMaster);
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
 * A crowdsale token.
 *
 * An ERC-20 token designed specifically for crowdsales with investor protection and 
 * further development path.
 *
 * - The token transfer() is disabled until the crowdsale is over
 * - The token contract gives an opt-in upgrade path to a new contract
 * - The same token can be part of several crowdsales through approve() mechanism
 * - The token can be capped (supply set in the constructor) 
 *   or uncapped (crowdsale contract can mint new tokens)
 */
contract DayToken is  ReleasableToken, MintableToken, UpgradeableToken {

    enum sellingStatus {NOTONSALE, EXPIRED, ONSALE}

    /** Basic structure for a contributor with a minting Address
     * adr address of the contributor
     * initialContributionDay initial contribution of the contributor in wei
     * lastUpdatedOn day count from Minting Epoch when the account balance was last updated
     * mintingPower Initial Minting power of the address
     * expiryBlockNumber Variable to mark end of Minting address sale. Set by user
     * minPriceInDay minimum price of Minting address in Day tokens. Set by user
     * status Selling status Variable for transfer Minting address.
     * sellingPriceInDay Variable for transfer Minting address. Price at which the address is actually sold
     */ 
    struct Contributor {
        address adr;
        uint256 initialContributionDay;
        uint256 lastUpdatedOn; //Day from Minting Epoch
        uint256 mintingPower;
        uint expiryBlockNumber;
        uint256 minPriceInDay;
        sellingStatus status;
    }

    /* Stores maximum days for which minting will happen since minting epoch */
    uint256 public maxMintingDays = 1095;

    /* Mapping to store id of each minting address */
    mapping (address => uint) public idOf;
    /* Mapping from id of each minting address to their respective structures */
    mapping (uint256 => Contributor) public contributors;
    /* mapping to store unix timestamp of when the minting address is issued to each team member */
    mapping (address => uint256) public teamIssuedTimestamp;
    mapping (address => bool) public soldAddresses;
    mapping (address => uint256) public sellingPriceInDayOf;

    /* Stores the id of the first  contributor */
    uint256 public firstContributorId;
    /* Stores total Pre + Post ICO TimeMints */
    uint256 public totalNormalContributorIds;
    /* Stores total Normal TimeMints allocated */
    uint256 public totalNormalContributorIdsAllocated = 0;
    
    /* Stores the id of the first team TimeMint */
    uint256 public firstTeamContributorId;
    /* Stores the total team TimeMints */
    uint256 public totalTeamContributorIds;
    /* Stores total team TimeMints allocated */
    uint256 public totalTeamContributorIdsAllocated = 0;

    /* Stores the id of the first Post ICO contributor (for auctionable TimeMints) */
    uint256 public firstPostIcoContributorId;
    /* Stores total Post ICO TimeMints (for auction) */
    uint256 public totalPostIcoContributorIds;
    /* Stores total Auction TimeMints allocated */
    uint256 public totalPostIcoContributorIdsAllocated = 0;

    /* Maximum number of address */
    uint256 public maxAddresses;

    /* Min Minting power with 19 decimals: 0.5% : 5000000000000000000 */
    uint256 public minMintingPower;
    /* Max Minting power with 19 decimals: 1% : 10000000000000000000 */
    uint256 public maxMintingPower;
    /* Halving cycle in days (88) */
    uint256 public halvingCycle; 
    /* Unix timestamp when minting is to be started */
    uint256 public initialBlockTimestamp;
    /* Flag to prevent setting initialBlockTimestamp more than once */
    bool public isInitialBlockTimestampSet;
    /* number of decimals in minting power */
    uint256 public mintingDec; 

    /* Minimum Balance in Day tokens required to sell a minting address */
    uint256 public minBalanceToSell;
    /* Team address lock down period from issued time, in seconds */
    uint256 public teamLockPeriodInSec;  //Initialize and set function
    /* Duration in secs that we consider as a day. (For test deployment purposes, 
       if we want to decrease length of a day. default: 84600)*/
    uint256 public DayInSecs;

    event UpdatedTokenInformation(string newName, string newSymbol); 
    event MintingAdrTransferred(uint id, address from, address to);
    event ContributorAdded(address adr, uint id);
    event TimeMintOnSale(uint id, address seller, uint minPriceInDay, uint expiryBlockNumber);
    event TimeMintSold(uint id, address buyer, uint offerInDay);
    event PostInvested(address investor, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);
    
    event TeamAddressAdded(address teamAddress, uint id);
    // Tell us invest was success
    event Invested(address receiver, uint weiAmount, uint tokenAmount, uint customerId, uint contributorId);

    modifier onlyContributor(uint id){
        require(isValidContributorId(id));
        _;
    }

    string public name; 

    string public symbol; 

    uint8 public decimals; 

    /**
        * Construct the token.
        *
        * This token must be created through a team multisig wallet, so that it is owned by that wallet.
        *
        * @param _name Token name
        * @param _symbol Token symbol - should be all caps
        * @param _initialSupply How many tokens we start with
        * @param _decimals Number of decimal places
        * _mintable Are new tokens created over the crowdsale or do we distribute only the initial supply?
        */
    function DayToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, 
        bool _mintable, uint _maxAddresses, uint _firstTeamContributorId, uint _totalTeamContributorIds, 
        uint _totalPostIcoContributorIds, uint256 _minMintingPower, uint256 _maxMintingPower, uint _halvingCycle, 
        uint256 _minBalanceToSell, uint256 _dayInSecs, uint256 _teamLockPeriodInSec) 
        UpgradeableToken(msg.sender) {
        
        // Create any address, can be transferred
        // to team multisig via changeOwner(),
        // also remember to call setUpgradeMaster()
        owner = msg.sender; 
        name = _name; 
        symbol = _symbol;  
        totalSupply = _initialSupply; 
        decimals = _decimals; 
        // Create initially all balance on the team multisig
        balances[owner] = totalSupply; 
        maxAddresses = _maxAddresses;
        require(maxAddresses > 1); // else division by zero will occur in setInitialMintingPowerOf
        
        firstContributorId = 1;
        totalNormalContributorIds = maxAddresses - _totalTeamContributorIds - _totalPostIcoContributorIds;

        // check timeMint total is sane
        require(totalNormalContributorIds >= 1);

        firstTeamContributorId = _firstTeamContributorId;
        totalTeamContributorIds = _totalTeamContributorIds;
        totalPostIcoContributorIds = _totalPostIcoContributorIds;
        
        // calculate first contributor id to be auctioned post ICO
        firstPostIcoContributorId = maxAddresses - totalPostIcoContributorIds + 1;
        minMintingPower = _minMintingPower;
        maxMintingPower = _maxMintingPower;
        halvingCycle = _halvingCycle;
        // setting future date far far away, year 2020, 
        // call setInitialBlockTimestamp to set proper timestamp
        initialBlockTimestamp = 1577836800;
        isInitialBlockTimestampSet = false;
        // use setMintingDec to change this
        mintingDec = 19;
        minBalanceToSell = _minBalanceToSell;
        DayInSecs = _dayInSecs;
        teamLockPeriodInSec = _teamLockPeriodInSec;
        
        if (totalSupply > 0) {
            Minted(owner, totalSupply); 
        }

        if (!_mintable) {
            mintingFinished = true; 
            require(totalSupply != 0); 
        }
    }

    /**
    * Used to set timestamp at which minting power of TimeMints is activated
    * Can be called only by owner
    * @param _initialBlockTimestamp timestamp to be set.
    */
    function setInitialBlockTimestamp(uint _initialBlockTimestamp) internal onlyOwner {
        require(!isInitialBlockTimestampSet);
        isInitialBlockTimestampSet = true;
        initialBlockTimestamp = _initialBlockTimestamp;
    }

    /**
    * check if mintining power is activated and Day token and Timemint transfer is enabled
    */
    function isDayTokenActivated() constant returns (bool isActivated) {
        return (block.timestamp >= initialBlockTimestamp);
    }


    /**
    * to check if an id is a valid contributor
    * @param _id contributor id to check.
    */
    function isValidContributorId(uint _id) constant returns (bool isValidContributor) {
        return (_id > 0 && _id <= maxAddresses && contributors[_id].adr != 0 
            && idOf[contributors[_id].adr] == _id); // cross checking
    }

    /**
    * to check if an address is a valid contributor
    * @param _address  contributor address to check.
    */
    function isValidContributorAddress(address _address) constant returns (bool isValidContributor) {
        return isValidContributorId(idOf[_address]);
    }


    /**
    * In case of Team address check if lock-in period is over (returns true for all non team addresses)
    * @param _address team address to check lock in period for.
    */
    function isTeamLockInPeriodOverIfTeamAddress(address _address) constant returns (bool isLockInPeriodOver) {
        isLockInPeriodOver = true;
        if (teamIssuedTimestamp[_address] != 0) {
                if (block.timestamp - teamIssuedTimestamp[_address] < teamLockPeriodInSec)
                    isLockInPeriodOver = false;
        }

        return isLockInPeriodOver;
    }

    /**
    * Used to set mintingDec
    * Can be called only by owner
    * @param _mintingDec bounty to be set.
    */
    function setMintingDec(uint256 _mintingDec) onlyOwner {
        require(!isInitialBlockTimestampSet);
        mintingDec = _mintingDec;
    }

    /**
        * When token is released to be transferable, enforce no new tokens can be created.
        */
    function releaseTokenTransfer() public onlyOwner {
        require(isInitialBlockTimestampSet);
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
        * Owner can update token information here
        */
    function setTokenInformation(string _name, string _symbol) onlyOwner {
        name = _name; 
        symbol = _symbol; 
        UpdatedTokenInformation(name, symbol); 
    }

    /**
        * Returns the current phase.  
        * Note: Phase starts with 1
        * @param _day Number of days since Minting Epoch
        */
    function getPhaseCount(uint _day) public constant returns (uint phase) {
        phase = (_day/halvingCycle) + 1; 
        return (phase); 
    }
    /**
        * Returns current day number since minting epoch 
        * or zero if initialBlockTimestamp is in future or its DayZero.
        */
    function getDayCount() public constant returns (uint daySinceMintingEpoch) {
        daySinceMintingEpoch = 0;
        if (isDayTokenActivated())
            daySinceMintingEpoch = (block.timestamp - initialBlockTimestamp)/DayInSecs; 

        return daySinceMintingEpoch; 
    }
    /**
        * Calculates and Sets the minting power of a particular id.
        * Called before Minting Epoch by constructor
        * @param _id id of the address whose minting power is to be set.
        */
    function setInitialMintingPowerOf(uint256 _id) internal onlyContributor(_id) {
        contributors[_id].mintingPower = 
            (maxMintingPower - ((_id-1) * (maxMintingPower - minMintingPower)/(maxAddresses-1))); 
    }

    /**
        * Returns minting power of a particular id.
        * @param _id Contribution id whose minting power is to be returned
        */
    function getMintingPowerById(uint _id) public constant returns (uint256 mintingPower) {
        return contributors[_id].mintingPower/(2**(getPhaseCount(getDayCount())-1)); 
    }

    /**
        * Returns minting power of a particular address.
        * @param _adr Address whose minting power is to be returned
        */
    function getMintingPowerByAddress(address _adr) public constant returns (uint256 mintingPower) {
        return getMintingPowerById(idOf[_adr]);
    }


    /**
        * Calculates and returns the balance based on the minting power, day and phase.
        * Can only be called internally
        * Can calculate balance based on last updated.
        * @param _id id whose balnce is to be calculated
        * @param _dayCount day count upto which balance is to be updated
        */
    function availableBalanceOf(uint256 _id, uint _dayCount) internal returns (uint256) {
        uint256 balance = balances[contributors[_id].adr]; 
        uint maxUpdateDays = _dayCount < maxMintingDays ? _dayCount : maxMintingDays;
        uint i = contributors[_id].lastUpdatedOn + 1;
        while(i <= maxUpdateDays) {
             uint phase = getPhaseCount(i);
             uint phaseEndDay = phase * halvingCycle - 1; // as first day is 0
             uint constantFactor = contributors[_id].mintingPower / 2**(phase-1);

            for (uint j = i; j <= phaseEndDay && j <= maxUpdateDays; j++) {
                balance = safeAdd( balance, constantFactor * balance / 10**(mintingDec + 2) );
            }

            i = j;
            
        } 
        return balance; 
    }

    /**
        * Updates the balance of the specified id in its structure and also in the balances[] mapping.
        * returns true if successful.
        * Only for internal calls. Not public.
        * @param _id id whose balance is to be updated.
        */
    function updateBalanceOf(uint256 _id) internal returns (bool success) {
        // check if its contributor
        if (isValidContributorId(_id)) {
            uint dayCount = getDayCount();
            // proceed only if not already updated today
            if (contributors[_id].lastUpdatedOn != dayCount && contributors[_id].lastUpdatedOn < maxMintingDays) {
                address adr = contributors[_id].adr;
                uint oldBalance = balances[adr];
                totalSupply = safeSub(totalSupply, oldBalance);
                uint newBalance = availableBalanceOf(_id, dayCount);
                balances[adr] = newBalance;
                totalSupply = safeAdd(totalSupply, newBalance);
                contributors[_id].lastUpdatedOn = dayCount;
                Transfer(0, adr, newBalance - oldBalance);
                return true; 
            }
        }
        return false;
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified address.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _adr address whose balance is to be returned.
        */
    function balanceOf(address _adr) constant returns (uint balance) {
        uint id = idOf[_adr];
        if (id != 0)
            return balanceById(id);
        else 
            return balances[_adr]; 
    }


    /**
        * Standard ERC20 function overridden.
        * Returns the balance of the specified id.
        * Calculates the balance on fly only if it is a minting address else 
        * simply returns balance from balances[] mapping.
        * For public calls.
        * @param _id address whose balance is to be returned.
        */
    function balanceById(uint _id) public constant returns (uint256 balance) {
        address adr = contributors[_id].adr; 
        if (isDayTokenActivated()) {
            if (isValidContributorId(_id)) {
                return ( availableBalanceOf(_id, getDayCount()) );
            }
        }
        return balances[adr]; 
    }

    /**
        * Returns totalSupply of DAY tokens.
        */
    function getTotalSupply() public constant returns (uint) {
        return totalSupply;
    }

    /** Function to update balance of a Timemint
        * returns true if balance updated, false otherwise
        * @param _id TimeMint to update
        */
    function updateTimeMintBalance(uint _id) public returns (bool) {
        require(isDayTokenActivated());
        return updateBalanceOf(_id);
    }

    /** Function to update balance of sender&#39;s Timemint
        * returns true if balance updated, false otherwise
        */
    function updateMyTimeMintBalance() public returns (bool) {
        require(isDayTokenActivated());
        return updateBalanceOf(idOf[msg.sender]);
    }

    /**
        * Standard ERC20 function overidden.
        * Used to transfer day tokens from caller&#39;s address to another
        * @param _to address to which Day tokens are to be transferred
        * @param _value Number of Day tokens to be transferred
        */
    function transfer(address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());
        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        updateBalanceOf(idOf[msg.sender]);

        // Check sender account has enough balance and transfer amount is non zero
        require ( balanceOf(msg.sender) >= _value && _value != 0 ); 
        
        updateBalanceOf(idOf[_to]);

        balances[msg.sender] = safeSub(balances[msg.sender], _value); 
        balances[_to] = safeAdd(balances[_to], _value); 
        Transfer(msg.sender, _to, _value);

        return true;
    }
    

    /**
        * Standard ERC20 Standard Token function overridden. Added Team address vesting period lock. 
        */
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(isDayTokenActivated());

        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(_from));

        uint _allowance = allowed[_from][msg.sender];

        updateBalanceOf(idOf[_from]);

        // Check from account has enough balance, transfer amount is non zero 
        // and _value is allowed to be transferred
        require ( balanceOf(_from) >= _value && _value != 0  &&  _value <= _allowance); 

        updateBalanceOf(idOf[_to]);

        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
    
        Transfer(_from, _to, _value);
        
        return true;
    }


    /** 
        * Add any contributor structure (For every kind of contributors: Team/Pre-ICO/ICO/Test)
        * @param _adr Address of the contributor to be added  
        * @param _initialContributionDay Initial Contribution of the contributor to be added
        */
  function addContributor(uint contributorId, address _adr, uint _initialContributionDay) internal onlyOwner {
        require(contributorId <= maxAddresses);
        //address should not be an existing contributor
        require(!isValidContributorAddress(_adr));
        //TimeMint should not be already allocated
        require(!isValidContributorId(contributorId));
        contributors[contributorId].adr = _adr;
        idOf[_adr] = contributorId;
        setInitialMintingPowerOf(contributorId);
        contributors[contributorId].initialContributionDay = _initialContributionDay;
        contributors[contributorId].lastUpdatedOn = getDayCount();
        ContributorAdded(_adr, contributorId);
        contributors[contributorId].status = sellingStatus.NOTONSALE;
    }


    /** Function to be called by minting addresses in order to sell their address
        * @param _minPriceInDay Minimum price in DAY tokens set by the seller
        * @param _expiryBlockNumber Expiry Block Number set by the seller
        */
    function sellMintingAddress(uint256 _minPriceInDay, uint _expiryBlockNumber) public returns (bool) {
        require(isDayTokenActivated());
        require(_expiryBlockNumber > block.number);

        // if Team address, check if lock-in period is over
        require(isTeamLockInPeriodOverIfTeamAddress(msg.sender));

        uint id = idOf[msg.sender];
        require(contributors[id].status == sellingStatus.NOTONSALE);

        // update balance of sender address before checking for minimum required balance
        updateBalanceOf(id);
        require(balances[msg.sender] >= minBalanceToSell);
        contributors[id].minPriceInDay = _minPriceInDay;
        contributors[id].expiryBlockNumber = _expiryBlockNumber;
        contributors[id].status = sellingStatus.ONSALE;
        balances[msg.sender] = safeSub(balances[msg.sender], minBalanceToSell);
        balances[this] = safeAdd(balances[this], minBalanceToSell);
        Transfer(msg.sender, this, minBalanceToSell);
        TimeMintOnSale(id, msg.sender, contributors[id].minPriceInDay, contributors[id].expiryBlockNumber);
        return true;
    }


    /** Function to be called by minting address in order to cancel the sale of their TimeMint
        */
    function cancelSaleOfMintingAddress() onlyContributor(idOf[msg.sender]) public {
        uint id = idOf[msg.sender];
        // TimeMint should be on sale
        require(contributors[id].status == sellingStatus.ONSALE);
        contributors[id].status = sellingStatus.EXPIRED;
    }


    /** Function to be called by any user to get a list of all On Sale TimeMints
        */
    function getOnSaleIds() constant public returns(uint[]) {
        uint[] memory idsOnSale = new uint[](maxAddresses);
        uint j = 0;
        for(uint i=1; i <= maxAddresses; i++) {

            if ( isValidContributorId(i) &&
                block.number <= contributors[i].expiryBlockNumber && 
                contributors[i].status == sellingStatus.ONSALE ) {
                    idsOnSale[j] = i;
                    j++;     
            }
            
        }
        return idsOnSale;
    }


    /** Function to be called by any user to get status of a Time Mint.
        * returns status 0 - Not on sale, 1 - Expired, 2 - On sale,
        * @param _id ID number of the Time Mint 
        */
    function getSellingStatus(uint _id) constant public returns(sellingStatus status) {
        require(isValidContributorId(_id));
        status = contributors[_id].status;
        if ( block.number > contributors[_id].expiryBlockNumber && 
                status == sellingStatus.ONSALE )
            status = sellingStatus.EXPIRED;

        return status;
    }

    /** Function to be called by any user to buy a onsale address by offering an amount
        * @param _offerId ID number of the address to be bought by the buyer
        * @param _offerInDay Offer given by the buyer in number of DAY tokens
        */
    function buyMintingAddress(uint _offerId, uint256 _offerInDay) public returns(bool) {
        if (contributors[_offerId].status == sellingStatus.ONSALE 
            && block.number > contributors[_offerId].expiryBlockNumber)
        {
            contributors[_offerId].status = sellingStatus.EXPIRED;
        }
        address soldAddress = contributors[_offerId].adr;
        require(contributors[_offerId].status == sellingStatus.ONSALE);
        require(_offerInDay >= contributors[_offerId].minPriceInDay);

        // prevent seller from cancelling sale in between
        contributors[_offerId].status = sellingStatus.NOTONSALE;

        // first get the offered DayToken in the token contract & 
        // then transfer the total sum (minBalanceToSend+_offerInDay) to the seller
        balances[msg.sender] = safeSub(balances[msg.sender], _offerInDay);
        balances[this] = safeAdd(balances[this], _offerInDay);
        Transfer(msg.sender, this, _offerInDay);
        if(transferMintingAddress(contributors[_offerId].adr, msg.sender)) {
            //mark the offer as sold & let seller pull the proceed to their own account.
            sellingPriceInDayOf[soldAddress] = _offerInDay;
            soldAddresses[soldAddress] = true; 
            TimeMintSold(_offerId, msg.sender, _offerInDay);  
        }
        return true;
    }


    /**
        * Transfer minting address from one user to another
        * Gives the transfer-to address, the id of the original address
        * returns true if successful and false if not.
        * @param _to address of the user to which minting address is to be tranferred
        */
    function transferMintingAddress(address _from, address _to) internal onlyContributor(idOf[_from]) returns (bool) {
        require(isDayTokenActivated());

        // _to should be non minting address
        require(!isValidContributorAddress(_to));
        
        uint id = idOf[_from];
        // update balance of from address before transferring minting power
        updateBalanceOf(id);

        contributors[id].adr = _to;
        idOf[_to] = id;
        idOf[_from] = 0;
        contributors[id].initialContributionDay = 0;
        // needed as id is assigned to new address
        contributors[id].lastUpdatedOn = getDayCount();
        contributors[id].expiryBlockNumber = 0;
        contributors[id].minPriceInDay = 0;
        MintingAdrTransferred(id, _from, _to);
        return true;
    }


    /** Function to allow seller to get back their deposited amount of day tokens(minBalanceToSell) and 
        * offer made by buyer after successful sale.
        * Throws if sale is not successful
        */
    function fetchSuccessfulSaleProceed() public  returns(bool) {
        require(soldAddresses[msg.sender] == true);
        // to prevent re-entrancy attack
        soldAddresses[msg.sender] = false;
        uint saleProceed = safeAdd(minBalanceToSell, sellingPriceInDayOf[msg.sender]);
        balances[this] = safeSub(balances[this], saleProceed);
        balances[msg.sender] = safeAdd(balances[msg.sender], saleProceed);
        Transfer(this, msg.sender, saleProceed);
        return true;
                
    }

    /** Function that lets a seller get their deposited day tokens (minBalanceToSell) back, if no buyer turns up.
        * Allowed only after expiryBlockNumber
        * Throws if any other state other than EXPIRED
        */
    function refundFailedAuctionAmount() onlyContributor(idOf[msg.sender]) public returns(bool){
        uint id = idOf[msg.sender];
        if(block.number > contributors[id].expiryBlockNumber && contributors[id].status == sellingStatus.ONSALE)
        {
            contributors[id].status = sellingStatus.EXPIRED;
        }
        require(contributors[id].status == sellingStatus.EXPIRED);
        // reset selling status
        contributors[id].status = sellingStatus.NOTONSALE;
        balances[this] = safeSub(balances[this], minBalanceToSell);
        // update balance of seller address before refunding
        updateBalanceOf(id);
        balances[msg.sender] = safeAdd(balances[msg.sender], minBalanceToSell);
        contributors[id].minPriceInDay = 0;
        contributors[id].expiryBlockNumber = 0;
        Transfer(this, msg.sender, minBalanceToSell);
        return true;
    }


    /** Function to add a team address as a contributor and store it&#39;s time issued to calculate vesting period
        * Called by owner
        */
    function addTeamTimeMints(address _adr, uint _id, uint _tokens, bool _isTest) public onlyOwner {
        //check if Id is in range of team Ids
        require(_id >= firstTeamContributorId && _id < firstTeamContributorId + totalTeamContributorIds);
        require(totalTeamContributorIdsAllocated < totalTeamContributorIds);
        addContributor(_id, _adr, 0);
        totalTeamContributorIdsAllocated++;
        // enforce lockin period if not test address
        if(!_isTest) teamIssuedTimestamp[_adr] = block.timestamp;
        mint(_adr, _tokens);
        TeamAddressAdded(_adr, _id);
    }


    /** Function to add reserved aution TimeMints post-ICO. Only by owner
        * @param _receiver Address of the minting to be added
        * @param _customerId Server side id of the customer
        * @param _id contributorId
        */
    function postAllocateAuctionTimeMints(address _receiver, uint _customerId, uint _id) public onlyOwner {

        //check if Id is in range of Auction Ids
        require(_id >= firstPostIcoContributorId && _id < firstPostIcoContributorId + totalPostIcoContributorIds);
        require(totalPostIcoContributorIdsAllocated < totalPostIcoContributorIds);
        
        require(released == true);
        addContributor(_id, _receiver, 0);
        totalPostIcoContributorIdsAllocated++;
        PostInvested(_receiver, 0, 0, _customerId, _id);
    }


    /** Function to add all contributors except team, test and Auctions TimeMints. Only by owner
        * @param _receiver Address of the minting to be added
        * @param _customerId Server side id of the customer
        * @param _id contributor id
        * @param _tokens day tokens to allocate
        * @param _weiAmount ether invested in wei
        */
    function allocateNormalTimeMints(address _receiver, uint _customerId, uint _id, uint _tokens, uint _weiAmount) public onlyOwner {
        // check if Id is in range of Normal Ids
        require(_id >= firstContributorId && _id <= totalNormalContributorIds);
        require(totalNormalContributorIdsAllocated < totalNormalContributorIds);
        addContributor(_id, _receiver, _tokens);
        totalNormalContributorIdsAllocated++;
        mint(_receiver, _tokens);
        Invested(_receiver, _weiAmount, _tokens, _customerId, _id);
        
    }


    /** Function to release token
        * Called by owner
        */
    function releaseToken(uint _initialBlockTimestamp) public onlyOwner {
        require(!released); // check not already released
        
        setInitialBlockTimestamp(_initialBlockTimestamp);

        // Make token transferable
        releaseTokenTransfer();
    }
    
}