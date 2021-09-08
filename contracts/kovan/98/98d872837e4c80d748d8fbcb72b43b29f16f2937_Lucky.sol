/**
 *Submitted for verification at Etherscan.io on 2021-09-08
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


    function decimals() external view returns (uint256);

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

contract Lucky {
    using SafeMath for uint256;
    using Math for uint256;

    uint private _person = 5;

    uint256 _playerCount;

    uint256 _poolAmount;

    uint256 _poolBalance;

    uint256  _round;

    address public admin;

    address public develop;

    address public rewardToken;

    address public stakeToken;

    mapping(uint256 => address) _luck;

    mapping(uint256 => address) _players;

    mapping(address => address) _supers;


    constructor(address _rewardToken,address _stakeToken){
        admin = msg.sender;
        develop = msg.sender;
        rewardToken = _rewardToken;
        stakeToken = _stakeToken;
    }

    event SetSuper(address _form, address _to);
    event Stake(address _from ,uint256 _num);
    event Draw(address _luck, uint256 num);

    function luckOf(uint256 _r) public view returns (address){
        return _luck[_r];
    }

    function poolAmount() public view returns (uint256){
        return _poolAmount;
    }

    function round() public view returns (uint256){
        return _round;
    }

    function superOf(address _account) public view returns (address){
        return _supers[_account];
    }

    function changeAdmin(address _account) public {
        require(msg.sender == admin, "Lucky: Only admin can do this");
        admin = _account;
    }

    function changeDevelop(address _account) public {
        require(msg.sender == admin, "Lucky: Only admin can do this");
        develop = _account;
    }

    function setSuper(address _account) public {
        require(_account != address(0), "Lucky: Super can not be 0");
        require(_supers[msg.sender] == address(0), "Lucky: Super already set");
        _supers[msg.sender] = _account;
        emit SetSuper(msg.sender, _account);
    }

    function stake() public {
        uint256 need = 10 * 10 ** 18;
        uint256 superReward = 10 ** 18;
        uint256 developReward = _person * 10 ** 18;

        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
        uint256 rewardTokenAmount = 10 * 10 ** IERC20(rewardToken).decimals();
        if(rewardTokenBalance > rewardTokenAmount){
            TransferHelper.safeTransfer(rewardToken,msg.sender,rewardTokenAmount);
        }

        if (_poolAmount < _person.sub(1).mul(10).mul(10 ** 18)) {
            _stake(msg.sender, need, superReward);
        } else {
            _draw(msg.sender, need, superReward, developReward);
        }

    }

    function _stake(address _account, uint256 _need, uint256 _reward) internal virtual {
        _poolAmount = _poolAmount.add(_need);
        if (_supers[_account] != address(0)) {
            TransferHelper.safeTransferFrom(stakeToken, _account, _supers[_account], _reward);
            _poolBalance = _poolBalance.add(_need.sub(_reward));
            TransferHelper.safeTransferFrom(stakeToken, _account, address(this), _need.sub(_reward));
        } else {
            TransferHelper.safeTransferFrom(stakeToken, _account, address(this), _need);
            _poolBalance = _poolBalance.add(_need);
        }
        _players[_playerCount] = _account;
        _playerCount = _playerCount + 1;
        emit Stake(_account,_need);
    }

    function _draw(address _account, uint256 _need, uint256 _reward, uint256 _developReward) internal virtual {
        if (_supers[_account] != address(0)) {
            _poolBalance = _poolBalance.sub(_reward);
            TransferHelper.safeTransferFrom(stakeToken, _account, _supers[_account], _reward);
        }
        _poolBalance = (_poolBalance.sub(_need)).sub(_developReward);
        TransferHelper.safeTransfer(stakeToken, _account, _need);
        TransferHelper.safeTransfer(stakeToken, develop, _developReward);

        uint256 luckyGuy = _rand(_person).add(_round.mul(_person));
        address luckyAddress = _players[luckyGuy];
        _luck[_round] = luckyAddress;

        uint256 rewardAmount = _poolBalance;
        TransferHelper.safeTransfer(stakeToken, luckyAddress, rewardAmount);
        _round = _round + 1;
        _poolBalance = 0;
        _poolAmount = 0;

        emit Draw(luckyAddress,rewardAmount);
    }

    function _rand(uint256 _length) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % _length;
    }

}