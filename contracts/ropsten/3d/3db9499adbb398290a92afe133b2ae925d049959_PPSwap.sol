/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// PPSwap014: 5/27/2021. Bob will make an offer with an orderID, the information of which will be stored in 
//                       the blockchain, and then Kathy will accept the offer with that orderID.
// PPSwap013: 5/26/2021. We will charge swap fees by ETH not by PPS. Both swap parties will be rewardsed with some PPS! The swap fees are 
//                       paid by Kathy not by Bob as Bob is a market maker. 
// PPSwap012: 5/15/2021: Only the contract owner or its delegate can call the safeSwap function. Only the delegate can set swapfeePerTrans, 
//            which is initally set to zero.  
// PPSwap011: 5/6/2021, the swap fee per transaction is defined by swapfeePerTrans.  
// PPSwap010: 5/6/2021, we combine PPSwap with PPS so that a user can buy PPS via sending ETH to the contract address.
//            We fixed the exchangeRate between PPS and ETH with the understanding that eventually the market will take over. 
// PPSwap009: 5/5/2021, now we can exchange two arbitrary ERC20 tokens. 
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface

contract ERC20Interface { // five  functions and four implicit getters
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint rawAmt) public returns (bool success);
    function approve(address spender, uint rawAmt) public returns (bool success);
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint rawAmt);
    event Approval(address indexed tokenOwner, address indexed spender, uint rawAmt);
}

// ----------------------------------------------------------------------------
// Safe Math Library
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

contract PPSwap is ERC20Interface, SafeMath{
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1000000000*10**18;
    uint public swapfeePerTrans = 0; // in terms of wei, no swap fee initially
    uint public rewardsPerParty = 1*10**18; // 1 PPS reward for each party
    uint public lastOrderID = 1*10**9; // the genesis orderID

    address  public contractOwner;
    address public contractOwnerDelegate;
    address  payable public trustAccount;

    mapping(uint => mapping(string => address)) orders; // orderID, key, value
    mapping(uint => mapping(string => uint)) orderAmts; // orderID, key, value
    mapping(uint => bool) orderStatus;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
  
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(address payable newTrustAccount) public { 
        contractOwner = msg.sender;
        contractOwnerDelegate = msg.sender; // default delegate
        trustAccount = newTrustAccount;
        uint amt = safeDiv(_totalSupply, 2);
        balances[trustAccount] = amt;  // half for the contract owner 
        balances[address(this)] = amt;  // half free rewards for the community
        emit Transfer(address(0), trustAccount, amt);
        emit Transfer(address(0), address(this), amt);
  
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


     modifier onlyContractOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    modifier onlyContractOwnerDelegate(){
       require(msg.sender == contractOwnerDelegate, "Only the contract owner's delegate can call this function.");
       _;
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

    
    // ERC the allowence function should be more specic +-
    function transferFrom(address from, address to, uint rawAmt) public returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], rawAmt); // this will ensure the spender indeed has the authorization
        balances[from] = safeSub(balances[from], rawAmt);
        balances[to] = safeAdd(balances[to], rawAmt);
        emit Transfer(from, to, rawAmt);
        return true;
    }    
    
    function setSwapfee(uint _swapfeePerTrans) 
        external 
        onlyContractOwnerDelegate
        returns (bool success)
    {
        swapfeePerTrans = _swapfeePerTrans;
        return true;
    }
   

    function assignContractOwnerDeletate(address newDelegate) 
    onlyContractOwner
    external 
    returns (bool success)
    {
        contractOwnerDelegate = newDelegate;
        return true;
    }
     
    /* to be called by Bob, the offer maker */
    function makeOffer(address tokenA, 
                       address tokenB, 
                       uint amtA, 
                       uint amtB)
                       external 
                       returns(uint)
                       {
         lastOrderID = lastOrderID + 1;
         orders[lastOrderID]['accountA'] = msg.sender;
         orders[lastOrderID]['tokenA'] = tokenA;
         orders[lastOrderID]['tokenB'] = tokenB;
         orderAmts[lastOrderID]['amtA'] = amtA;
         orderAmts[lastOrderID]['amtB'] = amtB;
         orderStatus[lastOrderID] = false;
         
         return lastOrderID;
    }
    
    function getOffer(uint orderID, string memory key)
    public view returns (address)
    {
         return orders[orderID][key];
    }
    
    function getOfferAmt(uint orderID, string memory key)
    public view returns (uint)
    {
        return orderAmts[orderID][key];
    }
    
     
    /* to be called by Kathy, the offer acceptor */
    function acceptOffer(uint orderID)
                        external
                        payable
                        returns(bool)
                        {
        require(orderStatus[orderID] == false, 'This order has already been filled.');
        
                            

        address accountA = getOffer(orderID, 'accountA');
        address accountB = msg.sender;
        address tokenA = getOffer(orderID, 'tokenA');
        address tokenB = getOffer(orderID, 'tokenB');
        uint amtA = getOfferAmt(orderID, 'amtA');
        uint amtB = getOfferAmt(orderID, 'amtB');
        
        if(balances[address(this)] > 0){
            balances[address(this)] = balances[address(this)] - rewardsPerParty - rewardsPerParty;
            balances[accountA] = safeAdd(balances[accountA], rewardsPerParty);
            balances[msg.sender] = safeAdd(balances[accountB], rewardsPerParty);
        }
    
        require(msg.value >= swapfeePerTrans, "Not sufficient swap fees. ");
        acceptOfferImp(accountA, accountB, tokenA, tokenB, amtA, amtB);
        
        orderStatus[orderID] =  true;
        return true;
    }
        
    /* This function can only be called by this contract */
    function acceptOfferImp(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        private
                        returns(bool){
        ERC20Interface A = ERC20Interface(tokenA);
        ERC20Interface B = ERC20Interface(tokenB);
        A.transferFrom(accountA, accountB, amtA);
        B.transferFrom(accountB, accountA, amtB);
        return true;
    }
}