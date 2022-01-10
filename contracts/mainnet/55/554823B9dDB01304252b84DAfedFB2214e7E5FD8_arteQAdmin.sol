/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "./IarteQAdmin.sol";

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
///
/// Reviewed and revised by: Masoud Khosravi <masoud_at_2b.team> <mkh_at_arteq.io>
///                          Ali Jafari <ali_at_2b.team> <aj_at_arteq.io>
///
/// @title The admin contract managing all other artèQ contracts
///
/// We achieve the followings by using this contract as the admin
/// account of any other artèQ contract:
///
/// 1) If one or two of the admin private keys are leaked out, other
///    admins can remove or replace the affected admin accounts.
///
/// 2) The contract having this account set as its admin account
///    cannot perform any adminitrative task without gathering
///    enough approvals from all admins (more than 50% of the admins
///    must approve a task).
///
///  3) With enough events emitted by this contract, any misuse of
///     administrative powers or a malicious behavior can be easily
///     tracked down, and if all other admins agree, the offender
///     account can get removed or replaced.
///
/// @notice Use at your own risk
contract arteQAdmin is IarteQAdmin {

    uint public MAX_NR_OF_ADMINS = 10;
    uint public MIN_NR_OF_ADMINS = 5;

    mapping (address => uint) private _admins;
    mapping (address => uint) private _finalizers;

    mapping (uint256 => uint) private _tasks;
    mapping (uint256 => mapping(address => uint)) private _taskApprovals;
    mapping (uint256 => uint) private _taskApprovalsCount;
    mapping (uint256 => string) private _taskURIs;

    uint private _nrOfAdmins;
    uint private _minRequiredNrOfApprovals;
    uint256 private _taskIdCounter;

    modifier onlyOneOfAdmins() {
        require(_admins[msg.sender] == 1, "arteQAdmin: not an admin account");
        _;
    }

    modifier onlyFinalizer() {
        require(_finalizers[msg.sender] == 1, "arteQAdmin: not a finalizer account");
        _;
    }

    modifier taskMustExist(uint256 taskId) {
        require(_tasks[taskId] == 1, "arteQAdmin: task does not exist");
        _;
    }

    modifier mustBeOneOfAdmins(address account) {
        require(_admins[account] == 1, "arteQAdmin: not an admin account");
        _;
    }

    modifier taskMustBeApproved(uint256 taskId) {
        require(_taskApprovalsCount[taskId] >= _minRequiredNrOfApprovals, "arteQAdmin: task is not approved");
        _;
    }

    constructor(address[] memory initialAdmins) {
        require(initialAdmins.length >= MIN_NR_OF_ADMINS, "arteQAdmin: not enough inital admins");
        require(initialAdmins.length <= MAX_NR_OF_ADMINS, "arteQAdmin: max nr of admins exceeded");
        _nrOfAdmins = 0;
        for (uint i = 0; i < initialAdmins.length; i++) {
            address admin = initialAdmins[i];
            _admins[admin] = 1;
            _nrOfAdmins++;
            emit AdminAdded(msg.sender, admin);
        }

        _minRequiredNrOfApprovals = 1 + uint(initialAdmins.length) / uint(2);
        emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);

        _taskIdCounter = 1;
    }

    function minNrOfAdmins() external view virtual override returns (uint) {
        return MIN_NR_OF_ADMINS;
    }

    function maxNrOfAdmins() external view virtual override returns (uint) {
        return MAX_NR_OF_ADMINS;
    }

    function nrOfAdmins() external view virtual override returns (uint) {
        return _nrOfAdmins;
    }

    function minRequiredNrOfApprovals() external view virtual override returns (uint) {
        return _minRequiredNrOfApprovals;
    }

    function isFinalizer(address account) external view virtual override onlyOneOfAdmins returns (bool) {
        return _finalizers[account] == 1;
    }

    function addFinalizer(uint256 taskId, address toBeAdded) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_finalizers[toBeAdded] == 0, "arteQAdmin: already a finalizer account");
        _finalizers[toBeAdded] = 1;
        emit FinalizerAdded(msg.sender, toBeAdded);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function removeFinalizer(uint256 taskId, address toBeRemoved) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_finalizers[toBeRemoved] == 1, "arteQAdmin: not a finalizer account");
        _finalizers[toBeRemoved] = 0;
        emit FinalizerRemoved(msg.sender, toBeRemoved);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function createTask(string memory detailsURI) external virtual override onlyOneOfAdmins {
        uint256 taskId = _taskIdCounter;
        _taskIdCounter++;
        _tasks[taskId] = 1;
        _taskApprovalsCount[taskId] = 0;
        _taskURIs[taskId] = detailsURI;
        emit TaskCreated(msg.sender, taskId, detailsURI);
    }

    function taskURI(uint256 taskId) external view virtual override onlyOneOfAdmins taskMustExist(taskId) returns (string memory) {
        return _taskURIs[taskId];
    }

    function approveTask(uint256 taskId) external virtual override onlyOneOfAdmins taskMustExist(taskId) {
        require(_taskApprovals[taskId][msg.sender] == 0, "arteQAdmin: already approved");
        _taskApprovals[taskId][msg.sender] = 1;
        _taskApprovalsCount[taskId]++;
        emit TaskApproved(msg.sender, taskId);
    }

    function cancelTaskApproval(uint256 taskId) external virtual override onlyOneOfAdmins taskMustExist(taskId) {
        require(_taskApprovals[taskId][msg.sender] == 1, "arteQAdmin: no approval to cancel");
        _taskApprovals[taskId][msg.sender] = 0;
        _taskApprovalsCount[taskId]--;
        emit TaskApprovalCancelled(msg.sender, taskId);
    }

    function nrOfApprovals(uint256 taskId) external view virtual override onlyOneOfAdmins taskMustExist(taskId) returns (uint) {
        return _taskApprovalsCount[taskId];
    }

    function finalizeTask(address origin, uint256 taskId) external virtual override
      onlyFinalizer
      mustBeOneOfAdmins(origin)
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, origin, taskId);
    }

    function isAdmin(address account) external view virtual override onlyOneOfAdmins returns (bool) {
        return _admins[account] == 1;
    }

    function addAdmin(uint256 taskId, address toBeAdded) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_nrOfAdmins < MAX_NR_OF_ADMINS, "arteQAdmin: cannot have more admin accounts");
        require(_admins[toBeAdded] == 0, "arteQAdmin: already an admin account");
        _admins[toBeAdded] = 1;
        _nrOfAdmins++;
        emit AdminAdded(msg.sender, toBeAdded);
        // adjust min required nr of approvals
        if (_minRequiredNrOfApprovals < (1 + uint(_nrOfAdmins) / uint(2))) {
            _minRequiredNrOfApprovals = 1 + uint(_nrOfAdmins) / uint(2);
            emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        }
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function replaceAdmin(uint256 taskId, address toBeRemoved, address toBeReplaced) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_admins[toBeRemoved] == 1, "arteQAdmin: no admin account found");
        require(_admins[toBeReplaced] == 0, "arteQAdmin: already an admin account");
        _admins[toBeRemoved] = 0;
        _admins[toBeReplaced] = 1;
        emit AdminReplaced(msg.sender, toBeRemoved, toBeReplaced);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function removeAdmin(uint256 taskId, address toBeRemoved) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(_nrOfAdmins > MIN_NR_OF_ADMINS, "arteQAdmin: cannot have fewer admin accounts");
        require(_admins[toBeRemoved] == 1, "arteQAdmin: no admin account found");
        _admins[toBeRemoved] = 0;
        _nrOfAdmins--;
        emit AdminRemoved(msg.sender, toBeRemoved);
        // adjust min required nr of approvals
        if (_minRequiredNrOfApprovals > _nrOfAdmins) {
            _minRequiredNrOfApprovals = _nrOfAdmins;
            emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        }
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    function setMinRequiredNrOfApprovals(uint256 taskId, uint newMinRequiredNrOfApprovals) external virtual override
      onlyOneOfAdmins
      taskMustExist(taskId)
      taskMustBeApproved(taskId) {
        require(newMinRequiredNrOfApprovals != _minRequiredNrOfApprovals , "arteQAdmin: same value");
        require(newMinRequiredNrOfApprovals > uint(_nrOfAdmins) / uint(2) , "arteQAdmin: value is too low");
        require(newMinRequiredNrOfApprovals <= _nrOfAdmins, "arteQAdmin: value is too high");
        _minRequiredNrOfApprovals = newMinRequiredNrOfApprovals;
        emit NewMinRequiredNrOfApprovalsSet(msg.sender, _minRequiredNrOfApprovals);
        // finalize task
        _tasks[taskId] = 0;
        emit TaskFinalized(msg.sender, msg.sender, taskId);
    }

    receive() external payable {
        revert("arteQAdmin: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQAdmin: cannot accept ether");
    }
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
/// @title The interface of the admin contract controlling all other artèQ smart contracts
interface IarteQAdmin is IarteQTaskFinalizer {

    event TaskCreated(address creatorAdmin, uint256 taskId, string detailsURI);
    event TaskApproved(address approverAdmin, uint256 taskId);
    event TaskApprovalCancelled(address cancellerAdmin, uint256 taskId);
    event FinalizerAdded(address granter, address newFinalizer);
    event FinalizerRemoved(address revoker, address removedFinalizer);
    event AdminAdded(address granter, address newAdmin);
    event AdminReplaced(address replacer, address removedAdmin, address replacedAdmin);
    event AdminRemoved(address revoker, address removedAdmin);
    event NewMinRequiredNrOfApprovalsSet(address setter, uint minRequiredNrOfApprovals);

    function minNrOfAdmins() external view returns (uint);
    function maxNrOfAdmins() external view returns (uint);
    function nrOfAdmins() external view returns (uint);
    function minRequiredNrOfApprovals() external view returns (uint);

    function isFinalizer(address account) external view returns (bool);
    function addFinalizer(uint256 taskId, address toBeAdded) external;
    function removeFinalizer(uint256 taskId, address toBeRemoved) external;

    function createTask(string memory detailsURI) external;
    function taskURI(uint256 taskId) external view returns (string memory);
    function approveTask(uint256 taskId) external;
    function cancelTaskApproval(uint256 taskId) external;
    function nrOfApprovals(uint256 taskId) external view returns (uint);

    function isAdmin(address account) external view returns (bool);
    function addAdmin(uint256 taskId, address toBeAdded) external;
    function replaceAdmin(uint256 taskId, address toBeRemoved, address toBeReplaced) external;
    function removeAdmin(uint256 taskId, address toBeRemoved) external;
    function setMinRequiredNrOfApprovals(uint256 taskId, uint newMinRequiredNrOfApprovals) external;
}

/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

/// @author Kam Amini <[email protected]> <[email protected]> <[email protected]>
/// @title The interface for finalizing tasks. Mainly used by artèQ contracts to
/// perform administrative tasks in conjuction with admin contract.
interface IarteQTaskFinalizer {

    event TaskFinalized(address finalizer, address origin, uint256 taskId);

    function finalizeTask(address origin, uint256 taskId) external;
}