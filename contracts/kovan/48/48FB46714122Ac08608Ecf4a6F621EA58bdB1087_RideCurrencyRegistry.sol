//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.2;

import {RideLibCurrencyRegistry} from "../../libraries/core/RideLibCurrencyRegistry.sol";
import {RideLibFee} from "../../libraries/core/RideLibFee.sol";

import {IRideCurrencyRegistry} from "../../interfaces/core/IRideCurrencyRegistry.sol";

contract RideCurrencyRegistry is IRideCurrencyRegistry {
    function registerFiat(string memory _code)
        external
        override
        returns (bytes32)
    {
        return RideLibCurrencyRegistry._registerFiat(_code);
    }

    function registerCrypto(address _token)
        external
        override
        returns (bytes32)
    {
        return RideLibCurrencyRegistry._registerCrypto(_token);
    }

    function getKeyFiat(string memory _code) external view override {
        RideLibCurrencyRegistry._getKeyFiat(_code);
    }

    function getKeyCrypto(address _token) external view override {
        RideLibCurrencyRegistry._getKeyCrypto(_token);
    }

    function removeCurrency(bytes32 _key) external override {
        RideLibCurrencyRegistry._removeCurrency(_key);
    }

    function setupFiatWithFee(
        string memory _code,
        uint256 _requestFee,
        uint256 _baseFee,
        uint256 _costPerMinute,
        uint256[] memory _costPerMetre
    ) external override returns (bytes32) {
        bytes32 key = RideLibCurrencyRegistry._registerFiat(_code);
        RideLibFee._setRequestFee(key, _requestFee);
        RideLibFee._setBaseFee(key, _baseFee);
        RideLibFee._setCostPerMinute(key, _costPerMinute);
        RideLibFee._setCostPerMetre(key, _costPerMetre);
        return key;
    }

    function setupCryptoWithFee(
        address _token,
        uint256 _requestFee,
        uint256 _baseFee,
        uint256 _costPerMinute,
        uint256[] memory _costPerMetre
    ) external override returns (bytes32) {
        bytes32 key = RideLibCurrencyRegistry._registerCrypto(_token);
        RideLibFee._setRequestFee(key, _requestFee);
        RideLibFee._setBaseFee(key, _baseFee);
        RideLibFee._setCostPerMinute(key, _costPerMinute);
        RideLibFee._setCostPerMetre(key, _costPerMetre);
        return key;
    }
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

    // _getKeyFiat to be called externally ONLY
    function _getKeyFiat(string memory _code) internal view returns (bytes32) {
        bytes32 key = keccak256(abi.encode(_code));
        _requireCurrencySupported(key);
        return key;
    }

    // _getKeyCrypto to be called externally ONLY
    function _getKeyCrypto(address _token) internal view returns (bytes32) {
        bytes32 key = bytes32(uint256(uint160(_token)) << 96);
        _requireCurrencySupported(key);
        return key;
    }

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

    function _getBaseFee(bytes32 _key) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return _storageFee().currencyKeyToBaseFee[_key];
    }

    function _getCostPerMinute(bytes32 _key) internal view returns (uint256) {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return _storageFee().currencyKeyToCostPerMinute[_key];
    }

    function _getCostPerMetre(bytes32 _key, uint256 _badge)
        internal
        view
        returns (uint256)
    {
        RideLibCurrencyRegistry._requireCurrencySupported(_key);
        return _storageFee().currencyKeyToBadgeToCostPerMetre[_key][_badge];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRideCurrencyRegistry {
    event CurrencyRegistered(address indexed sender, bytes32 key);

    function registerFiat(string memory _code) external returns (bytes32);

    function registerCrypto(address _token) external returns (bytes32);

    function getKeyFiat(string memory _code) external view;

    function getKeyCrypto(address _token) external view;

    event CurrencyRemoved(address indexed sender, bytes32 key);

    function removeCurrency(bytes32 _key) external;

    function setupFiatWithFee(
        string memory _code,
        uint256 _requestFee,
        uint256 _baseFee,
        uint256 _costPerMinute,
        uint256[] memory _costPerMetre
    ) external returns (bytes32);

    function setupCryptoWithFee(
        address _token,
        uint256 _requestFee,
        uint256 _baseFee,
        uint256 _costPerMinute,
        uint256[] memory _costPerMetre
    ) external returns (bytes32);
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