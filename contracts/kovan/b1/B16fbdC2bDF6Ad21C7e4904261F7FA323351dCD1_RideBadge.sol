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