pragma solidity ^0.4.20;

interface ERC20 {
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external constant returns (uint);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Token {
    string internal _symbol;
    string internal _name;
    uint8 internal _decimals;
    uint internal _totalSupply = 250000000;
    mapping (address => uint) internal _balanceOf;
    mapping (address => mapping (address => uint)) internal _allowances;

    constructor (string symbol, string name, uint8 decimals, uint totalSupply) public {
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        _totalSupply = totalSupply;
    }

    function name() public constant returns (string) {
        return _name;
    }

    function symbol() public constant returns (string) {
        return _symbol;
    }

    function decimals() public constant returns (uint8) {
        return _decimals;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint);
    function transfer(address _to, uint _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract PinmoToken3 is Token(&quot;PNT3&quot;, &quot;Pinmo Token&quot;, 1, 250000000), ERC20 {

    using SafeMath for uint;

    constructor () PinmoToken3() public {
        _balanceOf[msg.sender] = _totalSupply;
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _addr) public constant returns (uint) {
        return _balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public returns (bool) {
        if (_value > 0 &&
            _value <= _balanceOf[msg.sender] &&
            !isContract(_to)) {
            _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function isContract(address _addr) private constant returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        if (_allowances[_from][msg.sender] > 0 &&
           _value > 0 &&
            _allowances[_from][msg.sender] >= _value &&
            _balanceOf[_from] >= _value) {
            _balanceOf[_from] = _balanceOf[_from].sub(_value);
            _balanceOf[_to] = _balanceOf[_to].add(_value);
            _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(_value);
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender].add(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external constant returns (uint) {
        return _allowances[_owner][_spender];
    }
}

contract EtherTransferTo{
    function () public payable{
    }
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    
}
contract EtherTransferFrom{
    
    EtherTransferTo private _instance;
    
    constructor() EtherTransferFrom() public{
        // _instance = EtherTransferTo(address(this));
        _instance = new EtherTransferTo();
    }
    
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    function getBalanceOfInstance() public view returns (uint){
        return _instance.getBalance();
    }
    
    function () public payable {
        
        address(_instance).transfer(msg.value);
    }
}

contract MultiSigWallet { // this is safe to implement but it consumes gas 
    address private _owner;
    
    mapping(address => uint8) private _owners; 
    
    uint constant MIN_SIGNATURES = 2; // number of signatures before the transactions is authorized
    uint private _transactionsIdx;
    
    struct Transaction {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    mapping (uint => Transaction) private _transactions;
    uint[] private _pendingTransactions;
    
    modifier isOwner(){
        require(msg.sender == _owner);
        _;
    }
    
    modifier validOwner(){
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }
    
    event DepositFunds(address from, uint amount);
    event TransactionCreated(address from, address to, uint amount, uint transactionId);
    event TransactionCompleted(address from, address to, uint amount, uint transactionId);
    event TransactionSigned(address by, uint transactionId);

    
    constructor() MultiSigWallet() // can only be tested in the real environment
        public {
            _owner = msg.sender;
    }
    function addOwner(address owner)
        isOwner
        public {
            _owners[owner] = 1;    
        }
        
    function removeOwner(address owner)
        isOwner
        public {
            _owners[owner] = 0;
        }
        
    function ()
    public
    payable {
        emit DepositFunds(msg.sender, msg.value);
    }
    
    function withdraw(uint amount)
    
    public {
        transferTo(msg.sender, amount);
    }
    
    function transferTo(address to, uint amount)
    validOwner
    public {
        require(address(this).balance >= amount);
        uint transactionId = _transactionsIdx++;
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        
        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }
    
    function getPendingTransactions()
        view
        validOwner
        public
        returns (uint[]) {
            return _pendingTransactions;
        }
    
    function signTransaction(uint transactionId)
        validOwner
        public{
            Transaction storage transaction = _transactions[transactionId];
            // Transaction must exist
            require(0x0 != transaction.from);
            // Creator cannot sign the transaction 
            require(msg.sender != transaction.from);
            // Cannot sign a transaction more than once
            require(transaction.signatures[msg.sender] != 1);
            
            transaction.signatures[msg.sender] == 1;
            transaction.signatureCount++;
            
            emit TransactionSigned(msg.sender, transactionId);
            
            if(transaction.signatureCount >= MIN_SIGNATURES){
                require(address(this).balance >= transaction.amount);
                transaction.to.transfer(transaction.amount);
                emit TransactionCompleted(transaction.from, transaction.to, transaction.amount, transactionId);
                deleteTransaction(transactionId);
            }
        }
        function deleteTransaction(uint transactionId)
            validOwner
            public {
                uint8 replace = 0;
                for (uint i = 0; i < _pendingTransactions.length; i++){
                    if(1 == replace){
                        _pendingTransactions[i-1] = _pendingTransactions[i];
                    } else if(transactionId == _pendingTransactions[i]){
                        replace = 1;
                    }
                }
                delete _pendingTransactions[_pendingTransactions.length -1];
                _pendingTransactions.length--;
                delete _transactions[transactionId];
            }
            function walletBalance()
            constant
            public
            returns (uint){
                return address(this).balance;
            }
}

contract Escrow {
    uint balance;
    address public buyer;
    address public seller;
    address private escrow;
    uint private start;
    bool buyerOk;
    bool sellerOk;
    
    constructor (address buyer_address, address seller_address) 
    public{
        buyer = buyer_address;
        seller = seller_address;
        escrow = msg.sender;
        start = now;
    }
    function accept() payable public{
        if (msg.sender == buyer){
            buyerOk = true;
        } else if (msg.sender == seller){
            sellerOk = true;
        }
        if (buyerOk && sellerOk){
            payBalance();
        } else if (buyerOk && !!sellerOk && now > start + 30 days){
            // Freeze 30 days before release to buyer. The customer needs to remember
            // to call this method after freeze period.
            selfdestruct(buyer);
        }
    }
    function payBalance() private {
        escrow.transfer(address(this).balance / 100);
        if (seller.send(address(this).balance)){
            balance = 0;
        } else {
            revert();
        }
        
    }
    function deposit() public payable {
        if(msg.sender == buyer){
            balance += msg.value;
        }
    }
    function cancel() public {
        if(msg.sender == buyer){
            buyerOk = false;
        }else if (msg.sender == seller){
            sellerOk = false;
        }
        if(!buyerOk && !sellerOk){
            selfdestruct(buyer);
        }
    }
    function kill() public payable {
        if(msg.sender == escrow){
            selfdestruct(buyer);
        }
    }
}