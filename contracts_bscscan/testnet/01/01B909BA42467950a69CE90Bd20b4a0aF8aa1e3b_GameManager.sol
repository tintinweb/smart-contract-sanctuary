// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../core/interface/IDinolandNFT.sol";
import "../core/interface/IDinoMarketplace.sol";

contract GameManager is Ownable, ReentrancyGuard, Pausable {
     
    /*** CONSTRUCTOR ***/

    constructor (address _nftContractAddress, address _marketplaceContractAddress) {
        require(_nftContractAddress != address(0), "NFT contract address cannot be 0");
        require(_marketplaceContractAddress != address(0), "Marketplace contract address cannot be 0");
        nftContractAddress = _nftContractAddress;
        marketplaceContractAddress = _marketplaceContractAddress;
        whitelistedAdmins[msg.sender] = true;
    }

    /*** EVENTS ***/
    
    event EggOpened(uint256 eggId, uint256 dinoId);


    /*** STORAGES ***/

    mapping(address => bool) public whitelistedAdmins;
    address public nftContractAddress;
    address public marketplaceContractAddress;
    //Hatching rate by percent from 1-10,000 stand for 1% to 100%
    //Normal Egg
    uint32 private normalEggR1Rate = 6670;
    uint32 private normalEggR2Rate = 2405;
    uint32 private normalEggR3Rate = 515;
    uint32 private normalEggR4Rate = 305;
    uint32 private normalEggR5Rate = 105;
    //Lottery Egg
    uint32 private lotteryEggR1Rate = 5120;
    uint32 private lotteryEggR2Rate = 3535;
    uint32 private lotteryEggR3Rate = 875;
    uint32 private lotteryEggR4Rate = 325;
    uint32 private lotteryEggR5Rate = 145;
    
    uint8 public constant NORMAL = 11;
    uint8 public constant RARE = 12;
    uint8 public constant SUPER_RARE = 13;
    uint8 public constant LEGENDARY = 14;
    uint8 public constant MYSTIC = 15;
    uint8 public constant LOTTERY_EGG = 14;
    
    /*** MODIFIERS ***/

    modifier onlyAdmin() {
        require(whitelistedAdmins[msg.sender] == true, "Permission denied");
        _;
    }
    
    modifier noContract(address _addr){
      uint32 size;
      assembly {
        size := extcodesize(_addr)
      }
      require (size == 0);
      require(msg.sender == tx.origin);
      _;
    }
    
    /*** METHODS ***/
    function pause() external onlyOwner {
        _pause();
    } 

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function setWhitelistedAdmin(address _whitelistedAdminAddress, bool _isAdmin) external onlyOwner {
        require(_whitelistedAdminAddress != address(0), "Whitelisted admin address cannot be 0");
        whitelistedAdmins[_whitelistedAdminAddress] = _isAdmin;
    }
    
    function setNftContractAddress(address _newNftContractAddress) external onlyOwner {
        require(_newNftContractAddress != address(0), "NFT contract address cannot be 0");
        nftContractAddress = _newNftContractAddress;
    }
    
    function setMarkeplaceContractAddress(address _newMarketContractAddress) external onlyOwner {
        require(_newMarketContractAddress != address(0), "Marketplace contract address cannot be 0");
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
    
    function getDinoClassByEggGenes(uint256 _eggGenes) internal pure returns (uint256) {
        require(_eggGenes >= 1111, "Invalid egg");
        return _eggGenes/100;
    }

    function getNormalEggRates() external view returns (uint32[5] memory _rates) {
        _rates[0] = normalEggR1Rate;
        _rates[1] = normalEggR2Rate;
        _rates[2] = normalEggR3Rate;
        _rates[3] = normalEggR4Rate;
        _rates[4] = normalEggR5Rate;
    }

    function getLotteryEggRates() external view returns (uint32[5] memory _rates) {
        _rates[0] = lotteryEggR1Rate;
        _rates[1] = lotteryEggR2Rate;
        _rates[2] = lotteryEggR3Rate;
        _rates[3] = lotteryEggR4Rate;
        _rates[4] = lotteryEggR5Rate;
    }
    
    
    function openEgg(uint256 _eggId) external noContract(msg.sender) nonReentrant whenNotPaused {
        uint256 eggGenes;
        address eggOwner;
        uint256 eggCreatedAt;
        uint256 eggReadyHatchAt;
        bool eggIsAvailable;
        uint256 eggReadyAtBlock;
        (eggGenes, eggOwner, eggCreatedAt, eggReadyHatchAt, eggReadyAtBlock, eggIsAvailable) = IDinoMarketplace(marketplaceContractAddress).getEggDetail(_eggId);
        require(block.timestamp > eggReadyHatchAt, "Egg not ready");
        require(eggIsAvailable == true, "Egg not available");
        require(msg.sender == eggOwner, "Egg not owned by you");
        
        
        uint256 rand = (uint(keccak256(abi.encodePacked(blockhash(eggReadyAtBlock), _eggId))) + eggGenes) % 10000 + 1;
        uint256 classRand = uint(keccak256(abi.encodePacked(rand, block.coinbase))) % 10000 + 1;
        uint256 genderRand = uint(keccak256(abi.encodePacked(rand, block.timestamp))) % 10000 + 1;
        
        uint256 dinoGenes = 1111;
        uint128 dinoGender = 1;
        IDinoMarketplace(marketplaceContractAddress).disableEgg(_eggId);
        if(eggGenes / 100 == LOTTERY_EGG) {
            // Random Dino Class
            uint256 dinoClass = 11;
            if(classRand < 3333) {
                dinoClass = 11;
            } else if(classRand < 6666) {
                dinoClass = 12;
            } else {
                dinoClass = 13;
            }
            uint256 dinoRarity = 11;
            //Random Dino Rarity
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
            if(genderRand < 5000) {
                dinoGender = 1;
            } else {
                dinoGender = 2;
            }
            //Generate genes
            dinoGenes = dinoClass*100 + dinoRarity;
        } else {
            uint256 dinoClass = getDinoClassByEggGenes(eggGenes);
              //Random Dino Rarity
            uint8 dinoRarity = 11;
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
            if(genderRand < 5000) {
                dinoGender = 1;
            } else {
                dinoGender = 2;
            }
            //Generate genes
            dinoGenes = dinoClass*100 + dinoRarity;
        }
        uint256 dinoId = IDinolandNFT(nftContractAddress).createDino(dinoGenes, eggOwner, dinoGender, 1);
        emit EggOpened(_eggId, dinoId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDinolandNFT{
    function createDino(uint256 _dinoGenes, address _ownerAddress, uint128 _gender, uint128 _generation) external returns(uint256);
    function getDinosByOwner(address _owner) external returns(uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDinoMarketplace {
    function createEgg(
        uint256 _eggGenes,
        uint256 _readyHatchAt,
        address _owner
    ) external returns (uint256);

    function getEggDetail(uint256 _eggId)
        external
        view
        returns (
            uint256 genes,
            address owner,
            uint256 createdAt,
            uint256 readyHatchAt,
            uint256 readyAtBlock,
            bool isAvailable
        );

    function disableEgg(uint256 _eggId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

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