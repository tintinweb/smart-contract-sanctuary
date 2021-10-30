// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


import "./ERC721Enumerable.sol";
import "./IERC2981.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

contract FantomCats is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    IERC2981,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant maxSupply = 3000;
    uint256 public maxBuy = 5;
    uint256 public price = 25 ether;

    uint256 public presaleStart = 1634392800;
    uint256 public saleStart = 1634400000;
    string public baseURI;
    address private royaltyAddress;
    address private devAddress=0x811C63c1FD7275Cd690AD9A5d48920b523E5F142;
    address private communityAddress=0xbCC771cFFC2DEabE62C03aDa1183b6279398C8Ed;

    mapping(address => uint8) public whitelistBalance;

    uint256 public royalty = 500;

    constructor() ERC721("FantomCats", "CAT") {
        _pause();
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }



    function reserveForGiveaway(uint256 amount) public onlyOwner {
        _unpause();
        for (uint256 i = 0; i < amount; i++) {
            internalMint(devAddress);
        }
    }

    function buyCats(uint256 amount) public payable {
        require(msg.value >= price * amount, "not enough was paid");
        require(saleStart <= block.timestamp, "Sale isn't live yet");
        require(
            amount <= maxBuy,
            "No of Cats Exceeds max buy per transaction"
        );
        for (uint256 i = 0; i < amount; i++) {
            internalMint(msg.sender);
        }
    }

    function buyWhitelistedCat(uint8 amount) public payable {
        require(presaleStart <= block.timestamp, "Presale yet to start");
        require(saleStart >= block.timestamp, "Presale Over");
        require(
            whitelistBalance[msg.sender] > 0,
            "Address does'nt have any presale mint"
        );
        require(
            amount <= whitelistBalance[msg.sender],
            "Address doesn't have enough presale balance"
        );
        require(msg.value == price * amount, "Not enough was paid");


        whitelistBalance[msg.sender] -= amount;

        for (uint8 i = 0; i < amount; i++) {
            internalMint(msg.sender);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function catsOwned(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
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

    function tokenExists(uint256 _id) external view returns (bool) {
        return (_exists(_id));
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyAddress, (_salePrice * royalty) / 10000);
    }



    //dev

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPresaleTime(uint256 _time) public onlyOwner {
        presaleStart = _time;
    }

    function setSaleTime(uint256 _time) public onlyOwner {
        saleStart = _time;
    }

    function setMaxBuy(uint256 newMaxBuy) public onlyOwner {
        maxBuy = newMaxBuy;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }


    function setURI(uint256 tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function addWhitelistAddresses(address[] memory _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Address cannot be 0.");
            require(whitelistBalance[_addresses[i]] == 0, "Balance must be 0.");
            whitelistBalance[_addresses[i]] = 2;
        }
    }

    function setRoyalty(uint16 _royalty) external onlyOwner {
        require(_royalty >= 0, "Royalty must be greater than or equal to 0%");
        require(
            _royalty <= 750,
            "Royalty must be greater than or equal to 7.5%"
        );

        royalty = _royalty;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setCommunityAddress(address _address) external onlyOwner {
        communityAddress = _address;
    }

    function setDevAddress(address _address) external onlyOwner {
        devAddress = _address;
    }

    //Overrides

     function internalMint(address to) internal {
        require(totalSupply() < maxSupply, "All Cats have been minted!");
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function safeMint(address to) public onlyOwner {
        internalMint(to);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }



    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

 /// @dev withdraw native token
    function withdraw() public onlyOwner {
        uint256 amount=(address(this).balance/2);
        payable(communityAddress).transfer(amount);
        payable(devAddress).transfer(amount);
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        uint256 _amount = tokenContract.balanceOf(address(this))/2;
        tokenContract.transfer(communityAddress, _amount);
        tokenContract.transfer(devAddress, _amount);
    }

    /// @dev withdraw ERC721 tokens to the contract owner
    function withdrawNFT(address _tokenContract, uint256[] memory _id) external {
        IERC721 tokenContract = IERC721(_tokenContract);
        for (uint256 i = 0; i < _id.length; i++) {
            tokenContract.safeTransferFrom(address(this), devAddress, _id[i]);
        }
    }
}