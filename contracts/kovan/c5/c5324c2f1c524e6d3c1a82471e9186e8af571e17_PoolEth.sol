/**
 *Submitted for verification at Etherscan.io on 2021-03-22
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
contract PoolEth {
    using SafeMath for uint256;

    address public admin;

    address public rewardToken;

    uint256 public totalReward;

    uint256 public startTime;
    uint256 public endTime;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 private _totalWeight;
    uint256 private _timeRecord;
    mapping(address => uint256) private _weights;
    mapping(address => uint256) private _userTimeRecord;

    constructor(address _rewardToken, uint256 _start, uint256 _end, uint256 _totalReward) public {
        admin = msg.sender;
        rewardToken = _rewardToken;
        startTime = _start;
        endTime = _end;
        totalReward = _totalReward;
    }

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event GetRewarded(address indexed user, uint256 amount);

    modifier updateWeight(address account) {
        _totalWeight = _totalWeight.add(block.timestamp.sub(_timeRecord).mul(_totalSupply));
        _weights[account] = _weights[account].add(block.timestamp.sub(_userTimeRecord[account]).mul(_balances[account]));
        _timeRecord = block.timestamp;
        _userTimeRecord[account] = block.timestamp;
        _;
    }

    function _rewardRate() private returns (uint256){
        return totalReward.div(endTime.sub(startTime));
    }

    function _getEnd() private returns (uint256){
        return Math.min(block.timestamp, endTime);
    }

    function _periodReward() private returns (uint256){
        return _rewardRate().mul(_getEnd().sub(startTime));
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256){
        return _balances[account];
    }


    function totalWeight() public returns (uint256){
        return _totalWeight.add(_getEnd().sub(_timeRecord).mul(_totalSupply));
    }

    function weightOf(address account) public returns (uint256){
        return _weights[account].add(_getEnd().sub(_userTimeRecord[account]).mul(_balances[account]));
    }


    function earn(address account) public returns (uint256){
        return _periodReward().mul(weightOf(account)).div(totalWeight());
    }

    function stake() public payable updateWeight(msg.sender) {
        require(block.timestamp >= startTime, "Pool: Have not started");
        require(block.timestamp < endTime, "Pool: Already end");
        require(msg.value > 0, "Pool: Can not stake 0");
        _totalSupply = _totalSupply.add(msg.value);
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint amount) public updateWeight(msg.sender) {
        require(amount > 0, "Pool: Can not withdraw 0");
        require(_balances[msg.sender] >= amount, "Pool: Withdraw number exceeded");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.call{value:amount,gas:21000}("");
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public {
        uint256 reward = earn(msg.sender);
        if (reward > 0) {
            _weights[msg.sender] = 0;
            _userTimeRecord[msg.sender] = block.timestamp;
            TransferHelper.safeTransfer(rewardToken, msg.sender, reward);
            emit GetRewarded(msg.sender, reward);
        }
    }
}