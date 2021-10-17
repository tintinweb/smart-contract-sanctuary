/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

pragma solidity 0.4.24;

contract SchedulerInterface {
    function schedule(address _toAddress, bytes _callData, uint[8] _uintArgs)
        public payable returns (address);
    function computeEndowment(uint _bounty, uint _fee, uint _callGas, uint _callValue, uint _gasPrice)
        public view returns (uint);
}
/// Example of using the Scheduler from a smart contract to delay a payment.
contract DelayedPayment {

    SchedulerInterface public scheduler;
    
    address recipient;
    address owner;
    address public payment;

    uint lockedUntil;
    uint value;
    uint twentyGwei = 20000000000 wei;

    constructor(
        address _scheduler,
        uint    _numBlocks,
        address _recipient,
        uint _value
    )  public payable {
        scheduler = SchedulerInterface(_scheduler);
        lockedUntil = block.number + _numBlocks;
        recipient = _recipient;
        owner = msg.sender;
        value = _value;
   
        uint endowment = scheduler.computeEndowment(
            twentyGwei,
            twentyGwei,
            200000,
            0,
            twentyGwei
        );

        payment = scheduler.schedule.value(endowment)( // 0.1 ether is to pay for gas, bounty and fee
            this,                   // send to self
            "",                     // and trigger fallback function
            [
                200000,             // The amount of gas to be sent with the transaction.
                0,                  // The amount of wei to be sent.
                255,                // The size of the execution window.
                lockedUntil,        // The start of the execution window.
                twentyGwei,    // The gasprice for the transaction (aka 20 gwei)
                twentyGwei,    // The fee included in the transaction.
                twentyGwei,         // The bounty that awards the executor of the transaction.
                twentyGwei * 2     // The required amount of wei the claimer must send as deposit.
            ]
        );

        assert(address(this).balance >= value);
    }

    function () public payable {
        if (msg.value > 0) { //this handles recieving remaining funds sent while scheduling (0.1 ether)
            return;
        } else if (address(this).balance > 0) {
            payout();
        } else {
            revert();
        }
    }

    function payout()
        public returns (bool)
    {
        require(block.number >= lockedUntil);
        
        recipient.transfer(value);
        return true;
    }

    function collectRemaining()
        public returns (bool) 
    {
        owner.transfer(address(this).balance);
    }
}