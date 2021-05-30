// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IPublicLock.sol";
import "./ReservationManager.sol";

contract ReservationContract
{
    IPublicLock internal publicLock;
    ReservationManager internal reservationManager;

    struct Reservation
    {
        uint id;
        bool isCreated;
    }

    Reservation[] private reservations;

    mapping (uint => Reservation) private reservationsOfReservationUnit;

    constructor() public{
        publicLock = IPublicLock(0x9D3BAd7746Df8941d88377f65edE7f5F42c88e1b);
        reservationManager = ReservationManager(0x9FFA978Bd0f6e35653a7fd756CfbcfACa9952Ab7);
    }

    function refundReservation(uint reservationId, uint checkInKey) external
    {
        //require();
    }

    function createReservation(ReservationManager.ReservationUnit calldata reservationUnit) external payable
    {
        require(msg.value >= publicLock.keyPrice());
        publicLock.purchase.value(msg.value)(publicLock.keyPrice(), msg.sender, address(0), '0x00');
        uint id = reservations.length;
        reservations[id] = Reservation(id, true);
        reservationsOfReservationUnit[reservationUnit.id] = reservations[id];
    }

    function getReservation(uint reservationUnitId) external view returns(Reservation memory)
    {
        require(reservationsOfReservationUnit[reservationUnitId].isCreated);
        return reservationsOfReservationUnit[reservationUnitId];
    }

    function getKeyPrice() external view returns (uint) { return publicLock.keyPrice(); }
}