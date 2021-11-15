// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

contract BookingManager {
    enum RoomId { None, C01, C02, C03, C04, C05, C06, C07, C08, C09, C10, P01, P02, P03, P04, P05, P06, P07, P08, P09, P10 }

    event RoomBooked(RoomId roomId, uint hour, bytes32 userId);
    event RoomBookingCancelled(RoomId roomId, uint hour);

    struct UserBooking {
        mapping (uint => RoomId) bookings;
    }
    
    struct RoomBooking {
        mapping (uint => bytes32) bookings;
    }
    
    mapping (bytes32 => UserBooking) userBookings;
    mapping (uint => RoomBooking) roomBookings;

    function book(RoomId roomId, uint hour, bytes32 userId) public {
        require(hour <= 23, "The hour must be between 0 and 23 (inclusive)");
		require(userBookings[userId].bookings[hour] == RoomId.None, "This room is already booked at this hour");
        
        userBookings[userId].bookings[hour] = roomId;        
		roomBookings[uint(roomId)].bookings[hour] = userId;

        emit RoomBooked(roomId, hour, userId);
    }

	function cancelBooking(RoomId roomId, uint hour, bytes32 userId) public {
        require(hour <= 23, "The hour must be between 0 and 23 (inclusive)");
		require(userBookings[userId].bookings[hour] != RoomId.None, "This room is not booked at this hour");
        
		userBookings[userId].bookings[hour] = RoomId.None;
		roomBookings[uint(roomId)].bookings[hour] = 0;

		emit RoomBookingCancelled(roomId, hour);
	}
    
    function getBookings(bytes32 userId, uint hour) public view returns (RoomId) {
        return userBookings[userId].bookings[hour];
    }
}

