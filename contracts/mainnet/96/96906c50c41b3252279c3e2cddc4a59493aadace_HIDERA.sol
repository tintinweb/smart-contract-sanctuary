pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract Voter {
    
    struct Proposal{
        bytes32 name;
    }
    
    struct Ballot{
        bytes32 name;
        address chainperson;
        bool blind;
        bool finished;
    }
    
    struct votedData{
        uint256 proposal;
        bool isVal;
    }
    
    event Vote(
        address votedPerson,
        uint256 proposalIndex
        );
        
    event Finish(
        bool finished
        );

    mapping (address => mapping(uint256 => mapping(address => votedData))) votedDatas;
    mapping (address => mapping(uint256 => address[])) voted;
    mapping (address => mapping(uint256 => mapping(uint256 => uint256))) voteCount;
    mapping (address => Ballot[]) public ballots;   
    mapping (address => mapping(uint256 => Proposal[])) public proposals;
    
    function getBallotsNum(address chainperson) public constant returns (uint count) {
        return ballots[chainperson].length; 
    }
    function getProposalsNum(address chainperson, uint ballot) public constant returns (uint count) {
        return proposals[chainperson][ballot].length;
    }
    
    function getBallotIndex(address chainperson, bytes32 ballotName) public constant returns (uint index){
        for (uint i=0;i<ballots[chainperson].length;i++){
            if (ballots[chainperson][i].name == ballotName){
                return i;
            }
        }
    }
    function isVoted(address chainperson, uint ballot) public constant returns (bool result){
        for (uint8 i=0;i<voted[chainperson][ballot].length;i++){
            if (voted[chainperson][ballot][i] == msg.sender){
                return true;
            }
        }
        return false;
    }
    function startNewBallot(bytes32 ballotName, bool blindParam, bytes32[] proposalNames) external returns (bool success){
        for (uint8 y=0;y<ballots[msg.sender].length;y++){
            if (ballots[msg.sender][i].name == ballotName){
                revert();
            }
        }
        ballots[msg.sender].push(Ballot({
            name: ballotName, 
            chainperson: msg.sender, 
            blind: blindParam,
            finished: false
        }));
        
        uint ballotsNum = ballots[msg.sender].length;
        for (uint8 i=0;i<proposalNames.length;i++){
            proposals[msg.sender][ballotsNum-1].push(Proposal({name:proposalNames[i]}));
        }
        return true;
    }
    
    function getVoted(address chainperson, uint256 ballot) public constant returns (address[]){
        if (ballots[chainperson][ballot].blind == true){
            revert();
        }
        return voted[chainperson][ballot];
    }
    
    function getVotesCount(address chainperson, uint256 ballot, bytes32 proposalName) public constant returns (uint256 count){
        if (ballots[chainperson][ballot].blind == true){
            revert();
        }
        
        for (uint8 i=0;i<proposals[chainperson][ballot].length;i++){
            if (proposals[chainperson][ballot][i].name == proposalName){
                return voteCount[chainperson][ballot][i];
            }
        }
    }
    
    function getVotedData(address chainperson, uint256 ballot, address voter) public constant returns (uint256 proposalNum){
        if (ballots[chainperson][ballot].blind == true){
            revert();
        }
        
        if (votedDatas[chainperson][ballot][voter].isVal == true){
            return votedDatas[chainperson][ballot][voter].proposal;
        }
    }
    
    function vote(address chainperson, uint256 ballot, uint256 proposalNum) external returns (bool success){
        
        if (ballots[chainperson][ballot].finished == true){
            revert();
        }
        for (uint8 i = 0;i<voted[chainperson][ballot].length;i++){
            if (votedDatas[chainperson][ballot][msg.sender].isVal == true){
                revert();
            }
        }
        voted[chainperson][ballot].push(msg.sender);
        voteCount[chainperson][ballot][proposalNum]++;
        votedDatas[chainperson][ballot][msg.sender] = votedData({proposal: proposalNum, isVal: true});
        Vote(msg.sender, proposalNum);
        return true;
    }
    
    function getProposalIndex(address chainperson, uint256 ballot, bytes32 proposalName) public constant returns (uint index){
        for (uint8 i=0;i<proposals[chainperson][ballot].length;i++){
            if (proposals[chainperson][ballot][i].name == proposalName){
                return i;
            }
        }
    }
    
    
    function finishBallot(bytes32 ballot) external returns (bool success){
        for (uint8 i=0;i<ballots[msg.sender].length;i++){
            if (ballots[msg.sender][i].name == ballot) {
                if (ballots[msg.sender][i].chainperson == msg.sender){
                    ballots[msg.sender][i].finished = true;
                    Finish(true);
                    return true;
                } else {
                    return false;
                }
            }
        }
    }
    
    function getWinner(address chainperson, uint ballotIndex) public constant returns (bytes32 winnerName){
            if (ballots[chainperson][ballotIndex].finished == false){
                revert();
            }
            uint256 maxVotes;
            bytes32 winner;
            for (uint8 i=0;i<proposals[chainperson][ballotIndex].length;i++){
                if (voteCount[chainperson][ballotIndex][i]>maxVotes){
                    maxVotes = voteCount[chainperson][ballotIndex][i];
                    winner = proposals[chainperson][ballotIndex][i].name;
                }
            }
            return winner;
    }
}
contract Multisig {

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

    struct Wallet {
        bytes32 name;
        address creator;
        uint id;
        uint allowance;
        address[] owners;
        Log[] logs;
        Transaction[] transactions;
        uint appovalsreq;
    }
    
    struct Log {
        uint amount;
        address sender;
    }
    
    enum TxnStatus { Unconfirmed, Pending, Executed }
    
    /*
    * Modifiers
    */
    modifier onlyOwner ( address creator, uint walletId ) {
        bool found;
        for (uint i = 0;i<wallets[creator][walletId].owners.length;i++){
            if (wallets[creator][walletId].owners[i] == msg.sender){
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
    event WalletCreated(uint id);
    event TxnSumbitted(uint id);
    event TxnConfirmed(uint id);
    event topUpBalance(uint value);

    /*
    * Storage
    */
    mapping (address => Wallet[]) public wallets;
    
    /*
    * Constructor
    */
    function ibaMultisig() public{

    }

    /*
    * Getters
    */
    function getWalletId(address creator, bytes32 name) external view returns (uint, bool){
        for (uint i = 0;i<wallets[creator].length;i++){
            if (wallets[creator][i].name == name){
                return (i, true);
            }
        }
    }

    function getOwners(address creator, uint id) external view returns (address[]){
        return wallets[creator][id].owners;
    }
    
    function getTxnNum(address creator, uint id) external view returns (uint){
        require(wallets[creator][id].owners.length > 0);
        return wallets[creator][id].transactions.length;
    }
    
    function getTxn(address creator, uint walletId, uint id) external view returns (uint, address, uint, bytes, TxnStatus, address[], address){
        Transaction storage txn = wallets[creator][walletId].transactions[id];
        return (txn.id, txn.destination, txn.value, txn.data, txn.status, txn.confirmed, txn.creator);
    }
    
    function getLogsNum(address creator, uint id) external view returns (uint){
        return wallets[creator][id].logs.length;
    }
    
    function getLog(address creator, uint id, uint logId) external view returns (address, uint){
        return(wallets[creator][id].logs[logId].sender, wallets[creator][id].logs[logId].amount);
    }
    
    /*
    * Methods
    */
    
    function createWallet(uint approvals, address[] owners, bytes32 name) external payable{

        /* check if name was actually given */
        require(name.length != 0);
        
        /*check if approvals num equals or greater than given owners num*/
        require(approvals <= owners.length);
        
        /* check if wallets with given name already exists */
        bool found;
        for (uint i = 0; i<wallets[msg.sender].length;i++){
            if (wallets[msg.sender][i].name == name){
                found = true;
            }
        }
        require (found == false);
        
        /*instantiate new wallet*/
        uint currentLen = wallets[msg.sender].length++;
        wallets[msg.sender][currentLen].name = name;
        wallets[msg.sender][currentLen].creator = msg.sender;
        wallets[msg.sender][currentLen].id = currentLen;
        wallets[msg.sender][currentLen].allowance = msg.value;
        wallets[msg.sender][currentLen].owners = owners;
        wallets[msg.sender][currentLen].appovalsreq = approvals;
        emit WalletCreated(currentLen);
    }

    function topBalance(address creator, uint id) external payable {
        require (msg.value > 0 wei);
        wallets[creator][id].allowance += msg.value;
        
        /* create new log entry */
        uint loglen = wallets[creator][id].logs.length++;
        wallets[creator][id].logs[loglen].amount = msg.value;
        wallets[creator][id].logs[loglen].sender = msg.sender;
        emit topUpBalance(msg.value);
    }
    
    function submitTransaction(address creator, address destination, uint walletId, uint value, bytes data) onlyOwner (creator,walletId) external returns (bool) {
        uint newTxId = wallets[creator][walletId].transactions.length++;
        wallets[creator][walletId].transactions[newTxId].id = newTxId;
        wallets[creator][walletId].transactions[newTxId].destination = destination;
        wallets[creator][walletId].transactions[newTxId].value = value;
        wallets[creator][walletId].transactions[newTxId].data = data;
        wallets[creator][walletId].transactions[newTxId].creator = msg.sender;
        emit TxnSumbitted(newTxId);
        return true;
    }

    function confirmTransaction(address creator, uint walletId, uint txId) onlyOwner(creator, walletId) external returns (bool){
        Wallet storage wallet = wallets[creator][walletId];
        Transaction storage txn = wallet.transactions[txId];

        //check whether this owner has already confirmed this txn
                
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
        //push sender address into confirmed array if havent found
                                                       
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == wallet.appovalsreq){
            txn.status = TxnStatus.Pending;
        }
        
        //fire event
                                                       
        emit TxnConfirmed(txId);
        
        return true;
    }
    
    function executeTxn(address creator, uint walletId, uint txId) onlyOwner(creator, walletId) external returns (bool){
        Wallet storage wallet = wallets[creator][walletId];
        
        Transaction storage txn = wallet.transactions[txId];
        
        /* check txn status */
        require(txn.status == TxnStatus.Pending);
        
        /* check whether wallet has sufficient balance to send this transaction */
        require(wallet.allowance >= txn.value);
        
        /* send transaction */
        address dest = txn.destination;
        uint val = txn.value;
        bytes memory dat = txn.data;
        assert(dest.call.value(val)(dat));
            
        /* change transaction&#39;s status to executed */
        txn.status = TxnStatus.Executed;

        /* change wallet&#39;s balance */
        wallet.allowance = wallet.allowance - txn.value;

        return true;
        
    }
}
contract Escrow{
    
    struct Bid{
        bytes32 name;
        address oracle;
        address seller;
        address buyer;
        uint price;
        uint timeout;
        dealStatus status;
        uint fee;
        bool isLimited;
    }
    
    enum dealStatus{ unPaid, Pending, Closed, Rejected, Refund }
    
    mapping (address => Bid[]) public bids;
    mapping (address => uint) public pendingWithdrawals;
    
    event amountRecieved(
        address seller,
        uint bidId
    );
    
    event bidClosed(
        address seller,
        uint bidId
        );
        
    event bidCreated(
        address seller,
        bytes32 name,
        uint bidId
        );
        
    event refundDone(
        address seller,
        uint bidId
        );
        
    event withdrawDone(
        address person,
        uint amount
        );
    
    event bidRejected(
        address seller,
        uint bidId
        );
        
    function getBidIndex(address seller, bytes32 name) public constant returns (uint){
        for (uint8 i=0;i<bids[seller].length;i++){
            if (bids[seller][i].name == name){
                return i;
            }
        }
    }
    
    function getBidsNum (address seller) public constant returns (uint bidsNum) {
        return bids[seller].length;
    }
    
    function sendAmount (address seller, uint bidId) external payable{
        Bid storage a = bids[seller][bidId];
        require(msg.value == a.price && a.status == dealStatus.unPaid);
        if (a.isLimited == true){
            require(a.timeout > block.number);
        }
        a.status = dealStatus.Pending;
        amountRecieved(seller, bidId);
    }
    
    function createBid (bytes32 name, address seller, address oracle, address buyer, uint price, uint timeout, uint fee) external{
        require(name.length != 0 && price !=0);
        bool limited = true;
        if (timeout == 0){
            limited = false;
        }
        bids[seller].push(Bid({
            name: name, 
            oracle: oracle, 
            seller: seller, 
            buyer: buyer,
            price: price,
            timeout: block.number+timeout,
            status: dealStatus.unPaid,
            fee: fee,
            isLimited: limited
        }));
        uint bidId = bids[seller].length-1;
        bidCreated(seller, name, bidId);
    }
    
    function closeBid(address seller, uint bidId) external returns (bool){
        Bid storage bid = bids[seller][bidId];
        if (bid.isLimited == true){
            require(bid.timeout > block.number);
        }
        require(msg.sender == bid.oracle && bid.status == dealStatus.Pending);
        bid.status = dealStatus.Closed;
        pendingWithdrawals[bid.seller]+=bid.price-bid.fee;
        pendingWithdrawals[bid.oracle]+=bid.fee;
        withdraw(bid.seller);
        withdraw(bid.oracle);
        bidClosed(seller, bidId);
        return true;
    }
    
    function refund(address seller, uint bidId) external returns (bool){
        require(bids[seller][bidId].buyer == msg.sender && bids[seller][bidId].isLimited == true && bids[seller][bidId].timeout < block.number && bids[seller][bidId].status == dealStatus.Pending);
        Bid storage a = bids[seller][bidId];
        a.status = dealStatus.Refund;
        pendingWithdrawals[a.buyer] = a.price;
        withdraw(a.buyer);
        refundDone(seller,bidId);
        return true;
    }
    function rejectBid(address seller, uint bidId) external returns (bool){
        if (bids[seller][bidId].isLimited == true){
            require(bids[seller][bidId].timeout > block.number);
        }
        require(msg.sender == bids[seller][bidId].oracle && bids[seller][bidId].status == dealStatus.Pending);
        Bid storage bid = bids[seller][bidId];
        bid.status = dealStatus.Rejected;
        pendingWithdrawals[bid.oracle] = bid.fee;
        pendingWithdrawals[bid.buyer] = bid.price-bid.fee;
        withdraw(bid.buyer);
        withdraw(bid.oracle);
        bidRejected(seller, bidId);
        return true;
    }
    
    function withdraw(address person) private{
        uint amount = pendingWithdrawals[person];
        pendingWithdrawals[person] = 0;
        person.transfer(amount);
        withdrawDone(person, amount);
    }
    
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract HideraNetwork {
                
    // Public variables of the token
                
    string public name;
                
    string public symbol;
                
    uint8 public decimals = 8;
                
    // 8 decimals is the strongly suggested default, avoid changing it
                
    uint256 public totalSupply;

    // This creates an array with all balances
                
    mapping (address => uint256) public balanceOf;
                
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
                
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
                
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
                
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HideraNetwork(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
                
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
                
        name = tokenName;                                   // Set the name for display purposes
                
        symbol = tokenSymbol;                               // Set the symbol for display purposes
                
    }

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

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
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
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the senders allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract HIDERA is owned, HideraNetwork {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function HIDERA(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint256 tokenDecimals
        
    ) HideraNetwork(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
                
    /// @param target Address to receive the tokens
                
    /// @param mintedAmount the amount of tokens it will receive
                
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
                
    /// @param target Address to be frozen
                
    /// @param freeze either to freeze it or not
                
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
                
    /// @param newSellPrice Price the users can sell to the contract
                
    /// @param newBuyPrice Price users can buy from the contract
                
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
                
    function buy() payable public {
        uint amount = msg.value / buyPrice;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
                
    /// @param amount amount of tokens to be sold
                
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. Its important to do this last to avoid recursion attacks
    }
}