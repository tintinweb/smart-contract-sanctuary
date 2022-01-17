/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    Note: This version of plasma has been migrated
    Please check the Space Yetis contract for the correct address
*/

/*
    ERC20I (ERC20 0xInuarashi Edition)
    Minified and Gas Optimized
    From the efforts of the 0x Collective
    https://0xcollective.net
*/

contract ERC20I {
    // Token Params
    string public name;
    string public symbol;
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    // Decimals
    uint8 public constant decimals = 18;

    // Supply
    uint256 public totalSupply;
    
    // Mappings of Balances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Internal Functions
    function _mint(address to_, uint256 amount_) internal virtual {
        totalSupply += amount_;
        balanceOf[to_] += amount_;
        emit Transfer(address(0x0), to_, amount_);
    }
    function _burn(address from_, uint256 amount_) internal virtual {
        balanceOf[from_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(from_, address(0x0), amount_);
    }
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        allowance[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    // Public Functions
    function approve(address spender_, uint256 amount_) public virtual returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }
    function transfer(address to_, uint256 amount_) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(msg.sender, to_, amount_);
        return true;
    }
    function transferFrom(address from_, address to_, uint256 amount_) public virtual returns (bool) {
        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }
        balanceOf[from_] -= amount_;
        balanceOf[to_] += amount_;
        emit Transfer(from_, to_, amount_);
        return true;
    }

    // 0xInuarashi Custom Functions
    function multiTransfer(address[] memory to_, uint256[] memory amounts_) public virtual {
        require(to_.length == amounts_.length, "ERC20I: To and Amounts length Mismatch!");
        for (uint256 i = 0; i < to_.length; i++) {
            transfer(to_[i], amounts_[i]);
        }
    }
    function multiTransferFrom(address[] memory from_, address[] memory to_, uint256[] memory amounts_) public virtual {
        require(from_.length == to_.length && from_.length == amounts_.length, "ERC20I: From, To, and Amounts length Mismatch!");
        for (uint256 i = 0; i < from_.length; i++) {
            transferFrom(from_[i], to_[i], amounts_[i]);
        }
    }
}

abstract contract ERC20IBurnable is ERC20I {
    function burn(uint256 amount_) external virtual {
        _burn(msg.sender, amount_);
    }
    function burnFrom(address from_, uint256 amount_) public virtual {
        uint256 _currentAllowance = allowance[from_][msg.sender];
        require(_currentAllowance >= amount_, "ERC20IBurnable: Burn amount requested exceeds allowance!");

        if (allowance[from_][msg.sender] != type(uint256).max) {
            allowance[from_][msg.sender] -= amount_; }

        _burn(from_, amount_);
    }
}

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}

interface iSpaceYetis {
    function balanceOf(address address_) external view returns (uint256);
}

contract Plasma is ERC20IBurnable, Ownable {
    constructor() ERC20I("Plasma", "PLASMA") {}

    // Interfaces
    address public spaceYetisAddress;
    iSpaceYetis public SpaceYetis;
    function setSpaceYetis(address address_) external onlyOwner {
        spaceYetisAddress = address_; SpaceYetis = iSpaceYetis(address_); }

    // Times
    uint40 public yieldStartTime = 1640221200; // 2021-12-22_20-00 EST
    uint40 public yieldEndTime = 1955754000; // 2031-12-22_20-00 EST
    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner {
        yieldEndTime = yieldEndTime_; }

    // Yield Info
    uint256 public globalModulus = (10 ** 14);
    uint40 public yieldRatePerYeti = uint40(5 ether / globalModulus);
    struct Yield { uint40 lastUpdatedTime_; uint176 pendingRewards_; }
    mapping(address => Yield) public addressToYield;

    // Events
    event Claim(address to_, uint256 amount_);
    event CreditsDeducted(address from_, uint256 amount_);
    event CreditsAdded(address to_, uint256 amount_);

    // Controllers
    mapping(address => bool) public plasmaControllers;
    modifier onlyControllers { 
        require(plasmaControllers[msg.sender], "You are not a controller!"); _; }
    function setControllers(address address_, bool bool_) external onlyOwner {
        plasmaControllers[address_] = bool_; }
    
    // Credits System
    function deductCredits(address address_, uint256 amount_) external onlyControllers {
        uint176 _downscaledAmount = uint176(amount_ / globalModulus);
        require(addressToYield[address_].pendingRewards_ >= _downscaledAmount, 
            "Not enough credits!");
        addressToYield[address_].pendingRewards_ -= _downscaledAmount;
        emit CreditsDeducted(address_, amount_);
    }
    function addCredits(address address_, uint256 amount_) external onlyControllers {
        uint176 _downscaledAmount = uint176(amount_ / globalModulus);
        addressToYield[address_].pendingRewards_ += _downscaledAmount;
        emit CreditsAdded(address_, amount_);
    }

    // ERC20 Burn
    function burnByController(address from_, uint256 amount_) external onlyControllers {
        _burn(from_, amount_); }
    
    // Internal View Functions
    function __getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) { return a < b ? a : b; }
    function __getTimestamp() internal view returns (uint40) {
        return __getSmallerValueUint40(uint40(block.timestamp), yieldEndTime); }
    function __getYieldRate(address address_) internal view returns (uint40) {
        return uint40(SpaceYetis.balanceOf(address_)) * yieldRatePerYeti; }

    function __calculateYieldReward(address address_) internal view returns (uint176) { 
        uint40 _totalYieldRate = __getYieldRate(address_);
        if (_totalYieldRate == 0) { return 0; }
        uint40 _time = __getTimestamp();
        uint40 _lastUpdate = addressToYield[address_].lastUpdatedTime_;

        if (_lastUpdate > yieldStartTime) {
            return (_totalYieldRate * (_time - _lastUpdate) / 1 days);
        } else { return 0; }
    }

    // Internal Write Functions
    function __updateYieldReward(address address_) internal {
        uint40 _time = __getTimestamp();
        uint40 _lastUpdate = addressToYield[address_].lastUpdatedTime_;

        // This is not triggered in the case that the user has never minted / held a token before.
        if (_lastUpdate > 0) { 
            addressToYield[address_].pendingRewards_ += __calculateYieldReward(address_);
        }
        // This updates the time until the end when yieldEndTime is set on block.timestamp >= yieldEndTime occurance.
        if (_lastUpdate != yieldEndTime) {
            addressToYield[address_].lastUpdatedTime_ = _time;
        }
    }
    function __claimYieldReward(address address_) internal {
        uint176 _pendingRewards = addressToYield[address_].pendingRewards_;

        if (_pendingRewards > 0) {
            addressToYield[address_].pendingRewards_ = 0;
        
            uint256 _expandedReward = uint256(_pendingRewards * globalModulus);
        
            _mint(address_, _expandedReward); 
            emit Claim(address_, _expandedReward);
        }
    }

    // Public Write Functions
    function updateReward(address address_) public {
        __updateYieldReward(address_);
    }
    function claimTokens(address address_) public {
        __updateYieldReward(address_);
        __claimYieldReward(address_);
    }

    // Public View Functions
    function getStorageClaimableTokens(address address_) public view returns (uint256) {
        return uint256(addressToYield[address_].pendingRewards_ * globalModulus);
    }
    function getPendingClaimableTokens(address address_) public view returns (uint256) {
        return uint256(__calculateYieldReward(address_) * globalModulus);
    }
    function getTotalClaimableTokens(address address_) public view returns (uint256) {
        return uint256((addressToYield[address_].pendingRewards_ + __calculateYieldReward(address_)) * globalModulus);
    }
    function getYieldRateOfAddress(address address_) public view returns (uint256) {
        return uint256(__getYieldRate(address_) * globalModulus); 
    }
    function raw_getStorageClaimableTokens(address address_) public view returns (uint256) {
        return addressToYield[address_].pendingRewards_;
    }
    function raw_getPendingClaimableTokens(address address_) public view returns (uint256) {
        return __calculateYieldReward(address_);
    }
    function raw_getTotalClaimableTokens(address address_) public view returns (uint256) {
        return addressToYield[address_].pendingRewards_ + __calculateYieldReward(address_);
    }
}