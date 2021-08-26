/**
 *Submitted for verification at polygonscan.com on 2021-08-25
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2021
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author Murciano207
 *
 * @notice Ownership related functions
 */
contract InitializableOwnable {
    address public _OWNER_;
    address public _NEW_OWNER_;
    bool internal _INITIALIZED_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier notInitialized() {
        require(!_INITIALIZED_, "Spook_INITIALIZED");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    function initOwner(address newOwner) public notInitialized {
        _INITIALIZED_ = true;
        _OWNER_ = newOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

// File: contracts/lib/FeeRateModel.sol


interface IFeeRateImpl {
    function getFeeRate(address pool, address trader) external view returns (uint256);
}

interface IFeeRateModel {
    function getFeeRate(address trader) external view returns (uint256);
}

contract FeeRateModel is InitializableOwnable {
    address public feeRateImpl;

    function setFeeProxy(address _feeRateImpl) public onlyOwner {
        feeRateImpl = _feeRateImpl;
    }
    
    function getFeeRate(address trader) external view returns (uint256) {
        if(feeRateImpl == address(0))
            return 0;
        return IFeeRateImpl(feeRateImpl).getFeeRate(msg.sender,trader);
    }
}