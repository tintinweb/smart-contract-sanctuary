//This file contains a multisignature wallet contract that is used to control the eRAY token contract:
// - to set the settings of token generation round
// - to start and to stop token generation round
// - to freeze the token upon creation of array.io blockchain
// - to send eRAY tokens from this wallet
// - to make arbitrary transaction in usual to multisignature wallet way

// Elsewhere in other contracts or documentation this contract MAY be referenced as projectWallet

// Authors: Alexander Shevtsov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3b495a555f545657545c52550c0d7b5c565a525715585456">[email&#160;protected]</a>>
//          Vladimir Bobrov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ddab9db9b8beb8b3a9a8afa4baafb2a8adf3beb2b0">[email&#160;protected]</a>>
//          vladiuz1 <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3b4d487b5a49495a42155254">[email&#160;protected]</a>>
// License: see the repository file
// Last updated: 12 August 2018
pragma solidity ^0.4.22;

//Interface for the token contract
contract IToken {
    
    address public whitelist;

    function executeSettingsChange(
        uint amount, 
        uint minimalContribution, 
        uint partContributor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partContributorIncreasePerStage,
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
        uint minimalContribution;
        uint partContributor;
        uint partProject;
        uint partFounders;
        uint blocksPerStage;
        uint partContributorIncreasePerStage;
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

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(_ownerCount < MAX_OWNER_COUNT
            && _required <= _ownerCount
            && _required != 0
            && _ownerCount != 0);
        _;
    }

    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        owner = msg.sender;
    }

    /// @dev Fallback function allows to deposit ether.
    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function setToken(address _token) public onlyOwner {
        require(token == address(0));
        token = IToken(_token);
    }

    //---------------- TGR SETTINGS -----------
    /// @dev Sends request to change settings
    /// @return Transaction ID
    function tgrSettingsChangeRequest(
        uint amount, 
        uint minimalContribution,
        uint partContributor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partContributorIncreasePerStage,
        uint maxStages
    ) 
    public
    ownerExists(msg.sender)
    returns (uint _txIndex) 
    {
        assert(amount*partContributor*partProject*blocksPerStage*partContributorIncreasePerStage*maxStages != 0); //asserting no parameter is zero except partFounders
        assert(amount >= 1 ether);
        _txIndex = settingsRequestsCount;
        settingsRequests[_txIndex] = SettingsRequest({
            amount: amount,
            minimalContribution: minimalContribution,
            partContributor: partContributor,
            partProject: partProject,
            partFounders: partFounders,
            blocksPerStage: blocksPerStage,
            partContributorIncreasePerStage: partContributorIncreasePerStage,
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
                request.minimalContribution, 
                request.partContributor,
                request.partProject,
                request.partFounders,
                request.blocksPerStage,
                request.partContributorIncreasePerStage,
                request.maxStages
            );
            return true;
        } else {
            return false;
        }
    }

    function setFinishedTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"ce5e6393");
        confirmTransaction(transactionId);
    }

    function setLiveTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"29745306");
        confirmTransaction(transactionId);
    }

    function setFreezeTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"2c8cbe40");
        confirmTransaction(transactionId);
    }

    function transferTx(address _to, uint _value) public ownerExists(msg.sender) returns(uint transactionId) {
        //I rather seldom wish pain to other people, but solidity developers may be an exception.
        bytes memory calldata = new bytes(68); 
        calldata[0] = byte(hex"a9");
        calldata[1] = byte(hex"05");
        calldata[2] = byte(hex"9c");
        calldata[3] = byte(hex"bb");
        //When I wrote these lines my eyes were bleeding.
        bytes32 val = bytes32(_value);
        bytes32 dest = bytes32(_to);
        //I spent a day for this function, because my fingers made a fist.
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
        //Oh, reader! I hope you forget it like a bad nightmare.
        for(uint i=0; i<32; i++) {
            calldata[i+36]=val[i];
        }
        //Stil the ghost of this code will haunt you.
        transactionId = addTransaction(token, 0, calldata);
        confirmTransaction(transactionId);
        //I haven&#39;t mentioned that it&#39;s the most elegant solution for 0.4.20 compiler, which doesn&#39;t require rewriting all this shitty code.
        //Enjoy.
    }

    function setWhitelistTx(address _whitelist) public ownerExists(msg.sender) returns(uint transactionId) {
        bytes memory calldata = new bytes(36);
        calldata[0] = byte(hex"85");
        calldata[1] = byte(hex"4c");
        calldata[2] = byte(hex"ff");
        calldata[3] = byte(hex"2f");
        bytes32 dest = bytes32(_whitelist);
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
        transactionId = addTransaction(token, 0, calldata);
        confirmTransaction(transactionId);
    }

    //adds this address to the whitelist
    function whitelistTx(address _address) public ownerExists(msg.sender) returns(uint transactionId) {
        bytes memory calldata = new bytes(36);
        calldata[0] = byte(hex"0a");
        calldata[1] = byte(hex"3b");
        calldata[2] = byte(hex"0a");
        calldata[3] = byte(hex"4f");
        bytes32 dest = bytes32(_address);
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
        transactionId = addTransaction(token.whitelist(), 0, calldata);
        confirmTransaction(transactionId);

    }

//--------------------------Usual multisig functions for handling owners and transactions.

    /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of new owner.
    function addOwner(address _owner) public onlyWallet ownerDoesNotExist(_owner) notNull(_owner) validRequirement(owners.length + 1, required) {
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAddition(_owner);
    }
    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner.
    function removeOwner(address _owner) public onlyWallet ownerExists(_owner) {
        isOwner[_owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(_owner);
    }

    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
    /// @param _owner Address of owner to be replaced.
    /// @param _newOwner Address of new owner.
    function replaceOwner(address _owner, address _newOwner) public onlyWallet ownerExists(_owner) ownerDoesNotExist(_newOwner) {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
    }

    /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
    /// @param _required Number of required confirmations.
    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes data) public ownerExists(msg.sender) notNull(destination) returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

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
        emit Submission(transactionId);
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param _transactionId Transaction ID.
    function confirmTransaction(uint _transactionId) public ownerExists(msg.sender) transactionExists(_transactionId) notConfirmed(_transactionId, msg.sender) {
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
        executeTransaction(_transactionId);
    }

    //Will fail if calldata less than 4 bytes long. It&#39;s a feature, not a bug.
    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param _transactionId Transaction ID.
    function executeTransaction(uint _transactionId) public notExecuted(_transactionId) {
        if (isConfirmed(_transactionId)) {
            Transaction storage trx = transactions[_transactionId];
            trx.executed = true;
            //Just don&#39;t ask questions. It&#39;s needed. Believe me.
			bytes memory data = trx.data;
            bytes memory calldata;
            if (trx.data.length >= 4) {
                bytes4 signature;
                assembly {
                    signature := mload(add(data, 32))
                }
                calldata = new bytes(trx.data.length-4);
                for (uint i = 0; i<calldata.length; i++) {
                    calldata[i] = trx.data[i+4];
                }
            }
            else {
                calldata = new bytes(0);
            }
            if (trx.destination.call.value(trx.value)(signature, calldata))
                emit Execution(_transactionId);
            else {
                emit ExecutionFailure(_transactionId);
                trx.executed = false;
            }
        }
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param _transactionId Transaction ID.
    function revokeConfirmation(uint _transactionId) public ownerExists(msg.sender) confirmed(_transactionId, msg.sender) notExecuted(_transactionId) {
        confirmations[_transactionId][msg.sender] = false;
        emit Revocation(msg.sender, _transactionId);
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint _transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[_transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

	function isConfirmedSettingsRequest(uint _transactionId) public view returns (bool) {
		uint count = 0;
		for (uint i = 0; i < owners.length; i++) {
			if (settingsRequests[_transactionId].confirmations[owners[i]])
				count += 1;
			if (count == required)
				return true;
		}
		return false;
    }

    /// @dev Shows what settings were requested in a settings change request
    function viewSettingsChange(uint _txIndex) public constant 
    returns (uint amount, uint minimalContribution, uint partContributor, uint partProject, uint partFounders, uint blocksPerStage, uint partContributorIncreasePerStage, uint maxStages) {
        SettingsRequest memory request = settingsRequests[_txIndex];
        return (
            request.amount,
            request.minimalContribution,
            request.partContributor, 
            request.partProject,
            request.partFounders,
            request.blocksPerStage,
            request.partContributorIncreasePerStage,
            request.maxStages
        );
    }

    /// @dev Returns number of confirmations of a transaction.
    /// @param _transactionId Transaction ID.
    /// @return Number of confirmations.
    function getConfirmationCount(uint _transactionId) public view returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[_transactionId][owners[i]])
                count += 1;
    }

    function getSettingsChangeConfirmationCount(uint _txIndex) public view returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (settingsRequests[_txIndex].confirmations[owners[i]])
                count += 1;
    }

    /// @dev Returns total number of transactions after filers are applied.
    /// @param pending Include pending transactions.
    /// @param executed Include executed transactions.
    /// @return Total number of transactions after filters are applied.
    function getTransactionCount(bool pending, bool executed) public view returns (uint count) {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public view returns (address[]) {
        return owners;
    }

    /// @dev Returns array with owner addresses, which confirmed transaction.
    /// @param _transactionId Transaction ID.
    /// @return Returns array of owner addresses.
    function getConfirmations(uint _transactionId) public view returns (address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[_transactionId][owners[i]]) {
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
    function getTransactionIds(uint from, uint to, bool pending, bool executed) public view returns (uint[] _transactionIds) {
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