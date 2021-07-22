//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract Sale is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Information of each user's participation
  struct UserInfo {
      // How many tokens the user has provided
      uint amount;
      // Wether this user has already claimed their refund, defaults to false
      bool claimedRefund;
      // Wether this user has already claimed their share of tokens, defaults to false
      bool claimedTokens;
  }

  // Owner address, has access to withdrawing funds after the sale
  address public owner;
  // Keeper address, has access to tweaking sake parameters
  address public keeper;
  // The raising token
  IERC20 public paymentToken;
  // The offering token
  IERC20 public offeringToken;
  // The block number when sale starts
  uint public startBlock;
  // The block number when sale ends
  uint public endBlock;
  // The block number when tokens are redeemable
  uint public tokensBlock;
  // Total amount of raising tokens that need to be raised
  uint public raisingAmount;
  // Total amount of offeringToken that will be offered
  uint public offeringAmount;
  // Maximum a user can contribute
  uint public perUserCap;
  // Total amount of raising tokens that have already been raised
  uint public totalAmount;
  // Total amount payment token withdrawn by project
  uint public totalAmountWithdrawn;
  // User's participation info
  mapping(address => UserInfo) public userInfo;
  // Participants list
  address[] public addressList;


  event Deposit(address indexed user, uint amount);
  event HarvestRefund(address indexed user, uint amount);
  event HarvestTokens(address indexed user, uint amount);

  constructor(
      IERC20 _paymentToken,
      IERC20 _offeringToken,
      uint _startBlock,
      uint _endBlock,
      uint _tokensBlock,
      uint _offeringAmount,
      uint _raisingAmount,
      uint _perUserCap,
      address _owner,
      address _keeper
  ) {
      paymentToken = _paymentToken;
      offeringToken = _offeringToken;
      startBlock = _startBlock;
      endBlock = _endBlock;
      tokensBlock = _tokensBlock;
      offeringAmount = _offeringAmount;
      raisingAmount = _raisingAmount;
      perUserCap = _perUserCap;
      totalAmount = 0;
      owner = _owner;
      keeper = _keeper;
      _validateBlockParams();
      require(_paymentToken != _offeringToken, 'payment != offering');
      require(_offeringAmount > 0, 'offering > 0');
      require(_raisingAmount > 0, 'raising > 0');
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  modifier onlyOwnerOrKeeper() {
    require(msg.sender == owner || msg.sender == keeper, "!owner or keeper");
    _;
  }

  function _validateBlockParams() private view {
    require(startBlock > block.number, 'start > now');
    require(endBlock >= startBlock, 'end > start');
    require(endBlock - startBlock <= 172800, 'end < 1 month after start');
    require(tokensBlock - endBlock <= 172800, 'tokens < 1 month after end');
  }

  function setOfferingAmount(uint _offerAmount) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    offeringAmount = _offerAmount;
  }

  function setRaisingAmount(uint _raisingAmount) public onlyOwnerOrKeeper {
    require (block.number < startBlock, 'sale started');
    raisingAmount = _raisingAmount;
  }

  function setStartBlock(uint _block) public onlyOwnerOrKeeper {
    startBlock = _block;
    _validateBlockParams();
  }

  function setEndBlock(uint _block) public onlyOwnerOrKeeper {
    endBlock = _block;
    _validateBlockParams();
  }

  function setTokensBlock(uint _block) public onlyOwnerOrKeeper {
    tokensBlock = _block;
    _validateBlockParams();
  }

  function deposit(uint _amount) public {
    require (block.number > startBlock && block.number < endBlock, 'sale not active');
    require (_amount > 0, 'need amount > 0');
    paymentToken.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (userInfo[msg.sender].amount == 0) {
      addressList.push(address(msg.sender));
    }
    userInfo[msg.sender].amount = userInfo[msg.sender].amount + _amount;
    totalAmount = totalAmount + _amount;
    require(perUserCap == 0 || userInfo[msg.sender].amount <= perUserCap, 'over per user cap');
    emit Deposit(msg.sender, _amount);
  }

  function harvestRefund() public nonReentrant {
    require (block.number > endBlock, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimedRefund, 'nothing to harvest');
    uint amount = getRefundingAmount(msg.sender);
    if (amount > 0) {
      paymentToken.safeTransfer(address(msg.sender), amount);
    }
    userInfo[msg.sender].claimedRefund = true;
    emit HarvestRefund(msg.sender, amount);
  }

  function harvestTokens() public nonReentrant {
    require (block.number > tokensBlock, 'not harvest time');
    require (userInfo[msg.sender].amount > 0, 'have you participated?');
    require (!userInfo[msg.sender].claimedTokens, 'nothing to harvest');
    uint amount = getOfferingAmount(msg.sender);
    if (amount > 0) {
      offeringToken.safeTransfer(address(msg.sender), amount);
    }
    userInfo[msg.sender].claimedTokens = true;
    emit HarvestTokens(msg.sender, amount);
  }

  function harvestAll() public {
    harvestRefund();
    harvestTokens();
  }

  function hasHarvestedRefund(address _user) external view returns (bool) {
      return userInfo[_user].claimedRefund;
  }

  function hasHarvestedTokens(address _user) external view returns (bool) {
      return userInfo[_user].claimedTokens;
  }

  // Allocation in percent, 1 means 0.000001(0.0001%), 1000000 means 1(100%)
  function getUserAllocation(address _user) public view returns (uint) {
    return (userInfo[_user].amount * 1e12) / totalAmount / 1e6;
  }

  // Amount of offering token a user will receive
  function getOfferingAmount(address _user) public view returns (uint) {
    if (totalAmount > raisingAmount) {
      uint allocation = getUserAllocation(_user);
      return (offeringAmount * allocation) / 1e6;
    } else {
      return (userInfo[_user].amount * offeringAmount) / raisingAmount;
    }
  }

  // Amount of the offering token a user will be refunded
  function getRefundingAmount(address _user) public view returns (uint) {
    if (totalAmount <= raisingAmount) {
      return 0;
    }
    uint allocation = getUserAllocation(_user);
    uint payAmount = (raisingAmount * allocation) / 1e6;
    return userInfo[_user].amount - payAmount;
  }

  function getAddressListLength() external view returns (uint) {
    return addressList.length;
  }

  function getParams() external view returns (uint, uint, uint, uint, uint, uint, uint, uint) {
    return (startBlock, endBlock, tokensBlock, offeringAmount, raisingAmount, perUserCap, totalAmount, addressList.length);
  }

  function finalWithdraw(uint _paymentAmount, uint _offeringAmount) public onlyOwner {
    require (_paymentAmount <= paymentToken.balanceOf(address(this)), 'not enough payment token');
    require (_offeringAmount <= offeringToken.balanceOf(address(this)), 'not enough offerring token');
    if (_paymentAmount > 0) {
      paymentToken.safeTransfer(address(msg.sender), _paymentAmount);
      totalAmountWithdrawn += _paymentAmount;
      require(totalAmountWithdrawn <= raisingAmount, 'can only widthdraw what is owed');
    }
    if (_offeringAmount > 0) {
      offeringToken.safeTransfer(address(msg.sender), _offeringAmount);
    }
  }
}

// SPDX-License-Identifier: MIT

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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}