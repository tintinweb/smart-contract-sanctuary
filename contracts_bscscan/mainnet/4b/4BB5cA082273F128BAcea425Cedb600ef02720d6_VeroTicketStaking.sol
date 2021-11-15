pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./Utils.sol";
import "./IBEP20.sol";

contract VeroTicketStaking is DataStorage, Events, Manageable, Utils {
    using SafeMath for uint256;

    /**
     * @dev Constructor function
     */
    constructor(address payable wallet, IBEP20 _bep20, IBEP20 _ticketBep20) public {
        commissionWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        stakingToken = _bep20;
        rewardToken = _ticketBep20;
        plans.push(Plan(5, 20000*10**6));
    }

    function invest(uint8 plan, uint256 _amount)
        external
        payable
        blockReEntry()
    {
        require(_amount >= plans[plan].minInvest, "Invest amount isn't enough");
        require(plan == 0, "Invalid plan");
        require(
            stakingToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        _invest(plan, msg.sender, _amount);
        if (PROJECT_FEE > 0) {
            commissionWallet.transfer(PROJECT_FEE);
            emit FeePayed(msg.sender, PROJECT_FEE);
        }
    }

    function _invest(
        uint8 plan,
        address userAddress,
        uint256 _amount
    ) internal {
        User storage user = users[userAddress];
        uint256 currentTime = block.timestamp;
        require(
            user.lastStake.add(TIME_STAKE) <= currentTime,
            "Required: Must be take time to stake"
        );
        require(user.deposits.length == 0, "Required: Only one-time stake per address");
        _safeTransferFrom(userAddress, address(this), _amount);
        user.lastStake = currentTime;
        user.owner = userAddress;
        user.registerTime = currentTime;

        if (user.deposits.length == 0) {
            user.checkpoint = currentTime;
            emit Newbie(userAddress, currentTime);
            totalUser.push(user);
        }

        uint256 finish = getResult(plan);
        user.deposits.push(
            Deposit(
                plan,
                _amount,
                currentTime,
                finish,
                userAddress,
                PROJECT_FEE,
                false
            )
        );
        totalStakedAmount = totalStakedAmount.add(_amount);
        totalDeposits.push(
            Deposit(
                plan,
                _amount,
                currentTime,
                finish,
                userAddress,
                PROJECT_FEE,
                false
            )
        );

        emit NewDeposit(
            userAddress,
            0,
            _amount,
            currentTime,
            finish,
            PROJECT_FEE
        );
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        bool sent = stakingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }   
    
    function unStake(uint256 start) external payable blockReEntry() {
        require(msg.value == UNLOCK_FEE, "Required: Pay fee for unlock stake");
        User storage user = users[msg.sender];

        for (uint256 i = 0; i < user.deposits.length; i++) {            
            if (
                user.deposits[i].start == start &&
                user.deposits[i].isUnStake == false &&
                block.timestamp >= user.deposits[i].finish
            ) {
                user.deposits[i].isUnStake = true;
                stakingToken.transfer(user.owner, user.deposits[i].amount);
                rewardToken.transfer(user.owner, VERO_TICKET);
                user.totalPayout = user.totalPayout.add(user.deposits[i].amount);
                emit UnStake(msg.sender, start, user.deposits[i].amount);
                if(UNLOCK_FEE > 0) {
                    commissionWallet.transfer(UNLOCK_FEE);
                    emit FeePayed(msg.sender, UNLOCK_FEE);
                }                
            }
        }
    }

    function setOwner(address payable _addr) external onlyAdmins {
        owner = _addr;
        admins[_addr] = true;
    }

    function setFeeSystem(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
    }

    function setUnlockFeeSystem(uint256 _fee) external onlyAdmins {
        UNLOCK_FEE = _fee;
    }

    function setTime_Step(uint256 _timeStep) external onlyAdmins {
        TIME_STEP = _timeStep;
    }

    function setTime_Stake(uint256 _timeStake) external onlyAdmins {
        TIME_STAKE = _timeStake;
    }

    function setCommissionsWallet(address payable _addr) external onlyAdmins {
        commissionWallet = _addr;
    }

    function setMinInvestPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].minInvest = _amount;
    }

    function handleForfeitedBalance(address coinAddress, uint256 value, address payable to) public {
        require((msg.sender == owner), "Restricted Access!");
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IBEP20(coinAddress).transfer(to, value);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./DataStorage.sol";
import "./SafeMath.sol";

contract Utils is DataStorage {
    using SafeMath for uint256;

    function getResult(uint8 plan)
        public
        view
        returns (uint256 finish)
    {
        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            address curentUser,
            uint256 checkPoint,
            uint256 totalPayout,
            uint256 totalDeposit,
            uint256 registerTime,
            uint256 lastStake
        )
    {
        User storage user = users[userAddress];

        curentUser = user.owner;
        checkPoint = user.checkpoint;
        totalPayout = user.totalPayout;
        totalDeposit = getUserTotalDeposits(userAddress);
        registerTime = user.registerTime;
        lastStake = user.lastStake;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 minInvest)
    {
        time = plans[plan].time;
        minInvest = plans[plan].minInvest;
    }

    function isUnStake(address userAddress, uint256 start)
        public
        view
        returns (bool _isUnStake)
    {
        User storage user = users[userAddress];
        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].start == start) {
                _isUnStake = user.deposits[i].isUnStake;
            }
        }
    }

    function getAllDeposits(uint256 fromRegisterTime, uint256 toRegisterTime)
        public
        view
        returns (Deposit[] memory)
    {
        Deposit[] memory allDeposit = new Deposit[](totalDeposits.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalDeposits.length; index++) {
            if (totalDeposits[index].start >= fromRegisterTime && totalDeposits[index].start <= toRegisterTime) {
                allDeposit[count] = totalDeposits[index];
                ++count;
            }
        }
        return allDeposit;
    }

    function getAllDepositsByAddress(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        User memory user = users[userAddress];
        return user.deposits;
    }

    function getAllUser(uint256 fromRegisterTime, uint256 toRegisterTime)
        public
        view
        returns (User[] memory)
    {
        User[] memory allUser = new User[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (totalUser[index].registerTime >= fromRegisterTime && totalUser[index].registerTime <= toRegisterTime) {
                allUser[count] = totalUser[index];
                ++count;
            }
        }
        return allUser;
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract Manageable {
    mapping(address => bool) public admins;
    uint internal constant ENTRY_ENABLED = 1;
    uint internal constant ENTRY_DISABLED = 2;

    uint internal reentryStatus;
    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function modifyAdmins(address[] memory newAdmins, address[] memory removedAdmins) public onlyAdmins {
        for(uint256 index; index < newAdmins.length; index++) {
            admins[newAdmins[index]] = true;
        }
        for(uint256 index; index < removedAdmins.length; index++) {
            admins[removedAdmins[index]] = false;
        }
    }
  
    modifier blockReEntry() {
        require(reentryStatus != ENTRY_DISABLED, "Security Block");
        reentryStatus = ENTRY_DISABLED;

        _;

        reentryStatus = ENTRY_ENABLED;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract Events {
  event Newbie(address user, uint256 registerTime);
  event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 start, uint256 finish, uint256 fee);
  event Withdrawn(address indexed user, uint256 amount);
  event UnStake(address indexed user, uint256 start, uint256 amount);
  event FeePayed(address indexed user, uint256 totalAmount);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "./IBEP20.sol";

contract DataStorage {

	uint256 public PROJECT_FEE = 0.01 ether;
	uint256 public UNLOCK_FEE = 0 ether;
	uint256 public VERO_TICKET = 1;
	uint256 constant public PERCENTS_DIVIDER = 100000;
	uint256 public TIME_STEP = 1 days;
	uint256 public TIME_STAKE = 0;
	IBEP20 public stakingToken;
	IBEP20 public rewardToken;

  	uint256 public totalStakedAmount;

    struct Plan {
        uint256 time;
		uint256 minInvest;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
		uint256 finish;
		address userAddress;
		uint256 fee;
        bool isUnStake;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 totalPayout;
		address owner;
		uint256 registerTime;
		uint256 lastStake;
	}

	mapping (address => User) internal users;

	User[] internal totalUser;
	Deposit[] internal totalDeposits;


	address payable public commissionWallet;
    address payable public owner;
}

