/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) { c = a + b; require(c >= a); }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) { require(b <= a); c = a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) { require(b > 0); c = a / b; }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 value) external returns (bool success);
    function transferFrom( address from, address to, uint256 value) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public _owner;
    address public _newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() 
    { 
        _owner = msg.sender;
    }

    modifier onlyOwner 
    { 
        require(msg.sender == _owner); 
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner 
    { 
        _newOwner = newOwner;
    }

    function acceptOwnership() public 
    { 
        require(msg.sender == _newOwner); 
        emit OwnershipTransferred(_owner, _newOwner); 
        _owner = _newOwner; 
        _newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of _symbol, _name and _decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract BEP20 is IBEP20, Owned {
    using SafeMath for uint256;

    string public _symbol;
    string public _name;
    uint8 public _decimals;

    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    // Constructor
    constructor() public 
    {
        _symbol = 'TTT'; 
        _name = 'Trending Topic Token'; 
        _decimals = 18; 

        _totalSupply = 1000000 * 10**uint256(_decimals); 
        _balances[_owner] = _totalSupply; 
        emit Transfer(address(0), _owner, _totalSupply);
    }

    // Total supply
    function totalSupply() public override view returns (uint256) 
    { 
        return _totalSupply.sub(_balances[address(0)]);
    }

    // Get the token balance for account `owner`
    function balanceOf(address owner) public override view returns (uint256 balance)
    { 
        return _balances[owner];
    }

    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    function transfer(address to, uint256 value) public override returns (bool success)
    { 
        _balances[msg.sender] = _balances[msg.sender].sub(value); 
        _balances[to] = _balances[to].add(value); 
        emit Transfer(msg.sender, to, value); 
        return true;
    }

    // Token owner can approve for `spender` to transferFrom(...) `value`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    function approve(address spender, uint256 value) public override returns (bool success)
    { 
        _allowed[msg.sender][spender] = value; 
        emit Approval(msg.sender, spender, value); 
        return true;
    }

    // Transfer `value` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient value approved (...)
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    function transferFrom(address from, address to, uint256 value) public override returns (bool success) 
    { 
        _balances[from] = _balances[from].sub(value); 
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value); 
        _balances[to] = _balances[to].add(value); 
        emit Transfer(from, to, value); 
        return true;
    }

    // Returns the amount of value approved by the owner that can be
    // transferred to the spender's account
    function allowance(address owner, address spender) public override view returns (uint256 remaining)
    { 
        return _allowed[owner][spender];
    }
}