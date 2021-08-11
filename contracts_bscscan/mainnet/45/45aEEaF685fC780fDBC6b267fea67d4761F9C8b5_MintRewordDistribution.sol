/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow.");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow.");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow.");}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero.");
        return a / b;
    }
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow.");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

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

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner, "onlyAdmin");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingAdmin(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingAdmin(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingAdmin(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "Ownable: zero address");
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}


// Distribution fee
contract MintRewordDistribution is OwnableContract {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // MTS token
    address public mts;
    // Development team reword address
    address public devTo;
    // MintBar address
    address public bar;

    address private deadAddress = 0x000000000000000000000000000000000000dEaD;

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
    event BarAllocPoint(address indexed sender, uint256 allocPoint);
    event DevAllocPoint(address indexed sender, uint256 allocPoint);
    event DeflationAllocPoint(address indexed sender, uint256 allocPoint);

    constructor(address _bar, address _mts, address _devTo) public {
        bar = _bar;
        mts = _mts;
        devTo = _devTo;

        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
    }

    // distribute reword
    function distribute() external onlyAdmin() {
        uint256 totalAmount = IERC20(mts).balanceOf(address(this));
        if (totalAmount < 10) {
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
        IERC20(mts).safeTransfer(deadAddress, amountDeflation);

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
        emit BarAllocPoint(msg.sender, barAllocPoint);
    }

    function setDevAllocPoint(uint256 _devAllocPoint) public onlyOwner {
        devAllocPoint = _devAllocPoint;
        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
        emit DevAllocPoint(msg.sender, devAllocPoint);
    }

    function setDeflationAllocPoint(uint256 _deflationAllocPoint) public onlyOwner {
        deflationAllocPoint = _deflationAllocPoint;
        totalAllocPoint = barAllocPoint.add(devAllocPoint).add(deflationAllocPoint);
        emit DeflationAllocPoint(msg.sender, deflationAllocPoint);
    }

}