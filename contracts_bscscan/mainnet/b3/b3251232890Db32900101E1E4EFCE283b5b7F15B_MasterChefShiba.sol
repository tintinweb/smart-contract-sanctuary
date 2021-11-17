/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract MasterChefShiba {
    using SafeMath for uint256;

    struct User {
        uint256 deposit_time;
        uint256 claim_time;
        uint256 total_deposits;
        uint256 total_claims;
        uint256 last_distPoints;
    }

    address public shiba;
    address private dev;
    
    mapping(address => User) public users;
    address[] public userIndices;

    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_claimed;
    uint256 public total_rewards;
    uint256 public totalDistributeRewards;
    uint256 public totalDistributePoints;
    uint256 public unclaimedDistributeRewards;
    uint256 public devFeePercent;
    uint256 public constant MULTIPLIER = 10e18;
    address public flokisChef;

    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event Withdraw(address indexed addr, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor(address _flokisChef) public {
        devFeePercent = 2;
        dev = msg.sender;
        shiba = 0x2859e4544C4bB03966803b044A93563Bd2D0DD4D;
        flokisChef = _flokisChef;
    }

    receive() external payable {
        revert("Do not send BNB.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }
    
    modifier onlyFlokisChef() {
        require(msg.sender == flokisChef, "Caller is not flokisChef!");
        _;
    }

    function changeDev(address newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }
    
    function changeFlokisChef(address newFlokisChef) external onlyDev {
        require(newFlokisChef != address(0), "Zero address");
        flokisChef = newFlokisChef;
    }
    
    function migrateGlobals(
        uint256 _total_users,
        uint256 _total_deposited,
        uint256 _total_claimed,
        uint256 _total_rewards,
        uint256 _totalDistributeRewards,
        uint256 _totalDistributePoints,
        uint256 _unclaimedDistributeRewards
    ) external onlyDev {
        total_users = _total_users;
        total_deposited = _total_deposited;
        total_claimed = _total_claimed;
        total_rewards = _total_rewards;
        totalDistributeRewards = _totalDistributeRewards;
        totalDistributePoints = _totalDistributePoints;
        unclaimedDistributeRewards = _unclaimedDistributeRewards;
    }
    
    function migrateUsers(address[] memory _addr, User[] memory _user) external onlyDev {        
        for (uint256 i = 0; i < _addr.length; i++) {            
            if (users[_addr[i]].deposit_time == 0) {
                userIndices.push(_addr[i]);
                users[_addr[i]] = _user[i];
            }      
        }
    }

    function setUser(address _addr, User memory _user) external onlyDev {
        require(users[_addr].deposit_time > 0, "User does not exist");        
        users[_addr] = _user;
    }
    
    function setDevFeePercent(uint256 percent) external onlyDev {
        devFeePercent = percent;
    }

    function emergencyWithdraw(uint256 amnt) external onlyDev {
        IBEP20(shiba).transfer(dev, amnt);
    }

    function deposit(uint256 amount) external {
        address _addr = msg.sender;
        if (users[_addr].deposit_time == 0) {
            userIndices.push(_addr); // New user
            users[_addr].last_distPoints = totalDistributePoints;
            total_users++;
        }

        if (getTotalRewards(_addr) > 0)
            claim();

        users[_addr].deposit_time = block.timestamp;
        users[_addr].total_deposits = users[_addr].total_deposits.add(amount);

        total_deposited = total_deposited.add(amount);

        IBEP20(shiba).transfer(dev, amount.mul(devFeePercent).div(100)); // 2% (dev)

        emit NewDeposit(_addr, amount);
    }

    function _roll(address _sender) public {
        _dripRewards();

        uint256 _rewards = getDistributionRewards(_sender);
        require(_rewards > 0, "No rewards.");

        unclaimedDistributeRewards = unclaimedDistributeRewards.sub(getDistributionRewards(_sender));

        users[_sender].claim_time = block.timestamp;
        users[_sender].total_claims = users[_sender].total_claims.add(_rewards);
        total_claimed = total_claimed.add(_rewards);

        total_rewards = total_rewards.sub(_rewards);

        users[_sender].last_distPoints = totalDistributePoints;

        emit Withdraw(_sender, _rewards);

        users[_sender].deposit_time = block.timestamp;
        users[_sender].total_deposits = users[_sender].total_deposits.add(_rewards);

        total_deposited = total_deposited.add(_rewards);

        IBEP20(shiba).transfer(dev, _rewards.mul(devFeePercent).div(100)); // 2% (dev)

        emit NewDeposit(_sender, _rewards);
    }
    
    function _disperse(uint256 amount) internal {
        if (amount > 0 && total_deposited > 0) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(total_deposited));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
            unclaimedDistributeRewards = unclaimedDistributeRewards.add(amount);
        }
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        uint256 newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        uint256 distribute = users[account].total_deposits.mul(newDividendPoints).div(MULTIPLIER);
        return distribute > unclaimedDistributeRewards ? unclaimedDistributeRewards : distribute;
    }
    
    function getTotalRewards(address _user) public view returns (uint256) {
        return
            users[_user].total_deposits > 0
                ? getDistributionRewards(_user).add(
                    _getShibaBalancePool()
                        .mul(users[_user].total_deposits)
                        .div(total_deposited)
                )
                : 0;
    }

    function claim() public {
        _dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getDistributionRewards(_sender);
        require(_rewards > 0, "No rewards.");

        unclaimedDistributeRewards = unclaimedDistributeRewards.sub(getDistributionRewards(_sender));

        users[_sender].claim_time = block.timestamp;
        users[_sender].total_claims = users[_sender].total_claims.add(_rewards);
        total_claimed = total_claimed.add(_rewards);

        IBEP20(shiba).transfer(_sender, _rewards);
        total_rewards = total_rewards.sub(_rewards);

        users[_sender].last_distPoints = totalDistributePoints;

        emit Withdraw(_sender, _rewards);
    }

    function withdraw() external {
        withdraw(users[msg.sender].total_deposits);
    }

    function withdraw(uint256 amount) public onlyFlokisChef {
        address _sender = msg.sender;
        uint256 _amount = amount > users[_sender].total_deposits ? users[_sender].total_deposits : amount;
        require(_amount > 0, "User has not deposited");

        if (getTotalRewards(_sender) > 0)
            claim();

        users[_sender].deposit_time = 0;
        users[_sender].total_deposits = 0;
        total_deposited = total_deposited.sub(_amount);
    }

    function dripRewards() external {
        _dripRewards();
    }

    function _dripRewards() internal {
        uint256 drip = _getShibaBalancePool();

        if (drip > 0)
            _disperse(drip);
    }

    function getDayDripEstimate(address _user) external view returns (uint256) {
        return
            users[_user].total_deposits > 0
                ? _getShibaBalancePool()
                    .mul(users[_user].total_deposits)
                    .div(total_deposited)
                : 0;
    }
    
    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 total_deposits,
            uint256 total_claims,
            uint256 last_distPoints
        )
    {
        return (
            users[_addr].total_deposits,
            users[_addr].total_claims,
            users[_addr].last_distPoints
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_claimed,
            uint256 _total_rewards,
            uint256 _totalDistributeRewards
        )
    {
        return (total_users, total_deposited, total_claimed, total_rewards, totalDistributeRewards);
    }

    function getShibaBalancePool() external view returns (uint256) {
        return _getShibaBalancePool();
    }

    function _getShibaBalancePool() internal view returns (uint256) {
        return _getShibaBalance().sub(total_rewards);
    }

    function _getShibaBalance() internal view returns (uint256) {
        return IBEP20(shiba).balanceOf(address(this));
    }

    function getShibaBalance() external view returns (uint256) {
        return _getShibaBalance();
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}