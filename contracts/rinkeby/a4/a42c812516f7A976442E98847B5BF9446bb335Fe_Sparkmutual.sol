// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Owned.sol";
import "./lib/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IStakePool.sol";
import "./StakePool.sol";
import "./interfaces/ISPK.sol";
import "./interfaces/IProduct.sol";
//import "hardhat/console.sol";

contract Sparkmutual is Initializable, Owned, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  uint public MCR_CAPITAL_RATIO_E4; // 120% -> 1200
  uint internal constant ALPHA = 0.0000001 ether;
  uint internal constant MIN_MCR = 10 ether;
  uint internal constant MIN_CP = 100 ether;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public spk;
  address public stakePool;
  address public committee;
  uint public totalCoverFee;
  uint public totalCommitteeReward;

  address[] public products;
  mapping(address => bool) public isProductExists;

  // events
  event Purchase(address indexed buyer, uint ethAmount, uint spkAmount);
  event Redeem(address indexed buyer, uint spkAmount, uint ethAmount);

  // modifier
  modifier onlyExistingProduct(address prod) {
    require(isProductExists[prod], 'SM0');
    _;
  }

  /// @notice Initialize Sparkmutual smart contract
  function initialize(
    address ownerAddr,
    address spkAddr,
    address committeeAddr
  ) public initializer {
    __Owned_init(ownerAddr);
    spk = spkAddr;
    committee = committeeAddr;
    MCR_CAPITAL_RATIO_E4 = 40000; // 400%
  }

  /// @notice Version of the current implementation
  function version() public virtual pure returns (string memory) {
    return "0.0.1";
  }

  /// @notice Add product to sparkmutual
  /// @param product Address of the product contract to be added
  function addProduct(address product) virtual external nonReentrant onlyOwner {
    require(product != address(0), "SM2");
    require(!isProductExists[product], "SM3");
    products.push(product);
    isProductExists[product] = true;
  }

  /// @notice Remove product
  /// @param product Address of the product contract to be removed
  function removeProduct(address product) virtual external nonReentrant onlyOwner {
    require(isProductExists[product], "SM4");
    uint index = products.length + 1;
    for (uint i = 0; i < products.length; i++) {
      if (products[i] == product) {
        index = i;
        break;
      }
    }
    if (index != products.length + 1) {
      products[index] = products[products.length - 1];
      products.pop();
    }
    isProductExists[product] = false;
  }

  /// @notice get total number of products
  function getProductCount() virtual public view returns(uint) {
    return products.length;
  }

  /// @notice Buy covers with ETH or other tokens
  /// @param product Address of the product contract
  /// @param coverInfo Information of the cover, with a length at least 3. [0] is the coverage, [1] is the price, and [2] is the price in SPK
  function buyCover(
    address product,
    uint[] memory coverInfo
  ) public payable virtual onlyExistingProduct(product) nonReentrant {
    // verify basic cover information
    require(coverInfo.length > 2 && coverInfo[0] > 0 && coverInfo[1] > 0 && coverInfo[2] > 0, "SM6");

    // verify cover price in ETH or other tokens
    address token = IProduct(product).getToken();
    if ( token == ETH_ADDRESS) {
      require(coverInfo[1] == msg.value, "SM7");
    } else {
      IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), coverInfo[1]);
    }

    // verify cover fee
    IERC20Upgradeable(spk).safeTransferFrom(msg.sender, address(this), coverInfo[2]);
    totalCoverFee += coverInfo[2];

    // verify and add cover to product
    uint totalCapitalInETH = getTotalCapitalInETH();
    uint totalMcrInETH = getTotalMcrInETH();
    uint spkPrice = getPurchasePrice(0, totalCapitalInETH, totalMcrInETH);
    require(totalMcrInETH <= totalCapitalInETH, "SM8");
    IProduct(product).buyCover(totalCapitalInETH, totalMcrInETH, spkPrice, msg.sender, coverInfo);
  }

  /// @notice Submit a claim
  /// @param product The address of the product
  /// @param coverId The ID of the cover to be claimed
  /// @param fee The fee of claim
  function submitClaim(
    address product,
    uint coverId,
    uint fee
  ) external virtual onlyExistingProduct(product) nonReentrant {
//    IERC20Upgradeable(spk).safeApprove(address(this), 0);
//    IERC20Upgradeable(spk).safeApprove(address(this), fee);
    IERC20Upgradeable(spk).safeTransferFrom(msg.sender, address(this), fee);

    IProduct(product).submitClaim(msg.sender, coverId, fee);
  }

  /// @notice Vote a claim
  /// @param product The address of the product
  /// @param claimId The ID of the claim to be voted
  /// @param fee The voting fee
  function voteClaim(
    address product,
    uint claimId,
    uint fee,
    bool isApproval
  ) external virtual onlyExistingProduct(product) nonReentrant {
    IERC20Upgradeable(spk).safeTransferFrom(msg.sender, address(this), fee);
    uint weight = IStakePool(stakePool).getVotingWeight(msg.sender);
    IProduct(product).voteClaim(msg.sender, claimId, fee, weight, isApproval);
  }

  /// @notice Appeal a claim
  /// @param product The address of the product
  /// @param claimId The ID of the claim to be appealed
  /// @param fee The appeal fee
  function appealClaim(
    address product,
    uint claimId,
    uint fee
  ) external virtual onlyExistingProduct(product) nonReentrant {
    IERC20Upgradeable(spk).safeTransferFrom(msg.sender, address(this), fee);
    IProduct(product).appealClaim(claimId, fee);
  }

  /// @notice Process a claim
  /// @param product The address of the product
  /// @param claimId The ID of the claim to be appealed
  function processAppeal(
    address product,
    uint claimId,
    bool isApproval
  ) external virtual onlyExistingProduct(product) nonReentrant {
    require(msg.sender == committee, "SM9");
    uint reward = IProduct(product).processAppeal(claimId, isApproval);
    totalCommitteeReward += reward;
  }

  /// @notice Collect rewards
  /// @param product The address of the product
  /// @param claimId The ID of the claim to collect reward from
  function collectClaimReward(
    address product,
    uint claimId
  ) external virtual onlyExistingProduct(product) nonReentrant {
    uint reward = IProduct(product).collectClaimReward(msg.sender, claimId);
    require(reward > 0, "SM11");
    IERC20Upgradeable(spk).transfer(msg.sender, reward);
  }

  /// @notice Collect coverage of a cover
  function collectCoverage(
    address product,
    uint claimId
  ) external virtual onlyExistingProduct(product) nonReentrant {
    uint coverage = IProduct(product).collectCoverage(msg.sender, claimId);
    require(coverage > 0, "SM12");
    address token = IProduct(product).getToken();
    if (token == ETH_ADDRESS) {
      payable(msg.sender).transfer(coverage);
    } else {
      IERC20Upgradeable(token).transfer(msg.sender, coverage);
    }
  }

  /// @notice Collect rewards of committee
  function collectCommitteeReward() external virtual nonReentrant {
    require(totalCommitteeReward > 0, "SM12");
    IERC20Upgradeable(spk).transfer(committee, totalCommitteeReward);
    totalCommitteeReward = 0;
  }

  /// @notice Get total MCR of the product in ETH
  function getTotalMcrInETH() public view virtual returns(uint) {
    uint totalMcrInETH;
    for (uint i = 0; i < products.length; i++) {
      totalMcrInETH += IProduct(products[i]).getTotalMcrInETH();
    }
    return totalMcrInETH;
  }

  /// @notice Get total capital of the product in ETH
  function getTotalCapitalInETH() public view virtual returns(uint) {
    uint totalCapitalInETH = address(this).balance;
    for (uint i = 0; i < products.length; i++) {
      address token = IProduct(products[i]).getToken();
      if (token == ETH_ADDRESS)
        continue;
      totalCapitalInETH += IERC20Upgradeable(token).balanceOf(address(this))
      * IProduct(products[i]).getTokenPriceE8() / 1e8;
    }
    return totalCapitalInETH;
  }

  /// @notice Purchase SPK with ETH
  function purchase() public virtual payable nonReentrant {
    require(msg.value > 0, "SM1");

    uint cp = getTotalCapitalInETH() - msg.value;
    uint mcr = getTotalMcrInETH();
    uint spkAmount = getPurchaseAmount(msg.value, cp, mcr);

    ISPK(spk).mint(msg.sender, spkAmount);

    emit Purchase(msg.sender, msg.value, spkAmount);
  }

  /// @notice redeem SPK for ETH
  /// @param spkAmount Amount of SPK to be redeemed
  function redeem(uint spkAmount) public virtual nonReentrant {
    require(spkAmount > 0 && IERC20Upgradeable(spk).balanceOf(msg.sender) >= spkAmount, "SM13");

    uint cp = getTotalCapitalInETH();
    uint mcr = getTotalMcrInETH();

    (uint maxSpkLeft, uint maxSpkRight) = getMaxRedeemAmount(cp, mcr);
    require(spkAmount <= maxSpkLeft + maxSpkRight , "SM14");

    uint redeemAmount = getRedeemAmount(spkAmount, cp, mcr);
    uint redeemFee = redeemAmount * 25 / 1000;

    ISPK(spk).burn(msg.sender, spkAmount);
    payable(msg.sender).transfer(redeemAmount - redeemFee);
    payable(committee).transfer(redeemFee);

    emit Redeem(msg.sender, spkAmount, redeemAmount);
  }

  function getPurchaseAmount(uint amount, uint cp, uint mcr) public view virtual returns(uint) {
    uint mcrBounded = mcr < MIN_MCR ? MIN_MCR : mcr;

    if (cp < MIN_CP) {
      uint amountRight = cp + amount > MIN_CP ? cp + amount - MIN_CP : 0;
      uint amountLeft = amount - amountRight;
      uint priceLeft = (ALPHA * ((MIN_CP**2) / 1e18)) / mcrBounded;
      uint spkLeft = amountLeft * 1e18 / priceLeft;
      uint spkRight = (amountRight * mcrBounded * 1e36) / (MIN_CP * (MIN_CP + amountRight) * ALPHA);
      // console.log("getPurchaseAmount ooo", spkLeft, spkRight);
      return (spkLeft + spkRight);
    }

    // console.log("getPurchaseAmount xxx", spkAmount);
    return (amount * mcrBounded * 1e36) / (cp * (cp + amount) * ALPHA);
  }

  function getPurchasePrice(uint amount, uint cp, uint mcr) public view virtual returns(uint) {
    uint cpBounded = cp < MIN_CP ? MIN_CP : cp;
    uint mcrBounded = mcr < MIN_MCR ? MIN_MCR : mcr;

    uint price = (ALPHA * (cpBounded**2)) / (mcrBounded * 1e18);
    uint spkAmount = amount > 0 ? getPurchaseAmount(amount, cp, mcr) : 0;
    if (spkAmount > 0) {
      price = amount * 1e18 / spkAmount;
    }
    return price;
  }

  function getMaxRedeemAmount(uint cp, uint mcr) public view virtual returns(uint, uint) {
    if (cp <= mcr) return (0,0);

    uint mcrBounded = mcr < MIN_MCR ? MIN_MCR : mcr;
    uint price = (ALPHA * ((MIN_CP**2) / 1e18)) / mcrBounded;

    uint maxSpkLeft = 0;
    uint maxSpkRight = 0;

    if (cp < MIN_CP) {
      maxSpkLeft = (cp - mcr) * 1e18 / price;
    } else {
      if (mcr < MIN_CP) {
        maxSpkLeft = (MIN_CP - mcr) * 1e18 / price;
        maxSpkRight = ((cp * mcrBounded / MIN_CP) - mcrBounded) * 1e18 /
                      ((cp / 1e10) * (ALPHA / 1e8)) ;
      } else {
        maxSpkRight = ((cp - mcr) * mcrBounded * 1e16) /
                      ((cp / 1e10) * ((cp + mcr) / 1e10) * ALPHA);
      }
    }

    return (maxSpkLeft, maxSpkRight);
  }


  function getRedeemAmount(uint amount, uint cp, uint mcr) public view virtual returns(uint) {
    if (cp <= mcr || amount == 0) return 0;

    (uint maxSpkLeft, uint maxSpkRight) = getMaxRedeemAmount(cp, mcr);

    require(amount <= maxSpkRight + maxSpkLeft, "SM15");

    uint mcrBounded = mcr < MIN_MCR ? MIN_MCR : mcr;
    uint price = (ALPHA * ((MIN_CP**2) / 1e18)) / mcrBounded;

    if (maxSpkLeft > 0 && maxSpkRight == 0) {
      return amount * price / 1e18;
    }
    if (maxSpkLeft == 0 && maxSpkRight > 0) {
      return (cp**2) / (mcrBounded*1e36 / (ALPHA * amount) + cp);
    }
    // (maxSpkLeft > 0 && maxSpkRight > 0)
    if (amount <= maxSpkRight) {
      return (cp**2) / (mcrBounded*1e36 / (ALPHA * amount) + cp);
    }
    return (cp - MIN_CP) + (amount - maxSpkRight) * price / 1e18;
  }

  /// @notice Set stake pool
  function setStakePool(address stakePoolAddr) external onlyOwner {
    stakePool = stakePoolAddr;
  }

  /// @notice Set ratio of MCR to capital for the product
  /// @param ratio Ratio of MCR to capital of the product, times 1e4
  function setMcrCapitalRatio(uint ratio) external virtual onlyOwner {
    require(ratio >= 12000 && ratio <= 40000, "SM3"); // [120%, 400%]
    MCR_CAPITAL_RATIO_E4 = ratio;
  }

  /// @notice Set committee
  /// @param newCommittee Address of the committee
  function setCommittee(address newCommittee) external virtual onlyOwner {
    committee = newCommittee;
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

interface IStakePool {
  function stake(uint amount) external;
  function unstake(uint amount) external returns(uint);
  function addReward(address from, uint amount) external;
  function getVotingWeight(address stakerAddr) external returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IStakePool.sol";
import "./lib/Owned.sol";
import "./lib/IERC20Upgradeable.sol";
import "./lib/SafeERC20Upgradeable.sol";
import "./lib/ReentrancyGuardUpgradeable.sol";
//import "hardhat/console.sol";

contract StakePool is IStakePool, Initializable, Owned, ReentrancyGuardUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  address public token; // ERC20 token of the pool
  uint private constant NUM_OF_BLOCKS_PER_YEAR = 2102400;
  uint public totalStake; // total amount of stake;
  uint public totalRewardE18; // total reward to shared by all stakers
  uint public totalInterestE18; // total interest claimable by stakers, multiplies 1e18
  uint public cusumIpsE18; // cumulative sum of interest per stake, i.e., ips, multiplies 1e18
  uint public cusumReward; // cumulative sum of rewards sent to the pool
  uint public cusumStake; // cumulative sum of stakes sent to the pool
  uint public latestAccruedBlock; // latest block number that accrues interests
  uint public apyPerBlockE18; // interest rate per block, multiplies 1e18
  mapping(address => StakeInfo) stakeInfoMap; // owner => Stake

  struct StakeInfo {
    address owner;
    uint amount;
    uint cusumIpsStartE18;
    uint earnedInterestE18;
    uint changedAt;
  }

  /* events */
  event Stake(address indexed staker, uint amount);
  event Unstake(address indexed staker, uint amount, uint amountPlusInterest);
  event AddReward(address indexed rewarder, uint amount);

  /// @dev Initialize the smart contract
  function initialize(address ownerAddr, address tokenAddr) public initializer {
    __Owned_init(ownerAddr);
    token = tokenAddr;
  }

  /// @dev Version of the current implementation
  function version() public virtual pure returns (string memory) {
    return "0.0.1";
  }

  /// @dev Stake to the pool
  /// @param amount The amount to stake
  function stake(uint amount) external override nonReentrant {
    _accrueInterest();
    require(amount > 0, 'SP1'); // amount is zero
    StakeInfo storage stakeInfo = stakeInfoMap[msg.sender];
    require(stakeInfo.owner == address(0) || stakeInfo.owner == msg.sender, 'SP2'); // bad staker owner

    // transfer the staked amount from the staker to the pool
    IERC20Upgradeable(token).safeApprove(address(this), 0);
    IERC20Upgradeable(token).safeApprove(address(this), amount);
    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);

    // update pool information
    cusumStake += amount;
    totalStake += amount;

    // update stake information
    if (stakeInfo.owner == msg.sender) { // adding amount to an existing stake
      if (stakeInfo.amount > 0 && cusumIpsE18 > stakeInfo.cusumIpsStartE18) {
        uint earnedInterestE18 = stakeInfo.amount * (cusumIpsE18 - stakeInfo.cusumIpsStartE18);
        stakeInfo.earnedInterestE18 += earnedInterestE18;
      }
    } else { // new stake
      stakeInfo.owner = msg.sender;
    }
    stakeInfo.cusumIpsStartE18 = cusumIpsE18;
    stakeInfo.amount += amount;
    stakeInfo.changedAt = block.timestamp;

    emit Stake(stakeInfo.owner, amount);
  }

  /// @notice Unstake from the pool
  /// @param amount The amount to be unstaked
  function unstake(uint amount) external override nonReentrant returns(uint) {
    _accrueInterest();
    StakeInfo storage stakeInfo = stakeInfoMap[msg.sender];
    require(stakeInfo.owner == msg.sender, 'SP3'); // can't unstake an empty stake
//    console.log("unstake:", amount, stakeInfo.amount);
    require(amount > 0 && amount <= stakeInfo.amount, 'SP4'); // invalid amount to unstake

    // calculate unstake amount, plus interest
    uint interestE18 = ( stakeInfo.amount * ( cusumIpsE18 - stakeInfo.cusumIpsStartE18) ) + stakeInfo.earnedInterestE18 ;
    if (interestE18 > totalInterestE18 ) {
      interestE18 = totalInterestE18;
    }
    uint amountPlusInterest = amount + (interestE18 / 1e18);

    // transfer amount plus interest to the staker
    IERC20Upgradeable(token).safeTransfer(stakeInfo.owner, amountPlusInterest);

    // update pool information
    totalStake -= amount;
    totalInterestE18 -= interestE18;

    // update stake information
    stakeInfo.amount -= amount;
    stakeInfo.cusumIpsStartE18 = cusumIpsE18;
    stakeInfo.earnedInterestE18 = 0;
    stakeInfo.changedAt = block.timestamp;
    if (stakeInfo.amount == 0) {
      delete stakeInfoMap[stakeInfo.owner];
    }

    emit Unstake(stakeInfo.owner, amount, amountPlusInterest);
    return amountPlusInterest;
  }

  /// @notice Accrue interests for the pool
  function _accrueInterest() internal virtual {
    if ( block.number <= latestAccruedBlock ) return;

    if ( totalStake == 0 || totalRewardE18 == 0 ) {
      latestAccruedBlock = block.number;
      return;
    }

    // calculate accrued interest and corresponding ips
    uint interestE18 = ( apyPerBlockE18 * ( block.number - latestAccruedBlock ) * totalRewardE18) / 1e18 ;
    if (interestE18 > totalRewardE18 ) {
      interestE18 = totalRewardE18;
    }
    uint ipsE18 = interestE18 / totalStake;

    // update pool information iff ips is positive
    if (ipsE18 > 0 ) {
      cusumIpsE18 += ipsE18;
      totalInterestE18 += interestE18;
      totalRewardE18 -= interestE18;
    }
    latestAccruedBlock = block.number;
  }

  /// @dev Set the APY per block of the pool
  /// @param apyE4 The APY multiplied by 1e4, e.g., 400 means 4% APY
  function setApy(uint apyE4) external virtual nonReentrant onlyOwner {
    apyPerBlockE18 = ( apyE4 * 1e14 ) / NUM_OF_BLOCKS_PER_YEAR;
  }

  /// @dev Add rewards to the pool
  /// @param amount The amount of the rewards to be added
  function addReward(address from, uint amount) external override nonReentrant {
    require(from != address(0), "SP5");
    IERC20Upgradeable(token).safeTransferFrom(from, address(this), amount);

    totalRewardE18 += amount * 1e18;
    cusumReward += amount;

    emit AddReward(from, amount);
  }

  /// @dev Get stake information
  /// @param stakerAddr Address of the staker
  function getStake(address stakerAddr) external virtual view returns(StakeInfo memory) {
    return stakeInfoMap[stakerAddr];
  }

  /// @dev Get voting power of a staker
  /// @param stakerAddr Address of the staker
  function getVotingWeight(address stakerAddr) public override view returns(uint) {
    StakeInfo memory stk = stakeInfoMap[stakerAddr];
    return stk.amount * (block.timestamp - stk.changedAt);
  }

  /// @dev Get pool information
  function getPoolInfo() external virtual view returns(
    uint spTotalStake,
    uint spTotalRewardE18,
    uint spTotalInterestE18,
    uint spCusumIpsE18,
    uint spCusumReward,
    uint spCusumStake,
    uint spLatestAccruedBlock,
    uint spApyPerBlockE18) {
    return (
      totalStake,
      totalRewardE18,
      totalInterestE18,
      cusumIpsE18,
      cusumReward,
      cusumStake,
      latestAccruedBlock,
      apyPerBlockE18);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISPK {
  function mint(address to, uint amount) external;
  function burn(address to, uint amount) external;
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