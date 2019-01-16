pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/SmartSplitt.sol

contract SmartSplitt {
    using SafeMath for uint256;

    uint256 constant public ONE_HUNDRED_PERCENTS = 10000;               // 100%
    uint256 constant public ADMIN_FEE = 500;                            // 5%
    uint256 constant public MARKETING_FEE = 500;                        // 5%
    uint256 constant public BOUNTY_FEE = 100;                           // 1%
    uint256 constant public MAX_USER_DEPOSITS_COUNT = 50;
    uint256 constant public REFBACK_PERCENT = 150;                      // 1.5%
    uint256[] /*constant*/ public tariffPercents = [265, 350, 470];     // 2.65%, 3.5%, 4.7%
    uint256[] /*constant*/ public tariffDuration = [60 days, 40 days, 35 days];
    uint256[] /*constant*/ public tariffAmount = [1 ether, 15 ether, 50 ether];

    struct Deposit {
        uint256 time;
        uint256 amount;
    }

    struct User {
        uint256 lastPayment;
        uint256 reinvestReward;
        uint256 dividendsReward;
        Deposit[] deposits;
    }

    address public admin = 0xDB6827de6b9Fc722Dc4EFa7e35f3b78c54932494;
    address public marketing = 0x31CdA77ab136c8b971511473c3D04BBF7EAe8C0f;
    address public bounty = 0x36c92a9Da5256EaA5Ccc355415271b7d2682f32E;
    uint256 public totalDeposits;
    uint256 public totalInvestors;
    bool public running = true;
    mapping(address => User) public users;

    event InvestorAdded(address indexed investor);
    event ReferrerAdded(address indexed investor, address indexed referrer);
    event DepositAdded(address indexed investor, uint256 indexed depositsCount, uint256 amount);
    event UserDividendPayed(address indexed investor, uint256 dividend);
    event DepositDividendPayed(address indexed investor, uint256 indexed index, uint256 deposit, uint256 totalPayed, uint256 dividend);
    event ReferrerPayed(address indexed investor, address indexed referrer, uint256 amount);
    event FeePayed(address indexed investor, uint256 amount);
    event TotalDepositsChanged(uint256 totalDeposits);
    event BalanceChanged(uint256 balance);
    
    function() external payable {
        require(running, "SmartSplitt is not running");
        
        _payoutDividends(msg.sender, msg.sender, 0);
        
        if (msg.value > 0) {
            _createDeposit(msg.sender, msg.value, false);
        }

        emit BalanceChanged(address(this).balance);
    }

    function reinvest() external {
        require(running, "SmartSplitt is not running");

        uint256 dividendsSum = _payoutDividends(msg.sender, this, 0);

        if (dividendsSum > 0) {
            _createDeposit(msg.sender, dividendsSum, true);
        }
    }

    function enableAutoReinvest(uint256 reinvestReward) external {
        require(reinvestReward <= 10 finney, "Reward is to high"); // 0.01 ETH
        users[msg.sender].reinvestReward = reinvestReward;
    }

    function disableAutoReinvest() external {
        users[msg.sender].reinvestReward = 0;
    }

    function enableAutoDividends(uint256 dividendsReward) external {
        require(dividendsReward <= 10 finney, "Reward is to high"); // 0.01 ETH
        users[msg.sender].dividendsReward = dividendsReward;
    }

    function disableAutoDividends() external {
        users[msg.sender].dividendsReward = 0;
    }

    function autoDividendsFor(address who) external {
        User storage user = users[who];
        require(user.dividendsReward > 0, "User disabled auto-dividends");
        require(now > user.lastPayment.add(1 days), "Auto-dividends can be performed once per day");

        _payoutDividends(who, this, user.dividendsReward);

        msg.sender.transfer(user.dividendsReward);
    }

    function autoReinvestFor(address who) external {
        User storage user = users[who];
        require(user.reinvestReward > 0, "User disabled auto-reinvest");
        require(now > user.lastPayment.add(1 days), "Auto-reinvest can be performed once per day");

        uint256 dividendsSum = _payoutDividends(who, this, user.reinvestReward);
        _createDeposit(who, dividendsSum, true);

        msg.sender.transfer(user.reinvestReward);
    }

    // View methods

    function depositsCountForUser(address wallet) public view returns(uint256) {
        return users[wallet].deposits.length;
    }

    function depositForUser(address wallet, uint256 index) public view returns(uint256 time, uint256 amount) {
        time = users[wallet].deposits[index].time;
        amount = users[wallet].deposits[index].amount;
    }

    function dividendsSumForUser(address wallet) public view returns(uint256 dividendsSum) {
        return _dividendsSum(dividendsForUser(wallet));
    }

    function dividendsForUser(address wallet) public view returns(uint256[] dividends) {
        User storage user = users[wallet];
        dividends = new uint256[](user.deposits.length);

        for (uint i = 0; i < user.deposits.length; i++) {
            uint256 deposit = user.deposits[i].amount;
            uint256 tariff = tariffIndexForAmount(deposit);
            uint256 maxDuration = tariffDuration[tariff];

            uint256 howOld = now.sub(user.deposits[i].time);
            uint256 duration = now.sub(user.lastPayment);
            if (howOld > maxDuration) {
                uint256 overtime = howOld.sub(maxDuration);
                duration = duration.sub(overtime);
            }

            dividends[i] = dividendsForAmountAndTime(deposit, duration);
        }
    }

    function dividendsForAmountAndTime(uint256 amount, uint256 duration) public view returns(uint256) {
        uint256 tariff = tariffIndexForAmount(amount);
        uint256 percents = tariffPercents[tariff];
            
        return amount
            .mul(percents).div(ONE_HUNDRED_PERCENTS)
            .mul(duration).div(1 days);
    }

    function tariffIndexForAmount(uint256 amount) public view returns(uint256) {
        for (uint i = 0; i < tariffAmount.length; i++) {
            if (amount <= tariffAmount[i]) {
                return i;
            }
        }
        return tariffAmount.length - 1;
    }

    // Private methods

    function _payoutDividends(address who, address to, uint256 fee) private returns(uint256 dividendsSum) {
        User storage user = users[who];

        uint256[] memory dividends = dividendsForUser(who);
        dividendsSum = _dividendsSum(dividends).sub(fee);
        if (dividendsSum == 0) {
            return;
        }

        if (dividendsSum >= address(this).balance) {
            dividendsSum = address(this).balance;
            running = false;
        }

        if (to != address(this)) {
            to.transfer(dividendsSum);
        }
        user.lastPayment = now;
        emit UserDividendPayed(who, dividendsSum);
        for (uint i = 0; i < dividends.length; i++) {
            emit DepositDividendPayed(
                who,
                i,
                user.deposits[i].amount,
                dividendsForAmountAndTime(user.deposits[i].amount, now.sub(user.deposits[i].time)),
                dividends[i]
            );
        }

        // Cleanup deposits
        for (i = 0; i < user.deposits.length; i++) {
            uint256 deposit = user.deposits[i].amount;
            uint256 tariff = tariffIndexForAmount(deposit);
            uint256 maxDuration = tariffDuration[tariff];

            if (now >= user.deposits[i].time.add(maxDuration)) {
                user.deposits[i] = user.deposits[user.deposits.length - 1];
                user.deposits.length -= 1;
                i -= 1;
            }
        }
    }

    function _createDeposit(address who, uint256 value, bool isReinvesting) private {
        User storage user = users[who];
        
        if (user.lastPayment == 0) {
            user.lastPayment = now;
            totalInvestors += 1;
            emit InvestorAdded(who);
        }

        // Create deposit
        user.deposits.push(Deposit({
            time: now,
            amount: value
        }));
        require(user.deposits.length <= MAX_USER_DEPOSITS_COUNT, "Too many deposits per user");
        emit DepositAdded(who, user.deposits.length, value);

        // Add to total deposits
        totalDeposits = totalDeposits.add(value);
        emit TotalDepositsChanged(totalDeposits);

        if (!isReinvesting) {
            // Pay to referrer
            if (msg.data.length == 20) {
                address referrer = _bytesToAddress(msg.data);
                if (referrer != address(0) && referrer != who && users[referrer].deposits.length > 0) {
                    referrer.transfer(value.mul(REFBACK_PERCENT).div(ONE_HUNDRED_PERCENTS));
                    who.transfer(value.mul(REFBACK_PERCENT).div(ONE_HUNDRED_PERCENTS));
                    emit ReferrerPayed(who, referrer, value);
                }
            }

            // Admin and bounty fees
            uint256 marketingFee = value.mul(MARKETING_FEE).div(ONE_HUNDRED_PERCENTS);
            uint256 bountyFee = value.mul(BOUNTY_FEE).div(ONE_HUNDRED_PERCENTS);
            marketing.send(marketingFee); // solium-disable-line security/no-send
            bounty.send(bountyFee); // solium-disable-line security/no-send
            emit FeePayed(who, marketingFee.add(bountyFee));
        }

        uint256 adminFee = value.mul(ADMIN_FEE).div(ONE_HUNDRED_PERCENTS);
        admin.send(adminFee); // solium-disable-line security/no-send
        emit FeePayed(who, adminFee);
    }

    function _bytesToAddress(bytes data) private pure returns(address addr) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            addr := mload(add(data, 20)) 
        }
    }

    function _dividendsSum(uint256[] dividends) private pure returns(uint256 dividendsSum) {
        for (uint i = 0; i < dividends.length; i++) {
            dividendsSum = dividendsSum.add(dividends[i]);
        }
    }
}