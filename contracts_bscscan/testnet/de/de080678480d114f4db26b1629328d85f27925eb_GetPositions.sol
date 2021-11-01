// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";

import "./PositionManager.sol";
import "./IBookKeeper.sol";
import "./ICollateralPoolConfig.sol";

contract GetPositions is Initializable {
  using SafeMathUpgradeable for uint256;

  // --- Math ---
  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;
  uint256 constant RAD = 10**45;

  // --- Init ---
  function initialize() external initializer {}

  function getAllPositionsAsc(address _manager, address _user)
    external
    view
    returns (
      uint256[] memory _ids,
      address[] memory _positions,
      bytes32[] memory _collateralPools
    )
  {
    uint256 _count = PositionManager(_manager).ownerPositionCount(_user);
    uint256 _id = PositionManager(_manager).ownerFirstPositionId(_user);
    return _getPositionsAsc(_manager, _id, _count);
  }

  function getPositionsAsc(
    address _manager,
    uint256 _fromId,
    uint256 _size
  )
    external
    view
    returns (
      uint256[] memory _ids,
      address[] memory _positions,
      bytes32[] memory _collateralPools
    )
  {
    return _getPositionsAsc(_manager, _fromId, _size);
  }

  function _getPositionsAsc(
    address _manager,
    uint256 _fromId,
    uint256 _size
  )
    internal
    view
    returns (
      uint256[] memory _ids,
      address[] memory _positions,
      bytes32[] memory _collateralPools
    )
  {
    _ids = new uint256[](_size);
    _positions = new address[](_size);
    _collateralPools = new bytes32[](_size);
    uint256 _i = 0;
    uint256 _id = _fromId;

    while (_id > 0 && _i < _size) {
      _ids[_i] = _id;
      _positions[_i] = PositionManager(_manager).positions(_id);
      _collateralPools[_i] = PositionManager(_manager).collateralPools(_id);
      (, _id) = PositionManager(_manager).list(_id);
      _i++;
    }
  }

  function getAllPositionsDesc(address _manager, address _user)
    external
    view
    returns (
      uint256[] memory,
      address[] memory,
      bytes32[] memory
    )
  {
    uint256 _count = PositionManager(_manager).ownerPositionCount(_user);
    uint256 _id = PositionManager(_manager).ownerLastPositionId(_user);
    return _getPositionsDesc(_manager, _id, _count);
  }

  function getPositionsDesc(
    address _manager,
    uint256 _fromId,
    uint256 _size
  )
    external
    view
    returns (
      uint256[] memory,
      address[] memory,
      bytes32[] memory
    )
  {
    return _getPositionsDesc(_manager, _fromId, _size);
  }

  function _getPositionsDesc(
    address _manager,
    uint256 _fromId,
    uint256 _size
  )
    internal
    view
    returns (
      uint256[] memory _ids,
      address[] memory _positions,
      bytes32[] memory _collateralPools
    )
  {
    _ids = new uint256[](_size);
    _positions = new address[](_size);
    _collateralPools = new bytes32[](_size);
    uint256 _i = 0;
    uint256 _id = _fromId;

    while (_id > 0 && _i < _size) {
      _ids[_i] = _id;
      _positions[_i] = PositionManager(_manager).positions(_id);
      _collateralPools[_i] = PositionManager(_manager).collateralPools(_id);
      (_id, ) = PositionManager(_manager).list(_id);
      _i++;
    }
  }

  function getPositionWithSafetyBuffer(
    address _manager,
    uint256 _startIndex,
    uint256 _offset
  )
    external
    view
    returns (
      address[] memory _positions,
      uint256[] memory _debtShares,
      uint256[] memory _safetyBuffers
    )
  {
    if (_startIndex.add(_offset) > PositionManager(_manager).lastPositionId())
      _offset = PositionManager(_manager).lastPositionId().sub(_startIndex).add(1);

    IBookKeeper _bookKeeper = IBookKeeper(PositionManager(_manager).bookKeeper());
    _positions = new address[](_offset);
    _debtShares = new uint256[](_offset);
    _safetyBuffers = new uint256[](_offset);
    uint256 _resultIndex = 0;
    for (uint256 _positionIndex = _startIndex; _positionIndex < _startIndex.add(_offset); _positionIndex++) {
      if (PositionManager(_manager).positions(_positionIndex) == address(0)) break;
      _positions[_resultIndex] = PositionManager(_manager).positions(_positionIndex);

      bytes32 _collateralPoolId = PositionManager(_manager).collateralPools(_positionIndex);
      (uint256 _lockedCollateral, uint256 _debtShare) = _bookKeeper.positions(
        _collateralPoolId,
        _positions[_resultIndex]
      );

      ICollateralPoolConfig collateralPoolConfig = ICollateralPoolConfig(_bookKeeper.collateralPoolConfig());

      uint256 _safetyBuffer = calculateSafetyBuffer(
        _debtShare,
        collateralPoolConfig.getDebtAccumulatedRate(_collateralPoolId),
        _lockedCollateral,
        collateralPoolConfig.getPriceWithSafetyMargin(_collateralPoolId)
      );

      _safetyBuffers[_resultIndex] = _safetyBuffer;
      _debtShares[_resultIndex] = _debtShare;
      _resultIndex++;
    }
  }

  function calculateSafetyBuffer(
    uint256 _debtShare, // [wad]
    uint256 _debtAccumulatedRate, // [ray]
    uint256 _lockedCollateral, // [wad]
    uint256 _priceWithSafetyMargin // [ray]
  )
    internal
    view
    returns (
      uint256 _safetyBuffer // [rad]
    )
  {
    uint256 _collateralValue = _lockedCollateral.mul(_priceWithSafetyMargin);
    uint256 _debtValue = _debtShare.mul(_debtAccumulatedRate);
    _safetyBuffer = _collateralValue >= _debtValue ? _collateralValue.sub(_debtValue) : 0;
  }
}