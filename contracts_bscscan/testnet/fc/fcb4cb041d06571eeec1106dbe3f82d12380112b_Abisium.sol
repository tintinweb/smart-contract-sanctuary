/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at Etherscan.io on 2018-06-14
*/

pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
//
// Fantom Foundation FTM token public sale contract
//
// For details, please visit: http://fantom.foundation
//
//
// written by Alex Kampa - [email protected]
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// SafeMath
//
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

}

// ----------------------------------------------------------------------------
//
// Owned
//
// ----------------------------------------------------------------------------

contract Owned {

    address public owner;
    address public newOwner;

    mapping(address => bool) public isAdmin;

    event OwnershipTransferProposed(address indexed _from, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event AdminChange(address indexed _admin, bool _status);

    modifier onlyOwner {require(msg.sender == owner); _;}
    modifier onlyAdmin {require(isAdmin[msg.sender]); _;}

    constructor() public {
        owner = msg.sender;
        isAdmin[owner] = true;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0x0));
        emit OwnershipTransferProposed(owner, _newOwner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == false);
        isAdmin[_a] = true;
        emit AdminChange(_a, true);
    }

    function removeAdmin(address _a) public onlyOwner {
        require(isAdmin[_a] == true);
        isAdmin[_a] = false;
        emit AdminChange(_a, false);
    }

}


// ----------------------------------------------------------------------------
//
// Wallet
//
// ----------------------------------------------------------------------------

contract Wallet is Owned {

    address public wallet;

    event WalletUpdated(address newWallet);

    constructor() public {
        wallet = owner;
    }

    function setWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0x0));
        wallet = _wallet;
        emit WalletUpdated(_wallet);
    }

}


// ----------------------------------------------------------------------------
//
// ERC20Interface
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);

}


// ----------------------------------------------------------------------------
//
// ERC Token Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Token is ERC20Interface, Owned {

    using SafeMath for uint;

    uint public tokensIssuedTotal;
    mapping(address => uint) balances;
    mapping(address => mapping (address => uint)) allowed;

    function totalSupply() public view returns (uint) {
        return tokensIssuedTotal;
    }
    // Includes BOTH locked AND unlocked tokens

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(_to != 0x0);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

}


// ----------------------------------------------------------------------------
//
// LockSlots
//
// ----------------------------------------------------------------------------

contract LockSlots is ERC20Token {

    using SafeMath for uint;

    uint public constant LOCK_SLOTS = 5;
    mapping(address => uint[LOCK_SLOTS]) public lockTerm;
    mapping(address => uint[LOCK_SLOTS]) public lockAmnt;
    mapping(address => bool) public mayHaveLockedTokens;

    event RegisteredLockedTokens(address indexed account, uint indexed idx, uint tokens, uint term);

    function registerLockedTokens(address _account, uint _tokens, uint _term) internal returns (uint idx) {
        require(_term > now, "lock term must be in the future");

        // find a slot (clean up while doing this)
        // use either the existing slot with the exact same term,
        // of which there can be at most one, or the first empty slot
        idx = 9999;
        uint[LOCK_SLOTS] storage term = lockTerm[_account];
        uint[LOCK_SLOTS] storage amnt = lockAmnt[_account];
        for (uint i; i < LOCK_SLOTS; i++) {
            if (term[i] < now) {
                term[i] = 0;
                amnt[i] = 0;
                if (idx == 9999) idx = i;
            }
            if (term[i] == _term) idx = i;
        }

        // fail if no slot was found
        require(idx != 9999, "registerLockedTokens: no available slot found");

        // register locked tokens
        if (term[idx] == 0) term[idx] = _term;
        amnt[idx] = amnt[idx].add(_tokens);
        mayHaveLockedTokens[_account] = true;
        emit RegisteredLockedTokens(_account, idx, _tokens, _term);
    }

    // public view functions

    function lockedTokens(address _account) public view returns (uint) {
        if (!mayHaveLockedTokens[_account]) return 0;
        return pNumberOfLockedTokens(_account);
    }

    function unlockedTokens(address _account) public view returns (uint) {
        return balances[_account].sub(lockedTokens(_account));
    }

    function isAvailableLockSlot(address _account, uint _term) public view returns (bool) {
        if (!mayHaveLockedTokens[_account]) return true;
        if (_term < now) return true;
        uint[LOCK_SLOTS] storage term = lockTerm[_account];
        for (uint i; i < LOCK_SLOTS; i++) {
            if (term[i] < now || term[i] == _term) return true;
        }
        return false;
    }

    // internal and private functions

    function unlockedTokensInternal(address _account) internal returns (uint) {
        // updates mayHaveLockedTokens if necessary
        if (!mayHaveLockedTokens[_account]) return balances[_account];
        uint locked = pNumberOfLockedTokens(_account);
        if (locked == 0) mayHaveLockedTokens[_account] = false;
        return balances[_account].sub(locked);
    }

    function pNumberOfLockedTokens(address _account) private view returns (uint locked) {
        uint[LOCK_SLOTS] storage term = lockTerm[_account];
        uint[LOCK_SLOTS] storage amnt = lockAmnt[_account];
        for (uint i; i < LOCK_SLOTS; i++) {
            if (term[i] >= now) locked = locked.add(amnt[i]);
        }
    }

}


// ----------------------------------------------------------------------------
//
// FantomIcoDates
//
// ----------------------------------------------------------------------------

contract FantomIcoDates is Owned {

    uint public dateMainStart = 1634519640; // 15-JUN-2018 09:00 GMT + 0
    uint public dateMainEnd   = 1637198040; // 22-JUN-2018 09:00 GMT + 0

    uint public constant DATE_LIMIT = 1637198040 + 180 days;

    event IcoDateUpdated(uint id, uint unixts);

    // check dates

    modifier checkDateOrder {
      _ ;
      require ( dateMainStart < dateMainEnd ) ;
      require ( dateMainEnd < DATE_LIMIT ) ;
    }

    constructor() public checkDateOrder() {
        require(now < dateMainStart);
    }

    // set ico dates

    function setDateMainStart(uint _unixts) public onlyOwner checkDateOrder {
        require(now < _unixts && now < dateMainStart);
        dateMainStart = _unixts;
        emit IcoDateUpdated(1, _unixts);
    }

    function setDateMainEnd(uint _unixts) public onlyOwner checkDateOrder {
        require(now < _unixts && now < dateMainEnd);
        dateMainEnd = _unixts;
        emit IcoDateUpdated(2, _unixts);
    }

    // where are we? Passed first day or not?

    function isMainFirstDay() public view returns (bool) {
        if (now > dateMainStart && now <= dateMainStart + 1 days) return true;
        return false;
    }

    function isMain() public view returns (bool) {
        if (now > dateMainStart && now < dateMainEnd) return true;
        return false;
    }

}

// ----------------------------------------------------------------------------
//
// Fantom public token sale
//
// ----------------------------------------------------------------------------

contract Abisium is ERC20Token, Wallet, LockSlots, FantomIcoDates {

    // Utility variable

    uint constant E18 = 10**18;

    // Basic token data

    string public constant name = "Abisium";
    string public constant symbol = "ABS";
    uint8 public constant decimals = 18;

    // Token number of possible tokens in existance

    uint public constant MAX_TOTAL_TOKEN_SUPPLY = 100000 * E18;


    // crowdsale parameters
    // Opening ETH Rate: USD$463.28
    // Therefore, 1 ETH = 11582 FTM


    uint public tokensPerEth = 10000;

    // USD$2,000,000/463.28 = 4317.043668 ether
    // 4317.043668 ether/2551 addresses = 1.692294656 ether per address for the first 24 hours

    uint public constant MINIMUM_CONTRIBUTION = 0.01 ether;
    uint public constant MAXIMUM_FIRST_DAY_CONTRIBUTION = 1.692294656 ether;

    uint public constant TOKEN_MAIN_CAP = 50000000 * E18;

    bool public tokensTradeable;

    // whitelisting

    mapping(address => bool) public whitelist;
    uint public numberWhitelisted;

    // track main sale

    uint public tokensMain;
    mapping(address => uint) public balancesMain;

    uint public totalEthContributed;
    mapping(address => uint) public ethContributed;

    // tracking tokens minted

    uint public tokensMinted;
    mapping(address => uint) public balancesMinted;
    mapping(address => mapping(uint => uint)) public balancesMintedByType;

    // migration variable

    bool public isMigrationPhaseOpen;

    // Events ---------------------------------------------

    event UpdatedTokensPerEth(uint tokensPerEth);
    event Whitelisted(address indexed account, uint countWhitelisted);
    event TokensMinted(uint indexed mintType, address indexed account, uint tokens, uint term);
    event RegisterContribution(address indexed account, uint tokensIssued, uint ethContributed, uint ethReturned);
    event TokenExchangeRequested(address indexed account, uint tokens);

    // Basic Functions ------------------------------------

    constructor() public {}

    function () public payable {
        buyTokens();
    }

    // Information functions


    function availableToMint() public view returns (uint) {
        return MAX_TOTAL_TOKEN_SUPPLY.sub(TOKEN_MAIN_CAP).sub(tokensMinted);
    }

    function firstDayTokenLimit() public view returns (uint) {
        return ethToTokens(MAXIMUM_FIRST_DAY_CONTRIBUTION);
    }

    function ethToTokens(uint _eth) public view returns (uint tokens) {
        tokens = _eth.mul(tokensPerEth);
    }

    function tokensToEth(uint _tokens) public view returns (uint eth) {
        eth = _tokens / tokensPerEth;
    }

    // Admin functions

    function addToWhitelist(address _account) public onlyAdmin {
        pWhitelist(_account);
    }

    function addToWhitelistMultiple(address[] _addresses) public onlyAdmin {
        for (uint i; i < _addresses.length; i++) {
            pWhitelist(_addresses[i]);
        }
    }

    function pWhitelist(address _account) internal {
        if (whitelist[_account]) return;
        whitelist[_account] = true;
        numberWhitelisted = numberWhitelisted.add(1);
        emit Whitelisted(_account, numberWhitelisted);
    }

    // Owner functions ------------------------------------

    function updateTokensPerEth(uint _tokens_per_eth) public onlyOwner {
        require(now < dateMainStart);
        tokensPerEth = _tokens_per_eth;
        emit UpdatedTokensPerEth(tokensPerEth);
    }

    // Only owner can make tokens tradable at any time, or if the date is
    // greater than the end of the mainsale date plus 20 weeks, allow
    // any caller to make tokensTradeable.

    function makeTradeable() public {
        require(msg.sender == owner || now > dateMainEnd + 20 weeks);
        tokensTradeable = true;
    }

    function openMigrationPhase() public onlyOwner {
        require(now > dateMainEnd);
        isMigrationPhaseOpen = true;
    }

    // Token minting --------------------------------------

    function mintTokens(uint _mint_type, address _account, uint _tokens) public onlyOwner {
        pMintTokens(_mint_type, _account, _tokens, 0);
    }

    function mintTokensMultiple(uint _mint_type, address[] _accounts, uint[] _tokens) public onlyOwner {
        require(_accounts.length == _tokens.length);
        for (uint i; i < _accounts.length; i++) {
            pMintTokens(_mint_type, _accounts[i], _tokens[i], 0);
        }
    }

    function mintTokensLocked(uint _mint_type, address _account, uint _tokens, uint _term) public onlyOwner {
        pMintTokens(_mint_type, _account, _tokens, _term);
    }

    function mintTokensLockedMultiple(uint _mint_type, address[] _accounts, uint[] _tokens, uint[] _terms) public onlyOwner {
        require(_accounts.length == _tokens.length);
        require(_accounts.length == _terms.length);
        for (uint i; i < _accounts.length; i++) {
            pMintTokens(_mint_type, _accounts[i], _tokens[i], _terms[i]);
        }
    }

    function pMintTokens(uint _mint_type, address _account, uint _tokens, uint _term) private {
        require(whitelist[_account]);
        require(_account != 0x0);
        require(_tokens > 0);
        require(_tokens <= availableToMint(), "not enough tokens available to mint");
        require(_term == 0 || _term > now, "either without lock term, or lock term must be in the future");

        // register locked tokens (will throw if no slot is found)
        if (_term > 0) registerLockedTokens(_account, _tokens, _term);

        // update
        balances[_account] = balances[_account].add(_tokens);
        balancesMinted[_account] = balancesMinted[_account].add(_tokens);
        balancesMintedByType[_account][_mint_type] = balancesMintedByType[_account][_mint_type].add(_tokens);
        tokensMinted = tokensMinted.add(_tokens);
        tokensIssuedTotal = tokensIssuedTotal.add(_tokens);

        // log event
        emit Transfer(0x0, _account, _tokens);
        emit TokensMinted(_mint_type, _account, _tokens, _term);
    }

    // Main sale ------------------------------------------

    function buyTokens() private {

        require(isMain());
        require(msg.value >= MINIMUM_CONTRIBUTION);
        require(whitelist[msg.sender]);

        uint tokens_available = TOKEN_MAIN_CAP.sub(tokensMain);

        // adjust tokens_available on first day, if necessary
        if (isMainFirstDay()) {
            uint tokens_available_first_day = firstDayTokenLimit().sub(balancesMain[msg.sender]);
            if (tokens_available_first_day < tokens_available) {
                tokens_available = tokens_available_first_day;
            }
        }

        require (tokens_available > 0);

        uint tokens_requested = ethToTokens(msg.value);
        uint tokens_issued = tokens_requested;

        uint eth_contributed = msg.value;
        uint eth_returned;

        if (tokens_requested > tokens_available) {
            tokens_issued = tokens_available;
            eth_returned = tokensToEth(tokens_requested.sub(tokens_available));
            eth_contributed = msg.value.sub(eth_returned);
        }

        balances[msg.sender] = balances[msg.sender].add(tokens_issued);
        balancesMain[msg.sender] = balancesMain[msg.sender].add(tokens_issued);
        tokensMain = tokensMain.add(tokens_issued);
        tokensIssuedTotal = tokensIssuedTotal.add(tokens_issued);

        ethContributed[msg.sender] = ethContributed[msg.sender].add(eth_contributed);
        totalEthContributed = totalEthContributed.add(eth_contributed);

        // ether transfers
        if (eth_returned > 0) msg.sender.transfer(eth_returned);
        wallet.transfer(eth_contributed);

        // log
        emit Transfer(0x0, msg.sender, tokens_issued);
        emit RegisterContribution(msg.sender, tokens_issued, eth_contributed, eth_returned);
    }

    // Token exchange / migration to new platform ---------

    function requestTokenExchangeMax() public {
        requestTokenExchange(unlockedTokensInternal(msg.sender));
    }

    function requestTokenExchange(uint _tokens) public {
        require(isMigrationPhaseOpen);
        require(_tokens > 0 && _tokens <= unlockedTokensInternal(msg.sender));
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        tokensIssuedTotal = tokensIssuedTotal.sub(_tokens);
        emit Transfer(msg.sender, 0x0, _tokens);
        emit TokenExchangeRequested(msg.sender, _tokens);
    }

    // ERC20 functions -------------------

    /* Transfer out any accidentally sent ERC20 tokens */

    function transferAnyERC20Token(address _token_address, uint _amount) public onlyOwner returns (bool success) {
        return ERC20Interface(_token_address).transfer(owner, _amount);
    }

    /* Override "transfer" */

    function transfer(address _to, uint _amount) public returns (bool success) {
        require(tokensTradeable);
        require(_amount <= unlockedTokensInternal(msg.sender));
        return super.transfer(_to, _amount);
    }

    /* Override "transferFrom" */

    function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
        require(tokensTradeable);
        require(_amount <= unlockedTokensInternal(_from));
        return super.transferFrom(_from, _to, _amount);
    }

    /* Multiple token transfers from one address to save gas */

    function transferMultiple(address[] _addresses, uint[] _amounts) external {
        require(_addresses.length <= 100);
        require(_addresses.length == _amounts.length);

        // do the transfers
        for (uint j; j < _addresses.length; j++) {
            transfer(_addresses[j], _amounts[j]);
        }

    }

}