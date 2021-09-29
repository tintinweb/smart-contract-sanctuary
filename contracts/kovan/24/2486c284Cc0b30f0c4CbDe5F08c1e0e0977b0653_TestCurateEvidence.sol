pragma solidity 0.7.6;

import ".././ICurate.sol";

contract TestCurateEvidence is ICurate {

    struct Item {
        bytes data; // The data describing the item.
        Status status; // The current status of the item.
    }

    mapping(bytes32 => Item) public override items;
    mapping(bytes32 => address) public submitter;
    bytes32[] public override itemList;

    function addEvidence(uint256 _itemID, bytes calldata _data) external {
        items[bytes32(_itemID)] = Item({
            data: _data,
            status: Status.Registered
        });
        itemList.push(bytes32(_itemID));
        submitter[bytes32(_itemID)] = msg.sender;
    }

    function addPendingEvidence(uint256 _itemID, bytes calldata _data) external {
        items[bytes32(_itemID)] = Item({
            data: _data,
            status: Status.RegistrationRequested
        });
        itemList.push(bytes32(_itemID));
        submitter[bytes32(_itemID)] = msg.sender;
    }

    function addRemovingEvidence(uint256 _itemID, bytes calldata _data) external {
        items[bytes32(_itemID)] = Item({
            data: _data,
            status: Status.ClearingRequested
        });
        itemList.push(bytes32(_itemID));
        submitter[bytes32(_itemID)] = msg.sender;
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

        disputed = false;
        disputeID = 0;
        submissionTime = 0;
        resolved = false;
        parties = getParties(_itemID);
        numberOfRounds = 0;
        ruling = 0;
        arbitrator = payable(address(0x0));
        arbitratorExtraData = "";
        metaEvidenceID = 0;
    }

    function getParties(bytes32 _itemID) internal view returns(address payable[3] memory) {
        return [address(0x0), payable(submitter[_itemID]), address(0x0)];
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}