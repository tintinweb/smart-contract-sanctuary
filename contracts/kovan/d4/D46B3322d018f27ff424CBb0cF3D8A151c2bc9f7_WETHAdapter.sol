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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error MustBeCalledByOwner();

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner {
    if (msg.sender != owner) {
      revert MustBeCalledByOwner();
    }
    _;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    owner = newOwner;
    emit OwnershipTransferred(newOwner);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IOracle.sol";
import "./Ownable.sol";

error Overflow();
error InvalidValue();
error ElementNotFound();
error MustBeCalledBySponsorOwner(address owner);
error SponsorListFull(bytes16 campaign);
error SponsorListNotOversized(bytes16 campaign);
error InvalidSponsor(bytes32 sponsorId);
error UnapprovedSponsor(bytes32 sponsorId);
error SponsorAlreadyActive(bytes32 sponsorId);
error SponsorInactive(bytes32 sponsorId);
error SponsorBalanceEmpty(bytes32 sponsorId);
error MustWithdrawBalanceToChangeToken(bytes32 sponsorId);
error InsufficentBidToSwap(uint256 currentBid, uint256 attemptedSwapBid);

contract SponsorAuction is Ownable {
  struct Sponsor {
    uint128 balance;         // 16 bytes -- slot 1
    bool approved;           // 1 byte
    bool active;             // 1 byte
    uint8 slot;              // 1 byte
    uint32 lastUpdated;      // 4 bytes
    address owner;           // 20 bytes -- slot 2
    IERC20 token;            // 20 bytes -- slot 3
    uint128 paymentPerSecond; // 16 bytes -- slot 4
    bytes16 campaign;        // 16 bytes
    string metadata;
  }

  struct Campaign {
    uint8 slots;
    uint8 activeSlots;
  }

  mapping(bytes32 => Sponsor) private sponsors;

  mapping(bytes16 => Campaign) private campaigns;

  mapping(bytes16 => mapping(uint256 => bytes32)) private campaignActiveSponsors;

  mapping(address => uint256) public paymentCollected;

  IOracle public oracle;

  event NewSponsor(
    bytes32 indexed sponsor,
    bytes16 indexed campaign,
    address indexed owner,
    address token,
    uint128 paymentPerSecond,
    string metadata
  );
  event PaymentProcessed(
    bytes16 indexed campaign,
    bytes32 indexed sponsor,
    address indexed paymentToken,
    uint256 paymentAmount
  );
  event SponsorActivated(bytes16 indexed campaign, bytes32 indexed sponsor);
  event SponsorDeactivated(bytes16 indexed campaign, bytes32 indexed sponsor);
  event SponsorSwapped(
    bytes16 campaign,
    bytes32 sponsorDeactivated,
    bytes32 sponsorActivated
  );
  event MetadataUpdated(bytes32 indexed sponsor, string metadata);
  event SponsorOwnerTransferred(bytes32 indexed sponsor, address newOwner);
  event BidUpdated(bytes32 indexed sponsor, address indexed token, uint256 paymentPerSecond);

  event Deposit(bytes32 indexed sponsor, address indexed token, uint256 amount);
  event Withdrawal(bytes32 indexed sponsor, address indexed token, uint256 amount);

  event ApprovalSet(bytes32 indexed sponsor, bool approved);
  event NumberOfSlotsChanged(bytes16 indexed campaign, uint8 newNumSlots);
  event TreasuryWithdrawal(address indexed token, address indexed recipient, uint256 amount);

  // Constructor

  constructor(IOracle _oracle) {
    oracle = _oracle;
  }

  // View functions

  function getSponsor(bytes32 sponsorId) external view returns (
    address owner,
    bool approved,
    bool active,
    IERC20 token,
    uint128 paymentPerSecond,
    bytes16 campaign,
    uint32 lastUpdated,
    string memory metadata
  ) {
    Sponsor memory sponsor = sponsors[sponsorId];
    owner = sponsor.owner;
    approved = sponsor.approved;
    active = sponsor.active;
    token = sponsor.token;
    paymentPerSecond = sponsor.paymentPerSecond;
    campaign = sponsor.campaign;
    lastUpdated = sponsor.lastUpdated;
    metadata = sponsor.metadata;
  }

  function getCampaign(bytes16 campaignId) external view returns (uint8 slots, uint8 activeSlots) {
    Campaign memory campaign = campaigns[campaignId];
    slots = campaign.slots;
    activeSlots = campaign.activeSlots;
  }

  function sponsorBalance(bytes32 sponsorId) external view returns (
    uint128 balance,
    uint128 storedBalance,
    uint128 pendingPayment
  ) {
    Sponsor memory sponsor = sponsors[sponsorId];

    uint256 timeElapsed = block.timestamp - sponsor.lastUpdated;
    pendingPayment = uint128(timeElapsed) * sponsor.paymentPerSecond;

    if (pendingPayment > sponsor.balance) {
      // If their balance is too small, we just zero the balance
      pendingPayment = sponsor.balance;
    }

    storedBalance = sponsor.balance;
    balance = storedBalance - pendingPayment;
  }

  function getActiveSponsors(bytes16 campaignId) external view returns (bytes32[] memory activeSponsors) {
    Campaign memory campaign = campaigns[campaignId];
    activeSponsors = new bytes32[](campaign.activeSlots);

    for(uint256 i = 0; i < campaign.activeSlots; i += 1) {
      activeSponsors[i] = campaignActiveSponsors[campaignId][i];
    }
  }

  function paymentRate(bytes32 sponsorId) external view returns (
    uint128 paymentPerSecond,
    uint128 paymentPerSecondInETH
  ) {
    Sponsor memory sponsor = sponsors[sponsorId];
    paymentPerSecond = sponsor.paymentPerSecond;
    uint256 paymentPerSecondInETH256 = oracle.getPrice(address(sponsor.token), paymentPerSecond);
    // In the unlikely case of a 128-bit overflow, use MAX_INT for uint128
    paymentPerSecondInETH = paymentPerSecondInETH256 > type(uint128).max
      ? type(uint128).max
      : uint128(paymentPerSecondInETH256);
  }

  // Sponsor functions

  function createSponsor(
    address _token,
    bytes16 campaign,
    uint256 initialDeposit,
    uint128 paymentPerSecond,
    string calldata metadata
  ) external returns (bytes32 id) {
    if (campaign == bytes16(0) || _token == address(0)) {
      // TODO: ensure paymentPerSecond is small enough that the payment always fits into uint128
      revert InvalidValue();
    }

    uint128 balance = 0;
    if (initialDeposit > 0) {
      balance = _deposit(IERC20(_token), initialDeposit);
    }

    id = psuedoRandomID(msg.sender, metadata);

    sponsors[id] = Sponsor({
      campaign: campaign,
      owner: msg.sender,
      token: IERC20(_token),
      balance: balance,
      paymentPerSecond: paymentPerSecond,
      lastUpdated: uint32(block.timestamp),
      approved: false,
      active: false,
      slot: 0,
      metadata: metadata
    });

    emit NewSponsor(id, campaign, msg.sender, _token, paymentPerSecond, metadata);

    if (balance > 0) {
      emit Deposit(id, _token, balance);
    }
  }

  function deposit(bytes32 sponsorId, uint256 amount) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (sponsor.owner == address(0)) {
      revert InvalidSponsor(sponsorId);
    }

    uint128 depositReceived = _deposit(IERC20(sponsor.token), amount);

    sponsors[sponsorId].balance = sponsor.balance + depositReceived;

    emit Deposit(sponsorId, address(sponsor.token), depositReceived);

    if (sponsor.active) {
      updateSponsor(sponsorId, sponsor, false, false);
    }
  }

  function updateBid(bytes32 sponsorId, address token, uint128 paymentPerSecond) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (sponsor.owner != msg.sender) {
      revert MustBeCalledBySponsorOwner(sponsor.owner);
    }

    if (sponsor.active) {
      updateSponsor(sponsorId, sponsor, false, false);
    }

    if (address(sponsor.token) != token && sponsor.balance > 0) {
      revert MustWithdrawBalanceToChangeToken(sponsorId);
    }

    sponsors[sponsorId].token = IERC20(token);
    sponsors[sponsorId].paymentPerSecond = paymentPerSecond;

    emit BidUpdated(sponsorId, token, paymentPerSecond);
  }

  function updateMetadata(bytes32 sponsorId, string calldata metadata) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    address _owner = sponsor.owner;
    if (sponsors[sponsorId].owner != msg.sender) {
      revert MustBeCalledBySponsorOwner(_owner);
    }

    if (sponsor.active) {
      updateSponsor(sponsorId, sponsor, false, false);
    }

    sponsors[sponsorId].metadata = metadata;

    if (sponsor.approved || sponsor.active) {
      sponsors[sponsorId].approved = false;
      sponsors[sponsorId].active = false;
    }

    emit MetadataUpdated(sponsorId, metadata);

    if (sponsor.active) {
      emit SponsorDeactivated(sponsor.campaign, sponsorId);
    }
    if (sponsor.approved) {
      emit ApprovalSet(sponsorId, false);
    }
  }

  function withdraw(
    bytes32 sponsorId,
    uint256 amountRequested,
    address recipient
  ) external returns (uint256 withdrawAmount) {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (sponsor.owner != msg.sender) {
      revert MustBeCalledBySponsorOwner(sponsor.owner);
    }

    uint128 balance = sponsor.balance;
    bool active = sponsor.active;
    if (active) {
      (active, balance) = updateSponsor(sponsorId, sponsor, false, false);
    }

    if (balance == 0) {
      return 0;
    }

    uint128 _withdrawAmount = uint128(amountRequested) > balance ? balance : uint128(amountRequested);
    withdrawAmount = _withdrawAmount;

    if (active && withdrawAmount == balance) {
      clearSlot(sponsor.campaign, sponsor.slot);
      sponsors[sponsorId].active = false;
      // sponsor.slot doesn't need to be changed, since it's never read while deactivated

      emit SponsorDeactivated(sponsor.campaign, sponsorId);
    }

    sponsors[sponsorId].balance = balance - _withdrawAmount;

    SafeERC20.safeTransfer(sponsor.token, recipient, withdrawAmount);

    emit Withdrawal(sponsorId, address(sponsor.token), withdrawAmount);
  }

  function transferSponsorOwnership(bytes32 sponsorId, address newOwner) external {
    address _owner = sponsors[sponsorId].owner;
    if (_owner != msg.sender) {
      revert MustBeCalledBySponsorOwner(_owner);
    }

    sponsors[sponsorId].owner = newOwner;

    emit SponsorOwnerTransferred(sponsorId, newOwner);
  }

  // List adjustments

  /// @notice Activates an inactive sponsor on a campaign that has not filled all active slots
  /// @param sponsorId The ID of a sponsor that is approved but inactive
  function lift(bytes32 sponsorId) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (!sponsor.approved) {
      revert UnapprovedSponsor(sponsorId);
    }
    if (sponsor.active) {
      revert SponsorAlreadyActive(sponsorId);
    }

    Campaign memory campaign = campaigns[sponsor.campaign];

    if (campaign.activeSlots >= campaign.slots) {
      revert SponsorListFull(sponsor.campaign);
    }

    activateSponsor(sponsorId, sponsor.campaign, campaign.activeSlots);

    campaigns[sponsor.campaign].activeSlots = campaign.activeSlots + 1;
  }

  /// @notice If a campaign reduces the number of slots, any active sponsor may be dropped
  /// @param sponsorId The ID of a sponsor
  function drop(bytes32 sponsorId) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (!sponsor.active) {
      revert SponsorInactive(sponsorId);
    }

    Campaign memory campaign = campaigns[sponsor.campaign];

    if (campaign.activeSlots <= campaign.slots) {
      revert SponsorListNotOversized(sponsor.campaign);
    }

    updateSponsor(sponsorId, sponsor, true, false);
    campaigns[sponsor.campaign].activeSlots = campaign.activeSlots - 1;
  }

  function swap(bytes32 inactiveSponsorId, bytes32 activeSponsorId) external {
    Sponsor memory inactiveSponsor = sponsors[inactiveSponsorId];
    Sponsor memory activeSponsor = sponsors[activeSponsorId];
    
    if (inactiveSponsor.campaign == bytes16(0)) {
      revert InvalidValue(); // Inactive sponsor doesn't exist
    }
    if (!inactiveSponsor.approved) {
      revert UnapprovedSponsor(inactiveSponsorId);
    }
    if (inactiveSponsor.active) {
      revert SponsorAlreadyActive(inactiveSponsorId);
    }
    if (inactiveSponsor.balance == 0) {
      revert SponsorBalanceEmpty(inactiveSponsorId);
    }

    if (activeSponsorId == bytes32(0)) {
      revert InvalidValue(); // Active sponsor doesn't exist
    }
    if (!activeSponsor.active) {
      revert SponsorInactive(activeSponsorId);
    }

    (, uint256 newBalance) = updateSponsor(activeSponsorId, activeSponsor, true, true);

    // If the active sponsor has an empty balance, we can swap in any approved sponsor
    // If the balance isn't empty, then we compare bids
    if (newBalance != 0) {
      uint256 inactiveBidInETH = oracle.getPrice(address(inactiveSponsor.token), inactiveSponsor.paymentPerSecond);
      uint256 activeBidInETH = oracle.getPrice(address(activeSponsor.token), activeSponsor.paymentPerSecond);

      if (inactiveBidInETH <= activeBidInETH) {
        revert InsufficentBidToSwap(activeBidInETH, inactiveBidInETH);
      }
    }

    activateSponsor(inactiveSponsorId, inactiveSponsor.campaign, activeSponsor.slot);

    emit SponsorSwapped(
      inactiveSponsor.campaign,
      activeSponsorId,
      inactiveSponsorId
    );
  }

  function processPayment(bytes32 sponsorId) external {
    Sponsor memory sponsor = sponsors[sponsorId];
    if (!sponsor.active) {
      revert SponsorInactive(sponsorId);
    }

    updateSponsor(sponsorId, sponsor, false, false);
  }

  // Owner actions

  function setApproved(bytes32 sponsorId, bool approved) external onlyOwner {
    sponsors[sponsorId].approved = approved;
    emit ApprovalSet(sponsorId, approved);
  }

  function setNumSlots(bytes16 campaign, uint8 newNumSlots) external onlyOwner {
    campaigns[campaign].slots = newNumSlots;
    emit NumberOfSlotsChanged(campaign, newNumSlots);
  }

  function withdrawTreasury(address token, address recipient) external onlyOwner returns (uint256 amount) {
    amount = paymentCollected[token];
    if (amount > 0) {
      SafeERC20.safeTransfer(IERC20(token), recipient, amount);
      paymentCollected[token] = 0;
      emit TreasuryWithdrawal(token, recipient, amount);
    }
  }

  // Private functions

  function activateSponsor(bytes32 sponsorId, bytes16 campaign, uint8 slot) private {
    sponsors[sponsorId].lastUpdated = uint32(block.timestamp);
    sponsors[sponsorId].active = true;
    sponsors[sponsorId].slot = slot;

    campaignActiveSponsors[campaign][slot] = sponsorId;

    emit SponsorActivated(campaign, sponsorId);
  }

  /// @notice For a given sponsor, it will process pending payments and deactivate if necessary
  /// @param sponsorId The ID of a sponsor
  /// @param sponsor The current sponsor state
  /// @param forceDeactivate Deactivate the sponsor, even if there is sufficent balance (used in swap/drop)
  /// @param skipClearingSlot Leave the campaign slot enabled (used in swap)
  function updateSponsor(
    bytes32 sponsorId,
    Sponsor memory sponsor,
    bool forceDeactivate,
    bool skipClearingSlot
  ) private returns (bool newActiveState, uint128 newBalance) {
    newActiveState = !forceDeactivate;

    uint256 timeElapsed = block.timestamp - sponsor.lastUpdated;
    uint128 pendingPayment = uint128(timeElapsed) * sponsor.paymentPerSecond;

    if (pendingPayment > sponsor.balance) {
      // If their balance is too small, we just zero the balance
      pendingPayment = sponsor.balance;
      newActiveState = false;
    }

    paymentCollected[address(sponsor.token)] += pendingPayment;

    newBalance = sponsor.balance - pendingPayment;
    sponsors[sponsorId].balance = newBalance;
    sponsors[sponsorId].lastUpdated = uint32(block.timestamp);
    sponsors[sponsorId].active = newActiveState;

    if (pendingPayment > 0) {
      emit PaymentProcessed(
        sponsor.campaign,
        sponsorId,
        address(sponsor.token),
        pendingPayment
      );
    }
    if (!newActiveState) {
      if (!skipClearingSlot) {
        clearSlot(sponsor.campaign, sponsor.slot);
        // sponsor.slot doesn't need to be changed, since it's never read while deactivated
      }

      emit SponsorDeactivated(sponsor.campaign, sponsorId);
    }
  }

  function clearSlot(bytes16 campaignId, uint256 slot) private {
    Campaign memory campaign = campaigns[campaignId];

    uint256 lastActiveSpot = uint256(campaign.activeSlots) - 1;
    if (slot == lastActiveSpot) {
      campaignActiveSponsors[campaignId][slot] = bytes32(0);
    } else {
      campaignActiveSponsors[campaignId][slot] = campaignActiveSponsors[campaignId][lastActiveSpot];
      campaignActiveSponsors[campaignId][lastActiveSpot] = bytes32(0);
    }
    campaigns[campaignId].activeSlots = campaign.activeSlots - 1;
  }

  function _deposit(IERC20 token, uint256 amount) private returns (uint128) {
    uint256 startingBalance = token.balanceOf(address(this));
    SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
    uint256 endBalance = token.balanceOf(address(this));

    if (endBalance - startingBalance > type(uint128).max) {
      revert Overflow();
    }

    return uint128(endBalance - startingBalance);
  }

  function psuedoRandomID(address sender, string memory value) private view returns (bytes32) {
    return keccak256(abi.encodePacked(block.difficulty, block.timestamp, sender, value));        
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SponsorAuction.sol";

interface IWETH {
  function deposit() external payable;
  function approve(address recipient, uint256 amount) external;
}

contract WETHAdapter {
  SponsorAuction public immutable auction;
  IWETH public immutable weth;

  constructor(address _auction, address _weth) {
    auction = SponsorAuction(_auction);
    weth = IWETH(_weth);
  }

  function createSponsor(
    bytes16 campaign,
    uint128 paymentPerSecond,
    string calldata metadata
  ) external payable returns (bytes32 id) {
    weth.deposit{ value: msg.value }();
    weth.approve(address(auction), msg.value);

    id = auction.createSponsor(address(weth), campaign, uint128(msg.value), paymentPerSecond, metadata);
    auction.transferSponsorOwnership(id, msg.sender);
  }

  function deposit(bytes32 sponsorId) external payable {
    weth.deposit{ value: msg.value }();
    weth.approve(address(auction), msg.value);

    auction.deposit(sponsorId, msg.value);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOracle {
  function getPrice(address token, uint256 amount) external view returns (uint256);
}