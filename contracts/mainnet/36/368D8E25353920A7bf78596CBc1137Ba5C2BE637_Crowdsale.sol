pragma solidity ^0.4.15;
contract Base {
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }
    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************
    uint constant internal L00 = 2 ** 0;
    uint constant internal L01 = 2 ** 1;
    uint constant internal L02 = 2 ** 2;
    uint constant internal L03 = 2 ** 3;
    uint constant internal L04 = 2 ** 4;
    uint constant internal L05 = 2 ** 5;
    uint private bitlocks = 0;
    modifier noAnyReentrancy {
        var _locks = bitlocks;
        require(_locks == 0);
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }
}
contract IToken {
    function mint(address _to, uint _amount);
    function start();
    function getTotalSupply() returns(uint);
    function balanceOf(address _owner) returns(uint);
    function transfer(address _to, uint _amount) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function burn(uint256 _amount, address _address)  returns (bool success);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract Owned is Base {
    address public owner;
    address newOwner;
    function Owned() {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) only(owner) {
        newOwner = _newOwner;
    }
    function acceptOwnership() only(newOwner) {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    event OwnershipTransferred(address indexed _from, address indexed _to);
}
contract Crowdsale is Owned {
    using SafeMath for uint;
    enum State { INIT, PRESALE, PREICO, PREICO_FINISHED, ICO_FIRST, ICO_SECOND, ICO_THIRD, STOPPED, CLOSED, EMERGENCY_STOP}
    uint public constant MAX_SALE_SUPPLY = 24 * (10**25);
    uint public constant DECIMALS = (10**18);
    State public currentState = State.INIT;
    IToken public token;
    uint public totalSaleSupply = 0;
    uint public totalFunds = 0;
    uint public tokenPrice = 1000000000000000000; //wei
    uint public bonus = 50000; //50%
    uint public currentPrice;
    address public beneficiary;
    mapping(address => uint) balances;

    address public foundersWallet; //replace
    uint public foundersAmount = 160000000 * DECIMALS;
    uint public maxPreICOSupply = 48 * (10**24);
    uint public maxICOFirstSupply = 84 * (10**24);
    uint public maxICOSecondSupply = 48 * (10**24);
    uint public maxICOThirdSupply = 24 * (10**24);
    uint public currentRoundSupply = 0;
    uint private bonusBase = 100000; //100%;
    modifier inState(State _state){
        require(currentState == _state);
        _;
    }
    modifier salesRunning(){
        require(currentState == State.PREICO
        || currentState == State.ICO_FIRST
        || currentState == State.ICO_SECOND
        || currentState == State.ICO_THIRD);
        _;
    }
    modifier minAmount(){
        require(msg.value >= 0.2 ether);
        _;
    }

    event Transfer(address indexed _to, uint _value);
    function Crowdsale(address _foundersWallet, address _beneficiary){
        beneficiary = _beneficiary;
        foundersWallet = _foundersWallet;
    }
    function initialize(IToken _token)
    public
    only(owner)
    inState(State.INIT)
    {
        require(_token != address(0));
        token = _token;
        currentPrice = tokenPrice;
        _mint(foundersWallet, foundersAmount);
    }
    function setBonus(uint _bonus) public
    only(owner)
    {
        bonus = _bonus;
    }
    function setPrice(uint _tokenPrice)
    public
    only(owner)
    {
        currentPrice = _tokenPrice;
    }
    function setState(State _newState)
    public
    only(owner)
    {
        require(
            currentState == State.INIT && _newState == State.PRESALE
            || currentState == State.PRESALE && _newState == State.PREICO
            || currentState == State.PREICO && _newState == State.PREICO_FINISHED
            || currentState == State.PREICO_FINISHED && _newState == State.ICO_FIRST
            || currentState == State.ICO_FIRST && _newState == State.STOPPED
            || currentState == State.STOPPED && _newState == State.ICO_SECOND
            || currentState == State.ICO_SECOND && _newState == State.STOPPED
            || currentState == State.STOPPED && _newState == State.ICO_THIRD
            || currentState == State.ICO_THIRD && _newState == State.CLOSED
            || _newState == State.EMERGENCY_STOP
        );
        currentState = _newState;
        if(_newState == State.PREICO
        || _newState == State.ICO_FIRST
        || _newState == State.ICO_SECOND
        || _newState == State.ICO_THIRD){
            currentRoundSupply = 0;
        }
        if(_newState == State.CLOSED){
            _finish();
        }
    }
    function setStateWithBonus(State _newState, uint _bonus)
    public
    only(owner)
    {
        require(
            currentState == State.INIT && _newState == State.PRESALE
            || currentState == State.PRESALE && _newState == State.PREICO
            || currentState == State.PREICO && _newState == State.PREICO_FINISHED
            || currentState == State.PREICO_FINISHED && _newState == State.ICO_FIRST
            || currentState == State.ICO_FIRST && _newState == State.STOPPED
            || currentState == State.STOPPED && _newState == State.ICO_SECOND
            || currentState == State.ICO_SECOND && _newState == State.STOPPED
            || currentState == State.STOPPED && _newState == State.ICO_THIRD
            || currentState == State.ICO_THIRD && _newState == State.CLOSED
            || _newState == State.EMERGENCY_STOP
        );
        currentState = _newState;
        bonus = _bonus;
        if(_newState == State.CLOSED){
            _finish();
        }
    }
    function mintPresale(address _to, uint _amount)
    public
    only(owner)
    inState(State.PRESALE)
    {
        require(totalSaleSupply.add(_amount) <= MAX_SALE_SUPPLY);
        totalSaleSupply = totalSaleSupply.add(_amount);
        _mint(_to, _amount);
    }
    function ()
    public
    payable
    salesRunning
    minAmount
    {
        _receiveFunds();
    }



    //==================== Internal Methods =================
    function _receiveFunds()
    internal
    {
        require(msg.value != 0);
        uint transferTokens = msg.value.mul(DECIMALS).div(currentPrice);
        require(totalSaleSupply.add(transferTokens) <= MAX_SALE_SUPPLY);
        uint bonusTokens = transferTokens.mul(bonus).div(bonusBase);
        transferTokens = transferTokens.add(bonusTokens);
        _checkMaxRoundSupply(transferTokens);
        totalSaleSupply = totalSaleSupply.add(transferTokens);
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        totalFunds = totalFunds.add(msg.value);
        _mint(msg.sender, transferTokens);
        beneficiary.transfer(msg.value);
        Transfer(msg.sender, transferTokens);
    }
    function _mint(address _to, uint _amount)
    noAnyReentrancy
    internal
    {
        token.mint(_to, _amount);
    }
    function _checkMaxRoundSupply(uint _amountTokens)
    internal
    {
        if (currentState == State.PREICO) {
            require(currentRoundSupply.add(_amountTokens) <= maxPreICOSupply);
        } else if (currentState == State.ICO_FIRST) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOFirstSupply);
        } else if (currentState == State.ICO_SECOND) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOSecondSupply);
        } else if (currentState == State.ICO_THIRD) {
            require(currentRoundSupply.add(_amountTokens) <= maxICOThirdSupply);
        }
    }

    function burn(uint256 _amount, address _address) only(owner) {
        require(token.burn(_amount, _address));
    }

    function _finish()
    noAnyReentrancy
    internal
    {
        token.start();
    }
}