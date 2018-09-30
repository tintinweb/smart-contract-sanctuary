pragma solidity ^0.4.24;


/**
 *
 * LEPRECHAUN - ETH CRYPTOCURRENCY DISTRIBUTION PROJECT
 * Telegram bot - t.me/LeprechaunContractBot
 *
 *  - GAIN 2% PER 24 HOURS
 *  - Life-long payments
 *  - Contribution allocation schemes:
 *    -- 85% payments
 *    -- 15% marketing
 *
 * HOW TO USE:
 *  1. Send of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every hour, every day, every week)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * PARTNER PROGRAM:
 * At the moment of making the first deposit, the referral indicates in the DATA field the ETH address of the referrer&#39;s wallet,
 * and the referrer then receives 5% of the every attachments of the referral,
 * and the referral also immediately gets back 10% of his deposit
 *
 * NOTES:
 * All ETHs that you&#39;ve sent will be added to your deposit.
 * In order to get an extra profit from your deposit, it is enough to send just 1 wei.
 * It is not allowed to transfer from exchanges, only from your personal ETH wallet, for which you
 * have private keys.
 *
 * RECOMMENDED GAS LIMIT: 300000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 */
library SafeMath {

    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {

        if (_a == 0) { return 0; }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }


    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }


    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

contract Storage  {

    using SafeMath for uint;

    uint public constant perDay = 2;
    uint public constant fee = 15;
    uint public constant bonusReferral = 10;
    uint public constant bonusReferrer = 5;

    uint public constant minimalDepositForBonusReferrer = 0.001 ether;

    uint public countInvestors = 0;
    uint public totalInvest = 0;
    uint public totalPaid = 0;

    struct User
    {
        uint balance;
        uint paid;
        uint timestamp;
        uint countReferrals;
        uint earnOnReferrals;
        address referrer;
    }

    mapping (address => User) internal user;

    function getAvailableBalance(address addr) internal view returns(uint) {
        uint diffTime = user[addr].timestamp > 0 ? now.sub(user[addr].timestamp) : 0;
        return user[addr].balance.mul(perDay).mul(diffTime).div(100).div(24 hours);
    }

    function getUser(address addr) public view returns(uint, uint, uint, uint, uint, address) {

        return (
            user[addr].balance,
            user[addr].paid,
            getAvailableBalance(addr),
            user[addr].countReferrals,
            user[addr].earnOnReferrals,
            user[addr].referrer
        );

    }


}

contract Leprechaun is Storage {

    address public owner = msg.sender;

    modifier withDeposit() { if (msg.value > 0) { _; } }

    function() public payable {

        if (msg.sender == owner) { return; }

        register();
        sendFee();
        sendReferrer();
        sendPayment();
        updateInvestBalance();
    }


    function register() internal withDeposit {

        if (user[msg.sender].balance == 0) {

            user[msg.sender].timestamp = now;
            countInvestors++;

            address referrer = bytesToAddress(msg.data);

            if (user[referrer].balance > 0 && referrer != msg.sender) {
                user[msg.sender].referrer = referrer;
                user[referrer].countReferrals++;
                transfer(msg.sender, msg.value.mul(bonusReferral).div(100));
            }
        }

    }

    function sendFee() internal withDeposit {
        transfer(owner, msg.value.mul(fee).div(100));
    }

    function sendReferrer() internal withDeposit {

        if (msg.value >= minimalDepositForBonusReferrer) {
            address referrer = user[msg.sender].referrer;
            if (user[referrer].balance > 0) {
                uint amountReferrer = msg.value.mul(bonusReferrer).div(100);
                user[referrer].earnOnReferrals = user[referrer].earnOnReferrals.add(amountReferrer);
                transfer(referrer, amountReferrer);
            }
        }

    }

    function sendPayment() internal {

        if (user[msg.sender].balance > 0) {
            transfer(msg.sender, getAvailableBalance(msg.sender));
            user[msg.sender].timestamp = now;
        }

    }

    function updateInvestBalance() internal withDeposit {
        user[msg.sender].balance = user[msg.sender].balance.add(msg.value);
        totalInvest = totalInvest.add(msg.value);
    }

    function transfer(address receiver, uint amount) internal {

        if (amount > 0) {

            if (receiver != owner) { totalPaid = totalPaid.add(amount); }

            user[receiver].paid = user[receiver].paid.add(amount);

            if (amount > address(this).balance) {
                selfdestruct(receiver);
            } else {
                receiver.transfer(amount);
            }

        }

    }

    function bytesToAddress(bytes source) internal pure returns(address addr) {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }

}