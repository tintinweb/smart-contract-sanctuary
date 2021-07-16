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
        uint256 data;
    }

    struct Investor {
        address referrerAddress;
        uint256 withdrawProfit;
        Investment[] investments;
    }

    struct Settings {
        uint256 levelsCount;
        uint256 investmentPayInterval;
        uint256 investmentLifetime;
    }

    struct LevelSettings {
        uint256 investAmountMin;
        uint256 investAmountMax;
        uint256 investmentInterest;
        uint256 investmentLifetime;
        uint256 referrerPercent;
        uint256 upgradeBalance;
    }

    struct Statistic {
        uint256 investedAmount;
        uint256 withdrawalsAmount;
        uint256 investorsCount;
    }
}

contract Tron8 is Ownable {
    using SafeMath for uint256;

    Objects.Settings public settings;
    Objects.Statistic public statistic;

    mapping (uint256 => Objects.LevelSettings) public levelsSettings;
    mapping (address => Objects.Investor) private investors;

    address payable public feeAddress;
    address payable public insuranceAddress;
    address payable public marketingAddress;
    address payable public developmentAddress;
    uint256 constant public FEE_PERCENT = 20;
    uint256 feeBalance;

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

        investors[msg.sender].referrerAddress = address(0);
    }

    function() external
    {
        // Fallback function
    }

    function _initSettings() private
    {
        settings.levelsCount = 15;
        settings.investmentPayInterval = 4320 seconds;
        settings.investmentLifetime = 432000 seconds;

        // Level 1
        levelsSettings[0].investAmountMin = 100e6;
        levelsSettings[0].investAmountMax = 200e6;
        levelsSettings[0].investmentInterest = 1050;
        levelsSettings[0].referrerPercent = 200;
        levelsSettings[0].upgradeBalance = 0;
        // Level 2
        levelsSettings[1].investAmountMin = 200e6;
        levelsSettings[1].investAmountMax = 500e6;
        levelsSettings[1].investmentInterest = 1060;
        levelsSettings[1].referrerPercent = 160;
        levelsSettings[1].upgradeBalance = 10e6;
        // Level 3
        levelsSettings[2].investAmountMin = 500e6;
        levelsSettings[2].investAmountMax = 1000e6;
        levelsSettings[2].investmentInterest = 1070;
        levelsSettings[2].referrerPercent = 130;
        levelsSettings[2].upgradeBalance = 60e6;
        // Level 4
        levelsSettings[3].investAmountMin = 1000e6;
        levelsSettings[3].investAmountMax = 2000e6;
        levelsSettings[3].investmentInterest = 1085;
        levelsSettings[3].referrerPercent = 100;
        levelsSettings[3].upgradeBalance = 230e6;
        // Level 5
        levelsSettings[4].investAmountMin = 2000e6;
        levelsSettings[4].investAmountMax = 5000e6;
        levelsSettings[4].investmentInterest = 1100;
        levelsSettings[4].referrerPercent = 80;
        levelsSettings[4].upgradeBalance = 700e6;
        // Level 6
        levelsSettings[5].investAmountMin = 5000e6;
        levelsSettings[5].investAmountMax = 10000e6;
        levelsSettings[5].investmentInterest = 1120;
        levelsSettings[5].referrerPercent = 60;
        levelsSettings[5].upgradeBalance = 2000e6;
        // Level 7
        levelsSettings[6].investAmountMin = 10000e6;
        levelsSettings[6].investAmountMax = 20000e6;
        levelsSettings[6].investmentInterest = 1145;
        levelsSettings[6].referrerPercent = 50;
        levelsSettings[6].upgradeBalance = 5500e6;
        // Level 8
        levelsSettings[7].investAmountMin = 20000e6;
        levelsSettings[7].investAmountMax = 50000e6;
        levelsSettings[7].investmentInterest = 1175;
        levelsSettings[7].referrerPercent = 40;
        levelsSettings[7].upgradeBalance = 14000e6;
        // Level 9
        levelsSettings[8].investAmountMin = 50000e6;
        levelsSettings[8].investAmountMax = 100000e6;
        levelsSettings[8].investmentInterest = 1210;
        levelsSettings[8].referrerPercent = 30;
        levelsSettings[8].upgradeBalance = 39000e6;
        // Level 10
        levelsSettings[9].investAmountMin = 100000e6;
        levelsSettings[9].investAmountMax = 200000e6;
        levelsSettings[9].investmentInterest = 1250;
        levelsSettings[9].referrerPercent = 25;
        levelsSettings[9].upgradeBalance = 100000e6;
        // Level 11
        levelsSettings[10].investAmountMin = 200000e6;
        levelsSettings[10].investAmountMax = 500000e6;
        levelsSettings[10].investmentInterest = 1300;
        levelsSettings[10].referrerPercent = 20;
        levelsSettings[10].upgradeBalance = 250000e6;
        // Level 12
        levelsSettings[11].investAmountMin = 500000e6;
        levelsSettings[11].investAmountMax = 1000000e6;
        levelsSettings[11].investmentInterest = 1350;
        levelsSettings[11].referrerPercent = 15;
        levelsSettings[11].upgradeBalance = 675000e6;
        // Level 13
        levelsSettings[12].investAmountMin = 1000000e6;
        levelsSettings[12].investAmountMax = 2000000e6;
        levelsSettings[12].investmentInterest = 1400;
        levelsSettings[12].referrerPercent = 10;
        levelsSettings[12].upgradeBalance = 1500000e6;
        // Level 14
        levelsSettings[13].investAmountMin = 2000000e6;
        levelsSettings[13].investAmountMax = 5000000e6;
        levelsSettings[13].investmentInterest = 1500;
        levelsSettings[13].referrerPercent = 10;
        levelsSettings[13].upgradeBalance = 4000000e6;
        // Level 15
        levelsSettings[14].investAmountMin = 5000000e6;
        levelsSettings[14].investAmountMax = 9999999e6;
        levelsSettings[14].investmentInterest = 1600;
        levelsSettings[14].referrerPercent = 10;
        levelsSettings[14].upgradeBalance = 9999999e6;
    }

    function _calculateDividends(uint256 _amount, uint256 _interestPercent, uint256 _start, uint256 _end) private view returns (uint256) {
        return (_amount.mul(_interestPercent).div(100000).mul((_end - _start))).div(settings.investmentPayInterval);
    }

    function _packInvestment(uint256 isExpired, uint256 isWithdrawn, uint256 level, uint256 amount, uint256 createdAt, uint256 lastWithdrawalTime, uint256 isReinvest) private pure returns(uint256)
    {
        uint256 data = isExpired;
        data = data.add(isWithdrawn.mul(1e1));
        data = data.add(level.mul(1e2));
        data = data.add(amount.mul(1e4));
        data = data.add(createdAt.mul(1e17));
        data = data.add(lastWithdrawalTime.mul(1e27));
        data = data.add(isReinvest.mul(1e37));

        return data;
    }

    function _unpackInvestment(uint256 data) private pure returns(uint256 isExpired, uint256 isWithdrawn, uint256 level, uint256 amount, uint256 createdAt, uint256 lastWithdrawalTime, uint256 isReinvest)
    {
        uint256 _d = data;
        uint256 d7 = _d / 1e37;
        _d = _d.sub(d7.mul(1e37));
        uint256 d6 = _d / 1e27;
        _d = _d.sub(d6.mul(1e27));
        uint256 d5 = _d / 1e17;
        _d = _d.sub(d5.mul(1e17));
        uint256 d4 = _d / 1e4;
        _d = _d.sub(d4.mul(1e4));
        uint256 d3 = _d / 1e2;
        _d = _d.sub(d3.mul(1e2));
        uint256 d2 = _d / 1e1;
        uint256 d1 = _d.sub(d2.mul(1e1));

        isExpired = d1;
        isWithdrawn = d2;
        level = d3;
        amount = d4;
        createdAt = d5;
        lastWithdrawalTime = d6;
        isReinvest = d7;
    }

    function _createInvestment(address _address, uint256 _amount, uint256 _isReinvest) private
    {
        investors[_address].investments.push(Objects.Investment(_packInvestment(0, 0, investorLevelByAddress(_address), _amount, block.timestamp, block.timestamp, _isReinvest)));

        if (investors[_address].referrerAddress != address(0)) {
            uint256 _earningAmount = _amount.mul(levelsSettings[investorLevelByAddress(_address)].referrerPercent).div(1000);
            investors[investors[_address].referrerAddress].withdrawProfit = investors[investors[_address].referrerAddress].withdrawProfit.add(_earningAmount);
        }

        statistic.investedAmount = statistic.investedAmount.add(_amount);

        emit InvestEvent(_address, _amount, investorLevelByAddress(_address));
    }

    function getFeeBalance() public view onlyOwner returns(uint256)
    {
        return feeBalance;
    }

    function sendFees() public onlyOwner
    {
        uint256 feeAmount = feeBalance.div(4);
        feeBalance = 0;

        feeAddress.transfer(feeAmount);
        insuranceAddress.transfer(feeAmount);
        marketingAddress.transfer(feeAmount);
        developmentAddress.transfer(feeAmount);
    }

    function invest(address _referrerAddress) external payable
    {
        // Validate inputs
        require(!isContract(msg.sender), "Invest from contract not allowed");
        require(msg.sender != _referrerAddress, "Self invitation not allowed");
        require(_referrerAddress == owner || investors[_referrerAddress].referrerAddress != address(0), "Invalid referrer");

        if (investors[msg.sender].referrerAddress == address(0)) {
            statistic.investorsCount = statistic.investorsCount.add(1);

            investors[msg.sender].referrerAddress = _referrerAddress;
        }

        require(msg.value >= levelsSettings[investorLevelByAddress(msg.sender)].investAmountMin, "Less than the minimum required invest amount");
        require(msg.value <= levelsSettings[investorLevelByAddress(msg.sender)].investAmountMax, "More than the maximum required invest amount");

        _createInvestment(msg.sender, msg.value, 0);

        feeBalance = feeBalance.add(msg.value.mul(FEE_PERCENT).div(1000).mul(4));
    }

    function reinvest(uint256 _investmentNum) external
    {
        require(investors[msg.sender].investments.length > _investmentNum, "Can not reinvest because no investment not found");

        (, uint256 iIsWithdrawn, uint256 iLevel, uint256 iAmount, uint256 iCreatedAt,, uint256 iIsReinvest) = _unpackInvestment(investors[msg.sender].investments[_investmentNum].data);
        require(iLevel < settings.levelsCount, "Error in reinvest: Investment level is bigger then levelsCount");

        uint256 investmentEndTime = iCreatedAt.add(settings.investmentLifetime);

        require(iIsWithdrawn == 0, "Investment is already withdrawn");
        require(block.timestamp >= investmentEndTime, "ReInvest available after expire");

        uint256 dividendsAmount = _calculateDividends(iAmount, levelsSettings[iLevel].investmentInterest, iCreatedAt, investmentEndTime);
        require(dividendsAmount >= iAmount, "Earned amount must be more or equal then invested");

        uint256 amount2reInvest = iAmount;

        investors[msg.sender].investments[_investmentNum].data = _packInvestment(1, 1, iLevel, iAmount, iCreatedAt, investmentEndTime, iIsReinvest);

        _createInvestment(msg.sender, amount2reInvest, 1);

        investors[msg.sender].withdrawProfit = investors[msg.sender].withdrawProfit.add(dividendsAmount.sub(iAmount));
    }

    function withdraw(uint256 _investmentNum) external
    {
        require(investors[msg.sender].investments.length > _investmentNum, "Can not withdraw because no investment not found");
        (, uint256 iIsWithdrawn, uint256 iLevel, uint256 iAmount, uint256 iCreatedAt,, uint256 iIsReinvest) = _unpackInvestment(investors[msg.sender].investments[_investmentNum].data);
        require(iLevel < settings.levelsCount, "Error in reinvest: Investment level is bigger then levelsCount");

        uint256 investmentEndTime = iCreatedAt.add(settings.investmentLifetime);

        require(iIsWithdrawn == 0, "Investment is already used");
        require(block.timestamp >= investmentEndTime, "Withdraw available after expire");

        uint256 dividendsAmount = _calculateDividends(iAmount, levelsSettings[iLevel].investmentInterest, iCreatedAt, investmentEndTime);
        require(dividendsAmount <= contractBalance(), "Contract balance is exhausted, please try again later");

        investors[msg.sender].investments[_investmentNum].data = _packInvestment(1, 1, iLevel, iAmount, iCreatedAt, investmentEndTime, iIsReinvest);

        statistic.withdrawalsAmount = statistic.withdrawalsAmount.add(dividendsAmount);

        msg.sender.transfer(dividendsAmount);
        emit WithdrawEvent(msg.sender, dividendsAmount);
    }

    function withdrawProfits() external
    {
        require(investors[msg.sender].withdrawProfit > 0, "Nothing to withdraw");

        uint256 withdrawalAmount = investors[msg.sender].withdrawProfit;
        investors[msg.sender].withdrawProfit = 0;

        statistic.withdrawalsAmount = statistic.withdrawalsAmount.add(withdrawalAmount);
        uint256 contractBalance = contractBalance();

        if (withdrawalAmount >= contractBalance){
            withdrawalAmount = contractBalance;
        }

        msg.sender.transfer(withdrawalAmount);

        emit WithdrawEvent(msg.sender, withdrawalAmount);
    }

    function investmentsCreatedAtByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseCreatedAt = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,,,, uint256 createdAt,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseCreatedAt[i] = createdAt;
        }

        return (responseCreatedAt);
    }

    function investmentsAmountByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseAmount = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,,,uint256 amount,,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseAmount[i] = amount;
        }

        return (responseAmount);
    }

    function investmentsInvestorLevelByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseLevels = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,,uint256 level,,,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseLevels[i] = level;
        }

        return (responseLevels);
    }

    function investmentsIsExpiredByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseIsExpired = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,,,,uint256 createdAt,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseIsExpired[i] = block.timestamp >= createdAt.add(settings.investmentLifetime) ? 1 : 0;
        }

        return (responseIsExpired);
    }

    function investmentsIsWithdrawnByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseIsWithdrawn = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,uint256 IsWithdrawn,,,,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseIsWithdrawn[i] = IsWithdrawn;
        }

        return (responseIsWithdrawn);
    }

    function investmentsTotalDividendByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseTotalDividends = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,, uint256 level, uint256 amount, uint256 createdAt,,) = _unpackInvestment(investors[_address].investments[i].data);
            responseTotalDividends[i] = _calculateDividends(amount, levelsSettings[level].investmentInterest, createdAt, createdAt.add(settings.investmentLifetime));
        }

        return (responseTotalDividends);
    }

    function investmentsAvailableDividendsByAddress(address _address) public view returns (uint256[] memory)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256[] memory responseAvailableDividends = new uint256[](investors[_address].investments.length);

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,, uint256 level, uint256 amount, uint256 createdAt, uint256 lastWithdrawalTime,) = _unpackInvestment(investors[_address].investments[i].data);

            if (block.timestamp >= createdAt.add(settings.investmentLifetime)) {
                responseAvailableDividends[i] = _calculateDividends(amount, levelsSettings[level].investmentInterest, lastWithdrawalTime, createdAt.add(settings.investmentLifetime));
            } else {
                responseAvailableDividends[i] = _calculateDividends(amount, levelsSettings[level].investmentInterest, lastWithdrawalTime, block.timestamp);
            }
        }

        return (responseAvailableDividends);
    }

    function investorInfoByAddress(address _address) public view returns (address, uint256)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        return (
            investors[_address].referrerAddress,
            investors[_address].withdrawProfit
        );
    }

    function investorLevelByAddress(address _address) public view returns (uint256 level)
    {
        level = 0;
        for (uint256 i = 0; i < settings.levelsCount; i++) {
            if (investors[_address].withdrawProfit < levelsSettings[i].upgradeBalance) {
                break;
            }
            level = i;
        }
    }

    function investorStatsByAddress(address _address) public view returns (uint256, uint256, uint256, uint256)
    {
        if (msg.sender != owner) {
            require(msg.sender == _address, "Only owner or self is allowed to perform this action");
        }

        uint256 investedAmount = 0;
        uint256 reInvestedAmount = 0;
        uint256 reInvestmentsCount = 0;

        for (uint256 i = 0; i < investors[_address].investments.length; i++) {
            (,,, uint256 iAmount,,, uint256 iIsReinvest) = _unpackInvestment(investors[_address].investments[i].data);

            investedAmount = investedAmount.add(iAmount);

            if (iIsReinvest == 1) {
                reInvestedAmount = reInvestedAmount.add(iAmount);
                reInvestmentsCount = reInvestmentsCount.add(1);
            }
        }

        return (
            investors[_address].investments.length,
            reInvestmentsCount,
            investedAmount,
            reInvestedAmount
        );
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