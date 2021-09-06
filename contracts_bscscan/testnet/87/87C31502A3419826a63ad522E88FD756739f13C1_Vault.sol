/**
 *Submitted for verification at BscScan.com on 2021-09-06
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