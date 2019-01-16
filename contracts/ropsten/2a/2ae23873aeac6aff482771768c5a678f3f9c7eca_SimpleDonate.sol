pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------

// Simple Donate Contract 

// This contract  facilitates management of simple fundraising.
// Any and all funds can be withdrawn by the contract owner at any time. 

// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------

// Safe maths

// ----------------------------------------------------------------------------

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}

 
 contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


 


// ----------------------------------------------------------------------------

// Owned contract

// ----------------------------------------------------------------------------

contract Owned {

    address public owner;

    address public newOwner;


    event OwnershipTransferred(address indexed _from, address indexed _to);


    constructor() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        emit OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}



// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract SimpleDonate is   Owned {

    using SafeMath for uint;  

    string public  name; 
 

 
 
    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    constructor(string contractName) public  { 
        name = contractName; 
    }

    
    //accept ETH
    function() public payable
    {
        
    }
  

    
     // ------------------------------------------------------------------------

    // Owner can transfer out any Ether

    // ------------------------------------------------------------------------

    
     function withdrawEther(uint amount) public onlyOwner returns(bool) {
        
        require(amount < address(this).balance);
        owner.transfer(amount);
        return true;

    }
    
    // ------------------------------------------------------------------------

    // Owner can transfer out any ERC20 tokens

    // ------------------------------------------------------------------------

    function withdrawERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}