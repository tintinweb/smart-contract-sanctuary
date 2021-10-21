/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: MultiChainDebtShareState.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/MultiChainDebtShareState.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/MultiChainDebtShareState
*
* Contract Dependencies: 
*	- IMultiChainDebtShareState
*	- Owned
*	- State
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2021 PeriFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity 0.5.16;

// https://docs.peri.finance/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// Inheritance


// https://docs.peri.finance/contracts/source/contracts/state
contract State is Owned {
    // the address of the contract that can modify variables
    // this can only be changed by the owner of this contract
    address public associatedContract;

    constructor(address _associatedContract) internal {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== SETTERS ========== */

    // Change the associated contract to a new address
    function setAssociatedContract(address _associatedContract) external onlyOwner {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAssociatedContract {
        require(msg.sender == associatedContract, "Only the associated contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event AssociatedContractUpdated(address associatedContract);
}


interface IMultiChainDebtShareState {
    struct DebtShareStorage {
        // Indicates how much addtional debt should be added or subtracted
        // This should be only pUSD amount
        uint debtShare;
        // Indicates if the debtShare should be added or subtracted
        bool isDecreased;
        // When this data was added
        uint timeStamp;
    }

    // Views
    function debtShareStorageInfoAt(uint index)
        external
        view
        returns (
            uint debtShare,
            bool isDecreased,
            uint timeStamp
        );

    function debtShareStorageLength() external view returns (uint);

    function lastDebtShareStorageInfo()
        external
        view
        returns (
            uint debtShare,
            bool isDecreased,
            uint timeStamp
        );

    function lastDebtShareStorageIndex() external view returns (uint);

    // Mutative functions
    function appendToDebtShareStorage(uint debtShare, bool isDecreased) external;

    function updateDebtShareStorage(
        uint index,
        uint debtShare,
        bool isDecreased
    ) external;

    function removeDebtShareStorage(uint index) external;
}


// Inheritance


contract MultiChainDebtShareState is Owned, State, IMultiChainDebtShareState {
    DebtShareStorage[] private _debtShareStorage;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    // View functions
    function debtShareStorageInfoAt(uint index)
        external
        view
        returns (
            uint debtShare,
            bool isDecreased,
            uint timeStamp
        )
    {
        return (
            debtShare = _debtShareStorage[index].debtShare,
            isDecreased = _debtShareStorage[index].isDecreased,
            timeStamp = _debtShareStorage[index].timeStamp
        );
    }

    function debtShareStorageLength() external view returns (uint) {
        return _debtShareStorage.length;
    }

    function lastDebtShareStorageInfo()
        external
        view
        returns (
            uint debtShare,
            bool isDecreased,
            uint timeStamp
        )
    {
        if (_debtShareStorage.length < 1) {
            return (debtShare = 0, isDecreased = false, timeStamp = 0);
        }

        uint lastIndex = _lastDebtShareStorageIndex();
        debtShare = _debtShareStorage[lastIndex].debtShare;
        isDecreased = _debtShareStorage[lastIndex].isDecreased;
        timeStamp = _debtShareStorage[lastIndex].timeStamp;
    }

    function lastDebtShareStorageIndex() external view returns (uint) {
        return _lastDebtShareStorageIndex();
    }

    function _lastDebtShareStorageIndex() internal view returns (uint) {
        if (_debtShareStorage.length == 0) {
            return 0;
        }

        return _debtShareStorage.length - 1;
    }

    // Mutative functions
    function appendToDebtShareStorage(uint debtShare, bool isDecreased) external onlyAssociatedContract {
        DebtShareStorage memory debtShareStorage =
            DebtShareStorage({debtShare: debtShare, isDecreased: isDecreased, timeStamp: block.timestamp});

        _debtShareStorage.push(debtShareStorage);

        emit AppendDebtShareStorage(_lastDebtShareStorageIndex(), debtShare, isDecreased);
    }

    function updateDebtShareStorage(
        uint index,
        uint debtShare,
        bool isDecreased
    ) external onlyAssociatedContract {
        _debtShareStorage[index].debtShare = debtShare;
        _debtShareStorage[index].timeStamp = block.timestamp;
        _debtShareStorage[index].isDecreased = isDecreased;

        emit UpdatedDebtShareStorage(index, debtShare, isDecreased);
    }

    function removeDebtShareStorage(uint index) external onlyAssociatedContract {
        delete _debtShareStorage[index];

        emit RemovedDebtShareStorage(index);
    }

    // Modifiers

    // Events
    event AppendDebtShareStorage(uint index, uint _debtShare, bool isDecreased);

    event UpdatedDebtShareStorage(uint index, uint _debtShare, bool isDecreased);

    event RemovedDebtShareStorage(uint index);
}