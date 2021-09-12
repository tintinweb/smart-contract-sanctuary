// contracts/UmblNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract UmblNFT is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {    
    using SafeMath for uint8;
    using SafeMath for uint256;
    using Strings for string;

    uint public constant MAX_MINTING_TOKENS = 100000;

    enum TokenStatus { 
        MINTED, 
        PURCHASED, 
        EQUIPPED,
        STAKED 
    }

    // token data structure    
    struct UmblData {
        uint256 id;
        uint256 price;
        TokenStatus status;
    }

    // Flag for sale feature enable/disable
    bool public isEnabledSale = false;

    // map token id to umbl data
    mapping(uint256 => UmblData) public tokenUmblData;

    string private _baseTokenURI;
    uint public nextTokenId = 0;

    // initialize contract while deployment with contract's token name and symbol
    constructor(string memory baseURI) ERC721("Umbl NFT", "UMBL") {
        setBaseURI(baseURI);
    }  

    /*
    * Get the tokens owned by _owner
    */
    function tokensOfOwner(address _owner) 
        external 
        view 
        returns(uint256[] memory ) 
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Minting multiple tokens
    function mint(uint256 numTokens, uint256 _price) 
        public 
        onlyOwner 
        nonReentrant 
        returns(uint256)
    {
        require(numTokens > 0 && numTokens <= MAX_MINTING_TOKENS, "Must mint from 1 to 100000 NFTs");

        // mint all of these tokens
        for(uint i=0; i<numTokens; i++) {
            // increase next token ID
            nextTokenId++;

            // mint token
            _safeMint(owner(), nextTokenId);

            // create a new token struct and pass it new values
            UmblData memory newUmblData = UmblData(
                nextTokenId,
                _price,
                TokenStatus.MINTED
            );

            // add the token id and it's struct to all tokens mapping
            tokenUmblData[nextTokenId] = newUmblData;
        }

        return numTokens;
    }

    // get owner of the token
    function getTokenOwner(uint256 _tokenId)
        public view
        returns(address) 
    {
        address _tokenOwner = ownerOf(_tokenId);
        return _tokenOwner;
    }

    // get metadata of the token
    function getTokenMetaData(uint _tokenId)
        public view
        returns(string memory ) 
    {
        string memory _tokenMetaData = tokenURI(_tokenId);
        return _tokenMetaData;
    }

    // get total number of tokens owned by an address
    function getTotalNumberOfTokensOwnedByAnAddress()
        public view
        returns(uint256)
    {
        uint256 _totalNumberOfTokensOwned = balanceOf(msg.sender);
        return _totalNumberOfTokensOwned;
    }

    // Enable token isEquipped flag, lock it on saleso that lock it on sale
    function setTokenStatus(uint256 _tokenId, TokenStatus _tokenStatus) 
        public payable
    {
        // require that token should exist
        require(_exists(_tokenId));

        // check current call is same with the token's owner
        require(ownerOf(_tokenId) == msg.sender);

        // get the token from all UmblData mapping and create a memory of it as defined
        UmblData memory umblData = tokenUmblData[_tokenId];

        // check current token status is not same with parameter
        require(umblData.status != _tokenStatus);

        // update the token's forSale to false
        umblData.status = _tokenStatus;

        // set and update that token in the mapping
        tokenUmblData[_tokenId] = umblData;
    }

    // buy a token by passing in the token's id
    function buyToken(uint256 _tokenId)
        public payable
    {        
        // check if the function caller is not an zero address account
        require(msg.sender != address(0));

        // check if the token id of the token being bought exists or not
        require(_exists(_tokenId));

        // get the token's owner
        address tokenOwner = ownerOf(_tokenId);

        // token's owner should not be an zero address account
        require(tokenOwner != address(0));

        // the one who wants to buy the token should not be the token's owner
        require(tokenOwner != msg.sender);

        // get the token from all UmblData mapping and create a memory of it as defined
        UmblData memory umblData = tokenUmblData[_tokenId];

        // price sent in to buy should be equal to or more than the token's price
        require(msg.value >= umblData.price);

        // token should be for sale
        require(umblData.status == TokenStatus.PURCHASED);

        // transfer the token from owner to the caller of the function (buyer)
        _transfer(tokenOwner, msg.sender, _tokenId);

        // get owner of the token
        address payable sendTo = payable(tokenOwner);
        address payable tokenOwnerAddress = payable(owner());

        // get divided value of total token price
        uint256 _priceToOwner = msg.value / 10;
        uint256 _priceToSeller = msg.value - _priceToOwner;

        // send 10% token's worth of bnb to the owner
        tokenOwnerAddress.transfer(_priceToOwner);

        // send 90% token's worth of bnb to the owner
        sendTo.transfer(_priceToSeller);
    }

    // update token's price
    function changeTokenPrice(uint256 _tokenId, uint256 _newPrice)
        public
    {
        // require that token should exist
        require(_exists(_tokenId));

        // check the token's owner should be equal to the caller of the function
        require(ownerOf(_tokenId) == msg.sender);

        // get the token's struct from mapping and create a memory of it
        UmblData memory umblData = tokenUmblData[_tokenId];

        // update the token's price with new price
        umblData.price = _newPrice;

        // set and update the token in the mapping
        tokenUmblData[_tokenId] = umblData;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() 
        internal 
        view 
        override 
        returns (string memory) 
    {
        return _baseTokenURI;
    }

    function getMintedCount() 
        public 
        view 
        returns(uint) 
    {
        return nextTokenId;
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721) 
        returns (string memory) 
    {
        string memory _tokenURI = super.tokenURI(tokenId);
        // return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI)) : "";
    }      

    function _setBaseURI(string memory baseURI) 
        internal 
        virtual 
    {
        _baseTokenURI = baseURI;
    }

    // Administrative zone
    function setBaseURI(string memory baseURI) 
        public 
        onlyOwner 
    {
        _setBaseURI(baseURI);
    }

    function startMarketPlace() 
        public 
        onlyOwner 
    {
        isEnabledSale = true;
    }

    function pauseMarketPlace() 
        public 
        onlyOwner 
    {
        isEnabledSale = false;
    }
}