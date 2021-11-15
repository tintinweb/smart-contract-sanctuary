pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/**
 * @title CarChain P2P RideHailing Contract
 * @notice This is a test contract
 * @dev This is Ride-Hailing-V 0.1
 */
contract PureRideHailing {
    using SafeMath for uint256;


    /*---------Variables & constructor----------*/

    /* address => state */
    mapping(address => User) public passengers;
    mapping(address => User) public drivers;

    mapping(address => Vehicle) public vehicle;

    mapping(uint256 => Trip) public trips;
    uint256 private trip_count;



    /*---------Modifiers----------*/

    modifier onlyDriver {
        require(drivers[msg.sender].exists);
        _;
    }

    modifier onlyPassenger {
        require(passengers[msg.sender].exists);
        _;
    }


    /*---------Methods----------*/

    /*-----Managment----*/

    /**
     * @notice Registering passengers
     * @dev the _name and _number parameters can be empty and are not mandatory
     * @param _name : Passenger's nickname
     * @param _number : Passenger's number
     */
    function p_register(string memory _name, string memory _number) public {
        require(!passengers[msg.sender].exists);

        passengers[msg.sender].name = _name;
        passengers[msg.sender].number = _number;
        passengers[msg.sender].exists = true;
    }

    /**
     * @notice Registration of driver
     * @dev the _name and _number parameters can be empty and are not mandatory
     * @param _name : Driver's nickname
     * @param _number : Driver's number
     */
    function d_register(string memory _name, string memory _number) public {
        require(!drivers[msg.sender].exists);

        drivers[msg.sender].name = _name;
        drivers[msg.sender].number = _number;
        drivers[msg.sender].exists = true;


    }


    /**
    * @notice use to edit passenger data
    * @param _name : Passenger's new name
    * @param _number : Passenger's new number
    */
    function p_edit(string memory _name, string memory _number) public onlyPassenger {
        passengers[msg.sender].name = _name;
        passengers[msg.sender].number = _number;
    }

    /**
    * @notice use to edit driver data
    * @param _name : Driver's new name
    * @param _number : Driver's new number
    */
    function d_edit(string memory _name, string memory _number) public onlyDriver {

        drivers[msg.sender].name = _name;
        drivers[msg.sender].number = _number;
    }



    /**
    * @notice edit/submit vehicle by driver
    * @param _brand : Car brand
    * @param _model : Car Model
    * @param _color : Car color
    * @param _plate : car plate
    */
    function edit_vehicle(string memory _brand, string memory _model, string memory _color, string memory _plate) public onlyDriver {

        vehicle[msg.sender].brand = _brand;
        vehicle[msg.sender].model = _model;
        vehicle[msg.sender].color = _color;
        vehicle[msg.sender].plate = _plate;
    }



    /*-----trip----*/

    /**
    * @notice Request a trip by passenger
    * @param _origin: Origin coordinates
    * @param _destination: Destination coordinates
    * @param _deadline: accepting bid deadline
    */
    function request_trip(string memory _origin, string memory _destination, uint256 _deadline) public onlyPassenger {
        //Passenger should not be in trip
        require(passengers[msg.sender].inTrip == 0);

        //make trip

        trip_count += 1;
        trips[trip_count].passenger = msg.sender;
        trips[trip_count].state = 0;
        trips[trip_count].originData = _origin;
        trips[trip_count].destinationData = _destination;
        trips[trip_count].deadline = _deadline;

        //emit event
        emit TripRequest(trip_count, _origin, _destination, _deadline);
    }

    /**
    * @notice Bid for a trip
    * @param _tripId: Id of the trip
    * @param _amount: the bid amount
    * @param _deadline: the bid deadline
    */
    function bid_trip(uint256 _tripId, uint256 _amount, uint256 _deadline) public onlyDriver {
        //Driver should not be in trip
        require(drivers[msg.sender].inTrip == 0);
        require(_tripId <= trip_count);
        //trip state should be pending for bids
        require(trips[_tripId].state == 0);
        //passenger's deadline
        require(block.timestamp < trips[_tripId].deadline);


        trips[_tripId].bids.push(
            Bid(_amount, msg.sender, _deadline)
        );

        //Emit
        emit TripBid(_tripId, trips[_tripId].bids.length-1 ,msg.sender, _amount, _deadline);

    }

    /**
    * @notice Get all Bids for a trip
    * @param _tripId: Id of the trip
    */
    function get_bids(uint256 _tripId) public view returns(Bid[] memory) {
        return trips[_tripId].bids;
    }

    /**
    * @notice Approve bid by passenger
    * @param _tripId: Id of the trip
    * @param _bidIndex: Bid index to approve
    */
    function approve_bid(uint256 _tripId, uint256 _bidIndex) onlyPassenger public{
        //Passenger should not be in trip
        require(passengers[msg.sender].inTrip == 0);
        require(_tripId <= trip_count);
        require(trips[_tripId].passenger == msg.sender);
        //trip state should be pending for bids
        require(trips[_tripId].state == 0);
        require(_bidIndex < trips[_tripId].bids.length);


        Bid memory _driverBid = trips[_tripId].bids[_bidIndex];
        //Driver should not be in trip
        require(drivers[_driverBid.driver].inTrip == 0);

        //driver's deadline
        require(block.timestamp < _driverBid.deadline);

        trips[_tripId].amount = _driverBid.amount;
        trips[_tripId].driver = _driverBid.driver;
        trips[_tripId].state = 1;

        drivers[_driverBid.driver].inTrip = _tripId;
        passengers[msg.sender].inTrip = _tripId;

        //emit Event
        emit TripStarted(_tripId, msg.sender, _driverBid.driver, _driverBid.amount);

    }

    /**
    * @notice End trip by passenger
    * @param _tripId : trip Id
    * @param _rate : rate
    */
    function end_trip_p(uint256 _tripId, uint8 _rate) public onlyPassenger {
        require(passengers[msg.sender].inTrip == _tripId);

        require(trips[_tripId].state == 1);
        require(!trips[_tripId].p_rated);
        require(0 < _rate && _rate < 6);

        trips[_tripId].p_rated = true;
        if (trips[_tripId].d_rated) {
            trips[_tripId].state = 3;
        }
        drivers[trips[_tripId].driver].rate_sum += uint256(_rate);
        drivers[trips[_tripId].driver].rate_count += 1;
        passengers[msg.sender].inTrip = 0;

        emit PassengerEndedTrip(_tripId, _rate);

    }

    /**
    * @notice End trip by driver
    * @param _tripId : trip Id
    * @param _rate : rate
    */
    function end_trip_d(uint256 _tripId, uint8 _rate) public onlyDriver {
        require(drivers[msg.sender].inTrip == _tripId);

        require(trips[_tripId].state == 1);
        require(!trips[_tripId].d_rated);
        require(0 < _rate && _rate < 6);

        trips[_tripId].d_rated = true;
        if (trips[_tripId].p_rated) {
            trips[_tripId].state = 3;
        }
        passengers[trips[_tripId].passenger].rate_sum += uint256(_rate);
        passengers[trips[_tripId].passenger].rate_count += 1;
        drivers[msg.sender].inTrip = 0;

        emit DriverEndedTrip(_tripId, _rate);

    }

    /**
    * @notice cancel trip or trip request
    * @param _tripId : trip Id
    */
    function cancel_trip_p(uint256 _tripId) public onlyPassenger {
        require(trips[_tripId].passenger == msg.sender);
        require(!trips[_tripId].p_rated);

        if (trips[_tripId].state == 1) {
            passengers[msg.sender].inTrip = 0;
            drivers[trips[_tripId].driver].inTrip = 0;
        }

        trips[_tripId].state = 2;

        emit TripCanceled(_tripId);

    }

    /**
     * @notice cancel trip or trip request
     * @param _tripId : trip Id
     */
    function cancel_trip_d(uint256 _tripId) public onlyDriver {
        require(trips[_tripId].driver == msg.sender);
        require(!trips[_tripId].d_rated);

        if (trips[_tripId].state == 1) {
            passengers[msg.sender].inTrip = 0;
            drivers[trips[_tripId].driver].inTrip = 0;
        }


        trips[_tripId].state = 2;

        emit TripCanceled(_tripId);

    }


    /*-----Signiture validation----*/



    /** Trip states
     * 0 => requested
     * 1 => driver joined
     * 2 => canceled
     * 3 => ended
     */
    struct Trip {
        uint256 amount;
        string originData;
        string destinationData;
        address passenger;
        address driver;
        uint256 deadline;
        uint8 state;
        bool d_rated; //rate submitted by driver
        bool p_rated; //rate submitted by passenger
        Bid[] bids;
    }

    struct Bid {
        uint256 amount;
        address driver;
        uint256 deadline;
    }

    struct User {
        string name;
        string number;
        bool exists;
        uint256 inTrip; //if 0 => free to have trips, if not => current tripId
        uint256 rate_sum;
        uint128 rate_count;
    }

    struct Vehicle {
        string brand;
        string model;
        string color;
        string plate;
    }

    /*---------Events----------*/

    event TripRequest(uint256 indexed tripId, string origin, string destination, uint256 deadline);
    event TripBid(uint256 indexed tripId, uint256 bidIndex , address driver, uint256 amount, uint256 deadline);
    event TripStarted(uint256 indexed tripId, address passenger, address driver, uint256 amount);
    event PassengerEndedTrip(uint256 indexed tripId, uint8 rate);
    event DriverEndedTrip(uint256 indexed tripId, uint8 rate);
    event TripCanceled(uint256 indexed tripId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

