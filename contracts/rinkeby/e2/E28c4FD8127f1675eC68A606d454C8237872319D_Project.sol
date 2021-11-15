pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "./interfaces/IProject.sol";
import "./external/contracts/proxy/Initializable.sol";

/**
 * Rigor v0.1.0 Deployable Project Contract
 *
 * Project contract responsible for aggregating payments and data by/ for users on-chain
 */
contract Project is
    Initializable,
    IProject,
    SignatureDecoder
{
    using SafeMath for uint256;
    using Tasks for Task;

    // to make sure master implementation cannot be initialized
    constructor() initializer {}

    function initialize(
        bytes memory _hash,
        address _currency,
        address _sender,
        address _rigorAddress
    ) public initializer {
        IRigor _rigor = IRigor(_rigorAddress);
        eventsInstance = _rigor.eventsInstance();
        builderFee = _rigor.builderFee();
        investorFee = _rigor.investorFee();
        rigor = _rigor;
        builder = _sender;
        projectHash = _hash;
        currency = _currency;
    }

    /// MUTABLE FUNCTIONS ///

    // Project-Specific //

    function inviteContractor(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external contractorNotAccepted {
        require(_contractor != address(0), "3");
        require(msgSender() == builder, "4");
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
            ++phaseCount;
            require(checkPrecision(_feeSchedule[i]), "36");
            phases[phaseCount].phaseCost = _feeSchedule[i]; //starts from 1
        }
        eventsInstance.contractorInvited(contractor, _feeSchedule);
    }

    function acceptInviteContractor() external contractorNotAccepted {
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
    {
        if (contractorConfirmed) {
            checkSignature(_data, _signature);
        } else {
            address[3] memory _a = recoverAddresses(_data, _signature, 1);
            require(_a[0] == builder, "8");
        }
        (bytes memory _hash, uint256 _nonce) =
            abi.decode(_data, (bytes, uint256));
        require(_nonce == hashChangeNonce, "9");
        projectHash = _hash;
        hashChangeNonce = hashChangeNonce.add(1);
        eventsInstance.hashUpdated(projectHash);
    }

    function addPhasesGC(bytes calldata _data, bytes calldata _signature)
        external
        contractorAccepted
    {
        checkSignature(_data, _signature);
        (
            uint256[] memory _phaseCost,
            uint256 _phaseCount, /* Current phase count, for signature security */
            address _projectAddress /* This project address, for signature security */
        ) = abi.decode(_data, (uint256[], uint256, address));
        require(
            _phaseCount == phaseCount && _projectAddress == address(this),
            "10"
        );
        uint256 _phaseCostLength = _phaseCost.length;
        for (uint256 i = 0; i < _phaseCostLength; i++) {
            // add new phase and mark it as nonFunded
            ++phaseCount;
            require(checkPrecision(_phaseCost[i]), "36");
            phases[phaseCount].phaseCost = _phaseCost[i];
            nonFundedPhase.push(phaseCount);
        }
        eventsInstance.phasesAdded(_phaseCost);
    }

    function changeCostGC(bytes calldata _data, bytes calldata _signature)
        external
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
            require(checkPrecision(_phaseCost[i]), "36");
            uint256 _oldCost = phases[_phaseList[i]].phaseCost;
            phases[_phaseList[i]].phaseCost = _phaseCost[i];
            if (_oldCost > _phaseCost[i]) {
                /* reduce difference of old - new phase from totalAllocated */
                totalAllocated = totalAllocated.sub(
                    _oldCost.sub(_phaseCost[i])
                );
            } else if (_oldCost < _phaseCost[i]) {
                /* reduce old phase cost from totalAllocated
                mark the phase as nonFunded */
                totalAllocated = totalAllocated.sub(_oldCost);
                nonFundedPhase.push(_phaseList[i]);
            }
        }
        nonFundedPhase = sort_array(nonFundedPhase);
        eventsInstance.phaseUpdated(_phaseList, _phaseCost);
    }

    function releaseFeeContractor(uint256 _phase)
        external
        override
        onlyBuilder
        contractorAccepted
    {
        require(_phase < phaseCount, "15");
        require(!phases[_phase].paid, "16");

        for (uint256 i = 0; i < phases[_phase].phaseToTaskList.length; i++) {
            if (tasks[phases[_phase].phaseToTaskList[i]].getState() != 3) {
                revert("17");
            }
        }

        phases[_phase].paid = true;
        payFee(contractor, phases[_phase].phaseCost);
        eventsInstance.contractorFeeReleased(_phase);
    }

    //in case of ether also they have pass msg.value in argument
    function investInProject(uint256 _cost) external payable override {
        require(
            msgSender() == builder || msgSender() == rigor.communityContract(),
            "18"
        );
        require(_cost > 0, "19");
        require(projectCost() >= uint256(totalInvested.add(_cost)), "20");

        if (msgSender() == builder) {
            if (currency == rigor.etherCurrency()) {
                require(_cost == msg.value, "21");
            } else {
                IERC20 _token = IERC20(currency);
                _token.transferFrom(msgSender(), address(this), _cost);
            }
        }

        totalInvested = totalInvested.add(_cost);
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
        ) =
            abi.decode(
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
            "23"
        );
        require(
            _taskSerial == taskSerial && _projectAddress == address(this),
            "24"
        );
        require(
            _hash1.length == _hash2.length &&
                _hash1.length == _cost.length &&
                _hash1.length == _sc.length,
            "25"
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
                nonFundedTaskPhases = sort_array(nonFundedTaskPhases);
            }
        }

        for (uint256 i = 0; i < _hash1.length; i++) {
            taskSerial++;
            bytes32[2] memory _hashArray = [_hash1[i], _hash2[i]];
            require(checkPrecision(_cost[i]), "36");
            tasks[taskSerial].initialize(_hashArray, _cost[i]);
            phases[_phase].phaseToTaskList.push(taskSerial);
            nonFundedPhaseToTask[_phase].push(taskSerial);
            eventsInstance.taskCreated(taskSerial);
            if (_sc[i] != address(0)) {
                _indexToInvite[_j] = i;
                _scToInvite[_j] = _sc[i];
                _j.add(1);
            }
        }

        if (_j > 0) {
            inviteSCInternal(_indexToInvite, _scToInvite, _j);
        }
    }

    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
    {
        (bytes32[2] memory _taskHash, uint256 _nonce, uint256 _index) =
            abi.decode(_data, (bytes32[2], uint256, uint256));
        if (getAlerts(_index)[2]) {
            checkSignatureTask(_data, _signature, _index);
        } else {
            checkSignature(_data, _signature);
        }

        require(_nonce == hashChangeNonce, "26");
        tasks[_index].taskHash = _taskHash;
        hashChangeNonce = hashChangeNonce.add(1);
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
    ) internal {
        require(
            msgSender() == builder ||
                msgSender() == contractor ||
                msgSender() == address(this),
            "27"
        );
        require(_index.length == _to.length, "28");
        for (uint256 i = 0; i < _limit; i++) {
            require(_to[i] != address(0), "29");
            require(_to[i] != builder && _to[i] != contractor, "30");
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
        uint256 _index = abi.decode(_data, (uint256));
        checkSignatureTask(_data, _signature, _index);
        payFee(tasks[_index].subcontractor, tasks[_index].cost);
        tasks[_index].setComplete();
        eventsInstance.taskComplete(_index);
    }

    function fundProject() public override {
        uint256 _maxLoop = 50;
        bool _incompleteFund;
        uint256 _costToAllocate = totalInvested.sub(totalAllocated);
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
                _phaseCost = _phaseCost.add(
                    _phaseCost.mul(builderFee).div(1000)
                );
                if (_costToAllocate >= _phaseCost) {
                    _costToAllocate = _costToAllocate.sub(_phaseCost);
                } else {
                    _incompleteFund = true;
                    break;
                }
            }

            if (i == _nonFundedPhaseLength.sub(1)) {
                delete nonFundedPhase;
                nonFundedCounter = 0;
            } else nonFundedCounter = i;
        }

        // Fund Tasks
        if (!_incompleteFund) {
            uint256 _count;
            uint256 _phase;
            for (uint256 i = 0; i < nonFundedTaskPhases.length; i++) {
                uint256[] memory _nonFundedPhaseToTask =
                    nonFundedPhaseToTask[nonFundedTaskPhases[i]];
                uint256 _nonFundedTaskLength = _nonFundedPhaseToTask.length;
                _count = _count.add(_nonFundedTaskLength);
                if (_count > _maxLoop) {
                    _nonFundedTaskLength = _count - _maxLoop;
                    _incompleteFund = true; //not required for this loop
                }

                uint256 j = 0;
                for (j; j < _nonFundedTaskLength; j++) {
                    uint256 _taskId = _nonFundedPhaseToTask[j];
                    uint256 _taskCost = tasks[_taskId].cost;
                    _taskCost = _taskCost.add(
                        _taskCost.mul(builderFee).div(1000)
                    );
                    if (_costToAllocate >= _taskCost) {
                        tasks[_taskId].fundTask();
                        _costToAllocate = _costToAllocate.sub(_taskCost);
                        eventsInstance.taskFunded(_taskId);
                    } else {
                        _incompleteFund = true;
                        break;
                    }
                }

                if (_incompleteFund) {
                    _phase = i;
                    uint256[] memory _nonFundedTaskList =
                        new uint256[](_nonFundedTaskLength.sub(j));
                    uint256 _index = 0;
                    for (uint256 k = j; k < _nonFundedPhaseToTask.length; k++) {
                        _nonFundedTaskList[_index] = _nonFundedPhaseToTask[k];
                        _index = _index.add(1);
                    }
                    nonFundedPhaseToTask[i] = _nonFundedTaskList;
                    break;
                } else {
                    delete nonFundedPhaseToTask[i];
                }
            }

            if (_incompleteFund) {
                uint256[] memory _nonFundedTaskPhases = nonFundedTaskPhases;
                uint256[] memory _nonFundedTaskPhasesList =
                    new uint256[](_nonFundedTaskPhases.length.sub(_phase));
                uint256 _index;
                for (uint256 i = _phase; i < _nonFundedTaskPhases.length; i++) {
                    _nonFundedTaskPhasesList[_index] = _nonFundedTaskPhases[i];
                    _index = _index.add(1);
                }
                nonFundedTaskPhases = _nonFundedTaskPhasesList;
            } else {
                delete nonFundedTaskPhases;
            }
        }

        totalAllocated = totalInvested.sub(_costToAllocate);
    }

    //to withdraw amount remain in project after completion of project
    function withdraw() public onlyBuilder {
        for (uint256 _phase = 1; _phase <= phaseCount; _phase++) {
            if (!phases[_phase].paid) {
                revert("31");
            }
        }

        if (currency == rigor.etherCurrency()) {
            payable(msgSender()).transfer(address(this).balance);
        } else {
            IERC20 _token = IERC20(currency);
            _token.transfer(msgSender(), _token.balanceOf(address(this)));
        }
    }

    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
    {
        (uint256 _phase, uint256 _index, address _newSC, uint256 _newCost) =
            abi.decode(_data, (uint256, uint256, address, uint256));
        checkSignatureTask(_data, _signature, _index);
        uint256 _taskCost = tasks[_index].cost;
        if (_newCost != _taskCost) {
            uint256 _totalAllocated = totalAllocated;
            if (_newCost < _taskCost) {
                require(checkPrecision(_newCost), "36");
                //when _newCost is less than task cost
                totalAllocated = _totalAllocated.sub(
                    tasks[_index].cost.sub(_newCost)
                );
            } else if (
                //when _newCost is more than task cost and totalInvestment is enough
                totalInvested.sub(_totalAllocated) >= _newCost.sub(_taskCost)
            ) {
                totalAllocated = _totalAllocated.add(_newCost.sub(_taskCost));
            } else {
                //when _newCost is more than task cost and totalInvestment is not enough.
                tasks[_index].alerts[1] = false; // non-funded
                totalAllocated = _totalAllocated.sub(tasks[_index].cost); // reduce from total allocated

                if (nonFundedPhaseToTask[_phase].length == 0) {
                    uint256 _length = nonFundedTaskPhases.length;
                    nonFundedTaskPhases.push(_phase);
                    if (
                        _length > 0 && nonFundedTaskPhases[_length - 1] > _phase
                    ) {
                        nonFundedTaskPhases = sort_array(nonFundedTaskPhases);
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

    function payFee(address _recipient, uint256 _amount) private {
        uint256 _builderFee = _amount.mul(builderFee).div(1000);
        address payable _treasury = rigor.treasury();

        if (currency == rigor.etherCurrency()) {
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
            _cost = _cost.add(phases[_phase].phaseCost);
            for (
                uint256 _task = 1;
                _task <= phases[_phase].phaseToTaskList.length;
                _task++
            ) {
                _cost = _cost.add(
                    tasks[phases[_phase].phaseToTaskList[_task - 1]].cost
                );
            }
        }
        _cost = _cost.add(_cost.mul(builderFee).div(1000));
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
    ) internal pure returns (address[3] memory _recoveredArray) {
        bytes32 _hash = keccak256(_data);
        for (uint256 i = 0; i < _count; i++) {
            _recoveredArray[i] = recoverKey(_hash, _signature, i);
        }
    }

    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
        view
    {
        address[3] memory _a = recoverAddresses(_data, _signature, 2);
        require(
            (_a[0] == builder && _a[1] == contractor) ||
                (_a[0] == contractor && _a[1] == builder),
            "33"
        );
    }

    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _index
    ) internal view {
        address[3] memory _a = recoverAddresses(_data, _signature, 3);
        require(_a[0] != _a[1] && _a[0] != _a[2] && _a[1] != _a[2], "34");
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
            "35"
        );
    }

    // Insertion Sort
    function sort_array(uint256[] memory arr_)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 l = arr_.length;
        uint256[] memory arr = new uint256[](l);
        for (uint256 i = 0; i < l; i++) {
            arr[i] = arr_[i];
        }
        for (uint256 i = 0; i < l; i++) {
            for (uint256 j = i + 1; j < l; j++) {
                if (arr[i] > arr[j]) {
                    uint256 temp = arr[j];
                    arr[j] = arr[i];
                    arr[i] = temp;
                }
            }
        }
        return arr;
    }

    function checkPrecision(uint256 _amount) internal pure returns (bool) {
        return _amount.div(1000).mul(1000) == _amount;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.0;

import "./math/SafeMath.sol";

contract BasicMetaTransaction {
    using SafeMath for uint256;

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    function getChainID() public pure returns (uint256) {
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
        (bool success, bytes memory returnData) =
            address(this).call(
                abi.encodePacked(functionSignature, userAddress)
            );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
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
        bytes32 hash =
            prefixed(
                keccak256(
                    abi.encodePacked(nonce, this, chainID, functionSignature)
                )
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

pragma solidity >=0.7.0 <0.8.0;

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

pragma solidity >=0.7.0 <0.8.0;
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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

pragma solidity >=0.5.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

contract SignatureDecoder {
    
    /// @dev Recovers address who signed the message
    /// @param messageHash operation ethereum signed message hash
    /// @param messageSignature message `txHash` signature
    /// @param pos which signature to read
    function recoverKey (
        bytes32 messageHash,
        bytes memory messageSignature,
        uint256 pos
    )
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignature, pos);
        return ecrecover(messageHash, v, r, s);
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

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

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: UNLICENSED

interface IEvents {
    function hashUpdated(bytes calldata _updatedHash) external;

    function contractorInvited(
        address _contractor,
        uint256[] calldata _feeSchedule
    ) external;

    function contractorSwapped(address _oldContractor, address _newContractor)
        external;

    function builderConfirmed(address _builder) external;

    function contractorConfirmed(address _builder) external;

    function phasesAdded(uint256[] calldata _phaseCosts) external;

    function phaseUpdated(uint256[] calldata _phases, uint256[] calldata _costs)
        external;

    function taskHashUpdated(uint256 _taskId, bytes32[2] calldata _taskHash)
        external;

    function taskCreated(uint256 _taskID) external;

    function investedInProject(uint256 _cost) external;

    function scInvited(uint256 _taskID, address _sc) external;

    function scSwapped(
        uint256 _taskID,
        address _old,
        address _new
    ) external;

    function scConfirmed(uint256 _taskID, address _sc) external;

    function taskFunded(uint256 _taskID) external;

    function taskComplete(uint256 _taskID) external;

    function contractorFeeReleased(uint256 _phase) external;

    function changeOrderFee(uint256 _taskID, uint256 _newCost) external;

    function changeOrderSC(uint256 _taskID, address _sc) external;

    function projectAdded(
        uint256 _projectID,
        address _projectAddress,
        address _builder
    ) external;

    function repayInvestor(
        uint256 _index,
        address _projectAddress,
        address _investor,
        uint256 _tAmount
    ) external;

    function disputeRaised(
        address _sender,
        address _project,
        uint256 _taskId,
        uint256 _disputeId
    ) external;

    function disputeResolved(
        uint256 _disputeId,
        uint256 _result,
        bytes calldata _resultHash
    ) external;

    function communityAdded(
        uint256 _communityID,
        address _owner,
        address _currency,
        bytes calldata _hash
    ) external;

    function updateCommunityHash(
        uint256 _communityID,
        bytes calldata _oldHash,
        bytes calldata _newHash
    ) external;

    function memberAdded(uint256 _communityID, address _member) external;

    function projectPublished(
        uint256 _communityID,
        uint256 _apr,
        address _project,
        address _builder
    ) external;

    function investorInvested(
        uint256 _communityID,
        address _project,
        address _investor,
        uint256 _cost
    ) external;

    function nftCreated(uint256 _id, address _owner) external;

    function debtTransferred(
        uint256 _index,
        address _project,
        address _investor,
        address _to,
        uint256 _totalAmount
    ) external;

    function claimedInterest(
        uint256 _index,
        address _project,
        address _investor,
        uint256 _interestEarned,
        uint256 _totalAmount
    ) external;
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "../external/contracts/math/SafeMath.sol";
import "./IEvents.sol";
import "./IRigor.sol";
import "../external/contracts/signature/SignatureDecode.sol";
import "../external/contracts/token/ERC20/IERC20Original.sol";
import "../external/contracts/BasicMetaTransaction.sol";

import {Tasks, Task} from "../libraries/Tasks.sol";

/**
 * Rigor v0.1.0 Deployable Project Escrow Contract Interface
 *
 * Interface for child contract from Rigor service contract; escrows all funds
 * Use task library to store hashes of data within project
 */
abstract contract IProject is BasicMetaTransaction {
    /// LIBRARIES///
    using SafeMath for uint256;
    using Tasks for Task;

    struct Phase {
        uint256 phaseCost;
        uint256[] phaseToTaskList;
        bool paid;
    }

    // Fixed //
    IRigor public rigor;
    IEvents internal eventsInstance;
    address public currency;
    uint256 public builderFee;
    uint256 public investorFee;
    address public builder;

    // Variable //
    bytes public projectHash;
    address public contractor;
    bool public contractorConfirmed;
    uint256 public hashChangeNonce;
    uint256 public totalInvested;
    uint256 public totalAllocated;
    uint256 public phaseCount; //starts from 1
    uint256 public taskSerial; //starts from 1

    uint256 internal nonFundedCounter;
    uint256[] internal nonFundedPhase;

    uint256 internal nonFundedPhaseIndex = 1;
    uint256 internal nonFundedTask;
    mapping(uint256 => uint256[]) internal nonFundedPhaseToTask; //nonFundedPhaseToTasks
    uint256[] internal nonFundedTaskPhases; //sorted array of phase with non funded tasks

    mapping(uint256 => Phase) public phases;
    mapping(uint256 => Task) public tasks; //starts from 1

    /// MODIFIERS ///
    modifier onlyRigor() {
        require(msgSender() == address(rigor), "1");
        _;
    }

    modifier onlyBuilder() {
        require(msgSender() == builder, "2");
        _;
    }

    modifier contractorNotAccepted() {
        require(!contractorConfirmed, "5");
        _;
    }

    modifier contractorAccepted() {
        require(contractorConfirmed, "5.2");
        _;
    }

    /**
     * Pay a general contractor's fee for a given phase
     * @dev modifier onlyBuilder
     * @param _phase the phase to pay out
     */
    function releaseFeeContractor(uint256 _phase) external virtual;

    // Task-Specific //

    /**
     * Create a new task in this project
     * @dev modifier onlyContractor
     */
    function addTask(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Mark a task as complete
     * @dev modifier onlyContractor
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        virtual;

    /**
     * Invite a subcontractor to a given task
     * @dev modifier onlyContractor
     * @param _index uint: the index of the task the sc is invited to
     * @param _to address: the address of the subcontractor being invited
     */
    function inviteSC(uint256[] memory _index, address[] memory _to)
        public
        virtual;

    /**
     * Accept an invite to a given task
     * @dev modifier onlySC
     * @param _index uint: the index of the task being joined
     */
    function acceptInviteSC(uint256 _index) external virtual;

    function investInProject(uint256 _cost) external payable virtual;

    function fundProject() public virtual;

    /**
     * Recover lifecycle alerts from a task
     * @param _index uint the index of the task within the project contract
     * @return _alerts bool[5] array of alert statuses
     */
    function getAlerts(uint256 _index)
        public
        view
        virtual
        returns (bool[3] memory _alerts);

    function getTaskHash(uint256 _index)
        external
        view
        virtual
        returns (bytes32[2] memory _taskHash)
    {
        return tasks[_index].taskHash;
    }

    /**
     * Get the cost of a contractor's Fees
     * @return _cost uint the sum of all fees across all phases
     */
    function projectCost() external view virtual returns (uint256 _cost);

    function getPhaseToTaskList(uint256 _index)
        external
        view
        virtual
        returns (uint256[] memory _taskList);
}

pragma solidity >=0.7.0 <0.8.0;
//SPDX-License-Identifier: UNLICENSED

import "../external/contracts/math/SafeMath.sol";
import "./IEvents.sol";
import "../external/contracts/BasicMetaTransaction.sol";

interface IProjectFactory {
    function createProject(
        bytes memory _hash,
        address _currency,
        address _sender
    ) external returns (address _clone);
}

abstract contract IRigor is BasicMetaTransaction {
    /// LIBRARIES ///
    using SafeMath for uint256;

    modifier onlyAdmin() {
        require(admin == msgSender(), "only owner");
        _;
    }

    modifier nonZero(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// VARIABLES ///
    address public constant etherCurrency =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant daiCurrency =
        0x273f6Ebe797369F53ad3F286F0789Cb6ce548455;
    address public constant usdcCurrency =
        0xCD78b8062029d0EF32cc1c9457b6beC636A81A69;

    IEvents public eventsInstance;
    IProjectFactory public projectFactoryInstance; //TODO if it can be made internal
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

    function setAddr(
        address _eventsContract,
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _rETHAddress,
        address _rDaiAddress,
        address _rUSDCAddress
    ) external virtual;

    function validCurrency(address _currency) public pure virtual;

    /// ADMIN MANAGEMENT ///
    function replaceAdmin(address _newAdmin) external virtual;

    function replaceTreasury(address _treasury) external virtual;

    function replaceNetworkFee(uint256 _builderFee, uint256 _investorFee)
        external
        virtual;

    /// PROJECT ///
    function createProject(bytes memory _hash, address _currency)
        external
        virtual;
}

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: UNLICENSED

library Tasks {
    /// MODIFIERS ///
    modifier uninitialized(Task storage _self) {
        require(_self.state == TaskStatus.None, "Already initialized");
        _;
    }

    modifier onlyInactive(Task storage _self) {
        require(!_self.alerts[uint256(Lifecycle.SCConfirmed)], "Only Inactive");
        _;
    }

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
     * @param _self Task the task being joined by subcontractor
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

//Task metadata
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

