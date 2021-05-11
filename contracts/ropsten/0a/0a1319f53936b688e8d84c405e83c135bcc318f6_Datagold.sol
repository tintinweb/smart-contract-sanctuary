/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**
 *  1. Our metadata model will conform to the dublin core standard, aka, ISO 15836,[1] ANSI/NISO Z39.85,[2] and IETF RFC 5013. 
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
    
    
    address payable contractOwner;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    mapping(uint => mapping(string => string)) metadata; // dataid, key, value
    mapping(uint => address) datasetOwners; // the ownership of a dataset
    mapping(uint => address) datasetDelegates; // the delegate of a dataset, who can change its ownership

    event BuyDatagold(uint inAmt, uint outAmt);
    event InsertMetadata(uint indexed datasetId, string indexed key, string value);
    event AssignDatasetId(uint indexed datasetId, address indexed account);
    event TransferDatasetOwner(uint indexed datasetId, address indexed oldOwner, address indexed newOwner);
    
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

    modifier onlyOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
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
    public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId][key] = value;
        emit InsertMetadata(datasetId, key, value);
        
        return true;
    }
    
    // 1. contributor 
    function insertContributor(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['contributor'] = value;
        emit InsertMetadata(datasetId, 'contributor', value);
        
        return true;
    }
    
    // 2. coverage
    function insertCoverage(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['coverage'] = value;
        emit InsertMetadata(datasetId, 'coverage', value);
        
        return true;
    }
    
    // 3. creator
    function insertCreator(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['creator'] = value;
        emit InsertMetadata(datasetId, 'creator', value);
        
        return true;
    }
    
    // 4. date
    function insertDate(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['date'] = value;
        emit InsertMetadata(datasetId, 'date', value);
        
        return true;
    }
    
    // 5. description
    function insertDescription(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['description'] = value;
        emit InsertMetadata(datasetId, 'description', value);
        
        return true;
    }    

    // 6. format 
    function insertFormat(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['format'] = value;
        emit InsertMetadata(datasetId, 'format', value);
        
        return true;
    }    
    
    // 7. identifier
    function insertIdentifier(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['identifier'] = value;
        emit InsertMetadata(datasetId, 'identifier', value);
        
        return true;
    }   
    
    // 8. language  
    function insertLanguage(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['language'] = value;
        emit InsertMetadata(datasetId, 'language', value);
        
        return true;
    }   
    
     // 9. publisher 
    function insertPublisher(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['publisher'] = value;
        emit InsertMetadata(datasetId, 'publisher', value);
        
        return true;
    }   
    
     // 10. relation
    function insertRelation(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['relation'] = value;
        emit InsertMetadata(datasetId, 'relation', value);
        
        return true;
    }   
    
    // 11. rights
    function insertRights(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['rights'] = value;
        emit InsertMetadata(datasetId, 'rights', value);
        
        return true;
    }     
    
    // 12. source
    function insertSource(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['source'] = value;
        emit InsertMetadata(datasetId, 'source', value);
        
        return true;
    }     
    
    // 13. subject
    function insertSubject(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['subject'] = value;
        emit InsertMetadata(datasetId, 'subject', value);
        
        return true;
    } 
    
    // 14. title
    function insertTitle(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['title'] = value;
        emit InsertMetadata(datasetId, 'title', value);
        
        return true;
    }     
    
     // 15. type
    function insertType(uint datasetId, string memory value)
     public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        metadata[datasetId]['type'] = value;
        emit InsertMetadata(datasetId, 'type', value);
        
        return true;
    }     
      
        
    
       


    function queryMetadata(uint datasetId, string memory key) public view returns (string memory value)
    {
        return metadata[datasetId][key];
    }


    // 1. contributor
    function queryContributor(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['contributor'];
    }

    // 2. coverage
    function queryCoverage(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['coverage'];
    }

    // 3. creator
    function queryCreator(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['creator'];
    }
    
    // 4. date 
    function queryDate(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['date'];
    }
    
    // 5. description
    function queryDescription(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['description'];
    }
   
   // 6. format
    function queryFormat(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['format'];
    }
    
   // 7. identifier
    function queryIdentifier(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['identifier'];
    }
    
    // 8. language
    function queryLanguage(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['language'];
    } 

    // 9. publisher
    function queryPublisher(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['publisher'];
    }      
  
   // 10. relation
    function queryRelation(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['relation'];
    }      
     
   // 11. rights
    function queryRights(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['rights'];
    } 
    
   // 12. source
    function querySource(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['source'];
    }
    
   // 13. subject
    function querySubject(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['subject'];
    }    
    
   // 14. title
    function queryTitle(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['title'];
    }    
  
   // 15.  type
    function queryType(uint datasetId) public view returns (string memory value)
    {
        return metadata[datasetId]['type'];
    }  
    
    
    /* only the dataset owner or the delegate can transfer the ownership of a dataset */
    function transferDatasetOwner(uint datasetId, address newOwner) public
    returns (bool success)
    {
        require(datasetOwners[datasetId] == msg.sender || datasetDelegates[datasetId] == msg.sender);
        emit TransferDatasetOwner(datasetId, datasetOwners[datasetId], newOwner);
        datasetOwners[datasetId] = newOwner;
        
        return true;
    }
    
    /* only the owner of a dataset can assign a delegate, the delegate can change the ownership of a dataset */
    function assignDatasetDeletegate(uint datasetId, address delegate)
    public 
    returns (bool success)
    {
        require(datasetOwners[datasetId] == msg.sender);
        
        datasetDelegates[datasetId] = delegate;
        return true;
    }
    

    
}