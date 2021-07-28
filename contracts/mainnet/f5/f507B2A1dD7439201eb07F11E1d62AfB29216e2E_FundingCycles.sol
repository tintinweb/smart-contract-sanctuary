// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@paulrberg/contracts/math/PRBMath.sol";

import "./interfaces/IFundingCycles.sol";
import "./interfaces/IPrices.sol";
import "./abstract/TerminalUtility.sol";

/** 
  @notice Manage funding cycle configurations, accounting, and scheduling.
*/
contract FundingCycles is TerminalUtility, IFundingCycles {
    // --- private stored contants --- //

    // The number of seconds in a day.
    uint256 private constant SECONDS_IN_DAY = 86400;

    // --- private stored properties --- //

    // Stores the reconfiguration properties of each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _packedConfigurationPropertiesOf;

    // Stores the properties added by the mechanism to manage and schedule each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _packedIntrinsicPropertiesOf;

    // Stores the metadata for each funding cycle, packed into one storage slot.
    mapping(uint256 => uint256) private _metadataOf;

    // Stores the amount that each funding cycle can tap funding cycle.
    mapping(uint256 => uint256) private _targetOf;

    // Stores the amount that has been tapped within each funding cycle.
    mapping(uint256 => uint256) private _tappedOf;

    // --- public stored constants --- //

    /// @notice The weight used for each project's first funding cycle.
    uint256 public constant override BASE_WEIGHT = 1E24;

    /// @notice The maximum value that a cycle limit can be set to.
    uint256 public constant override MAX_CYCLE_LIMIT = 32;

    // --- public stored properties --- //

    /// @notice The ID of the latest funding cycle for each project.
    mapping(uint256 => uint256) public override latestIdOf;

    /// @notice The total number of funding cycles created, which is used for issuing funding cycle IDs.
    /// @dev Funding cycles have IDs > 0.
    uint256 public override count = 0;

    // --- external views --- //

    /**
        @notice 
        Get the funding cycle with the given ID.

        @param _fundingCycleId The ID of the funding cycle to get.

        @return _fundingCycle The funding cycle.
    */
    function get(uint256 _fundingCycleId)
        external
        view
        override
        returns (FundingCycle memory)
    {
        // The funding cycle should exist.
        require(
            _fundingCycleId > 0 && _fundingCycleId <= count,
            "FundingCycle::get: NOT_FOUND"
        );

        return _getStruct(_fundingCycleId);
    }

    /**
        @notice 
        The funding cycle that's next up for a project, and therefor not currently accepting payments.

        @dev 
        This runs roughly similar logic to `_configurable`.

        @param _projectId The ID of the project being looked through.

        @return _fundingCycle The queued funding cycle.
    */
    function queuedOf(uint256 _projectId)
        external
        view
        override
        returns (FundingCycle memory)
    {
        // The project must have funding cycles.
        if (latestIdOf[_projectId] == 0) return _getStruct(0);

        // Get a reference to the standby funding cycle.
        uint256 _fundingCycleId = _standby(_projectId);

        // If it exists, return it.
        if (_fundingCycleId > 0) return _getStruct(_fundingCycleId);

        // Get a reference to the eligible funding cycle.
        _fundingCycleId = _eligible(_projectId);

        // If an eligible funding cycle exists...
        if (_fundingCycleId > 0) {
            // Get the necessary properties for the standby funding cycle.
            FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);

            // There's no queued if the current has a duration of 0.
            if (_fundingCycle.duration == 0) return _getStruct(0);

            // Check to see if the correct ballot is approved for this funding cycle.
            // If so, return a funding cycle based on it.
            if (_isApproved(_fundingCycle))
                return _mockFundingCycleBasedOn(_fundingCycle, false);

            // If it hasn't been approved, set the ID to be its base funding cycle, which carries the last approved configuration.
            _fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active,
            // so use the ID of the latest active funding cycle, which carries the last approved configuration.
            _fundingCycleId = latestIdOf[_projectId];
        }

        // A funding cycle must exist.
        if (_fundingCycleId == 0) return _getStruct(0);

        // Return a mock of what its second next up funding cycle would be.
        // Use second next because the next would be a mock of the current funding cycle.
        return _mockFundingCycleBasedOn(_getStruct(_fundingCycleId), false);
    }

    /**
        @notice 
        The funding cycle that is currently active for the specified project.

        @dev 
        This runs very similar logic to `_tappable`.

        @param _projectId The ID of the project being looked through.

        @return fundingCycle The current funding cycle.
    */
    function currentOf(uint256 _projectId)
        external
        view
        override
        returns (FundingCycle memory fundingCycle)
    {
        // The project must have funding cycles.
        if (latestIdOf[_projectId] == 0) return _getStruct(0);

        // Check for an active funding cycle.
        uint256 _fundingCycleId = _eligible(_projectId);

        // If no active funding cycle is found, check if there is a standby funding cycle.
        // If one exists, it will become active one it has been tapped.
        if (_fundingCycleId == 0) _fundingCycleId = _standby(_projectId);

        // Keep a reference to the eligible funding cycle.
        FundingCycle memory _fundingCycle;

        // If a standy funding cycle exists...
        if (_fundingCycleId > 0) {
            // Get the necessary properties for the standby funding cycle.
            _fundingCycle = _getStruct(_fundingCycleId);

            // Check to see if the correct ballot is approved for this funding cycle, and that it has started.
            if (
                _fundingCycle.start <= block.timestamp &&
                _isApproved(_fundingCycle)
            ) return _fundingCycle;

            // If it hasn't been approved, set the ID to be the based funding cycle,
            // which carries the last approved configuration.
            _fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active,
            // so us the ID of the latest active funding cycle, which carries the last approved configuration.
            _fundingCycleId = latestIdOf[_projectId];
        }

        // The funding cycle cant be 0.
        if (_fundingCycleId == 0) return _getStruct(0);

        // The funding cycle to base a current one on.
        _fundingCycle = _getStruct(_fundingCycleId);

        // Return a mock of what the next funding cycle would be like,
        // which would become active one it has been tapped.
        return _mockFundingCycleBasedOn(_fundingCycle, true);
    }

    /** 
      @notice 
      The currency ballot state of the project.

      @param _projectId The ID of the project to check for a pending reconfiguration.

      @return The current ballot's state.
    */
    function currentBallotStateOf(uint256 _projectId)
        external
        view
        override
        returns (BallotState)
    {
        // The project must have funding cycles.
        require(
            latestIdOf[_projectId] > 0,
            "FundingCycles::currentBallotStateOf: NOT_FOUND"
        );

        // Get a reference to the latest funding cycle ID.
        uint256 _fundingCycleId = latestIdOf[_projectId];

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);

        // If the latest funding cycle is the first, or if it has already started, it must be approved.
        if (_fundingCycle.basedOn == 0) return BallotState.Standby;

        return
            _ballotState(
                _fundingCycleId,
                _fundingCycle.configured,
                _fundingCycle.basedOn
            );
    }

    // --- external transactions --- //

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory)
        TerminalUtility(_terminalDirectory)
    {}

    /**
        @notice 
        Configures the next eligible funding cycle for the specified project.

        @dev
        Only a project's current terminal can configure its funding cycles.

        @param _projectId The ID of the project being reconfigured.
        @param _properties The funding cycle configuration.
          @dev _properties.target The amount that the project wants to receive in each funding cycle. 18 decimals.
          @dev _properties.currency The currency of the `_target`. Send 0 for ETH or 1 for USD.
          @dev _properties.duration The duration of the funding cycle for which the `_target` amount is needed. Measured in days. 
            Set to 0 for no expiry and to be able to reconfigure anytime.
          @dev _cycleLimit The number of cycles that this configuration should last for before going back to the last permanent. This does nothing for a project's first funding cycle.
          @dev _properties.discountRate A number from 0-200 indicating how valuable a contribution to this funding cycle is compared to previous funding cycles.
            If it's 0, each funding cycle will have equal weight.
            If the number is 100, a contribution to the next funding cycle will only give you 90% of tickets given to a contribution of the same amount during the current funding cycle.
            If the number is 200, a contribution to the next funding cycle will only give you 80% of tickets given to a contribution of the same amoutn during the current funding cycle.
            If the number is 201, an non-recurring funding cycle will get made.
          @dev _ballot The new ballot that will be used to approve subsequent reconfigurations.
        @param _metadata Data to associate with this funding cycle configuration.
        @param _fee The fee that this configuration will incure when tapping.
        @param _configureActiveFundingCycle If a funding cycle that has already started should be configurable.

        @return fundingCycle The funding cycle that the configuration will take effect during.
    */
    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        uint256 _metadata,
        uint256 _fee,
        bool _configureActiveFundingCycle
    )
        external
        override
        onlyTerminal(_projectId)
        returns (FundingCycle memory fundingCycle)
    {
        // Duration must fit in a uint16.
        require(
            _properties.duration <= type(uint16).max,
            "FundingCycles::configure: BAD_DURATION"
        );

        // Currency must be less than the limit.
        require(
            _properties.cycleLimit <= MAX_CYCLE_LIMIT,
            "FundingCycles::configure: BAD_CYCLE_LIMIT"
        );

        // Discount rate token must be less than or equal to 100%.
        require(
            _properties.discountRate <= 201,
            "FundingCycles::configure: BAD_DISCOUNT_RATE"
        );

        // Currency must fit into a uint8.
        require(
            _properties.currency <= type(uint8).max,
            "FundingCycles::configure: BAD_CURRENCY"
        );

        // Fee must be less than or equal to 100%.
        require(_fee <= 200, "FundingCycles::configure: BAD_FEE");

        // Set the configuration timestamp is now.
        uint256 _configured = block.timestamp;

        // Gets the ID of the funding cycle to reconfigure.
        uint256 _fundingCycleId = _configurable(
            _projectId,
            _configured,
            _configureActiveFundingCycle
        );

        // Store the configuration.
        _packAndStoreConfigurationProperties(
            _fundingCycleId,
            _configured,
            _properties.cycleLimit,
            _properties.ballot,
            _properties.duration,
            _properties.currency,
            _fee,
            _properties.discountRate
        );

        // Set the target amount.
        _targetOf[_fundingCycleId] = _properties.target;

        // Set the metadata.
        _metadataOf[_fundingCycleId] = _metadata;

        emit Configure(
            _fundingCycleId,
            _projectId,
            _configured,
            _properties,
            _metadata,
            msg.sender
        );

        return _getStruct(_fundingCycleId);
    }

    /** 
      @notice 
      Tap funds from a project's currently tappable funding cycle.

      @dev
      Only a project's current terminal can tap funds for its funding cycles.

      @param _projectId The ID of the project being tapped.
      @param _amount The amount being tapped.

      @return fundingCycle The tapped funding cycle.
    */
    function tap(uint256 _projectId, uint256 _amount)
        external
        override
        onlyTerminal(_projectId)
        returns (FundingCycle memory fundingCycle)
    {
        // Get a reference to the funding cycle being tapped.
        uint256 fundingCycleId = _tappable(_projectId);

        // Get a reference to how much has already been tapped from this funding cycle.
        uint256 _tapped = _tappedOf[fundingCycleId];

        // Amount must be within what is still tappable.
        require(
            _amount <= _targetOf[fundingCycleId] - _tapped,
            "FundingCycles::tap: INSUFFICIENT_FUNDS"
        );

        // The new amount that has been tapped.
        uint256 _newTappedAmount = _tapped + _amount;

        // Store the new amount.
        _tappedOf[fundingCycleId] = _newTappedAmount;

        emit Tap(
            fundingCycleId,
            _projectId,
            _amount,
            _newTappedAmount,
            msg.sender
        );

        return _getStruct(fundingCycleId);
    }

    // --- private helper functions --- //

    /**
        @notice 
        Returns the configurable funding cycle for this project if it exists, otherwise creates one.

        @param _projectId The ID of the project to find a configurable funding cycle for.
        @param _configured The time at which the configuration is occuring.
        @param _configureActiveFundingCycle If the active funding cycle should be configurable. Otherwise the next funding cycle will be used.

        @return fundingCycleId The ID of the configurable funding cycle.
    */
    function _configurable(
        uint256 _projectId,
        uint256 _configured,
        bool _configureActiveFundingCycle
    ) private returns (uint256 fundingCycleId) {
        // If there's not yet a funding cycle for the project, return the ID of a newly created one.
        if (latestIdOf[_projectId] == 0)
            return _init(_projectId, _getStruct(0), block.timestamp, false);

        // Get the standby funding cycle's ID.
        fundingCycleId = _standby(_projectId);

        // If it exists, make sure its updated, then return it.
        if (fundingCycleId > 0) {
            // Get the funding cycle that the specified one is based on.
            FundingCycle memory _baseFundingCycle = _getStruct(
                _getStruct(fundingCycleId).basedOn
            );

            // The base's ballot must have ended.
            _updateFundingCycle(
                fundingCycleId,
                _baseFundingCycle,
                _getTimeAfterBallot(_baseFundingCycle, _configured),
                false
            );
            return fundingCycleId;
        }

        // Get the active funding cycle's ID.
        fundingCycleId = _eligible(_projectId);

        // If the ID of an eligible funding cycle exists, it's approved, and active funding cycles are configurable, return it.
        if (fundingCycleId > 0) {
            if (!_isIdApproved(fundingCycleId)) {
                // If it hasn't been approved, set the ID to be the based funding cycle,
                // which carries the last approved configuration.
                fundingCycleId = _getStruct(fundingCycleId).basedOn;
            } else if (_configureActiveFundingCycle) {
                return fundingCycleId;
            }
        } else {
            // Get the ID of the latest funding cycle which has the latest reconfiguration.
            fundingCycleId = latestIdOf[_projectId];
        }

        // Determine if the configurable funding cycle can only take effect on or after a certain date.
        uint256 _mustStartOnOrAfter;

        // Base off of the active funding cycle if it exists.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // Make sure the funding cycle is recurring.
        require(
            _fundingCycle.discountRate < 201,
            "FundingCycles::_configurable: NON_RECURRING"
        );

        if (_configureActiveFundingCycle) {
            // If the duration is zero, always go back to the original start.
            if (_fundingCycle.duration == 0) {
                _mustStartOnOrAfter = _fundingCycle.start;
            } else {
                // Set to the start time of the current active start time.
                uint256 _timeFromStartMultiple = (block.timestamp -
                    _fundingCycle.start) %
                    (_fundingCycle.duration * SECONDS_IN_DAY);
                _mustStartOnOrAfter = block.timestamp - _timeFromStartMultiple;
            }
        } else {
            // The ballot must have ended.
            _mustStartOnOrAfter = _getTimeAfterBallot(
                _fundingCycle,
                _configured
            );
        }

        // Return the newly initialized configurable funding cycle.
        fundingCycleId = _init(
            _projectId,
            _fundingCycle,
            _mustStartOnOrAfter,
            false
        );
    }

    /**
        @notice 
        Returns the funding cycle that can be tapped at the time of the call.

        @param _projectId The ID of the project to find a configurable funding cycle for.

        @return fundingCycleId The ID of the tappable funding cycle.
    */
    function _tappable(uint256 _projectId)
        private
        returns (uint256 fundingCycleId)
    {
        // Check for the ID of an eligible funding cycle.
        fundingCycleId = _eligible(_projectId);

        // No eligible funding cycle found, check for the ID of a standby funding cycle.
        // If this one exists, it will become eligible one it has started.
        if (fundingCycleId == 0) fundingCycleId = _standby(_projectId);

        // Keep a reference to the funding cycle eligible for being tappable.
        FundingCycle memory _fundingCycle;

        // If the ID of an eligible funding cycle exists,
        // check to see if it has been approved by the based funding cycle's ballot.
        if (fundingCycleId > 0) {
            // Get the necessary properties for the funding cycle.
            _fundingCycle = _getStruct(fundingCycleId);

            // Check to see if the cycle is approved. If so, return it.
            if (
                _fundingCycle.start <= block.timestamp &&
                _isApproved(_fundingCycle)
            ) return fundingCycleId;

            // If it hasn't been approved, set the ID to be the base funding cycle,
            // which carries the last approved configuration.
            fundingCycleId = _fundingCycle.basedOn;
        } else {
            // No upcoming funding cycle found that is eligible to become active, clone the latest active funding cycle.
            // which carries the last approved configuration.
            fundingCycleId = latestIdOf[_projectId];
        }

        // The funding cycle cant be 0.
        require(fundingCycleId > 0, "FundingCycles::_tappable: NOT_FOUND");

        // Set the eligible funding cycle.
        _fundingCycle = _getStruct(fundingCycleId);

        // Funding cycles with a discount rate of 100% are non-recurring.
        require(
            _fundingCycle.discountRate < 201,
            "FundingCycles::_tappable: NON_RECURRING"
        );

        // The time when the funding cycle immediately after the eligible funding cycle starts.
        uint256 _nextImmediateStart = _fundingCycle.start +
            (_fundingCycle.duration * SECONDS_IN_DAY);

        // The distance from now until the nearest past multiple of the cycle duration from its start.
        // A duration of zero means the reconfiguration can start right away.
        uint256 _timeFromImmediateStartMultiple = _fundingCycle.duration == 0
            ? 0
            : (block.timestamp - _nextImmediateStart) %
                (_fundingCycle.duration * SECONDS_IN_DAY);

        // Return the tappable funding cycle.
        fundingCycleId = _init(
            _projectId,
            _fundingCycle,
            block.timestamp - _timeFromImmediateStartMultiple,
            true
        );
    }

    /**
        @notice 
        Initializes a funding cycle with the appropriate properties.

        @param _projectId The ID of the project to which the funding cycle being initialized belongs.
        @param _baseFundingCycle The funding cycle to base the initialized one on.
        @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.
        @param _copy If non-intrinsic properties should be copied from the base funding cycle.

        @return newFundingCycleId The ID of the initialized funding cycle.
    */
    function _init(
        uint256 _projectId,
        FundingCycle memory _baseFundingCycle,
        uint256 _mustStartOnOrAfter,
        bool _copy
    ) private returns (uint256 newFundingCycleId) {
        // Increment the count of funding cycles.
        count++;

        // Set the project's latest funding cycle ID to the new count.
        latestIdOf[_projectId] = count;

        // If there is no base, initialize a first cycle.
        if (_baseFundingCycle.id == 0) {
            // Set fresh intrinsic properties.
            _packAndStoreIntrinsicProperties(
                count,
                _projectId,
                BASE_WEIGHT,
                1,
                0,
                block.timestamp
            );
        } else {
            // Update the intrinsic properties of the funding cycle being initialized.
            _updateFundingCycle(
                count,
                _baseFundingCycle,
                _mustStartOnOrAfter,
                _copy
            );
        }

        // Get a reference to the funding cycle with updated intrinsic properties.
        FundingCycle memory _fundingCycle = _getStruct(count);

        emit Init(
            count,
            _fundingCycle.projectId,
            _fundingCycle.number,
            _fundingCycle.basedOn,
            _fundingCycle.weight,
            _fundingCycle.start
        );

        return _fundingCycle.id;
    }

    /**
        @notice 
        The project's funding cycle that hasn't yet started, if one exists.

        @param _projectId The ID of project to look through.

        @return fundingCycleId The ID of the standby funding cycle.
    */
    function _standby(uint256 _projectId)
        private
        view
        returns (uint256 fundingCycleId)
    {
        // Get a reference to the project's latest funding cycle.
        fundingCycleId = latestIdOf[_projectId];

        // If there isn't one, theres also no standy funding cycle.
        if (fundingCycleId == 0) return 0;

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // There is no upcoming funding cycle if the latest funding cycle has already started.
        if (block.timestamp >= _fundingCycle.start) return 0;
    }

    /**
        @notice 
        The project's funding cycle that has started and hasn't yet expired.

        @param _projectId The ID of the project to look through.

        @return fundingCycleId The ID of the active funding cycle.
    */
    function _eligible(uint256 _projectId)
        private
        view
        returns (uint256 fundingCycleId)
    {
        // Get a reference to the project's latest funding cycle.
        fundingCycleId = latestIdOf[_projectId];

        // If the latest funding cycle doesn't exist, return an undefined funding cycle.
        if (fundingCycleId == 0) return 0;

        // Get the necessary properties for the latest funding cycle.
        FundingCycle memory _fundingCycle = _getStruct(fundingCycleId);

        // If the latest is expired, return an undefined funding cycle.
        // A duration of 0 can not be expired.
        if (
            _fundingCycle.duration > 0 &&
            block.timestamp >=
            _fundingCycle.start + (_fundingCycle.duration * SECONDS_IN_DAY)
        ) return 0;

        // The first funding cycle when running on local can be in the future for some reason.
        // This will have no effect in production.
        if (
            _fundingCycle.basedOn == 0 || block.timestamp >= _fundingCycle.start
        ) return fundingCycleId;

        // The base cant be expired.
        FundingCycle memory _baseFundingCycle = _getStruct(
            _fundingCycle.basedOn
        );

        // If the current time is past the end of the base, return 0.
        // A duration of 0 is always eligible.
        if (
            _baseFundingCycle.duration > 0 &&
            block.timestamp >=
            _baseFundingCycle.start +
                (_baseFundingCycle.duration * SECONDS_IN_DAY)
        ) return 0;

        // Return the funding cycle immediately before the latest.
        fundingCycleId = _fundingCycle.basedOn;
    }

    /** 
        @notice 
        A view of the funding cycle that would be created based on the provided one if the project doesn't make a reconfiguration.

        @param _baseFundingCycle The funding cycle to make the calculation for.
        @param _allowMidCycle Allow the mocked funding cycle to already be mid cycle.

        @return The next funding cycle, with an ID set to 0.
    */
    function _mockFundingCycleBasedOn(
        FundingCycle memory _baseFundingCycle,
        bool _allowMidCycle
    ) internal view returns (FundingCycle memory) {
        // Can't mock a non recurring funding cycle.
        if (_baseFundingCycle.discountRate == 201) return _getStruct(0);

        // If the base has a limit, find the last permanent funding cycle, which is needed to make subsequent calculations.
        // Otherwise, the base is already the latest permanent funding cycle.
        FundingCycle memory _latestPermanentFundingCycle = _baseFundingCycle
        .cycleLimit > 0
            ? _latestPermanentCycleBefore(_baseFundingCycle)
            : _baseFundingCycle;

        // The distance of the current time to the start of the next possible funding cycle.
        uint256 _timeFromImmediateStartMultiple;

        if (_allowMidCycle && _baseFundingCycle.duration > 0) {
            // Get the end time of the last cycle.
            uint256 _cycleEnd = _baseFundingCycle.start +
                (_baseFundingCycle.cycleLimit *
                    _baseFundingCycle.duration *
                    SECONDS_IN_DAY);

            // If the cycle end time is in the past, the mock should start at a multiple of the last permanent cycle since the cycle ended.
            if (
                _baseFundingCycle.cycleLimit > 0 && _cycleEnd < block.timestamp
            ) {
                _timeFromImmediateStartMultiple = _latestPermanentFundingCycle
                .duration == 0
                    ? 0
                    : ((block.timestamp - _cycleEnd) %
                        (_latestPermanentFundingCycle.duration *
                            SECONDS_IN_DAY));
            } else {
                _timeFromImmediateStartMultiple =
                    _baseFundingCycle.duration *
                    SECONDS_IN_DAY;
            }
        } else {
            _timeFromImmediateStartMultiple = 0;
        }

        // Derive what the start time should be.
        uint256 _start = _deriveStart(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            block.timestamp - _timeFromImmediateStartMultiple
        );

        // Derive what the cycle limit should be.
        uint256 _cycleLimit = _deriveCycleLimit(_baseFundingCycle, _start);

        // Copy the last permanent funding cycle if the bases' limit is up.
        FundingCycle memory _fundingCycleToCopy = _cycleLimit == 0
            ? _latestPermanentFundingCycle
            : _baseFundingCycle;

        return
            FundingCycle(
                0,
                _fundingCycleToCopy.projectId,
                _deriveNumber(
                    _baseFundingCycle,
                    _latestPermanentFundingCycle,
                    _start
                ),
                _fundingCycleToCopy.id,
                _fundingCycleToCopy.configured,
                _cycleLimit,
                _deriveWeight(
                    _baseFundingCycle,
                    _latestPermanentFundingCycle,
                    _start
                ),
                _fundingCycleToCopy.ballot,
                _start,
                _fundingCycleToCopy.duration,
                _fundingCycleToCopy.target,
                _fundingCycleToCopy.currency,
                _fundingCycleToCopy.fee,
                _fundingCycleToCopy.discountRate,
                0,
                _fundingCycleToCopy.metadata
            );
    }

    /** 
      @notice
      Updates intrinsic properties for a funding cycle given a base cycle.

      @param _fundingCycleId The ID of the funding cycle to make sure is update.
      @param _baseFundingCycle The cycle that the one being updated is based on.
      @param _mustStartOnOrAfter The time before which the initialized funding cycle can't start.
      @param _copy If non-intrinsic properties should be copied from the base funding cycle.
    */
    function _updateFundingCycle(
        uint256 _fundingCycleId,
        FundingCycle memory _baseFundingCycle,
        uint256 _mustStartOnOrAfter,
        bool _copy
    ) private {
        // Get the latest permanent funding cycle.
        FundingCycle memory _latestPermanentFundingCycle = _baseFundingCycle
        .cycleLimit > 0
            ? _latestPermanentCycleBefore(_baseFundingCycle)
            : _baseFundingCycle;

        // Derive the correct next start time from the base.
        uint256 _start = _deriveStart(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _mustStartOnOrAfter
        );

        // Derive the correct weight.
        uint256 _weight = _deriveWeight(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _start
        );

        // Derive the correct number.
        uint256 _number = _deriveNumber(
            _baseFundingCycle,
            _latestPermanentFundingCycle,
            _start
        );

        // Copy if needed.
        if (_copy) {
            // Derive what the cycle limit should be.
            uint256 _cycleLimit = _deriveCycleLimit(_baseFundingCycle, _start);

            // Copy the last permanent funding cycle if the bases' limit is up.
            FundingCycle memory _fundingCycleToCopy = _cycleLimit == 0
                ? _latestPermanentFundingCycle
                : _baseFundingCycle;

            // Save the configuration efficiently.
            _packAndStoreConfigurationProperties(
                _fundingCycleId,
                _fundingCycleToCopy.configured,
                _cycleLimit,
                _fundingCycleToCopy.ballot,
                _fundingCycleToCopy.duration,
                _fundingCycleToCopy.currency,
                _fundingCycleToCopy.fee,
                _fundingCycleToCopy.discountRate
            );

            _metadataOf[count] = _metadataOf[_fundingCycleToCopy.id];
            _targetOf[count] = _targetOf[_fundingCycleToCopy.id];
        }

        // Update the intrinsic properties.
        _packAndStoreIntrinsicProperties(
            _fundingCycleId,
            _baseFundingCycle.projectId,
            _weight,
            _number,
            _baseFundingCycle.id,
            _start
        );
    }

    /**
      @notice 
      Efficiently stores a funding cycle's provided intrinsic properties.

      @param _fundingCycleId The ID of the funding cycle to pack and store.
      @param _projectId The ID of the project to which the funding cycle belongs.
      @param _weight The weight of the funding cycle.
      @param _number The number of the funding cycle.
      @param _basedOn The ID of the based funding cycle.
      @param _start The start time of this funding cycle.

     */
    function _packAndStoreIntrinsicProperties(
        uint256 _fundingCycleId,
        uint256 _projectId,
        uint256 _weight,
        uint256 _number,
        uint256 _basedOn,
        uint256 _start
    ) private {
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

        // Set in storage.
        _packedIntrinsicPropertiesOf[_fundingCycleId] = packed;
    }

    /**
      @notice 
      Efficiently stores a funding cycles provided configuration properties.

      @param _fundingCycleId The ID of the funding cycle to pack and store.
      @param _configured The timestamp of the configuration.
      @param _cycleLimit The number of cycles that this configuration should last for before going back to the last permanent.
      @param _ballot The ballot to use for future reconfiguration approvals. 
      @param _duration The duration of the funding cycle.
      @param _currency The currency of the funding cycle.
      @param _fee The fee of the funding cycle.
      @param _discountRate The discount rate of the based funding cycle.
     */
    function _packAndStoreConfigurationProperties(
        uint256 _fundingCycleId,
        uint256 _configured,
        uint256 _cycleLimit,
        IFundingCycleBallot _ballot,
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
        // discountRate in bytes 240-247 bytes.
        packed |= _discountRate << 240;
        // cycleLimit in bytes 248-255 bytes.
        packed |= _cycleLimit << 248;

        // Set in storage.
        _packedConfigurationPropertiesOf[_fundingCycleId] = packed;
    }

    /**
        @notice 
        Unpack a funding cycle's packed stored values into an easy-to-work-with funding cycle struct.

        @param _id The ID of the funding cycle to get a struct of.

        @return _fundingCycle The funding cycle struct.
    */
    function _getStruct(uint256 _id)
        private
        view
        returns (FundingCycle memory _fundingCycle)
    {
        // Return an empty funding cycle if the ID specified is 0.
        if (_id == 0) return _fundingCycle;

        _fundingCycle.id = _id;

        uint256 _packedIntrinsicProperties = _packedIntrinsicPropertiesOf[_id];

        _fundingCycle.weight = uint256(uint80(_packedIntrinsicProperties));
        _fundingCycle.projectId = uint256(
            uint56(_packedIntrinsicProperties >> 80)
        );
        _fundingCycle.basedOn = uint256(
            uint48(_packedIntrinsicProperties >> 136)
        );
        _fundingCycle.start = uint256(
            uint48(_packedIntrinsicProperties >> 184)
        );
        _fundingCycle.number = uint256(
            uint24(_packedIntrinsicProperties >> 232)
        );


            uint256 _packedConfigurationProperties
         = _packedConfigurationPropertiesOf[_id];
        _fundingCycle.ballot = IFundingCycleBallot(
            address(uint160(_packedConfigurationProperties))
        );
        _fundingCycle.configured = uint256(
            uint48(_packedConfigurationProperties >> 160)
        );
        _fundingCycle.duration = uint256(
            uint16(_packedConfigurationProperties >> 208)
        );
        _fundingCycle.currency = uint256(
            uint8(_packedConfigurationProperties >> 224)
        );
        _fundingCycle.fee = uint256(
            uint8(_packedConfigurationProperties >> 232)
        );
        _fundingCycle.discountRate = uint256(
            uint8(_packedConfigurationProperties >> 240)
        );
        _fundingCycle.cycleLimit = uint256(
            uint8(_packedConfigurationProperties >> 248)
        );
        _fundingCycle.target = _targetOf[_id];
        _fundingCycle.tapped = _tappedOf[_id];
        _fundingCycle.metadata = _metadataOf[_id];
    }

    /** 
        @notice 
        The date that is the nearest multiple of the specified funding cycle's duration from its end.

        @param _baseFundingCycle The funding cycle to make the calculation for.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_baseFundingCycle` to not have a limit.
        @param _mustStartOnOrAfter A date that the derived start must be on or come after.

        @return start The next start time.
    */
    function _deriveStart(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _mustStartOnOrAfter
    ) internal pure returns (uint256 start) {
        // A subsequent cycle to one with a duration of 0 should start as soon as possible.
        if (_baseFundingCycle.duration == 0) return _mustStartOnOrAfter;

        // Save a reference to the duration measured in seconds.
        uint256 _durationInSeconds = _baseFundingCycle.duration *
            SECONDS_IN_DAY;

        // The time when the funding cycle immediately after the specified funding cycle starts.
        uint256 _nextImmediateStart = _baseFundingCycle.start +
            _durationInSeconds;

        // If the next immediate start is now or in the future, return it.
        if (_nextImmediateStart >= _mustStartOnOrAfter)
            return _nextImmediateStart;

        uint256 _cycleLimit = _baseFundingCycle.cycleLimit;

        uint256 _timeFromImmediateStartMultiple;
        // Only use base
        if (
            _mustStartOnOrAfter <=
            _baseFundingCycle.start + _durationInSeconds * _cycleLimit
        ) {
            // Otherwise, use the closest multiple of the duration from the old end.
            _timeFromImmediateStartMultiple =
                (_mustStartOnOrAfter - _nextImmediateStart) %
                _durationInSeconds;
        } else {
            // If the cycle has ended, make the calculation with the latest permanent funding cycle.
            _timeFromImmediateStartMultiple = _latestPermanentFundingCycle
            .duration == 0
                ? 0
                : ((_mustStartOnOrAfter -
                    (_baseFundingCycle.start +
                        (_durationInSeconds * _cycleLimit))) %
                    (_latestPermanentFundingCycle.duration * SECONDS_IN_DAY));

            // Use the duration of the permanent funding cycle from here on out.
            _durationInSeconds =
                _latestPermanentFundingCycle.duration *
                SECONDS_IN_DAY;
        }

        // Otherwise use an increment of the duration from the most recent start.
        start = _mustStartOnOrAfter - _timeFromImmediateStartMultiple;

        // Add increments of duration as necessary to satisfy the threshold.
        while (_mustStartOnOrAfter > start) start = start + _durationInSeconds;
    }

    /** 
        @notice 
        The accumulated weight change since the specified funding cycle.

        @param _baseFundingCycle The funding cycle to make the calculation with.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_fundingCycle` to not have a limit.
        @param _start The start time to derive a weight for.

        @return weight The next weight.
    */
    function _deriveWeight(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _start
    ) internal pure returns (uint256 weight) {
        // A subsequent cycle to one with a duration of 0 should have the next possible weight.
        if (_baseFundingCycle.duration == 0)
            return
                PRBMath.mulDiv(
                    _baseFundingCycle.weight,
                    1000 - _baseFundingCycle.discountRate,
                    1000
                );

        // The difference between the start of the base funding cycle and the proposed start.
        uint256 _startDistance = _start - _baseFundingCycle.start;

        // The number of seconds that the base funding cycle is limited to.
        uint256 _limitLength = _baseFundingCycle.cycleLimit == 0 ||
            _baseFundingCycle.basedOn == 0
            ? 0
            : _baseFundingCycle.cycleLimit *
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

        // The weight should be based off the base funding cycle's weight.
        weight = _baseFundingCycle.weight;

        // If there's no limit or if the limit is greater than the start distance,
        // apply the discount rate of the base.
        if (_limitLength == 0 || _limitLength > _startDistance) {
            // If the discount rate is 0, return the same weight.
            if (_baseFundingCycle.discountRate == 0) return weight;

            uint256 _discountMultiple = _startDistance /
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

            for (uint256 i = 0; i < _discountMultiple; i++) {
                // The number of times to apply the discount rate.
                // Base the new weight on the specified funding cycle's weight.
                weight = PRBMath.mulDiv(
                    weight,
                    1000 - _baseFundingCycle.discountRate,
                    1000
                );
            }
        } else {
            // If the time between the base start at the given start is longer than
            // the limit, the discount rate for the limited base has to be applied first,
            // and then the discount rate for the last permanent should be applied to
            // the remaining distance.

            // Use up the limited discount rate up until the limit.
            if (_baseFundingCycle.discountRate > 0) {
                for (uint256 i = 0; i < _baseFundingCycle.cycleLimit; i++) {
                    weight = PRBMath.mulDiv(
                        weight,
                        1000 - _baseFundingCycle.discountRate,
                        1000
                    );
                }
            }

            if (_latestPermanentFundingCycle.discountRate > 0) {
                // The number of times to apply the latest permanent discount rate.


                    uint256 _permanentDiscountMultiple
                 = _latestPermanentFundingCycle.duration == 0
                    ? 0
                    : (_startDistance - _limitLength) /
                        (_latestPermanentFundingCycle.duration *
                            SECONDS_IN_DAY);

                for (uint256 i = 0; i < _permanentDiscountMultiple; i++) {
                    // base the weight on the result of the previous calculation.
                    weight = PRBMath.mulDiv(
                        weight,
                        1000 - _latestPermanentFundingCycle.discountRate,
                        1000
                    );
                }
            }
        }
    }

    /** 
        @notice 
        The number of the next funding cycle given the specified funding cycle.

        @param _baseFundingCycle The funding cycle to make the calculation with.
        @param _latestPermanentFundingCycle The latest funding cycle in the same project as `_fundingCycle` to not have a limit.
        @param _start The start time to derive a number for.

        @return number The next number.
    */
    function _deriveNumber(
        FundingCycle memory _baseFundingCycle,
        FundingCycle memory _latestPermanentFundingCycle,
        uint256 _start
    ) internal pure returns (uint256 number) {
        // A subsequent cycle to one with a duration of 0 should be the next number.
        if (_baseFundingCycle.duration == 0)
            return _baseFundingCycle.number + 1;

        // The difference between the start of the base funding cycle and the proposed start.
        uint256 _startDistance = _start - _baseFundingCycle.start;

        // The number of seconds that the base funding cycle is limited to.
        uint256 _limitLength = _baseFundingCycle.cycleLimit == 0
            ? 0
            : _baseFundingCycle.cycleLimit *
                (_baseFundingCycle.duration * SECONDS_IN_DAY);

        if (_limitLength == 0 || _limitLength > _startDistance) {
            // If there's no limit or if the limit is greater than the start distance,
            // get the result by finding the number of base cycles that fit in the start distance.
            number =
                _baseFundingCycle.number +
                (_startDistance /
                    (_baseFundingCycle.duration * SECONDS_IN_DAY));
        } else {
            // If the time between the base start at the given start is longer than
            // the limit, first calculate the number of cycles that passed under the limit,
            // and add any cycles that have passed of the latest permanent funding cycle afterwards.

            number =
                _baseFundingCycle.number +
                (_limitLength / (_baseFundingCycle.duration * SECONDS_IN_DAY));

            number =
                number +
                (
                    _latestPermanentFundingCycle.duration == 0
                        ? 0
                        : ((_startDistance - _limitLength) /
                            (_latestPermanentFundingCycle.duration *
                                SECONDS_IN_DAY))
                );
        }
    }

    /** 
        @notice 
        The limited number of times a funding cycle configuration can be active given the specified funding cycle.

        @param _fundingCycle The funding cycle to make the calculation with.
        @param _start The start time to derive cycles remaining for.

        @return start The inclusive nunmber of cycles remaining.
    */
    function _deriveCycleLimit(
        FundingCycle memory _fundingCycle,
        uint256 _start
    ) internal pure returns (uint256) {
        if (_fundingCycle.cycleLimit <= 1 || _fundingCycle.duration == 0)
            return 0;
        uint256 _cycles = ((_start - _fundingCycle.start) /
            (_fundingCycle.duration * SECONDS_IN_DAY));

        if (_cycles >= _fundingCycle.cycleLimit) return 0;
        return _fundingCycle.cycleLimit - _cycles;
    }

    /** 
      @notice 
      Checks to see if the funding cycle of the provided ID is approved according to the correct ballot.

      @param _fundingCycleId The ID of the funding cycle to get an approval flag for.

      @return The approval flag.
    */
    function _isIdApproved(uint256 _fundingCycleId)
        private
        view
        returns (bool)
    {
        FundingCycle memory _fundingCycle = _getStruct(_fundingCycleId);
        return _isApproved(_fundingCycle);
    }

    /** 
      @notice 
      Checks to see if the provided funding cycle is approved according to the correct ballot.

      @param _fundingCycle The ID of the funding cycle to get an approval flag for.

      @return The approval flag.
    */
    function _isApproved(FundingCycle memory _fundingCycle)
        private
        view
        returns (bool)
    {
        return
            _ballotState(
                _fundingCycle.id,
                _fundingCycle.configured,
                _fundingCycle.basedOn
            ) == BallotState.Approved;
    }

    /**
        @notice 
        A funding cycle configuration's currency status.

        @param _id The ID of the funding cycle configuration to check the status of.
        @param _configuration The timestamp of when the configuration took place.
        @param _ballotFundingCycleId The ID of the funding cycle which is configured with the ballot that should be used.

        @return The funding cycle's configuration status.
    */
    function _ballotState(
        uint256 _id,
        uint256 _configuration,
        uint256 _ballotFundingCycleId
    ) private view returns (BallotState) {
        // If there is no ballot funding cycle, auto approve.
        if (_ballotFundingCycleId == 0) return BallotState.Approved;

        // Get the ballot funding cycle.
        FundingCycle memory _ballotFundingCycle = _getStruct(
            _ballotFundingCycleId
        );

        // If the configuration is the same as the ballot's funding cycle,
        // the ballot isn't applicable. Auto approve since the ballot funding cycle is approved.
        if (_ballotFundingCycle.configured == _configuration)
            return BallotState.Approved;

        // If there is no ballot, the ID is auto approved.
        // Otherwise, return the ballot's state.
        return
            _ballotFundingCycle.ballot == IFundingCycleBallot(address(0))
                ? BallotState.Approved
                : _ballotFundingCycle.ballot.state(_id, _configuration);
    }

    /** 
      @notice 
      Finds the last funding cycle that was permanent in relation to the specified funding cycle.

      @dev
      Determined what the latest funding cycle with a `cycleLimit` of 0 is, or isn't based on any previous funding cycle.


      @param _fundingCycle The funding cycle to find the most recent permanent cycle compared to.

      @return fundingCycle The most recent permanent funding cycle.
    */
    function _latestPermanentCycleBefore(FundingCycle memory _fundingCycle)
        private
        view
        returns (FundingCycle memory fundingCycle)
    {
        if (_fundingCycle.basedOn == 0) return _fundingCycle;
        fundingCycle = _getStruct(_fundingCycle.basedOn);
        if (fundingCycle.cycleLimit == 0) return fundingCycle;
        return _latestPermanentCycleBefore(fundingCycle);
    }

    /** 
      @notice
      The time after the ballot of the provided funding cycle has expired.

      @dev
      If the ballot ends in the past, the current block timestamp will be returned.

      @param _fundingCycle The ID funding cycle to make the caluclation the ballot of.
      @param _from The time from which the ballot duration should be calculated.

      @return The time when the ballot duration ends.
    */
    function _getTimeAfterBallot(
        FundingCycle memory _fundingCycle,
        uint256 _from
    ) private view returns (uint256) {
        // The ballot must have ended.
        uint256 _ballotExpiration = _fundingCycle.ballot !=
            IFundingCycleBallot(address(0))
            ? _from + _fundingCycle.ballot.duration()
            : 0;

        return
            block.timestamp > _ballotExpiration
                ? block.timestamp
                : _ballotExpiration;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "prb-math/contracts/PRBMath.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IPrices.sol";
import "./IProjects.sol";
import "./IFundingCycleBallot.sol";

/// @notice The funding cycle structure represents a project stewarded by an address, and accounts for which addresses have helped sustain the project.
struct FundingCycle {
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
    // The number of cycles that this configuration should last for before going back to the last permanent.
    uint256 cycleLimit;
    // A number determining the amount of redistribution shares this funding cycle will issue to each sustainer.
    uint256 weight;
    // The ballot contract to use to determine a subsequent funding cycle's reconfiguration status.
    IFundingCycleBallot ballot;
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

struct FundingCycleProperties {
    uint256 target;
    uint256 currency;
    uint256 duration;
    uint256 cycleLimit;
    uint256 discountRate;
    IFundingCycleBallot ballot;
}

interface IFundingCycles {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 reconfigured,
        FundingCycleProperties _properties,
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

    event Init(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        uint256 number,
        uint256 previous,
        uint256 weight,
        uint256 start
    );

    function latestIdOf(uint256 _projectId) external view returns (uint256);

    function count() external view returns (uint256);

    function BASE_WEIGHT() external view returns (uint256);

    function MAX_CYCLE_LIMIT() external view returns (uint256);

    function get(uint256 _fundingCycleId)
        external
        view
        returns (FundingCycle memory);

    function queuedOf(uint256 _projectId)
        external
        view
        returns (FundingCycle memory);

    function currentOf(uint256 _projectId)
        external
        view
        returns (FundingCycle memory);

    function currentBallotStateOf(uint256 _projectId)
        external
        view
        returns (BallotState);

    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        uint256 _metadata,
        uint256 _fee,
        bool _configureActiveFundingCycle
    ) external returns (FundingCycle memory fundingCycle);

    function tap(uint256 _projectId, uint256 _amount)
        external
        returns (FundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IPrices {
    event AddFeed(uint256 indexed currency, AggregatorV3Interface indexed feed);

    function feedDecimalAdjuster(uint256 _currency) external returns (uint256);

    function targetDecimals() external returns (uint256);

    function feedFor(uint256 _currency)
        external
        returns (AggregatorV3Interface);

    function getETHPriceFor(uint256 _currency) external view returns (uint256);

    function addFeed(AggregatorV3Interface _priceFeed, uint256 _currency)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./../interfaces/ITerminalUtility.sol";

abstract contract TerminalUtility is ITerminalUtility {
    modifier onlyTerminal(uint256 _projectId) {
        require(
            address(terminalDirectory.terminalOf(_projectId)) == msg.sender,
            "TerminalUtility: UNAUTHORIZED"
        );
        _;
    }

    /// @notice The direct deposit terminals.
    ITerminalDirectory public immutable override terminalDirectory;

    /** 
      @param _terminalDirectory A directory of a project's current Juicebox terminal to receive payments in.
    */
    constructor(ITerminalDirectory _terminalDirectory) {
        terminalDirectory = _terminalDirectory;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITerminal.sol";
import "./IOperatorStore.sol";

interface IProjects is IERC721 {
    event Create(
        uint256 indexed projectId,
        address indexed owner,
        bytes32 indexed handle,
        string uri,
        ITerminal terminal,
        address caller
    );

    event SetHandle(
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event SetUri(uint256 indexed projectId, string uri, address caller);

    event TransferHandle(
        uint256 indexed projectId,
        address indexed to,
        bytes32 indexed handle,
        bytes32 newHandle,
        address caller
    );

    event ClaimHandle(
        address indexed account,
        uint256 indexed projectId,
        bytes32 indexed handle,
        address caller
    );

    event ChallengeHandle(
        bytes32 indexed handle,
        uint256 challengeExpiry,
        address caller
    );

    event RenewHandle(
        bytes32 indexed handle,
        uint256 indexed projectId,
        address caller
    );

    function count() external view returns (uint256);

    function uriOf(uint256 _projectId) external view returns (string memory);

    function handleOf(uint256 _projectId) external returns (bytes32 handle);

    function projectFor(bytes32 _handle) external returns (uint256 projectId);

    function transferAddressFor(bytes32 _handle)
        external
        returns (address receiver);

    function challengeExpiryOf(bytes32 _handle) external returns (uint256);

    function exists(uint256 _projectId) external view returns (bool);

    function create(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        ITerminal _terminal
    ) external returns (uint256 id);

    function setHandle(uint256 _projectId, bytes32 _handle) external;

    function setUri(uint256 _projectId, string calldata _uri) external;

    function transferHandle(
        uint256 _projectId,
        address _to,
        bytes32 _newHandle
    ) external returns (bytes32 _handle);

    function claimHandle(
        bytes32 _handle,
        address _for,
        uint256 _projectId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalV1.sol";

enum BallotState {
    Approved,
    Active,
    Failed,
    Standby
}

interface IFundingCycleBallot {
    function duration() external view returns (uint256);

    function state(uint256 _fundingCycleId, uint256 _configured)
        external
        view
        returns (BallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

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
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";

interface ITerminal {
    event Pay(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        string note,
        address caller
    );

    event AddToBalance(
        uint256 indexed projectId,
        uint256 value,
        address caller
    );

    event AllowMigration(ITerminal allowed);

    event Migrate(
        uint256 indexed projectId,
        ITerminal indexed to,
        uint256 _amount,
        address caller
    );

    function terminalDirectory() external view returns (ITerminalDirectory);

    function migrationIsAllowed(ITerminal _terminal)
        external
        view
        returns (bool);

    function pay(
        uint256 _projectId,
        address _beneficiary,
        string calldata _memo,
        bool _preferUnstakedTickets
    ) external payable returns (uint256 fundingCycleId);

    function addToBalance(uint256 _projectId) external payable;

    function allowMigration(ITerminal _contract) external;

    function migrate(uint256 _projectId, ITerminal _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IOperatorStore {
    event SetOperator(
        address indexed operator,
        address indexed account,
        uint256 indexed domain,
        uint256[] permissionIndexes,
        uint256 packed
    );

    function permissionsOf(
        address _operator,
        address _account,
        uint256 _domain
    ) external view returns (uint256);

    function hasPermission(
        address _operator,
        address _account,
        uint256 _domain,
        uint256 _permissionIndex
    ) external view returns (bool);

    function hasPermissions(
        address _operator,
        address _account,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external view returns (bool);

    function setOperator(
        address _operator,
        uint256 _domain,
        uint256[] calldata _permissionIndexes
    ) external;

    function setOperators(
        address[] calldata _operators,
        uint256[] calldata _domains,
        uint256[][] calldata _permissionIndexes
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IDirectPaymentAddress.sol";
import "./ITerminal.sol";
import "./IProjects.sol";
import "./IProjects.sol";

interface ITerminalDirectory {
    event DeployAddress(
        uint256 indexed projectId,
        string memo,
        address indexed caller
    );

    event SetTerminal(
        uint256 indexed projectId,
        ITerminal indexed terminal,
        address caller
    );

    event SetPayerPreferences(
        address indexed account,
        address beneficiary,
        bool preferUnstakedTickets
    );

    function projects() external view returns (IProjects);

    function terminalOf(uint256 _projectId) external view returns (ITerminal);

    function beneficiaryOf(address _account) external returns (address);

    function unstakedTicketsPreferenceOf(address _account)
        external
        returns (bool);

    function addressesOf(uint256 _projectId)
        external
        view
        returns (IDirectPaymentAddress[] memory);

    function deployAddress(uint256 _projectId, string calldata _memo) external;

    function setTerminal(uint256 _projectId, ITerminal _terminal) external;

    function setPayerPreferences(
        address _beneficiary,
        bool _preferUnstakedTickets
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";
import "./ITerminal.sol";

interface IDirectPaymentAddress {
    event Forward(
        address indexed payer,
        uint256 indexed projectId,
        address beneficiary,
        uint256 value,
        string memo,
        bool preferUnstakedTickets
    );

    function terminalDirectory() external returns (ITerminalDirectory);

    function projectId() external returns (uint256);

    function memo() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ITicketBooth.sol";
import "./IFundingCycles.sol";
import "./IYielder.sol";
import "./IProjects.sol";
import "./IModStore.sol";
import "./ITerminal.sol";
import "./IOperatorStore.sol";
import "./IPrices.sol";

struct FundingCycleMetadata {
    uint256 reservedRate;
    uint256 bondingCurveRate;
    uint256 reconfigurationBondingCurveRate;
}

interface ITerminalV1 {
    event Configure(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address caller
    );

    event Tap(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        uint256 currency,
        uint256 netTransferAmount,
        uint256 beneficiaryTransferAmount,
        uint256 govFeeAmount,
        address caller
    );
    event Redeem(
        address indexed holder,
        address indexed beneficiary,
        uint256 indexed _projectId,
        uint256 amount,
        uint256 returnAmount,
        address caller
    );

    event PrintReserveTickets(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 count,
        uint256 beneficiaryTicketAmount,
        address caller
    );

    event DistributeToPayoutMod(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        PayoutMod mod,
        uint256 modCut,
        address caller
    );
    event DistributeToTicketMod(
        uint256 indexed fundingCycleId,
        uint256 indexed projectId,
        TicketMod mod,
        uint256 modCut,
        address caller
    );
    event AppointGovernance(address governance);

    event AcceptGovernance(address governance);

    event PrintPreminedTickets(
        uint256 indexed projectId,
        address indexed beneficiary,
        uint256 amount,
        uint256 currency,
        string memo,
        address caller
    );

    event Deposit(uint256 amount);

    event EnsureTargetLocalWei(uint256 target);

    event SetYielder(IYielder newYielder);

    event SetFee(uint256 _amount);

    event SetTargetLocalWei(uint256 amount);

    function governance() external view returns (address payable);

    function pendingGovernance() external view returns (address payable);

    function projects() external view returns (IProjects);

    function fundingCycles() external view returns (IFundingCycles);

    function ticketBooth() external view returns (ITicketBooth);

    function prices() external view returns (IPrices);

    function modStore() external view returns (IModStore);

    function reservedTicketBalanceOf(uint256 _projectId, uint256 _reservedRate)
        external
        view
        returns (uint256);

    function canPrintPreminedTickets(uint256 _projectId)
        external
        view
        returns (bool);

    function balanceOf(uint256 _projectId) external view returns (uint256);

    function currentOverflowOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function claimableOverflowOf(
        address _account,
        uint256 _amount,
        uint256 _projectId
    ) external view returns (uint256);

    function fee() external view returns (uint256);

    function deploy(
        address _owner,
        bytes32 _handle,
        string calldata _uri,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    ) external;

    function configure(
        uint256 _projectId,
        FundingCycleProperties calldata _properties,
        FundingCycleMetadata calldata _metadata,
        PayoutMod[] memory _payoutMods,
        TicketMod[] memory _ticketMods
    ) external returns (uint256);

    function printPreminedTickets(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        address _beneficiary,
        string memory _memo,
        bool _preferUnstakedTickets
    ) external;

    function tap(
        uint256 _projectId,
        uint256 _amount,
        uint256 _currency,
        uint256 _minReturnedWei
    ) external returns (uint256);

    function redeem(
        address _account,
        uint256 _projectId,
        uint256 _amount,
        uint256 _minReturnedWei,
        address payable _beneficiary,
        bool _preferUnstaked
    ) external returns (uint256 returnAmount);

    function printReservedTickets(uint256 _projectId)
        external
        returns (uint256 reservedTicketsToPrint);

    function setFee(uint256 _fee) external;

    function appointGovernance(address payable _pendingGovernance) external;

    function acceptGovernance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IProjects.sol";
import "./IOperatorStore.sol";
import "./ITickets.sol";

interface ITicketBooth {
    event Issue(
        uint256 indexed projectId,
        string name,
        string symbol,
        address caller
    );
    event Print(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        bool convertedTickets,
        bool preferUnstakedTickets,
        address controller
    );

    event Redeem(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        uint256 stakedTickets,
        bool preferUnstaked,
        address controller
    );

    event Stake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unstake(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Lock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Unlock(
        address indexed holder,
        uint256 indexed projectId,
        uint256 amount,
        address caller
    );

    event Transfer(
        address indexed holder,
        uint256 indexed projectId,
        address indexed recipient,
        uint256 amount,
        address caller
    );

    function ticketsOf(uint256 _projectId) external view returns (ITickets);

    function projects() external view returns (IProjects);

    function lockedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function lockedBalanceBy(
        address _operator,
        address _holder,
        uint256 _projectId
    ) external view returns (uint256);

    function stakedBalanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256);

    function stakedTotalSupplyOf(uint256 _projectId)
        external
        view
        returns (uint256);

    function totalSupplyOf(uint256 _projectId) external view returns (uint256);

    function balanceOf(address _holder, uint256 _projectId)
        external
        view
        returns (uint256 _result);

    function issue(
        uint256 _projectId,
        string calldata _name,
        string calldata _symbol
    ) external;

    function print(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstakedTickets
    ) external;

    function redeem(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        bool _preferUnstaked
    ) external;

    function stake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unstake(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function lock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function unlock(
        address _holder,
        uint256 _projectId,
        uint256 _amount
    ) external;

    function transfer(
        address _holder,
        uint256 _projectId,
        uint256 _amount,
        address _recipient
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ITerminalV1.sol";

// In constructure, give unlimited access for TerminalV1 to take money from this.
interface IYielder {
    function deposited() external view returns (uint256);

    function getCurrentBalance() external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 _amount, address payable _beneficiary) external;

    function withdrawAll(address payable _beneficiary)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IOperatorStore.sol";
import "./IProjects.sol";
import "./IModAllocator.sol";

struct PayoutMod {
    bool preferUnstaked;
    uint16 percent;
    uint48 lockedUntil;
    address payable beneficiary;
    IModAllocator allocator;
    uint56 projectId;
}

struct TicketMod {
    bool preferUnstaked;
    uint16 percent;
    uint48 lockedUntil;
    address payable beneficiary;
}

interface IModStore {
    event SetPayoutMod(
        uint256 indexed projectId,
        uint256 indexed configuration,
        PayoutMod mods,
        address caller
    );

    event SetTicketMod(
        uint256 indexed projectId,
        uint256 indexed configuration,
        TicketMod mods,
        address caller
    );

    function projects() external view returns (IProjects);

    function payoutModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        returns (PayoutMod[] memory);

    function ticketModsOf(uint256 _projectId, uint256 _configuration)
        external
        view
        returns (TicketMod[] memory);

    function setPayoutMods(
        uint256 _projectId,
        uint256 _configuration,
        PayoutMod[] memory _mods
    ) external;

    function setTicketMods(
        uint256 _projectId,
        uint256 _configuration,
        TicketMod[] memory _mods
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITickets is IERC20 {
    function print(address _account, uint256 _amount) external;

    function redeem(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
pragma solidity 0.8.6;

interface IModAllocator {
    event Allocate(
        uint256 indexed projectId,
        uint256 indexed forProjectId,
        address indexed beneficiary,
        uint256 amount,
        address caller
    );

    function allocate(
        uint256 _projectId,
        uint256 _forProjectId,
        address _beneficiary
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ITerminalDirectory.sol";

interface ITerminalUtility {
    function terminalDirectory() external view returns (ITerminalDirectory);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
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