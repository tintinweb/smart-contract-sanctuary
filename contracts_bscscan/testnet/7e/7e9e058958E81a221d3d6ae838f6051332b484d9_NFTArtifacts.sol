/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

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
interface INFTArtifacts {
    function rarityDecimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function addArtifact(uint256 artifactId, uint256 rarity) external;

    function getRandomArtifactId(uint256 randomNumber)
        external
        view
        returns (uint256);

    event AddArtifact(uint256 indexed artifactId, uint256 rarity);
}
interface INFTArtifactsMetadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function baseTokenURI() external view returns (string memory);
}
contract NFTArtifacts is
    Ownable,
    INFTArtifacts,
    INFTArtifactsMetadata
{
    string private _name;
    string private _symbol;
    string private _baseTokenURI;
    uint256 private immutable _rarityDecimals;

    uint256[] private _artifactIds;
    uint256 private _totalRarity;

    struct RarityInfo {
        uint256 zeroIndex;
        uint256 rarity;
    }

    mapping(uint256 => RarityInfo) public artifactIdToRarity;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        uint256 rarityDecimals_
    ) {
        require(
            rarityDecimals_ > uint256(0),
            "NFTArtifactsManager::constructor: rarityDecimals_ must be greater than 0!"
        );

        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI_;
        _rarityDecimals = rarityDecimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function rarityDecimals() public view returns (uint256) {
        return _rarityDecimals;
    }

    function totalSupply() public view returns (uint256) {
        return _artifactIds.length;
    }

    function addArtifact(uint256 artifactId_, uint256 rarity_)
        public
        onlyOwner
    {
        require(
            artifactId_ > uint256(0),
            "NFTArtifactsManager::addArtifact: artifactId_ must be greater than 0!"
        );
        require(
            rarity_ > uint256(0),
            "NFTArtifactsManager::addArtifact: rarity_ must be greater than 0!"
        );
        require(
            artifactIdToRarity[artifactId_].rarity == uint256(0),
            "NFTArtifactsManager::addArtifact: artifactId_ is already existed!"
        );
        require(
            _totalRarity + rarity_ <= type(uint256).max,
            "NFTArtifactsManager::addArtifact: _totalRarity overflow!"
        );

        _artifactIds.push(artifactId_);

        RarityInfo storage _rarityInfo = artifactIdToRarity[artifactId_];
        _rarityInfo.zeroIndex = _totalRarity;
        _rarityInfo.rarity = rarity_;

        _totalRarity += rarity_;

        emit AddArtifact(artifactId_, rarity_);
    }

    function getRandomArtifactId(uint256 randomNumber_)
        public
        view
        returns (uint256 _artifactId)
    {
        require(
            randomNumber_ > uint256(0),
            "NFTArtifactsManager::getRandomArtifactId: randomNumber_ must be greater than 0!"
        );
        require(
            _totalRarity > 0,
            "NFTArtifactsManager::getRandomArtifactId: add actifacts before using this function!"
        );

        uint256 _randomNumber = randomNumber_ % _totalRarity;

        for (uint256 i = 0; i < _artifactIds.length; i++) {
            RarityInfo storage _rarityInfo = artifactIdToRarity[
                _artifactIds[i]
            ];
            if (
                _rarityInfo.zeroIndex <= _randomNumber &&
                _randomNumber < _rarityInfo.zeroIndex + _rarityInfo.rarity
            ) {
                _artifactId = _artifactIds[i];
                break;
            }
        }
    }
}