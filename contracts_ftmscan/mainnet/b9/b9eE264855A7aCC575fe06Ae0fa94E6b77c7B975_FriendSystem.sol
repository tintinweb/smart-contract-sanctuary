/**
 *Submitted for verification at FtmScan.com on 2021-11-25
 */

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

    function addFriend(address target) external {
        // Already requested
        require(
            !requestListStatus[msg.sender][target],
            "Requests were already sent"
        );
        // Already friends
        require(!friendListStatus[msg.sender][target], "Already friends");
        require(target != msg.sender, "Can not add yourself");
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

    function addManyFriends(address[] calldata friends) external {
        uint256 friendsLen = friends.length;
        uint256 i;
        for (i = 0; i < friendsLen; i++) {
            // If they are friends already
            address target = friends[i];
            if (friendListStatus[msg.sender][target]) {
                continue;
            }
            // If the request was already sent
            if (requestListStatus[msg.sender][target]) {
                continue;
            }
            if (msg.sender == target) {
                continue;
            }
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
    }

    function acceptAll() external {
        address[] memory friends = getPendingList(msg.sender);
        uint256 friendsLen = friends.length;
        uint256 i;
        for (i = 0; i < friendsLen; i++) {
            address target = friends[i];
            // Move request related status
            requestListLength[target] -= 1;
            pendingListStatus[msg.sender][target] = false;
            requestListStatus[target][msg.sender] = false;

            // Add friends related status
            friendListStatus[msg.sender][target] = true;
            friendListStatus[target][msg.sender] = true;

            friendList[msg.sender].push(target);
            friendList[target].push(msg.sender);
            friendListLength[msg.sender] += 1;
            friendListLength[target] += 1;
        }
        pendingListLength[msg.sender] = 0;
        delete pendingList[msg.sender];
    }

    function removeFriend(address target) external {
        require(friendListStatus[msg.sender][target], "Not friends");
        require(friendListStatus[target][msg.sender], "Not friends");
        // They are friends
        friendListLength[msg.sender] -= 1;
        friendListLength[target] -= 1;
        friendListStatus[msg.sender][target] = false;
        friendListStatus[target][msg.sender] = false;
        if (friendListLength[msg.sender] == 0) {
            delete friendList[msg.sender];
        }
        if (friendListLength[target] == 0) {
            delete friendList[target];
        }
    }

    function removeManyFriends(address[] calldata friends) external {
        uint256 friendsLen = friends.length;
        uint256 i;

        for (i = 0; i < friendsLen; i++) {
            address target = friends[i];
            if (!friendListStatus[msg.sender][target]) {
                continue;
            }
            if (msg.sender == target) {
                continue;
            }
            friendListLength[msg.sender] -= 1;
            friendListLength[target] -= 1;
            friendListStatus[msg.sender][target] = false;
            friendListStatus[target][msg.sender] = false;
            if (friendListLength[target] == 0) {
                delete friendList[target];
            }
        }
        if (friendListLength[msg.sender] == 0) {
            delete friendList[msg.sender];
        }
    }

    function getPendingList(address user)
        public
        view
        returns (address[] memory pending)
    {
        uint256 pendingLength = pendingList[user].length;
        uint256 i = 0;
        uint256 idx = 0;
        if (pendingListLength[user] == 0) {
            return pending;
        }
        pending = new address[](pendingListLength[user]);
        for (i = 0; i < pendingLength; i++) {
            if (pendingListStatus[user][pendingList[user][i]]) {
                pending[idx++] = pendingList[user][i];
            }
        }
    }

    function cancelManyPendings(address[] calldata pending) external {
        uint256 pendingLen = pending.length;
        uint256 i = 0;
        for (i = 0; i < pendingLen; i++) {
            pendingListStatus[msg.sender][pending[i]] = false;
            pendingListLength[msg.sender] -= 1;

            requestListStatus[pending[i]][msg.sender] = false;
            requestListLength[pending[i]] -= 1;

            if (requestListLength[pending[i]] == 0) {
                delete requestList[pending[i]];
            }
        }

        if (pendingListLength[msg.sender] == 0) {
            delete pendingList[msg.sender];
        }
    }

    function cancelAllPendings() external {
        address[] memory pending = getPendingList(msg.sender);
        uint256 pendingLen = pending.length;
        uint256 i = 0;
        for (i = 0; i < pendingLen; i++) {
            pendingListStatus[msg.sender][pending[i]] = false;

            requestListStatus[pending[i]][msg.sender] = false;
            requestListLength[pending[i]] -= 1;
            if (requestListLength[pending[i]] == 0) {
                delete requestList[pending[i]];
            }
        }
        pendingListLength[msg.sender] = 0;
        delete pendingList[msg.sender];
    }

    function getRequestList(address user)
        public
        view
        returns (address[] memory requests)
    {
        uint256 requestLength = requestList[user].length;
        uint256 i = 0;
        uint256 idx = 0;
        if (requestListLength[user] == 0) {
            return requests;
        }
        requests = new address[](requestListLength[user]);
        for (i = 0; i < requestLength; i++) {
            if (requestListStatus[user][requestList[user][i]]) {
                requests[idx++] = requestList[user][i];
            }
        }
    }

    function cancleManyRequests(address[] calldata requests) external {
        uint256 requestsLen = requests.length;
        uint256 i = 0;
        for (i = 0; i < requestsLen; i++) {
            requestListStatus[msg.sender][requests[i]] = false;
            requestListLength[msg.sender] -= 1;

            pendingListStatus[requests[i]][msg.sender] = false;
            pendingListLength[requests[i]] -= 1;

            if (pendingListLength[requests[i]] == 0) {
                delete pendingList[requests[i]];
            }
        }
        if (requestListLength[msg.sender] == 0) {
            delete requestList[msg.sender];
        }
    }

    function cancelAllRequests() external {
        address[] memory requests = getRequestList(msg.sender);
        uint256 requestsLen = requests.length;
        uint256 i = 0;
        for (i = 0; i < requestsLen; i++) {
            requestListStatus[msg.sender][requests[i]] = false;

            pendingListStatus[requests[i]][msg.sender] = false;
            pendingListLength[requests[i]] -= 1;
            if (pendingListLength[requests[i]] == 0) {
                delete pendingList[requests[i]];
            }
        }
        requestListLength[msg.sender] = 0;
        delete requestList[msg.sender];
    }

    function getFriendList(address user)
        public
        view
        returns (address[] memory friends)
    {
        uint256 friendLength = friendList[user].length;
        uint256 i = 0;
        uint256 idx = 0;
        if (friendListLength[user] == 0) {
            return friends;
        }
        friends = new address[](friendListLength[user]);
        for (i = 0; i < friendLength; i++) {
            if (friendListStatus[user][friendList[user][i]]) {
                friends[idx++] = friendList[user][i];
            }
        }
    }
}