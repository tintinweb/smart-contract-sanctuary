/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// File: contracts\libraries\SafeMath.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

// File: contracts\interfaces\IERC20.sol



pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// File: contracts\libraries\SafeERC20.sol



pragma solidity 0.6.12;


library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeBalanceOf(IERC20 token, address account) public view returns (uint256) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x70a08231, account));
        return success && data.length > 0 ? abi.decode(data, (uint256)) : 0;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }

    function safeBurn(IERC20 token, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x42966c68, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Burn failed");
    }
}

// File: contracts\Ownable.sol


// Audit on 5-Jan-2021 by Keno and BoringCrypto

// P1 - P3: OK
pragma solidity 0.6.12;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

// T1 - T4: OK
contract OwnableData {
    // V1 - V5: OK
    address public owner;
    // V1 - V5: OK
    address public pendingOwner;
}

// T1 - T4: OK
contract Ownable is OwnableData {
    // E1: OK
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    // F1 - F9: OK
    // C1 - C21: OK
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    // M1 - M5: OK
    // C1 - C21: OK
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File: contracts\MintRewordDistribution.sol



// P1 - P3: OK
pragma solidity 0.6.12;




// Distribution fee
contract MintRewordDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // MTS token
    address public mts;
    // Development team reword address
    address public devTo;
    // MintBar address
    address public bar;

    // Allocation points assigned to MintBar
    uint256 public barAllocPoint = 10;
    // Allocation points assigned to development team 
    uint256 public devAllocPoint = 3;
    // Allocation points assigned to deflation mts
    uint256 public deflationAllocPoint = 7; 
    // Total allocation points. Must be the sum of all allocation points.
    uint256 public totalAllocPoint = 0; 

    event Distribution(
        address indexed bar,
        address indexed devTo,
        uint256 amountBar,
        uint256 amountDev,
        uint256 amountDeflation
    );

    constructor(address _bar, address _mts, address _devTo) public {
        bar = _bar;
        mts = _mts;
        devTo = _devTo;

        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
    }

    // It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "MintRewordDistribution: must use EOA");
        _;
    }

    // distribute reword
    function distribute() external onlyEOA() {
        uint256 totalAmount = IERC20(mts).balanceOf(address(this));
        if (totalAmount == 0) {
            return;
        }

        // distribute to MintBar
        uint256 amountBar = totalAmount.mul(barAllocPoint).div(totalAllocPoint);
        IERC20(mts).safeTransfer(bar, amountBar);
        // distribute to dev
        uint256 amountDev = totalAmount.mul(devAllocPoint).div(totalAllocPoint);
        IERC20(mts).safeTransfer(devTo, amountDev);
        // distribute to deflation
        uint256 amountDeflation = totalAmount.mul(deflationAllocPoint).div(totalAllocPoint);
        IERC20(mts).safeBurn(amountDeflation);

        emit Distribution(bar, devTo, amountBar, amountDev, amountDeflation);
    }

    function setDevTo(address _devTo) public onlyOwner {
        devTo = _devTo;
    }

    function setBar(address _bar) public onlyOwner {
        bar = _bar;
    }

    function setBarAllocPoint(uint256 _barAllocPoint) public onlyOwner {
        barAllocPoint = _barAllocPoint;
        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
    }

    function setDevAllocPoint(uint256 _devAllocPoint) public onlyOwner {
        devAllocPoint = _devAllocPoint;
        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
    }

    function setDeflationAllocPoint(uint256 _deflationAllocPoint) public onlyOwner {
        deflationAllocPoint = _deflationAllocPoint;
        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
    }

}