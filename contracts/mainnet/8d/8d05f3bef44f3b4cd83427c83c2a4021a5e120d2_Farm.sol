/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

pragma solidity ^0.8.0;

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
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
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
            );
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

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IFarmFactory.sol

interface IFarmFactory {
    function userEnteredFarm(address _user) external;

    function userLeftFarm(address _user) external;

    function addFarm(address _farmAddress) external;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/interfaces/IFarm.sol

interface IFarm {
    function owner() external view returns (address);
}

// File: contracts/Vesting.sol

contract Vesting is ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public token;
    uint256 public vestingDuration; // 1170000 blocks ~ 180 days
    address public farm;

    struct VestingInfo {
        uint256 amount;
        uint256 startBlock;
        uint256 claimedAmount;
    }

    // user address => vestingInfo[]
    mapping(address => VestingInfo[]) private _userToVestingList;

    modifier onlyFarm() {
        require(msg.sender == farm, "Vesting: FORBIDDEN");
        _;
    }

    modifier onlyFarmOwner() {
        require(msg.sender == IFarm(farm).owner(), "Vesting: FORBIDDEN");
        _;
    }

    constructor(address _token, uint256 _vestingDuration) {
        token = IERC20(_token);
        require(_vestingDuration > 0, "Vesting: Invalid duration");

        vestingDuration = _vestingDuration;
        farm = msg.sender;
    }

    function addVesting(address _user, uint256 _amount) external onlyFarm {
        token.safeTransferFrom(msg.sender, address(this), _amount);
        VestingInfo memory info = VestingInfo(_amount, block.number, 0);
        _userToVestingList[_user].push(info);
    }

    function claimVesting(uint256 _index) external nonReentrant {
        _claimVestingInternal(_index);
    }

    function claimTotalVesting() external nonReentrant {
        uint256 count = _userToVestingList[msg.sender].length;
        for (uint256 _index = 0; _index < count; _index++) {
            if (_getVestingClaimableAmount(msg.sender, _index) > 0) {
                _claimVestingInternal(_index);
            }
        }
    }

    function _claimVestingInternal(uint256 _index) internal {
        require(_index < _userToVestingList[msg.sender].length, "Vesting: Invalid index");
        uint256 claimableAmount = _getVestingClaimableAmount(msg.sender, _index);
        require(claimableAmount > 0, "Vesting: Nothing to claim");
        _userToVestingList[msg.sender][_index].claimedAmount =
            _userToVestingList[msg.sender][_index].claimedAmount +
            claimableAmount;
        require(token.transfer(msg.sender, claimableAmount), "Vesting: transfer failed");
    }

    function _getVestingClaimableAmount(address _user, uint256 _index)
        internal
        view
        returns (uint256 claimableAmount)
    {
        VestingInfo memory info = _userToVestingList[_user][_index];
        if (block.number <= info.startBlock) return 0;
        uint256 passedBlocks = block.number - info.startBlock;

        uint256 releasedAmount;
        if (passedBlocks >= vestingDuration) {
            releasedAmount = info.amount;
        } else {
            releasedAmount = (info.amount * passedBlocks) / vestingDuration;
        }

        claimableAmount = 0;
        if (releasedAmount > info.claimedAmount) {
            claimableAmount = releasedAmount - info.claimedAmount;
        }
    }

    function getVestingTotalClaimableAmount(address _user)
        external
        view
        returns (uint256 totalClaimableAmount)
    {
        uint256 count = _userToVestingList[_user].length;
        for (uint256 _index = 0; _index < count; _index++) {
            totalClaimableAmount = totalClaimableAmount + _getVestingClaimableAmount(_user, _index);
        }
    }

    function getVestingClaimableAmount(address _user, uint256 _index)
        external
        view
        returns (uint256)
    {
        return _getVestingClaimableAmount(_user, _index);
    }

    function getVestingsCountByUser(address _user) external view returns (uint256) {
        uint256 count = _userToVestingList[_user].length;
        return count;
    }

    function getVestingInfo(address _user, uint256 _index)
        external
        view
        returns (VestingInfo memory)
    {
        require(_index < _userToVestingList[_user].length, "Vesting: Invalid index");
        VestingInfo memory info = _userToVestingList[_user][_index];
        return info;
    }

    function getTotalAmountLockedByUser(address _user) external view returns (uint256) {
        uint256 count = _userToVestingList[_user].length;
        uint256 amountLocked = 0;
        for (uint256 _index = 0; _index < count; _index++) {
            amountLocked =
                amountLocked +
                _userToVestingList[_user][_index].amount -
                _userToVestingList[_user][_index].claimedAmount;
        }

        return amountLocked;
    }

    function updateVestingDuration(uint256 _vestingDuration) external onlyFarmOwner {
        vestingDuration = _vestingDuration;
    }
}

// SPDX-License-Identifier: GPL-3.0
// File: contracts/Farm.sol

contract Farm {
    using SafeERC20 for IERC20;

    /// @notice information stuct on each user than stakes LP tokens.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }

    address public owner;

    IERC20 public lpToken;
    IERC20 public rewardToken;
    uint256 public startBlock;
    uint256 public rewardPerBlock;
    uint256 public lastRewardBlock;
    uint256 public accRewardPerShare;
    uint256 public farmerCount;
    bool public isActive;

    uint256 public firstCycleRate;
    uint256 public initRate;
    uint256 public reducingRate; // 95 equivalent to 95%
    uint256 public reducingCycle; // 195000 equivalent 195000 block

    IFarmFactory public factory;
    address public farmGenerator;

    Vesting public vesting;
    uint256 public percentForVesting; // 50 equivalent to 50%

    /// @notice information on each user than stakes LP tokens
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Farm: FORBIDDEN");
        _;
    }

    modifier mustActive() {
        require(isActive == true, "Farm: Not active");
        _;
    }

    constructor(address _factory, address _farmGenerator) {
        factory = IFarmFactory(_factory);
        farmGenerator = _farmGenerator;
    }

    /**
     * @notice initialize the farming contract. This is called only once upon farm creation and the FarmGenerator ensures the farm has the correct paramaters
     */
    function init(
        IERC20 _rewardToken,
        IERC20 _lpToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256[] memory _rateParameters, // 0: firstCycleRate , 1: initRate, 2: reducingRate, 3: reducingCycle
        uint256[] memory _vestingParameters, // 0: percentForVesting, 1: vestingDuration
        address _owner
    ) public {
        require(msg.sender == address(farmGenerator), "Farm: FORBIDDEN");
        require(address(_rewardToken) != address(0), "Farm: Invalid reward token");
        require(_rewardPerBlock > 1000, "Farm: Invalid block reward"); // minimum 1000 divisibility per block reward
        require(_startBlock > block.number, "Farm: Invalid start block"); // ideally at least 24 hours more to give farmers time
        require(_vestingParameters[0] <= 100, "Farm: Invalid percent for vesting");
        require(_rateParameters[0] > 0, "Farm: Invalid first cycle rate");
        require(_rateParameters[1] > 0, "Farm: Invalid initial rate");
        require(_rateParameters[2] > 0 && _rateParameters[1] < 100, "Farm: Invalid reducing rate");
        require(_rateParameters[3] > 0, "Farm: Invalid reducing cycle");

        rewardToken = _rewardToken;
        startBlock = _startBlock;
        rewardPerBlock = _rewardPerBlock;
        firstCycleRate = _rateParameters[0];
        initRate = _rateParameters[1];
        reducingRate = _rateParameters[2];
        reducingCycle = _rateParameters[3];
        isActive = true;
        owner = _owner;

        uint256 _lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        lpToken = _lpToken;
        lastRewardBlock = _lastRewardBlock;
        accRewardPerShare = 0;

        if (_vestingParameters[0] > 0) {
            percentForVesting = _vestingParameters[0];
            vesting = new Vesting(address(_rewardToken), _vestingParameters[1]);
            _rewardToken.safeApprove(address(vesting), type(uint256).max);
        }
    }

    /**
     * @notice Gets the reward multiplier over the given _fromBlock until _to block
     * @param _fromBlock the start of the period to measure rewards for
     * @param _toBlock the end of the period to measure rewards for
     * @return The weighted multiplier for the given period
     */
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
        return _getMultiplierFromStart(_toBlock) - _getMultiplierFromStart(_fromBlock);
    }

    function _getMultiplierFromStart(uint256 _block) internal view returns (uint256) {
        uint256 roundPassed = (_block - startBlock) / reducingCycle;

        if (roundPassed == 0) {
            return (_block - startBlock) * firstCycleRate * 1e12;
        } else {
            uint256 multiplier = reducingCycle * firstCycleRate * 1e12;
            uint256 i = 0;
            for (i = 0; i < roundPassed - 1; i++) {
                multiplier =
                    multiplier +
                    ((1e12 * initRate * reducingRate**i) / 100**i) *
                    reducingCycle;
            }

            if ((_block - startBlock) % reducingCycle > 0) {
                multiplier =
                    multiplier +
                    ((1e12 * initRate * reducingRate**i) / 100**i) *
                    ((_block - startBlock) % reducingCycle);
            }

            return multiplier;
        }
    }

    /**
     * @notice function to see accumulated balance of reward token for specified user
     * @param _user the user for whom unclaimed tokens will be shown
     * @return total amount of withdrawable reward tokens
     */
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 _accRewardPerShare = accRewardPerShare;
        uint256 _lpSupply = lpToken.balanceOf(address(this));
        if (block.number > lastRewardBlock && _lpSupply != 0 && isActive == true) {
            uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
            uint256 _tokenReward = (_multiplier * rewardPerBlock) / 1e12;
            _accRewardPerShare = _accRewardPerShare + ((_tokenReward * 1e12) / _lpSupply);
        }
        return ((user.amount * _accRewardPerShare) / 1e12) - user.rewardDebt;
    }

    /**
     * @notice updates pool information to be up to date to the current block
     */
    function updatePool() public mustActive {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 _lpSupply = lpToken.balanceOf(address(this));
        if (_lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 _tokenReward = (_multiplier * rewardPerBlock) / 1e12;
        accRewardPerShare = accRewardPerShare + ((_tokenReward * 1e12) / _lpSupply);
        lastRewardBlock = block.number;
    }

    /**
     * @notice deposit LP token function for msg.sender
     * @param _amount the total deposit amount
     */
    function deposit(uint256 _amount) public mustActive {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 _pending = ((user.amount * accRewardPerShare) / 1e12) - user.rewardDebt;

            uint256 availableRewardToken = rewardToken.balanceOf(address(this));
            if (_pending > availableRewardToken) {
                _pending = availableRewardToken;
            }

            uint256 _forVesting = 0;
            if (percentForVesting > 0) {
                _forVesting = (_pending * percentForVesting) / 100;
                vesting.addVesting(msg.sender, _forVesting);
            }

            rewardToken.safeTransfer(msg.sender, _pending - _forVesting);
        }
        if (user.amount == 0 && _amount > 0) {
            factory.userEnteredFarm(msg.sender);
            farmerCount++;
        }
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        user.amount = user.amount + _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @notice withdraw LP token function for msg.sender
     * @param _amount the total withdrawable amount
     */
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "INSUFFICIENT");

        if (isActive == true) {
            updatePool();
        }

        if (user.amount == _amount && _amount > 0) {
            factory.userLeftFarm(msg.sender);
            farmerCount--;
        }

        uint256 _pending = ((user.amount * accRewardPerShare) / 1e12) - user.rewardDebt;

        uint256 availableRewardToken = rewardToken.balanceOf(address(this));
        if (_pending > availableRewardToken) {
            _pending = availableRewardToken;
        }

        uint256 _forVesting = 0;
        if (percentForVesting > 0) {
            _forVesting = (_pending * percentForVesting) / 100;
            vesting.addVesting(msg.sender, _forVesting);
        }

        rewardToken.safeTransfer(msg.sender, _pending - _forVesting);

        user.amount = user.amount - _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        lpToken.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice emergency functoin to withdraw LP tokens and forego harvest rewards. Important to protect users LP tokens
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        lpToken.safeTransfer(msg.sender, user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        if (user.amount > 0) {
            factory.userLeftFarm(msg.sender);
            farmerCount--;
        }
        user.amount = 0;
        user.rewardDebt = 0;
    }

    /**
     * @notice Safe reward transfer function, just in case a rounding error causes pool to not have enough reward tokens
     * @param _to the user address to transfer tokens to
     * @param _amount the total amount of tokens to transfer
     */
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        rewardToken.transfer(_to, _amount);
    }

    function rescueFunds(
        address tokenToRescue,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(address(lpToken) != tokenToRescue, "Farm: Cannot claim token held by the contract");

        IERC20(tokenToRescue).safeTransfer(to, amount);
    }

    function updateReducingRate(uint256 _reducingRate) external onlyOwner mustActive {
        require(_reducingRate > 0 && _reducingRate <= 100, "Farm: Invalid reducing rate");
        reducingRate = _reducingRate;
    }

    function updatePercentForVesting(uint256 _percentForVesting) external onlyOwner {
        require(
            _percentForVesting >= 0 && _percentForVesting <= 100,
            "Farm: Invalid percent for vesting"
        );
        percentForVesting = _percentForVesting;
    }

    function forceEnd() external onlyOwner mustActive {
        updatePool();
        isActive = false;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }
}