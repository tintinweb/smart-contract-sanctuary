//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./BitHotelRoomCollection.sol";

/**@title Presale BitHotel smart contract
 * @author BitHotel Team
 */
 // solhint-disable-next-line max-states-count
contract PresaleBitHotelRoomCollectionBTH is AccessControl, ERC721Holder, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    struct GameNFT {
        BitHotelRoomCollection collection;
        uint256 tokenId;
        string uri;
        uint256 royaltyValue;
        uint256 price;
        uint256 discountPrice;
        bool valid;
    }

    mapping(address => mapping(uint256 => GameNFT)) private _gameNfts; 
    mapping(address => uint256) private _bought;
    mapping(address => uint256) private _whitelistIndex;
    mapping(address => uint256) private _discountedIndex;

    uint8 private constant _MAX_BUYS = 2;
    uint256 private _discountRate;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant DISCOUNTED_ROLE = keccak256("DISCOUNTED_ROLE");
    address[] private _whitelisted;
    address[] private _discounted;

    // Amount of BTH wei raised
    uint256 private _weiRaised;

    address private _wallet;
    uint256 private _globalRoyaltyValue;
    bool private _isWhitelistEnabled = true;

    IUniswapV2Router02 private _v2Router;
    address private _v2RouterAddress;
    address[] private _tokenPath;
    IERC20 private _bth;
    address private _bthAddress;
    address private _busdAddress;

    enum Error {
        None,
        RevertWithMessage,
        RevertWithoutMessage,
        Panic
    }

    modifier maxBuys(address beneficiary) {
        // solhint-disable-next-line reason-string
        require(_bought[beneficiary] < _MAX_BUYS, "BitHotelRoomCollection: already bought MAX amount NFTs");
        _;
    }

    /**
     * @dev Event emitted when GameNFT is added.
     * @param collectionAddress the address of the nft collection
     * @param tokenId the token identification of the nft
     * @param uri ipfs uris of the nft
     * @param royaltyValue the royalty value for the team
     * @param price the price of the nft
     * @param discountPrice the discount price of the nft
     * @param valid true of false
     */
    event AddGameNFT(address collectionAddress, uint256 tokenId, string uri, uint256 royaltyValue, uint256 price, uint256 discountPrice, bool valid);
    event Claimed(address receiver, address contractAddress, uint256 tokenId);
     /**
     * @dev Event emitted when BTH token is received from beneficiary.
     */
    event Received(address operator, address from, uint256 tokenId, bytes data, uint256 gas);
    /**
     * @dev Event emitted when assets are deposited
     *
     * @param purchaser who deposit for the stablecoin/BTH
     * @param to where deposit forward to
     * @param token IERC20 stablecoin/BTH deposited
     * @param amount amount of tokens deposited
     */
    event Deposited(address indexed purchaser, address indexed to, address token, uint256 amount);

    constructor(
        address wallet_,
        address busdAddress,
        address bthAddress,
        uint256 globalRoyaltyValue_,
        uint256 discountRate_
    ){
        _wallet = wallet_;
        _busdAddress = busdAddress;
        _bthAddress = bthAddress;
        _bth = IERC20(bthAddress);
        _globalRoyaltyValue = globalRoyaltyValue_;
        _discountRate = discountRate_;

        //_v2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //pancakeswap mainnet
        _v2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //pancakeswap TESTNET
        _v2RouterAddress = address(_v2Router);
        _tokenPath = new address[](2);
        _tokenPath[0] = busdAddress;
        _tokenPath[1] = bthAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev initializer will run after deploy the contract immediately.
     *
     * @param gameNfs set up the game collection NFTs 
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `gameNfs` can not be the empty array.
     * - `collectionAddress` within `gameNfs` input array can not be the zero address.
     * - `tokenId` within input array can not be the zero value.
     *
     */
    function initializer(GameNFT[] calldata gameNfs) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(gameNfs.length > 0, "BitHotelRoomCollection: empty gameNfs");
        for(uint256 i = 0; i< gameNfs.length; i++) {
            address collectionAddress = address(gameNfs[i].collection);
            GameNFT storage gameNft = _gameNfts[collectionAddress][gameNfs[i].tokenId];
            // solhint-disable-next-line reason-string
            require(address(gameNft.collection) != address(0), "BitHotelRoomCollection: collection address is the zero address");
            // solhint-disable-next-line reason-string
            require(gameNft.tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
            addGameNft(
                collectionAddress,
                gameNft.tokenId,
                gameNft.uri,
                gameNft.royaltyValue,
                gameNft.price
           );
               
         }
    }

    /**
     * @dev remove whitelisted addresses.
     * @param whitelists array of addresses
     *
     * Requirements:
     *
     * - `whitelists` whitelists length cannot be 0.
     *
    */
    function bulkRemoveWhitelist(address[] calldata whitelists) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelists.length > 0, "BitHotelRoomCollection: empty whitelist");
        for (uint256 i = 0; i < whitelists.length; i++) {
            address whitelisted_ = whitelists[i];
            removeWhitelist(whitelisted_);
        }
    }

    /**
     * @dev remove discounted addresses.
     * @param discountedAddresses array of addresses
     *
     * Requirements:
     *
     * - `discountedAddresses` discountedAddresses length cannot be 0.
     *
    */
    function bulkRemoveDiscountedAddresses(address[] calldata discountedAddresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountedAddresses.length > 0, "BitHotelRoomCollection: empty discountedAddres");
        for (uint256 i = 0; i < discountedAddresses.length; i++) {
            address discountedAddres = discountedAddresses[i];
            removeDiscounted(discountedAddres);
        }
    }

    /** 
     * @dev add multiple GameNFT in to Presale contract
     * @param tokenIds arrays of nft identifications
     * @param uris array of ipfs uris
     * @param royaltyValues array of royalty value, 
     *   if 0 then the smart contrac will use globalRoyaltyValue
     * @param prices array of bth prices of NFTs
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenIds` tokenIds length cannot be 0.
     * - `uris` uris length must be equal to tokenIds length.
     * - `royaltyValues` royaltyValues length must be equal to tokenIds length.
     * - `prices` prices length must be equal to tokenIds length.
     * - `tokenId` within `gameNfs` input array can not be the zero value.
     * - `price` within `gameNfs` input array can not be the zero value.
     *
    */
    function bulkAddGameNFTs(
        address collectionAddress, 
        uint256[] memory tokenIds,
        string[] memory uris,
        uint256[] memory royaltyValues,
        uint256[] memory prices
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenIds.length > 0, "BitHotelRoomCollection: empty nft");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == uris.length, "BitHotelRoomCollection: invalid uri length");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == royaltyValues.length, "BitHotelRoomCollection: invalid royaltyValues length");
        // solhint-disable-next-line reason-string
        require(tokenIds.length == prices.length, "BitHotelRoomCollection: invalid prices length");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 bthPrice = prices[i];
            // solhint-disable-next-line reason-string
            require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
            // solhint-disable-next-line reason-string
            require(bthPrice != 0, "BitHotelRoomCollection: price is zero");
            addGameNft(collectionAddress, tokenId, uris[i], royaltyValues[i], bthPrice);
        }
    }

    /** 
     * @dev set Room informations into collection contract
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the token identification of the nft
     * @param number the room number of the nft
     * @param floorId the floorId of the room, on which floor is the room situated
     * @param roomTypeId the id of the room type
     * @param locked the ability to locked transfers of the nft
     * @param x the x position of the room within the floor
     * @param y the y position of the room within the floor
     * @param width the width of the room 
     * @param height the height of the room 
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must be added in `GameNFT`.
     *
    */
    function setRoomInfos(
        address collectionAddress,
        uint256 tokenId,
        uint256 number,
        string memory floorId,
        string memory roomTypeId,
        bool locked,
        uint8 x,
        uint8 y,
        uint32 width,
        uint32 height
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).setRoomInfos(tokenId, number, floorId, roomTypeId, locked, x, y, width, height);
    }

    function whitelisted() external view returns(address[] memory) {
        return _whitelisted;
    }

    function discounted() external view returns(address[] memory) {
        return _discounted;
    }

    function tokenPath() external view returns(address[] memory){
        return _tokenPath;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setDiscountRate(uint256 discountRate_) external onlyRole(DEFAULT_ADMIN_ROLE) {
         _discountRate = discountRate_;
    }

    function setWhitelistEnabled(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _isWhitelistEnabled = value;
    }

    /** 
     * @dev lock trading for the specific nft
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the nft identifications
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must added in `GameNFT`.
     *
     */
    function lockTokenId(address collectionAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).lockTokenId(tokenId);
    }

    /** 
     * @dev lock trading for the specific nft
     *
     * @param collectionAddress the address of the nft collection
     * @param tokenId the nft identifications
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     * - `collectionAddress` can not be the zero address.
     * - `tokenId` can not be the zero value.
     * - `collectionAddress` and `tokenId` must added in `GameNFT`.
     *
     */
    function releaseLockedTokenId(address collectionAddress, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collectionAddress != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is zero");
        // solhint-disable-next-line reason-string
        require(exists(collectionAddress, tokenId), "BitHotelRoomCollection: tokenID does not exist in GameNFT");
        BitHotelRoomCollection(collectionAddress).releaseLockedTokenId(tokenId);
    }

    /**
    * @dev set whitelisted addresses.
    * @param whitelists array of addresses
    */
    function bulkWhitelist(address[] calldata whitelists) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelists.length > 0, "BitHotelRoomCollection: empty address");
        for (uint256 i = 0; i < whitelists.length; i++) {
            address whitelisted_ = whitelists[i];
            setWhitelist(whitelisted_);
        }
    }

    /**
    * @dev set bulk discounted addresses.
    * @param discountAddresses array of addresses
    */
    function bulkDiscounted(address[] calldata discountAddresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountAddresses.length > 0, "BitHotelRoomCollection: empty address");
        for (uint256 i = 0; i < discountAddresses.length; i++) {
            address discounted_ = discountAddresses[i];
            setDiscountAddress(discounted_);
        }
    }

    /**
     * @dev See {IBitHotelRoomCollection-setController}.
     */
    function setController(address collectionAddress, address controller_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BitHotelRoomCollection(collectionAddress).setController(controller_);
    }

    function setToken(address token_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_bthAddress != token_, "PresaleBitHotel: token already set");
        _bth = IERC20(token_);
        _bthAddress = token_;
    }

    // PUBLIC 

    // testing
    function token() public view returns(address) {
        return _bthAddress;
    }

    // Mainnet
    function bth() public view returns(address) {
        return _bthAddress;
    }

    function busd() public view returns(address) {
        return _busdAddress;
    }

    function router() public view returns(address) {
        return _v2RouterAddress;
    }

    function discountRate() public view returns(uint256) {
        return _discountRate;
    }

    function wallet() public view returns(address) {
        return _wallet;
    }

    function globalRoyaltyValue() public view returns(uint256) {
        return _globalRoyaltyValue;
    }

    /**
     * @return the amount of BTH wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function totalWhitelisted() public view returns(uint256) {
        return _whitelisted.length;
    }

    function totalDiscounted() public view returns(uint256) {
        return _discounted.length;
    }

    //return the index of whitelisted address
    function whitelistIndex(address whitelisted_) public view returns(uint256) {
        return _whitelistIndex[whitelisted_];
    }

    //return the index of discounted address
    function discountedIndex(address discountedAddress) public view returns(uint256) {
        return _discountedIndex[discountedAddress];
    }

    function bought(address beneficiary) public view returns (uint256) {
        return _bought[beneficiary];
    }

    function exists(address collectionAddress, uint256 tokenId) public view returns(bool) {
        return _gameNfts[collectionAddress][tokenId].tokenId == tokenId;
    }


    function getAmountsOut(uint256 amountIn)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return _v2Router.getAmountsOut(amountIn, _tokenPath);
    }

    /**
     * @return the GameNFT storage information
     */
    function gameNFTbyTokenId(address collection, uint256 tokenId) public view returns(uint256, string memory, uint256, uint256, bool) {
        uint256 tokenId_ = _gameNfts[collection][tokenId].tokenId;
        string memory uri_ = _gameNfts[collection][tokenId].uri;
        uint256 royaltyValue = _gameNfts[collection][tokenId].royaltyValue;
        uint256 price = _gameNfts[collection][tokenId].price;
        bool valid = _gameNfts[collection][tokenId].valid;
        return (tokenId_, uri_, royaltyValue, price, valid);
    }

    /**
     * @return the discound bus price of the nft
     */
    function getDiscountPriceByTokenID(address collection, uint256 tokenId) public view returns(uint256) {
        return _gameNfts[collection][tokenId].discountPrice;
    }

    function isWhitelistEnabled() public view returns(bool) {
        return _isWhitelistEnabled;
    }

    /**
     * @dev set one whitelist address.
     * @param whitelist address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `whitelist` can not be the zero address.
     */
    function setWhitelist(address whitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelist != address(0), "PresaleBitHotel: whitelisted is the zero address");
        if (!hasRole(WHITELISTED_ROLE, whitelist)) {
            uint256 index;
            index = totalWhitelisted() + 1; // mapping index starts with 1
            _whitelistIndex[whitelist] = index;
            _whitelisted.push(whitelist);
            _setupRole(WHITELISTED_ROLE, whitelist);
        }
    }

    /**
     * @dev set one discounted address.
     * @param discountAddress address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `discountAddress` can not be the zero address.
     */
    function setDiscountAddress(address discountAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discountAddress != address(0), "PresaleBitHotel: discountAddress is the zero address");
        if (!hasRole(DISCOUNTED_ROLE, discountAddress)) {
            uint256 index;
            index = totalDiscounted() + 1; // mapping index starts with 1
            _discountedIndex[discountAddress] = index;
            _discounted.push(discountAddress);
            _setupRole(DISCOUNTED_ROLE, discountAddress);
            // Discounted must have WHITELISTED_ROLE
            if (!hasRole(WHITELISTED_ROLE, discountAddress)) {
                setWhitelist(discountAddress);
            }
        }
    }

    /** 
     * @dev add one GameNFT in to Presale contract
     * @param tokenId the nft identifications
     * @param uri ipfs uris of the nft
     * @param royaltyValue the royalty value for the team, 
     *   if 0 then the smart contrac will use globalRoyaltyValue
     * @param price the BTH price of the NFT
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `collection` can not be the zero address.
     * - `tokenId` within can not be the zero value.
     * - `price` within must be greater than zero.
     *
     */
   function addGameNft(
       address collection,
       uint256 tokenId,
       string memory uri,
       uint256 royaltyValue,
       uint256 price
   ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(collection != address(0), "BitHotelRoomCollection: addres is the zero address");
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is the zero value");
        // solhint-disable-next-line reason-string
        require(price > 0, "BitHotelRoomCollection: price is the zero value");
       
        if (royaltyValue == 0) {
            royaltyValue = globalRoyaltyValue();
        }

        uint256 weiPrice = price * 1 ether; // 18 decimals of BTH
        GameNFT storage gameNft = _gameNfts[collection][tokenId];
        gameNft.collection = BitHotelRoomCollection(collection);
        gameNft.tokenId = tokenId;
        gameNft.uri = uri;
        gameNft.royaltyValue = royaltyValue;
        gameNft.price = weiPrice;
        gameNft.discountPrice =  weiPrice - (weiPrice * discountRate() / 100);
        gameNft.valid = true;
        emit AddGameNFT(collection, tokenId, uri, royaltyValue, weiPrice, gameNft.discountPrice, gameNft.valid);
    }

    /**
     * @dev remove from whitelist.
     * @param whitelist address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `whitelist` must have WHITELISTED_ROLE.
     * - `whitelist` must have whitelisted mapping.
     */
    function removeWhitelist(address whitelist) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(whitelist != address(0), "PresaleBitHotel: whitelisted is the zero address");
        // solhint-disable-next-line reason-string
        require(hasRole(WHITELISTED_ROLE, whitelist), "PresaleBitHotel: address not whitelisted");

        uint256 index = whitelistIndex(whitelist);
        // solhint-disable-next-line reason-string
        require(index > 0, "PresaleBitHotelRoomCollection: no whitelist index found in mapping");

        uint256 arrayIndex = index - 1;
        // solhint-disable-next-line reason-string
        require(arrayIndex >= 0, "PresaleBitHotelRoomCollection: array out-of-bounds");
        for (uint i = arrayIndex; i < _whitelisted.length - 1; i++) {
            _whitelisted[i] = _whitelisted[i + 1];
        }
        _whitelisted.pop();
        delete _whitelistIndex[whitelist];
        _revokeRole(WHITELISTED_ROLE, whitelist);
    }

    /**
     * @dev remove from whitelist.
     * @param discounted_ address
     *
     * Requirements:
     *
     * - `msg.sender` only admin addresses can call this function.
     * - `discounted_` must have DISCOUNTED_ROLE.
     * - `discounted_` must have discounted mapping.
     */
    function removeDiscounted(address discounted_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(discounted_ != address(0), "PresaleBitHotel: discounted is the zero address");
        // solhint-disable-next-line reason-string
        require(hasRole(DISCOUNTED_ROLE, discounted_), "PresaleBitHotel: address not discounted");

        uint256 index = discountedIndex(discounted_);
        // solhint-disable-next-line reason-string
        require(index > 0, "PresaleBitHotelRoomCollection: no discounted index found in mapping");
        
        uint256 arrayIndex = index - 1;
        // solhint-disable-next-line reason-string
        require(arrayIndex >= 0, "PresaleBitHotelRoomCollection: array out-of-bounds");
        for (uint i = arrayIndex; i < _discounted.length - 1; i++) {
            _discounted[i] = _discounted[i + 1];
        }
        _discounted.pop();
        delete _discountedIndex[discounted_];
        _revokeRole(DISCOUNTED_ROLE, discounted_);
        if (hasRole(WHITELISTED_ROLE, discounted_)) {
            removeWhitelist(discounted_);
        }
    }
  
    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn"t be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     * @param bthAmount amount of the BTH token
     * @param collection address of the nft collection
     * @param tokenId the tokenId to be minted
     *
     * Requirements:
     *
     * - `token()` must have a token address.
     * - `beneficiary` cannot be the zero address.
     * - `bthAmount` cannot be the zero value.
     * - `collection` address cannot be the zero address.
     * - `tokenId` must exist in GameNFt storage.
     * - `bthAmount` must be the same as gameNFT bthAmount,
     *      if discounted must be the same as gameNFT discountPrice. 
     * - collection totalSupply must be smaller than replicas
     *   (there are still tokens available to mint)
     */
    function buy(address beneficiary, uint256 bthAmount, address collection, uint256 tokenId) 
        external 
        nonReentrant 
        whenNotPaused
    {
        if (isWhitelistEnabled()) {
            // solhint-disable-next-line reason-string
            require(hasRole(WHITELISTED_ROLE, _msgSender()), "PresaleBitHotelRoomCollection: sender is not whitelisted");
            // solhint-disable-next-line reason-string
            require(_bought[_msgSender()] < _MAX_BUYS, "BitHotelRoomCollection: already bought MAX amount NFTs");
        }
        _preValidateBuy(beneficiary, bthAmount, collection);
        _preValidateMint(collection, tokenId, bthAmount);
        address operator = _msgSender();
        

        uint256 balanceBefore = _bth.balanceOf(operator);
        // solhint-disable-next-line reason-string
        require(balanceBefore >= bthAmount, "PresaleBitHotelRoomCollection, not enough BTH token in beneficiary wallet");
    
        _receiveTokens(operator, bthAmount);
        emit Deposited(operator, wallet(), token(), bthAmount);

        _processMintNft(collection, beneficiary, tokenId);

         // update state       
        _weiRaised += bthAmount;
        if (bought(operator) == 0) {
            _bought[operator] = 1;
        } else {
            _bought[operator] += 1;
        }
    }

    /**
     * @dev Validation of an incoming buy. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Sale to extend their validations.
     * @param beneficiary Address performing the token purchase
     * @param bthAmount Value in wei involved in the purchase
     * @param collection address of the nft collection
     *
     * Requirements:
     *
     * - `beneficiary` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - `collection` address cannot be the zero address.
     */
    function _preValidateBuy(address beneficiary, uint256 bthAmount, address collection) internal virtual view {
        // solhint-disable-next-line reason-string
        require(token() != address(0), "PresaleBitHotel: token is the zero address");
        // solhint-disable-next-line reason-string
        require(beneficiary != address(0), "PresaleBitHotel: beneficiary is the zero address");
        require(bthAmount != 0, "PresaleBitHotel: bthAmount is 0");
         // solhint-disable-next-line reason-string
        require(collection!= address(0), "PresaleBitHotel: collection address is the zero address");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

     /**
     * @dev Validation of an incoming minting. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Sale to extend their validations.
     * @param collection address of the nft collection
     * @param tokenId The id of the nft
     * @param bthAmount amount of the stable coin
     *
     * Requirements:
     *
     * - `tokenId` must exist in GameNFt storage.
     * - `bthAmount` must be the same as gameNFT bthPrice,
     *      if discounted must be the same as gameNFT discountPrice. 
     * - `tokenId` not minted before
     * - collection totalSupply must be smaller than replicas
     *   (there are still tokens available to mint)
     *
     */
    function _preValidateMint(address collection, uint256 tokenId, uint256 bthAmount) internal virtual view {
        // solhint-disable-next-line reason-string
        require(exists(collection, tokenId), "PresaleBitHotel: tokenId not yet added to GameNFT");
        if (hasRole(DISCOUNTED_ROLE, _msgSender())) {
            uint256 discountPrice = getDiscountPriceByTokenID(collection, tokenId);
            // solhint-disable-next-line reason-string
            require(bthAmount == discountPrice, "PresaleBitHotel, bthAmount is not equal to discountPrice");
        } else {
            (,,, uint256 bthPrice,) = gameNFTbyTokenId(collection, tokenId);
            // solhint-disable-next-line reason-string
            require(bthAmount == bthPrice, "PresaleBitHotel, bthAmount is not equal to bthPrice");
        }
        bool exists_ = BitHotelRoomCollection(collection).exists(tokenId);
        // solhint-disable-next-line reason-string
        require(!exists_, "PresaleBitHotel: tokenId already minted");
        uint256 replicas = BitHotelRoomCollection(collection).replicas();
        uint256 totalSupply = BitHotelRoomCollection(collection).totalSupply();
        // solhint-disable-next-line reason-string
        require(totalSupply < replicas, "PresaleBitHotel: all tokens already minted.");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
    * @dev SafeTransferFrom beneficiary. Override this method to modify the way in which the sale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param tokenAmount Number of tokens to be emitted
    */
    function _receiveTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        _bth.safeTransferFrom(beneficiary, wallet(), tokenAmount);
    }

    /**
     * @dev Executed when a buy has been validated and is ready to be executed. Doesn"t necessarily mint
     *      nfts.
     * @param beneficiary Address receiving the tokens
     * @param collection address of the nft collection
     * @param tokenId The id of the nft
     */
    function _processMintNft(address collection, address beneficiary, uint256 tokenId) internal {
        _safeMint(beneficiary, collection, tokenId);
    }

    /**
    * @dev mint of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
    * its tokens.
    * @param beneficiary Address performing the token purchase
    * @param collection address of the nft collection
    * @param tokenId The id of the nft
    */
    function _safeMint(
        address beneficiary,
        address collection,
        uint256 tokenId
        ) internal virtual {

        // get GameNFT by `tokenId`
        (,string memory uri, uint256 royaltyValue,,) = gameNFTbyTokenId(collection, tokenId);
        bytes memory data_ = "0x";
        BitHotelRoomCollection(collection).safeMint(
            beneficiary,
            tokenId,
            uri,
            wallet(), 
            royaltyValue,
            data_
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./IBitHotelRoomCollection.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract BitHotelRoomCollection is IBitHotelRoomCollection, AccessControl, ERC721Enumerable, ERC721URIStorage, ERC2981PerTokenRoyalties {
    struct Room {
        uint256 number;
        string floorId;
        string roomTypeId;
        bool locked;
        Dimensions dimensions;
    }

    struct Dimensions {
        uint8 x;
        uint8 y;
        uint256 width;
        uint256 height;
    }

    mapping(uint256 => Room) private _rooms;
    mapping(uint256 => address[]) private _ownersHistory;

    address[] private _owners;
    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    string private _baseTokenURI;
    address private _controller;
    uint256 private _replicas;

    modifier onlyController(address controller_) {
        // solhint-disable-next-line reason-string
        require(controller() == controller_, "BitHotelRoomCollection: not a controller address.");
        _;
    }

    modifier notLocked(uint256 tokenId) {
        if (_rooms[tokenId].locked) {
            revert TokenLocked(tokenId);
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address controller_,
        uint256 replicas_
    ) 
        ERC721(name, symbol) 
    {
        _controller = controller_;
        _replicas = replicas_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev See {IBitHotelRoomCollection-tokenIds}.
     */
    function tokenIds() external view returns (uint256[] memory) {
        return _allTokens;
    }

    /**
     * @dev See {IBitHotelRoomCollection-ownersHistory}.
     */
    function ownersHistory(uint256 tokenId) external view returns (address[] memory) {
        return _ownersHistory[tokenId];
    }

    /**
     * @dev See {IBitHotelRoomCollection-getRoomInfos}.
     * @param tokenId the nft identification
     */
    function getRoomInfos(uint256 tokenId) external virtual override view returns (uint256, string memory, string memory) {
        uint256 number = _rooms[tokenId].number;
        string memory floorId = _rooms[tokenId].floorId;
        string memory roomTypeId = _rooms[tokenId].roomTypeId;
        return(number, floorId, roomTypeId);
    }

    /**
     * @dev See {IBitHotelRoomCollection-getRoomDimensions}.
     */
    function getRoomDimensions(uint256 tokenId) external view returns (uint8, uint8, uint256, uint256) {
        uint8 x = _rooms[tokenId].dimensions.x;
        uint8 y = _rooms[tokenId].dimensions.y;
        uint256 width = _rooms[tokenId].dimensions.width;
        uint256 height = _rooms[tokenId].dimensions.height;
        return (x, y, width, height);
    }

    /**
     * @dev See {IBitHotelRoomCollection-locked}.
     */
    function locked(uint256 tokenId) external view returns (bool) {
        return _rooms[tokenId].locked;
    }

    /**
     * @dev See {IBitHotelRoomCollection-setRoomInfos}.
     */
    function setRoomInfos(
        uint256 tokenId,
        uint256 number,
        string memory floorId,
        string memory roomTypeId,
        bool locked_,
        uint8 x,
        uint8 y,
        uint256 width,
        uint256 height
    ) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(tokenId != 0, "BitHotelRoomCollection: tokenId is the zero value");
        Room storage room = _rooms[tokenId];
        room.number = number;
        room.floorId = floorId;
        room.roomTypeId = roomTypeId; 
        room.locked = locked_; 
        room.dimensions.x = x; 
        room.dimensions.y = y;
        room.dimensions.width = width; 
        room.dimensions.height = height; 
        emit RoomInfoAdded(tokenId, number, floorId, roomTypeId, locked_);
        emit DimensionsAdded(x, y, width, height);
    }

    /**
     * @dev See {IBitHotelRoomCollection-setController}.
     */
    function setController(address controller_) external onlyController(_msgSender()) {
         // solhint-disable-next-line reason-string
        require(controller_ != address(0), "BitHotelRoomCollection: controller is the zero address");
         // solhint-disable-next-line reason-string
        require(controller_ != controller(), "BitHotelRoomCollection: controller already updated");
        _controller = controller_;
        emit ControllerChanged(controller_);
    }

    /**
     * @dev See {IBitHotelRoomCollection-lockTokenId}.
     */
    function lockTokenId(uint256 tokenId) external onlyController(_msgSender()) {
         // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change for nonexistent token");
        _rooms[tokenId].locked = true;
        emit TokenIdLocked(tokenId, true);
    }

    /**
     * @dev See {IBitHotelRoomCollection-releaseLockedTokenId}.
     */
    function releaseLockedTokenId(uint256 tokenId) external onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change for nonexistent token");
        // solhint-disable-next-line reason-string
        require(_rooms[tokenId].locked == true, "BitHotelRoomCollection: tokenId not locked");
        _rooms[tokenId].locked = false;
        emit TokenIdReleased(tokenId, false);
    }

    /**
     * @dev See {IBitHotelRoomCollection-controller}.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev See {IBitHotelRoomCollection-replicas}.
     */
    function replicas() public view returns (uint256) {
        return _replicas;
    }

    /**
     * @dev See {IBitHotelRoomCollection-baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {IBitHotelRoomCollection-exists}.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable, ERC165, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBitHotelRoomCollection.setBaseURI}.
     */
    function setBaseURI(string memory newBaseTokenURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldBaseTokenURI = baseURI();
        _baseTokenURI = newBaseTokenURI;
        emit BaseUriChanged(oldBaseTokenURI, newBaseTokenURI);
    }

    /**
     * @dev See {IBitHotelRoomCollection.setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-next-line reason-string
        require(_exists(tokenId), "BitHotelRoomCollection: change uri for nonexistent token");
        _setTokenURI(tokenId, tokenURI_);
    }

    /**
     * @dev See {IBitHotelRoomCollection-mint}.
     * WARNING: Usage of this method is discouraged, use {safeMint} whenever possible
    */
    function mint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(totalSupply() < replicas(),"BitHotelRoomCollection: all tokens already minted.");

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }
        _allTokens.push(tokenId);
        emit TokenMint(tokenId, to);
    }

    /**
     * @dev See {IBitHotelRoomCollection-safeMint}.
    */
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory data_ 
    ) public onlyController(_msgSender()) {
        // solhint-disable-next-line reason-string
        require(totalSupply() < replicas(),"BitHotelRoomCollection: all tokens already minted.");

        super._safeMint(to, tokenId, data_);
        _setTokenURI(tokenId, uri);
        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }
        _allTokens.push(tokenId);
        emit TokenMint(tokenId, to);
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
    ) 
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        notLocked(tokenId)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        // add owner to _ownersHistory
        _ownersHistory[tokenId].push(to);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
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
    function _burn(uint256 tokenId) 
        internal
        virtual
        override(ERC721, ERC721URIStorage)
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBitHotelRoomCollection is IERC721 {

    error TokenLocked(uint256 tokenId);

     /**
     * @dev Emitted when `Room` is added.
     * @param tokenId the token identification of the nft
     * @param number the room number of the nft
     * @param floorId the floorId of the nft
     * @param roomTypeId the roomTypeId of the nft
     * @param locked true or false whether the nft is locked for trading
     */
    event RoomInfoAdded(uint256 tokenId, uint256 number, string floorId, string roomTypeId, bool locked);
  
    /**
     * @dev Emitted when `Dimensions` nft is added.
     */
    event DimensionsAdded(uint8 x, uint8 y, uint256 width, uint256 height);

    /**
     * @dev Emitted when `tokenId` nft is minted to `to`.
    */
    event TokenMint(uint256 tokenId, address to);

    /**
     * @dev Emitted when `setBaseURI` is change to `newBaseTokenURI`.
    */
    event BaseUriChanged(string oldBaseTokenURI, string newBaseTokenURI);

    /**
     * @dev Emitted when `setContoller` is change to `newAddress`.
    */
    event ControllerChanged(address newAddress);

    /**
     * @dev Emitted when `locked` of `tokenId` is change to true.
    */
    event TokenIdLocked(uint256 tokenId, bool locked);

    /**
     * @dev Emitted when `locked` of `tokenId` is change to false.
    */
    event TokenIdReleased(uint256 tokenId, bool locked);

    /**
     * @dev Returns all tokenIds.
     */
    function tokenIds() external view returns (uint256[] memory);

    /**
     * @dev Returns all current and previous owners of the `tokenId` token.
     */
    function ownersHistory(uint256 tokenId) external view returns (address[] memory);

    /**
     * @dev Returns all information of the Room of the `tokenId` token.
     * @param tokenId the nft identification
     */
    function getRoomInfos(uint256 tokenId) external view returns (uint256, string memory, string memory);

    /**
     * @dev Returns the dimensions of the Room , such as x- and y-position of the `tokenId` token.
     * @param tokenId the nft identification
     */
    function getRoomDimensions(uint256 tokenId) external view returns (uint8, uint8, uint256, uint256);

    /**
     * @dev Returns true of false of the locked value for the room of the `tokenId` token
     */
    function locked(uint256 tokenId) external view returns (bool);

    /**
     * @dev Return the address of the controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Return the amount of replicas has been minted.
     */
    function replicas() external view returns (uint256);

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Set Room informations of the `tokenId` token.
     *
     * @param tokenId the token identification of the nft
     * @param number the room number of the nft
     * @param floorId the floorId of the room, on which floor is the room situated
     * @param roomTypeId the id of the room type
     * @param locked the ability to locked transfers of the nft
     * @param x the x position of the room within the floor
     * @param y the y position of the room within the floor
     * @param width the width of the room 
     * @param height the height of the room 
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId` can not be the zero value.
     *
     * Emits a {RoomInfoAdded} event.
     * Emits a {DimensionsAdded} event.
     */
    function setRoomInfos(
        uint256 tokenId,
        uint256 number,
        string memory floorId,
        string memory roomTypeId,
        bool locked,
        uint8 x,
        uint8 y,
        uint256 width,
        uint256 height
    ) external ;

    /**
     * @dev Set the controller address.
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `controller_` cannot be the zero address.
     * - `controller_` cannot be the same address as the current value.
     */
    function setController(address controller_) external;

    /**
     * @dev lock the nft trading of the `tokenId` token.
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId`must exist.
     * -
     */
    function lockTokenId(uint256 tokenId) external;

    /**
     * @dev release lock the nft trading of the `tokenId` token.
     *
     * Requirements:
     *
     * - `msg.sender` only the controller address can call this function.
     * - `tokenId` must exist.
     * - `tokenId` cannot be locked before.
     * -
     */
    function releaseLockedTokenId(uint256 tokenId) external;

    /**
     * @dev setBaseURI.
     *
     * @param newBaseTokenURI the new base uri for the collections
     *
     * Requirements:
     *
     * - `msg.sender` only the admin address can call this function.
     *
     */
    function setBaseURI(string calldata newBaseTokenURI) external;

    /**
     * @dev setTokenUri for the `tokenId`.
     *
     * @param tokenId the nft identifications
     * @param tokenURI_ ipfs uris of the nft
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     *
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI_) external;

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * @param tokenId the nft identifications
     * @param uri ipfs uris of the nft
     * @param royaltyRecipient the recipient address of the royalty
     * @param royaltyValue the royalty value for the team,
     *   if 0 then the smart contrac will use globalRoyaltyValue 
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits {TokenMint and Transfer} event.
     */
    function mint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue
    ) external;

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * @param tokenId the nft identifications
     * @param uri ipfs uris of the nft
     * @param royaltyRecipient the recipient address of the royalty
     * @param royaltyValue the royalty value for the team,
     *   if 0 then the smart contrac will use globalRoyaltyValue 
     *
     * Requirements:
     *
     * - `msg.sender` only the old controller address can call this function.
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits {TokenMint and Transfer} event.
     */
    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri,
        address royaltyRecipient,
        uint256 royaltyValue,
        bytes memory _data 
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";
/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155


abstract contract ERC2981PerTokenRoyalties is ERC165, IERC2981Royalties{
    
    struct Royalty {
        address recipient;
        uint256 value;
    }

    mapping (uint256 => Royalty) internal _royalties; 

    /// @dev Sets token royalties
    /// @param id the token id fir which we register the royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");

        _royalties[id] = Royalty(recipient, value);
    }


     /// @inheritdoc IERC2981Royalties
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.recipient, (value * royalty.value) / 10000);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

pragma solidity ^0.8.8;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId_ - the NFT asset queried for royalty information
    /// @param value_ - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 tokenId_, uint256 value_)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}