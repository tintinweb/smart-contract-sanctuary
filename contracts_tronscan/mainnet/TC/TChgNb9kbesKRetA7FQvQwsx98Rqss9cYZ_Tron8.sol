//SourceUnit: Tron8.sol

pragma solidity ^0.5.10;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }
}

library Objects {
    struct Investment {
        bool isExpired;
        bool isWithdrawn;
        uint256 amount;
        uint256 createdAt;
        uint256 lastWithdrawalTime;
        uint256 level;
    }

    struct ReferrerLevelInfo {
        uint256 count;
        uint256 earningsAmount;
    }

    struct Investor {
        address addr;
        uint256 referrerUID;
        uint256 availableReferrerEarningsAmount;
        uint256 investmentsCount;
        uint256 reInvestmentsCount;
        uint256 investedAmount;
        uint256 reInvestedAmount;
        uint256 level;
        mapping (uint256 => Investment) investments;
        mapping (uint256 => ReferrerLevelInfo) referrerLevelsInfo;
    }

    struct Settings {
        uint256 rootReferrerCode;
        uint256 investmentPayInterval;
        uint256 referrerLevelsCount;
        uint256 levelsCount;
    }

    struct LevelSettings {
        uint256 investAmountMin;
        uint256 investAmountMax;
        uint256 maxActiveInvestmentsCount;
        uint256 investmentInterest;
        uint256 investmentLifetime;
        mapping (uint256 => uint256) referrerLevelsPercent;
        uint256 upgradeInvestedAmount;
        uint256 upgradeReInvestsCount;
    }

    struct Statistic {
        uint256 investedAmount;
        uint256 reInvestedAmount;
        uint256 withdrawalsAmount;
        uint256 investorsCount;
    }
}

contract Tron8 is Ownable {
    using SafeMath for uint256;

    Objects.Settings public settings;
    Objects.Statistic public statistic;

    mapping (uint256 => Objects.LevelSettings) public levelsSettings;
    mapping (address => uint256) public address2uid;
    mapping (uint256 => Objects.Investor) private uid2investor;

    uint256 public latestInvestorCode;
    address payable public feeAddress;
    address payable public insuranceAddress;
    address payable public marketingAddress;
    address payable public developmentAddress;
    uint256 constant public FEE_PERCENT = 20; // 2%

    event InvestEvent(address investor, uint256 amount, uint256 investorLevel);
    event WithdrawEvent(address investor, uint256 amount);
    event LevelChangeEvent(address investor, uint256 newLevel, uint256 oldLevel);

    constructor(address payable _feeAddress, address payable _insuranceAddress, address payable _marketingAddress, address payable _developmentAddress) public
    {
        feeAddress = _feeAddress;
        insuranceAddress = _insuranceAddress;
        marketingAddress = _marketingAddress;
        developmentAddress = _developmentAddress;

        _initSettings();
        _initStatistic();

        latestInvestorCode = settings.rootReferrerCode;
        address2uid[msg.sender] = latestInvestorCode;
        uid2investor[latestInvestorCode].addr = msg.sender;
        uid2investor[latestInvestorCode].referrerUID = 0;
        uid2investor[latestInvestorCode].availableReferrerEarningsAmount = 0;
        uid2investor[latestInvestorCode].investmentsCount = 0;
        uid2investor[latestInvestorCode].reInvestmentsCount = 0;
        uid2investor[latestInvestorCode].investedAmount = 0;
        uid2investor[latestInvestorCode].reInvestedAmount = 0;
        uid2investor[latestInvestorCode].level = 0;
    }

    function() external
    {
        // Fallback function
    }

    function _initSettings() private
    {
        settings.rootReferrerCode = 100;
        settings.referrerLevelsCount = 5;
        settings.levelsCount = 15;
        settings.investmentPayInterval = 4320 seconds;

        // Level 1
        levelsSettings[0].investAmountMin = 100e6;
        levelsSettings[0].investAmountMax = 200e6;
        levelsSettings[0].maxActiveInvestmentsCount = 2;
        levelsSettings[0].investmentInterest = 1050;
        levelsSettings[0].investmentLifetime = 432000 seconds;
        levelsSettings[0].referrerLevelsPercent[0] = 200; 
        levelsSettings[0].referrerLevelsPercent[1] = 100;
        levelsSettings[0].referrerLevelsPercent[2] = 50;
        levelsSettings[0].referrerLevelsPercent[3] = 30;
        levelsSettings[0].referrerLevelsPercent[4] = 20;
        levelsSettings[0].upgradeInvestedAmount = 0;
        levelsSettings[0].upgradeReInvestsCount = 0;
        // Level 2
        levelsSettings[1].investAmountMin = 200e6;
        levelsSettings[1].investAmountMax = 500e6;
        levelsSettings[1].maxActiveInvestmentsCount = 3;
        levelsSettings[1].investmentInterest = 1060;
        levelsSettings[1].investmentLifetime = 432000 seconds;
        levelsSettings[1].referrerLevelsPercent[0] = 160;
        levelsSettings[1].referrerLevelsPercent[1] = 80;
        levelsSettings[1].referrerLevelsPercent[2] = 40;
        levelsSettings[1].referrerLevelsPercent[3] = 25;
        levelsSettings[1].referrerLevelsPercent[4] = 15;
        levelsSettings[1].upgradeInvestedAmount = 300e6;
        levelsSettings[1].upgradeReInvestsCount = 2;
        // Level 3
        levelsSettings[2].investAmountMin = 500e6;
        levelsSettings[2].investAmountMax = 1200e6;
        levelsSettings[2].maxActiveInvestmentsCount = 4;
        levelsSettings[2].investmentInterest = 1070;
        levelsSettings[2].investmentLifetime = 432000 seconds;
        levelsSettings[2].referrerLevelsPercent[0] = 130;
        levelsSettings[2].referrerLevelsPercent[1] = 60;
        levelsSettings[2].referrerLevelsPercent[2] = 30;
        levelsSettings[2].referrerLevelsPercent[3] = 20;
        levelsSettings[2].referrerLevelsPercent[4] = 10;
        levelsSettings[2].upgradeInvestedAmount = 1200e6;
        levelsSettings[2].upgradeReInvestsCount = 5;
        // Level 4
        levelsSettings[3].investAmountMin = 1200e6;
        levelsSettings[3].investAmountMax = 3000e6;
        levelsSettings[3].maxActiveInvestmentsCount = 5;
        levelsSettings[3].investmentInterest = 1085;
        levelsSettings[3].investmentLifetime = 432000 seconds;
        levelsSettings[3].referrerLevelsPercent[0] = 100;
        levelsSettings[3].referrerLevelsPercent[1] = 50;
        levelsSettings[3].referrerLevelsPercent[2] = 25;
        levelsSettings[3].referrerLevelsPercent[3] = 15;
        levelsSettings[3].referrerLevelsPercent[4] = 10;
        levelsSettings[3].upgradeInvestedAmount = 3000e6;
        levelsSettings[3].upgradeReInvestsCount = 9;
        // Level 5
        levelsSettings[4].investAmountMin = 3000e6;
        levelsSettings[4].investAmountMax = 7500e6;
        levelsSettings[4].maxActiveInvestmentsCount = 6;
        levelsSettings[4].investmentInterest = 1100;
        levelsSettings[4].investmentLifetime = 432000 seconds;
        levelsSettings[4].referrerLevelsPercent[0] = 80;
        levelsSettings[4].referrerLevelsPercent[1] = 40;
        levelsSettings[4].referrerLevelsPercent[2] = 20;
        levelsSettings[4].referrerLevelsPercent[3] = 10;
        levelsSettings[4].referrerLevelsPercent[4] = 10;
        levelsSettings[4].upgradeInvestedAmount = 7500e6;
        levelsSettings[4].upgradeReInvestsCount = 14;
        // Level 6
        levelsSettings[5].investAmountMin = 7500e6;
        levelsSettings[5].investAmountMax = 20000e6;
        levelsSettings[5].maxActiveInvestmentsCount = 7;
        levelsSettings[5].investmentInterest = 1120;
        levelsSettings[5].investmentLifetime = 432000 seconds;
        levelsSettings[5].referrerLevelsPercent[0] = 60;
        levelsSettings[5].referrerLevelsPercent[1] = 30;
        levelsSettings[5].referrerLevelsPercent[2] = 15;
        levelsSettings[5].referrerLevelsPercent[3] = 10;
        levelsSettings[5].referrerLevelsPercent[4] = 5;
        levelsSettings[5].upgradeInvestedAmount = 20000e6;
        levelsSettings[5].upgradeReInvestsCount = 20;
        // Level 7
        levelsSettings[6].investAmountMin = 20000e6;
        levelsSettings[6].investAmountMax = 50000e6;
        levelsSettings[6].maxActiveInvestmentsCount = 8;
        levelsSettings[6].investmentInterest = 1145;
        levelsSettings[6].investmentLifetime = 432000 seconds;
        levelsSettings[6].referrerLevelsPercent[0] = 50;
        levelsSettings[6].referrerLevelsPercent[1] = 25;
        levelsSettings[6].referrerLevelsPercent[2] = 10;
        levelsSettings[6].referrerLevelsPercent[3] = 10;
        levelsSettings[6].referrerLevelsPercent[4] = 5;
        levelsSettings[6].upgradeInvestedAmount = 50000e6;
        levelsSettings[6].upgradeReInvestsCount = 27;
        // Level 8
        levelsSettings[7].investAmountMin = 50000e6;
        levelsSettings[7].investAmountMax = 100000e6;
        levelsSettings[7].maxActiveInvestmentsCount = 9;
        levelsSettings[7].investmentInterest = 1175;
        levelsSettings[7].investmentLifetime = 432000 seconds;
        levelsSettings[7].referrerLevelsPercent[0] = 40;
        levelsSettings[7].referrerLevelsPercent[1] = 20;
        levelsSettings[7].referrerLevelsPercent[2] = 10;
        levelsSettings[7].referrerLevelsPercent[3] = 5;
        levelsSettings[7].referrerLevelsPercent[4] = 5;
        levelsSettings[7].upgradeInvestedAmount = 125000e6;
        levelsSettings[7].upgradeReInvestsCount = 35;
        // Level 9
        levelsSettings[8].investAmountMin = 100000e6;
        levelsSettings[8].investAmountMax = 150000e6;
        levelsSettings[8].maxActiveInvestmentsCount = 10;
        levelsSettings[8].investmentInterest = 1210;
        levelsSettings[8].investmentLifetime = 432000 seconds;
        levelsSettings[8].referrerLevelsPercent[0] = 30;
        levelsSettings[8].referrerLevelsPercent[1] = 15;
        levelsSettings[8].referrerLevelsPercent[2] = 10;
        levelsSettings[8].referrerLevelsPercent[3] = 5;
        levelsSettings[8].referrerLevelsPercent[4] = 0;
        levelsSettings[8].upgradeInvestedAmount = 225000e6;
        levelsSettings[8].upgradeReInvestsCount = 44;
        // Level 10
        levelsSettings[9].investAmountMin = 150000e6;
        levelsSettings[9].investAmountMax = 300000e6;
        levelsSettings[9].maxActiveInvestmentsCount = 11;
        levelsSettings[9].investmentInterest = 1250;
        levelsSettings[9].investmentLifetime = 432000 seconds;
        levelsSettings[9].referrerLevelsPercent[0] = 25;
        levelsSettings[9].referrerLevelsPercent[1] = 10;
        levelsSettings[9].referrerLevelsPercent[2] = 5;
        levelsSettings[9].referrerLevelsPercent[3] = 5;
        levelsSettings[9].referrerLevelsPercent[4] = 0;
        levelsSettings[9].upgradeInvestedAmount = 500000e6;
        levelsSettings[9].upgradeReInvestsCount = 54;
        // Level 11
        levelsSettings[10].investAmountMin = 300000e6;
        levelsSettings[10].investAmountMax = 500000e6;
        levelsSettings[10].maxActiveInvestmentsCount = 12;
        levelsSettings[10].investmentInterest = 1300;
        levelsSettings[10].investmentLifetime = 432000 seconds;
        levelsSettings[10].referrerLevelsPercent[0] = 20;
        levelsSettings[10].referrerLevelsPercent[1] = 10;
        levelsSettings[10].referrerLevelsPercent[2] = 5;
        levelsSettings[10].referrerLevelsPercent[3] = 0;
        levelsSettings[10].referrerLevelsPercent[4] = 0;
        levelsSettings[10].upgradeInvestedAmount = 1000000e6;
        levelsSettings[10].upgradeReInvestsCount = 65;
        // Level 12
        levelsSettings[11].investAmountMin = 500000e6;
        levelsSettings[11].investAmountMax = 1000000e6;
        levelsSettings[11].maxActiveInvestmentsCount = 13;
        levelsSettings[11].investmentInterest = 1350;
        levelsSettings[11].investmentLifetime = 432000 seconds;
        levelsSettings[11].referrerLevelsPercent[0] = 15;
        levelsSettings[11].referrerLevelsPercent[1] = 10;
        levelsSettings[11].referrerLevelsPercent[2] = 5;
        levelsSettings[11].referrerLevelsPercent[3] = 0;
        levelsSettings[11].referrerLevelsPercent[4] = 0;
        levelsSettings[11].upgradeInvestedAmount = 2500000e6;
        levelsSettings[11].upgradeReInvestsCount = 77;
        // Level 13
        levelsSettings[12].investAmountMin = 1000000e6;
        levelsSettings[12].investAmountMax = 1500000e6;
        levelsSettings[12].maxActiveInvestmentsCount = 14;
        levelsSettings[12].investmentInterest = 1400;
        levelsSettings[12].investmentLifetime = 432000 seconds;
        levelsSettings[12].referrerLevelsPercent[0] = 10;
        levelsSettings[12].referrerLevelsPercent[1] = 5;
        levelsSettings[12].referrerLevelsPercent[2] = 0;
        levelsSettings[12].referrerLevelsPercent[3] = 0;
        levelsSettings[12].referrerLevelsPercent[4] = 0;
        levelsSettings[12].upgradeInvestedAmount = 3500000e6;
        levelsSettings[12].upgradeReInvestsCount = 90;
        // Level 14
        levelsSettings[13].investAmountMin = 1500000e6;
        levelsSettings[13].investAmountMax = 2500000e6;
        levelsSettings[13].maxActiveInvestmentsCount = 15;
        levelsSettings[13].investmentInterest = 1500;
        levelsSettings[13].investmentLifetime = 432000 seconds;
        levelsSettings[13].referrerLevelsPercent[0] = 10;
        levelsSettings[13].referrerLevelsPercent[1] = 5;
        levelsSettings[13].referrerLevelsPercent[2] = 0;
        levelsSettings[13].referrerLevelsPercent[3] = 0;
        levelsSettings[13].referrerLevelsPercent[4] = 0;
        levelsSettings[13].upgradeInvestedAmount = 5000000e6;
        levelsSettings[13].upgradeReInvestsCount = 104;
        // Level 15
        levelsSettings[14].investAmountMin = 2500000e6;
        levelsSettings[14].investAmountMax = 2**256 - 15;
        levelsSettings[14].maxActiveInvestmentsCount = 15;
        levelsSettings[14].investmentInterest = 1600;
        levelsSettings[14].investmentLifetime = 432000 seconds;
        levelsSettings[14].referrerLevelsPercent[0] = 10;
        levelsSettings[14].referrerLevelsPercent[1] = 5;
        levelsSettings[14].referrerLevelsPercent[2] = 0;
        levelsSettings[14].referrerLevelsPercent[3] = 0;
        levelsSettings[14].referrerLevelsPercent[4] = 0;
        levelsSettings[14].upgradeInvestedAmount = 10000000e6;
        levelsSettings[14].upgradeReInvestsCount = 119;
    }

    function _initStatistic() private
    {
        statistic.investedAmount = 0;
        statistic.reInvestedAmount = 0;
        statistic.withdrawalsAmount = 0;
        statistic.investorsCount = 0;
    }

    function _addInvestor(address _address, uint256 _referrerUID) private
        returns (uint256)
    {
        if (_referrerUID >= settings.rootReferrerCode) {
            if (uid2investor[_referrerUID].addr == address(0)) {
                _referrerUID = settings.rootReferrerCode;
            }
        } else {
            _referrerUID = settings.rootReferrerCode;
        }

        statistic.investorsCount = statistic.investorsCount.add(1);
        latestInvestorCode = latestInvestorCode.add(1);

        address2uid[_address] = latestInvestorCode;
        uid2investor[latestInvestorCode].addr = _address;
        uid2investor[latestInvestorCode].referrerUID = _referrerUID;
        uid2investor[latestInvestorCode].availableReferrerEarningsAmount = 0;
        uid2investor[latestInvestorCode].investmentsCount = 0;
        uid2investor[latestInvestorCode].reInvestmentsCount = 0;
        uid2investor[latestInvestorCode].investedAmount = 0;
        uid2investor[latestInvestorCode].reInvestedAmount = 0;
        uid2investor[latestInvestorCode].level = 0;

        uint256 _currentReferrerLevelUID = _referrerUID;
        for (uint256 i = 0; i < settings.referrerLevelsCount; i++) {
            if (_currentReferrerLevelUID >= settings.rootReferrerCode) {
                uid2investor[_currentReferrerLevelUID].referrerLevelsInfo[i].count = uid2investor[_currentReferrerLevelUID].referrerLevelsInfo[i].count.add(1);

                _currentReferrerLevelUID = uid2investor[_currentReferrerLevelUID].referrerUID;
            } else break;
        }

        return (latestInvestorCode);
    }

    function _calculateDividends(uint256 _amount, uint256 _interestPercent, uint256 _start, uint256 _end) private view returns (uint256) {
        return (_amount.mul(_interestPercent).div(100000).mul((_end - _start))).div(settings.investmentPayInterval);
    }

    function _payReferralEarnings(uint256 _investorUID, uint256 _investmentAmount, uint256 _referrerUID) private {
        Objects.Investor storage investor = uid2investor[_investorUID];
        Objects.LevelSettings storage levelSettings = levelsSettings[investor.level];

        require(investor.level < settings.levelsCount, "Error in pay earnings: Investor level is bigger then levelsCount");

        if (_referrerUID >= settings.rootReferrerCode) {
            if (uid2investor[_referrerUID].addr == address(0)) {
                _referrerUID = 0;
            }
        } else {
            _referrerUID = 0;
        }

        uint256 _currentReferrerLevelUID = _referrerUID;
        for (uint256 i = 0; i < settings.referrerLevelsCount; i++) {
            if (_currentReferrerLevelUID >= settings.rootReferrerCode) {
                uint256 _earningAmount = (_investmentAmount.mul(levelSettings.referrerLevelsPercent[i])).div(1000);

                uid2investor[_currentReferrerLevelUID].referrerLevelsInfo[i].earningsAmount = uid2investor[_currentReferrerLevelUID].referrerLevelsInfo[i].earningsAmount.add(_earningAmount);
                uid2investor[_currentReferrerLevelUID].availableReferrerEarningsAmount = uid2investor[_currentReferrerLevelUID].availableReferrerEarningsAmount.add(_earningAmount);

                _currentReferrerLevelUID = uid2investor[_currentReferrerLevelUID].referrerUID;
            } else break;
        }
    }

    function _createInvestment(uint256 _investorUID, uint256 _amount) private returns(uint256)
    {
        Objects.Investor storage investor = uid2investor[_investorUID];
        uint256 investmentsCount = investor.investmentsCount;

        Objects.LevelSettings storage levelSettings = levelsSettings[investor.level];

        uint256 activeInvestmentsCount = 0;
        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            Objects.Investment storage investment = investor.investments[i];
            Objects.LevelSettings storage investmentLevelSettings = levelsSettings[investment.level];

            if (block.timestamp < investment.createdAt.add(investmentLevelSettings.investmentLifetime)) {
                activeInvestmentsCount = activeInvestmentsCount.add(1);
            }
        }

        require(activeInvestmentsCount < levelSettings.maxActiveInvestmentsCount, "Maximum active investment limit has been reached");

        Objects.Investment storage investment = investor.investments[investmentsCount];
        investment.isExpired = false;
        investment.isWithdrawn = false;
        investment.amount = _amount;
        investment.createdAt = block.timestamp;
        investment.lastWithdrawalTime = block.timestamp;
        investment.level = investor.level;

        investor.investmentsCount = investor.investmentsCount.add(1);
        investor.investedAmount = investor.investedAmount.add(investment.amount);

        _payReferralEarnings(_investorUID, investment.amount, investor.referrerUID);

        statistic.investedAmount = statistic.investedAmount.add(_amount);

        emit InvestEvent(investor.addr, _amount, investor.level);

        uint256 newLevel = investor.level.add(1);
        if (newLevel < settings.levelsCount && investor.investedAmount >= levelsSettings[newLevel].upgradeInvestedAmount && investor.reInvestmentsCount >= levelsSettings[newLevel].upgradeReInvestsCount) {
            uint256 oldLevel = investor.level;
            investor.level = newLevel;

            emit LevelChangeEvent(investor.addr, newLevel, oldLevel);
        }

        return investmentsCount;
    }

    function invest(uint256 _referrerUID) public payable
    {
        address _address = msg.sender;
        uint256 _amount = msg.value;

        // Validate inputs
        require(!isContract(msg.sender), "Invest from contract not allowed");

        uint256 investorUID = address2uid[_address];

        if (investorUID == 0) {
            investorUID = _addInvestor(_address, _referrerUID);
        }

        Objects.Investor storage investor = uid2investor[investorUID];

        require(_amount >= levelsSettings[investor.level].investAmountMin, "Less than the minimum required invest amount");
        require(_amount <= levelsSettings[investor.level].investAmountMax, "More than the maximum required invest amount");

        _createInvestment(investorUID, _amount);

        uint256 feeAmount = msg.value.mul(FEE_PERCENT).div(1000);
        feeAddress.transfer(feeAmount);
        insuranceAddress.transfer(feeAmount);
        marketingAddress.transfer(feeAmount);
        developmentAddress.transfer(feeAmount);
    }

    function reinvest(uint256 _investmentNum) public
    {
        uint256 investorUID = address2uid[msg.sender];
        require(investorUID != 0, "Can not reinvest because no any investments");

        Objects.Investor storage investor = uid2investor[investorUID];
        require(investor.investmentsCount > _investmentNum, "Can not reinvest because no investment not found");

        Objects.Investment storage investment = investor.investments[_investmentNum];
        Objects.LevelSettings storage levelSettings = levelsSettings[investment.level];
        require(investment.level < settings.levelsCount, "Error in reinvest: Investment level is bigger then levelsCount");

        uint256 expireTime = block.timestamp;
        uint256 investmentEndTime = investment.createdAt.add(levelSettings.investmentLifetime);

        require(!investment.isWithdrawn, "Investment is already withdrawn");
        require(expireTime >= investmentEndTime, "ReInvest available after expire");

        expireTime = investmentEndTime;

        uint256 dividendsAmount = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.createdAt, expireTime);
        require(dividendsAmount >= investment.amount, "Earned amount must be more or equal then invested");

        uint256 amount2reInvest = investment.amount;
        uint256 amount2withdraw = dividendsAmount.sub(investment.amount);

        require(amount2withdraw <= contractBalance(), "Contract balance is exhausted, please try again later");

        investment.isExpired = true;
        investment.isWithdrawn = true;
        investment.lastWithdrawalTime = expireTime;

        investor.reInvestedAmount = investor.reInvestedAmount.add(amount2reInvest);
        investor.reInvestmentsCount = investor.reInvestmentsCount.add(1);

        _createInvestment(investorUID, amount2reInvest);

        statistic.reInvestedAmount = statistic.reInvestedAmount.add(amount2reInvest);
        statistic.withdrawalsAmount = statistic.withdrawalsAmount.add(amount2withdraw);

        msg.sender.transfer(amount2withdraw);
        emit WithdrawEvent(msg.sender, amount2withdraw);
    }

    function withdraw(uint256 _investmentNum) public
    {
        uint256 investorUID = address2uid[msg.sender];
        require(investorUID != 0, "Can not withdraw because no any investments");

        Objects.Investor storage investor = uid2investor[investorUID];
        require(investor.investmentsCount > _investmentNum, "Can not withdraw because no investment not found");

        Objects.Investment storage investment = investor.investments[_investmentNum];
        Objects.LevelSettings storage levelSettings = levelsSettings[investment.level];
        require(investment.level < settings.levelsCount, "Error in reinvest: Investment level is bigger then levelsCount");

        uint256 expireTime = block.timestamp;
        uint256 investmentEndTime = investment.createdAt.add(levelSettings.investmentLifetime);

        require(!investment.isWithdrawn, "Investment is already used");
        require(expireTime >= investmentEndTime, "Withdraw available after expire");

        expireTime = investmentEndTime;

        uint256 dividendsAmount = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.createdAt, expireTime);

        require(dividendsAmount <= contractBalance(), "Contract balance is exhausted, please try again later");

        investment.isExpired = true;
        investment.isWithdrawn = true;
        investment.lastWithdrawalTime = expireTime;

        statistic.withdrawalsAmount = statistic.withdrawalsAmount.add(dividendsAmount);

        if (investor.level > 0) {
            investor.level = investor.level.sub(1);
        }

        msg.sender.transfer(dividendsAmount);
        emit WithdrawEvent(msg.sender, dividendsAmount);
    }

    function withdrawReferralEarnings() public
    {
        uint256 investorUID = address2uid[msg.sender];
        require(investorUID != 0, "Can not withdraw because no any investments");

        Objects.Investor storage investor = uid2investor[investorUID];
        uint256 withdrawalAmount = 0;

        // Withdraw referral earnings
        if (investor.availableReferrerEarningsAmount > 0) {
            withdrawalAmount = withdrawalAmount.add(investor.availableReferrerEarningsAmount);
            investor.availableReferrerEarningsAmount = 0;
        }

        statistic.withdrawalsAmount = statistic.withdrawalsAmount.add(withdrawalAmount);

        require(withdrawalAmount > 0, "Nothing to withdraw");

        uint256 contractBalance = contractBalance();

        if(withdrawalAmount >= contractBalance){
            withdrawalAmount = contractBalance;
        }

        msg.sender.transfer(withdrawalAmount);

        emit WithdrawEvent(msg.sender, withdrawalAmount);
    }

    function investmentsCreatedAtByUid(uint256 _investorUID) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        uint256[] memory responseCreatedAt = new uint256[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            responseCreatedAt[i] = investor.investments[i].createdAt;
        }

        return (responseCreatedAt);
    }

    function investmentsAmountByUid(uint256 _investorUID) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        uint256[] memory responseAmount = new uint256[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            responseAmount[i] = investor.investments[i].amount;
        }

        return (responseAmount);
    }

    function investmentsInvestorLevelByUid(uint256 _investorUID) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        uint256[] memory responseLevels = new uint256[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            responseLevels[i] = investor.investments[i].level;
        }

        return (responseLevels);
    }

    function investmentsIsExpiredByUid(uint256 _investorUID) public view returns (bool[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        bool[] memory responseIsExpired = new bool[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            Objects.Investment storage investment = investor.investments[i];
            Objects.LevelSettings storage levelSettings = levelsSettings[investment.level];

            responseIsExpired[i] = block.timestamp >= investment.createdAt.add(levelSettings.investmentLifetime);
        }

        return (responseIsExpired);
    }

    function investmentsIsWithdrawnByUid(uint256 _investorUID) public view returns (bool[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        bool[] memory responseIsWithdrawn = new bool[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            responseIsWithdrawn[i] = investor.investments[i].isWithdrawn;
        }

        return (responseIsWithdrawn);
    }

    function investmentsTotalDividendByUid(uint256 _investorUID) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        uint256[] memory responseTotalDividends = new uint256[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            Objects.Investment storage investment = investor.investments[i];
            Objects.LevelSettings storage levelSettings = levelsSettings[investment.level];

            responseTotalDividends[i] = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.createdAt, investment.createdAt.add(levelSettings.investmentLifetime));
        }

        return (responseTotalDividends);
    }

    function investmentsAvailableDividendsByUid(uint256 _investorUID) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];

        uint256[] memory responseAvailableDividends = new uint256[](investor.investmentsCount);

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            Objects.Investment storage investment = investor.investments[i];
            Objects.LevelSettings storage levelSettings = levelsSettings[investment.level];

            if (block.timestamp >= investment.createdAt.add(levelSettings.investmentLifetime)) {
                responseAvailableDividends[i] = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.lastWithdrawalTime, investment.createdAt.add(levelSettings.investmentLifetime));
            } else {
                responseAvailableDividends[i] = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.lastWithdrawalTime, block.timestamp);
            }
        }

        return (responseAvailableDividends);
    }

    function investorInfo(address _address) public view
        returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory)
    {
        return investorInfoByUid(address2uid[_address]);
    }

    function investorInfoByUid(uint256 _investorUID) public view
        returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory)
    {
        if (msg.sender != owner) {
            require(address2uid[msg.sender] == _investorUID, "Only owner or self is allowed to perform this action");
        }

        Objects.Investor storage investor = uid2investor[_investorUID];
        Objects.LevelSettings storage levelSettings = levelsSettings[investor.level];

        uint256[] memory referrerCounts = new uint256[](settings.referrerLevelsCount);
        uint256[] memory referrerEarningsAmounts = new uint256[](settings.referrerLevelsCount);

        for (uint256 i = 0; i < settings.referrerLevelsCount; i++) {
            referrerCounts[i] = investor.referrerLevelsInfo[i].count;
            referrerEarningsAmounts[i] = investor.referrerLevelsInfo[i].earningsAmount;
        }

        uint256 investorBalance = investor.availableReferrerEarningsAmount;

        for (uint256 i = 0; i < investor.investmentsCount; i++) {
            Objects.Investment storage investment = investor.investments[i];
            uint256 dividendsAmount = 0;

            if (block.timestamp >= investment.createdAt.add(levelSettings.investmentLifetime)) {
                dividendsAmount = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.lastWithdrawalTime, investment.createdAt.add(levelSettings.investmentLifetime));
            } else {
                dividendsAmount = _calculateDividends(investment.amount, levelSettings.investmentInterest, investment.lastWithdrawalTime, block.timestamp);
            }

            investorBalance = investorBalance.add(dividendsAmount);
        }

        return (
            investor.addr,
            investor.referrerUID,
            investor.level,
            investorBalance,
            investor.availableReferrerEarningsAmount,
            investor.investmentsCount,
            investor.reInvestmentsCount,
            investor.investedAmount,
            investor.reInvestedAmount,
            referrerCounts,
            referrerEarningsAmounts
        );
    }

    function levelSettingReferrerLevels(uint256 level) public view returns (uint256[] memory)
    {
        require(level < settings.levelsCount);

        uint256[] memory list = new uint256[](settings.referrerLevelsCount);

        for (uint256 i = 0; i <= settings.referrerLevelsCount; i++) {
            list[i] = levelsSettings[level].referrerLevelsPercent[i];
        }

        return (list);
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}