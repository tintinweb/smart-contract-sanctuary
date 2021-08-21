// SPDX-License-Identifier: MIT

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Strings.sol";

pragma solidity ^0.8.0;

contract TestingContract is ERC721Enumerable, Ownable{
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    uint256 public constant NFT_PRICE = 50000000000000000; // 0.05 ETH
    uint public constant MAX_NFT_PURCHASE = 20;
    uint256 public MAX_SUPPLY = 10000;
    bool public saleIsActive = false;

    string private _baseURIExtended;

    string public _contentCheckpointHashUrlBase;
    uint256 public _contentCheckpointIndex;

    constructor() ERC721("TestingContract","TC"){ }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveTokens(uint256 num) public onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Purchase would exceed max supply");
        require(numberOfTokens <= MAX_NFT_PURCHASE,"Can only mint up to 10 per purchase");
        require(NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setCheckpoint(string memory contentBase, uint256 checkpointIndex) external onlyOwner {
      _contentCheckpointHashUrlBase = contentBase;
      _contentCheckpointIndex = checkpointIndex;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory urlBase = tokenId < _contentCheckpointIndex ?
          _contentCheckpointHashUrlBase : _baseURI();

        return string(abi.encodePacked(urlBase, tokenId.toString()));
    }
}