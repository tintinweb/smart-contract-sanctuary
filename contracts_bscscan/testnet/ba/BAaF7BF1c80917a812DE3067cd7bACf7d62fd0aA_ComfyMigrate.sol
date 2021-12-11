/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract Owner {

    address private owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract ComfyMigrate is ReentrancyGuard, Owner {

    struct MigrationInfo {
        uint256 maxAmount;
        uint256 remainingAmount;
        uint256 unlockTime;
    }

    bool public startUnlocking = false;
    bool public swapAllowed = false;
    mapping(address => bool) whitelistedWallet;
    mapping(address => MigrationInfo) comfyToMigrate; // address => remaining Comfy2
    uint256 maxWithdrawal = 250000000 * 10 ** 18; // 250M

    address comfy1 = 0xC737B44CB0Aa18815a1F6918EB338dEe7e7E6bD7;
    address comfy2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address multiSigWallet = 0x85f2893B8984d289C9afb6B4F0fB73d84fb1efbA;


    function swapComfy1ForComfy2() external nonReentrant {
        require(swapAllowed, "Swap not allowed yet");
        require(whitelistedWallet[msg.sender], "You are not whitelisted");
        IERC20 comfy1Token = IERC20(comfy1);
        uint256 comfy1Balance = comfy1Token.balanceOf(msg.sender);
        require(comfy1Balance > 0, "You don't have any Comfy1!");
        if(comfy1Balance > comfyToMigrate[msg.sender].maxAmount) {
            comfy1Balance = comfyToMigrate[msg.sender].maxAmount;
        }
        require(comfy1Token.transferFrom(msg.sender, address(this), comfy1Balance), "Transfer to ComfyMigrate failed");
        require(comfy1Token.transfer(multiSigWallet, comfy1Balance), "Transfer to MultiSigWallet failed");
        comfyToMigrate[msg.sender].unlockTime = block.timestamp;
    }

    function comfy2Withdrawal() external nonReentrant {
        require(startUnlocking, "Contract is still locked!");
        require(whitelistedWallet[msg.sender], "You are not whitelisted");
        require(comfyToMigrate[msg.sender].remainingAmount > 0, "Nothing to withdraw");
        require(block.timestamp > comfyToMigrate[msg.sender].unlockTime, "You have to wait 22 hours before you can withdraw again");
        comfyToMigrate[msg.sender].unlockTime = block.timestamp + 22 hours;
        IBEP20 comfy2Token = IBEP20(comfy2);
        uint256 amountToWithdraw = 0;
        if(comfyToMigrate[msg.sender].remainingAmount >= maxWithdrawal && maxWithdrawal <= comfyToMigrate[msg.sender].maxAmount) {
            amountToWithdraw = maxWithdrawal;
        } else {
            amountToWithdraw = comfyToMigrate[msg.sender].remainingAmount;
        }
        comfyToMigrate[msg.sender].remainingAmount -= amountToWithdraw;
        require(comfy2Token.transfer(msg.sender, amountToWithdraw), "Comfy2 withdrawal failed");
    }

    function burnAll() external onlyOwner {
        IBEP20 comfy2Token = IBEP20(comfy2);
        uint256 comfy2balance = comfy2Token.balanceOf(address(this));
        require(comfy2Token.transfer(DEAD, comfy2balance), "Burn failed");
    }

    function setComfy2Address(address addr) external onlyOwner {
        comfy2 = addr;
    }

    function setWhitelistedWallet(address walletAddress, bool isWhitelisted, uint256 maxAmount) external onlyOwner {
        whitelistedWallet[walletAddress] = isWhitelisted;
        comfyToMigrate[walletAddress].maxAmount = maxAmount;
        comfyToMigrate[walletAddress].remainingAmount = maxAmount;
    }

    function setStartUnlocking(bool unlocking) external onlyOwner {
        startUnlocking = unlocking;
    }

    function setSwapAllowed(bool allowed) external onlyOwner {
        swapAllowed = allowed;
    }

    function changeMultiSigWallet(address addr) external onlyOwner {
        multiSigWallet = addr;
    }

    // TEST ONLY REMOVE
    function changeComfy1Address(address addr) external onlyOwner {
        comfy1 = addr;
    }
    
}