//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RideDriver.sol";
import "./RidePassenger.sol";

/// @title Main contract for driver and passenger interaction
contract RideHub is RideDriver, RidePassenger {

}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./RideBase.sol";
import "./RideUtils.sol";

/// @title Driver component of RideHub
contract RideDriver is RideBase {
    using Counters for Counters.Counter;
    Counters.Counter private _driverIdCounter;

    event DriverRegistered(address sender);
    event AcceptedTicket(bytes32 indexed tixId, address sender);
    event DriverCancelled(bytes32 indexed tixId, address sender);
    event DestinationReached(bytes32 indexed tixId, address sender);
    event DestinationNotReached(bytes32 indexed tixId, address sender);
    event ForceEndDriver(bytes32 indexed tixId, address sender);

    modifier isDriver() {
        require(
            addressToDriverReputation[msg.sender].id != 0,
            "caller not driver"
        );
        _;
    }

    constructor() {
        _burnFirstDriverId();
    }

    /**
     * registerDriver registers approved applicants (has passed background check)
     *
     * @param _maxMetresPerTrip | unit in metre
     *
     * @custom:event DriverRegistered
     */
    function registerDriver(uint256 _maxMetresPerTrip)
        external
        initializedRideBase
        notDriver
        notActive
    {
        require(
            bytes(addressToDriverReputation[msg.sender].uri).length != 0,
            "uri not set in bg check"
        );
        require(msg.sender != address(0), "0 address");

        addressToDriverReputation[msg.sender].id = _mint();
        addressToDriverReputation[msg.sender]
            .maxMetresPerTrip = _maxMetresPerTrip;
        addressToDriverReputation[msg.sender].metresTravelled = 0;
        addressToDriverReputation[msg.sender].countStart = 0;
        addressToDriverReputation[msg.sender].countEnd = 0;
        addressToDriverReputation[msg.sender].totalRating = 0;
        addressToDriverReputation[msg.sender].countRating = 0;

        emit DriverRegistered(msg.sender);
    }

    /**
     * updateMaxMetresPerTrip updates maximum metre per trip of driver
     *
     * @param _maxMetresPerTrip | unit in metre
     */
    function updateMaxMetresPerTrip(uint256 _maxMetresPerTrip)
        external
        isDriver
        notActive
    {
        addressToDriverReputation[msg.sender]
            .maxMetresPerTrip = _maxMetresPerTrip;
    }

    /**
     * getTicket allows driver to accept passenger's ticket request
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
    function getTicket(bytes32 _tixId, uint256 _useBadge)
        external
        isDriver
        notActive
        notBan
    {
        uint256 driverScore = RideUtils._calculateScore(
            addressToDriverReputation[msg.sender].metresTravelled,
            addressToDriverReputation[msg.sender].countStart,
            addressToDriverReputation[msg.sender].countEnd,
            addressToDriverReputation[msg.sender].totalRating,
            addressToDriverReputation[msg.sender].countRating,
            RATING_MAX
        );
        uint256 driverBadge = _getBadge(driverScore);
        require(_useBadge <= driverBadge, "badge rank not achieved");

        require(
            addressToDeposit[msg.sender] > tixIdToTicket[_tixId].fare,
            "driver's deposit < fare"
        );
        require(
            tixIdToTicket[_tixId].metres <=
                addressToDriverReputation[msg.sender].maxMetresPerTrip,
            "trip too long"
        );
        if (tixIdToTicket[_tixId].strict) {
            require(
                _useBadge == tixIdToTicket[_tixId].badge,
                "driver not meet badge - strict"
            );
        } else {
            require(
                _useBadge >= tixIdToTicket[_tixId].badge,
                "driver not meet badge"
            );
        }

        tixIdToTicket[_tixId].driver = msg.sender;
        addressToActive[msg.sender] = true;

        emit AcceptedTicket(_tixId, msg.sender); // --> update frontend (also, add warning that if passenger cancel, will incure fee)
    }

    /**
     * cancelPickUp cancels pick up, can only be called before startTrip
     *
     * @param _tixId Ticket ID
     *
     * @custom:event DriverCancelled
     */
    function cancelPickUp(bytes32 _tixId)
        external
        driverMatchTixDriver(_tixId, msg.sender)
        tripNotStart(_tixId)
    {
        address passenger = tixIdToTicket[_tixId].passenger;

        _transfer(_tixId, requestFee, msg.sender, passenger);

        _cleanUp(_tixId, passenger, msg.sender);

        emit DriverCancelled(_tixId, msg.sender); // --> update frontend
    }

    /**
     * destinationReached allows driver to indicate to passenger to end trip and destination reached
     *
     * @param _tixId Ticket ID
     *
     * @custom:event DestinationReached
     */
    function destinationReached(bytes32 _tixId)
        external
        driverMatchTixDriver(_tixId, msg.sender)
        tripInProgress(_tixId)
    {
        tixToEndDetails[_tixId] = EndDetails({
            driver: msg.sender,
            reached: true
        });

        emit DestinationReached(_tixId, msg.sender);
    }

    /**
     * destinationNotReached allows driver to indicate to passenger to end trip and destination not reached
     *
     * @param _tixId Ticket ID
     *
     * @custom:event DestinationNotReached
     */
    function destinationNotReached(bytes32 _tixId)
        external
        driverMatchTixDriver(_tixId, msg.sender)
        tripInProgress(_tixId)
    {
        tixToEndDetails[_tixId] = EndDetails({
            driver: msg.sender,
            reached: false
        });

        emit DestinationNotReached(_tixId, msg.sender);
    }

    /**
     * forceEndDriver can be called after tixIdToTicket[_tixId].forceEndTimestamp duration
     * and if passenger has not called endTrip
     *
     * @param _tixId Ticket ID
     *
     * @custom:event ForceEndDriver
     *
     * no fare is paid, but passenger is temporarily banned for banDuration
     */
    function forceEndDriver(bytes32 _tixId)
        external
        driverMatchTixDriver(_tixId, msg.sender)
        tripInProgress(_tixId) /** means both parties still active */
        forceEndAllowed(_tixId)
    {
        require(
            tixToEndDetails[_tixId].driver != address(0),
            "driver must end trip"
        ); // TODO: test
        address passenger = tixIdToTicket[_tixId].passenger;

        _temporaryBan(passenger);
        _cleanUp(_tixId, passenger, msg.sender);

        emit ForceEndDriver(_tixId, msg.sender);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    /**
     * _mint a driver ID
     *
     * @return driver ID
     */
    function _mint() internal returns (uint256) {
        uint256 id = _driverIdCounter.current();
        _driverIdCounter.increment();
        return id;
    }

    /**
     * _burnFirstDriverId burns driver ID 0
     * can only be called at RideHub deployment
     */
    function _burnFirstDriverId() internal {
        assert(_driverIdCounter.current() == 0);
        _driverIdCounter.increment();
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RideBase.sol";
import "./RideUtils.sol";

// import "hardhat/console.sol";

/// @title Passenger component of RideHub
contract RidePassenger is RideBase {
    event RequestTicket(bytes32 indexed tixId, address sender);
    event RequestCancelled(bytes32 indexed tixId, address sender);
    event TripStarted(bytes32 indexed tixId, address passenger, address driver);
    event TripEnded(bytes32 indexed tixId, address sender);
    event ForceEndPassenger(bytes32 indexed tixId, address sender);

    modifier paxMatchTixPax(bytes32 _tixId, address _passenger) {
        require(
            _passenger == tixIdToTicket[_tixId].passenger,
            "pax not match tix pax"
        );
        _;
    }

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
    ) external initializedRideBase notDriver notActive notBan {
        uint256 fare = RideUtils._getFare(
            baseFare,
            _metres,
            _minutes,
            badgeToCostPerMetre[_badge],
            costPerMinute
        );
        require(
            addressToDeposit[msg.sender] > fare,
            "passenger's deposit < fare"
        );

        bytes32 tixId = keccak256(abi.encode(msg.sender, block.timestamp));

        tixIdToTicket[tixId].passenger = msg.sender;
        tixIdToTicket[tixId].badge = _badge;
        tixIdToTicket[tixId].strict = _strict;
        tixIdToTicket[tixId].metres = _metres;
        tixIdToTicket[tixId].fare = fare;

        addressToActive[msg.sender] = true;

        emit RequestTicket(tixId, msg.sender);
    }

    /**
     * cancelRequest cancels ticket, can only be called before startTrip
     *
     * @param _tixId Ticket ID
     *
     * @custom:event RequestCancelled
     */
    function cancelRequest(bytes32 _tixId)
        external
        paxMatchTixPax(_tixId, msg.sender)
        tripNotStart(_tixId)
    {
        address driver = tixIdToTicket[_tixId].driver;
        if (driver != address(0)) {
            // case when cancel inbetween driver accepted, but haven't reach passenger
            // give warning at frontend to passenger
            _transfer(_tixId, requestFee, msg.sender, driver);
        }

        _cleanUp(_tixId, msg.sender, driver);

        emit RequestCancelled(_tixId, msg.sender); // --> update frontend request pool
    }

    /**
     * startTrip starts the trip, can only be called once driver reached passenger
     *
     * @param _tixId Ticket ID
     * @param _driver driver's address - get via QR scan?
     *
     * @custom:event TripStarted
     */
    function startTrip(bytes32 _tixId, address _driver)
        external
        paxMatchTixPax(_tixId, msg.sender)
        driverMatchTixDriver(_tixId, _driver)
        tripNotStart(_tixId)
    {
        addressToDriverReputation[_driver].countStart += 1;
        tixIdToTicket[_tixId].tripStart = true;
        tixIdToTicket[_tixId].forceEndTimestamp = block.timestamp + 1 days;

        emit TripStarted(_tixId, msg.sender, _driver); // update frontend
    }

    /**
     * endTrip ends the trip, can only be called once driver has called either destinationReached or destinationNotReached
     *
     * @param _tixId Ticket ID
     * @param _confirmation confirmation from passenger that either destination has been reached or not
     * @param _rating refer _giveRating
     *
     * @custom:event TripEnded
     *
     * driver would select destination reached or not, and event will emit to passenger's UI
     * then passenger would confirm if this is true or false (via frontend UI), followed by a rating
     */
    function endTrip(
        bytes32 _tixId,
        bool _confirmation,
        uint256 _rating
    ) external paxMatchTixPax(_tixId, msg.sender) tripInProgress(_tixId) {
        address driver = tixToEndDetails[_tixId].driver;
        require(driver != address(0), "driver must end trip");
        require(
            _confirmation,
            "pax must confirm destination reached or not - indicated by driver"
        );

        if (tixToEndDetails[_tixId].reached) {
            _transfer(_tixId, tixIdToTicket[_tixId].fare, msg.sender, driver);
            addressToDriverReputation[driver].metresTravelled += tixIdToTicket[
                _tixId
            ].metres;
            addressToDriverReputation[driver].countEnd += 1;
        }

        _giveRating(driver, _rating);

        _cleanUp(_tixId, msg.sender, driver);

        emit TripEnded(_tixId, msg.sender);
    }

    /**
     * forceEndPassenger can be called after tixIdToTicket[_tixId].forceEndTimestamp duration
     * and if driver has not called destinationReached or destinationNotReached
     *
     * @param _tixId Ticket ID
     *
     * @custom:event ForceEndPassenger
     *
     * no fare is paid, but driver is temporarily banned for banDuration
     */
    function forceEndPassenger(bytes32 _tixId)
        external
        paxMatchTixPax(_tixId, msg.sender)
        tripInProgress(_tixId) /** means both parties still active */
        forceEndAllowed(_tixId)
    {
        require(
            tixToEndDetails[_tixId].driver == address(0),
            "driver ended trip"
        ); // TODO: test
        address driver = tixIdToTicket[_tixId].driver;

        _temporaryBan(driver);
        _giveRating(driver, 1);
        _cleanUp(_tixId, msg.sender, driver);

        emit ForceEndPassenger(_tixId, msg.sender);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    /**
     * _giveRating
     *
     * @param _driver driver's address
     * @param _rating unitless integer between RATING_MIN and RATING_MAX
     *
     * @custom:event TripStarted
     */
    function _giveRating(address _driver, uint256 _rating) internal {
        require(_rating >= RATING_MIN && _rating <= RATING_MAX); // TODO: contract exceeds size limit when add error msg
        addressToDriverReputation[_driver].totalRating += _rating;
        addressToDriverReputation[_driver].countRating += 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./RideCost.sol";

// import "hardhat/console.sol";

/// @title Base contract for Passenger and Driver of RideHub
contract RideBase is RideCost, ReentrancyGuard, Initializable {
    ERC20 public token;

    uint256 internal constant RATING_MIN = 1;
    uint256 internal constant RATING_MAX = 5;
    bool public initialized;

    mapping(address => uint256) public addressToDeposit;
    mapping(address => bool) public addressToActive;
    mapping(address => uint256) public addressToBanEndTimestamp;

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
    mapping(address => DriverReputation) public addressToDriverReputation;

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
    mapping(bytes32 => Ticket) internal tixIdToTicket;

    struct EndDetails {
        address driver;
        bool reached;
    }
    mapping(bytes32 => EndDetails) internal tixToEndDetails;

    event InitializedRideBase(address token, address deployer);
    event TokensDeposited(address sender, uint256 amount);
    event TokensRemoved(address sender, uint256 amount);
    event TokensTransferred(
        bytes32 indexed tixId,
        uint256 amount,
        address decrease,
        address increase
    );
    event TicketCleared(bytes32 indexed tixId);
    event UserBanned(address banned, uint256 until);
    event ApplicantApproved(address applicant);

    /**
     * @dev order of execution of modifiers when used in functions is left to right
     */

    modifier notDriver() {
        require(
            addressToDriverReputation[msg.sender].id == 0,
            "caller is driver"
        );
        _;
    }

    modifier notActive() {
        require(!addressToActive[msg.sender], "caller is active");
        _;
    }

    modifier driverMatchTixDriver(bytes32 _tixId, address _driver) {
        require(
            _driver == tixIdToTicket[_tixId].driver,
            "driver not match tix driver"
        );
        _;
    }

    modifier tripNotStart(bytes32 _tixId) {
        require(!tixIdToTicket[_tixId].tripStart, "trip already started");
        _;
    }

    modifier tripInProgress(bytes32 _tixId) {
        require(tixIdToTicket[_tixId].tripStart, "trip not started");
        _;
    }

    modifier forceEndAllowed(bytes32 _tixId) {
        require(
            block.timestamp > tixIdToTicket[_tixId].forceEndTimestamp,
            "too early"
        );
        _;
    }

    modifier notBan() {
        require(
            block.timestamp >= addressToBanEndTimestamp[msg.sender],
            "still banned"
        );
        _;
    }

    modifier initializedRideBase() {
        require(initialized, "not init RideBase");
        _;
    }

    /**
     * initializeRideBase initializes parameters of RideHub
     *
     * @dev to be run instantly after deployment
     *
     * @param _tokenAddress     | Ride token address
     * @param _badgesMaxScores  | Refer RideBadge.sol
     * @param _requestFee       | Refer RideCost.sol
     * @param _baseFare         | Refer RideCost.sol
     * @param _costPerMetre     | Refer RideCost.sol
     * @param _costPerMinute    | Refer RideCost.sol
     * @param _banDuration      | Refer RideCost.sol
     *
     * @custom:event InitializedRideBase
     */
    function initializeRideBase(
        address _tokenAddress,
        uint256[] memory _badgesMaxScores,
        uint256 _requestFee,
        uint256 _baseFare,
        uint256[] memory _costPerMetre,
        uint256 _costPerMinute,
        uint256 _banDuration
    ) external onlyOwner initializer {
        token = ERC20(_tokenAddress);
        setBadgesMaxScores(_badgesMaxScores);
        setRequestFee(_requestFee);
        setBaseFare(_baseFare);
        setCostPerMetre(_costPerMetre);
        setCostPerMinute(_costPerMinute);
        setBanDuration(_banDuration);

        initialized = true;

        emit InitializedRideBase(_tokenAddress, msg.sender);
    }

    /**
     * placeDeposit allows users to deposit token into RideHub contract
     *
     * @dev call token contract's "approve" first
     *
     * @param _amount | unit in token
     *
     * @custom:event TokensDeposited
     */
    function placeDeposit(uint256 _amount) external initializedRideBase {
        require(_amount > 0, "0 amount");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "check token allowance"
        );
        bool sent = token.transferFrom(msg.sender, address(this), _amount);
        require(sent, "tx failed");

        addressToDeposit[msg.sender] += _amount;

        emit TokensDeposited(msg.sender, _amount);
    }

    /**
     * removeDeposit allows users to remove token from RideHub contract
     *
     * @custom:event TokensRemoved
     */
    function removeDeposit() external notActive nonReentrant {
        uint256 amount = addressToDeposit[msg.sender];
        require(amount > 0, "deposit empty");
        require(
            token.balanceOf(address(this)) >= amount,
            "contract insufficient funds"
        );
        addressToDeposit[msg.sender] = 0;
        bool sent = token.transfer(msg.sender, amount);
        // bool sent = token.transferFrom(address(this), msg.sender, amount);
        require(sent, "tx failed");

        emit TokensRemoved(msg.sender, amount);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

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
        addressToDeposit[_decrease] -= _amount;
        addressToDeposit[_increase] += _amount;

        emit TokensTransferred(_tixId, _amount, _decrease, _increase);
    }

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
        delete tixIdToTicket[_tixId];
        delete tixToEndDetails[_tixId];
        addressToActive[_passenger] = false;
        addressToActive[_driver] = false;

        emit TicketCleared(_tixId);
    }

    /**
     * _temporaryBan user
     *
     * @param _address address to be banned
     *
     * @custom:event UserBanned
     */
    function _temporaryBan(address _address) internal {
        uint256 banUntil = block.timestamp + banDuration;
        addressToBanEndTimestamp[_address] = banUntil;

        emit UserBanned(_address, banUntil);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// --------------------------- admin functions -------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    /// @custom:TODO: backup fn if pax or driver didn't force end

    /**
     * passBackgroundCheck of driver applicants
     *
     * @param _driver applicant
     * @param _uri information of applicant
     *
     * @custom:event ApplicantApproved
     */
    function passBackgroundCheck(address _driver, string memory _uri)
        external
        onlyOwner
        initializedRideBase
    {
        require(
            bytes(addressToDriverReputation[_driver].uri).length == 0,
            "uri already set"
        );
        addressToDriverReputation[_driver].uri = _uri;

        emit ApplicantApproved(_driver);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Utility functions for RideHub
library RideUtils {
    /**
     * _getFare calculates the fare of a trip.
     *
     * @param _baseFare        | unit in token
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
        uint256 _baseFare,
        uint256 _metresTravelled,
        uint256 _minutesTaken,
        uint256 _costPerMetre,
        uint256 _costPerMinute
    ) internal pure returns (uint256) {
        return (_baseFare +
            (_metresTravelled * _costPerMetre) +
            (_minutesTaken * _costPerMinute));
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

    // function _shuffle(bytes32[] memory _value, uint256 _randomNumber)
    //     internal
    //     pure
    //     returns (bytes32[] memory)
    // {
    //     for (uint256 i = 0; i < _value.length; i++) {
    //         uint256 n = i + (_randomNumber % (_value.length - i)); // uint256(keccak256(abi.encodePacked(block.timestamp)))
    //         bytes32 temp = _value[n];
    //         _value[n] = _value[i];
    //         _value[i] = temp;
    //     }
    //     return _value;
    // }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RideBadge.sol";

/// @title Sets RideHub's costs
contract RideCost is RideBadge {
    uint256 public requestFee;
    uint256 public baseFare;
    uint256 public costPerMinute;
    uint256 public banDuration;
    mapping(uint256 => uint256) public badgeToCostPerMetre;

    /**
     * setRequestFee sets request fee
     *
     * @param _requestFee | unit in token
     */
    function setRequestFee(uint256 _requestFee) public onlyOwner {
        requestFee = _requestFee; // input format: token in Wei
    }

    /**
     * setBaseFare sets base fare
     *
     * @param _baseFare | unit in token
     */
    function setBaseFare(uint256 _baseFare) public onlyOwner {
        baseFare = _baseFare; // input format: token in Wei
    }

    /**
     * setCostPerMinute sets cost per minute
     *
     * @param _costPerMinute | unit in token
     */
    function setCostPerMinute(uint256 _costPerMinute) public onlyOwner {
        costPerMinute = _costPerMinute; // input format: token in Wei
    }

    /**
     * setBanDuration sets user ban duration
     *
     * @param _banDuration | unit in unix timestamp | https://docs.soliditylang.org/en/v0.8.10/units-and-global-variables.html#time-units
     */
    function setBanDuration(uint256 _banDuration) public onlyOwner {
        banDuration = _banDuration;
    }

    /**
     * setCostPerMetre sets cost per metre
     *
     * @param _costPerMetre | unit in token
     */
    function setCostPerMetre(uint256[] memory _costPerMetre) public onlyOwner {
        require(
            _costPerMetre.length == badgesCount,
            "_costPerMetre.length must be equal Badges"
        );
        for (uint256 i = 0; i < _costPerMetre.length; i++) {
            badgeToCostPerMetre[i] = _costPerMetre[i]; // input format: token in Wei // rounded down
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RideControl.sol";

/// @title Badge rank for drivers
contract RideBadge is RideControl {
    enum Badges {
        Newbie,
        Bronze,
        Silver,
        Gold,
        Platinum,
        Veteran
    }
    uint256 internal constant badgesCount = 6;

    mapping(uint256 => uint256) public badgeToBadgeMaxScore;

    /**
     * setBadgesMaxScores maps score to badge
     *
     * @param _badgesMaxScores Score that defines a specific badge rank
     */
    function setBadgesMaxScores(uint256[] memory _badgesMaxScores)
        public
        onlyOwner
    {
        require(
            _badgesMaxScores.length == badgesCount - 1,
            "_badgesMaxScores.length must be 1 less than Badges"
        );
        for (uint256 i = 0; i < _badgesMaxScores.length; i++) {
            badgeToBadgeMaxScore[i] = _badgesMaxScores[i];
        }
    }

    /**
     * _getBadge returns the badge rank for given score
     *
     * @param _score | unitless integer
     *
     * @return badge rank
     */
    function _getBadge(uint256 _score) internal view returns (uint256) {
        if (_score <= badgeToBadgeMaxScore[0]) {
            return uint256(Badges.Newbie);
        } else if (
            _score > badgeToBadgeMaxScore[0] &&
            _score <= badgeToBadgeMaxScore[1]
        ) {
            return uint256(Badges.Bronze);
        } else if (
            _score > badgeToBadgeMaxScore[1] &&
            _score <= badgeToBadgeMaxScore[2]
        ) {
            return uint256(Badges.Silver);
        } else if (
            _score > badgeToBadgeMaxScore[2] &&
            _score <= badgeToBadgeMaxScore[3]
        ) {
            return uint256(Badges.Gold);
        } else if (
            _score > badgeToBadgeMaxScore[3] &&
            _score <= badgeToBadgeMaxScore[4]
        ) {
            return uint256(Badges.Platinum);
        } else {
            return uint256(Badges.Veteran);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:TODO implement contract details

// import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Access & Governance settings
contract RideControl is Ownable {
    // bytes32 public constant ROLE_GOVERNANCE = keccak256("ROLE_GOVERNANCE");
    // bytes32 public constant ROLE_MULTISIG = keccak256("ROLE_MULTISIG"); // for quicker execution | background checks ?
    // bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN"); // for tasks like background checks
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}