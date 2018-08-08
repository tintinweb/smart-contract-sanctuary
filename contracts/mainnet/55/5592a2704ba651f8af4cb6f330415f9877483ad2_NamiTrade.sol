pragma solidity ^0.4.23;


/*
* NamiMultiSigWallet smart contract-------------------------------
*/
/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract NamiMultiSigWallet {

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
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(!(ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0));
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!(isOwner[_owners[i]] || _owners[i] == 0));
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
        emit OwnerAddition(owner);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(owner);
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
        for (uint i=0; i<owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
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
        emit Confirmation(msg.sender, transactionId);
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
        emit Revocation(msg.sender, transactionId);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            // Transaction tx = transactions[transactionId];
            transactions[transactionId].executed = true;
            // tx.executed = true;
            if (transactions[transactionId].destination.call.value(transactions[transactionId].value)(transactions[transactionId].data)) {
                emit Execution(transactionId);
            } else {
                emit ExecutionFailure(transactionId);
                transactions[transactionId].executed = false;
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
        for (uint i = 0; i < owners.length; i++) {
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
        emit Submission(transactionId);
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
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
        }
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
        for (uint i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed)
                count += 1;
        }
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
        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
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
        for (i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}

 /*
 * Contract that is working with ERC223 tokens
 */
 
 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool success);
    function tokenFallbackBuyer(address _from, uint _value, address _buyer) public returns (bool success);
    function tokenFallbackExchange(address _from, uint _value, uint _price) public returns (bool success);
}
contract PresaleToken {
    mapping (address => uint256) public balanceOf;
    function burnTokens(address _owner) public;
}

// ERC20 token interface is implemented only partially.
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract NamiCrowdSale {
    using SafeMath for uint256;

    /// NAC Broker Presale Token
    /// @dev Constructor
    constructor(address _escrow, address _namiMultiSigWallet, address _namiPresale) public {
        require(_namiMultiSigWallet != 0x0);
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        namiPresale = _namiPresale;
    }


    /*/
     *  Constants
    /*/

    string public name = "Nami ICO";
    string public  symbol = "NAC";
    uint   public decimals = 18;

    bool public TRANSFERABLE = false; // default not transferable

    uint public constant TOKEN_SUPPLY_LIMIT = 1000000000 * (1 ether / 1 wei);
    
    uint public binary = 0;

    /*/
     *  Token state
    /*/

    enum Phase {
        Created,
        Running,
        Paused,
        Migrating,
        Migrated
    }

    Phase public currentPhase = Phase.Created;
    uint public totalSupply = 0; // amount of tokens already sold

    // escrow has exclusive priveleges to call administrative
    // functions on this contract.
    address public escrow;

    // Gathered funds can be withdraw only to namimultisigwallet&#39;s address.
    address public namiMultiSigWallet;

    // nami presale contract
    address public namiPresale;

    // Crowdsale manager has exclusive priveleges to burn presale tokens.
    address public crowdsaleManager;
    
    // binary option address
    address public binaryAddress;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    modifier onlyCrowdsaleManager() {
        require(msg.sender == crowdsaleManager); 
        _; 
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }
    
    modifier onlyTranferable() {
        require(TRANSFERABLE);
        _;
    }
    
    modifier onlyNamiMultisig() {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    /*/
     *  Events
    /*/

    event LogBuy(address indexed owner, uint value);
    event LogBurn(address indexed owner, uint value);
    event LogPhaseSwitch(Phase newPhase);
    // Log migrate token
    event LogMigrate(address _from, address _to, uint256 amount);
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    /*/
     *  Public functions
    /*/

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // Transfer the balance from owner&#39;s account to another account
    // only escrow can send token (to send token private sale)
    function transferForTeam(address _to, uint256 _value) public
        onlyEscrow
    {
        _transfer(msg.sender, _to, _value);
    }
    
    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public
        onlyTranferable
    {
        _transfer(msg.sender, _to, _value);
    }
    
       /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) 
        public
        onlyTranferable
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        onlyTranferable
        returns (bool success) 
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        onlyTranferable
        returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // allows transfer token
    function changeTransferable () public
        onlyEscrow
    {
        TRANSFERABLE = !TRANSFERABLE;
    }
    
    // change escrow
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    // change binary value
    function changeBinary(uint _binary)
        public
        onlyEscrow
    {
        binary = _binary;
    }
    
    // change binary address
    function changeBinaryAddress(address _binaryAddress)
        public
        onlyEscrow
    {
        require(_binaryAddress != 0x0);
        binaryAddress = _binaryAddress;
    }
    
    /*
    * price in ICO:
    * first week: 1 ETH = 2400 NAC
    * second week: 1 ETH = 23000 NAC
    * 3rd week: 1 ETH = 2200 NAC
    * 4th week: 1 ETH = 2100 NAC
    * 5th week: 1 ETH = 2000 NAC
    * 6th week: 1 ETH = 1900 NAC
    * 7th week: 1 ETH = 1800 NAC
    * 8th week: 1 ETH = 1700 nac
    * time: 
    * 1517443200: Thursday, February 1, 2018 12:00:00 AM
    * 1518048000: Thursday, February 8, 2018 12:00:00 AM
    * 1518652800: Thursday, February 15, 2018 12:00:00 AM
    * 1519257600: Thursday, February 22, 2018 12:00:00 AM
    * 1519862400: Thursday, March 1, 2018 12:00:00 AM
    * 1520467200: Thursday, March 8, 2018 12:00:00 AM
    * 1521072000: Thursday, March 15, 2018 12:00:00 AM
    * 1521676800: Thursday, March 22, 2018 12:00:00 AM
    * 1522281600: Thursday, March 29, 2018 12:00:00 AM
    */
    function getPrice() public view returns (uint price) {
        if (now < 1517443200) {
            // presale
            return 3450;
        } else if (1517443200 < now && now <= 1518048000) {
            // 1st week
            return 2400;
        } else if (1518048000 < now && now <= 1518652800) {
            // 2nd week
            return 2300;
        } else if (1518652800 < now && now <= 1519257600) {
            // 3rd week
            return 2200;
        } else if (1519257600 < now && now <= 1519862400) {
            // 4th week
            return 2100;
        } else if (1519862400 < now && now <= 1520467200) {
            // 5th week
            return 2000;
        } else if (1520467200 < now && now <= 1521072000) {
            // 6th week
            return 1900;
        } else if (1521072000 < now && now <= 1521676800) {
            // 7th week
            return 1800;
        } else if (1521676800 < now && now <= 1522281600) {
            // 8th week
            return 1700;
        } else {
            return binary;
        }
    }


    function() payable public {
        buy(msg.sender);
    }
    
    
    function buy(address _buyer) payable public {
        // Available only if presale is running.
        require(currentPhase == Phase.Running);
        // require ICO time or binary option
        require(now <= 1522281600 || msg.sender == binaryAddress);
        require(msg.value != 0);
        uint newTokens = msg.value * getPrice();
        require (totalSupply + newTokens < TOKEN_SUPPLY_LIMIT);
        // add new token to buyer
        balanceOf[_buyer] = balanceOf[_buyer].add(newTokens);
        // add new token to totalSupply
        totalSupply = totalSupply.add(newTokens);
        emit LogBuy(_buyer,newTokens);
        emit Transfer(this,_buyer,newTokens);
    }
    

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function burnTokens(address _owner) public
        onlyCrowdsaleManager
    {
        // Available only during migration phase
        require(currentPhase == Phase.Migrating);

        uint tokens = balanceOf[_owner];
        require(tokens != 0);
        balanceOf[_owner] = 0;
        totalSupply -= tokens;
        emit LogBurn(_owner, tokens);
        emit Transfer(_owner, crowdsaleManager, tokens);

        // Automatically switch phase when migration is done.
        if (totalSupply == 0) {
            currentPhase = Phase.Migrated;
            emit LogPhaseSwitch(Phase.Migrated);
        }
    }


    /*/
     *  Administrative functions
    /*/
    function setPresalePhase(Phase _nextPhase) public
        onlyEscrow
    {
        bool canSwitchPhase
            =  (currentPhase == Phase.Created && _nextPhase == Phase.Running)
            || (currentPhase == Phase.Running && _nextPhase == Phase.Paused)
                // switch to migration phase only if crowdsale manager is set
            || ((currentPhase == Phase.Running || currentPhase == Phase.Paused)
                && _nextPhase == Phase.Migrating
                && crowdsaleManager != 0x0)
            || (currentPhase == Phase.Paused && _nextPhase == Phase.Running)
                // switch to migrated only if everyting is migrated
            || (currentPhase == Phase.Migrating && _nextPhase == Phase.Migrated
                && totalSupply == 0);

        require(canSwitchPhase);
        currentPhase = _nextPhase;
        emit LogPhaseSwitch(_nextPhase);
    }


    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
        // Available at any phase.
        if (address(this).balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }
    
    function safeWithdraw(address _withdraw, uint _amount) public
        onlyEscrow
    {
        NamiMultiSigWallet namiWallet = NamiMultiSigWallet(namiMultiSigWallet);
        if (namiWallet.isOwner(_withdraw)) {
            _withdraw.transfer(_amount);
        }
    }


    function setCrowdsaleManager(address _mgr) public
        onlyEscrow
    {
        // You can&#39;t change crowdsale contract when migration is in progress.
        require(currentPhase != Phase.Migrating);
        crowdsaleManager = _mgr;
    }

    // internal migrate migration tokens
    function _migrateToken(address _from, address _to)
        internal
    {
        PresaleToken presale = PresaleToken(namiPresale);
        uint256 newToken = presale.balanceOf(_from);
        require(newToken > 0);
        // burn old token
        presale.burnTokens(_from);
        // add new token to _to
        balanceOf[_to] = balanceOf[_to].add(newToken);
        // add new token to totalSupply
        totalSupply = totalSupply.add(newToken);
        emit LogMigrate(_from, _to, newToken);
        emit Transfer(this,_to,newToken);
    }

    // migate token function for Nami Team
    function migrateToken(address _from, address _to) public
        onlyEscrow
    {
        _migrateToken(_from, _to);
    }

    // migrate token for investor
    function migrateForInvestor() public {
        _migrateToken(msg.sender, msg.sender);
    }

    // Nami internal exchange
    
    // event for Nami exchange
    event TransferToBuyer(address indexed _from, address indexed _to, uint _value, address indexed _seller);
    event TransferToExchange(address indexed _from, address indexed _to, uint _value, uint _price);
    
    
    /**
     * @dev Transfer the specified amount of tokens to the NamiExchange address.
     *      Invokes the `tokenFallbackExchange` function.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallbackExchange` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _price price to sell token.
     */
     
    function transferToExchange(address _to, uint _value, uint _price) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackExchange(msg.sender, _value, _price);
            emit TransferToExchange(msg.sender, _to, _value, _price);
        }
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the NamiExchange address.
     *      Invokes the `tokenFallbackBuyer` function.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallbackBuyer` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _buyer address of seller.
     */
     
    function transferToBuyer(address _to, uint _value, address _buyer) public {
        uint codeLength;
        
        assembly {
            codeLength := extcodesize(_to)
        }
        
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallbackBuyer(msg.sender, _value, _buyer);
            emit TransferToBuyer(msg.sender, _to, _value, _buyer);
        }
    }
//-------------------------------------------------------------------------------------------------------
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}




contract NamiTrade{
    using SafeMath for uint256;
    
    uint public minNac = 0; // min NAC deposit
    uint public minWithdraw =  10 * 10**18;
    uint public maxWithdraw = 1000000 * 10**18; // max NAC withdraw one time
    
    constructor(address _escrow, address _namiMultiSigWallet, address _namiAddress) public {
        require(_namiMultiSigWallet != 0x0);
        escrow = _escrow;
        namiMultiSigWallet = _namiMultiSigWallet;
        NamiAddr = _namiAddress; 
    }
    
    
    // balance of pool
    uint public NetfBalance;
    /**
     * NetfRevenueBalance:      NetfRevenue[_roundIndex].currentNAC
     * NlfBalance:              NLFunds[currentRound].currentNAC
     * NlfRevenueBalance:       listSubRoundNLF[currentRound][_subRoundIndex].totalNacInSubRound
     */

    
    // escrow has exclusive priveleges to call administrative
    // functions on this contract.
    address public escrow;

    // Gathered funds can be withdraw only to namimultisigwallet&#39;s address.
    address public namiMultiSigWallet;
    
    /// address of Nami token
    address public NamiAddr;
    
    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }
    
    modifier onlyNami {
        require(msg.sender == NamiAddr);
        _;
    }
    
    modifier onlyNamiMultisig {
        require(msg.sender == namiMultiSigWallet);
        _;
    }
    
    modifier onlyController {
        require(isController[msg.sender] == true);
        _;
    }
    
    
    /*
    *
    * list setting function
    */
    mapping(address => bool) public isController;
    
    
    
    // set controller address
    /**
     * make new controller
     * require input address is not a controller
     * execute any time in sc state
     */
    function setController(address _controller)
        public
        onlyEscrow
    {
        require(!isController[_controller]);
        isController[_controller] = true;
    }
    
    /**
     * remove controller
     * require input address is a controller
     * execute any time in sc state
     */
    function removeController(address _controller)
        public
        onlyEscrow
    {
        require(isController[_controller]);
        isController[_controller] = false;
    }
    
    
    // change minimum nac to deposit
    function changeMinNac(uint _minNAC) public
        onlyEscrow
    {
        require(_minNAC != 0);
        minNac = _minNAC;
    }
    
    // change escrow
    function changeEscrow(address _escrow) public
        onlyNamiMultisig
    {
        require(_escrow != 0x0);
        escrow = _escrow;
    }
    
    
    // min and max for withdraw nac
    function changeMinWithdraw(uint _minWithdraw) public
        onlyEscrow
    {
        require(_minWithdraw != 0);
        minWithdraw = _minWithdraw;
    }
    
    function changeMaxWithdraw(uint _maxNac) public
        onlyEscrow
    {
        require(_maxNac != 0);
        maxWithdraw = _maxNac;
    }
    
    /// @dev withdraw ether to nami multisignature wallet, only escrow can call
    /// @param _amount value ether in wei to withdraw
    function withdrawEther(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
        // Available at any phase.
        if (address(this).balance > 0) {
            namiMultiSigWallet.transfer(_amount);
        }
    }
    
    
    /// @dev withdraw NAC to nami multisignature wallet, only escrow can call
    /// @param _amount value NAC to withdraw
    function withdrawNac(uint _amount) public
        onlyEscrow
    {
        require(namiMultiSigWallet != 0x0);
        // Available at any phase.
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        if (namiToken.balanceOf(address(this)) > 0) {
            namiToken.transfer(namiMultiSigWallet, _amount);
        }
    }
    
    /*
    *
    *
    * List event
    */
    event Deposit(address indexed user, uint amount, uint timeDeposit);
    event Withdraw(address indexed user, uint amount, uint timeWithdraw);
    
    event PlaceBuyFciOrder(address indexed investor, uint amount, uint timePlaceOrder);
    event PlaceSellFciOrder(address indexed investor, uint amount, uint timePlaceOrder);
    event InvestToNLF(address indexed investor, uint amount, uint timeInvest);
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////fci token function///////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    string public name = "Nami Trade";
    string public symbol = "FCI-Test";
    uint8 public decimals = 18;
    
    uint256 public totalSupply;
    
    //  paus phrase to compute ratio fci
    bool public isPause;
    
    // time expires of price fci
    uint256 public timeExpires;
    
    // price fci : if 1 fci = 2 nac => priceFci = 2000000
    uint public fciDecimals = 1000000;
    uint256 public priceFci;
    
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    // This notifies someone buy fci by NAC
    event BuyFci(address investor, uint256 valueNac, uint256 valueFci, uint timeBuyFci);
    event SellFci(address investor, uint256 valueNac, uint256 valueFci, uint timeSellFci);
    
    modifier onlyRunning {
        require(isPause == false);
        _;
    }
    
    
    /**
     * controller update balance of Netf to smart contract
     */
    function addNacToNetf(uint _valueNac) public onlyController {
        NetfBalance = NetfBalance.add(_valueNac);
    }
    
    
    /**
     * controller update balance of Netf to smart contract
     */
    function removeNacFromNetf(uint _valueNac) public onlyController {
        NetfBalance = NetfBalance.sub(_valueNac);
    }
    
    //////////////////////////////////////////////////////buy and sell fci function//////////////////////////////////////////////////////////
    /**
    *  Setup pause phrase
    */
    function changePause() public onlyController {
        isPause = !isPause;
    }
    
    /**
     * 
     * 
     * update price fci daily
     */
     function updatePriceFci(uint _price, uint _timeExpires) onlyController public {
         require(now > timeExpires);
         priceFci = _price;
         timeExpires = _timeExpires;
     }
    
    /**
     * before buy users need to place buy Order
     * function buy fci
     * only controller can execute in phrase running
     */
    function buyFci(address _buyer, uint _valueNac) onlyController public {
        // require fci is Running
        require(isPause == false && now < timeExpires);
        // require buyer not is 0x0 address
        require(_buyer != 0x0);
        require( _valueNac * fciDecimals > priceFci);
        uint fciReceive = (_valueNac.mul(fciDecimals))/priceFci;
        
        // construct fci
        balanceOf[_buyer] = balanceOf[_buyer].add(fciReceive);
        totalSupply = totalSupply.add(fciReceive);
        NetfBalance = NetfBalance.add(_valueNac);
        
        emit Transfer(address(this), _buyer, fciReceive);
        emit BuyFci(_buyer, _valueNac, fciReceive, now);
    }
    
    
    /**
     * 
     * before controller buy fci for user
     * user nead to place sell order
     */
    function placeSellFciOrder(uint _valueFci) onlyRunning public {
        require(balanceOf[msg.sender] >= _valueFci && _valueFci > 0);
        _transfer(msg.sender, address(this), _valueFci);
        emit PlaceSellFciOrder(msg.sender, _valueFci, now);
    }
    
    /**
     * 
     * function sellFci
     * only controller can execute in phare running
     */
    function sellFci(address _seller, uint _valueFci) onlyController public {
        // require fci is Running
        require(isPause == false && now < timeExpires);
        // require buyer not is 0x0 address
        require(_seller != 0x0);
        require(_valueFci * priceFci > fciDecimals);
        uint nacReturn = (_valueFci.mul(priceFci))/fciDecimals;
        
        // destroy fci
        balanceOf[address(this)] = balanceOf[address(this)].sub(_valueFci);
        totalSupply = totalSupply.sub(_valueFci);
        
        // update NETF balance
        NetfBalance = NetfBalance.sub(nacReturn);
        
        // send NAC
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        namiToken.transfer(_seller, nacReturn);
        
        emit Transfer(_seller, address(this), _valueFci);
        emit SellFci(_seller, nacReturn, _valueFci, now);
    }
    
    /////////////////////////////////////////////////////NETF Revenue function///////////////////////////////////////////////////////////////
    struct ShareHolderNETF {
        uint stake;
        bool isWithdrawn;
    }
    
    struct RoundNetfRevenue {
        bool isOpen;
        uint currentNAC;
        uint totalFci;
        bool withdrawable;
    }
    
    uint public currentNetfRound;
    
    mapping (uint => RoundNetfRevenue) public NetfRevenue;
    mapping (uint => mapping(address => ShareHolderNETF)) public usersNETF;
    
    // 1. open Netf round
    /**
     * first controller open one round for netf revenue
     */
    function openNetfRevenueRound(uint _roundIndex) onlyController public {
        require(NetfRevenue[_roundIndex].isOpen == false);
        currentNetfRound = _roundIndex;
        NetfRevenue[_roundIndex].isOpen = true;
    }
    
    /**
     * 
     * this function update balance of NETF revenue funds add NAC to funds
     * only executable if round open and round not withdraw yet
     */
    function depositNetfRevenue(uint _valueNac) onlyController public {
        require(NetfRevenue[currentNetfRound].isOpen == true && NetfRevenue[currentNetfRound].withdrawable == false);
        NetfRevenue[currentNetfRound].currentNAC = NetfRevenue[currentNetfRound].currentNAC.add(_valueNac);
    }
    
    /**
     * 
     * this function update balance of NETF Funds remove NAC from funds
     * only executable if round open and round not withdraw yet
     */
    function withdrawNetfRevenue(uint _valueNac) onlyController public {
        require(NetfRevenue[currentNetfRound].isOpen == true && NetfRevenue[currentNetfRound].withdrawable == false);
        NetfRevenue[currentNetfRound].currentNAC = NetfRevenue[currentNetfRound].currentNAC.sub(_valueNac);
    }
    
    // switch to pause phrase here
    
    /**
     * after pause all investor to buy, sell and exchange fci on the market
     * controller or investor latch final fci of current round
     */
     function latchTotalFci(uint _roundIndex) onlyController public {
         require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
         require(NetfRevenue[_roundIndex].withdrawable == false);
         NetfRevenue[_roundIndex].totalFci = totalSupply;
     }
     
     function latchFciUserController(uint _roundIndex, address _investor) onlyController public {
         require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
         require(NetfRevenue[_roundIndex].withdrawable == false);
         require(balanceOf[_investor] > 0);
         usersNETF[_roundIndex][_investor].stake = balanceOf[_investor];
     }
     
     /**
      * investor can latch Fci by themself
      */
     function latchFciUser(uint _roundIndex) public {
         require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
         require(NetfRevenue[_roundIndex].withdrawable == false);
         require(balanceOf[msg.sender] > 0);
         usersNETF[_roundIndex][msg.sender].stake = balanceOf[msg.sender];
     }
     
     /**
      * after all investor latch fci, controller change round state withdrawable
      * now investor can withdraw NAC from NetfRevenue funds of this round
      * and auto switch to unpause phrase
      */
     function changeWithdrawableNetfRe(uint _roundIndex) onlyController public {
         require(isPause == true && NetfRevenue[_roundIndex].isOpen == true);
         NetfRevenue[_roundIndex].withdrawable = true;
         isPause = false;
     }
     
     // after latch all investor, unpause here
     /**
      * withdraw NAC for 
      * run by controller
      */
     function withdrawNacNetfReController(uint _roundIndex, address _investor) onlyController public {
         require(NetfRevenue[_roundIndex].withdrawable == true && isPause == false && _investor != 0x0);
         require(usersNETF[_roundIndex][_investor].stake > 0 && usersNETF[_roundIndex][_investor].isWithdrawn == false);
         require(NetfRevenue[_roundIndex].totalFci > 0);
         // withdraw NAC
         uint nacReturn = ( NetfRevenue[_roundIndex].currentNAC.mul(usersNETF[_roundIndex][_investor].stake) ) / NetfRevenue[_roundIndex].totalFci;
         NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
         namiToken.transfer(_investor, nacReturn);
         
         usersNETF[_roundIndex][_investor].isWithdrawn = true;
     }
     
     /**
      * withdraw NAC for 
      * run by investor
      */
     function withdrawNacNetfRe(uint _roundIndex) public {
         require(NetfRevenue[_roundIndex].withdrawable == true && isPause == false);
         require(usersNETF[_roundIndex][msg.sender].stake > 0 && usersNETF[_roundIndex][msg.sender].isWithdrawn == false);
         require(NetfRevenue[_roundIndex].totalFci > 0);
         // withdraw NAC
         uint nacReturn = ( NetfRevenue[_roundIndex].currentNAC.mul(usersNETF[_roundIndex][msg.sender].stake) ) / NetfRevenue[_roundIndex].totalFci;
         NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
         namiToken.transfer(msg.sender, nacReturn);
         
         usersNETF[_roundIndex][msg.sender].isWithdrawn = true;
     }
    
    /////////////////////////////////////////////////////token fci function//////////////////////////////////////////////////////////////////
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public onlyRunning {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyRunning returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public onlyRunning
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public onlyRunning
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////end fci token function///////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////pool function////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    uint public currentRound = 1;
    uint public currentSubRound = 1;
    
    struct shareHolderNLF {
        uint fciNLF;
        bool isWithdrawnRound;
    }
    
    struct SubRound {
        uint totalNacInSubRound;
        bool isOpen;
        bool isCloseNacPool;
    }
    
    struct Round {
        bool isOpen;
        bool isActivePool;
        bool withdrawable;
        uint currentNAC;
        uint finalNAC;
    }
    
    // NLF Funds
    mapping(uint => Round) public NLFunds;
    mapping(uint => mapping(address => mapping(uint => bool))) public isWithdrawnSubRoundNLF;
    mapping(uint => mapping(uint => SubRound)) public listSubRoundNLF;
    mapping(uint => mapping(address => shareHolderNLF)) public membersNLF;
    
    
    event ActivateRound(uint RoundIndex, uint TimeActive);
    event ActivateSubRound(uint RoundIndex, uint TimeActive);
    // ------------------------------------------------ 
    /**
     * Admin function
     * Open and Close Round
     */
    function activateRound(uint _roundIndex)
        onlyEscrow
        public
    {
        // require round not open
        require(NLFunds[_roundIndex].isOpen == false);
        NLFunds[_roundIndex].isOpen = true;
        currentRound = _roundIndex;
        emit ActivateRound(_roundIndex, now);
    }
    
    ///////////////////////deposit to NLF funds in tokenFallbackExchange///////////////////////////////
    /**
     * after all user deposit to NLF pool
     */
    function deactivateRound(uint _roundIndex)
        onlyEscrow
        public
    {
        // require round id is openning
        require(NLFunds[_roundIndex].isOpen == true);
        NLFunds[_roundIndex].isActivePool = true;
        NLFunds[_roundIndex].isOpen = false;
        NLFunds[_roundIndex].finalNAC = NLFunds[_roundIndex].currentNAC;
    }
    
    /**
     * before send NAC to subround controller need active subround
     */
    function activateSubRound(uint _subRoundIndex)
        onlyController
        public
    {
        // require current round is not open and pool active
        require(NLFunds[currentRound].isOpen == false && NLFunds[currentRound].isActivePool == true);
        // require sub round not open
        require(listSubRoundNLF[currentRound][_subRoundIndex].isOpen == false);
        //
        currentSubRound = _subRoundIndex;
        require(listSubRoundNLF[currentRound][_subRoundIndex].isCloseNacPool == false);
        
        listSubRoundNLF[currentRound][_subRoundIndex].isOpen = true;
        emit ActivateSubRound(_subRoundIndex, now);
    }
    
    
    /**
     * every week controller deposit to subround to send NAC to all user have NLF fci
     */
    function depositToSubRound(uint _value)
        onlyController
        public
    {
        // require sub round is openning
        require(currentSubRound != 0);
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);
        
        // modify total NAC in each subround
        listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound = listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound.add(_value);
    }
    
    
    /**
     * every week controller deposit to subround to send NAC to all user have NLF fci
     */
    function withdrawFromSubRound(uint _value)
        onlyController
        public
    {
        // require sub round is openning
        require(currentSubRound != 0);
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);
        
        // modify total NAC in each subround
        listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound = listSubRoundNLF[currentRound][currentSubRound].totalNacInSubRound.sub(_value);
    }
    
    
    /**
     * controller close deposit subround phrase and user can withdraw NAC from subround
     */
    function closeDepositSubRound()
        onlyController
        public
    {
        require(listSubRoundNLF[currentRound][currentSubRound].isOpen == true);
        require(listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool == false);
        
        listSubRoundNLF[currentRound][currentSubRound].isCloseNacPool = true;
    }
    
    
    /**
     * user withdraw NAC from each subround of NLF funds for investor
     */
    function withdrawSubRound(uint _subRoundIndex) public {
        // require close deposit to subround
        require(listSubRoundNLF[currentRound][_subRoundIndex].isCloseNacPool == true);
        
        // user not ever withdraw nac in this subround
        require(isWithdrawnSubRoundNLF[currentRound][msg.sender][_subRoundIndex] == false);
        
        // require user have fci
        require(membersNLF[currentRound][msg.sender].fciNLF > 0);
        
        // withdraw token
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        
        uint nacReturn = (listSubRoundNLF[currentRound][_subRoundIndex].totalNacInSubRound.mul(membersNLF[currentRound][msg.sender].fciNLF)).div(NLFunds[currentRound].finalNAC);
        namiToken.transfer(msg.sender, nacReturn);
        
        isWithdrawnSubRoundNLF[currentRound][msg.sender][_subRoundIndex] = true;
    }
    
    
    /**
     * controller of NLF add NAC to update NLF balance
     * this NAC come from 10% trading revenue
     */
    function addNacToNLF(uint _value) public onlyController {
        require(NLFunds[currentRound].isActivePool == true);
        require(NLFunds[currentRound].withdrawable == false);
        
        NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.add(_value);
    }
    
    /**
     * controller get NAC from NLF pool to send to trader
     */
    
    function removeNacFromNLF(uint _value) public onlyController {
        require(NLFunds[currentRound].isActivePool == true);
        require(NLFunds[currentRound].withdrawable == false);
        
        NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.sub(_value);
    }
    
    /**
     * end of round escrow run this to allow user sell fci to receive NAC
     */
    function changeWithdrawableRound(uint _roundIndex)
        public
        onlyEscrow
    {
        require(NLFunds[currentRound].isActivePool == true);
        require(NLFunds[_roundIndex].withdrawable == false && NLFunds[_roundIndex].isOpen == false);
        
        NLFunds[_roundIndex].withdrawable = true;
    }
    
    
    /**
     * end of round user sell fci to receive NAC from NLF funds
     * function for investor
     */
    function withdrawRound(uint _roundIndex) public {
        require(NLFunds[_roundIndex].withdrawable == true);
        require(membersNLF[currentRound][msg.sender].isWithdrawnRound == false);
        require(membersNLF[currentRound][msg.sender].fciNLF > 0);
        
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint nacReturn = NLFunds[currentRound].currentNAC.mul(membersNLF[currentRound][msg.sender].fciNLF).div(NLFunds[currentRound].finalNAC);
        namiToken.transfer(msg.sender, nacReturn);
        
        // update status round
        membersNLF[currentRound][msg.sender].isWithdrawnRound = true;
        membersNLF[currentRound][msg.sender].fciNLF = 0;
    }
    
    function withdrawRoundController(uint _roundIndex, address _investor) public onlyController {
        require(NLFunds[_roundIndex].withdrawable == true);
        require(membersNLF[currentRound][_investor].isWithdrawnRound == false);
        require(membersNLF[currentRound][_investor].fciNLF > 0);
        
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        uint nacReturn = NLFunds[currentRound].currentNAC.mul(membersNLF[currentRound][_investor].fciNLF).div(NLFunds[currentRound].finalNAC);
        namiToken.transfer(msg.sender, nacReturn);
        
        // update status round
        membersNLF[currentRound][_investor].isWithdrawnRound = true;
        membersNLF[currentRound][_investor].fciNLF = 0;
    }
    
    
    
    /**
     * fall back function call from nami crawsale smart contract
     * deposit NAC to NAMI TRADE broker, invest to NETF and NLF funds
     */
    function tokenFallbackExchange(address _from, uint _value, uint _choose) onlyNami public returns (bool success) {
        require(_choose <= 2);
        if (_choose == 0) {
            // deposit NAC to nami trade broker
            require(_value >= minNac);
            emit Deposit(_from, _value, now);
        } else if(_choose == 1) {
            require(_value >= minNac && NLFunds[currentRound].isOpen == true);
            // invest to NLF funds
            membersNLF[currentRound][_from].fciNLF = membersNLF[currentRound][_from].fciNLF.add(_value);
            NLFunds[currentRound].currentNAC = NLFunds[currentRound].currentNAC.add(_value);
            
            emit InvestToNLF(_from, _value, now);
        } else if(_choose == 2) {
            // invest NAC to NETF Funds
            require(_value >= minNac); // msg.value >= 0.1 ether
            emit PlaceBuyFciOrder(_from, _value, now);
        }
        return true;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////end pool function///////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // withdraw token
    function withdrawToken(address _account, uint _amount)
        public
        onlyController
    {
        require(_amount >= minWithdraw && _amount <= maxWithdraw);
        NamiCrowdSale namiToken = NamiCrowdSale(NamiAddr);
        
        uint previousBalances = namiToken.balanceOf(address(this));
        require(previousBalances >= _amount);
        
        // transfer token
        namiToken.transfer(_account, _amount);
        
        // emit event
        emit Withdraw(_account, _amount, now);
        assert(previousBalances >= namiToken.balanceOf(address(this)));
    }
    
    
}