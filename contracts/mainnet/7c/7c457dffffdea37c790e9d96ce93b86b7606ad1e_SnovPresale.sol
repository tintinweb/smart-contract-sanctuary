pragma solidity ^0.4.11;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256 ) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256 ) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

    function assert(bool assertion) internal {
        if (!assertion) {
            throw;
        }
    }
}

contract ERC20 {

    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else return false;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else return false;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract Ownable {

    address public owner;
    address public pendingOwner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) throw;
        _;
    }

    // Safe transfer of ownership in 2 steps. Once called, a newOwner needs to call claimOwnership() to prove ownership.
    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
    }

    function claimOwnership() {
        if (msg.sender == pendingOwner) {
            owner = pendingOwner;
            pendingOwner = 0;
        }
    }
}

contract MultiOwnable {

    mapping (address => bool) ownerMap;
    address[] public owners;

    event OwnerAdded(address indexed _newOwner);
    event OwnerRemoved(address indexed _oldOwner);

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) throw;
        _;
    }

    function MultiOwnable() {
        // Add default owner
        address owner = msg.sender;
        ownerMap[owner] = true;
        owners.push(owner);
    }

    function ownerCount() constant returns (uint256) {
        return owners.length;
    }

    function isOwner(address owner) constant returns (bool) {
        return ownerMap[owner];
    }

    function addOwner(address owner) onlyOwner returns (bool) {
        if (!isOwner(owner) && owner != 0) {
            ownerMap[owner] = true;
            owners.push(owner);

            OwnerAdded(owner);
            return true;
        } else return false;
    }

    function removeOwner(address owner) onlyOwner returns (bool) {
        if (isOwner(owner)) {
            ownerMap[owner] = false;
            for (uint i = 0; i < owners.length - 1; i++) {
                if (owners[i] == owner) {
                    owners[i] = owners[owners.length - 1];
                    break;
                }
            }
            owners.length -= 1;

            OwnerRemoved(owner);
            return true;
        } else return false;
    }
}

contract Pausable is Ownable {

    bool public paused;

    modifier ifNotPaused {
        if (paused) throw;
        _;
    }

    modifier ifPaused {
        if (!paused) throw;
        _;
    }

    // Called by the owner on emergency, triggers paused state
    function pause() external onlyOwner {
        paused = true;
    }

    // Called by the owner on end of emergency, returns to normal state
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract TokenSpender {
    function receiveApproval(address _from, uint256 _value);
}

contract BsToken is StandardToken, MultiOwnable {

    bool public locked;

    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 18;
    string public version = &#39;v0.1&#39;;

    address public creator;
    address public seller;
    uint256 public tokensSold;
    uint256 public totalSales;

    event Sell(address indexed _seller, address indexed _buyer, uint256 _value);
    event SellerChanged(address indexed _oldSeller, address indexed _newSeller);

    modifier onlyUnlocked() {
        if (!isOwner(msg.sender) && locked) throw;
        _;
    }

    function BsToken(string _name, string _symbol, uint256 _totalSupplyNoDecimals, address _seller) MultiOwnable() {

        // Lock the transfer function during the presale/crowdsale to prevent speculations.
        locked = true;

        creator = msg.sender;
        seller = _seller;

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupplyNoDecimals * 1e18;

        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }

    function changeSeller(address newSeller) onlyOwner returns (bool) {
        if (newSeller == 0x0 || seller == newSeller) throw;

        address oldSeller = seller;

        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = safeAdd(balances[newSeller], unsoldTokens);
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        SellerChanged(oldSeller, newSeller);
        return true;
    }

    function sellNoDecimals(address _to, uint256 _value) returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner returns (bool) {
        if (balances[seller] >= _value && _value > 0) {
            balances[seller] = safeSub(balances[seller], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(seller, _to, _value);

            tokensSold = safeAdd(tokensSold, _value);
            totalSales = safeAdd(totalSales, 1);
            Sell(seller, _to, _value);
            return true;
        } else return false;
    }

    function transfer(address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function lock() onlyOwner {
        locked = true;
    }

    function unlock() onlyOwner {
        locked = false;
    }

    function burn(uint256 _value) returns (bool) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
            totalSupply = safeSub(totalSupply, _value);
            Transfer(msg.sender, 0x0, _value);
            return true;
        } else return false;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value) {
        TokenSpender spender = TokenSpender(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value);
        }
    }
}

/**
 * In this presale We assume that ETH rate is 320 USD/ETH
 */
contract BsPresale_SNOV is SafeMath, Ownable, Pausable {

    struct Backer {
        uint256 weiReceived; // Amount of wei given by backer
        uint256 tokensSent;  // Amount of tokens received in return to the given amount of ETH.
    }

    // TODO rename to buyers.
    mapping(address => Backer) public backers; // backers indexed by their ETH address

    // (buyerEthAddr => (unixTs => tokensSold))
    mapping (address => mapping (uint256 => uint256)) public externalSales;

    BsToken public token;           // Token contract reference.
    address public beneficiary;     // Address that will receive ETH raised during this presale.
    address public notifier;        // Address that can this presale about changed external conditions.

    uint256 public usdPerEth;
    uint256 public usdPerEthMin = 200; // Lowest boundary of USD/ETH rate
    uint256 public usdPerEthMax = 500; // Highest boundary of USD/ETH rate

    struct UsdPerEthLog {
        uint256 rate;
        uint256 time;
        address changedBy;
    }

    UsdPerEthLog[] public usdPerEthLog; // History of used rates of USD/ETH

    uint256 public minInvestCents = 1; // Because 1 token = 1 cent.
    uint256 public tokensPerCents           = 1.15 * 1e18; // + 15% bonus during presale. Ordinary price is 1 token per 1 USD cent.
    uint256 public tokensPerCents_gte50kUsd = 1.25 * 1e18; // + 25% bonus for contribution >= 50k USD during presale.
    uint256 public amount50kUsdInCents = 50 * 1000 * 100;  // 50k USD in cents.
    uint256 public maxCapInCents       = 15 * 1e6 * 100;   // 15m USD in cents.

    // TODO do we have some amount of privately raised money at start of presale?
    uint256 public totalWeiReceived = 0;   // Total amount of wei received during this presale smart contract.
    uint256 public totalInCents = 0;       // Total amount of USD raised during this presale including (wei -> USD) + (external USD).
    uint256 public totalTokensSold;        // Total amount of tokens sold during this presale.
    uint256 public totalEthSales;          // Total amount of ETH contributions during this presale.
    uint256 public totalExternalSales;     // Total amount of external contributions (USD, BTC, etc.) during this presale.

    uint256 public startTime = 1504526400; // 2017-09-04T12:00:00Z
    uint256 public endTime   = 1507032000; // 2017-10-03T12:00:00Z
    uint256 public finalizedTime = 0;      // Unix timestamp when finalize() was called.

    event BeneficiaryChanged(address indexed _oldAddress, address indexed _newAddress);
    event NotifierChanged(address indexed _oldAddress, address indexed _newAddress);
    event UsdPerEthChanged(uint256 _oldRate, uint256 _newRate);

    event EthReceived(address _buyer, uint256 _amountInWei);
    event ExternalSale(address _buyer, uint256 _amountInUsd, uint256 _tokensSold, uint256 _unixTs);

    modifier respectTimeFrame() {
        if (!isSaleOn()) throw;
        _;
    }

    modifier canNotify() {
        if (msg.sender != owner && msg.sender != notifier) throw;
        _;
    }

    function BsPresale_SNOV(address _token, address _beneficiary, uint256 _usdPerEth) {
        token = BsToken(_token);

        owner = msg.sender;
        notifier = owner;
        beneficiary = _beneficiary;

        setUsdPerEth(_usdPerEth);
    }

    // Override this method to mock current time.
    function getNow() constant returns (uint256) {
        return now;
    }

    function setBeneficiary(address _beneficiary) onlyOwner {
        BeneficiaryChanged(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }

    function setNotifier(address _notifier) onlyOwner {
        NotifierChanged(notifier, _notifier);
        notifier = _notifier;
    }

    function setUsdPerEth(uint256 _usdPerEth) canNotify {
        if (_usdPerEth < usdPerEthMin || _usdPerEth > usdPerEthMax) throw;

        UsdPerEthChanged(usdPerEth, _usdPerEth);
        usdPerEth = _usdPerEth;
        usdPerEthLog.push(UsdPerEthLog({ rate: usdPerEth, time: getNow(), changedBy: msg.sender }));
    }

    function usdPerEthLogSize() constant returns (uint256) {
        return usdPerEthLog.length;
    }

    /*
     * The fallback function corresponds to a donation in ETH
     */
    function() payable {
        sellTokensForEth(msg.sender, msg.value);
    }

    /// We don&#39;t need to use respectTimeFrame modifier here as we do for ETH contributions,
    /// because foreign transaction can came with a delay thus it&#39;s a problem of outer server to manage time.
    /// @param _buyer - ETH address of buyer where we will send tokens to.
    function externalSale(address _buyer, uint256 _amountInUsd, uint256 _tokensSoldNoDecimals, uint256 _unixTs)
            ifNotPaused canNotify {

        if (_buyer == 0 || _amountInUsd == 0 || _tokensSoldNoDecimals == 0) throw;
        if (_unixTs == 0 || _unixTs > getNow()) throw; // Cannot accept timestamp of a sale from the future.

        // If this foreign transaction has been already processed in this contract.
        if (externalSales[_buyer][_unixTs] > 0) throw;

        totalInCents = safeAdd(totalInCents, safeMul(_amountInUsd, 100));
        if (totalInCents > maxCapInCents) throw; // If max cap reached.

        uint256 tokensSold = safeMul(_tokensSoldNoDecimals, 1e18);
        if (!token.sell(_buyer, tokensSold)) throw; // Transfer tokens to buyer.

        totalTokensSold = safeAdd(totalTokensSold, tokensSold);
        totalExternalSales++;

        externalSales[_buyer][_unixTs] = tokensSold;
        ExternalSale(_buyer, _amountInUsd, tokensSold, _unixTs);
    }

    function sellTokensForEth(address _buyer, uint256 _amountInWei) internal ifNotPaused respectTimeFrame {

        uint256 amountInCents = weiToCents(_amountInWei);
        if (amountInCents < minInvestCents) throw;

        totalInCents = safeAdd(totalInCents, amountInCents);
        if (totalInCents > maxCapInCents) throw; // If max cap reached.

        uint256 tokensSold = centsToTokens(amountInCents);
        if (!token.sell(_buyer, tokensSold)) throw; // Transfer tokens to buyer.

        totalWeiReceived = safeAdd(totalWeiReceived, _amountInWei);
        totalTokensSold = safeAdd(totalTokensSold, tokensSold);
        totalEthSales++;

        Backer backer = backers[_buyer];
        backer.tokensSent = safeAdd(backer.tokensSent, tokensSold);
        backer.weiReceived = safeAdd(backer.weiReceived, _amountInWei);  // Update the total wei collected during the crowdfunding for this backer

        EthReceived(_buyer, _amountInWei);
    }

    function totalSales() constant returns (uint256) {
        return safeAdd(totalEthSales, totalExternalSales);
    }

    function weiToCents(uint256 _amountInWei) constant returns (uint256) {
        return safeDiv(safeMul(_amountInWei, usdPerEth * 100), 1 ether);
    }

    function centsToTokens(uint256 _amountInCents) constant returns (uint256) {
        uint256 rate = tokensPerCents;
        // Give -25% discount if buyer sent more than 50k USD.
        if (_amountInCents >= amount50kUsdInCents) {
            rate = tokensPerCents_gte50kUsd;
        }
        return safeMul(_amountInCents, rate);
    }

    function isMaxCapReached() constant returns (bool) {
        return totalInCents >= maxCapInCents;
    }

    function isSaleOn() constant returns (bool) {
        uint256 _now = getNow();
        return startTime <= _now && _now <= endTime;
    }

    function isSaleOver() constant returns (bool) {
        return getNow() > endTime;
    }

    function isFinalized() constant returns (bool) {
        return finalizedTime > 0;
    }

    /*
    * Finalize the presale. Raised money can be sent to beneficiary only if presale hit end time or max cap (15m USD).
    */
    function finalize() onlyOwner {

        // Cannot finalise before end day of presale until max cap is reached.
        if (!isMaxCapReached() && !isSaleOver()) throw;

        beneficiary.transfer(this.balance);

        finalizedTime = getNow();
    }
}

contract SnovPresale is BsPresale_SNOV {

    function SnovPresale() BsPresale_SNOV(
        0xBDC5bAC39Dbe132B1E030e898aE3830017D7d969,
        0x983F64a550CD9D733f2829275f94B1A3728Fe888,
        288
    ) {}
}