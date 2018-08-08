pragma solidity ^0.4.18;

contract IToken {
    function executeSettingsChange(
        uint amount, 
        uint partInvestor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partInvestorIncreasePerStage,
        uint maxStages
    );
}


contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    address owner; //the one who creates the contract, only this person can set the token
    uint public required;
    uint public transactionCount;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
   
    IToken public token;

    struct SettingsRequest {
        uint amount;
        uint partInvestor;
        uint partProject;
        uint partFounders;
        uint blocksPerStage;
        uint partInvestorIncreasePerStage;
        uint maxStages;
        bool executed;
        mapping(address => bool) confirmations;
    }

    uint settingsRequestsCount = 0;
    mapping(uint => SettingsRequest) settingsRequests;

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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier ownerDoesNotExist(address _owner) {
        require(!isOwner[_owner]);
        _;
    }
    
    modifier ownerExists(address _owner) {
        require(isOwner[_owner]);
        _;
    }

    modifier transactionExists(uint _transactionId) {
        require(transactions[_transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint _transactionId, address _owner) {
        require(confirmations[_transactionId][_owner]);
        _;
    }

    modifier notConfirmed(uint _transactionId, address _owner) {
        require(!confirmations[_transactionId][_owner]);
        _;
    }

    modifier notExecuted(uint _transactionId) {
        require(!transactions[_transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount < MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    function MultiSigWallet(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        owner = msg.sender;
    }

    function setToken(address _token) public onlyOwner {
        require(token == address(0));
        token = IToken(_token);
    }

    //---------------- TGE SETTINGS -----------
    /// @dev Sends request to change settings
    /// @return Transaction ID
    function tgeSettingsChangeRequest(
        uint amount, 
        uint partInvestor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partInvestorIncreasePerStage,
        uint maxStages
    ) 
    public
    ownerExists(msg.sender)
    returns (uint _txIndex) 
    {
        assert(amount*partInvestor*partProject*blocksPerStage*partInvestorIncreasePerStage*maxStages != 0); //asserting no parameter is zero except partFounders
        _txIndex = settingsRequestsCount;
        settingsRequests[_txIndex] = SettingsRequest({
            amount: amount,
            partInvestor: partInvestor,
            partProject: partProject,
            partFounders: partFounders,
            blocksPerStage: blocksPerStage,
            partInvestorIncreasePerStage: partInvestorIncreasePerStage,
            maxStages: maxStages,
            executed: false
        });
        settingsRequestsCount++;
        confirmSettingsChange(_txIndex);
        return _txIndex;
    }

    /// @dev Allows an owner to confirm a change settings request.
    /// @param _txIndex Transaction ID.
    function confirmSettingsChange(uint _txIndex) public ownerExists(msg.sender) returns(bool success) {
        require(settingsRequests[_txIndex].executed == false);
        settingsRequests[_txIndex].confirmations[msg.sender] = true;
        if(isConfirmedSettingsRequest(_txIndex)){
            SettingsRequest storage request = settingsRequests[_txIndex];
            request.executed = true;
            IToken(token).executeSettingsChange(
                request.amount, 
                request.partInvestor,
                request.partProject,
                request.partFounders,
                request.blocksPerStage,
                request.partInvestorIncreasePerStage,
                request.maxStages
            );
            return true;
        } else {
            return false;
        }
    }

    function isConfirmedSettingsRequest(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (settingsRequests[transactionId].confirmations[owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    function getSettingsChangeConfirmationCount(uint _txIndex) public view returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (settingsRequests[_txIndex].confirmations[owners[i]])
                count += 1;
    }

    /// @dev Shows what settings were requested in a settings change request
    function viewSettingsChange(uint _txIndex) public constant 
    returns (uint amount, uint partInvestor, uint partProject, uint partFounders, uint blocksPerStage, uint partInvestorIncreasePerStage, uint maxStages) {
        SettingsRequest memory request = settingsRequests[_txIndex];
        return (
            request.amount,
            request.partInvestor, 
            request.partProject,
            request.partFounders,
            request.blocksPerStage,
            request.partInvestorIncreasePerStage,
            request.maxStages
        );
    }

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of new owner.
    function addOwner(address _owner)
        public
        onlyWallet
        ownerDoesNotExist(_owner)
        notNull(_owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(_owner);
        OwnerAddition(_owner);
    }
    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner.
    function removeOwner(address _owner)
        public
        onlyWallet
        ownerExists(_owner)
    {
        isOwner[_owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(_owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner to be replaced.
    /// @param _newOwner Address of new owner.
    function replaceOwner(address _owner, address _newOwner)
        public
        onlyWallet
        ownerExists(_owner)
        ownerDoesNotExist(_newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        OwnerRemoval(_owner);
        OwnerAddition(_newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        RequirementChange(_required);
    }

    function setFinishedTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"64f65cc0");
        confirmTransaction(transactionId);
    }

    function setLiveTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"9d0714b2");
        confirmTransaction(transactionId);
    }

    function setFreezeTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"2c8cbe40");
        confirmTransaction(transactionId);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data) public
        ownerExists(msg.sender)
        notNull(destination)
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
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint _transactionId) public notExecuted(_transactionId) {
        if (isConfirmed(_transactionId)) {
            Transaction storage trx = transactions[_transactionId];
            trx.executed = true;
            if (trx.destination.call.value(trx.value)(trx.data))
                Execution(_transactionId);
            else {
                ExecutionFailure(_transactionId);
                trx.executed = false;
            }
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

    /*
     * Internal functions
     */

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes data) internal returns (uint transactionId) {
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
    function getConfirmationCount(uint transactionId) public constant returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed) public constant returns (uint count) {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public constant returns (address[]) {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint transactionId) public constant returns (address[] _confirmations) {
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
    function getTransactionIds(uint from, uint to, bool pending, bool executed) public constant returns (uint[] _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=from; i<transactionCount; i++)
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