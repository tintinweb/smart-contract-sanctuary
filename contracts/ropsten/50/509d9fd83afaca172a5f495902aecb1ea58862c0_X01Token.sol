/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity 0.6.8;

// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : {{Token Symbol}}
// Name          : {{Token Name}}
// Total supply  : {{Total Supply}}
// Decimals      : {{Decimals}}
// Owner Account : {{Owner Account}}
//
// Enjoy.
//
// (c) by Juan Cruz Martinez 2020. MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Lib: Safe Math
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


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

interface ERC20Interface 
{
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external  returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}*/


/**
ERC20 X01Basic2021Jun30 Token, with the addition of symbol, name and decimals and assisted token transfers
*/
contract X01Token is SafeMath 
{
    string public constant symbol = "X01";
    string public constant  name = "X01Basic2021Jun30";
    uint8 public constant decimals = 0;
    uint public constant _totalSupply = 1000000;

    mapping(address => uint) balances;
    
    event Transfer(address indexed from, address indexed to, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        //symbol = "X01"; //{{Token Symbol}}
        //name = "X01Basic2021Jun30"; //{{Token Name}}
        //decimals = 0; //{{Decimals}}
        //_totalSupply = 1000000; //{{Total Supply}}
        balances[msg.sender] = _totalSupply; //{{Owner Account}}
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) 
    {
        return _totalSupply;
    }
    
    
    // ------------------------------------------------------------------------
    // Total supply Available
    // ------------------------------------------------------------------------
    function totalSupplyAvailable() public view returns (uint) 
    {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public  view returns (uint balance) 
    {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    /*
    function transfer(address to, uint tokens) public  returns (bool success) 
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    */


    
}