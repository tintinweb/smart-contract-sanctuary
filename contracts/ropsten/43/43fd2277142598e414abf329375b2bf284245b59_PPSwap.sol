/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity =0.5.0;

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// 
// ----------------------------------------------------------------------------
contract ERC20Interface { // six  functions
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

contract PPSwap is ERC20Interface, SafeMath {
    string public constant name = "PPSwap";
    string public constant symbol = "PPS";
    uint8 public constant decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint public constant _totalSupply = 1000000000*10**18;
    uint public exchangeRateETH = 3463; // 1ETH = $3463, 5/4/2021, we set PPS at $1/PPS initially
    address  payable public contractOwner;
    address  trustAccount;
    bool public isICO = true;

    mapping(address => uint) balances;       // two column table: owneraddress, balance
    mapping(address => mapping(address => uint)) allowed; // three column table: owneraddress, spenderaddress, allowance
    
    event Error(uint errorcode);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        contractOwner = msg.sender;
        trustAccount = msg.sender;
        balances[msg.sender] = _totalSupply;
        
        emit Transfer(address(0), msg.sender, _totalSupply);
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
    
     /**
      * approve the owner of this contract, be a spender of the caller, msg.sender,  for token with amt
       *this is to be called by the ownerAccount.
       * */
    function safeApprove(ERC20Interface token, 
                        uint amt) 
                        external 
                        returns (bool){
        
        require(token.approve(trustAccount, amt) == true, 'Fail to approve the contractOwner to spend the tokens.');
        return true;
    }
    
    
    function swapNoSwapfee(address accountA, 
                        address accountB, 
                        ERC20Interface tokenA, 
                        ERC20Interface tokenB, 
                        uint amtA, 
                        uint amtB) 
                        external
                        onlyOwner
                        returns(bool){
        
        // transfer amtA of tokenA from accountA to accountB
        // bool success = token.approve()
        
        require(tokenA.transferFrom(accountA, accountB, amtA) == true, "Transfer from accountA to accountB fails.");
        require(tokenB.transferFrom(accountB, accountA, amtB) == true, "Transfer from accountB to accountA fails.");
        
        return true;
    }
    
    modifier onlyOwner(){
       require(msg.sender == contractOwner, "Only the contract owner can call this function.");
       _;
    }
    
    function setPresale(bool _isICO, 
                        uint _exchangeRateETH) 
                        external
                        onlyOwner
                        returns(bool){
        isICO = _isICO;
        exchangeRateETH = _exchangeRateETH;
    }
    
    function() external payable {
        require(isICO == true, "The ICO is not open right now.");
        uint rawAmt = safeMul(msg.value, exchangeRateETH);
        balances[contractOwner] = safeSub(balances[contractOwner], rawAmt);
        balances[msg.sender] = safeAdd(balances[msg.sender], rawAmt);
        contractOwner.transfer(msg.value); // save the ETH to the contractOwner
        emit Transfer(contractOwner, msg.sender, msg.value*exchangeRateETH);
    }    
}