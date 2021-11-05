// Copyright 2010 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerManager
/// @author Danilo Tuler
pragma solidity ^0.7.0;

interface WorkerManager {
    /// @notice Returns true if worker node is available
    /// @param workerAddress address of the worker node
    function isAvailable(address workerAddress) external view returns (bool);

    /// @notice Returns true if worker node is pending
    /// @param workerAddress address of the worker node
    function isPending(address workerAddress) external view returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice Get the user of the worker node, which may not be the owner yet, or how was the previous owner of a retired node
    function getUser(address workerAddress) external view returns (address);

    /// @notice Returns true if worker node is owned by some user
    function isOwned(address workerAddress) external view returns (bool);

    /// @notice Asks the worker to work for the sender. Sender needs to pay something.
    /// @param workerAddress address of the worker
    function hire(address payable workerAddress) external payable;

    /// @notice Called by the worker to accept the job
    function acceptJob() external;

    /// @notice Called by the worker to reject a job offer
    function rejectJob() external payable;

    /// @notice Called by the user to cancel a job offer
    /// @param workerAddress address of the worker node
    function cancelHire(address workerAddress) external;

    /// @notice Called by the user to retire his worker.
    /// @param workerAddress address of the worker to be retired
    /// @dev this also removes all authorizations in place
    function retire(address payable workerAddress) external;

    /// @notice Returns true if worker node was retired by its owner
    function isRetired(address workerAddress) external view returns (bool);

    /// @notice Events signalling every state transition
    event JobOffer(address indexed worker, address indexed user);
    event JobAccepted(address indexed worker, address indexed user);
    event JobRejected(address indexed worker, address indexed user);
    event Retired(address indexed worker, address indexed user);
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerManagerImpl
/// @author Danilo Tuler
pragma solidity ^0.7.0;

import "./WorkerManager.sol";

contract WorkerManagerImpl is WorkerManager {
    /// @dev user can only hire a worker if he sends more than minimum value
    uint256 constant MINIMUM_FUNDING = 0.001 ether;

    /// @dev transfers bigger than maximum value should be done directly
    uint256 constant MAXIMUM_FUNDING = 3 ether;

    /// @notice A worker can be in 4 different states, starting from Available
    enum WorkerState {Available, Pending, Owned, Retired}

    /// @dev mapping from worker to its user
    mapping(address => address payable) private userOf;

    /// @dev mapping from worker to its internal state
    mapping(address => WorkerState) private stateOf;

    function isAvailable(address workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[workerAddress] == WorkerState.Available;
    }

    function isPending(address workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[workerAddress] == WorkerState.Pending;
    }

    function getOwner(address _workerAddress)
        public
        override
        view
        returns (address)
    {
        return
            stateOf[_workerAddress] == WorkerState.Owned
                ? userOf[_workerAddress]
                : address(0);
    }

    function getUser(address _workerAddress)
        public
        override
        view
        returns (address)
    {
        return userOf[_workerAddress];
    }

    function isOwned(address _workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[_workerAddress] == WorkerState.Owned;
    }

    function hire(address payable _workerAddress) public override payable {
        require(isAvailable(_workerAddress), "worker is not available");
        require(_workerAddress != address(0), "worker address can not be 0x0");
        require(msg.value >= MINIMUM_FUNDING, "funding below minimum");
        require(msg.value <= MAXIMUM_FUNDING, "funding above maximum");

        // set owner
        userOf[_workerAddress] = msg.sender;

        // change state
        stateOf[_workerAddress] = WorkerState.Pending;

        // transfer ether to worker
        _workerAddress.transfer(msg.value);

        // emit event
        emit JobOffer(_workerAddress, msg.sender);
    }

    function acceptJob() public override {
        require(
            userOf[msg.sender] != address(0),
            "worker does not have a job offer"
        );
        require(
            stateOf[msg.sender] == WorkerState.Pending,
            "worker not is not in pending state"
        );

        // change state
        stateOf[msg.sender] = WorkerState.Owned;
        // from now on getOwner will return the user

        // emit event
        emit JobAccepted(msg.sender, userOf[msg.sender]);
    }

    function rejectJob() public override payable {
        require(
            userOf[msg.sender] != address(0),
            "worker does not have a job offer"
        );

        address payable owner = userOf[msg.sender];

        // reset hirer back to null
        userOf[msg.sender] = address(0);

        // change state
        stateOf[msg.sender] = WorkerState.Available;

        // return the money
        owner.transfer(msg.value);

        // emit event
        emit JobRejected(msg.sender, userOf[msg.sender]);
    }

    function cancelHire(address _workerAddress) public override {
        require(
            userOf[_workerAddress] != address(0),
            "worker does not have a job offer"
        );

        require(
            userOf[_workerAddress] == msg.sender,
            "only hirer can cancel the offer"
        );

        // change state
        stateOf[_workerAddress] = WorkerState.Retired;

        // emit event
        emit JobRejected(_workerAddress, msg.sender);
    }

    function retire(address payable _workerAddress) public override {
        require(
            stateOf[_workerAddress] == WorkerState.Owned,
            "worker not owned"
        );
        require(
            userOf[_workerAddress] == msg.sender,
            "only owner can retire worker"
        );

        // change state
        stateOf[_workerAddress] = WorkerState.Retired;

        // emit event
        emit Retired(_workerAddress, msg.sender);
    }

    function isRetired(address _workerAddress)
        public
        override
        view
        returns (bool)
    {
        return stateOf[_workerAddress] == WorkerState.Retired;
    }
}