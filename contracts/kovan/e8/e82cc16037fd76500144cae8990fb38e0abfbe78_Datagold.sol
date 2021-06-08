/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

/**
 * 
 * Datagold 003: 6/7/2021. We introduced the notion of listing. A dataset needs to be registered to get a unique datasetID and then gets 
 *    listed for sale. A unique listingID will be assigned for each listing. A listing can be listed (1), sold (2), or unlisted (3).
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
    address payable trustAccount;

   // datagold coins
    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance

    // listing information
    uint public lastListingID = 1000000000; // the genesis listingID
    mapping(uint => uint) listingPrice;        // price in datagold units
    mapping(uint => uint) listingDatasetID;    // which dataset is for sale for this listing
    mapping(uint => address) listingOwners; // need to record of the owner of this listing
    mapping(uint => uint) listingStatus;   // 1: listed; 2: sold; 3: unlisted, onced sold or unlisted, the listing is closed. 
    
    // the profile of a dataset
    mapping(uint => mapping(string => string)) metadata; // dataid, key, value
    mapping(uint => address) datasetOwners; // the ownership of a dataset

    
    // the profile of an account
    mapping(address => mapping(string => string)) accountInfo; // address, key, value

    event AssignDatasetId(uint indexed datasetId, address indexed account);
    event Sold(uint indexed listingID, uint indexed datasetID, address oldOwner, address newOwner, uint price);
    event TransferDatasetOwner(uint indexed datasetId, address indexed oldOwner, address indexed newOwner);
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address payable trustAcc) public {
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
    
 
    modifier onlyDatasetOwner(uint datasetID){
       require(msg.sender == datasetOwners[datasetID], "only the dataset owner can call this function. ");
       _;
    }
    
    
    /*
    function() external payable {
        revert();  
    }
    */
    

    function insertMetadata(uint datasetId, string memory key, string memory value)     
    onlyDatasetOwner(datasetId)
    public returns (bool success){
        metadata[datasetId][key] = value;
        
        return true;
    }
    
    // called by any one who likes to sell a dataset 
    function registerDatasetProfile(string memory contributor, 
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
  
    
    function listForSale(uint datasetID, uint price)
    onlyDatasetOwner(datasetID)
    public returns (uint){
        lastListingID = lastListingID + 1;
        listingDatasetID[lastListingID] = datasetID;
        listingOwners[lastListingID] =  msg.sender;
        listingPrice[lastListingID] = price;
        listingStatus[lastListingID] = 1;
        
        return lastListingID;
    }  
    
    function getListingDatasetID(uint listingID)
    public view
    returns (uint)
    {
      return listingDatasetID[listingID];
      
    }
    
    function getListingOwner(uint listingID)
    public view
    returns (address)
    {
      return listingOwners[listingID];
      
    }
    
    function getListingPrice(uint listingID)
    public view
    returns (uint)
    {
      return listingPrice[listingID];
      
    }    

    function getListingStatus(uint listingID)
    public view
    returns (uint)
    {
      return listingStatus[listingID];
      
    }    

 
    function unlistFromSale(uint listingID)
    public returns(bool)
    {
          require(listingStatus[listingID] == 1);
          
          require(listingOwners[listingID] == msg.sender, "Only the owner of the listing can unlist it.");
          listingStatus[listingID] = 3;
          
          return true;
    }
    

    /* We need to make sure that the current owner of the dataset is the owner that posted the listing 
       a listing is invalid once the owner of a dataset has changed */
    function purchaseDataset(uint listingID)
    external 
    returns (bool)
    {
        require(listingStatus[listingID] == 1);
        
        uint datasetID = listingDatasetID[listingID];
        require(listingOwners[listingID] == datasetOwners[datasetID], "The owner of the dataset has changed, the listing is not valid anymore.");
        
        address buyer = msg.sender;
        
        uint price = listingPrice[listingID];
        uint amtToContract = safeDiv(safeMul(price, 3), 100);
        uint amtToSeller = safeSub(price, amtToContract);

        address seller = datasetOwners[datasetID];
        balances[buyer] = safeSub(balances[buyer], price);
        balances[address(this)] = safeAdd(balances[address(this)], amtToContract);
        balances[seller] = safeAdd(balances[seller], amtToSeller);
        
        datasetOwners[datasetID] = buyer;
        listingStatus[listingID] = 2;
        emit Sold(listingID, datasetID, seller, buyer, listingPrice[listingID]);
 
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

    
    function queryPrice(uint listingID) public view returns (uint)
    {
        return listingPrice[listingID];
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
    
    /* Exeriment only: a user can buy DGC by sending ETH to this contract address */
    function() external payable {
        balances[trustAccount] = safeSub(balances[trustAccount], msg.value*100); // 1 ETH = 100 DGC
        balances[msg.sender] = safeAdd(balances[msg.sender], msg.value*100);
        trustAccount.transfer(msg.value);
    }
}