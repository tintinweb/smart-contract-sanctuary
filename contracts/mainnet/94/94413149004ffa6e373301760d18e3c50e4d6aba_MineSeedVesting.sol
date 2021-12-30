/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MineSeedVesting {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public startDate = 1646092801; // 2022-03-01 00:00:01

    uint256 public endDate =   1669852801; // 2022-12-01 00:00:01
    
    uint256 public unlockAmountTotal;
    
    uint256 public tokenDecimals;
    
    uint256 public maxUnlockTimes;

    address msgSender;
    
    mapping(address => UserVestingInfo) public UserVesting;

    struct UserVestingInfo {
        uint256 totalAmount;
        uint256 firstAmount;
        uint256 unlockAmount;
        uint256 secondUnlock;
        uint256 lastUnlockTime;
    }

    event FirstBySenderEvent(address indexed sender, uint256 amount);

    event UnlockBySenderEvent(address indexed sender, uint256 amount);

    constructor(address _token) public {
        msgSender = msg.sender;
        token = IERC20(_token);
        tokenDecimals = token.decimals();
        maxUnlockTimes = endDate.sub(startDate);
        //add user vesting
        addUserVestingInfo(0x0051437667689B36f9cFec31E4F007f1497c0F98, 10_000_000);
        addUserVestingInfo(0x01b0743d28db13a5F6019B482070b5e22C44F25D, 791_667);
        addUserVestingInfo(0x05404219D412C7B5A986Be58BC3a4ee3cE56d6ca, 1_375_000);
        addUserVestingInfo(0x0BaBd8774f4FB8904184b0965204e5A9Db43aCfe, 2_000_000);
        addUserVestingInfo(0x16E110beD33c0445BE68B957cbbef5cd7e1BBD4f, 1_583_333);
        addUserVestingInfo(0x1a62BF05796d0Ae7ee0600a2F33Cd2d2d2F826D1, 2_216_667);
        addUserVestingInfo(0x21d426655A41c0874048DD0a3E29B1cFF5Ec5FB6, 791_667);
        addUserVestingInfo(0x33684C973d118028Bf971A17434A862F3A3E5eb6, 633_333);
        addUserVestingInfo(0x3904eFc39b16e9CE6483E8bEAC623fca370286D1, 5_000_000);
        addUserVestingInfo(0x4d883824258f7253101f266a23207DCb2Dd45768, 1_583_333);
        addUserVestingInfo(0x51bb5e198C1899516a101E15088626811bd04108, 1_900_000);
        addUserVestingInfo(0x52611C224e44867Ca611cFA0D05535d7ba07dC55, 1_666_667);
        addUserVestingInfo(0x52c23f3F1b0c44C5285540f183C129c6eF169e63, 791_667);
        addUserVestingInfo(0x5526AE8332fC020A827eE7798584A9E05765a6aa, 1_583_333);
        addUserVestingInfo(0x58a252cc4073daCC7eaE81e7Ea193FAA13099849, 15_604_167);
        addUserVestingInfo(0x60bae59D2b56069F7Ad2A6B8CbdB08c1c67951F7, 3_166_667);
        addUserVestingInfo(0x6e4116462a0abE7A5e75dD66e44A1cBB6b2006F1, 791_667);
        addUserVestingInfo(0x71d1f0a05F82c0EBd02b8704E3d2337b517a6B3A, 6_166_666);
        addUserVestingInfo(0x7d614762E9E8a716f6889C4158f3392986BbbcA3, 791_667);
        addUserVestingInfo(0x8663381606Edfc0F2d5136f7e763b91A6d76ed22, 791_667);
        addUserVestingInfo(0x91406B5d57893E307f042D71C91e223a7058Eb72, 791_667);
        addUserVestingInfo(0x9d6edF1e6B74b16B9E049d970E9489eDEFFB654B, 791_667);
        addUserVestingInfo(0x9E6d8980BC9fc98c5d2db48c46237d12d9873ab0, 3_166_667);
        addUserVestingInfo(0xaa3238003BD3D90Ba5C4A3d1A53553F44219F2B0, 3_166_667);
        addUserVestingInfo(0xb5018Bc174321fFE9e0A38d262e9A448FBD21cdb, 2_375_000);
        addUserVestingInfo(0xB8D61dc88c4cb9e4590992a2e3a70bd75a187989, 6_833_333);
        addUserVestingInfo(0xBA2F8710a3FeecCf53f50b22bA0e5b5D230Eb343, 6_333_333);
        addUserVestingInfo(0xBC89f9389aD2207E08E2Dfe2cE1a0238a6cDfAcd, 19_991_666);
        addUserVestingInfo(0xC59c15C93f9aA3c381c76c7Af84fa09E615e765B, 50_000);
        addUserVestingInfo(0xD2Ef10da66727627C68bEd148e881C923C1baA77, 666_666);
        addUserVestingInfo(0xDE5E5AdBA79dB5f84579743e7a26728FA8f4E8d8, 4_166_666);
        addUserVestingInfo(0xf7B496c0178b1Ee935ea3307188B5b1FbB0cDa59, 1_187_500);
        addUserVestingInfo(0xa5013Bce0182E74FfEf440B3B5dd7173ddCb52cE, 500_000);
    }

    function addUserVestingInfo(address _address, uint256 _totalAmount) public {
        require(msgSender == msg.sender, "You do not have permission to operate");
        require(_address != address(0), "The lock address cannot be a black hole address");
        UserVestingInfo storage _userVestingInfo = UserVesting[_address];
        require(_totalAmount > 0, "Lock up amount cannot be 0");
        require(_userVestingInfo.totalAmount == 0, "Lock has been added");
        _userVestingInfo.totalAmount = _totalAmount.mul(10 ** tokenDecimals);
        _userVestingInfo.firstAmount = _userVestingInfo.totalAmount.mul(10).div(100); //10%
        _userVestingInfo.secondUnlock = _userVestingInfo.totalAmount.sub(_userVestingInfo.firstAmount).div(maxUnlockTimes);
        unlockAmountTotal = unlockAmountTotal.add(_userVestingInfo.totalAmount);
    }

    function blockTimestamp() public virtual view returns(uint256) {
        return block.timestamp;
    }

    function getUnlockTimes() public virtual view returns(uint256) {
        if(blockTimestamp() > startDate) {
            return blockTimestamp().sub(startDate);
        } else {
            return 0;
        }
    }

    function unlockFirstBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        require(_userVestingInfo.firstAmount > 0, "The user has unlocked the first token");
        require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has unlocked the first token");
        require(blockTimestamp() > startDate, "It's not time to lock and unlock");
        _safeTransfer(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(_userVestingInfo.firstAmount);

        emit FirstBySenderEvent(msg.sender, _userVestingInfo.firstAmount);
        _userVestingInfo.firstAmount = 0;
    }

    function unlockBySender() public {
        UserVestingInfo storage _userVestingInfo = UserVesting[msg.sender];
        require(_userVestingInfo.totalAmount > 0, "The user has no lock record");
        uint256 unlockAmount = 0;
        if(blockTimestamp() > endDate) {
            require(_userVestingInfo.totalAmount > _userVestingInfo.unlockAmount, "The user has no unlocked quota");
            unlockAmount = _userVestingInfo.totalAmount.sub(_userVestingInfo.unlockAmount);
        } else {
            uint256 unlockTimes = getUnlockTimes();
            require(unlockTimes > _userVestingInfo.lastUnlockTime, "The user has no lock record");
            unlockAmount = unlockTimes.sub(_userVestingInfo.lastUnlockTime).mul(_userVestingInfo.secondUnlock);
            _userVestingInfo.lastUnlockTime = unlockTimes;
        }
        _safeTransfer(msg.sender, unlockAmount);
        _userVestingInfo.unlockAmount = _userVestingInfo.unlockAmount.add(unlockAmount);

        emit UnlockBySenderEvent(msg.sender, unlockAmount);
    }

    function _safeTransfer(address _unlockAddress, uint256 _unlockToken) private {
        require(balanceOf() >= _unlockToken, "Insufficient available balance for transfer");
        token.transfer(_unlockAddress, _unlockToken);
    }

    function balanceOf() public view returns(uint256) {
        return token.balanceOf(address(this));
    }

    function balanceOfBySender() public view returns(uint256) {
        return token.balanceOf(msg.sender);
    }

    function balanceOfByAddress(address _address) public view returns(uint256) {
        return token.balanceOf(_address);
    }
}