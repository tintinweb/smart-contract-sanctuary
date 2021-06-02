/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

/**
 * 
 * Datagold 002: 6/2/2021. Symbol: DGC (Data Gold Coins). Write an insertManyMetaData function for efficiency. 10M as the total supply
 * Datagold 001: 5/12/2021.    
 *    1) Our metadata model supports the metadata of a dataset and the metadata/profile for an account. 
 *    2) We will also support the price metadata in terms of PPS
 *    Recommendation 1: enum DatasetProfile {contributor, coverage, creator, date, description, format,  identifier, language, publisher, relation, rights, source, subject, title, type}
 *    Recommendation 2: enum AccountProfile {firstname, lastname, organization, street1, street2, city, state, province, zip, country, email, phone, fax, website}
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
    string public constant symbol = "DGC";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant totalSupply = 10000000*10**18; // 10M is the total supply
    uint public lastDatasetId = 1000000000; // the genesis datasetId
    
    
    address contractOwner;
    address trustAccount;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    mapping(uint => mapping(string => string)) metadata; // dataid, key, value
    mapping(uint => uint) priceInDGC;        // price in datagold units
    mapping(uint => address) datasetOwners; // the ownership of a dataset
    mapping(uint => address) sellerAgents; // the seller agent of a dataset, who can change its ownership, a seller agent corresponds to a website
    
    
    // the following mappings are for the profile of each address, the data owner, optional
    mapping(address => mapping(string => string)) accountInfo; // address, key, value

    event AssignDatasetId(uint indexed datasetId, address indexed account);
    event TransferDatasetOwner(uint indexed datasetId, address indexed oldOwner, address indexed newOwner);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address trustAcc) public {
        trustAccount = trustAcc;
        contractOwner = msg.sender;
        balances[trustAccount] = totalSupply;
        emit Transfer(address(0), trustAccount, totalSupply);
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
    
    modifier onlySellerAgent(uint datasetId){
       require(msg.sender == sellerAgents[datasetId], "only the seller agent of the dataset can call this function. ");
       _;
    }
 
    modifier onlyDatasetOwner(uint datasetId){
       require(msg.sender == datasetOwners[datasetId], "only the dataset owner can call this function. ");
       _;
    }
    
    function() external payable {
        revert();  // not allowing peopole to send ETH here
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
        
        return true;
    }
    
    // called by any one who likes to sell a dataset 
    function insertDatasetProfile(string memory contributor, 
                              string memory coverage, 
                              string memory creator, 
                              string memory date, 
                              string memory description, 
                              string memory format,  
                              string memory identifier, 
                              string memory language, 
                              string memory publisher, 
                              string memory relation, 
                              string memory rights, 
                              string memory source, 
                              string memory subject, 
                              string memory title, 
                              string memory dtype)
    public returns (uint)
    {
        lastDatasetId = lastDatasetId + 1;
        datasetOwners[lastDatasetId] = msg.sender;
        emit AssignDatasetId(lastDatasetId, msg.sender);
        metadata[lastDatasetId]['contributor'] = contributor;
        metadata[lastDatasetId]['coverage'] = coverage;
         metadata[lastDatasetId]['creator'] = creator;
         metadata[lastDatasetId]['date'] = date;
         metadata[lastDatasetId]['description'] = description;
         metadata[lastDatasetId]['format'] = format;
         metadata[lastDatasetId]['identifier'] = identifier;
         metadata[lastDatasetId]['language'] = language;
         metadata[lastDatasetId]['publisher'] = publisher;
         metadata[lastDatasetId]['relation'] = relation;
         metadata[lastDatasetId]['rights'] = rights;
         metadata[lastDatasetId]['source'] = source;
         metadata[lastDatasetId]['subject'] = subject;
         metadata[lastDatasetId]['title'] = title;
         metadata[lastDatasetId]['type'] = dtype;
         
         return lastDatasetId;
    }
  
     
    function insertPrice(uint datasetId, uint newPrice)
    onlyDatasetOwner(datasetId)
    public returns (bool success){
        priceInDGC[datasetId] = newPrice;
        
        return true;
    }  
    
    function insertAccountInfo(string memory key, string memory value)
    public returns (bool success){
        accountInfo[msg.sender][key] = value;
        return true;
    }
    
    function insertAccountProfile(
                  string memory firstname,
                  string memory lastname, 
                  string memory organization, 
                  string memory street1, 
                  string memory street2, 
                  string memory city, 
                  string memory state, 
                  string memory province, 
                  string memory zip, 
                  string memory country, 
                  string memory email, 
                  string memory phone, 
                  string memory fax, 
                  string memory website
                  )
    public returns(bool)
    {
        accountInfo[msg.sender]['firstname'] = firstname;
        accountInfo[msg.sender]['lastname'] = lastname;
        accountInfo[msg.sender]['organization'] = organization;
        accountInfo[msg.sender]['street1'] = street1;
        accountInfo[msg.sender]['street2'] = street2;
        accountInfo[msg.sender]['city'] = city;
        accountInfo[msg.sender]['state'] = state;
        accountInfo[msg.sender]['province'] = province;
        accountInfo[msg.sender]['zip'] = zip;
        accountInfo[msg.sender]['country'] = country;
        accountInfo[msg.sender]['email'] = email;
        accountInfo[msg.sender]['phone'] = phone;
        accountInfo[msg.sender]['fax'] = fax;
        accountInfo[msg.sender]['website'] = website;
      
        return true;  
    } 


    
    function queryMetadata(uint datasetId, string memory key) public view returns (string memory value)
    {
        return metadata[datasetId][key];
    }

    
    function queryPrice(uint datasetId) public view returns (uint priceOfData)
    {
        return priceInDGC[datasetId];
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
    onlySellerAgent(datasetId)
    returns (bool success)
    {
        uint amtTotheSeller = priceInDGC[datasetId];
        uint amtToContractOwner = safeDiv(safeMul(amtTotheSeller, 3), 100);
        uint amtToDelegate = safeDiv(safeMul(amtTotheSeller, 3), 100);
        amtTotheSeller = safeSub(amtTotheSeller, amtToContractOwner);
        amtTotheSeller = safeSub(amtTotheSeller, amtToDelegate);
        
        address datasetOwner = datasetOwners[datasetId];
        transferFrom(newOwner, contractOwner, amtToContractOwner);
        transferFrom(newOwner, sellerAgents[datasetId], amtToDelegate);
        transferFrom(newOwner, datasetOwner, amtTotheSeller);
        
        datasetOwners[datasetId] = newOwner;
        emit TransferDatasetOwner(datasetId, datasetOwners[datasetId], newOwner);
  
        return true;      
    }
    
    
    /* only the owner of a dataset can assign a seller agent, the seller agent can change the ownership of a dataset
       and can perform the sellDataset functions. We assume a market 
       of multiple seller agents, each seller agent has its own website. */
    function assignSellerAgent(uint datasetId, address agent)
    onlyDatasetOwner(datasetId)
    public 
    returns (bool success)
    {
        sellerAgents[datasetId] = agent;
        return true;
    }
}