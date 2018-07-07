pragma solidity ^0.4.19;


// ----------------------------------------------------------------------------
// Safe maths start
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
// ----------------------------------------------------------------------------
// Safe maths end
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC20 contract start
// ----------------------------------------------------------------------------
contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// ERC20 contract end
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Owned contract start
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}
// ----------------------------------------------------------------------------
// Owned contract end
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// FastExchange contract start
// ----------------------------------------------------------------------------
contract FastExchange is Owned, SafeMath {

    struct FTransaction {
        address from;
        uint receivedEth;
        uint tokenRate;
        uint tokenAmount;
        uint createdAt;
        uint transferredAt;
    }
    
    uint private constant minEth = 0.05 ether;
    uint private constant maxEth = 5 ether;
    uint private lockedEth;
    uint private withdrawableEth;

    FTransaction[] private transactions;
    mapping (address => uint[]) private transactionBook;
    mapping (string => address) tokenAddresses;

    //events
    event ReceiveEth(address from, uint transactionId, uint ethValue);
    event TokenTransferred(address to, uint transactionId, uint tokenAmount, uint refundEth, uint tokenRate);
    event TransactionLog(address from, uint receivedEth, uint tokenRate, uint tokenAmount, uint createdAt, uint transferredAt);

    //events

    //modifiers
    modifier AccepableEther(uint _etherValue) {
        require(_etherValue >= minEth);
        require(_etherValue <= maxEth);
        _;
    } 

    modifier ValidTransactionId(uint _transactionId) {
        require(transactions.length - 1 >= _transactionId);
        _;
    }

    modifier TransactionIsNotClosed(uint _transactionId) {
        require(transactions[_transactionId].transferredAt == 0);
        _;
    }

    modifier ValidTokenAddress(string symbol) {
        require(tokenAddresses[symbol] != address(0));
        _;
    }

    modifier Withdrawable(){
        require(withdrawableEth > 0);
        _;
    }

    modifier PreviousTransactionIsExecuted(uint transactionId) {
        require(transactionId == 0 || transactions[transactionId - 1].transferredAt != 0);
        _;
    }
    

    //constructor
    constructor() public {
        
    } 

    function () public payable {
        _processIncomingEther(msg.sender, msg.value);
    }

    
    

    function _processIncomingEther(address _sender, uint _ethValue) private AccepableEther(_ethValue) {
        transactions.push(FTransaction(_sender, _ethValue, 0, 0, now, 0));
        transactionBook[_sender].push(transactions.length - 1);
        lockedEth = safeAdd(lockedEth, _ethValue);
        emit ReceiveEth(_sender, transactionBook[_sender].length -1, _ethValue);  
    }

    function withdraw() public onlyOwner Withdrawable{
        owner.transfer(withdrawableEth);
        withdrawableEth = 0;
    }

    function setTokenInfo(string _symbol, address _address) public onlyOwner returns (string, address){
        tokenAddresses[_symbol] = _address;
        return (_symbol, _address);
    }

    function getTransactionListLength() public constant onlyOwner returns (uint length){
        length = transactions.length;
    }

    function getTransactionDetail(uint _transactionId) public constant onlyOwner ValidTransactionId(_transactionId) returns (address, uint, uint, uint, uint, uint){
        FTransaction storage t = transactions[_transactionId];
        return (t.from, t.receivedEth, t.tokenRate, t.tokenAmount, t.createdAt, t.transferredAt);
    }

    function getUserTransactionIndexes(address _user) public constant onlyOwner returns(uint[]) {
        return transactionBook[_user];
    }

    function getLastPendingTransaction() public constant onlyOwner returns(uint, bool) {
        for(uint i =0; i < transactions.length; i++){
            if(transactions[i].transferredAt == 0) {
                return (i,true);
            }
        }
        return (0,false);
    }

    function cancelTransaction(uint _transactionId) public onlyOwner ValidTransactionId(_transactionId) TransactionIsNotClosed(_transactionId)
        PreviousTransactionIsExecuted(_transactionId) {
        FTransaction storage t = transactions[_transactionId];
        t.transferredAt = now;
        t.from.transfer(t.receivedEth);
        lockedEth = safeSub(lockedEth, t.receivedEth);
    }

    function sendToken(uint _transactionId, uint _tokenRate, uint _maxTokenAmount, string _symbol) public onlyOwner ValidTransactionId(_transactionId) TransactionIsNotClosed(_transactionId)
        PreviousTransactionIsExecuted(_transactionId) ValidTokenAddress(_symbol) {
        
        FTransaction storage t = transactions[_transactionId];
        ERC20Token tokenContract = ERC20Token(tokenAddresses[_symbol]);
        uint tokenBalance = tokenContract.balanceOf(this); 
        uint tokenToSend = safeMul(_tokenRate, t.receivedEth); 
        if(_maxTokenAmount < tokenToSend){
            tokenToSend = _maxTokenAmount;
        }
        if(tokenBalance < tokenToSend){ 
            tokenToSend = tokenBalance;
        }
        
        uint refundEth = safeSub(t.receivedEth, safeDiv(tokenToSend, _tokenRate));
        lockedEth = safeSub(lockedEth, t.receivedEth);
        if(refundEth > 0){
            t.from.transfer(refundEth);
            withdrawableEth = safeAdd(withdrawableEth, safeSub(t.receivedEth, refundEth));
        }else{
            withdrawableEth = safeAdd(withdrawableEth, t.receivedEth);
        }
        if(tokenToSend > 0){
            tokenContract.transfer(t.from, tokenToSend);
        }
        t.tokenRate = _tokenRate;
        t.tokenAmount = tokenToSend;
        t.transferredAt = now;
        //emit TokenTransferred(t.from, _transactionId, tokenToSend, refundEth, _tokenRate);
    }
    
    
}
// ----------------------------------------------------------------------------
// FastExchange contract end
// ----------------------------------------------------------------------------