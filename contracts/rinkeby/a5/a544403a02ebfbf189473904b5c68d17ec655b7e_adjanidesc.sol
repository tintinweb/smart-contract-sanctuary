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
    function getTokenSeed(uint256 tokenId) external view returns (uint256 seed);
}

contract adjanidesc is Ownable{

    address public animalAdjectivesAddress;
    adjectiveAnimalContract adjectiveAnimal;
    
    constructor() {
    animalAdjectivesAddress = 0x84649Ca135924966B254011ECFa0aA79a1C652cA;
    adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    }


    string[56] adjectiveCommon = ["Romantic","Rotund","Weak","Triangular","Thin","Terrific","Zealous","Jumbo","Poor","Curved","Fabulous","Narrow","Obese","Wide","Ancient","Happy","Messy","Pretty","Unique","Youthful","Big","Powerful","Nasty","Slim","Square","Broad","Circular","Based","Colorful","Strong","Expensive","Vulgar","Large","Abundant","Elegant","Filthy","Impossible","Skinny","Little","Long","Elderly","Pixelated","Heavy","Majestic","Dirty","Hungry","Old","Massive","Tall","Distorted","Quixotic","Immense","Attractive","Delicate","Blobby","Thick"];
    string[25] adjectiveRare = ["Globular","Cubic","Glorious","Miniature","Cheap","Giant","Glamorous","Gigantic","Angry","Handsome","Basic","Huge","Fat","Flat","Juvenile","Tiny","Ugly","Modern","Puny","Defective","X-Large","Beautiful","Small","Clean","Vast"];
    string[12] adjectiveEpic = ["Knockoff","Short","Scrawny","Accurate","Rare","Royal","Mammoth","Imaginary","Sharp","Shiny","Crooked","X-Small"];
    string[38] animalCommon = ["Iguana","Duck","Walrus","Alligator","Turkey","Bear","Camel","Narwhal","Eagle","Skunk","Gerbil","Jaguar","Octopus","Dog","Gorilla","Leopard","Koala","Owl","Pig","Cheetah","Swan","Fox","Peacock","Tiger","Kangaroo","Raccoon","Wolf","Mouse","Giraffe","Rhino","Moose","Bat","Whale","Bull","Lion","Quail","Hedgehog","Elephant"];
    string[18] animalRare = ["Anteater","Squirrel","Urchin","Yak","Cow","Goat","Snake","Sheep","Dolphin","Flamingo","Jellyfish","Fish","Deer","Cat","Penguin","Horse","Parrot","Turtle"];
    string[9] animalEpic = ["Ostrich","Shark","Zebra","Hippo","Chicken","Rabbit","Monkey","Vulture","Xeme"];
    string[2] colorCommon = ["black","white"];
    string[4] colorRare = ["cyan","teal","purple","pink"];
    string[6] colorEpic = ["brown","orange","yellow","green","blue","red"];

    
    function getAdjective(uint256 tokenId) public view returns (string memory adjectiveId) {
        uint256 randNumber = getSeed(tokenId)%1000;
        
        if (randNumber < 500) {
            adjectiveId = adjectiveCommon[getSeed(tokenId)%56];
        }
        else if (randNumber < 850) {
            adjectiveId = adjectiveRare[getSeed(tokenId)%25];
        }
        else {
            adjectiveId = adjectiveEpic[getSeed(tokenId)%12];
        }
        
    }
    
    function getAnimal(uint256 tokenId) public view returns (string memory animalId) {
        uint256 randNumber = getSeed(tokenId)%1000;
        
        if (randNumber < 500) {
            animalId = animalCommon[getSeed(tokenId)%38];
        }
        else if (randNumber < 850) {
            animalId = animalRare[getSeed(tokenId)%18];
        }
        else {
            animalId = animalEpic[getSeed(tokenId)%9];
        }

    }
    
    function getColor(uint256 tokenId) public view returns (string memory colorId) {
        uint256 randNumber = getSeed(tokenId)%1000;
        
        if (randNumber < 500) {
            colorId = colorCommon[getSeed(tokenId)%6];
        }
        else if (randNumber < 850) {
            colorId = colorRare[getSeed(tokenId)%4];
        }
        else {
            colorId = colorEpic[getSeed(tokenId)%2];
        }
        
    }
    
    function getSeed(uint256 tokenId) public view returns (uint256 seed) {
        seed = adjectiveAnimal.getTokenSeed(tokenId);
    }
    
    function setA2Contract(address newAddress) public onlyOwner {
        animalAdjectivesAddress = newAddress;
        adjectiveAnimal = adjectiveAnimalContract(animalAdjectivesAddress);
    }

}