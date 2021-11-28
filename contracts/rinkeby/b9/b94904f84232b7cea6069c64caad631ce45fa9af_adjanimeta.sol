/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

pragma solidity ^0.7.6;

//SPDX-License-Identifier: UNLICENSED;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
 
abstract contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
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
    function dataForMetaContract(uint256 tokenId) external view returns (bool exists, string memory image, string memory artist, uint256 licenseId, bool finalized, bool verified);
}

interface adjectiveAnimalDescContract {
    function getAdjective(uint256 tokenId) external view returns (string memory adjectiveId);
    function getAnimal(uint256 tokenId) external view returns (string memory animalId);
    function getColor(uint256 tokenId) external view returns (string memory colorId);
}

contract adjanimeta is Ownable {

    address public animalAdjectivesAddress;
    address public animalAdjectivesDescAddress;
    adjectiveAnimalContract adjectiveAnimal;
    adjectiveAnimalDescContract adjectiveAnimalDesc;
    
    string headerText = 'data:application/json;ascii,{"description": "We are the Adjective Animals - a community designed, social NFT project.","image":"ipfs://';
    string adjectiveText = '","attributes":[{"trait_type":"Adjective","value":"';
    string animalText = '"},{"trait_type":"Animal","value":"';
    string colorText = '"},{"trait_type":"Color","value":"';
    string artistNameText = '"},{"trait_type":"Artist Name","value":"';
    string licenseText = '"},{"trait_type":"License","value":"';
    string artFinalizedText = '"},{"trait_type":"Finalized","value":"';
    string artistVerifiedText = '"},{"trait_type":"Verified","value":"';
    string footerText = '"}]}';
    
    constructor() {
    animalAdjectivesAddress = 0x0aBc22fB3442Ebf748B3097b294b83F43793666D;
    animalAdjectivesDescAddress = 0xA544403a02ebfBF189473904B5C68d17eC655B7e;
    adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    adjectiveAnimalDesc = adjectiveAnimalDescContract(animalAdjectivesDescAddress);
    }
    
    function setA2Contract(address newAddress) public onlyOwner {
        animalAdjectivesAddress = newAddress;
        adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    }
    
    function setA2DescContract(address newAddress) public onlyOwner {
        animalAdjectivesDescAddress = newAddress;
        adjectiveAnimalDesc = adjectiveAnimalDescContract(animalAdjectivesDescAddress);
    }
    
    function getJSON(uint256 tokenID) public view returns (string memory JSON) {
        
        (bool exists, string memory image, string memory artistName, uint256 licenseId, bool finalized, bool verified) = adjectiveAnimal.dataForMetaContract(tokenID);
        
        require(exists, "ERC721Metadata: URI query for nonexistent token");
        
        string memory finalizedString;
        string memory verifiedString;
        
        if (finalized == true) {
            finalizedString = "True";
        }
        else {
            finalizedString = "False";
        }

        if (verified == true) {
            verifiedString = "True";
        }
        else {
            verifiedString = "False";
        }
        
        JSON = string(abi.encodePacked(headerText,image));
        JSON = string(abi.encodePacked(JSON,adjectiveText,adjectiveAnimalDesc.getAdjective(tokenID)));
        JSON = string(abi.encodePacked(JSON,animalText,adjectiveAnimalDesc.getAnimal(tokenID)));
        JSON = string(abi.encodePacked(JSON,colorText,adjectiveAnimalDesc.getColor(tokenID)));
        JSON = string(abi.encodePacked(JSON,artistNameText,artistName));
        JSON = string(abi.encodePacked(JSON,licenseText,licenseId));
        JSON = string(abi.encodePacked(JSON,artFinalizedText,finalizedString));
        JSON = string(abi.encodePacked(JSON,artistVerifiedText,verifiedString));
        JSON = string(abi.encodePacked(JSON,footerText));
        
    }


}