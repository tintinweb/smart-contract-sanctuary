/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)



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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/vesting/IVesting.sol

interface IVesting {

    event UpdatedTreasury(address newTreasury);
    event UpdatedTeam(address newTeam);
    event UpdatedEcosystemFund(address newEcosystemFund);
    event UpdatedLongTermLockUp(address newLongTermLockUp);
    event TokenSet(address token);
    event InitialDeposit(address _to, uint256 _amount, uint _cliff, uint _vesting);
    event TokensClaimed(address _holder, uint256 _amount);
    event ReferenceDateSet(uint256 _referenceDate);

    function setReferenceDate(uint256 _referenceDate) external;
    function setToken(address token) external;
    function initialized() external view returns(bool);
    function treasury() external view returns(address);
    function updateTreasuryWallet(address newTreasury) external;
    function team() external view returns(address);
    function updateTeamWallet(address newTeam) external;
    function ecosystemFund() external view returns(address);
    function updateEcosystemFundWallet(address newEcosystemFund) external;
    function longTermLockUp() external view returns(address);
    function updateLongTermLockUpWallet(address newLongTermLockUp) external;
    function initialDeposit(address _to, uint256 _amount, uint _cliff, uint _vesting) external;
    function claim() external;
    function claimFor(address _holder) external;
    function claimAll() external;
    function getBalances(address _holder) external view returns(uint, uint, uint);

}

// File: contracts/vesting/Vesting.sol


contract Vesting is Ownable, IVesting {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    uint256 public referenceDate = 0;
    uint32 private constant MONTH = 30 days;

    struct VestingData {
        uint cliff; // Number of months during which the holder's tokens are locked in cliff
        uint vesting; // Total Number of months during which the holder's tokens are vested
        uint256 totalVestedAmount; // amount of tokens in vesting on the contract for a given address and a given vesting schema
        uint256 releasedAmount; // amount of tokens already released from totalVestedAmount
    }

    mapping(address => VestingData) public _vestingData;

    address private _treasury;
    address private _team;
    address private _ecosystemFund;
    address private _longTermLockUp;
    IERC20Metadata private _token;
    bool private _initialized;

    /**
     * @dev contract constructor
     * @param treasury_ the treasury address
     * @param team_ the team address
     * @param ecosystemFund_ the ecosystem fund address
     * @param longTermLockUp_ the long term lockup address
     * @param owner the owner address
     */
    constructor(
        address treasury_,
        address team_,
        address ecosystemFund_,
        address longTermLockUp_,
        address owner)  {
        _treasury = treasury_;
        _team = team_;
        _ecosystemFund =ecosystemFund_;
        _longTermLockUp = longTermLockUp_;
        _initialized = false;
        _transferOwnership(owner);
    }

    /**
     * @dev function used to set the reference date for the start of vesting
     * @param _referenceDate the date of reference in UNIX time
     * only owner can call this function 
     */
    function setReferenceDate(uint256 _referenceDate) external override onlyOwner {
        //require(referenceDate == 0, 'Reference date has already been initialized');
        require(_referenceDate != 0, 'Cannot set reference date to 0');
        referenceDate = _referenceDate;
        emit ReferenceDateSet(_referenceDate);
    }

    /**
     * @dev initialization function setting the address of BMEX token
     * can be called only once, after that the contract is set to initialized
     */
    function setToken(address token) external override {
        require(!initialized(), "token address already set");
        _token = IERC20Metadata(token);
        _initialized = true;
        emit TokenSet(token);
    }

    /**
     * @dev getter function for initialization status (token initialization)
     */
    function initialized() public view override returns(bool) {
        return _initialized;
    }

    /**
     * @dev getter function for treasury wallet address
     */
    function treasury() public view override returns(address) {
        return _treasury;
    }

    /**
     * @dev function used to update the wallet of treasury
     * the vesting data corresponding to the treasury will be transferred to the new wallet
     * @param newTreasury the new wallet used for treasury
     * only owner can call this function
     */
    function updateTreasuryWallet(address newTreasury) external override onlyOwner {
        require(newTreasury != address(0), "cannot be address zero");
        require(_vestingData[newTreasury].totalVestedAmount == 0, "address already set");
        _vestingData[newTreasury] = _vestingData[_treasury];
        delete _vestingData[_treasury];
        _treasury = newTreasury;
        emit UpdatedTreasury(newTreasury);
    }

    /**
     * @dev getter function for team wallet address
     */
    function team() public view override returns(address) {
        return _team;
    }

    /**
     * @dev function used to update the team wallet
     * the vesting data corresponding to the team will be transferred to the new wallet
     * @param newTeam the new wallet used for team
     * only owner can call this function
     */
    function updateTeamWallet(address newTeam) external override onlyOwner {
        require(newTeam != address(0), "cannot be address zero");
        require(_vestingData[newTeam].totalVestedAmount == 0, "address already set");
        _vestingData[newTeam] = _vestingData[_team];
        delete _vestingData[_team];
        _team = newTeam;
        emit UpdatedTeam(newTeam);
    }

    /**
     * @dev getter function for ecosystemFund wallet address
     */
    function ecosystemFund() public view override returns(address) {
        return _ecosystemFund;
    }

    /**
     * @dev function used to update the wallet of ecosystem fund
     * the vesting data corresponding to the ecosystem fund will be transferred to the new wallet
     * @param newEcosystemFund the new wallet used for ecosystem fund
     * only owner can call this function
     */
    function updateEcosystemFundWallet(address newEcosystemFund) external override onlyOwner {
        require(newEcosystemFund != address(0), "cannot be address zero");
        require(_vestingData[newEcosystemFund].totalVestedAmount == 0, "address already set");
        _vestingData[newEcosystemFund] = _vestingData[_ecosystemFund];
        delete _vestingData[_ecosystemFund];
        _ecosystemFund = newEcosystemFund;
        emit UpdatedEcosystemFund(newEcosystemFund);
    }

    /**
     * @dev getter function for long term lockup wallet address
     */
    function longTermLockUp() public view override returns(address) {
        return _longTermLockUp;
    }

    /**
     * @dev function used to update the wallet of long term lockup
     * the vesting data corresponding to the long term lockup will be transferred to the new wallet
     * @param newLongTermLockUp the new wallet used for long term lockup
     * only owner can call this function
     */
    function updateLongTermLockUpWallet(address newLongTermLockUp) external override onlyOwner {
        require(newLongTermLockUp != address(0), "cannot be address zero");
        require(_vestingData[newLongTermLockUp].totalVestedAmount == 0, "address already set");
        _vestingData[newLongTermLockUp] = _vestingData[_longTermLockUp];
        delete _vestingData[_longTermLockUp];
        _longTermLockUp = newLongTermLockUp;
        emit UpdatedLongTermLockUp(newLongTermLockUp);
    }

    /**
     * @dev function allowing to make a deposit of tokens on the vesting contract for one of the 4 wallets
     * pre registered, if an initial deposit already exists, the function will fail
     * @param _to the address of the token holder
     * @param _amount the amount of tokens belonging to _to
     * @param _cliff the duration of cliff, in months
     * @param _vesting the duration of the vesting, in months, including the cliff
     */
    function initialDeposit(
        address _to,
        uint256 _amount,
        uint _cliff,
        uint _vesting
    ) external override {
        // Validate input parameters
        require(
            _to == treasury() ||
            _to == team() ||
            _to == ecosystemFund() ||
            _to == longTermLockUp(), 'invalid address parameter');
        require(_amount > 0, 'Value must be positive');
        require(_vestingData[_to].totalVestedAmount == 0, 'not initial deposit');
        // transfer tokens on the vesting contract
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _vestingData[_to].totalVestedAmount = _amount;
        _vestingData[_to].releasedAmount = 0;
        _vestingData[_to].cliff = _cliff;
        _vestingData[_to].vesting = _vesting;

        emit InitialDeposit(_to, _amount, _cliff, _vesting);
    }

    /**
     * @dev internal function calculating the available tokens of a token holder, related to the vesting scheme
     * and holdings of this holder
     */
    function _getAvailableBalance(address _holder) internal view returns (uint256) {
        if (_vestingData[_holder].totalVestedAmount == _vestingData[_holder].releasedAmount) {
            //All tokens released
            return 0;
        }
        if (referenceDate == 0) {
            return 0;
        }

        // solhint-disable-next-line not-rely-on-time
        uint256 currentTime = block.timestamp;

        uint256 startVesting = referenceDate + (_vestingData[_holder].cliff * MONTH);
        if (currentTime < startVesting) {
            return 0; // All balance is still locked
        }

        uint256 vestingTicks = (currentTime - referenceDate) / MONTH;

        // Divide with 10^12 resolution
        uint256 tokensPerTick = (_vestingData[_holder].totalVestedAmount * (10**12 / _vestingData[_holder].vesting)) /
        10**12;
        uint256 unlockedBalance = tokensPerTick * vestingTicks;
        if (vestingTicks >= _vestingData[_holder].vesting) {
            unlockedBalance = _vestingData[_holder].totalVestedAmount;
        }

        if (_vestingData[_holder].releasedAmount >= unlockedBalance) {
            return 0;
        } else {
            return unlockedBalance - _vestingData[_holder].releasedAmount;
        }
    }

    /**
     * @dev function that allows a token owner to claim tokens for himself
     * if there is some free tokens they will be sent out of the vesting contract to the owner wallet
     */
    function claim() external override {
        claimFor(msg.sender);
    }

    /**
     * @dev function that claims tokens on behalf of a wallet
     * this function can be called by anyone
     * if there is some free tokens they will be sent out of the vesting contract to the owner wallet
     * owner needs to actually exist otherwise the function will fail
     */
    function claimFor(address _holder) public override {
        require(
            _holder == treasury() ||
            _holder == team() ||
            _holder == ecosystemFund() ||
            _holder == longTermLockUp(), 'invalid holder');
        uint256 availableBalance = _getAvailableBalance(_holder);
        if (availableBalance > 0) {
            _token.safeTransfer(_holder, availableBalance);
            _vestingData[_holder].releasedAmount += availableBalance;
            emit TokensClaimed(_holder, availableBalance);
        }
    }

    /**
     * @dev function that claims tokens on behalf of all the wallets at the same time
     * this function can be called by anyone
     * if there is some free tokens they will be sent out of the vesting contract to their owners
     */
    function claimAll() external override {
        claimFor(treasury());
        claimFor(team());
        claimFor(ecosystemFund());
        claimFor(longTermLockUp());
    }

    /**
     * @dev Get the balances of the holder on the vesting contract.
     * totalBalance is the balance that is on the vesting contract and belongs to the holder
     * lockedBalance is the share of total balance that is locked on the vesting contract
     * freeBalance is the share of the total balance that can be claimed by calling a claim function on the contract
     * @param _holder the wallet of the token holder, it has to be one of the 4 wallets holding tokens
     */
    function getBalances(address _holder) external view override returns
    (
        uint totalBalance,
        uint lockedBalance,
        uint freeBalance
    )
    {
        require(
            _holder == treasury() ||
            _holder == team() ||
            _holder == ecosystemFund() ||
            _holder == longTermLockUp(), 'invalid holder');

        totalBalance = _vestingData[_holder].totalVestedAmount - _vestingData[_holder].releasedAmount;
        freeBalance = _getAvailableBalance(_holder);
        lockedBalance = totalBalance - freeBalance;
    }


}