pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;
    uint constant preIcoPrice = 4101;
    uint constant icoPrice = 2255;

    function mul(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b != 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) constant internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) constant internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mulByFraction(uint256 number, uint256 numerator, uint256 denominator) internal returns (uint256) {
        return div(mul(number, numerator), denominator);
    }

    // presale volume bonus calculation 
    function presaleVolumeBonus(uint256 price) internal returns (uint256) {

        // preCTX > ETH
        uint256 val = div(price, preIcoPrice);

        if(val >= 100 * BASE) return add(price, price * 1/20); // 5%
        if(val >= 50 * BASE) return add(price, price * 3/100); // 3%
        if(val >= 20 * BASE) return add(price, price * 1/50);  // 2%

        return price;
    }

    // ICO volume bonus calculation
    function volumeBonus(uint256 etherValue) internal returns (uint256) {

        if(etherValue >= 1000000000000000000000) return 15;// +15% tokens
        if(etherValue >=  500000000000000000000) return 10; // +10% tokens
        if(etherValue >=  300000000000000000000) return 7;  // +7% tokens
        if(etherValue >=  100000000000000000000) return 5;  // +5% tokens
        if(etherValue >=   50000000000000000000) return 3;   // +3% tokens
        if(etherValue >=   20000000000000000000) return 2;   // +2% tokens

        return 0;
    }

    // ICO date bonus calculation
    function dateBonus(uint startIco) internal returns (uint256) {

        // day from ICO start
        uint daysFromStart = (now - startIco) / DAY_IN_SECONDS + 1;

        if(daysFromStart == 1) return 15; // +15% tokens
        if(daysFromStart == 2) return 10; // +10% tokens
        if(daysFromStart == 3) return 10; // +10% tokens
        if(daysFromStart == 4) return 5;  // +5% tokens
        if(daysFromStart == 5) return 5;  // +5% tokens
        if(daysFromStart == 6) return 5;  // +5% tokens

        // no discount
        return 0;
    }

}


/// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
/// @title Abstract token contract - Functions to be implemented by token contracts.

contract AbstractToken {
    // This is not an abstract function, because solc won&#39;t recognize generated getter functions for public variables as functions
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {
    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => bool) ownerAppended;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    address[] public owners;

    /*
     *  Read and write storage functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            if(!ownerAppended[_to]) {
                ownerAppended[_to] = true;
                owners.push(_to);
            }
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read storage functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}


contract CarTaxiToken is StandardToken, SafeMath {
    /*
     * Token meta data
     */
    string public constant name = "CarTaxi";
    string public constant symbol = "CTX";
    uint public constant decimals = 18;

    // tottal supply

    address public icoContract = 0x0;
    /*
     * Modifiers
     */

    modifier onlyIcoContract() {
        // only ICO contract is allowed to proceed
        require(msg.sender == icoContract);
        _;
    }

    /*
     * Contract functions
     */

    /// @dev Contract is needed in icoContract address
    /// @param _icoContract Address of account which will be mint tokens
    function CarTaxiToken(address _icoContract) {
        assert(_icoContract != 0x0);
        icoContract = _icoContract;
    }

    /// @dev Burns tokens from address. It&#39;s can be applied by account with address this.icoContract
    /// @param _from Address of account, from which will be burned tokens
    /// @param _value Amount of tokens, that will be burned
    function burnTokens(address _from, uint _value) onlyIcoContract {
        assert(_from != 0x0);
        require(_value > 0);

        balances[_from] = sub(balances[_from], _value);
    }

    /// @dev Adds tokens to address. It&#39;s can be applied by account with address this.icoContract
    /// @param _to Address of account to which the tokens will pass
    /// @param _value Amount of tokens
    function emitTokens(address _to, uint _value) onlyIcoContract {
        assert(_to != 0x0);
        require(_value > 0);

        balances[_to] = add(balances[_to], _value);

        if(!ownerAppended[_to]) {
            ownerAppended[_to] = true;
            owners.push(_to);
        }

    }

    function getOwner(uint index) constant returns (address, uint256) {
        return (owners[index], balances[owners[index]]);
    }

    function getOwnerCount() constant returns (uint) {
        return owners.length;
    }

}


contract CarTaxiIco is SafeMath {
    /*
     * ICO meta data
     */
    CarTaxiToken public cartaxiToken;
    AbstractToken public preIcoToken;

    enum State{
        Pause,
        Init,
        Running,
        Stopped,
        Migrated
    }

    State public currentState = State.Pause;

    uint public startIcoDate = 0;

    // Address of account to which ethers will be tranfered in case of successful ICO
    address public escrow;
    // Address of manager
    address public icoManager;
    // Address of a account, that will transfer tokens from pre-ICO
    address public tokenImporter = 0x0;
    // Addresses of founders and bountyOwner
    address public founder1;
    address public founder2;
    address public founder3;
    address public founder4;
    address public bountyOwner;

    // 487.500.000 CTX tokens
    uint public constant supplyLimit = 487500000000000000000000000;

    //  12500000 CTX is token for bountyOwner
    uint public constant bountyOwnersTokens = 12500000000000000000000000;

    // 1 ETH = 2255 CTX
    uint public constant PRICE = 2255;

    // BASE = 10^18
    uint constant BASE = 1000000000000000000;

    // 2018.02.04 07:00 UTC
    // founders&#39; reward time
    uint public foundersRewardTime = 1517727600;

    // Amount of imported tokens from pre-ICO
    uint public importedTokens = 0;
    // Amount of sold tokens on ICO
    uint public soldTokensOnIco = 0;
    // Amount of issued tokens on pre-ICO = 3047.999951828165582669 * 4101
    uint public constant soldTokensOnPreIco = 12499847802447308000000000;
    // Tokens to founders can be sent only if sentTokensToFounders == false and time > foundersRewardTime
    bool public sentTokensToFounders = false;
    // Tokens to bounty owner can be sent only after ICO
    bool public sentTokensToBountyOwner = false;

    uint public etherRaised = 0;

    /*
     * Modifiers
     */

    modifier whenInitialized() {
        // only when contract is initialized
        require(currentState >= State.Init);
        _;
    }

    modifier onlyManager() {
        // only ICO manager can do this action
        require(msg.sender == icoManager);
        _;
    }

    modifier onIcoRunning() {
        // Checks, if ICO is running and has not been stopped
        require(currentState == State.Running);
        _;
    }

    modifier onIcoStopped() {
        // Checks if ICO was stopped or deadline is reached
        require(currentState == State.Stopped);
        _;
    }

    modifier notMigrated() {
        // Checks if base can be migrated
        require(currentState != State.Migrated);
        _;
    }

    modifier onlyImporter() {
        // only importer contract is allowed to proceed
        require(msg.sender == tokenImporter);
        _;
    }

    /// @dev Constructor of ICO. Requires address of icoManager,
    /// @param _icoManager Address of ICO manager
    /// @param _preIcoToken Address of pre-ICO contract
    function CarTaxiIco(address _icoManager, address _preIcoToken) {
        assert(_preIcoToken != 0x0);
        assert(_icoManager != 0x0);

        cartaxiToken = new CarTaxiToken(this);
        icoManager = _icoManager;
        preIcoToken = AbstractToken(_preIcoToken);
    }

    /// @dev Initialises addresses of founders, tokens owner, escrow.
    /// Initialises balances of tokens owner
    /// @param _founder1 Address of founder 1
    /// @param _founder2 Address of founder 2
    /// @param _founder3 Address of founder 3
    /// @param _founder4 Address of founder 4
    /// @param _escrow Address of escrow
    function init(address _founder1, address _founder2, address _founder3, address _founder4, address _escrow) onlyManager {
        assert(currentState != State.Init);
        assert(_founder1 != 0x0);
        assert(_founder2 != 0x0);
        assert(_founder3 != 0x0);
        assert(_founder4 != 0x0);
        assert(_escrow != 0x0);

        founder1 = _founder1;
        founder2 = _founder2;
        founder3 = _founder3;
        founder4 = _founder4;
        escrow = _escrow;

        currentState = State.Init;
    }

    /// @dev Sets new state
    /// @param _newState Value of new state
    function setState(State _newState) public onlyManager
    {
        currentState = _newState;
        if(currentState == State.Running) {
            startIcoDate = now;
        }
    }

    /// @dev Sets new manager. Only manager can do it
    /// @param _newIcoManager Address of new ICO manager
    function setNewManager(address _newIcoManager) onlyManager {
        assert(_newIcoManager != 0x0);
        icoManager = _newIcoManager;
    }

    /// @dev Sets bounty owner. Only manager can do it
    /// @param _bountyOwner Address of Bounty owner
    function setBountyOwner(address _bountyOwner) onlyManager {
        assert(_bountyOwner != 0x0);
        bountyOwner = _bountyOwner;
    }

    // saves info if account&#39;s tokens were imported from pre-ICO
    mapping (address => bool) private importedFromPreIco;

    /// @dev Imports account&#39;s tokens from pre-ICO. It can be done only by user, ICO manager or token importer
    /// @param _account Address of account which tokens will be imported
    function importTokens(address _account) {
        // only token holder or manager can do migration
        require(msg.sender == icoManager || msg.sender == _account);
        require(!importedFromPreIco[_account]);

        uint preIcoBal = preIcoToken.balanceOf(_account);
        uint preIcoBalance = presaleVolumeBonus(preIcoBal);

        if (preIcoBalance > 0) {
            cartaxiToken.emitTokens(_account, preIcoBalance);
            importedTokens = add(importedTokens, preIcoBalance);
        }

        importedFromPreIco[_account] = true;
    }

    /// @dev Buy quantity of tokens depending on the amount of sent ethers.
    /// @param _buyer Address of account which will receive tokens
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0);
        require(msg.value > 0);

        uint tokensToEmit = msg.value * PRICE;
        //calculate date bonus
        uint dateBonusPercent = dateBonus(startIcoDate);
        //calculate volume bonus
        uint volumeBonusPercent = volumeBonus(msg.value);
        //total bonus tokens
        uint totalBonusPercent = dateBonusPercent + volumeBonusPercent;

        if(totalBonusPercent > 0){
            tokensToEmit =  tokensToEmit + mulByFraction(tokensToEmit, totalBonusPercent, 100);
        }

        require(add(soldTokensOnIco, tokensToEmit) <= supplyLimit);

        soldTokensOnIco = add(soldTokensOnIco, tokensToEmit);

        //emit tokens to token holder
        cartaxiToken.emitTokens(_buyer, tokensToEmit);

        etherRaised = add(etherRaised, msg.value);
    }

    /// @dev Fall back function ~50k-100k gas
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }

    /// @dev Burn tokens from accounts only in state "not migrated". Only manager can do it
    /// @param _from Address of account
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        cartaxiToken.burnTokens(_from, _value);
    }

    /// @dev Partial withdraw. Only manager can do it
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        assert(_value <= this.balance);
        // send 123 to get 1.23
        escrow.transfer(_value * 10000000000000000); // 10^16
    }

    /// @dev Ether withdraw. Only manager can do it
    function withdrawAllEther() onlyManager {
        if(this.balance > 0)
        {
            escrow.transfer(this.balance);
        }
    }

    ///@dev Send tokens to bountyOwner depending on crowdsale results. Can be send only after ICO.
    function sendTokensToBountyOwner() onlyManager whenInitialized {
        require(!sentTokensToBountyOwner);

        //Calculate total tokens sold on pre-ICO and ICO
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

        //Calculate bounty tokens depending on total tokens sold
        uint bountyTokens = mulByFraction(tokensSold, 25, 1000); // 2.5%

        cartaxiToken.emitTokens(bountyOwner, bountyTokens);

        sentTokensToBountyOwner = true;
    }

    /// @dev Send tokens to founders. Can be sent only after cartaxiToken.rewardTime() (2018.02.04 0:00 UTC)
    function sendTokensToFounders() onlyManager whenInitialized {
        require(!sentTokensToFounders && now >= foundersRewardTime);

        //Calculate total tokens sold on pre-ICO and ICO
        uint tokensSold = add(soldTokensOnIco, soldTokensOnPreIco);

        //Calculate founder reward depending on total tokens sold
        uint totalRewardToFounders = mulByFraction(tokensSold, 3166, 10000); // 31.66%

        uint founderReward = mulByFraction(totalRewardToFounders, 25, 100); // 25% pie

        //send every founder 25% of total founder reward
        cartaxiToken.emitTokens(founder1, founderReward);
        cartaxiToken.emitTokens(founder2, founderReward);
        cartaxiToken.emitTokens(founder3, founderReward);
        cartaxiToken.emitTokens(founder4, founderReward);

        sentTokensToFounders = true;
    }
}