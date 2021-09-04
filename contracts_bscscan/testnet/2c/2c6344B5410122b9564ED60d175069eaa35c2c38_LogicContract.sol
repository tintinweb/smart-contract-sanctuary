/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

contract Vault {
    
    enum Type {
        Deposit,
        Withdrawal
    }
    
    struct Transaction {
        address user;
        uint256 timestamp;
        Type transactionType;
        uint256 amount;
    }
    
    address public lastCaller;
    
    uint256 private numberOne;
    bool private boolean;
    
    uint256 public transactionLastId;
    mapping(uint256 => Transaction) public transactions;
    
    function getNumberOne() external view returns(uint256) {
        return numberOne;
    }
    
    function getBoolean() external view returns(bool) {
        return boolean;
    }
    
    function getTranasction(uint256 id) external view returns(Transaction memory) {
        return transactions[id];
    }
    
    function setNumberOne(uint256 _numberOne) external {
        numberOne = _numberOne;
        lastCaller = msg.sender;
    }
    
    function setBoolean(bool _boolean) external {
        boolean = _boolean;
        lastCaller = msg.sender;
    }
    
    function addNewTransaction(Transaction memory transaction) external {
        transactions[transactionLastId] = transaction;
        
        transactionLastId += 1;
        
        lastCaller = msg.sender;
    }
    
}

contract LogicContract {
    uint public num;
    address public sender;
    uint public value;
    
    Vault public vault;
    
    function initialize(address _vault) external {
        vault = Vault(_vault);
    }
    
    function getNumberOne() external view returns(uint256 numberOne) {
        return vault.getNumberOne();
    }
    
    function getBoolean() external view returns(bool boolean) {
        return vault.getBoolean();
    }
    
    function getTranasction(uint256 id) external view returns(Vault.Transaction memory transaction) {
        return vault.getTranasction(id);
    }
    
    
    function setNumberOne(uint256 _numberOne) external {
        vault.setNumberOne(_numberOne);
    }
    
    function setBoolean(bool _boolean) external {
        vault.setBoolean(_boolean);
    }
    
    function makeTransaction(uint256 amount) external {
        vault.addNewTransaction(Vault.Transaction(msg.sender,block.timestamp, Vault.Type(0), amount));
    }

    function setVars(uint _num) external payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}