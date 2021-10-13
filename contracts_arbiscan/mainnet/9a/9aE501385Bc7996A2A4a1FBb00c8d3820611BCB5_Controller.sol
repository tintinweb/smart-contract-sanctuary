/**
 *Submitted for verification at arbiscan.io on 2021-10-13
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

/**
 * @title Ownable
 * @author DODO Breeder
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
        require(!_INITIALIZED_, "DODO_INITIALIZED");
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

// File: contracts/lib/SafeMath.sol


/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/NFTPool/impl/Controller.sol



contract Controller is InitializableOwnable {
    using SafeMath for uint256;

    uint256 public _GLOBAL_NFT_IN_FEE_RATE_ = 0;
    uint256 public _GLOBAL_NFT_OUT_FEE_RATE_ = 0;

    struct FilterAdminFeeRateInfo {
        uint256 nftInFeeRate;
        uint256 nftOutFeeRate;
        bool isOpen;
    }

    mapping(address => FilterAdminFeeRateInfo) filterAdminFeeRates;

    mapping(address => bool) public isEmergencyWithdrawOpen;

    //==================== Event =====================
    event SetEmergencyWithdraw(address filter, bool isOpen);
    event SetFilterAdminFeeRateInfo(address filterAdmin, uint256 nftInFee, uint256 nftOutFee, bool isOpen);
    event SetGlobalParam(uint256 nftInFee, uint256 nftOutFee);

    //==================== Ownable ====================

    function setFilterAdminFeeRateInfo(
        address filterAdminAddr,
        uint256 nftInFeeRate,
        uint256 nftOutFeeRate,
        bool isOpen
    ) external onlyOwner {
        require(nftInFeeRate <= 1e18 && nftOutFeeRate <= 1e18, "FEE_RATE_TOO_LARGE");
        FilterAdminFeeRateInfo memory feeRateInfo = FilterAdminFeeRateInfo({
            nftInFeeRate: nftInFeeRate,
            nftOutFeeRate: nftOutFeeRate,
            isOpen: isOpen
        });
        filterAdminFeeRates[filterAdminAddr] = feeRateInfo;

        emit SetFilterAdminFeeRateInfo(filterAdminAddr, nftInFeeRate, nftOutFeeRate, isOpen);
    }

    function setGlobalParam(uint256 nftInFeeRate, uint256 nftOutFeeRate) external onlyOwner {
        require(nftInFeeRate <= 1e18 && nftOutFeeRate <= 1e18, "FEE_RATE_TOO_LARGE");
        _GLOBAL_NFT_IN_FEE_RATE_ = nftInFeeRate;
        _GLOBAL_NFT_OUT_FEE_RATE_ = nftOutFeeRate;

        emit SetGlobalParam(nftInFeeRate, nftOutFeeRate);
    }

    function setEmergencyWithdraw(address filter, bool isOpen) external onlyOwner {
        isEmergencyWithdrawOpen[filter] = isOpen;
        emit SetEmergencyWithdraw(filter, isOpen);
    }

    //===================== View ========================
    function getMintFeeRate(address filterAdminAddr) external view returns (uint256) {
        FilterAdminFeeRateInfo memory filterAdminFeeRateInfo = filterAdminFeeRates[filterAdminAddr];

        if (filterAdminFeeRateInfo.isOpen) {
            return filterAdminFeeRateInfo.nftInFeeRate;
        } else {
            return _GLOBAL_NFT_IN_FEE_RATE_;
        }
    }

    function getBurnFeeRate(address filterAdminAddr) external view returns (uint256) {
        FilterAdminFeeRateInfo memory filterAdminFeeInfo = filterAdminFeeRates[filterAdminAddr];

        if (filterAdminFeeInfo.isOpen) {
            return filterAdminFeeInfo.nftOutFeeRate;
        } else {
            return _GLOBAL_NFT_OUT_FEE_RATE_;
        }
    }
}