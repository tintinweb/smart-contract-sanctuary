// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Aggregator.sol";


contract TestNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Address for address;

    string private _uri;

    uint256 public _price;

    AggregatorV3Interface internal priceFeed;

    mapping(uint256 => address) private _creators;

   constructor(string memory _name, string memory _symbol, address cOwner, string memory uri_) Ownable(cOwner) ERC721(_name, _symbol) {
        _uri = uri_;
        _price = 13;
        //mainnet
        //priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        //testnet
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    }


    function getLatestPrice() public view returns (int) {

        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;

    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, tokenId.toString())) : "";
    }


    function setBaseURI(string memory _newuri) public onlyOwner {
        _uri = _newuri;

    }


    function setMintPrice(uint256 _newprice) public onlyOwner {
        _price = _newprice;
    }


    function withdrawOwner() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function getCreator(uint256 _tokenId) public view returns (address) {
        return _creators[_tokenId];
    }


    function create(uint256 _tokenId) public payable {
        require(_tokenId > 0 && _tokenId <= 13000, "Token ID invalid");
        require(!_exists(_tokenId), "ERC721Metadata: token already exists.");
        if (_price > 0) {
            uint256 rate = uint256(getLatestPrice());
            require(msg.value >= _price * 10 ** 26 / rate, "Insufficient amount of ETH to mint token");
            uint256 change = msg.value - (_price * 10 ** 26 / rate);
            if (change > 0) {
                payable(_msgSender()).transfer(change);
            }
        }
        _safeMint(_msgSender(), _tokenId);
        _creators[_tokenId] = _msgSender();
    }


    function burn(uint256 tokenId) public  {
        require(ownerOf(tokenId) == _msgSender(), "Caller is not an owner of token");
        require(_exists(tokenId), "Token doesn't exist");
        _burn(tokenId);
        delete _creators[tokenId];
    }

}