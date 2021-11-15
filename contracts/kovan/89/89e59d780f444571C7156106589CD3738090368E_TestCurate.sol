pragma solidity 0.7.6;

import ".././ICurate.sol";

contract TestCurate is ICurate {

    struct Item {
        bytes data; // The data describing the item.
        Status status; // The current status of the item.
    }

    mapping(bytes32 => Item) public override items;
    bytes32[] public override itemList;

    function addPolicy(uint256 _itemID, string calldata _data) external {
        items[bytes32(_itemID)] = Item({
            data: bytes(_data),
            status: Status.Registered
        });
        itemList.push(bytes32(_itemID));
    }

    function removePolicy(uint256 _itemID) external {
        items[bytes32(_itemID)] = Item({
            data: "",
            status: Status.Absent
        });
    }

    function getItemInfo(bytes32 _itemID)
        external
        view
        override
        returns (
            bytes memory data,
            Status status,
            uint numberOfRequests
        )
    {
        Item storage item = items[_itemID];
        return (
            item.data,
            item.status,
            1
        );
    }

    function getRequestInfo(bytes32 _itemID, uint _request)
        external
        view
        override
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint numberOfRounds,
            uint256 ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint metaEvidenceID
        )
    {
        return (
            false, // disputed
            0,
            0,
            false, // resolved
            [address(0x0), address(0x0), address(0x0)],
            0,
            0,
            payable(address(0x0)),
            "",
            0
        );
    }
}

pragma solidity 0.7.6;

interface ICurate {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    function itemList(uint256 _index) external returns (bytes32);
    function items(bytes32 _itemID) external view returns (bytes memory data, Status status);
    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (
            bytes memory data,
            Status status,
            uint numberOfRequests
        );
    function getRequestInfo(bytes32 _itemID, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint numberOfRounds,
            uint256 ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint metaEvidenceID
        );
}

