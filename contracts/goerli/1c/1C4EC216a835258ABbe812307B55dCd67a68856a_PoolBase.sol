// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;
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

  function getCooldownFee(IERC20 _token) external view override returns (uint256) {
    return baseData().activateCooldownFee;
  }

  function getSherXWeight(IERC20 _token) external view override returns (uint256) {
    return baseData().sherXWeight;
  }

  function getGovPool(IERC20 _token) external view override returns (address) {
    return baseData().govPool;
  }

  function isPremium(IERC20 _token) external view override returns (bool) {
    return baseData().premiums;
  }

  function isStake(IERC20 _token) external view override returns (bool) {
    return baseData().stakes;
  }

  function getProtocolBalance(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData().protocolBalance[_protocol];
  }

  function getProtocolPremium(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData().protocolPremium[_protocol];
  }

  function getLockToken(IERC20 _token) external view override returns (ILock) {
    return baseData().lockToken;
  }

  function isProtocol(bytes32 _protocol, IERC20 _token) external view override returns (bool) {
    return baseData().isProtocol[_protocol];
  }

  function getProtocols(IERC20 _token) external view override returns (bytes32[] memory) {
    return baseData().protocols;
  }

  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view override returns (PoolStorage.UnstakeEntry memory) {
    return baseData().unstakeEntries[_staker][_id];
  }

  function getTotalAccruedDebt(IERC20 _token) external view override returns (uint256) {
    baseData();
    return LibPool.getTotalAccruedDebt(_token);
  }

  function getFirstMoneyOut(IERC20 _token) external view override returns (uint256) {
    return baseData().firstMoneyOut;
  }

  function getAccruedDebt(bytes32 _protocol, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    baseData();
    return LibPool.accruedDebt(_protocol, _token);
  }

  function getTotalPremiumPerBlock(IERC20 _token) external view override returns (uint256) {
    return baseData().totalPremiumPerBlock;
  }

  function getPremiumLastPaid(IERC20 _token) external view override returns (uint256) {
    return baseData().totalPremiumLastPaid;
  }

  function getSherXUnderlying(IERC20 _token) external view override returns (uint256) {
    return baseData().sherXUnderlying;
  }

  function getUnstakeEntrySize(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    return baseData().unstakeEntries[_staker].length;
  }

  function getInitialUnstakeEntry(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData();
    GovStorage.Base storage gs = GovStorage.gs();
    for (uint256 i = 0; i < ps.unstakeEntries[_staker].length; i++) {
      if (ps.unstakeEntries[_staker][i].blockInitiated == 0) {
        continue;
      }
      if (
        ps.unstakeEntries[_staker][i].blockInitiated.add(gs.unstakeCooldown).add(
          gs.unstakeWindow
        ) <= block.number
      ) {
        continue;
      }
      return i;
    }
    return ps.unstakeEntries[_staker].length;
  }

  function getStakersPoolBalance(IERC20 _token) public view override returns (uint256) {
    return baseData().stakeBalance;
  }

  function getStakerPoolBalance(address _staker, IERC20 _token)
    external
    view
    override
    returns (uint256)
  {
    PoolStorage.Base storage ps = baseData();
    if (ps.lockToken.totalSupply() == 0) {
      return 0;
    }
    return
      ps.lockToken.balanceOf(_staker).mul(getStakersPoolBalance(_token)).div(
        ps.lockToken.totalSupply()
      );
  }

  function getTotalUnmintedSherX(IERC20 _token) public view override returns (uint256) {
    baseData();
    return LibPool.getTotalUnmintedSherX(_token);
  }

  function getUnallocatedSherXStored(IERC20 _token) public view override returns (uint256) {
    return baseData().unallocatedSherX;
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
    baseData();
    return LibPool.getUnallocatedSherXFor(_user, _token);
  }

  function getTotalSherXPerBlock(IERC20 _token) public view override returns (uint256) {
    return SherXStorage.sx().sherXPerBlock.mul(baseData().sherXWeight).div(10**18);
  }

  function getSherXPerBlock(IERC20 _token) external view override returns (uint256) {
    return getSherXPerBlock(msg.sender, _token);
  }

  function getSherXPerBlock(address _user, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData();
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
    return
      getTotalSherXPerBlock(_token).mul(_lock).div(baseData().lockToken.totalSupply().add(_lock));
  }

  function getSherXLastAccrued(IERC20 _token) external view override returns (uint256) {
    return baseData().sherXLastAccrued;
  }

  function LockToTokenXRate(IERC20 _token) external view override returns (uint256) {
    return LockToToken(10**18, _token);
  }

  function LockToToken(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData();
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || ps.stakeBalance == 0) {
      revert('NO_DATA');
    }
    return ps.stakeBalance.mul(_amount).div(totalLock);
  }

  function TokenToLockXRate(IERC20 _token) external view override returns (uint256) {
    return TokenToLock(10**18, _token);
  }

  function TokenToLock(uint256 _amount, IERC20 _token) public view override returns (uint256) {
    PoolStorage.Base storage ps = baseData();
    uint256 totalLock = ps.lockToken.totalSupply();
    if (totalLock == 0 || ps.stakeBalance == 0) {
      return 10**18;
    }
    return totalLock.mul(_amount).div(ps.stakeBalance);
  }

  //
  // Internal view methods
  //

  function baseData() internal view returns (PoolStorage.Base storage ps) {
    ps = PoolStorage.ps(bps());
    require(ps.govPool != address(0), 'INVALID_TOKEN');
  }

  function bps() internal pure returns (IERC20 rt) {
    // These fields are not accessible from assembly
    bytes memory array = msg.data;
    uint256 index = msg.data.length;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
      rt := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
    }
  }

  //
  // State changing methods
  //

  function setCooldownFee(uint256 _fee, IERC20 _token) external override {
    require(msg.sender == GovStorage.gs().govMain, 'NOT_GOV_MAIN');
    require(_fee <= 10**18, 'MAX_VALUE');

    baseData().activateCooldownFee = _fee;
  }

  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external override {
    require(_amount > 0, 'AMOUNT');
    require(GovStorage.gs().protocolIsCovered[_protocol], 'PROTOCOL');
    PoolStorage.Base storage ps = baseData();
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
    require(_amount > 0, 'AMOUNT');
    require(_receiver != address(0), 'RECEIVER');
    PoolStorage.Base storage ps = baseData();

    LibPool.payOffDebtAll(_token);

    if (_amount == uint256(-1)) {
      _amount = ps.protocolBalance[_protocol];
    }

    _token.safeTransfer(_receiver, _amount);
    ps.protocolBalance[_protocol] = ps.protocolBalance[_protocol].sub(_amount);
  }

  function activateCooldown(uint256 _amount, IERC20 _token) external override returns (uint256) {
    require(_amount > 0, 'AMOUNT');
    PoolStorage.Base storage ps = baseData();

    ps.lockToken.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 fee = _amount.mul(ps.activateCooldownFee).div(10**18);
    if (fee > 0) {
      // stake of user gets burned
      // representative amount token get added to first money out pool
      uint256 tokenAmount = fee.mul(ps.stakeBalance).div(ps.lockToken.totalSupply());
      ps.stakeBalance = ps.stakeBalance.sub(tokenAmount);
      ps.firstMoneyOut = ps.firstMoneyOut.add(tokenAmount);

      ps.lockToken.burn(address(this), fee);
    }

    ps.unstakeEntries[msg.sender].push(PoolStorage.UnstakeEntry(block.number, _amount.sub(fee)));

    return ps.unstakeEntries[msg.sender].length - 1;
  }

  function cancelCooldown(uint256 _id, IERC20 _token) external override {
    PoolStorage.Base storage ps = baseData();
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(withdraw.blockInitiated.add(gs.unstakeCooldown) >= block.number, 'COOLDOWN_EXPIRED');
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.safeTransfer(msg.sender, withdraw.lock);
  }

  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external override {
    PoolStorage.Base storage ps = baseData();
    GovStorage.Base storage gs = GovStorage.gs();

    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[_account][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');

    require(
      withdraw.blockInitiated.add(gs.unstakeCooldown).add(gs.unstakeWindow) < block.number,
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
    PoolStorage.Base storage ps = baseData();
    require(_receiver != address(0), 'RECEIVER');
    GovStorage.Base storage gs = GovStorage.gs();
    PoolStorage.UnstakeEntry memory withdraw = ps.unstakeEntries[msg.sender][_id];
    require(withdraw.blockInitiated != 0, 'WITHDRAW_NOT_ACTIVE');
    // period is including
    require(withdraw.blockInitiated.add(gs.unstakeCooldown) < block.number, 'COOLDOWN_ACTIVE');
    require(
      withdraw.blockInitiated.add(gs.unstakeCooldown).add(gs.unstakeWindow) >= block.number,
      'UNSTAKE_WINDOW_EXPIRED'
    );
    amount = withdraw.lock.mul(ps.stakeBalance).div(ps.lockToken.totalSupply());

    ps.stakeBalance = ps.stakeBalance.sub(amount);
    delete ps.unstakeEntries[msg.sender][_id];
    ps.lockToken.burn(address(this), withdraw.lock);
    _token.safeTransfer(_receiver, amount);
  }

  function payOffDebtAll(IERC20 _token) external override {
    baseData();
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

    PoolStorage.Base storage ps = baseData();
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
    if (_forceDebt && accrued > 0) {
      ps.sherXUnderlying = ps.sherXUnderlying.add(ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // send any leftovers back to the protocol receiver
    if (ps.protocolBalance[_protocol] > 0) {
      _token.safeTransfer(_receiver, ps.protocolBalance[_protocol]);
      delete ps.protocolBalance[_protocol];
    }

    // move last index to index of _protocol
    ps.protocols[_index] = ps.protocols[ps.protocols.length - 1];
    // remove last index
    ps.protocols.pop();
    ps.isProtocol[_protocol] = false;
    // could still be >0, if accrued more debt than needed.
    if (ps.protocolPremium[_protocol] > 0) {
      ps.totalPremiumPerBlock = ps.totalPremiumPerBlock.sub(ps.protocolPremium[_protocol]);
      delete ps.protocolPremium[_protocol];
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;
pragma abicoder v2;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../storage/PoolStorage.sol';

/**
  @title Sherlock Pool Controller
  @author Evert Kors
  @notice This contract is for every token pool
  @dev Contract is meant to be included as a facet in the diamond
  @dev Storage library is used
  @dev Storage pointer is calculated based on last _token argument
*/
interface IPoolBase {
  //
  // Events
  //

  //
  // View methods
  //

  /**
    @notice Returns the fee used on `_token` cooldown activation
    @param _token Token used
    @return Cooldown fee scaled by 10**18
  */
  function getCooldownFee(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns SherX weight for `_token`
    @param _token Token used
    @return SherX weight scaled by 10**18
  */
  function getSherXWeight(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns account responsible for `_token`
    @param _token Token used
    @return Account address
  */
  function getGovPool(IERC20 _token) external view returns (address);

  /**
    @notice Returns boolean indicating if `_token` can be used for protocol payments
    @param _token Token used
    @return Premium boolean
  */
  function isPremium(IERC20 _token) external view returns (bool);

  /**
    @notice Returns boolean indicating if `_token` can be used for staking
    @param _token Token used
    @return Staking boolean
  */
  function isStake(IERC20 _token) external view returns (bool);

  /**
    @notice Returns current `_token` balance for `_protocol`
    @param _protocol Protocol identifier
    @param _token Token used
    @return Current balance
  */
  function getProtocolBalance(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns current `_token` premium for `_protocol`
    @param _protocol Protocol identifier
    @param _token Token used
    @return Current premium per block
  */
  function getProtocolPremium(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns linked lockToken for `_token`
    @param _token Token used
    @return Address of lockToken
  */
  function getLockToken(IERC20 _token) external view returns (ILock);

  /**
    @notice Returns if `_protocol` is whitelisted for `_token`
    @param _protocol Protocol identifier
    @param _token Token used
    @return Boolean indicating whitelist status
  */
  function isProtocol(bytes32 _protocol, IERC20 _token) external view returns (bool);

  /**
    @notice Returns array of whitelisted protcols
    @param _token Token used
    @return Array protocol identifiers
  */
  function getProtocols(IERC20 _token) external view returns (bytes32[] memory);

  /**
    @notice Returns `_token` untake entry for `_staker` with id `_id`
    @param _staker Account that started unstake process
    @param _id ID of unstaking entry
    @param _token Token used
    @return Unstaking entry
  */
  function getUnstakeEntry(
    address _staker,
    uint256 _id,
    IERC20 _token
  ) external view returns (PoolStorage.UnstakeEntry memory);

  /**
    @notice Return total debt in  `_token` whitelisted protocols accrued
    @param _token Token used
    @return Total accrued debt
  */
  function getTotalAccruedDebt(IERC20 _token) external view returns (uint256);

  /**
    @notice Return current size of first money out pool
    @param _token Token used
    @return First money out size
  */
  function getFirstMoneyOut(IERC20 _token) external view returns (uint256);

  /**
    @notice Return debt in  `_token` `_protocol` accrued
    @param _protocol Protocol identifier
    @param _token Token used
    @return Accrued debt
  */
  function getAccruedDebt(bytes32 _protocol, IERC20 _token) external view returns (uint256);

  /**
    @notice Return total premium per block that whitelisted protocols are accrueing as debt
    @param _token Token used
    @return Total amount of premium
  */
  function getTotalPremiumPerBlock(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns block debt was last accrued.
    @param _token Token used
    @return Block number
  */
  function getPremiumLastPaid(IERC20 _token) external view returns (uint256);

  /**
    @notice Return total amount of `_token` used as underlying for SHERX
    @param _token Token used
    @return Amount used as underlying
  */
  function getSherXUnderlying(IERC20 _token) external view returns (uint256);

  /**
    @notice Return total amount of `_staker` unstaking entries for `_token`
    @param _staker Account used
    @param _token Token used
    @return Amount of entries
  */
  function getUnstakeEntrySize(address _staker, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns initial active unstaking enty for `_staker`
    @param _staker Account used
    @param _token Token used
    @return Initial ID of unstaking entry
  */
  function getInitialUnstakeEntry(address _staker, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns amount staked in `_token`
    @param _token Token used
    @return Amount staked
  */
  function getStakersPoolBalance(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns `_staker` amount staked in `_token`
    @param _staker Account used
    @param _token Token used
    @return Amount staked
  */
  function getStakerPoolBalance(address _staker, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns unminted SHERX for `_token`
    @param _token Token used
    @return Unminted SHERX
  */
  function getTotalUnmintedSherX(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns stored amount of SHERX not allocated to stakers
    @param _token Token used
    @return Unallocated amount of SHERX
  */
  function getUnallocatedSherXStored(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns current amount of SHERX not allocated to stakers
    @param _token Token used
    @return Unallocated amount of SHERX
  */
  function getUnallocatedSherXTotal(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns current amount of SHERX not allocated to `_user`
    @param _user Staker in token
    @param _token Token used
    @return Unallocated amount of SHERX
  */
  function getUnallocatedSherXFor(address _user, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns SHERX distributed to `_token` stakers per block
    @param _token Token used
    @return Amount of SHERX distributed
  */
  function getTotalSherXPerBlock(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns SHERX distributed per block to sender for staking in `_token`
    @param _token Token used
    @return Amount of SHERX distributed
  */
  function getSherXPerBlock(IERC20 _token) external view returns (uint256);

  /**
    @notice Returns SHERX distributed per block to `_user` for staking in `_token`
    @param _user Account used
    @param _token Token used
    @return Amount of SHERX distributed
  */
  function getSherXPerBlock(address _user, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns SHERX distributed per block when staking `_amount` of `_token`
    @param _amount Amount of tokens
    @param _token Token used
    @return SHERX to be distrubuted if staked
  */
  function getSherXPerBlock(uint256 _amount, IERC20 _token) external view returns (uint256);

  /**
    @notice Returns block SHERX was last accrued to `_token`
    @param _token Token used
    @return Block last accrued
  */
  function getSherXLastAccrued(IERC20 _token) external view returns (uint256);

  /**
    @notice Current exchange rate from lockToken to `_token`
    @param _token Token used
    @return Current exchange rate
  */
  function LockToTokenXRate(IERC20 _token) external view returns (uint256);

  /**
    @notice Current exchange rate from lockToken to `_token` using `_amount`
    @param _amount Amount to be exchanged
    @param _token Token used
    @return Current exchange rate
  */
  function LockToToken(uint256 _amount, IERC20 _token) external view returns (uint256);

  /**
    @notice Current exchange rate from `_token` to lockToken
    @param _token Token used
    @return Current exchange rate
  */
  function TokenToLockXRate(IERC20 _token) external view returns (uint256);

  /**
    @notice Current exchange rate from `_token` to lockToken using `_amount`
    @param _amount Amount to be exchanged
    @param _token Token used
    @return Current exchange rate
  */
  function TokenToLock(uint256 _amount, IERC20 _token) external view returns (uint256);

  //
  // State changing methods
  //

  /**
    @notice Set `_fee` used for activating cooldowns on `_token`
    @param _fee Fee scaled by 10**18
    @param _token Token used
  */
  function setCooldownFee(uint256 _fee, IERC20 _token) external;

  /**
    @notice Deposit `_amount` of `_token` on behalf of `_protocol`
    @param _protocol Protocol identifier
    @param _amount Amount of tokens
    @param _token Token used
  */
  function depositProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    IERC20 _token
  ) external;

  /**
    @notice Withdraw `_amount` of `_token` on behalf of `_protocol` to `_receiver`
    @param _protocol Protocol identifier
    @param _amount Amount of tokens
    @param _receiver Address receiving the amount
    @param _token Token used
  */
  function withdrawProtocolBalance(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    IERC20 _token
  ) external;

  /**
    @notice Start unstaking flow for sender with `_amount` of lockTokens
    @param _amount Amount of lockTokens
    @param _token Token used
    @return ID of unstaking entry
    @dev e.g. _token is DAI, _amount is amount of lockDAI
  */
  function activateCooldown(uint256 _amount, IERC20 _token) external returns (uint256);

  /**
    @notice Cancel unstaking `_token` with entry `_id` for sender
    @param _id ID of unstaking entry
    @param _token Token used
  */
  function cancelCooldown(uint256 _id, IERC20 _token) external;

  /**
    @notice Returns lockTokens to _account if unstaking entry _id is expired
    @param _account Account that initiated unstaking flow
    @param _id ID of unstaking entry
    @param _token Token used
  */
  function unstakeWindowExpiry(
    address _account,
    uint256 _id,
    IERC20 _token
  ) external;

  /**
    @notice Unstake _token for sender with entry _id, send to _receiver
    @param _id ID of unstaking entry
    @param _receiver Account receiving the tokens
    @param _token Token used
    @return amount of tokens unstaked
  */
  function unstake(
    uint256 _id,
    address _receiver,
    IERC20 _token
  ) external returns (uint256 amount);

  /**
    @notice Pay off accrued debt of whitelisted protocols
    @param _token Token used
  */
  function payOffDebtAll(IERC20 _token) external;

  /**
    @notice Remove `_protocol` from `_token` whitelist, send remaining balance to `_receiver`
    @param _protocol Protocol indetifier
    @param _index Entry of protocol in storage array
    @param _forceDebt If protocol has outstanding debt, pay off
    @param _receiver Receiver of remaining deposited balance
    @param _token Token used
  */
  function cleanProtocol(
    bytes32 _protocol,
    uint256 _index,
    bool _forceDebt,
    address _receiver,
    IERC20 _token
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library GovStorage {
  bytes32 constant GOV_STORAGE_POSITION = keccak256('diamond.sherlock.gov');

  struct Base {
    address govMain;
    // NOTE: UNUSED
    mapping(bytes32 => address) protocolManagers;
    mapping(bytes32 => address) protocolAgents;
    uint256 unstakeCooldown;
    uint256 unstakeWindow;
    mapping(bytes32 => bool) protocolIsCovered;
    IERC20[] tokensStaker;
    IERC20[] tokensSherX;
    address watsonsAddress;
    uint256 watsonsSherxWeight;
    uint256 watsonsSherxLastAccrued;
  }

  function gs() internal pure returns (Base storage gsx) {
    bytes32 position = GOV_STORAGE_POSITION;
    assembly {
      gsx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

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

  function accruedDebt(bytes32 _protocol, IERC20 _token) public view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _accruedDebt(ps, _protocol, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalAccruedDebt(IERC20 _token) public view returns (uint256) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    return _getTotalAccruedDebt(ps, block.number.sub(ps.totalPremiumLastPaid));
  }

  function getTotalUnmintedSherX(IERC20 _token) public view returns (uint256 sherX) {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    SherXStorage.Base storage sx = SherXStorage.sx();
    sherX = block.number.sub(ps.sherXLastAccrued).mul(sx.sherXPerBlock).mul(ps.sherXWeight).div(
      10**18
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
      lock = _amount.mul(totalLock).div(ps.stakeBalance);
    }
    ps.stakeBalance = ps.stakeBalance.add(_amount);
    ps.lockToken.mint(_receiver, lock);
  }

  function payOffDebtAll(IERC20 _token) external {
    PoolStorage.Base storage ps = PoolStorage.ps(_token);
    uint256 blocks = block.number.sub(ps.totalPremiumLastPaid);

    for (uint256 i = 0; i < ps.protocols.length; i++) {
      _payOffDebt(ps, ps.protocols[i], blocks);
    }
    // TODO gas optimalisation check
    // _getTotalAccruedDebt reads 1 variable from storage (200 gas)
    // is it cheaper to sum up the debt return value of _payOffDebt()
    // and store that into ps.sherXUnderlying?
    uint256 totalAccruedDebt = _getTotalAccruedDebt(ps, blocks);
    // move funds to the sherX etf
    ps.sherXUnderlying = ps.sherXUnderlying.add(totalAccruedDebt);
    ps.totalPremiumLastPaid = block.number;
  }

  function _payOffDebt(
    PoolStorage.Base storage ps,
    bytes32 _protocol,
    uint256 _blocks
  ) private {
    uint256 debt = _accruedDebt(ps, _protocol, _blocks);
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
pragma solidity ^0.7.0;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../interfaces/ILock.sol';

// TokenStorage
library PoolStorage {
  string constant POOL_STORAGE_PREFIX = 'diamond.sherlock.pool.';

  struct Base {
    address govPool;
    //
    // Staking
    //
    bool stakes;
    ILock lockToken;
    uint256 activateCooldownFee;
    uint256 stakeBalance;
    mapping(address => UnstakeEntry[]) unstakeEntries;
    uint256 firstMoneyOut;
    uint256 unallocatedSherX;
    // How much sherX is distributed to stakers of this token
    uint256 sherXWeight;
    uint256 sherXLastAccrued;
    // Non-native variables
    mapping(address => uint256) sWithdrawn;
    uint256 sWeight;
    //
    // Protocol payments
    //
    bool premiums;
    mapping(bytes32 => uint256) protocolBalance;
    mapping(bytes32 => uint256) protocolPremium;
    uint256 totalPremiumPerBlock;
    uint256 totalPremiumLastPaid;
    // How much token (this) is available for sherX holders
    uint256 sherXUnderlying;
    mapping(bytes32 => bool) isProtocol;
    bytes32[] protocols;
  }

  struct UnstakeEntry {
    uint256 blockInitiated;
    uint256 lock;
  }

  function ps(IERC20 _token) internal pure returns (Base storage psx) {
    bytes32 position = keccak256(abi.encode(POOL_STORAGE_PREFIX, _token));
    assembly {
      psx.slot := position
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.4;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
  @title Lock Token
  @author Evert Kors
  @notice Lock tokens represent a stake in Sherlock
*/
interface ILock is IERC20 {
  /**
    @notice Returns the owner of this contract
    @return Owner address
    @dev Should be equal to the Sherlock address
  */
  function getOwner() external view returns (address);

  /**
    @notice Returns token it represents
    @return Token address
  */
  function underlying() external view returns (IERC20);

  /**
    @notice Mint `_amount` tokens for `_account`
    @param _account Account to receive tokens
    @param _amount Amount to be minted
  */
  function mint(address _account, uint256 _amount) external;

  /**
    @notice Burn `_amount` tokens for `_account`
    @param _account Account to be burned
    @param _amount Amount to be burned
  */
  function burn(address _account, uint256 _amount) external;
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
pragma solidity ^0.7.0;

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

