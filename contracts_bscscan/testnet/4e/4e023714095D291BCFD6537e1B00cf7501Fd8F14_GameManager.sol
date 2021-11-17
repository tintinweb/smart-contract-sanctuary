// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Ownable.sol";

interface IDinoMarketplace {
   function getEggDetail(uint256 _eggId) external view returns(uint256 genes, address owner, uint256 createdAt, uint256 readyHatchAt, bool isAvailable);
   function disableEgg(uint256 _eggId) external;
}

interface IDinoLandNFT {
    function createDino(uint256 _genes, address _owner, uint128 _gender, uint128 _generation) external returns (uint256);
}


contract GameManager is Ownable{
    constructor (address _nftContractAddress, address _marketplaceContractAddress) {
        nftContractAddress = _nftContractAddress;
        marketplaceContractAddress = _marketplaceContractAddress;
    }
    
    address public nftContractAddress;
    address public marketplaceContractAddress;
    //Hatching rate by percent from 1-10,000 stand for 1% to 100%
    //Normal Egg
    uint32 normalEggR1Rate = 6670;
    uint32 normalEggR2Rate = 2405;
    uint32 normalEggR3Rate = 515;
    uint32 normalEggR4Rate = 305;
    uint32 normalEggR5Rate = 105;
    //Lottery Egg
    uint32 lotteryEggR1Rate = 5120;
    uint32 lotteryEggR2Rate = 3535;
    uint32 lotteryEggR3Rate = 875;
    uint32 lotteryEggR4Rate = 325;
    uint32 lotteryEggR5Rate = 145;
    
    uint8 public constant NORMAL = 11;
    uint8 public constant RARE = 12;
    uint8 public constant SUPER_RARE = 13;
    uint8 public constant LEGENDARY = 14;
    uint8 public constant MYSTIC = 15;
    
    uint8 public constant NOVIS_CLASS = 11;
    uint8 public constant AQUIS_CLASS = 12;
    uint8 public constant TERROT_CLASS = 13;
    
    event EggOpened(uint256 eggId, uint256 dinoId);
    
    function setNftContractAddress(address _newNftContractAddress) external onlyOwner {
        nftContractAddress = _newNftContractAddress;
    }
    
    function setMarkeplaceContractAddress(address _newMarketContractAddress) external onlyOwner {
        marketplaceContractAddress = _newMarketContractAddress;
    }
    
    function setNormalEggRate(uint32 _normalEggR1Rate, uint32 _normalEggR2Rate, uint32 _normalEggR3Rate, uint32 _normalEggR4Rate, uint32 _normalEggR5Rate) external onlyOwner {
        require(_normalEggR1Rate + _normalEggR2Rate + _normalEggR3Rate + _normalEggR4Rate + _normalEggR5Rate == 10000, "Total rate not equal to 10000");
        normalEggR1Rate = _normalEggR1Rate;
        normalEggR2Rate = _normalEggR2Rate;
        normalEggR3Rate = _normalEggR3Rate;
        normalEggR4Rate = _normalEggR4Rate;
        normalEggR5Rate = _normalEggR5Rate;
    }
    
    function setLotteryEggRate(uint32 _lotteryEggR1Rate, uint32 _lotteryEggR2Rate, uint32 _lotteryEggR3Rate, uint32 _lotteryEggR4Rate, uint32 _lotteryEggR5Rate) external onlyOwner {
        require(_lotteryEggR1Rate + _lotteryEggR2Rate + _lotteryEggR3Rate + _lotteryEggR4Rate + _lotteryEggR5Rate == 10000, "Total rate not equal to 10000");
        lotteryEggR1Rate = _lotteryEggR1Rate;
        lotteryEggR2Rate = _lotteryEggR2Rate;
        lotteryEggR3Rate = _lotteryEggR3Rate;
        lotteryEggR4Rate = _lotteryEggR4Rate;
        lotteryEggR5Rate = _lotteryEggR5Rate;
    }
    
    
    function isLotteryEgg(uint256 _eggGenes) internal pure returns (bool) {
        if(_eggGenes / 100 == 14) return true;
        return false;
    }
    
    function getDinoClassByEggGenes(uint256 _eggGenes) internal pure returns (uint256) {
        require(_eggGenes >= 1111, "Invalid egg");
        return _eggGenes/100;
    }
    
    function openEgg(uint256 _eggId) external {
        uint256 eggGenes;
        address eggOwner;
        uint256 eggCreatedAt;
        uint256 eggReadyHatchAt;
        bool eggIsAvailable;
        (eggGenes, eggOwner, eggCreatedAt, eggReadyHatchAt, eggIsAvailable) = IDinoMarketplace(marketplaceContractAddress).getEggDetail(_eggId);
        require(eggOwner == msg.sender, "You are not owner");
        require(block.timestamp > eggReadyHatchAt, "Egg not ready");
        require(eggIsAvailable == true, "Egg not available");
        
        
        uint256 rand = (uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp, msg.sender, "DinoLand"))) + block.timestamp) % 10000 + 1;
        uint256 dinoGenes;
        uint128 dinoGender = 1;
        if(isLotteryEgg(eggGenes)) {
            IDinoMarketplace(nftContractAddress).disableEgg(_eggId);
            //Random Dino Class
            uint8 dinoClass;
            if(rand < 333333) {
                dinoClass = NOVIS_CLASS;
            } else if(rand < 6666) {
                dinoClass = AQUIS_CLASS;
            } else {
                dinoClass = TERROT_CLASS;
            }
            //Random Dino Rarity
            uint8 dinoRarity;
            if(rand < lotteryEggR1Rate) {
                dinoRarity = NORMAL;
            } else if (rand < lotteryEggR1Rate + lotteryEggR2Rate) {
                dinoRarity = RARE;
            } else if (rand < lotteryEggR1Rate + lotteryEggR2Rate + lotteryEggR3Rate) {
                dinoRarity = SUPER_RARE;
            } else if (rand < lotteryEggR1Rate + lotteryEggR2Rate + lotteryEggR3Rate + lotteryEggR4Rate) {
                dinoRarity = LEGENDARY;
            } else {
                dinoRarity = MYSTIC;
            }
            //Random Gender
            if(rand < 5000) {
                dinoGender = 1;
            } else {
                dinoGender = 2;
            }
            //Generate genes
            dinoGenes = dinoClass*100 + dinoRarity;
        } else {
            IDinoMarketplace(nftContractAddress).disableEgg(_eggId);
            uint256 dinoClass = getDinoClassByEggGenes(eggGenes);
              //Random Dino Rarity
            uint8 dinoRarity;
            if(rand < normalEggR1Rate) {
                dinoRarity = NORMAL;
            } else if (rand < normalEggR1Rate + normalEggR2Rate) {
                dinoRarity = RARE;
            } else if (rand < normalEggR1Rate + normalEggR2Rate + normalEggR3Rate) {
                dinoRarity = SUPER_RARE;
            } else if (rand < normalEggR1Rate + normalEggR2Rate + normalEggR3Rate + normalEggR4Rate) {
                dinoRarity = LEGENDARY;
            } else {
                dinoRarity = MYSTIC;
            }
            //Random Gender
            if(rand < 5000) {
                dinoGender = 1;
            } else {
                dinoGender = 2;
            }
            //Generate genes
            dinoGenes = dinoClass*100 + dinoRarity;
        }
        uint256 dinoId = IDinoLandNFT(nftContractAddress).createDino(dinoGenes, msg.sender, dinoGender, 1);
        emit EggOpened(_eggId, dinoId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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