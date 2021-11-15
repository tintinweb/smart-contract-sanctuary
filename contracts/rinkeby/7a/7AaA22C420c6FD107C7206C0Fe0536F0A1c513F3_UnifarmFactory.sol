// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "./access/Ownable.sol";
import "./UnifarmVesting.sol";
import "./libraries/SafeMath.sol";

/**
 * @title Unifarm Factory
 * @dev Unifarm factory for deploying different investor vesting contracts with multiple beneficiary functionality.
 * @author Opendefi by Oropocket.
 */

contract UnifarmFactory is Ownable {
    /// @notice using safemath for maticmatics operations in soldity.
    using SafeMath for uint256;

    /// @notice Vested Array to store Multiple Vesting Addresses.
    address[] public vested;

    /// @notice vestToken Address basically UNIFARM TOKEN Address.
    address public vestToken;

    /// @notice event Vested emitted on every createVest.
    event Vested(address vestAddress, uint256 time);

    /**
    @notice construct UnifarmFactory Contract.
    @param vestToken_ vestToken Address. 
     */

    constructor(address vestToken_) Ownable(_msgSender()) {
        vestToken = vestToken_;
    }

    /**
     * @notice create and deploy multiple vest contracts.
     * @notice can be called by onlyOwner.
     * @param startTime vesting startTime in EPOCH.
     * @param endTime vesting endTime in EPOCH.
     * @param cliff duration when claim starts.
     * @param unlockDuration every liner unlocking schedule in seconds.
     * @param allowReleaseAll allow release All once.
     * @return vestAddress A vesting address.
     */

    function createVest(
        uint256 startTime,
        uint256 endTime,
        uint256 cliff,
        uint256 unlockDuration,
        bool allowReleaseAll
    ) external onlyOwner returns (address vestAddress) {
        vestAddress = address(
            new UnifarmVesting(
                _msgSender(),
                startTime.add(cliff),
                startTime,
                startTime.add(endTime),
                unlockDuration,
                allowReleaseAll,
                address(this)
            )
        );

        vested.push(vestAddress);
        emit Vested(vestAddress, block.timestamp);
    }

    /**
    @notice get the vest child contracts length.
    @return length of vested array. 
     */

    function getVestLength() public view returns (uint256) {
        return vested.length;
    }

    /**
    @notice update the vest Token Address.
    @return bool true.
     */

    function updateVestToken(address _newVestToken) external onlyOwner returns (bool) {
        require(_newVestToken != address(0), "new vest token is zero address");
        vestToken = _newVestToken;
        return true;
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "../security/Pausable.sol";

abstract contract Ownable is Pausable {
    /// @notice store owner.
    address public owner;

    /// @notice store superAdmin using for reverting ownership.
    address public superAdmin;

    /// @notice OwnershipTransferred emit on each ownership transfered.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address ownerAddress) {
        owner = ownerAddress;
        superAdmin = ownerAddress;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        require(superAdmin == _msgSender(), "Ownable: caller is not the admin");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyAdmin {
        emit OwnershipTransferred(owner, superAdmin);
        owner = superAdmin;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "./libraries/SafeERC20.sol";
import "./access/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IUFARMBeneficiaryBook.sol";
import "./abstract/Factory.sol";

/**
 * @title Unifarm Vesting Contract
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme.
 * @author OpenDefi by Oropocket.
 */

contract UnifarmVesting is Ownable {
    /// @notice use of SafeMath for mathematics operations.
    using SafeMath for uint256;

    /// @notice use SafeERC20 for IERC20 (interface of ERC20).
    using SafeERC20 for IERC20;

    /// @notice event Released emit on every release which is called by Valid Beneficiary of UFARM.
    event Released(address indexed beneficiary, uint256 amount, uint256 time);

    /// @notice event Withdrawal emit on every SafeWithdraw.
    event Withdrawal(address indexed account, uint256 amount, uint256 time);

    /// @notice when actually token released will be start.
    uint256 public cliff;

    /// @notice vesting start time.
    uint256 public startTime;

    /// @notice vesting end time.
    uint256 public endTime;

    /// @notice A struct to store beneficiary details.
    struct Beneficiary {
        uint256 releasedTokens;
        uint256 lastRelease;
    }

    /// @notice store beneficiary details by its address.
    mapping(address => Beneficiary) public beneficiaryDetails;

    /// @notice linear unlocking duration. every period token released.
    uint256 public unlockDuration;

    /// @notice UFARM factory.
    Factory public factory;

    /// @notice UFARM Beneficiary Book Address.
    address public bookAddress;

    /// @notice allowReleaseAll works on special condition when there is no vesting schedule. eg Airdrop.
    bool public allowReleaseAll;

    /**
     * @notice construct a UFARM Vesting Contract. endTime should be greater than cliff period.
     * @param owner_ owner Address Provided by factory contract.
     * @param cliff_ cliff duration in seconds. eg 30**86400 for 30 days cliff duration.
     * @param startTime_ when will be vesting start provided by factory contract.
     * @param endTime_ when vesting going to be end. eg 360**86400 for 1 year.
     * @param unlockDuration_ duration of linear unlocking. eg 86400 for 1 day linear unlocking.
     * @param allowReleaseAll_ allow release All once.
     * @param factoryAddress_ factory address.
     */

    constructor(
        address owner_,
        uint256 cliff_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 unlockDuration_,
        bool allowReleaseAll_,
        address factoryAddress_
    ) Ownable(owner_) {
        require(
            endTime_ > cliff_,
            "UnifarmVesting: endTime_ should be greater than cliff_ duration."
        );

        cliff = cliff_;
        startTime = startTime_;
        endTime = endTime_;
        unlockDuration = unlockDuration_;
        allowReleaseAll = allowReleaseAll_;

        factory = Factory(factoryAddress_);
    }

    /**
     * @notice Transfers vested tokens to beneficiary. function will fail when unverified beneficiary try.
     * @notice function will failed on when allow release All disabled.
     * @notice beneficiary will be derived from UFARMBeneficiaryBook Contract.
     * @param insertId insertId of beneficiary.
     */

    function releaseAll(uint256 insertId) external whenNotPaused {
        require(allowReleaseAll, "UnifarmVesting: invalid attempt");

        (bool isBeneficiary, address vestAddress, uint256 claimTokens) =
            IUFARMBeneficiaryBook(bookAddress).isBeneficiary(_msgSender(), insertId);
        require(isBeneficiary, "UnifarmVesting: Invalid Beneficiary");
        require(vestAddress == address(this), "UnifarmVesting: Invalid Vesting Address");
        require(
            beneficiaryDetails[_msgSender()].releasedTokens < claimTokens,
            "UnifarmVesting: no claimable tokens remains"
        );

        beneficiaryDetails[_msgSender()].releasedTokens = beneficiaryDetails[_msgSender()]
            .releasedTokens
            .add(claimTokens);
        beneficiaryDetails[_msgSender()].lastRelease = block.timestamp;

        address vestTokenAddress = factory.vestToken();
        IERC20 vestToken = IERC20(vestTokenAddress);

        require(
            IERC20(vestToken).balanceOf(address(this)) > claimTokens,
            "UnifarmVesting: insufficient balance"
        );
        vestToken.safeTransfer(_msgSender(), claimTokens);
        emit Released(_msgSender(), claimTokens, _getNow());
    }

    /**
     * @notice Transfers vested tokens to beneficiary. function will fail when invalid beneficiary tries.
     * @notice function will fail on when beneficiary try to release during cliff period.
     * @notice beneficiary will be derived from UFARMBeneficiaryBook Contract.
     * @param insertId insertId of beneficiary.
     */

    function release(uint256 insertId) external whenNotPaused {
        require(!allowReleaseAll, "UnifarmVesting: invalid attempt");
        (bool isBeneficiary, address vestAddress, uint256 claimTokens) =
            IUFARMBeneficiaryBook(bookAddress).isBeneficiary(_msgSender(), insertId);

        require(isBeneficiary, "UnifarmVesting: Invalid Beneficiary");
        require(vestAddress == address(this), "UnifarmVesting: Invalid Vesting Address");
        require(block.timestamp >= cliff, "UnifarmVesting: cliff period exeception");

        require(
            beneficiaryDetails[_msgSender()].releasedTokens <= claimTokens,
            "UnifarmVesting: no claimable tokens remains"
        );

        address vestTokenAddress = factory.vestToken();
        IERC20 vestToken = IERC20(vestTokenAddress);

        uint256 unlockedTokens = getUnlockedTokens(_msgSender(), claimTokens);
        distribute(_msgSender(), unlockedTokens, vestToken);
    }

    /**
     * @notice distribution of tokens. it may be failed on insufficient balance or when user have no unlocked token.
     * @param holder A beneficiary Address.
     * @param unlockedTokens No of Unlocked Tokens.
     */

    function distribute(
        address holder,
        uint256 unlockedTokens,
        IERC20 vestToken
    ) internal {
        require(unlockedTokens > 0, "UnifarmVesting: You dont have unlocked tokens");

        beneficiaryDetails[holder].releasedTokens = beneficiaryDetails[holder].releasedTokens.add(
            unlockedTokens
        );
        beneficiaryDetails[holder].lastRelease = block.timestamp;

        require(
            IERC20(vestToken).balanceOf(address(this)) > unlockedTokens,
            "UnifarmVesting: insufficient balance"
        );
        vestToken.safeTransfer(holder, unlockedTokens);
        emit Released(holder, unlockedTokens, block.timestamp);
    }

    /**
     * @notice derived block timestamp.
     * @return block timestamp.
     */

    function _getNow() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
    * @notice A View Function for calculating unlock tokens of beneficiary.
     * @notice We have impose very fancy math here
               if block.timestamp >= endTime `endTime.sub(lastRelease).div(unlockDuration).mul(eachPeriod)`       
               else `_getNow().sub(lastRelease).div(unlockDuration).mul(eachPeriod)`     
     * @return unlockedTokens (Beneficiary Unlocked Tokens).
     */

    function getUnlockedTokens(address holder, uint256 claimableTokens)
        internal
        view
        returns (uint256 unlockedTokens)
    {
        Beneficiary storage user = beneficiaryDetails[holder];

        uint256 tokens = paymentSpliter(claimableTokens);
        uint256 lastRelease = user.lastRelease > 0 ? user.lastRelease : cliff;

        uint256 eachPeriod = unlockDuration.div(1 days);

        uint256 unlockedDays;

        if (_getNow() >= endTime)
            unlockedDays = ~~endTime.sub(lastRelease).div(unlockDuration).mul(eachPeriod);
        else unlockedDays = ~~_getNow().sub(lastRelease).div(unlockDuration).mul(eachPeriod);

        unlockedTokens = tokens.mul(unlockedDays);
    }

    /**
     * @notice payment spliter claim-tokens/diff
     * @param claim total claimble tokens.
     * @return tokens no Of tokens he receive every unlock duration.
     */
    function paymentSpliter(uint256 claim) internal view returns (uint256 tokens) {
        uint256 diff = ~~endTime.sub(cliff);
        tokens = claim.div(diff.div(unlockDuration));
    }

    /**
     * @notice set UFARM Beneficiary Address. called by only Owner.
     * @param bookAddress_ UFARM Beneficiary Book Address.
     */

    function setBeneficiaryBook(address bookAddress_) external onlyOwner {
        bookAddress = bookAddress_;
    }

    /**
     * @notice safe Withdraw Vest Tokens function will failed on insufficient contract balance.
     * @notice called by Only Owner.
     * @param noOfTokens number of tokens to withdraw.
     */
    function safeWithdraw(IERC20 tokenAddress, uint256 noOfTokens) external onlyOwner {
        require(address(tokenAddress) != address(0), "Invalid Token Address");
        require(
            tokenAddress.balanceOf(address(this)) >= noOfTokens,
            "UnifarmVesting: Insufficient Balance"
        );
        // send the tokens
        tokenAddress.safeTransfer(owner, noOfTokens);
        emit Withdrawal(owner, noOfTokens, _getNow());
    }

    /**
     * @notice for security concern we will paused this contract.
     * @return true when not paused.
     */

    function doPause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /**
     * @notice vice-versa action like pause.
     * @return true when unpaused.
     */

    function doUnpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /**
     * @notice update the factory instance called by onlyOwner.
     * @return true on succeed.
     */

    function updateFactory(address _newFactory) external onlyOwner returns (bool) {
        require(_newFactory != address(0), "new factory address is zero.");
        factory = Factory(_newFactory);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

import "../access/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

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
    using SafeMath for uint256;
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
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

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

abstract contract IUFARMBeneficiaryBook {
    function isBeneficiary(address account, uint256 insertId)
        public
        view
        virtual
        returns (
            bool,
            address,
            uint256
        );
}

// SPDX-License-Identifier: MIT;

pragma solidity 0.8.0;

abstract contract Factory {
    address public vestToken;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

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

pragma solidity 0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

