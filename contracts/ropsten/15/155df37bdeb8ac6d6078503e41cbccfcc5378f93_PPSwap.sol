/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// 
// PPSwap010: 5/6/2021, we combine PPSwap with PPS so that a user can buy PPS via sending ETH to the contract address.
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
    
    address  public contractOwner;
    address  payable public trustAccount;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event Transfer(address from, address to, uint amt);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public { 
        contractOwner = msg.sender;
        trustAccount = msg.sender;
        balances[trustAccount] = _totalSupply;
        emit Transfer(address(0), trustAccount, _totalSupply);
  
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
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
        balances[to] = safeAdd(balances[to], uint56(rawAmt));
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
    /*
    *
    * If tokens are sent to this contract address by accidents, the contract owner will widthdraw them. 
    * 
    */
    

    /*
    *   1. Request accountA to approve PPSwap.address to spend tokenA of amount amtA by calling tokenA.approve(PPSwap.address, amtA)
    *   2. Request accountB to approve PPSwap.address to spend tokenB of amount amtB by calling tokenB.approve(PPSwap.address, amtB)
    *   3. Call safeSwap to transfer tokenA of amtA from AccountA to AccountB and transfer tokenB of amtB from accountB to accountA.
    *     
    */
    // this function can ONLY be called by the contractOwner externally. 
    function safeSwap(address accountA, 
                        address accountB, 
                        address tokenA, 
                        address tokenB, 
                        uint amtA, 
                        uint amtB) 
                        external
                        returns(bool){
        
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
        require(A.transferFrom(accountA, accountB, amtA) == true, "Transfer from accountA to accountB fails.");
        require(B.transferFrom(accountB, accountA, amtB) == true, "Transfer from accountB to accountA fails.");
        return true;
    }
    
    modifier onlyOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }

    
    /* PPS can be purchased by sending ETH to this contract address initially. */
    function() external payable {
        purchasePPS();
    }
    
    function purchasePPS() internal {
        uint amt = safeMul(msg.value, exchangeRateETH);
        balances[trustAccount] = safeSub(balances[trustAccount], amt); 
        balances[msg.sender] = safeAdd(balances[msg.sender], amt);
        trustAccount.transfer(msg.value);
        emit Transfer(contractOwner, msg.sender, amt); 
    }    
}