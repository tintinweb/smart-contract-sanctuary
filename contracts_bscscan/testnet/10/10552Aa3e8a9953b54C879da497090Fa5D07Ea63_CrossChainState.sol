/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: CrossChainState.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/CrossChainState.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/CrossChainState
*
* Contract Dependencies: 
*	- ICrossChainState
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


interface ICrossChainState {
    struct CrossNetworkUserData {
        // total network debtLedgerIndex
        uint totalNetworkDebtLedgerIndex;
        // user state debtledgerIndex
        uint userStateDebtLedgerIndex;
    }

    // Views
    function totalNetworkDebtLedgerLength() external view returns (uint);

    function lastTotalNetworkDebtLedgerEntry() external view returns (uint);

    function getTotalNetworkDebtEntryAtIndex(uint) external view returns (uint);

    function getCrossNetworkUserData(address) external view returns (uint, uint);

    // Mutative functions
    function setCrossNetworkUserData(address, uint) external;

    function clearCrossNetworkUserData(address) external;

    function appendTotalNetworkDebtLedger(uint) external;
}


// Inheritance


/**
 * @title CrossChainState
 * @author @Enitsed
 * @notice This contract saves data of All the networks staking system debt
 */
contract CrossChainState is Owned, State, ICrossChainState {
    // the total network debt and current network debt percentage
    mapping(address => CrossNetworkUserData) private _crossNetworkUserData;

    uint[] internal _totalNetworkDebtLedger;

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    // View functions

    /**
     * @notice returns the length of total network debt entry
     * @return uint
     */
    function totalNetworkDebtLedgerLength() external view returns (uint) {
        return _totalNetworkDebtLedger.length;
    }

    /**
     * @notice returns the latest total network debt
     * @return uint
     */
    function lastTotalNetworkDebtLedgerEntry() external view returns (uint) {
        return _getTotalNetworkDebtEntryAtIndex(_totalNetworkDebtLedger.length - 1);
    }

    /**
     * @notice returns the total network debt amount at index
     * @param index uint
     * @return uint
     */
    function getTotalNetworkDebtEntryAtIndex(uint index) external view returns (uint) {
        return _getTotalNetworkDebtEntryAtIndex(index);
    }

    function getCrossNetworkUserData(address account)
        external
        view
        returns (uint crossChainDebtEntryIndex, uint userStateDebtLedgerIndex)
    {
        crossChainDebtEntryIndex = _crossNetworkUserData[account].totalNetworkDebtLedgerIndex;
        userStateDebtLedgerIndex = _crossNetworkUserData[account].userStateDebtLedgerIndex;
    }

    function _getTotalNetworkDebtEntryAtIndex(uint index) internal view returns (uint) {
        require(_totalNetworkDebtLedger.length > 0, "There is no available cross network debt data");

        return _totalNetworkDebtLedger[index];
    }

    // Mutative functions

    /**
     * @notice set total network status when user's debt ownership is changed
     * @param from address
     * @param userStateDebtLedgerIndex uint
     */
    function setCrossNetworkUserData(address from, uint userStateDebtLedgerIndex) external onlyAssociatedContract {
        _crossNetworkUserData[from] = CrossNetworkUserData(_totalNetworkDebtLedger.length - 1, userStateDebtLedgerIndex);

        emit UserCrossNetworkDataUpdated(from, userStateDebtLedgerIndex, block.timestamp);
    }

    /**
     * @notice clear the user's total network debt info
     * @param from address
     */
    function clearCrossNetworkUserData(address from) external onlyAssociatedContract {
        delete _crossNetworkUserData[from];

        emit UserCrossNetworkDataRemoved(from, block.timestamp);
    }

    /**
     * @notice append total network debt to the entry
     * @param totalNetworkDebt uint
     */
    function appendTotalNetworkDebtLedger(uint totalNetworkDebt) external onlyAssociatedContract {
        _totalNetworkDebtLedger.push(totalNetworkDebt);

        emit TotalNetworkDebtAdded(totalNetworkDebt, block.timestamp);
    }

    // Events

    /**
     * @notice Emitted when totalNetworkDebt has added
     * @param totalNetworkDebt uint
     * @param timestamp uint
     */
    event TotalNetworkDebtAdded(uint totalNetworkDebt, uint timestamp);

    /**
     * @notice Emitted when user cross network data updated
     * @param account address
     * @param userStateDebtLedgerIndex uint
     * @param timestamp uint
     */
    event UserCrossNetworkDataUpdated(address account, uint userStateDebtLedgerIndex, uint timestamp);

    /**
     * @notice Emitted when user cross network data deleted
     * @param account address
     * @param timestamp uint
     */
    event UserCrossNetworkDataRemoved(address account, uint timestamp);
}