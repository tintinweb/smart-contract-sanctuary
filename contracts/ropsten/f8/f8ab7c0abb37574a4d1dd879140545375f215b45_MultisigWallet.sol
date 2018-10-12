contract MultisigWallet {
        /** FIELDS **/
        // max number of owner 
        uint public maxOwner = 50;
        // list owners
        mapping(address => bool) public owners;
        // list transaction
        mapping(uint => Transaction) public transactions;
        // list tranasction&#39;s ID of one owner
        mapping(address => uint[]) public OwnerTransaction;

        // structure of Transaction
        struct Transaction {
            address[] receiver;
            uint[] amount;
            uint numConfirms;
            bool executed;
        }
        
        // state of owner to each tranasction
        // true : confirmed 
        mapping(uint => mapping(address => bool)) public confirmed;
        
        // total tranasction
        uint public totalTransaction;
        
        // the minimum number of owner agree to execute transaction
        uint requirement;
        
        /** EVENTS **/
        event Confirmed(uint transactionID, address owner, uint numberOfConfirmed);
        event Transfer(uint transactionID);
        event CreateTransaction(uint transactionID, address creator);
        event Deposit(address sender, uint amount);
        
        /** MODIFIERS **/
        // check the sender whether is a owner or not
        modifier isOwner(address sender){
            if(!owners[sender]){
                revert();
            }
            _;
        }
        
        
        modifier isTransactionExecuted(uint transactionID){
            if(transactions[transactionID].executed){
                revert();
            }
            _;
        }
        
        modifier isAlreadyConfirmed(uint transactionID, address sender){
            if(confirmed[transactionID][sender]){
                revert();
            }
            _;
        }
        
        modifier validRequirement(uint ownerCount, uint _required){
            require(ownerCount <= maxOwner
                && _required <= ownerCount
                && _required != 0
                && ownerCount != 0);
            _;
        }
        
        modifier notNull(address[] _address) {
            for (uint i=0; i< _address.length; i++) {
                require(_address[i] != 0);
            }
            _;
        }
        
        /** FUNCTIONS **/
        
        constructor(address[] _owners, uint _required) validRequirement(_owners.length, _required) payable public {
            for (uint i=0; i < _owners.length; i++) {
                require(_owners[i] != 0);
                owners[_owners[i]] = true;
            }
            requirement = _required;
        }
        
        function() payable public{
            if(msg.value > 0){
               emit Deposit(msg.sender, msg.value);
            }
        }
        
        function createAndExecuteTransaction(address[] _reciever, uint[] _amount, uint _transactionId)      isOwner(msg.sender)
                                                                                                            isTransactionExecuted(_transactionId)
                                                                                                            notNull(_reciever) 
                                                                                                            external 
        {
            if(transactions[_transactionId].numConfirms == 0){
                require(_reciever.length == _amount.length);
                totalTransaction++;
                transactions[_transactionId] = Transaction({
                    receiver: _reciever,
                    amount: _amount,
                    numConfirms: 1,
                    executed: false
                });
                confirmed[_transactionId][msg.sender] = true;
                OwnerTransaction[msg.sender].push(_transactionId);
                
                emit CreateTransaction(_transactionId, msg.sender);
            } else {
                confirmTransaction(_transactionId);
            }
        }
        
        function confirmTransaction(uint _transactionId) isAlreadyConfirmed(_transactionId, msg.sender) 
                                                         internal
        {
            
	        confirmed[_transactionId][msg.sender] = true;
            transactions[_transactionId].numConfirms += 1;
            
            if(transactions[_transactionId].numConfirms >= requirement){
                executeTransaction(_transactionId);
            }
            
            emit Confirmed(_transactionId, msg.sender, transactions[_transactionId].numConfirms);
        }
        
        function executeTransaction(uint _transactionId) internal
        {
            transactions[_transactionId].executed = true;
            for (uint i = 0; i < transactions[_transactionId].receiver.length; i++) {
                transactions[_transactionId].receiver[i].transfer(transactions[_transactionId].amount[i]);
            }
            emit Transfer(_transactionId);
        }
        
    }