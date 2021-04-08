/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract BadgeFactory {

    event BadgeDefinitionCreated(string badgeName, string entity, string property, bool preAwardValue, bool postAwardValue);

    address public governance;
    address public badgeRecipientOracle;
    address public badgeRecipientCuration; // not implemented

    string public queryURL;

    constructor(string memory _queryURL) {
        governance = msg.sender;
        queryURL = _queryURL;
    }

    function setQueryURL(string memory queryURLString) public {
        require (msg.sender == governance, "!governance");

        queryURL = queryURLString;
    }

    function setBadgeRecipientOracle(address oracleAddress) public {
        require (msg.sender == governance, "!governance");

        badgeRecipientOracle = oracleAddress;
    }

    function setBadgeRecipientCuration(address curationAddress) public {
        require (msg.sender == governance, "!governance");

        badgeRecipientCuration = curationAddress;
    }

    function createBadgeDefinition(
        string calldata badgeName,
        string calldata entity,
        string calldata property,
        bool preAwardValue,
        bool postAwardValue) public {
            
        require (msg.sender == governance, "!governance");

        emit BadgeDefinitionCreated(badgeName, entity, property, preAwardValue, postAwardValue);
    }

}