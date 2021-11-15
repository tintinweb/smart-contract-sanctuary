//      ___                     _            ___  _  _    _            
//     / __\_ __  _   _  _ __  | |_  ___    / __\(_)| |_ (_)  ___  ___ 
//    / /  | '__|| | | || '_ \ | __|/ _ \  / /   | || __|| | / _ \/ __|
//   / /___| |   | |_| || |_) || |_| (_) |/ /___ | || |_ | ||  __/\__ \
//   \____/|_|    \__, || .__/  \__|\___/ \____/ |_| \__||_| \___||___/
//                |___/ |_|                                            
//
// CryptoCities is an ERC721 compliant smart contract for this project:
// (https://cryptocities.net)  
//
// In addition to a standard ERC721 interface it also includes:
//  - a maker / taker off-chain marketplace which executes final trades here
//  - batch functions for most token read functions
//  - a limited supply of 25000 tokens
// 
//  Discord:
//   https://discord.gg/Y4mhwWg 
//
//  Bug Bounty:
//   Please see the details of our bug bounty program below.  
//   https://cryptocities.net/bug_bounty
//
//  Disclaimer:
//   We take the greatest of care when making our smart contracts but this is crypto and the future 
//   is always unknown. Even if it is exciting and full of wonderful possibilities, anything can happen,  
//   blockchains will evolve, vulnerabilities can arise, and markets can go up and down. CryptoCities and its  
//   owners accept no liability for any issues relating to the use of this contract or any losses that may occur. 
//   Please see our full terms here: 
//   https://cryptocities.net/terms


// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./base/ERC721Batchable.sol";

contract CryptoCities is ERC721Batchable 
{
    // there can only ever be a max of this many tokens in the contract
    uint public constant tokenLimit = 25000;

    // the base url used for all meta data 
    // likely to be stored on IPFS over time   
    string private _baseTokenURI;

    // the opensea proxy registry contract (can be changed if this registry ever moves to a new contract)
    // 0xa5409ec958C83C3f309868babACA7c86DCB077c1  mainnet
    // 0xF57B2c51dED3A29e6891aba85459d600256Cf317  rinkeby
    // 0x0000000000000000000000000000000000000000  local
    address private _proxyRegistryAddress;

    // only authorized minters can mint tokens
    // this will originally be set to a swapping contract to allow users to swap their tokens to this new contract 
    mapping (address => bool) public isMinter;    

    // pausing the market disables the built-in maker/taker offer system 
    // it does not affect normal ERC721 transfers 
    bool public marketPaused;

    // the marketplace fee for any internal paid trades (stored in basis points eg. 250 = 2.5% fee) 
    uint16 public marketFee;

    // the marketplace witness is used to validate marketplace offers 
    address private _marketWitness;

    // offer that can no longer be used any more
    mapping (bytes32 => bool) private _cancelledOrCompletedOffers;

    // support for ERC2981
    uint16 private _royaltyFee;
    address private _royaltyReciever;

    constructor(address _owner, address _recovery, address proxyRegistryAddress) ERC721("CryptoCities", unicode"⬢City")    
    {
        // set the owner, recovery & treasury addresses
        transferOwnership(_owner);
        treasury = _owner;
        recovery = _recovery;

        // set the meta base url
        _baseTokenURI = "https://cryptocities.net/meta/";

        // set the open sea proxy registry address
        _proxyRegistryAddress = proxyRegistryAddress;

        // market starts disabled
        marketPaused = true;       
        marketFee = 250;    
    }


    /// BASE URI

    // base uri is where the metadata lives
    // only the owner can change this

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function contractURI() public pure returns (string memory) {
        return "https://cryptocities.net/meta/cities_contract";
    }

    /// PROXY REGISTRY

    // registers a proxy address for OpenSea or others
    // can only be changed by the contract owner
    // setting address to 0 will disable the proxy 

    function setProxyRegistry(address proxyRegistry) external onlyOwner { 

        // check the contract address is correct (will revert if not)
        if(proxyRegistry!= address(0)) {
            ProxyRegistry(proxyRegistry).proxies(address(0));
        }

        _proxyRegistryAddress = proxyRegistry;    
    }

    // this override allows us to whitelist user's OpenSea proxy accounts to enable gas-less listings
    function isApprovedForAll(address token_owner, address operator) public view override returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        if(_proxyRegistryAddress!= address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(token_owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(token_owner, operator);
    }


    /// MINTING

    // only authorized minters can mint
    // can't mint more tokens than the token limit
    
    // ERC721 standard checks:
    // can't mint while the contract is paused (checked in _beforeTokenTransfer())
    // token id's can't already exist 
    // cant mint to address(0)
    // if 'to' refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

    // emitted when a minter's authorization changes
    event MinterSet(address indexed minter, bool auth);

    // only allows an authorized minter to call the function
    modifier onlyMinters() 
    {
        require(isMinter[_msgSender()]==true, "caller not a minter");
        _;
    }

    // changes a minter's authorization
    function setMinter(address minter, bool authorized) external onlyOwner 
    { 
        isMinter[minter] = authorized;        
        emit MinterSet(minter, authorized);        
    }

    // mint a single token
    function mint(address to, uint256 tokenId) external onlyMinters  
    {        
        require(totalSupply()<tokenLimit, "token limit reached");
        _safeMint(to, tokenId);
    }

    // mint a batch of tokens
    // (gas: this function can run out of gas if too many id's are provided
    //       limiting to 25 will currently fit in the block gas limit but this may change in future)
    function mintBatch(address to, uint256[] memory tokenIds) external onlyMinters     
    {       
        require(tokenIds.length <= 25, "more than 25 ids");
        require(totalSupply()+tokenIds.length <= tokenLimit, "batch exceeds token limit");

        for (uint256 i = 0; i < tokenIds.length; i++) {  
            // we safe mint the first token          
            if(i==0) _safeMint(to, tokenIds[i]);

            // then we assume the rest are safe because they are going to the same receiver  
            else _mint(to, tokenIds[i]);      
        }         
    }

    /// BURNING

    // only the contract owner can burn tokens it owns
    // the contract owner can't burn someone elses tokens
    // normal users can't burn tokens

    // ERC721 standard checks:
    // can't burn while the contract is paused (checked in _beforeTokenTransfer())
    // the token id must exist

    function burn(uint256 tokenId) external onlyOwner 
    {
         require(ownerOf(tokenId) == owner(), "token owner not contract owner");
        _burn(tokenId);
    }


    /// MARKETPLACE

    // this contract includes a maker / taker offerplace
    // (similar to those seen in OpenSea, 0x Protocol and other NFT projects) 
    //
    // offers are made by makers off-chain and filled by callers on-chain
    // makers do this by signing their offer with their wallet 
    // smart contracts can't be makers because they can't sign messages
    // if a witness address is set then it must sign the offer hash too (eg. the website marketplace)

    // there are two types of offers depending on whether the maker specifies a taker in their offer:
    // maker / taker       (peer-to-peer offer:  two users agreeing to trade items)
    // maker / no taker    (open offer:  one user listing their items in the marketplace)

    // if eth is paid then it will always be on the taker side (the maker never pays eth in this simplified model)
    // a market fee is charged if eth is paid
    // trading tokens with no eth is free and no fee is deducted

    // allowed exchanges:

    //   maker tokens  > <  eth                          (maker sells their tokens to anyone)
    //   maker tokens  >                                 (maker gives their tokens away to anyone)

    //   maker tokens  >    taker                        (maker gives their tokens to a specific taker)
    //   maker tokens  > <  taker tokens                     .. for specific tokens back
    //   maker tokens  > <  taker tokens & eth               .. for specific tokens and eth back 
    //   maker tokens  > <  taker eth                        .. for eth only

    //   maker           <  taker tokens                 (taker gives their tokens to the maker)
    //   maker           <  taker tokens & eth               .. and with eth    

    event OfferAccepted(bytes32 indexed hash, address indexed maker, address indexed taker, uint[] makerIds, uint[] takerIds, uint takerWei, uint marketFee);    
    event OfferCancelled(bytes32 indexed hash);
    
    struct Offer {
        address maker;
        address taker;
        uint256[] makerIds;        
        uint256[] takerIds;
        uint256 takerWei;
        uint256 expiry;
        uint256 nonce;
    }

    // pausing the market will stop offers from being able to be accepted (they can still be generated or cancelled)
    function pauseMarket(bool pauseTrading) external onlyOwner {
        marketPaused = pauseTrading;
    }

    // the market fee is set in basis points (eg. 250 basis points = 2.5%)
    function setMarketFee(uint16 basisPoints) external onlyOwner {
        require(basisPoints <= 10000);
        marketFee = basisPoints;
    }

    // if a market witness is set then it will need to sign all offers too (set to 0 to disable)
    function setMarketWitness(address newWitness) external onlyOwner {
        _marketWitness = newWitness;
    }

    // recovers the signer address from a offer hash and signature
    function signerOfHash(bytes32 offer_hash, bytes memory signature) public pure returns (address signer){
        require(signature.length == 65, "sig wrong length");

        bytes32 geth_modified_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", offer_hash));
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

        require(v == 27 || v == 28, "bad sig v");

        return ecrecover(geth_modified_hash, v, r, s);
    }
 

    // this generates a hash of an offer that can then be signed by a maker
    // the offer has to have basic validity before it can be hashed
    // if checking ids then the tokens need to be owned by the parties too 
    function hashOffer(Offer memory offer, bool checkIds) public view returns (bytes32){

        // the maker can't be 0
        require(offer.maker!=address(0), "maker is 0");

        // maker and taker can't be the same
        require(offer.maker!=offer.taker, "same maker / taker");

        // the offer must not be expired yet
        require(block.timestamp < offer.expiry, "expired");

        // token id must be in the offer
        require(offer.makerIds.length>0 || offer.takerIds.length>0, "no ids");

        // if checking ids then maker must own the maker token ids
        if(checkIds){
            for(uint i=0; i<offer.makerIds.length; i++){
                require(ownerOf(offer.makerIds[i])==offer.maker, "bad maker ids");
            }
        }

        // if no taker has been specified (open offer - i.e. typical marketplace listing)
        if(offer.taker==address(0)){

            // then there can't be taker token ids in the offer
            require(offer.takerIds.length==0, "taker ids with no taker");
        }

        // if a taker has been specified (peer-to-peer offer - i.e. direct trade between two users)
        else{

            if(checkIds){
                // then the taker must own all the taker token ids   
                for(uint i=0; i<offer.takerIds.length; i++){
                    require(ownerOf(offer.takerIds[i])==offer.taker, "bad taker ids");
                }
            }
        }

        // now return the hash
        return keccak256(abi.encode(
            offer.maker,
            offer.taker,
            keccak256(abi.encodePacked(offer.makerIds)),            
            keccak256(abi.encodePacked(offer.takerIds)),
            offer.takerWei,
            offer.expiry,
            offer.nonce,
            address(this)        // including the contract address prevents cross-contract replays  
        ));
    }

    // an offer is valid if:
    //  it's maker / taker details are valid 
    //  it has been signed by the maker
    //  it has not been cancelled or completed yet
    //  the parties own their tokens (if checking ids)
    //  the witness has signed it (if witnessing is enabled)
    //  the trade is valid (if requested)
    function validOffer(Offer memory offer, bytes memory signature, bytes memory witnessSignature, bool checkIds, bool checkTradeValid, uint checkValue) external view returns (bool){

        // will revert if the offer or signer is not valid or checks fail
        bytes32 _offer_hash = _getValidOfferHash(offer, signature, checkIds, checkTradeValid, checkValue);

        // check the witness if needed
        _validWitness(_offer_hash, witnessSignature);

        return true;
    }

    // if a market witness is set then they need to sign the offer hash too
    function _validWitness(bytes32 _offer_hash, bytes memory witnessSignature) internal view {
        if(_marketWitness!=address(0)){       
            require(_marketWitness == signerOfHash(_offer_hash, witnessSignature), "wrong witness");  
        }
    }

    // gets the hash of an offer and checks that it has been signed by the maker
    function _getValidOfferHash(Offer memory offer, bytes memory signature, bool checkIds, bool checkTradeValid, uint checkValue) internal view returns (bytes32){

        // get the offer signer 
        bytes32 _offer_hash = hashOffer(offer, checkIds);
        address _signer = signerOfHash(_offer_hash, signature);
        
        // the signer must be the maker
        require(offer.maker==_signer, "maker not signer");
        
        // the offer can't be cancelled or completed already
        require(_cancelledOrCompletedOffers[_offer_hash]!=true, "offer cancelled or completed");

        // if checking the trade then we need to check the taker side too
        if(checkTradeValid){

            address caller = _msgSender();

            // no trading when paused
            require(!marketPaused, "marketplace paused");

            // caller can't be the maker
            require(caller!=offer.maker, "caller is the maker");

            // if there is a taker specified then they must be the caller
            require(caller==offer.taker || offer.taker==address(0), "caller not the taker");

            // check the correct wei has been provided by the taker (can be 0)
            require(checkValue==offer.takerWei, "wrong payment sent");
        }

        return _offer_hash;
    }
      
    
    // (gas: these functions can run out of gas if too many id's are provided
    //       not limiting them here because block gas limits change over time and we don't know what they will be in future)

    // stops the offer hash from being usable in future
    // can only be cancelled by the maker or the contract owner    
    function cancelOffer(Offer memory offer) external {
        address caller = _msgSender();
        require(caller == offer.maker || caller == owner(), "caller not maker or contract owner");

        // get the offer hash 
        bytes32 _offer_hash = hashOffer(offer, false);
                
        // set the offer hash as cancelled
        _cancelledOrCompletedOffers[_offer_hash]=true;
    
        emit OfferCancelled(_offer_hash);       
    }

    // fills an offer
    
    // offers can't be traded when the market is paused or the contract is paused
    // offers must be valid and signed by the maker 
    // the caller has to be the taker or can be an unknown party if no taker is set
    // eth may or may not be required by the offer
    // tokens must belong to the makers and takers

    function acceptOffer(Offer memory offer, bytes memory signature, bytes memory witnessSignature) external payable reentrancyGuard {
        
        // CHECKS
        
        // will revert if the offer or signer is not valid 
        // will also check token ids to make sure they belong to the parties
        // will check the caller and eth matches the offer taker details 
        bytes32 _offer_hash = _getValidOfferHash(offer, signature, true, true, msg.value);
       
        // check the witness if needed
        _validWitness(_offer_hash, witnessSignature);
       
        // EFFECTS

        address caller = _msgSender();

        // transfer the maker tokens to the caller
        for(uint i=0; i<offer.makerIds.length; i++){
             _safeTransfer(offer.maker, caller, offer.makerIds[i], "");
        }

        // transfer the taker tokens to the maker 
        for(uint i=0; i<offer.takerIds.length; i++){
             _safeTransfer(caller, offer.maker, offer.takerIds[i], "");
        }

        // set the offer has as completed (stops the offer from being reused)
        _cancelledOrCompletedOffers[_offer_hash]=true;

        // INTERACTIONS

        // transfer the payment if one is present
        uint _fee = 0;
        if(msg.value>0){

            // calculate the marketplace fee (stored as basis points)
            // eg. 250 basis points is 2.5%  (250/10000) 
            _fee = msg.value * marketFee / 10000;
            uint _earned = msg.value - _fee;

            // safety check (should never be hit)
            assert(_fee>=0 && _earned>=0 && _earned<= msg.value && _fee+_earned==msg.value);
            
            // send the payment to the maker
            //   security note: calls to a maker should only revert if insufficient gas is sent by the caller/taker
            //   makers can't be smart contracts because makers need to sign the offer hash for us
            //    - currently only EOA's (externally owned accounts) can sign a message on the ethereum network
            //    - smart contracts don't have a private key and can't sign a message, so they can't be makers here
            //    - offers for specific makers can be blacklisted in the marketplace if required

            (bool success, ) = offer.maker.call{value:_earned}("");    
            require(success, "payment to maker failed");            
        }

        emit OfferAccepted(_offer_hash, offer.maker, caller, offer.makerIds, offer.takerIds, offer.takerWei, _fee);
    }  
    

    /// ERC2981 support

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x2a55205a  // ERC2981
               || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReciever, (salePrice * _royaltyFee) / 10000);
    }

    // the royalties fee is set in basis points (eg. 250 basis points = 2.5%)
    function setRoyalties(address newReceiver, uint16 basisPoints) external onlyOwner {
        require(basisPoints <= 10000);
        _royaltyReciever = newReceiver;
        _royaltyFee = basisPoints;
    }
}

// used to whitelist proxy accounts of OpenSea users so that they are automatically able to trade any item on OpenSea
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../base/OwnableRecoverable.sol";

// ERC721Batchable wraps multiple commonly used base contracts into a single contract
// 
// it includes:
//  ERC721 with Enumerable
//  contract ownership & recovery
//  contract pausing
//  treasury 
//  batching

abstract contract ERC721Batchable is ERC721Enumerable, Pausable, OwnableRecoverable 
{   
    // the treasure address that can make withdrawals from the contract balance
    address public treasury;

    constructor()  
    {
       
    }

    // used to stop a contract function from being reentrant-called 
    bool private _reentrancyLock = false;
    modifier reentrancyGuard {
        require(!_reentrancyLock, "ReentrancyGuard: reentrant call");
 
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }


    /// PAUSING

    // only the contract owner can pause and unpause
    // can't pause if already paused
    // can't unpause if already unpaused
    // disables minting, burning, transfers (including marketplace accepted offers)

    function pause() external virtual onlyOwner {        
        _pause();        
    }
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    // this hook is called by _mint, _burn & _transfer 
    // it allows us to block these actions while the contract is paused
    // also prevent transfers to the contract address
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        require(to != address(this), "cant transfer to the contract address");
        
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "token transfer while contract paused");
    }


    /// TREASURY

    // can only be called by the contract owner
    // withdrawals can only be made to the treasury account

    // allows for a dedicated address to be used for withdrawals
    function setTreasury(address newTreasury) external onlyOwner { 
        require(newTreasury!=address(0), "cant be 0 address");
        treasury = newTreasury;
    }

    // funds can be withdrawn to the treasury account for safe keeping
    function treasuryOut(uint amount) external onlyOwner reentrancyGuard {
        
        // can withdraw any amount up to the account balance (0 will withdraw everything)
        uint balance = address(this).balance;
        if(amount == 0 || amount > balance) amount = balance;

        // make the withdrawal
        (bool success, ) = treasury.call{value:amount}("");
        require(success, "transfer failed");
    }
    
    // the owner can pay funds in at any time although this is not needed
    // perhaps the contract needs to hold a certain balance in future for some external requirement
    function treasuryIn() external payable onlyOwner {

    }


    /// BATCHING

    // all normal ERC721 read functions can be batched
    // this allows for any user or app to look up all their tokens in a single call or via paging

    function tokenByIndexBatch(uint256[] memory indexes) public view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            batch[i] = tokenByIndex(indexes[i]);
        }

        return batch; 
    }

    function balanceOfBatch(address[] memory owners) external view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](owners.length);

        for (uint256 i = 0; i < owners.length; i++) {
            batch[i] = balanceOf(owners[i]);
        }

        return batch;        
    }

    function ownerOfBatch(uint256[] memory tokenIds) external view virtual returns (address[] memory) {  
        address[] memory batch = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = ownerOf(tokenIds[i]);
        }

        return batch;
    }

    function tokenURIBatch(uint256[] memory tokenIds) external view virtual returns (string[] memory) {
        string[] memory batch = new string[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = tokenURI(tokenIds[i]);
        }

        return batch;
    }

    function getApprovedBatch(uint256[] memory tokenIds) external view virtual returns (address[] memory) {
        address[] memory batch = new address[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            batch[i] = getApproved(tokenIds[i]);
        }

        return batch;
    }

    function tokenOfOwnerByIndexBatch(address owner_, uint256[] memory indexes) external view virtual returns (uint256[] memory) {
        uint256[] memory batch = new uint256[](indexes.length);

        for (uint256 i = 0; i < indexes.length; i++) {
            batch[i] = tokenOfOwnerByIndex(owner_, indexes[i]);
        }

        return batch;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
/**
 * This is a modified version of the standard OpenZeppelin Ownable contract that allows for a recovery address to be used to recover ownership
 * 
 * 
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
abstract contract OwnableRecoverable is Context {
    address private _owner;

    // the recovery address can be used to recover ownership if the owner wallet is ever lost
    // it should be a cold-storage wallet stored in a vault and never used for any other operation
    // it should be set in the parent constructor
    // if ownership moves to a new organization then the recovery address should be moved too
    address public recovery;

    // initializes the contract setting the deployer as the initial owner.
    constructor () {
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
        require(owner() == _msgSender(), "caller is not the owner");
        _;
    }

    modifier onlyOwnerOrRecovery() {
        require(_msgSender() == owner() || _msgSender() == recovery, "caller is not the owner or recovery");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwnerOrRecovery {
        require(newOwner != address(0), "cant use 0 address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        _owner = newOwner;
    }   

    // the recovery address can be changed by the owner or the recovery address
    function setRecovery(address newRecovery) public virtual onlyOwnerOrRecovery {   
        require(newRecovery != address(0), "cant use 0 address");
        recovery = newRecovery;
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

import "../ERC721.sol";
import "./IERC721Enumerable.sol"; 

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

