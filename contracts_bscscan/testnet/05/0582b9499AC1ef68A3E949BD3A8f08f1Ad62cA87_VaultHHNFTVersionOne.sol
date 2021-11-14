/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(isContract(address(token)), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract VaultHHNFTVersionOne is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 public INVEST_MIN_AMOUNT;
    uint256 public INVEST_MAX_AMOUNT;
    uint256[] public REFERRAL_PERCENTS = [70, 30, 15, 10, 5];
    uint256 constant public PROJECT_FEE = 50;
    uint256 constant public PERCENT_STEP = 5;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalInvested;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 minAmount;
        uint256 maxAmount;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256[5] levels;
        uint256 totalBonus;
        uint256 withdrawn;
    }

    mapping (address => User) internal users;

    bool public started;
    address payable public commissionWallet;


    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address tokenAddr, address payable wallet) {
        require(!isContract(wallet) && isContract(tokenAddr));
        token = IERC20(tokenAddr);
        commissionWallet = wallet;

        plans.push(Plan(3, 5,50000 * 10 ** 18,400000 * 10 ** 18));
        plans.push(Plan(7, 11,50000 * 10 ** 18,300000 * 10 ** 18));
        plans.push(Plan(15, 19,50000 * 10 ** 18,250000 * 10 ** 18));
        plans.push(Plan(30, 26,50000 * 10 ** 18,200000 * 10 ** 18));
    }

    function setStarted(bool value) external onlyOwner {
        started = value;
    }

    function invest(uint8 plan, uint256 value) public {
        require(started,"Not started yet");
        require(plan < 4, "Invalid plan");

        require(plans[plan].minAmount <= value && plans[plan].maxAmount >= value, "Invest out of the range");

        require(value <= token.allowance(msg.sender, address(this)));
        token.safeTransferFrom(msg.sender, address(this), value);

        uint256 fee = value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        token.safeTransfer(commissionWallet, fee);
        emit FeePayed(msg.sender, fee);

        User storage user = users[msg.sender];

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }else{
            uint256[] memory totalDepositedPerPlan;
            for(uint256 i = 0; i < user.deposits.length; i++){
                totalDepositedPerPlan[user.deposits[i].plan] = totalDepositedPerPlan[user.deposits[i].plan] == 0 ? user.deposits[i].amount :totalDepositedPerPlan[user.deposits[i].plan].add(user.deposits[i].amount);
            }
            uint256 totalPretend = totalDepositedPerPlan[plan].add(value);
            require(totalPretend > plans[plan].maxAmount,"MAX_INVEST_PLAN_WALLET_EXCEED");
        }


        user.deposits.push(Deposit(plan, value, block.timestamp));

        totalInvested = totalInvested.add(value);

        emit NewDeposit(msg.sender, plan, value);
    }

    function withdraw() public {
        
        User storage user = users[msg.sender];

        uint256 userTotalAmount = getUserDividends(msg.sender);

        require(userTotalAmount > 0, "User has no dividends");

        //uint256 vaultBalance = token.balanceOf(address(this));

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(userTotalAmount);

        token.safeTransfer(msg.sender, userTotalAmount);

        emit Withdrawn(msg.sender, userTotalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userTotalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
            if (user.checkpoint < finish) {
                uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
                    userTotalAmount = userTotalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }

        return userTotalAmount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
        return amount;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
    }

    function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
        return(totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn) {
        return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress));
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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
}