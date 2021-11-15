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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProSmart is Context {
  using SafeERC20 for IERC20;

  struct Referrals {
    address left;
    address right;
  }

  struct User {
    bool exists;
    uint256 id;
    uint256 uplineId;
    uint256 referrerId;
    uint8 uplineStructure;
    uint8 currentStructure;
    uint8 maxStructureDepth;
    mapping (uint8 => Referrals) structureReferrals;
    mapping (uint8 => int256) structureSizes;
    mapping (uint8 => uint256) levelPayments;
    mapping (uint8 => uint256) levelExpiresAt;
    mapping (uint8 => mapping (uint8 => uint256)) usersOnDepth;
  }

  address public mainAccount;
  uint256 public currentUserId;

  mapping (uint8 => uint256) public levelPrices;
  mapping (uint8 => uint256) public levelDurations;
  mapping (address => User) public users;
  mapping (uint256 => address) public userAddresses;

  IERC20 public depositToken;

  uint8 constant private MAX_STRUCTURES = 4;
  uint8 constant private MAX_LEVEL = 5;
  uint8 constant private FIRST_LEVEL_REFERRALS_LIMIT = 2;

  event RegisterUser(address indexed user, address indexed inviter, address upline, uint8 uplineStructure, uint256 id, uint256 time);
  event BuyLevel(address indexed user, uint8 level, bool autoBuy, uint256 time);

  event GetLevelPayment(address indexed user, address indexed downline, uint8 level, uint256 amount, uint256 time);
  event GetLevelProfit(address indexed user, address indexed downline, uint8 level, uint256 amount, uint256 time);
  event LostLevelProfit(address indexed user, address indexed downline, uint8 level, uint256 amount, uint256 time);

  modifier userNotRegistered() {
    require(!users[_msgSender()].exists, 'User is already registered');
    _;
  }

  modifier userRegistered() {
    require(users[_msgSender()].exists, 'User does not exist');
    _;
  }

  modifier validReferrerAddress(address _referrerAddress) {
    require(users[_referrerAddress].exists, 'Invalid referrer address');
    _;
  }

  modifier validLevel(uint8 _level) {
    require(_level > 0 && _level <= MAX_LEVEL, 'Invalid level');
    _;
  }

  modifier hasEnoughApprovedTokensForLevel(uint8 _level) {
    require(depositToken.allowance(_msgSender(), address(this)) >= levelPrices[_level], 'Not enough approved tokens for a level');
    _;
  }

  constructor(address _mainAccount, address[8] memory _referrals, IERC20 _depositTokenAddress) {
    depositToken = _depositTokenAddress;

    levelPrices[1] = 100 * 10**18; // 100 busd
    levelPrices[2] = 200 * 10**18; // 200 busd
    levelPrices[3] = 400 * 10**18; // 400 busd
    levelPrices[4] = 800 * 10**18; // 800 busd
    levelPrices[5] = 1600 * 10**18; // 1600 busd

    levelDurations[1] = 36 days;
    levelDurations[2] = 54 days;
    levelDurations[3] = 72 days;
    levelDurations[4] = 90 days;
    levelDurations[5] = 108 days;

    mainAccount = _mainAccount;

    _createUser(mainAccount, 0, 0, 0);

    for (uint8 i = 1; i <= MAX_LEVEL; i++) {
      users[mainAccount].levelExpiresAt[i] = 1 << 37;
    }

    uint8 structureNum = 1;
    for (uint8 i = 0; i < 8; i += 2) {
      address left = _referrals[i];
      address right = _referrals[i+1];

      _createUser(left, 1, 1, structureNum);
      _createUser(right, 1, 1, structureNum);

      for (uint8 j = 1; j <= MAX_LEVEL; j++) {
        users[left].levelExpiresAt[j] = 1 << 37;
        users[right].levelExpiresAt[j] = 1 << 37;
      }

      users[mainAccount].structureReferrals[structureNum].left = left;
      users[mainAccount].structureReferrals[structureNum].right = right;
      users[mainAccount].structureSizes[structureNum] = 2;
      users[mainAccount].usersOnDepth[structureNum][1] = 2;

      structureNum++;
    }
  }

  fallback() external {
    if (_msgData().length == 0) {
      return registerUser(mainAccount);
    }

    registerUser(_bytesToAddress(_msgData()));
  }

  function getUserUpline(address _user, uint _height) public view returns (address) {
    if (_height <= 0 || _user == address(0)) {
      return _user;
    }

    return getUserUpline(userAddresses[users[_user].uplineId], _height - 1);
  }

  function getUserStructureReferrals(address _user, uint8 _structNum) public view returns (Referrals memory) {
    return users[_user].structureReferrals[_structNum];
  }

  function getUserStructureSize(address _user, uint8 _structNum) public view returns (int256) {
    return users[_user].structureSizes[_structNum];
  }

  function getUsersOnDepth(address _user, uint8 _structNum, uint8 _depth) public view returns (uint256) {
    return users[_user].usersOnDepth[_structNum][_depth];
  }

  function getUserLevelExpiresAt(address _user, uint8 _level) public view returns (uint256) {
    return users[_user].levelExpiresAt[_level];
  }

  function getUserLevelPayments(address _user, uint8 _level) public view returns (uint256) {
    return users[_user].levelPayments[_level];
  }

  function registerUser(address _referrerAddress)
    public
    userNotRegistered()
    validReferrerAddress(_referrerAddress)
    hasEnoughApprovedTokensForLevel(1)
  {
    User storage referrer = users[_referrerAddress];

    uint256 uplineId = referrer.id;
    uint8 referrerCurrentStructure = referrer.currentStructure;

    if (referrer.structureSizes[referrerCurrentStructure] >= int256(((1 << referrer.maxStructureDepth) - 1) * 2)) {
      if (referrerCurrentStructure == MAX_STRUCTURES) {
        referrerCurrentStructure = 1;

        referrer.maxStructureDepth++;
      } else {
        referrerCurrentStructure++;
      }

      referrer.currentStructure = referrerCurrentStructure;
    }

    if (referrer.usersOnDepth[referrerCurrentStructure][1] == FIRST_LEVEL_REFERRALS_LIMIT) {
      uplineId = users[findFreeUpline(_referrerAddress, referrerCurrentStructure, referrer.maxStructureDepth)].id;
    }

    address uplineAddress = userAddresses[uplineId];
    User storage uplineUser = users[uplineAddress];
    uint8 uplineCurrentStructure = uplineUser.currentStructure;

    _createUser(_msgSender(), referrer.id, uplineId, uplineCurrentStructure);
    users[_msgSender()].levelExpiresAt[1] = block.timestamp + levelDurations[1];

    if (uplineUser.structureReferrals[uplineCurrentStructure].left == address(0)) {
      uplineUser.structureReferrals[uplineCurrentStructure].left = _msgSender();
    } else {
      uplineUser.structureReferrals[uplineCurrentStructure].right = _msgSender();
    }

    uint8 uplStructure = uplineCurrentStructure;
    uint8 depth = 1;
    User storage uplUser = uplineUser;
    do {
      if (uplUser.structureSizes[uplStructure] < 0) {
        uplUser.structureSizes[uplStructure] = 1;
      } else {
        uplUser.structureSizes[uplStructure]++;
      }
      uplUser.usersOnDepth[uplStructure][depth]++;

      depth++;
      uplStructure = uplUser.uplineStructure;
      uplUser = users[userAddresses[uplUser.uplineId]];
    } while (uplUser.exists);

    emit RegisterUser(_msgSender(), _referrerAddress, uplineAddress, uplineCurrentStructure, currentUserId, block.timestamp);
    transferLevelPayment(1, _msgSender(), levelPrices[1]);
  }

  function buyLevel(uint8 _level)
    public
    userRegistered()
    validLevel(_level)
    hasEnoughApprovedTokensForLevel(_level)
  {
    for (uint8 l = _level - 1; l > 0; l--) {
      require(getUserLevelExpiresAt(_msgSender(), l) >= block.timestamp, 'Buy the previous level');
    }

    if (getUserLevelExpiresAt(_msgSender(), _level) < block.timestamp) {
      users[_msgSender()].levelExpiresAt[_level] = block.timestamp + levelDurations[_level];
    } else {
      users[_msgSender()].levelExpiresAt[_level] += levelDurations[_level];
    }

    uint256 amount = levelPrices[_level];

    if (users[_msgSender()].levelPayments[_level] > 0 && users[_msgSender()].levelPayments[_level] < amount) {
      amount = amount - users[_msgSender()].levelPayments[_level];
      users[_msgSender()].levelPayments[_level] = 0;
    }

    emit BuyLevel(_msgSender(), _level, false, block.timestamp);
    transferLevelPayment(_level, _msgSender(), amount);
  }

  function findFreeUpline(address _user, uint8 _structureNum, uint8 _maxDepth) internal view returns (address) {
    uint8 depth = 2;

    while (depth <= _maxDepth) {
      if (users[_user].usersOnDepth[_structureNum][depth] < (1 << depth)) {
        break;
      }

      depth++;
    }

    depth--;
    address upline;

    Referrals storage referrals = users[_user].structureReferrals[_structureNum];

    do {
      if (users[referrals.left].usersOnDepth[1][depth] < (1 << depth)) {
        upline = referrals.left;
      } else {
        upline = referrals.right;
      }

      referrals = users[upline].structureReferrals[1];
      depth--;
    } while (depth > 0);

    require(upline != address(0), 'Upline was not found');

    return upline;
  }

  function transferLevelPayment(uint8 _level, address _user, uint256 _amount) internal {
    address upline = getUserUpline(_user, _level);

    if (upline == address(0)) {
      upline = mainAccount;
    }

    if (getUserLevelExpiresAt(upline, _level) < block.timestamp) {
      emit LostLevelProfit(upline, _user, _level, _amount, block.timestamp);
      transferLevelPayment(_level, upline, _amount);
      return;
    }

    uint8 nextLevel = _level + 1;

    if (_level == MAX_LEVEL || getUserLevelExpiresAt(upline, nextLevel) >= block.timestamp) {
      depositToken.safeTransferFrom(_msgSender(), upline, _amount);
      emit GetLevelProfit(upline, _user, _level, _amount, block.timestamp);
      return;
    }

    users[upline].levelPayments[nextLevel] += _amount;
    uint256 excessAmount;
    if (users[upline].levelPayments[nextLevel] > levelPrices[nextLevel]) {
      excessAmount = users[upline].levelPayments[nextLevel] - levelPrices[nextLevel];
      _amount -= excessAmount;
    }

    emit GetLevelPayment(upline, _user, _level, _amount, block.timestamp);

    if (users[upline].levelPayments[nextLevel] >= levelPrices[nextLevel]) {
      users[upline].levelExpiresAt[nextLevel] = block.timestamp + levelDurations[nextLevel];
      users[upline].levelPayments[nextLevel] = 0;
      emit BuyLevel(upline, nextLevel, true, block.timestamp);

      if (excessAmount > 0) {
        depositToken.safeTransferFrom(_msgSender(), upline, excessAmount);
        emit GetLevelProfit(upline, _user, _level, excessAmount, block.timestamp);
      }
    }

    transferLevelPayment(nextLevel, upline, _amount);
  }

  function _createUser(address _user, uint256 referrerId, uint256 uplineId, uint8 uplineStructure) private returns (User storage) {
    currentUserId++;

    User storage user = users[_user];
    user.exists = true;
    user.id = currentUserId;
    user.referrerId = referrerId;
    user.uplineId = uplineId;
    user.uplineStructure = uplineStructure;
    user.currentStructure = 1;
    user.structureReferrals[1] = Referrals({
      left: address(0),
      right: address(0)
    });
    user.maxStructureDepth = 5;
    user.structureSizes[1] = -1;
    user.structureSizes[2] = -1;
    user.structureSizes[3] = -1;
    user.structureSizes[4] = -1;

    userAddresses[currentUserId] = _user;

    return user;
  }

  function _bytesToAddress(bytes memory _addr) private pure returns (address addr) {
    assembly {
      addr := mload(add(_addr, 20))
    }
  }
}

