//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./RideDriver.sol";
import "./RidePassenger.sol";

contract RideMain is RideDriver, RidePassenger {
    constructor(
        address _vrfCoordinator, // chainlink's VRF
        address _linkToken, // chainlink's VRF
        bytes32 _keyhash, // chainlink's VRF
        uint256 _feeLink // chainlink's VRF
    ) RidePassenger(_vrfCoordinator, _linkToken, _keyhash, _feeLink) {}
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./RideBase.sol";
import "./RideBadge.sol";
import "./RideUtils.sol";

contract RideDriver is RideBase, RideBadge {
    using Counters for Counters.Counter;
    Counters.Counter private _driverIdCounter;

    event DriverRegistered(address sender);
    event AcceptedTicket(bytes32 indexed tixId, address sender);
    event DriverCancelled(bytes32 indexed tixId, address sender);
    event DriverEnd(bytes32 indexed tixId, address sender);

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

    // callable by unregistered driver after pass (centralized) background check
    function registerDriver(uint256 _maxMetresPerTrip)
        external
        initializedRideBase
        notDriver
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

    function isCallerDriver() external view returns (bool) {
        if (addressToDriverReputation[msg.sender].id != 0) {
            return true;
        } else {
            return false;
        }
    }

    function updateMaxMetresPerTrip(uint256 _maxMetresPerTrip)
        external
        isDriver
        notActive
    {
        addressToDriverReputation[msg.sender]
            .maxMetresPerTrip = _maxMetresPerTrip;
    }

    // sort require statements at frontend so dont hit in solidity, internal checks is to prevent hack only
    function getPassenger(bytes32 _tixId)
        external
        initializedRideBase
        isDriver
        notActive
    {
        uint256 estimatedFare = RideUtils._getFare(
            baseFare,
            tixIdToTicket[_tixId].estimatedMetres,
            tixIdToTicket[_tixId].estimatedMinutes,
            costPerMetre,
            costPerMinute
        );
        require(
            addressToDeposit[msg.sender] > estimatedFare * collateralMultiplier,
            "driver's deposit < fare"
        );
        uint256 driverBadge = _getDriverBadge(msg.sender);
        require(
            driverBadge >= tixIdToTicket[_tixId].minimumBadge,
            "driver not meet badge"
        );
        require(
            tixIdToTicket[_tixId].estimatedMetres <=
                addressToDriverReputation[msg.sender].maxMetresPerTrip,
            "trip too long"
        );

        tixIdToTicket[_tixId].driver = msg.sender;
        addressToActive[msg.sender] = true;

        emit AcceptedTicket(_tixId, msg.sender); // --> update frontend (also, add warning that if passenger cancel, will incure fee)
    }

    function cancelPickUp(bytes32 _tixId)
        external
        driverMatchTixDriver(_tixId, msg.sender)
        tripNotStart(_tixId)
    {
        address passenger = tixIdToTicket[_tixId].passenger;

        _swapTokens(_tixId, requestFee, msg.sender, passenger);

        _cleanUp(_tixId, passenger, msg.sender);

        emit DriverCancelled(_tixId, msg.sender); // --> update frontend
    }

    function endTripDriver(
        bytes32 _tixId,
        string memory _destination,
        uint256 _metresTravelled,
        uint256 _minutesTaken
    ) external driverMatchTixDriver(_tixId, msg.sender) tripInProgress(_tixId) {
        tixToEndDetails[_tixId] = EndDetails({
            driver: msg.sender,
            destination: _destination,
            metresTravelled: _metresTravelled,
            minutesTaken: _minutesTaken
        });

        emit DriverEnd(_tixId, msg.sender);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function _mint() internal returns (uint256) {
        uint256 id = _driverIdCounter.current();
        _driverIdCounter.increment();
        return id;
    }

    function _burnFirstDriverId() internal {
        assert(_driverIdCounter.current() == 0);
        _driverIdCounter.increment();
    }

    function _getDriverBadge(address _driver) internal view returns (uint256) {
        uint256 driverScore = RideUtils._calculateScore(
            addressToDriverReputation[_driver].metresTravelled,
            addressToDriverReputation[_driver].totalRating,
            addressToDriverReputation[_driver].countStart,
            addressToDriverReputation[_driver].countEnd
        );
        uint256 driverBadge = _getBadge(driverScore);

        return driverBadge;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

import "./RideBase.sol";
import "./RideUtils.sol";

// import "hardhat/console.sol";

contract RidePassenger is RideBase, VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal feeLink;

    struct Tmp {
        address passenger;
        uint256 minimumBadge;
        string destination;
        uint256 estimatedMetres;
        uint256 estimatedMinutes;
    }
    mapping(bytes32 => Tmp) internal randomRequestToTmp;

    mapping(address => bool) public addressToProcessing; // TODO: if no use at frontend set internal
    mapping(address => bytes32) public addressToTixId; // TODO: no need use if can use event

    event RandomRequest(bytes32 indexed idx, address requester);
    event SaltReceived(bytes32 indexed tixId, address requester);
    // TODO: test indexed - https://ethereum.stackexchange.com/questions/8658/what-does-the-indexed-keyword-do
    event RequestCancelled(bytes32 indexed tixId, address sender);
    event TripStart(bytes32 indexed tixId, address passenger, address driver);
    event PassengerEnd(bytes32 indexed tixId, address sender);

    modifier paxMatchTixPax(bytes32 _tixId, address _passenger) {
        require(
            _passenger == tixIdToTicket[_tixId].passenger,
            "pax not match tix pax"
        );
        _;
    }

    constructor(
        address _vrfCoordinator, // chainlink's VRF
        address _linkToken, // chainlink's VRF
        bytes32 _keyhash, // chainlink's VRF
        uint256 _feeLink // chainlink's VRF
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyhash;
        feeLink = _feeLink;
    }

    function requestTicket(
        uint256 _minimumBadge,
        string memory _destination,
        uint256 _estimatedMetres,
        uint256 _estimatedMinutes
    ) external initializedRideBase notDriver notActive {
        require(!addressToProcessing[msg.sender], "processing");
        delete addressToTixId[msg.sender]; // TODO: no need use if can use event

        uint256 estimatedFare = RideUtils._getFare(
            baseFare,
            _estimatedMetres,
            _estimatedMinutes,
            costPerMetre,
            costPerMinute
        );
        require(
            addressToDeposit[msg.sender] > estimatedFare * collateralMultiplier,
            "passenger's deposit < fare"
        );

        bytes32 idx = _getRandomNumber();
        randomRequestToTmp[idx] = Tmp({
            passenger: msg.sender,
            minimumBadge: _minimumBadge,
            destination: _destination,
            estimatedMetres: _estimatedMetres,
            estimatedMinutes: _estimatedMinutes
        });
        addressToProcessing[msg.sender] = true;

        emit RandomRequest(idx, msg.sender);
    }

    function fulfillRandomness(bytes32 _idx, uint256 _salt) internal override {
        address passenger = randomRequestToTmp[_idx].passenger;
        bytes32 tixId = keccak256(
            abi.encode(passenger, block.timestamp, _salt)
        );
        tixIdToTicket[tixId].passenger = passenger;
        tixIdToTicket[tixId].minimumBadge = randomRequestToTmp[_idx]
            .minimumBadge;
        tixIdToTicket[tixId].destination = randomRequestToTmp[_idx].destination;
        tixIdToTicket[tixId].estimatedMetres = randomRequestToTmp[_idx]
            .estimatedMetres;
        tixIdToTicket[tixId].estimatedMinutes = randomRequestToTmp[_idx]
            .estimatedMinutes;
        addressToActive[passenger] = true;
        addressToProcessing[passenger] = false;

        addressToTixId[passenger] = tixId; // read this at frontend  // TODO: no need use if can use event
        emit SaltReceived(tixId, passenger);
    }

    // call before startTrip
    function cancelRequest(bytes32 _tixId)
        external
        paxMatchTixPax(_tixId, msg.sender)
        tripNotStart(_tixId)
    {
        address driver = tixIdToTicket[_tixId].driver;
        if (driver != address(0)) {
            // case when cancel inbetween driver accepted, but haven't reach passenger
            // give warning at frontend to passenger
            _swapTokens(_tixId, requestFee, msg.sender, driver);
        }

        _cleanUp(_tixId, msg.sender, driver);

        emit RequestCancelled(_tixId, msg.sender); // --> update frontend request pool
    }

    // input driver from say, QR scan etc
    function startTrip(bytes32 _tixId, address _driver)
        external
        paxMatchTixPax(_tixId, msg.sender)
        driverMatchTixDriver(_tixId, _driver)
        tripNotStart(_tixId)
    {
        addressToDriverReputation[_driver].countStart += 1;
        tixIdToTicket[_tixId].tripStart = true;

        emit TripStart(_tixId, msg.sender, _driver); // update frontend
    }

    // incentive to passenger to end trip to not get charged more
    // require confirmation from driver
    function endTripPassenger(bytes32 _tixId, uint256 _rating)
        external
        paxMatchTixPax(_tixId, msg.sender)
        tripInProgress(_tixId)
    {
        address driver = tixToEndDetails[_tixId].driver;
        require(
            tixToEndDetails[_tixId].driver != address(0),
            "driver must end trip"
        );

        bool destinationMatch = keccak256(
            bytes(tixToEndDetails[_tixId].destination)
        ) == keccak256(bytes(tixIdToTicket[_tixId].destination)); // https://ethereum.stackexchange.com/a/82739/82768

        uint256 fare = RideUtils._getFare(
            baseFare,
            tixToEndDetails[_tixId].metresTravelled,
            tixToEndDetails[_tixId].minutesTaken,
            costPerMetre,
            costPerMinute
        );

        // passenger still pays (up to travelled distance) even if journey ends abruptly (not inside destinationMatch check)
        _swapTokens(_tixId, fare, msg.sender, driver);

        if (destinationMatch) {
            addressToDriverReputation[driver]
                .metresTravelled += tixToEndDetails[_tixId].metresTravelled;
            addressToDriverReputation[driver].countEnd += 1;
        }
        _giveRating(driver, _rating);

        _cleanUp(_tixId, msg.sender, driver);

        emit PassengerEnd(_tixId, msg.sender);
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function _getRandomNumber() internal returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= feeLink, "not enough LINK");
        return requestRandomness(keyHash, feeLink);
    }

    function _giveRating(address _driver, uint256 _rating) internal {
        addressToDriverReputation[_driver].totalRating += _rating;
        addressToDriverReputation[_driver].countRating += 1;
    }
}

// SPDX-License-Identifier: MIT

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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RideBase is ReentrancyGuard, Initializable, Ownable {
    ERC20 public token;
    // bytes32 public constant ROLE_GOVERNANCE = keccak256("ROLE_GOVERNANCE");
    // bytes32 public constant ROLE_MULTISIG = keccak256("ROLE_MULTISIG"); // for quicker execution
    // bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN"); // for tasks like background checks

    bool public initialized;
    uint256 public collateralMultiplier;
    uint256 public requestFee; // only applies if request cancelled after X time has passed
    uint256 public baseFare;
    uint256 public costPerMetre;
    uint256 public costPerMinute;
    uint256 public maxTicketPool;

    mapping(address => uint256) public addressToDeposit;

    struct DriverReputation {
        // lifetime cumulative values
        uint256 id;
        string uri;
        uint256 maxMetresPerTrip;
        uint256 metresTravelled;
        uint256 countStart;
        uint256 countEnd;
        uint256 totalRating;
        uint256 countRating; // simplified out of formula, keep for display
    }
    mapping(address => DriverReputation) public addressToDriverReputation;

    struct Ticket {
        address passenger;
        address driver;
        uint256 minimumBadge;
        string destination;
        uint256 estimatedMetres;
        uint256 estimatedMinutes;
        bool tripStart;
    }
    mapping(bytes32 => Ticket) internal tixIdToTicket;
    mapping(address => bool) public addressToActive;

    struct EndDetails {
        address driver;
        string destination;
        uint256 metresTravelled;
        uint256 minutesTaken;
    }
    mapping(bytes32 => EndDetails) internal tixToEndDetails;

    event TokensSwapped(
        bytes32 indexed tixId,
        uint256 amount,
        address decrease,
        address increase
    );
    event Initialized(address token, address deployer);

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

    modifier initializedRideBase() {
        require(initialized, "not initialized");
        _;
    }

    // important that modifiers defined left to right for initializeRideBase,
    // as modifier execution order is left to right
    function initializeRideBase(
        address _tokenAddress,
        uint256 _collateralMultiplier, // input format: integer only, currently eg 2
        uint256 _requestFee, // input format: token in Wei
        uint256 _baseFare, // input format: token in Wei
        uint256 _costPerMetre, // input format: token in Wei // rounded down
        uint256 _costPerMinute // input format: token in Wei // rounded down (5:59 == 5 minutes)
    )
        external
        // uint256 _maxTicketPool // input format: token in Wei
        onlyOwner
        initializer
    {
        token = ERC20(_tokenAddress);
        collateralMultiplier = _collateralMultiplier;
        requestFee = _requestFee;
        baseFare = _baseFare;
        costPerMetre = _costPerMetre;
        costPerMinute = _costPerMinute;
        // maxTicketPool = _maxTicketPool;
        initialized = true;

        emit Initialized(_tokenAddress, msg.sender);
    }

    // call approve first
    // input is WEI
    function placeDeposit(uint256 _amount) external initializedRideBase {
        bool sent = token.transferFrom(
            msg.sender,
            payable(address(this)),
            _amount
        );
        require(sent, "tx failed");

        addressToDeposit[msg.sender] += _amount;
    }

    function removeDeposit() external notActive nonReentrant {
        uint256 amount = addressToDeposit[msg.sender];
        require(amount > 0, "deposit empty");
        addressToDeposit[msg.sender] = 0;
        bool sent = token.transfer(msg.sender, amount);
        require(sent, "tx failed");
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// ------------------------- internal functions ------------------------- /////
    ///// ---------------------------------------------------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    function _swapTokens(
        bytes32 _tixId,
        uint256 _amount,
        address _decrease,
        address _increase
    ) internal {
        addressToDeposit[_decrease] -= _amount;
        addressToDeposit[_increase] += _amount;

        emit TokensSwapped(_tixId, _amount, _decrease, _increase);
    }

    function _cleanUp(
        bytes32 _tixId,
        address _passenger,
        address _driver
    ) internal {
        delete tixIdToTicket[_tixId];
        delete tixToEndDetails[_tixId];
        addressToActive[_passenger] = false;
        addressToActive[_driver] = false;
    }

    //////////////////////////////////////////////////////////////////////////////////
    ///// ---------------------------------------------------------------------- /////
    ///// --------------------------- admin functions -------------------------- /////
    ///// --------------------------- use multicall ? -------------------------- /////
    //////////////////////////////////////////////////////////////////////////////////

    // TODO: backup function if for some reason driver/passenger didnt end trip - cleanUp not called

    function setCollateralMultiplier(uint256 _collateralMultiplier)
        external
        onlyOwner
    {
        collateralMultiplier = _collateralMultiplier; // input format: integer only, currently eg 2
    }

    function setRequestFee(uint256 _requestFee) external onlyOwner {
        requestFee = _requestFee; // input format: token in Wei
    }

    function setBaseFare(uint256 _baseFare) external onlyOwner {
        baseFare = _baseFare; // input format: token in Wei
    }

    function setCostPerMetre(uint256 _costPerMetre) external onlyOwner {
        costPerMetre = _costPerMetre; // input format: token in Wei // rounded down
    }

    function setCostPerMinute(uint256 _costPerMinute) external onlyOwner {
        costPerMinute = _costPerMinute; // input format: token in Wei // rounded down (5:59 == 5 minutes)
    }

    // function setMaxTicketPool(uint256 _maxTicketPool) external onlyOwner {
    //     maxTicketPool = _maxTicketPool; // input format: token in Wei
    // }

    function backgroundCheck(address _driver, string memory _uri)
        external
        onlyOwner
        initializedRideBase
    {
        require(
            bytes(addressToDriverReputation[_driver].uri).length == 0,
            "uri already set"
        );
        addressToDriverReputation[_driver].uri = _uri;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RideBadge is Ownable {
    uint256 public badgeBronze;
    uint256 public badgeSilver;
    uint256 public badgeGold;
    uint256 public badgePlatinum;
    uint256 public badgeVeteran;

    bool internal firstSet;

    function setBadge(uint256[] memory _badgesThreshold) external onlyOwner {
        badgeBronze = _badgesThreshold[0];
        badgeSilver = _badgesThreshold[1];
        badgeGold = _badgesThreshold[2];
        badgePlatinum = _badgesThreshold[3];
        badgeVeteran = _badgesThreshold[4];

        firstSet = true;
    }

    function _getBadge(uint256 _score) internal view returns (uint256) {
        require(firstSet, "not set before");

        if (_score < badgeBronze) {
            return 0; // badgeNewbie
        } else if (_score >= badgeBronze && _score < badgeSilver) {
            return 1; // badgeBronze
        } else if (_score >= badgeSilver && _score < badgeGold) {
            return 2; // badgeSilver
        } else if (_score >= badgeGold && _score < badgePlatinum) {
            return 3; // badgeGold
        } else if (_score >= badgePlatinum && _score < badgeVeteran) {
            return 4; // badgePlatinum
        } else {
            return 5; // badgeVeteran
        }
    }
}

// contract RideBadge is Ownable {
//     uint256 loopLength;

//     struct BadgeScoreRange {
//         string badgeName;
//         uint256 scoreStart;
//         uint256 scoreEnd;
//     }
//     mapping(uint256 => BadgeScoreRange) public indexToBadgeScoreRange;

//     constructor(uint256 _loopLength) {
//         loopLength = _loopLength; // badge ranking shouldn't be more than 10 usually
//     }

//     function setBadge(
//         uint256 _index,
//         string memory _name,
//         uint256 _scoreStart,
//         uint256 _scoreEnd
//     ) external onlyOwner {
//         indexToBadgeScoreRange[_index] = BadgeScoreRange({
//             badgeName: _name,
//             scoreStart: _scoreStart,
//             scoreEnd: _scoreEnd
//         });
//     }

//     function setLoopLength(uint256 _length) external onlyOwner {
//         loopLength = _length;
//     }

//     function _getBadge(uint256 _score) internal view returns (uint256) {
//         for (uint256 i = 0; i < loopLength; i++) {
//             if (
//                 _score >= indexToBadgeScoreRange[i].scoreStart &&
//                 _score < indexToBadgeScoreRange[i].scoreEnd
//             ) {
//                 return i;
//             }
//         }
//     }
// }

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library RideUtils {
    function _getFare(
        uint256 _baseFare,
        uint256 _metresTravelled,
        uint256 _minutesTaken,
        uint256 _costPerMetre,
        uint256 _costPerMinute
    ) internal pure returns (uint256) {
        // _metresTravelled & _minutesTaken should be whole numbers
        // _costPerMetre & _costPerMinute should be rounded down, if rounded to 0 then just charge baseFare only
        return (_baseFare +
            (_metresTravelled * _costPerMetre) +
            (_minutesTaken * _costPerMinute));
    }

    function _calculateScore(
        uint256 _metresTravelled,
        uint256 _totalRating,
        uint256 _countStart,
        uint256 _countEnd
    ) internal pure returns (uint256) {
        /**
         * metresTravelled == m
         * countStart == s
         * countEnd == e
         * totalRating == rt (sum(r1, r2, ... rN)
         * countRating == rc
         *
         * baseScore = m * e (accounts for [short distance | high count] && [long distance | low count])
         * apply weighting ratio to baseScore: baseScore * e/s
         * averageRating = rt/rc
         * apply weighting ratio to averageRating: averageRating * rc/e
         * combined score: m*e*(e/s) * (rt/rc)*(rc/e)
         * simplify: (m*e*rt)/s
         */
        // note: division rounds to zero
        if (_countStart == 0) {
            return 0;
        } else {
            return (_metresTravelled * _totalRating * _countEnd) / _countStart;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}