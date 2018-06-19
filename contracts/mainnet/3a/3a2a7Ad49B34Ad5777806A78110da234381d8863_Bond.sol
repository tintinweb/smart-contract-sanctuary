pragma solidity 0.4.16;


contract Bond {
    
    uint public issuerDateMinutes;
    string public issuerName;
    string public name;
    string public description;
    uint128 public totalAssetUnits;
    uint128 public totalFiatValue;
    uint128 public fiatPerAssetUnit;
    uint128 public interestRate;
    string public fiatCurrency;
    uint16 public paymentPeriods;

    address public owner;
    string bondID; 
    address public issuer;
    address public escrowContract;
    mapping(address => uint128) balances;
    
    bool public matured;
    uint public matured_block_number;
    uint public matured_timestamp;
    
    event TxExecuted(uint32 indexed event_id);

    function Bond(
        uint _issuerDateMinutes,
        string _issuerName,
        string _name,
        string _description,
        uint128 _totalAssetUnits,
        uint128 _totalFiatValue,
        uint128 _fiatPerAssetUnit,
        uint128 _interestRate,
        uint16 _paymentPeriods,
        string _bondID,
        string _fiatCurrency,
        address _escrowContract) {
            issuerDateMinutes = _issuerDateMinutes;
            issuerName = _issuerName;
            name = _name;
            description = _description;
            totalAssetUnits = _totalAssetUnits;
            totalFiatValue = _totalFiatValue;
            fiatPerAssetUnit = _fiatPerAssetUnit;
            interestRate = _interestRate;
            paymentPeriods = _paymentPeriods;
            fiatCurrency = _fiatCurrency;
                        
            owner = msg.sender;
            bondID = _bondID;
            escrowContract = _escrowContract;
            matured = false;
    }
    
    modifier onlyOwner() {
        if(msg.sender == owner) _;
    }
    
    modifier onlyIssuer() {
        if(msg.sender == issuer) _;
    }
    
    function setMatured(uint32 event_id) onlyOwner returns (bool success) {
        if(matured==false){
            matured = true;
            matured_block_number = block.number;
            matured_timestamp = block.timestamp;
            TxExecuted(event_id);
        }        
        return true;
    }
    
    function checkBalance(address account) constant returns (uint128 _balance) {
        if(matured)
            return 0;
        return balances[account];
    }
    
    function getTotalSupply() constant returns (uint supply) {
        return totalAssetUnits;
    }
    
    function setIssuer(address _issuer, uint32 event_id) onlyOwner returns (bool success) {
        if(matured==false && issuer==address(0)){
            issuer = _issuer;
            balances[_issuer] = totalAssetUnits;
            TxExecuted(event_id);
            return true;
        }
        return false;
    }
    
    function getIssuer() constant returns (address _issuer) {
        return issuer;
    }
    
    struct Transfer {
        uint128 lockAmount;
        bytes32 currencyAndBank;
        address executingBond;
        address lockFrom;
        address issuer;
        uint128 assetAmount;
        uint128 balancesIssuer;
        uint32 event_id;
        bool first;
        bool second;
    }
    mapping (bytes16 => Transfer) public transferBond; 
    function transfer(uint128 assetAmount, bytes16 lockID, uint32 event_id) onlyIssuer returns (bool success) {
        if(matured==false){
            uint128 lockAmount;
            bytes32 currencyAndBank;
            address executingBond;
            address lockFrom;
            transferBond[lockID].assetAmount = assetAmount;
            transferBond[lockID].event_id = event_id;
            Escrow escrow = Escrow(escrowContract);        
            (lockAmount, currencyAndBank, lockFrom, executingBond) = escrow.lockedMoney(lockID);
            transferBond[lockID].lockAmount = lockAmount;
            transferBond[lockID].currencyAndBank = currencyAndBank;
            transferBond[lockID].executingBond = executingBond;
            transferBond[lockID].lockFrom = lockFrom;
            transferBond[lockID].issuer = issuer;
            transferBond[lockID].balancesIssuer = balances[issuer];
            transferBond[lockID].first = balances[issuer]>=assetAmount;
            transferBond[lockID].second = escrow.executeLock(lockID, issuer)==true;        
            if(transferBond[lockID].first && transferBond[lockID].second){ 
                balances[lockFrom] += assetAmount;
                balances[issuer] -= assetAmount;
                TxExecuted(event_id);
                return true;
            }
        }
        return false;
    }
}

contract Escrow{
    
    function Escrow() {
        owner = msg.sender;
    }

    mapping (address => mapping (bytes32 => uint128)) public balances;
    mapping (bytes16 => Lock) public lockedMoney;
    address public owner;
    
    struct Lock {
        uint128 amount;
        bytes32 currencyAndBank;
        address from;
        address executingBond;
    }
    
    event TxExecuted(uint32 indexed event_id);
    
    modifier onlyOwner() {
        if(msg.sender == owner)
        _;
    }
    
    function checkBalance(address acc, string currencyAndBank) constant returns (uint128 balance) {
        bytes32 cab = sha3(currencyAndBank);
        return balances[acc][cab];
    }
    
    function getLocked(bytes16 lockID) returns (uint) {
        return lockedMoney[lockID].amount;
    }
    
    function deposit(address to, uint128 amount, string currencyAndBank, uint32 event_id) 
        onlyOwner returns(bool success) {
            bytes32 cab = sha3(currencyAndBank);
            balances[to][cab] += amount;
            TxExecuted(event_id);
            return true;
    } 
    
    function withdraw(uint128 amount, string currencyAndBank, uint32 event_id) 
        returns(bool success) {
            bytes32 cab = sha3(currencyAndBank);
            require(balances[msg.sender][cab] >= amount);
            balances[msg.sender][cab] -= amount;
            TxExecuted(event_id);
            return true;
    }
    
    function lock(uint128 amount, string currencyAndBank, address executingBond, bytes16 lockID, uint32 event_id) 
        returns(bool success) {   
            bytes32 cab = sha3(currencyAndBank);
            require(balances[msg.sender][cab] >= amount);
            balances[msg.sender][cab] -= amount;
            lockedMoney[lockID].currencyAndBank = cab;
            lockedMoney[lockID].amount += amount;
            lockedMoney[lockID].from = msg.sender;
            lockedMoney[lockID].executingBond = executingBond;
            TxExecuted(event_id);
            return true; 
    }
    
    function executeLock(bytes16 lockID, address issuer) returns(bool success) {
        if(msg.sender == lockedMoney[lockID].executingBond){
	        balances[issuer][lockedMoney[lockID].currencyAndBank] += lockedMoney[lockID].amount;            
	        delete lockedMoney[lockID];
	        return true;
		}else
		    return false;
    }
    
    function unlock(bytes16 lockID, uint32 event_id) onlyOwner returns (bool success) {
        balances[lockedMoney[lockID].from][lockedMoney[lockID].currencyAndBank] +=
            lockedMoney[lockID].amount;
        delete lockedMoney[lockID];
        TxExecuted(event_id);
        return true;
    }
    
    function pay(address to, uint128 amount, string currencyAndBank, uint32 event_id) 
        returns (bool success){
            bytes32 cab = sha3(currencyAndBank);
            require(balances[msg.sender][cab] >= amount);
            balances[msg.sender][cab] -= amount;
            balances[to][cab] += amount;
            TxExecuted(event_id);
            return true;
    }
}