// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title WorkerAuthManager
/// @author Danilo Tuler
pragma solidity ^0.7.0;

interface WorkerAuthManager {
    /// @notice Gives worker permission to act on a DApp
    /// @param _workerAddress address of the worker node to given permission
    /// @param _dappAddress address of the dapp that permission will be given to
    function authorize(address _workerAddress, address _dappAddress) external;

    /// @notice Removes worker's permission to act on a DApp
    /// @param _workerAddress address of the proxy that will lose permission
    /// @param _dappAddresses addresses of dapps that will lose permission
    function deauthorize(address _workerAddress, address _dappAddresses)
        external;

    /// @notice Returns is the dapp is authorized to be called by that worker
    /// @param _workerAddress address of the worker
    /// @param _dappAddress address of the DApp
    function isAuthorized(address _workerAddress, address _dappAddress)
        external
        view
        returns (bool);

    /// @notice Get the owner of the worker node
    /// @param workerAddress address of the worker node
    function getOwner(address workerAddress) external view returns (address);

    /// @notice A DApp has been authorized by a user for a worker
    event Authorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );

    /// @notice A DApp has been deauthorized by a user for a worker
    event Deauthorization(
        address indexed user,
        address indexed worker,
        address indexed dapp
    );
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

/// @title WorkerAuthManagerImpl
/// @author Danilo Tuler
pragma solidity ^0.7.0;

import "./WorkerManager.sol";
import "./WorkerAuthManager.sol";

contract WorkerAuthManagerImpl is WorkerAuthManager {
    WorkerManager workerManager;

    /// @dev permissions keyed by hash(user, worker, dapp)
    mapping(bytes32 => bool) private permissions;

    constructor(address _workerManager) {
        workerManager = WorkerManager(_workerManager);
    }

    modifier onlyByOwner(address _workerAddress) {
        require(
            workerManager.getOwner(_workerAddress) == msg.sender,
            "worker not hired by sender"
        );
        _;
    }

    function getAuthorizationKey(
        address _user,
        address _worker,
        address _dapp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _worker, _dapp));
    }

    function authorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByOwner(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == false, "dapp already authorized");

        // record authorization from that user
        permissions[key] = true;

        // emit event
        emit Authorization(msg.sender, _workerAddress, _dappAddress);
    }

    function deauthorize(address _workerAddress, address _dappAddress)
        public
        override
        onlyByOwner(_workerAddress)
    {
        bytes32 key = getAuthorizationKey(
            msg.sender,
            _workerAddress,
            _dappAddress
        );
        require(permissions[key] == true, "dapp not authorized");

        // record deauthorization from that user
        permissions[key] = false;

        // emit event
        emit Deauthorization(msg.sender, _workerAddress, _dappAddress);
    }

    function isAuthorized(address _workerAddress, address _dappAddress)
        public
        override
        view
        returns (bool)
    {
        return
            permissions[getAuthorizationKey(
                workerManager.getOwner(_workerAddress),
                _workerAddress,
                _dappAddress
            )];
    }

    function getOwner(address _workerAddress)
        public
        override
        view
        returns (address)
    {
        return workerManager.getOwner(_workerAddress);
    }

    /*
    // XXX: we can't do this because the worker need to accept the job before receiving an authorization
    function hireAndAuthorize(
        address payable _workerAddress,
        address _dappAddress
    ) public override payable {
        workerManager.hire(_workerAddress);
        authorize(_workerAddress, _dappAddress);
    }
    */
}

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