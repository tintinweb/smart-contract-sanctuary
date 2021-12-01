//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface myIERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    // want to implement an ERC721 that can be used as skin only for the intended class ?
    // vvv expose those two functions vvv
    function isStrictOnSummonerClass() external returns (bool);
    function class(uint) external view returns (uint);
    function level(uint) external view returns (uint);
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

    address immutable token;
    address skins;
    uint256 public rogueReserve;
    uint256 public roguesTotalLevels;
    uint256 public tokenPerLevel;
    uint256 unaccountedRewards;
    mapping(uint256 => uint256) public roguesLevels;
    mapping(uint256 => uint256) public roguesValues;
    mapping(uint256 => uint256) public adventurersTime;

    uint256 ROGUE_PERCENT = 20; // Percent of tokens for rogues 
    uint256 TOKENS_PER_DAY = 10000e18; // Tokens claimable for adventurers per day

    constructor(address _rarity, address _token) {
        rarity = _rarity;
        exManager = new RaritySkinManager(_rarity);
		exManager.transferOwnership(msg.sender);
        token = _token;
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

        if (roguesLevels[tokenId] == 0 && adventurersTime[tokenId] == 0 && implementation == skins) { // check if skin first time take part in event
            if (myIERC721(implementation).class(tokenId) == 9) { // check if skin is Rogue
                roguesTotalLevels += myIERC721(rarity).level(summonerId);
                roguesValues[tokenId] = tokenPerLevel;
                roguesLevels[tokenId] = myIERC721(rarity).level(summonerId);
            } else {
                adventurersTime[tokenId] = block.timestamp;
            }
        }
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

    // Launch event functions

    function skinsImplementation(address _skins) external onlyOwner {
        skins = _skins;
    }

    function availableForClaim(uint256 tokenId) external view returns (uint amount) {
        if (myIERC721(skins).class(tokenId) == 9) {
            return roguesLevels[tokenId] * (tokenPerLevel - roguesValues[tokenId]);
        } else {
            return (TOKENS_PER_DAY * (block.timestamp - adventurersTime[tokenId]) / 86400 ) * (100 - ROGUE_PERCENT) / 100;
        }
    }

    function claim(uint256 tokenId) external {
        require(isApprovedOrOwner(skins, msg.sender, tokenId), "You must be owner or approved for this token");
        require(roguesLevels[tokenId] != 0 || adventurersTime[tokenId] != 0, "You must assign skin to summoner");

        if (myIERC721(skins).class(tokenId) == 9) {
            claimByRogue(tokenId);
        } else {
            claimByAdventurer(tokenId);
        }
    }    

    function claimByAdventurer(uint256 tokenId) private {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance > 0 && tokenBalance > rogueReserve, "No tokens left for claiming");

        uint256 earnedAmount = TOKENS_PER_DAY * (block.timestamp - adventurersTime[tokenId]) / 86400;
        adventurersTime[tokenId] = block.timestamp;
        uint256 rogueAmount = earnedAmount * ROGUE_PERCENT / 100;
        rogueReserve += rogueAmount;

        if (roguesTotalLevels == 0) {
            unaccountedRewards += rogueAmount;
        } else {
            tokenPerLevel += (rogueAmount + unaccountedRewards) / roguesTotalLevels;
            unaccountedRewards = 0;
        }
        IERC20(token).transfer(msg.sender, earnedAmount - rogueAmount);
    }

    function claimByRogue(uint256 tokenId) private {
        uint256 amount = roguesLevels[tokenId] * (tokenPerLevel - roguesValues[tokenId]);
        rogueReserve -= amount;
        roguesValues[tokenId] = tokenPerLevel;
        IERC20(token).transfer(msg.sender, amount);
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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