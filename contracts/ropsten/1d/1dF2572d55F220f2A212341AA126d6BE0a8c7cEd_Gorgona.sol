pragma solidity ^0.4.24;

contract Gorgona {
    address public owner;
    address public adminAddr;
    uint constant public MASS_TRANSACTION_LIMIT = 150;
    uint constant public MINIMUM_INVEST = 10000000000000000 wei;
    uint constant public INTEREST = 3;
    uint public depositAmount;
    uint public round;
    uint public lastPaymentDate;
    GorgonaKiller public gorgonaKiller;
    address[] public addresses;
    mapping(address => Investor) public investors;
    bool public pause;

    struct Investor
    {
        uint id;
        uint deposit;
        uint deposits;
        uint date;
        address referrer;
    }

    struct GorgonaKiller
    {
        address addr;
        uint deposit;
    }

    event Invest(address addr, uint amount, address referrer);
    event Payout(address addr, uint amount, string eventType, address from);
    event NextRoundStarted(uint round, uint date, uint deposit);
    event GorgonaKillerChanged(address addr, uint deposit);

    modifier onlyOwner {if (msg.sender == owner) _;}

    constructor() public {
        owner = msg.sender;
        adminAddr = msg.sender;
        addresses.length = 1;
        round = 1;
    }

    function transferOwnership(address addr) onlyOwner public {
        owner = addr;
    }

    function addInvestors(address[] _addr, uint[] _deposit, uint[] _date, address[] _referrer) onlyOwner public {
        // add initiated investors
        for (uint i = 0; i < _addr.length; i++) {
            uint id = addresses.length;
            if (investors[_addr[i]].deposit == 0) {
                addresses.push(_addr[i]);
                depositAmount += investors[_addr[i]].deposit;
            }

            investors[_addr[i]] = Investor(id, _deposit[i], 1, _date[i], _referrer[i]);
            emit Invest(_addr[i], _deposit  [i], _referrer[i]);

            if (investors[_addr[i]].deposit > gorgonaKiller.deposit) {
                gorgonaKiller = GorgonaKiller(_addr[i], investors[_addr[i]].deposit);
            }
        }
        lastPaymentDate = now;
    }

    function() payable public {
        if (owner == msg.sender) {
            return;
        }

        if (0 == msg.value) {
            payoutSelf();
            return;
        }

        require(false == pause, "Gorgona is restarting. Please wait.");
        require(msg.value >= MINIMUM_INVEST, "Too small amount, minimum 0.01 ether");
        Investor storage user = investors[msg.sender];

        if (user.id == 0) {
            // ensure that payment not from hacker contract
            msg.sender.transfer(0 wei);
            addresses.push(msg.sender);
            user.id = addresses.length;
            user.date = now;

            // referrer
            address referrer = bytesToAddress(msg.data);
            if (investors[referrer].deposit > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }
        } else {
            payoutSelf();
        }

        // save investor
        user.deposit += msg.value;
        user.deposits += 1;

        emit Invest(msg.sender, msg.value, user.referrer);

        depositAmount += msg.value;
        lastPaymentDate = now;

        adminAddr.transfer(msg.value / 5); // project fee
        uint bonusAmount = (msg.value / 100) * INTEREST; // referrer commission for all deposits

        if (user.referrer > 0x0) {
            if (user.referrer.send(bonusAmount)) {
                emit Payout(user.referrer, bonusAmount, "referral", msg.sender);
            }

            if (user.deposits == 1) { // cashback only for the first deposit
                if (msg.sender.send(bonusAmount)) {
                    emit Payout(msg.sender, bonusAmount, "cash-back", 0);
                }
            }
        } else if (gorgonaKiller.addr > 0x0) {
            if (gorgonaKiller.addr.send(bonusAmount)) {
                emit Payout(gorgonaKiller.addr, bonusAmount, "killer", msg.sender);
            }
        }

        if (user.deposit > gorgonaKiller.deposit) {
            gorgonaKiller = GorgonaKiller(msg.sender, user.deposit);
            emit GorgonaKillerChanged(msg.sender, user.deposit);
        }
    }

    function payout(uint offset) public
    {
        if (pause == true) {
            doRestart();
            return;
        }

        uint txs;
        uint amount;

        for (uint idx = addresses.length - offset - 1; idx >= 1 && txs < MASS_TRANSACTION_LIMIT; idx--) {
            address addr = addresses[idx];
            if (investors[addr].date + 20 hours > now) {
                continue;
            }

            amount = getInvestorDividendsAmount(addr);
            investors[addr].date = now;

            if (address(this).balance < amount) {
                pause = true;
                return;
            }

            if (addr.send(amount)) {
                emit Payout(addr, amount, "bulk-payout", 0);
            }

            txs++;
        }
    }

    function payoutSelf() private {
        require(investors[msg.sender].id > 0, "Investor not found.");
        uint amount = getInvestorDividendsAmount(msg.sender);

        investors[msg.sender].date = now;
        if (address(this).balance < amount) {
            pause = true;
            return;
        }

        msg.sender.transfer(amount);
        emit Payout(msg.sender, amount, "self-payout", 0);
    }

    function doRestart() private {
        uint txs;
        address addr;

        for (uint i = addresses.length - 1; i > 0; i--) {
            addr = addresses[i];
            addresses.length -= 1;
            delete investors[addr];
            if (txs++ == MASS_TRANSACTION_LIMIT) {
                return;
            }
        }

        emit NextRoundStarted(round, now, depositAmount);
        pause = false;
        round += 1;
        depositAmount = 0;
        lastPaymentDate = now;

        delete gorgonaKiller;
    }

    function getInvestorCount() public view returns (uint) {
        return addresses.length - 1;
    }

    function getInvestorDividendsAmount(address addr) public view returns (uint) {
        return investors[addr].deposit / 100 * INTEREST * (now - investors[addr].date) / 1 days;
    }

    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}