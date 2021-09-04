/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

pragma solidity ^0.8.0;


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

library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

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
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Defil {
    using SafeMath for uint256;
    using Math for uint256;

    address public admin;

    address  public stakeToken;

    address  public rewardToken;

    uint256 private _duration = 365;

    mapping(uint256 => uint256) private _rates;

    struct book {
        uint256 day;
        uint256 amount;
        uint256 endTime;
        uint256 rewardTime;
        bool status;
        uint256 interest;
        uint256 reward;
    }

    mapping(address => book[]) private _userBook;


    constructor(address _stakeToken, address _rewardToken)  {
        admin = msg.sender;
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        _rates[90] = 1;
        _rates[180] = 2;
        _rates[360] = 4;
        _rates[540] = 6;
    }

    event Staked(address indexed user, uint256 amount, uint256 day);
    event Withdraw(address indexed user, uint256 amount);
    event GetReward(address indexed user, uint256 amount);


    function bookOf(address account) public view returns (book[] memory){
        return _userBook[account];
    }

    function rewardBalance(address account) public view returns (uint256){
        uint256 _reward;
        for (uint i = 0; i < _userBook[account].length; i++) {_reward = _reward.add(_singleBookReward(_userBook[account][i]));}
        return _reward;
    }

    function stake(uint256 amount, uint256 day, uint256 reward) public {
        require(day == 90 || day == 180 || day == 360 || day == 540, "Pool: day error");
        require(amount > 0, "Pool: Can't stake 0");
        uint256 _in = _interest(amount, day);
        _userBook[msg.sender].push(book(day, amount, block.timestamp.add(day.mul(86400)), block.timestamp, true, _in, reward));
        TransferHelper.safeTransferFrom(stakeToken, msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, day);
    }

    function withdraw(uint256 index) public {
        require(_userBook[msg.sender].length > index, "Pool: index error");
        book memory b = _userBook[msg.sender][index];
        require(b.status == true, "Pool: already withdraw");
        _userBook[msg.sender][index].status = false;
        _userBook[msg.sender][index].endTime = block.timestamp;

        uint256 _amount;
        if (block.timestamp < b.endTime) {
            _amount = b.amount.mul(95).div(100);
        } else {
            _amount = b.amount.add(b.interest);
        }
        TransferHelper.safeTransfer(stakeToken, msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    function withdrawAll() public {
        require(_userBook[msg.sender].length > 0, "Pool: no stakes");
        uint256 _amount;
        for (uint i = 0; i < _userBook[msg.sender].length; i++) {
            book memory b = _userBook[msg.sender][i];
            if (b.status == true) {
                if (block.timestamp < b.endTime) {
                    _amount = _amount.add(b.amount.mul(95).div(100));
                } else {
                    _amount += _amount.add(b.amount.add(b.interest));
                }
            }
            _userBook[msg.sender][i].status = false;
            _userBook[msg.sender][i].endTime = block.timestamp;
        }
        if(_amount > 0){
            TransferHelper.safeTransfer(stakeToken, msg.sender, _amount);
            emit Withdraw(msg.sender,_amount);
        }
    }

    function getReward() public {
        uint256 reward = rewardBalance(msg.sender);
        require(reward > 0, "Pool: no remain reward");
        for (uint i = 0; i < _userBook[msg.sender].length; i++) {_userBook[msg.sender][i].rewardTime = block.timestamp;}
        TransferHelper.safeTransfer(rewardToken, msg.sender, reward);
        emit GetReward(msg.sender, reward);
    }

    function _interest(uint256 amount, uint256 day) private view returns (uint256){
        return amount.mul(_rates[day]).div(100).mul(day).div(360);
    }

    function _singleBookReward(book memory b) private view returns (uint256){
        if(b.status == false){
            return 0;
        }
        uint256 _endTime = Math.min(block.timestamp, b.endTime);
        if (_endTime <= b.rewardTime) {
            return 0;
        }
        return _endTime.sub(b.rewardTime).div(86400).mul(b.reward).div(365);
    }
}