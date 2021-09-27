// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/IPoolBase.sol';

import '../storage/GovStorage.sol';

import '../libraries/LibPool.sol';

contract PoolBase is IPoolBase {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ILock;

  //
  // View methods
  //

  function getCooldownFee(IERC20 _token) external view override returns (uint32) {
    return baseData(_token).activateCooldownFee;
  }

  function getSherXWeight(IERC20 _token) external view override returns (uint16) {
    return baseData(_token).sherXWeight;
  }

  function getGovPool(IERC20 _token) external view override returns (address) {
    return baseData(_token).govPool;
  }

  function isPremium(IERC20 _token) external view override returns (bool) {
    return baseData(_token).premiums;
  }

  function isStake(IERC20 _token) external view override returns (bool) {
    return baseData(_token).stakes;
  }

  function getProtocolBalance(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).protocolBalance[_protocol];
  }

  function getProtocolPremium(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).protocolPremium[_protocol];
  }

  function getLockToken(IERC20 _token) external view override returns (ILock) {
    return baseData(_token).lockToken;
  }

  function isProtocol(bytes32 _protocol, IERC20 _token) external view override returns (bool) {
    return baseData(_token).isProtocol[_protocol];
  }

  function getProtocols(IERC20 _token) external view override returns (bytes32[] memory) {
    return baseData(_token).protocols;
  }

  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view override returns (PoolStorage.UnstakeEntry memory) {
    return baseData(_token).unstakeEntries[_staker][_id];
  }

  function getTotalAccruedDebt(IERC20 _token) external view override returns (uint256) {
    baseData(_token);
    return LibPool.getTotalAccruedDebt(_token);
  }

  function getFirstMoneyOut(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).firstMoneyOut;
  }

  function getAccruedDebt(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    baseData(_token);
    return LibPool.accruedDebt(_protocol, _token);
  }

  function getTotalPremiumPerBlock(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).totalPremiumPerBlock;
  }

  function getPremiumLastPaid(IERC20 _token) external view override returns (uint40) {
    return baseData(_token).totalPremiumLastPaid;
  }

  function getSherXUnderlying(IERC20 _token) external view override returns (uint256) {
    return baseData(_token).sherXUnderlying;
  }

  function getUnstakeEntrySize(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).unstakeEntries[_staker].length;
  }

  function getInitialUnstakeEntry(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();
    for (uint256 i = 0; i < ps.unstakeEntries[_staker].length; i++) {
      if (ps.unstakeEntries[_staker][i].blockInitiated == 0) {
        continue;
      }
      if (
        ps.unstakeEntries[_staker][i].blockInitiated + gs.unstakeCooldown + gs.unstakeWindow <
        uint40(block.number)
      ) {
        continue;
      }
      return i;
    }
    return ps.unstakeEntries[_staker].length;
  }

  function getUnactivatedStakersPoolBalance(IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData(_token).stakeBalance;
  }

  function getStakersPoolBalance(IERC20 _token) public view override returns (uint256) {
    return LibPool.stakeBalance(baseData(_token));
  }

  function getStakerPoolBalance(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData(_token);
    if (ps.lockToken.totalSupply() == 0) {
      return 0;
    }
    return
      ps.lockToken.balanceOf(_staker).mul(getStakersPoolBalance(_token)).div(
        ps.lockToken.totalSupply()
      );
  }

  function getTotalUnmintedSherX(IERC20 _token) external view override returns (uint256) {
    baseData(_token);
    return LibPool.getTotalUnmintedSherX(_token);
  }

  function getUnallocatedSherXStored(IERC20 _token) public view override returns (uint256) {
    return baseData(_token).unallocatedSherX;
  }

  function getUnallocatedSherXTotal(IERC20 _token) external view override returns (uint256) {
    return getUnallocatedSherXStored(_token).add(LibPool.getTotalUnmintedSherX(_token));
  }

  function getUnallocatedSherXFor(address _user, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    baseData(_token);
    return LibPool.getUnallocatedSherXFor(_user, _token);
  }

  function getTotalSherXPerBlock(IERC20 _token) public view override returns (uint256) {
    return SherXStorage.sx().sherXPerBlock.mul(baseData(_token).sherXWeight).div(type(uint16).max);
  }

  function getSherXPerBlock(IERC20 _token) external view override returns (uint256) {
    return getSherXPerBlock(msg.sender, _token);
  }

  function getSherXPerBlock(address _user, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    if (ps.lockToken.totalSupply() == 0) {
      return 0;
    }
    return
      getTotalSherXPerBlock(_token).mul(ps.lockToken.balanceOf(_user)).div(
        ps.lockToken.totalSupply()
      );
  }

  function getSherXPerBlock(uint256 _lock, IERC20 _token) external view override returns (uint256) {
    // simulates staking (adding lock)
    if (_lock == 0) {
      return 0;
    }
    return
      getTotalSherXPerBlock(_token).mul(_lock).div(
        baseData(_token).lockToken.totalSupply().add(_lock)
      );
  }

  function getSherXLastAccrued(IERC20 _token) external view override returns (uint40) {
    return baseData(_token).sherXLastAccrued;
  }

  function LockToTokenXRate(IERC20 _token) external view override returns (uint256) {
    return LockToToken(10**18, _token);
  }

  function LockToToken(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    uint256 balance = LibPool.stakeBalance(ps);
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || balance == 0) {
      revert('NO_DATA');
    }
    return balance.mul(_amount).div(totalLock);
  }

  function TokenToLockXRate(IERC20 _token) external view override returns (uint256) {
    return TokenToLock(10**18, _token);
  }

  function TokenToLock(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData(_token);
    uint256 balance = LibPool.stakeBalance(ps);
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || balance == 0) {
      return 10**18;
    }
    return totalLock.mul(_amount).div(balance);
  }

  //
  // State changing methods
  //

  function setCooldownFee(uint32 _fee, IERC20 _token) external override {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');

    baseData(_token).activateCooldownFee = _fee;
  }

  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external override {
    require(_amount != 0, 'AMOUNT');
    require(GovStorage.gs().protocolIsCovered[_protocol], 'PROTOCOL');
    PoolStorage.Base storage ps = baseData(_token);
    require(ps.isProtocol[_protocol], 'NO_DEPOSIT');

    _token.safeTransferFrom(msg.sender, address(this), _amount);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].add(_amount);
  }

  function withdrawProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external override {
    require(msg.sender == GovStorage.gs().protocolAgents[_protocol], 'SENDER');
    require(_amount != 0, 'AMOUNT');
    require(_receiver != address(0), 'RECEIVER');
    PoolStorage.Base storage ps = baseData(_token);

    LibPool.payOffDebtAll(_token);

    if (_amount == type(uint256).max) {
      _amount = ps.protocolBalance[_protocol];
    }

    _token.safeTransfer(_receiver, _amount);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].sub(_amount);
  }

  function activateCooldown(uint256 _amount, IERC20 _token) external override returns (uint256) {
    require(_amount != 0, 'AMOUNT');
    PoolStorage.Base storage ps = baseData(_token);

    ps.lockToken.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 fee = _amount.mul(ps.activateCooldownFee).div(type(uint32).max);
    if (fee != 0) {
      // stake of user gets burned
      // representative amount token get added to first money out pool
      uint256 tokenAmount = fee.mul(LibPool.stakeBalance(ps)).div(ps.lockToken.totalSupply());
      ps.firstMoneyOut = ps.firstMoneyOut.add(tokenAmount);

      ps.lockToken.burn(address(this), fee);
    }

    ps.unstakeEntries[msg.sender].push(
      PoolStorage.UnstakeEntry(uint40(block.number), _amount.sub(fee))
    );

    return ps.unstakeEntries[msg.sender].length - 1;
  }

  function cancelCooldown(uint256 _id, IERC20 _token) external override {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(
      withdraw.blockInitiated + gs.unstakeCooldown >= uint40(block.number),
      'COOLDOWN_EXPIRED'
    );
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.safeTransfer(msg.sender, withdraw.lock);
  }

  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external override {
    PoolStorage.Base storage ps = baseData(_token);
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[_account][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(
      withdraw.blockInitiated + gs.unstakeCooldown + gs.unstakeWindow < uint40(block.number),
      'UNSTAKE_WINDOW_NOT_EXPIRED'
    );
    delete ps.unstakeEntries[_account][_id];
    ps.lockToken.safeTransfer(_account, withdraw.lock);
  }

  function unstake(
    uint256 _id,
    address _receiver,
    IERC20 _token
  ) external override returns (uint256 amount) {
    PoolStorage.Base storage ps = baseData(_token);
    require(_receiver != address(0), 'RECEIVER');
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');
    // period is including
    require(withdraw.blockInitiated + gs.unstakeCooldown < uint40(block.number), 'COOLDOWN_ACTIVE');
    require(
      withdraw.blockInitiated + gs.unstakeCooldown + gs.unstakeWindow >= uint40(block.number),
      'UNSTAKE_WINDOW_EXPIRED'
    );
    amount = withdraw.lock.mul(LibPool.stakeBalance(ps)).div(ps.lockToken.totalSupply());

    ps.stakeBalance = ps.stakeBalance.sub(amount);
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.burn(address(this), withdraw.lock);
    _token.safeTransfer(_receiver, amount);
  }

  function payOffDebtAll(IERC20 _token) external override {
    baseData(_token);
    LibPool.payOffDebtAll(_token);
  }

  function cleanProtocol(
    bytes32 _protocol,
    uint256 _index,
    bool _forceDebt,
    address _receiver,
    IERC20 _token
  ) external override {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');
    require(_receiver != address(0), 'RECEIVER');

    PoolStorage.Base storage ps = baseData(_token);
    require(ps.protocols[_index] == _protocol, 'INDEX');

    // If protocol has 0 accrued debt, the premium should also be 0
    // If protocol has >0 accrued debt, needs to be bigger then balance
    // Otherwise just update premium to 0 for the protocol first and then delete
    uint256 accrued = LibPool.accruedDebt(_protocol, _token);
    if (accrued == 0) {
      require(ps.protocolPremium[_protocol] == 0, 'CAN_NOT_DELETE');
    } else {
      require(accrued > ps.protocolBalance[_protocol], 'CAN_NOT_DELETE2');
    }

    // send the remainder of the protocol balance to the sherx underlying
    if (_forceDebt && accrued != 0) {
      ps.sherXUnderlying = ps.sherXUnderlying.add(ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // send any leftovers back to the protocol receiver
    if (ps.protocolBalance[_protocol] != 0) {
      _token.safeTransfer(_receiver, ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // move last index to index of _protocol
    ps.protocols[_index] = ps.protocols[ps.protocols.length - 1];
    // remove last index
    ps.protocols.pop();
    ps.isProtocol[_protocol] = false;
    // could still be >0, if accrued more debt than needed.
    if (ps.protocolPremium[_protocol] != 0) {
      ps.totalPremiumPerBlock = ps.totalPremiumPerBlock.sub(ps.protocolPremium[_protocol]);
      delete ps.protocolPremium[_protocol];
    }
  }

  function baseData(IERC20 _token) internal view returns (PoolStorage.Base storage ps) {
    ps = PoolStorage.ps(_token);
    require(ps.govPool != address(0), 'INVALID_TOKEN');
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../storage/PoolStorage.sol';

/// @title Sherlock Pool Controller
/// @author Evert Kors
/// @notice This contract is for every token pool
/// @dev Contract is meant to be included as a facet in the diamond
/// @dev Storage library is used
/// @dev Storage pointer is calculated based on last _token argument
interface IPoolBase {
  //
  // Events
  //

  //
  // View methods
  //

  /// @notice Returns the fee used on `_token` cooldown activation
  /// @param _token Token used
  /// @return Cooldown fee scaled by type(uint32).max
  function getCooldownFee(IERC20 _token) external view returns (uint32);

  /// @notice Returns SherX weight for `_token`
  /// @param _token Token used
  /// @return SherX weight scaled by type(uint16).max
  function getSherXWeight(IERC20 _token) external view returns (uint16);

  /// @notice Returns account responsible for `_token`
  /// @param _token Token used
  /// @return Account address
  function getGovPool(IERC20 _token) external view returns (address);

  /// @notice Returns boolean indicating if `_token` can be used for protocol payments
  /// @param _token Token used
  /// @return Premium boolean
  function isPremium(IERC20 _token) external view returns (bool);

  /// @notice Returns boolean indicating if `_token` can be used for staking
  /// @param _token Token used
  /// @return Staking boolean
  function isStake(IERC20 _token) external view returns (bool);

  /// @notice Returns current `_token` balance for `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Current balance
  function getProtocolBalance(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Returns current `_token` premium for `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Current premium per block
  function getProtocolPremium(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Returns linked lockToken for `_token`
  /// @param _token Token used
  /// @return Address of lockToken
  function getLockToken(IERC20 _token) external view returns (ILock);

  /// @notice Returns if `_protocol` is whitelisted for `_token`
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Boolean indicating whitelist status
  function isProtocol(bytes32 _protocol, IERC20 _token) external view returns (bool);

  /// @notice Returns array of whitelisted protcols
  /// @param _token Token used
  /// @return Array protocol identifiers
  function getProtocols(IERC20 _token) external view returns (bytes32[] memory);

  /// @notice Returns `_token` untake entry for `_staker` with id `_id`
  /// @param _staker Account that started unstake process
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  /// @return Unstaking entry
  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view returns (PoolStorage.UnstakeEntry memory);

  /// @notice Return total debt in  `_token` whitelisted protocols accrued
  /// @param _token Token used
  /// @return Total accrued debt
  function getTotalAccruedDebt(IERC20 _token) external view returns (uint256);

  /// @notice Return current size of first money out pool
  /// @param _token Token used
  /// @return First money out size
  function getFirstMoneyOut(IERC20 _token) external view returns (uint256);

  /// @notice Return debt in  `_token` `_protocol` accrued
  /// @param _protocol Protocol identifier
  /// @param _token Token used
  /// @return Accrued debt
  function getAccruedDebt(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /// @notice Return total premium per block that whitelisted protocols are accrueing as debt
  /// @param _token Token used
  /// @return Total amount of premium
  function getTotalPremiumPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns block debt was last accrued.
  /// @param _token Token used
  /// @return Block number
  function getPremiumLastPaid(IERC20 _token) external view returns (uint40);

  /// @notice Return total amount of `_token` used as underlying for SHERX
  /// @param _token Token used
  /// @return Amount used as underlying
  function getSherXUnderlying(IERC20 _token) external view returns (uint256);

  /// @notice Return total amount of `_staker` unstaking entries for `_token`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Amount of entries
  function getUnstakeEntrySize(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns initial active unstaking enty for `_staker`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Initial ID of unstaking entry
  function getInitialUnstakeEntry(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns amount staked in `_token` that is not included in a yield strategy
  /// @param _token Token used
  /// @return Amount staked
  function getUnactivatedStakersPoolBalance(IERC20 _token) external view returns (uint256);

  /// @notice Returns amount staked in `_token` including yield strategy
  /// @param _token Token used
  /// @return Amount staked
  function getStakersPoolBalance(IERC20 _token) external view returns (uint256);

  /// @notice Returns `_staker` amount staked in `_token`
  /// @param _staker Account used
  /// @param _token Token used
  /// @return Amount staked
  function getStakerPoolBalance(address _staker, IERC20 _token) external view returns (uint256);

  /// @notice Returns unminted SHERX for `_token`
  /// @param _token Token used
  /// @return Unminted SHERX
  function getTotalUnmintedSherX(IERC20 _token) external view returns (uint256);

  /// @notice Returns stored amount of SHERX not allocated to stakers
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXStored(IERC20 _token) external view returns (uint256);

  /// @notice Returns current amount of SHERX not allocated to stakers
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXTotal(IERC20 _token) external view returns (uint256);

  /// @notice Returns current amount of SHERX not allocated to `_user`
  /// @param _user Staker in token
  /// @param _token Token used
  /// @return Unallocated amount of SHERX
  function getUnallocatedSherXFor(address _user, IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed to `_token` stakers per block
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getTotalSherXPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block to sender for staking in `_token`
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getSherXPerBlock(IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block to `_user` for staking in `_token`
  /// @param _user Account used
  /// @param _token Token used
  /// @return Amount of SHERX distributed
  function getSherXPerBlock(address _user, IERC20 _token) external view returns (uint256);

  /// @notice Returns SHERX distributed per block when staking `_amount` of `_token`
  /// @param _amount Amount of tokens
  /// @param _token Token used
  /// @return SHERX to be distrubuted if staked
  function getSherXPerBlock(uint256 _amount, IERC20 _token) external view returns (uint256);

  /// @notice Returns block SHERX was last accrued to `_token`
  /// @param _token Token used
  /// @return Block last accrued
  function getSherXLastAccrued(IERC20 _token) external view returns (uint40);

  /// @notice Current exchange rate from lockToken to `_token`
  /// @param _token Token used
  /// @return Current exchange rate
  function LockToTokenXRate(IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from lockToken to `_token` using `_amount`
  /// @param _amount Amount to be exchanged
  /// @param _token Token used
  /// @return Current exchange rate
  function LockToToken(uint256 _amount, IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from `_token` to lockToken
  /// @param _token Token used
  /// @return Current exchange rate
  function TokenToLockXRate(IERC20 _token) external view returns (uint256);

  /// @notice Current exchange rate from `_token` to lockToken using `_amount`
  /// @param _amount Amount to be exchanged
  /// @param _token Token used
  /// @return Current exchange rate
  function TokenToLock(uint256 _amount, IERC20 _token) external view returns (uint256);

  //
  // State changing methods
  //

  /// @notice Set `_fee` used for activating cooldowns on `_token`
  /// @param _fee Fee scaled by type(uint32).max
  /// @param _token Token used
  function setCooldownFee(uint32 _fee, IERC20 _token) external;

  /// @notice Deposit `_amount` of `_token` on behalf of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _token Token used
  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external;

  /// @notice Withdraw `_amount` of `_token` on behalf of `_protocol` to `_receiver`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address receiving the amount
  /// @param _token Token used
  function withdrawProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external;

  /// @notice Start unstaking flow for sender with `_amount` of lockTokens
  /// @param _amount Amount of lockTokens
  /// @param _token Token used
  /// @return ID of unstaking entry
  /// @dev e.g. _token is DAI, _amount is amount of lockDAI
  function activateCooldown(uint256 _amount, IERC20 _token) external returns (uint256);

  /// @notice Cancel unstaking `_token` with entry `_id` for sender
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  function cancelCooldown(uint256 _id, IERC20 _token) external;

  /// @notice Returns lockTokens to _account if unstaking entry _id is expired
  /// @param _account Account that initiated unstaking flow
  /// @param _id ID of unstaking entry
  /// @param _token Token used
  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external;

  /// @notice Unstake _token for sender with entry _id, send to _receiver
  /// @param _id ID of unstaking entry
  /// @param _receiver Account receiving the tokens
  /// @param _token Token used
  /// @return amount of tokens unstaked
  function unstake(
    uint256 _id,
    address _receiver,
    IERC20 _token
  ) external returns (uint256 amount);

  /// @notice Pay off accrued debt of whitelisted protocols
  /// @param _token Token used
  function payOffDebtAll(IERC20 _token) external;

  /// @notice Remove `_protocol` from `_token` whitelist, send remaining balance to `_receiver`
  /// @param _protocol Protocol indetifier
  /// @param _index Entry of protocol in storage array
  /// @param _forceDebt If protocol has outstanding debt, pay off
  /// @param _receiver Receiver of remaining deposited balance
  /// @param _token Token used
  function cleanProtocol(
    bytes32 _protocol,
    uint256 _index,
    bool _forceDebt,
    address _receiver,
    IERC20 _token
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library GovStorage {
  bytes32 constant GOV_STORAGE_POSITION = keccak256('diamond.sherlock.gov');

  struct Base {
    // The address appointed as the govMain entity
    address govMain;
    // NOTE: UNUSED
    mapping(bytes32 => address) protocolManagers;
    // Based on the protocol identifier, get the address of the protocol that is able the withdraw balances
    mapping(bytes32 => address) protocolAgents;
    // Check if the protocol is included in the solution at all
    mapping(bytes32 => bool) protocolIsCovered;
    // The array of tokens the accounts are able to stake in
    IERC20[] tokensStaker;
    // The array of tokens the protocol are able to pay premium in
    // These tokens will also be the underlying for SherX
    IERC20[] tokensSherX;
    // The address of the watsons, an account that can receive SherX rewards
    address watsonsAddress;
    // How much sherX is distributed to this account
    // The max value is type(uint16).max, which means 100% of the total SherX minted is allocated to this acocunt
    uint16 watsonsSherxWeight;
    // The last block the total amount of rewards were accrued.
    uint40 watsonsSherxLastAccrued;
    // Max amount of SherX token to be in the `tokensSherX` array
    uint8 maxTokensSherX;
    // Max amount of Staker token to be in the `tokensStaker` array
    uint8 maxTokensStaker;
    // Max amount of protocol to be in single pool
    uint8 maxProtocolPool;
    // The amount of blocks the cooldown period takes
    uint40 unstakeCooldown;
    // The amount of blocks for the window of opportunity of unstaking
    uint40 unstakeWindow;
  }

  function gs() internal pure returns (Base storage gsx) {
    bytes32 position = GOV_STORAGE_POSITION;
    assembly {
      gsx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../storage/PoolStorage.sol';
import '../storage/SherXStorage.sol';

library LibPool {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ILock;

  function stakeBalance(PoolStorage.Base storage ps) public view returns (uint256) {
    uint256 balance = ps.stakeBalance;

    if (address(ps.strategy) != address(0)) {
      balance = balance.add(ps.strategy.balanceOf());
    }

    return balance.sub(ps.firstMoneyOut);
  }

  function accruedDebt(bytes32 _protocol, IERC20 _token) external view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _accruedDebt(ps, _protocol, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalAccruedDebt(IERC20 _token) external view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _getTotalAccruedDebt(ps, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalUnmintedSherX(IERC20 _token) public view returns (uint256 sherX) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    SherXStorage.Base storage sx = SherXStorage.sx();
    sherX = block.number.sub(ps.sherXLastAccrued).mul(sx.sherXPerBlock).mul(ps.sherXWeight).div(
      type(uint16).max
    );
  }

  function getUnallocatedSherXFor(address _user, IERC20 _token)
    external
    view
    returns (uint256 withdrawable_amount)
  {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);

    uint256 userAmount = ps.lockToken.balanceOf(_user);
    uint256 totalAmount = ps.lockToken.totalSupply();
    if (totalAmount == 0) {
      return 0;
    }

    uint256 raw_amount =
      ps.sWeight.add(getTotalUnmintedSherX(_token)).mul(userAmount).div(totalAmount);
    withdrawable_amount = raw_amount.sub(ps.sWithdrawn[_user]);
  }

  function stake(
    PoolStorage.Base storage ps,
    uint256 _amount,
    address _receiver
  ) external returns (uint256 lock) {
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0) {
      // mint initial lock
      lock = 10**18;
    } else {
      // mint lock based on funds in pool
      lock = _amount.mul(totalLock).div(stakeBalance(ps));
    }
    ps.stakeBalance = ps.stakeBalance.add(_amount);
    ps.lockToken.mint(_receiver, lock);
  }

  function payOffDebtAll(IERC20 _token) external {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    uint256 blocks = block.number.sub(ps.totalPremiumLastPaid);

    uint256 totalAccruedDebt;
    uint256 length = ps.protocols.length;
    for (uint256 i = 0; i < length; i++) {
      totalAccruedDebt = totalAccruedDebt.add(_payOffDebt(ps, ps.protocols[i], blocks));
    }
    // move funds to the sherX etf
    ps.sherXUnderlying = ps.sherXUnderlying.add(totalAccruedDebt);
    ps.totalPremiumLastPaid = uint40(block.number);
  }

  function _payOffDebt(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _blocks
  ) private returns (uint256 debt) {
    debt = _accruedDebt(ps, _protocol, _blocks);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].sub(debt);
  }

  function _accruedDebt(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _blocks
  ) private view returns (uint256) {
    return _blocks.mul(ps.protocolPremium[_protocol]);
  }

  function _getTotalAccruedDebt(PoolStorage.Base storage ps, uint256 _blocks)
    private
    view
    returns (uint256)
  {
    return _blocks.mul(ps.totalPremiumPerBlock);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';
import '../interfaces/IStrategy.sol';

// TokenStorage
library PoolStorage {
  bytes32 constant POOL_STORAGE_PREFIX = 'diamond.sherlock.pool.';

  struct Base {
    address govPool;
    // Variable used to calculate the fee when activating the cooldown
    // Max value is type(uint32).max which creates a 100% fee on the withdrawal
    uint32 activateCooldownFee;
    // How much sherX is distributed to stakers of this token
    // The max value is type(uint16).max, which means 100% of the total SherX minted is allocated to this pool
    uint16 sherXWeight;
    // The last block the total amount of rewards were accrued.
    // Accrueing SherX increases the `unallocatedSherX` variable
    uint40 sherXLastAccrued;
    // Indicates if protocol are able to pay premiums with this token
    // If this value is true, the token is also included as underlying of the SherX
    bool premiums;
    // Protocol debt can only be settled at once for all the protocols at the same time
    // This variable is the block number the last time all the protocols debt was settled
    uint40 totalPremiumLastPaid;
    //
    // Staking
    //
    // Indicates if stakers can stake funds in the pool
    bool stakes;
    // Address of the lockToken. Representing stakes in this pool
    ILock lockToken;
    // The total amount staked by the stakers in this pool, including value of `firstMoneyOut`
    // if you exclude the `firstMoneyOut` from this value, you get the actual amount of tokens staked
    // This value is also excluding funds deposited in a strategy.
    uint256 stakeBalance;
    // All the withdrawals by an account
    // The values of the struct are all deleted if expiry() or unstake() function is called
    mapping(address => UnstakeEntry[]) unstakeEntries;
    // Represents the amount of tokens in the first money out pool
    uint256 firstMoneyOut;
    // If the `stakes` = true, the stakers can be rewarded by sherx
    // stakers can claim their rewards by calling the harvest() function
    // SherX could be minted before the stakers call the harvest() function
    // Minted SherX that is assigned as reward for the pool will be added to this value
    uint256 unallocatedSherX;
    // Non-native variables
    // These variables are used to calculate the right amount of SherX rewards for the token staked
    mapping(address => uint256) sWithdrawn;
    uint256 sWeight;
    // Storing the protocol token balance based on the protocols bytes32 indentifier
    mapping(bytes32 => uint256) protocolBalance;
    // Storing the protocol premium, the amount of debt the protocol builds up per block.
    // This is based on the bytes32 identifier of the protocol.
    mapping(bytes32 => uint256) protocolPremium;
    // The sum of all the protocol premiums, the total amount of debt that builds up in this token. (per block)
    uint256 totalPremiumPerBlock;
    // How much tokens are used as underlying for SherX
    uint256 sherXUnderlying;
    // Check if the protocol is included in the token pool
    // The protocol can deposit balances if this is the case
    mapping(bytes32 => bool) isProtocol;
    // Array of protocols that are registered in this pool
    bytes32[] protocols;
    // Active strategy for this token pool
    IStrategy strategy;
  }

  struct UnstakeEntry {
    // The block number the cooldown is activated
    uint40 blockInitiated;
    // The amount of lock tokens to be withdrawn
    uint256 lock;
  }

  function ps(IERC20 _token) internal pure returns (Base storage psx) {
    bytes32 position = keccak256(abi.encodePacked(POOL_STORAGE_PREFIX, _token));
    assembly {
      psx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Lock Token
/// @author Evert Kors
/// @notice Lock tokens represent a stake in Sherlock
interface ILock is IERC20 {
  /// @notice Returns the owner of this contract
  /// @return Owner address
  /// @dev Should be equal to the Sherlock address
  function getOwner() external view returns (address);

  /// @notice Returns token it represents
  /// @return Token address
  function underlying() external view returns (IERC20);

  /// @notice Mint `_amount` tokens for `_account`
  /// @param _account Account to receive tokens
  /// @param _amount Amount to be minted
  function mint(address _account, uint256 _amount) external;

  /// @notice Burn `_amount` tokens for `_account`
  /// @param _account Account to be burned
  /// @param _amount Amount to be burned
  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface IStrategy {
  function want() external view returns (ERC20);

  function withdrawAll() external returns (uint256);

  function withdraw(uint256 _amount) external;

  function deposit() external;

  function balanceOf() external view returns (uint256);

  function sweep(address _receiver, IERC20[] memory _extraTokens) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library SherXStorage {
  bytes32 constant SHERX_STORAGE_POSITION = keccak256('diamond.sherlock.x');

  struct Base {
    mapping(IERC20 => uint256) tokenUSD;
    uint256 totalUsdPerBlock;
    uint256 totalUsdPool;
    uint256 totalUsdLastSettled;
    uint256 sherXPerBlock;
    uint256 internalTotalSupply;
    uint256 internalTotalSupplySettled;
  }

  function sx() internal pure returns (Base storage sxx) {
    bytes32 position = SHERX_STORAGE_POSITION;
    assembly {
      sxx.slot := position
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

{
  "optimizer": {
    "enabled": true,
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
  "libraries": {
    "@sherlock/v1-core/contracts/libraries/LibPool.sol": {
      "LibPool": "0xe1215b2dc94f487818d65fd7a4f8b9558602f0e0"
    }
  }
}