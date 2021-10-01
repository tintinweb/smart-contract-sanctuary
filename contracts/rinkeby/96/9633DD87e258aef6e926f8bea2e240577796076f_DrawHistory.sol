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
import "./interfaces/IDrawHistory.sol";
import "./libraries/DrawLib.sol";
import "./libraries/DrawRingBufferLib.sol";

/**
  * @title  PoolTogether V4 DrawHistory
  * @author PoolTogether Inc Team
  * @notice The DrawHistory keeps a historical record of Draws created/pushed by DrawBeacon(s).
            Once a DrawBeacon (on mainnet) completes a RNG request, a new Draw will be added
            to the DrawHistory draws ring buffer. A DrawHistory will store a limited number
            of Draws before beginning to overwrite (managed via the cardinality) previous Draws.
            All mainnet DrawHistory(s) are updated directly from a DrawBeacon, but non-mainnet
            DrawHistory(s) (Matic, Optimism, Arbitrum, etc...) will receive a cross-chain message,
            duplicating the mainnet Draw configuration - enabling a prize savings liquidity network.
*/
contract DrawHistory is IDrawHistory, Manageable {
  using DrawRingBufferLib for DrawRingBufferLib.Buffer;

  /// @notice Draws ring buffer max length.
  uint16 public constant MAX_CARDINALITY = 256;

  /// @notice Draws ring buffer array.
  DrawLib.Draw[MAX_CARDINALITY] private _draws;

  /// @notice Holds ring buffer information
  DrawRingBufferLib.Buffer internal drawRingBuffer;

  /* ============ Deploy ============ */

  /**
    * @notice Deploy DrawHistory smart contract.
    * @param _owner Address of the owner of the DrawHistory.
    * @param _cardinality Draw ring buffer cardinality.
  */
  constructor(
    address _owner,
    uint8 _cardinality
  ) Ownable(_owner) {
    drawRingBuffer.cardinality = _cardinality;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc IDrawHistory
  function getDraw(uint32 drawId) external view override returns(DrawLib.Draw memory) {
    return _draws[_drawIdToDrawIndex(drawRingBuffer, drawId)];
  }

  /// @inheritdoc IDrawHistory
  function getDraws(uint32[] calldata drawIds) external view override returns(DrawLib.Draw[] memory) {
    DrawLib.Draw[] memory draws = new DrawLib.Draw[](drawIds.length);
    DrawRingBufferLib.Buffer memory buffer = drawRingBuffer;
    for (uint256 index = 0; index < drawIds.length; index++) {
      draws[index] = _draws[_drawIdToDrawIndex(buffer, drawIds[index])];
    }
    return draws;
  }

  /// @inheritdoc IDrawHistory
  function getNewestDraw() external view override returns (DrawLib.Draw memory) {
    return _getNewestDraw(drawRingBuffer);
  }

  /// @inheritdoc IDrawHistory
  function getOldestDraw() external view override returns (DrawLib.Draw memory) {
    // oldest draw should be next available index, otherwise it's at 0
    DrawRingBufferLib.Buffer memory buffer = drawRingBuffer;
    DrawLib.Draw memory draw = _draws[buffer.nextIndex];
    if (draw.timestamp == 0) { // if draw is not init, then use draw at 0
      draw = _draws[0];
    }
    return draw;
  }

  /// @inheritdoc IDrawHistory
  function pushDraw(DrawLib.Draw memory _draw) external override onlyManagerOrOwner returns (uint32) {
    return _pushDraw(_draw);
  }

  /// @inheritdoc IDrawHistory
  function setDraw(DrawLib.Draw memory _newDraw) external override onlyOwner returns (uint32) {
    DrawRingBufferLib.Buffer memory buffer = drawRingBuffer;
    uint32 index = buffer.getIndex(_newDraw.drawId);
    _draws[index] = _newDraw;
    emit DrawSet(_newDraw.drawId, _newDraw);
    return _newDraw.drawId;
  }

  /* ============ Internal Functions ============ */

  /**
    * @notice Convert a Draw.drawId to a Draws ring buffer index pointer.
    * @dev    The getNewestDraw.drawId() is used to calculate a Draws ID delta position.
    * @param _drawId Draw.drawId
    * @return Draws ring buffer index pointer
  */
  function _drawIdToDrawIndex(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId) internal pure returns (uint32) {
    return _buffer.getIndex(_drawId);
  }

  /**
    * @notice Read newest Draw from the draws ring buffer.
    * @dev    Uses the lastDrawId to calculate the most recently added Draw.
    * @param _buffer Draw ring buffer
    * @return DrawLib.Draw
  */
  function _getNewestDraw(DrawRingBufferLib.Buffer memory _buffer) internal view returns (DrawLib.Draw memory) {
    return _draws[_buffer.getIndex(_buffer.lastDrawId)];
  }

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Push new draw onto draws list via authorized manager or owner.
    * @param _newDraw DrawLib.Draw
    * @return Draw.drawId
  */
  function _pushDraw(DrawLib.Draw memory _newDraw) internal returns (uint32) {
    DrawRingBufferLib.Buffer memory _buffer = drawRingBuffer;
    _draws[_buffer.nextIndex] = _newDraw;
    drawRingBuffer = _buffer.push(_newDraw.drawId);
    emit DrawSet(_newDraw.drawId, _newDraw);
    return _newDraw.drawId;
  }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "../libraries/DrawLib.sol";

interface IDrawHistory {

  /**
    * @notice Emit when a new draw has been created.
    * @param drawId Draw id
    * @param draw The Draw struct
  */
  event DrawSet (
    uint32 indexed drawId,
    DrawLib.Draw draw
  );

  /**
    * @notice Read a Draw from the draws ring buffer.
    * @dev    Read a Draw using the Draw.drawId to calculate position in the draws ring buffer.
    * @param drawId Draw.drawId
    * @return DrawLib.Draw
  */
  function getDraw(uint32 drawId) external view returns (DrawLib.Draw memory);

  /**
    * @notice Read multiple Draws from the draws ring buffer.
    * @dev    Read multiple Draws using each Draw.drawId to calculate position in the draws ring buffer.
    * @param drawIds Array of Draw.drawIds
    * @return DrawLib.Draw[]
  */
  function getDraws(uint32[] calldata drawIds) external view returns (DrawLib.Draw[] memory);
  /**
    * @notice Read newest Draw from the draws ring buffer.
    * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
    * @return DrawLib.Draw
  */
  function getNewestDraw() external view returns (DrawLib.Draw memory);
  /**
    * @notice Read oldest Draw from the draws ring buffer.
    * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with the cardinality.
    * @return DrawLib.Draw
  */
  function getOldestDraw() external view returns (DrawLib.Draw memory);

  /**
    * @notice Push Draw onto draws ring buffer history.
    * @dev    Push new draw onto draws history via authorized manager or owner.
    * @param draw DrawLib.Draw
    * @return Draw.drawId
  */
  function pushDraw(DrawLib.Draw calldata draw) external returns(uint32);

  /**
    * @notice Set existing Draw in draws ring buffer with new parameters.
    * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
    * @param newDraw DrawLib.Draw
    * @return Draw.drawId
  */
  function setDraw(DrawLib.Draw calldata newDraw) external returns(uint32);
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

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}