// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../abstract/MasterAware.sol";
import "../../interfaces/IClaimsReward.sol";
import "../../interfaces/IIncidents.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IPooledStaking.sol";
import "../../interfaces/IQuotation.sol";
import "../../interfaces/IQuotationData.sol";
import "../../interfaces/ITokenController.sol";
import "../../interfaces/ITokenData.sol";

contract Quotation is IQuotation, MasterAware, ReentrancyGuard {
  using SafeMath for uint;

  IClaimsReward public cr;
  IPool public pool;
  IPooledStaking public pooledStaking;
  IQuotationData public qd;
  ITokenController public tc;
  ITokenData public td;
  IIncidents public incidents;

  /**
   * @dev Iupgradable Interface to update dependent contract address
   */
  function changeDependentContractAddress() public onlyInternal {
    cr = IClaimsReward(master.getLatestAddress("CR"));
    pool = IPool(master.getLatestAddress("P1"));
    pooledStaking = IPooledStaking(master.getLatestAddress("PS"));
    qd = IQuotationData(master.getLatestAddress("QD"));
    tc = ITokenController(master.getLatestAddress("TC"));
    td = ITokenData(master.getLatestAddress("TD"));
    incidents = IIncidents(master.getLatestAddress("IC"));
  }

  // solhint-disable-next-line no-empty-blocks
  function sendEther() public payable {}

  /**
   * @dev Expires a cover after a set period of time and changes the status of the cover
   * @dev Reduces the total and contract sum assured
   * @param coverId Cover Id.
   */
  function expireCover(uint coverId) external {

    uint expirationDate = qd.getValidityOfCover(coverId);
    require(expirationDate < now, "Quotation: cover is not due to expire");

    uint coverStatus = qd.getCoverStatusNo(coverId);
    require(coverStatus != uint(IQuotationData.CoverStatus.CoverExpired), "Quotation: cover already expired");

    (/* claim count */, bool hasOpenClaim, /* accepted */) = tc.coverInfo(coverId);
    require(!hasOpenClaim, "Quotation: cover has an open claim");

    if (coverStatus != uint(IQuotationData.CoverStatus.ClaimAccepted)) {
      (,, address contractAddress, bytes4 currency, uint amount,) = qd.getCoverDetailsByCoverID1(coverId);
      qd.subFromTotalSumAssured(currency, amount);
      qd.subFromTotalSumAssuredSC(contractAddress, currency, amount);
    }

    qd.changeCoverStatusNo(coverId, uint8(IQuotationData.CoverStatus.CoverExpired));
  }

  function withdrawCoverNote(address coverOwner, uint[] calldata coverIds, uint[] calldata reasonIndexes) external {

    uint gracePeriod = tc.claimSubmissionGracePeriod();

    for (uint i = 0; i < coverIds.length; i++) {
      uint expirationDate = qd.getValidityOfCover(coverIds[i]);
      require(expirationDate.add(gracePeriod) < now, "Quotation: cannot withdraw before grace period expiration");
    }

    tc.withdrawCoverNote(coverOwner, coverIds, reasonIndexes);
  }

  function getWithdrawableCoverNoteCoverIds(
    address coverOwner
  ) public view returns (
    uint[] memory expiredCoverIds,
    bytes32[] memory lockReasons
  ) {

    uint[] memory coverIds = qd.getAllCoversOfUser(coverOwner);
    uint[] memory expiredIdsQueue = new uint[](coverIds.length);
    uint gracePeriod = tc.claimSubmissionGracePeriod();
    uint expiredQueueLength = 0;

    for (uint i = 0; i < coverIds.length; i++) {

      uint coverExpirationDate = qd.getValidityOfCover(coverIds[i]);
      uint gracePeriodExpirationDate = coverExpirationDate.add(gracePeriod);
      (/* claimCount */, bool hasOpenClaim, /* hasAcceptedClaim */) = tc.coverInfo(coverIds[i]);

      if (!hasOpenClaim && gracePeriodExpirationDate < now) {
        expiredIdsQueue[expiredQueueLength] = coverIds[i];
        expiredQueueLength++;
      }
    }

    expiredCoverIds = new uint[](expiredQueueLength);
    lockReasons = new bytes32[](expiredQueueLength);

    for (uint i = 0; i < expiredQueueLength; i++) {
      expiredCoverIds[i] = expiredIdsQueue[i];
      lockReasons[i] = keccak256(abi.encodePacked("CN", coverOwner, expiredIdsQueue[i]));
    }
  }

  function getWithdrawableCoverNotesAmount(address coverOwner) external view returns (uint) {

    uint withdrawableAmount;
    bytes32[] memory lockReasons;
    (/*expiredCoverIds*/, lockReasons) = getWithdrawableCoverNoteCoverIds(coverOwner);

    for (uint i = 0; i < lockReasons.length; i++) {
      uint coverNoteAmount = tc.tokensLocked(coverOwner, lockReasons[i]);
      withdrawableAmount = withdrawableAmount.add(coverNoteAmount);
    }

    return withdrawableAmount;
  }

  /**
   * @dev Makes Cover funded via NXM tokens.
   * @param smartCAdd Smart Contract Address
   */
  function makeCoverUsingNXMTokens(
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    bytes4 coverCurr,
    address smartCAdd,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyMember whenNotPaused {
    tc.burnFrom(msg.sender, coverDetails[2]); // needs allowance
    _verifyCoverDetails(msg.sender, smartCAdd, coverCurr, coverDetails, coverPeriod, _v, _r, _s, true);
  }

  /**
   * @dev Verifies cover details signed off chain.
   * @param from address of funder.
   * @param scAddress Smart Contract Address
   */
  function verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public onlyInternal {
    _verifyCoverDetails(
      from,
      scAddress,
      coverCurr,
      coverDetails,
      coverPeriod,
      _v,
      _r,
      _s,
      false
    );
  }

  /**
   * @dev Verifies signature.
   * @param coverDetails details related to cover.
   * @param coverPeriod validity of cover.
   * @param contractAddress smart contract address.
   * @param _v argument from vrs hash.
   * @param _r argument from vrs hash.
   * @param _s argument from vrs hash.
   */
  function verifySignature(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public view returns (bool) {
    require(contractAddress != address(0));
    bytes32 hash = getOrderHash(coverDetails, coverPeriod, currency, contractAddress);
    return isValidSignature(hash, _v, _r, _s);
  }

  /**
   * @dev Gets order hash for given cover details.
   * @param coverDetails details realted to cover.
   * @param coverPeriod validity of cover.
   * @param contractAddress smart contract address.
   */
  function getOrderHash(
    uint[] memory coverDetails,
    uint16 coverPeriod,
    bytes4 currency,
    address contractAddress
  ) public view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        coverDetails[0],
        currency,
        coverPeriod,
        contractAddress,
        coverDetails[1],
        coverDetails[2],
        coverDetails[3],
        coverDetails[4],
        address(this)
      )
    );
  }

  /**
   * @dev Verifies signature.
   * @param hash order hash
   * @param v argument from vrs hash.
   * @param r argument from vrs hash.
   * @param s argument from vrs hash.
   */
  function isValidSignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
    address a = ecrecover(prefixedHash, v, r, s);
    return (a == qd.getAuthQuoteEngine());
  }

  /**
   * @dev Creates cover of the quotation, changes the status of the quotation ,
   * updates the total sum assured and locks the tokens of the cover against a quote.
   * @param from Quote member Ethereum address.
   */
  function _makeCover(//solhint-disable-line
    address payable from,
    address contractAddress,
    bytes4 coverCurrency,
    uint[] memory coverDetails,
    uint16 coverPeriod
  ) internal {

    address underlyingToken = incidents.underlyingToken(contractAddress);

    if (underlyingToken != address(0)) {
      address coverAsset = cr.getCurrencyAssetAddress(coverCurrency);
      require(coverAsset == underlyingToken, "Quotation: Unsupported cover asset for this product");
    }

    uint cid = qd.getCoverLength();

    qd.addCover(
      coverPeriod,
      coverDetails[0],
      from,
      coverCurrency,
      contractAddress,
      coverDetails[1],
      coverDetails[2]
    );

    uint coverNoteAmount = coverDetails[2].mul(qd.tokensRetained()).div(100);

    uint gracePeriod = tc.claimSubmissionGracePeriod();
    uint claimSubmissionPeriod = uint(coverPeriod).mul(1 days).add(gracePeriod);
    bytes32 reason = keccak256(abi.encodePacked("CN", from, cid));

    // mint and lock cover note
    td.setDepositCNAmount(cid, coverNoteAmount);
    tc.mintCoverNote(from, reason, coverNoteAmount, claimSubmissionPeriod);

    qd.addInTotalSumAssured(coverCurrency, coverDetails[0]);
    qd.addInTotalSumAssuredSC(contractAddress, coverCurrency, coverDetails[0]);

    uint coverPremiumInNXM = coverDetails[2];
    uint stakersRewardPercentage = td.stakerCommissionPer();
    uint rewardValue = coverPremiumInNXM.mul(stakersRewardPercentage).div(100);
    pooledStaking.accumulateReward(contractAddress, rewardValue);
  }

  /**
   * @dev Makes a cover.
   * @param from address of funder.
   * @param scAddress Smart Contract Address
   */
  function _verifyCoverDetails(
    address payable from,
    address scAddress,
    bytes4 coverCurr,
    uint[] memory coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s,
    bool isNXM
  ) internal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    address asset = cr.getCurrencyAssetAddress(coverCurr);
    if (coverCurr != "ETH" && !isNXM) {
      pool.transferAssetFrom(asset, from, coverDetails[1]);
    }

    require(verifySignature(coverDetails, coverPeriod, coverCurr, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, coverCurr, coverDetails, coverPeriod);
  }

  function createCover(
    address payable from,
    address scAddress,
    bytes4 currency,
    uint[] calldata coverDetails,
    uint16 coverPeriod,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external onlyInternal {

    require(coverDetails[3] > now, "Quotation: Quote has expired");
    require(coverPeriod >= 30 && coverPeriod <= 365, "Quotation: Cover period out of bounds");
    require(!qd.timestampRepeated(coverDetails[4]), "Quotation: Quote already used");
    qd.setTimestampRepeated(coverDetails[4]);

    require(verifySignature(coverDetails, coverPeriod, currency, scAddress, _v, _r, _s), "Quotation: signature mismatch");
    _makeCover(from, scAddress, currency, coverDetails, coverPeriod);
  }

  // referenced in master, keeping for now
  // solhint-disable-next-line no-empty-blocks
  function transferAssetsToNewContract(address) external pure {}

  function freeUpHeldCovers() external nonReentrant {

    IERC20 dai = IERC20(cr.getCurrencyAssetAddress("DAI"));
    uint membershipFee = td.joiningFee();
    uint lastCoverId = 106;

    for (uint id = 1; id <= lastCoverId; id++) {

      if (qd.holdedCoverIDStatus(id) != uint(IQuotationData.HCIDStatus.kycPending)) {
        continue;
      }

      (/*id*/, /*sc*/, bytes4 currency, /*period*/) = qd.getHoldedCoverDetailsByID1(id);
      (/*id*/, address payable userAddress, uint[] memory coverDetails) = qd.getHoldedCoverDetailsByID2(id);

      uint refundedETH = membershipFee;
      uint coverPremium = coverDetails[1];

      if (qd.refundEligible(userAddress)) {
        qd.setRefundEligible(userAddress, false);
      }

      qd.setHoldedCoverIDStatus(id, uint(IQuotationData.HCIDStatus.kycFailedOrRefunded));

      if (currency == "ETH") {
        refundedETH = refundedETH.add(coverPremium);
      } else {
        require(dai.transfer(userAddress, coverPremium), "Quotation: DAI refund transfer failed");
      }

      userAddress.transfer(refundedETH);
    }
  }
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface ITokenData {

  function walletAddress() external view returns (address payable);
  function lockTokenTimeAfterCoverExp() external view returns (uint);
  function bookTime() external view returns (uint);
  function lockCADays() external view returns (uint);
  function lockMVDays() external view returns (uint);
  function scValidDays() external view returns (uint);
  function joiningFee() external view returns (uint);
  function stakerCommissionPer() external view returns (uint);
  function stakerMaxCommissionPer() external view returns (uint);
  function tokenExponent() external view returns (uint);
  function priceStep() external view returns (uint);

  function depositedCN(uint) external view returns (uint amount, bool isDeposited);

  function lastCompletedStakeCommission(address) external view returns (uint);

  function changeWalletAddress(address payable _address) external;

  function getStakerStakedContractByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (address stakedContractAddress);

  function getStakerStakedBurnedByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint burnedAmount);

  function getStakerStakedUnlockableBeforeLastBurnByIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint unlockable);

  function getStakerStakedContractIndex(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint scIndex);

  function getStakedContractStakerIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (uint sIndex);

  function getStakerInitialStakedAmountOnContract(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function getStakerStakedContractLength(
    address _stakerAddress
  )
  external
  view
  returns (uint length);

  function getStakerUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint amount);

  function pushUnlockedStakedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;


  function pushBurnedTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function setUnlockableBeforeLastBurnTokens(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function pushEarnedStakeCommissions(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _stakedContractIndex,
    uint _commissionAmount
  ) external;

  function pushRedeemedStakeCommissions(
    address _stakerAddress,
    uint _stakerIndex,
    uint _amount
  ) external;

  function getStakerEarnedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerRedeemedStakeCommission(
    address _stakerAddress,
    uint _stakerIndex
  )
  external
  view
  returns (uint);

  function getStakerTotalEarnedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionEarned);

  function getStakerTotalReedmedStakeCommission(
    address _stakerAddress
  )
  external
  view
  returns (uint totalCommissionRedeemed);

  function setDepositCN(uint coverId, bool flag) external;

  function getStakedContractStakerByIndex(
    address _stakedContractAddress,
    uint _stakedContractIndex
  )
  external
  view
  returns (address stakerAddress);

  function getStakedContractStakersLength(
    address _stakedContractAddress
  ) external view returns (uint length);

  function addStake(
    address _stakerAddress,
    address _stakedContractAddress,
    uint _amount
  ) external returns (uint scIndex);

  function bookCATokens(address _of) external;

  function isCATokensBooked(address _of) external view returns (bool res);

  function setStakedContractCurrentCommissionIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setLastCompletedStakeCommissionIndex(
    address _stakerAddress,
    uint _index
  ) external;


  function setStakedContractCurrentBurnIndex(
    address _stakedContractAddress,
    uint _index
  ) external;

  function setDepositCNAmount(uint coverId, uint amount) external;
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

