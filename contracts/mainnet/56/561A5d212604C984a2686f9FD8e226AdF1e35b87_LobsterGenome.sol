// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title LobsterBeachClub interface
*/
interface ILobsterBeachClub {
    function seedNumber() external view returns (uint256);
    function maxSupply() external view returns (uint256);
}

/**
* @title LobsterGenome contract
* @dev Handles lobster traits, assets and constructing gene sequences
*/
contract LobsterGenome is Ownable {
    // mapping of gene sequence to traits / rarities
    mapping(uint => uint16[]) public traits;
    // mapping of gene sequence to sum of all rarities
    mapping(uint => uint16) public sequenceToRarityTotals;
    // provenance record of images and metadata
    string public provenance;
    // list of gene sequences
    uint16[] sequences;
    // list of assets
    uint16[] assets;
    ILobsterBeachClub public lobsterBeachClub;

    constructor(address lbcAddress) {
        setLobsterBeachClub(lbcAddress);
    }

    function setLobsterBeachClub(address lbcAddress) public onlyOwner {
        lobsterBeachClub = ILobsterBeachClub(lbcAddress);
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    /**
    * @dev reset traits and rarities
    */
    function resetTraits() public onlyOwner {
        for(uint i; i < sequences.length; i++) {
            delete traits[i];
            delete sequenceToRarityTotals[i];
        }
        delete sequences;
    }

    /**
    * @dev set available traits and rarities at the same time
    * @dev example: [500, 500, 0, 100, 300, 600] sets two sequences separated by '0'
    *               [500, 500], [100, 300, 600] sequence 0 and 1, index is trait value is rarity
    */
    function setTraits(uint16[] memory rarities) public onlyOwner {
        require(rarities.length > 0, "Rarities is empty, Use resetTraits() instead");
        resetTraits();
        uint16 trait = 0;
        sequences.push(trait);
        for(uint i; i < rarities.length; i++) {
            uint16 rarity = rarities[i];
            if (rarity == 0) {
                trait++;
                sequences.push(trait);
            } else {
                traits[trait].push(rarity);
                sequenceToRarityTotals[trait] += rarity;
            }
        }
    }

    /**
    * @dev Returns the sequence for a given tokenId
    * @dev Deterministic based on tokenId and seedNumber from lobsterBeachClub
    * @dev One trait is selected and appended to sequence based on rarity
    * @dev Returns geneSequence of asset if tokenId is chosen for an asset
    */
    function getGeneSequence(uint256 tokenId) public view returns (uint256 _geneSequence) {
        uint256 assetOwned = getAssetOwned(tokenId);
        if (assetOwned != 0) {
            return assetOwned;
        }
        uint256 seedNumber = lobsterBeachClub.seedNumber();
        uint256 geneSequenceSeed = uint256(keccak256(abi.encode(seedNumber, tokenId)));
        uint256 geneSequence;
        for(uint i; i < sequences.length; i++) {
            uint16 sequence = sequences[i];
            uint16[] memory rarities = traits[sequence];
            uint256 sequenceRandomValue = uint256(keccak256(abi.encode(geneSequenceSeed, i)));
            uint256 sequenceRandomResult = (sequenceRandomValue % sequenceToRarityTotals[sequence]) + 1;
            uint16 rarityCount;
            uint resultingTrait;
            for(uint j; j < rarities.length; j++) {
                uint16 rarity = rarities[j];
                rarityCount += rarity;
                if (sequenceRandomResult <= rarityCount) {
                    resultingTrait = j;
                    break;
                }
            }
            geneSequence += 10**(3*sequence) * resultingTrait;
        }
        return geneSequence;
    }

    /**
    * @dev Set geneSequences of assets available
    * @dev Used as 1 of 1s or 1 of Ns (N being same geneSequence repeated N times)
    */
    function setAssets(uint16[] memory _assets) public onlyOwner {
        uint256 maxSupply = lobsterBeachClub.maxSupply();
        require(_assets.length <= maxSupply, "You cannot supply more assets than max supply");
        for (uint i; i < _assets.length; i++) {
            require(_assets[i] > 0 && _assets[i] < 1000, "Asset id must be between 1 and 999");
        }
        assets = _assets;
    }
    
    /**
    * @dev Deterministically decides which tokenIds of maxSupply from lobsterBeachClub will receive each asset
    * @dev Determination is based on seedNumber
    * @dev To prevent from tokenHolders knowing which section of tokenIds are more likely to receive an asset
    *      the direction which assets are chosen from 0 or maxSupply is also deterministic on the seedNumber
    */
    function getAssetOwned(uint256 tokenId) public view returns (uint16 assetId) {
        uint256 maxSupply = lobsterBeachClub.maxSupply();
        uint256 seedNumber = lobsterBeachClub.seedNumber();
        uint256 totalDistance = maxSupply;
        uint256 direction = seedNumber % 2;
        for (uint i; i < assets.length; i++) {
            uint256 difference = totalDistance / (assets.length - i);
            uint256 assetSeed = uint256(keccak256(abi.encode(seedNumber, i)));
            uint256 distance = (assetSeed % difference) + 1;
            totalDistance -= distance;
            if ((direction == 0 && totalDistance == tokenId) || (direction == 1 && (maxSupply - totalDistance - 1 == tokenId))) {
                return assets[i];
            }
        }
        return 0;
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

