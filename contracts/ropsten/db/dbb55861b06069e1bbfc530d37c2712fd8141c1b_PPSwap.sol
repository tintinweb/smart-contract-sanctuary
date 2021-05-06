/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// PPSwap009: 5/5/2021
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

contract PPSwap is SafeMath {
    address  payable public contractOwner;
    address  trustAccount;

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
    }
    
    /*
    *
    * If tokens are sent to this contract address by accidents, the contract owner will widthdraw them. 
    * 
    */
    

    /*
    *   1. Request accountA to approve thisContract.address to spend tokenA of amount amtA by calling tokenA.approve(thisContract.address, amtA)
    *   2. Request accountB to approve thisContract.address to spend tokenB of amount amtB by calling tokenB.approve(thisContract.address, amtB)
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

    
    function() external payable {
        contractOwner.transfer(msg.value); // if the contract receives ETH, it will forward it to the contractOwner
        emit Transfer(msg.sender, contractOwner, msg.value);
    }    
}