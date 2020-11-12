// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/CMRewards.sol

// Expirmental! v0.6.1

pragma solidity 0.6.6;


// CMRewards is a contract for calculating rewards
// based the amount a user has staked.
contract CMRewards {
    using SafeMath for uint256;

    // rewards rate = rewardRate / rewardMin
    uint256 public rewardMin    =       1e10; // wont calculate rewards on smaller.
    uint256 public rewardRate   =       5;    // 5/1e10 ~ .001 per share

    mapping(address => UserStake) public users;

    /** @dev
     * This keeps track of a users stake for calculating payouts and
     * rewards
    */
    struct UserStake {
        uint256 staked;
        uint256 lastUpdated;
        uint256 rewardDebt;
    }

    /** @dev adds pending rewards to reward debt. */
    function _updateUser(address u) internal {
        if (users[u].staked > rewardMin) {
            users[u].rewardDebt = users[u].rewardDebt.add(_pendingRewards(u));
        }
        users[u].lastUpdated = block.number;
    }

    /** @dev calculates a users rewards that accumilated since the last update*/
    function _pendingRewards(address u) internal view returns (uint256) {
        uint256 _duration = block.number.sub(users[u].lastUpdated);
        uint256 _rewards = rewardRate.mul(users[u].staked).div(rewardMin);
        return _duration.mul(_rewards);
    }

    /** @dev adds staked amount to the user safely. (Updates user before) */
    function _userAddStake(address _addr, uint256 _value) internal {
        require(_value > 0, "staked value must be greated than 0");
        _updateUser(_addr);
        users[_addr].staked = users[_addr].staked.add(_value);
    }

    /** @dev safely removes from a users stake. (Updates user before) */
    function _usersRemoveStake(address _addr, uint256 _value) internal {
        require(users[_addr].staked >= _value, "Cannot remove more than the user has staked");
        _updateUser(_addr);
        users[_addr].staked = users[_addr].staked.sub(_value);
    }
}

// File: contracts/DiFyDAIWallet.sol

pragma solidity 0.6.6;





interface IYDAI {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function balanceOf(address account) external view returns(uint256);
    function getPricePerFullShare() external view returns(uint256);
}

contract DiFyDAIWallet is Ownable, CMRewards {
    using SafeMath for uint256;
    uint256 constant BP = 10**12;

    IERC20 yfiii;
    IERC20 dai;
    IYDAI ydai;

    uint256 public adminFee = 5;              // 0.5%
    uint256 constant public adminFeeMax = 150; // 15%
    uint256 constant adminFeeFull = 1000;

    constructor(address daiAddress, address ydaiAddress, address yfiiiAddress) public {
        dai = IERC20(daiAddress);
        ydai = IYDAI(ydaiAddress);
        yfiii = IERC20(yfiiiAddress);
    }

    /**
     * @dev deposit dai and stake the recieved ydai for rewards
    */
    function deposit(uint256 _amount) public {
        // transfer dai
        require(dai.transferFrom(msg.sender, address(this), _amount), "deposit failed");

        // starting ydai balance:
        uint256 startBal = ydai.balanceOf(address(this));
        // invest with ydai
        ydai.deposit(_amount);
        // endind ydai balance:
        uint256 endBal = ydai.balanceOf(address(this));

        // update the user
        _userAddStake(msg.sender, endBal.sub(startBal));
    }

    /**
     * @dev withdraw msg.sender's staked ydai from yearn, take admin fee and
     * and send dai the dai to msg.sender
    */
    function withdraw(uint256 _amount) public {
        require(_amount <= users[msg.sender].staked, "Cannot withdraw more than your balance");
        require(_amount > 0, "Cannot withdraw 0");

        // update user and subtract withdrawed amount
        _usersRemoveStake(msg.sender, _amount);

        // withdraw from ydai
        uint256 startBal = dai.balanceOf(address(this));
        ydai.withdraw(_amount);
        uint256 endBal = dai.balanceOf(address(this));

        // send to user
        uint256 _avaliable = endBal.sub(startBal);
        uint256 _fee = _avaliable.mul(adminFee).div(adminFeeFull);

        require(dai.transfer(msg.sender, _avaliable.sub(_fee)), "withdraw failed");
        //dai.transfer(owner(), _fee);
    }

    /**
     * @dev claim reward debt
    */
    function claim() public {
        // update the user – calculating any rewards
        _updateUser(msg.sender);

        // transfer the rewards
        uint256 _rewards = users[msg.sender].rewardDebt;
        users[msg.sender].rewardDebt = 0;

        // transfer
        require(yfiii.transfer(msg.sender, _rewards), "transfer failed");
    }

    // Helper methods:

    /**
     * @dev see a users total rewards. reward_debt + rewards_pending
    */
    function userRewards(address u) public view returns(uint256) {
        return users[u].rewardDebt.add(_pendingRewards(u));
    }

    /**
     * @dev see a users current amount of ydai staked. Alias for users[u].staked
    */
    function userStake(address u) public view returns(uint256) {
        return users[u].staked;
    }

    /**
     * @dev force update yourself to lock in rewards. (This shouldnt need to be called).
    */
    function updateSelf() public {
        _updateUser(msg.sender);
    }

    /**
     *  @dev total DAI balance of this contract
    */
    function balanceDAI() public view returns(uint256) {
        return dai.balanceOf(address(this));
    }

    /**
     *  @dev total YDAI balance
    */
    function balanceYDAI() public view returns(uint256) {
        return ydai.balanceOf(address(this));
    }

    /**
     * @dev withdraw ETH token to a given address.
    */
    function safeWithdrawETH(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    /**
     * @dev dai balance
    */
    function safeWithdrawDAI(address payable to, uint256 amount) public onlyOwner {
        dai.transfer(to, amount);
    }

    /**
     * @dev withdraw an erc20 token to a given address.
     * cannot withdraw yDAI
    */
    function safeWithdrawERC20(address token, address to, uint amount) public onlyOwner {
        // This method is only for removing tokens that were accidentally sent here.
        // Therefore, owner cannot remove ydai, as these are held on behalf of the users.
        require(token != address(ydai), "cannot withdraw ydai");
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev set reward rate. reward rate = rate / reward_min
    */
    function setRewardRate(uint _newRate) public onlyOwner {
        rewardRate = _newRate;
    }

    /**
     * @dev sets minimum stake to recieve rewards
    */
    function setRewardMin(uint _newMin) public onlyOwner {
        rewardMin = _newMin;
    }

    /**
     * @dev sets new admin fee. Must be smaller than adminFeeMax
    */
    function setAdminFee(uint256 _newFee) public onlyOwner {
        require(_newFee < adminFeeMax, "fee must be less than max fee");
        adminFee = _newFee;
    }

    function approve() public onlyOwner {
        dai.approve(address(ydai), 2**256 - 1);
    }

}