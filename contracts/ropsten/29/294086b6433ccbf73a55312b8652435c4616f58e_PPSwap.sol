/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
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
    uint public exchangeRateETH = 1000; // initially, 1ETH = 1000 PPS
    uint public swapfeePerTrans = 0; // no swap fee initially

    address  public contractOwner;
    address public contractOwnerDelegate;
    address  payable public trustAccount;
    bool public isICO = true;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
  
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public { 
        contractOwner = msg.sender;
        contractOwnerDelegate = msg.sender; // default delegate
        trustAccount = msg.sender;
        balances[trustAccount] = _totalSupply;
        emit Transfer(address(0), trustAccount, _totalSupply);
  
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
     
    function safeSwap(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        onlyContractOwnerDelegate
                        external
                        returns(bool)
                        {

        // Security: we use a simple constant swap fee model. Simplicity is the key to ensure security.
        // The swap fee is shared by both parties, half for 
        uint swapfee = swapfeePerTrans/2;
        require(balances[accountA] >= swapfee, "Insufficient PPS balance to swap tokens.");
        require(balances[accountB] >= swapfee, "Insufficient PPS balance to swap tokens.");
        balances[accountA] = safeSub(balances[accountA], swapfee);
        balances[accountB] = safeSub(balances[accountB], swapfee);
        balances[trustAccount] = safeAdd(balances[trustAccount], swapfeePerTrans);
        return safeSwapByContract(accountA, accountB, tokenA, tokenB, amtA, amtB);                      
    }
        
    /* This function can only be called by this contract */
    function safeSwapByContract(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        private
                        returns(bool){
        ERC20Interface A = ERC20Interface(tokenA);
        ERC20Interface B = ERC20Interface(tokenB);
        require(A.transferFrom(accountA, accountB, amtA), "Transfer from accountA to accountB fails.");
        require(B.transferFrom(accountB, accountA, amtB), "Transfer from accountB to accountA fails.");
        return true;
    }
    

    
    function  setICO(bool _isICO) 
         external 
         onlyContractOwnerDelegate
    {
         isICO = _isICO;
    }
         
    
    /* PPS can be purchased by sending ETH to this contract address during ICO. */
    function() external payable {
        if(isICO){
             purchasePPS();
        }
        else{
            forwardETH();
        }
    }
    
    function purchasePPS() internal {
        uint amt = safeMul(msg.value, exchangeRateETH);
        balances[trustAccount] = safeSub(balances[trustAccount], amt); 
        balances[msg.sender] = safeAdd(balances[msg.sender], amt);
        trustAccount.transfer(msg.value);
        emit Transfer(contractOwner, msg.sender, amt); 
    }   
    
    function forwardETH() internal{
        trustAccount.transfer(msg.value);  // send the ETH to the trust account for postprocessing
    }
 }