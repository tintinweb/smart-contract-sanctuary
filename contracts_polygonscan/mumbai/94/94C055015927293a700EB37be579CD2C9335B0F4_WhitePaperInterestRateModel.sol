// SPDX-License-Identifier: MIT
/// @dev size: 2.426 Kbytes
pragma solidity ^0.8.0;

import "./InterestRateModel.sol";
import "../security/Ownable.sol";

/**
  * @title InterestRateModel Contract
  * @author Amplify
  */
contract WhitePaperInterestRateModel is InterestRateModel, Ownable {
    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint256 internal immutable blocksPerYear;

    GracePeriod[] private _gracePeriod;

    constructor(uint256 _blockPerYear) {
        blocksPerYear = _blockPerYear;
        predefinedStages();
    }

    function predefinedStages() internal {
        _gracePeriod.push(GracePeriod(4e16, 30, 60));
        _gracePeriod.push(GracePeriod(8e16, 60, 120));
        _gracePeriod.push(GracePeriod(15e16, 120, 180));
    }
    
    /**
     * @dev See {InterestRateModel-utilizationRate}.
     */
    function utilizationRate(uint256 cash, uint256 borrows) external override pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }

        return borrows * 1e18 / (cash + borrows);
    }

    /**
     * @dev See {InterestRateModel-getBorrowRate}.
     */
    function getBorrowRate(uint256 interestRate) external override view returns (uint256) { 
        return interestRate / blocksPerYear;
    }

    /**
     * @dev See {InterestRateModel-getGracePeriod}.
     */
    function getGracePeriod() external override view returns (GracePeriod[] memory) {
        return _gracePeriod;
    }

    function getGracePeriodSnapshot() external override view returns (GracePeriod[] memory, uint256) {
        return (_gracePeriod, blocksPerYear);
    }

    /**
     * @dev See {InterestRateModel-getPenaltyFee}.
     */
    function getPenaltyFee(uint8 index) external override view returns (uint256) {
        GracePeriod memory gracePeriod = _gracePeriod[index];

        if (gracePeriod.fee > 0) {
            return gracePeriod.fee / blocksPerYear;
        }
        return 0;
    }

    function addGracePeriod(uint256 _fee, uint256 _start, uint256 _end) external onlyOwner {
        _gracePeriod.push(GracePeriod(_fee, _start, _end));
    }

    function updateGracePeriod(uint256 _index, uint256 _fee, uint256 _start, uint256 _end) external onlyOwner {
        _gracePeriod[_index] = GracePeriod(_fee, _start, _end);
    }

    function removeGracePeriod(uint256 _index) external onlyOwner {
        delete _gracePeriod[_index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  * @title InterestRateModel Interface
  * @author Amplify
  */
abstract contract InterestRateModel {
	bool public isInterestRateModel = true;

    struct GracePeriod {
        uint256 fee;
        uint256 start;
        uint256 end;
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows)`
     * @param cash The amount of cash in the pool
     * @param borrows The amount of borrows in the pool
     * @return The utilization rate as a mantissa between [0, 1e18]
     */
    function utilizationRate(uint256 cash, uint256 borrows) external virtual pure returns (uint256);

    /**
     * @notice Calculates the borrow rate for a given interest rate and GracePeriod length
     * @param interestRate The interest rate as a percentage number between [0, 100]
     * @return The borrow rate as a mantissa between  [0, 1e18]
     */
    function getBorrowRate(uint256 interestRate) external virtual view returns (uint256);

    /**
     * @notice Calculates the penalty fee for a given days range
     * @param index The index of the grace period record
     * @return The penalty fee as a mantissa between [0, 1e18]
     */
    function getPenaltyFee(uint8 index) external virtual view returns (uint256);

    /**
     * @notice Returns the penalty stages array
     */
    function getGracePeriod() external virtual view returns (GracePeriod[] memory);
    function getGracePeriodSnapshot() external virtual view returns (GracePeriod[] memory, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

    /// @notice owner address set on construction
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership role
     * @notice Changes the owner of this contract to a new address
     * @dev Only owner
     * @param _newOwner beneficiary to vest remaining tokens to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must be non-zero");
        
        address currentOwner = owner;
        require(_newOwner != currentOwner, "New owner cannot be the current owner");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}