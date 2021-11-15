//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//Shiba data structure
struct DogsMetaData {
    uint8 ethnicity;
    uint8 profession;
    uint8 head; //2 
    uint8 mouse; 
    uint8 eyes; 
    uint8 body; 
    uint8 collar; 
    uint8 tail; 
    uint8 ear; 
    uint8 cap; 
    uint8 clothing; 
    uint8 ornaments; //11 gen
    uint64 attack;
    uint64 defense;
    uint64 speed;
    uint32 father;
    uint32 mother;
    uint64 birth;
}

//Growth attributes
struct GrowthValue { uint8 attack; uint8 defense; uint8 speed; }

//Monitor lock
struct MonitorInfos {
    uint64 lefttime;
    bytes24 message;
}

//Fertility allocation
struct SireAttrConfig {
    uint8 ethnicity_option;
    //Occupational gene range
    uint8 profession_option;
    //Head gene range
    uint8 head_option;
    //Mouth gene range
    uint8 mouse_option;
    //Eye gene range
    uint8 eyes_option;
    //Body gene range
    uint8 body_option;
    //Collar gene range
    uint8 collar_option;
    //Tail gene range
    uint8 tail_option;
    //Clothing gene range
    uint8 clothing_option;
    //Ear gene range
    uint8 ear_option;
    //Hat gene range
    uint8 cap_option;
    //Accessories gene range
    uint8 ornaments_option;
}

interface IGameFiShibaSire {
    function sire( DogsMetaData memory _father, DogsMetaData memory _mother ) external returns (DogsMetaData memory);
    function sireFee(uint time) external view returns (uint256);
    function growingInfos() external view  returns(GrowthValue[] memory);
    function knighthood(uint tokenId) external view returns(uint);
    function identity() external view returns (uint[] memory);
    function genRarity(uint gen) external view returns(bool);
}

interface IGameFiShibaMonitor{
    function isMonitoring(uint256 tokenId) external view returns (bool) ;
    function monitorInfos(uint256 tokenId) external view returns (MonitorInfos memory);
}

interface IGameFiShiba is IERC721,IERC721Receiver,IERC721Enumerable,IGameFiShibaMonitor{
    function mint(address to, DogsMetaData memory meta) external returns (uint256 _tokenId);
    function sire(uint father,uint mother) external returns(uint _tokenId);
    function metaData(uint tokenId) external view returns (DogsMetaData memory);
    function exists(uint tokenId) external view returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

library GameFiShibaLib {
    function _randomSpeed(uint nonce) internal view returns (uint256) { return uint256( keccak256( abi.encodePacked( nonce, msg.sender, block.difficulty, block.timestamp, block.coinbase ) ) ); }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GameFiShibaCommon.sol";
import "./GameFiShibaLib.sol";


////////////////////////////////////////////////////////////////////////
////      ________                         ___________ __           ////
////     /  _____/ _____     _____    ____ \_   _____/|__|          ////    
////    /   \  ___ \__  \   /     \ _/ __ \ |    __)  |  |          ////
////    \    \_\  \ / __ \_|  Y Y  \\  ___/ |     \   |  |          ////
////     \______  /(____  /|__|_|  / \___  >\___  /   |__|          ////
////            \/      \/       \/      \/     \/                  ////
////           _________ __      __ ___                             ////
////          /   _____/|  |__  |__|\_ |__  _____                   ////
////          \_____  \ |  |  \ |  | | __ \ \__  \                  ////
////          /        \|   Y  \|  | | \_\ \ / __ \_                ////
////         /_______  /|___|  /|__| |___  /(____  /                ////
////                 \/      \/          \/      \/                 ////
////                                                gamefishiba.io  ////   
////////////////////////////////////////////////////////////////////////

/// @title GameFi Shiba
/// @author GameFi Shiba team

contract GameFiShibaMarket is ReentrancyGuard,Ownable{
    using SafeMath for uint;

   /**
     * Event emitted when a trade is executed.
     */
    event Trade(bytes32 indexed hash, address indexed maker, address taker, uint makerWei, uint[] makerIds, uint takerWei, uint[] takerIds);

    /**
     * Event emitted when a trade offer is cancelled.
     */
    event OfferCancelled(bytes32 hash);

    /**
     * Event emitted when the public sale begins.
     */
    event SaleBegins();

    struct Offer {
        address maker;
        address taker;
        uint256 makerWei;
        uint256[] makerIds;
        uint256 takerWei;
        uint256[] takerIds;
        uint256 expiry;
        uint256 salt;
    }

    bool public marketPaused;
    
    bool public salesPaused;

    IGameFiShiba immutable public _gamefishiba;

    IERC20 immutable public WETH ;
    
    address immutable public  _receptor;

    mapping (bytes32 => bool) public cancelledOffers;

    uint public marketFee = 30;
    //Accumulated fee
    uint public totalTradeFee;
    //Accumulated sales
    uint public totalSales;
    //Gene pool
    mapping(uint=>mapping(uint=>DogsMetaData)) mintPool;
    //Gene pool size
    mapping(uint=>uint) mintPoolSize;
    //selling price
    uint[] private  _grantSalesPrices;

    uint nonce;

    //Empty meta data
    bytes32 private _emptyMetaData ;
    //Event of sales status change
    event MintStateChange(address,bool);
    //Event of market transaction status change
    event MarketStateChange(address,bool);
    
    modifier whenMintEable(){
        require(!salesPaused,'mint close');
        _;
    }

    modifier whenNotPaused(){
        require(!marketPaused,'market paused');
        _;
    }

    //0xc778417E063141139Fce010982780140Aa0cD5Ab
    constructor(address cryptoshiba_,address weth_,address mintpool_){
        _gamefishiba = IGameFiShiba(cryptoshiba_);
        WETH = IERC20(weth_);  
        _receptor = mintpool_;
        _emptyMetaData = keccak256(abi.encode(DogsMetaData(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)));
        salesPaused = true;
    }

    function hashOffer(Offer memory offer) private pure returns (bytes32){
        return keccak256(abi.encode(
                    offer.maker,
                    offer.taker,
                    offer.makerWei,
                    keccak256(abi.encodePacked(offer.makerIds)),
                    offer.takerWei,
                    keccak256(abi.encodePacked(offer.takerIds)),
                    offer.expiry,
                    offer.salt
                ));
    }

    function hashToSign(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt) public pure returns (bytes32) {
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        return hashOffer(offer);
    }

    function hashToVerify(Offer memory offer) private pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashOffer(offer)));
    }

    function verify(address signer, bytes32 hash, bytes memory signature) internal pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        return signer == ecrecover(hash, v, r, s);
    }

    function tradeValid(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt, bytes memory signature) view public returns (bool) {
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        // Check for cancellation
        bytes32 hash = hashOffer(offer);
        require(cancelledOffers[hash] == false, "Trade offer was cancelled.");
        // Verify signature
        bytes32 verifyHash = hashToVerify(offer);
        require(verify(offer.maker, verifyHash, signature), "Signature not valid.");
        // Check for expiry
        require(block.timestamp < offer.expiry, "Trade offer expired.");
        // Only one side should ever have to pay, not both
        require(makerWei == 0 || takerWei == 0, "Only one side of trade must pay.");
        // At least one side should offer tokens
        require(makerIds.length > 0 || takerIds.length > 0, "One side must offer tokens.");
        // Make sure the maker has funded the trade
        require(WETH.balanceOf(offer.maker) >= offer.makerWei, "Maker does not have sufficient balance.");
        // Ensure the maker owns the maker tokens
        for (uint i = 0; i < offer.makerIds.length; i++) {
            require(_gamefishiba.ownerOf(offer.makerIds[i]) == offer.maker, "At least one maker token doesn't belong to maker.");
            require(!_gamefishiba.isMonitoring(offer.makerIds[i]),"At least one maker token doesn't free");
        }
        // If the taker can be anybody, then there can be no taker tokens
        if (offer.taker == address(0)) {
            // If taker not specified, then can't specify IDs
            require(offer.takerIds.length == 0, "If trade is offered to anybody, cannot specify tokens from taker.");
        } else {
            // Ensure the taker owns the taker tokens
            for (uint i = 0; i < offer.takerIds.length; i++) {
                require(_gamefishiba.ownerOf(offer.takerIds[i]) == offer.taker, "At least one taker token doesn't belong to taker.");
                require(!_gamefishiba.isMonitoring(offer.takerIds[i]),"At least one maker token doesn't free");
            }
        }
        return true;
    }

    function cancelOffer(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt) external {
        require(maker == msg.sender, "Only the maker can cancel this offer.");
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);
        bytes32 hash = hashOffer(offer);
        cancelledOffers[hash] = true;
        emit OfferCancelled(hash);
    }

    function gratuity(address from ,address to,uint amount) internal {
        if(amount == 0){
            return;
        }
        uint fee = amount.mul(marketFee).div(1000);
        WETH.transferFrom(from, to , amount.sub(fee));
        if(fee > 0){
            totalTradeFee = totalTradeFee.add(fee);
            WETH.transferFrom(from, _receptor , fee);
        }
    }

    function acceptTrade(address maker, address taker, uint256 makerWei, uint256[] memory makerIds, uint256 takerWei, uint256[] memory takerIds, uint256 expiry, uint256 salt, bytes memory signature) external  nonReentrant whenNotPaused {
        require(!marketPaused, "Market is paused.");
        require(msg.sender != maker, "Can't accept ones own trade.");
        Offer memory offer = Offer(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt);

        require(offer.taker == address(0) || offer.taker == msg.sender, "Not the recipient of this offer.");
        require(tradeValid(maker, taker, makerWei, makerIds, takerWei, takerIds, expiry, salt, signature), "Trade not valid.");
        require(WETH.balanceOf(msg.sender) >= offer.takerWei , "Insufficient funds to execute trade.");
        
        // Transfer ETH
        gratuity(maker,msg.sender,offer.makerWei);
        gratuity(msg.sender,maker,offer.takerWei);
        
        // Transfer maker ids to taker (msg.sender)
        for (uint i = 0; i < makerIds.length; i++) {
            _gamefishiba.transferFrom(maker,msg.sender, makerIds[i]);
        }
        // Transfer taker ids to maker
        for (uint i = 0; i < takerIds.length; i++) {
            _gamefishiba.transferFrom(msg.sender,maker, takerIds[i]);
        }
        // Prevent a replay attack on this offer
        bytes32 hash = hashOffer(offer);
        cancelledOffers[hash] = true;
        emit Trade(hash, offer.maker, msg.sender, offer.makerWei, offer.makerIds, offer.takerWei, offer.takerIds);
    }

    //update transaction fee
    function setMarketFee(uint marketFee_) public onlyOwner {
        marketFee = marketFee_;
    }
    //Get the sale price
    function grantSalesPrices(uint grant) public view returns(uint){
        return _grantSalesPrices[grant];
    }
    //Update sale price
    function setGrantSalesPrices(uint grant,uint price) onlyOwner public {
        if( grant >= _grantSalesPrices.length)
            _grantSalesPrices.push(price);
        else
            _grantSalesPrices[grant]=price;
    }
    //Get an nft 
    function mint(address to,uint grant) public nonReentrant whenMintEable returns(uint _tokenId){
        uint len  = mintPoolSize[grant];
        require(len > 0 , 'Sold out');
        WETH.transferFrom(msg.sender, address(this), grantSalesPrices(grant));
        uint random = GameFiShibaLib._randomSpeed(++nonce) % len;
        _tokenId = _gamefishiba.mint(to, mintPool[grant][random]);
        if(random != len - 1){
            mintPool[grant][random] = mintPool[grant][len - 1];
        }
        mintPoolSize[grant]--;
    }
    //Put genetic data into the pool
    function pushMetaData(uint grant,DogsMetaData[] memory meta) nonReentrant onlyOwner public {
        for(uint i=0;i<meta.length;i++){
            require(keccak256(abi.encode(meta)) != _emptyMetaData);
            mintPool[grant][mintPoolSize[grant]++] = meta[i];
        }
    }
    //peek the elements in the pool
    function peek(uint grant,uint index)  public view onlyOwner returns (DogsMetaData memory _meta){
        return mintPool[grant][index];
    }
    //Get the pool size
    function sizeOf(uint grant) public view returns(uint _size){
        return mintPoolSize[grant];
    }
    //Go back to the corresponding genetic data
    function revertMetaData(uint grant,uint index,DogsMetaData memory meta) nonReentrant onlyOwner public{
        require(mintPoolSize[grant] > index,'index out of bound');
        require(keccak256(abi.encode(meta)) != keccak256(abi.encode(mintPool[grant][index])),"revert fail");
        uint len =  mintPoolSize[grant];
        if(index != len -1){
            mintPool[grant][index] = mintPool[grant][len - 1];
        }
        mintPoolSize[grant]--;
    }
    //pause mint , Default off
    function pauseMint() public onlyOwner{
        salesPaused = true;
        emit MintStateChange(msg.sender,true);
    }
    //unpause mint
    function unpauseMint() public onlyOwner{
        salesPaused = false;
        emit MintStateChange(msg.sender,false);
    }
    //Close free trade
    function pause() public onlyOwner{
        marketPaused = true;
        emit MarketStateChange(msg.sender, true);
    }
    //Open free trade
    function unpause() public onlyOwner{
        marketPaused = false;
        emit MarketStateChange(msg.sender, false);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

