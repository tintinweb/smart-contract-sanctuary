pragma solidity 0.6.4;

import "./IERC20.sol";

interface aaRouter{
    function setHXYAddress(address _hxyAddress) external;
    
    function setHXBAddress(address _hxbAddress) external;
    
    function setHXPAddress(address _hxpAddress) external;
    
    function setSplitter(address _splitter) external;
    
    function setRatios(uint _hxy, uint _hxb, uint _hxp) external;
    
    function unlockHxp() external;
    
}


/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract MultiSigWallet {
    
    //uniswap setup
    address public routerAddress = address(0xc1154C084E19cD21002DB3ff5dAF0B4E18f949a2);
    aaRouter internal aaRouterInterface = aaRouter(routerAddress);
    //constants
    uint constant public MAX_OWNER_COUNT = 8;
    //events
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
    //mappings
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    //data
    address[] public owners;
    uint public required;
    uint public transactionCount;

    struct Transaction {
        address payable destination;
        uint inputValue;
        uint functionCall;
        address tokenAddress;
        uint hxyMint;
        uint hxbMint;
        uint hxpMint;
        bool executed;
    }
    //modifiers
    modifier onlyWallet() {
        if (msg.sender != address(this))
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
        if (transactions[transactionId].destination == address(0))
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
        if (_address == address(0))
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
    receive()
        external
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == address(0))
                revert();
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
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.pop();
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
    /// @param inputValue value to send as input
    /// @param callTo define function to call as uint
    /// @param tokenAddress use when sending tokens directly as desired token to send
    /// @return transactionId Returns transactionId.
    function submitTransaction(address payable destination, uint inputValue, uint callTo, address tokenAddress, uint hxyMint, uint hxbMint, uint hxpMint)
        public
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, inputValue, callTo, tokenAddress, hxyMint, hxbMint, hxpMint);
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
        uint callTo = transactions[transactionId].functionCall;
        if(callTo == 0){
            sendEth(transactionId);
        }
        else if(callTo == 1)
        {
            sendToken(transactionId);
        }
        else if(callTo == 2)
        {
            setHxyAddress(transactionId);
        }
        else if(callTo == 3)
        {
            setHxbAddress(transactionId);
        }
        else if(callTo == 4)
        {
            setHxpAddress(transactionId);
        }
        else if(callTo == 5)
        {
            setSplitterAddress(transactionId);
        }
        else if(callTo == 6)
        {
            setMintRatios(transactionId);
        }
        else if(callTo == 7)
        {
            setHxpUnlock(transactionId);
        }
        else{
            revert();
        }
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
    
    //sends inputValue as ETH to destination
    function sendEth(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
            require(address(this).balance >= _tx.inputValue, "eth balance too low");
             _tx.destination.transfer(_tx.inputValue);
            emit Execution(transactionId);
        }
    }
    
    //sends inputValue as tokenAddress amount to destination
    function sendToken(uint transactionId)
        public
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
            address _token = _tx.tokenAddress;
            require(IERC20(_token).balanceOf(address(this)) >= _tx.inputValue, "hex balance too low");
             IERC20(_token).transfer(_tx.destination, _tx.inputValue);
            emit Execution(transactionId);
        }
    }

    //sets aaRouter HXY address as destination
    function setHxyAddress(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.setHXYAddress(_tx.destination);
        }
    }
    
    //sets aaRouter HXB address as destination
    function setHxbAddress(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.setHXBAddress(_tx.destination);
        }
    }
    
    //sets aaRouter HXP address as destination
    function setHxpAddress(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.setHXPAddress(_tx.destination);
        }
    }
    
   //sets aaRouter SPLITTER address as destination
    function setSplitterAddress(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.setSplitter(_tx.destination);
        }
    }
    
    //sets aaRouter mintRatios address as inputValues
    function setMintRatios(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.setRatios(_tx.hxyMint, _tx.hxbMint, _tx.hxpMint);
        }
    }
    
    //sets hxp unlockable from contract
    function setHxpUnlock(uint transactionId)
    public
    notExecuted(transactionId)
    {
        if(isConfirmed(transactionId)){
            Transaction memory _tx = transactions[transactionId];
            _tx.executed = true;
           aaRouterInterface.unlockHxp();
        }
    }
    
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId)
        public
        view
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
    /// @param inputValue  to add as input
    /// @return transactionId Returns transaction ID.
    function addTransaction(address payable destination, uint inputValue, uint functionCall, address tokenAddress, uint hxyMint, uint hxbMint, uint hxpMint)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            inputValue: inputValue,
            functionCall: functionCall,
            tokenAddress: tokenAddress,
            hxyMint: hxyMint,
            hxbMint: hxbMint,
            hxpMint: hxpMint,
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
    /// @return count Number of confirmations.
    function getConfirmationCount(uint transactionId)
        public
        view
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return count Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed)
        public
        view
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
        view
        returns (address[]memory)
    {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @return _confirmations Returns array of owner addresses.
    function getConfirmations(uint transactionId)
        public
        view
        returns (address[] memory _confirmations)
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
    /// @return _transactionIds Returns array of transaction IDs.
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        view
        returns (uint[] memory _transactionIds)
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

 