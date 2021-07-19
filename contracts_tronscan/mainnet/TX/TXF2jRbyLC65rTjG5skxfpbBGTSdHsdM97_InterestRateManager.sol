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

//SourceUnit: IAccountTier.sol

pragma solidity >=0.5.10;

interface IAccountTier {
    function getInvestorInfo(address account) external view
        returns (
            uint256 totalInvested_,
            uint256 activeBalance_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 withdrawableBalance_,
            uint256 activeBalanceAfterWithdrawal_,           
		    address referredBy_,
            uint256 joinedDate_
        );

    function getContractInfo() external view 
        returns (
            uint256 totalInvestors_,
            uint256 totalInvested_,
            uint256 totalWithdrawn_,
            uint256 contractBalance_,
            uint256 insuranceBalance_,
            bool stopPanicWithdrawal_
        );

    function payoutInsurance(address payable insurer, uint256 claimAmount) external;
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

//SourceUnit: InterestRateManager.sol

pragma solidity >=0.5.10;

import './IInterestRateTier.sol';
import './IAccountTier.sol';
import './IInsuranceTier.sol';
import './SafeMath.sol';
import './Authorizable.sol';

contract Constants {
    uint256 constant public PERCENT_DIVIDER = 100000;
	uint256 constant public MIN_INVESTMENT = 100 trx;
	uint256 constant public CONTRACT_BALANCE_STEP = 10000000 trx;
    uint256 constant public CONTRACT_PERCENT = 100;
    uint256 constant public MAX_CONTRACT_BALANCE_RATE = 1000;
	uint256 constant public BASE_PERCENT = 1000;
	uint256 constant public HOLD_PERCENT = 22;
	uint256 constant public MAX_HOLD_PERCENT = 660;
	uint256 constant public MAX_WITHDRAW_PERCENT = 10000;
	uint256 constant public TIME_STEP = 1 days;
	uint256[] public REF_RATE = [100, 50, 25];
    uint8[] public accountTypes = [1, 2, 4, 8];
}

contract InterestRateManager is IInterestRateTier, Authorizable, Constants {
    using SafeMath for uint256;

    uint256 baseRate = 1000;
    uint256 holdRate = 22;
    uint256 maxHoldRate = 660;
    uint256 maxInterestRate = 10000;
    uint256 totalUsers;
    uint256 offerCount;
    uint256 activeOfferOffset;

    struct Offer {
        uint256 rate;
		uint256 startAt;
		uint256 endAt;
		uint256 validTill;
		uint256 minInvestmentAmount;
		uint256 maxInvestmentAmount;
		uint256 activeBalance;
    }

    mapping(uint256 => Offer) offers;
    mapping(uint256 => address) offerAddresses;
    mapping(address => uint256) userOfferCount;
    mapping(address => mapping(uint256 => uint256[])) userOffers;

    IAccountTier accountTier;
    IInsuranceTier insuranceTier;

    constructor() public {
 
    }

    function setAccountTier(IAccountTier accountTier_) external onlyOwnerOrAuthorized {
        accountTier = accountTier_;
    }

    function setInsuranceTier(IInsuranceTier insuranceTier_) external onlyOwnerOrAuthorized {
        insuranceTier = insuranceTier_;
    }

    function getTiers() external view onlyOwnerOrAuthorized returns (address, address) {
        return (
            address(accountTier),
            address(insuranceTier)
        );
    }

    function getSystemInterestRates(
        uint256 contractBalance
    ) external view onlyOwnerOrAuthorized returns (uint256[] memory) 
    {
        uint256 index = 0;
        uint256[] memory interestRates = new uint256[](4);

        interestRates[index++] = PERCENT_DIVIDER;
        interestRates[index++] = baseRate;
        interestRates[index++] = HOLD_PERCENT;
        interestRates[index++] = _getContractBalanceRate(contractBalance);

        return interestRates;
    }

    function getUserInterestRate(
        uint256 contractBalance, 
        uint256 totalActiveInvestments, 
        uint256[] calldata referralAmount
    ) external view onlyOwnerOrAuthorized returns (uint256) {
        return baseRate.add(_calculateReferralRate(totalActiveInvestments, referralAmount)).add(_getContractBalanceRate(contractBalance));
    }

    function calculateReferralRate(uint256 totalActiveInvestments, uint256[] calldata referralAmount) external view 
        onlyOwnerOrAuthorized returns (uint256) 
    {
        return _calculateReferralRate(totalActiveInvestments, referralAmount);
    }

    function getInvestmentInterest(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn,
        uint256 lastPayout
    ) 
        external view onlyOwnerOrAuthorized 
        returns (
            uint256 holdInterestRate_,
            uint256 bonusInterestRate_
        ) 
    {
        holdInterestRate_ = _calculateHoldPercentRate(account, lastPayout);
        bonusInterestRate_ = _calculateBonusInterestRate(
            account,
            investmentIndex,
            actualInvestment,
            activeInvestment,
            withdrawn           
        );
    }

    function calculateNetInterestRate(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn, 
        uint256 userInterestRate,  
        uint256 lastPayout
    ) external view onlyOwnerOrAuthorized returns (uint256) {
        // Add holding rate
        uint256 netInterestRate = userInterestRate.add(_calculateHoldPercentRate(account, lastPayout));
        netInterestRate = netInterestRate.add(_calculateBonusInterestRate(
            account,
            investmentIndex,
            actualInvestment,
            activeInvestment,
            withdrawn           
        ));

        if (netInterestRate > maxInterestRate) {
            netInterestRate = maxInterestRate;
        }

        return netInterestRate;
    }

    function setInvestmentOffer(
        address account,
		uint256 investmentIndex,
		uint256 investedAmount
    ) external onlyOwnerOrAuthorized
    {
        bool hasActiveOffer = false;

        for (uint256 i = activeOfferOffset; i < offerCount; i++) {
            if (offers[i].endAt > block.timestamp) {
                hasActiveOffer = true;
                if (!_checkInvestmentHasOffer(account, investmentIndex, i) && 
                    (investedAmount >= offers[i].minInvestmentAmount) &&
                    (offers[i].maxInvestmentAmount == 0 || investedAmount <= offers[i].maxInvestmentAmount)
                ) {
                    userOffers[account][investmentIndex].push(i);

                    if (userOfferCount[account] == 0) {
                        offerAddresses[totalUsers] = account;
                        totalUsers = totalUsers.add(1);
                    }

                    userOfferCount[account] = userOfferCount[account].add(1);
                }
            } else if (!hasActiveOffer) {
                if (activeOfferOffset < i) {
                    activeOfferOffset = i;
                }
            }
        }
    }

    function getActiveOffers() external view onlyOwnerOrAuthorized 
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
		uint256[] memory id;
        uint256[] memory rate;
		uint256[] memory startAt;
		uint256[] memory endAt;

        for (uint256 i = activeOfferOffset; i < offerCount; i++) {
            if (offers[i].endAt > block.timestamp) {
                id[i] = i;
                rate[i] = offers[i].rate;
                startAt[i] = offers[i].startAt;
                endAt[i] = offers[i].endAt;
            }
        }

        return (
            id,
            rate,
            startAt,
            endAt
        );
    }

    function getOfferCountAndUsers() external view onlyOwnerOrAuthorized 
        returns (uint256 offerCount_, uint256 totalUsers_) 
    {
        offerCount_ = offerCount;
        totalUsers_ = totalUsers;
    }

    function setOfferById(
        uint256 offerId,
        uint256 rate,
		uint256 startAt,
		uint256 endAt,
		uint256 validTill,
		uint256 minInvestmentAmount,
		uint256 maxInvestmentAmount,
        uint256 activeBalance
    ) external onlyOwnerOrAuthorized
    {
        uint256 startAt_ = startAt;
        uint256 endAt_ = endAt;
        uint256 offerId_ = offerId;

        if (startAt_ == 0) {
            startAt_ = block.timestamp;
        }

        if (endAt_ == 0) {
            endAt_ = startAt_.add(TIME_STEP.mul(7));
        }

        require(endAt_ > startAt_, "End date greater than start date");

        Offer storage offer = offers[offerId];

        if (offer.startAt == 0) {
            offerId_ = offerCount;
            offerCount = offerCount.add(1);
        }

        offers[offerId_] = Offer(rate, startAt_, endAt_, validTill, minInvestmentAmount, maxInvestmentAmount, activeBalance);
    }

    function getOfferById(uint256 offerId) external view onlyOwnerOrAuthorized 
        returns (
            uint256 rate_,
            uint256 startAt_,
            uint256 endAt_,
            uint256 validTill_,
            uint256 minInvestmentAmount_,
            uint256 maxInvestmentAmount_,
            uint256 activeBalance_
        ) 
    {
        Offer storage offer = offers[offerId];
        rate_ = offer.rate;
        startAt_ = offer.startAt;
        endAt_ = offer.endAt;
        validTill_ = offer.validTill;
        minInvestmentAmount_ = offer.minInvestmentAmount;
        maxInvestmentAmount_ = offer.maxInvestmentAmount;
        activeBalance_ = offer.activeBalance;
    }

    function getUserOffer(address account, uint256 investmentIndex) external view onlyOwnerOrAuthorized 
        returns (
            uint256[] memory
        ) 
    {
        return userOffers[account][investmentIndex];
    }

    function _calculateReferralRate(uint256 totalActiveInvestments, uint256[] memory referralAmount) private view 
        returns (uint256) 
    {
        uint256 referralRate = 0;

        for (uint256 i = 0; i < REF_RATE.length; i++) {
            referralRate = referralRate.add(referralAmount[i].div(totalActiveInvestments).mul(REF_RATE[i]));
        }

        return referralRate;
    }

    function _calculateBonusInterestRate(
        address account,
        uint256 investmentIndex, 
        uint256 actualInvestment, 
        uint256 activeInvestment, 
        uint256 withdrawn
    ) internal view returns (uint256) {
        uint256 bonusInterestRate = 0;

        // Add bonus rate until 100% withdrawal
        if (actualInvestment > withdrawn) {
            uint256[] memory offerIds = userOffers[account][investmentIndex];
            for (uint256 i = 0; i < offerIds.length; i++) {         
                if (
                    (
                        offers[offerIds[i]].validTill == 0 ||
                        offers[offerIds[i]].validTill >= block.timestamp
                    )
                    &&
                    (
                        offers[offerIds[i]].activeBalance == 0 || 
                        activeInvestment >= offers[offerIds[i]].activeBalance
                    )
                ) {
                    bonusInterestRate = bonusInterestRate.add(offers[offerIds[i]].rate);
                }
            }
        }

        return bonusInterestRate;
    }

    function _checkInvestmentHasOffer(address account, uint256 investmentIndex, uint256 offerId) private view returns (bool) {
        bool hasOffer = false;
        uint256[] memory offerIds = userOffers[account][investmentIndex];

        for (uint256 i = 0; i < offerIds.length; i++) {
            if (offerIds[i] == offerId) {
                hasOffer = true;
                break;
            }
        }

        return hasOffer;
    }

    function _getContractBalanceRate(uint256 contractBalance) private pure returns (uint256) {
        uint256 rate = 0;

        if (contractBalance >= CONTRACT_BALANCE_STEP) {
            rate = contractBalance.div(CONTRACT_BALANCE_STEP).mul(CONTRACT_PERCENT);

            if (rate > MAX_CONTRACT_BALANCE_RATE) {
                rate = MAX_CONTRACT_BALANCE_RATE;
            }
        }

        return rate;
    }

    function _calculateHoldPercentRate(address account, uint256 checkpoint) private view returns (uint) {
        (uint256 totalPayout_, uint256 lastPayout_) = insuranceTier.calculateInsurancePaid(account, checkpoint);
        uint256 holdPercentage = (block.timestamp.sub(lastPayout_)).div(TIME_STEP).mul(holdRate);

        if (holdPercentage > maxHoldRate) {
            holdPercentage = maxHoldRate;
        }

        return holdPercentage;
    }

    function _calculateFee(uint256 amount, uint256 percentage) private pure returns (uint256) {
        return (amount.mul(percentage)).div(PERCENT_DIVIDER);
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