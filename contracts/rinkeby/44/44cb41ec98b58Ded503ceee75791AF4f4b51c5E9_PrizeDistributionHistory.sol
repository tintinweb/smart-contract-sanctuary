// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./libraries/DrawLib.sol";
import "./libraries/DrawRingBufferLib.sol";
import "./interfaces/IPrizeDistributionHistory.sol";

/**
  * @title  PoolTogether V4 PrizeDistributionHistory
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionHistory stores individual PrizeDistributions for each Draw.drawId.
            PrizeDistributions parameters like cardinality, bitRange, distributions, number of picks
            and prize. The settings determine the specific distribution model for each individual
            draw. Storage of the PrizeDistribution(s) is handled by ring buffer with a max cardinality
            of 256 or roughly 5 years of history with a weekly draw cadence.
*/
contract PrizeDistributionHistory is IPrizeDistributionHistory, Manageable {
  using DrawRingBufferLib for DrawRingBufferLib.Buffer;

  uint256 internal constant MAX_CARDINALITY = 256;

  uint256 internal constant DISTRIBUTION_CEILING = 1e9;
  event Deployed(uint8 cardinality);

  /// @notice PrizeDistributions ring buffer history.
  DrawLib.PrizeDistribution[MAX_CARDINALITY] internal _prizeDistributionsRingBuffer;

  /// @notice Ring buffer data (nextIndex, lastDrawId, cardinality)
  DrawRingBufferLib.Buffer internal prizeDistributionsRingBufferData;

  /* ============ Constructor ============ */

  /**
    * @notice Constructor for PrizeDistributionHistory
    * @param _owner Address of the PrizeDistributionHistory owner
    * @param _cardinality Cardinality of the `prizeDistributionsRingBufferData`
   */
  constructor(
    address _owner,
    uint8 _cardinality
  ) Ownable(_owner) {
    prizeDistributionsRingBufferData.cardinality = _cardinality;
    emit Deployed(_cardinality);
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IPrizeDistributionHistory
  function getPrizeDistribution(uint32 _drawId) external override view returns(DrawLib.PrizeDistribution memory) {
    return _getPrizeDistributions(prizeDistributionsRingBufferData, _drawId);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getPrizeDistributions(uint32[] calldata _drawIds) external override view returns(DrawLib.PrizeDistribution[] memory) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    DrawLib.PrizeDistribution[] memory _prizeDistributions = new DrawLib.PrizeDistribution[](_drawIds.length);
    for (uint256 i = 0; i < _drawIds.length; i++) {
      _prizeDistributions[i] = _getPrizeDistributions(buffer, _drawIds[i]);
    }
    return _prizeDistributions;
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getNewestPrizeDistribution() external override view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    return (_prizeDistributionsRingBuffer[buffer.getIndex(buffer.lastDrawId)], buffer.lastDrawId);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function getOldestPrizeDistribution() external override view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    prizeDistribution = _prizeDistributionsRingBuffer[buffer.nextIndex];

    // IF the next PrizeDistributions.bitRangeSize == 0 the ring buffer HAS NOT looped around.
    // The PrizeDistributions at index 0 IS by defaut the oldest prizeDistribution.
    if (buffer.lastDrawId == 0) {
      drawId = 0; // return 0 to indicate no prizeDistribution ring buffer history
    } else if (prizeDistribution.bitRangeSize == 0) {
      prizeDistribution = _prizeDistributionsRingBuffer[0];
      drawId = (buffer.lastDrawId + 1) - buffer.nextIndex; // 2 + 1 - 2 = 1 | [1,2,0]
    } else {
      // Calculates the Draw.drawID using the ring buffer length and SEQUENTIAL id(s)
      // Sequential "guaranteedness" is handled in DrawRingBufferLib.push()
      drawId = (buffer.lastDrawId + 1) - buffer.cardinality; // 4 + 1 - 3 = 2 | [4,2,3]
    }
  }

  /// @inheritdoc IPrizeDistributionHistory
  function pushPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) external override onlyManagerOrOwner returns (bool) {
    return _pushPrizeDistribution(_drawId, _prizeDistribution);
  }

  /// @inheritdoc IPrizeDistributionHistory
  function setPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) external override onlyOwner returns (uint32) {
    DrawRingBufferLib.Buffer memory buffer = prizeDistributionsRingBufferData;
    uint32 index = buffer.getIndex(_drawId);
    _prizeDistributionsRingBuffer[index] = _prizeDistribution;
    emit PrizeDistributionsSet(_drawId, _prizeDistribution);
    return _drawId;
  }


  /* ============ Internal Functions ============ */

  /**
    * @notice Gets the PrizeDistributionHistory for a Draw.drawID
    * @param _prizeDistributionsRingBufferData DrawRingBufferLib.Buffer
    * @param drawId Draw.drawId
   */
  function _getPrizeDistributions(
    DrawRingBufferLib.Buffer memory _prizeDistributionsRingBufferData,
    uint32 drawId
  ) internal view returns (DrawLib.PrizeDistribution memory) {
    return _prizeDistributionsRingBuffer[_prizeDistributionsRingBufferData.getIndex(drawId)];
  }

  /**
    * @notice Set newest PrizeDistributionHistory in ring buffer storage.
    * @param _drawId       Draw.drawId
    * @param _prizeDistribution PrizeDistributionHistory struct
   */
  function _pushPrizeDistribution(uint32 _drawId, DrawLib.PrizeDistribution calldata _prizeDistribution) internal returns (bool) {
    require(_drawId > 0, "DrawCalc/draw-id-gt-0");
    require(_prizeDistribution.bitRangeSize <= 256 / _prizeDistribution.matchCardinality, "DrawCalc/bitRangeSize-too-large");
    require(_prizeDistribution.bitRangeSize > 0, "DrawCalc/bitRangeSize-gt-0");
    require(_prizeDistribution.maxPicksPerUser > 0, "DrawCalc/maxPicksPerUser-gt-0");

    // ensure that the distributions are not gt 100%
    uint256 sumTotalDistributions = 0;
    uint256 nonZeroDistributions = 0;
    uint256 distributionsLength = _prizeDistribution.distributions.length;

    for(uint256 index = 0; index < distributionsLength; index++){
      sumTotalDistributions += _prizeDistribution.distributions[index];
      if(_prizeDistribution.distributions[index] > 0){
        nonZeroDistributions++;
      }
    }

    // Each distribution amount stored as uint32 - summed can't exceed 1e9
    require(sumTotalDistributions <= DISTRIBUTION_CEILING, "DrawCalc/distributions-gt-100%");

    require(_prizeDistribution.matchCardinality >= nonZeroDistributions, "DrawCalc/matchCardinality-gte-distributions");

    DrawRingBufferLib.Buffer memory _prizeDistributionsRingBufferData = prizeDistributionsRingBufferData;
    _prizeDistributionsRingBuffer[_prizeDistributionsRingBufferData.nextIndex] = _prizeDistribution;
    prizeDistributionsRingBufferData = prizeDistributionsRingBufferData.push(_drawId);

    emit PrizeDistributionsSet(_drawId, _prizeDistribution);

    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;
import "../libraries/DrawLib.sol";

interface IPrizeDistributionHistory {

  /**
    * @notice Emit when a new draw has been created.
    * @param drawId       Draw id
    * @param timestamp    Epoch timestamp when the draw is created.
    * @param winningRandomNumber Randomly generated number used to calculate draw winning numbers
  */
  event DrawSet (
    uint32 drawId,
    uint32 timestamp,
    uint256 winningRandomNumber
  );

  /**
    * @notice Emitted when the DrawParams are set/updated
    * @param drawId       Draw id
    * @param prizeDistributions DrawLib.PrizeDistribution
  */
  event PrizeDistributionsSet(uint32 indexed drawId, DrawLib.PrizeDistribution prizeDistributions);


  /**
    * @notice Read newest PrizeDistributions from the prize distributions ring buffer.
    * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
    * @return prizeDistribution DrawLib.PrizeDistribution
    * @return drawId Draw.drawId
  */
  function getNewestPrizeDistribution() external view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId);

  /**
    * @notice Read oldest PrizeDistributions from the prize distributions ring buffer.
    * @dev    Finds the oldest Draw by buffer.nextIndex and buffer.lastDrawId
    * @return prizeDistribution DrawLib.PrizeDistribution
    * @return drawId Draw.drawId
  */
  function getOldestPrizeDistribution() external view returns (DrawLib.PrizeDistribution memory prizeDistribution, uint32 drawId);

  /**
    * @notice Gets array of PrizeDistributionHistory for Draw.drawID(s)
    * @param drawIds Draw.drawId
   */
  function getPrizeDistributions(uint32[] calldata drawIds) external view returns (DrawLib.PrizeDistribution[] memory);

  /**
    * @notice Gets the PrizeDistributionHistory for a Draw.drawID
    * @param drawId Draw.drawId
   */
  function getPrizeDistribution(uint32 drawId) external view returns (DrawLib.PrizeDistribution memory);

  /**
    * @notice Sets PrizeDistributionHistory for a Draw.drawID.
    * @dev    Only callable by the owner or manager
    * @param drawId Draw.drawId
    * @param draw   PrizeDistributionHistory struct
   */
  function pushPrizeDistribution(uint32 drawId, DrawLib.PrizeDistribution calldata draw) external returns(bool);

  /**
    * @notice Set existing Draw in prize distributions ring buffer with new parameters.
    * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
    * @return Draw.drawId
  */
  function setPrizeDistribution(uint32 drawId, DrawLib.PrizeDistribution calldata draw) external returns(uint32); // maybe return drawIndex

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library DrawLib {

    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    uint8 public constant DISTRIBUTIONS_LENGTH = 16;

    ///@notice Draw settings for the tsunami draw calculator
    ///@param bitRangeSize Decimal representation of bitRangeSize
    ///@param matchCardinality The bitRangeSize's to consider in the 256 random numbers. Must be > 1 and < 256/bitRangeSize
    ///@param startTimestampOffset The starting time offset in seconds from which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
    ///@param maxPicksPerUser Maximum number of picks a user can make in this Draw
    ///@param numberOfPicks Number of picks this Draw has (may vary network to network)
    ///@param distributions Array of prize distributions percentages, expressed in fraction form with base 1e18. Max sum of these <= 1 Ether. ordering: index0: grandPrize, index1: runnerUp, etc.
    ///@param prize Total prize amount available in this draw calculator for this Draw (may vary from network to network)
    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint136 numberOfPicks;
        uint32[DISTRIBUTIONS_LENGTH] distributions;
        uint256 prize;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./RingBuffer.sol";

/// @title Library for creating and managing a draw ring buffer.
library DrawRingBufferLib {

  /// @notice Draw buffer struct.
  struct Buffer {
    uint32 lastDrawId;
    uint32 nextIndex;
    uint32 cardinality;
  }

  /// @notice Helper function to know if the draw ring buffer has been initialized.
  /// @dev since draws start at 1 and are monotonically increased, we know we are uninitialized if nextIndex = 0 and lastDrawId = 0.
  /// @param _buffer The buffer to check.
  function isInitialized(Buffer memory _buffer) internal pure returns (bool) {
    return !(_buffer.nextIndex == 0 && _buffer.lastDrawId == 0);
  }

  /// @notice Push a draw to the buffer.
  /// @param _buffer The buffer to push to.
  /// @param _drawId The draw id to push.
  /// @return The new buffer.
  function push(Buffer memory _buffer, uint32 _drawId) internal pure returns (Buffer memory) {
    require(!isInitialized(_buffer) || _drawId == _buffer.lastDrawId + 1, "DRB/must-be-contig");
    return Buffer({
      lastDrawId: _drawId,
      nextIndex: uint32(RingBuffer.nextIndex(_buffer.nextIndex, _buffer.cardinality)),
      cardinality: _buffer.cardinality
    });
  }

  /// @notice Get draw ring buffer index pointer.
  /// @param _buffer The buffer to get the `nextIndex` from.
  /// @param _drawId The draw id to get the index for.
  /// @return The draw ring buffer index pointer.
  function getIndex(Buffer memory _buffer, uint32 _drawId) internal pure returns (uint32) {
    require(isInitialized(_buffer) && _drawId <= _buffer.lastDrawId, "DRB/future-draw");

    uint32 indexOffset = _buffer.lastDrawId - _drawId;
    require(indexOffset < _buffer.cardinality, "DRB/expired-draw");

    uint256 mostRecent = RingBuffer.mostRecentIndex(_buffer.nextIndex, _buffer.cardinality);

    return uint32(RingBuffer.offset(uint32(mostRecent), indexOffset, _buffer.cardinality));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

library RingBuffer {

  /// @notice Returns TWAB index.
  /// @dev `twabs` is a circular buffer of `MAX_CARDINALITY` size equal to 32. So the array goes from 0 to 31.
  /// @dev In order to navigate the circular buffer, we need to use the modulo operator.
  /// @dev For example, if `_index` is equal to 32, `_index % MAX_CARDINALITY` will return 0 and will point to the first element of the array.
  /// @param _index Index used to navigate through `twabs` circular buffer.
  function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
    return _index % _cardinality;
  }

  function offset(uint256 _index, uint256 _amount, uint256 _cardinality) internal pure returns (uint256) {
    return (_index + _cardinality - _amount) % _cardinality;
  }

  /// @notice Returns the index of the last recorded TWAB
  /// @param _nextAvailableIndex The next available twab index.  This will be recorded to next.
  /// @param _cardinality The cardinality of the TWAB history.
  /// @return The index of the last recorded TWAB
  function mostRecentIndex(uint256 _nextAvailableIndex, uint256 _cardinality) internal pure returns (uint256) {
    if (_cardinality == 0) {
      return 0;
    }
    return (_nextAvailableIndex + uint256(_cardinality) - 1) % _cardinality;
  }

  function nextIndex(uint256 _currentIndex, uint256 _cardinality) internal pure returns (uint256) {
    return (_currentIndex + 1) % _cardinality;
  }

}

