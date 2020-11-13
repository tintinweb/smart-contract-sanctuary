// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/utils/SafeCast.sol";

import "../utils/UInt256Array.sol";
import "./ComptrollerStorage.sol";
import "../token/TokenListenerInterface.sol";

/// @title The Comptroller disburses rewards to pool users
/* solium-disable security/no-block-members */
contract Comptroller is ComptrollerStorage, TokenListenerInterface {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using UInt256Array for uint256[];
  using ExtendedSafeCast for uint256;
  using BalanceDrip for BalanceDrip.State;
  using VolumeDrip for VolumeDrip.State;
  using BalanceDripManager for BalanceDripManager.State;
  using VolumeDripManager for VolumeDripManager.State;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;

  /// @notice Emitted when a balance drip is actived
  event BalanceDripActivated(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    uint256 dripRatePerSecond
  );

  /// @notice Emitted when a balance drip is deactivated
  event BalanceDripDeactivated(
    address indexed source,
    address indexed measure,
    address indexed dripToken
  );

  /// @notice Emitted when a balance drip rate is updated
  event BalanceDripRateSet(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    uint256 dripRatePerSecond
  );

  /// @notice Emitted when a balance drip drips tokens
  event BalanceDripDripped(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    address user,
    uint256 amount
  );

  event DripTokenDripped(
    address indexed dripToken,
    address indexed user,
    uint256 amount
  );

  /// @notice Emitted when a volue drip drips tokens
  event VolumeDripDripped(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral,
    address user,
    uint256 amount
  );

  /// @notice Emitted when a user claims drip tokens
  event DripTokenClaimed(
    address indexed operator,
    address indexed dripToken,
    address indexed user,
    uint256 amount
  );

  /// @notice Emitted when a volume drip is activated
  event VolumeDripActivated(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral,
    uint256 periodSeconds,
    uint256 dripAmount
  );

  event TransferredOut(
    address indexed token,
    address indexed to,
    uint256 amount
  );

  /// @notice Emitted when a new volume drip period has started
  event VolumeDripPeriodStarted(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral,
    uint32 period,
    uint256 dripAmount,
    uint256 endTime
  );

  /// @notice Emitted when a volume drip period has ended
  event VolumeDripPeriodEnded(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral,
    uint32 period,
    uint256 totalSupply,
    uint256 drippedTokens
  );

  /// @notice Emitted when a volume drip is updated
  event VolumeDripSet(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral,
    uint256 periodSeconds,
    uint256 dripAmount
  );

  /// @notice Emitted when a volume drip is deactivated.
  event VolumeDripDeactivated(
    address indexed source,
    address indexed measure,
    address indexed dripToken,
    bool isReferral
  );

  /// @notice Convenience struct used when updating drips
  struct UpdatePair {
    address source;
    address measure;
  }

  /// @notice Convenience struct used to retrieve balances after updating drips
  struct DripTokenBalance {
    address dripToken;
    uint256 balance;
  }

  /// @notice Initializes a new Comptroller.
  constructor () public {
    __Ownable_init();
  }

  function transferOut(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).transfer(to, amount);

    emit TransferredOut(token, to, amount);
  }

  /// @notice Activates a balance drip.  Only callable by the owner.
  /// @param source The balance drip "source"; i.e. a Prize Pool address.
  /// @param measure The ERC20 token whose balances determines user's share of the drip rate.
  /// @param dripToken The token that is dripped to users.
  /// @param dripRatePerSecond The amount of drip tokens that are awarded each second to the total supply of measure.
  function activateBalanceDrip(address source, address measure, address dripToken, uint256 dripRatePerSecond) external onlyOwner {

    balanceDrips[source].activateDrip(measure, dripToken, dripRatePerSecond);

    emit BalanceDripActivated(
      source,
      measure,
      dripToken,
      dripRatePerSecond
    );
  }

  /// @notice Deactivates a balance drip.  Only callable by the owner.
  /// @param source The balance drip "source"; i.e. a Prize Pool address.
  /// @param measure The ERC20 token whose balances determines user's share of the drip rate.
  /// @param dripToken The token that is dripped to users.
  /// @param prevDripToken The previous drip token in the balance drip list.  If the dripToken is the first address,
  /// then the previous address is the SENTINEL address: 0x0000000000000000000000000000000000000001
  function deactivateBalanceDrip(address source, address measure, address dripToken, address prevDripToken) external onlyOwner {
    _deactivateBalanceDrip(source, measure, dripToken, prevDripToken);
  }

  /// @notice Deactivates a balance drip.  Only callable by the owner.
  /// @param source The balance drip "source"; i.e. a Prize Pool address.
  /// @param measure The ERC20 token whose balances determines user's share of the drip rate.
  /// @param dripToken The token that is dripped to users.
  /// @param prevDripToken The previous drip token in the balance drip list.  If the dripToken is the first address,
  /// then the previous address is the SENTINEL address: 0x0000000000000000000000000000000000000001
  function _deactivateBalanceDrip(address source, address measure, address dripToken, address prevDripToken) internal {
    balanceDrips[source].deactivateDrip(measure, dripToken, prevDripToken, _currentTime().toUint32(), _availableDripTokenBalance(dripToken));

    emit BalanceDripDeactivated(source, measure, dripToken);
  }

  /// @notice Gets a list of active balance drip tokens
  /// @param source The balance drip "source"; i.e. a Prize Pool address.
  /// @param measure The ERC20 token whose balances determines user's share of the drip rate.
  /// @return An array of active Balance Drip token addresses
  function getActiveBalanceDripTokens(address source, address measure) external view returns (address[] memory) {
    return balanceDrips[source].getActiveBalanceDrips(measure);
  }

  /// @notice Returns the state of a balance drip.
  /// @param source The balance drip "source"; i.e. Prize Pool
  /// @param measure The token that measure's a users share of the drip
  /// @param dripToken The token that is being dripped to users
  /// @return dripRatePerSecond The current drip rate of the balance drip.
  /// @return exchangeRateMantissa The current exchange rate from measure to dripTokens
  /// @return timestamp The timestamp at which the balance drip was last updated.
  function getBalanceDrip(
    address source,
    address measure,
    address dripToken
  )
    external
    view
    returns (
      uint256 dripRatePerSecond,
      uint128 exchangeRateMantissa,
      uint32 timestamp
    )
  {
    BalanceDrip.State storage balanceDrip = balanceDrips[source].getDrip(measure, dripToken);
    dripRatePerSecond = balanceDrip.dripRatePerSecond;
    exchangeRateMantissa = balanceDrip.exchangeRateMantissa;
    timestamp = balanceDrip.timestamp;
  }

  /// @notice Sets the drip rate for a balance drip.  The drip rate is the number of drip tokens given to the
  /// entire supply of measure tokens.  Only callable by the owner.
  /// @param source The balance drip "source"; i.e. Prize Pool
  /// @param measure The token to use to measure a user's share of the drip rate
  /// @param dripToken The token that is dripped to the user
  /// @param dripRatePerSecond The new drip rate per second
  function setBalanceDripRate(address source, address measure, address dripToken, uint256 dripRatePerSecond) external onlyOwner {
    balanceDrips[source].setDripRate(measure, dripToken, dripRatePerSecond, _currentTime().toUint32(), _availableDripTokenBalance(dripToken));

    emit BalanceDripRateSet(
      source,
      measure,
      dripToken,
      dripRatePerSecond
    );
  }

  /// @notice Activates a volume drip.  Volume drips distribute tokens to users based on their share of the activity within a period.
  /// @param source The Prize Pool for which to bind to
  /// @param measure The Prize Pool controlled token whose volume should be measured
  /// @param dripToken The token that is being disbursed
  /// @param isReferral Whether this volume drip is for referrals
  /// @param periodSeconds The period of the volume drip, in seconds
  /// @param dripAmount The amount of dripTokens disbursed each period.
  /// @param endTime The time at which the first period ends.
  function activateVolumeDrip(
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    uint32 periodSeconds,
    uint112 dripAmount,
    uint32 endTime
  )
    external
    onlyOwner
  {
    uint32 period;

    if (isReferral) {
      period = referralVolumeDrips[source].activate(measure, dripToken, periodSeconds, dripAmount, endTime);
    } else {
      period = volumeDrips[source].activate(measure, dripToken, periodSeconds, dripAmount, endTime);
    }

    emit VolumeDripActivated(
      source,
      measure,
      dripToken,
      isReferral,
      periodSeconds,
      dripAmount
    );

    emit VolumeDripPeriodStarted(
      source,
      measure,
      dripToken,
      isReferral,
      period,
      dripAmount,
      endTime
    );
  }

  /// @notice Deactivates a volume drip.  Volume drips distribute tokens to users based on their share of the activity within a period.
  /// @param source The Prize Pool for which to bind to
  /// @param measure The Prize Pool controlled token whose volume should be measured
  /// @param dripToken The token that is being disbursed
  /// @param isReferral Whether this volume drip is for referrals
  /// @param prevDripToken The previous drip token in the volume drip list.  Is different for referrals vs non-referral volume drips.
  function deactivateVolumeDrip(
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    address prevDripToken
  )
    external
    onlyOwner
  {
    _deactivateVolumeDrip(source, measure, dripToken, isReferral, prevDripToken);
  }

  /// @notice Deactivates a volume drip.  Volume drips distribute tokens to users based on their share of the activity within a period.
  /// @param source The Prize Pool for which to bind to
  /// @param measure The Prize Pool controlled token whose volume should be measured
  /// @param dripToken The token that is being disbursed
  /// @param isReferral Whether this volume drip is for referrals
  /// @param prevDripToken The previous drip token in the volume drip list.  Is different for referrals vs non-referral volume drips.
  function _deactivateVolumeDrip(
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    address prevDripToken
  )
    internal
  {
    if (isReferral) {
      referralVolumeDrips[source].deactivate(measure, dripToken, prevDripToken);
    } else {
      volumeDrips[source].deactivate(measure, dripToken, prevDripToken);
    }

    emit VolumeDripDeactivated(
      source,
      measure,
      dripToken,
      isReferral
    );
  }


  /// @notice Sets the parameters for the *next* volume drip period.  The source, measure, dripToken and isReferral combined
  /// are used to uniquely identify a volume drip.  Only callable by the owner.
  /// @param source The Prize Pool of the volume drip
  /// @param measure The token whose volume is being measured
  /// @param dripToken The token that is being disbursed
  /// @param isReferral Whether this volume drip is a referral
  /// @param periodSeconds The length to use for the next period
  /// @param dripAmount The amount of tokens to drip for the next period
  function setVolumeDrip(
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    uint32 periodSeconds,
    uint112 dripAmount
  )
    external
    onlyOwner
  {
    if (isReferral) {
      referralVolumeDrips[source].set(measure, dripToken, periodSeconds, dripAmount);
    } else {
      volumeDrips[source].set(measure, dripToken, periodSeconds, dripAmount);
    }

    emit VolumeDripSet(
      source,
      measure,
      dripToken,
      isReferral,
      periodSeconds,
      dripAmount
    );
  }

  function getVolumeDrip(
    address source,
    address measure,
    address dripToken,
    bool isReferral
  )
    external
    view
    returns (
      uint256 periodSeconds,
      uint256 dripAmount,
      uint256 periodCount
    )
  {
    VolumeDrip.State memory drip;

    if (isReferral) {
      drip = referralVolumeDrips[source].volumeDrips[measure][dripToken];
    } else {
      drip = volumeDrips[source].volumeDrips[measure][dripToken];
    }

    return (
      drip.nextPeriodSeconds,
      drip.nextDripAmount,
      drip.periodCount
    );
  }

  /// @notice Gets a list of active volume drip tokens
  /// @param source The volume drip "source"; i.e. a Prize Pool address.
  /// @param measure The ERC20 token whose volume determines user's share of the drip rate.
  /// @param isReferral Whether this volume drip is a referral
  /// @return An array of active Volume Drip token addresses
  function getActiveVolumeDripTokens(address source, address measure, bool isReferral) external view returns (address[] memory) {
    if (isReferral) {
      return referralVolumeDrips[source].getActiveVolumeDrips(measure);
    } else {
      return volumeDrips[source].getActiveVolumeDrips(measure);
    }
  }

  function isVolumeDripActive(
    address source,
    address measure,
    address dripToken,
    bool isReferral
  )
    external
    view
    returns (bool)
  {
    if (isReferral) {
      return referralVolumeDrips[source].isActive(measure, dripToken);
    } else {
      return volumeDrips[source].isActive(measure, dripToken);
    }
  }

  function getVolumeDripPeriod(
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    uint16 period
  )
    external
    view
    returns (
      uint112 totalSupply,
      uint112 dripAmount,
      uint32 endTime
    )
  {
    VolumeDrip.Period memory periodState;

    if (isReferral) {
      periodState = referralVolumeDrips[source].volumeDrips[measure][dripToken].periods[period];
    } else {
      periodState = volumeDrips[source].volumeDrips[measure][dripToken].periods[period];
    }

    return (
      periodState.totalSupply,
      periodState.dripAmount,
      periodState.endTime
    );
  }

  /// @notice Returns a users claimable balance of drip tokens.  This is the combination of all balance and volume drips.
  /// @param dripToken The token that is being disbursed
  /// @param user The user whose balance should be checked.
  /// @return The claimable balance of the dripToken by the user.
  function balanceOfDrip(address user, address dripToken) external view returns (uint256) {
    return dripTokenBalances[dripToken][user];
  }

  /// @notice Claims a drip token on behalf of a user.  If the passed amount is less than or equal to the users drip balance, then
  /// they will be transferred that amount.  Otherwise, it fails.
  /// @param user The user for whom to claim the drip tokens
  /// @param dripToken The drip token to claim
  /// @param amount The amount of drip token to claim
  function claimDrip(address user, address dripToken, uint256 amount) public {
    address sender = _msgSender();
    dripTokenTotalSupply[dripToken] = dripTokenTotalSupply[dripToken].sub(amount);
    dripTokenBalances[dripToken][user] = dripTokenBalances[dripToken][user].sub(amount);
    require(IERC20(dripToken).transfer(user, amount), "Comptroller/claim-transfer-failed");

    emit DripTokenClaimed(sender, dripToken, user, amount);
  }

  function claimDrips(address user, address[] memory dripTokens) public {
    for (uint i = 0; i < dripTokens.length; i++) {
      claimDrip(user, dripTokens[i], dripTokenBalances[dripTokens[i]][user]);
    }
  }

  function updateActiveBalanceDripsForPairs(
    UpdatePair[] memory pairs
  ) public {
    uint256 currentTime = _currentTime();
    uint256 i;
    for (i = 0; i < pairs.length; i++) {
      UpdatePair memory pair = pairs[i];
      _updateActiveBalanceDrips(
        balanceDrips[pair.source],
        pair.source,
        pair.measure,
        IERC20(pair.measure).totalSupply(),
        currentTime
      );
    }
  }

  function updateActiveVolumeDripsForPairs(
    UpdatePair[] memory pairs
  ) public {
    uint256 i;
    for (i = 0; i < pairs.length; i++) {
      UpdatePair memory pair = pairs[i];
      _updateActiveVolumeDrips(
        volumeDrips[pair.source],
        pair.source,
        pair.measure,
        false
      );
      _updateActiveVolumeDrips(
        referralVolumeDrips[pair.source],
        pair.source,
        pair.measure,
        true
      );
    }
  }

  function mintAndCaptureVolumeDripsForPairs(
    UpdatePair[] memory pairs,
    address user,
    uint256 amount,
    address[] memory dripTokens
  ) public {
    uint256 i;
    for (i = 0; i < pairs.length; i++) {
      UpdatePair memory pair = pairs[i];

      _mintAndCaptureForVolumeDrips(pair.source, pair.measure, user, amount, dripTokens);
      _mintAndCaptureReferralVolumeDrips(pair.source, pair.measure, user, amount, dripTokens);
    }
  }

  function _mintAndCaptureForVolumeDrips(
    address source,
    address measure,
    address user,
    uint256 amount,
    address[] memory dripTokens
  ) internal {
    uint i;
    for (i = 0; i < dripTokens.length; i++) {
      address dripToken = dripTokens[i];

      VolumeDrip.State storage state = volumeDrips[source].volumeDrips[measure][dripToken];
      _captureClaimForVolumeDrip(state, source, measure, dripToken, false, user, amount);
    }
  }

  function _mintAndCaptureReferralVolumeDrips(
    address source,
    address measure,
    address user,
    uint256 amount,
    address[] memory dripTokens
  ) internal {
    uint i;
    for (i = 0; i < dripTokens.length; i++) {
      address dripToken = dripTokens[i];

      VolumeDrip.State storage referralState = referralVolumeDrips[source].volumeDrips[measure][dripToken];
      _captureClaimForVolumeDrip(referralState, source, measure, dripToken, true, user, amount);
    }
  }

  function _captureClaimForVolumeDrip(
    VolumeDrip.State storage dripState,
    address source,
    address measure,
    address dripToken,
    bool isReferral,
    address user,
    uint256 amount
  ) internal {
    uint256 newUserTokens = dripState.mint(
      user,
      amount
    );

    if (newUserTokens > 0) {
      _addDripBalance(dripToken, user, newUserTokens);
      emit VolumeDripDripped(source, measure, dripToken, isReferral, user, newUserTokens);
    }
  }

  /// @param pairs The (source, measure) pairs to update.  For each pair all of the balance drips, volume drips, and referral volume drips will be updated.
  /// @param user The user whose drips and balances will be updated.
  /// @param dripTokens The drip tokens to retrieve claim balances for.
  function captureClaimsForBalanceDripsForPairs(
    UpdatePair[] memory pairs,
    address user,
    address[] memory dripTokens
  )
    public
  {
    uint256 i;
    for (i = 0; i < pairs.length; i++) {
      UpdatePair memory pair = pairs[i];
      uint256 measureBalance = IERC20(pair.measure).balanceOf(user);
      _captureClaimsForBalanceDrips(pair.source, pair.measure, user, measureBalance, dripTokens);
    }
  }

  function _captureClaimsForBalanceDrips(
    address source,
    address measure,
    address user,
    uint256 userMeasureBalance,
    address[] memory dripTokens
  ) internal {
    uint i;
    for (i = 0; i < dripTokens.length; i++) {
      address dripToken = dripTokens[i];

      BalanceDrip.State storage state = balanceDrips[source].balanceDrips[measure][dripToken];
      if (state.exchangeRateMantissa > 0) {
        _captureClaimForBalanceDrip(state, source, measure, dripToken, user, userMeasureBalance);
      }
    }
  }

  function _captureClaimForBalanceDrip(
    BalanceDrip.State storage dripState,
    address source,
    address measure,
    address dripToken,
    address user,
    uint256 measureBalance
  ) internal {
    uint256 newUserTokens = dripState.captureNewTokensForUser(
      user,
      measureBalance
    );

    if (newUserTokens > 0) {
      _addDripBalance(dripToken, user, newUserTokens);
      emit BalanceDripDripped(source, measure, dripToken, user, newUserTokens);
    }
  }

  function balanceOfClaims(
    address user,
    address[] memory dripTokens
  ) public view returns (DripTokenBalance[] memory) {
    DripTokenBalance[] memory balances = new DripTokenBalance[](dripTokens.length);
    uint256 i;
    for (i = 0; i < dripTokens.length; i++) {
      balances[i] = DripTokenBalance({
        dripToken: dripTokens[i],
        balance: dripTokenBalances[dripTokens[i]][user]
      });
    }
    return balances;
  }

  /// @notice Updates the given drips for a user and then claims the given drip tokens.  This call will
  /// poke all of the drips and update the claim balances for the given user.
  /// @dev This function will be useful to check the *current* claim balances for a user.
  /// Just need to run this as a constant function to see the latest balances.
  /// in order to claim the values, this function needs to be run alongside a claimDrip function.
  /// @param pairs The (source, measure) pairs of drips to update for the given user
  /// @param user The user for whom to update and claim tokens
  /// @param dripTokens The drip tokens whose entire balance will be claimed after the update.
  /// @return The claimable balance of each of the passed drip tokens for the user.  These are the post-update balances, and therefore the most accurate.
  function updateDrips(
    UpdatePair[] memory pairs,
    address user,
    address[] memory dripTokens
  )
    public returns (DripTokenBalance[] memory)
  {
    updateActiveBalanceDripsForPairs(pairs);
    captureClaimsForBalanceDripsForPairs(pairs, user, dripTokens);
    updateActiveVolumeDripsForPairs(pairs);
    mintAndCaptureVolumeDripsForPairs(pairs, user, 0, dripTokens);
    DripTokenBalance[] memory balances = balanceOfClaims(user, dripTokens);
    return balances;
  }

  /// @notice Updates the given drips for a user and then claims the given drip tokens.  This call will
  /// poke all of the drips and update the claim balances for the given user.
  /// @dev This function will be useful to check the *current* claim balances for a user.
  /// Just need to run this as a constant function to see the latest balances.
  /// in order to claim the values, this function needs to be run alongside a claimDrip function.
  /// @param pairs The (source, measure) pairs of drips to update for the given user
  /// @param user The user for whom to update and claim tokens
  /// @param dripTokens The drip tokens whose entire balance will be claimed after the update.
  /// @return The claimable balance of each of the passed drip tokens for the user.  These are the post-update balances, and therefore the most accurate.
  function updateAndClaimDrips(
    UpdatePair[] calldata pairs,
    address user,
    address[] calldata dripTokens
  )
    external returns (DripTokenBalance[] memory)
  {
    DripTokenBalance[] memory balances = updateDrips(pairs, user, dripTokens);
    claimDrips(user, dripTokens);
    return balances;
  }

  function _activeBalanceDripTokens(address source, address measure) internal view returns (address[] memory) {
    return balanceDrips[source].activeBalanceDrips[measure].addressArray();
  }

  function _activeVolumeDripTokens(address source, address measure) internal view returns (address[] memory) {
    return volumeDrips[source].activeVolumeDrips[measure].addressArray();
  }

  function _activeReferralVolumeDripTokens(address source, address measure) internal view returns (address[] memory) {
    return referralVolumeDrips[source].activeVolumeDrips[measure].addressArray();
  }

  /// @notice Updates the balance drips
  /// @param source The Prize Pool of the balance drip
  /// @param manager The BalanceDripManager whose drips should be updated
  /// @param measure The measure token whose balance is changing
  /// @param measureTotalSupply The last total supply of the measure tokens
  /// @param currentTime The current
  function _updateActiveBalanceDrips(
    BalanceDripManager.State storage manager,
    address source,
    address measure,
    uint256 measureTotalSupply,
    uint256 currentTime
  ) internal {
    address prevDripToken = manager.activeBalanceDrips[measure].end();
    address currentDripToken = manager.activeBalanceDrips[measure].start();
    while (currentDripToken != address(0) && currentDripToken != manager.activeBalanceDrips[measure].end()) {
      BalanceDrip.State storage dripState = manager.balanceDrips[measure][currentDripToken];
      uint256 limit = _availableDripTokenBalance(currentDripToken);

      uint256 newTokens = dripState.drip(
        measureTotalSupply,
        currentTime,
        limit
      );

      // if we've hit the limit, then kill it.
      bool isDripComplete = newTokens == limit;

      if (isDripComplete) {
        _deactivateBalanceDrip(source, measure, currentDripToken, prevDripToken);
      }

      prevDripToken = currentDripToken;
      currentDripToken = manager.activeBalanceDrips[measure].next(currentDripToken);
    }
  }

  /// @notice Records a deposit for a volume drip
  /// @param source The Prize Pool of the volume drip
  /// @param manager The VolumeDripManager containing the drips that need to be iterated through.
  /// @param isReferral Whether the passed manager contains referral volume drip
  /// @param measure The token that was deposited
  function _updateActiveVolumeDrips(
    VolumeDripManager.State storage manager,
    address source,
    address measure,
    bool isReferral
  )
    internal
  {
    address prevDripToken = manager.activeVolumeDrips[measure].end();
    uint256 currentTime = _currentTime();
    address currentDripToken = manager.activeVolumeDrips[measure].start();
    while (currentDripToken != address(0) && currentDripToken != manager.activeVolumeDrips[measure].end()) {
      VolumeDrip.State storage dripState = manager.volumeDrips[measure][currentDripToken];
      uint256 limit = _availableDripTokenBalance(currentDripToken);

      uint32 lastPeriod = dripState.periodCount;
      uint256 newTokens = dripState.drip(
        currentTime,
        limit
      );
      if (lastPeriod != dripState.periodCount) {
        emit VolumeDripPeriodEnded(
          source,
          measure,
          currentDripToken,
          isReferral,
          lastPeriod,
          dripState.periods[lastPeriod].totalSupply,
          newTokens
        );
        emit VolumeDripPeriodStarted(
          source,
          measure,
          currentDripToken,
          isReferral,
          dripState.periodCount,
          dripState.periods[dripState.periodCount].dripAmount,
          dripState.periods[dripState.periodCount].endTime
        );
      }

      // if we've hit the limit, then kill it.
      bool isDripComplete = newTokens == limit;


      if (isDripComplete) {
        _deactivateVolumeDrip(source, measure, currentDripToken, isReferral, prevDripToken);
      }

      prevDripToken = currentDripToken;
      currentDripToken = manager.activeVolumeDrips[measure].next(currentDripToken);
    }
  }

  function _addDripBalance(address dripToken, address user, uint256 amount) internal returns (uint256) {
    uint256 amountAvailable = _availableDripTokenBalance(dripToken);
    uint256 actualAmount = (amount > amountAvailable) ? amountAvailable : amount;

    dripTokenTotalSupply[dripToken] = dripTokenTotalSupply[dripToken].add(actualAmount);
    dripTokenBalances[dripToken][user] = dripTokenBalances[dripToken][user].add(actualAmount);

    emit DripTokenDripped(dripToken, user, actualAmount);
    return actualAmount;
  }

  function _availableDripTokenBalance(address dripToken) internal view returns (uint256) {
    uint256 comptrollerBalance = IERC20(dripToken).balanceOf(address(this));
    uint256 totalClaimable = dripTokenTotalSupply[dripToken];
    return (totalClaimable < comptrollerBalance) ? comptrollerBalance.sub(totalClaimable) : 0;
  }

  /// @notice Called by a "source" (i.e. Prize Pool) when a user mints new "measure" tokens.
  /// @param to The user who is minting the tokens
  /// @param amount The amount of tokens they are minting
  /// @param measure The measure token they are minting
  /// @param referrer The user who referred the minting.
  function beforeTokenMint(
    address to,
    uint256 amount,
    address measure,
    address referrer
  )
    external
    override
  {
    address source = _msgSender();
    uint256 balance = IERC20(measure).balanceOf(to);
    uint256 totalSupply = IERC20(measure).totalSupply();

    address[] memory balanceDripTokens = _activeBalanceDripTokens(source, measure);
    _updateActiveBalanceDrips(
      balanceDrips[source],
      source,
      measure,
      totalSupply,
      _currentTime()
    );
    _captureClaimsForBalanceDrips(source, measure, to, balance, balanceDripTokens);

    address[] memory volumeDripTokens = _activeVolumeDripTokens(source, measure);
    _updateActiveVolumeDrips(
      volumeDrips[source],
      source,
      measure,
      false
    );
    _mintAndCaptureForVolumeDrips(source, measure, to, amount, volumeDripTokens);

    if (referrer != address(0)) {
      address[] memory referralVolumeDripTokens = _activeReferralVolumeDripTokens(source, measure);
      _updateActiveVolumeDrips(
        referralVolumeDrips[source],
        source,
        measure,
        true
      );
      _mintAndCaptureReferralVolumeDrips(source, measure, referrer, amount, referralVolumeDripTokens);
     }
  }

  /// @notice Called by a "source" (i.e. Prize Pool) when tokens change hands or are burned
  /// @param from The user who is sending the tokens
  /// @param to The user who is receiving the tokens
  /// @param measure The measure token they are burning
  function beforeTokenTransfer(
    address from,
    address to,
    uint256,
    address measure
  )
    external
    override
  {
    if (from == address(0)) {
      // ignore minting
      return;
    }
    address source = _msgSender();
    uint256 totalSupply = IERC20(measure).totalSupply();
    uint256 fromBalance = IERC20(measure).balanceOf(from);

    address[] memory balanceDripTokens = _activeBalanceDripTokens(source, measure);

    _updateActiveBalanceDrips(
      balanceDrips[source],
      source,
      measure,
      totalSupply,
      _currentTime()
    );

    _captureClaimsForBalanceDrips(source, measure, from, fromBalance, balanceDripTokens);

    if (to != address(0)) {
      uint256 toBalance = IERC20(measure).balanceOf(to);
      _captureClaimsForBalanceDrips(source, measure, to, toBalance, balanceDripTokens);
    }
  }

  /// @notice returns the current time.  Allows for override in testing.
  /// @return The current time (block.timestamp)
  function _currentTime() internal virtual view returns (uint256) {
    return block.timestamp;
  }

}
