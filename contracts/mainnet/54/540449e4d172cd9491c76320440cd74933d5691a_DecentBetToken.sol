pragma solidity ^0.4.8;

// accepted from zeppelin-solidity https://github.com/OpenZeppelin/zeppelin-solidity
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);

    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// accepted from zeppelin-solidity https://github.com/OpenZeppelin/zeppelin-solidity

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
        assert(c >= a && c >= b);
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

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }

}

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<span class="__cf_email__" data-cfemail="4132352427202f6f26242e33262401222e2f32242f3238326f2f2435">[email&#160;protected]</span>>
contract MultiSigWallet {

    // flag to determine if address is for a real contract or not
    bool public isMultiSigWallet = false;

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
        if (msg.sender != address(this)) throw;
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) throw;
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner]) throw;
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0) throw;
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner]) throw;
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed) throw;
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0) throw;
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (ownerCount > MAX_OWNER_COUNT) throw;
        if (_required > ownerCount) throw;
        if (_required == 0) throw;
        if (ownerCount == 0) throw;
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
            if (isOwner[_owners[i]] || _owners[i] == 0) throw;
            isOwner[_owners[i]] = true;
        }
        isMultiSigWallet = true;
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
    /// @param newOwner Address of new owner.
    /// @param index the indx of the owner to be replaced
    function replaceOwnerIndexed(address owner, address newOwner, uint index)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
    {
        if (owners[index] != owner) throw;
        owners[index] = newOwner;
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

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
    internal
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
        if ((pending && !transactions[i].executed) ||
        (executed && transactions[i].executed))
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
        if ((pending && !transactions[i].executed) ||
        (executed && transactions[i].executed))
        {
            transactionIdsTemp[count] = i;
            count += 1;
        }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
        _transactionIds[i - from] = transactionIdsTemp[i];
    }

}

contract UpgradeAgent is SafeMath {
    address public owner;

    bool public isUpgradeAgent;

    function upgradeFrom(address _from, uint256 _value) public;

    function finalizeUpgrade() public;

    function setOriginalSupply() public;
}

/// @title Time-locked vault of tokens allocated to DecentBet after 365 days
contract DecentBetVault is SafeMath {

    // flag to determine if address is for a real contract or not
    bool public isDecentBetVault = false;

    DecentBetToken decentBetToken;

    address decentBetMultisig;

    uint256 unlockedAtTime;

    // smaller lock for testing
    uint256 public constant timeOffset = 1 years;

    /// @notice Constructor function sets the DecentBet Multisig address and
    /// total number of locked tokens to transfer
    function DecentBetVault(address _decentBetMultisig) /** internal */ {
        if (_decentBetMultisig == 0x0) throw;
        decentBetToken = DecentBetToken(msg.sender);
        decentBetMultisig = _decentBetMultisig;
        isDecentBetVault = true;

        // 1 year later
        unlockedAtTime = safeAdd(getTime(), timeOffset);
    }

    /// @notice Transfer locked tokens to Decent.bet&#39;s multisig wallet
    function unlock() external {
        // Wait your turn!
        if (getTime() < unlockedAtTime) throw;
        // Will fail if allocation (and therefore toTransfer) is 0.
        if (!decentBetToken.transfer(decentBetMultisig, decentBetToken.balanceOf(this))) throw;
    }

    function getTime() internal returns (uint256) {
        return now;
    }

    // disallow ETH payments to TimeVault
    function() payable {
        throw;
    }

}


/// @title DecentBet crowdsale contract
contract DecentBetToken is SafeMath, ERC20 {

    // flag to determine if address is for a real contract or not
    bool public isDecentBetToken = false;

    // State machine
    enum State{Waiting, PreSale, CommunitySale, PublicSale, Success}

    // Token information
    string public constant name = "Decent.Bet Token";

    string public constant symbol = "DBET";

    uint256 public constant decimals = 18;  // decimal places

    uint256 public constant housePercentOfTotal = 10;

    uint256 public constant vaultPercentOfTotal = 18;

    uint256 public constant bountyPercentOfTotal = 2;

    uint256 public constant crowdfundPercentOfTotal = 70;

    uint256 public constant hundredPercent = 100;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    // Authorized addresses
    address public team;

    // Upgrade information
    bool public finalizedUpgrade = false;

    address public upgradeMaster;

    UpgradeAgent public upgradeAgent;

    uint256 public totalUpgraded;

    // Crowdsale information
    bool public finalizedCrowdfunding = false;

    // Whitelisted addresses for pre-sale
    address[] public preSaleWhitelist;
    mapping (address => bool) public preSaleAllowed;

    // Whitelisted addresses from community
    address[] public communitySaleWhitelist;
    mapping (address => bool) public communitySaleAllowed;
    uint[2] public communitySaleCap = [100000 ether, 200000 ether];
    mapping (address => uint[2]) communitySalePurchases;

    uint256 public preSaleStartTime; // Pre-sale start block timestamp
    uint256 public fundingStartTime; // crowdsale start block timestamp
    uint256 public fundingEndTime; // crowdsale end block timestamp
    // DBET:ETH exchange rate - Needs to be updated at time of ICO.
    // Price of ETH/0.125. For example: If ETH/USD = 300, it would be 2400 DBETs per ETH.
    uint256 public baseTokensPerEther;
    uint256 public tokenCreationMax = safeMul(250000 ether, 1000); // A maximum of 250M DBETs can be minted during ICO.

    // Amount of tokens alloted to pre-sale investors.
    uint256 public preSaleAllotment;
    // Address of pre-sale investors.
    address public preSaleAddress;

    // for testing on testnet
    //uint256 public constant tokenCreationMax = safeMul(10 ether, baseTokensPerEther);
    //uint256 public constant tokenCreationMin = safeMul(3 ether, baseTokensPerEther);

    address public decentBetMultisig;

    DecentBetVault public timeVault; // DecentBet&#39;s time-locked vault

    event Upgrade(address indexed _from, address indexed _to, uint256 _value);

    event UpgradeFinalized(address sender, address upgradeAgent);

    event UpgradeAgentSet(address agent);

    // Allow only the team address to continue
    modifier onlyTeam() {
        if(msg.sender != team) throw;
        _;
    }

    function DecentBetToken(address _decentBetMultisig,
    address _upgradeMaster, address _team,
    uint256 _baseTokensPerEther, uint256 _fundingStartTime,
    uint256 _fundingEndTime) {

        if (_decentBetMultisig == 0) throw;
        if (_team == 0) throw;
        if (_upgradeMaster == 0) throw;
        if (_baseTokensPerEther == 0) throw;

        // For testing/dev
        //         if(_fundingStartTime == 0) throw;
        // Crowdsale can only officially start during/after the current block timestamp.
        if (_fundingStartTime < getTime()) throw;

        if (_fundingEndTime <= _fundingStartTime) throw;

        isDecentBetToken = true;

        upgradeMaster = _upgradeMaster;
        team = _team;

        baseTokensPerEther = _baseTokensPerEther;

        preSaleStartTime = _fundingStartTime - 1 days;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;

        // Pre-sale issuance from pre-sale contract
        // 0x7be601aab2f40cc23653965749b84e5cb8cfda43
        preSaleAddress = 0x87f7beeda96216ec2a325e417a45ed262495686b;
        preSaleAllotment = 45000000 ether;

        balances[preSaleAddress] = preSaleAllotment;
        totalSupply = safeAdd(totalSupply, preSaleAllotment);

        timeVault = new DecentBetVault(_decentBetMultisig);
        if (!timeVault.isDecentBetVault()) throw;

        decentBetMultisig = _decentBetMultisig;
        if (!MultiSigWallet(decentBetMultisig).isMultiSigWallet()) throw;
    }

    function balanceOf(address who) constant returns (uint) {
        return balances[who];
    }

    /// @notice Transfer `value` DBET tokens from sender&#39;s account
    /// `msg.sender` to provided account address `to`.
    /// @notice This function is disabled during the funding.
    /// @dev Required state: Success
    /// @param to The address of the recipient
    /// @param value The number of DBETs to transfer
    /// @return Whether the transfer was successful or not
    function transfer(address to, uint256 value) returns (bool ok) {
        if (getState() != State.Success) throw;
        // Abort if crowdfunding was not a success.
        uint256 senderBalance = balances[msg.sender];
        if (senderBalance >= value && value > 0) {
            senderBalance = safeSub(senderBalance, value);
            balances[msg.sender] = senderBalance;
            balances[to] = safeAdd(balances[to], value);
            Transfer(msg.sender, to, value);
            return true;
        }
        return false;
    }

    /// @notice Transfer `value` DBET tokens from sender &#39;from&#39;
    /// to provided account address `to`.
    /// @notice This function is disabled during the funding.
    /// @dev Required state: Success
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The number of DBETs to transfer
    /// @return Whether the transfer was successful or not
    function transferFrom(address from, address to, uint256 value) returns (bool ok) {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        // protect against wrapping uints
        if (balances[from] >= value &&
        allowed[from][msg.sender] >= value &&
        safeAdd(balances[to], value) > balances[to])
        {
            balances[to] = safeAdd(balances[to], value);
            balances[from] = safeSub(balances[from], value);
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], value);
            Transfer(from, to, value);
            return true;
        }
        else {return false;}
    }

    /// @notice `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address spender, uint256 value) returns (bool ok) {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) constant returns (uint) {
        return allowed[owner][spender];
    }

    // Token upgrade functionality

    /// @notice Upgrade tokens to the new token contract.
    /// @dev Required state: Success
    /// @param value The number of tokens to upgrade
    function upgrade(uint256 value) external {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        if (upgradeAgent.owner() == 0x0) throw;
        // need a real upgradeAgent address
        if (finalizedUpgrade) throw;
        // cannot upgrade if finalized

        // Validate input value.
        if (value == 0) throw;
        if (value > balances[msg.sender]) throw;

        // update the balances here first before calling out (reentrancy)
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

    /// @notice Set address of upgrade target contract and enable upgrade
    /// process.
    /// @dev Required state: Success
    /// @param agent The address of the UpgradeAgent contract
    function setUpgradeAgent(address agent) external {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        if (agent == 0x0) throw;
        // don&#39;t set agent to nothing
        if (msg.sender != upgradeMaster) throw;
        // Only a master can designate the next agent
        upgradeAgent = UpgradeAgent(agent);
        if (!upgradeAgent.isUpgradeAgent()) throw;
        // this needs to be called in success condition to guarantee the invariant is true
        upgradeAgent.setOriginalSupply();
        UpgradeAgentSet(upgradeAgent);
    }

    /// @notice Set address of upgrade target contract and enable upgrade
    /// process.
    /// @dev Required state: Success
    /// @param master The address that will manage upgrades, not the upgradeAgent contract address
    function setUpgradeMaster(address master) external {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        if (master == 0x0) throw;
        if (msg.sender != upgradeMaster) throw;
        // Only a master can designate the next master
        upgradeMaster = master;
    }

    /// @notice finalize the upgrade
    /// @dev Required state: Success
    function finalizeUpgrade() external {
        if (getState() != State.Success) throw;
        // Abort if not in Success state.
        if (upgradeAgent.owner() == 0x0) throw;
        // we need a valid upgrade agent
        if (msg.sender != upgradeMaster) throw;
        // only upgradeMaster can finalize
        if (finalizedUpgrade) throw;
        // can&#39;t finalize twice

        finalizedUpgrade = true;
        // prevent future upgrades

        upgradeAgent.finalizeUpgrade();
        // call finalize upgrade on new contract
        UpgradeFinalized(msg.sender, upgradeAgent);
    }

    // Allow users to purchase by sending Ether to the contract
    function() payable {
        invest();
    }

    // Updates tokens per ETH rates before the pre-sale
    function updateBaseTokensPerEther(uint _baseTokensPerEther) onlyTeam {
        if(getState() != State.Waiting) throw;

        baseTokensPerEther = _baseTokensPerEther;
    }

    // Returns the current rate after adding bonuses for the time period
    function getTokensAtCurrentRate(uint weiValue) constant returns (uint) {
        /* Pre-sale */
        if(getTime() >= preSaleStartTime && getTime() < fundingStartTime) {
            return safeDiv(safeMul(weiValue, safeMul(baseTokensPerEther, 120)), 100); // 20% bonus
        }

        /* Community sale */
        else if(getTime() >= fundingStartTime && getTime() < fundingStartTime + 1 days) {
            return safeDiv(safeMul(weiValue, safeMul(baseTokensPerEther, 120)), 100); // 20% bonus
        } else if(getTime() >= (fundingStartTime + 1 days) && getTime() < fundingStartTime + 2 days) {
            return safeDiv(safeMul(weiValue, safeMul(baseTokensPerEther, 120)), 100); // 20% bonus
        }

        /* Public sale */
        else if(getTime() >= (fundingStartTime + 2 days) && getTime() < fundingStartTime + 1 weeks) {
            return safeDiv(safeMul(weiValue, safeMul(baseTokensPerEther, 110)), 100); // 10% bonus
        } else if(getTime() >= fundingStartTime + 1 weeks && getTime() < fundingStartTime + 2 weeks) {
            return safeDiv(safeMul(weiValue, safeMul(baseTokensPerEther, 105)), 100); // 5% bonus
        } else if(getTime() >= fundingStartTime + 2 weeks && getTime() < fundingEndTime) {
            return safeMul(weiValue, baseTokensPerEther); // 0% bonus
        }
    }

    // Allows the owner to add an address to the pre-sale whitelist.
    function addToPreSaleWhitelist(address _address) onlyTeam {

        // Add to pre-sale whitelist only if state is Waiting right now.
        if(getState() != State.Waiting) throw;

        // Address already added to whitelist.
        if (preSaleAllowed[_address]) throw;

        preSaleWhitelist.push(_address);
        preSaleAllowed[_address] = true;
    }

    // Allows the owner to add an address to the community whitelist.
    function addToCommunitySaleWhitelist(address[] addresses) onlyTeam {

        // Add to community sale whitelist only if state is Waiting or Presale right now.
        if(getState() != State.Waiting &&
        getState() != State.PreSale) throw;

        for(uint i = 0; i < addresses.length; i++) {
            if(!communitySaleAllowed[addresses[i]]) {
                communitySaleWhitelist.push(addresses[i]);
                communitySaleAllowed[addresses[i]] = true;
            }
        }
    }

    /// @notice Create tokens when funding is active.
    /// @dev Required state: Funding
    /// @dev State transition: -> Funding Success (only if cap reached)
    function invest() payable {

        // Abort if not in PreSale, CommunitySale or PublicSale state.
        if (getState() != State.PreSale &&
        getState() != State.CommunitySale &&
        getState() != State.PublicSale) throw;

        // User hasn&#39;t been whitelisted for pre-sale.
        if(getState() == State.PreSale && !preSaleAllowed[msg.sender]) throw;

        // User hasn&#39;t been whitelisted for community sale.
        if(getState() == State.CommunitySale && !communitySaleAllowed[msg.sender]) throw;

        // Do not allow creating 0 tokens.
        if (msg.value == 0) throw;

        // multiply by exchange rate to get newly created token amount
        uint256 createdTokens = getTokensAtCurrentRate(msg.value);

        allocateTokens(msg.sender, createdTokens);
    }

    // Allocates tokens to an investors&#39; address
    function allocateTokens(address _address, uint amount) internal {

        // we are creating tokens, so increase the totalSupply.
        totalSupply = safeAdd(totalSupply, amount);

        // don&#39;t go over the limit!
        if (totalSupply > tokenCreationMax) throw;

        // Don&#39;t allow community whitelisted addresses to purchase more than their cap.
        if(getState() == State.CommunitySale) {
            // Community sale day 1.
            // Whitelisted addresses can purchase a maximum of 100k DBETs (10k USD).
            if(getTime() >= fundingStartTime &&
            getTime() < fundingStartTime + 1 days) {
                if(safeAdd(communitySalePurchases[msg.sender][0], amount) > communitySaleCap[0])
                throw;
                else
                communitySalePurchases[msg.sender][0] =
                safeAdd(communitySalePurchases[msg.sender][0], amount);
            }

            // Community sale day 2.
            // Whitelisted addresses can purchase a maximum of 200k DBETs (20k USD).
            else if(getTime() >= (fundingStartTime + 1 days) &&
            getTime() < fundingStartTime + 2 days) {
                if(safeAdd(communitySalePurchases[msg.sender][1], amount) > communitySaleCap[1])
                throw;
                else
                communitySalePurchases[msg.sender][1] =
                safeAdd(communitySalePurchases[msg.sender][1], amount);
            }
        }

        // Assign new tokens to the sender.
        balances[_address] = safeAdd(balances[_address], amount);

        // Log token creation event
        Transfer(0, _address, amount);
    }

    /// @notice Finalize crowdfunding
    /// @dev If cap was reached or crowdfunding has ended then:
    /// create DBET for the DecentBet Multisig and team,
    /// transfer ETH to the DecentBet Multisig address.
    /// @dev Required state: Success
    function finalizeCrowdfunding() external {
        // Abort if not in Funding Success state.
        if (getState() != State.Success) throw;
        // don&#39;t finalize unless we won
        if (finalizedCrowdfunding) throw;
        // can&#39;t finalize twice (so sneaky!)

        // prevent more creation of tokens
        finalizedCrowdfunding = true;

        // Founder&#39;s supply : 18% of total goes to vault, time locked for 6 months
        uint256 vaultTokens = safeDiv(safeMul(totalSupply, vaultPercentOfTotal), crowdfundPercentOfTotal);
        balances[timeVault] = safeAdd(balances[timeVault], vaultTokens);
        Transfer(0, timeVault, vaultTokens);

        // House: 10% of total goes to Decent.bet for initial house setup
        uint256 houseTokens = safeDiv(safeMul(totalSupply, housePercentOfTotal), crowdfundPercentOfTotal);
        balances[timeVault] = safeAdd(balances[decentBetMultisig], houseTokens);
        Transfer(0, decentBetMultisig, houseTokens);

        // Bounties: 2% of total goes to Decent bet for bounties
        uint256 bountyTokens = safeDiv(safeMul(totalSupply, bountyPercentOfTotal), crowdfundPercentOfTotal);
        balances[decentBetMultisig] = safeAdd(balances[decentBetMultisig], bountyTokens);
        Transfer(0, decentBetMultisig, bountyTokens);

        // Transfer ETH to the DBET Multisig address.
        if (!decentBetMultisig.send(this.balance)) throw;
    }

    // Interface marker
    function isDecentBetCrowdsale() returns (bool) {
        return true;
    }

    function getTime() constant returns (uint256) {
        return now;
    }

    /// @notice This manages the crowdfunding state machine
    /// We make it a function and do not assign the result to a variable
    /// So there is no chance of the variable being stale
    function getState() public constant returns (State){
        /* Successful if crowdsale was finalized */
        if(finalizedCrowdfunding) return State.Success;

        /* Pre-sale not started */
        else if (getTime() < preSaleStartTime) return State.Waiting;

        /* Pre-sale */
        else if (getTime() >= preSaleStartTime &&
        getTime() < fundingStartTime &&
        totalSupply < tokenCreationMax) return State.PreSale;

        /* Community sale */
        else if (getTime() >= fundingStartTime &&
        getTime() < fundingStartTime + 2 days &&
        totalSupply < tokenCreationMax) return State.CommunitySale;

        /* Public sale */
        else if (getTime() >= (fundingStartTime + 2 days) &&
        getTime() < fundingEndTime &&
        totalSupply < tokenCreationMax) return State.PublicSale;

        /* Success */
        else if (getTime() >= fundingEndTime ||
        totalSupply == tokenCreationMax) return State.Success;
    }

}