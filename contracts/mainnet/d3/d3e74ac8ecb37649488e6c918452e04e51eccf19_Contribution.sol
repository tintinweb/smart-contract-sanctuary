pragma solidity ^0.4.8;

// folio.ninja ERC20 Token & Crowdsale Contract
// Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="244d4a424b64424b484d4b0a4a4d4a4e45">[email&#160;protected]</a>
// Cap of 12,632,000 Tokens
// 632,000 Tokens to Foundation
// 25,000 ETH Cap that goes to Developers
// Allows subsequent contribution / minting if cap not reached.

contract Assertive {
  function assert(bool assertion) internal {
      if (!assertion) throw;
  }
}

contract SafeMath is Assertive{
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract ERC20Protocol {
    function totalSupply() constant returns (uint256 totalSupply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20Protocol {
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { 
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}

// Folio Ninja Token Contract
contract FolioNinjaToken is ERC20, SafeMath {
    // Consant token specific fields
    string public constant name = "folio.ninja";
    string public constant symbol = "FLN";
    uint public constant decimals = 18;
    uint public constant MAX_TOTAL_TOKEN_AMOUNT = 12632000 * 10 ** decimals;

    // Fields that are only changed in constructor
    address public minter; // Contribution contract
    address public FOUNDATION_WALLET; // Can change to other minting contribution contracts but only until total amount of token minted
    uint public startTime; // Contribution start time in seconds
    uint public endTime; // Contribution end time in seconds

    // MODIFIERS
    modifier only_minter {
        assert(msg.sender == minter);
        _;
    }

    modifier only_foundation {
        assert(msg.sender == FOUNDATION_WALLET);
        _;
    }

    modifier is_later_than(uint x) {
        assert(now > x);
        _;
    }

    modifier max_total_token_amount_not_reached(uint amount) {
        assert(safeAdd(totalSupply, amount) <= MAX_TOTAL_TOKEN_AMOUNT);
        _;
    }

    // METHODS
    function FolioNinjaToken(address setMinter, address setFoundation, uint setStartTime, uint setEndTime) {
        minter = setMinter;
        FOUNDATION_WALLET = setFoundation;
        startTime = setStartTime;
        endTime = setEndTime;
    }

    /// Pre: Address of contribution contract (minter) is set
    /// Post: Mints token
    function mintToken(address recipient, uint amount)
        external
        only_minter
        max_total_token_amount_not_reached(amount)
    {
        balances[recipient] = safeAdd(balances[recipient], amount);
        totalSupply = safeAdd(totalSupply, amount);
    }

    /// Pre: Prevent transfers until contribution period is over.
    /// Post: Transfer FLN from msg.sender
    /// Note: ERC20 interface
    function transfer(address recipient, uint amount)
        is_later_than(endTime)
        returns (bool success)
    {
        return super.transfer(recipient, amount);
    }

    /// Pre: Prevent transfers until contribution period is over.
    /// Post: Transfer FLN from arbitrary address
    /// Note: ERC20 interface
    function transferFrom(address sender, address recipient, uint amount)
        is_later_than(endTime)
        returns (bool success)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    /// Pre: minting address is set. Restricted to foundation.
    /// Post: New minter can now create tokens up to MAX_TOTAL_TOKEN_AMOUNT.
    /// Note: This allows additional contribution periods at a later stage, while still using the same ERC20 compliant contract.
    function changeMintingAddress(address newMintingAddress) only_foundation { minter = newMintingAddress; }

    /// Pre: foundation address is set. Restricted to foundation.
    /// Post: New address set. This address controls the setting of the minter address
    function changeFoundationAddress(address newFoundationAddress) only_foundation { FOUNDATION_WALLET = newFoundationAddress; }
}

/// @title Contribution Contract
contract Contribution is SafeMath {
    // FIELDS

    // Constant fields
    uint public constant ETHER_CAP = 25000 ether; // Max amount raised during first contribution; targeted amount AUD 7M
    uint public constant MAX_CONTRIBUTION_DURATION = 8 weeks; // Max amount in seconds of contribution period

    // Price Rates
    uint public constant PRICE_RATE_FIRST = 480;
    uint public constant PRICE_RATE_SECOND = 460;
    uint public constant PRICE_RATE_THIRD = 440;
    uint public constant PRICE_RATE_FOURTH = 400;

    // Foundation Holdings
    uint public constant FOUNDATION_TOKENS = 632000 ether;

    // Fields that are only changed in constructor
    address public FOUNDATION_WALLET; // folio.ninja foundation wallet
    address public DEV_WALLET; // folio.ninja multisig wallet

    uint public startTime; // Contribution start time in seconds
    uint public endTime; // Contribution end time in seconds

    FolioNinjaToken public folioToken; // Contract of the ERC20 compliant folio.ninja token

    // Fields that can be changed by functions
    uint public etherRaised; // This will keep track of the Ether raised during the contribution
    bool public halted; // The foundation address can set this to true to halt the contribution due to an emergency

    // EVENTS
    event TokensBought(address indexed sender, uint eth, uint amount);

    // MODIFIERS
    modifier only_foundation {
        assert(msg.sender == FOUNDATION_WALLET);
        _;
    }

    modifier is_not_halted {
        assert(!halted);
        _;
    }

    modifier ether_cap_not_reached {
        assert(safeAdd(etherRaised, msg.value) <= ETHER_CAP);
        _;
    }

    modifier is_not_earlier_than(uint x) {
        assert(now >= x);
        _;
    }

    modifier is_earlier_than(uint x) {
        assert(now < x);
        _;
    }

    // CONSTANT METHODS

    /// Pre: startTime, endTime specified in constructor,
    /// Post: Price rate at given blockTime; One ether equals priceRate() of FLN tokens
    function priceRate() constant returns (uint) {
        // Four price tiers
        if (startTime <= now && now < startTime + 1 weeks)
            return PRICE_RATE_FIRST;
        if (startTime + 1 weeks <= now && now < startTime + 2 weeks)
            return PRICE_RATE_SECOND;
        if (startTime + 2 weeks <= now && now < startTime + 3 weeks)
            return PRICE_RATE_THIRD;
        if (startTime + 3 weeks <= now && now < endTime)
            return PRICE_RATE_FOURTH;
        // Should not be called before or after contribution period
        assert(false);
    }

    // NON-CONSTANT METHODS
    function Contribution(address setDevWallet, address setFoundationWallet, uint setStartTime) {
        DEV_WALLET = setDevWallet;
        FOUNDATION_WALLET = setFoundationWallet;
        startTime = setStartTime;
        endTime = startTime + MAX_CONTRIBUTION_DURATION;
        folioToken = new FolioNinjaToken(this, FOUNDATION_WALLET, startTime, endTime); // Create Folio Ninja Token Contract

        // Mint folio.ninja foundation tokens
        folioToken.mintToken(FOUNDATION_WALLET, FOUNDATION_TOKENS);
    }

    /// Pre: N/a
    /// Post: Bought folio.ninja tokens according to priceRate() and msg.value
    function () payable { buyRecipient(msg.sender); }

    /// Pre: N/a
    /// Post: Bought folio ninja tokens according to priceRate() and msg.value on behalf of recipient
    function buyRecipient(address recipient)
        payable
        is_not_earlier_than(startTime)
        is_earlier_than(endTime)
        is_not_halted
        ether_cap_not_reached
    {
        uint amount = safeMul(msg.value, priceRate());
        folioToken.mintToken(recipient, amount);
        etherRaised = safeAdd(etherRaised, msg.value);
        assert(DEV_WALLET.send(msg.value));
        TokensBought(recipient, msg.value, amount);
    }

    /// Pre: Emergency situation that requires contribution period to stop.
    /// Post: Contributing not possible anymore.
    function halt() only_foundation { halted = true; }

    /// Pre: Emergency situation resolved.
    /// Post: Contributing becomes possible again.
    function unhalt() only_foundation { halted = false; }

    /// Pre: Restricted to foundation.
    /// Post: New address set. To halt contribution and/or change minter in FolioNinjaToken contract.
    function changeFoundationAddress(address newFoundationAddress) only_foundation { FOUNDATION_WALLET = newFoundationAddress; }

    /// Pre: Restricted to foundation.
    /// Post: New address set. To change beneficiary of contributions
    function changeDevAddress(address newDevAddress) only_foundation { DEV_WALLET = newDevAddress; }
}