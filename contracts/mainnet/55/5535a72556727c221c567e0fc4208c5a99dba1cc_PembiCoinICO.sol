pragma solidity 0.4.14;

// -----------------------------------------------------------------------------
// PembiCoin crowdsale contract.
// Copyright (c) 2017 Pembient, Inc.
// The MIT License.
// -----------------------------------------------------------------------------

contract PembiCoinICO {

    enum State {Active, Idle, Successful, Failed}

    State public currentState = State.Idle;
    uint256 public contributorCount = 0;

    address public owner;

    mapping(uint256 => address) private contributors;
    mapping(address => uint256) private amounts;

    event Transferred(
        address indexed _from,
        address indexed _to,
        uint256 _amount
    );

    event Transitioned(
        address indexed _subject,
        address indexed _object,
        State _oldState,
        State _newState
    );

    function PembiCoinICO() public {
        owner = msg.sender;
    }

    function() external payable inState(State.Active) {
        require(msg.value > 0);
        if (amounts[msg.sender] == 0) {
            contributors[contributorCount] = msg.sender;
            contributorCount = safeAdd(contributorCount, 1);
        }
        amounts[msg.sender] = safeAdd(amounts[msg.sender], msg.value);
        Transferred(msg.sender, address(this), msg.value);
    }

    function refund() external inState(State.Failed) {
        uint256 amount = amounts[msg.sender];
        assert(amount > 0 && amount <= this.balance);
        amounts[msg.sender] = 0;
        msg.sender.transfer(amount);
        Transferred(address(this), msg.sender, amount);
    }

    function payout() external inState(State.Successful) onlyOwner {
        uint256 amount = this.balance;
        owner.transfer(amount);
        Transferred(address(this), owner, amount);
    }

    function setActive() external inState(State.Idle) onlyOwner {
        State oldState = currentState;
        currentState = State.Active;
        Transitioned(msg.sender, address(this), oldState, currentState);
    }

    function setIdle() external inState(State.Active) onlyOwner {
        State oldState = currentState;
        currentState = State.Idle;
        Transitioned(msg.sender, address(this), oldState, currentState);
    }

    function setSuccessful() external inState(State.Idle) onlyOwner {
        State oldState = currentState;
        currentState = State.Successful;
        Transitioned(msg.sender, address(this), oldState, currentState);
    }

    function setFailed() external inState(State.Idle) onlyOwner {
        State oldState = currentState;
        currentState = State.Failed;
        Transitioned(msg.sender, address(this), oldState, currentState);
    }

    function getContribution(uint256 _i)
        external
        constant
        returns (address o_contributor, uint256 o_amount)
    {
        require(_i >= 0 && _i < contributorCount);
        o_contributor = contributors[_i];
        o_amount = amounts[o_contributor];
    }

    function safeAdd(uint256 a, uint256 b)
        private
        constant
        returns (uint256 o_sum)
    {
        o_sum = a + b;
        assert(o_sum >= a && o_sum >= b);
    }

    modifier inState(State _state) {
        require(_state == currentState);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}