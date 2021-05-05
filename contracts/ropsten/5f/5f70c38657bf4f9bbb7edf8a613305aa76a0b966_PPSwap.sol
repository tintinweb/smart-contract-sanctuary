/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

/*
* PPSwap006.sol 5, 4, 2021
* It is better to put PPS and PPSwap into a different contracts. 
* 
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

    
    function() external payable {
        contractOwner.transfer(msg.value); // if the contract receives ETH, it will forward it to the contractOwner
        emit Transfer(msg.sender, contractOwner, msg.value);
    }    
}