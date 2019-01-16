// GORGONA.IO
// Get 3% every day!
// Get 3% cash-back if you have referral
// 3% from each referral deposit
// HOW TO GET PARTICIPANT:
// Just send ETH to contract 0x222222 (min. 0.01 ETH)
//
// How to get my dividends?
// Send 0 ETH to contract. No limits.
//
//
// Interest
// IF balance > 0 ETH = 3% per day
// IF balance > 1000 ETH = 2% per day
// IF balance > 4000 ETH = 1% per day


// DO NOT HOLD YOU MONEY ON CONTRACT!
// Get your dividends every day!
// Maximum hold-time 3 days, if you hold more - you lose money
// Maximum dividends only for 3 days


pragma solidity ^0.4.24;


library GrowingControl {
    using GrowingControl for data;

    struct data {
        uint min;
        uint max;

        uint startAt;
        uint maxAmountPerDay;
        mapping(uint => uint) investmentsPerDay;
    }

    function addInvestment(data storage control, uint amount) internal
    {
        control.investmentsPerDay[getCurrentDay()] += amount;
    }

    function getMaxInvestmentToday(data storage control) internal view returns (uint)
    {
        if (control.startAt == 0) {
            return 10000 ether; // disabled
        }

        if (control.startAt > now) {
            return 10000 ether; // too early
        }

        return control.maxAmountPerDay - control.getTodayInvestment();
    }

    function getCurrentDay() internal view returns (uint)
    {
        return now / 24 hours;
    }

    function getTodayInvestment(data storage control) internal view returns (uint)
    {
        return control.investmentsPerDay[getCurrentDay()];
    }
}


library PreEntrance {
    using PreEntrance for data;

    struct data {
        mapping(address => bool) members;

        uint from;
        uint to;
    }

    function isActive(data storage preEntrance) internal view returns (bool)
    {
        if (now < preEntrance.from) {
            return false;
        }

        if (now > preEntrance.to) {
            return false;
        }

        return true;
    }

    function add(data storage preEntrance, address[] addr) internal
    {
        for (uint i = 0; i < addr.length - 1; i++) {
            preEntrance.members[addr[i]] = true;
        }
    }

    function isMember(data storage preEntrance, address addr) internal view returns (bool)
    {
        return preEntrance.members[addr];
    }
}

contract Gorgona {
    using GrowingControl for GrowingControl.data;
    using PreEntrance for PreEntrance.data;

    address public owner;
    uint constant public MINIMUM_INVEST = 10000000000000000 wei;
    uint public currentInterest = 3;
    uint public depositAmount;
    uint public paidAmount;
    uint public round = 1;
    uint public lastPaymentDate;

    uint public advertFee = 5;
    uint public devFee = 7;
    uint public profitThreshold = 2;

    address public devAddr;
    address public advertAddr;

    address[] public addresses;
    mapping(address => Investor) public investors;
    bool public pause;

    struct Perseus {
        address addr;
        uint deposit;
        uint from;
    }

    struct Investor
    {
        uint id;
        uint deposit;
        uint deposits;
        uint paidOut;
        uint date;
        address referrer;
    }

    event Invest(address indexed addr, uint amount, address referrer);
    event Payout(address indexed addr, uint amount, string eventType, address from);
    event NextRoundStarted(uint indexed round, uint date, uint deposit);
    event PerseusUpdate(address addr, string eventType);

    Perseus public perseus;
    GrowingControl.data private growingControl;
    PreEntrance.data private preEntrance;

    // only contract creator access
    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        devAddr = msg.sender;

        addresses.length = 1;

        growingControl.min = 30 ether;
        growingControl.max = 500 ether;

        growingControl.maxAmountPerDay = 100;
    }

    function setAdvertAddr(address addr) onlyOwner public {
        advertAddr = addr;
    }

    function transferOwnership(address addr) onlyOwner public {
        owner = addr;
    }

    function setGrowingControlStartAt(uint startAt) onlyOwner public {
        growingControl.startAt = startAt;
    }

    function getGrowingControlStartAt() public view returns (uint) {
        return growingControl.startAt;
    }

    function setGrowingMaxPerDay(uint maxAmountPerDay) onlyOwner public {
        require(maxAmountPerDay >= growingControl.min && maxAmountPerDay <= growingControl.max, "incorrect amount");
        growingControl.maxAmountPerDay = maxAmountPerDay;
    }

    function addPreEntranceMembers(address[] addr, uint from, uint to) onlyOwner public
    {
        preEntrance.from = from;
        preEntrance.to = to;
        preEntrance.add(addr);
    }

    function() payable public {
        // ensure that payment not from contract
        if (isContract(msg.sender)) {
            revert();
        }

        if (pause) {
            doRestart();
            return;
        }

        if (0 == msg.value) {
            payDividends();
            return;
        }

        if (preEntrance.isActive()) {
            require(preEntrance.isMember(msg.sender), "Only predefined members can make deposit");
        }

        require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.01 ether");
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {
            user.id = addresses.push(msg.sender);
            user.date = now;

            // referrer
            address referrer = bytesToAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            payDividends();
        }

        uint investment = min(growingControl.getMaxInvestmentToday(), msg.value);
        require(investment > 0, "Too much investments today");

        // save investor
        user.deposit += investment;
        user.deposits += 1;

        emit Invest(msg.sender, investment, user.referrer);

        depositAmount += investment;
        lastPaymentDate = now;

        // project fee
        if (devAddr.send(investment / 100 * devFee)) {

        }

        // advert fee
        if (advertAddr.send(investment / 100 * advertFee)) {

        }

        // referrer commission for all deposits
        uint bonusAmount = investment / 100 * currentInterest;

        if (user.referrer > 0x0) {
            if (user.referrer.send(bonusAmount)) {
                emit Payout(user.referrer, bonusAmount, "referral", msg.sender);
            }

            if (user.deposits == 1) {// cashback only for the first deposit
                if (msg.sender.send(bonusAmount)) {
                    emit Payout(msg.sender, bonusAmount, "cash-back", 0);
                }
            }
        } else if (perseus.addr > 0x0 && perseus.from + 24 hours > now) {
            if (perseus.addr.send(bonusAmount)) {
                emit Payout(perseus.addr, bonusAmount, "perseus", msg.sender);
            }
        }

        considerCurrentInterest();
        growingControl.addInvestment(investment);
        considerPerseus(investment);

        if (msg.value > investment) {
            msg.sender.transfer(msg.value - investment);
        }
    }

    function getTodayInvestment() view public returns (uint)
    {
        return growingControl.getTodayInvestment();
    }

    function getMaximumInvestmentPerDay() view public returns (uint)
    {
        return growingControl.maxAmountPerDay;
    }

    function payDividends() private {
        require(investors[msg.sender].id > 0, "Investor not found");
        uint amount = getInvestorDividendsAmount(msg.sender);

        if (amount == 0) {
            return;
        }

        investors[msg.sender].date = now;
        investors[msg.sender].paidOut += amount;
        paidAmount += amount;

        uint balance = address(this).balance;

        if (balance < amount) {
            msg.sender.transfer(balance);
            pause = true;
            return;
        }

        msg.sender.transfer(amount);
        emit Payout(msg.sender, amount, "payout", 0);

        if (investors[msg.sender].paidOut >= investors[msg.sender].deposit * profitThreshold) {
            excludeInvestor(msg.sender);
        }
    }

    function excludeInvestor(address addr) internal
    {
        delete investors[addr];
        //        delete addresses[investors[addr].id];
    }

    function doRestart() private {
        uint txs;
        address addr;

        for (uint i = addresses.length - 1; i > 0; i--) {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
            if (txs++ == 150) {
                return;
            }
        }

        emit NextRoundStarted(round, now, depositAmount);
        pause = false;
        round += 1;
        depositAmount = 0;
        paidAmount = 0;
        lastPaymentDate = now;
    }

    function getInvestorCount() public view returns (uint) {
        return addresses.length - 1;
    }

    function considerCurrentInterest() internal
    {
        uint interest;

        if (depositAmount >= 5000 ether) {
            interest = 1;
        } else if (depositAmount >= 1000 ether) {
            interest = 2;
        } else {
            interest = 3;
        }

        if (interest > currentInterest) {
            return;
        }

        currentInterest = interest;
    }

    function considerPerseus(uint amount) internal {
        if (perseus.addr > 0x0 && perseus.from + 24 hours < now) {
            perseus.addr = 0x0;
            perseus.deposit = 0;
            emit PerseusUpdate(msg.sender, "expired");
        }

        if (amount > perseus.deposit) {
            perseus = Perseus(msg.sender, amount, now);
            emit PerseusUpdate(msg.sender, "change");
        }
    }

    // Calculate dividends for addr
    // Maximum amount of dividends only for 3 days!
    // If you not get divs 4 days - you lost divs for 1 day
    function getInvestorDividendsAmount(address addr) public view returns (uint) {
        uint time = min(now - investors[addr].date, 3 days);
        return investors[addr].deposit / 100 * currentInterest * time / 1 days;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function min(uint a, uint b) public pure returns (uint) {
        if (a < b) return a;
        else return b;
    }
}