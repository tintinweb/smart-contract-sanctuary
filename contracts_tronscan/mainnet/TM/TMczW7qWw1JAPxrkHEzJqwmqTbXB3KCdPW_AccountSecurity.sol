//SourceUnit: AccountSecurity.sol

pragma solidity >=0.5.10;

import './IProtectionTier.sol';
import './IAccountTier.sol';
import './SafeMath.sol';
import './Authorizable.sol';

contract AccountSecurity is Authorizable, IProtectionTier {
    using SafeMath for uint256;

    uint256 constant public PERCENT_DIVIDER = 100000;

    bool panicWithdrawalHold;
    bool allowOnlyInsurance;

    uint256 withdrawalRulesCount;
    uint256 withdrawalHoldsCount;

    struct WithdrawalRule {
        uint256 allowedPercentage;
		bool enabled;
    }

    struct WithdrawalHold {
        address account;
		bool hold;
    }

    mapping(uint256 => WithdrawalRule) withdrawalRules;
    mapping(uint256 => address) withdrawalHoldAddresses;
    mapping(address => WithdrawalHold) withdrawalHolds;

    IAccountTier accountTier;

    constructor() public {

    }

    function setAccountTier(IAccountTier accountTier_) external onlyOwnerOrAuthorized {
        accountTier = accountTier_;
    }

    function getTiers() external view onlyOwnerOrAuthorized returns (address) {
        return (
            address(accountTier)
        );
    }

    function getWithdrawalRulesCount() external view onlyOwnerOrAuthorized 
        returns (uint256) 
    {
        return withdrawalRulesCount;
    }

    function getWithdrawalHoldsCount() external view onlyOwnerOrAuthorized 
        returns (uint256) 
    {
        return withdrawalHoldsCount;
    }

    function getWithdrawalHoldAddressById(uint256 id) external view onlyOwnerOrAuthorized 
        returns (address) 
    {
        return withdrawalHoldAddresses[id];
    }

    function getWithdrawalHoldFlagByAddress(address account) external view onlyOwnerOrAuthorized 
        returns (bool) 
    {
        return withdrawalHolds[account].hold;
    }

    function setWithdrawalRule(
        uint256 ruleId,
        uint256 allowedPercentage,
		bool enabled
    ) external onlyOwnerOrAuthorized
    {
        require(allowedPercentage > 0, "Percentage greater than zero");
        WithdrawalRule storage withdrawalRule = withdrawalRules[ruleId];

        if (withdrawalRule.allowedPercentage == 0) {
            withdrawalRulesCount = withdrawalRulesCount.add(1);
        }

        withdrawalRule.allowedPercentage = allowedPercentage;
        withdrawalRule.enabled = enabled;
    }

    function setWithdrawalHold(
        address account,
		bool hold
    ) external onlyOwnerOrAuthorized
    {
        WithdrawalHold storage withdrawalHold = withdrawalHolds[account];

        if (withdrawalHold.account != account) {
            withdrawalHoldAddresses[withdrawalHoldsCount] = account;
            withdrawalHoldsCount = withdrawalHoldsCount.add(1);
        }

        withdrawalHold.account = account;
        withdrawalHold.hold = hold;
    }

    function stopPanicWithdrawal(bool panicWithdrawalHold_) external onlyOwnerOrAuthorized {
        panicWithdrawalHold = panicWithdrawalHold_;
    }

    function setAllowOnlyInsurance(bool allowOnlyInsurance_) external onlyOwnerOrAuthorized {
        allowOnlyInsurance = allowOnlyInsurance_;
    }

    function checkWithdrawalMode(address payable account) external view onlyOwnerOrAuthorized returns (uint256) {
        if (panicWithdrawalHold) {
            return 0;
        }

        if (withdrawalHolds[account].hold) {
            return 1;
        }

        (uint256 totalInvested_,
            uint256 totalWithdrawn_) = _getInvestorInfo(account);

        for (uint256 i = 0; i < withdrawalRulesCount; i++) {
            if (withdrawalRules[i].enabled) {
                if (totalWithdrawn_ >= _calculateFee(totalInvested_, withdrawalRules[i].allowedPercentage)) {
                    return 0;
                }
            }
        }

        if (allowOnlyInsurance) {
            return 3;
        }

        return 2;
    }

    function checkInvestmentMode(address account, address referrer, uint256 amount) 
        external view onlyOwnerOrAuthorized returns (uint256) 
    {
        if (allowOnlyInsurance) {
            return 3;
        }

        return 2;
    }

    function checkPanicWithdrawalHold() external view onlyOwnerOrAuthorized returns (bool) {
        return panicWithdrawalHold;
    }

    function _getInvestorInfo(address account) internal view returns (uint256, uint256) {
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
            totalWithdrawn_
        );
    }

    function _calculateFee(uint256 amount, uint256 percentage) private pure returns (uint256) {
        return (amount.mul(percentage)).div(PERCENT_DIVIDER);
    }
}

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

//SourceUnit: IProtectionTier.sol

pragma solidity >=0.5.10;

interface IProtectionTier {
    function checkWithdrawalMode(address payable account) external view returns (uint256);
    function checkInvestmentMode(address account, address referrer, uint256 amount) 
        external view returns (uint256);
    function checkPanicWithdrawalHold() external view returns (bool);
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