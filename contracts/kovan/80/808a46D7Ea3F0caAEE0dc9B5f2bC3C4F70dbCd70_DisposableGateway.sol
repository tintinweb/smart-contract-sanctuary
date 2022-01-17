// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "../../modules/cover/Gateway.sol";

contract DisposableGateway is Gateway {

  function initialize(address masterAddress, address daiAddress) external {
    master = INXMMaster(masterAddress);
    DAI = daiAddress;
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/ILegacyClaims.sol";
import "../../interfaces/ILegacyClaimsData.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IGateway.sol";
import "../../interfaces/ILegacyIncidents.sol";
import "../../interfaces/IMemberRoles.sol";
import "../../interfaces/INXMToken.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IQuotation.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/ICover.sol";

contract Gateway is IGateway, MasterAware {

  /* ============ CONSTANTS ============== */

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /* ========== STATE VARIABLES ========== */

  IQuotation public quotation;
  INXMToken public nxmToken;
  ITokenController public tokenController;
  IQuotationData public quotationData;
  ILegacyClaimsData public claimsData;
  ILegacyClaims public claims;
  IPool public pool;
  IMemberRoles public memberRoles;

  // assigned in initialize
  address public DAI;

  ILegacyIncidents public incidents;
  ICover public cover;


  function changeDependentContractAddress() external {
    quotation = IQuotation(master.getLatestAddress("QT"));
    nxmToken = INXMToken(master.tokenAddress());
    tokenController = ITokenController(master.getLatestAddress("TC"));
    quotationData = IQuotationData(master.getLatestAddress("QD"));
    claimsData = ILegacyClaimsData(master.getLatestAddress("CD"));
    claims = ILegacyClaims(master.getLatestAddress("CL"));
    incidents = ILegacyIncidents(master.getLatestAddress("IC"));
    pool = IPool(master.getLatestAddress("P1"));
    memberRoles = IMemberRoles(master.getLatestAddress("MR"));
    cover = ICover(master.getLatestAddress("CO"));
  }

  function initializeDAI() external {
    DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  }

  function getCoverPrice (
    address /* contractAddress */,
    address /* coverAsset */,
    uint /* sumAssured */,
    uint16 /* coverPeriod */,
    CoverType /* coverType */,
    bytes calldata data
  ) external override view returns (uint coverPrice) {

    // mark function as view instead of pure for future compatibility
    this;

    (
    coverPrice,
    /* coverPriceNXM */,
    /* generatedAt */,
    /* expiresAt */,
    /* _v */,
    /* _r */,
    /* _s */
    ) = abi.decode(data, (uint, uint, uint, uint, uint8, bytes32, bytes32));
  }

  function buyCover (
    address contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    CoverType coverType,
    bytes calldata data
  ) external override payable onlyMember whenNotPaused returns (uint) {

    // only 1 cover type supported at this time
    require(coverType == CoverType.SIGNED_QUOTE_CONTRACT_COVER, "Gateway: Unsupported cover type");
    require(sumAssured % 10 ** assetDecimals(coverAsset) == 0, "Gateway: Only whole unit sumAssured supported");

    {
      (
      uint[] memory coverDetails,
      uint8 _v,
      bytes32 _r,
      bytes32 _s
      ) = convertToLegacyQuote(sumAssured, data, coverAsset);

      {
        uint premiumAmount = coverDetails[1];
        if (coverAsset == ETH) {
          require(msg.value == premiumAmount, "Gateway: ETH amount does not match premium");
          // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
          (bool ok, /* data */) = address(pool).call{value: premiumAmount}("");
          require(ok, "Gateway: Transfer to Pool failed");
        } else {
          IERC20 token = IERC20(coverAsset);
          token.transferFrom(msg.sender, address(pool), premiumAmount);
        }
      }

      quotation.createCover(
        payable(msg.sender),
        contractAddress,
        getCurrencyFromAssetAddress(coverAsset),
        coverDetails,
        coverPeriod, _v, _r, _s
      );
    }

    uint coverId = quotationData.getCoverLength() - 1;
    emit CoverBought(coverId, msg.sender, contractAddress, coverAsset, sumAssured, coverPeriod, coverType, data);
    return coverId;
  }

  /// @dev Migrates covers from V1 to V2
  ///
  /// @param coverId     V1 cover identifier
  /// @param data        Additional data that can be passed by Distributor.sol callers
  function submitClaim(uint coverId, bytes calldata data) external override returns (uint) {
    // [todo] Maybe we could use data to specify other addresses and only use tx.origin if empty,
    // thus allowing multisigs to migrate a cover in one tx without an EOA being involved.
    cover.migrateCoverFromOwner(coverId, msg.sender, tx.origin);
  }

  function claimTokens(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address coveredToken
  ) external override returns (uint claimId, uint payoutAmount, address payoutToken) {
    IERC20 token = IERC20(coveredToken);
    token.transferFrom(msg.sender, address(this), coveredTokenAmount);
    token.approve(address(incidents), coveredTokenAmount);
    (claimId, payoutAmount, payoutToken) = incidents.redeemPayoutForMember(
      coverId,
      coverId,
      coveredTokenAmount,
      msg.sender
    );
  }

  function getClaimCoverId(uint claimId) public override view returns (uint) {
    (, uint coverId) = claimsData.getClaimCoverId(claimId);
    return coverId;
  }

  function getPayoutOutcome(uint claimId) external override view returns (
    ClaimStatus status,
    uint amountPaid,
    address coverAsset
  ) {
    (, uint coverId) = claimsData.getClaimCoverId(claimId);
    (, uint internalClaimStatus) = claimsData.getClaimStatusNumber(claimId);

    coverAsset = getCurrencyAssetAddress(quotationData.getCurrencyOfCover(coverId));
    if (internalClaimStatus == 14) {
      (,address productId) = quotationData.getscAddressOfCover(coverId);
      address coveredTokenAddress = incidents.coveredToken(productId);
      if (coveredTokenAddress != address(0)) {
        amountPaid = incidents.claimPayout(claimId);
      } else {
        amountPaid = quotationData.getCoverSumAssured(coverId) * 10 ** assetDecimals(coverAsset);
      }
    } else {
      amountPaid = 0;
    }

    if (internalClaimStatus == 6 || internalClaimStatus == 9 || internalClaimStatus == 11) {
      status = ClaimStatus.REJECTED;
    } else if (internalClaimStatus == 13 || internalClaimStatus == 14) {
      status = ClaimStatus.ACCEPTED;
    } else {
      status = ClaimStatus.IN_PROGRESS;
    }
  }

  function getCover(uint coverId) public override view returns (
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil,
    address contractAddress,
    address coverAsset,
    uint premiumInNXM,
    address memberAddress
  ) {
    bytes4 currency;
    (/*cid*/, memberAddress, contractAddress, currency, /*sumAssured*/, premiumInNXM) = quotationData.getCoverDetailsByCoverID1(coverId);
    (/*cid*/, status, sumAssured, coverPeriod, validUntil) = quotationData.getCoverDetailsByCoverID2(coverId);

    coverAsset = getCurrencyAssetAddress(currency);
    sumAssured = sumAssured * 10 ** assetDecimals(coverAsset);
  }

  function switchMembership(address newAddress) external override {
    memberRoles.switchMembershipOf(msg.sender, newAddress);
    nxmToken.transferFrom(msg.sender, newAddress, nxmToken.balanceOf(msg.sender));
  }

  function executeCoverAction(
    uint /* tokenId */,
    uint8 /* action */,
    bytes calldata /* data */
  ) external override payable returns (bytes memory, uint) {
    revert("Gateway: Unsupported action");
  }

  function convertToLegacyQuote(uint sumAssured, bytes memory data, address asset)
    internal view returns (uint[] memory coverDetails, uint8, bytes32, bytes32) {
    (
    uint coverPrice,
    uint coverPriceNXM,
    uint expiresAt,
    uint generatedAt,
    uint8 v,
    bytes32 r,
    bytes32 s
    ) = abi.decode(data, (uint, uint, uint, uint, uint8, bytes32, bytes32));
    coverDetails = new uint[](5);
    // convert from wei to units
    coverDetails[0] = sumAssured / 10 ** assetDecimals(asset);
    coverDetails[1] = coverPrice;
    coverDetails[2] = coverPriceNXM;
    coverDetails[3] = expiresAt;
    coverDetails[4] = generatedAt;
    return (coverDetails, v, r, s);
  }

  function assetDecimals(address asset) public view returns (uint) {
    return asset == ETH ? 18 : IERC20Detailed(asset).decimals();
  }

  function getCurrencyFromAssetAddress(address asset) public view returns (bytes4) {

    if (asset == ETH) {
      return "ETH";
    }

    if (asset == DAI) {
      return "DAI";
    }

    revert("Gateway: unknown asset");
  }

  function getCurrencyAssetAddress(bytes4 currency) public view returns (address) {

    if (currency == "ETH") {
      return ETH;
    }

    if (currency == "DAI") {
      return DAI;
    }

    revert("Gateway: unknown currency");
  }

  event CoverBought(
    uint coverId,
    address indexed buyer,
    address indexed contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    CoverType indexed coverType,
    bytes data
  );

  event ClaimSubmitted(
    uint indexed claimId,
    uint indexed coverId,
    address indexed submitter,
    bytes data
  );
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

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

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyClaims {

  function setClaimStatus(uint claimId, uint stat) external;

  function getCATokens(uint claimId, uint member) external view returns (uint tokens);

  function submitClaimAfterEPOff() external pure;

  function submitCAVote(uint claimId, int8 verdict) external;

  function submitMemberVote(uint claimId, int8 verdict) external;

  function pauseAllPendingClaimsVoting() external pure;

  function startAllPendingClaimsVoting() external pure;

  function checkVoteClosing(uint claimId) external view returns (int8 close);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyClaimsData {

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

interface IERC20Detailed {

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IGateway {

  enum ClaimStatus { IN_PROGRESS, ACCEPTED, REJECTED }

  enum CoverType { SIGNED_QUOTE_CONTRACT_COVER }

  function buyCover (
    address contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    CoverType coverType,
    bytes calldata data
  ) external payable returns (uint);

  function getCoverPrice (
    address contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    CoverType coverType,
    bytes calldata data
  ) external view returns (uint coverPrice);

  function getCover(uint coverId)
  external
  view
  returns (
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil,
    address contractAddress,
    address coverAsset,
    uint premiumInNXM,
    address memberAddress
  );

  function submitClaim(uint coverId, bytes calldata data) external returns (uint);

  function claimTokens(
    uint coverId,
    uint incidentId,
    uint coveredTokenAmount,
    address coverAsset
  ) external returns (uint claimId, uint payoutAmount, address payoutToken);

  function getClaimCoverId(uint claimId) external view returns (uint);

  function getPayoutOutcome(uint claimId) external view returns (ClaimStatus status, uint paidAmount, address asset);

  function executeCoverAction(uint tokenId, uint8 action, bytes calldata data) external payable returns (bytes memory, uint);

  function switchMembership(address _newAddress) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ILegacyIncidents {

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

interface IMemberRoles {

  enum Role {UnAssigned, AdvisoryBoard, Member, Owner}

  function payJoiningFee(address _userAddress) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipAndAssets(
    address newAddress,
    uint[] calldata coverIds,
    address[] calldata stakingPools
  ) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function swapOwner(address _newOwnerAddress) external;

  function addInitialABMembers(address[] calldata abArray) external;

  function kycVerdict(address payable _userAddress, bool verdict) external;

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

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMToken {

  function burn(uint256 amount) external returns (bool);

  function burnFrom(address from, uint256 value) external returns (bool);

  function operatorTransfer(address from, uint256 value) external returns (bool);

  function mint(address account, uint256 amount) external;

  function isLockedForMV(address member) external view returns (uint);

  function addToWhiteList(address _member) external returns (bool);

  function removeFromWhiteList(address _member) external returns (bool);

  function changeOperator(address _newOperator) external returns (bool);

  function lockForMemberVote(address _of, uint _days) external;

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./IPriceFeedOracle.sol";

interface IPool {

  struct SwapDetails {
    uint104 minAmount;
    uint104 maxAmount;
    uint32 lastSwapTime;
    // 2 decimals of precision. 0.01% -> 0.0001 -> 1e14
    uint16 maxSlippageRatio;
  }

  struct Asset {
    address assetAddress;
    uint8 decimals;
    bool deprecated;
  }

  function assets(uint index) external view returns (
    address assetAddress,
    uint8 decimals,
    bool deprecated
  );

  function buyNXM(uint minTokensOut) external payable;

  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function minPoolEth() external returns (uint);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setSwapDetailsLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssets() external view returns (
    address[] memory assetAddresses,
    uint8[] memory decimals,
    bool[] memory deprecated
  );

  function getAssetSwapDetails(address assetAddress) external view returns (
    uint104 min,
    uint104 max,
    uint32 lastAssetSwapTime,
    uint16 maxSlippageRatio
  );

  function getNXMForEth(uint ethAmount) external view returns (uint);

  function sendPayout (
    uint assetIndex,
    address payable payoutAddress,
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

  function getTokenPrice(uint assetId) external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IQuotation {
  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
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

import "./INXMToken.sol";

interface ITokenController {

  struct CoverInfo {
    uint16 claimCount;
    bool hasOpenClaim;
    bool hasAcceptedClaim;
    // note: still 224 bits available here, can be used later
  }

  function coverInfo(uint id) external view returns (uint16 claimCount, bool hasOpenClaim, bool hasAcceptedClaim);

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function lockOf(address _of, bytes32 _reason, uint256 _amount, uint256 _time) external returns (bool);

  function extendLockOf(address _of, bytes32 _reason, uint256 _time) external returns (bool);

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

  function token() external view returns (INXMToken);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ICover {

  /* ========== DATA STRUCTURES ========== */

  enum RedeemMethod {
    Claim,
    Incident
  }

  // Basically CoverStatus from QuotationData.sol but with the extra Migrated status to avoid
  // polluting Cover.sol state layout with new status variables.
  enum LegacyCoverStatus {
    Active,
    ClaimAccepted,
    ClaimDenied,
    CoverExpired,
    ClaimSubmitted,
    Requested,
    Migrated
  }

  struct PoolAllocationRequest {
    uint64 poolId;
    uint coverAmountInAsset;
  }

  struct PoolAllocation {
    uint64 poolId;
    uint96 coverAmountInNXM;
    uint96 premiumInNXM;
  }

  struct CoverData {
    uint24 productId;
    uint8 payoutAsset;
    uint96 amountPaidOut;
  }

  struct CoverSegment {
    uint96 amount;
    uint32 start;
    uint32 period;  // seconds
    uint16 priceRatio;
  }

  struct BuyCoverParams {
    address owner;
    uint24 productId;
    uint8 payoutAsset;
    uint96 amount;
    uint32 period;
    uint maxPremiumInAsset;
    uint8 paymentAsset;
    bool payWithNXM;
    uint16 commissionRatio;
    address commissionDestination;
  }

  struct IncreaseAmountAndReducePeriodParams {
    uint coverId;
    uint32 periodReduction;
    uint96 amount;
    uint8 paymentAsset;
    uint maxPremiumInAsset;
  }

  struct ProductBucket {
    uint96 coverAmountExpiring;
  }

  struct IncreaseAmountParams {
    uint coverId;
    uint8 paymentAsset;
    PoolAllocationRequest[] coverChunkRequests;
  }

  struct Product {
    uint16 productType;
    address productAddress;
    /*
      cover assets bitmap. each bit in the base-2 representation represents whether the asset with the index
      of that bit is enabled as a cover asset for this product.
    */
    uint32 coverAssets;
    uint16 initialPriceRatio;
    uint16 capacityReductionRatio;
  }

  struct ProductType {
    string descriptionIpfsHash;
    uint8 redeemMethod;
    uint16 gracePeriodInDays;
  }

  /* ========== VIEWS ========== */

  function covers(uint id) external view returns (uint24, uint8, uint96, uint32, uint32, uint16);

  function products(uint id) external view returns (uint16, address, uint32, uint16, uint16);

  function productTypes(uint id) external view returns (string memory, uint8, uint16);

  /* === MUTATIVE FUNCTIONS ==== */

  function migrateCover(uint coverId, address toNewOwner) external;

  function migrateCoverFromOwner(uint coverId, address fromOwner, address toNewOwner) external;

  function buyCover(
    BuyCoverParams calldata params,
    PoolAllocationRequest[] calldata coverChunkRequests
  ) external payable returns (uint /*coverId*/);

  function createStakingPool(address manager) external;

  function setInitialPrices(
    uint[] calldata productId,
    uint16[] calldata initialPriceRatio
  ) external;

  function addProducts(Product[] calldata newProducts) external;

  function addProductTypes(ProductType[] calldata newProductTypes) external;

  function setCoverAssetsFallback(uint32 _coverAssetsFallback) external;

  function performPayoutBurn(uint coverId, uint amount) external returns (address /*owner*/);

  function coverNFT() external returns (address);

  function transferCovers(address from, address to, uint256[] calldata coverIds) external;

  /* ========== EVENTS ========== */

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