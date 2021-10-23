/**
 *Submitted for verification at polygonscan.com on 2021-10-21
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: MultiChainDebtShareManager.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/MultiChainDebtShareManager.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/MultiChainDebtShareManager
*
* Contract Dependencies: 
*	- IMultiChainDebtShareManager
*	- Owned
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


interface IMultiChainDebtShareManager {
    // View Functions
    function multiChainDebtShareState() external view returns (address);

    function getCurrentExternalDebtEntry() external view returns (uint debtShare, bool isDecreased);

    // Mutative functions
    function setCurrentExternalDebtEntry(uint debtShare, bool isDecreased) external;

    function removeCurrentExternalDebtEntry() external;

    function setMultiChainDebtShareState(address multiChainDebtShareStateAddress) external;
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


contract MultiChainDebtShareManager is Owned, IMultiChainDebtShareManager {
    IMultiChainDebtShareState internal _multiChainDebtShareState;

    constructor(address _owner, address _debtShareState) public Owned(_owner) {
        _multiChainDebtShareState = IMultiChainDebtShareState(_debtShareState);
    }

    // View functions
    function multiChainDebtShareState() external view returns (address) {
        return address(_multiChainDebtShareState);
    }

    function getCurrentExternalDebtEntry() external view returns (uint debtShare, bool isDecreased) {
        (debtShare, isDecreased, ) = _multiChainDebtShareState.lastDebtShareStorageInfo();
    }

    // Mutative functions
    function setCurrentExternalDebtEntry(uint debtShare, bool isDecreased) external onlyOwner {
        _multiChainDebtShareState.appendToDebtShareStorage(debtShare, isDecreased);
    }

    function removeCurrentExternalDebtEntry() external onlyOwner {
        _multiChainDebtShareState.removeDebtShareStorage(_multiChainDebtShareState.lastDebtShareStorageIndex());
    }

    function setMultiChainDebtShareState(address multiChainDebtShareStateAddress) external onlyOwner {
        _multiChainDebtShareState = IMultiChainDebtShareState(multiChainDebtShareStateAddress);
    }
}