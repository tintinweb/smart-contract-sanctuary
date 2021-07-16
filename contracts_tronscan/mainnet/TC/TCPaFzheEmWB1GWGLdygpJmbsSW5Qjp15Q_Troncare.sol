//SourceUnit: Address.sol

pragma solidity >=0.5.4 <0.6.0;

library Address {
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function transfer(address recipient, uint256 amount) internal {
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Transfer failed");
    }

    function toPayable(address recipient) internal pure returns (address payable) {
        return address(uint160(recipient));
    }
}


//SourceUnit: IOwnable.sol

pragma solidity >=0.5.4 <0.6.0;

/*
* @title IOwnable contract interface.
*/
interface IOwnable {
    function owner() external view returns (address);
    function allowed(address) external view returns (bool);
}


//SourceUnit: Ownable.sol

pragma solidity >=0.5.4 <0.6.0;

import "./IOwnable.sol";

contract Ownable is IOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor(address _newOwner) public {
        _owner = _newOwner;
        emit OwnershipTransferred(address(0), _newOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function allowed(address _who) public view returns (bool) {
        return owner() == _who;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


//SourceUnit: SafeMath.sol

pragma solidity >=0.5.4 <0.6.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: Troncare.sol

pragma solidity >=0.5.4 <0.6.0;

import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/*
 *	TRONCARE - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://troncare.org                                       │
 *   │                                                                       │
 *   |   Developed by: t.me/smart_contract_dev                               |
 *   |   Based on: TRON2GET source code                                      |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (200 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.05% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.1% for every 1,000,00 TRX on platform address balance
 *
 *   - Minimal deposit: 200 TRX, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 3-level referral commission: 4% - 2% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82.5% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 7.5% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 */

contract Troncare is Ownable, ReentrancyGuard {
    using Address for *;
    using SafeMath for uint256;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event MinDepositChanged(uint256 amount);
    event Paused();
    event UnPaused();

    uint256 public getMinDeposit;

    uint256 constant public PERCENTS_DIVIDER = 10000; // 100%
    uint256 constant public BASE_PERCENT = 100; // 1%
    uint256 constant public OPERATIONAL_FEE = 850; // 8.5%
    uint256 constant public INVESTMENT_AMOUNT_BONUS = 10; // 0.1%
    uint256 constant public INVESTMENT_MAX_AMOUNT_BONUS = 500; // 5%
    uint256 constant public PERSONAL_HOLD_BONUS = 5; // 0.05% but divided on the call
    uint256 constant public MAX_CONTRACT_BONUS = 300; // Contract total amount bonus MAX 3%
    uint256 constant public INVESTMENT_BONUS_STEP = 10_000e6; // 10K TRX
    uint256 constant public CONTRACT_BALANCE_STEP = 2_000_000e6; // 2M TRX
    uint256 constant public TIME_STEP = 1 days; // 24H

    uint256[] public REFERRAL_PERCENTS = [400, 200, 50]; // 4%, 2%, 0.5%

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address public teamWallet;

    bool private _paused;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 totalDeposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 level1;
        uint256 level2;
        uint256 level3;
    }

    struct DepositLog {
        address from;
        uint256 amount;
        uint256 timestamp;
    }

    DepositLog[] public lastDeposits;

    mapping (address => User) public users;
    mapping (address => uint256) public balance;

    constructor(address _teamWallet) public Ownable(msg.sender) {
        teamWallet = _teamWallet;
        require(teamWallet != address(0), "Troncare: team wallet didnt set");
        getMinDeposit = 100e6; // 100 TRX
        emit MinDepositChanged(getMinDeposit);
        emit UnPaused();
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBalanceRate() public view returns (uint256) {
        if (getContractBalance() < CONTRACT_BALANCE_STEP) {
            return 0;
        }
        uint256 contractBalancePercent = getContractBalance().div(CONTRACT_BALANCE_STEP);
        if (contractBalancePercent >= MAX_CONTRACT_BONUS) {
            return MAX_CONTRACT_BONUS;
        }

        return contractBalancePercent;
    }

    // @dev without contract balance check
    function availableForWithdrawDirty(address userAddress) public view returns (uint256 totalAmount) {
        uint256 dividends = getUserDividends(msg.sender);
        totalAmount = totalAmount.add(dividends);

        uint256 referralBonus = getUserReferralBonus(userAddress);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
        }
    }

    // @dev sum up of basic profit + hold bonus + contract bonus + total deposit bonus
    function getUserPercentRate(address userAddress) public view returns (uint256) {
        return BASE_PERCENT
        .add(getHoldBonus(userAddress))
        .add(getContractBalanceRate())
        .add(getInvestBonus(userAddress));
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        if (!isActive(userAddress)) {
            return 0;
        }

        User memory user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(user.deposits[i].start))
                    .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                    .mul(block.timestamp.sub(user.checkpoint))
                    .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);
            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns (uint256, uint256, uint256) {
        return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].bonus;
    }

    // @dev available balance for withdraw - default method
    function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns (uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }

        return false;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].totalDeposits;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 amount;
        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    // @dev Invest bonus
    function getInvestBonus(address userAddress) public view returns (uint256) {
        uint256 deposits = getUserTotalDeposits(userAddress);
        if (deposits >= INVESTMENT_BONUS_STEP) {
            if (deposits.div(INVESTMENT_BONUS_STEP) >= INVESTMENT_MAX_AMOUNT_BONUS) {
                return INVESTMENT_MAX_AMOUNT_BONUS;
            }
            return deposits.div(INVESTMENT_BONUS_STEP);
        }

        return 0;
    }

    // @dev Hold bonus
    function getHoldBonus(address userAddress) public view returns (uint256) {
        uint256 checkpoint = getUserCheckpoint(userAddress);
        if (checkpoint == 0) {
            return 0;
        }

        uint256 timeframe = (checkpoint <= block.timestamp) ? block.timestamp.sub(checkpoint, "sub: timeframe") : 0;
        if (timeframe >= TIME_STEP) {
            uint256 periods = timeframe.div(TIME_STEP);  // TIME_STEP = 24H
            if (periods > 0) {
                return periods.mul(PERSONAL_HOLD_BONUS);
            }
        }

        return 0;
    }

    function invest(address referrer) external payable notPaused nonReentrant {
        require(msg.value >= getMinDeposit, "Troncare: low deposit");
        require(msg.sender != referrer, "Troncare: affiliate is referrer");

        uint toTeamWallet = msg.value.mul(OPERATIONAL_FEE).div(PERCENTS_DIVIDER);
        _updateBalance(teamWallet, toTeamWallet);

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {

                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);

                    if (i == 0) {
                        users[upline].level1 = users[upline].level1.add(1);
                    } else if (i == 1) {
                        users[upline].level2 = users[upline].level2.add(1);
                    } else if (i == 2) {
                        users[upline].level3 = users[upline].level3.add(1);
                    }

                    emit RefBonus(upline, msg.sender, i, amount);

                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));
        user.totalDeposits = user.totalDeposits.add(msg.value);

        _depositLog();

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        _withdrawTeam(); // dev: withdraw to team wallet

        emit NewDeposit(msg.sender, msg.value);
        emit FeePayed(msg.sender, msg.value.mul(OPERATIONAL_FEE).div(PERCENTS_DIVIDER));
    }

    function withdraw() external nonReentrant {
        User storage user = users[msg.sender];

        uint256 totalAmount;
        uint256 dividends = getUserDividends(msg.sender);
        totalAmount = totalAmount.add(dividends);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }

        require(totalAmount != 0, "User has no dividends");

        user.checkpoint = block.timestamp;
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        _safeWithdraw(msg.sender, totalAmount);
    }

    function _withdrawTeam() internal {
        uint256 _toWithdraw = balance[teamWallet];
        balance[teamWallet] = 0;
        _safeWithdraw(teamWallet, _toWithdraw);
    }

    function setMinInvestAmount(uint256 _amount) public onlyOwner {
        getMinDeposit = _amount;
        emit MinDepositChanged(_amount);
    }

    function pauseInvestment(bool _unpause) public onlyOwner {
        if (_unpause) {
            _paused = false;
            emit UnPaused();
        } else {
            _paused = true;
            emit Paused();
        }
    }

    function _depositLog() internal {
        lastDeposits.push(DepositLog({
            from: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp
        }));

        if (lastDeposits.length > 10) {
            for (uint i = 0; i < lastDeposits.length - 1; i++) {
                lastDeposits[i] = lastDeposits[i + 1];
            }
            lastDeposits.pop();
        }
    }

    function _updateBalance(address _who, uint256 _amount) internal {
        balance[_who] = balance[_who].add(_amount);
    }

    function _safeWithdraw(address _to, uint _amount) internal {
        require(_to != address(0), "SafeWithdraw: address zero withdraw");

        uint256 contractBalance = getContractBalance();
        if (contractBalance < _amount) {
            _amount = contractBalance;
        }

        Address.transfer(_to, _amount);
        emit Withdrawn(_to, _amount);
    }

    modifier notPaused() {
        require(!_paused, "Invest: paused");
        _;
    }
}