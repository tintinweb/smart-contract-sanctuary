// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/Owned.sol";
import "../lib/IERC20Upgradeable.sol";
import "../lib/SafeERC20Upgradeable.sol";
import "../lib/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IProduct.sol";
import "./BaseProduct.sol";
//import "hardhat/console.sol";

contract Temperature is IProduct, BaseProduct, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public CURR_DATA_HASH;
  uint public CURR_NUM_OF_PLANS;
  uint public MAX_NUM_OF_VOTERS;
  uint public CLAIM_FEE_MULTIPLIER;
  uint public VOTE_FEE_MULTIPLIER;
  uint public APPEAL_FEE_MULTIPLIER;
  uint public NO_CLAIM_PERIOD;
  uint public VOTING_PERIOD;
  uint public APPEAL_PERIOD;
  uint public COLLECTION_PERIOD;

  bytes32[] public dataHashes;
  mapping(bytes32 => Data) public dataMap;

  // cover related
  uint public coverCount;
  uint[] public covers;
  mapping(uint => Cover) public coverMap;
  mapping(address => uint[]) public userCoverMap;

  // claim related
  uint public claimCount;
  uint[] public claims;
  mapping(uint => Claim) public claimMap;
  mapping(address => uint[]) public userClaimMap;

  // vote related
  mapping(address => uint[]) public userVotes; // user => claimId[]
  mapping(address => mapping(uint => Vote)) public userVoteMap;
  mapping(uint => Vote[]) public claimVotes; // claimId => Vote

  // appeal
  uint[] public appeals;


  struct Data {
    string url;
    bytes32 hash;
    uint numOfPlans;
  }

  struct Cover {
    bytes32 dataHash;
    address user;
    uint id;
    uint coverage;
    uint price;
    uint fee;
    uint coverType; // 0 - invalid, 1 - week high, 2 - week low, 3 - month high, 4 - month low
    uint planId;
    uint period;
    uint status;  // 0 - invalid, 1 - covered, 2 - claim submitted, 3 - claim rejected by users, 4 - claim accepted by users,
                  // 5 - appealed, 6 - claim rejected by committee, 7 - claim accepted by committee, 8 - coverage collected.
    uint createdAt;
  }

  struct Claim {
    uint id;
    uint fee;
    uint status; // 0 - 2 invalid, 3 - rejected by users, 4 - accepted by users,
                 // 5 - appealed, 6 - rejected by committee, 7 - approved by committee, 8 - coverage collected.
    uint coverId;
    uint createdAt;
    uint votingEndsAt;
    uint appealEndsAt;
    uint totalReward;
    uint totalApprover;
    uint approverWeight;
    uint rejecterWeight;
  }

  struct Vote {
    address user;
    uint weight;
    bool isApproval;
    bool isRewarded;
  }

  modifier onlyCore() {
    require(msg.sender == core, 'TMP0');
    _;
  }

  /// @notice Initialize the smart contract
  function initialize(
    address ownerAddr,
    address coreAddr,
    address tokenAddr,
    string memory currencyStr,
    uint mcrCoverageRatioE4,
    uint priceCoverageRatioE4
  )
    public
    initializer
  {
    __BaseProduct_init(ownerAddr, coreAddr, tokenAddr, currencyStr, mcrCoverageRatioE4, priceCoverageRatioE4);
    MAX_NUM_OF_VOTERS = 8;
    NO_CLAIM_PERIOD = 7 days;
    VOTING_PERIOD = 3 days;
    APPEAL_PERIOD = 3 days;
    COLLECTION_PERIOD = 3 days;
    CLAIM_FEE_MULTIPLIER = 5;
    VOTE_FEE_MULTIPLIER = 2;
    APPEAL_FEE_MULTIPLIER = 10;
  }

  /// @notice Version of the current implementation
  function version() public virtual pure returns (string memory) {
    return "0.0.2";
  }

  function buyCover(
    uint totalCapitalInETH,
    uint totalMcrInETH,
    uint spkPrice,
    address user,
    uint[] memory coverInfo
  ) external override onlyCore nonReentrant {
    require(coverInfo.length == 6, "TMP1");
    require(coverInfo[0] * getTokenPriceE8() <= totalCapitalInETH * 1e7, "TMP3"); // verify coverage
    // TODO: in frontend, add a slippage
    require(coverInfo[1] >= getCoverPrice(totalCapitalInETH, totalMcrInETH, coverInfo[0]), "TMP4"); // verify price
    require(coverInfo[2] >= getCoverFee(coverInfo[0], spkPrice), "TMP5"); // verify fee
    require(coverInfo[3] >= 1 && coverInfo[3] <= 4, "TMP6"); // verify coverType
    require(coverInfo[4] < CURR_NUM_OF_PLANS, "TMP7"); // verify planId, 0, 1, ..., CURR_NUM_OF_PLANS - 1
    if (coverInfo[3] <= 2) { // verify period
      require(coverInfo[5] >= block.timestamp + 7 days && coverInfo[5] < block.timestamp + 360 days, "TMP8");
    } else {
      require(coverInfo[5] >= block.timestamp + 30 days && coverInfo[5] < block.timestamp + 360 days, "TMP9");
    }

    // add the cover
    Cover memory cover;
    cover.dataHash = CURR_DATA_HASH;
    cover.user = user;
    cover.id = ++coverCount;
    cover.coverage = coverInfo[0];
    cover.price = coverInfo[1];
    cover.fee = coverInfo[2];
    cover.coverType = coverInfo[3];
    cover.planId = coverInfo[4];
    cover.period = coverInfo[5];
    cover.status = 1;
    cover.createdAt = block.timestamp;

    coverMap[cover.id] = cover;
    covers.push(cover.id);
    userCoverMap[user].push(cover.id);

    totalCoverage += cover.coverage;
  }

  /// @notice Get cover price in token
  /// @param totalCapitalInETH Total capital in ETH
  /// @param totalMcrInETH Total MCR in ETH
  /// @param coverage Coverage of the cover in token
  function getCoverPrice(
    uint totalCapitalInETH,
    uint totalMcrInETH,
    uint coverage
  )
    public view override returns(uint)
  {
    uint coverageInETH = coverage * getTokenPriceE8() / 1e8;
    uint price = (coverage * PRICE_COVERAGE_RATIO_E4) / 1e4;
    uint priceInETH = price * getTokenPriceE8() / 1e8;
    uint mcrRatioE4 = (totalMcrInETH * 1e4 + MCR_COVERAGE_RATIO_E4 * coverageInETH)
      / (totalCapitalInETH + priceInETH);

    uint adjustedPrice = (coverage * mcrRatioE4**8) / 1e32;
    if (adjustedPrice < price) {
      return price;
    } else if (adjustedPrice > coverage) {
      return coverage;
    }
    return adjustedPrice;
  }

  function submitClaim(address user, uint coverId, uint claimFee) external override onlyCore nonReentrant {
    Cover storage cover = coverMap[coverId];

    require(cover.status == 1 && cover.user == user && cover.fee*CLAIM_FEE_MULTIPLIER <= claimFee, "TMP10");
    // TODO: to uncomment this line for production
    require(block.timestamp >= cover.period + NO_CLAIM_PERIOD, "TMP11");

    // add claim
    claims.push(++claimCount);
    userClaimMap[user].push(claimCount);
    Claim storage claim = claimMap[claimCount];
    claim.id = claimCount;
    claim.fee = claimFee;
    claim.status = 3; // when submitted, default is rejected by users
    claim.coverId = cover.id;
    claim.totalReward = claimFee;
    claim.createdAt = block.timestamp;
    claim.votingEndsAt = block.timestamp + VOTING_PERIOD;
    claim.appealEndsAt = block.timestamp + VOTING_PERIOD + APPEAL_PERIOD;

    // update cover status
    cover.status = 3; // when submitted, default is approved by users
  }

  /// @notice Vote a claim
  /// @param user The voter
  /// @param claimId The ID of the claim
  /// @param voteFee The fee to vote
  /// @param weight The weight of the claim
  /// @param isApproval The vote is an approval or not
  function voteClaim(
    address user,
    uint claimId,
    uint voteFee,
    uint weight,
    bool isApproval
  ) external override onlyCore nonReentrant {
    Claim storage claim = claimMap[claimId];
    Cover storage cover = coverMap[claim.coverId];
    Vote storage vote = userVoteMap[user][claimId];

    require(weight > 0 &&
      vote.user == address(0) &&
      cover.user != user &&
      voteFee >= cover.fee*VOTE_FEE_MULTIPLIER , "TMP13"
    ); // can't vote more than once

    require(claim.status == 3 || claim.status == 4 , "TMP14");
    require(block.timestamp > claim.createdAt && block.timestamp < claim.votingEndsAt, "TMP15");
    require(claimVotes[claimId].length < MAX_NUM_OF_VOTERS, "TMP16");

    // update userVotes and claimVotes
    vote.user = user;
    vote.weight = weight;
    vote.isApproval = isApproval;
    claimVotes[claimId].push(vote);
    userVotes[user].push(claimId);

    // update the claim
    if (isApproval) {
      claim.approverWeight += weight;
      claim.totalApprover += 1;
    } else {
      claim.rejecterWeight += weight;
    }
    claim.totalReward += voteFee;

    // update the cover status
    if (claim.approverWeight < claim.rejecterWeight) {
      cover.status = 3;
      claim.status = 3;
    } else {
      cover.status = 4;
      claim.status = 4;
    }
  }

  /// @notice Appeal a claim
  /// @param claimId The ID of the claim
  /// @param appealFee The fee to appeal
  function appealClaim(
    uint claimId,
    uint appealFee
  ) external override onlyCore nonReentrant {
    Claim storage claim = claimMap[claimId];
    Cover storage cover = coverMap[claim.coverId];

    require((claim.status == 3 || claim.status == 4) &&
      claim.status == cover.status &&
      claim.fee * APPEAL_FEE_MULTIPLIER <= appealFee,
      "TMP17"
    ); // can only be appealed when rejected or approved by users

    // TODO: enable it on production
    require(block.timestamp > claim.votingEndsAt && block.timestamp < claim.appealEndsAt, "TMP18");

    // update claim
    claim.status = 5;
    claim.totalReward += appealFee;

    // update cover
    cover.status = 5;

    // add appeals
    appeals.push(claimId);
  }

  function processAppeal(
    uint claimId,
    bool isApproval
  ) external override onlyCore nonReentrant returns(uint) {
    Claim storage claim = claimMap[claimId];
    Cover storage cover = coverMap[claim.coverId];
    require(claim.status == 5 && cover.status == 5, "TMP21");

    uint idx = appeals.length + 1;
    for (uint i = 0; i < appeals.length; i++) {
      if (appeals[i] == claimId) {
        idx = i;
        break;
      }
    }
    require(idx < appeals.length, "TMP22");
    appeals[idx] = appeals[appeals.length-1];
    appeals.pop();

    claim.status = isApproval ? 7 : 6;
    cover.status = isApproval ? 7 : 6;

    claim.totalReward -= claim.fee*APPEAL_FEE_MULTIPLIER;

    return claim.fee*APPEAL_FEE_MULTIPLIER;
  }

  /// @notice Collect claim reward
  /// @param user The user to collect the claim reward
  /// @param claimId The ID of the claim
  function collectClaimReward(
    address user,
    uint claimId
  ) external override onlyCore nonReentrant returns(uint) {
    Claim storage claim = claimMap[claimId];
    Cover storage cover = coverMap[claim.coverId];
    Vote storage vote = userVoteMap[user][claimId];
    // only voters can collect rewards, and only once
    require((cover.user == user || vote.user == user) && !vote.isRewarded, "TMP19");
    // TODO: uncomment for production
    require(block.timestamp > claim.appealEndsAt + COLLECTION_PERIOD, "TMP20");

    uint totalVoter = claimVotes[claim.id].length;
    uint reward;
    if ((claim.status == 7 || claim.status == 4) && claim.totalApprover > 0 && vote.isApproval) { // approved
      vote.isRewarded = true;
      reward = claim.totalApprover == 0 ? claim.totalReward : (claim.totalReward / claim.totalApprover);
    } else if ((claim.status == 6 || claim.status == 3) && totalVoter > claim.totalApprover && !vote.isApproval) { // rejected
      vote.isRewarded = true;
      reward = totalVoter == claim.totalApprover ? claim.totalReward : (claim.totalReward / (totalVoter - claim.totalApprover));
    }

    return reward;
  }

  /// @notice Collect coverage
  /// @param user The user to collect the coverage
  /// @param claimId The ID of the claim
  function collectCoverage(
    address user,
    uint claimId
  ) external override onlyCore nonReentrant returns(uint) {
    Claim storage claim = claimMap[claimId];
    Cover storage cover = coverMap[claim.coverId];

    require(cover.user == user && (claim.status == 7 || claim.status == 4) , "TMP21");
    // TODO: uncomment for production
    require(block.timestamp > claim.appealEndsAt + COLLECTION_PERIOD, "TMP22");

    claim.status = 8;
    cover.status = 8;

    return cover.coverage;
  }

  /// @notice Get token of the product
  function getToken() public view override returns(address) {
    return token;
  }

  /// @notice Get MCR of the product, in ETH
  function getTotalMcrInETH() public view override returns(uint) {
    return (totalCoverage * MCR_COVERAGE_RATIO_E4 * getTokenPriceE8()) / 1e12;
  }

  /// @notice Get token price in ETH
  function getTokenPriceE8() public view override returns(uint) {
    return 1e8;
  }

  /// @notice Get fees of cover, in SPK, ~1% of the coverage
  function getCoverFee(uint coverage, uint spkPrice) public view override returns(uint) {
    return (coverage * getTokenPriceE8() * 1e8) / spkPrice;
  }

  function getMcrCoverageRatioE4() public view override returns(uint) {
    return MCR_COVERAGE_RATIO_E4;
  }

  function getPriceCoverageRatioE4() public view override returns(uint) {
    return PRICE_COVERAGE_RATIO_E4;
  }

  function getUserCovers(address user) public view override returns(uint[] memory) {
    return userCoverMap[user];
  }

  function getUserVotes(address user) public view override returns(uint[] memory) {
    return userVotes[user];
  }

  function getUserClaims(address user) public view override returns(uint[] memory) {
    return userClaimMap[user];
  }

  function getAllCovers() public view override returns(uint[] memory) {
    return covers;
  }

  function getAllClaims() public view override returns(uint[] memory) {
    return claims;
  }

  function getAllAppeals() public view override returns(uint[] memory) {
    return appeals;
  }

  function updateData(string calldata url, bytes32 hash, uint numOfPlans) public onlyOwner {
    require(hash.length > 0 && numOfPlans > 0, "TMP11");
    dataMap[hash] = Data(url, hash, numOfPlans);
    dataHashes.push(hash);
    CURR_DATA_HASH = hash;
    CURR_NUM_OF_PLANS = numOfPlans;
  }

  function setParameter(uint8 paramType, uint value) public onlyOwner {
    if (paramType == 0) {
      MAX_NUM_OF_VOTERS = value;
      return;
    }
    if (paramType == 1) {
      CLAIM_FEE_MULTIPLIER = value;
      return;
    }
    if (paramType == 2) {
      VOTE_FEE_MULTIPLIER = value;
      return;
    }
    if (paramType == 3) {
      APPEAL_FEE_MULTIPLIER = value;
      return;
    }
    if (paramType == 4) {
      NO_CLAIM_PERIOD = value;
      return;
    }
    if (paramType == 5) {
      VOTING_PERIOD = value;
      return;
    }
    if (paramType == 6) {
      APPEAL_PERIOD = value;
      return;
    }
    if (paramType == 7) {
      COLLECTION_PERIOD = value;
      return;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";

contract Owned is Initializable {
    address public owner;
    address public pendingOwner;

    event SetPendingOwner(address pendingOwner);
    event AcceptOwnership(address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Owned-OO: called by non-owner');
        _;
    }
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, 'Owned-OPO: called by non-pending owner');
        _;
    }

    function __Owned_init(address ownerAddress) internal initializer {
        owner = ownerAddress;
    }

    /// @dev Change ownership by setting the pending owner
    /// @param pendingOwnerAddress The address of the pending owner
    function changeOwnership(address pendingOwnerAddress) external virtual onlyOwner {
        require(pendingOwnerAddress != address(0), 'Owned-CO: zero address');
        pendingOwner = pendingOwnerAddress;
        emit SetPendingOwner(pendingOwnerAddress);
    }

    /// @dev Accept to be the new owner
    function acceptOwnership() external onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit AcceptOwnership(owner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "./IERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
  using AddressUpgradeable for address;

  function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
  function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

import "./Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

  function __ReentrancyGuard_init() internal initializer {
    __ReentrancyGuard_init_unchained();
  }

  function __ReentrancyGuard_init_unchained() internal initializer {
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
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProduct {
  function getToken() external view returns(address);
  function getTotalMcrInETH() external view returns(uint);
  function getPriceCoverageRatioE4() external view returns(uint);
  function getMcrCoverageRatioE4() external view returns(uint);
  function getTokenPriceE8() external view returns(uint);
  function getCoverPrice(uint totalCapitalInETH, uint totalMcrInETH, uint coverage) external view returns(uint);
  function getUserCovers(address user) external view returns(uint[] memory);
  function getUserVotes(address user) external view returns(uint[] memory);
  function getUserClaims(address user) external view returns(uint[] memory);
  function getAllCovers() external view returns(uint[] memory);
  function getAllClaims() external view returns(uint[] memory);
  function getAllAppeals() external view returns(uint[] memory);
  function getCoverFee(uint coverage, uint spkPrice) external returns(uint);

  function buyCover(uint totalCapitalInETH, uint totalMcrInETH, uint spkPrice, address owner, uint[] memory coverInfo) external;

  function submitClaim(address user, uint coverId, uint claimFee) external;
  function voteClaim(address user, uint claimId, uint voteFee, uint weight, bool isApproval) external;
  function appealClaim(uint claimId, uint appealFee) external;
  function collectClaimReward(address user, uint claimId) external returns(uint);
  function collectCoverage(address user, uint claimId) external returns(uint);
  function processAppeal(uint claimId, bool isApproval) external returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/Owned.sol";

contract BaseProduct is Owned {

  uint public MCR_COVERAGE_RATIO_E4; // 20% -> 2000
  uint public PRICE_COVERAGE_RATIO_E4; // 3% -> 300

  address public core;
  address public token;
  string public currency;
  uint public totalCoverage;

  /// @notice Initialize the smart contract
  function __BaseProduct_init(
    address ownerAddr,
    address coreAddr,
    address tokenAddr,
    string memory currencyStr,
    uint mcrCoverageRatioE4,
    uint priceCoverageRatioE4
  )
  public
  initializer
  {
    __Owned_init(ownerAddr);
    core = coreAddr;
    token = tokenAddr;
    currency = currencyStr;
    MCR_COVERAGE_RATIO_E4 = mcrCoverageRatioE4;
    PRICE_COVERAGE_RATIO_E4 = priceCoverageRatioE4;
  }

  /// @notice Set ratio of MCR to coverage for the product
  /// @param ratio Ratio of MCR to coverage of the product, times 1e4
  function setMcrCoverageRatio(uint ratio) external virtual onlyOwner {
    require(ratio >= 100 && ratio <= 10000, "BP1"); // [1%, 100%]
    MCR_COVERAGE_RATIO_E4 = ratio;
  }

  /// @notice Set ratio of price to coverage for the product
  /// @param ratio Ratio of price to coverage of the product, times 1e4
  function setPriceCoverageRatio(uint ratio) external virtual onlyOwner {
    require(ratio >= 100 && ratio <= 10000, "BP2"); // [1%, 100%]
    PRICE_COVERAGE_RATIO_E4 = ratio;
  }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

{
  "optimizer": {
    "enabled": false,
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