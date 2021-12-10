/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/*
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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: node_modules\@openzeppelin\contracts\ownership\Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () public {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface adjectiveAnimalContract {
    function getTokenSeed(uint256 tokenId) external view returns (uint256 seed);
}


contract Chainface2Chars is Ownable {

    address public animalAdjectivesAddress;
    adjectiveAnimalContract adjectiveAnimal;
    
    constructor() public {
    animalAdjectivesAddress = 0x84649Ca135924966B254011ECFa0aA79a1C652cA;
    adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    }


    string[16] public leftFaceArray = ["ᖳ","ᕦ","ᛩ","〈","﹝","⦇","𐐋","【","〘","〚","┊","⦃","[","(","ლ","⧼"];
    string[17] public leftEyeArray = ["Ͼ","ϕ","𐌈","⠄","⊛","⊡","⊙","⦿","⨕","◬","◈","ᗒ"," ͡°","˘","◠","★","⩹"];
    string[20] public mouthArray = ["۷","ܫ","໒","𐑒","ᨎ","ᨏ","⚇","⩊","◡","⌒","⌓","‿","𐠑","︷","⋏","▾","∪","∩","⥿","_"];
    string[17] public rightEyeArray = ["Ͽ","ϕ","𐌈","⠄","⊛","⊡","⊙","⦿","⨕","◬","◈","ᗕ"," ͡°","˘","◠","★","⩺"];
    string[16] public rightFaceArray = ["ᖰ","ᕤ","ᚹ","〉","﹞","⦈","𐐙","】","〙","〛","┊","⦄","]",")","ლ","⧽"];
    
    function setA2Contract(address newAddress) public onlyOwner {
        animalAdjectivesAddress = newAddress;
        adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    }

}