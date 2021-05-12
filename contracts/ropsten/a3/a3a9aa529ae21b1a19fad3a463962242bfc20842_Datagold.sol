/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

/**
 * 
 *  1. Our metadata model supports the metadata of a dataset and the metadata/profile for an account. 
 *  2. We will also support the price metadata in terms of PPS
*
*/
pragma solidity ^0.5.0;

/*
    ERC20 Standard Token interface
*/
contract ERC20Interface{ // six  functions
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}

// ----------------------------------------------------------------------------
// Safe Math Contract
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


contract Datagold is ERC20Interface, SafeMath{
    string public constant name = "Datagold";
    string public constant symbol = "DAT";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant totalSupply = 1000000000*10**18;
    uint public lastDatasetId = 1000000000; // the genesis datasetId
    
    //  enum DatasetProfile {contributor, coverage, creator, date, description, format,  identifier, language, publisher, relation, rights, source, subject, title, dtype}
    // enum AccountProfile {firstName, lastName, organization, street1, street2, city, state, province, zip, country, email, phone, fax, website}
    
    address payable contractOwner;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    mapping(uint => mapping(string => string)) metadata; // dataid, key, value
    mapping(uint => uint) price; // dataid, price
    mapping(uint => address) datasetOwners; // the ownership of a dataset
    mapping(uint => address) datasetDelegates; // the delegate of a dataset, who can change its ownership
    
    
    // the following mappings are for the profile of each address, the data owner, optional
    mapping(address => mapping(string => string)) accountInfo; // address, key, value

    event BuyDatagold(uint inAmt, uint outAmt);
    event InsertMetadata(uint indexed datasetId, string indexed key, string value);
    event InsertPrice(uint indexed datasetId, uint price);
    event AssignDatasetId(uint indexed datasetId, address indexed account);
    event TransferDatasetOwner(uint indexed datasetId, address indexed oldOwner, address indexed newOwner);
    event InsertAccountInfo(address indexed account, string indexed key, string  value);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        contractOwner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // called by the owner
    function approve(address spender, uint rawAmt) public returns (bool success) {
        allowed[msg.sender][spender] = rawAmt;
        emit Approval(msg.sender, spender, rawAmt);
        return true;
    }

    function transfer(address to, uint rawAmt) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(msg.sender, to, rawAmt);
        return true;
    }

    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        balances[from] = safeSub(balances[from], rawAmt);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }

    modifier onlyContractOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    modifier onlyDelegate(uint datasetId){
       require(msg.sender == datasetDelegates[datasetId], "only the delegate of the dataset can call this function. ");
       _;
    }
 
    modifier onlyDatasetOwner(uint datasetId){
       require(msg.sender == datasetOwners[datasetId], "only the dataset owner can call this function. ");
       _;
    }
    
    /* send back my tokens when people send me PPS */
    function() external payable {
        buyDatagold();
    }
    
    
    function buyDatagold() public payable {
        balances[contractOwner] = safeSub(balances[contractOwner], msg.value*330000);
        balances[msg.sender] = safeAdd(balances[msg.sender], msg.value*330000);
        contractOwner.transfer(msg.value);
        emit BuyDatagold(msg.value, msg.value*100);
    }
    
    function assignDatasetId() public returns (uint)
    {
        lastDatasetId = lastDatasetId + 1;
        datasetOwners[lastDatasetId] = msg.sender;
        emit AssignDatasetId(lastDatasetId, msg.sender);
        return lastDatasetId;
    }
    
    
    
    function insertMetadata(uint datasetId, string memory key, string memory value)     
    onlyDatasetOwner(datasetId)
    public returns (bool success){
        metadata[datasetId][key] = value;
        emit InsertMetadata(datasetId, key, value);
        
        return true;
    }
    
  
     
    function insertPrice(uint datasetId, uint newPrice)
    onlyDatasetOwner(datasetId)
    public returns (bool success){
        price[datasetId] = newPrice;
        emit InsertPrice(datasetId, newPrice);
        
        return true;
    }  
    
    function insertAccountInfo(string memory key, string memory value)
    public returns (bool success){
        accountInfo[msg.sender][key] = value;
        emit InsertAccountInfo(msg.sender, key, value);
        return true;
    }
    

    
    function queryMetadata(uint datasetId, string memory key) public view returns (string memory value)
    {
        return metadata[datasetId][key];
    }

    
    function queryPrice(uint datasetId) public view returns (uint priceOfData)
    {
        return price[datasetId];
    }  
    

    function queryAccountInfo(address account, string memory key) public view returns (string memory)
    {
        return accountInfo[account][key];
    }
    
    function getDatasetOwner(uint datasetId) public view returns (address){
        return datasetOwners[datasetId];
    }


    /* only the dataset owner or the delegate can transfer the ownership of a dataset */
    function transferDatasetOwner(uint datasetId, address newOwner) public
    onlyDatasetOwner(datasetId)
    returns (bool success)
    {
        datasetOwners[datasetId] = newOwner;
        emit TransferDatasetOwner(datasetId, datasetOwners[datasetId], newOwner);
 
        return true;
    }
    
    function sellDataset(uint datasetId, address newOwner) public
    onlyDelegate(datasetId)
    returns (bool success)
    {
        uint amtTotheSeller = price[datasetId];
        uint amtToContractOwner = safeDiv(safeMul(amtTotheSeller, 3), 100);
        uint amtToDelegate = safeDiv(safeMul(amtTotheSeller, 3), 100);
        amtTotheSeller = safeSub(amtTotheSeller, amtToContractOwner);
        amtTotheSeller = safeSub(amtTotheSeller, amtToDelegate);
        
        address datasetOwner = datasetOwners[datasetId];
        transferFrom(newOwner, contractOwner, amtToContractOwner);
        transferFrom(newOwner, datasetDelegates[datasetId], amtToDelegate);
        transferFrom(newOwner, datasetOwner, amtTotheSeller);
        
        datasetOwners[datasetId] = newOwner;
        emit TransferDatasetOwner(datasetId, datasetOwners[datasetId], newOwner);
  
        return true;      
    }
    
    
    /* only the owner of a dataset can assign a delegate, the delegate can change the ownership of a dataset
       and the delegate is like a seller agent and can perform the sellDataset functions. We assume a market 
       of multiple seller agents */
    function assignDatasetDelegate(uint datasetId, address delegate)
    onlyDatasetOwner(datasetId)
    public 
    returns (bool success)
    {
        datasetDelegates[datasetId] = delegate;
        return true;
    }
}