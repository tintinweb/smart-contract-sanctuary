pragma solidity ^0.4.8;

// @address 0x
// @multisig
// The implementation for the IME.IME ICO smart contract was inspired by
// the Ethereum token creation tutorial, the FirstBlood token, and the BAT token.
// compiler: 0.4.17+commit.bdeb9e52

/*
1. Contract Address: 0x

2. Official Site URL:https://www.IME.IM/

3. Link to download a 28x28png icon logo:https://IME.IM/TOKENLOGO.png

4. Official Contact Email Address:IM@IME.IM

5. Link to blog (optional):

6. Link to reddit (optional):

7. Link to slack (optional):https://

8. Link to facebook (optional):https://www.facebook.com/

9. Link to twitter (optional):@

10. Link to bitcointalk (optional):

11. Link to github (optional):https://github.com/IMEIM

12. Link to telegram (optional):https://t.me/

13. Link to whitepaper (optional):https://hitepaper_EN.pdf
*/

///////////////
// SAFE MATH //
///////////////

contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }

}


////////////////////
// STANDARD TOKEN //
////////////////////

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*  ERC 20 token */
contract StandardToken is Token {

    mapping (address => uint256) balances;
    //pre ico locked balance
    mapping (address => uint256) lockedBalances;
    mapping (address => uint256) initLockedBalances;

    mapping (address => mapping (address => uint256)) allowed;
    bool allowTransfer = false;

    function transfer(address _to, uint256 _value) public returns (bool success){
        if (balances[msg.sender] >= _value && _value > 0 && allowTransfer) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && allowTransfer) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant public returns (uint256 balance){
        return balances[_owner] + lockedBalances[_owner];
    }
    function availableBalanceOf(address _owner) constant public returns (uint256 balance){
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}

/////////////////////
//IME.IM ICO TOKEN//
/////////////////////

contract IMETOKEN is StandardToken, SafeMath {
    // Descriptive properties
    string public constant name = "IME.IM Token";
    string public constant symbol = "IME";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // Account for ether proceed.
    address public etherProceedsAccount = 0x0;
    address public multiWallet = 0x0;

    //owners
    mapping (address => bool) public isOwner;
    address[] public owners;

    // These params specify the start, end, min, and max of the sale.
    bool public isFinalized;

    uint256 public window0TotalSupply = 0;
    uint256 public window1TotalSupply = 0;
    uint256 public window2TotalSupply = 0;
    uint256 public window3TotalSupply = 0;

    uint256 public window0StartTime = 0;
    uint256 public window0EndTime = 0;
    uint256 public window1StartTime = 0;
    uint256 public window1EndTime = 0;
    uint256 public window2StartTime = 0;
    uint256 public window2EndTime = 0;
    uint256 public window3StartTime = 0;
    uint256 public window3EndTime = 0;

    // setting the capacity of every part of ico
    uint256 public preservedTokens = 1300000000 * 10**decimals;
    uint256 public window0TokenCreationCap = 200000000 * 10**decimals;
    uint256 public window1TokenCreationCap = 200000000 * 10**decimals;
    uint256 public window2TokenCreationCap = 300000000 * 10**decimals;
    uint256 public window3TokenCreationCap = 0 * 10**decimals;

    // Setting the exchange rate for the ICO.
    uint256 public window0TokenExchangeRate = 5000;
    uint256 public window1TokenExchangeRate = 4000;
    uint256 public window2TokenExchangeRate = 3000;
    uint256 public window3TokenExchangeRate = 0;

    uint256 public preICOLimit = 0;
    bool public instantTransfer = false;

    // Events for logging refunds and token creation.
    event CreateGameIco(address indexed _to, uint256 _value);
    event PreICOTokenPushed(address indexed _buyer, uint256 _amount);
    event UnlockBalance(address indexed _owner, uint256 _amount);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    // constructor
    function IMEIM() public
    {
        totalSupply             = 2000000000 * 10**decimals;
        isFinalized             = false;
        etherProceedsAccount    = msg.sender;
    }
    function adjustTime(
    uint256 _window0StartTime, uint256 _window0EndTime,
    uint256 _window1StartTime, uint256 _window1EndTime,
    uint256 _window2StartTime, uint256 _window2EndTime)
    public{
        require(msg.sender == etherProceedsAccount);
        window0StartTime = _window0StartTime;
        window0EndTime = _window0EndTime;
        window1StartTime = _window1StartTime;
        window1EndTime = _window1EndTime;
        window2StartTime = _window2StartTime;
        window2EndTime = _window2EndTime;
    }
    function adjustSupply(
    uint256 _window0TotalSupply,
    uint256 _window1TotalSupply,
    uint256 _window2TotalSupply)
    public{
        require(msg.sender == etherProceedsAccount);
        window0TotalSupply = _window0TotalSupply * 10**decimals;
        window1TotalSupply = _window1TotalSupply * 10**decimals;
        window2TotalSupply = _window2TotalSupply * 10**decimals;
    }
    function adjustCap(
    uint256 _preservedTokens,
    uint256 _window0TokenCreationCap,
    uint256 _window1TokenCreationCap,
    uint256 _window2TokenCreationCap)
    public{
        require(msg.sender == etherProceedsAccount);
        preservedTokens = _preservedTokens * 10**decimals;
        window0TokenCreationCap = _window0TokenCreationCap * 10**decimals;
        window1TokenCreationCap = _window1TokenCreationCap * 10**decimals;
        window2TokenCreationCap = _window2TokenCreationCap * 10**decimals;
    }
    function adjustRate(
    uint256 _window0TokenExchangeRate,
    uint256 _window1TokenExchangeRate,
    uint256 _window2TokenExchangeRate)
    public{
        require(msg.sender == etherProceedsAccount);
        window0TokenExchangeRate = _window0TokenExchangeRate;
        window1TokenExchangeRate = _window1TokenExchangeRate;
        window2TokenExchangeRate = _window2TokenExchangeRate;
    }
    function setProceedsAccount(address _newEtherProceedsAccount)
    public{
        require(msg.sender == etherProceedsAccount);
        etherProceedsAccount = _newEtherProceedsAccount;
    }
    function setMultiWallet(address _newWallet)
    public{
        require(msg.sender == etherProceedsAccount);
        multiWallet = _newWallet;
    }
    function setPreICOLimit(uint256 _preICOLimit)
    public{
        require(msg.sender == etherProceedsAccount);
        preICOLimit = _preICOLimit;
    }
    function setInstantTransfer(bool _instantTransfer)
    public{
        require(msg.sender == etherProceedsAccount);
        instantTransfer = _instantTransfer;
    }
    function setAllowTransfer(bool _allowTransfer)
    public{
        require(msg.sender == etherProceedsAccount);
        allowTransfer = _allowTransfer;
    }
    function addOwner(address owner)
    public{
        require(msg.sender == etherProceedsAccount);
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }
    function removeOwner(address owner)
    public{
        require(msg.sender == etherProceedsAccount);
        isOwner[owner] = false;
        OwnerRemoval(owner);
    }

    function preICOPush(address buyer, uint256 amount)
    public{
        require(msg.sender == etherProceedsAccount);

        uint256 tokens = 0;
        uint256 checkedSupply = 0;
        checkedSupply = safeAdd(window0TotalSupply, amount);
        require(window0TokenCreationCap >= checkedSupply);
        assignLockedBalance(buyer, amount);
        window0TotalSupply = checkedSupply;
        PreICOTokenPushed(buyer, amount);
    }
    function lockedBalanceOf(address _owner) constant public returns (uint256 balance) {
        return lockedBalances[_owner];
    }
    function initLockedBalanceOf(address _owner) constant public returns (uint256 balance) {
        return initLockedBalances[_owner];
    }
    function unlockBalance(address _owner, uint256 prob)
    public
    ownerExists(msg.sender)
    returns (bool){
        uint256 shouldUnlockedBalance = 0;
        shouldUnlockedBalance = initLockedBalances[_owner] * prob / 100;
        if(shouldUnlockedBalance > lockedBalances[_owner]){
            shouldUnlockedBalance = lockedBalances[_owner];
        }
        balances[_owner] += shouldUnlockedBalance;
        lockedBalances[_owner] -= shouldUnlockedBalance;
        UnlockBalance(_owner, shouldUnlockedBalance);
        return true;
    }

    function () payable public{
        create();
    }
    function create() internal{
        require(!isFinalized);
        require(msg.value >= 0.01 ether);
        uint256 tokens = 0;
        uint256 checkedSupply = 0;

        if(window0StartTime != 0 && window0EndTime != 0 && time() >= window0StartTime && time() <= window0EndTime){
            if(preICOLimit > 0){
                require(msg.value >= preICOLimit);
            }
            tokens = safeMult(msg.value, window0TokenExchangeRate);
            checkedSupply = safeAdd(window0TotalSupply, tokens);
            require(window0TokenCreationCap >= checkedSupply);
            assignLockedBalance(msg.sender, tokens);
            window0TotalSupply = checkedSupply;
            if(multiWallet != 0x0 && instantTransfer) multiWallet.transfer(msg.value);
            CreateGameIco(msg.sender, tokens);
        }else if(window1StartTime != 0 && window1EndTime!= 0 && time() >= window1StartTime && time() <= window1EndTime){
            tokens = safeMult(msg.value, window1TokenExchangeRate);
            checkedSupply = safeAdd(window1TotalSupply, tokens);
            require(window1TokenCreationCap >= checkedSupply);
            balances[msg.sender] += tokens;
            window1TotalSupply = checkedSupply;
            if(multiWallet != 0x0 && instantTransfer) multiWallet.transfer(msg.value);
            CreateGameIco(msg.sender, tokens);
        }else if(window2StartTime != 0 && window2EndTime != 0 && time() >= window2StartTime && time() <= window2EndTime){
            tokens = safeMult(msg.value, window2TokenExchangeRate);
            checkedSupply = safeAdd(window2TotalSupply, tokens);
            require(window2TokenCreationCap >= checkedSupply);
            balances[msg.sender] += tokens;
            window2TotalSupply = checkedSupply;
            if(multiWallet != 0x0 && instantTransfer) multiWallet.transfer(msg.value);
            CreateGameIco(msg.sender, tokens);
        }else{
            require(false);
        }

    }

    function time() internal returns (uint) {
        return block.timestamp;
    }

    function today(uint startTime) internal returns (uint) {
        return dayFor(time(), startTime);
    }

    function dayFor(uint timestamp, uint startTime) internal returns (uint) {
        return timestamp < startTime ? 0 : safeSubtract(timestamp, startTime) / 24 hours + 1;
    }

    function withDraw(uint256 _value) public{
        require(msg.sender == etherProceedsAccount);
        if(multiWallet != 0x0){
            multiWallet.transfer(_value);
        }else{
            etherProceedsAccount.transfer(_value);
        }
    }

    function finalize() public{
        require(!isFinalized);
        require(msg.sender == etherProceedsAccount);
        isFinalized = true;
        if(multiWallet != 0x0){
            assignLockedBalance(multiWallet, totalSupply- window0TotalSupply- window1TotalSupply - window2TotalSupply);
            if(this.balance > 0) multiWallet.transfer(this.balance);
        }else{
            assignLockedBalance(etherProceedsAccount, totalSupply- window0TotalSupply- window1TotalSupply - window2TotalSupply);
            if(this.balance > 0) etherProceedsAccount.transfer(this.balance);
        }
    }

    function supply() constant public returns (uint256){
        return window0TotalSupply + window1TotalSupply + window2TotalSupply;
    }

    function assignLockedBalance(address _owner, uint256 val) private{
        initLockedBalances[_owner] += val;
        lockedBalances[_owner] += val;
    }

}