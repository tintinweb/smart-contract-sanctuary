//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    // want to implement an ERC721 that can be used as skin only for the intended class ?
    // vvv expose those two functions vvv
    function isStrictOnSummonerClass() external returns (bool);
    function class(uint) external returns (uint);
}

// gift to the community : open standard to use any ERC721 as summoner skin !
contract RaritySkinManager is Ownable {

    address immutable rarity;
    
    mapping(uint256 => Skin) public skinOf;
    mapping(bytes32 => uint256) public summonerOf;
    mapping(address => bool) private trustedImplementations;
    
    event SumonnerSkinAssigned (Skin skin, uint256 summoner);
    
    struct Skin {
        address implementation;
        uint256 tokenId;
    }

    constructor(address _rarity) {
        rarity = _rarity;
    }    
    
    modifier classChecked(address implementation, uint tokenId, uint summonerId) {
        try myIERC721(implementation).isStrictOnSummonerClass() returns(bool isStrict) {
            if(isStrict){
                require(myIERC721(rarity).class(summonerId) == myIERC721(implementation).class(tokenId), "Summoner and skin must be of the same class");
            }

            _;
        } catch Panic(uint) {
            _;
        }
    }
    
    function assignSkinToSummoner(address implementation, uint tokenId, uint summonerId) external 
    classChecked(implementation, tokenId, summonerId) {
        require(isApprovedOrOwner(implementation, msg.sender, tokenId), "You must be owner or approved for this token");
        require(isApprovedOrOwner(rarity, msg.sender, summonerId), "You must be owner or approved for this summoner");
        
        _assignSkinToSummoner(implementation, tokenId, summonerId);
    }

    // you can request the owner of this contract to add your NFT contract to the trusted list if you implement ownership checks on summoner and token
    function trustedAssignSkinToSummoner(uint tokenId, uint summonerId) external
    classChecked(msg.sender, tokenId, summonerId) {
        require(trustedImplementations[msg.sender], "Only trusted ERC721 implementations can access this way of assignation");
        
        _assignSkinToSummoner(msg.sender, tokenId, summonerId);
    }
    
    function _assignSkinToSummoner(address implementation, uint tokenId, uint summonerId) private {
        // reinitialize previous assignation
        skinOf[summonerOf[skinKey(Skin(implementation, tokenId))]] = Skin(address(0),0);
        
        summonerOf[skinKey(Skin(implementation, tokenId))] = summonerId;
        skinOf[summonerId] = Skin(implementation, tokenId);
        
        emit SumonnerSkinAssigned(Skin(implementation, tokenId), summonerId);
    }
    
    function skinKey(Skin memory skin) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(skin.implementation, skin.tokenId));
    }
    
    function trustImplementation(address _impAddress) external onlyOwner {
        trustedImplementations[_impAddress] = true;
    }
    
    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
    }
}

// IMPORTANT BUG FIX : use this contract for calls and assignations instead of the original contract.
// Skins assigned using the original contract are still here.
// this contract fixes a bug is rarity skin manager which makes the assignation of
// a NFT not implementing the isStrictOnSummonerClass() method revert.
// It is essentially a wrapper of the original contract, no modification is needed on the
// way to interact with it, besides using his address instead of the original one.
contract RaritySkinManagerFix is Ownable {
    
    address immutable rarity;

    // original contract
    RaritySkinManager public exManager;

    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(uint256 => RaritySkinManager.Skin) private _skinOf;
    mapping(bytes32 => uint256) private _summonerOf;
    mapping(address => bool) private trustedImplementations;

    event SumonnerSkinAssigned (RaritySkinManager.Skin skin, uint256 summoner);

    bool constant public isStrictOnSummonerClass = true; // make a function with this

    constructor(address _rarity) {
        rarity = _rarity;
        exManager = new RaritySkinManager(_rarity);
		exManager.transferOwnership(msg.sender);
    }
    
    modifier classChecked(address implementation, uint tokenId, uint summonerId) {
        try myIERC721(implementation).isStrictOnSummonerClass() returns(bool isStrict) {
            if(isStrict){
                require(myIERC721(rarity).class(summonerId) == myIERC721(implementation).class(tokenId), "Summoner and skin must be of the same class");
            }

            _;
        } catch Error(string memory){
            _;
        } catch Panic(uint) {
            _;
        } catch (bytes memory) {
            _;
        }
    }

    function skinOf(uint256 summonerId) public view returns(RaritySkinManager.Skin memory){
        (address skinImplemFromExManager, uint skinIdFromExManager) = exManager.skinOf(summonerId);
        RaritySkinManager.Skin memory skin = _skinOf[summonerId];

        if (skin.implementation == deadAddress){
            return RaritySkinManager.Skin(address(0),0);
        }
        else if (skin.implementation == address(0)){
            return RaritySkinManager.Skin(skinImplemFromExManager, skinIdFromExManager);
        } else {
            return _skinOf[summonerId];
        }
    }

    function summonerOf(bytes32 _skinKey) public view returns(uint256 summonerId){
        if (_summonerOf[_skinKey] == 0){
            return exManager.summonerOf(_skinKey);
        } else {
            return _summonerOf[_skinKey];
        }
    }

    // you can request the owner of this contract to add your NFT contract to the trusted list if you implement ownership checks on summoner and token
    function trustedAssignSkinToSummoner(uint tokenId, uint summonerId) external
    classChecked(msg.sender, tokenId, summonerId) {
        require(trustedImplementations[msg.sender], "Only trusted ERC721 implementations can access this way of assignation");
        
        _assignSkinToSummoner(msg.sender, tokenId, summonerId);
    }
    
    function assignSkinToSummoner(address implementation, uint tokenId, uint summonerId) external 
    classChecked(implementation, tokenId, summonerId) {
        require(isApprovedOrOwner(implementation, msg.sender, tokenId), "You must be owner or approved for this token");
        require(isApprovedOrOwner(rarity, msg.sender, summonerId), "You must be owner or approved for this summoner");
        
        _assignSkinToSummoner(implementation, tokenId, summonerId);
    }

    function _assignSkinToSummoner(address implementation, uint tokenId, uint summonerId) private {
        // reinitialize previous assignation
        _skinOf[_summonerOf[exManager.skinKey(RaritySkinManager.Skin(implementation, tokenId))]] = RaritySkinManager.Skin(deadAddress,0);
        
        _summonerOf[exManager.skinKey(RaritySkinManager.Skin(implementation, tokenId))] = summonerId;
        _skinOf[summonerId] = RaritySkinManager.Skin(implementation, tokenId);
        
        emit SumonnerSkinAssigned(RaritySkinManager.Skin(implementation, tokenId), summonerId);
    }

    function skinKey(RaritySkinManager.Skin memory skin) public view returns(bytes32) {
        return exManager.skinKey(skin);
    }

    function trustImplementation(address _impAddress) external onlyOwner {
        trustedImplementations[_impAddress] = true;
    }

    function isApprovedOrOwner(address nftAddress, address spender, uint256 tokenId) private view returns (bool) {
        myIERC721 implementation = myIERC721(nftAddress);
        address owner = implementation.ownerOf(tokenId);
        return (spender == owner || implementation.getApproved(tokenId) == spender || implementation.isApprovedForAll(owner, spender));
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