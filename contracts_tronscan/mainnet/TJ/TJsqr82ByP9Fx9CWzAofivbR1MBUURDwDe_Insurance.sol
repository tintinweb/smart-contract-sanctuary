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

//SourceUnit: Insurance.sol

pragma solidity >=0.5.10;

import './IInsuranceTier.sol';
import './IAccountTier.sol';
import './SafeMath.sol';
import './Authorizable.sol';

contract Constants {
    uint256 constant public PERCENT_DIVIDER = 100000;
	uint256 constant public MIN_INVESTMENT = 100 trx;
	uint256 constant public MIN_CONTRACT_BALANCE = 1000 trx;
	uint256 constant public CONTRACT_BALANCE_STEP = 10000000 trx;
    uint256 constant public CONTRACT_PERCENT = 100;
    uint256 constant public MAX_CONTRACT_BALANCE_RATE = 1000;
	uint256 constant public BASE_PERCENT = 1000;
	uint256 constant public CLAIM_PERCENT = 50000;
	uint256 constant public HOLD_PERCENT = 22;
	uint256 constant public MAX_HOLD_PERCENT = 660;
	uint256 constant public MAX_WITHDRAW_PERCENT = 10000;
	uint256 constant public TIME_STEP = 1 days;
    uint256 constant public PAYOUT_INVESTMENT_RATE = 40000;
    uint256 constant public PAYOUT_INSURANCE_RATE = 5000;
	uint256[] public REF_RATE = [100, 50, 25];
    uint8[] public accountTypes = [1, 2, 4, 8];
}

contract Insurance is IInsuranceTier, Authorizable, Constants {
    using SafeMath for uint256;

    uint256 insuranceBalance;
    uint256 insuranceFee;
    uint256 payoutInsuranceFee;

    uint256 totalPaid;
    uint256 totalMembers;

    bool claimInsurance;
    bool claimFullInsurance;

    struct PayoutData {
        uint256 amount;
		uint256 paidAt;
    }

    struct Payout {
        address investor;
		uint256 payoutCount;
        mapping(uint256 => PayoutData) payouts;
    }

    mapping(uint256 => address) payoutAddresses;
    mapping(address => Payout) payouts;

    IAccountTier accountTier;

    constructor(uint256 insuranceFee_, uint256 payoutInsuranceFee_) public {
        insuranceFee = insuranceFee_;
        payoutInsuranceFee = payoutInsuranceFee_;
    }

    function setAccountTier(IAccountTier accountTier_) external onlyOwnerOrAuthorized {
        accountTier = accountTier_;
    }

    function getTiers() external view onlyOwnerOrAuthorized returns (address) {
        return (
            address(accountTier)
        );
    }

    function claim(address payable account) external onlyOwnerOrAuthorized {
        require(claimInsurance, "insurance claim not enabled");
        require(insuranceBalance > 0, "zero insurance balance");

        (
            uint256 netClaimedAmount_,
            uint256 netClaimableAmount_,
            uint256 nextClaimableAmount_, 
            uint256 nextClaimableDate_
        ) = _calculateClaim(account);

        require(block.timestamp >= nextClaimableDate_, "claim unavailable");
        require(claimFullInsurance || insuranceBalance >= nextClaimableAmount_, "not enough insurance balance");

        if (nextClaimableAmount_ > insuranceBalance) {
            nextClaimableAmount_ = insuranceBalance;
        }

        transferFromInsurance(nextClaimableAmount_);
        totalPaid = totalPaid.add(nextClaimableAmount_);

        Payout storage payout = payouts[account];

        if (payout.payoutCount == 0) {
            payoutAddresses[totalMembers] = account;
            totalMembers = totalMembers.add(1);
        }

        payout.payouts[payout.payoutCount] = PayoutData(nextClaimableAmount_, block.timestamp);
        payout.payoutCount = payout.payoutCount.add(1);

        accountTier.payoutInsurance(account, nextClaimableAmount_);
    }

    function calculateClaim(address account) external view onlyOwnerOrAuthorized
        returns (
            uint256 netClaimedAmount_,
            uint256 netClaimableAmount_,
            uint256 nextClaimableAmount_, 
            uint256 nextClaimableDate_
        ) 
    {
        return _calculateClaim(account);
    }

    function calculateInsurancePaid(address account, uint256 lastPayout)
        external view onlyOwnerOrAuthorized returns (uint256, uint256)
    {
        return _calculateInsurancePaid(account, lastPayout);
    }

    function _calculateClaim(address account) internal view
        returns (
            uint256 netClaimedAmount_,
            uint256 netClaimableAmount_,
            uint256 nextClaimableAmount_, 
            uint256 nextClaimableDate_
        ) 
    {
        uint256 contractBalance = _getContractBalance();

        (uint256 totalInvested_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 joinedDate_) = _getInvestorInfo(account);

        netClaimableAmount_ = totalInvested_.sub(totalWithdrawn_);
        uint256 lastPayout = lastWithdrawn_;

        if (netClaimableAmount_ > 0) {
            (uint256 totalPayout_, uint256 lastPayout_) = _calculateInsurancePaid(account, lastPayout);

            if (netClaimableAmount_ > totalPayout_) {
                netClaimableAmount_ = netClaimableAmount_.sub(totalPayout_);
            } else {
                netClaimableAmount_ = 0;
            }
            
            netClaimedAmount_ = totalPayout_;
            lastPayout = lastPayout_;
        }
        
        if (netClaimableAmount_ > 0) {
            nextClaimableAmount_ = _calculateFee(totalInvested_, CLAIM_PERCENT);

            if (netClaimableAmount_ < nextClaimableAmount_) {
                nextClaimableAmount_ = netClaimableAmount_;
            }

            uint256 nextClaimableDate = joinedDate_.add(TIME_STEP.mul(30));
            
            if (claimInsurance) {
                if (contractBalance < MIN_CONTRACT_BALANCE) {
                    nextClaimableDate_ = lastPayout.add(TIME_STEP);
                } else {
                    if (lastPayout.add(TIME_STEP.mul(15)) > nextClaimableDate) {
                        nextClaimableDate_ = lastPayout.add(TIME_STEP.mul(15));
                    } else {
                        nextClaimableDate_ = nextClaimableDate;
                    }
                }
            } else {
                nextClaimableDate_ = nextClaimableDate;
            }
        }
    }

    function _calculateInsurancePaid(address account, uint256 lastPayout)
        internal view returns (uint256, uint256)
    {
        uint256 totalPayout;
        Payout storage payout = payouts[account];

        if (payout.payoutCount > 0) {
            for(uint256 i = 0; i < payout.payoutCount; i++) {
                totalPayout = totalPayout.add(payout.payouts[i].amount);

                if (payout.payouts[i].paidAt > lastPayout) {
                    lastPayout = payout.payouts[i].paidAt;
                }
            }
        }

        return (
            totalPayout,
            lastPayout
        );
    }

    function transferToInsurance(uint256 amount) external onlyOwnerOrAuthorized {
        insuranceBalance = insuranceBalance.add(amount);
    }

    function transferFromInsurance(uint256 amount) public onlyOwnerOrAuthorized {
        insuranceBalance = insuranceBalance.sub(amount);
    }

    function calculateActiveInvestment(uint256 amount) external view onlyOwnerOrAuthorized returns (uint256) {
        return amount.sub(_calculateInvestmentFee(amount));
    }

    function calculateInvestmentFee(uint256 amount) external view onlyOwnerOrAuthorized returns (uint256) {
        return _calculateInvestmentFee(amount);
    }

    function calculatePayoutFee(uint256 amount) external view onlyOwnerOrAuthorized returns (uint256) {
        return _calculateFee(amount, payoutInsuranceFee);
    }

    function getInsuranceBalance() external view onlyOwnerOrAuthorized returns (uint256) {
        return insuranceBalance;
    }

    function getClaimInsuranceFlags() external view 
        returns (bool claimInsurance_, bool claimFullInsurance_) 
    {
        claimInsurance_ = claimInsurance;
        claimFullInsurance_ = claimFullInsurance;
    }

    function getInsuranceFees() external view onlyOwnerOrAuthorized 
        returns (uint256 insuranceFee_, uint256 payoutInsuranceFee_) 
    {
        insuranceFee_ = insuranceFee;
        payoutInsuranceFee_ = payoutInsuranceFee;
    }

    function setClaimInsuranceFlags(bool claimInsurance_, bool claimFullInsurance_) external onlyOwnerOrAuthorized {
        claimInsurance = claimInsurance_;
        claimFullInsurance = claimFullInsurance_;
    }

    function setInsuranceFees(uint256 insuranceFee_, uint256 payoutInsuranceFee_) 
        external onlyOwnerOrAuthorized
    {
        insuranceFee = insuranceFee_;
        payoutInsuranceFee = payoutInsuranceFee_;
    }

    function _getContractBalance() internal view returns (uint256) {
        (
            uint256 totalInvestors_,
            uint256 totalInvestedInContract_,
            uint256 totalWithdrawnFromContract_,
            uint256 contractBalance_,
            uint256 insuranceBalance_,
            bool stopPanicWithdrawal_
        ) = accountTier.getContractInfo();

        return contractBalance_;
    }

    function _getInvestorInfo(address account) internal view returns (uint256, uint256, uint256, uint256) {
        (uint256 totalInvested_,
            uint256 activeBalance_,
            uint256 totalWithdrawn_,
            uint256 lastWithdrawn_,
            uint256 withdrawableBalance_,
            uint256 activeBalanceAfterWithdrawal_,           
		    address referredBy_,
            uint256 joinedDate_
        ) = accountTier.getInvestorInfo(account);

        return (
            totalInvested_,
            totalWithdrawn_,
            lastWithdrawn_,
            joinedDate_
        );
    }

    function _calculateInvestmentFee(uint256 amount) private view returns (uint256) {
        return _calculateFee(amount, insuranceFee);
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