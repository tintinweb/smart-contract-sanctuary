//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibUtils} from "../../libraries/RideLibUtils.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibFee} from "../../libraries/core/RideLibFee.sol";
import {RideLibPenalty} from "../../libraries/core/RideLibPenalty.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";
import {RideLibUser} from "../../libraries/core/RideLibUser.sol";
import {RideLibPassenger} from "../../libraries/core/RideLibPassenger.sol";
import {RideLibDriver} from "../../libraries/core/RideLibDriver.sol";

contract RidePassenger {
    event RequestTicket(
        bytes32 indexed tixId,
        address sender,
        uint256 baseFee,
        uint256 costPerMinute,
        uint256 costPerMetre,
        uint256 minutesTaken,
        uint256 metresTravelled
    );

    /**
     * requestTicket allows passenger to request for ride
     *
     * @param _badge badge rank requested
     * @param _strict whether driver must meet requested badge rank exactly (true) or default - any badge rank equal or greater than (false)
     * @param _metres estimated distance from origin to destination as determined by Maps API
     * @param _minutes estimated time taken from origin to destination as determined by Maps API
     *
     * @custom:event RequestTicket
     */
    function requestTicket(
        uint256 _badge,
        bool _strict,
        uint256 _metres,
        uint256 _minutes
    ) external {
        RideLibDriver.requireNotDriver();
        RideLibUser.requireNotActive();
        RideLibPenalty.requireNotBanned();

        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();
        RideLibUser.StorageUser storage s3 = RideLibUser._storageUser();

        uint256 fare = RideLibFee._getFare(
            s1.baseFee,
            _metres,
            _minutes,
            s1.badgeToCostPerMetre[_badge],
            s1.costPerMinute
        );
        require(
            s3.addressToDeposit[msg.sender] > fare,
            "passenger's deposit < fare"
        );

        bytes32 tixId = keccak256(abi.encode(msg.sender, block.timestamp));

        s2.tixIdToTicket[tixId].passenger = msg.sender;
        s2.tixIdToTicket[tixId].badge = _badge;
        s2.tixIdToTicket[tixId].strict = _strict;
        s2.tixIdToTicket[tixId].metres = _metres;
        s2.tixIdToTicket[tixId].fare = fare;

        s2.addressToTixId[msg.sender] = tixId;

        emit RequestTicket(
            tixId,
            msg.sender,
            s1.baseFee,
            s1.costPerMinute,
            s1.badgeToCostPerMetre[_badge],
            _minutes,
            _metres
        );
    }

    event RequestCancelled(bytes32 indexed tixId, address sender);

    /**
     * cancelRequest cancels ticket, can only be called before startTrip
     *
     * @custom:event RequestCancelled
     */
    function cancelRequest() external {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripNotStart();

        RideLibFee.StorageFee storage s1 = RideLibFee._storageFee();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        address driver = s2.tixIdToTicket[tixId].driver;
        if (driver != address(0)) {
            // case when cancel inbetween driver accepted, but haven't reach passenger
            // give warning at frontend to passenger
            RideLibUser._transfer(tixId, s1.requestFee, msg.sender, driver);
        }

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit RequestCancelled(tixId, msg.sender); // --> update frontend request pool
    }

    event TripStarted(bytes32 indexed tixId, address passenger, address driver);

    /**
     * startTrip starts the trip, can only be called once driver reached passenger
     *
     * @param _driver driver's address - get via QR scan?
     *
     * @custom:event TripStarted
     */
    function startTrip(address _driver) external {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibDriver.requireDrvMatchTixDrv(_driver);
        RideLibPassenger.requireTripNotStart();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        s1.addressToDriverReputation[_driver].countStart += 1;
        s2.tixIdToTicket[tixId].tripStart = true;
        s2.tixIdToTicket[tixId].forceEndTimestamp = block.timestamp + 1 days; // TODO: change 1 day to setter fn

        emit TripStarted(tixId, msg.sender, _driver); // update frontend
    }

    event TripEndedPax(bytes32 indexed tixId, address sender);

    /**
     * endTripPax ends the trip, can only be called once driver has called either endTripDrv
     *
     * @param _agree agreement from passenger that either destination has been reached or not
     * @param _rating refer _giveRating
     *
     * @custom:event TripEndedPax
     *
     * Driver would select destination reached or not, and event will emit to passenger's UI
     * then passenger would agree if this is true or false (via frontend UI), followed by a rating.
     * No matter what, passenger needs to pay fare, so incentive to passenger to be kind so driver
     * get passenger to destination. This prevents passenger abuse.
     */
    function endTripPax(bool _agree, uint256 _rating) external {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripInProgress();

        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.addressToTixId[msg.sender];
        address driver = s2.tixToDriverEnd[tixId].driver;
        require(driver != address(0), "driver must end trip");
        require(
            _agree,
            "pax must agree destination reached or not - indicated by driver"
        );

        RideLibUser._transfer(
            tixId,
            s2.tixIdToTicket[tixId].fare,
            msg.sender,
            driver
        );
        if (s2.tixToDriverEnd[tixId].reached) {
            s1.addressToDriverReputation[driver].metresTravelled += s2
                .tixIdToTicket[tixId]
                .metres;
            s1.addressToDriverReputation[driver].countEnd += 1;
        }

        RideLibPassenger._giveRating(driver, _rating);

        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit TripEndedPax(tixId, msg.sender);
    }

    event ForceEndPax(bytes32 indexed tixId, address sender);

    /**
     * forceEndPax can be called after tixIdToTicket[tixId].forceEndTimestamp duration
     * and if driver has NOT called endTripDrv
     *
     * @custom:event ForceEndPax
     *
     * no fare is paid, but driver is temporarily banned for banDuration
     */
    function forceEndPax() external {
        RideLibPassenger.requirePaxMatchTixPax();
        RideLibPassenger.requireTripInProgress(); /** means both parties still active */
        RideLibPassenger.requireForceEndAllowed();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.addressToTixId[msg.sender];
        require(
            s1.tixToDriverEnd[tixId].driver == address(0),
            "driver ended trip"
        ); // TODO: test
        address driver = s1.tixIdToTicket[tixId].driver;

        RideLibPenalty._temporaryBan(driver);
        RideLibPassenger._giveRating(driver, 1);
        RideLibTicket._cleanUp(tixId, msg.sender, driver);

        emit ForceEndPax(tixId, msg.sender);
    }

    /**
     * setRatingBounds sets bounds for rating
     *
     * @param _min | unitless integer
     * @param _max | unitless integer
     */
    function setRatingBounds(uint256 _min, uint256 _max) public {
        RideLibUtils.enforceIsContractOwner();
        RideLibPassenger.StoragePassenger storage s1 = RideLibPassenger
            ._storagePassenger();
        s1.rating_min = _min;
        s1.rating_max = _max;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {IRideCut} from "../interfaces/IRideCut.sol";

library RideLibUtils {
    bytes32 constant RIDE_UTILS_STORAGE_POSITION =
        keccak256("diamond.standard.ride.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct RideUtilsStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function rideUtilsStorage()
        internal
        pure
        returns (RideUtilsStorage storage rus)
    {
        bytes32 position = RIDE_UTILS_STORAGE_POSITION;
        assembly {
            rus.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        RideUtilsStorage storage rus = rideUtilsStorage();
        address previousOwner = rus.contractOwner;
        rus.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = rideUtilsStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == rideUtilsStorage().contractOwner,
            "RideUtilsStorage: Must be contract owner"
        );
    }

    event RideCut(IRideCut.FacetCut[] _rideCut, address _init, bytes _calldata);

    // Internal function version of rideCut
    function rideCut(
        IRideCut.FacetCut[] memory _rideCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _rideCut.length; facetIndex++) {
            IRideCut.FacetCutAction action = _rideCut[facetIndex].action;
            if (action == IRideCut.FacetCutAction.Add) {
                addFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else if (action == IRideCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else if (action == IRideCut.FacetCutAction.Remove) {
                removeFunctions(
                    _rideCut[facetIndex].facetAddress,
                    _rideCut[facetIndex].functionSelectors
                );
            } else {
                revert("RideLibUtilsCut: Incorrect FacetCutAction");
            }
        }
        emit RideCut(_rideCut, _init, _calldata);
        initializeRideCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            rus.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(rus, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "RideLibUtilsCut: Can't add function that already exists"
            );
            addFunction(rus, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            rus.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(rus, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "RideLibUtilsCut: Can't replace function with same function"
            );
            removeFunction(rus, oldFacetAddress, selector);
            addFunction(rus, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "RideLibUtilsCut: No selectors in facet to cut"
        );
        RideUtilsStorage storage rus = rideUtilsStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "RideLibUtilsCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = rus
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(rus, oldFacetAddress, selector);
        }
    }

    function addFacet(RideUtilsStorage storage rus, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "RideLibUtilsCut: New facet has no code"
        );
        rus.facetFunctionSelectors[_facetAddress].facetAddressPosition = rus
            .facetAddresses
            .length;
        rus.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        RideUtilsStorage storage rus,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        rus
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        rus.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        rus.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        RideUtilsStorage storage rus,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "RideLibUtilsCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "RideLibUtilsCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = rus
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = rus
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = rus
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            rus.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            rus
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        rus.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete rus.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = rus.facetAddresses.length - 1;
            uint256 facetAddressPosition = rus
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = rus.facetAddresses[
                    lastFacetAddressPosition
                ];
                rus.facetAddresses[facetAddressPosition] = lastFacetAddress;
                rus
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            rus.facetAddresses.pop();
            delete rus
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeRideCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "RideLibUtilsCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "RideLibUtilsCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "RideLibUtilsCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("RideLibUtilsCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideBadge} from "../../facets/core/RideBadge.sol";

library RideLibBadge {
    bytes32 constant STORAGE_POSITION_BADGE = keccak256("ds.badge");

    /**
     * lifetime cumulative values of drivers
     */
    struct DriverReputation {
        uint256 id;
        string uri;
        uint256 maxMetresPerTrip;
        uint256 metresTravelled;
        uint256 countStart;
        uint256 countEnd;
        uint256 totalRating;
        uint256 countRating;
    }

    struct StorageBadge {
        mapping(uint256 => uint256) badgeToBadgeMaxScore;
        mapping(uint256 => bool) insertedMaxScore;
        uint256[] badges;
        mapping(address => DriverReputation) addressToDriverReputation;
    }

    function _storageBadge() internal pure returns (StorageBadge storage s) {
        bytes32 position = STORAGE_POSITION_BADGE;
        assembly {
            s.slot := position
        }
    }

    /**
     * _getBadgesCount returns number of recognized badges
     *
     * @return badges count
     */
    function _getBadgesCount() internal pure returns (uint256) {
        return uint256(RideBadge.Badges.Veteran) + 1;
    }

    /**
     * _getBadge returns the badge rank for given score
     *
     * @param _score | unitless integer
     *
     * @return badge rank
     */
    function _getBadge(uint256 _score) internal view returns (uint256) {
        StorageBadge storage s1 = _storageBadge();

        for (uint256 i = 0; i < s1.badges.length; i++) {
            require(
                s1.badgeToBadgeMaxScore[s1.badges[i]] > 0,
                "zero badge score bounds"
            );
        }

        if (_score <= s1.badgeToBadgeMaxScore[0]) {
            return uint256(RideBadge.Badges.Newbie);
        } else if (
            _score > s1.badgeToBadgeMaxScore[0] &&
            _score <= s1.badgeToBadgeMaxScore[1]
        ) {
            return uint256(RideBadge.Badges.Bronze);
        } else if (
            _score > s1.badgeToBadgeMaxScore[1] &&
            _score <= s1.badgeToBadgeMaxScore[2]
        ) {
            return uint256(RideBadge.Badges.Silver);
        } else if (
            _score > s1.badgeToBadgeMaxScore[2] &&
            _score <= s1.badgeToBadgeMaxScore[3]
        ) {
            return uint256(RideBadge.Badges.Gold);
        } else if (
            _score > s1.badgeToBadgeMaxScore[3] &&
            _score <= s1.badgeToBadgeMaxScore[4]
        ) {
            return uint256(RideBadge.Badges.Platinum);
        } else {
            return uint256(RideBadge.Badges.Veteran);
        }
    }

    /**
     * _calculateScore calculates score from driver's reputation details (see params of function)
     *
     * @param _metresTravelled | unit in metre
     * @param _countStart      | unitless integer
     * @param _countEnd        | unitless integer
     * @param _totalRating     | unitless integer
     * @param _countRating     | unitless integer
     * @param _maxRating       | unitless integer
     *
     * @return Driver's score to determine badge rank | unitless integer
     *
     * Derive Driver's Score Formula:-
     *
     * Score is fundamentally determined based on distance travelled, where the more trips a driver makes,
     * the higher the score. Thus, the base score is directly proportional to:
     *
     * _metresTravelled
     *
     * where _metresTravelled is the total cumulative distance covered by the driver over all trips made.
     *
     * To encourage the completion of trips, the base score would be penalized by the amount of incomplete
     * trips, using:
     *
     *  _countEnd / _countStart
     *
     * which is the ratio of number of trips complete to the number of trips started. This gives:
     *
     * _metresTravelled * (_countEnd / _countStart)
     *
     * Driver score should also be influenced by passenger's rating of the overall trip, thus, the base
     * score is further penalized by the average driver rating over all trips, given by:
     *
     * _totalRating / _countRating
     *
     * where _totalRating is the cumulative rating value by passengers over all trips and _countRating is
     * the total number of rates by those passengers. The rating penalization is also divided by the max
     * possible rating score to make the penalization a ratio:
     *
     * (_totalRating / _countRating) / _maxRating
     *
     * The score formula is given by:
     *
     * _metresTravelled * (_countEnd / _countStart) * ((_totalRating / _countRating) / _maxRating)
     *
     * which simplifies to:
     *
     * (_metresTravelled * _countEnd * _totalRating) / (_countStart * _countRating * _maxRating)
     *
     * note: Solidity rounds down return value to the nearest whole number.
     *
     * note: Score is used to determine badge rank. To determine which score corresponds to which rank,
     *       can just determine from _metresTravelled, as other variables are just penalization factors.
     */
    function _calculateScore(
        uint256 _metresTravelled,
        uint256 _countStart,
        uint256 _countEnd,
        uint256 _totalRating,
        uint256 _countRating,
        uint256 _maxRating
    ) internal pure returns (uint256) {
        if (_countStart == 0) {
            return 0;
        } else {
            return
                (_metresTravelled * _countEnd * _totalRating) /
                (_countStart * _countRating * _maxRating);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibFee {
    bytes32 constant STORAGE_POSITION_FEE = keccak256("ds.fee");

    struct StorageFee {
        uint256 requestFee;
        uint256 baseFee;
        uint256 costPerMinute;
        mapping(uint256 => uint256) badgeToCostPerMetre;
    }

    function _storageFee() internal pure returns (StorageFee storage s) {
        bytes32 position = STORAGE_POSITION_FEE;
        assembly {
            s.slot := position
        }
    }

    // event FareBreakdown(
    //     uint256 baseFee,
    //     uint256 costPerMinute,
    //     uint256 costPerMetre,
    //     uint256 minutesTaken,
    //     uint256 metresTravelled
    // );

    /**
     * _getFare calculates the fare of a trip.
     *
     * @param _baseFee        | unit in token
     * @param _metresTravelled | unit in metre
     * @param _minutesTaken    | unit in minute
     * @param _costPerMetre    | unit in token
     * @param _costPerMinute   | unit in token
     *
     * @return Fare | unit in token
     *
     * _metresTravelled and _minutesTaken are rounded down,
     * for example, if _minutesTaken is 1.5 minutes (90 seconds) then round to 1 minute
     * if _minutesTaken is 0.5 minutes (30 seconds) then round to 0 minute
     */
    function _getFare(
        uint256 _baseFee,
        uint256 _metresTravelled,
        uint256 _minutesTaken,
        uint256 _costPerMetre,
        uint256 _costPerMinute
    ) internal pure returns (uint256) {
        // emit FareBreakdown(
        //     _baseFee,
        //     _costPerMinute,
        //     _costPerMetre,
        //     _minutesTaken,
        //     _metresTravelled
        // ); // if put event emitter then modifies state so cannot be pure/view function

        return (_baseFee +
            (_metresTravelled * _costPerMetre) +
            (_minutesTaken * _costPerMinute));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibPenalty {
    bytes32 constant STORAGE_POSITION_PENALTY = keccak256("ds.penalty");

    struct StoragePenalty {
        uint256 banDuration;
        mapping(address => uint256) addressToBanEndTimestamp;
    }

    function _storagePenalty()
        internal
        pure
        returns (StoragePenalty storage s)
    {
        bytes32 position = STORAGE_POSITION_PENALTY;
        assembly {
            s.slot := position
        }
    }

    function requireNotBanned() internal view {
        StoragePenalty storage s1 = _storagePenalty();
        require(
            block.timestamp >= s1.addressToBanEndTimestamp[msg.sender],
            "still banned"
        );
    }

    event UserBanned(address banned, uint256 until);

    /**
     * _temporaryBan user
     *
     * @param _address address to be banned
     *
     * @custom:event UserBanned
     */
    function _temporaryBan(address _address) internal {
        StoragePenalty storage s1 = _storagePenalty();
        uint256 banUntil = block.timestamp + s1.banDuration;
        s1.addressToBanEndTimestamp[_address] = banUntil;

        emit UserBanned(_address, banUntil);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibTicket {
    bytes32 constant STORAGE_POSITION_TICKET = keccak256("ds.ticket");

    /**
     * @dev if a ticket exists (details not 0) in tixIdToTicket, then it is considered active
     *
     * @custom:TODO: Make it loopable so that can list to drivers?
     */
    struct Ticket {
        address passenger;
        address driver;
        uint256 badge;
        bool strict;
        uint256 metres;
        uint256 fare;
        bool tripStart;
        uint256 forceEndTimestamp;
    }

    /**
     * *Required to confirm if driver did initiate destination reached or not
     */
    struct DriverEnd {
        address driver;
        bool reached;
    }

    struct StorageTicket {
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(address => bytes32) addressToTixId;
        mapping(bytes32 => DriverEnd) tixToDriverEnd;
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    event TicketCleared(bytes32 indexed tixId);

    /**
     * _cleanUp clears ticket information and set active status of users to false
     *
     * @param _tixId Ticket ID
     * @param _passenger passenger's address
     * @param _driver driver's address
     *
     * @custom:event TicketCleared
     */
    function _cleanUp(
        bytes32 _tixId,
        address _passenger,
        address _driver
    ) internal {
        StorageTicket storage s1 = _storageTicket();
        delete s1.tixIdToTicket[_tixId];
        delete s1.tixToDriverEnd[_tixId];
        delete s1.addressToTixId[_passenger];
        delete s1.addressToTixId[_driver];

        emit TicketCleared(_tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibUser {
    bytes32 constant STORAGE_POSITION_USER = keccak256("ds.user");

    struct StorageUser {
        ERC20 token;
        mapping(address => uint256) addressToDeposit;
    }

    function _storageUser() internal pure returns (StorageUser storage s) {
        bytes32 position = STORAGE_POSITION_USER;
        assembly {
            s.slot := position
        }
    }

    function requireNotActive() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(s1.addressToTixId[msg.sender] == 0, "caller is active");
    }

    event TokensTransferred(
        bytes32 indexed tixId,
        uint256 amount,
        address decrease,
        address increase
    );

    /**
     * _transfer rebalances _amount tokens from one address to another
     *
     * @param _tixId Ticket ID
     * @param _amount | unit in token
     * @param _decrease address to decrease tokens by
     * @param _increase address to increase tokens by
     *
     * @custom:event TokensTransferred
     */
    function _transfer(
        bytes32 _tixId,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageUser storage s1 = _storageUser();

        s1.addressToDeposit[_decrease] -= _amount;
        s1.addressToDeposit[_increase] += _amount;

        emit TokensTransferred(_tixId, _amount, _decrease, _increase);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibPassenger {
    bytes32 constant STORAGE_POSITION_PASSENGER = keccak256("ds.passenger");

    struct StoragePassenger {
        uint256 rating_min;
        uint256 rating_max;
    }

    function _storagePassenger()
        internal
        pure
        returns (StoragePassenger storage s)
    {
        bytes32 position = STORAGE_POSITION_PASSENGER;
        assembly {
            s.slot := position
        }
    }

    function requirePaxMatchTixPax() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            msg.sender ==
                s1.tixIdToTicket[s1.addressToTixId[msg.sender]].passenger,
            "pax not match tix pax"
        );
    }

    function requireTripNotStart() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            !s1.tixIdToTicket[s1.addressToTixId[msg.sender]].tripStart,
            "trip already started"
        );
    }

    function requireTripInProgress() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            s1.tixIdToTicket[s1.addressToTixId[msg.sender]].tripStart,
            "trip not started"
        );
    }

    function requireForceEndAllowed() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            block.timestamp >
                s1
                    .tixIdToTicket[s1.addressToTixId[msg.sender]]
                    .forceEndTimestamp,
            "too early"
        );
    }

    /**
     * _giveRating
     *
     * @param _driver driver's address
     * @param _rating unitless integer between RATING_MIN and RATING_MAX
     *
     * @custom:event TripStarted
     */
    function _giveRating(address _driver, uint256 _rating) internal {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        StoragePassenger storage s2 = _storagePassenger();

        require(s2.rating_min > 0, "minimum rating must be more than zero");
        require(s2.rating_max > 0, "maximum rating must be more than zero");
        require(
            _rating >= s2.rating_min && _rating <= s2.rating_max,
            "rating must be within min and max ratings (inclusive)"
        );

        s1.addressToDriverReputation[_driver].totalRating += _rating;
        s1.addressToDriverReputation[_driver].countRating += 1;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibDriver {
    function requireDrvMatchTixDrv(address _driver) internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            _driver == s1.tixIdToTicket[s1.addressToTixId[msg.sender]].driver,
            "drv not match tix drv"
        );
    }

    function requireIsDriver() internal view {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        require(
            s1.addressToDriverReputation[msg.sender].id != 0,
            "caller not driver"
        );
    }

    function requireNotDriver() internal view {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        require(
            s1.addressToDriverReputation[msg.sender].id == 0,
            "caller is driver"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _rideCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function rideCut(
        FacetCut[] calldata _rideCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event RideCut(FacetCut[] _rideCut, address _init, bytes _calldata);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibUtils} from "../../libraries/RideLibUtils.sol";

/// @title Badge rank for drivers
contract RideBadge {
    enum Badges {
        Newbie,
        Bronze,
        Silver,
        Gold,
        Platinum,
        Veteran
    } // note: if we edit last badge, rmb edit RideLibBadge._getBadgesCount fn as well

    event SetBadgesMaxScores(uint256[] scores, address sender);

    /**
     * TODO:
     * Check if setBadgesMaxScores is used in other contracts after
     * diamond pattern finalized. if no use then change visibility
     * to external
     */
    /**
     * setBadgesMaxScores maps score to badge
     *
     * @param _badgesMaxScores Score that defines a specific badge rank
     */
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores) public {
        RideLibUtils.enforceIsContractOwner();
        require(
            _badgesMaxScores.length == RideLibBadge._getBadgesCount() - 1,
            "_badgesMaxScores.length must be 1 less than Badges"
        );
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        for (uint256 i = 0; i < _badgesMaxScores.length; i++) {
            s1.badgeToBadgeMaxScore[i] = _badgesMaxScores[i];

            if (!s1.insertedMaxScore[i]) {
                s1.insertedMaxScore[i] = true;
                s1.badges.push(i);
            }
        }

        emit SetBadgesMaxScores(_badgesMaxScores, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}