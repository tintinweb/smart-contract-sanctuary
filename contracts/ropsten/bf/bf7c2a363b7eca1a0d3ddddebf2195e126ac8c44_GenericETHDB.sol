/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract GenericETHDB {
    struct Node {
        address nodeAddress;
        bool isValid;
    }

    struct Dataset {
        string data;
        uint256 lastUpdated;
    }

    Node[] public validNodes;
    address payable public owner;
    string public DBName;

    Dataset[] datasetList;

    constructor(uint256 datasetCount, string memory dbName) {
        owner = payable(msg.sender);

        for (uint256 i = 0; i < datasetCount; i++) {
            datasetList.push(Dataset("", 0));
        }

        DBName = dbName;
    }

    modifier isOwner() {
        require(
            msg.sender == owner,
            "Caller is not the owner of this contract."
        );
        _;
    }

    modifier isOwnerOrValidNode() {
        if (msg.sender == owner) {
            _;
        } else {
            for (uint256 i = 0; i < validNodes.length; i++) {
                if (
                    validNodes[i].nodeAddress == msg.sender &&
                    validNodes[i].isValid
                ) {
                    _;
                }
            }
            revert("Caller is not in valid nodes list, and is not the owner.");
        }
    }

    function changeOwner(address newOwner) public isOwner {
        owner = payable(newOwner);
    }

    function setDataset(uint256 datasetID, string calldata data)
        public
        isOwnerOrValidNode
    {
        if (datasetList.length <= datasetID) {
            revert("There's no dataset with that ID.");
        } else {
            datasetList[datasetID].data = data;
            datasetList[datasetID].lastUpdated = block.timestamp;
        }
    }

    function getDataset(uint256 datasetID)
        public
        view
        returns (uint256, string memory)
    {
        if (datasetList.length <= datasetID) {
            revert("There's no dataset with that ID.");
        } else {
            return (
                datasetList[datasetID].lastUpdated,
                datasetList[datasetID].data
            );
        }
    }

    function createNewDataset() public isOwner returns (uint256) {
        uint256 newID = datasetList.length;
        datasetList.push(Dataset("", 0));

        return newID;
    }

    function withdraw() public isOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");

        if (!success) {
            revert("Unknown error.");
        }
    }

    function transfer(address to, uint256 amount) public isOwner {
        (bool success, ) = to.call{value: amount}("");

        if (!success) {
            revert("Not enough money?");
        }
    }

    receive() external payable {}
}