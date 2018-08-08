pragma solidity 0.4.23;

contract ZethrBankroll {
    using SafeMath for uint;

    uint constant public MAX_OWNER_COUNT = 10;
    uint constant public MAX_WITHDRAW_PCT_DAILY = 15;
    uint constant public MAX_WITHDRAW_PCT_TX = 5;
    
    uint constant internal resetTimer = 1 days; 

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event WhiteListAddition(address indexed contractAddress);
    event WhiteListRemoval(address indexed contractAddress);
    event RequirementChange(uint required);
    event DevWithdraw(uint amountTotal, uint amountPerPerson);

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isWhitelisted;
    address[] public owners;
    address[] public whiteListedContracts;
    uint public required;
    uint public transactionCount;
    uint internal dailyResetTime;
    uint internal dailyLimit;
    uint internal ethDispensedToday;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }
    
    modifier onlyWhiteListedContract() {
        if (!isWhitelisted[msg.sender])
            revert();
        _;
    }
    
    modifier contractIsNotWhiteListed(address contractAddress) {
        if (isWhitelisted[contractAddress])
            revert();
        _;
    }
    
    modifier contractIsWhiteListed(address contractAddress) {
        if (!isWhitelisted[contractAddress])
            revert();
        _;
    }
    
    modifier isAnOwner() {
        address caller = msg.sender;
        if (!isOwner[caller])
            revert();
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert();
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert();
        _;
    }

    modifier transactionExists(uint transactionId) {
        if (transactions[transactionId].destination == 0)
            revert();
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert();
        _;
    }

    modifier notExecuted(uint transactionId) {
        if (transactions[transactionId].executed)
            revert();
        _;
    }

    modifier notNull(address _address) {
        if (_address == 0)
            revert();
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   ownerCount > MAX_OWNER_COUNT
            || _required > ownerCount
            || _required == 0
            || ownerCount == 0)
            revert();
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function()
        public
        payable
    {
        
    }
    
    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor (address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == 0)
                revert();
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        
        dailyResetTime = now;
    }


    /// @dev Calculates if an amount of Ether exceeds the aggregate daily limit of 15% of contract
    ///        balance or 5% of the contract balance on its own.
    function permissibleWithdrawal(uint _toWithdraw)
        public
        onlyWallet
        returns(bool)
    {
        uint currentTime     = now;
        uint contractBalance = address(this).balance;
        uint maxPerTx        = (contractBalance.mul(MAX_WITHDRAW_PCT_TX)).div(100);
        
        require (_toWithdraw <= maxPerTx);
        
        if (currentTime - dailyResetTime >= resetTimer)
            {
                dailyResetTime    = currentTime;
                dailyLimit        = (contractBalance.mul(MAX_WITHDRAW_PCT_DAILY)).div(100);
                ethDispensedToday = _toWithdraw;
                return true;
            }
        else 
            {
                if (ethDispensedToday.add(_toWithdraw) <= dailyLimit)
                    {
                        ethDispensedToday += _toWithdraw;
                        return true;
                    }
                else { return false; }
            }
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
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
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
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
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
            Transaction storage txToExecute = transactions[transactionId];
            txToExecute.executed = true;
            if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txToExecute.executed = false;
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

    // Additions for Bankroll
    function whiteListContract(address contractAddress)
        public
        onlyWallet
        contractIsNotWhiteListed(contractAddress)
        notNull(contractAddress)
    {
        isWhitelisted[contractAddress] = true;
        whiteListedContracts.push(contractAddress);
        emit WhiteListAddition(contractAddress);
    }
    
    // Remove a whitelisted contract. This is an exception to the norm in that
    // it can be invoked directly by any owner, in the event that a game is found
    // to be bugged or otherwise faulty, so it can be shut down as an emergency measure.
    // Iterates through the whitelisted contracts to find contractAddress,
    //  then swaps it with the last address in the list - then decrements length
    function deWhiteListContract(address contractAddress)
        public
        isAnOwner
        contractIsWhiteListed(contractAddress)
    {
        isWhitelisted[contractAddress] = false;
        for (uint i=0; i<whiteListedContracts.length - 1; i++)
            if (whiteListedContracts[i] == contractAddress) {
                whiteListedContracts[i] = owners[whiteListedContracts.length - 1];
                break;
            }
            
        whiteListedContracts.length -= 1;
        
        emit WhiteListRemoval(contractAddress);
    }
    
    // Legit sweaty palms when writing this
    // AUDIT AUDIT AUDIT
    // Should withdraw "amount" to whitelisted contracts only!
    // Should block withdraws greater than MAX_WITHDRAW_PCT_TX of balance.
    function contractWithdraw(uint amount) public 
        onlyWhiteListedContract
    {
        // Make sure amount is <= balance*MAX_WITHDRAW_PCT_TX
        require(permissibleWithdrawal(amount));
        
        msg.sender.transfer(amount);
    }
    
    // Dev withdraw - splits equally among all owners of contract
    function devWithdraw(uint amount) public
        onlyWallet
    {
        require(permissibleWithdrawal(amount));        
        
        uint amountPerPerson = SafeMath.div(amount, owners.length);
        
        for (uint i=0; i<owners.length; i++) {
            owners[i].transfer(amountPerPerson);
        }
        
        emit DevWithdraw(amount, amountPerPerson);
    }
    
    // Receive dividends from Zethr and buy back in 

    function receiveDividends() public payable {
        Zethr(msg.sender).buy.value(msg.value)(address(0x0));
    }


    // Convert an hexadecimal character to their value
    function fromHexChar(uint c) public pure returns (uint) {
        if (byte(c) >= byte(&#39;0&#39;) && byte(c) <= byte(&#39;9&#39;)) {
            return c - uint(byte(&#39;0&#39;));
        }
        if (byte(c) >= byte(&#39;a&#39;) && byte(c) <= byte(&#39;f&#39;)) {
            return 10 + c - uint(byte(&#39;a&#39;));
        }
        if (byte(c) >= byte(&#39;A&#39;) && byte(c) <= byte(&#39;F&#39;)) {
            return 10 + c - uint(byte(&#39;A&#39;));
        }
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string s) public pure returns (bytes) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = byte(fromHexChar(uint(ss[2*i])) * 16 +
                    fromHexChar(uint(ss[2*i+1])));
        }
        return r;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Zethr{
        function buy(address)
        public
        payable {}
}