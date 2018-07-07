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
    
    uint private constant minEth = 0.1 ether;
    uint private constant maxEth = 5 ether;
    address tokenAddress;
    address faucetAddress;

    FTransaction[] public transactions;
    mapping (address => uint[]) public transactionBook;
    //mapping (address => Transaction) lastestTransaction;

    //events
    event ReceiveEth(address from, uint transactionId, uint ethValue);
    event TokenTransferred(address to, uint transactionId, uint tokenAmount, uint refundEth, uint tokenRate);
    event TransactionLog(address from, uint receivedEth, uint tokenRate, uint tokenAmount, uint createdAt, uint transferredAt);
    event LogNumber(string logName, uint content);
    event LogString(string logName, string content);
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
    

    //constructor
    constructor() public {
        tokenAddress = 0x29846b840A9C74b02CA1b7dB1BF80D2BF3D1355b;
        faucetAddress = 0xB7983Ce7796d47616CE896b2d006145BC856Dc0E;
    } 

    function () public payable {
        _processIncomingEther(msg.sender, msg.value);
    }

    

    function _processIncomingEther(address _sender, uint _ethValue) private AccepableEther(_ethValue) {
        transactions.push(FTransaction(_sender, _ethValue, 0, 0, now, 0));
        transactionBook[_sender].push(transactions.length - 1);
        emit ReceiveEth(_sender, transactionBook[_sender].length -1, _ethValue);  
    }

    function withdraw() public onlyOwner{
        owner.transfer(address(this).balance);
    }

    function getTransactionDetail(uint _transactionId) public constant onlyOwner  ValidTransactionId(_transactionId) returns (address, uint, uint, uint, uint, uint){
        FTransaction storage t = transactions[_transactionId];
        return (t.from, t.receivedEth, t.tokenRate, t.tokenAmount, t.createdAt, t.transferredAt);
    }

    function getUserTransactionIndexes(address _user) public constant onlyOwner returns(uint[]) {
        return transactionBook[_user];
    }

    function logAllTransactions(address _from) public {
        uint[] storage ids = transactionBook[_from];
        for (uint i = 0; i < ids.length; i++) {
            FTransaction storage t = transactions[ids[i]];
            emit TransactionLog(t.from, t.receivedEth, t.tokenRate, t.tokenAmount, t.createdAt, t.transferredAt);
        }
    }

    function sendToken(uint _transactionId, uint _tokenRate) public onlyOwner ValidTransactionId(_transactionId) TransactionIsNotClosed(_transactionId){
        
        FTransaction storage t = transactions[_transactionId];
        ERC20Token tokenContract = ERC20Token(tokenAddress);
        uint allowedToken = tokenContract.allowance(faucetAddress,this); 
        uint maxToken = tokenContract.balanceOf(faucetAddress); 
        uint tokenToSend = safeMul(_tokenRate, t.receivedEth); 
        if(allowedToken < tokenToSend){ 
            tokenToSend = allowedToken;
        }
        if(maxToken < tokenToSend){
            tokenToSend = maxToken;
        }

        uint refundEth = safeSub(t.receivedEth, safeDiv(tokenToSend, _tokenRate));
        if(refundEth > 0){
            t.from.transfer(refundEth);
        }
        if(tokenToSend > 0){
            tokenContract.transferFrom(faucetAddress, t.from, tokenToSend);
        }
        t.tokenRate = _tokenRate;
        t.tokenAmount = tokenToSend;
        t.transferredAt = now;
    
        emit TokenTransferred(t.from, _transactionId, tokenToSend, refundEth, _tokenRate);
        emit TransactionLog(t.from, t.receivedEth, t.tokenRate, t.tokenAmount, t.createdAt, t.transferredAt);
        
    }
    
    
}
// ----------------------------------------------------------------------------
// FastExchange contract end
// ----------------------------------------------------------------------------