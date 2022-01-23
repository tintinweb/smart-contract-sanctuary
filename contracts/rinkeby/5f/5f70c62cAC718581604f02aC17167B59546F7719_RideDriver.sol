//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibFee} from "../../libraries/core/RideLibFee.sol";
import {RideLibPenalty} from "../../libraries/core/RideLibPenalty.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";
import {RideLibHolding} from "../../libraries/core/RideLibHolding.sol";
import {RideLibPassenger} from "../../libraries/core/RideLibPassenger.sol";
import {RideLibDriver} from "../../libraries/core/RideLibDriver.sol";

import {RideLibExchange} from "../../libraries/core/RideLibExchange.sol";

import {IRideDriver} from "../../interfaces/core/IRideDriver.sol";

contract RideDriver is IRideDriver {
    /**
     * acceptTicket allows driver to accept passenger's ticket request
     *
     * @param _tixId Ticket ID
     * @param _useBadge allows driver to use any badge rank equal to or lower than current rank 
     (this is to give driver the option of lower cosr per metre rates)
     *
     * @custom:event AcceptedTicket
     *
     * higher badge can charge higher price, but what if passenger always choose lower price?
     * (badgeToCostPerMetre[_badge], at RidePassenger.sol) then higher badge driver wont get chosen at all
     * solution: _useBadge that allows driver to choose which badge rank they want to use up to achieved badge rank
     * at frontend, default _useBadge to driver's current badge rank
     */
    function acceptTicket(
        bytes32 _keyLocal,
        bytes32 _keyAccept,
        bytes32 _tixId,
        uint256 _useBadge
    ) external override {
        RideLibDriver._requireIsDriver();
        RideLibTicket._requireNotActive();
        RideLibPenalty._requireNotBanned();
        RideLibExchange._requireXPerYPriceFeedSupported(_keyLocal, _keyAccept);

        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        require(
            s2.tixIdToTicket[_tixId].passenger != address(0),
            "ticket not exists"
        );
        require(
            s2.tixIdToTicket[_tixId].keyLocal == _keyLocal,
            "local currency key not match"
        );
        require(
            s2.tixIdToTicket[_tixId].keyPay == _keyAccept,
            "payment currency key not match"
        );

        uint256 driverScore = RideLibBadge._calculateScore();
        uint256 driverBadge = RideLibBadge._getBadge(driverScore);
        require(_useBadge <= driverBadge, "badge rank not achieved");

        uint256 holdingAmount = RideLibHolding
            ._storageHolding()
            .userToCurrencyKeyToHolding[msg.sender][_keyAccept];
        require(
            (holdingAmount > s2.tixIdToTicket[_tixId].requestFee) &&
                (holdingAmount > s2.tixIdToTicket[_tixId].fare),
            "driver's holding < requestFee or fare"
        );

        require(
            s2.tixIdToTicket[_tixId].metres <=
                RideLibBadge
                    ._storageBadge()
                    .driverToDriverReputation[msg.sender]
                    .maxMetresPerTrip,
            "trip too long"
        );
        if (s2.tixIdToTicket[_tixId].strict) {
            require(
                _useBadge == s2.tixIdToTicket[_tixId].badge,
                "driver not meet badge - strict"
            );
        } else {
            require(
                _useBadge >= s2.tixIdToTicket[_tixId].badge,
                "driver not meet badge"
            );
        }

        s2.tixIdToTicket[_tixId].driver = msg.sender;
        s2.userToTixId[msg.sender] = _tixId;

        emit AcceptedTicket(msg.sender, _tixId); // --> update frontend (also, add warning that if passenger cancel, will incure fee)
    }

    /**
     * cancelPickUp cancels pick up, can only be called before startTrip
     *
     * @custom:event DriverCancelled
     */
    function cancelPickUp() external override {
        RideLibDriver._requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger._requireTripNotStart();

        RideLibTicket.StorageTicket storage s2 = RideLibTicket._storageTicket();

        bytes32 tixId = s2.userToTixId[msg.sender];
        address passenger = s2.tixIdToTicket[tixId].passenger;

        RideLibHolding._transferCurrency(
            tixId,
            s2.tixIdToTicket[tixId].keyPay,
            s2.tixIdToTicket[tixId].requestFee,
            msg.sender,
            passenger
        );

        RideLibTicket._cleanUp(tixId, passenger, msg.sender);

        emit DriverCancelled(msg.sender, tixId); // --> update frontend
    }

    /**
     * endTripDrv allows driver to indicate to passenger to end trip and destination is either reached or not
     *
     * @param _reached boolean indicating whether destination has been reach or not
     *
     * @custom:event TripEndedDrv
     */
    // TODO: test that this fn can be recalled immediately after first call so that driver can change _reached status if needed. Test in remix first.
    function endTripDrv(bool _reached) external override {
        RideLibDriver._requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger._requireTripInProgress();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.userToTixId[msg.sender];
        // tixToDriverEnd[tixId] = DriverEnd({driver: msg.sender, reached: true}); // takes up more space
        s1.tixToDriverEnd[tixId].driver = msg.sender;
        s1.tixToDriverEnd[tixId].reached = _reached;

        emit TripEndedDrv(msg.sender, tixId, _reached);
    }

    /**
     * forceEndDrv can be called after tixIdToTicket[tixId].forceEndTimestamp duration
     * and if passenger has not called endTripPax
     *
     * @custom:event ForceEndDrv
     *
     * no fare is paid, but passenger is temporarily banned for banDuration
     */
    function forceEndDrv() external override {
        RideLibDriver._requireDrvMatchTixDrv(msg.sender);
        RideLibPassenger._requireTripInProgress(); /** means both parties still active */
        RideLibPassenger._requireForceEndAllowed();

        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();

        bytes32 tixId = s1.userToTixId[msg.sender];
        require(
            s1.tixToDriverEnd[tixId].driver != address(0),
            "driver must end trip"
        ); // TODO: test
        address passenger = s1.tixIdToTicket[tixId].passenger;

        RideLibPenalty._temporaryBan(passenger);
        RideLibTicket._cleanUp(tixId, passenger, msg.sender);

        emit ForceEndDrv(msg.sender, tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideBadge} from "../../facets/core/RideBadge.sol";
import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibRater} from "../../libraries/core/RideLibRater.sol";

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
        mapping(uint256 => bool) _insertedMaxScore;
        uint256[] _badges;
        mapping(address => DriverReputation) driverToDriverReputation;
    }

    function _storageBadge() internal pure returns (StorageBadge storage s) {
        bytes32 position = STORAGE_POSITION_BADGE;
        assembly {
            s.slot := position
        }
    }

    event SetBadgesMaxScores(address indexed sender, uint256[] scores);

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
    function _setBadgesMaxScores(uint256[] memory _badgesMaxScores) internal {
        RideLibOwnership._requireIsContractOwner();
        require(
            _badgesMaxScores.length == _getBadgesCount() - 1,
            "_badgesMaxScores.length must be 1 less than Badges"
        );
        StorageBadge storage s1 = _storageBadge();
        for (uint256 i = 0; i < _badgesMaxScores.length; i++) {
            s1.badgeToBadgeMaxScore[i] = _badgesMaxScores[i];

            if (!s1._insertedMaxScore[i]) {
                s1._insertedMaxScore[i] = true;
                s1._badges.push(i);
            }
        }

        emit SetBadgesMaxScores(msg.sender, _badgesMaxScores);
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

        for (uint256 i = 0; i < s1._badges.length; i++) {
            require(
                s1.badgeToBadgeMaxScore[s1._badges[i]] > 0,
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
    function _calculateScore() internal view returns (uint256) {
        StorageBadge storage s1 = _storageBadge();

        uint256 metresTravelled = s1
            .driverToDriverReputation[msg.sender]
            .metresTravelled;
        uint256 countStart = s1.driverToDriverReputation[msg.sender].countStart;
        uint256 countEnd = s1.driverToDriverReputation[msg.sender].countEnd;
        uint256 totalRating = s1
            .driverToDriverReputation[msg.sender]
            .totalRating;
        uint256 countRating = s1
            .driverToDriverReputation[msg.sender]
            .countRating;
        uint256 maxRating = RideLibRater._storageRater().ratingMax;

        if (countStart == 0) {
            return 0;
        } else {
            return
                (metresTravelled * countEnd * totalRating) /
                (countStart * countRating * maxRating);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";

library RideLibFee {
    bytes32 constant STORAGE_POSITION_FEE = keccak256("ds.fee");

    struct StorageFee {
        mapping(bytes32 => uint256) currencyKeyToRequestFee;
        mapping(bytes32 => uint256) currencyKeyToBaseFee;
        mapping(bytes32 => uint256) currencyKeyToCostPerMinute;
        mapping(bytes32 => mapping(uint256 => uint256)) currencyKeyToBadgeToCostPerMetre;
    }

    function _storageFee() internal pure returns (StorageFee storage s) {
        bytes32 position = STORAGE_POSITION_FEE;
        assembly {
            s.slot := position
        }
    }

    event FeeSetRequest(address indexed sender, uint256 fee);

    /**
     * _setRequestFee sets request fee
     *
     * @param _key        | currency key
     * @param _requestFee | unit in Wei
     */
    function _setRequestFee(bytes32 _key, uint256 _requestFee) internal {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToRequestFee[_key] = _requestFee; // input format: token in Wei

        emit FeeSetRequest(msg.sender, _requestFee);
    }

    event FeeSetBase(address indexed sender, uint256 fee);

    /**
     * _setBaseFee sets base fee
     *
     * @param _key     | currency key
     * @param _baseFee | unit in Wei
     */
    function _setBaseFee(bytes32 _key, uint256 _baseFee) internal {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToBaseFee[_key] = _baseFee; // input format: token in Wei

        emit FeeSetBase(msg.sender, _baseFee);
    }

    event FeeSetCostPerMinute(address indexed sender, uint256 fee);

    /**
     * _setCostPerMinute sets cost per minute
     *
     * @param _key           | currency key
     * @param _costPerMinute | unit in Wei
     */
    function _setCostPerMinute(bytes32 _key, uint256 _costPerMinute) internal {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        _storageFee().currencyKeyToCostPerMinute[_key] = _costPerMinute; // input format: token in Wei

        emit FeeSetCostPerMinute(msg.sender, _costPerMinute);
    }

    event FeeSetCostPerMetre(address indexed sender, uint256[] fee);

    /**
     * _setCostPerMetre sets cost per metre
     *
     * @param _key          | currency key
     * @param _costPerMetre | unit in Wei
     */
    function _setCostPerMetre(bytes32 _key, uint256[] memory _costPerMetre)
        internal
    {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        require(
            _costPerMetre.length == RideLibBadge._getBadgesCount(),
            "_costPerMetre.length must be equal Badges"
        );
        for (uint256 i = 0; i < _costPerMetre.length; i++) {
            _storageFee().currencyKeyToBadgeToCostPerMetre[_key][
                    i
                ] = _costPerMetre[i]; // input format: token in Wei // rounded down
        }

        emit FeeSetCostPerMetre(msg.sender, _costPerMetre);
    }

    /**
     * _getFare calculates the fare of a trip.
     *
     * @param _key             | currency key
     * @param _badge           | badge
     * @param _metresTravelled | unit in metre
     * @param _minutesTaken    | unit in minute
     *
     * @return Fare | unit in Wei
     *
     * _metresTravelled and _minutesTaken are rounded down,
     * for example, if _minutesTaken is 1.5 minutes (90 seconds) then round to 1 minute
     * if _minutesTaken is 0.5 minutes (30 seconds) then round to 0 minute
     */
    function _getFare(
        bytes32 _key,
        uint256 _badge,
        uint256 _minutesTaken,
        uint256 _metresTravelled
    ) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        StorageFee storage s1 = _storageFee();

        uint256 baseFee = s1.currencyKeyToBaseFee[_key];
        uint256 costPerMinute = s1.currencyKeyToCostPerMinute[_key];
        uint256 costPerMetre = s1.currencyKeyToBadgeToCostPerMetre[_key][
            _badge
        ];

        return (baseFee +
            (costPerMinute * _minutesTaken) +
            (costPerMetre * _metresTravelled));
    }

    function _getRequestFee(bytes32 _key) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return _storageFee().currencyKeyToRequestFee[_key];
    }

    // function _getBaseFee(bytes32 _key) internal view returns (uint256) {
    //     RideLibCurrencyRegistry._requireCurrencySupported(_key);
    //     return _storageFee().currencyKeyToBaseFee[_key];
    // }

    // function _getCostPerMinute(bytes32 _key) internal view returns (uint256) {
    //     RideLibCurrencyRegistry._requireCurrencySupported(_key);
    //     return _storageFee().currencyKeyToCostPerMinute[_key];
    // }

    // function _getCostPerMetre(bytes32 _key, uint256 _badge)
    //     internal
    //     view
    //     returns (uint256)
    // {
    //     RideLibCurrencyRegistry._requireCurrencySupported(_key);
    //     return _storageFee().currencyKeyToBadgeToCostPerMetre[_key][_badge];
    // }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

library RideLibPenalty {
    bytes32 constant STORAGE_POSITION_PENALTY = keccak256("ds.penalty");

    struct StoragePenalty {
        uint256 banDuration;
        mapping(address => uint256) userToBanEndTimestamp;
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

    function _requireNotBanned() internal view {
        require(
            block.timestamp >=
                _storagePenalty().userToBanEndTimestamp[msg.sender],
            "still banned"
        );
    }

    event SetBanDuration(address indexed sender, uint256 _banDuration);

    /**
     * setBanDuration sets user ban duration
     *
     * @param _banDuration | unit in unix timestamp | https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html#time-units
     */
    function _setBanDuration(uint256 _banDuration) internal {
        RideLibOwnership._requireIsContractOwner();
        _storagePenalty().banDuration = _banDuration;

        emit SetBanDuration(msg.sender, _banDuration);
    }

    event UserBanned(address indexed user, uint256 from, uint256 to);

    /**
     * _temporaryBan user
     *
     * @param _user address to be banned
     *
     * @custom:event UserBanned
     */
    function _temporaryBan(address _user) internal {
        StoragePenalty storage s1 = _storagePenalty();
        uint256 banUntil = block.timestamp + s1.banDuration;
        s1.userToBanEndTimestamp[_user] = banUntil;

        emit UserBanned(_user, block.timestamp, banUntil);
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
        bytes32 keyLocal;
        bytes32 keyPay;
        uint256 requestFee;
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
        mapping(address => bytes32) userToTixId;
        mapping(bytes32 => Ticket) tixIdToTicket;
        mapping(bytes32 => DriverEnd) tixToDriverEnd;
    }

    function _storageTicket() internal pure returns (StorageTicket storage s) {
        bytes32 position = STORAGE_POSITION_TICKET;
        assembly {
            s.slot := position
        }
    }

    function _requireNotActive() internal view {
        require(
            _storageTicket().userToTixId[msg.sender] == 0,
            "caller is active"
        );
    }

    event TicketCleared(address indexed sender, bytes32 indexed tixId);

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
        delete s1.userToTixId[_passenger];
        delete s1.userToTixId[_driver];

        emit TicketCleared(msg.sender, _tixId);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";

library RideLibHolding {
    bytes32 constant STORAGE_POSITION_HOLDING = keccak256("ds.holding");

    struct StorageHolding {
        mapping(address => mapping(bytes32 => uint256)) userToCurrencyKeyToHolding;
    }

    function _storageHolding()
        internal
        pure
        returns (StorageHolding storage s)
    {
        bytes32 position = STORAGE_POSITION_HOLDING;
        assembly {
            s.slot := position
        }
    }

    event CurrencyTransferred(
        address indexed decrease,
        bytes32 indexed tixId,
        address increase,
        bytes32 key,
        uint256 amount
    );

    /**
     * _transfer rebalances _amount tokens from one address to another
     *
     * @param _tixId Ticket ID
     * @param _key currency key
     * @param _amount | unit in token
     * @param _decrease address to decrease tokens by
     * @param _increase address to increase tokens by
     *
     * @custom:event CurrencyTransferred
     *
     * not use msg.sender instead of _decrease param? in case admin is required to sort things out
     */
    function _transferCurrency(
        bytes32 _tixId,
        bytes32 _key,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        StorageHolding storage s1 = _storageHolding();

        s1.userToCurrencyKeyToHolding[_decrease][_key] -= _amount;
        s1.userToCurrencyKeyToHolding[_increase][_key] += _amount;

        emit CurrencyTransferred(_decrease, _tixId, _increase, _key, _amount); // note decrease is sender
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibPassenger {
    function _requirePaxMatchTixPax() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            msg.sender ==
                s1.tixIdToTicket[s1.userToTixId[msg.sender]].passenger,
            "pax not match tix pax"
        );
    }

    function _requireTripNotStart() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            !s1.tixIdToTicket[s1.userToTixId[msg.sender]].tripStart,
            "trip already started"
        );
    }

    function _requireTripInProgress() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            s1.tixIdToTicket[s1.userToTixId[msg.sender]].tripStart,
            "trip not started"
        );
    }

    function _requireForceEndAllowed() internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            block.timestamp >
                s1.tixIdToTicket[s1.userToTixId[msg.sender]].forceEndTimestamp,
            "too early"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";
import {RideLibTicket} from "../../libraries/core/RideLibTicket.sol";

library RideLibDriver {
    function _requireDrvMatchTixDrv(address _driver) internal view {
        RideLibTicket.StorageTicket storage s1 = RideLibTicket._storageTicket();
        require(
            _driver == s1.tixIdToTicket[s1.userToTixId[msg.sender]].driver,
            "drv not match tix drv"
        );
    }

    function _requireIsDriver() internal view {
        require(
            RideLibBadge
                ._storageBadge()
                .driverToDriverReputation[msg.sender]
                .id != 0,
            "caller not driver"
        );
    }

    function _requireNotDriver() internal view {
        require(
            RideLibBadge
                ._storageBadge()
                .driverToDriverReputation[msg.sender]
                .id == 0,
            "caller is driver"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";

library RideLibExchange {
    bytes32 constant STORAGE_POSITION_EXCHANGE = keccak256("ds.exchange");

    struct StorageExchange {
        mapping(bytes32 => mapping(bytes32 => address)) xToYToXPerYPriceFeed;
        mapping(bytes32 => mapping(bytes32 => bool)) xToYToXPerYInverse;
    }

    function _storageExchange()
        internal
        pure
        returns (StorageExchange storage s)
    {
        bytes32 position = STORAGE_POSITION_EXCHANGE;
        assembly {
            s.slot := position
        }
    }

    function _requireXPerYPriceFeedSupported(bytes32 _keyX, bytes32 _keyY)
        internal
        view
    {
        require(
            _storageExchange().xToYToXPerYPriceFeed[_keyX][_keyY] != address(0),
            "price feed not supported"
        );
    }

    event PriceFeedAdded(
        address indexed sender,
        bytes32 keyX,
        bytes32 keyY,
        address priceFeed
    );

    // NOTE: to add ETH/USD price feed (displayed on chainlink), x = USD, y = ETH
    function _addXPerYPriceFeed(
        bytes32 _keyX,
        bytes32 _keyY,
        address _priceFeed
    ) internal {
        RideLibOwnership._requireIsContractOwner();
        RideLibCurrencyRegistry._requireCurrencySupported(_keyX);
        RideLibCurrencyRegistry._requireCurrencySupported(_keyY);

        require(_priceFeed != address(0), "zero price feed address");
        StorageExchange storage s1 = _storageExchange();
        require(
            s1.xToYToXPerYPriceFeed[_keyX][_keyY] == address(0),
            "price feed already supported"
        );
        s1.xToYToXPerYPriceFeed[_keyX][_keyY] = _priceFeed;
        s1.xToYToXPerYPriceFeed[_keyY][_keyX] = _priceFeed; // reverse pairing
        s1.xToYToXPerYInverse[_keyY][_keyX] = true;

        emit PriceFeedAdded(msg.sender, _keyX, _keyY, _priceFeed);
    }

    event PriceFeedRemoved(address indexed sender, address priceFeed);

    function _removeXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY) internal {
        RideLibOwnership._requireIsContractOwner();
        _requireXPerYPriceFeedSupported(_keyX, _keyY);

        StorageExchange storage s1 = _storageExchange();
        address priceFeed = s1.xToYToXPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXPerYPriceFeed[_keyX][_keyY];
        delete s1.xToYToXPerYPriceFeed[_keyY][_keyX]; // reverse pairing
        delete s1.xToYToXPerYInverse[_keyY][_keyX];

        // require(
        //     s1.xToYToXPerYPriceFeed[_keyX][_keyY] == address(0),
        //     "price feed not removed 1"
        // );
        // require(
        //     s1.xToYToXPerYPriceFeed[_keyY][_keyX] == address(0),
        //     "price feed not removed 2"
        // ); // reverse pairing
        // require(!s1.xToYToXPerYInverse[_keyY][_keyX], "reverse not removed");

        emit PriceFeedRemoved(msg.sender, priceFeed);
    }

    // function _getXPerYPriceFeed(bytes32 _keyX, bytes32 _keyY)
    //     internal
    //     view
    //     returns (address)
    // {
    //     _requireXPerYPriceFeedSupported(_keyX, _keyY);
    //     return _storageExchange().xToYToXPerYPriceFeed[_keyX][_keyY];
    // }

    function _convertCurrency(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        if (_storageExchange().xToYToXPerYInverse[_keyX][_keyY]) {
            return _convertInverse(_keyX, _keyY, _amountX);
        } else {
            return _convertDirect(_keyX, _keyY, _amountX);
        }
    }

    function _convertDirect(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        uint256 xPerYWei = _getXPerYInWei(_keyX, _keyY);
        return ((_amountX * 10**18) / xPerYWei); // note: no rounding occurs as value is converted into wei
    }

    function _convertInverse(
        bytes32 _keyX,
        bytes32 _keyY,
        uint256 _amountX
    ) internal view returns (uint256) {
        uint256 xPerYWei = _getXPerYInWei(_keyX, _keyY);
        return (_amountX * xPerYWei) / 10**18; // note: no rounding occurs as value is converted into wei
    }

    function _getXPerYInWei(bytes32 _keyX, bytes32 _keyY)
        internal
        view
        returns (uint256)
    {
        _requireXPerYPriceFeedSupported(_keyX, _keyY);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            _storageExchange().xToYToXPerYPriceFeed[_keyX][_keyY]
        );
        (, int256 xPerY, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return uint256(uint256(xPerY) * 10**(18 - decimals)); // convert to wei
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideDriver {
    event AcceptedTicket(address indexed sender, bytes32 indexed tixId);

    function acceptTicket(
        bytes32 _keyLocal,
        bytes32 _keyAccept,
        bytes32 _tixId,
        uint256 _useBadge
    ) external;

    event DriverCancelled(address indexed sender, bytes32 indexed tixId);

    function cancelPickUp() external;

    event TripEndedDrv(
        address indexed sender,
        bytes32 indexed tixId,
        bool reached
    );

    function endTripDrv(bool _reached) external;

    event ForceEndDrv(address indexed sender, bytes32 indexed tixId);

    function forceEndDrv() external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";

import {IRideBadge} from "../../interfaces/core/IRideBadge.sol";

/// @title Badge rank for drivers
contract RideBadge is IRideBadge {
    enum Badges {
        Newbie,
        Bronze,
        Silver,
        Gold,
        Platinum,
        Veteran
    } // note: if we edit last badge, rmb edit RideLibBadge._getBadgesCount fn as well

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
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores)
        external
        override
    {
        RideLibBadge._setBadgesMaxScores(_badgesMaxScores);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// -------------------------- getter functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function getBadgeToBadgeMaxScore(uint256 _badge)
        external
        view
        override
        returns (uint256)
    {
        return RideLibBadge._storageBadge().badgeToBadgeMaxScore[_badge];
    }

    function getDriverToDriverReputation(address _driver)
        external
        view
        override
        returns (RideLibBadge.DriverReputation memory)
    {
        return RideLibBadge._storageBadge().driverToDriverReputation[_driver];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

library RideLibOwnership {
    bytes32 constant STORAGE_POSITION_OWNERSHIP = keccak256("ds.ownership");

    struct StorageOwnership {
        address contractOwner;
    }

    function _storageOwnership()
        internal
        pure
        returns (StorageOwnership storage s)
    {
        bytes32 position = STORAGE_POSITION_OWNERSHIP;
        assembly {
            s.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        StorageOwnership storage s1 = _storageOwnership();
        address previousOwner = s1.contractOwner;
        s1.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address) {
        return _storageOwnership().contractOwner;
    }

    function _requireIsContractOwner() internal view {
        require(
            msg.sender == _storageOwnership().contractOwner,
            "not contract owner"
        );
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";
import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";

library RideLibRater {
    bytes32 constant STORAGE_POSITION_RATER = keccak256("ds.rater");

    struct StorageRater {
        uint256 ratingMin;
        uint256 ratingMax;
    }

    function _storageRater() internal pure returns (StorageRater storage s) {
        bytes32 position = STORAGE_POSITION_RATER;
        assembly {
            s.slot := position
        }
    }

    event SetRatingBounds(address indexed sender, uint256 min, uint256 max);

    /**
     * setRatingBounds sets bounds for rating
     *
     * @param _min | unitless integer
     * @param _max | unitless integer
     */
    function _setRatingBounds(uint256 _min, uint256 _max) internal {
        RideLibOwnership._requireIsContractOwner();
        StorageRater storage s1 = _storageRater();
        s1.ratingMin = _min;
        s1.ratingMax = _max;

        emit SetRatingBounds(msg.sender, _min, _max);
    }

    /**
     * _giveRating
     *
     * @param _driver driver's address
     * @param _rating unitless integer between RATING_MIN and RATING_MAX
     *
     */
    function _giveRating(address _driver, uint256 _rating) internal {
        RideLibBadge.StorageBadge storage s1 = RideLibBadge._storageBadge();
        StorageRater storage s2 = _storageRater();

        require(s2.ratingMin > 0, "minimum rating must be more than zero");
        require(s2.ratingMax > 0, "maximum rating must be more than zero");
        require(
            _rating >= s2.ratingMin && _rating <= s2.ratingMax,
            "rating must be within min and max ratings (inclusive)"
        );

        s1.driverToDriverReputation[_driver].totalRating += _rating;
        s1.driverToDriverReputation[_driver].countRating += 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {RideLibBadge} from "../../libraries/core/RideLibBadge.sol";

interface IRideBadge {
    event SetBadgesMaxScores(address indexed sender, uint256[] scores);

    function setBadgesMaxScores(uint256[] memory _badgesMaxScores) external;

    function getBadgeToBadgeMaxScore(uint256 _badge)
        external
        view
        returns (uint256);

    function getDriverToDriverReputation(address _driver)
        external
        view
        returns (RideLibBadge.DriverReputation memory);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibOwnership} from "../../libraries/utils/RideLibOwnership.sol";

// CurrencyRegistry is separated from Exchange mainly to ease checks for Holding and Fee, and to separately register fiat and crypto easily
library RideLibCurrencyRegistry {
    bytes32 constant STORAGE_POSITION_CURRENCYREGISTRY =
        keccak256("ds.currencyregistry");

    struct StorageCurrencyRegistry {
        mapping(bytes32 => bool) currencyKeyToSupported;
        mapping(bytes32 => bool) currencyKeyToCrypto;
    }

    function _storageCurrencyRegistry()
        internal
        pure
        returns (StorageCurrencyRegistry storage s)
    {
        bytes32 position = STORAGE_POSITION_CURRENCYREGISTRY;
        assembly {
            s.slot := position
        }
    }

    function _requireCurrencySupported(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToSupported[_key],
            "currency not supported"
        );
    }

    // _requireIsCrypto does NOT check if is ERC20
    function _requireIsCrypto(bytes32 _key) internal view {
        require(
            _storageCurrencyRegistry().currencyKeyToCrypto[_key],
            "not crypto"
        );
    }

    // code must follow: ISO-4217 Currency Code Standard: https://www.iso.org/iso-4217-currency-codes.html
    function _registerFiat(string memory _code) internal returns (bytes32) {
        bytes32 key = keccak256(abi.encode(_code));
        _register(key);
        return key;
    }

    function _registerCrypto(address _token) internal returns (bytes32) {
        require(_token != address(0), "zero token address");
        bytes32 key = bytes32(uint256(uint160(_token)) << 96);
        _register(key);
        _storageCurrencyRegistry().currencyKeyToCrypto[key] = true;
        return key;
    }

    event CurrencyRegistered(address indexed sender, bytes32 key);

    function _register(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _storageCurrencyRegistry().currencyKeyToSupported[_key] = true;

        emit CurrencyRegistered(msg.sender, _key);
    }

    // // _getKeyFiat to be called externally ONLY
    // function _getKeyFiat(string memory _code) internal view returns (bytes32) {
    //     bytes32 key = keccak256(abi.encode(_code));
    //     _requireCurrencySupported(key);
    //     return key;
    // }

    // // _getKeyCrypto to be called externally ONLY
    // function _getKeyCrypto(address _token) internal view returns (bytes32) {
    //     bytes32 key = bytes32(uint256(uint160(_token)) << 96);
    //     _requireCurrencySupported(key);
    //     return key;
    // }

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function _removeCurrency(bytes32 _key) internal {
        RideLibOwnership._requireIsContractOwner();
        _requireCurrencySupported(_key);
        StorageCurrencyRegistry storage s1 = _storageCurrencyRegistry();
        delete s1.currencyKeyToSupported[_key]; // delete cheaper than set false
        // require(!s1.currencyKeyToSupported[_key], "failed to remove 1");

        if (s1.currencyKeyToCrypto[_key]) {
            delete s1.currencyKeyToCrypto[_key];
            // require(!s1.currencyKeyToCrypto[_key], "failed to remove 2");
        }

        emit CurrencyRemoved(msg.sender, _key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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