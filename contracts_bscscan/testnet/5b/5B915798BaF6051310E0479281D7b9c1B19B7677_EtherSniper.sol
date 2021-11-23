/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
/**
 * @title EtherSniper Game Contract
 * @dev Store & Retrieve EtherSniper Game data
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @dev `EtherSniper` token interface
 */
interface ETSInterface {
    function approve(
        address spender, 
        uint256 amount
    ) external returns (bool success);
    
    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
    
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external returns (bool);
}


/**
 * @dev Player Information Struct.
 * It will save player's Information detail.
 */

struct PlayerInfo {
    string playerName;
    uint256 playerLevel;
    uint256 playerExp;
    uint256[] playerWeapons;
}

/**
 * @dev Weapon Information struct.
 */

struct WeaponInfo {
    uint256 weaponPrice;
    bool    weaponUsable;
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner = msg.sender;
    }
    
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract EtherSniper is Ownable {
    using SafeMath for uint256;

    // BattleGround token address.
    address public tokenAddress = 0xF51eE462603E7E23FbC4264faaEB3d09c612e9d1;
    
     /**
     * @dev Game  wallet for the game rooms.
     * All earnings from game goes here
     */
    address public gameWallet = 0xF1CBd8CC86bCEcd2C5b900d8B20932eB0f4d15CA;
    address public tempGameWallet = 0xF1CBd8CC86bCEcd2C5b900d8B20932eB0f4d15CA;

    // Mapping of player point
    mapping(address => uint256) public userPoint;    
    
    // Mapping of Player Information
    mapping(address => PlayerInfo) public playerInfo;
    
    // Array of Weapon Price Information
    WeaponInfo[] weaponInfo;

    // Point buy rate
    uint256 public pointBuyRate = 1000; // 1:1

    // Point sell rate
    uint256 public pointSellRate = 1000; // 1:1
    
    ETSInterface public ETS = ETSInterface(tokenAddress);
    
    /**
     * @dev Initializes the contract information and setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
    }
    
    // Purchase point with ETS token
    function purchasePoint(uint256 _tokenAmount) public {
        require(ETS.transferFrom(msg.sender, address(this), _tokenAmount.mul(1e18)));
        
        userPoint[msg.sender] += _tokenAmount.mul(pointBuyRate).div(1000);
    }
    
    // Sell point for ETS Token
    function sellPoint(uint256 _amount) public {
        require(userPoint[msg.sender] >= _amount);
        
        uint256 tokenAmount = _amount.mul(1000).div(pointSellRate).mul(1e18);
        
        require(ETS.transfer(msg.sender, tokenAmount));
        
        userPoint[msg.sender].sub(_amount);
    }
    
    // Retrieve point
    function retrievePoint() public view returns(uint256){
        return userPoint[msg.sender];
    }

    // Retrieve Point Buy / Sell Rate
    function retrievePointRate() public view returns(uint256, uint256) {
        return (pointBuyRate, pointSellRate);        
    }
    
    // Retriev Weapon information
    function retrieveWeaponInfo() public view returns(WeaponInfo[] memory) {
        return weaponInfo;
    }
    
    // Purchase weapon with point
    function purchaseWeaponWithPoint(uint256 _weaponId) public {
        require(weaponInfo.length > _weaponId, "No such weapon");
        require(weaponInfo[_weaponId].weaponUsable, "Not usable weapon");
        
        uint256 price = weaponInfo[_weaponId].weaponPrice;
        require(userPoint[msg.sender] >= price, "No enough point");
        
        for(uint i = 0; i < playerInfo[msg.sender].playerWeapons.length; i++) {
            require(playerInfo[msg.sender].playerWeapons[i] != _weaponId, "Already Purchased");
        }
        
        userPoint[msg.sender] = userPoint[msg.sender].sub(price);
        playerInfo[msg.sender].playerWeapons.push(_weaponId);
    }
    
    // Purchase weapon with token
    function purchaseWeaponWithToken(uint256 _weaponId) public {
        require(weaponInfo.length > _weaponId, "No such weapon");
        require(weaponInfo[_weaponId].weaponUsable, "Not usable weapon");

        uint256 price = weaponInfo[_weaponId].weaponPrice;
        uint256 tokenAmount = price.mul(pointSellRate).div(1000);

        for(uint i = 0; i < playerInfo[msg.sender].playerWeapons.length; i++) {
            require(playerInfo[msg.sender].playerWeapons[i] != _weaponId, "Already Purchased");
        }
        
        require(ETS.transferFrom(msg.sender, address(this), tokenAmount.mul(1e18)));
        
        playerInfo[msg.sender].playerWeapons.push(_weaponId);
    }
    
    // Admin functions
    function updatePointBuyRate(uint256 _rate) public onlyOwner {
        pointBuyRate = _rate;
    }
    
    function updatePointSellRate(uint256 _rate) public onlyOwner {
        pointSellRate = _rate;
    }
    
    function addWeapon(uint256 price) public onlyOwner {
        WeaponInfo memory newWeapon;
        newWeapon.weaponPrice = price;
        newWeapon.weaponUsable = true;
        weaponInfo.push(newWeapon);
    }
    
    function updateWeaponPrice(uint256 weaponId, uint256 price) public onlyOwner {
        weaponInfo[weaponId].weaponPrice = price;
    }
    
    function updateWeaponUsable(uint256 weaponId, bool usable) public onlyOwner {
        weaponInfo[weaponId].weaponUsable = usable;
    }
}