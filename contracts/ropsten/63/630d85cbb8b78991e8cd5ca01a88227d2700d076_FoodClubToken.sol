/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
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
// 'tFoodClub' token contract
//
// Deployed to : 0xc6BF35f95019D95a37Cf230191E69a0009217D6a
// Symbol      : tFDCLB
// Name        : Test Food Club Token
// Total supply: 100000000000000000
// Decimals    : 11
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
        
    /**
     * external, meaning it can only be called from outside the contract.
     * view, which means that it does not change the state. This kind of function does not generate a transaction and does not cost gas
     */
     
    function name() virtual external view returns (string memory);
    function symbol() virtual external view returns (string memory);
    function decimals() virtual external view returns (uint8); 

    function totalSupply() virtual external view returns (uint256);
    function balanceOf(address tokenOwner) virtual external view returns (uint256 balance);
 
    function transfer(address recipient, uint256 tokens) virtual external returns (bool success);

    event Transfer(address indexed sender, address indexed recipient, uint256 tokens);

}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract FoodClubToken is ERC20Interface, Owned, SafeMath {
    
    string private _symbol = "tFDCLB";
    string private _name = "Test Food Club Token";
    uint8 private _decimals = 11;
    
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        _totalSupply = 100000000000000000;
        _balances[0xc6BF35f95019D95a37Cf230191E69a0009217D6a] = _totalSupply;
       emit Transfer(address(0), 0xc6BF35f95019D95a37Cf230191E69a0009217D6a, _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Returns the name of the token.
    // ------------------------------------------------------------------------
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // ------------------------------------------------------------------------
    // Returns the symbol of the token, usually a shorter version of the name
    // ------------------------------------------------------------------------
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    // ------------------------------------------------------------------------
    // Returns the symbol of the token, usually a shorter version of the name
    // 
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens in existence.
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)  public override view returns (uint256 balance) {
        return _balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address recipient, uint256 tokens) public override returns (bool success) {
        _balances[msg.sender] = safeSub(_balances[msg.sender], tokens);
        _balances[recipient] = safeAdd(_balances[recipient], tokens);
        emit Transfer(msg.sender, recipient, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive() external payable {
        revert();
    }
    
     // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}