pragma solidity ^0.4.19;


// ----------------------------------------------------------------------------
// Safe maths start
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
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
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
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
        uint maxToken;
        uint refundEth;
        uint createdAt;
        uint transferedAt;
    }
    
    uint public constant minEth = 0.1 ether;
    uint public constant maxEth = 5 ether;
    address tokenAddress;
    address faucetAddress;

    mapping (address => FTransaction[]) transactionBook;
    //mapping (address => Transaction) lastestTransaction;

    //events
    event ReceiveEth(address from, uint transactionId, uint ethValue);
    event TokenTransfered(address to, uint transactionId, uint tokenAmount, uint refundEth, uint tokenRate);
    event CannotCreateNewTransaction(string mess);
    event Log(string mes);
    event LogTime(uint time);
    //events

    //modifiers
    modifier AccepableEther(uint _etherValue) {
        require(_etherValue >= minEth);
        require(_etherValue <= maxEth);
        _;
    } 

    modifier ValidTransactionId(address _sender, uint _transactionId) {
        require(transactionBook[_sender].length - 1 >= _transactionId);
        _;
    }

    

    //constructor
    /*constructor(address _tokenAddress, address _faucetAddress) public {
        tokenAddress = _tokenAddress;
        faucetAddress = _faucetAddress;
    }*/
    
    constructor() public {
        tokenAddress = 0x86a85ce4CC3FA15a4C24Ae720990d998A65B4917;
        faucetAddress = 0xB7983Ce7796d47616CE896b2d006145BC856Dc0E;
    }

    function () public payable {
        _processIncomingEther(msg.sender, msg.value);
    }

    function _processIncomingEther(address _sender, uint _ethValue) private AccepableEther(_ethValue) {
        transactionBook[_sender].push(FTransaction(_sender, _ethValue, 0, 0, 0, now, 0));
        emit ReceiveEth(_sender, transactionBook[_sender].length -1, _ethValue);  
    }

    function sendToken(address _sender, uint _transactionId, uint _tokenRate, uint _maxToken) public onlyOwner ValidTransactionId(_sender, _transactionId){
        FTransaction storage t = transactionBook[_sender][_transactionId];
        uint tokenToSend = safeMul(_tokenRate, t.receivedEth);
        if(tokenToSend > _maxToken){
            tokenToSend = _maxToken;
        }
        ERC20Token tokenContract = ERC20Token(tokenAddress);
        if(tokenContract.allowance(faucetAddress,this) < tokenToSend){
            tokenToSend = _maxToken;
        }
        uint refundEth = safeSub(t.receivedEth, safeDiv(tokenToSend, _tokenRate));
        if(refundEth > 0){
            _sender.transfer(refundEth);
        }
        if(tokenToSend > 0){
            tokenContract.transferFrom(faucetAddress, _sender, tokenToSend);
        }
        transactionBook[_sender][_transactionId].tokenRate = _tokenRate;
        transactionBook[_sender][_transactionId].maxToken = _maxToken;
        transactionBook[_sender][_transactionId].refundEth = refundEth;
        transactionBook[_sender][_transactionId].transferedAt = now;
        emit TokenTransfered(_sender, _transactionId, tokenToSend, refundEth, _tokenRate);
    }
}
// ----------------------------------------------------------------------------
// FastExchange contract end
// ----------------------------------------------------------------------------