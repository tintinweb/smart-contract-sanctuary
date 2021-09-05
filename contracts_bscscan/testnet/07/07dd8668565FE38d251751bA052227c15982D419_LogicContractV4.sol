/**
 *Submitted for verification at BscScan.com on 2021-09-04
*/

contract LogicContractV4 {
    
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
    
    struct Donation {
        address user;
        uint256 amount;
        uint256 timestamp;
    }
    
    uint256 private numberOne;
    bool private boolean;
    
    uint256 public transactionLastId;
    uint256 public donationLastId;
    uint256 public unusedVariable; 
    
    mapping(uint256 => Transaction) private transactions;
    mapping(uint256 => Donation) private donations;
    
    function getVersion() external pure returns(string memory){
        return "V4";
    }
    
    function getNumberOne() external view returns(uint256) {
        return numberOne;
    }
    
    function getBoolean() external view returns(bool) {
        return boolean;
    }
    
    function getTranasction(uint256 id) external view returns(Transaction memory) {
        return transactions[id];
    }
    
    function getDonation(uint256 id) external view returns(Donation memory) {
        return donations[id];
    }
    
    function setNumberOne(uint256 _numberOne) external {
        numberOne = _numberOne;
    }
    
    function setBoolean(bool _boolean) external {
        boolean = _boolean;
    }
    
    function addNewTransaction(Transaction memory transaction) external {
        transactions[transactionLastId] = transaction;
        
        transactionLastId += 1;
    }
    
    function addNewDonation(Donation memory donation) external {
        donations[donationLastId] = donation;
        
        donationLastId += 1;
    }
}