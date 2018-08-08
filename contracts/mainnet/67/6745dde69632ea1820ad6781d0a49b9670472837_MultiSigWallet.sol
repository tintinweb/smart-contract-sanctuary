pragma solidity ^0.4.11;

contract ERC20Interface {
    // Get the total token supply
    function totalSupply() constant returns (uint256);
 
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) constant returns (uint256 balance);
 
    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) returns (bool success);
 
    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) returns (bool success);
 
    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 
    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 
    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
contract RoseCoin is ERC20Interface {
    uint8 public constant decimals = 5;
    string public constant symbol = "RSC";
    string public constant name = "RoseCoin";

    uint public _level = 0;
    bool public _selling = true;
    uint public _totalSupply = 10 ** 14;
    uint public _originalBuyPrice = 10 ** 10;
    uint public _minimumBuyAmount = 10 ** 17;
   
    // Owner of this contract
    address public owner;
 
    // Balances for each account
    mapping(address => uint256) balances;
 
    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;
    
    uint public _icoSupply = _totalSupply;
    uint[4] public ratio = [12, 10, 10, 13];
    uint[4] public threshold = [95000000000000, 85000000000000, 0, 80000000000000];

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlyNotOwner() {
        if (msg.sender == owner) {
            revert();
        }
        _;
    }

    modifier thresholdAll() {
        if (!_selling || msg.value < _minimumBuyAmount || _icoSupply <= threshold[3]) { //
            revert();
        }
        _;
    }
 
    // Constructor
    function RoseCoin() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }
 
    function totalSupply() constant returns (uint256) {
        return _totalSupply;
    }
 
    // What is the balance of a particular account?
    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }
 
    // Transfer the balance from sender&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool) {
        if (balances[msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }


    function toggleSale() onlyOwner {
        _selling = !_selling;
    }

    function setBuyPrice(uint newBuyPrice) onlyOwner {
        _originalBuyPrice = newBuyPrice;
    }
    
    // Buy RoseCoin by sending Ether    
    function buy() payable onlyNotOwner thresholdAll returns (uint256 amount) {
        amount = 0;
        uint remain = msg.value / _originalBuyPrice;
        
        while (remain > 0 && _level < 3) { //
            remain = remain * ratio[_level] / ratio[_level+1];
            if (_icoSupply <= remain + threshold[_level]) {
                remain = (remain + threshold[_level] - _icoSupply) * ratio[_level+1] / ratio[_level];
                amount += _icoSupply - threshold[_level];
                _icoSupply = threshold[_level];
                _level += 1;
            }
            else {
                _icoSupply -= remain;
                amount += remain;
                remain = 0;
                break;
            }
        }
        
        if (balances[owner] < amount)
            revert();
        
        if (remain > 0) {
            remain *= _originalBuyPrice;
            msg.sender.transfer(remain);
        }
        
        balances[owner] -= amount;
        balances[msg.sender] += amount;
        owner.transfer(msg.value - remain);
        Transfer(owner, msg.sender, amount);
        return amount;
    }
    
    // Owner withdraws Ether in contract
    function withdraw() onlyOwner returns (bool) {
        return owner.send(this.balance);
    }
}

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
/// @author Stefan George - <<span class="__cf_email__" data-cfemail="0477706162656a2a63616b76636144676b6a77616a777d772a6a6170">[email&#160;protected]</span>>
contract MultiSigWallet {

    event Confirmation(address sender, bytes32 transactionHash);
    event Revocation(address sender, bytes32 transactionHash);
    event Submission(bytes32 transactionHash);
    event Execution(bytes32 transactionHash);
    event Deposit(address sender, uint value);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequiredUpdate(uint required);
    event CoinCreation(address coin);

    mapping (bytes32 => Transaction) public transactions;
    mapping (bytes32 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] owners;
    bytes32[] transactionList;
    uint public required;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        uint nonce;
        bool executed;
    }

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert();
        _;
    }

    modifier signaturesFromOwners(bytes32 transactionHash, uint8[] v, bytes32[] rs) {
        for (uint i=0; i<v.length; i++)
            if (!isOwner[ecrecover(transactionHash, v[i], rs[i], rs[v.length + i])])
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

    modifier confirmed(bytes32 transactionHash, address owner) {
        if (!confirmations[transactionHash][owner])
            revert();
        _;
    }

    modifier notConfirmed(bytes32 transactionHash, address owner) {
        if (confirmations[transactionHash][owner])
            revert();
        _;
    }

    modifier notExecuted(bytes32 transactionHash) {
        if (transactions[transactionHash].executed)
            revert();
        _;
    }

    modifier notNull(address destination) {
        if (destination == 0)
            revert();
        _;
    }

    modifier validRequired(uint _ownerCount, uint _required) {
        if (   _required > _ownerCount
            || _required == 0
            || _ownerCount == 0)
            revert();
        _;
    }

    function addOwner(address owner)
        external
        onlyWallet
        ownerDoesNotExist(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

    function removeOwner(address owner)
        external
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            updateRequired(owners.length);
        OwnerRemoval(owner);
    }

    function updateRequired(uint _required)
        public
        onlyWallet
        validRequired(owners.length, _required)
    {
        required = _required;
        RequiredUpdate(_required);
    }

    function addTransaction(address destination, uint value, bytes data, uint nonce)
        private
        notNull(destination)
        returns (bytes32 transactionHash)
    {
        transactionHash = sha3(destination, value, data, nonce);
        if (transactions[transactionHash].destination == 0) {
            transactions[transactionHash] = Transaction({
                destination: destination,
                value: value,
                data: data,
                nonce: nonce,
                executed: false
            });
            transactionList.push(transactionHash);
            Submission(transactionHash);
        }
    }

    function submitTransaction(address destination, uint value, bytes data, uint nonce)
        external
        ownerExists(msg.sender)
        returns (bytes32 transactionHash)
    {
        transactionHash = addTransaction(destination, value, data, nonce);
        confirmTransaction(transactionHash);
    }

    function submitTransactionWithSignatures(address destination, uint value, bytes data, uint nonce, uint8[] v, bytes32[] rs)
        external
        ownerExists(msg.sender)
        returns (bytes32 transactionHash)
    {
        transactionHash = addTransaction(destination, value, data, nonce);
        confirmTransactionWithSignatures(transactionHash, v, rs);
    }

    function addConfirmation(bytes32 transactionHash, address owner)
        private
        notConfirmed(transactionHash, owner)
    {
        confirmations[transactionHash][owner] = true;
        Confirmation(owner, transactionHash);
    }

    function confirmTransaction(bytes32 transactionHash)
        public
        ownerExists(msg.sender)
    {
        addConfirmation(transactionHash, msg.sender);
        executeTransaction(transactionHash);
    }

    function confirmTransactionWithSignatures(bytes32 transactionHash, uint8[] v, bytes32[] rs)
        public
        signaturesFromOwners(transactionHash, v, rs)
    {
        for (uint i=0; i<v.length; i++)
            addConfirmation(transactionHash, ecrecover(transactionHash, v[i], rs[i], rs[i + v.length]));
        executeTransaction(transactionHash);
    }

    function executeTransaction(bytes32 transactionHash)
        public
        notExecuted(transactionHash)
    {
        if (isConfirmed(transactionHash)) {
            Transaction storage txn = transactions[transactionHash]; //
            txn.executed = true;
            if (!txn.destination.call.value(txn.value)(txn.data))
                revert();
            Execution(transactionHash);
        }
    }

    function revokeConfirmation(bytes32 transactionHash)
        external
        ownerExists(msg.sender)
        confirmed(transactionHash, msg.sender)
        notExecuted(transactionHash)
    {
        confirmations[transactionHash][msg.sender] = false;
        Revocation(msg.sender, transactionHash);
    }

    function MultiSigWallet(address[] _owners, uint _required)
        validRequired(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++)
            isOwner[_owners[i]] = true;
        owners = _owners;
        required = _required;
    }

    function()
        payable
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

    function isConfirmed(bytes32 transactionHash)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionHash][owners[i]])
                count += 1;
            if (count == required)
                return true;
    }

    function confirmationCount(bytes32 transactionHash)
        external
        constant
        returns (uint count)
    {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionHash][owners[i]])
                count += 1;
    }

    function filterTransactions(bool isPending)
        private
        constant
        returns (bytes32[] _transactionList)
    {
        bytes32[] memory _transactionListTemp = new bytes32[](transactionList.length);
        uint count = 0;
        for (uint i=0; i<transactionList.length; i++)
            if (   isPending && !transactions[transactionList[i]].executed
                || !isPending && transactions[transactionList[i]].executed)
            {
                _transactionListTemp[count] = transactionList[i];
                count += 1;
            }
        _transactionList = new bytes32[](count);
        for (i=0; i<count; i++)
            if (_transactionListTemp[i] > 0)
                _transactionList[i] = _transactionListTemp[i];
    }

    function getPendingTransactions()
        external
        constant
        returns (bytes32[])
    {
        return filterTransactions(true);
    }

    function getExecutedTransactions()
        external
        constant
        returns (bytes32[])
    {
        return filterTransactions(false);
    }
    
    function createCoin()
        external
        onlyWallet
    {
        CoinCreation(new RoseCoin());
    }
}