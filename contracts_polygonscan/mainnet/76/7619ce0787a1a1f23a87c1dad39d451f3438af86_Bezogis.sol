// @openzeppelin v3.2.0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC721.sol";


import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";

import "./Context.sol";
import "./Address.sol";
import "./EnumerableSet.sol";


import "./Ownable.sol";

import "./VRFConsumerBase.sol";



contract Bezogis is Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable ,
    Ownable ,
    VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // Polygon (Matic) Mainnet - VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // Polygon (Matic) Mainnet - LINK Token
        ) {
    using Strings for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // 0=defaultURI
    uint256 private constant MIN_BEZOGI_URI = 1;
    // 0=defaultURI
    string  private constant DEFAULT_BEZOGI_URI = "0";
    // max NFT supply
    uint256 private  MAX_NFT_SUPPLY = 0;

    // transfer the tokens from the sender to this contract
    IERC20 private _posWETHToken;
    
    // baseURI
    string  private _baseTokenURI;
    // mapping for bezogi URIs=[1-4096](Uint256)
    EnumerableSet.UintSet private _uriSet;  
    // mapping for token requestId
    mapping(bytes32 => uint256) private _requestIdTokenId;
    // total summoned bezogi
    uint256 private _totalSummonedBezogi = 0;
    // summoning
    mapping(uint256 => bool) private _summoning;

    // bezogi price,[4097-MAX]
    uint256 private _bezogiPrice = 1 ether;

    
    // sale available
    bool private _saleAvailable = false;
    // pre-sale available
    bool private _presaleAvailable = true;
    // transfer available
    bool private _transferAvailable = false;
    // summon available
    bool private _summonAvailable = false;
    

    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // presale whitelist
    mapping(address => bool) private _presaleWhitelist;
    // mapping for token transfer blacklist
    mapping (address => EnumerableSet.UintSet) private _tokenBlacklist;


    constructor(
        
    ) ERC721("Bezogis", "BEZOGIS") {
        _baseTokenURI = "https://api.bezoge.com/token/api/nft/";

        
        // Polygon (Matic) Mainnet
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
        
        

        _posWETHToken = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function ownerInitMaxNFTSupply(uint256 maxNFTSupply) onlyOwner public {
        require(maxNFTSupply > MAX_NFT_SUPPLY, "ERC721: maxNFTSupply value is incorrect");
        for (uint256 i = (MAX_NFT_SUPPLY + MIN_BEZOGI_URI); i <= maxNFTSupply; i++) {
            _uriSet.add(i);
        }
        MAX_NFT_SUPPLY = maxNFTSupply;
    }
    function ownerMintNFT(uint256 total) onlyOwner public {
        for (uint256 i = 0; i < total; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
    function ownerAirdrop(address[] memory _addressArray) onlyOwner public {
        for (uint256 i = 0; i < _addressArray.length; i++) {
            address owner = _addressArray[i];
            uint256 mintIndex = totalSupply();
            _safeMint(owner, mintIndex);
        }
    }
    function minterMintWithSummon(address[] memory _addressArray) public  {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC721: must have minter role to mint");
        
        // 4096
        uint256 mintIndex = totalSupply();
        require(mintIndex >= MAX_NFT_SUPPLY, "ERC721: mintIndex value is incorrect");
        

        for (uint256 i = 0; i < _addressArray.length; i++) {
            // [4096,4120)=[4096,4119]
            mintIndex = totalSupply();
            address owner = _addressArray[i];
            _safeMint(owner, mintIndex);

            summonTokenWithURI(mintIndex,(mintIndex + 1).toString());
            MAX_NFT_SUPPLY = MAX_NFT_SUPPLY  + 1;
        }
    }

    function ownerSetBaseTokenURI(string memory baseTokenURI) onlyOwner public {
        _baseTokenURI = baseTokenURI;
    }
    function ownerSetSaleAvailable(bool saleAvailable) onlyOwner public {
        _saleAvailable = saleAvailable;
    }
    function ownerSetSummonAvailable(bool summonAvailable) onlyOwner public {
        _summonAvailable = summonAvailable;
    }
    function ownerSetTransferAvailable(bool transferAvailable) onlyOwner public {
        _transferAvailable = transferAvailable;
    }
    function ownerSetPresaleAvailable(bool presaleAvailable) onlyOwner public {
        _presaleAvailable = presaleAvailable;
    }
    function ownerSetBezogiPrice(uint256 bezogiPrice) onlyOwner public {
        _bezogiPrice = bezogiPrice;
    }


    
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function ownerWithdrawWETH() onlyOwner public {
        require(_posWETHToken.transfer(msg.sender, _posWETHToken.balanceOf(address(this))), "Unable to transfer WETH");
    }
    /**
     * @dev Withdraw LINK from this contract (Callable by owner)
    */
    function ownerWithdrawLink() onlyOwner public {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer LINK");
    } 
    function pause() onlyOwner public virtual {
        _pause();
    }
    function unpause() onlyOwner public virtual {
        _unpause();
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        require(from == address(0) || getTransferAvailable(), "Unable to transfer during NFT sale.");
        require(!publicTokenBlacklisted(from,tokenId), "Unable to transfer, your token is blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable,ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    function getUriSetAtIndex(uint256 index) public view returns (uint256) {
        return _uriSet.at(index);
    }
    function getSummonAvailable() public view returns (bool) {
        return _summonAvailable;
    }
    function getTransferAvailable() public view returns (bool) {
        return _transferAvailable;
    }
    function getSaleAvailable() public view returns (bool) {
        return _saleAvailable;
    }
    function getPresaleAvailable() public view returns (bool) {
        return _presaleAvailable;
    }
    function getMaxNFTSupply() public view returns (uint256) {
        return MAX_NFT_SUPPLY;
    }   
    function getTotalSummonedBezogi() public view returns (uint256) {
        return _totalSummonedBezogi;
    } 
    function getAvailableBezogiURILength() public view returns (uint256) {
        return MAX_NFT_SUPPLY - getTotalSummonedBezogi();
    }   
    function getTokenSummoned(uint256 tokenId) public view returns (bool) {
        return bytes(_tokenURIs[tokenId]).length != 0;
    }
    function getBaseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    } 
    function getBezogiPrice() public view returns (uint256) {
        return _bezogiPrice;
    } 
    

    function publicSummonNFT(uint256 tokenId) public{
        require(getSummonAvailable(), "ERC721: summon unavailable");
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        require(!getTokenSummoned(tokenId), "ERC721: token has been summoned");
        require(!_summoning[tokenId], "ERC721: token is summoning");
        uint256 availableBezogiURILength = getAvailableBezogiURILength();
        require(availableBezogiURILength > 0, "ERC721: no available bezogi");
        
        address owner = ownerOf(tokenId);
        require(msg.sender == owner,"ERC721: only owner can summon");

        _summoning[tokenId] = true;
        bytes32 requestId = getRandomNumber();
        _requestIdTokenId[requestId] = tokenId;
    }
    



    /**
    * @dev Mints bezogi
    */
    function publicMintNFT(uint256 numberOfNfts) public  {
        // totalSupply() = [0,4096],MAX_NFT_SUPPLY=4096
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");        
        require((totalSupply() + numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(getSaleAvailable(), "Sale has not started");
        require(_posWETHToken.allowance(msg.sender, address(this)) >= (publicGetNFTPrice() * numberOfNfts), "Ether allowance value is incorrect");
        require(_posWETHToken.balanceOf(msg.sender) >= (publicGetNFTPrice() * numberOfNfts), "Insufficient WETH balance");
        
    
        if(getPresaleAvailable()){
            require(publicPresaleWhitelisted(msg.sender), "You are not on the pre-sale whitelist");            
            require(numberOfNfts <= 3, "You may not mint more than 3 NFTs during presale");            
            // max 3 NFT
            uint256 nftBalance = balanceOf(msg.sender) + numberOfNfts;
            require(nftBalance <= 3, "ERC721: You cannot mint more than 3 NFTs during presale");
        } else {
            require(numberOfNfts <= 10, "You may not mint more than 10 NFTs");
            // max 10 NFT
            uint256 nftBalance = balanceOf(msg.sender) + numberOfNfts;
            require(nftBalance <= 10, "ERC721: You cannot mint more than 10 NFTs");
        }
        
        _posWETHToken.transferFrom(msg.sender, address(this), (publicGetNFTPrice() * numberOfNfts));
        for (uint256 i = 0; i < numberOfNfts; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
        
    }
    function publicGetWETHAllowance(address _address) public view returns (uint256) {
        return _posWETHToken.allowance(_address, address(this));
    }
    /**
     * @dev Gets current Bezogi Price
     */
    function publicGetNFTPrice() public view returns (uint256) {
        uint currentSupply = totalSupply();

        // totalSupply() = [0,4096],MAX_NFT_SUPPLY=4096
        if (currentSupply >= 4096) {
            return _bezogiPrice;
        } else if (currentSupply >= 4000) {
            return 0.16 ether; 
        } else if (currentSupply >= 3000) {
            return 0.096 ether;
        } else if (currentSupply >= 2000) {
            return 0.064 ether;
        } else if (currentSupply >= 750) {
            return 0.032 ether;
        } else if (currentSupply >= 0) {
            return 0.0032 ether;
        } else {
            return 0.16 ether; 
        }
    }
    
    
    /***********************************CHAINLINK****************************************** */
    bytes32 internal keyHash;
    uint256 internal fee;
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // [0-4096]
        uint256 availableBezogiURILength = getAvailableBezogiURILength();
        uint256 tokenId = _requestIdTokenId[requestId];
        uint256 randomIndex = 0; 
        if(availableBezogiURILength > 0){
            // [0,4096)=[0-4095]
            randomIndex = randomness % availableBezogiURILength;
            if(_exists(tokenId) && !getTokenSummoned(tokenId) && _summoning[tokenId]){
                // _uriSet.length(); 4096 ,index=[0,4096) values=[1-4096]
                uint256 uri = _uriSet.at(randomIndex);
                summonTokenWithURI(tokenId,uri.toString());
                _uriSet.remove(uri);
                delete _summoning[tokenId];
            }
        }
    }
    function summonTokenWithURI(uint256 tokenId, string memory bezogiURI) internal  {
        _setTokenURI(tokenId, bezogiURI);
        _totalSummonedBezogi = _totalSummonedBezogi + 1;
    }
    function chainlinkTokenAddress() public pure returns (address) {
        return address(0xb0897686c545045aFc77CF20eC7A532E3120E0F1);
    }
    /***********************************CHAINLINK****************************************** */

    /***********************************TOKEN URI****************************************** */
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
        } else {
            // return string(abi.encodePacked(base, "0"));
            return string(abi.encodePacked(base, DEFAULT_BEZOGI_URI));
        }
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
        require(msg.sender == owner(), "ERC721URIStorage: owner required");
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    /***********************************TOKEN URI****************************************** */


    /***********************************PRESALE-WHITELIST********************************** */
    function ownerPresaleWhitelistAdd(address[] memory _addressArray) public onlyOwner {
        for (uint256 i = 0; i < _addressArray.length; i++) {
            _presaleWhitelist[_addressArray[i]] = true;
        }
    }
    function ownerPresaleWhitelistRemove(address[] memory _addressArray) public onlyOwner {
        for (uint256 i = 0; i < _addressArray.length; i++) {
            delete _presaleWhitelist[_addressArray[i]];
        }
    }
    function publicPresaleWhitelisted(address _address) public view returns(bool) {
        return _presaleWhitelist[_address];
    }
    /***********************************PRESALE-WHITELIST********************************** */


    // /**********************************TOKEN-BLACKLIST********************************** */
    function minterTokenBlacklistAdd(address _address,uint256 tokenId) public  {
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721: must have minter or admin role to add");
        require(_address != address(0), "ERC721: Cannot add zero address to the blacklist");
        _tokenBlacklist[_address].add(tokenId);
    }
    function minterTokenBlacklistRemove(address _address,uint256 tokenId) public  {
        require(hasRole(MINTER_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC721: must have minter or admin role to remove");
        _tokenBlacklist[_address].remove(tokenId);
    }
    function publicTokenBlacklisted(address _address,uint256 tokenId) public view returns(bool) {
        return _tokenBlacklist[_address].contains(tokenId);
    }
    // /**********************************TOKEN-BLACKLIST********************************** */


}