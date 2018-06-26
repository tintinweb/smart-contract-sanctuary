pragma solidity ^0.4.19;


contract AtomicSwap
{
    enum State
    {
        Initiated,
        Redeemed,
        Refunded
    }

    event Initiate(address indexed initiator, address indexed participant, uint amount, bytes32 secretHash, uint timeout, uint date);

    event Redeem(string secret, uint date);

    event Refund(uint date);

    function AtomicSwap(address _participant, uint amount, bytes32 secretHash, uint timeout) public payable
    {
        require(msg.value == amount);

        initTimestamp = block.timestamp;
        refundTime = initTimestamp + timeout;
        value = amount;
        hashedSecret = secretHash;
        initiator = msg.sender;
        state = State.Initiated;
        participant = _participant;

        Initiate(msg.sender, participant, amount, secretHash, timeout, block.timestamp);
    }

    function redeem(string secret) external
    {
        require(state == State.Initiated);
        require(sha256(secret) == hashedSecret);
        require(!emptied);
        require(block.timestamp < refundTime);

        emptied = true;
        participant.transfer(value);
        state = State.Redeemed;

        Redeem(secret, block.timestamp);
    }

    function refund() external
    {
        require(state == State.Initiated);
        require(!emptied);
        require(block.timestamp > refundTime);

        emptied = true;
        initiator.transfer(value);
        state = State.Refunded;

        Refund(block.timestamp);
    }

    uint public initTimestamp;

    uint public refundTime;
    
    bytes32 public hashedSecret;
    
    address public initiator;
    
    address public participant;
    
    uint256 public value;
    
    bool public emptied;
    
    State public state;
}