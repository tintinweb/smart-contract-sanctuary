/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;

        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract DynamicStaking is Context {
    using SafeMath for uint256;
    using Address for address;

    struct Staker {
        uint256 stakedBalance;
        uint256 stakedReward;
        uint256 stakedTimestamp;
    }

    bool private isActive;

    mapping(address => Staker) public stakers;
    address[] public stakersList;
    address private devX;

    IERC20 public inu;
    IERC20 public rewardToken;
    uint256 public startDate;
    uint256 public duration;
    uint256 public rewardAmount;
    string public name;

    event StakeINU(address user, uint256 amount);
    event UnstakeINU(address user, uint256 amount);
    event Collect(address user, uint256 amount);

    constructor(
        address _inu,
        address _rewardToken,
        address _devX,
        uint256 _duration,
        string memory _name
    ) public {
        inu = IERC20(_inu);
        rewardToken = IERC20(_rewardToken);
        devX = _devX;
        duration = _duration;
        name = _name;
    }

    modifier updateRewards() {
        uint256 len = stakersList.length;
        uint256 now_ = now;
        Staker storage user;
        for (uint256 i = 1; i <= len; i++) {
            user = stakers[stakersList[i - 1]];
            user.stakedReward = user.stakedReward.add(
                getReward(stakersList[i - 1])
            );
            user.stakedTimestamp = now_;
        }
        _;
    }

    function getStakedBalance(address sender) public view returns (uint256) {
        return stakers[sender].stakedBalance;
    }

    function getRate() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function getStatus() public view returns (bool) {
        return isActive;
    }

    function setRewardAmount() external updateRewards {
        require(_msgSender() == devX, "Only Dev");
        rewardAmount = rewardToken.balanceOf(address(this));
        startDate = now;
    }

    function getReward(address account) public view returns (uint256) {
        Staker memory user = stakers[account];
        uint256 currentReward = stakers[account].stakedReward;
        uint256 totalStaked = inu.balanceOf(address(this));

        if (
            getStakedBalance(account) == 0 ||
            now >= (startDate + duration) ||
            totalStaked == 0 ||
            !getStatus()
        ) {
            return currentReward;
        }

        uint256 currentStaked = user.stakedBalance;
        uint256 timeRemaining = now.sub(user.stakedTimestamp);
        currentStaked = currentStaked.mul(timeRemaining).mul(rewardAmount);
        currentStaked = currentStaked.div(totalStaked).div(duration);

        return currentReward.add(currentStaked);
    }

    function setActive(bool bool_) external {
        require(_msgSender() == devX, "Not Dev");
        require(isActive != bool_);
        isActive = bool_;
    }

    function stakeINU(uint256 _amount) external updateRewards {
        require(isActive, "Not Active!");
        require(_amount > 0, "No negative staking");
        require(
            inu.balanceOf(_msgSender()) >= _amount,
            "Insufficient Amount In Balance"
        );

        Staker storage user = stakers[_msgSender()];

        uint256 balanceNow = inu.balanceOf(address(this));
        inu.transferFrom(_msgSender(), address(this), _amount);
        uint256 receivedBalance = inu.balanceOf(address(this)).sub(balanceNow);

        uint256 poolFee = receivedBalance.div(100);
        inu.transfer(devX, poolFee);

        receivedBalance = receivedBalance.sub(poolFee);

        user.stakedReward = getReward(_msgSender());
        user.stakedBalance = user.stakedBalance.add(receivedBalance);
        user.stakedTimestamp = now;

        emit StakeINU(_msgSender(), receivedBalance);
    }

    function unstakeINU(uint256 _amount) external updateRewards {
        Staker storage user = stakers[_msgSender()];

        require(_amount > 0, "No negative withdraw");
        require(
            user.stakedBalance >= _amount,
            "Insufficient Amount in Balance"
        );

        if (getReward(_msgSender()) > 0) {
            collectReward();
        } else {
            user.stakedReward = getReward(_msgSender());
            user.stakedTimestamp = now;
        }

        user.stakedBalance = user.stakedBalance.sub(_amount);

        if (inu.balanceOf(address(this)) < _amount) {
            inu.transfer(_msgSender(), inu.balanceOf(address(this)));
        } else {
            inu.transfer(_msgSender(), _amount);
        }

        emit UnstakeINU(_msgSender(), _amount);
    }

    function collectReward() public {
        Staker storage user = stakers[_msgSender()];
        uint256 reward = getReward(_msgSender());
        require(reward > 0, "No Rewards in Balance");

        if (reward >= rewardToken.balanceOf(address(this))) {
            rewardToken.transfer(
                _msgSender(),
                rewardToken.balanceOf(address(this))
            );
        } else {
            rewardToken.transfer(_msgSender(), reward);
        }

        user.stakedReward = 0;
        user.stakedTimestamp = now;

        emit Collect(_msgSender(), reward);
    }
}