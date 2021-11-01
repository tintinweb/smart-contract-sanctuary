// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@paulrberg/contracts/math/PRBMath.sol';

import './interfaces/IJBFundingCycleStore.sol';
import './abstract/JBControllerUtility.sol';

/** 
  @notice 
  Manages funding cycle configurations, accounting, and scheduling.
*/
contract JBFundingCycleStore is JBControllerUtility, IJBFundingCycleStore {
  //*********************************************************************//
  // --------------------- private stored constants -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The number of seconds in a day.
  */
  uint256 private constant _SECONDS_IN_DAY = 86400;

  //*********************************************************************//
  // --------------------- private stored properties ------------------- //
  //*********************************************************************//

  /** 
    @notice
    Stores the reconfiguration properties of each funding cycle, packed into one storage slot.

    _projectId The ID of the project to get configuration properties of.
  */
  mapping(uint256 => uint256) private _packedConfigurationPropertiesOf;

  /** 
    @notice
    Stores the properties added by the mechanism to manage and schedule each funding cycle, packed into one storage slot.
    
    _projectId The ID of the project to get instrinsic properties of.
  */
  mapping(uint256 => uint256) private _packedIntrinsicPropertiesOf;

  /** 
    @notice
    Stores the metadata for each funding cycle, packed into one storage slot.

    _projectId The ID of the project to get the`_metadataOf`.
  */
  mapping(uint256 => uint256) private _metadataOf;

  /** 
    @notice
    Stores the amount that each funding cycle can tap funding cycle.

    _projectId The ID of the project to get the target of.
  */
  mapping(uint256 => uint256) private _targetOf;

  /** 
    @notice
    Stores the amount that has been tapped within each funding cycle.

    _projectId The ID of the project to get the tapped amount of.
  */
  mapping(uint256 => uint256) private _tappedAmountOf;

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /** 
    @notice 
    The ID of the latest funding cycle for each project.

    _projectId The ID of the project to get the latest funding cycle ID of.
  */
  mapping(uint256 => uint256) public override latestIdOf;

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
    @notice 
    Get the funding cycle with the given ID.

    @param _fundingCycleId The ID of the funding cycle to get.

    @return fundingCycle The funding cycle.
  */
  function get(uint256 _fundingCycleId)
    external
    view
    override
    returns (JBFundingCycle memory fundingCycle)
  {
    // The funding cycle should exist.
    require(_fundingCycleId > 0, '0x13 BAD_ID');

    // See if there's stored info for the provided ID.
    fundingCycle = _getStructFor(_fundingCycleId);

    // If so, return it.
    if (fundingCycle.number > 0) return fundingCycle;

    // Get the current funding cycle. It might exist but not yet have been stored.
    fundingCycle = currentOf(_fundingCycleId);

    // If the IDs match, return it.
    if (fundingCycle.id == _fundingCycleId) return fundingCycle;

    // Get the queued funding cycle. It might exist but not yet have been stored.
    fundingCycle = queuedOf(_fundingCycleId);

    // If the IDs match, return it.
    if (fundingCycle.id == _fundingCycleId) return fundingCycle;

    // Return an empty Funding Cycle.
    return _getStructFor(0);
  }

  /**
    @notice 
    The funding cycle that's next up for the specified project.

    @dev
    Returns an empty funding cycle with an ID of 0 if a queued funding cycle of the project is not found.

    @dev 
    This runs roughly similar logic to `_configurableOf`.

    @param _projectId The ID of the project to get the queued funding cycle of.

    @return _fundingCycle The queued funding cycle.
  */
  function queuedOf(uint256 _projectId) public view override returns (JBFundingCycle memory) {
    // The project must have funding cycles.
    if (latestIdOf[_projectId] == 0) return _getStructFor(0);

    // Get a reference to the standby funding cycle.
    uint256 _fundingCycleId = _standbyOf(_projectId);

    // If it exists, return it.
    if (_fundingCycleId > 0) return _getStructFor(_fundingCycleId);

    // Get a reference to the latest stored funding cycle for the project.
    _fundingCycleId = latestIdOf[_projectId];

    // Get the necessary properties for the standby funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(_fundingCycleId);

    // There's no queued if the current has a duration of 0.
    if (_fundingCycle.duration == 0) return _getStructFor(0);

    // Check to see if the correct ballot is approved for this funding cycle.
    // If so, return a funding cycle based on it.
    if (_isApproved(_fundingCycle)) return _mockFundingCycleBasedOn(_fundingCycle, false);

    // If it hasn't been approved, set the ID to be its base funding cycle, which carries the last approved configuration.
    _fundingCycleId = _fundingCycle.basedOn;

    // A funding cycle must exist.
    if (_fundingCycleId == 0) return _getStructFor(0);

    // Return a mock of what its second next up funding cycle would be.
    // Use second next because the next would be a mock of the current funding cycle.
    return _mockFundingCycleBasedOn(_getStructFor(_fundingCycleId), false);
  }

  /**
    @notice 
    The funding cycle that is currently active for the specified project.

    @dev
    Returns an empty funding cycle with an ID of 0 if a current funding cycle of the project is not found.

    @dev 
    This runs very similar logic to `_tappableOf`.

    @param _projectId The ID of the project to get the current funding cycle of.

    @return fundingCycle The current funding cycle.
  */
  function currentOf(uint256 _projectId)
    public
    view
    override
    returns (JBFundingCycle memory fundingCycle)
  {
    // The project must have funding cycles.
    if (latestIdOf[_projectId] == 0) return _getStructFor(0);

    // Check for an eligible funding cycle.
    uint256 _fundingCycleId = _eligibleOf(_projectId);

    // If no active funding cycle is found, check if there is a standby funding cycle.
    // If one exists, it will become active one it has been tapped.
    if (_fundingCycleId == 0) _fundingCycleId = _standbyOf(_projectId);

    // Keep a reference to the eligible funding cycle.
    JBFundingCycle memory _fundingCycle;

    // If a standby funding cycle exists...
    if (_fundingCycleId > 0) {
      // Get the necessary properties for the standby funding cycle.
      _fundingCycle = _getStructFor(_fundingCycleId);

      // Check to see if the correct ballot is approved for this funding cycle, and that it has started.
      if (_fundingCycle.start <= block.timestamp && _isApproved(_fundingCycle))
        return _fundingCycle;

      // If it hasn't been approved, set the ID to be the based funding cycle,
      // which carries the last approved configuration.
      _fundingCycleId = _fundingCycle.basedOn;
    } else {
      // No upcoming funding cycle found that is eligible to become active,
      // so us the ID of the latest active funding cycle, which carries the last configuration.
      _fundingCycleId = latestIdOf[_projectId];

      // Get the funding cycle for the latest ID.
      _fundingCycle = _getStructFor(_fundingCycleId);

      // If it's not approved, get a reference to the funding cycle that the latest is based on, which has the latest approved configuration.
      if (!_isApproved(_fundingCycle)) _fundingCycleId = _fundingCycle.basedOn;
    }

    // The funding cycle cant be 0.
    if (_fundingCycleId == 0) return _getStructFor(0);

    // The funding cycle to base a current one on.
    _fundingCycle = _getStructFor(_fundingCycleId);

    // Return a mock of what the next funding cycle would be like,
    // which would become active once it has been tapped.
    return _mockFundingCycleBasedOn(_fundingCycle, true);
  }

  /** 
    @notice 
    The currency ballot state of the project.

    @param _projectId The ID of the project to check the ballot state of.

    @return The current ballot's state.
  */
  function currentBallotStateOf(uint256 _projectId) external view override returns (JBBallotState) {
    // Get a reference to the latest funding cycle ID.
    uint256 _fundingCycleId = latestIdOf[_projectId];

    // The project must have funding cycles.
    require(_fundingCycleId > 0, '0x14: NOT_FOUND');

    // Get the necessary properties for the latest funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(_fundingCycleId);

    // If the latest funding cycle is the first, or if it has already started, it must be approved.
    if (_fundingCycle.basedOn == 0) return JBBallotState.Approved;

    return _ballotStateOf(_fundingCycleId, _fundingCycle.configured, _fundingCycle.basedOn);
  }

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(IJBDirectory _directory) JBControllerUtility(_directory) {}

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
    @notice 
    Configures the next eligible funding cycle for the specified project.

    @dev
    Only a project's current controller can configure its funding cycles.

    @param _projectId The ID of the project being configured.
    @param _data The funding cycle configuration.
      @dev _data.target The amount that the project wants to receive in each funding cycle. 18 decimals.
      @dev _data.currency The currency of the `_target`. Send 0 for ETH or 1 for USD.
      @dev _data.duration The duration of the funding cycle for which the `_target` amount is needed. Measured in days. 
        Set to 0 for no expiry and to be able to reconfigure anytime.
      @dev _data.discountRate A number from 0-10000 indicating how valuable a contribution to this funding cycle is compared to previous funding cycles.
        If it's 0, each funding cycle will have equal weight.
        If the number is 9000, a contribution to the next funding cycle will only give you 10% of tickets given to a contribution of the same amoutn during the current funding cycle.
        If the number is 10001, an non-recurring funding cycle will get made.
      @dev _data.ballot The new ballot that will be used to approve subsequent reconfigurations.
    @param _metadata Data to associate with this funding cycle configuration.
    @param _fee The fee that this configuration incurs when tapping.

    @return The funding cycle that the configuration will take effect during.
  */
  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _fee
  ) external override onlyController(_projectId) returns (JBFundingCycle memory) {
    // Duration must fit in a uint16.
    require(_data.duration <= type(uint16).max, '0x15: BAD_DURATION');

    // Discount rate token must be less than or equal to 100%. A value of 10001 means non-recurring.
    require(_data.discountRate <= 10001, '0x16: BAD_DISCOUNT_RATE');

    // Currency must fit into a uint8.
    require(_data.currency <= type(uint8).max, '0x17: BAD_CURRENCY');

    // Weight must fit into a uint8.
    require(_data.weight <= type(uint80).max, '0x18: BAD_WEIGHT');

    // Fee must be less than or equal to 100%.
    require(_fee <= 200, '0x19: BAD_FEE');

    // Set the configuration timestamp is now.
    uint256 _configured = block.timestamp;

    // Gets the ID of the funding cycle to reconfigure.
    uint256 _fundingCycleId = _configurableOf(_projectId, _configured, _data.weight);

    // Store the configuration.
    _packAndStoreConfigurationPropertiesOf(
      _fundingCycleId,
      _configured,
      _data.ballot,
      _data.duration,
      _data.currency,
      _fee,
      _data.discountRate
    );

    // Set the target amount.
    _targetOf[_fundingCycleId] = _data.target;

    // Set the metadata.
    _metadataOf[_fundingCycleId] = _metadata;

    emit Configure(_fundingCycleId, _projectId, _configured, _data, _metadata, msg.sender);

    return _getStructFor(_fundingCycleId);
  }

  /** 
    @notice 
    Tap funds from a project's currently tappable funding cycle.

    @dev
    Only a project's current controller can tap funds for its funding cycles.

    @param _projectId The ID of the project being tapped.
    @param _amount The amount being tapped.

    @return The tapped funding cycle.
  */
  function tapFrom(uint256 _projectId, uint256 _amount)
    external
    override
    onlyController(_projectId)
    returns (JBFundingCycle memory)
  {
    // Amount must be positive.
    require(_amount > 0, '0x1a: INSUFFICIENT_FUNDS');

    // Get a reference to the funding cycle being tapped.
    uint256 _fundingCycleId = _tappableOf(_projectId);

    // The new amount that has been tapped.
    uint256 _newTappedAmount = _tappedAmountOf[_fundingCycleId] + _amount;

    // Amount must be within what is still tappable.
    require(_newTappedAmount <= _targetOf[_fundingCycleId], '0x1b: INSUFFICIENT_FUNDS');

    // Store the new amount.
    _tappedAmountOf[_fundingCycleId] = _newTappedAmount;

    emit Tap(_fundingCycleId, _projectId, _amount, _newTappedAmount, msg.sender);

    return _getStructFor(_fundingCycleId);
  }

  //*********************************************************************//
  // --------------------- private helper functions -------------------- //
  //*********************************************************************//

  /**
    @notice 
    Returns the configurable funding cycle for this project if it exists, otherwise creates one.

    @param _projectId The ID of the project to find a configurable funding cycle for.
    @param _configured The time at which the configuration is occurring.
    @param _weight The weight to store along with a newly created configurable funding cycle.

    @return fundingCycleId The ID of the configurable funding cycle.
  */
  function _configurableOf(
    uint256 _projectId,
    uint256 _configured,
    uint256 _weight
  ) private returns (uint256 fundingCycleId) {
    // If there's not yet a funding cycle for the project, return the ID of a newly created one.
    if (latestIdOf[_projectId] == 0)
      return _initFor(_projectId, _getStructFor(0), block.timestamp, _weight);

    // Get the standby funding cycle's ID.
    fundingCycleId = _standbyOf(_projectId);

    // If it exists, make sure its updated, then return it.
    if (fundingCycleId > 0) {
      // Get the funding cycle that the specified one is based on.
      JBFundingCycle memory _baseFundingCycle = _getStructFor(
        _getStructFor(fundingCycleId).basedOn
      );

      // The base's ballot must have ended.
      _updateFundingCycleBasedOn(
        _baseFundingCycle,
        _getLatestTimeAfterBallotOf(_baseFundingCycle, _configured),
        _weight
      );
      return fundingCycleId;
    }

    // Get the active funding cycle's ID.
    fundingCycleId = _eligibleOf(_projectId);

    // If the ID of an eligible funding cycle exists, it's approved, and active funding cycles are configurable, return it.
    if (fundingCycleId > 0) {
      if (!_isIdApproved(fundingCycleId)) {
        // If it hasn't been approved, set the ID to be the based funding cycle,
        // which carries the last approved configuration.
        fundingCycleId = _getStructFor(fundingCycleId).basedOn;
      }
    } else {
      // Get the ID of the latest funding cycle which has the latest reconfiguration.
      fundingCycleId = latestIdOf[_projectId];

      // If it hasn't been approved, set the ID to be the based funding cycle,
      // which carries the last approved configuration.
      if (!_isIdApproved(fundingCycleId)) fundingCycleId = _getStructFor(fundingCycleId).basedOn;
    }

    // Base off of the active funding cycle if it exists.
    JBFundingCycle memory _fundingCycle = _getStructFor(fundingCycleId);

    // Make sure the funding cycle is recurring.
    require(_fundingCycle.discountRate < 10001, '0x1c: NON_RECURRING');

    // Determine if the configurable funding cycle can only take effect on or after a certain date.
    uint256 _mustStartOnOrAfter;

    // The ballot must have ended.
    _mustStartOnOrAfter = _getLatestTimeAfterBallotOf(_fundingCycle, _configured);

    // Return the newly initialized configurable funding cycle.
    // No need to copy since a new configuration is going to be applied.
    fundingCycleId = _initFor(_projectId, _fundingCycle, _mustStartOnOrAfter, _weight);
  }

  /**
    @notice 
    Returns the funding cycle that can be tapped at the time of the call.

    @param _projectId The ID of the project to find a tappable funding cycle for.

    @return fundingCycleId The ID of the tappable funding cycle.
  */
  function _tappableOf(uint256 _projectId) private returns (uint256 fundingCycleId) {
    // Check for the ID of an eligible funding cycle.
    fundingCycleId = _eligibleOf(_projectId);

    // No eligible funding cycle found, check for the ID of a standby funding cycle.
    // If this one exists, it will become eligible one it has started.
    if (fundingCycleId == 0) fundingCycleId = _standbyOf(_projectId);

    // Keep a reference to the funding cycle eligible for being tappable.
    JBFundingCycle memory _fundingCycle;

    // If the ID of an eligible funding cycle exists,
    // check to see if it has been approved by the based funding cycle's ballot.
    if (fundingCycleId > 0) {
      // Get the necessary properties for the funding cycle.
      _fundingCycle = _getStructFor(fundingCycleId);

      // Check to see if the cycle is approved. If so, return it.
      if (_fundingCycle.start <= block.timestamp && _isApproved(_fundingCycle))
        return fundingCycleId;

      // If it hasn't been approved, set the ID to be the base funding cycle,
      // which carries the last approved configuration.
      fundingCycleId = _fundingCycle.basedOn;
    } else {
      // No upcoming funding cycle found that is eligible to become active, clone the latest active funding cycle.
      // which carries the last configuration.
      fundingCycleId = latestIdOf[_projectId];

      // Get the funding cycle for the latest ID.
      _fundingCycle = _getStructFor(fundingCycleId);

      // If it's not approved, get a reference to the funding cycle that the latest is based on, which has the latest approved configuration.
      if (!_isApproved(_fundingCycle)) fundingCycleId = _fundingCycle.basedOn;
    }

    // The funding cycle cant be 0.
    require(fundingCycleId > 0, '0x1d: NOT_FOUND');

    // Set the eligible funding cycle.
    _fundingCycle = _getStructFor(fundingCycleId);

    // Funding cycles with a discount rate of 100% are non-recurring.
    require(_fundingCycle.discountRate < 10001, '0x1e: NON_RECURRING');

    // The time when the funding cycle immediately after the eligible funding cycle starts.
    uint256 _nextImmediateStart = _fundingCycle.start + (_fundingCycle.duration * _SECONDS_IN_DAY);

    // The distance from now until the nearest past multiple of the cycle duration from its start.
    // A duration of zero means the reconfiguration can start right away.
    uint256 _timeFromImmediateStartMultiple = _fundingCycle.duration == 0
      ? 0
      : (block.timestamp - _nextImmediateStart) % (_fundingCycle.duration * _SECONDS_IN_DAY);

    // Return the tappable funding cycle.
    fundingCycleId = _initFor(
      _projectId,
      _fundingCycle,
      block.timestamp - _timeFromImmediateStartMultiple,
      0
    );

    // Copy the properties of the base funding cycle onto the new configuration efficiently.
    _packAndStoreConfigurationPropertiesOf(
      fundingCycleId,
      _fundingCycle.configured,
      _fundingCycle.ballot,
      _fundingCycle.duration,
      _fundingCycle.currency,
      _fundingCycle.fee,
      _fundingCycle.discountRate
    );

    _metadataOf[fundingCycleId] = _metadataOf[_fundingCycle.id];
    _targetOf[fundingCycleId] = _targetOf[_fundingCycle.id];
  }

  /**
    @notice 
    Initializes a funding cycle with the appropriate properties.

    @param _projectId The ID of the project to which the funding cycle being initialized belongs.
    @param _baseFundingCycle The funding cycle to base the initialized one on.
    @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.

    @return newFundingCycleId The ID of the initialized funding cycle.
  */
  function _initFor(
    uint256 _projectId,
    JBFundingCycle memory _baseFundingCycle,
    uint256 _mustStartOnOrAfter,
    uint256 _weight
  ) private returns (uint256 newFundingCycleId) {
    // If there is no base, initialize a first cycle.
    if (_baseFundingCycle.id == 0) {
      // The first number is 1.
      uint256 _number = 1;

      // Get the formatted ID.
      newFundingCycleId = _idFor(_projectId, _number);

      // Set fresh intrinsic properties.
      _packAndStoreIntrinsicPropertiesOf(
        _projectId,
        _number,
        _weight,
        _baseFundingCycle.id,
        block.timestamp
      );
    } else {
      // Update the intrinsic properties of the funding cycle being initialized.
      newFundingCycleId = _updateFundingCycleBasedOn(
        _baseFundingCycle,
        _mustStartOnOrAfter,
        _weight
      );
    }

    // Set the project's latest funding cycle ID to the new count.
    latestIdOf[_projectId] = newFundingCycleId;

    emit Init(newFundingCycleId, _projectId, _baseFundingCycle.id);
  }

  /** 
    @notice
    Updates intrinsic properties for a funding cycle given a base cycle.

    @param _baseFundingCycle The cycle that the one being updated is based on.
    @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.
    @param _weight The weight to store along with a newly updated configurable funding cycle.

    @return fundingCycleId The ID of the funding cycle that was updated.
  */
  function _updateFundingCycleBasedOn(
    JBFundingCycle memory _baseFundingCycle,
    uint256 _mustStartOnOrAfter,
    uint256 _weight
  ) private returns (uint256 fundingCycleId) {
    // Derive the correct next start time from the base.
    uint256 _start = _deriveStartFrom(_baseFundingCycle, _mustStartOnOrAfter);

    // A weight of 1 is treated as a weight of 0.
    _weight = _weight > 0
      ? (_weight == 1 ? 0 : _weight)
      : _deriveWeightFrom(_baseFundingCycle, _start);

    // Derive the correct number.
    uint256 _number = _deriveNumberFrom(_baseFundingCycle, _start);

    // Update the intrinsic properties.
    fundingCycleId = _packAndStoreIntrinsicPropertiesOf(
      _baseFundingCycle.projectId,
      _number,
      _weight,
      _baseFundingCycle.id,
      _start
    );
  }

  /**
    @notice 
    Efficiently stores a funding cycle's provided intrinsic properties.

    @param _projectId The ID of the project to which the funding cycle belongs.
    @param _number The number of the funding cycle.
    @param _weight The weight of the funding cycle.
    @param _basedOn The ID of the based funding cycle.
    @param _start The start time of this funding cycle.

    @return fundingCycleId The ID of the funding cycle that was updated.
  */
  function _packAndStoreIntrinsicPropertiesOf(
    uint256 _projectId,
    uint256 _number,
    uint256 _weight,
    uint256 _basedOn,
    uint256 _start
  ) private returns (uint256 fundingCycleId) {
    // weight in bytes 0-79 bytes.
    uint256 packed = _weight;
    // projectId in bytes 80-135 bytes.
    packed |= _projectId << 80;
    // basedOn in bytes 136-183 bytes.
    packed |= _basedOn << 136;
    // start in bytes 184-231 bytes.
    packed |= _start << 184;
    // number in bytes 232-255 bytes.
    packed |= _number << 232;

    // Construct the ID.
    fundingCycleId = _idFor(_projectId, _number);

    // Set in storage.
    _packedIntrinsicPropertiesOf[fundingCycleId] = packed;
  }

  /**
    @notice 
    Efficiently stores a funding cycles provided configuration properties.

    @param _fundingCycleId The ID of the funding cycle to pack and store.
    @param _configured The timestamp of the configuration.
    @param _ballot The ballot to use for future reconfiguration approvals. 
    @param _duration The duration of the funding cycle.
    @param _currency The currency of the funding cycle.
    @param _fee The fee of the funding cycle.
    @param _discountRate The discount rate of the base funding cycle.
  */
  function _packAndStoreConfigurationPropertiesOf(
    uint256 _fundingCycleId,
    uint256 _configured,
    IJBFundingCycleBallot _ballot,
    uint256 _duration,
    uint256 _currency,
    uint256 _fee,
    uint256 _discountRate
  ) private {
    // ballot in bytes 0-159 bytes.
    uint256 packed = uint160(address(_ballot));
    // configured in bytes 160-207 bytes.
    packed |= _configured << 160;
    // duration in bytes 208-223 bytes.
    packed |= _duration << 208;
    // basedOn in bytes 224-231 bytes.
    packed |= _currency << 224;
    // fee in bytes 232-239 bytes.
    packed |= _fee << 232;
    // discountRate in bytes 240-255 bytes.
    packed |= _discountRate << 240;

    // Set in storage.
    _packedConfigurationPropertiesOf[_fundingCycleId] = packed;
  }

  /**
    @notice 
    The project's stored funding cycle that hasn't yet started, if one exists.

    @dev
    A value of 0 is returned if no funding cycle was found.
    
    @param _projectId The ID of a project to look through for a standby cycle.

    @return fundingCycleId The ID of the standby funding cycle.
  */
  function _standbyOf(uint256 _projectId) private view returns (uint256 fundingCycleId) {
    // Get a reference to the project's latest funding cycle.
    fundingCycleId = latestIdOf[_projectId];

    // If there isn't one, theres also no standby funding cycle.
    if (fundingCycleId == 0) return 0;

    // Get the necessary properties for the latest funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(fundingCycleId);

    // There is no upcoming funding cycle if the latest funding cycle has already started.
    if (block.timestamp >= _fundingCycle.start) return 0;
  }

  /**
    @notice 
    The project's stored funding cycle that has started and hasn't yet expired.
    
    @dev
    A value of 0 is returned if no funding cycle was found.

    @param _projectId The ID of the project to look through.

    @return fundingCycleId The ID of the active funding cycle.
  */
  function _eligibleOf(uint256 _projectId) private view returns (uint256 fundingCycleId) {
    // Get a reference to the project's latest funding cycle.
    fundingCycleId = latestIdOf[_projectId];

    // If there isn't one, theres also no eligible funding cycle.
    if (fundingCycleId == 0) return 0;

    // Get the necessary properties for the latest funding cycle.
    JBFundingCycle memory _fundingCycle = _getStructFor(fundingCycleId);

    // If the latest is expired, return an empty funding cycle.
    // A duration of 0 can not be expired.
    if (
      _fundingCycle.duration > 0 &&
      block.timestamp >= _fundingCycle.start + (_fundingCycle.duration * _SECONDS_IN_DAY)
    ) return 0;

    // The base cant be expired.
    JBFundingCycle memory _baseFundingCycle = _getStructFor(_fundingCycle.basedOn);

    // If the current time is past the end of the base, return 0.
    // A duration of 0 is always eligible.
    if (
      _baseFundingCycle.duration > 0 &&
      block.timestamp >= _baseFundingCycle.start + (_baseFundingCycle.duration * _SECONDS_IN_DAY)
    ) return 0;

    // Return the funding cycle immediately before the latest.
    fundingCycleId = _fundingCycle.basedOn;
  }

  /** 
    @notice 
    A view of the funding cycle that would be created based on the provided one if the project doesn't make a reconfiguration.

    @dev
    Returns an empty funding cycle if there can't be a mock funding cycle based on the provided one.

    @param _baseFundingCycle The funding cycle that the resulting funding cycle should follow.
    @param _allowMidCycle A flag indicating if the mocked funding cycle is allowed to already be mid cycle.

    @return A mock of what the next funding cycle will be.
  */
  function _mockFundingCycleBasedOn(JBFundingCycle memory _baseFundingCycle, bool _allowMidCycle)
    private
    view
    returns (JBFundingCycle memory)
  {
    // Can't mock a non recurring funding cycle.
    if (_baseFundingCycle.discountRate == 10001) return _getStructFor(0);

    // The distance of the current time to the start of the next possible funding cycle.
    // If the returned mock cycle must not yet have started, the start time of the mock must be in the future so no need to adjust backwards.
    // If the base funding cycle doesn't have a duration, no adjustment is necessary because the next cycle can start immediately.
    uint256 _timeFromImmediateStartMultiple = !_allowMidCycle || _baseFundingCycle.duration == 0
      ? 0
      : _baseFundingCycle.duration * _SECONDS_IN_DAY;

    // Derive what the start time should be.
    uint256 _start = _deriveStartFrom(
      _baseFundingCycle,
      block.timestamp - _timeFromImmediateStartMultiple
    );

    // Derive what the number should be.
    uint256 _number = _deriveNumberFrom(_baseFundingCycle, _start);

    return
      JBFundingCycle(
        _idFor(_baseFundingCycle.projectId, _number),
        _baseFundingCycle.projectId,
        _number,
        _baseFundingCycle.id,
        _baseFundingCycle.configured,
        _deriveWeightFrom(_baseFundingCycle, _start),
        _baseFundingCycle.ballot,
        _start,
        _baseFundingCycle.duration,
        _baseFundingCycle.target,
        _baseFundingCycle.currency,
        _baseFundingCycle.fee,
        _baseFundingCycle.discountRate,
        0,
        _baseFundingCycle.metadata
      );
  }

  /**
    @notice 
    Unpack a funding cycle's packed stored values into an easy-to-work-with funding cycle struct.

    @param _id The funding cycle ID to get the full struct for.

    @return fundingCycle The funding cycle struct.
  */
  function _getStructFor(uint256 _id) private view returns (JBFundingCycle memory fundingCycle) {
    // Return an empty funding cycle if the ID specified is 0.
    if (_id == 0) return fundingCycle;

    fundingCycle.id = _id;

    uint256 _packedIntrinsicProperties = _packedIntrinsicPropertiesOf[_id];

    fundingCycle.weight = uint256(uint80(_packedIntrinsicProperties));
    fundingCycle.projectId = uint256(uint56(_packedIntrinsicProperties >> 80));
    fundingCycle.basedOn = uint256(uint48(_packedIntrinsicProperties >> 136));
    fundingCycle.start = uint256(uint48(_packedIntrinsicProperties >> 184));
    fundingCycle.number = uint256(uint24(_packedIntrinsicProperties >> 232));

    uint256 _packedConfigurationProperties = _packedConfigurationPropertiesOf[_id];

    fundingCycle.ballot = IJBFundingCycleBallot(address(uint160(_packedConfigurationProperties)));
    fundingCycle.configured = uint256(uint48(_packedConfigurationProperties >> 160));
    fundingCycle.duration = uint256(uint16(_packedConfigurationProperties >> 208));
    fundingCycle.currency = uint256(uint8(_packedConfigurationProperties >> 224));
    fundingCycle.fee = uint256(uint8(_packedConfigurationProperties >> 232));
    fundingCycle.discountRate = uint256(uint16(_packedConfigurationProperties >> 240));

    fundingCycle.target = _targetOf[_id];
    fundingCycle.tapped = _tappedAmountOf[_id];
    fundingCycle.metadata = _metadataOf[_id];
  }

  /** 
    @notice 
    The date that is the nearest multiple of the specified funding cycle's duration from its end.

    @param _baseFundingCycle The funding cycle to make the calculation for.
    @param _mustStartOnOrAfter A date that the derived start must be on or come after.

    @return start The next start time.
  */
  function _deriveStartFrom(JBFundingCycle memory _baseFundingCycle, uint256 _mustStartOnOrAfter)
    private
    pure
    returns (uint256 start)
  {
    // A subsequent cycle to one with a duration of 0 should start as soon as possible.
    if (_baseFundingCycle.duration == 0) return _mustStartOnOrAfter;

    // Save a reference to the cycle's duration measured in seconds.
    uint256 _cycleDurationInSeconds = _baseFundingCycle.duration * _SECONDS_IN_DAY;

    // The time when the funding cycle immediately after the specified funding cycle starts.
    uint256 _nextImmediateStart = _baseFundingCycle.start + _cycleDurationInSeconds;

    // If the next immediate start is now or in the future, return it.
    if (_nextImmediateStart >= _mustStartOnOrAfter) return _nextImmediateStart;

    // The amount of seconds since the `_mustStartOnOrAfter` time that results in a start time that might satisfy the specified constraints.
    uint256 _timeFromImmediateStartMultiple = (_mustStartOnOrAfter - _nextImmediateStart) %
      _cycleDurationInSeconds;

    // A reference to the first possible start timestamp.
    start = _mustStartOnOrAfter - _timeFromImmediateStartMultiple;

    // Add increments of duration as necessary to satisfy the threshold.
    while (_mustStartOnOrAfter > start) start = start + _cycleDurationInSeconds;
  }

  /** 
    @notice 
    The accumulated weight change since the specified funding cycle.

    @param _baseFundingCycle The funding cycle to make the calculation with.
    @param _start The start time to derive a weight for.

    @return weight The next weight.
  */
  function _deriveWeightFrom(JBFundingCycle memory _baseFundingCycle, uint256 _start)
    private
    pure
    returns (uint256 weight)
  {
    // A subsequent cycle to one with a duration of 0 should have the next possible weight.
    if (_baseFundingCycle.duration == 0)
      return
        PRBMath.mulDiv(_baseFundingCycle.weight, 10000 - _baseFundingCycle.discountRate, 10000);

    // The weight should be based off the base funding cycle's weight.
    weight = _baseFundingCycle.weight;

    // If the discount is 0, the weight doesn't change.
    if (_baseFundingCycle.discountRate == 0) return weight;

    // The difference between the start of the base funding cycle and the proposed start.
    uint256 _startDistance = _start - _baseFundingCycle.start;

    // Apply the base funding cycle's discount rate for each cycle that has passed.
    uint256 _discountMultiple = _startDistance / (_baseFundingCycle.duration * _SECONDS_IN_DAY);

    for (uint256 i = 0; i < _discountMultiple; i++)
      // The number of times to apply the discount rate.
      // Base the new weight on the specified funding cycle's weight.
      weight = PRBMath.mulDiv(weight, 10000 - _baseFundingCycle.discountRate, 10000);
  }

  /** 
    @notice 
    The number of the next funding cycle given the specified funding cycle.

    @param _baseFundingCycle The funding cycle to make the calculation with.
    @param _start The start time to derive a number for.

    @return The next number.
  */
  function _deriveNumberFrom(JBFundingCycle memory _baseFundingCycle, uint256 _start)
    private
    pure
    returns (uint256)
  {
    // A subsequent cycle to one with a duration of 0 should be the next number.
    if (_baseFundingCycle.duration == 0) return _baseFundingCycle.number + 1;

    // The difference between the start of the base funding cycle and the proposed start.
    uint256 _startDistance = _start - _baseFundingCycle.start;

    // Find the number of base cycles that fit in the start distance.
    return
      _baseFundingCycle.number + (_startDistance / (_baseFundingCycle.duration * _SECONDS_IN_DAY));
  }

  /** 
    @notice 
    Checks to see if the funding cycle of the provided ID is approved according to the correct ballot.

    @param _fundingCycleId The ID of the funding cycle to get an approval flag for.

    @return The approval flag.
  */
  function _isIdApproved(uint256 _fundingCycleId) private view returns (bool) {
    JBFundingCycle memory _fundingCycle = _getStructFor(_fundingCycleId);
    return _isApproved(_fundingCycle);
  }

  /** 
    @notice 
    Checks to see if the provided funding cycle is approved according to the correct ballot.

    @param _fundingCycle The ID of the funding cycle to get an approval flag for.

    @return The approval flag.
  */
  function _isApproved(JBFundingCycle memory _fundingCycle) private view returns (bool) {
    return
      _ballotStateOf(_fundingCycle.id, _fundingCycle.configured, _fundingCycle.basedOn) ==
      JBBallotState.Approved;
  }

  /**
    @notice 
    A funding cycle configuration's current status.

    @param _id The ID of the funding cycle configuration to check the status of.
    @param _configuration This differentiates reconfigurations onto the same upcoming funding cycle, which all would have the same ID but different configuration times.
    @param _ballotFundingCycleId The ID of the funding cycle which is configured with the ballot that should be used.

    @return The funding cycle's configuration status.
  */
  function _ballotStateOf(
    uint256 _id,
    uint256 _configuration,
    uint256 _ballotFundingCycleId
  ) private view returns (JBBallotState) {
    // If there is no ballot funding cycle, implicitly approve.
    if (_ballotFundingCycleId == 0) return JBBallotState.Approved;

    // Get the ballot funding cycle.
    JBFundingCycle memory _ballotFundingCycle = _getStructFor(_ballotFundingCycleId);

    // If the configuration is the same as the ballot's funding cycle,
    // the ballot isn't applicable. Auto approve since the ballot funding cycle is approved.
    if (_ballotFundingCycle.configured >= _configuration) return JBBallotState.Approved;

    // If there is no ballot, the ID is auto approved.
    // Otherwise, return the ballot's state.
    return
      _ballotFundingCycle.ballot == IJBFundingCycleBallot(address(0))
        ? JBBallotState.Approved
        : _ballotFundingCycle.ballot.state(_id, _configuration);
  }

  /** 
    @notice
    The time after the ballot of the provided funding cycle has expired.

    @dev
    If the ballot ends in the past, the current block timestamp will be returned.

    @param _fundingCycle The ID funding cycle to make the caluclation from.
    @param _from The time from which the ballot duration should be calculated.

    @return The time when the ballot has officially ended.
  */
  function _getLatestTimeAfterBallotOf(JBFundingCycle memory _fundingCycle, uint256 _from)
    private
    view
    returns (uint256)
  {
    // If the provided funding cycle has no ballot, return the current timestamp.
    if (_fundingCycle.ballot == IJBFundingCycleBallot(address(0))) return block.timestamp;

    // Get a reference to the time the ballot ends.
    uint256 _ballotExpiration = _from + _fundingCycle.ballot.duration();

    // If the ballot ends in past, return the current timestamp. Otherwise return the ballot's expiration.
    return block.timestamp > _ballotExpiration ? block.timestamp : _ballotExpiration;
  }

  /** 
    @notice 
    Constructs a unique ID from a project ID and a number.

    @param _projectId The ID of the project to use in the ID.
    @param _number The number to use in the ID

    @return The ID that is unique to the provided inputs.
  */
  function _idFor(uint256 _projectId, uint256 _number) private pure returns (uint256) {
    return uint256(uint56(_projectId) | uint24(_number));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBControllerUtility.sol';

/** 
  @notice
  Provides tools for contracts that has functionality that can only be accessed by a project's controller.
*/
abstract contract JBControllerUtility is IJBControllerUtility {
  modifier onlyController(uint256 _projectId) {
    require(address(directory.controllerOf(_projectId)) == msg.sender, '0x4f: UNAUTHORIZED');
    _;
  }

  /** 
    @notice 
    The directory of terminals and controllers for projects.
  */
  IJBDirectory public immutable override directory;

  /** 
    @param _directory A contract storing directories of terminals and controllers for each project.
  */
  constructor(IJBDirectory _directory) {
    directory = _directory;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

enum JBBallotState {
  Approved,
  Active,
  Failed,
  Standby
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBTerminal.sol';
import './IJBFundingCycleStore.sol';

interface IJBController {
  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function prepForMigrationOf(uint256 _projectId, IJBController _from) external;

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    uint256 _reserveRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function signalWithdrawlFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBTerminal _terminal
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';

interface IJBControllerUtility {
  function directory() external view returns (IJBDirectory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBTerminal.sol';
import './IJBProjects.sol';
import './IJBController.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, IJBController indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event RemoveTerminal(uint256 indexed projectId, IJBTerminal indexed terminal, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBTerminal indexed terminal,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function controllerOf(uint256 _projectId) external view returns (IJBController);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBTerminal);

  function terminalsOf(uint256 _projectId) external view returns (IJBTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBTerminal _terminal) external view returns (bool);

  function isTerminalDelegateOf(uint256 _projectId, address _delegate) external view returns (bool);

  function addTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function removeTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;

  function setControllerOf(uint256 _projectId, IJBController _controller) external;

  function setPrimaryTerminalOf(uint256 _projectId, IJBTerminal _terminal) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot {
  function duration() external view returns (uint256);

  function state(uint256 _fundingCycleId, uint256 _configured)
    external
    view
    returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBFundingCycleBallot.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 indexed configured,
    JBFundingCycleData data,
    uint256 metadata,
    address caller
  );

  event Tap(
    uint256 indexed fundingCycleId,
    uint256 indexed projectId,
    uint256 amount,
    uint256 newTappedAmount,
    address caller
  );

  event Init(uint256 indexed fundingCycleId, uint256 indexed projectId, uint256 indexed basedOn);

  function latestIdOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _fundingCycleId) external view returns (JBFundingCycle memory);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _fee
  ) external returns (JBFundingCycle memory fundingCycle);

  function tapFrom(uint256 _projectId, uint256 _amount)
    external
    returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBTerminal.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    bytes32 indexed handle,
    string uri,
    address caller
  );

  event SetHandle(uint256 indexed projectId, bytes32 indexed handle, address caller);

  event SetUri(uint256 indexed projectId, string uri, address caller);

  event TransferHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    bytes32 newHandle,
    address caller
  );

  event ClaimHandle(
    uint256 indexed projectId,
    address indexed transferAddress,
    bytes32 indexed handle,
    address caller
  );

  event ChallengeHandle(
    bytes32 indexed handle,
    uint256 indexed projectId,
    uint256 challengeExpiry,
    address caller
  );

  event RenewHandle(bytes32 indexed handle, uint256 indexed projectId, address caller);

  function count() external view returns (uint256);

  function uriOf(uint256 _projectId) external view returns (string memory);

  function handleOf(uint256 _projectId) external returns (bytes32 handle);

  function idFor(bytes32 _handle) external returns (uint256 projectId);

  function transferAddressFor(bytes32 _handle) external returns (address receiver);

  function challengeExpiryOf(bytes32 _handle) external returns (uint256);

  function createFor(
    address _owner,
    bytes32 _handle,
    string calldata _uri
  ) external returns (uint256 id);

  function setHandleOf(uint256 _projectId, bytes32 _handle) external;

  function setUriOf(uint256 _projectId, string calldata _uri) external;

  function transferHandleOf(
    uint256 _projectId,
    address _transferAddress,
    bytes32 _newHandle
  ) external returns (bytes32 _handle);

  function claimHandle(
    bytes32 _handle,
    address _for,
    uint256 _projectId
  ) external;

  function challengeHandle(bytes32 _handle) external;

  function renewHandleOf(uint256 _projectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './IJBDirectory.sol';
import './IJBVault.sol';

interface IJBTerminal {
  function token() external view returns (address);

  function ethBalanceOf(uint256 _projectId) external view returns (uint256);

  function delegate() external view returns (address);

  function pay(
    uint256 _projectId,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _delegateMetadata
  ) external payable returns (uint256 fundingCycleId);

  function addToBalanceOf(uint256 _projectId, string memory _memo) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import './IJBDirectory.sol';

interface IJBVault {
  event Deposit(uint256 indexed projectId, uint256 amount, address caller);
  event Withdraw(uint256 indexed projectId, uint256 amount, address to, address caller);

  function token() external view returns (address);

  function deposit(uint256 _projectId, uint256 _amount) external payable;

  function withdraw(
    uint256 _projectId,
    uint256 _amount,
    address payable _to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

/// @notice The funding cycle structure represents a project stewarded by an address, and accounts for which addresses have helped sustain the project.
struct JBFundingCycle {
  // A unique number that's incremented for each new funding cycle, starting with 1.
  uint256 id;
  // The ID of the project contract that this funding cycle belongs to.
  uint256 projectId;
  // The number of this funding cycle for the project.
  uint256 number;
  // The ID of a previous funding cycle that this one is based on.
  uint256 basedOn;
  // The time when this funding cycle was last configured.
  uint256 configured;
  // A number determining the amount of redistribution shares this funding cycle will issue to each sustainer.
  uint256 weight;
  // The ballot contract to use to determine a subsequent funding cycle's reconfiguration status.
  IJBFundingCycleBallot ballot;
  // The time when this funding cycle will become active.
  uint256 start;
  // The number of seconds until this funding cycle's surplus is redistributed.
  uint256 duration;
  // The amount that this funding cycle is targeting in terms of the currency.
  uint256 target;
  // The currency that the target is measured in.
  uint256 currency;
  // The percentage of each payment to send as a fee to the Juicebox admin.
  uint256 fee;
  // A percentage indicating how much more weight to give a funding cycle compared to its predecessor.
  uint256 discountRate;
  // The amount of available funds that have been tapped by the project in terms of the currency.
  uint256 tapped;
  // A packed list of extra data. The first 8 bytes are reserved for versioning.
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './../interfaces/IJBFundingCycleBallot.sol';

struct JBFundingCycleData {
  // The target of the funding cycle.
  uint256 target;
  // The currency of the funding cycle. 0 is ETH, 1 is USD.
  uint256 currency;
  // The duration of the funding cycle.
  uint256 duration;
  // The discount rate of the funding cycle.
  uint256 discountRate;
  // The weight of the funding cycle. Send a weight of 1 to set a minimum.
  uint256 weight;
  // The ballot of the funding cycle.
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculting the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculting the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explictly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE = 78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the closest power of two that is higher than x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}