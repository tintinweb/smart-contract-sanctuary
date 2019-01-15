pragma solidity 0.4.24;

interface tokenInterface {
    function transfer(address reciever, uint amount) external;
    function balanceOf(address owner) external returns (uint256);
}

contract dapMultisig {

    /*
    * Types
    */
    struct Transaction {
        uint id;
        address destination;
        uint value;
        bytes data;
        TxnStatus status;
        address[] confirmed;
        address creator;
    }
    
    struct tokenTransaction {
        uint id;
        tokenInterface token;
        address reciever;
        uint value;
        address[] confirmed;
        TxnStatus status;
        address creator;
    }
    
    struct Log {
        uint amount;
        address sender;
    }
    
    enum TxnStatus { Unconfirmed, Pending, Executed }
    
    /*
    * Modifiers
    */
    modifier onlyOwner () {
        bool found;
        for (uint i = 0;i<owners.length;i++){
            if (owners[i] == msg.sender){
                found = true;
            }
        }
        if (found){
            _;
        }
    }
    
    /*
    * Events
    */
    event WalletCreated(address creator, address[] owners);
    event TxnSumbitted(uint id);
    event TxnConfirmed(uint id);
    event topUpBalance(uint value);
    event tokenTxnConfirmed(uint id, address owner);
    event tokenTxnExecuted(address token, uint256 value, address reciever);
    /*
    * Storage
    */
    bytes32 public name;
    address public creator;
    uint public allowance;
    address[] public owners;
    Log[] logs;
    Transaction[] transactions;
    tokenTransaction[] tokenTransactions;
    uint public approvalsreq;
    
    /*
    * Constructor
    */
    constructor (uint _approvals, address[] _owners, bytes32 _name) public payable{
        /* check if name was actually given */
        require(_name.length != 0);
        
        /*check if approvals num equals or greater than given owners num*/
        require(_approvals <= _owners.length);
        
        name = _name;
        creator = msg.sender;
        allowance = msg.value;
        owners = _owners;
        approvalsreq = _approvals;
        emit WalletCreated(msg.sender, _owners);
    }

    //fallback to accept funds without method signature
    function () external payable {
        allowance += msg.value;
    }
    
    /*
    * Getters
    */

    function getOwners() external view returns (address[]){
        return owners;
    }
    
    function getTxnNum() external view returns (uint){
        return transactions.length;
    }
    
    function getTxn(uint _id) external view returns (uint, address, uint, bytes, TxnStatus, address[], address){
        Transaction storage txn = transactions[_id];
        return (txn.id, txn.destination, txn.value, txn.data, txn.status, txn.confirmed, txn.creator);
    }
    
    function getLogsNum() external view returns (uint){
        return logs.length;
    }
    
    function getLog(uint logId) external view returns (address, uint){
        return(logs[logId].sender, logs[logId].amount);
    }
    
    function getTokenTxnNum() external view returns (uint){
        return tokenTransactions.length;
    }
    
    function getTokenTxn(uint _id) external view returns(uint, address, address, uint256, address[], TxnStatus, address){
        tokenTransaction storage txn = tokenTransactions[_id];
        return (txn.id, txn.token, txn.reciever, txn.value, txn.confirmed, txn.status, txn.creator);
    }
    
    /*
    * Methods
    */

    function topBalance() external payable {
        require (msg.value > 0 wei);
        allowance += msg.value;
        
        /* create new log entry */
        uint loglen = logs.length++;
        logs[loglen].amount = msg.value;
        logs[loglen].sender = msg.sender;
        emit topUpBalance(msg.value);
    }
    
    function submitTransaction(address _destination, uint _value, bytes _data) onlyOwner () external returns (bool) {
        uint newTxId = transactions.length++;
        transactions[newTxId].id = newTxId;
        transactions[newTxId].destination = _destination;
        transactions[newTxId].value = _value;
        transactions[newTxId].data = _data;
        transactions[newTxId].creator = msg.sender;
        transactions[newTxId].confirmed.push(msg.sender);
        if (transactions[newTxId].confirmed.length == approvalsreq){
            transactions[newTxId].status = TxnStatus.Pending;
        }
        emit TxnSumbitted(newTxId);
        return true;
    }

    function confirmTransaction(uint txId) onlyOwner() external returns (bool){
        Transaction storage txn = transactions[txId];

        //check whether this owner has already confirmed this txn
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
        //push sender address into confirmed array if haven&#39;t found
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == approvalsreq){
            txn.status = TxnStatus.Pending;
        }
        
        //fire event
        emit TxnConfirmed(txId);
        
        return true;
    }
    
    function executeTxn(uint txId) onlyOwner() external returns (bool){
        
        Transaction storage txn = transactions[txId];
        
        /* check txn status */
        require(txn.status == TxnStatus.Pending);
        
        /* check whether wallet has sufficient balance to send this transaction */
        require(allowance >= txn.value);
        
        /* send transaction */
        address dest = txn.destination;
        uint val = txn.value;
        bytes memory dat = txn.data;
        assert(dest.call.value(val)(dat));
            
        /* change transaction&#39;s status to executed */
        txn.status = TxnStatus.Executed;

        /* change wallet&#39;s balance */
        allowance = allowance - txn.value;

        return true;
        
    }
    
    function submitTokenTransaction(address _tokenAddress, address _receiever, uint _value) onlyOwner() external returns (bool) {
        uint newTxId = tokenTransactions.length++;
        tokenTransactions[newTxId].id = newTxId;
        tokenTransactions[newTxId].token = tokenInterface(_tokenAddress);
        tokenTransactions[newTxId].reciever = _receiever;
        tokenTransactions[newTxId].value = _value;
        tokenTransactions[newTxId].confirmed.push(msg.sender);
        if (tokenTransactions[newTxId].confirmed.length == approvalsreq){
            tokenTransactions[newTxId].status = TxnStatus.Pending;
        }
        emit TxnSumbitted(newTxId);
        return true;
    }
    
    function confirmTokenTransaction(uint txId) onlyOwner() external returns (bool){
        tokenTransaction storage txn = tokenTransactions[txId];

        //check whether this owner has already confirmed this txn
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
        //push sender address into confirmed array if haven&#39;t found
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == approvalsreq){
            txn.status = TxnStatus.Pending;
        }
        
        //fire event
        emit tokenTxnConfirmed(txId, msg.sender);
        
        return true;
    }
    
    function executeTokenTxn(uint txId) onlyOwner() external returns (bool){
        
        tokenTransaction storage txn = tokenTransactions[txId];
        
        /* check txn status */
        require(txn.status == TxnStatus.Pending);
        
        /* check whether wallet has sufficient balance to send this transaction */
        uint256 balance = txn.token.balanceOf(address(this));
        require (txn.value <= balance);
        
        /* Send tokens */
        txn.token.transfer(txn.reciever, txn.value);
        
        /* change transaction&#39;s status to executed */
        txn.status = TxnStatus.Executed;
        
        /* Fire event */
        emit tokenTxnExecuted(address(txn.token), txn.value, txn.reciever);
       
        return true;
    }
}