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
        uint checkInKey;
        bool isCreated;
    }

    Reservation[] private reservations;

    mapping (uint => uint) private reservationsOfReservationUnit;
    mapping (uint => uint) private reservationCountOfReservationUnit;
    mapping (uint => address) private reservationsOfOwner;
    mapping (address => uint) private reservationCountOfOwner;
    mapping (uint => Reservation) private reservationIdOfReservation;

    constructor() public{
        publicLock = IPublicLock(0x9D3BAd7746Df8941d88377f65edE7f5F42c88e1b);
        reservationManager = ReservationManager(0xEb5F8D3007e1241629Df2891Fe32a7CaBff158B1);
    }

    function refundReservation(uint reservationId, uint checkInKey) external
    {
        require(reservationIdOfReservation[reservationId].checkInKey == checkInKey);
        publicLock.cancelAndRefund(publicLock.getTokenIdFor(msg.sender));
    }

    function createReservation(uint reservationUnitId) external payable
    {
        require(msg.value >= publicLock.keyPrice());
        publicLock.purchase.value(msg.value)(publicLock.keyPrice(), msg.sender, address(0), '0x00');
        uint id = reservations.length;
        Reservation memory reservation = Reservation(id, generateRandomCheckInKey(id), true);
        reservations.push(reservation);
        reservationsOfReservationUnit[id] = reservationUnitId;
        reservationCountOfReservationUnit[reservationUnitId]++;
        reservationIdOfReservation[id] = reservations[id];
        reservationsOfOwner[id] = msg.sender;
        reservationCountOfOwner[msg.sender]++;
    }

    function generateRandomCheckInKey(uint id) private view returns (uint) {
        uint rand = uint(keccak256(abi.encodePacked(id)));
        return rand;
    }

    function getReservationsOfUnit(uint reservationUnitId) external view returns(Reservation[] memory)
    {
        Reservation[] memory res = new Reservation[](reservationCountOfReservationUnit[reservationUnitId]);
        uint count = 0;

        for(uint i = 0; i < reservations.length; i++)
        {
            if(reservationsOfReservationUnit[i] == reservationUnitId)
            {
                res[count++] = reservations[i];
            }
        }
        return res;
    }

    function getReservations() external view returns (Reservation[] memory)
    {
        return reservations;
    }

    function getReservationsOfOwner() external view returns (Reservation[] memory)
    {
        Reservation[] memory res = new Reservation[](reservationCountOfOwner[msg.sender]);
        uint count = 0;
        for (uint i = 0; i < reservations.length; i++)
        {
            if(reservationsOfOwner[i] == msg.sender)
            {
                res[count++] = reservations[i];
            }
        }

        return res;
    }

    function getKeyPrice() external view returns (uint) { return publicLock.keyPrice(); }
}