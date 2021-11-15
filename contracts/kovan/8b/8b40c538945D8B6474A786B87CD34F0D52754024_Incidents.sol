// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/IClaimsData.sol";
import "../../interfaces/IClaimsReward.sol";
import "../../interfaces/IIncidents.sol";
import "../../interfaces/IMCR.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IPooledStaking.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";

contract Incidents is IIncidents, MasterAware {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  struct Incident {
    address productId;
    uint32 date;
    uint priceBefore;
  }

  // contract identifiers
  enum ID {CD, CR, QD, TC, MR, P1, PS, MC}

  mapping(uint => address payable) public internalContracts;

  Incident[] public incidents;

  // product id => underlying token (ex. yDAI -> DAI)
  mapping(address => address) public underlyingToken;

  // product id => covered token (ex. 0xc7ed.....1 -> yDAI)
  mapping(address => address) public coveredToken;

  // claim id => payout amount
  mapping(uint => uint) public claimPayout;

  // product id => accumulated burn amount
  mapping(address => uint) public accumulatedBurn;

  // burn ratio in bps, ex 2000 for 20%
  uint public BURN_RATIO;

  // burn ratio in bps
  uint public DEDUCTIBLE_RATIO;

  uint constant BASIS_PRECISION = 10000;

  event ProductAdded(
    address indexed productId,
    address indexed coveredToken,
    address indexed underlyingToken
  );

  event IncidentAdded(
    address indexed productId,
    uint incidentDate,
    uint priceBefore
  );

  modifier onlyAdvisoryBoard {
    uint abRole = uint(IMemberRoles.Role.AdvisoryBoard);
    require(
      memberRoles().checkRole(msg.sender, abRole),
      "Incidents: Caller is not an advisory board member"
    );
    _;
  }

  function initialize() external {
    require(BURN_RATIO == 0, "Already initialized");
    BURN_RATIO = 2000;
    DEDUCTIBLE_RATIO = 9000;
  }

  function addProducts(
    address[] calldata _productIds,
    address[] calldata _coveredTokens,
    address[] calldata _underlyingTokens
  ) external onlyAdvisoryBoard {

    require(
      _productIds.length == _coveredTokens.length,
      "Incidents: Protocols and covered tokens lengths differ"
    );

    require(
      _productIds.length == _underlyingTokens.length,
      "Incidents: Protocols and underyling tokens lengths differ"
    );

    for (uint i = 0; i < _productIds.length; i++) {
      address id = _productIds[i];

      require(coveredToken[id] == address(0), "Incidents: covered token is already set");
      require(underlyingToken[id] == address(0), "Incidents: underlying token is already set");

      coveredToken[id] = _coveredTokens[i];
      underlyingToken[id] = _underlyingTokens[i];
      emit ProductAdded(id, _coveredTokens[i], _underlyingTokens[i]);
    }
  }

  function incidentCount() external view returns (uint) {
    return incidents.length;
  }

  function addIncident(
    address productId,
    uint incidentDate,
    uint priceBefore
  ) external onlyGovernance {
    address underlying = underlyingToken[productId];
    require(underlying != address(0), "Incidents: Unsupported product");

    Incident memory incident = Incident(productId, uint32(incidentDate), priceBefore);
    incidents.push(incident);

    emit IncidentAdded(productId, incidentDate, priceBefore);
  }

  function redeemPayoutForMember(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address member
  ) external onlyInternal returns (uint claimId, uint payoutAmount, address payoutToken) {
    (claimId, payoutAmount, payoutToken) = _redeemPayout(coverId, incidentId, coveredTokenAmount, member);
  }

  function redeemPayout(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount
  ) external returns (uint claimId, uint payoutAmount, address payoutToken) {
    (claimId, payoutAmount, payoutToken) = _redeemPayout(coverId, incidentId, coveredTokenAmount, msg.sender);
  }

  function _redeemPayout(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address coverOwner
  ) internal whenNotPaused returns (uint claimId, uint payoutAmount, address coverAsset) {
    IQuotationData qd = quotationData();
    Incident memory incident = incidents[incidentId];
    uint sumAssured;
    bytes4 currency;

    {
      address productId;
      address _coverOwner;

      (/* id */, _coverOwner, productId,
       currency, sumAssured, /* premiumNXM */
      ) = qd.getCoverDetailsByCoverID1(coverId);

      // check ownership and covered protocol
      require(coverOwner == _coverOwner, "Incidents: Not cover owner");
      require(productId == incident.productId, "Incidents: Bad incident id");
    }

    {
      uint coverPeriod = uint(qd.getCoverPeriod(coverId)).mul(1 days);
      uint coverExpirationDate = qd.getValidityOfCover(coverId);
      uint coverStartDate = coverExpirationDate.sub(coverPeriod);

      // check cover validity
      require(coverStartDate <= incident.date, "Incidents: Cover start date is after the incident");
      require(coverExpirationDate >= incident.date, "Incidents: Cover end date is before the incident");

      // check grace period
      uint gracePeriod = tokenController().claimSubmissionGracePeriod();
      require(coverExpirationDate.add(gracePeriod) >= block.timestamp, "Incidents: Grace period has expired");
    }

    {
      // assumes 18 decimals (eth & dai)
      uint decimalPrecision = 1e18;
      uint maxAmount;

      // sumAssured is currently stored without decimals
      uint coverAmount = sumAssured.mul(decimalPrecision);

      {
        // max amount check
        uint deductiblePriceBefore = incident.priceBefore.mul(DEDUCTIBLE_RATIO).div(BASIS_PRECISION);
        maxAmount = coverAmount.mul(decimalPrecision).div(deductiblePriceBefore);
        require(coveredTokenAmount <= maxAmount, "Incidents: Amount exceeds sum assured");
      }

      // payoutAmount = coveredTokenAmount / maxAmount * coverAmount
      //              = coveredTokenAmount * coverAmount / maxAmount
      payoutAmount = coveredTokenAmount.mul(coverAmount).div(maxAmount);
    }

    {
      ITokenController tc = tokenController();
      // mark cover as having a successful claim
      tc.markCoverClaimOpen(coverId);
      tc.markCoverClaimClosed(coverId, true);

      // create the claim
      IClaimsData cd = claimsData();
      claimId = cd.actualClaimLength();
      cd.addClaim(claimId, coverId, coverOwner, now);
      cd.callClaimEvent(coverId, coverOwner, claimId, now);
      cd.setClaimStatus(claimId, 14);
      qd.changeCoverStatusNo(coverId, uint8(IQuotationData.CoverStatus.ClaimAccepted));

      claimPayout[claimId] = payoutAmount;
    }

    coverAsset = claimsReward().getCurrencyAssetAddress(currency);

    _sendPayoutAndPushBurn(
      incident.productId,
      address(uint160(coverOwner)),
      coveredTokenAmount,
      coverAsset,
      payoutAmount
    );

    qd.subFromTotalSumAssured(currency, sumAssured);
    qd.subFromTotalSumAssuredSC(incident.productId, currency, sumAssured);

    mcr().updateMCRInternal(pool().getPoolValueInEth(), true);

    claimsReward().unlockCoverNote(coverId);
  }

  function pushBurns(address productId, uint maxIterations) external {

    uint burnAmount = accumulatedBurn[productId];
    delete accumulatedBurn[productId];

    require(burnAmount > 0, "Incidents: No burns to push");
    require(maxIterations >= 30, "Incidents: Pass at least 30 iterations");

    IPooledStaking ps = pooledStaking();
    ps.pushBurn(productId, burnAmount);
    ps.processPendingActions(maxIterations);
  }

  function withdrawAsset(address asset, address destination, uint amount) external onlyGovernance {
    IERC20 token = IERC20(asset);
    uint balance = token.balanceOf(address(this));
    uint transferAmount = amount > balance ? balance : amount;
    token.safeTransfer(destination, transferAmount);
  }

  function _sendPayoutAndPushBurn(
    address productId,
    address payable coverOwner,
    uint coveredTokenAmount,
    address coverAsset,
    uint payoutAmount
  ) internal {

    address _coveredToken = coveredToken[productId];

    // pull depegged tokens
    IERC20(_coveredToken).safeTransferFrom(msg.sender, address(this), coveredTokenAmount);

    IPool p1 = pool();

    // send the payoutAmount
    {
      address payable payoutAddress = memberRoles().getClaimPayoutAddress(coverOwner);
      bool success = p1.sendClaimPayout(coverAsset, payoutAddress, payoutAmount);
      require(success, "Incidents: Payout failed");
    }

    {
      // burn
      uint decimalPrecision = 1e18;
      uint assetPerNxm = p1.getTokenPrice(coverAsset);
      uint maxBurnAmount = payoutAmount.mul(decimalPrecision).div(assetPerNxm);
      uint burnAmount = maxBurnAmount.mul(BURN_RATIO).div(BASIS_PRECISION);

      accumulatedBurn[productId] = accumulatedBurn[productId].add(burnAmount);
    }
  }

  function claimsData() internal view returns (IClaimsData) {
    return IClaimsData(internalContracts[uint(ID.CD)]);
  }

  function claimsReward() internal view returns (IClaimsReward) {
    return IClaimsReward(internalContracts[uint(ID.CR)]);
  }

  function quotationData() internal view returns (IQuotationData) {
    return IQuotationData(internalContracts[uint(ID.QD)]);
  }

  function tokenController() internal view returns (ITokenController) {
    return ITokenController(internalContracts[uint(ID.TC)]);
  }

  function memberRoles() internal view returns (IMemberRoles) {
    return IMemberRoles(internalContracts[uint(ID.MR)]);
  }

  function pool() internal view returns (IPool) {
    return IPool(internalContracts[uint(ID.P1)]);
  }

  function pooledStaking() internal view returns (IPooledStaking) {
    return IPooledStaking(internalContracts[uint(ID.PS)]);
  }

  function mcr() internal view returns (IMCR) {
    return IMCR(internalContracts[uint(ID.MC)]);
  }

  function updateUintParameters(bytes8 code, uint value) external onlyGovernance {

    if (code == "BURNRATE") {
      require(value <= BASIS_PRECISION, "Incidents: Burn ratio cannot exceed 10000");
      BURN_RATIO = value;
      return;
    }

    if (code == "DEDUCTIB") {
      require(value <= BASIS_PRECISION, "Incidents: Deductible ratio cannot exceed 10000");
      DEDUCTIBLE_RATIO = value;
      return;
    }

    revert("Incidents: Invalid parameter");
  }

  function changeDependentContractAddress() external {
    INXMMaster master = INXMMaster(master);
    internalContracts[uint(ID.CD)] = master.getLatestAddress("CD");
    internalContracts[uint(ID.CR)] = master.getLatestAddress("CR");
    internalContracts[uint(ID.QD)] = master.getLatestAddress("QD");
    internalContracts[uint(ID.TC)] = master.getLatestAddress("TC");
    internalContracts[uint(ID.MR)] = master.getLatestAddress("MR");
    internalContracts[uint(ID.P1)] = master.getLatestAddress("P1");
    internalContracts[uint(ID.PS)] = master.getLatestAddress("PS");
    internalContracts[uint(ID.MC)] = master.getLatestAddress("MC");
  }

}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "../interfaces/INXMMaster.sol";

contract MasterAware {

  INXMMaster public master;

  modifier onlyMember {
    require(master.isMember(msg.sender), "Caller is not a member");
    _;
  }

  modifier onlyInternal {
    require(master.isInternal(msg.sender), "Caller is not an internal contract");
    _;
  }

  modifier onlyMaster {
    if (address(master) != address(0)) {
      require(address(master) == msg.sender, "Not master");
    }
    _;
  }

  modifier onlyGovernance {
    require(
      master.checkIsAuthToGoverned(msg.sender),
      "Caller is not authorized to govern"
    );
    _;
  }

  modifier whenPaused {
    require(master.isPause(), "System is not paused");
    _;
  }

  modifier whenNotPaused {
    require(!master.isPause(), "System is paused");
    _;
  }

  function changeDependentContractAddress() external;

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IClaimsData {

  function pendingClaimStart() external view returns (uint);
  function claimDepositTime() external view returns (uint);
  function maxVotingTime() external view returns (uint);
  function minVotingTime() external view returns (uint);
  function payoutRetryTime() external view returns (uint);
  function claimRewardPerc() external view returns (uint);
  function minVoteThreshold() external view returns (uint);
  function maxVoteThreshold() external view returns (uint);
  function majorityConsensus() external view returns (uint);
  function pauseDaysCA() external view returns (uint);

  function userClaimVotePausedOn(address) external view returns (uint);

  function setpendingClaimStart(uint _start) external;

  function setRewardDistributedIndexCA(address _voter, uint caIndex) external;

  function setUserClaimVotePausedOn(address user) external;

  function setRewardDistributedIndexMV(address _voter, uint mvIndex) external;


  function setClaimRewardDetail(
    uint claimid,
    uint percCA,
    uint percMV,
    uint tokens
  ) external;

  function setRewardClaimed(uint _voteid, bool claimed) external;

  function changeFinalVerdict(uint _claimId, int8 _verdict) external;

  function addClaim(
    uint _claimId,
    uint _coverId,
    address _from,
    uint _nowtime
  ) external;

  function addVote(
    address _voter,
    uint _tokens,
    uint claimId,
    int8 _verdict
  ) external;

  function addClaimVoteCA(uint _claimId, uint _voteid) external;

  function setUserClaimVoteCA(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function setClaimTokensCA(uint _claimId, int8 _vote, uint _tokens) external;

  function setClaimTokensMV(uint _claimId, int8 _vote, uint _tokens) external;

  function addClaimVotemember(uint _claimId, uint _voteid) external;

  function setUserClaimVoteMember(
    address _from,
    uint _claimId,
    uint _voteid
  ) external;

  function updateState12Count(uint _claimId, uint _cnt) external;

  function setClaimStatus(uint _claimId, uint _stat) external;

  function setClaimdateUpd(uint _claimId, uint _dateUpd) external;

  function setClaimAtEmergencyPause(
    uint _coverId,
    uint _dateUpd,
    bool _submit
  ) external;

  function setClaimSubmittedAtEPTrue(uint _index, bool _submit) external;


  function setFirstClaimIndexToSubmitAfterEP(
    uint _firstClaimIndexToSubmit
  ) external;


  function setPendingClaimDetails(
    uint _claimId,
    uint _pendingTime,
    bool _voting
  ) external;

  function setPendingClaimVoteStatus(uint _claimId, bool _vote) external;

  function setFirstClaimIndexToStartVotingAfterEP(
    uint _claimStartVotingFirstIndex
  ) external;

  function callVoteEvent(
    address _userAddress,
    uint _claimId,
    bytes4 _typeOf,
    uint _tokens,
    uint _submitDate,
    int8 _verdict
  ) external;

  function callClaimEvent(
    uint _coverId,
    address _userAddress,
    uint _claimId,
    uint _datesubmit
  ) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getClaimOfEmergencyPauseByIndex(
    uint _index
  )
  external
  view
  returns (
    uint coverId,
    uint dateUpd,
    bool submit
  );

  function getAllClaimsByIndex(
    uint _claimId
  )
  external
  view
  returns (
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getUserClaimVoteCA(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getUserClaimVoteMember(
    address _add,
    uint _claimId
  )
  external
  view
  returns (uint idVote);

  function getAllVoteLength() external view returns (uint voteCount);

  function getClaimStatusNumber(uint _claimId) external view returns (uint claimId, uint statno);

  function getRewardStatus(uint statusNumber) external view returns (uint percCA, uint percMV);

  function getClaimState12Count(uint _claimId) external view returns (uint num);

  function getClaimDateUpd(uint _claimId) external view returns (uint dateupd);

  function getAllClaimsByAddress(address _member) external view returns (uint[] memory claimarr);


  function getClaimsTokenCA(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );

  function getClaimsTokenMV(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint accept,
    uint deny
  );
  function getCaClaimVotesToken(uint _claimId) external view returns (uint claimId, uint cnt);

  function getMemberClaimVotesToken(
    uint _claimId
  )
  external
  view
  returns (uint claimId, uint cnt);

  function getVoteDetails(uint _voteid)
  external view
  returns (
    uint tokens,
    uint claimId,
    int8 verdict,
    bool rewardClaimed
  );

  function getVoterVote(uint _voteid) external view returns (address voter);

  function getClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint coverId,
    int8 vote,
    uint status,
    uint dateUpd,
    uint state12Count
  );

  function getClaimVoteLength(
    uint _claimId,
    uint8 _ca
  )
  external
  view
  returns (uint claimId, uint len);

  function getVoteVerdict(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (int8 ver);

  function getVoteToken(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (uint tok);

  function getVoteVoter(
    uint _claimId,
    uint _index,
    uint8 _ca
  )
  external
  view
  returns (address voter);

  function getUserClaimCount(address _add) external view returns (uint len);

  function getClaimLength() external view returns (uint len);

  function actualClaimLength() external view returns (uint len);


  function getClaimFromNewStart(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint coverid,
    uint claimId,
    int8 voteCA,
    int8 voteMV,
    uint statusnumber
  );

  function getUserClaimByIndex(
    uint _index,
    address _add
  )
  external
  view
  returns (
    uint status,
    uint coverid,
    uint claimId
  );

  function getAllVotesForClaim(
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint[] memory ca,
    uint[] memory mv
  );


  function getTokensClaim(
    address _of,
    uint _claimId
  )
  external
  view
  returns (
    uint claimId,
    uint tokens
  );

  function getRewardDistributedIndex(
    address _voter
  )
  external
  view
  returns (
    uint lastCAvoteIndex,
    uint lastMVvoteIndex
  );

  function getClaimRewardDetail(
    uint claimid
  )
  external
  view
  returns (
    uint percCA,
    uint percMV,
    uint tokens
  );

  function getClaimCoverId(uint _claimId) external view returns (uint claimId, uint coverid);

  function getClaimVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getClaimMVote(uint _claimId, int8 _verdict) external view returns (uint claimId, uint token);

  function getVoteAddressCA(address _voter, uint index) external view returns (uint);

  function getVoteAddressMember(address _voter, uint index) external view returns (uint);

  function getVoteAddressCALength(address _voter) external view returns (uint);

  function getVoteAddressMemberLength(address _voter) external view returns (uint);

  function getFinalVerdict(uint _claimId) external view returns (int8 verdict);

  function getLengthOfClaimSubmittedAtEP() external view returns (uint len);

  function getFirstClaimIndexToSubmitAfterEP() external view returns (uint indexToSubmit);

  function getLengthOfClaimVotingPause() external view returns (uint len);

  function getPendingClaimDetailsByIndex(
    uint _index
  )
  external
  view
  returns (
    uint claimId,
    uint pendingTime,
    bool voting
  );

  function getFirstClaimIndexToStartVotingAfterEP() external view returns (uint firstindex);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IClaimsReward {

  /// @dev Decides the next course of action for a given claim.
  function changeClaimStatus(uint claimid) external;

  function getCurrencyAssetAddress(bytes4 currency) external view returns (address);

  function getRewardToBeGiven(
    uint check,
    uint voteid,
    uint flag
  )
  external
  view
  returns (
    uint tokenCalculated,
    bool lastClaimedCheck,
    uint tokens,
    uint perc
  );

  function upgrade(address _newAdd) external;

  function getRewardToBeDistributedByUser(address _add) external view returns (uint total);

  function getRewardAndClaimedStatus(uint check, uint claimId) external view returns (uint reward, bool claimed);

  function claimAllPendingReward(uint records) external;

  function getAllPendingRewardOfUser(address _add) external view returns (uint);

  function unlockCoverNote(uint coverId) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IIncidents {

  function underlyingToken(address) external view returns (address);

  function coveredToken(address) external view returns (address);

  function claimPayout(uint) external view returns (uint);

  function incidentCount() external view returns (uint);

  function addIncident(
    address productId,
    uint incidentDate,
    uint priceBefore
  ) external;

  function redeemPayoutForMember(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address member
  ) external returns (uint claimId, uint payoutAmount, address payoutToken);

  function redeemPayout(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount
  ) external returns (uint claimId, uint payoutAmount, address payoutToken);

  function pushBurns(address productId, uint maxIterations) external;

  function withdrawAsset(address asset, address destination, uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMCR {

  function updateMCRInternal(uint poolValueInEth, bool forceUpdate) external;
  function getMCR() external view returns (uint);


  function maxMCRFloorIncrement() external view returns (uint24);

  function mcrFloor() external view returns (uint112);
  function mcr() external view returns (uint112);
  function desiredMCR() external view returns (uint112);
  function lastUpdateTime() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  function payJoiningFee(address _userAddress) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function swapOwner(address _newOwnerAddress) external;

  function kycVerdict(address payable _userAddress, bool verdict) external;

  function getClaimPayoutAddress(address payable _member) external view returns (address payable);

  function setClaimPayoutAddress(address payable _address) external;

  function totalRoles() external view returns (uint256);

  function changeAuthorized(uint _roleId, address _newAuthorized) external;

  function members(uint _memberRoleId) external view returns (uint, address[] memory memberArray);

  function numberOfMembers(uint _memberRoleId) external view returns (uint);

  function authorized(uint _memberRoleId) external view returns (address);

  function roles(address _memberAddress) external view returns (uint[] memory);

  function checkRole(address _memberAddress, uint _roleId) external view returns (bool);

  function getMemberLengthForAllRoles() external view returns (uint[] memory totalMembers);

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool);

  function membersLength(uint _memberRoleId) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./IPriceFeedOracle.sol";

interface IPool {
  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function minPoolEth() external returns (uint);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setAssetDataLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssetDetails(address _asset) external view returns (
    uint112 min,
    uint112 max,
    uint32 lastAssetSwapTime,
    uint maxSlippageRatio
  );

  function sendClaimPayout (
    address asset,
    address payable payoutAddress,
    uint amount
  ) external returns (bool success);

  function transferAsset(
    address asset,
    address payable destination,
    uint amount
  ) external;

  function upgradeCapitalPool(address payable newPoolAddress) external;

  function priceFeedOracle() external view returns (IPriceFeedOracle);

  function getPoolValueInEth() external view returns (uint);


  function transferAssetFrom(address asset, address from, uint amount) external;

  function getEthForNXM(uint nxmAmount) external view returns (uint ethAmount);

  function calculateEthForNXM(
    uint nxmAmount,
    uint currentTotalAssetValue,
    uint mcrEth
  ) external pure returns (uint);

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) external pure returns (uint tokenPrice);

  function getTokenPrice(address asset) external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IPooledStaking {

  function accumulateReward(address contractAddress, uint amount) external;

  function pushBurn(address contractAddress, uint amount) external;

  function hasPendingActions() external view returns (bool);

  function processPendingActions(uint maxIterations) external returns (bool finished);

  function contractStake(address contractAddress) external view returns (uint);

  function stakerReward(address staker) external view returns (uint);

  function stakerDeposit(address staker) external view returns (uint);

  function stakerContractStake(address staker, address contractAddress) external view returns (uint);

  function withdraw(uint amount) external;

  function stakerMaxWithdrawable(address stakerAddress) external view returns (uint);

  function withdrawReward(address stakerAddress) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IQuotationData {

  function authQuoteEngine() external view returns (address);
  function stlp() external view returns (uint);
  function stl() external view returns (uint);
  function pm() external view returns (uint);
  function minDays() external view returns (uint);
  function tokensRetained() external view returns (uint);
  function kycAuthAddress() external view returns (address);

  function refundEligible(address) external view returns (bool);
  function holdedCoverIDStatus(uint) external view returns (uint);
  function timestampRepeated(uint) external view returns (bool);

  enum HCIDStatus {NA, kycPending, kycPass, kycFailedOrRefunded, kycPassNoCover}
  enum CoverStatus {Active, ClaimAccepted, ClaimDenied, CoverExpired, ClaimSubmitted, Requested}

  function addInTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssuredSC(address _add, bytes4 _curr, uint _amount) external;

  function subFromTotalSumAssured(bytes4 _curr, uint _amount) external;

  function addInTotalSumAssured(bytes4 _curr, uint _amount) external;

  function setTimestampRepeated(uint _timestamp) external;

  /// @dev Creates a blank new cover.
  function addCover(
    uint16 _coverPeriod,
    uint _sumAssured,
    address payable _userAddress,
    bytes4 _currencyCode,
    address _scAddress,
    uint premium,
    uint premiumNXM
  ) external;


  function addHoldCover(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod
  ) external;

  function setRefundEligible(address _add, bool status) external;

  function setHoldedCoverIDStatus(uint holdedCoverID, uint status) external;

  function setKycAuthAddress(address _add) external;

  function changeAuthQuoteEngine(address _add) external;

  function getUintParameters(bytes8 code) external view returns (bytes8 codeVal, uint val);

  function getProductDetails()
  external
  view
  returns (
    uint _minDays,
    uint _pm,
    uint _stl,
    uint _stlp
  );

  function getCoverLength() external view returns (uint len);

  function getAuthQuoteEngine() external view returns (address _add);

  function getTotalSumAssured(bytes4 _curr) external view returns (uint amount);

  function getAllCoversOfUser(address _add) external view returns (uint[] memory allCover);

  function getUserCoverLength(address _add) external view returns (uint len);

  function getCoverStatusNo(uint _cid) external view returns (uint8);

  function getCoverPeriod(uint _cid) external view returns (uint32 cp);

  function getCoverSumAssured(uint _cid) external view returns (uint sa);

  function getCurrencyOfCover(uint _cid) external view returns (bytes4 curr);

  function getValidityOfCover(uint _cid) external view returns (uint date);

  function getscAddressOfCover(uint _cid) external view returns (uint, address);

  function getCoverMemberAddress(uint _cid) external view returns (address payable _add);

  function getCoverPremiumNXM(uint _cid) external view returns (uint _premiumNXM);

  function getCoverDetailsByCoverID1(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    address _memberAddress,
    address _scAddress,
    bytes4 _currencyCode,
    uint _sumAssured,
    uint premiumNXM
  );

  function getCoverDetailsByCoverID2(
    uint _cid
  )
  external
  view
  returns (
    uint cid,
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil
  );

  function getHoldedCoverDetailsByID1(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address scAddress,
    bytes4 coverCurr,
    uint16 coverPeriod
  );

  function getUserHoldedCoverLength(address _add) external view returns (uint);

  function getUserHoldedCoverByIndex(address _add, uint index) external view returns (uint);

  function getHoldedCoverDetailsByID2(
    uint _hcid
  )
  external
  view
  returns (
    uint hcid,
    address payable memberAddress,
    uint[] memory coverDetails
  );

  function getTotalSumAssuredSC(address _add, bytes4 _curr) external view returns (uint amount);

  function changeCoverStatusNo(uint _cid, uint8 _stat) external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ITokenController {

  function coverInfo(uint id) external view returns (uint16 claimCount, bool hasOpenClaim, bool hasAcceptedClaim);

  function claimSubmissionGracePeriod() external view returns (uint);

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function markCoverClaimOpen(uint coverId) external;

  function markCoverClaimClosed(uint coverId, bool isAccepted) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function lockClaimAssessmentTokens(uint256 _amount, uint256 _time) external;

  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);

  function mintCoverNote(
    address _of,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) external;

  function extendClaimAssessmentLock(uint256 _time) external;

  function extendLockOf(address _of, bytes32 _reason, uint256 _time) external returns (bool);

  function increaseClaimAssessmentLock(uint256 _amount) external;

  function burnFrom(address _of, uint amount) external returns (bool);

  function burnLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function reduceLock(address _of, bytes32 _reason, uint256 _time) external;

  function releaseLockedTokens(address _of, bytes32 _reason, uint256 _amount) external;

  function addToWhitelist(address _member) external;

  function removeFromWhitelist(address _member) external;

  function mint(address _member, uint _amount) external;

  function lockForMemberVote(address _of, uint _days) external;
  function withdrawClaimAssessmentTokens(address _of) external;

  function getLockReasons(address _of) external view returns (bytes32[] memory reasons);

  function getLockedTokensValidity(address _of, bytes32 reason) external view returns (uint256 validity);

  function getUnlockableTokens(address _of) external view returns (uint256 unlockableTokens);

  function tokensLocked(address _of, bytes32 _reason) external view returns (uint256 amount);

  function tokensLockedWithValidity(address _of, bytes32 _reason)
  external
  view
  returns (uint256 amount, uint256 validity);

  function tokensUnlockable(address _of, bytes32 _reason) external view returns (uint256 amount);

  function totalSupply() external view returns (uint256);

  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) external view returns (uint256 amount);
  function totalBalanceOf(address _of) external view returns (uint256 amount);

  function totalLockedBalance(address _of) external view returns (uint256 amount);
}

pragma solidity ^0.5.0;

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

pragma solidity ^0.5.5;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isOwner(address _add) external view returns (bool);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function dAppLocker() external view returns (address _add);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IPriceFeedOracle {

  function daiAddress() external view returns (address);
  function stETH() external view returns (address);
  function ETH() external view returns (address);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);

}

