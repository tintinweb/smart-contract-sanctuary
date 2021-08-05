/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// Dependency file: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

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

// Dependency file: contracts/libraries/TransferHelper.sol


// pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/modules/BaseRewardField.sol

// pragma solidity >=0.6.6;
// import 'contracts/libraries/SafeMath.sol';
// import 'contracts/libraries/TransferHelper.sol';

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}

contract BaseRewardField {
    using SafeMath for uint;
    
    uint public totalProductivity;
    uint public accAmountPerShare;
    
    uint public totalShare;
    uint public mintedShare;
    uint public mintCumulation;
    
    uint public lastRewardBlock;
    uint public amountPerBlock;
    
    uint private unlocked = 1;
    address public shareToken;
    
    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }

    mapping(address => UserInfo) public users;
    
    function _setShareToken(address _shareToken) internal {
        shareToken = _shareToken;
    }
    
    function _changeAmountPerBlock(uint value) internal returns (bool) {
        uint old = amountPerBlock;
        require(value != old, 'AMOUNT_PER_BLOCK_NO_CHANGE');
        _update();
        amountPerBlock = value;
        return true;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (totalProductivity == 0) {
            lastRewardBlock = block.number;
            return;
        }
        
        uint256 reward = _currentReward();
        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        totalShare += reward;
        lastRewardBlock = block.number;
    }
    
    function _currentReward() internal virtual view returns (uint) {
        uint256 multiplier = block.number.sub(lastRewardBlock);
        uint reward =  multiplier.mul(amountPerBlock);
        if(IERC20(shareToken).balanceOf(address(this)) < reward) {
            return IERC20(shareToken).balanceOf(address(this));
        } else {
            return reward;
        }
    }
    
    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function _increaseProductivity(address user, uint value) internal virtual returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseProductivity(address user, uint value) internal virtual returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _update();
        _audit(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);
        
        return true;
    }
    
    function _takeWithAddress(address user) internal view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (totalProductivity != 0) {
            uint reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function _mint(address user) internal virtual lock returns (uint) {
        _update();
        _audit(user);
        require(users[user].rewardEarn > 0, "NOTHING TO MINT REWARD");
        uint amount = users[user].rewardEarn;
        TransferHelper.safeTransfer(shareToken, msg.sender, amount);
        users[user].rewardEarn = 0;
        mintedShare += amount;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) public virtual view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() public virtual view returns (uint) {
        return accAmountPerShare;
    }
}

// Root file: contracts/AAAAReward.sol

pragma solidity >=0.5.16;
// import 'contracts/modules/BaseRewardField.sol';

contract AAAAReward is BaseRewardField {
    
    address public owner;
    address public stakeToken;
    
    event ProductivityIncreased (address indexed user, uint value);
    event ProductivityDecreased (address indexed user, uint value);
    event Mint(address indexed user, uint amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address _owner) external {
        require(msg.sender == owner, "FORBIDDEN");
        owner = _owner;
    }
    
    function changeAmountPerBlock(uint value) external {
        require(msg.sender == owner, "FORBIDDEN");
        _changeAmountPerBlock(value);
    }
    
    function initialize(address _stakeToken, address _shareToken) external {
        require(msg.sender == owner, "FORBIDDEN");
        stakeToken = _stakeToken;
        _setShareToken(_shareToken);
    }
    
    function extract(uint _amount) external {
        require(msg.sender == owner, "FORBIDDEN");
        TransferHelper.safeTransfer(shareToken, msg.sender, _amount);
    }
    
    function stake(uint _amount) external {
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), _amount);
        _increaseProductivity(msg.sender, _amount);
        emit ProductivityIncreased(msg.sender, _amount);
    }
    
    function withdraw(uint _amount) external {
        _decreaseProductivity(msg.sender, _amount);
        TransferHelper.safeTransfer(stakeToken, msg.sender, _amount);
        emit ProductivityDecreased(msg.sender, _amount);
    }
    
    function queryReward() external view returns (uint){
        return _takeWithAddress(msg.sender);
    }
    
    function mintReward() external {
        uint amount = _mint(msg.sender);
        emit Mint(msg.sender, amount);
    }
}