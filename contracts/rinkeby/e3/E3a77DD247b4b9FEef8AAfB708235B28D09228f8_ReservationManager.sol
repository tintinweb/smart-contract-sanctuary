/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract ReservationManager
{
    struct Provider
    {
        uint id;
        string name;
        bool isCreated;
    }

    struct ReservationUnit
    {
        uint id;
        uint16 possibleGuestCount;
        uint reservationCount;
        bool isCreated;
    }

    event NewProvider(address owner, Provider provider);
    event NewReservationUnit(address owner, uint providerId, string providerName, ReservationUnit reservationUnit);

    Provider[] private providers;
    ReservationUnit[] private reservationUnits;

    //owner mappings
    mapping (uint => address) private ownerOfProvider;
    mapping (address => Provider) private providerOfOwner;

    //reservationUnit mappings
    mapping (uint => uint) private reservationUnitOfProvider;
    mapping (uint => uint) private reservationUnitCountOfProvider;

    mapping (uint => Provider) private providerOfId;

    function createProvider(string memory name) public
    {
        require(!providerOfOwner[msg.sender].isCreated);

        uint id = providers.length;
        Provider memory provider = Provider(id, name, true);
        providers.push(provider);

        ownerOfProvider[id] = msg.sender;
        providerOfOwner[msg.sender] = provider;
        providerOfId[id] = provider;

        emit NewProvider(msg.sender, provider);
    }

    function createReservationUnit(uint16 guestCount) public
    {
        require(providerOfOwner[msg.sender].isCreated && guestCount > 0);

        uint id = reservationUnits.length;

        reservationUnits.push(ReservationUnit(id, guestCount, 0, true));
        reservationUnitOfProvider[id] = providerOfOwner[msg.sender].id;
        reservationUnitCountOfProvider[providerOfOwner[msg.sender].id]++;

        emit NewReservationUnit(msg.sender, providerOfOwner[msg.sender].id, providerOfOwner[msg.sender].name, reservationUnits[id]);
    }

    function getProviders() public view returns(Provider[] memory)
    {
        return providers;
    }

    function increaseUnitReservationCount(uint unitId) external
    {
        reservationUnits[unitId].reservationCount++;
    }

    function getCurrentProvider() public view returns(Provider memory)
    {
        return providerOfOwner[msg.sender];
    }

    function getReservationUnits() public view returns(ReservationUnit[] memory)
    {
        return reservationUnits;
    }

    function getReservationUnitsOfProvider(uint id) public view returns(ReservationUnit[] memory)
    {
        require(providerOfId[id].isCreated);
        uint count = 0;
        ReservationUnit[] memory ru = new ReservationUnit[](reservationUnitCountOfProvider[id]);

        for(uint i = 0;i < reservationUnits.length; i++)
        {
            if(reservationUnitOfProvider[i] == id)
                ru[count++] = reservationUnits[i];
        }
        return ru;
    }
}