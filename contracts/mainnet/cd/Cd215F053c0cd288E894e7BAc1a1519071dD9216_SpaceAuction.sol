// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
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

	  address private _owner = 0xe39b8617D571CEe5e75e1EC6B2bb40DdC8CF6Fa3; // Votium multi-sig address

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// Votium Space Auction

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Ownable.sol";

interface Swap {
  function SwapStake(uint256, uint256, uint8) external; // in, out, method
}
interface Stash {
  function lockCRV(uint256) external;
}


contract SpaceAuction is Ownable {

  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  Swap public swapper;    // interface with sushi/curve swap contract
  address public stash;   // interface with merkle stash contract

  struct Bids {
    address owner;        // bidder
    uint256 maxPerVote;   // max paid per 1 vote
    uint256 maxTotal;     // max paid total
    bool invalid;         // becomes invalid if at the end of the auction, the bidder's snapshot vote does not match their registered hash
  }

  struct ProposalData {
    uint256 deadline;     // set to 2 hours before snapshot voting ends
    uint256 winningBid;   // not set until proposal status is at least 1. Is not final until 2
    uint256 power;        // number of votes cast on behalf of the winner. Is not final until 2
    uint8 status;
      // 0 = open auction (or no auction, if deadline = 0)
      // 1 = winner selected
      // 2 = winning hash confirmed to be valid
      // 3 = closed with vote confirmation
      // 4 = no winner/no vote confirmation
      // Any user can force status 4 if deadline is more than 6 hours old and team has not verified final vote count
    Bids[] bids; // array of 'Bids' struct found above
  }

  struct Bidders {
    bytes32 msgHash;
    uint256 balance;
    uint256 bidId;
  }

  mapping(bytes32 => mapping(address => Bidders)) public bidder;        // maps proposal id + address to Bidders
  mapping(bytes32 => ProposalData) public proposal;                     // maps proposal id to ProposalData
  bytes32[] public proposals;                                           // public registry of proposal ids

  mapping(address => bool) public approvedTeam;                         // for team functions that do not require multi-sig security

  address public platform = 0xe39b8617D571CEe5e75e1EC6B2bb40DdC8CF6Fa3; // Team multi-sig address

  uint256 public slashFee = 300;                                        // 3% initial slash fee
  uint256 public constant DENOMINATOR = 10000;                          // denominates Ratio as % with 2 decimals (100 = 1%)

  mapping(bytes32 => bool) public winningHashes;                        // tells vote proxy contract if a vote is valid

  IERC20 public CRV = IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);

  /* ========== CONSTRUCTOR ========== */

  constructor(address _swapper, address _stash) {
    swapper = Swap(_swapper);        // sets swap contract address to interface
    stash = _stash;                  // sets merkle stash address without interface
    approvedTeam[msg.sender] = true; // adds deployer address to approved team functions
  }

  /* ========== OWNER FUNCTIONS ========== */

  // Update swapper contract
  function updateSwapper(address _swapper) public onlyOwner {
    swapper = Swap(_swapper);
  }
  // Update stash contract
  function updateStash(address _stash) public onlyOwner {
    stash = _stash;
  }
  // Lever for changing fees
  function setFees(uint256 _slash) public onlyOwner {
    require(_slash < 1000, "!<1000");  // Allowable range of 0 to 10% for slash
    slashFee = _slash;
  }
  // add or remove address from team functions
  function modifyTeam(address _member, bool _approval) public onlyOwner {
    approvedTeam[_member] = _approval;
  }
  // approve a vote msg hash in case snapshot is down during the timestamped window for the user submitted hash
  function emergencyValidation(bytes32 _hash) public onlyOwner {
    winningHashes[_hash] = true;
  }
  /* ========== APPROVED TEAM FUNCTIONS ======= */

  // begin auction
  function initiateAuction(bytes32 _proposal, uint256 _deadline) public onlyTeam {
    require(proposal[_proposal].deadline == 0, "exists");
    proposal[_proposal].deadline = _deadline;
    proposals.push(_proposal);
  }

  // select winner of auction
  function selectWinner(bytes32 _proposal, uint256 _votes) public onlyTeam {
    require(proposal[_proposal].deadline < block.timestamp, "Auction has not ended");
    require(proposal[_proposal].status < 2, "!<2");
    (uint256 w, bool hasWinner) = winnerIf(_proposal, _votes);
    require(hasWinner == true, "No qualifying bids");
    proposal[_proposal].winningBid = w;
    proposal[_proposal].power = _votes;
    proposal[_proposal].status = 1;
  }

  // confirm a registered hash belongs to a valid vote to prevent arbitrary msgs from be signed on behalf of the vote contract
  function confirmWinner(bytes32 _proposal) public onlyTeam {
    require(proposal[_proposal].status == 1, "!1");
    bytes32 _hash = bidder[_proposal][proposal[_proposal].bids[proposal[_proposal].winningBid].owner].msgHash;
    winningHashes[_hash] = true;
    proposal[_proposal].status = 2;
  }

  // used to slash bid trolls who register a msg hash that does not correspond with their snapshot vote
  // can also be used in an emergency either by the request of Curve team or Convex team, if a winning bidder
  // is beleived to be a malicious party acting against the best interest of any of the respective platforms
  // _slash should only 'true' if the bid is completely invalid
  function invalidateWinner(bytes32 _proposal, bool _slash) public onlyTeam {
    require(proposal[_proposal].status == 1, "!1"); // Can only invalidate if the winner has not been confirmed
    uint256 w = proposal[_proposal].winningBid;
    require(proposal[_proposal].bids[w].invalid == false, "already invalidated"); // prevents double slashing
    proposal[_proposal].bids[w].invalid = true;
    if(_slash == true) {
      uint256 slashed = bidder[_proposal][proposal[_proposal].bids[w].owner].balance*slashFee/DENOMINATOR; // calculate slashed amount
      bidder[_proposal][proposal[_proposal].bids[w].owner].balance -= slashed;  // remove slashed amount from user balance
      CRV.safeTransfer(platform, slashed); // send slashed amount to platform multi-sig
    }
  }

  // finalize an auction with number of confirmed votes after proposal ends
  function finalize(bytes32 _proposal, uint256 _votes, uint256 _minOut, uint8 _method) public onlyTeam {
    require(proposal[_proposal].status == 2, "!2"); // Can only finalize if winner confirmed
    if(_votes == 0) {
      proposal[_proposal].status = 4; // finalize with no winner
    } else {
      // calculate paid total based on final number of votes received
      Bids memory currentBid = proposal[_proposal].bids[proposal[_proposal].winningBid];
      uint256 paidTotal = currentBid.maxTotal;
      uint256 paidPer = paidTotal/_votes;
      if(paidPer > currentBid.maxPerVote) {
        paidPer = currentBid.maxPerVote;
        paidTotal = paidPer*_votes;
      }
      bidder[_proposal][currentBid.owner].balance -= paidTotal; // removed paid total from winner balance
      if(_minOut == 0) {
        // call stash to lock->stake directly
        CRV.approve(stash, paidTotal);
        Stash(stash).lockCRV(paidTotal);
      } else {
        // call swapper to swap and stake on behalf of stash
        CRV.approve(address(swapper), paidTotal);
        swapper.SwapStake(paidTotal, _minOut, _method);
      }
      proposal[_proposal].status = 3; // set status to finalized with winner
    }
  }

  /* ========== VIEWS ========== */

  // length of proposals registery
  function proposalsLength() public view returns (uint256) {
    return proposals.length;
  }

  // length of bids array in a proposal
  function bidsInProposal(bytes32 _proposal) public view returns (uint256) {
    return proposal[_proposal].bids.length;
  }

  // view specific bid in a given proposal
  function viewBid(bytes32 _proposal, uint256 _bid) public view returns (Bids memory bid) {
    bid = proposal[_proposal].bids[_bid];
  }

  // called by vote proxy contract as part of EIP1271 contract signing
  function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bool) {
    return winningHashes[_hash];
  }

  // Calculates winner of a proposal based on reported voting power
  function winnerIf(bytes32 _proposal, uint256 _votes) public view returns (uint256 winningId, bool hasWinner) {
    require(_votes > 0, "!>0"); // cannot calculate winner of zero votes
    uint256 paidPer;
    uint256 highest;
    // cycle through all bids in proposal
    for(uint256 i=0;i<proposal[_proposal].bids.length;i++) {
      // ignore invalidated bids
      if(proposal[_proposal].bids[i].invalid == false) {
        paidPer = proposal[_proposal].bids[i].maxTotal/_votes; // assume max total is paid
        // if max payment exceeds max per vote allowance, revert to max per vote
        if(paidPer > proposal[_proposal].bids[i].maxPerVote) { paidPer = proposal[_proposal].bids[i].maxPerVote; }
        if(paidPer > highest) {
          winningId = i;
          highest = paidPer;
        }
      }
    }
    // verify a winner has been selected
    if(highest > 0) { hasWinner = true; }
  }

  /* ========== PUBLIC FUNCTIONS ========== */

  // if an auction is not finalized 30 hours after deadline, any user can force status 4 (no winner)
  function forceNoWinner(bytes32 _proposal) public {
    require(proposal[_proposal].deadline+30 hours < block.timestamp, "<30hrs");
    require(proposal[_proposal].status < 3, "final");
    proposal[_proposal].status = 4;
  }

  // register a vote hash to attach to a proposal
  function registerHash(bytes32 _proposal, bytes32 _hash) public {
    require(proposal[_proposal].deadline > block.timestamp, "expired");
    bidder[_proposal][msg.sender].msgHash = _hash;
  }

  // place bid
  function placeBid(bytes32 _proposal, uint256 _maxPerVote, uint256 _maxTotal) public {
    require(_maxTotal > 0, "Cannot bid 0");
    require(_maxPerVote > 0, "Cannot bid 0");
    require(proposal[_proposal].deadline > block.timestamp, "expired");
    require(bidder[_proposal][msg.sender].balance == 0, "Already bid");
    require(bidder[_proposal][msg.sender].msgHash != keccak256(""), "No hash");
    // transfer funds to this contract
    CRV.safeTransferFrom(msg.sender, address(this), _maxTotal);
    // form bid entry
    Bids memory currentEntry;
    currentEntry.owner = msg.sender;
    currentEntry.maxPerVote = _maxPerVote;
    currentEntry.maxTotal = _maxTotal;
    proposal[_proposal].bids.push(currentEntry);
    bidder[_proposal][msg.sender].bidId = proposal[_proposal].bids.length-1;
    bidder[_proposal][msg.sender].balance = _maxTotal;
  }

  // increase a current bid
  function increaseBid(bytes32 _proposal, uint256 bidId, uint256 _maxPerVote, uint256 _maxTotal) public {
    require(proposal[_proposal].deadline > block.timestamp, "expired");
    require(proposal[_proposal].bids[bidId].owner == msg.sender, "!owner");
    // if maxPerVote is greater than original, perform adjustment
    if(_maxPerVote > proposal[_proposal].bids[bidId].maxPerVote) {
      proposal[_proposal].bids[bidId].maxPerVote = _maxPerVote;
    }
    // if maxTotal is greater than original, perform adjustment
    if(_maxTotal > proposal[_proposal].bids[bidId].maxTotal) {
      uint256 increase = _maxTotal-proposal[_proposal].bids[bidId].maxTotal;
      CRV.safeTransferFrom(msg.sender, address(this), increase);
      proposal[_proposal].bids[bidId].maxTotal += increase;
      bidder[_proposal][msg.sender].balance += increase;
    }
  }

  // roll a balance from a finalized auction into a bid for an active auction
  function rollBalance(bytes32 _proposalA, bytes32 _proposalB, uint256 _maxPerVote) public {
    require(proposal[_proposalB].deadline > block.timestamp, "Invalid B"); // Can only roll into active auction
    require(proposal[_proposalA].status > 2, "Invalid A");  // Can only roll out of finalized auction
    require(bidder[_proposalB][msg.sender].balance == 0, "Already bid"); // Address cannot have two bids
    require(bidder[_proposalB][msg.sender].msgHash != keccak256(""), "No hash"); // Address must first register a vote hash
    require(_maxPerVote > 0, "bid 0"); // Cannot bid 0
    require(bidder[_proposalA][msg.sender].balance > 0, "0 balance"); // No balance to transfer

    uint256 bal = bidder[_proposalA][msg.sender].balance; // store original auction balance
    bidder[_proposalA][msg.sender].balance = 0; // set original auction balance to 0
    // form bid entry
    Bids memory currentEntry;
    currentEntry.owner = msg.sender;
    currentEntry.maxPerVote = _maxPerVote;
    currentEntry.maxTotal = bal;
    proposal[_proposalB].bids.push(currentEntry);
    bidder[_proposalB][msg.sender].balance = bal; // set user balance of new auction
  }

  // withdraw from finalized auction
  function withdraw(bytes32 _proposal) public {
    require(proposal[_proposal].status > 2, "not final");
    uint256 bal = bidder[_proposal][msg.sender].balance; // store balance
    if(bal > 0) {
      bidder[_proposal][msg.sender].balance = 0; // set balance to 0
      CRV.safeTransfer(msg.sender, bal); // send stored balance to user
    }
  }

  /* ========== MODIFIERS ========== */

  modifier onlyTeam() {
    require(approvedTeam[msg.sender] == true, "Team only");
    _;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}