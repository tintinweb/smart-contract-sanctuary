/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

/* ----------------------------------------------------------------------------
Huge Profit International (HK) Holdings has the right to final interpretation and reserves the right to modify with all issued Shu Zi Mu Dan (SZMD).

For the latest revision of the operating policies and trading models of SZMD please refer to the official announcements on the website (http:// www.bitcaps.club/szmd). The website has the final interpretation and reserves all rights to modify, to insert, and/or to withdraw any parts with the announcements.
---------------------------------------------------------------------------- */

pragma solidity ^0.5.0;


// ----------------------------------------------------------------------------
// Safe maths, Math operations with safety checks
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// The first one of published this smart contract is the owner of token.
// The Ownership is transferred to the other one.
//   @msg.sender is default parm of solidity.
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

// ----------------------------------------------------------------------------
// This contract only defines a modifier but does not use it.
// It will be used in derived contracts.
// The function body is inserted where the special symbol
// "_;" in the definition of a modifier appears.
// This means that if the owner calls this function,
// the function is executed and otherwise, an exception is thrown.
// ----------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

// ----------------------------------------------------------------------------
// Allows the current owner to transfer control of the contract to a newOwner.
// Using the modifier onlyOwner to check the caller.
//   @param newOwner, the address to accept ownership.
// ----------------------------------------------------------------------------
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// ----------------------------------------------------------------------------
// Basic version of ERC20 Standard
// @dev see https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ShuZiMuDan is ERC20Interface, Owned {
    using SafeMath for uint;


// ----------------------------------------------------------------------------
// This area is executed once in the initial stage with Constructor.
// ----------------------------------------------------------------------------
    string public constant name = "Shu Zi Mu Dan";
	string public constant symbol = "SZMD";
    uint8 public constant decimals = 6;
	
	string public constant features = "Delivery voucher, consumption reward converted shares voucher, employees performance reward converted shares voucher.";

	string public constant website = "http://www.bitpeony.com";

    uint _totalSupply;
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


// ------------------------------------------------------------------------
// Constructor
// ------------------------------------------------------------------------
    constructor() public {
        _totalSupply = 10000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


// ------------------------------------------------------------------------
// Total supply
// ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


// ------------------------------------------------------------------------
// Get the token balance for account.
//   @param tokenOwner. The address from which the balance will be retrieved.
//   @return The balance of tokenOwner.
// ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


// ------------------------------------------------------------------------
// Transfer the balance from token owner's account to `to` account.
//   - Owner's account must have sufficient balance to transfer
//   - 0 value transfers are allowed
// Implements ERC 20 Token standard:https://github.com/ethereum/EIPs/issues/20
// ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


// ------------------------------------------------------------------------
// Token owner can approve for `spender` to transferFrom `tokens`
// from the token owner's account.
//   @param spender, The address which will spend the funds.
//   @param tokens, The amount of tokens to be spent.
// ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


// ------------------------------------------------------------------------
// Transfer `tokens` from the `from` account to the `to` account.
// The calling account must already have sufficient tokens approve
// for spending from the `from` account.
//   - From account must have sufficient balance to transfer
//   - Spender must have sufficient allowance to transfer
//   - 0 value transfers are allowed
// ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


// ------------------------------------------------------------------------
// @dev Function to check the amount of tokens that an owner allowed to a spender.
//   @param tokenOwner. The address which owns the funds.
//   @param spender. The address which will spend the funds.
//   @param remaining, specifying the amount of tokens still available for the spender.
// ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

// ------------------------------------------------------------------------
// Don't accept ETH.
// ------------------------------------------------------------------------
    function () external payable {
        revert();
    }

// ------------------------------------------------------------------------
// Owner can transfer out any accidentally sent ERC20 tokens
// ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

}