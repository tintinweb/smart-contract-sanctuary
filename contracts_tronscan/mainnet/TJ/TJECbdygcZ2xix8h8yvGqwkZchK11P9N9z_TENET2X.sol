//SourceUnit: TENET2X.sol

pragma solidity 0.5.8;


import "./math.sol";
import "./safeerc20.sol";
contract TENET2X {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public mytoken = IERC20(0x41D7B1DB907186BF4B058BE15C0FA27314315FEF54);

    uint256 constant public INVEST_MIN_AMOUNT = 50000000;
    uint256 constant public BASE_PERCENT = 30;
    uint256[] public REFERRAL_PERCENTS = [100, 50, 20, 10];
    uint256 constant public PROJECT_FEE = 100;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    address payable public projectAddress;

    struct Deposit {
        uint256 amount; 
        uint256 withdrawn;
        uint256 start;
    }
    struct Bonons {
        uint256 amount;
        uint256 rate;
        uint256 start;
        uint256 level; 
        uint256 withdrawn;
    }

    struct User {
        Deposit[] deposits;  
        uint256 checkpoint;
        address referrer;
        Bonons[] bonusArr;  
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable projectAddr) public {
        require(!isContract(projectAddr));
        projectAddress = projectAddr;
    }

    function getTotalUsers() public view returns(uint256) {
        return totalUsers;
    }
    function getTotalInvested() public view returns(uint256) {
        return totalInvested;
    }

    function invest(address referrer, uint256 amount) public payable {
        require(amount >= INVEST_MIN_AMOUNT);
        amount = amount.mul(1e12);
        mytoken.safeTransferFrom(msg.sender, projectAddress, amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        mytoken.safeTransferFrom(msg.sender, address(this), amount.sub(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)));
        
        emit FeePayed(msg.sender, amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

        User storage user = users[msg.sender];

        if (user.deposits.length == 0 && user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
        uint256 refAmount = 0;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 76; i++) {
                if (upline != address(0)) {
                    uint256 index = i <= 3 ? i : 3;
                    uint256 refPercen = REFERRAL_PERCENTS[index];
                    uint256 amount = amount.mul(refPercen).div(PERCENTS_DIVIDER);
                    refAmount = refAmount + amount;
                    users[upline].bonusArr.push(Bonons(amount, refPercen, block.timestamp, i, 0));
                    emit RefBonus(upline, msg.sender, index, amount);
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }
        refAmount = refAmount <= amount ? refAmount : amount;
        user.deposits.push(Deposit(amount, 0, block.timestamp));

        totalInvested = totalInvested.add(amount);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, amount);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = 0;
        uint256 dividends = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {
                uint256 userPercentRate = getUserPercentRate(msg.sender);
                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        uint256 totalDividends2 = 0;
        uint256 dividends2 = 0;
        for (uint256 i = 0; i < user.bonusArr.length; i++) {

            if (user.bonusArr[i].withdrawn < user.bonusArr[i].amount.mul(2)) {

                if (user.bonusArr[i].start > user.checkpoint) {

                    dividends2 = (user.bonusArr[i].amount.mul(user.bonusArr[i].rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.bonusArr[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends2 = (user.bonusArr[i].amount.mul(user.bonusArr[i].rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.bonusArr[i].withdrawn.add(dividends2) > user.bonusArr[i].amount.mul(2)) {
                    dividends2 = (user.bonusArr[i].amount.mul(2)).sub(user.bonusArr[i].withdrawn);
                }
                user.bonusArr[i].withdrawn = user.bonusArr[i].withdrawn.add(dividends2); /// changing of storage data
                totalDividends2 = totalDividends2.add(dividends2);

            }

        }

        totalAmount = totalAmount.add(totalDividends2);

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = getContractBalance();
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        // 发送提成
        mytoken.safeApprove(address(this), totalAmount);
        mytoken.safeTransferFrom(address(this), msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getContractBalance() public view returns (uint256) {
        return mytoken.balanceOf(address(this));
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 rate = BASE_PERCENT;
        if (user.referrer != address(0)) {
            address upline = user.referrer;
            // 76代，分完100%
            uint256 totalIntro = 0;
            for (uint256 i = 0; i < 76; i++) {
                if (upline != address(0)) {
                    uint256 index = i <= 3 ? i : 3;
                    uint256 refPercen = REFERRAL_PERCENTS[index];
                    totalIntro = totalIntro.add(refPercen);
                    upline = users[upline].referrer;
                } else break;
            }
            rate = BASE_PERCENT.mul(PERCENTS_DIVIDER.sub(totalIntro)).div(PERCENTS_DIVIDER);
            if (rate <0){
                rate = 0;
            }
        }

        return rate;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);


            }

        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.bonusArr.length; i++) {

            if (user.bonusArr[i].withdrawn < user.bonusArr[i].amount.mul(2)) {

                if (user.bonusArr[i].start > user.checkpoint) {

                    dividends = (user.bonusArr[i].amount.mul(user.bonusArr[i].rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.bonusArr[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.bonusArr[i].amount.mul(user.bonusArr[i].rate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.bonusArr[i].withdrawn.add(dividends) > user.bonusArr[i].amount.mul(2)) {
                    dividends = (user.bonusArr[i].amount.mul(2)).sub(user.bonusArr[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);


            }

        }

        return totalDividends;
    }
    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }
    function getUserBonus(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 bonusSum;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        for (uint256 i = 0; i < user.bonusArr.length; i++) {
            bonusSum = bonusSum.add(user.bonusArr[i].amount.mul(2));
            if(user.bonusArr[i].level==0){
                level1 = level1.add(1);
            }else if(user.bonusArr[i].level==1){
                level2 = level2.add(1);
            }else{
                level3 = level3.add(1);
            }
        }
        return bonusSum;
    }
    function getUserBonus1(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 bonusSum;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        for (uint256 i = 0; i < user.bonusArr.length; i++) {
            bonusSum = bonusSum.add(user.bonusArr[i].amount);
            if(user.bonusArr[i].level==0){
                level1 = level1.add(1);
            }else if(user.bonusArr[i].level==1){
                level2 = level2.add(1);
            }else{
                level3 = level3.add(1);
            }
        }
        return level1;
    }
    function getUserBonus2(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 bonusSum;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        for (uint256 i = 0; i < user.bonusArr.length; i++) {
            bonusSum = bonusSum.add(user.bonusArr[i].amount);
            if(user.bonusArr[i].level==0){
                level1 = level1.add(1);
            }else if(user.bonusArr[i].level==1){
                level2 = level2.add(1);
            }else{
                level3 = level3.add(1);
            }
        }
        return level2;
    }
    function getUserBonus3(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 bonusSum;
        uint256 level1;
        uint256 level2;
        uint256 level3;
        for (uint256 i = 0; i < user.bonusArr.length; i++) {
            bonusSum = bonusSum.add(user.bonusArr[i].amount);
            if(user.bonusArr[i].level==0){
                level1 = level1.add(1);
            }else if(user.bonusArr[i].level==1){
                level2 = level2.add(1);
            }else{
                level3 = level3.add(1);
            }
        }
        return level3;
    }
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        for (uint256 i = 0; i < user.bonusArr.length; i++) {
            amount = amount.add(user.bonusArr[i].withdrawn);

        }

        return amount;
    }

}



//SourceUnit: address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

//SourceUnit: ierc20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

    function mint(address account, uint amount) external;

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

    function burn(uint256 amount) external;

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

//SourceUnit: math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
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

//SourceUnit: safeerc20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
import "safemath.sol";
import "address.sol";
import "ierc20.sol";
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SourceUnit: safemath.sol

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}