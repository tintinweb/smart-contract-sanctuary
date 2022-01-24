/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Maticsea.sol


pragma solidity 0.8.11;

contract Maticsea is ReentrancyGuard {
    using SafeMath for uint256;
    address public owner;
    uint256 private constant PRIMARY_BENIFICIARY_INVESTMENT_PERC = 65;
    uint256 private constant SECONDARY_BENIFICIARY_INVESTMENT_PERC = 35;
    uint256 private constant PRIMARY_BENIFICIARY_REINVESTMENT_PERC = 40;
    uint256 private constant SECONDARY_BENIFICIARY_REINVESTMENT_PERC = 20;
    uint256 private constant PLAN_TERM = 30 days;
    uint256 private constant TIME_STEP_DRAW = 1 days;
    uint256 private constant DAILY_INTEREST_RATE = 80;
    uint256 private constant DAILY_AUTO_REINTEREST_RATE = 300;
    uint256 private constant ON_WITHDRAW_AUTO_REINTEREST_RATE = 200;
    uint256 private constant MIN_WITHDRAW = 0.02 ether;
    uint256 private constant MIN_INVESTMENT = 0.05 ether;
    uint256 private constant REFERENCE_LEVEL1_RATE = 50;
    uint256 private constant REFERENCE_LEVEL2_RATE = 30;
    uint256 private constant REFERENCE_LEVEL3_RATE = 15;
    uint256 private constant REFERENCE_LEVEL4_RATE = 5;
    uint256 private constant REFERENCE_LEVEL5_RATE = 5;
    address payable public primaryBenificiary;
    address payable public secondaryBenificiary;
    uint256 public totalInvested;
    uint256 public activeInvested;
    uint256 public totalWithdrawal;
    uint256 public totalReinvested;
    uint256 public totalReferralReward;
    struct Investor {
        address addr;
        address ref;
        uint256[5] refs;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest;
        Investment[] investments;
    }
    struct Investment {
        uint256 investmentDate;
        uint256 investment;
        uint256 dividendCalculatedDate;
        bool isExpired;
        uint256 lastWithdrawalDate;
        uint256 dividends;
        uint256 withdrawn;
    }
    mapping(address => Investor) public investors;
    event OnInvest(address investor, uint256 amount);
    event OnReinvest(address investor, uint256 amount);
    constructor(
        address payable _primaryAddress,
        address payable _secondaryAddress
    ) {
        require(
            _primaryAddress != address(0) && _secondaryAddress != address(0),
            "Primary or Secondary address cannot be null"
        );
        primaryBenificiary = _primaryAddress;
        secondaryBenificiary = _secondaryAddress;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only owner is authorized for this option"
        );
        _;
    }
    function changePrimaryBenificiary(address payable newAddress)
        public
        onlyOwner
    {
        require(newAddress != address(0), "Address cannot be null");
        primaryBenificiary = newAddress;
    }
    function changeSecondaryBenificiary(address payable newAddress)
        public
        onlyOwner
    {
        require(newAddress != address(0), "Address cannot be null");
        secondaryBenificiary = newAddress;
    }
    function invest(address _ref) public payable {
        if (_invest(msg.sender, _ref, msg.value)) {
            emit OnInvest(msg.sender, msg.value);
        }
    }
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function _invest(
        address _addr,
        address _ref,
        uint256 _amount
    ) private returns (bool) {
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.05 Matic");
        require(_ref != _addr, "Ref address cannot be same with caller");
        if (investors[_addr].addr == address(0)) {
            _addInvestor(_addr, _ref, _amount);
        }
        investors[_addr].totalDeposit = investors[_addr].totalDeposit.add(
            _amount
        );
        totalInvested = totalInvested.add(_amount);
        activeInvested = activeInvested.add(_amount);
        investors[_addr].investments.push(
            Investment({
                investmentDate: block.timestamp,
                investment: _amount,
                dividendCalculatedDate: block.timestamp,
                lastWithdrawalDate: block.timestamp,
                isExpired: false,
                dividends: 0,
                withdrawn: 0
            })
        );
        _sendRewardOnInvestment(_amount);
        return true;
    }
    function _sendReferralReward(
        address payable _ref,
        uint256 level,
        uint256 _amount
    ) private {
        uint256 reward;
        if (level == 1) {
            reward = _amount.mul(REFERENCE_LEVEL1_RATE).div(1000);
        } else if (level == 2) {
            reward = _amount.mul(REFERENCE_LEVEL2_RATE).div(1000);
        } else if (level == 3) {
            reward = _amount.mul(REFERENCE_LEVEL3_RATE).div(1000);
        } else if (level == 4) {
            reward = _amount.mul(REFERENCE_LEVEL4_RATE).div(1000);
        } else if (level == 5) {
            reward = _amount.mul(REFERENCE_LEVEL5_RATE).div(1000);
        }
        totalReferralReward = totalReferralReward.add(reward);
        _ref.transfer(reward);
    }
    function _reinvest(address _addr, uint256 _amount) private returns (bool) {
        investors[_addr].totalDeposit = investors[_addr].totalDeposit.add(
            _amount
        );
        investors[_addr].totalReinvest = investors[_addr].totalReinvest.add(
            _amount
        );
        totalReinvested = totalReinvested.add(_amount);
        investors[_addr].investments.push(
            Investment({
                investmentDate: block.timestamp,
                investment: _amount,
                dividendCalculatedDate: block.timestamp,
                lastWithdrawalDate: block.timestamp,
                isExpired: false,
                dividends: 0,
                withdrawn: 0
            })
        );
        activeInvested = activeInvested.add(_amount);
        totalInvested = totalInvested.add(_amount);
        _sendRewardOnReinvestment(_amount);
        return true;
    }
    function _addInvestor(
        address _addr,
        address _ref,
        uint256 _amount
    ) private {
        investors[_addr].addr = _addr;
        address refAddr = _ref;
        investors[_addr].ref = _ref;
        for (uint256 i = 0; i < 5; i++) {
            if (investors[refAddr].addr != address(0)) {
                investors[refAddr].refs[i] = investors[refAddr].refs[i].add(1);
                _sendReferralReward(payable(refAddr), (i + 1), _amount);
            } else break;
            refAddr = investors[refAddr].ref;
        }
    }
    function _sendRewardOnInvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount
            .mul(PRIMARY_BENIFICIARY_INVESTMENT_PERC)
            .div(1000);
        uint256 rewardForSecondaryBenificiary = _amount
            .mul(SECONDARY_BENIFICIARY_INVESTMENT_PERC)
            .div(1000);
        primaryBenificiary.transfer(rewardForPrimaryBenificiary);
        secondaryBenificiary.transfer(rewardForSecondaryBenificiary);
    }
    function _sendRewardOnReinvestment(uint256 _amount) private {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 rewardForPrimaryBenificiary = _amount
            .mul(PRIMARY_BENIFICIARY_REINVESTMENT_PERC)
            .div(1000);
        uint256 rewardForSecondaryBenificiary = _amount
            .mul(SECONDARY_BENIFICIARY_REINVESTMENT_PERC)
            .div(1000);
        primaryBenificiary.transfer(rewardForPrimaryBenificiary);
        secondaryBenificiary.transfer(rewardForSecondaryBenificiary);
    }
    function getInvestorRefs(address addr)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Investor storage investor = investors[addr];
        return (
            investor.refs[0],
            investor.refs[1],
            investor.refs[2],
            investor.refs[3],
            investor.refs[4]
        );
    }
    function getDividends(address addr) public view returns (uint256,bool) {
        Investor storage investor = investors[addr];
        uint256 dividendAmount = 0;
        bool toReinvest=false;
        for (uint256 i = 0; i < investor.investments.length; i++) {
            // if (investor.investments[i].isExpired) {
            //     continue;
            // }
            uint256 calculatedDate = block.timestamp;
            uint256 endTime = investor.investments[i].investmentDate.add(
                PLAN_TERM
            );
            if (calculatedDate >= endTime) {
                calculatedDate = endTime;
            }
            uint256 amount = _calculateDividends(
                investor.investments[i].investment,
                DAILY_INTEREST_RATE,
                calculatedDate,
                investor.investments[i].lastWithdrawalDate
            );
            dividendAmount = dividendAmount.add(amount);
             uint256 numberOfDays = calculatedDate.subz(
                investor.investments[i].dividendCalculatedDate
            ) / TIME_STEP_DRAW;
            if (numberOfDays > 0) toReinvest = true;
        }
        return (dividendAmount,toReinvest);
    }
    function calculateDividendsAndautoReinvest(address addr) public {
        Investor storage investor = investors[addr];
        for (uint256 i = 0; i < investor.investments.length; i++) {
            if (investor.investments[i].isExpired) {
                continue;
            }
            uint256 calculatedDate = block.timestamp;
            uint256 endTime = investor.investments[i].investmentDate.add(
                PLAN_TERM
            );
            if (calculatedDate >= endTime) {
                calculatedDate = endTime;
                investor.investments[i].isExpired = true;
                activeInvested = activeInvested.subz(
                    investor.investments[i].investment
                );
            }
            uint256 amount = _calculateDividends(
                investor.investments[i].investment,
                DAILY_INTEREST_RATE,
                calculatedDate,
                investor.investments[i].lastWithdrawalDate
            );
            investor.investments[i].dividends = amount;
            uint256 numberOfDays = calculatedDate.subz(
                investor.investments[i].dividendCalculatedDate
            ) / TIME_STEP_DRAW;
            if (numberOfDays == 0) continue;
            uint256 amountToReinvest = amount
                .mul(DAILY_AUTO_REINTEREST_RATE)
                .div(1000);
            if (_reinvest(addr, amountToReinvest)) {
                emit OnInvest(addr, amountToReinvest);
            }
            investor.investments[i].dividends = investor
                .investments[i]
                .dividends
                .subz(amountToReinvest);
            totalReinvested = totalReinvested.add(amountToReinvest);
            investor.investments[i].dividendCalculatedDate = calculatedDate;
        }
    }
    function getInvestments(address addr)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        Investor storage investor = investors[addr];
        uint256[] memory investmentDates = new uint256[](
            investor.investments.length
        );
        uint256[] memory investments = new uint256[](
            investor.investments.length
        );
        uint256[] memory withdrawn = new uint256[](investor.investments.length);
        bool[] memory isExpireds = new bool[](investor.investments.length);
        for (uint256 i; i < investor.investments.length; i++) {
            require(
                investor.investments[i].investmentDate != 0,
                "wrong investment date"
            );
            withdrawn[i] = investor.investments[i].withdrawn;
            investmentDates[i] = investor.investments[i].investmentDate;
            investments[i] = investor.investments[i].investment;
            if (investor.investments[i].isExpired) {
                isExpireds[i] = true;
            } else {
                isExpireds[i] = false;
                if (PLAN_TERM > 0) {
                    if (
                        block.timestamp >=
                        investor.investments[i].investmentDate.add(PLAN_TERM)
                    ) {
                        isExpireds[i] = true;
                    }
                }
            }
        }
        return (investmentDates, investments, withdrawn, isExpireds);
    }
    function _calculateDividends(
        uint256 _amount,
        uint256 _dailyInterestRate,
        uint256 _now,
        uint256 _start
    ) private pure returns (uint256) {
        return
            (((_amount * _dailyInterestRate) / 1000) * (_now - _start)) /
            (TIME_STEP_DRAW);
    }
    function withdraw() public nonReentrant {
        calculateDividendsAndautoReinvest(msg.sender);
        (uint256 dividends,) = getDividends(msg.sender);
        require(
            dividends >= MIN_WITHDRAW,
            "Cannot withdraw less than 0.02 Matic"
        );
        uint256 reinvestAmount = dividends
            .mul(ON_WITHDRAW_AUTO_REINTEREST_RATE)
            .div(1000);
        _reinvest(msg.sender, reinvestAmount);
        uint256 remainingAmount = dividends.subz(reinvestAmount);
        // Withdrawal date save
        totalWithdrawal = totalWithdrawal.add(remainingAmount);
        investors[msg.sender].totalWithdraw = remainingAmount;
        for (uint256 i = 0; i < investors[msg.sender].investments.length; i++) {
            investors[msg.sender].investments[i].lastWithdrawalDate = block
                .timestamp;
            investors[msg.sender].investments[i].withdrawn = investors[
                msg.sender
            ].investments[i].dividends;
            investors[msg.sender].investments[i].dividends = 0;
        }
        payable(msg.sender).transfer(remainingAmount);
    }
    function getContractInformation()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 contractBalance = getBalance();
        return (
            contractBalance,
            totalInvested,
            activeInvested,
            totalWithdrawal,
            totalReinvested,
            totalReferralReward
        );
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        uint256 c = a - b;
        return c;
    }
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}