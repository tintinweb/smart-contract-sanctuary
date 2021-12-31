/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;



contract MemberList {
  using SafeERC20 for IERC20;

  uint public memberCount;
  uint private payPrice = 5000000000000000000;
  IERC20 private nucToken;

  struct Member {
    uint id;
    string name;
    address creator;
  }

  struct Payment {
    address paidBy;
    uint paidAt;
    uint blockNumber;
  }

  // id_time
  mapping(string => Payment) public payments;
  mapping(uint => Member) public members;

  event MemberCreated(
    uint id,
    string name
  );

  event MemberPaid(
    string paymentId,
    Payment payment
  );

  constructor() {
    nucToken = IERC20(address(0x9C25f4aD456231D913A42322f82ecF23165AB2b7));
  }

  function createMember(string memory name) public {
    memberCount++;
    Member storage member = members[memberCount];
    member.id = memberCount;
    member.name = name;
    member.creator = msg.sender;

    emit MemberCreated(memberCount, name);
  }

  function pay(string memory paymentId) public {
    nucToken.transferFrom(msg.sender, address(0x43e98522A20e40edf475B81b2fDA1508Bea516c7), payPrice);
    Payment storage payment = payments[paymentId];
    payment.paidBy = msg.sender;
    payment.paidAt = block.timestamp;
    payment.blockNumber = block.number;
    emit MemberPaid(paymentId, payments[paymentId]);
  }
}




// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)




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



contract SnackFund {
  using SafeERC20 for IERC20;

  uint public memberCount;
  uint public paymentCount;
  uint public minPayPrice = 5000000000000000000;
  address public fundHolderAddress;
  // memberId -> Member
  mapping(uint => Member) public members;
  // address -> memberId[]
  mapping(address => uint[]) private membersByCreator;
  uint private enabledUserCount;
  // paymentId -> Payment
  mapping(uint => Payment) public payments;
  // time -> paymentId[]
  mapping(uint => uint[]) private paymentsByTime;
  // memberId -> paymentId[]
  mapping(uint => uint[]) private paymentsByMember;
  // address -> paymentId[]
  mapping(address => uint[]) private paymentsPaidByAddress;
  // memberId -> (time -> paymentId)
  mapping(uint => mapping(uint => uint)) private paymentByMemberAndTime;
  IERC20 private nucToken;

  struct Member {
    uint id;
    string name;
    address creator;
    bool disabled;
  }

  struct Payment {
    uint id;
    uint paidAmount;
    address paidBy;
    uint paidAt;
    uint paidForMemberId;
    uint paidForTime;
    uint blockNumber;
  }

  event MemberCreated(
    uint id,
    string name
  );

  event MemberUpdated(
    Member updatedMember
  );

  event MemberToggled(
    Member toggledMember
  );

  event MemberPaid(
    Payment payment
  );

  constructor(address _nucTokenAddress, address _fundHolderAddress, address _oldMemberListAddress) {
    require(_nucTokenAddress != address(0), "Nuc Token address is required!");
    require(_fundHolderAddress != address(0), "Fund holder address is required!");
    nucToken = IERC20(_nucTokenAddress);
    fundHolderAddress = _fundHolderAddress;

    // migrate existing member from MemberListContract
    if (_oldMemberListAddress != address(0)) {
      MemberList oldMemberList = MemberList(_oldMemberListAddress);
      uint oldMemberListCount = oldMemberList.memberCount();
      for (uint i = 1; i <= oldMemberListCount; i++) {
        (, string memory name, address creator) = oldMemberList.members(i);
        _createMember(name, creator);

        // due to bad design in MemberListContract, only can migrate payment in 2021-12
        string memory paymentId = string(abi.encodePacked(uint2str(i), "_1638291600000"));
        (address _paidBy, uint _paidAt, uint _blockNumber) = oldMemberList.payments(paymentId);
        if (_paidAt != 0) {
          // it's always 5 NUC from the old contract
          _createPayment(5000000000000000000, _paidBy, _paidAt, members[i].id, 1638291600000, _blockNumber);
        }
      }
    }
  }

  function createMember(string memory _name) public {
    _createMember(_name, msg.sender);
    emit MemberCreated(memberCount, _name);
  }

  function editMember(uint _memberId, string memory _name) public {
    Member storage member = members[_memberId];
    require(_memberId > 0 && _memberId <= memberCount, "Member does not exist!");
    require(member.creator == msg.sender, "Only creator can edit this member");
    member.name = _name;

    emit MemberUpdated(member);
  }

  function toggleMember(uint _memberId) public {
    Member storage member = members[_memberId];
    require(_memberId > 0 && _memberId <= memberCount, "Member does not exist!");
    require(member.creator == msg.sender || msg.sender == fundHolderAddress, "Only fund holder or creator can enable/disable this member");
    member.disabled = !member.disabled;

    if (member.disabled) {
      enabledUserCount--;
    } else {
      enabledUserCount++;
    }

    emit MemberToggled(member);
  }

  function pay(uint _memberId, uint _timePayFor, uint _amount) public {
    Payment storage payment = payments[paymentByMemberAndTime[_memberId][_timePayFor]];

    require(_memberId > 0 && _memberId <= memberCount, "Member does not exist!");
    require(members[_memberId].disabled == false, "Cannot pay for a disabled member!");
    require(msg.sender != fundHolderAddress, "Fund holder cannot pay!");
    require(_amount >= minPayPrice, "Minimum pay amount is 5!");
    require(payment.paidAt != 0, "Only can pay once per time!");

    nucToken.transferFrom(msg.sender, fundHolderAddress, minPayPrice);

    _createPayment(_amount, msg.sender, block.timestamp, _memberId, _timePayFor, block.number);
    emit MemberPaid(payment);
  }

  function getAllMembers() public view returns (Member[] memory) {
    Member[] memory _members = new Member[](memberCount);
    for (uint i = 1; i <= memberCount; i++) {
      Member storage _member = members[i];
      _members[i - 1] = _member;
    }
    return _members;
  }

  function getEnabledMembers(bool _enabled) public view returns (Member[] memory) {
    Member[] memory _members = new Member[](_enabled ? enabledUserCount : memberCount - enabledUserCount);
    uint _index;
    for (uint i = 1; i <= memberCount; i++) {
      Member storage _member = members[i];
      if (_member.disabled == !_enabled) {
        _members[_index] = _member;
        _index++;
      }
    }
    return _members;
  }

  function getEnabledMembersByCreator(address _creator, bool _enabled) public view returns (Member[] memory) {
    Member[] memory _membersByCreator = getMembersByCreator(_creator);
    uint _count;
    for (uint i = 0; i < _membersByCreator.length; i++) {
      Member memory _member = _membersByCreator[i];
      if (_member.disabled == !_enabled) {
        _count++;
      }
    }
    Member[] memory _members = new Member[](_count);
    uint _index;
    for (uint i = 0; i < _membersByCreator.length; i++) {
      Member memory _member = _membersByCreator[i];
      if (_member.disabled == !_enabled) {
        _members[_index] = _member;
        _index++;
      }
    }
    return _members;
  }

  function getMembersByCreator(address _creator) public view returns (Member[] memory) {
    uint[] storage _membersByCreator = membersByCreator[_creator];
    Member[] memory _members = new Member[](_membersByCreator.length);
    for (uint i = 0; i < _membersByCreator.length; i++) {
      Member storage _member = members[_membersByCreator[i]];
      _members[i] = _member;
    }
    return _members;
  }

  function getAllPayments() public view returns (Payment[] memory) {
    Payment[] memory _payments = new Payment[](paymentCount);
    for (uint i = 1; i <= paymentCount; i++) {
      Payment storage _payment = payments[i];
      _payments[i - 1] = _payment;
    }
    return _payments;
  }

  function getPaymentsByTime(uint _time) public view returns (Payment[] memory) {
    uint[] memory _paymentsByTime = paymentsByTime[_time];
    return _getPaymentsByIds(_paymentsByTime);
  }

  function getPaymentsByMember(uint _memberId) public view returns (Payment[] memory) {
    uint[] memory _paymentsByMember = paymentsByMember[_memberId];
    return _getPaymentsByIds(_paymentsByMember);
  }

  function getPaymentsPaidByAddress(address _address) public view returns (Payment[] memory) {
    uint[] memory _paymentsPaidByAddress = paymentsPaidByAddress[_address];
    return _getPaymentsByIds(_paymentsPaidByAddress);
  }

  function _getPaymentsByIds(uint[] memory _paymentIds) private view returns (Payment[] memory) {
    Payment[] memory _payments = new Payment[](_paymentIds.length);
    for (uint i = 0; i < _paymentIds.length; i++) {
      Payment storage _payment = payments[_paymentIds[i]];
      _payments[i] = _payment;
    }
    return _payments;
  }

  function getPaymentByMemberAndTime(uint _memberId, uint _time) public view returns (Payment memory) {
    return payments[paymentByMemberAndTime[_memberId][_time]];
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function _createMember(string memory _name, address _creator) internal {
    memberCount++;
    enabledUserCount++;
    Member storage member = members[memberCount];
    member.id = memberCount;
    member.name = _name;
    member.creator = _creator;
    member.disabled = false;

    uint[] storage _membersByCreator = membersByCreator[_creator];
    _membersByCreator.push(member.id);
  }

  function _createPayment(uint _paidAmount, address _paidBy, uint _paidAt, uint _paidForMemberId, uint _paidForTime, uint _blockNumber) internal {
    paymentCount++;
    Payment storage payment = payments[paymentCount];
    payment.id = paymentCount;
    payment.paidAmount = _paidAmount;
    payment.paidBy = _paidBy;
    payment.paidAt = _paidAt;
    payment.paidForMemberId = _paidForMemberId;
    payment.paidForTime = _paidForTime;
    payment.blockNumber = _blockNumber;

    uint[] storage _paymentsByTime = paymentsByTime[_paidForTime];
    _paymentsByTime.push(payment.id);
    uint[] storage _paymentsByMember = paymentsByMember[_paidForMemberId];
    _paymentsByMember.push(payment.id);
    uint[] storage _paymentsPaidByAddress = paymentsPaidByAddress[_paidBy];
    _paymentsPaidByAddress.push(payment.id);
    paymentByMemberAndTime[_paidForMemberId][_paidForTime] = payment.id;
  }
}