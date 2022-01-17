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

    uint8 public constant NORMAL = 11;
    uint8 public constant RARE = 12;
    uint8 public constant SUPER_RARE = 13;
    uint8 public constant LEGENDARY = 14;
    uint8 public constant MYSTIC = 15;
    uint8 public constant LOTTERY_EGG = 14;
    uint256[] public normalRates = [5000, 7500, 9000, 9700, 10000];
    uint256[] public lotteryRates = [3000, 6500, 8600, 9000, 10000];
    uint256[] public maxTraits = [3, 3, 2, 1, 1];
    
    
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
    
    function _getEggType(uint256 _eggGenes) internal pure returns (uint256) {
        require(_eggGenes >= 1111, "Invalid egg");
        return _eggGenes/100;
    }

    function setNormalEggRates(uint256[] memory _rates) external onlyOwner {
        require(_rates.length == 5, "Invalid rates length");
        normalRates = _rates;
    }

    function setLotteryEggRates(uint256[] memory _rates) external onlyOwner {
        require(_rates.length == 5, "Invalid rates length");
        lotteryRates = _rates;
    }
    
    
    function _calculateTraitIndex(uint256 _rarity, uint256 _rand) internal view returns(uint256 traitIndex) {
        uint256 maxTraitByRarity = maxTraits[_rarity - 1];
        traitIndex = _rand % maxTraitByRarity;
        for(uint256 i = 0; i < _rarity - 1; i ++) {
            traitIndex += maxTraits[i];
        }
    }

    function _calculateRarity(uint256 _rand, uint256 _eggType) internal view returns(uint256 rarity) {
        uint256 rand = uint256(_rand) % 10000;
        uint i = 0;
        if(_eggType == 14) {
            while(lotteryRates[i] < rand && i < lotteryRates.length) {
                i++;
            }
        } else {
            while (normalRates[i] < rand && i < normalRates.length) {
                i++;
            }
        }
        return i + 1;
    }

    /// @dev Slice _nbits bits from _offset of _n, also can use to get random number as well
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        return uint256((_n & mask) >> _offset);
    }
    /// @dev Slice and return 4 bits from _slot
    function _get4Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(4), _slot * 4));
    }

    /// @dev Decode dino genes to uint8 array, we have 21 group and 4 bit per group
    function decodeDino(uint256 _genes) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](21);
        uint256 i;
        for(i = 0; i < 21; i++) {
            traits[i] = _get4Bits(_genes, i);
        }
        return traits;
    }

    /// @dev Encode dino traits array to uint256 genes
    function encodeDino(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < 21; i++) {
            _genes = _genes << 4;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[20 - i];
        }
        return _genes;
    }

    /// @dev Random dino genes
    function _generateGenes(uint256 _rand, uint256 _eggType) public view returns (uint256 genes) {
        uint8[] memory traits = new uint8[](21);
        uint256 rand = uint256(_rand);
        uint256 randomIndex;
        for(uint256 i = 0; i < 21; i ++) {
            if(i % 3 == 0) {
                uint256 rarity = _calculateRarity(rand, _eggType);
                rand = rand + _sliceNumber(rand, 3, randomIndex) * 500;
                if(rarity <= 3) randomIndex += 3;
                randomIndex += 2;
                traits[i] = uint8(_calculateTraitIndex(rarity, rand));

                if(i == 0) {
                    /// @dev 3 first traits stand for class
                    if(_eggType <= 13) {
                        traits[i] = uint8(_eggType) - 11;
                    } else  {
                        traits[i] = traits[i] % 3;
                    }
                    traits[i + 1] = traits[i];
                    traits[i + 2] = traits[i];
                } else {
                    traits[i + 1] = traits[i];
                    traits[i + 2] = traits[i];
                    uint256 rand1 = _sliceNumber(rand, 2, randomIndex);
                    randomIndex += 2;
                    uint256 recessiveTrait1Rarity = rarity;
                    /// @dev 1/4 percent to have different recessive trait 1
                    if(rand1 == 0) {
                        recessiveTrait1Rarity = _calculateRarity(uint256(rand + block.number), _eggType);
                    }
                    traits[i + 1] = uint8(_calculateTraitIndex(recessiveTrait1Rarity, rand1));
                    randomIndex += 2;
                    uint256 rand2 = _sliceNumber(rand, 3, randomIndex);
                    uint256 recessiveTrait2Rarity = rarity;
                    /// @dev 1/8 percent to have different recessive trait 2
                    if(rand2 == 0) {
                        recessiveTrait2Rarity = _calculateRarity(uint256(rand + rand1), _eggType);
                    }
                    traits[i + 2] = uint8(_calculateTraitIndex(recessiveTrait2Rarity, rand2));
                }
                
            }
        }
        return encodeDino(traits);
    }

    /// @dev Open egg
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
        
        IDinoMarketplace(marketplaceContractAddress).disableEgg(_eggId);
        uint256 eggType = _getEggType(eggGenes);
        uint256 rand = (uint(keccak256(abi.encodePacked(blockhash(eggReadyAtBlock), _eggId))) + eggGenes);
        uint256 dinoGenes = _generateGenes(rand, eggType);
        uint256 dinoGender = uint256(keccak256(abi.encodePacked(rand, block.timestamp))) % 2 + 1;
        
        uint256 dinoId = IDinolandNFT(nftContractAddress).createDino(dinoGenes, eggOwner, uint128(dinoGender), 1);
        
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