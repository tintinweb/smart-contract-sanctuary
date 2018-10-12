pragma solidity ^0.4.24;

/*
 * ETHCutter Contract
 * 
 * - 1% per hour for 5 days (120% total)
 * - 6% referral program (1 level)
 * - 0.1-100 ETH per deposit (unlimited deposits count)
 * 
 *  1. Set an address of you upline in DATA field (if exists), and send 0.1-100 ETH to contract address. Gas limit: 300000.
 *  2. Send 0 or not more than 0.1 ETH and get your profit. You can get profit at any time (every minute, every hour, every day).
 *
 * EMAIL: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0e6b7a666d7b7a7a6b7c4e69636f6762206d6163">[email&#160;protected]</a>
 * TELEGRAM SUPPORT 24/7: https://t.me/ethcutter_support or tg://resolve?domain=ethcutter_support
 * TELEGRAM CHAT (RU): https://t.me/ethcutter_ru or tg://resolve?domain=ethcutter_ru
 * TELEGRAM CHAT (EN): https://t.me/ethcutter_en or tg://resolve?domain=ethcutter_en
 */

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }
        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}

library AddressUtils {
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(_addr)}
        return size > 0;
    }
}

library Helpers {
    function walletFromData(bytes data) internal pure returns (address wallet) {
        assembly {
            wallet := mload(add(data, 20))
        }
    }
}

contract ETHCutter {
    using SafeMath for uint256;
    using AddressUtils for address;

    address public adminWallet;

    uint256 constant public DEPOSIT_MIN = 10 finney;
    uint256 constant public DEPOSIT_MAX = 10 ether;
    uint256 constant public DEPOSIT_PERIOD = 5 days;
    uint256 constant public TOTAL_PERCENT = 120;
    uint256 constant public UPLINE_PERCENT = 6;
    uint256 constant public EXPENSES_PERCENT = 15;

    uint256 public totalDeposited = 0;
    uint256 public totalWithdrawn = 0;
    uint256 public usersCount = 0;
    uint256 public depositsCount = 0;
    uint256 public expenses = 0;

    mapping(address => User) public users;
    mapping(uint256 => Deposit) public deposits;

    struct Deposit {
        uint256 createdAt;
        uint256 endAt;
        uint256 amount;
        uint256 accrued;
        uint256 totalForAccrual;
        bool active;
    }

    struct User {
        uint256 createdAt;
        address upline;
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 depositsCount;
        uint256[] deposits;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminWallet);
        _;
    }

    constructor() public {
        adminWallet = msg.sender;
        createUser(msg.sender, address(0));
    }

    function createUser(address wallet, address upline) internal {
        users[wallet] = User({
            createdAt : now,
            upline : upline,
            totalDeposited : 0,
            totalWithdrawn : 0,
            depositsCount : 0,
            deposits : new uint256[](0)
            });
        usersCount++;
    }

    function createDeposit(address wallet, uint256 amount) internal {
        User storage user = users[wallet];

        Deposit memory deposit = Deposit({
            createdAt : now,
            endAt : now.add(DEPOSIT_PERIOD),
            amount : amount,
            accrued : 0,
            totalForAccrual : amount.div(100).mul(TOTAL_PERCENT),
            active : true
        });

        deposits[depositsCount] = deposit;
        user.deposits.push(depositsCount);

        user.totalDeposited = user.totalDeposited.add(amount);
        totalDeposited = amount.add(totalDeposited);

        user.depositsCount++;
        depositsCount++;
        expenses = expenses.add(amount.div(100).mul(EXPENSES_PERCENT));

        uint256 referralFee = amount.div(100).mul(UPLINE_PERCENT);
        transferReferralFee(user.upline, referralFee);
    }

    function transferReferralFee(address to, uint256 amount) internal {
        if (to != address(0)) {
            to.transfer(amount);
        }
    }

    function getUpline() internal view returns (address){
        address uplineWallet = Helpers.walletFromData(msg.data);
        return users[uplineWallet].createdAt > 0 && msg.sender != uplineWallet
        ? uplineWallet
        : adminWallet;
    }

    function() payable public {
        address wallet = msg.sender;
        uint256 amount = msg.value;

        require(wallet != address(0), &#39;Address incorrect&#39;);
        require(!wallet.isContract(), &#39;Address is contract&#39;);
        require(amount <= DEPOSIT_MAX, &#39;Amount too big&#39;);

        if (users[wallet].createdAt == 0) {
            createUser(wallet, getUpline());
        }

        if (amount >= DEPOSIT_MIN) {
            createDeposit(wallet, amount);
        } else {
            accrualDeposits();
        }
    }

    function accrualDeposits() internal {
        address wallet = msg.sender;
        User storage user = users[wallet];

        for (uint i = 0; i < user.depositsCount; i++) {
            if (deposits[user.deposits[i]].active) {
                accrual(user.deposits[i], wallet);
            }
        }
    }

    function getAccrualAmount(Deposit deposit) internal view returns (uint256){
        uint256 amount = deposit.totalForAccrual
        .div(DEPOSIT_PERIOD)
        .mul(
            now.sub(deposit.createdAt)
        )
        .sub(deposit.accrued);

        if (amount.add(deposit.accrued) > deposit.totalForAccrual) {
            amount = deposit.totalForAccrual.sub(deposit.accrued);
        }

        return amount;
    }

    function accrual(uint256 depositId, address wallet) internal {
        uint256 amount = getAccrualAmount(deposits[depositId]);
        Deposit storage deposit = deposits[depositId];

        withdraw(wallet, amount);

        deposits[depositId].accrued = deposit.accrued.add(amount);

        if (deposits[depositId].accrued >= deposit.totalForAccrual) {
            deposits[depositId].active = false;
        }
    }

    function withdraw(address wallet, uint256 amount) internal {
        wallet.transfer(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        users[wallet].totalWithdrawn = users[wallet].totalWithdrawn.add(amount);
    }

    function withdrawExpenses() public onlyAdmin {
        adminWallet.transfer(expenses);
        expenses = 0;
    }

    function getUserDeposits(address _address) public view returns (uint256[]){
        return users[_address].deposits;
    }

}