/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function allowance(address owner, address spender)
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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Pool.sol

contract KawaPool is Ownable {
    struct user {
        uint256 staked;
        uint256 withdrawn;
        uint256[] stakeTimes;
        uint256[] stakeAmounts;
        uint256[] startingAPYLength;
    }
    using SafeMath for uint256;
    uint256 public mintedTokens;
    uint256 public totalStaked;
    uint256[] apys;
    uint256[] apyTimes;
    mapping(address => user) public userList;
    event StakeTokens(address indexed user, uint256 tokensStaked);
    IERC20 stakeToken;
    IERC20 xKawaToken;
    mapping(address => uint256) earlyUnstake;

    constructor(
        address tokenAddress,
        address rewardTokenAddress,
        uint256 initAPY
    ) public {
        stakeToken = IERC20(tokenAddress);
        xKawaToken = IERC20(rewardTokenAddress);
        apys.push(initAPY);
        apyTimes.push(now);
    }

    function userStaked(address addrToCheck) public view returns (uint256) {
        return userList[addrToCheck].staked;
    }

    function userClaimable(address addrToCheck)
        public
        view
        returns (uint256 withdrawable)
    {
        if (xKawaToken.balanceOf(address(this)) > 0) {
            withdrawable = calculateStaked(addrToCheck)
            .add(earlyUnstake[addrToCheck])
            .sub(userList[msg.sender].withdrawn);
            if (withdrawable > xKawaToken.balanceOf(address(this))) {
                withdrawable = xKawaToken.balanceOf(address(this));
            }
        } else {
            withdrawable = 0;
        }
    }

    function changeAPY(uint256 newAPY) external onlyOwner {
        apys.push(newAPY);
        apyTimes.push(now);
    }

    function emergencyWithdraw() external onlyOwner {
        require(
            xKawaToken.transfer(
                msg.sender,
                xKawaToken.balanceOf(address(this))
            ),
            "Emergency withdrawl failed"
        );
    }

    function withdrawTokens() public {
        //remove supplied
        earlyUnstake[msg.sender] = userClaimable(msg.sender);
        require(
            stakeToken.transfer(msg.sender, userList[msg.sender].staked),
            "Stake Token Transfer failed"
        );
        totalStaked = totalStaked.sub(userList[msg.sender].staked);
        delete userList[msg.sender];
    }

    function withdrawReward() public {
        uint256 withdrawable = userClaimable(msg.sender);
        require(
            xKawaToken.transfer(msg.sender, withdrawable),
            "Reward Token Transfer failed"
        );
        userList[msg.sender].withdrawn = userList[msg.sender].withdrawn.add(
            withdrawable
        );
        delete earlyUnstake[msg.sender];
        mintedTokens = mintedTokens.add(withdrawable);
    }

    function claimAndWithdraw() public {
        withdrawReward();
        withdrawTokens();
    }

    function stakeTokens(uint256 amountOfTokens) public {
        totalStaked = totalStaked.add(amountOfTokens);
        require(
            stakeToken.transferFrom(msg.sender, address(this), amountOfTokens),
            "Stake Token Transfer Failed"
        );
        userList[msg.sender].staked = userList[msg.sender].staked.add(
            amountOfTokens
        );
        userList[msg.sender].stakeTimes.push(now);
        userList[msg.sender].stakeAmounts.push(amountOfTokens);
        userList[msg.sender].startingAPYLength.push(apys.length - 1);
        emit StakeTokens(msg.sender, amountOfTokens);
    }

    function calculateStaked(address usercheck)
        public
        view
        returns (uint256 totalMinted)
    {
        totalMinted = 0;
        for (uint256 i = 0; i < userList[usercheck].stakeAmounts.length; i++) {
            //loop through everytime they have staked
            for (
                uint256 j = userList[usercheck].startingAPYLength[i];
                j < apys.length;
                j++
            ) {
                //for the i number of time they have staked, go through each apy times and values since they have staked (which is startingAPYLength)
                if (userList[usercheck].stakeTimes[i] < apyTimes[j]) {
                    //this will happen if there is an APY change after the user has staked, since only after apy change can apy time > user staked time
                    if (userList[usercheck].stakeTimes[i] < apyTimes[j - 1]) {
                        //assuming there are 2 or more apy changes after staking, it will mean user has amount still staked in between the 2 apy
                        totalMinted = totalMinted.add(
                            (
                                userList[usercheck].stakeAmounts[i].mul(
                                    (apyTimes[j].sub(apyTimes[j - 1]))
                                )
                            )
                            .mul(apys[j])
                            .div(10**18)
                        );
                    } else {
                        //will take place on the 1st apy change after staking
                        totalMinted = totalMinted.add(
                            (
                                userList[usercheck].stakeAmounts[i].mul(
                                    (now.sub(apyTimes[j]))
                                )
                            )
                            .mul(apys[j])
                            .div(10**18)
                        );
                    }
                } else {
                    //Will take place only once for each iteration in i, as only once and the first time will apy time < user stake time
                    totalMinted = totalMinted.add(
                        (
                            userList[usercheck].stakeAmounts[i].mul(
                                (now.sub(userList[usercheck].stakeTimes[i]))
                            )
                        )
                        .mul(apys[j])
                        .div(10**18)
                    );
                    //multiplies stake amount with time staked, divided by apy value which gives number of tokens to be minted
                }
            }
        }
    }
}