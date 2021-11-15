// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {IStakedToken} from './IStakedToken.sol';
import {IStakeUIHelper} from '../interfaces/IStakeUIHelper.sol';
import {IERC20WithNonce} from '../interfaces/IERC20WithNonce.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IPriceOracle} from '../interfaces/IPriceOracle.sol';

interface BPTPriceFeedI {
  function latestAnswer() external view returns (uint256);
}

contract StakeUIHelper is IStakeUIHelper {
  IPriceOracle public immutable PRICE_ORACLE;
  BPTPriceFeedI public immutable BPT_PRICE_FEED;

  address public immutable AAVE;
  IStakedToken public immutable STAKED_AAVE;

  address public immutable BPT;
  IStakedToken public immutable STAKED_BPT;

  uint256 constant SECONDS_PER_YEAR = 365 * 24 * 60 * 60;
  uint256 constant APY_PRECISION = 10000;
  address constant MOCK_USD_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;
  uint256 internal constant USD_BASE = 1e26;

  constructor(
    IPriceOracle priceOracle,
    BPTPriceFeedI bptPriceFeed,
    address aave,
    IStakedToken stkAave,
    address bpt,
    IStakedToken stkBpt
  ) public {
    PRICE_ORACLE = priceOracle;
    BPT_PRICE_FEED = bptPriceFeed;

    AAVE = aave;
    STAKED_AAVE = stkAave;

    BPT = bpt;
    STAKED_BPT = stkBpt;
  }

  function _getStakedAssetData(
    IStakedToken stakeToken,
    address underlyingToken,
    address user,
    bool isNonceAvailable
  ) internal view returns (AssetUIData memory) {
    AssetUIData memory data;

    data.stakeTokenTotalSupply = stakeToken.totalSupply();
    data.stakeCooldownSeconds = stakeToken.COOLDOWN_SECONDS();
    data.stakeUnstakeWindow = stakeToken.UNSTAKE_WINDOW();
    data.rewardTokenPriceEth = PRICE_ORACLE.getAssetPrice(AAVE);
    data.distributionEnd = stakeToken.DISTRIBUTION_END();
    if (block.timestamp < data.distributionEnd) {
      data.distributionPerSecond = stakeToken.assets(address(stakeToken)).emissionPerSecond;
    }

    if (user != address(0)) {
      data.underlyingTokenUserBalance = IERC20(underlyingToken).balanceOf(user);
      data.stakeTokenUserBalance = stakeToken.balanceOf(user);
      data.userIncentivesToClaim = stakeToken.getTotalRewardsBalance(user);
      data.userCooldown = stakeToken.stakersCooldowns(user);
      data.userPermitNonce = isNonceAvailable ? IERC20WithNonce(underlyingToken)._nonces(user) : 0;
    }
    return data;
  }

  function _calculateApy(uint256 distributionPerSecond, uint256 stakeTokenTotalSupply)
    internal
    pure
    returns (uint256)
  {
    return (distributionPerSecond * SECONDS_PER_YEAR * APY_PRECISION) / stakeTokenTotalSupply;
  }

  function getStkAaveData(address user) public view override returns (AssetUIData memory) {
    AssetUIData memory data = _getStakedAssetData(STAKED_AAVE, AAVE, user, true);

    data.stakeTokenPriceEth = data.rewardTokenPriceEth;
    data.stakeApy = _calculateApy(data.distributionPerSecond, data.stakeTokenTotalSupply);
    return data;
  }

  function getStkBptData(address user) public view override returns (AssetUIData memory) {
    AssetUIData memory data = _getStakedAssetData(STAKED_BPT, BPT, user, false);

    data.stakeTokenPriceEth = address(BPT_PRICE_FEED) != address(0)
      ? BPT_PRICE_FEED.latestAnswer()
      : PRICE_ORACLE.getAssetPrice(BPT);
    data.stakeApy = _calculateApy(
      data.distributionPerSecond * data.rewardTokenPriceEth,
      data.stakeTokenTotalSupply * data.stakeTokenPriceEth
    );

    return data;
  }

  function getUserUIData(address user)
    external
    view
    override
    returns (
      AssetUIData memory,
      AssetUIData memory,
      uint256
    )
  {
    return (
      getStkAaveData(user),
      getStkBptData(user),
      USD_BASE / PRICE_ORACLE.getAssetPrice(MOCK_USD_ADDRESS)
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IStakedToken {
  struct AssetData {
    uint128 emissionPerSecond;
    uint128 lastUpdateTimestamp;
    uint256 index;
  }

  function totalSupply() external view returns (uint256);

  function COOLDOWN_SECONDS() external view returns (uint256);

  function UNSTAKE_WINDOW() external view returns (uint256);

  function DISTRIBUTION_END() external view returns (uint256);

  function assets(address asset) external view returns (AssetData memory);

  function balanceOf(address user) external view returns (uint256);

  function getTotalRewardsBalance(address user) external view returns (uint256);

  function stakersCooldowns(address user) external view returns (uint256);


  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IStakeUIHelper {
  struct AssetUIData {
    uint256 stakeTokenTotalSupply;
    uint256 stakeCooldownSeconds;
    uint256 stakeUnstakeWindow;
    uint256 stakeTokenPriceEth;
    uint256 rewardTokenPriceEth;
    uint256 stakeApy;
    uint128 distributionPerSecond;
    uint256 distributionEnd;
    uint256 stakeTokenUserBalance;
    uint256 underlyingTokenUserBalance;
    uint256 userCooldown;
    uint256 userIncentivesToClaim;
    uint256 userPermitNonce;
  }

  function getStkAaveData(address user) external view returns (AssetUIData memory);

  function getStkBptData(address user) external view returns (AssetUIData memory);

  function getUserUIData(address user)
    external
    view
    returns (
      AssetUIData memory,
      AssetUIData memory,
      uint256
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {IERC20} from './IERC20.sol';

interface IERC20WithNonce is IERC20 {
  function _nonces(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
pragma solidity 0.7.5;

interface IPriceOracle {
  function getAssetPrice(address asset) external view returns (uint256);
}

