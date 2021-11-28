/**
 *Submitted for verification at FtmScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract FriendSystem {

    mapping(address => address[]) public friendList;
    mapping(address => mapping(address => bool)) public friendListStatus;
    mapping(address => uint256) public friendListLength;
    
    mapping(address => address[]) public pendingList;
    mapping(address => mapping(address => bool)) public pendingListStatus;
    mapping(address => uint256) public pendingListLength;

    mapping(address => address[]) public requestList;
    mapping(address => mapping(address => bool)) public requestListStatus;
    mapping(address => uint256) public requestListLength;


    function addFriend(
        address target
    ) external {
        // Already requested
        require(!requestListStatus[msg.sender][target], "Requests were already sent"); 
        // Already friends
        require(!friendListStatus[msg.sender][target], "Already friends");
        // Requested friend is in the pending status
        if (pendingListStatus[msg.sender][target]) {
            // Move request related status
            requestListLength[target] -= 1;
            pendingListLength[msg.sender] -= 1;
            pendingListStatus[msg.sender][target] = false;
            requestListStatus[target][msg.sender] = false;

            // Add friends related status
            friendListStatus[msg.sender][target] = true;
            friendListStatus[target][msg.sender] = true;

            friendList[msg.sender].push(target);
            friendList[target].push(msg.sender);
            friendListLength[msg.sender] += 1;
            friendListLength[target] += 1;
        } else {
            // Send requests
            pendingListStatus[target][msg.sender] = true;
            requestListStatus[msg.sender][target] = true;      

            // Add to list
            requestList[msg.sender].push(target);
            pendingList[target].push(msg.sender);
            requestListLength[msg.sender] += 1;
            pendingListLength[target] += 1;
        }
    }

    function getPendingList(address user) public view returns (address[] memory pending) {
        uint256 pendingLength = pendingList[user].length;
        uint256 i = 0;
        uint256 idx = 0;
        if (pendingListLength[user] == 0) {
            return pending;
        }
        pending = new address[](pendingListLength[user]);
        for (i = 0; i<pendingLength; i++) {
            if (pendingListStatus[user][pendingList[user][i]]) {
                pending[idx++] = pendingList[user][i];
            }
        }
    }

    function getRequsetList(address user) public view returns (address[] memory requests) {
        uint256 requestLength = requestList[user].length;
        uint256 i = 0;
        uint256 idx = 0;
        if (requestListLength[user] == 0) {
            return requests;
        }
        requests = new address[](requestListLength[user]);
        for (i = 0; i<requestLength; i++) {
            if (requestListStatus[user][requestList[user][i]]) {
                requests[idx++] = requestList[user][i];
            }
        }
    } 


    function getFriendList(address user) public view returns (address[] memory friends) {
        return friendList[user];
    }
}