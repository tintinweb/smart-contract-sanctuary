// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SubwayApeClub is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping(address => uint256) mintPassAddresses;

    string private _baseURIextended;

    uint256 public tokenSupply;

    uint256 private maxMintSupply;
    bool public publicSale = false;
    bool public mintPassSale = false;
    uint256 public price = 0.15 ether;

    constructor() ERC721("SubwayApeClub", "SWAC") {}

    function totalSupply() external view returns (uint256) {
        return tokenSupply;
    }

    function mint(uint256 _mintAmount) public payable {
        require(msg.value >= price * _mintAmount, "Insuffcient amount sent");
        require(
            tokenSupply + _mintAmount <= maxMintSupply,
            "Purchase would exceed max supply"
        );
        require(publicSale, "Sale is not active");
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(msg.sender, tokenSupply + 1);
            tokenSupply++;
        }
    }

    function mintPass(uint256 _mintAmount) public payable {
        require(msg.value >= price * _mintAmount, "Insuffcient amount sent");
        require(
            tokenSupply + _mintAmount <= maxMintSupply,
            "Purchase would exceed max supply"
        );
        require(
            mintPassAddresses[msg.sender] >= 1,
            "Address exceeds max alloted per address or not on whitelist"
        );
        require(mintPassSale == true, "Sale is not active");
        for (uint256 i = 0; i < _mintAmount; i++) {
            mintPassAddresses[msg.sender] = mintPassAddresses[msg.sender].sub(
                1
            );
            _safeMint(msg.sender, tokenSupply + i);
            tokenSupply++;
        }
    }

    function setMaxSupply(uint256 _setMaxSupply) public onlyOwner {
        maxMintSupply = _setMaxSupply;
    }

    function setPublicSaleStatus() external onlyOwner {
        publicSale = !publicSale;
    }

    function setMintPassSaleStatus() external onlyOwner {
        mintPassSale = !mintPassSale;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setPrice(uint256 _priceInWei) external onlyOwner {
        price = _priceInWei;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function populateMintPass(address[] memory _mintPassAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _mintPassAddresses.length; i++) {
            mintPassAddresses[_mintPassAddresses[i]] = mintPassAddresses[
                _mintPassAddresses[i]
            ].add(2);
        }
    }

    function viewMintPassForAddress(address _address)
        external
        view
        returns (uint256)
    {
        return mintPassAddresses[_address];
    }
}