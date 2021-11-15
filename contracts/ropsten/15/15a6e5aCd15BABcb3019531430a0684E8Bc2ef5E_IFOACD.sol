// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
// removed safeMath, see https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2465

pragma solidity "0.8.0";

// @title IFOV3

contract IFOACD is Ownable{
    using SafeERC20 for IERC20;

    // The LP token used
    IERC20 public lpToken;

    // The offering token
    IERC20 public offeringToken;

    // Number of pools
    uint8 private constant numberPools = 2;

    // The block number when IFO starts
    uint256 public startBlock;

    // The block number when IFO ends
    uint256 public endBlock;

    // Array of PoolCharacteristics of size numberPools
    PoolCharacteristics[numberPools] private _poolInformation;

    // maps the user-address and PoolID to the deposited amount in that Pool
    mapping(address => mapping(uint8 => uint256)) public amountPool;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        // amount of tokens offered for the pool (in offeringTokens)
        uint256 offeringAmountPool;
        // price in DIE/USDT => for 1 MGH/USDT price would be 10^12 
        // for Pool0 the price is set to priceA;
        // for Pool1 priceA is the lower bound (IN MGH/USDT) and priceB is irrelevant
        uint256 priceA;
        uint256 priceB;
        // total amount deposited in the Pool (in LP tokens); resets when new Start and EndBlock are set
        uint256 totalAmountPool;
    }

    // Admin withdraw events
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken, uint256 amountWei);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint8 indexed pid);

    // Event for new start & end blocks
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint priceA_, uint8 pid);

    // modifier to prevent admin from calling critical set up functions before 3 days after harvest time

    modifier adminTimeLock() {
      //  require(block.number >= endBlock + 21000, 'admin must wait');
        _;
    }


    /**
     * @dev It can only be called once.
     * @param _lpToken: the LP token used
     * @param _offeringToken: the token that is offered for the IFO
     */

    constructor(
        IERC20 _lpToken,
        IERC20 _offeringToken
    ) {
        require(_lpToken.totalSupply() >= 0);
        require(_offeringToken.totalSupply() >= 0);
        require(_lpToken != _offeringToken, "Tokens must be be different");
        lpToken = _lpToken;
        offeringToken = _offeringToken;
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _amount: the number of LP token used (6 decimals)
     * @param _pid: pool id
     */
    function depositPool(uint256 _amount, uint8 _pid) external {

        // Checks whether the pool id is valid
        require(_pid < numberPools, "Non valid pool id");

        // Checks that pool was set
        require(_poolInformation[_pid].offeringAmountPool > 0, "Pool not set");

        // Checks whether the block number is not too early
        require(block.number >= startBlock, "Too early");

        // Checks whether the block number is not too late
        require(block.number <= endBlock, "Too late");

        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Amount must be > 0");

        // if its pool1, check if new total amount will be smaller or equal to OfferingAmount / price
        if(_pid == 0){
          require(
            _poolInformation[_pid].offeringAmountPool >= (_poolInformation[_pid].totalAmountPool + (_amount)) * (_poolInformation[_pid].priceA),
            'not enough Offering Tokens left in Pool1');
        }

        // Transfers funds to this contract
        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        // Update the user status
        amountPool[msg.sender][_pid] += _amount;

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool += _amount;

        emit Deposit(msg.sender, _amount, _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @notice if user is not whitelisted and the whitelist is active, the user is refunded in lpTokens
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external {
        // buffer time between end of deposit and start of harvest for admin to whitelist (~7 hours)
        require(block.number >= endBlock, "Too early");

        // Checks whether pool id is valid
        require(_pid < numberPools, "Non valid pool id");

        // Checks whether the user has participated
        require(amountPool[msg.sender][_pid] > 0, "Did not participate");

        uint256 offeringTokenAmount = _calculateOfferingAmountPool(
            msg.sender,
            _pid
        );

        amountPool[msg.sender][_pid] = 0;

        // Transfer these tokens back to the user
        offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
        emit Harvest(msg.sender, offeringTokenAmount, _pid);
    }


    /**
     * @notice It allows the admin to withdraw funds
     * @param _lpAmount: the number of LP token to withdraw (18 decimals)
     * @param _offerAmount: the number of offering amount to withdraw
     * @param _weiAmount: the amount of Wei to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount, uint256 _weiAmount) external onlyOwner adminTimeLock {

        if (_lpAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }

        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }

        if (_weiAmount > 0){
            payable(address(msg.sender)).transfer(_weiAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount, _weiAmount);
    }

    function adminWithdraw() external onlyOwner {
        uint256 amount = lpToken.balanceOf(address(this));
        lpToken.transfer(msg.sender, amount);
        emit AdminWithdraw(amount, 0, 0);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(lpToken), "Cannot be LP token");
        require(_tokenAddress != address(offeringToken), "Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It sets parameters for pool
     * @param _offeringAmountPool: offering amount (in tokens)
     * @param _pid: pool id
     * @dev This function is only callable by admin.
     * @notice can not offer more than the current balance of the contract
     * @notice 
     */
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _priceA,
        uint8 _pid
    ) external  onlyOwner adminTimeLock {

        require(_pid < numberPools, "Pool does not exist");

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].priceA = _priceA;

        //calculate the current total OfferingAmount
        uint sum = 0;
        for (uint j = 0; j < numberPools; j++){
            sum += _poolInformation[j].offeringAmountPool;
        }
        //require that all offered tokens are in the contract
        require(sum <= offeringToken.balanceOf(address(this)),
        'cant offer more than balance');

        emit PoolParametersSet(_offeringAmountPool, _priceA, _pid);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @param _startBlock: the new start block
     * @param _endBlock: the new end block
     * @notice 
     * @notice automatically resets the totalAmount in each Pool to 0
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner adminTimeLock  {
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");
      //reset the totalAmount in each pool, when initiating new start and end blocks
        for(uint j = 0; j < numberPools; j++){
            _poolInformation[j].totalAmountPool = 0;
            _poolInformation[j].offeringAmountPool = 0;
        }
        startBlock = _startBlock;
        endBlock = _endBlock;

        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: poolId
     * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
     * @return totalAmountPool: total amount pool deposited (in LP tokens)
     */
    function viewPoolInformation(uint256 _pid)
        external
        view
        
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].priceA,
            _poolInformation[_pid].priceB,
            _poolInformation[_pid].totalAmountPool
        );
    }

    /**
     * @notice External view function to see user allocations
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user amount in pools
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserAmount(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);

        for (uint8 i = 0; i < numberPools; i++) {
            amountPools[i] = amountPool[_user][i];
        }
        return (amountPools);
    }

    /**
     * @notice External view function to see user offering and refunding amounts 
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
          uint256 userOfferingAmountPool;

          if (_poolInformation[_pids[i]].offeringAmountPool > 0) {
            userOfferingAmountPool = _calculateOfferingAmountPool(_user, _pids[i]);
          }

          amountPools[i] = userOfferingAmountPool;
        }
        return amountPools;
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @param _pid: pool id
     * @return {uint256, uint256} It returns the offering amount, the refunding amount (in LP tokens)
     */
    function _calculateOfferingAmountPool(address _user, uint8 _pid)
      internal
      view
      returns (uint256)
    {
      if(amountPool[_user][_pid] == 0){
        return(0);
      }

		uint256 userOfferingAmount;
      // calculate for Pool1
      if (_pid == 0){
        userOfferingAmount = amountPool[_user][0] * (_poolInformation[0].priceA);
        return userOfferingAmount;
      }

      // calculate for Pool2
      if (_pid == 1){
        if(_poolInformation[1].offeringAmountPool / _poolInformation[1].totalAmountPool > _poolInformation[1].priceA){
          return amountPool[_user][1] * (_poolInformation[0].priceA);
        }else{
          return _getUserAllocationPool(_user, _pid) * _poolInformation[1].offeringAmountPool / 1e12;
        }
      }
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return it returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return amountPool[_user][_pid] * (1e12) / _poolInformation[_pid].totalAmountPool;
        } else {
            return 0;
        }
    }
}

