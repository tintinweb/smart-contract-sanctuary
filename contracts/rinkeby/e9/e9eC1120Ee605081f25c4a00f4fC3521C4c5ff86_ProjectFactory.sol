pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

import "./Project.sol";
import "./external/contracts/proxy/CloneFactory.sol";

/**
 * @title ProjectFactory
 * @dev This contract is used by rigor to create cheap clones of Project contract implementation
 */
contract ProjectFactory is CloneFactory {
    //master implementation of project contract
    address public implementation;

    // address of the latest rigor contract
    address public rigor;

    /**
     * @dev initialize this contract with rigor and master project address
     * @param _implementation the implementation address of project smart contract
     * @param _rigor the latest address of rigor contract
     */
    constructor(address _implementation, address _rigor) {
        implementation = _implementation;
        rigor = _rigor;
    }

    /**
     * @dev create a clone for project contract
     * @notice this function can only be called by Rigor contract
     * @param _hash bytes ipfs hash for project
     * @param _currency address of the currency used by project
     * @param _sender address of the sender, builder
     * @return _clone address of the clone project contract
     */
    function createProject(
        bytes memory _hash,
        address _currency,
        address _sender
    ) external returns (address _clone) {
        require(msg.sender == rigor, "Only Rigor");
        _clone = createClone(implementation);
        Project(_clone).initialize(_hash, _currency, _sender, rigor);
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

import "./interfaces/IProject.sol";

/**
 * @title Deployable Project Contract for HomeFi v0.1.0
 * @notice This contract is for project management of HomeFi.
 * Project contract responsible for aggregating payments and data by/ for users on-chain
 * @dev This contract is created as a clone copy for the end user
 */
contract Project is IProject, SignatureDecoder {
    // using Tasks library for Task struct
    using Tasks for Task;

    /// @dev to make sure master implementation cannot be initialized
    constructor() initializer {}

    function initialize(
        bytes memory _hash,
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external override initializer {
        IHomeFi _homeFi = IHomeFi(_homeFiAddress);
        eventsInstance = _homeFi.eventsInstance();
        builderFee = _homeFi.builderFee();
        investorFee = _homeFi.investorFee();
        homeFi = _homeFi;
        builder = _sender;
        projectHash = _hash;
        currency = _currency;
    }

    // Project-Specific //

    function inviteContractor(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external override contractorNotAccepted onlyBuilder {
        require(_contractor != address(0), "5");
        address _oldContractor = contractor;
        contractor = _contractor;
        if (_oldContractor != address(0)) {
            // delete all previous records
            for (uint256 i = 1; i <= phaseCount; i++) {
                delete phases[phaseCount].phaseCost;
            }
            phaseCount = 0;
        }
        // set new fee schedule
        for (uint256 i = 0; i < _feeSchedule.length; i++) {
            phaseCount += 1;
            checkPrecision(_feeSchedule[i]);
            phases[phaseCount].phaseCost = _feeSchedule[i]; //starts from 1
        }
        eventsInstance.contractorInvited(contractor, _feeSchedule);
    }

    function acceptInviteContractor() external override contractorNotAccepted {
        require(msgSender() == contractor, "6");
        // before GC is added project cost is Phase cost
        require(totalInvested == projectCost(), "7");
        /* set totalAllocated to total phase cost
        hence this amount will be reversed for GC*/
        totalAllocated = totalInvested;
        contractorConfirmed = true;
        eventsInstance.contractorConfirmed(contractor);
    }

    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        if (contractorConfirmed) {
            checkSignature(_data, _signature);
        } else {
            address[3] memory _a = recoverAddresses(_data, _signature, 1);
            require(_a[0] == builder, "8");
        }
        (bytes memory _hash, uint256 _nonce) = abi.decode(
            _data,
            (bytes, uint256)
        );
        require(_nonce == hashChangeNonce, "9");
        projectHash = _hash;
        hashChangeNonce += 1;
        eventsInstance.hashUpdated(projectHash);
    }

    function addPhasesGC(bytes calldata _data, bytes calldata _signature)
        external
        override
        contractorAccepted
    {
        checkSignature(_data, _signature);
        (
            uint256[] memory _phaseCost,
            uint256 _phaseCount,
            address _projectAddress
        ) = abi.decode(_data, (uint256[], uint256, address));
        require(
            _phaseCount == phaseCount && _projectAddress == address(this),
            "10"
        );
        uint256 _phaseCostLength = _phaseCost.length;
        for (uint256 i = 0; i < _phaseCostLength; i++) {
            // add new phase and mark it as nonFunded
            phaseCount += 1;
            checkPrecision(_phaseCost[i]);
            phases[phaseCount].phaseCost = _phaseCost[i];
            nonFundedPhase.push(phaseCount);
        }
        eventsInstance.phasesAdded(_phaseCost);
    }

    function changeCostGC(bytes calldata _data, bytes calldata _signature)
        external
        override
        contractorAccepted
    {
        checkSignature(_data, _signature);
        (
            uint256[] memory _phaseList,
            uint256[] memory _phaseCost,
            address _projectAddress /* For signature security */
        ) = abi.decode(_data, (uint256[], uint256[], address));
        require(_phaseList.length == _phaseCost.length, "11");
        require(_projectAddress == address(this), "12");
        uint256 _phaseLength = _phaseList.length;
        for (uint256 i = 0; i < _phaseLength; i++) {
            require(!phases[_phaseList[i]].paid, "13");
            checkPrecision(_phaseCost[i]);
            uint256 _oldCost = phases[_phaseList[i]].phaseCost;
            phases[_phaseList[i]].phaseCost = _phaseCost[i];
            if (_oldCost > _phaseCost[i]) {
                /* reduce difference of old - new phase from totalAllocated */
                totalAllocated -= _oldCost - _phaseCost[i];
            } else if (_oldCost < _phaseCost[i]) {
                /* reduce old phase cost from totalAllocated
                mark the phase as nonFunded */
                totalAllocated -= _oldCost;
                nonFundedPhase.push(_phaseList[i]);
            }
        }
        nonFundedPhase = sortArray(nonFundedPhase);
        eventsInstance.phaseUpdated(_phaseList, _phaseCost);
    }

    function releaseFeeContractor(uint256 _phase)
        external
        override
        onlyBuilder
        contractorAccepted
    {
        require(_phase < phaseCount, "14");
        require(!phases[_phase].paid, "15");

        for (uint256 i = 0; i < phases[_phase].phaseToTaskList.length; i++) {
            if (tasks[phases[_phase].phaseToTaskList[i]].getState() != 3) {
                revert("33");
            }
        }

        phases[_phase].paid = true;
        payFee(contractor, phases[_phase].phaseCost);
        eventsInstance.contractorFeeReleased(_phase);
    }

    function investInProject(uint256 _cost)
        external
        payable
        override
        nonReentrant
    {
        require(
            msgSender() == builder || msgSender() == homeFi.communityContract(),
            "16"
        );
        require(_cost > 0, "17");
        require(projectCost() >= uint256(totalInvested + _cost), "18");

        if (msgSender() == builder) {
            if (currency == homeFi.ETHER_CURRENCY()) {
                require(_cost == msg.value, "19");
            } else {
                IERC20 _token = IERC20(currency);
                _token.transferFrom(msgSender(), address(this), _cost);
            }
        }

        totalInvested += _cost;
        eventsInstance.investedInProject(_cost);
        fundProject();
    }

    // Task Specific //

    function addTask(bytes calldata _data, bytes calldata _signature)
        external
        override
        contractorAccepted
    {
        checkSignature(_data, _signature);
        (
            uint256 _phase,
            bytes32[] memory _hash1,
            bytes32[] memory _hash2,
            uint256[] memory _cost,
            address[] memory _sc,
            uint256 _taskSerial,
            address _projectAddress
        ) = abi.decode(
                _data,
                (
                    uint256,
                    bytes32[],
                    bytes32[],
                    uint256[],
                    address[],
                    uint256,
                    address
                )
            );
        require(
            _phase != 0 && _phase <= phaseCount && !phases[_phase].paid,
            "20"
        );
        require(
            _taskSerial == taskSerial && _projectAddress == address(this),
            "21"
        );
        require(
            _hash1.length == _hash2.length &&
                _hash1.length == _cost.length &&
                _hash1.length == _sc.length,
            "22"
        );
        //array for index to add sc
        // array for sc for that index
        uint256[] memory _indexToInvite = new uint256[](_hash1.length);
        address[] memory _scToInvite = new address[](_hash1.length);
        uint256 _j = 0;

        if (nonFundedPhaseToTask[_phase].length == 0) {
            uint256 _length = nonFundedTaskPhases.length;
            nonFundedTaskPhases.push(_phase);
            if (_length > 0 && nonFundedTaskPhases[_length - 1] > _phase) {
                nonFundedTaskPhases = sortArray(nonFundedTaskPhases);
            }
        }

        for (uint256 i = 0; i < _hash1.length; i++) {
            taskSerial = taskSerial += 1;
            bytes32[2] memory _hashArray = [_hash1[i], _hash2[i]];
            checkPrecision(_cost[i]);
            tasks[taskSerial].initialize(_hashArray, _cost[i]);
            phases[_phase].phaseToTaskList.push(taskSerial);
            nonFundedPhaseToTask[_phase].push(taskSerial);
            eventsInstance.taskCreated(taskSerial);
            if (_sc[i] != address(0)) {
                _indexToInvite[_j] = i;
                _scToInvite[_j] = _sc[i];
                _j += 1;
            }
        }

        if (_j > 0) {
            inviteSCInternal(_indexToInvite, _scToInvite, _j);
        }
    }

    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        (bytes32[2] memory _taskHash, uint256 _nonce, uint256 _index) = abi
            .decode(_data, (bytes32[2], uint256, uint256));
        if (getAlerts(_index)[2]) {
            checkSignatureTask(_data, _signature, _index);
        } else {
            checkSignature(_data, _signature);
        }

        require(_nonce == hashChangeNonce, "23");
        tasks[_index].taskHash = _taskHash;
        hashChangeNonce += 1;
        eventsInstance.taskHashUpdated(_index, _taskHash);
    }

    function inviteSC(uint256[] memory _index, address[] memory _to)
        public
        override
    {
        inviteSCInternal(_index, _to, _index.length);
    }

    function inviteSCInternal(
        uint256[] memory _index,
        address[] memory _to,
        uint256 _limit
    ) internal override {
        require(
            msgSender() == builder ||
                msgSender() == contractor ||
                msgSender() == address(this),
            "24"
        );
        require(_index.length == _to.length, "25");
        for (uint256 i = 0; i < _limit; i++) {
            require(_to[i] != address(0), "26");
            require(_to[i] != builder && _to[i] != contractor, "27");
            address _old = tasks[_index[i]].subcontractor;
            tasks[_index[i]].inviteSubcontractor(_to[i]);
            if (_old != address(0))
                eventsInstance.scSwapped(_index[i], _old, _to[i]);
            else eventsInstance.scInvited(_index[i], _to[i]);
        }
    }

    function acceptInviteSC(uint256 _index) external override {
        tasks[_index].acceptInvitation(msgSender());
        eventsInstance.scConfirmed(_index, msgSender());
    }

    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        (uint256 _index, address _projectAddress) = abi.decode(
            _data,
            (uint256, address)
        );
        require(_projectAddress == address(this), "28");
        checkSignatureTask(_data, _signature, _index);
        payFee(tasks[_index].subcontractor, tasks[_index].cost);
        tasks[_index].setComplete();
        eventsInstance.taskComplete(_index);
    }

    function fundProject() public override {
        uint256 _maxLoop = 50;
        bool _incompleteFund;
        uint256 _costToAllocate = totalInvested - totalAllocated;
        // Fund Phase
        uint256 _nonFundedPhaseLength = nonFundedPhase.length;
        if (_nonFundedPhaseLength > 0) {
            if (_nonFundedPhaseLength > _maxLoop) {
                _nonFundedPhaseLength = _maxLoop;
                _incompleteFund = true;
            }

            uint256 i = nonFundedCounter;
            for (i; i < _nonFundedPhaseLength; i++) {
                uint256 _phaseCost = phases[nonFundedPhase[i]].phaseCost;
                _phaseCost += (_phaseCost * builderFee) / 1000;
                if (_costToAllocate >= _phaseCost) {
                    _costToAllocate -= _phaseCost;
                } else {
                    _incompleteFund = true;
                    break;
                }
            }

            if (i == _nonFundedPhaseLength - 1) {
                delete nonFundedPhase;
                nonFundedCounter = 0;
            } else nonFundedCounter = i;
        }

        // Fund Tasks
        if (!_incompleteFund) {
            uint256 _count;
            uint256 _phase;
            for (uint256 i = 0; i < nonFundedTaskPhases.length; i++) {
                uint256[] memory _nonFundedPhaseToTask = nonFundedPhaseToTask[
                    nonFundedTaskPhases[i]
                ];
                uint256 _nonFundedTaskLength = _nonFundedPhaseToTask.length;
                _count += _nonFundedTaskLength;
                if (_count > _maxLoop) {
                    _nonFundedTaskLength = _count - _maxLoop;
                    _incompleteFund = true; //not required for this loop
                }

                uint256 j = 0;
                for (j; j < _nonFundedTaskLength; j++) {
                    uint256 _taskId = _nonFundedPhaseToTask[j];
                    uint256 _taskCost = tasks[_taskId].cost;
                    _taskCost += (_taskCost * builderFee) / 1000;
                    if (_costToAllocate >= _taskCost) {
                        tasks[_taskId].fundTask();
                        _costToAllocate -= _taskCost;
                        eventsInstance.taskFunded(_taskId);
                    } else {
                        _incompleteFund = true;
                        break;
                    }
                }

                if (_incompleteFund) {
                    _phase = i;
                    uint256[] memory _nonFundedTaskList = new uint256[](
                        _nonFundedTaskLength - j
                    );
                    uint256 _index = 0;
                    for (uint256 k = j; k < _nonFundedPhaseToTask.length; k++) {
                        _nonFundedTaskList[_index] = _nonFundedPhaseToTask[k];
                        _index += 1;
                    }
                    nonFundedPhaseToTask[i] = _nonFundedTaskList;
                    break;
                } else {
                    delete nonFundedPhaseToTask[i];
                }
            }

            if (_incompleteFund) {
                uint256[] memory _nonFundedTaskPhases = nonFundedTaskPhases;
                uint256[] memory _nonFundedTaskPhasesList = new uint256[](
                    _nonFundedTaskPhases.length - _phase
                );
                uint256 _index;
                for (uint256 i = _phase; i < _nonFundedTaskPhases.length; i++) {
                    _nonFundedTaskPhasesList[_index] = _nonFundedTaskPhases[i];
                    _index += 1;
                }
                nonFundedTaskPhases = _nonFundedTaskPhasesList;
            } else {
                delete nonFundedTaskPhases;
            }
        }

        totalAllocated = totalInvested - _costToAllocate;
    }

    function withdraw() external override onlyBuilder {
        for (uint256 _phase = 1; _phase <= phaseCount; _phase++) {
            if (!phases[_phase].paid) {
                revert("34");
            }
        }

        if (currency == homeFi.ETHER_CURRENCY()) {
            payable(msgSender()).transfer(address(this).balance);
        } else {
            IERC20 _token = IERC20(currency);
            _token.transfer(msgSender(), _token.balanceOf(address(this)));
        }
    }

    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        (uint256 _phase, uint256 _index, address _newSC, uint256 _newCost) = abi
            .decode(_data, (uint256, uint256, address, uint256));
        checkSignatureTask(_data, _signature, _index);
        uint256 _taskCost = tasks[_index].cost;
        if (_newCost != _taskCost) {
            uint256 _totalAllocated = totalAllocated;
            if (_newCost < _taskCost) {
                checkPrecision(_newCost);
                //when _newCost is less than task cost
                totalAllocated -= tasks[_index].cost - _newCost;
            } else if (
                //when _newCost is more than task cost and totalInvestment is enough
                totalInvested - _totalAllocated >= _newCost - _taskCost
            ) {
                totalAllocated += (_newCost - _taskCost);
            } else {
                //when _newCost is more than task cost and totalInvestment is not enough.
                tasks[_index].alerts[1] = false; // non-funded
                totalAllocated -= tasks[_index].cost; // reduce from total allocated

                if (nonFundedPhaseToTask[_phase].length == 0) {
                    uint256 _length = nonFundedTaskPhases.length;
                    nonFundedTaskPhases.push(_phase);
                    if (
                        _length > 0 && nonFundedTaskPhases[_length - 1] > _phase
                    ) {
                        nonFundedTaskPhases = sortArray(nonFundedTaskPhases);
                    }
                }
                nonFundedPhaseToTask[_phase].push(taskSerial);
            }
            tasks[_index].cost = _newCost;
            eventsInstance.changeOrderFee(_index, _newCost);
        }
        if (_newSC != tasks[_index].subcontractor) {
            tasks[_index].alerts[2] = false; // SCConfirmed false
            if (_newSC != address(0)) {
                uint256[] memory _ts = new uint256[](1);
                _ts[0] = _index;
                address[] memory _scList = new address[](1);
                _scList[0] = _newSC;
                inviteSC(_ts, _scList); // inv‸iteSubcontractor
            } else {
                tasks[_index].subcontractor = address(0);
            }
            eventsInstance.changeOrderSC(_index, _newSC);
        }
    }

    function payFee(address _recipient, uint256 _amount) internal override {
        uint256 _builderFee = (_amount * builderFee) / 1000;
        address payable _treasury = homeFi.treasury();

        if (currency == homeFi.ETHER_CURRENCY()) {
            _treasury.transfer(_builderFee);
            payable(_recipient).transfer(_amount);
        } else {
            IERC20 _token = IERC20(currency);
            _token.transfer(_treasury, _builderFee);
            _token.transfer(_recipient, _amount);
        }
    }

    function getAlerts(uint256 _index)
        public
        view
        override
        returns (bool[3] memory _alerts)
    {
        return tasks[_index].getAlerts();
    }

    function getTaskHash(uint256 _index)
        external
        view
        override
        returns (bytes32[2] memory _taskHash)
    {
        return tasks[_index].taskHash;
    }

    function projectCost() public view override returns (uint256 _cost) {
        for (uint256 _phase = 1; _phase <= phaseCount; _phase++) {
            _cost += phases[_phase].phaseCost;
            for (
                uint256 _task = 1;
                _task <= phases[_phase].phaseToTaskList.length;
                _task++
            ) {
                _cost += tasks[phases[_phase].phaseToTaskList[_task - 1]].cost;
            }
        }
        _cost += (_cost * builderFee) / 1000;
    }

    function getPhaseToTaskList(uint256 _index)
        external
        view
        override
        returns (uint256[] memory _taskList)
    {
        _taskList = phases[_index].phaseToTaskList;
    }

    function recoverAddresses(
        bytes memory _data,
        bytes memory _signature,
        uint256 _count
    ) internal pure override returns (address[3] memory _recoveredArray) {
        bytes32 _hash = keccak256(_data);
        for (uint256 i = 0; i < _count; i++) {
            _recoveredArray[i] = recoverKey(_hash, _signature, i);
        }
    }

    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
        view
        override
    {
        address[3] memory _a = recoverAddresses(_data, _signature, 2);
        require(
            (_a[0] == builder && _a[1] == contractor) ||
                (_a[0] == contractor && _a[1] == builder),
            "29"
        );
    }

    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _index
    ) internal view override {
        address[3] memory _a = recoverAddresses(_data, _signature, 3);
        require(_a[0] != _a[1] && _a[0] != _a[2] && _a[1] != _a[2], "30");
        require(
            (_a[0] == builder ||
                _a[0] == contractor ||
                _a[0] == tasks[_index].subcontractor) &&
                (_a[1] == builder ||
                    _a[1] == contractor ||
                    _a[1] == tasks[_index].subcontractor) &&
                (_a[2] == builder ||
                    _a[2] == contractor ||
                    _a[2] == tasks[_index].subcontractor),
            "31"
        );
    }

    function sortArray(uint256[] memory arr_)
        internal
        pure
        override
        returns (uint256[] memory)
    {
        uint256 _l = arr_.length;
        uint256[] memory _arr = new uint256[](_l);
        for (uint256 i = 0; i < _l; i++) {
            _arr[i] = arr_[i];
        }
        for (uint256 i = 0; i < _l; i++) {
            for (uint256 j = i + 1; j < _l; j++) {
                if (_arr[i] > _arr[j]) {
                    uint256 temp = _arr[j];
                    _arr[j] = _arr[i];
                    _arr[i] = temp;
                }
            }
        }
        return _arr;
    }

    function checkPrecision(uint256 _amount) internal pure override {
        require(((_amount / 1000) * 1000) == _amount, "32");
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED
/*
The MIT License (MIT)

Copyright (c) 2018 Murray Software, LLC.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

import "../external/contracts/proxy/Initializable.sol";
import "./IEvents.sol";
import "./IHomeFi.sol";
import "../external/contracts/signature/SignatureDecode.sol";
import "../external/contracts/token/ERC20/IERC20Original.sol";
import "../external/contracts/BasicMetaTransaction.sol";
import "../external/contracts/utils/ReentrancyGuard.sol";
import {Tasks, Task} from "../libraries/Tasks.sol";

/**
 * HomeFI v0.1.0 Deployable Project Escrow Contract Interface
 *
 * Interface for child contract from HomeFi service contract; escrows all funds
 * Use task library to store hashes of data within project
 */
/**
 * @title Abstract contract for Project contracts
 * @notice This abstract contract is for project management of HomeFi.
 */
abstract contract IProject is
    Initializable,
    BasicMetaTransaction,
    ReentrancyGuard
{
    // using Tasks library for Task struct
    using Tasks for Task;

    // struct to store phase related details
    struct Phase {
        uint256 phaseCost;
        uint256[] phaseToTaskList;
        bool paid;
    }

    // Fixed //

    // HomeFi NFT contract instance
    IHomeFi public homeFi;

    // Event contract instance
    IEvents internal eventsInstance;

    // Address of project currency
    address public currency;

    // builder fee inherited from HomeFi
    uint256 public builderFee;

    // investor fee inherited from HomeFi
    uint256 public investorFee;

    // address of builder
    address public builder;

    // Variable //

    // bytes encoded ipfs hash of project
    bytes public projectHash;

    // address of invited contractor
    address public contractor;

    // bool that indicated if contractor has accepted invite
    bool public contractorConfirmed;

    // nonce that is used for signature security related to hash change
    uint256 public hashChangeNonce;

    // total amount invested in project
    uint256 public totalInvested;

    // total amount allocated in prject
    uint256 public totalAllocated;

    // phase count of project. starts from 1.
    uint256 public phaseCount;

    // task count/serial. Starts from 1.
    uint256 public taskSerial;

    // the index in nonFundedPhase from which phases are not funded
    uint256 internal nonFundedCounter;

    // array of phase index that are non funded.
    uint256[] internal nonFundedPhase;

    // sorted array of phase with non funded tasks
    uint256[] internal nonFundedTaskPhases;

    // mapping for each index of nonFundedTaskPhases to array of non funded task indexes.
    mapping(uint256 => uint256[]) internal nonFundedPhaseToTask;

    // mapping of phase index to Phase struct
    mapping(uint256 => Phase) public phases;

    // mapping of tasks index to Task struct.
    mapping(uint256 => Task) public tasks;

    /// MODIFIERS ///

    /**
     * @dev only allow if sender is project builder
     */
    modifier onlyBuilder() {
        require(msgSender() == builder, "2");
        _;
    }

    /**
     * @dev only allow if contractor has not accepted invite request
     */
    modifier contractorNotAccepted() {
        require(!contractorConfirmed, "3");
        _;
    }

    /**
     * @dev only allow if contractor has accepted invite request
     */
    modifier contractorAccepted() {
        require(contractorConfirmed, "4");
        _;
    }

    /**
     * @notice initialize this contract with required parameters. This is initialized by HomeFi contract
     * @dev modifier initializer
     * @param _hash bytes ipfs hash of this project
     * @param _currency currency address for this project
     * @param _sender address of the creator / builder for this project
     * @param _homeFiAddress address of the HomeFi contract
     */
    function initialize(
        bytes memory _hash,
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external virtual;

    /**
     * @notice builder can invite a contractor with fee schedule
     * @dev modifier contractorNotAccepted
     * @param _contractor address of contractor to invite
     * @param _feeSchedule uint256 array whose length represent number of phases and each element represent the phase cost
     */
    function inviteContractor(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external virtual;

    /**
     * @notice contractor can accept the invite sent by builder
     * @dev modifier contractorNotAccepted.
     * Investment must be equal to total of all phase cost
     */
    function acceptInviteContractor() external virtual;

    /**
     * @notice update project ipfs hash with adequate signatures.
     * @dev If contractor is approved then both builder and contractor signature needed. Else only builder's.
     * @param _data bytes encoded from-
     * - bytes _hash bytes encoded ipfs hash.
     * - uint256 _nonce current hashChangeNonce
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice change order to add phases in project. signature of both builder and contractor required.
     * @dev modifier contractorAccepted.
     * @param _data bytes encoded from-
     * - uint256[] _phaseCost array where each element represent phase cost, length of this array is number of phase to be added
     * - uint256 _phaseCount current phase count, for signature security
     * - address _projectAddress this project address, for signature security
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addPhasesGC(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice change order to change cost of existing phases. signature of both builder and contractor required.
     * @dev modifier contractorAccepted.
     * @param _data bytes encoded from-
     * - uint256[] _phaseList array of phase indexes that needs to be updated
     * - uint256[] _phaseCost cost that needs to be updated for each phase index in _phaseList
     * - address _projectAddress this project address, for signature security
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function changeCostGC(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice release phase payment of a contractor
     * @dev modifier onlyBuilder, contractorAccepted
     * @param _phase the phase index for which the payment needs to be released
     */
    function releaseFeeContractor(uint256 _phase) external virtual;

    /**
     * @notice allows investing in the project, also funds 50 phase and tasks. If the project currency is ERC20 token,
     * then before calling this function the sender must approve the tokens to this contract.
     * @dev can only be called by builder or community contract(via investor).
     * @param _cost the cost that is needed to be invested
     */
    function investInProject(uint256 _cost) external payable virtual;

    // Task-Specific //

    /**
     * @notice adds tasks in a particular phase. Needs both builder and contractor signature.
     * @dev contractor must be approved.
     * @param _data bytes encoded from-
     * - uint256 _phase phase number in which tasks are added
     * - bytes32[] _hash1 an array whose length is equal to number of task that you want to add,
     *   and each element is 1st part of Base58 converted ipfs hash.
     * - bytes32[] _hash2 an array similar to 2, but this time the 2nd part of Base58 converted ipfs hash.
     * - uint256[] _cost an array of cost for each task index
     * - address[] _sc an array subcontractor address for each task index
     * - uint256 _taskSerial current task count/serial before adding these tasks. Can be fetched by taskSerial.
     *   For signature security.
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addTask(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @dev If subcontractor is approved then builder, contractor and subcontractor signature needed.
     * Else only builder and contractor.
     * @notice update ipfs hash for a particular task
     * @param _data bytes encoded from-
     * - bytes32[2] _taskHash Base58 converted ipfs hash divided into two parts of bytes32
     * - uint256 _nonce current hashChangeNonce
     * - uint256 _index task index
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice invite subcontractors for existing tasks. This can be called by builder or contractor.
     * @dev this function internally calls inviteSCInternal.
     * _index must not have a task which already has approved subcontractor.
     * @param _index array the task index for which subcontractors needs to be assigned.
     * @param _to array of addresses of subcontractor for the respective task index.
     */
    function inviteSC(uint256[] memory _index, address[] memory _to)
        public
        virtual;

    /**
     * @dev invite subcontractors for existing tasks.
     * _index must not have a task which already has approved subcontractor.
     */
    function inviteSCInternal(
        uint256[] memory _index,
        address[] memory _to,
        uint256 _limit
    ) internal virtual;

    /**
     * @notice accept invite as subcontractor for a particular task.
     * Only subcontractor invited can call this.
     * @dev subcontractor must be unapproved.
     * @param _index the task index for which sender wants to accept invite.
     */
    function acceptInviteSC(uint256 _index) external virtual;

    /**
     * @notice mark a task a complete and release subcontractor payment.
     * Needs builder,contractor and subcontractor signature.
     * @dev task must be in active state.
     * @param _data bytes encoded from-
     * - uint256 _index the index of task
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @notice allocates funds for unallocated tasks and phases, and mark them as funded.
     * @dev this is by default called by investInProject.
     * But when unallocated task/phase count are beyond 50 then this is needed to be called externally.
     */
    function fundProject() public virtual;

    /**
     * @notice withdraw amount remain in project after completion of project
     * Can only be called by builder.
     * @dev modifier onlyBuilder. All tasks must be paid to call this function.
     */
    function withdraw() external virtual;

    /**
     * @notice change order to change a task's subcontractor, cost or both.
     * Needs builder,contractor and subcontractor signature.
     * @param _data bytes encoded from-
     * - uint256 _phase index of phase in which the task is present
     * - uint256 _index index of the task
     * - address _newSC address of new subcontractor.
     *   If do not want to replace subcontractor, then pass address of existing subcontractor.
     * - uint256 _newCost new cost for the task.
     *   If do not want to change cost, then pass existing cost.
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * @dev transfer funds to contractor or subcontract, on completion of phase or task respectively.
     */
    function payFee(address _recipient, uint256 _amount) internal virtual;

    /**
     * @notice returns Lifecycle statuses of a task
     * @param _index task index
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached.
     * Lifecycle alerts- [None, TaskFunded, SCConfirmed]
     */
    function getAlerts(uint256 _index)
        public
        view
        virtual
        returns (bool[3] memory _alerts);

    /**
     * @notice returns task ipfs hash
     * @param _index task index
     * @return _taskHash bytes32[2] array divided Base58 ipfs hash
     */
    function getTaskHash(uint256 _index)
        external
        view
        virtual
        returns (bytes32[2] memory _taskHash)
    {
        return tasks[_index].taskHash;
    }

    /**
     * @notice returns cost of project. Cost of project is sum of phase and task costs.
     * @return _cost uint256 cost of project.
     */
    function projectCost() external view virtual returns (uint256 _cost);

    /**
     * @notice returns tasks index array in a phase.
     * @return _taskList uint256[] tasks indexes.
     */
    function getPhaseToTaskList(uint256 _index)
        external
        view
        virtual
        returns (uint256[] memory _taskList);

    /**
     * @dev returns address recovered from _data and _signature
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _count number of addresses to recover
     * @return _recoveredArray address[3] array of recovered address
     */
    function recoverAddresses(
        bytes memory _data,
        bytes memory _signature,
        uint256 _count
    ) internal pure virtual returns (address[3] memory _recoveredArray);

    /**
     * @dev check if recovered signatures match with builder and contractor address.
     * reverts if signature do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     */
    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
        view
        virtual;

    /**
     * @dev check if recovered signatures match with builder, contractor and subcontractor address for a task.
     * reverts if signatures do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _index index of the task.
     */
    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _index
    ) internal view virtual;

    /**
     * @dev Insertion Sort, in ascending order.
     * @param arr_ uint256[] array needed to be sorted.
     * @return _arr uint256[] array sorted in ascending order.
     */
    function sortArray(uint256[] memory arr_)
        internal
        pure
        virtual
        returns (uint256[] memory);

    /**
     * @dev check if precision is greater than 1000, if so it reverts
     * @param _amount amount needed to be checked for precision.
     */
    function checkPrecision(uint256 _amount) internal pure virtual;
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./IHomeFi.sol";
import "../external/contracts/proxy/Initializable.sol";
import "../external/contracts/proxy/OwnedUpgradeabilityProxy.sol";

abstract contract IEvents is Initializable {
    /// EVENTS ///

    // Project.sol Events //
    event HashUpdated(address indexed _project, bytes _hash);
    event ContractorInvited(
        address indexed _project,
        address indexed _newContractor,
        uint256[] _feeSchedule
    );
    event ContractorSwapped(
        address indexed _project,
        address indexed _oldContractor,
        address indexed _newContractor
    );
    event BuilderConfirmed(address indexed _project, address indexed _builder);
    event ContractorConfirmed(
        address indexed _project,
        address indexed _contractor
    );
    event PhasesAdded(address indexed _project, uint256[] _phaseCost);
    event PhaseUpdated(
        address indexed _project,
        uint256[] _phase,
        uint256[] _updatedCost
    );
    event ProjectFunded(address indexed _project, uint256 indexed _value);
    event InvestedInProject(address indexed _project, uint256 _cost);
    event TaskCreated(address indexed _project, uint256 indexed _taskID);
    event TaskHashUpdated(
        address indexed _project,
        uint256 _taskId,
        bytes32[2] _taskHash
    );
    event SCInvited(
        address indexed _project,
        uint256 indexed _taskID,
        address indexed _sc
    );
    event SCSwapped(
        address indexed _project,
        uint256 _taskID,
        address indexed _old,
        address indexed _new
    );
    event SCConfirmed(
        address indexed _project,
        uint256 _taskID,
        address indexed _sc
    );
    event TaskFunded(address indexed _project, uint256 _taskID);
    event TaskComplete(address indexed _project, uint256 _taskID);
    event ContractorFeeReleased(address indexed _project, uint256 _phase);
    event ChangeOrderFee(address _project, uint256 _taskID, uint256 _newCost);
    event ChangeOrderSC(address _project, uint256 _taskID, address _sc);

    // HomeFi.sol Events //
    event ProjectAdded(
        uint256 _projectID,
        address indexed _projectAddress,
        address indexed _builder
    );
    event RepayInvestor(
        uint256 indexed _communityID,
        address indexed _projectAddress,
        address indexed _investor,
        uint256 _tAmount,
        uint256 _repayDate
    );
    event NftCreated(uint256 _id, address _owner);

    // Dispute.sol Events //
    event DisputeRaised(
        address indexed _raisedBy,
        address indexed _project,
        uint256 indexed _taskId,
        uint256 _disputeId
    );
    event DisputeResolved(uint256 disputeId, uint256 result, bytes resultHash);

    // Community.sol Events //

    event CommunityAdded(
        uint256 _communityID,
        address indexed _owner,
        address indexed _currency,
        bytes _hash
    );
    event UpdateCommunityHash(
        uint256 _communityID,
        bytes _oldHash,
        bytes _newHash
    );
    event MemberAdded(uint256 indexed _communityID, address indexed _member);
    event ProjectPublished(
        uint256 indexed _communityID,
        uint256 _apr,
        address indexed _project,
        address indexed _builder
    );
    event InvestorInvested(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _cost,
        uint256 _investmentDate
    );
    event DebtTransferred(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        address to,
        uint256 _totalAmount
    );
    event ClaimedInterest(
        uint256 indexed _communityID,
        address indexed _project,
        address indexed _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    );

    /// MODIFIERS ///
    modifier validProject() {
        // ensure that the caller is an instance of Project.sol
        require(homeFi.projectExist(msg.sender), "Invalid projectContract");
        _;
    }

    modifier onlyDisputeContract() {
        // ensure that the caller is deployed instance of Dispute.sol
        require(
            homeFi.disputeContract() == msg.sender,
            "Invalid disputeContract"
        );
        _;
    }

    modifier onlyHomeFi() {
        // ensure that the caller is the deployed instance of HomeFi.sol
        require(address(homeFi) == msg.sender, "Only HomeFi Contract");
        _;
    }

    modifier onlyCommunityContract() {
        // ensure that the caller is the deployed instance of Community.sol
        require(
            homeFi.communityContract() == msg.sender,
            "Only communityContract"
        );
        _;
    }

    IHomeFi public homeFi;

    /// CONSTRUCTOR ///

    /**
     * Initialize a new events contract
     * @notice THIS IS THE CONSTRUCTOR thanks upgradable proxies
     * @dev modifier initializer
     *
     * @param _homeFi IHomeFi - instance of main Rigor contract. Can be accessed with raw address
     */
    function initialize(address _homeFi) external virtual;

    /// FUNCTIONS ///

    /**
     * Call to emit when the hash of a project is updated
     *
     * @param _updatedHash bytes - hash of project metadata used to identify the project
     */
    function hashUpdated(bytes calldata _updatedHash) external virtual;

    /**
     * Call to emit when a new General Contractor is invited to a HomeFi project
     * @dev modifier validProject
     *
     * @param _contractor address - the address invited to the project as the general contractir
     * @param _feeSchedule uint256[] - array (length = number of phases) of contractor fees to be paid per phase
     */
    function contractorInvited(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external virtual;

    /**
     * Call to emit when a project's General Contractor is swapped
     * @dev modifier validProject
     *
     * @param _oldContractor address - the address being uninvited/ removed as General Contractor
     * @param _newContractor address - the address being invited as General Contractor
     */
    function contractorSwapped(address _oldContractor, address _newContractor)
        external
        virtual;

    /**
     * Call to emit when a projet's builder is confirmed
     * @dev modifier validProject
     * @dev pretty sure this should be deleted/ is not used
     *
     * @param _builder address - the address confirmed as the project builder
     */
    function builderConfirmed(address _builder) external virtual;

    /**
     * Call to emit when a projet's general contractor is confirmed
     * @dev modifier validProject
     *
     * @param _contractor address - the address confirmed as the project general contractor
     */
    function contractorConfirmed(address _contractor) external virtual;

    /**
     * Call to emit when a project has phases added
     * @dev modifier validProject
     *
     * @param _phaseCosts uint256 - array of added phases' costs
     */
    function phasesAdded(uint256[] calldata _phaseCosts) external virtual;

    /**
     * Call to emit when a project's phases are updated
     * @dev modifier validProject
     *
     * @param _phases uint256[] - array of phase indices to mutate cost for
     * @param _costs uint256[] - array of costs to change with array index corresponding to _phase[index] task
     */
    function phaseUpdated(uint256[] calldata _phases, uint256[] calldata _costs)
        external
        virtual;

    /**
     * Call to emit when a task's identifying hash is changed
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the updated task
     * @param _taskHash bytes[32] - a 64 byte hash that is split in two given max bytes size of 32
     */
    function taskHashUpdated(uint256 _taskID, bytes32[2] calldata _taskHash)
        external
        virtual;

    /**
     * Call to emit when a new task is created in a project
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the newly created task
     */
    function taskCreated(uint256 _taskID) external virtual;

    /**
     * Call to emit when an investor has loaned funds to a project
     * @dev modifier validProject
     *
     * @param _cost uint256 - the amount of currency invested in the project (depends on project currency)
     */
    function investedInProject(uint256 _cost) external virtual;

    /**
     * Call to emit when a subcontractor is invited to a task for the first time
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task the subcontractor is being invited to
     * @param _sc address - the address of the user being invited as subcontractor to the task
     */
    function scInvited(uint256 _taskID, address _sc) external virtual;

    /**
     * Call to emit when a subcontractor is being swapped out in a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task the subcontractor is being swapped in
     * @param _old address - the address of the user being uninvited as subcontractor to the task
     * @param _new address - the address of the user being invited as subcontractor to the task
     */
    function scSwapped(
        uint256 _taskID,
        address _old,
        address _new
    ) external virtual;

    /**
     * Call to emit when a subcontractor is confirmed for a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task joined by the subcontractor
     * @param _sc address - the address of the user joining the task as subcontractor
     */
    function scConfirmed(uint256 _taskID, address _sc) external virtual;

    /**
     * Call to emit when a task is funded
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the funded task
     */
    function taskFunded(uint256 _taskID) external virtual;

    /**
     * Call to emit when a task has been completed
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the completed task
     */
    function taskComplete(uint256 _taskID) external virtual;

    /**
     * Call to emit when a phase has been completed/ the contractor fee for the phase has been released from escrow
     * @dev modifier validProject
     *
     * @param _phase uint256 - the index of the completed phase
     */
    function contractorFeeReleased(uint256 _phase) external virtual;

    /**
     * Call to emit when a task has a change order changing the cost of a task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task where the change order occurred
     * @param _newCost uint256 - the new cost of the task (in the project currency)
     */
    function changeOrderFee(uint256 _taskID, uint256 _newCost) external virtual;

    /**
     * Call to emit when a task has a change order that swaps the subcontractor on the task
     * @dev modifier validProject
     *
     * @param _taskID uint256 - the uuid of the task where the change order occurred
     * @param _sc uint256 - the subcontractor being added to the task in the change order
     */
    function changeOrderSC(uint256 _taskID, address _sc) external virtual;

    /**
     * Call to emit when a project is created (new NFT is minted)
     * @dev modifier onlyHomeFi
     *
     * @param _projectID uint256 - the ERC721 enumerable index/ uuid of the project
     * @param _projectAddress address - the address of the newly deployed project contract
     * @param _builder address - the address of the user permissioned as the project's builder
     */
    function projectAdded(
        uint256 _projectID,
        address _projectAddress,
        address _builder
    ) external virtual;

    /**
     * Call to emit when an investor's loan is repaid with interest
     * @dev modifier onlyCommunityContract
     *
     * @param _index uint256 - the uuid of the community that the project loan occurred in
     * @param _projectAddress address - the address of the deployed contract address where the loan was escrowed
     * @param _investor address - the address that supplied the loan/ is receiving repayment
     * @param _tAmount uint256 - the amount repaid to the investor (principal + interest) in the project currency
     * @param _repayDate uint256 - timestamp of block that contains the repayment transaction
     */
    function repayInvestor(
        uint256 _index,
        address _projectAddress,
        address _investor,
        uint256 _tAmount,
        uint256 _repayDate
    ) external virtual;

    /**
     * Call to emit when a new dispute is raised
     * @dev modifier onlyDisputeContract
     *
     * @param _sender address - the user that raised the dispute within the project task
     *  - can only be builder, general contractor, or one of project's subcontractors
     * @param _project address - the address of the deployed project contract where escrowed funds are under dispute
     * @param _taskId uint256 - the uuid of the task within the project contract where the dispute occurred
     * @param _disputeId uint256 - the uuid/ serial of the dispute within the dispute contract
     */
    function disputeRaised(
        address _sender,
        address _project,
        uint256 _taskId,
        uint256 _disputeId
    ) external virtual;

    /**
     * Call to emit when a dispute has been arbitrated and funds have been directed to the correct address
     * @dev modifier onlyDisputeContract
     *
     * @param _disputeId uint256 - the uuid/serial of the dispute within the dispute contract
     * @param _result uint256 - integer encoding of dispute status enum
     *  - 0: None, 1: Active, 2: Accepted, 3: Rejected
     * @param _resultHash bytes - the ipfs CID of the document submitted to document dispute resolution
     */
    function disputeResolved(
        uint256 _disputeId,
        uint256 _result,
        bytes calldata _resultHash
    ) external virtual;

    /**
     * Call to emit when a new investment community is created
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the created investment community
     * @param _owner address - the address of the user who manages the investment community
     * @param _currency address - the address of the currency used as collateral in projects within the community
     * @param _hash bytes - the hash of community metadata used to identify the community
     */
    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external virtual;

    /**
     * Call to emit when a community's identifying hash is updated
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the investment community whose hash is being updated
     * @param _oldHash bytes - the old hash of community metadata used to identify the community being removed
     * @param _newHash bytes - the new hash of community metadata used to identify the community being added
     */
    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external virtual;

    /**
     * Call to emit when a member has been added to an investment community as a new investor
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the investment community being joined
     * @param _member address - the address of the user joining the community as an investor
     */
    function memberAdded(uint256 _communityID, address _member)
        external
        virtual;

    /**
     * Call to emit when a project is added to an investment community for fund raising
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community being published to
     * @param _apr uint256 - the annual percentage return (interest rate) on loans made to the project
     * @param _project address - the address of the deployed project contract where loans are escrowed
     * @param _builder address - the address of the user permissioned as the project's builder
     */
    function projectPublished(
        uint256 _communityID,
        uint256 _apr,
        address _project,
        address _builder
    ) external virtual;

    /**
     * Call to emit when an investor loans funds to a project
     * @dev modifier onlyCommunityContract
     *
     * @param _communityID uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract the investor loaned funds to
     * @param _investor address - the address of the investing user
     * @param _cost uint256 - the amount of funds invested by _investor, in the project currency
     * @param _investmentDate - the timestamp of the block containing the investment transaction
     */
    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost,
        uint256 _investmentDate
    ) external virtual;

    /**
     * Call to emit when a new project & accompanying ERC721 token have been created
     * @dev modifier onlyHomeFi
     *
     * @param _id uint256 - the ERC721 enumerable serial/ project id
     * @param _owner address - address permissioned as project's builder/ nft owner
     */
    function nftCreated(uint256 _id, address _owner) external virtual;

    /**
     * Call to emit when fractional ownership of a project's debt is transferred
     * @dev modifier onlyCommunityContract
     *
     * @param _index uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract tracked by the NFT
     * @param _investor address - the current owner who is sending the fractional ownership of the NFT
     * @param _to address - the new owner who is the recipient of fractional ownership of the NFT
     * @param _totalAmount uint256 - the amount of debt tokens transferred (in the project's wrapped currency)
     */
    function debtTransferred(
        uint256 _index,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external virtual;

    /**
     * Call to emit when an investor claims their repayment with interest
     * @dev modifier onlyCommunityContract
     *
     * @param _index uint256 - the uuid/ serial of the community the project is published in
     * @param _project address - the address of the deployed project contract the investor loaned to
     * @param _investor address - the address of the investor claiming interest
     * @param _interestEarned uint256 - the amount of collateral tokens earned in interest (in project's currency)
     * @param _totalAmount uint256 - collateral tokens: principal + interest returned to investor
     */
    function claimedInterest(
        uint256 _index,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external virtual;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED

import "./IEvents.sol";
import "../external/contracts/BasicMetaTransaction.sol";
import "../external/contracts/utils/ReentrancyGuard.sol";
import "../external/contracts/token/ERC721/ERC721.sol";
import "../external/contracts/proxy/OwnedUpgradeabilityProxy.sol";
import "../external/contracts/proxy/Initializable.sol";

interface IProjectFactory {
    function createProject(
        bytes memory _hash,
        address _currency,
        address _sender
    ) external returns (address _clone);
}

/**
 * @title HomeFi v0.1.0 ERC721 Contract Interface
 * @notice Interface for main on-chain client for HomeFi protocol
 * Interface for administrative controls and project deployment
 */
abstract contract IHomeFi is BasicMetaTransaction, ReentrancyGuard {
    modifier onlyAdmin() {
        require(admin == msgSender(), "only owner");
        _;
    }

    modifier nonZero(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// VARIABLES ///
    address public constant ETHER_CURRENCY =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DAI_CURRENCY =
        0x273f6Ebe797369F53ad3F286F0789Cb6ce548455;
    address public constant USDC_CURRENCY =
        0xCD78b8062029d0EF32cc1c9457b6beC636A81A69;

    IEvents public eventsInstance;
    IProjectFactory public projectFactoryInstance;
    address public disputeContract;
    address public communityContract;

    string public name;
    string public symbol;
    address public admin;
    address payable public treasury;
    uint256 public builderFee;
    uint256 public investorFee;
    mapping(uint256 => address) public projects;
    mapping(address => bool) public projectExist;

    mapping(address => uint256) public projectTokenId;

    mapping(address => address) public wrappedToken;

    uint256 public projectSerial;
    bool public addrSet;
    uint256 internal _tokenIds;

    /**
     * Pass addresses of other deployed modules into the HomeFi contract
     * @dev can only be called once
     * @param _eventsContract address - contract address of Events.sol
     * @param _projectFactory contract address of ProjectFactory.sol
     * @param _communityContract contract address of Community.sol
     * @param _disputeContract contract address of Dispute.sol
     * @param _rETHAddress Ether debt token address
     * @param _rDaiAddress Dai debt token address
     * @param _rUSDCAddress USDC debt token address
     */
    function setAddr(
        address _eventsContract,
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _rETHAddress,
        address _rDaiAddress,
        address _rUSDCAddress
    ) external virtual;

    /**
     * @dev to validate the currency is supported by HomeFi or not
     * @param _currency currency address
     */
    function validCurrency(address _currency) public pure virtual;

    /// ADMIN MANAGEMENT ///
    /**
     * @notice only called by admin
     * @dev replace admin
     * @param _newAdmin new admin address
     */
    function replaceAdmin(address _newAdmin) external virtual;

    /**
     * @notice only called by admin
     * @dev address which will receive HomeFi builder and investor fee
     * @param _treasury new treasury address
     */
    function replaceTreasury(address _treasury) external virtual;

    /**
     * @notice this is only called by admin
     * @dev to reset the builder and investor fee for HomeFi deployment
     * @param _builderFee percentage of fee builder have to pay to HomeFi treasury
     * @param _investorFee percentage of fee investor have to pay to HomeFi treasury
     */
    function replaceNetworkFee(uint256 _builderFee, uint256 _investorFee)
        external
        virtual;

    /// PROJECT ///
    /**
     * @dev to create a project
     * @param _hash IPFS hash of project details
     * @param _currency address of currency which this project going to use
     */
    function createProject(bytes memory _hash, address _currency)
        external
        virtual;

    /**
     * @dev make every project NFT
     * @param _to to which user this NFT belong to first time it will builder
     * @param _tokenURI ipfs hash of project which contain project details like name, description etc.
     * @return _tokenIds NFT Id of project
     */
    function mintNFT(address _to, string memory _tokenURI)
        internal
        virtual
        returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

contract SignatureDecoder {
    /// @dev Recovers address who signed the message
    /// @param messageHash keccak256 hash of message
    /// @param messageSignatures concatenated message signatures
    /// @param pos which signature to read
    function recoverKey(
        bytes32 messageHash,
        bytes memory messageSignatures,
        uint256 pos
    ) public pure returns (address) {
        if (messageSignatures.length % 65 != 0) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignatures, pos);

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(toEthSignedMessageHash(messageHash), v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./math/SafeMath.sol";

contract BasicMetaTransaction {
    using SafeMath for uint256;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
        );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

library Tasks {
    /// MODIFIERS ///

    /// @dev only allows task with status None, uninitialized tasks
    modifier uninitialized(Task storage _self) {
        require(_self.state == TaskStatus.None, "Already initialized");
        _;
    }

    /// @dev only allow inactive tasks. Task are inactive if SC is unconfirmed.
    modifier onlyInactive(Task storage _self) {
        require(!_self.alerts[uint256(Lifecycle.SCConfirmed)], "Only Inactive");
        _;
    }

    /// @dev only allow active tasks. Task are inactive if SC is confirmed.
    modifier onlyActive(Task storage _self) {
        require(_self.alerts[uint256(Lifecycle.SCConfirmed)], "Only Active");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    // Task Status Changing Functions //

    /**
     * Create a new Task object
     * @dev cannot operate on initialized tasks
     * @param _self Task the task struct being mutated
     * @param _cost uint the number of tokens to be escrowed in this contract
     */
    function initialize(
        Task storage _self,
        bytes32[2] memory _taskHash,
        uint256 _cost
    ) public uninitialized(_self) {
        _self.taskHash = _taskHash;
        _self.cost = _cost;
        _self.state = TaskStatus.Inactive;
        _self.alerts[0] = true;
    }

    /**
     * Attempt to transition task state from Payment Pending to Complete
     * @dev modifier onlyActive
     * @param _self Task the task whose state is being mutated
     */
    function setComplete(Task storage _self) internal onlyActive(_self) {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.None)] = true;
        _self.state = TaskStatus.Complete;
    }

    // Subcontractor Joining //

    /**
     * Invite a subcontractor to the task
     * @dev modifier onlyInactive
     * @param _self Task the task being joined by subcontractor
     * @param _sc address the subcontractor being invited
     */
    function inviteSubcontractor(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        _self.subcontractor = _sc;
    }

    /**
     * As a subcontractor, accept an invitation to participate in a task.
     * @dev modifier onlyInactive
     * @param _self Task the task being joined by subcontractor
     * @param _sc Address of sender
     */
    function acceptInvitation(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        // Prerequisites //
        require(_self.subcontractor == _sc, "Only Subcontractor");
        require(_self.alerts[uint256(Lifecycle.TaskFunded)], "Only funded");

        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = true;
        if (_self.alerts[uint256(Lifecycle.None)])
            _self.alerts[uint256(Lifecycle.None)] = false;
        _self.state = TaskStatus.Active;
    }

    // Task Funding //

    /**
     * Set a task as funded
     * @dev modifier onlyAdmin
     * @param _self Task the task being set as funded
     */
    function fundTask(Task storage _self) internal onlyInactive(_self) {
        // Prerequisites //
        require(!_self.alerts[uint256(Lifecycle.TaskFunded)], "Already funded");

        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = true;
        if (_self.alerts[uint256(Lifecycle.None)])
            _self.alerts[uint256(Lifecycle.None)] = false;
    }

    /// VIEWABLE FUNCTIONS ///

    /**
     * Determine the current state of all alerts in the project
     * @param _self Task the task being queried for alert status
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached
     */
    function getAlerts(Task storage _self)
        internal
        view
        returns (bool[3] memory _alerts)
    {
        for (uint256 i = 0; i < _alerts.length; i++)
            _alerts[i] = _self.alerts[i];
    }

    /**
     * Return the numerical encoding of the TaskStatus enumeration stored as state in a task
     * @param _self Task the task being queried for state
     * @return _state uint 0: none, 1: inactive, 2: active, 3: complete
     */
    function getState(Task storage _self)
        internal
        view
        returns (uint256 _state)
    {
        return uint256(_self.state);
    }
}

// Task metadata
struct Task {
    // Metadata //
    bytes32[2] taskHash;
    uint256 cost;
    address subcontractor;
    // Lifecycle //
    TaskStatus state;
    mapping(uint256 => bool) alerts;
}

enum TaskStatus {
    None,
    Inactive,
    Active,
    Complete
}

enum Lifecycle {
    None,
    TaskFunded,
    SCConfirmed
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED
import "./UpgradeabilityProxy.sol";

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    // Storage position of the owner of the contract
    bytes32 private constant PROXY_OWNER_POSITION =
        keccak256("org.rigour.proxy.owner");

    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor(address _implementation) {
        _setUpgradeabilityOwner(msg.sender);
        _upgradeTo(_implementation);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
        _;
    }

    function proxyOwner() public view returns (address owner) {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
        emit ProxyOwnershipTransferred(proxyOwner(), _newOwner);
    }

    /**
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param _implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address _implementation) public onlyProxyOwner {
        _upgradeTo(_implementation);
    }

    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = PROXY_OWNER_POSITION;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721 is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    // string private _name;

    // Token symbol
    // string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return
            _tokenOwners.get(
                tokenId,
                "ERC721: owner query for nonexistent token"
            );
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    // function name() public view virtual override returns (string memory) {
    //     return _name;
    // }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    // function symbol() public view virtual override returns (string memory) {
    //     return _symbol;
    // }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner ||
                ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        ); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: UNLICENSED
import "./Proxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the current implementation
    bytes32 private constant IMPLEMENTATION_POSITION =
        keccak256("org.govblocks.proxy.implementation");

    /**
     * @dev Constructor function
     */
    constructor() {}

    function implementation() public view override returns (address impl) {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param _newImplementation address representing the new implementation to be set
     */
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = IMPLEMENTATION_POSITION;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        emit Upgraded(_newImplementation);
    }
}

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: UNLICENSED

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    function _fallback() internal {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Fallback function that delegates calls to the address returned by `implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    // function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    // function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        require(
            map._entries.length > index,
            "EnumerableMap: index out of bounds"
        );

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key)
        private
        view
        returns (bool, bytes32)
    {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool, address)
    {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return
            address(
                uint160(uint256(_get(map._inner, bytes32(key), errorMessage)))
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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