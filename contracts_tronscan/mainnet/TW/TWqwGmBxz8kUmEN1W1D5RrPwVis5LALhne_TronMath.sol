//SourceUnit: Authorizable.sol

pragma solidity >=0.5.10;

import './Ownable.sol';

contract Authorizable is Ownable {
    mapping(address => bool) private authorizedAccounts;

    // Internal empty constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    modifier onlyOwnerOrAuthorized() {
        _isOwnerOrAuthorized();
        _;
    }

    function _isOwnerOrAuthorized() private view {
        require(authorizedAccounts[msg.sender] || msg.sender == _getOwner(), "unauthorized");
    }

    function setAuthorizedAccount(address account, bool isAuthorized) external onlyOwnerOrAuthorized {
        authorizedAccounts[account] = isAuthorized;
    }

    function isAuthorizedAccount(address account) external view onlyOwnerOrAuthorized returns (bool) {
        return authorizedAccounts[account];
    }
}

//SourceUnit: IInsuranceTier.sol

pragma solidity >=0.5.10;

interface IInsuranceTier {
    function transferToInsurance(uint256 amount) external;
    function calculateActiveInvestment(uint256 amount) external view returns (uint256);
    function calculateInvestmentFee(uint256 amount) external view returns (uint256);
    function calculatePayoutFee(uint256 amount) external view returns (uint256);
    function getInsuranceBalance() external view returns (uint256);
    function claim(address payable account) external;
    function calculateClaim(address account) external view
        returns (
            uint256 netClaimedAmount_,
            uint256 netClaimableAmount_,
            uint256 nextClaimableAmount_, 
            uint256 nextClaimableDate_
        );

    function getClaimInsuranceFlags() external view 
        returns (bool claimInsurance_, bool claimFullInsurance_);

    function calculateInsurancePaid(address account, uint256 lastPayout)
        external view returns (uint256, uint256);
}

//SourceUnit: IInterestRateTier.sol

pragma solidity >=0.5.10;

interface IInterestRateTier {
    function getUserInterestRate(
        uint256 contractBalance, 
        uint256 totalActiveInvestments, 
        uint256[] calldata referralAmount
    ) external view returns (uint256);

    function calculateNetInterestRate(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn, 
        uint256 userInterestRate,  
        uint256 lastPayout
    ) external view returns (uint256);

    function calculateReferralRate(uint256 totalActiveInvestments, uint256[] calldata referralAmount) external view 
        returns (uint256);

    function setInvestmentOffer(
        address account,
		uint256 investmentIndex,
		uint256 investedAmount
    ) external;

    function getSystemInterestRates(
        uint256 contractBalance
    ) external view returns (uint256[] memory);

    function getActiveOffers() external view 
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getInvestmentInterest(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn,
        uint256 lastPayout
    ) 
        external view 
        returns (
            uint256 holdInterestRate_,
            uint256 bonusInterestRate_
        );
}

//SourceUnit: IProtectionTier.sol

pragma solidity >=0.5.10;

interface IProtectionTier {
    function checkWithdrawalMode(address payable account) external view returns (uint256);
    function checkInvestmentMode(address account, address referrer, uint256 amount) 
        external view returns (uint256);
    function checkPanicWithdrawalHold() external view returns (bool);
}

//SourceUnit: IStructs.sol

pragma solidity >=0.5.10;

interface IStructs {
    struct Invested {
        uint256 actual;
        uint256 calculated;
        uint256 active;
    }

    struct Investment {
        uint256 timestamp;
        Invested invested;
        uint256 lastPayout;
        uint256 withdrawn;
    }

    struct Investor {
		uint256 checkin;
        uint256 investmentCount;
        uint256 referralCount;
		address referredBy;
        mapping(uint256 => uint256) referralAmount;
        mapping(uint256 => address) referrals;
        mapping(uint256 => Investment) investments;
    }
}

//SourceUnit: Ownable.sol

pragma solidity >=0.5.10;

contract Ownable {
    address payable private owner;

    // Internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized");
        _;
    }

    function getOwner() external view onlyOwner returns (address) {
        return _getOwner();
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function _getOwner() internal view returns (address) {
        return owner;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity >=0.5.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

//SourceUnit: TronMath.sol



pragma solidity >=0.5.10;

import './IInsuranceTier.sol';
import './IInterestRateTier.sol';
import './IProtectionTier.sol';
import './IStructs.sol';
import './SafeMath.sol';
import './Authorizable.sol';

library SafeAddress {
    function safeTransfer(address payable account, uint256 amount) internal {
        require(address(this).balance >= amount, "Contract: insufficient balance");
        account.transfer(amount);
    }
}

contract Constants {
    uint256 constant public PERCENT_DIVIDER = 100000;
	uint256 constant public MIN_INVESTMENT = 100 trx;
	uint256 constant public CONTRACT_BALANCE_STEP = 10000000 trx;
	uint256 constant public MAX_INVESTMENT_COUNT = 100;
    uint256 constant public CONTRACT_PERCENT = 100;
    uint256 constant public MAX_CONTRACT_BALANCE_RATE = 1000;
	uint256 constant public BASE_PERCENT = 1000;
	uint256 constant public HOLD_PERCENT = 22;
	uint256 constant public MAX_HOLD_PERCENT = 660;
	uint256 constant public MAX_WITHDRAW_PERCENT = 10000;
	uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PAYOUT_INVESTMENT_RATE = 40000;
    uint256 constant public PAYOUT_INSURANCE_RATE = 5000;
	uint256[] public REF_RATE = [100, 50, 25];
    uint8[] public accountTypes = [1, 2, 4, 8];
}

contract TronMath is Authorizable, IStructs, Constants {
    using SafeMath for uint256;
    using SafeAddress for address payable;

    uint256 totalInvestors;
    uint256 totalInvested;
    uint256 totalWithdrawn;

    uint256 public contractBalance;

    mapping(address => Investor) investors;
    mapping(uint256 => address) investorAddresses;

    address payable markettingAccount;
    address payable adminAccount;
    address payable devAccount;

    uint256 markettingFee = 3000;   // 3%
    uint256 adminFee = 1000;        // 1%
    uint256 devFee = 1000;          // 1%

    IInsuranceTier insuranceTier;
    IInterestRateTier interestRateTier;
    IProtectionTier protectionTier;

    event NewInvestment(address indexed investor, uint256 amount, uint256 timestamp);
    event NewInvestor(address indexed investor, address indexed referrer, uint256 timestamp);
    event Withdraw(address indexed investor, uint256 amount, uint256 timestamp);

    constructor(uint256[] memory percentage) public {
        markettingAccount = msg.sender;
        adminAccount = msg.sender;
        devAccount = msg.sender;

        markettingFee = percentage[0];
        adminFee = percentage[1];
        devFee = percentage[2];
    }

    function() external payable {
        _donateToInsurance(msg.value);
    }

    function donate() public payable {
        _donateToInsurance(msg.value);
    }

    function invest(address _referrer) public payable {
        _invest(msg.sender, _referrer, msg.value);
    }

    function withdraw() public {
		_withdraw(msg.sender);
    }

    function claim() public {
		insuranceTier.claim(msg.sender);
    }

    function calculateClaim() public view
        returns (
            uint256 netClaimedAmount_,
            uint256 netClaimableAmount_,
            uint256 nextClaimableAmount_, 
            uint256 nextClaimableDate_
        ) 
    {
        return insuranceTier.calculateClaim(msg.sender);
    }

    function setSystemAccount(address payable newAccount, uint256 accountType) external onlyOwnerOrAuthorized {
        uint256 index = 0;

        if (accountType | accountTypes[index++] == accountType) {
            markettingAccount = newAccount;
        } 
        
        if (accountType | accountTypes[index++] == accountType) {
            adminAccount = newAccount;
        } 
        
        if (accountType | accountTypes[index++] == accountType) {
            devAccount = newAccount;
        } 
    }

    function setSystemFee(uint256 percentage, uint256 accountType) external onlyOwnerOrAuthorized {
        uint256 index = 0;

        if (accountType | accountTypes[index++] == accountType) {
            markettingFee = percentage;
        } 
        
        if (accountType | accountTypes[index++] == accountType) {
            adminFee = percentage;
        } 
        
        if (accountType | accountTypes[index++] == accountType) {
            devFee = percentage;
        } 
    }

    function setInsuranceTier(IInsuranceTier insuranceTier_) external onlyOwnerOrAuthorized {
        insuranceTier = insuranceTier_;
    }

    function setInterestRateTier(IInterestRateTier interestRateTier_) external onlyOwnerOrAuthorized {
        interestRateTier = interestRateTier_;
    }

    function setProtectionTier(IProtectionTier protectionTier_) external onlyOwnerOrAuthorized {
        protectionTier = protectionTier_;
    }

    function getTiers() external view onlyOwnerOrAuthorized returns (address, address, address) {
        return (
            address(insuranceTier),
            address(interestRateTier),
            address(protectionTier)
        );
    }

    function payoutInsurance(address payable insurer, uint256 claimAmount) external onlyOwnerOrAuthorized {
        (bool claimInsurance_, bool claimFullInsurance_) = insuranceTier.getClaimInsuranceFlags();
        require(claimInsurance_, "insurance claim not enabled");

        uint256 insuranceBalance_ = insuranceTier.getInsuranceBalance();
        require(insuranceBalance_ >= claimAmount, "not enough insurance balance");

        Investor storage investor = investors[insurer];
        require(investor.investmentCount > 0, "No investments");

        uint256 withdrawn = claimAmount;

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];

            if (investment.invested.active > 0) {
                if (investment.invested.active >= withdrawn) {
                    investment.invested.active = investment.invested.active.sub(withdrawn);
                    withdrawn = 0;
                } else {
                    withdrawn = withdrawn.sub(investment.invested.active);
                    investment.invested.active = 0;
                }
            }

            if (withdrawn == 0) {
                break;
            }
        }

        insurer.safeTransfer(claimAmount);
    }

    function getInvestorAddress(uint256 index) external view onlyOwnerOrAuthorized returns (address) {
        return investorAddresses[index];
    }

    function getContractInfo() external view 
        returns (
            uint256 totalInvestors_,
            uint256 totalInvested_,
            uint256 totalWithdrawn_,
            uint256 contractBalance_,
            uint256 insuranceBalance_,
            bool stopPanicWithdrawal_
        ) 
    {
        totalInvestors_ = totalInvestors;
        totalInvested_ = totalInvested;
        totalWithdrawn_ = totalWithdrawn;
        contractBalance_ = contractBalance;
        insuranceBalance_ = insuranceTier.getInsuranceBalance();
        stopPanicWithdrawal_ = protectionTier.checkPanicWithdrawalHold();
    }

    function getSystemInterestRates() external view returns (uint256[] memory)
    {
        return interestRateTier.getSystemInterestRates(contractBalance);
    }

    function getActiveOffers() external view 
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return interestRateTier.getActiveOffers();
    }

    function getInvestorInfo() external view
        returns (
            uint256 totalInvested_,
            uint256 activeBalance_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 withdrawableBalance_,
            uint256 activeBalanceAfterWithdrawal_,           
		    address referredBy_,
            uint256 joinedDate_
        )
    {
        return _getInvestorInfo(msg.sender);
    }

    function getInvestorInfo(address account) external view onlyOwnerOrAuthorized
        returns (
            uint256 totalInvested_,
            uint256 activeBalance_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 withdrawableBalance_,
            uint256 activeBalanceAfterWithdrawal_,           
		    address referredBy_,
            uint256 joinedDate_
        )
    {
        return _getInvestorInfo(account);
    }

    function _getInvestorInfo(address account) internal view
        returns (
            uint256 totalInvested_,
            uint256 activeBalance_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 withdrawableBalance_,
            uint256 activeBalanceAfterWithdrawal_,           
		    address referredBy_,
            uint256 joinedDate_
        )
    {
        referredBy_ = investors[account].referredBy;
        joinedDate_ = investors[account].checkin;
        totalInvested_ = _sumActualInvestment(account, false);
        activeBalance_ = _sumActiveInvestment(account);

        (uint256 netWithdrawn, uint256 lastWithdrawn) = _sumWithdrawnAmount(account);
        totalWithdrawn_ = netWithdrawn;
        lastWithdrawn_ = lastWithdrawn;

        (uint256 withdrawableBalance, uint256 activeBalanceAfterWithdrawal, uint256 ignored) = _calculatePayout(account);
        withdrawableBalance_ = withdrawableBalance;
        activeBalanceAfterWithdrawal_ = activeBalanceAfterWithdrawal;
    }

    function getReferralAmount() external view returns (uint256[] memory) {
        return _getReferralAmount(msg.sender);
    }

    function getReferralAmount(address account) external view onlyOwnerOrAuthorized returns (uint256[] memory) {
        return _getReferralAmount(account);
    }

    function getInvestment() external view 
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        return _getInvestment(msg.sender);
    }

    function donateFromContractToInsurance(uint256 percentage) external onlyOwnerOrAuthorized {
        _donateFromContractToInsurance(_calculateFee(contractBalance, percentage));
    }

    function getInvestment(address account) external view onlyOwnerOrAuthorized
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        return _getInvestment(account);
    }

    function _getInvestment(address account) internal view 
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        Investor storage investor = investors[account];
        require(investor.investmentCount > 0, "no investor found");

        uint256[] memory timestamp = new uint256[](investor.investmentCount);
        uint256[] memory lastPayout = new uint256[](investor.investmentCount);
        uint256[] memory withdrawn = new uint256[](investor.investmentCount);
        uint256[] memory actualInvested = new uint256[](investor.investmentCount);
        uint256[] memory calculatedInvested = new uint256[](investor.investmentCount);
        uint256[] memory activeInvested = new uint256[](investor.investmentCount);

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];

            timestamp[i] = investment.timestamp;
            
            if (investment.timestamp == investment.lastPayout) {
                lastPayout[i] = 0;
            } else {
                lastPayout[i] = investment.lastPayout;
            }

            withdrawn[i] = investment.withdrawn;
            actualInvested[i] = investment.invested.actual;
            calculatedInvested[i] = investment.invested.calculated;
            activeInvested[i] = investment.invested.active;
        }

        return (
            timestamp,
            lastPayout,
            withdrawn,
            actualInvested,
            calculatedInvested,
            activeInvested
        );
    }

    function getInvestmentInterest() external view 
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        return _getInvestmentInterest(msg.sender);
    }

    function getInvestmentInterest(address account) external view onlyOwnerOrAuthorized
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        return _getInvestmentInterest(account);
    }

    function _getInvestmentInterest(address account) internal view 
        returns (
            uint256,
            uint256[] memory,
            uint256[] memory
        ) 
    {
        Investor storage investor = investors[account];
        require(investor.investmentCount > 0, "no investor found");

        uint256[] memory holdInterestRate = new uint256[](investor.investmentCount);
        uint256[] memory bonusInterestRate = new uint256[](investor.investmentCount);

        uint256 referralInterest = interestRateTier.calculateReferralRate(_sumActualInvestment(account, true), _getReferralAmount(account));

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];

            (uint256 holdInterestRate_, uint256 bonusInterestRate_) = 
                interestRateTier.getInvestmentInterest(
                    account,
                    i,
                    investment.invested.actual, 
                    investment.invested.active, 
                    investment.withdrawn, 
                    investment.lastPayout
                );

            holdInterestRate[i] = holdInterestRate_;
            bonusInterestRate[i] = bonusInterestRate_;
        }

        return (
            referralInterest,
            holdInterestRate,
            bonusInterestRate
        );
    }

    function _calculatePayout(address account) internal view returns (uint256, uint256, uint256) {
        Investor storage investor = investors[account];

        if (investor.investmentCount == 0) {
            return (
                0, 0, 0
            );
        }

        uint256 userInterestRate = _getUserInterestRate(account);
        uint256 netPayout;
        uint256 netInsuranceFromPayout;
        uint256 activeInvestmentAfterWithdrawal;

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];
            uint256 maxPayout = _getMaxPayout(investment.invested.actual);

            if (uint(investment.withdrawn) < maxPayout) {
                (
                    uint256 actualPayout,
                    uint256 insurancePayout,
                    uint256 activePayoutDeduction
                ) = _calculatePayoutSplits(account, i, userInterestRate);

                netPayout = netPayout.add(actualPayout);
                netInsuranceFromPayout = netInsuranceFromPayout.add(insurancePayout);
                activeInvestmentAfterWithdrawal = activeInvestmentAfterWithdrawal.add(investment.invested.active.sub(activePayoutDeduction));
            }
        }

        return (
            netPayout,
            activeInvestmentAfterWithdrawal,
            netInsuranceFromPayout
        );
    }

    function _invest(address account, address referrer, uint256 amount) internal {
        require(!_isContract(account), "not allowed");
        require(amount >= MIN_INVESTMENT, "Amount less than minimum investment");

        uint256 investmentMode = protectionTier.checkInvestmentMode(account, referrer, amount);

        if (investmentMode == 2) {
            Investor storage investor = investors[account];
            require(investor.investmentCount + 1 <= MAX_INVESTMENT_COUNT, "Maximum investment reached"); 

            totalInvested = totalInvested.add(amount);
            contractBalance = contractBalance.add(amount);         

            if (investor.investmentCount == 0) {
                investor.checkin = block.timestamp;

                investorAddresses[totalInvestors] = account;
                totalInvestors = totalInvestors.add(1);

                if (referrer == address(0) || referrer == account || investors[referrer].investmentCount == 0) {
                    referrer = _getOwner();
                }

                investor.referredBy = referrer;

                Investor storage referredBy = investors[referrer];
                referredBy.referrals[referredBy.referralCount] = account;
                referredBy.referralCount = referredBy.referralCount.add(1);
                emit NewInvestor(account, referrer, block.timestamp);
            }

            _setupReferralPayout(account, amount);
            uint256 calculated = insuranceTier.calculateActiveInvestment(amount);

            uint256 investmentCount = investor.investmentCount;
            investor.investments[investmentCount].timestamp = block.timestamp;
            investor.investments[investmentCount].lastPayout = block.timestamp;
            investor.investments[investmentCount].invested = Invested(amount, calculated, calculated);

            investor.investmentCount = investor.investmentCount.add(1);
            interestRateTier.setInvestmentOffer(account, investmentCount, amount);

            _splitPlatformInvestment(amount);
            emit NewInvestment(account, amount, block.timestamp);
        }
    }

    function _calculateInsuranceLastPayout(address account, uint256 lastPayout) internal view returns (uint256) {
        (uint256 totalPayout_, uint256 lastPayout_) = insuranceTier.calculateInsurancePaid(account, lastPayout);
        return lastPayout_;
    }

    function _calculatePayoutSplits(address account, uint256 index, uint256 userInterestRate) internal view 
        returns (uint256, uint256, uint256) 
    {
        Investment storage investment = investors[account].investments[index];
        uint256 lastPayout_ = _calculateInsuranceLastPayout(account, investment.lastPayout);
        uint256 expectedPayout = _calculateFee(uint(investment.invested.active)
            .mul(block.timestamp.sub(lastPayout_))
            .div(TIME_STEP), _calculateNetInterestRate(
            account,
            index,
            investment.invested.actual, 
            investment.invested.active, 
            investment.withdrawn, 
            userInterestRate, 
            lastPayout_
        ));

        if (expectedPayout > investment.invested.active) {
            expectedPayout = investment.invested.active;
        }

        uint256 insurancePayout = insuranceTier.calculatePayoutFee(expectedPayout);
        uint256 actualPayout = expectedPayout.sub(insurancePayout);
        uint256 maxPayout = _getMaxPayout(investment.invested.actual);
        uint256 activePayoutDeduction = _calculateFee(expectedPayout, PAYOUT_INVESTMENT_RATE);

        if (investment.withdrawn.add(actualPayout) > maxPayout) {
            actualPayout = investment.withdrawn.add(actualPayout).sub(maxPayout);
            activePayoutDeduction = investment.invested.active;
        }

        return (
            actualPayout,
            insurancePayout,
            activePayoutDeduction
        );
    }

    function _withdraw(address payable account) internal {
        uint256 withdrawalMode = protectionTier.checkWithdrawalMode(account);

        require(withdrawalMode > 0, "Withdrawal on hold for everyone");
        require(withdrawalMode > 1, "Withdrawal suspended for you");

        if (withdrawalMode == 2) {
            Investor storage investor = investors[account];
            require(investor.investmentCount > 0, "No investments");

            uint256 userInterestRate = _getUserInterestRate(account);
            uint256 netPayout;
            uint256 netInsuranceFromPayout;

            for (uint256 i = 0; i < investor.investmentCount; i++) {
                Investment storage investment = investor.investments[i];

                if (uint(investment.withdrawn) < _getMaxPayout(investment.invested.actual)) {
                    (
                        uint256 actualPayout,
                        uint256 insurancePayout,
                        uint256 activePayoutDeduction
                    ) = _calculatePayoutSplits(account, i, userInterestRate);

                    investment.lastPayout = block.timestamp;
                    investment.invested.active = investment.invested.active.sub(activePayoutDeduction);

                    if (investment.invested.active == 0) {
                        _deductReferralPayout(account, investment.invested.actual);
                    }

                    investment.withdrawn = investment.withdrawn.add(actualPayout);

                    netPayout = netPayout.add(actualPayout);
                    netInsuranceFromPayout = netInsuranceFromPayout.add(insurancePayout);
                }
            }

            totalWithdrawn = totalWithdrawn.add(netPayout);

            _donateFromContractToInsurance(netInsuranceFromPayout);
            _payPlatformFeeFromContract(netPayout);
            _safeTransferFromContract(account, netPayout);

            emit Withdraw(account, netPayout, now);
        }
    }

    function _getMaxPayout(uint256 amount) internal pure returns (uint) {
        return amount.mul(3);
    }

    function _setupReferralPayout(address account, uint256 amount) internal {
        address referredBy = investors[account].referredBy;

        for (uint8 i = 0; i < REF_RATE.length; i++) {
            if (referredBy == address(0)) break;

            investors[referredBy].referralAmount[i] = investors[referredBy].referralAmount[i].add(amount);

            referredBy = investors[referredBy].referredBy;
        }
    }

    function _getReferralAmount(address account) internal view returns (uint256[] memory) {
        Investor storage investor = investors[account];
        uint256[] memory referralAmount = new uint256[](REF_RATE.length);

        for (uint256 i = 0; i < REF_RATE.length; i++) {
            referralAmount[i] = investor.referralAmount[i];
        }

        return referralAmount;
    }

    function _sumActualInvestment(address account, bool isActual) internal view returns (uint256) {
        Investor storage investor = investors[account];
        uint256 totalInvestments = 0;

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];
            uint256 maxPayout = _getMaxPayout(investment.invested.actual);

            if (!isActual || uint(investment.withdrawn) < maxPayout) {
                totalInvestments = totalInvestments.add(investment.invested.actual);
            }
        }

        return totalInvestments;
    }

    function _sumActiveInvestment(address account) internal view returns (uint256) {
        Investor storage investor = investors[account];
        uint256 totalInvestments = 0;

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];
            uint256 maxPayout = _getMaxPayout(investment.invested.actual);

            if (uint(investment.withdrawn) < maxPayout) {
                totalInvestments = totalInvestments.add(investment.invested.active);
            }
        }

        return totalInvestments;
    }

    function _sumWithdrawnAmount(address account) internal view returns (uint256, uint256) {
        Investor storage investor = investors[account];
        uint256 netWithdrawn;
        uint256 lastWithdrawn;

        for (uint256 i = 0; i < investor.investmentCount; i++) {
            Investment storage investment = investor.investments[i];
            netWithdrawn = netWithdrawn.add(investment.withdrawn);

            if (investment.lastPayout > lastWithdrawn) {
                lastWithdrawn = investment.lastPayout;
            }
        }

        return (
            netWithdrawn,
            lastWithdrawn
        );
    }

    function _deductReferralPayout(address account, uint256 amount) internal {
        address referredBy = investors[account].referredBy;

        for (uint8 i = 0; i < REF_RATE.length; i++) {
            if (referredBy == address(0)) break;

            investors[referredBy].referralAmount[i] = investors[referredBy].referralAmount[i].sub(amount);

            referredBy = investors[referredBy].referredBy;
        }
    }

    function _donateFromContractToInsurance(uint256 amount) internal {
        _transferFromContract(amount);
        _donateToInsurance(amount);
    }

    function _calculateFee(uint256 amount, uint256 percent) internal pure returns (uint256) {
        return (amount.mul(percent)).div(PERCENT_DIVIDER);
    }

    function _transferFromContract(uint256 amount) internal {
        require(contractBalance >= amount, "insufficient withdrawal balance");
        contractBalance = contractBalance.sub(amount);
    }

    function _donateToInsurance(uint256 amount) internal {
        insuranceTier.transferToInsurance(amount);
    }

    function _splitPlatformInvestment(uint256 _amount) internal {
        _payPlatformFeeFromContract(_amount);
        _transferToInsuranceFromContract(_amount);
    }

    function _transferToInsuranceFromContract(uint256 amount) internal {
        uint256 fee = insuranceTier.calculateInvestmentFee(amount);
        _donateFromContractToInsurance(fee);
    }

    function _payPlatformFeeFromContract(uint256 amount) internal {
        _transferFee(markettingAccount, amount, markettingFee);
        _transferFee(adminAccount, amount, adminFee);
        _transferFee(devAccount, amount, devFee);
    }

    function _transferFee(address payable recipient, uint256 amount, uint256 percent) internal {
        uint256 fee = _calculateFee(amount, percent);
        _safeTransferFromContract(recipient, fee);
    }

    function _safeTransferFromContract(address payable recipient, uint256 amount) internal {
        _transferFromContract(amount);
        recipient.safeTransfer(amount);
    }

    function _getUserInterestRate(address account) internal view returns (uint256) {
        uint256 totalActiveInvestments = _sumActualInvestment(account, true);
        return interestRateTier.getUserInterestRate(contractBalance, totalActiveInvestments, _getReferralAmount(account));
    }

    function _calculateNetInterestRate(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn, 
        uint256 userInterestRate,  
        uint256 lastPayout
    ) internal view returns (uint256) {
        return interestRateTier.calculateNetInterestRate(
            account, 
            investmentIndex, 
            actualInvestment, 
            activeInvestment,
            withdrawn,
            userInterestRate,
            lastPayout
        );
    }

    function _isContract(address _address) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_address) }
        return size > 0;
    }
}