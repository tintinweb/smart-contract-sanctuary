pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

contract SafeMath {

    uint constant DAY_IN_SECONDS = 86400;
    uint constant BASE = 1000000000000000000;

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

    // ICO date bonus calculation
    function dateBonus(uint roundIco, uint endIco, uint256 amount) internal returns (uint256) {
        if(endIco >= now && roundIco == 0){
            return add(amount,mulByFraction(amount, 15, 100));
        }else{
            return amount;
        }
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


contract RobotTradingToken is StandardToken, SafeMath {
    /*
     * Token meta data
     */
     
    string public constant name = "Robot Trading";
    string public constant symbol = "RTD";
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
    function RobotTradingToken(address _icoContract) {
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


contract RobotTradingIco is SafeMath {
    /*
     * ICO meta data
     */
    RobotTradingToken public robottradingToken;

    enum State{
        Init,
        Pause,
        Running,
        Stopped,
        Migrated
    }

    State public currentState = State.Pause;

    string public constant name = "Robot Trading ICO";

    // Addresses of founders and other level
    address public accManager;
    address public accFounder;
    address public accPartner;
    address public accCompany;
    address public accRecive;

    // 10,000 M RDT tokens
    uint public supplyLimit = 10000000000000000000000000000;

    // BASE = 10^18
    uint constant BASE = 1000000000000000000;

    // current round ICO
    uint public roundICO = 0;

    struct RoundStruct {
        uint round;//ICO round 0 is preICO other is normal ICO
        uint price;//ICO price for this round 1 ETH = 10000 RDT
        uint supply;//total supply start at 1%
        uint recive;//total recive ETH
        uint soldTokens;//total tokens sold
        uint sendTokens;//total tokens sold
        uint dateStart;//start ICO date
        uint dateEnd; //end ICO date
    }

    RoundStruct[] public roundData;

    bool public sentTokensToFounder = false;
    bool public sentTokensToPartner = false;
    bool public sentTokensToCompany = false;

    uint public tokensToFunder = 0;
    uint public tokensToPartner = 0;
    uint public tokensToCompany = 0;
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
        require(msg.sender == accManager);
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

    /// @dev Constructor of ICO. Requires address of accManager,
    /// @param _accManager Address of ICO manager
    function RobotTradingIco(address _accManager) {
        assert(_accManager != 0x0);

        robottradingToken = new RobotTradingToken(this);
        accManager = _accManager;
    }

    /// @dev Initialises addresses of founders, tokens owner, accRecive.
    /// Initialises balances of tokens owner
    /// @param _founder Address of founder
    /// @param _partner Address of partner
    /// @param _company Address of company
    /// @param _recive Address of recive
    function init(address _founder, address _partner, address _company, address _recive) onlyManager {
        assert(currentState != State.Init);
        assert(_founder != 0x0);
        assert(_recive != 0x0);

        accFounder = _founder;
        accPartner = _partner;
        accCompany = _company;
        accRecive = _recive;

        currentState = State.Init;
    }

    /// @dev Sets new state
    /// @param _newState Value of new state
    function setState(State _newState) public onlyManager
    {
        currentState = _newState;
        if(currentState == State.Running) {
            roundData[roundICO].dateStart = now;
        }
    }
    /// @dev Sets new round ico
    function setNewIco(uint _round, uint _price, uint _startDate, uint _endDate,  uint _newAmount) public onlyManager  whenInitialized {
 
        require(roundData.length == _round);

        RoundStruct memory roundStruct;
        roundData.push(roundStruct);

        roundICO = _round; // round 1 input 1
        roundData[_round].round = _round;
        roundData[_round].price = _price;
        roundData[_round].supply = mul(_newAmount, BASE); //input 10000 got 10000 token for this ico
        roundData[_round].recive = 0;
        roundData[_round].soldTokens = 0;
        roundData[_round].sendTokens = 0;
        roundData[_round].dateStart = _startDate;
        roundData[_round].dateEnd = _endDate;

    }


    /// @dev Sets manager. Only manager can do it
    /// @param _accManager Address of new ICO manager
    function setManager(address _accManager) onlyManager {
        assert(_accManager != 0x0);
        accManager = _accManager;
    }

    /// @dev Buy quantity of tokens depending on the amount of sent ethers.
    /// @param _buyer Address of account which will receive tokens
    function buyTokens(address _buyer) private {
        assert(_buyer != 0x0 && roundData[roundICO].dateEnd >= now && roundData[roundICO].dateStart <= now);
        require(msg.value > 0);

        uint tokensToEmit =  mul(msg.value, roundData[roundICO].price);

        if(roundICO==0){
            tokensToEmit =  dateBonus(roundICO, roundData[roundICO].dateEnd, tokensToEmit);
        }
        require(add(roundData[roundICO].soldTokens, tokensToEmit) <= roundData[roundICO].supply);
        roundData[roundICO].soldTokens = add(roundData[roundICO].soldTokens, tokensToEmit);
 
        //emit tokens to token holder
        robottradingToken.emitTokens(_buyer, tokensToEmit);
        etherRaised = add(etherRaised, msg.value);
    }

    /// @dev Fall back function ~50k-100k gas
    function () payable onIcoRunning {
        buyTokens(msg.sender);
    }

    /// @dev Burn tokens from accounts only in state "not migrated". Only manager can do it
    /// @param _from Address of account
    function burnTokens(address _from, uint _value) onlyManager notMigrated {
        robottradingToken.burnTokens(_from, _value);
    }

    /// @dev Partial withdraw. Only manager can do it
    function withdrawEther(uint _value) onlyManager {
        require(_value > 0);
        assert(_value <= this.balance);
        // send 123 to get 1.23
        accRecive.transfer(_value * 10000000000000000); // 10^16
    }

    /// @dev Ether withdraw. Only manager can do it
    function withdrawAllEther() onlyManager {
        if(this.balance > 0)
        {
            accRecive.transfer(this.balance);
        }
    }

    ///@dev Send tokens to Partner.
    function sendTokensToPartner() onlyManager whenInitialized {
        require(!sentTokensToPartner);

        uint tokensSold = add(roundData[0].soldTokens, roundData[1].soldTokens);
        uint partnerTokens = mulByFraction(supplyLimit, 11, 100); // 11%

        tokensToPartner = sub(partnerTokens,tokensSold);
        robottradingToken.emitTokens(accPartner, partnerTokens);
        sentTokensToPartner = true;
    }

    /// @dev Send limit tokens to Partner. Can&#39;t be sent no more limit 11%
    function sendLimitTokensToPartner(uint _value) onlyManager whenInitialized {
        require(!sentTokensToPartner);
        uint partnerLimit = mulByFraction(supplyLimit, 11, 100); // calc token 11%
        uint partnerReward = sub(partnerLimit, tokensToPartner); // calc token <= 11%
        uint partnerValue = mul(_value, BASE); // send 123 to get 123 token no decimel

        require(partnerReward >= partnerValue);
        tokensToPartner = add(tokensToPartner, partnerValue);
        robottradingToken.emitTokens(accPartner, partnerValue);
    }

    /// @dev Send all tokens to founders. Can&#39;t be sent no more limit 30%
    function sendTokensToCompany() onlyManager whenInitialized {
        require(!sentTokensToCompany);

        //Calculate founder reward depending on total tokens sold
        uint companyLimit = mulByFraction(supplyLimit, 30, 100); // calc token 30%
        uint companyReward = sub(companyLimit, tokensToCompany); // 30% - tokensToCompany = amount for company

        require(companyReward > 0);

        tokensToCompany = add(tokensToCompany, companyReward);

        robottradingToken.emitTokens(accCompany, companyReward);
        sentTokensToCompany = true;
    }

    /// @dev Send limit tokens to company. Can&#39;t be sent no more limit 30%
    function sendLimitTokensToCompany(uint _value) onlyManager whenInitialized {
        require(!sentTokensToCompany);
        uint companyLimit = mulByFraction(supplyLimit, 30, 100); // calc token 30%
        uint companyReward = sub(companyLimit, tokensToCompany); // calc token <= 30%
        uint companyValue = mul(_value, BASE); // send 123 to get 123 token no decimel

        require(companyReward >= companyValue);
        tokensToCompany = add(tokensToCompany, companyValue);
        robottradingToken.emitTokens(accCompany, companyValue);
    }

    /// @dev Send all tokens to founders. 
    function sendAllTokensToFounder(uint _round) onlyManager whenInitialized {
        require(roundData[_round].soldTokens>=1);

        uint icoToken = add(roundData[_round].soldTokens,roundData[_round].sendTokens);
        uint icoSupply = roundData[_round].supply;

        uint founderValue = sub(icoSupply, icoToken);

        roundData[_round].sendTokens = add(roundData[_round].sendTokens, founderValue);
        tokensToFunder = add(tokensToFunder,founderValue);
        robottradingToken.emitTokens(accFounder, founderValue);
    }

    /// @dev Send limit tokens to founders. 
    function sendLimitTokensToFounder(uint _round, uint _value) onlyManager whenInitialized {
        require(roundData[_round].soldTokens>=1);

        uint icoToken = add(roundData[_round].soldTokens,roundData[_round].sendTokens);
        uint icoSupply = roundData[_round].supply;

        uint founderReward = sub(icoSupply, icoToken);
        uint founderValue = mul(_value, BASE); // send 123 to get 123 token no decimel

        require(founderReward >= founderValue);

        roundData[_round].sendTokens = add(roundData[_round].sendTokens, founderValue);
        tokensToFunder = add(tokensToFunder,founderValue);
        robottradingToken.emitTokens(accFounder, founderValue);
    }

    /// @dev inc Supply tokens . Can&#39;t be inc no more 35%
    function incSupply(uint _percent) onlyManager whenInitialized {
        require(_percent<=35);
        supplyLimit = add(supplyLimit,mulByFraction(supplyLimit, _percent, 100));
    }

}