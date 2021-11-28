/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

//SPDX-License-Identifier: Delayed Release MIT
pragma solidity ^0.8.0;

/*
    ERC20I (ERC20 0xInuarashi Edition)
    Minified and Gas Optimized
    Contributors: 0xInuarashi (Message to Martians, Anonymice), 0xBasset (Ether Orcs)
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
    function _mint(address to_, uint256 amount_) internal {
        totalSupply += amount_;
        balanceOf[to_] += amount_;
        emit Transfer(address(0x0), to_, amount_);
    }
    function _burn(address from_, uint256 amount_) internal {
        balanceOf[from_] -= amount_;
        totalSupply -= amount_;
        emit Transfer(from_, address(0x0), amount_);
    }

    // Public Functions
    function approve(address spender_, uint256 amount_) public virtual returns (bool) {
        allowance[msg.sender][spender_] = amount_;
        emit Approval(msg.sender, spender_, amount_);
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

// Martian Essence ($MES)
/*
    Calculate MES Yield Per Character [x]
    Update Yield Modulus [/]
    Update Yield Database [/]
    Claim Tokens [/]
    Interface Controller - Stattelite Station []
    Interface Controller - Character Leveler []
    Interface Controller - Equipment Upgrader []
    Interface Controller - Character Augmenter []
    Interface Controller - Spaceships []
    Interface Controller - Placeholder1 []
    Interface Controller - Placeholder2 []
    Interface Controller - Placeholder3 []
*/

// TODO: we need to implement modifier logic because we changed it to uint40 from uint256 to save gas!
contract MartianEssence is ERC20I {
    // // Access
    // Minified Ownable
    address public owner;
    constructor() ERC20I("Martian Essence", "MES") { owner = msg.sender; }
    modifier onlyOwner { require(msg.sender == owner, "You are not the owner!"); _; }
    function setNewOwner(address address_) external onlyOwner { owner = address_; }

    // // Times
    uint40 public yieldStartTime = 0;
    uint40 public yieldEndTime = 3408109200; // 2077-12-31_00-00-00
    // uint40 internal secondsInDay = 86400;

    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner {
        yieldEndTime = yieldEndTime_;
    }

    // Controller Logic
    mapping(address => bool) mesControllers;
    function setController(address address_, bool bool_) external onlyOwner {
        mesControllers[address_] = bool_; }
    modifier onlyControllers {
        require(mesControllers[msg.sender], "You are not a controller!");
        _; }

    // Mappings for Yield
    uint256 public globalModulus = (10 ** 14);

    struct Yield {
        uint40 yieldRate_;
        uint176 pendingRewards_;
        uint40 lastUpdatedTime_;
    }

    mapping(address => Yield) public addressToYieldInfo;

    // Events
    event Claim(address to_, uint256 amount_);

    // // Administration
    function setYieldRate(address address_, uint256 yieldRate_) external onlyControllers {
        uint40 _yieldRate = uint40(yieldRate_ / globalModulus);
        addressToYieldInfo[address_].yieldRate_ = _yieldRate;
    }
    function addYieldRate(address address_, uint256 yieldRateAdd_) external onlyControllers {
        uint40 _yieldRateAdd = uint40(yieldRateAdd_ / globalModulus);
        addressToYieldInfo[address_].yieldRate_ += _yieldRateAdd;
    }
    function subYieldRate(address address_, uint256 yieldRateSub_) external onlyControllers {
        uint40 _yieldRateSub = uint40(yieldRateSub_ / globalModulus);
        addressToYieldInfo[address_].yieldRate_ -= _yieldRateSub;
    }

    // // Credits System
    function deductCredits(address address_, uint256 amount_) external onlyControllers {
        uint40 _amount = uint40(amount_ / globalModulus);
        require(addressToYieldInfo[address_].pendingRewards_ >= _amount, "Not enough credits!");
        addressToYieldInfo[address_].pendingRewards_ -= _amount;
    }
    function addCredits(address address_, uint256 amount_) external onlyControllers {
        uint40 _amount = uint40(amount_ / globalModulus);
        addressToYieldInfo[address_].pendingRewards_ += _amount;
    }

    // // Internal Functions
    // View Functions
    function __getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }
    function __calculateYieldReward(address address_) internal view returns (uint40) {
        uint40 _totalYieldRate = addressToYieldInfo[address_].yieldRate_; if (_totalYieldRate == 0) { return 0; }
        uint40 _time = __getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
        uint40 _lastUpdate = addressToYieldInfo[address_].lastUpdatedTime_;

        if (_lastUpdate > yieldStartTime) {
            return _totalYieldRate * (_time - _lastUpdate) / 1 days;
        } else {
            return 0;
        }
    }

    // Write Functions
    function __updateYieldRateOnMint(address to_, uint256 modulus_) internal {
        uint40 _modulus = uint40(modulus_ / globalModulus);
        addressToYieldInfo[to_].yieldRate_ += _modulus;
    }
    function __updateYieldRateOnTransfer(address from_, address to_, uint256 modulus_) internal {
        uint40 _modulus = uint40(modulus_ / globalModulus);
        addressToYieldInfo[from_].yieldRate_ -= _modulus;
        addressToYieldInfo[to_].yieldRate_ += _modulus;
    }

    function __updateYieldReward(address address_) internal {
        uint40 _time = __getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
        uint40 _lastUpdate = addressToYieldInfo[address_].lastUpdatedTime_;

        if (_lastUpdate > 0) { addressToYieldInfo[address_].pendingRewards_ += __calculateYieldReward(address_); }
        if (_lastUpdate != yieldEndTime) { addressToYieldInfo[address_].lastUpdatedTime_ = _time; }
    }
    function __claimYieldReward(address address_) internal {
        uint176 _pendingRewards = addressToYieldInfo[address_].pendingRewards_;

        if (_pendingRewards > 0) { 
            addressToYieldInfo[address_].pendingRewards_ = 0;

            uint256 _expandedReward = uint256(_pendingRewards * globalModulus);

            _mint(address_, _expandedReward);
            emit Claim(address_, _expandedReward);
        } 
    }

    // // Public Functions
    // Update 
    function updateReward(address address_) public {
        // Note: anyone can call this!
        __updateYieldReward(address_); 
    }

    // Claim
    function claimTokens(address address_) public {
        // Note: anyone can call this!
        __updateYieldReward(address_);
        __claimYieldReward(address_);
    }
    function claimTokensWithoutUpdatingBalances(address address_) public {
        __claimYieldReward(address_); // experimental
    }

    // Multi Functions
    function multiUpdateReward(address[] memory addresses_) public {
        for (uint256 i = 0; i < addresses_.length; i++) {
            updateReward(addresses_[i]);
        }
    }
    function multiClaimTokens(address[] memory addresses_) public {
        for (uint256 i = 0; i < addresses_.length; i++) {
            claimTokens(addresses_[i]);
        }
    }
    function multiClaimTokensWithoutUpdatingBalances(address[] memory addresses_) public {
        for (uint256 i = 0; i < addresses_.length; i++) {
            claimTokensWithoutUpdatingBalances(addresses_[i]); // experimental
        }
    }

    // Burn
    function burn(address from_, uint256 amount_) public onlyControllers {
        _burn(from_, amount_);
    }

    function testMint(address to_, uint256 amount_) public {
        _mint(to_, amount_);
    }

    // // View Functions
    // Converted Values
    function getStorageClaimableTokens(address address_) public view returns (uint256) {
        return uint256(addressToYieldInfo[address_].pendingRewards_ * globalModulus);
    }
    function getPendingClaimableTokens(address address_) public view returns (uint256) {
        return uint256(__calculateYieldReward(address_) * globalModulus);
    }
    function getTotalClaimableTokens(address address_) public view returns (uint256) {
        return uint256((addressToYieldInfo[address_].pendingRewards_ + __calculateYieldReward(address_)) * globalModulus);
    }
    function getYieldRateOfAddress(address address_) public view returns (uint256) {
        return uint256(addressToYieldInfo[address_].yieldRate_ * globalModulus); 
    }

    // Raw Values
    function rawGetStorageClaimableTokens(address address_) public view returns (uint256) {
        return addressToYieldInfo[address_].pendingRewards_;
    }
    function rawGPendingClaimableTokens(address address_) public view returns (uint256) {
        return __calculateYieldReward(address_);
    }
    function rawGTotalClaimableTokens(address address_) public view returns (uint256) {
        return addressToYieldInfo[address_].pendingRewards_ + __calculateYieldReward(address_);
    }
}