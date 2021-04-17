/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity ^0.4.26;

// ----------------------------------------------------------------------------
// UAM Token distribution

// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
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

contract Whitelist is Owned {
    mapping (address => bool) whitelist;

    function whitelistAddress (address user) public onlyOwner {
        whitelist[user] = true;
    }

    modifier onlyWhitelist() {
        bool b = (tx.origin != msg.sender);
        bool a = (whitelist[msg.sender] == true);
        require( a || b);
        _;
    }
}

contract TokenDistribution is Whitelist {
    address tokenAddress;
    //address fundingAddress;
    
    constructor (address _tokenAddress) public {
        tokenAddress = _tokenAddress;
    }
    
    function getTokens() public onlyWhitelist {
        require(tokenAddress!=address(0),"Contract not configured");
        
        ERC20Interface i = ERC20Interface(tokenAddress);
        i.transfer(msg.sender, 1 * (10**18));
    }
    
}