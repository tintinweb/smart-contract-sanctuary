// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/Manageable.sol";

// TokenRelease is used to release tokens by plans
// There is two phases, as following
// -------------------------------------------------------------------------
//                         startBlock (begin the release)
//                              |
// |----config phase------------|-------------release phase-----------------|
//                              |
//           no release         |              can not config
//

contract TokenRelease is Manageable {
     using SafeERC20 for IERC20;
     using SafeMath for uint256;

    event EmergencyWithdraw(address indexed token, uint256 balance);
    event SetEmergencyAddress(address indexed emergencyAddress);
    event SetUser(address indexed user, uint256 indexed rid, uint256 amount);
    event WithdrawTge(address indexed _user, uint256 indexed _rid, uint256 pendingAmount);
    event WithdrawRelease(address indexed _user, uint256 indexed _rid, uint256 pendingAmount);

    enum ReleaseType {
        PRE_SEED,
        SEED,
        PRIVATE_I,
        PRIVATE_II,
        LAUNCH_PAD,
        STRATEGY,
        ADVISOR,
        TEAM
    }

    struct ReleasePlan {
        ReleaseType releaseType;

        uint256 total;                 // Total MGA
        uint256 tge;                   // TGE percentage
        uint256[] schedules;           // Release percentage each epoch
        uint256 lockPeriod;            // Total lock blocks
        uint256 blocksPerReleaseUnit;  // Blocks in each release epoch

        uint256 accMGAPerShare;        // Accumulated MGAs per share, times 1e12.
        uint256 lastReleaseBlock;      // 
        uint256 totalUserAmount;       // totalUserAmount is the sum of users' amount, totalUserAmount == total
        uint256 totalRelease;          // released amount
        uint256 totalWithdraw;         // user withdrawed amount
    }

    struct UserInfo {
        uint256 amount;                // The amount MGA user should get in total, used to calc the percentage of 
                                       // tgeAmount+releaseAmount <= amount
        uint256 rewardDebt;            //
        uint256 tgeAmount;             // tge amount already got 
        uint256 releaseAmount;         // release amount already got
        uint256 index;
    } 

    ReleasePlan[] public releasePlan;

    // rid --> user --> UserInfo
    mapping(uint256=>mapping(address=>UserInfo)) public userInfo;
    
    // rid --> users
    mapping(uint256=>address[]) public users;

    mapping(address=>uint256) private user2Rid;

    mapping(ReleaseType=>uint256) private rt2Rid;

    address public mga;

    uint256 public startBlock;

    uint256 public constant BLOCK_PER_TIME_UNIT = 3 * 20 * 24; //time uint is day, one block every 3 seconds

    address public emergencyAddress;

    bool public initialized = false;

    modifier onlyInitializing() {
        require(initialized == false, "TokenRelease: INITIALIZED");
        _;
    }

    modifier onlyInitialized() {
        require(initialized == true, "TokenRelease: INITIALIZING");
        _;
    }

    constructor(address _mga, 
        uint256 _startBlock, 
        address _emergencyAddress) {
        require(_mga != address(0), "TokenRelease: ZERO_ADDRESS");
        require(block.number < _startBlock, "TokenRelease: INVALID_START");
        require(_emergencyAddress != address(0), "TokenRelease: ZERO_ADDRESS");

        mga = _mga;
        startBlock = _startBlock;
        emergencyAddress = _emergencyAddress;
    }

    function getUsersLength(uint256 _rid) public view returns(uint256) {
        return users[_rid].length;
    }

    function getReleasePlanLength() public view returns(uint256) {
        return releasePlan.length;
    }

    function getBlockPerTimeUnit() public pure returns(uint256) {
        return BLOCK_PER_TIME_UNIT;
    }

    function planTotal() public view returns(uint256) {
        uint256 length = releasePlan.length;
        uint256 total;

        for(uint256 i=0; i<=length; i++) {
            total = total.add(releasePlan[i].total);
        }
        return total;
    }

    function releaseTotal() public view returns(uint256) {
        uint256 length = releasePlan.length;
        uint256 total;

        for(uint256 i=0; i<=length; i++) {
            total = total.add(releasePlan[i].totalRelease);
        }
        return total;
    }

    function withdrawTotal() public view returns(uint256) {
        uint256 length = releasePlan.length;
        uint256 total;

        for(uint256 i=0; i<=length; i++) {
            total = total.add(releasePlan[i].totalWithdraw);
        }
        return total;
    }

    function isBalanceEnough() public view returns(bool) {
        return IERC20(mga).balanceOf(address(this)) >= planTotal().sub(withdrawTotal());
    }

    function checkSchedules(uint256 _tge, uint256[] memory _schedules) internal pure {
        uint256 sum = _tge;
        for(uint256 i=0; i<_schedules.length; i++) {
            sum = sum.add(_schedules[i]);
        }
        require(sum == 100, "TokenRelease: INVALID_SCHEDULE");
    }

    function  checkPrerequisites() public view {
        // Not Start
        require(initialized == false, "TokenRelease: INITIALIZED");
        //All Release Plan Configured
        require(releasePlan.length==8, "TokenRelease: INVALID_RELEASE");
        //Balance Is Enough
        require(planTotal() <= IERC20(mga).balanceOf(address(this)), "TokenRelease: BALANCE_NOT_ENOUGH");
        //Release Plan: total == totalUserAmount, configured user info
        uint256 length = releasePlan.length;
        for(uint256 i=0; i<length; i++) {
            ReleasePlan storage release = releasePlan[i];
            require(release.total == release.totalUserAmount, "ToKenRelease: WRONG_USER_AMOUNT");
        }

        require(block.number < startBlock, "TokenRelease: TIME_OUT");
    }

    function start() public onlyOwner {
        checkPrerequisites();
        initialized = true;
    }

    function addRelease(
        ReleaseType _releaseType,
        uint256 _total,
        uint256 _tge,
        uint256[] memory _schedules,
        uint256 _lockDays,
        uint256 _releaseDays) public onlyOwner onlyInitializing  {
        require(!isReleaseExist(_releaseType), "TokenRelease: ALREADY_EXIST");
        require(_total > 0,                    "TokenRelease: INVALID_TOTAL");
        require(_releaseDays > 0,              "TokenRelease: INVALID_DAY");
        checkSchedules(_tge, _schedules);

        uint256 startPoint = startBlock.add(_lockDays.mul(BLOCK_PER_TIME_UNIT));

        releasePlan.push(ReleasePlan({
            releaseType             : _releaseType,
            total                   : _total,
            tge                     : _tge,
            schedules               : _schedules,
            lockPeriod              : _lockDays.mul(BLOCK_PER_TIME_UNIT),
            blocksPerReleaseUnit    : _releaseDays.mul(BLOCK_PER_TIME_UNIT),
            accMGAPerShare          : 0,
            lastReleaseBlock        : startPoint,
            totalUserAmount         : 0,
            totalRelease            : _total.mul(_tge).div(100),
            totalWithdraw           : 0
        }));

        rt2Rid[_releaseType] = releasePlan.length;
    }

    function setRelease(ReleaseType _releaseType,
        uint256 _total,
        uint256 _tge,
        uint256[] memory _schedules,
        uint256 _lockDays,
        uint256 _releaseDays) public  onlyOwner onlyInitializing {
        require(isReleaseExist(_releaseType),  "TokenRelease: NOT_EXIST");
        require(_total > 0,                    "TokenRelease: INVALID_TOTAL");
        require(_releaseDays > 0,              "TokenRelease: INVALID_DAY");
        checkSchedules(_tge, _schedules);
        uint256 startPoint = startBlock.add(_lockDays.mul(BLOCK_PER_TIME_UNIT));

        ReleasePlan storage release = releasePlan[getRid(_releaseType)];
        release.total                   = _total;
        release.tge                     = _tge;
        release.schedules               = _schedules;
        release.lockPeriod              = _lockDays.mul(BLOCK_PER_TIME_UNIT);
        release.blocksPerReleaseUnit    = _releaseDays.mul(BLOCK_PER_TIME_UNIT);
        release.lastReleaseBlock        = startPoint;
        release.totalRelease            = _total.mul(_tge).div(100);
    }

    function isReleaseExist(ReleaseType _releaseType) public view returns(bool) {
        return rt2Rid[_releaseType] != uint256(0);
    }

    function isUserExist(address _user) public view returns(bool) {
        return user2Rid[_user] != uint256(0);
    }

    function getRid(ReleaseType _releaseType) public view returns(uint256) {
        require(isReleaseExist(_releaseType), "TokenRelease: NOT_EXIST");
        return rt2Rid[_releaseType]-1;
    }

    function getRid(address _user) public view returns(uint256) {
        require(isUserExist(_user), "TokenRelease: NOT_EXIST");
        return user2Rid[_user]-1;
    }

    function releasePhase(uint256 _rid, uint256 blockNumber) public view returns(uint256) {
        ReleasePlan storage release = releasePlan[_rid];
        if(release.blocksPerReleaseUnit == 0) {
            return 0;
        }

        if (blockNumber > startBlock.add(release.lockPeriod)) {
            return blockNumber.sub(startBlock).sub(release.lockPeriod).sub(1).div(release.blocksPerReleaseUnit).add(1);
        }

        return 0;
    }

    function releaseSpeed(uint256 _rid, uint256 blockNumber) public view returns(uint256) {
        uint256 phase = releasePhase(_rid, blockNumber);

        if(phase > 0) {
            phase = phase-1;
            ReleasePlan storage release = releasePlan[_rid];

            if(phase < release.schedules.length ) {
                uint amount = release.total.mul(release.schedules[phase]).div(100);
                return amount.div(release.blocksPerReleaseUnit);
            }
        }

        return 0;
    }

    //  --------------------------------------------------------------------------------------
    // schedules(x%)          0     | ..............| length-2  |  length-1 | length
    // phase      0     |     1     | ............. | length-1  |  length   | length+1
    //        [X][X][X] | [*][*][*] | ............. | [*][*][*] | [*][*][*] | [X][X][X]
    //

    function getBlockRelease(uint256 _rid) public view returns(uint256) {
        ReleasePlan storage release = releasePlan[_rid];

        uint256 blockRelease = 0;
        uint256 blockNumber = block.number;
        uint256 lastReleaseBlock = release.lastReleaseBlock; 
        uint256 lastPhase = releasePhase(_rid, lastReleaseBlock);
        uint256 curPhase  = releasePhase(_rid, blockNumber);
        uint256 startPoint = startBlock.add(release.lockPeriod);

        if(release.total == 0                     // Invalid release plan 
          || lastPhase > release.schedules.length // release complete
          || curPhase <= 0 ) {                    // release not start
            return 0;
        }

        if(curPhase > release.schedules.length) {
            curPhase = release.schedules.length;
            blockNumber = startPoint.add(release.blocksPerReleaseUnit.mul(curPhase));
        }

        while(lastPhase < curPhase) {
            uint256 endPhaseBlock = startPoint.add(release.blocksPerReleaseUnit.mul(lastPhase));
            blockRelease = blockRelease.add(endPhaseBlock.sub(lastReleaseBlock).mul(releaseSpeed(_rid, endPhaseBlock)));
            lastReleaseBlock = endPhaseBlock;
            lastPhase++;
        }

        blockRelease = blockRelease.add(blockNumber.sub(lastReleaseBlock).mul(releaseSpeed(_rid, blockNumber)));

        return blockRelease;
    }

    function setUser(ReleaseType _releaseType, address _user, uint256 _amount) public onlyOwner onlyInitializing {
        //user not exist or user can exist only in one release plan
        require(!isUserExist(_user) || getRid(_user)==getRid(_releaseType), "TokenRelease: USER_EXIST"); 

        uint256 rid = getRid(_releaseType);
        ReleasePlan storage release = releasePlan[rid];
        UserInfo storage user = userInfo[rid][_user];

        release.totalUserAmount.sub(user.amount).add(_amount);
        user.amount = _amount;
        user.rewardDebt = 0;
        user2Rid[_user] = rid+1;

        if(!isUserExist(_user)) {
            users[rid].push(_user);
            user.index=users[rid].length - 1;
        }

        emit SetUser(_user, rid, _amount);
    } 

    function delUser(ReleaseType _releaseType, address _user) public onlyOwner onlyInitializing {
        uint256 rid = getRid(_releaseType);
        require(getRid(_user)==rid , "TokenRelease: WRONG_USER");

        ReleasePlan storage release = releasePlan[rid];
        UserInfo storage user = userInfo[rid][_user];

        address lastUserAddress = users[rid][users[rid].length-1];
        UserInfo storage lastUser =userInfo[rid][lastUserAddress];

        release.totalUserAmount.sub(user.amount);

        users[rid][user.index] = lastUserAddress;
        lastUser.index = user.index;

        users[rid].pop();
        delete userInfo[rid][_user];
        delete user2Rid[_user];

    }

    function updateRelease(uint256 _rid) public {
        ReleasePlan storage release = releasePlan[_rid];

        if(block.number <= release.lastReleaseBlock) {
            return;
        }

        if(release.total == 0 || release.totalRelease >= release.total) {
            release.lastReleaseBlock = block.number;
            return;
        }

        uint256 blockRelease = getBlockRelease(_rid);
        if(blockRelease <= 0) {
            release.lastReleaseBlock = block.number;
            return;
        }

        //release.totalRelease < release.total && blockRelease >0
        if(blockRelease.add(release.totalRelease) >= release.total) {
            blockRelease = release.total.sub(release.totalRelease);
        }

        release.accMGAPerShare = release.accMGAPerShare.add(blockRelease.mul(1e12).div(release.totalUserAmount));
        release.totalRelease=release.totalRelease.add(blockRelease);
        release.lastReleaseBlock = block.number;
    }

    function withdraw(address _user) public onlyInitialized {
        uint256 rid = getRid(_user);
        updateRelease(rid);
        withdrawTge(rid, _user);
        withdrawRelease(rid, _user);
    }

    function withdrawTge(uint256 _rid, address _user) internal {
        ReleasePlan storage release = releasePlan[_rid];
        UserInfo storage user = userInfo[_rid][_user];

        if(user.amount > 0 && release.tge > 0 && user.tgeAmount <= 0) {
            uint256 pendingAmount = release.total.mul(release.tge).mul(user.amount).div(100).div(release.totalUserAmount);
            safeTransfer(_user, pendingAmount);
            user.tgeAmount = pendingAmount;
            release.totalWithdraw = release.totalWithdraw.add(pendingAmount);
            emit WithdrawTge(_user, _rid, pendingAmount);
        }
    }

    function withdrawRelease(uint256 _rid, address _user) internal {
        ReleasePlan storage release = releasePlan[_rid];
        UserInfo storage user = userInfo[_rid][_user];

        if(user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(release.accMGAPerShare).div(1e12).sub(user.rewardDebt);
            
            if(pendingAmount > 0) {
                uint256 userTgeTotal     = release.total.mul(release.tge).mul(user.amount).div(100).div(release.totalUserAmount);
                uint256 userReleaseTotal = release.total.mul(user.amount).div(release.totalUserAmount).sub(userTgeTotal);

                if(user.releaseAmount < userReleaseTotal ) {
                    if(pendingAmount.add(user.releaseAmount) >= userReleaseTotal) {
                         pendingAmount = userReleaseTotal.sub(user.releaseAmount);
                    }

                    safeTransfer(_user, pendingAmount);
                    user.releaseAmount = user.releaseAmount.add(pendingAmount);
                    release.totalWithdraw = release.totalWithdraw.add(pendingAmount);
                    emit WithdrawRelease(_user, _rid, pendingAmount);
                }
            }
        }

        user.rewardDebt = user.amount.mul(release.accMGAPerShare).div(1e12);
    }

    function pending(address _user) public view returns(uint256)  {
        return pendingTge(_user).add(pendingRelease(_user));
    }

    function pendingTge(address _user) public view returns(uint256) {
        uint256 rid = getRid(_user);
        ReleasePlan storage release = releasePlan[rid];
        UserInfo storage user = userInfo[rid][_user];

        if(user.amount > 0 && release.tge > 0 && user.tgeAmount <= 0) {
            return release.total.mul(release.tge).mul(user.amount).div(100).div(release.totalUserAmount);
        }
        return 0;
    }

    function pendingRelease(address _user) public view returns(uint256) {
        uint256 rid = getRid(_user);
        ReleasePlan storage release = releasePlan[rid];
        UserInfo storage user = userInfo[rid][_user];
        uint256 accMGAPerShare = release.accMGAPerShare;

        if(block.number > release.lastReleaseBlock) {
            uint256 blockRelease = getBlockRelease(rid);
            accMGAPerShare = accMGAPerShare.add(blockRelease.mul(1e12).div(release.totalUserAmount)); 
        }

        return user.amount.mul(accMGAPerShare).div(1e12).sub(user.rewardDebt);
    }

    function pending() public view returns(uint256) {
        return pending(msg.sender);
    }

    function pendingTge() public view returns(uint256) {
        return pendingTge(msg.sender);
    }

    function pendingRelease() public view returns(uint256) {
        return pendingRelease(msg.sender);
    }

    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 balance = IERC20(mga).balanceOf(address(this));
        require(balance >= _amount, "TokenRelease: NOT_ENOUGH");

        IERC20(mga).safeTransfer(_to, _amount);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = IERC20(mga).balanceOf(address(this));
        require(balance > 0, "TokenRelease: ZERO_BALANCE");
        IERC20(mga).safeTransfer(emergencyAddress, balance);
        emit EmergencyWithdraw(mga, balance);
    }

    function setEmergencyAddress(address _emergencyAddress) external onlyOwner {
        require(_emergencyAddress != address(0), "TokenRelease: ZERO_ADDRESS");
        emergencyAddress = _emergencyAddress;
        emit SetEmergencyAddress(_emergencyAddress);
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Manageable is Context {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    mapping(address=>bool) public managers;

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


     modifier onlyManager(){
        require(managers[_msgSender()], "NOT_MANAGER");
        _;
    }

    function addManager(address _manager) public onlyOwner {
        require(_manager != address(0), "ZERO_ADDRESS");
        managers[_manager] = true;
    }
  
    function delManager(address _manager) public onlyOwner {
        require(_manager != address(0), "ZERO_ADDRESS");
        managers[_manager] = false;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}