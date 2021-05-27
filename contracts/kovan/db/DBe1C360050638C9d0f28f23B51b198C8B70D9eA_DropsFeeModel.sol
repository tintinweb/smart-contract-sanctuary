/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// File: contracts/lib/InitializableOwnable.sol

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

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

// File: contracts/lib/DecimalMath.sol


/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant ONE = 10**18;
    uint256 internal constant ONE2 = 10**36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / (10**18);
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(10**18);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(10**18).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).div(target);
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return uint256(10**36).divCeil(target);
    }
}

// File: contracts/DODODrops/DODODropsV2/DropsFeeModel.sol


interface IFee {
    function getUserFee(address user,uint256 ticketAmount) external view returns (uint256);
}

interface IPrice {
    function getUserPrice(address user, uint256 originalPrice, uint256 ticketAmount) external view returns (uint256);
}

contract DropsFeeModel is InitializableOwnable {
    using SafeMath for uint256;

    struct DropBoxInfo {
        bool isSet;
        uint256 globalFee;
        address feeAddr;
        address priceAddr;
    }

    mapping(address => DropBoxInfo) dropBoxes;

    function addDropBoxInfo(address dropBox, uint256 globalFee, address feeAddr, address priceAddr) external onlyOwner {
        DropBoxInfo memory dropBoxInfo =  DropBoxInfo({
            isSet: true,
            globalFee: globalFee,
            feeAddr: feeAddr,
            priceAddr: priceAddr
        });
        dropBoxes[dropBox] = dropBoxInfo;
    }

    function setDropBoxInfo(address dropBox, uint256 globalFee, address feeAddr, address priceAddr) external onlyOwner {
        require(dropBoxes[dropBox].isSet, "NOT_FOUND_BOX");
        dropBoxes[dropBox].globalFee = globalFee;
        dropBoxes[dropBox].feeAddr = feeAddr;
        dropBoxes[dropBox].priceAddr = priceAddr;
    }

    function getPayAmount(address dropBox, address user, uint256 originalPrice, uint256 ticketAmount) external view returns (uint256 payAmount, uint256 feeAmount) {
        DropBoxInfo memory dropBoxInfo = dropBoxes[dropBox];
        if(!dropBoxInfo.isSet) {
            payAmount = originalPrice.mul(ticketAmount);
            feeAmount = 0;
        } else {
            uint256 feeRate = dropBoxInfo.globalFee;
            address feeAddr = dropBoxInfo.feeAddr;
            if(feeAddr != address(0))
                feeRate = IFee(feeAddr).getUserFee(user, ticketAmount);
            
            uint256 price = originalPrice;
            address priceAddr = dropBoxInfo.priceAddr;
            if(priceAddr != address(0))
                price = IPrice(priceAddr).getUserPrice(user, originalPrice, ticketAmount);
            
            payAmount = price.mul(ticketAmount);
            feeAmount = DecimalMath.mulFloor(payAmount, feeRate);
        }
    }
}