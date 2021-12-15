// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MysteryBox is Ownable {

    struct MysteryBoxType {
        string name;
        uint256 priceNative;
        uint256 priceTVC;
        uint256 priceNativeDesc;
        uint256 priceTVCDesc;
        uint[] arrayFreqs;
        uint256 stock;
    }
    
    uint256 private mysteryBoxTypeCount;
    mapping (uint256 => MysteryBoxType) private mapMysteryBoxTypes;
    
    mapping (uint256 => uint256[]) private mapArraysFreqs;

    address private roleAdmin;

    modifier onlyAdminOrOwner(){
        require(msg.sender == roleAdmin || msg.sender == owner(), "You don't have permissions");
        _;
    }
    
    function changeAdmin(address _newAdmin) public onlyOwner {
        roleAdmin = _newAdmin;
    }


    function getMysteryBoxCount() external view onlyAdminOrOwner returns(uint256 count_) {
        return mysteryBoxTypeCount;
    }

    constructor() {
        mysteryBoxTypeCount = 1;
        
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(569), uint(769), uint(899), uint(968), uint(998), uint(1000), uint(0)];
        MysteryBoxType memory mysteryBoxType1 = MysteryBoxType(
            "Basic",
            2500 * 1e14,
            3000 * 1e14,
            2375 * 1e14,
            2850 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            2500
            );
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType1;
        
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(289), uint(639), uint(819), uint(949), uint(992), uint(1000), uint(0)];
        MysteryBoxType memory mysteryBoxType2 = MysteryBoxType(
            "Common",
            4000 * 1e14,
            5100 * 1e14,
            3800 * 1e14,
            4845 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            1500
            );
            
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType2;
        
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = [uint(0), uint(99), uint(469), uint(799), uint(949), uint(992), uint(1000)];
        MysteryBoxType memory mysteryBoxType3 = MysteryBoxType(
            "Premium",
            7500 * 1e14,
            8700 * 1e14,
            7125 * 1e14,
            8265 * 1e14,
            mapArraysFreqs[mysteryBoxTypeCount],
            500
            );
        
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType3;
        
    }
    
    function addNewMysteryBoxType(string memory _name, uint256 _priceNative, uint256 _priceTVC, uint256 _priceNativeDesc, uint256 _priceTVCDesc, uint256[] memory _arrayFreqs, uint256 _stock) public onlyOwner {
        mysteryBoxTypeCount++;
        mapArraysFreqs[mysteryBoxTypeCount] = _arrayFreqs;
        MysteryBoxType memory mysteryBoxType = MysteryBoxType(
            _name,
            _priceNative,
            _priceTVC,
            _priceNativeDesc,
            _priceTVCDesc,
            _arrayFreqs,
            _stock
            );
        
        mapMysteryBoxTypes[mysteryBoxTypeCount] = mysteryBoxType;
    }
    
    function modifyMysteryBoxType(uint256 _idMystery, string memory _name, uint256 _priceNative, uint256 _priceTVC, uint256 _priceNativeDesc, uint256 _priceTVCDesc, uint256[] memory _arrayFreqs, uint256 _stock) public onlyOwner {
        require(_idMystery <= mysteryBoxTypeCount, "Not exist mystery box.");
        mapArraysFreqs[_idMystery] = _arrayFreqs;
        MysteryBoxType memory mysteryBoxType = MysteryBoxType(
            _name,
            _priceNative,
            _priceTVC,
            _priceNativeDesc,
            _priceTVCDesc,
            _arrayFreqs,
            _stock
            );
        
        mapMysteryBoxTypes[_idMystery] = mysteryBoxType;
    }
    
    function mysteryBoxDetails(uint256 _mysteryBoxId) public view returns (MysteryBoxType memory mysteryBoxDetails_) { 
        require(_mysteryBoxId <= mysteryBoxTypeCount, "Nonexistent token");
        return mapMysteryBoxTypes[_mysteryBoxId];
    }

    function changeMysteryBoxStock(uint256 _numberMysteryBoxType, uint256 _amount) public onlyAdminOrOwner {
        uint256 value = mapMysteryBoxTypes[_numberMysteryBoxType].stock;
        require(value > 0, "Counter: decrement overflow");
        require(value >= _amount, "Not enough stock");
        unchecked {
            mapMysteryBoxTypes[_numberMysteryBoxType].stock -= _amount;
        }
        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}