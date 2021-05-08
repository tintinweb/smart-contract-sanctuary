/**
 *Submitted for verification at Etherscan.io on 2021-05-08
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
    mapping(uint => mapping(string => string)) publicMetadata; // dataid, key, value
    mapping(uint => mapping(string => string)) privateMetadata; // only the owner can query
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
    
    // metadata functions, owerContract only
    function insertPublicMetadata(uint datasetId, string memory key, string memory value) 
    //onlyOwner
    public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        publicMetadata[datasetId][key] = value;
        emit InsertMetadata(datasetId, key, value);
        
        return true;
    }
    
    function queryPublicMetadata(uint datasetId, string memory key) public view returns (string memory value)
    {
        return publicMetadata[datasetId][key];
    }


    // metadata functions, owerContract only
    function insertPrivateMetadata(uint datasetId, string memory key, string memory value) 
    //onlyOwner
    public returns (bool success){
        require(datasetOwners[datasetId] == msg.sender); // each dataset can only have one curator
        privateMetadata[datasetId][key] = value;
        emit InsertMetadata(datasetId, key, value);
        
        return true;
    }
    
    function queryPrivateMetadata(uint datasetId, string memory key) public view returns (string memory value)
    {
        require(datasetOwners[datasetId] == msg.sender); // only the dataset owner can query this metadata
        return privateMetadata[datasetId][key];
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