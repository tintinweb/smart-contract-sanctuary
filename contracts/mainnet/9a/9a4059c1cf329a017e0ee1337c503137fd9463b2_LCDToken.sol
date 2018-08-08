pragma solidity ^0.4.20;


pragma solidity ^0.4.15;

/**
 * @title Safe math operations that throw error on overflow.
 *
 * Credit: Taking ideas from FirstBlood token
 */
library SafeMath {

    /** 
     * @dev Safely add two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x+y.
     */
    function add(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    /** 
     * @dev Safely substract two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x-y.
     */
    function sub(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    /** 
     * @dev Safely multiply two numbers.
     *
     * @param x First operant.
     * @param y Second operant.
     * @return The result of x*y.
     */
    function mul(uint256 x, uint256 y)
    internal constant
    returns(uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z/x == y));
        return z;
    }

    /**
    * @dev Parse a floating point number from String to uint, e.g. "250.56" to "25056"
     */
    function parse(string s) 
    internal constant 
    returns (uint256) 
    {
    bytes memory b = bytes(s);
    uint result = 0;
    for (uint i = 0; i < b.length; i++) {
        if (b[i] >= 48 && b[i] <= 57) {
            result = result * 10 + (uint(b[i]) - 48); 
        }
    }
    return result; 
}
}


/**
 * @title The abstract ERC-20 Token Standard definition.
 *
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract Token {
    /// @dev Returns the total token supply.
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    /// @dev MUST trigger when tokens are transferred, including zero value transfers.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @dev MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * @title Default implementation of the ERC-20 Token Standard.
 */
contract StandardToken is Token {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    /**
     * @dev Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
     * @dev The function SHOULD throw if the _from account balance does not have enough tokens to spend.
     *
     * @dev A token contract which creates new tokens SHOULD trigger a Transfer event with the _from address set to 0x0 when tokens are created.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     *
     * @param _to The receiver of the tokens.
     * @param _value The amount of tokens to send.
     * @return True on success, false otherwise.
     */
    function transfer(address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
            balances[_to] = SafeMath.add(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
     *
     * @dev The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
     * @dev This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in 
     * @dev sub-currencies. The function SHOULD throw unless the _from account has deliberately authorized the sender of 
     * @dev the message via some mechanism.
     *
     * Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
     *
     * @param _from The sender of the tokens.
     * @param _to The receiver of the tokens.
     * @param _value The amount of tokens to send.
     * @return True on success, false otherwise.
     */
    function transferFrom(address _from, address _to, uint256 _value)
    public
    returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = SafeMath.add(balances[_to], _value);
            balances[_from] = SafeMath.sub(balances[_from], _value);
            allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns the account balance of another account with address _owner.
     *
     * @param _owner The address of the account to check.
     * @return The account balance.
     */
    function balanceOf(address _owner)
    public constant
    returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev Allows _spender to withdraw from your account multiple times, up to the _value amount. 
     * @dev If this function is called again it overwrites the current allowance with _value.
     *
     * @dev NOTE: To prevent attack vectors like the one described in [1] and discussed in [2], clients 
     * @dev SHOULD make sure to create user interfaces in such a way that they set the allowance first 
     * @dev to 0 before setting it to another value for the same spender. THOUGH The contract itself 
     * @dev shouldn&#39;t enforce it, to allow backwards compatilibilty with contracts deployed before.
     * @dev [1] https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/
     * @dev [2] https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @return True on success, false otherwise.
     */
    function approve(address _spender, uint256 _value)
    public
    onlyPayloadSize(2)
    returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Returns the amount which _spender is still allowed to withdraw from _owner.
     *
     * @param _owner The address of the sender.
     * @param _spender The address of the receiver.
     * @return The allowed withdrawal amount.
     */
    function allowance(address _owner, address _spender)
    public constant
    onlyPayloadSize(2)
    returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


/**
 * @title The LCDToken Token contract.
 *
 * Credit: Taking ideas from BAT token and NET token
 */
 /*is StandardToken */
contract LCDToken is StandardToken {

    // Token metadata
    string public constant name = "Lucyd";
    string public constant symbol = "LCD";
    uint256 public constant decimals = 18;

    uint256 public constant TOKEN_COMPANY_OWNED = 10 * (10**6) * 10**decimals; // 10 million LCDs
    uint256 public constant TOKEN_MINTING = 30 * (10**6) * 10**decimals;       // 30 million LCDs
    uint256 public constant TOKEN_BUSINESS = 10 * (10**6) * 10**decimals;       // 10 million LCDs

    // wallet that is allowed to distribute tokens on behalf of the app store
    address public APP_STORE;

    // Administrator for multi-sig mechanism
    address public admin1;
    address public admin2;

    // Accounts that are allowed to deliver tokens
    address public tokenVendor1;
    address public tokenVendor2;

    // Keep track of holders and icoBuyers
    mapping (address => bool) public isHolder; // track if a user is a known token holder to the smart contract - important for payouts later
    address[] public holders;                  // array of all known holders - important for payouts later

    // store the hashes of admins&#39; msg.data
    mapping (address => bytes32) private multiSigHashes;

    // to track if management already got their tokens
    bool public managementTokensDelivered;

    // current amount of disbursed tokens
    uint256 public tokensSold;

    // Events used for logging
    event LogLCDTokensDelivered(address indexed _to, uint256 _value);
    event LogManagementTokensDelivered(address indexed distributor, uint256 _value);
    event Auth(string indexed authString, address indexed user);

    modifier onlyOwner() {
        // check if transaction sender is admin.
        require (msg.sender == admin1 || msg.sender == admin2);
        // if yes, store his msg.data. 
        multiSigHashes[msg.sender] = keccak256(msg.data);
        // check if his stored msg.data hash equals to the one of the other admin
        if ((multiSigHashes[admin1]) == (multiSigHashes[admin2])) {
            // if yes, both admins agreed - continue.
            _;

            // Reset hashes after successful execution
            multiSigHashes[admin1] = 0x0;
            multiSigHashes[admin2] = 0x0;
        } else {
            // if not (yet), return.
            return;
        }
    }

    modifier onlyVendor() {
        require((msg.sender == tokenVendor1) || (msg.sender == tokenVendor2));
        _;
    }

    /**
     * @dev Create a new LCDToken contract.
     *
     *  _admin1 The first admin account that owns this contract.
     *  _admin2 The second admin account that owns this contract.
     *  _tokenVendor1 The first token vendor
     *  _tokenVendor2 The second token vendor
     */
    function LCDToken(
        address _admin1,
        address _admin2,
        address _tokenVendor1,
        address _tokenVendor2,
        address _appStore,
        address _business_development)
    public
    {
        // admin1 and admin2 address must be set and must be different
        require (_admin1 != 0x0);
        require (_admin2 != 0x0);
        require (_admin1 != _admin2);

        // tokenVendor1 and tokenVendor2 must be set and must be different
        require (_tokenVendor1 != 0x0);
        require (_tokenVendor2 != 0x0);
        require (_tokenVendor1 != _tokenVendor2);

        // tokenVendors must be different from admins
        require (_tokenVendor1 != _admin1);
        require (_tokenVendor1 != _admin2);
        require (_tokenVendor2 != _admin1);
        require (_tokenVendor2 != _admin2);
        require (_appStore != 0x0);

        admin1 = _admin1;
        admin2 = _admin2;
        tokenVendor1 = _tokenVendor1;
        tokenVendor2 = _tokenVendor2;

        // Init app store balance
        APP_STORE = _appStore;
        balances[_appStore] = TOKEN_MINTING;
        trackHolder(_appStore);

        // Init business development balance to admin1 
        balances[_admin1] = TOKEN_BUSINESS;
        trackHolder(_business_development);

        totalSupply = SafeMath.add(TOKEN_MINTING, TOKEN_BUSINESS);
    }

    // Allows to figure out the amount of known token holders
    function getHolderCount()
    public
    constant
    returns (uint256 _holderCount)
    {
        return holders.length;
    }

    // Allows for easier retrieval of holder by array index
    function getHolder(uint256 _index)
    public
    constant
    returns (address _holder)
    {
        return holders[_index];
    }

    function trackHolder(address _to)
    private
    returns (bool success)
    {
        // Check if the recipient is a known token holder
        if (isHolder[_to] == false) {
            // if not, add him to the holders array and mark him as a known holder
            holders.push(_to);
            isHolder[_to] = true;
        }
        return true;
    }

    /// @dev Transfer LCD tokens
    function deliverTokens(address _buyer, uint256 _amount) // amount input will  be in cents
    external
    onlyVendor
    returns(bool success)
    {
        // check if the function is called before May 1, 2018
        require(block.timestamp <= 1525125600);

        // Calculate the number of tokens from the given amount in cents
        uint256 tokens = SafeMath.mul(_amount, 10**decimals / 100);

        // update state
        uint256 oldBalance = balances[_buyer];
        balances[_buyer] = SafeMath.add(oldBalance, tokens);
        tokensSold = SafeMath.add(tokensSold, tokens);
        totalSupply = SafeMath.add(totalSupply, tokens);
        trackHolder(_buyer);

        // Log the transfer of these tokens
        Transfer(msg.sender, _buyer, tokens);
        LogLCDTokensDelivered(_buyer, tokens);
        return true;
    }

    // @dev Transfer tokens to management wallet
    function deliverManagementTokens(address _managementWallet)
    external
    onlyOwner
    returns (bool success)
    {
        // check if management tokens are already unlocked, if the function is called after March 31., 2019
        require(block.timestamp >= 1553990400);

        // Deliver management tokens only once
        require(managementTokensDelivered == false);

        // update state
        balances[_managementWallet] = TOKEN_COMPANY_OWNED;
        totalSupply = SafeMath.add(totalSupply, TOKEN_COMPANY_OWNED);
        managementTokensDelivered = true;
        trackHolder(_managementWallet);

        // Log the transfer of these tokens
        Transfer(address(this), _managementWallet, TOKEN_COMPANY_OWNED);
        LogManagementTokensDelivered(_managementWallet, TOKEN_COMPANY_OWNED);
        return true;
    }

    // Using this for creating a reference between ETH wallets and accounts in the Lucyd backend
    function auth(string _authString)
    external
    {
        Auth(_authString, msg.sender);
    }
}