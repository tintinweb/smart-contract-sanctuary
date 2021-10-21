// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

/**
 * @title BCBytes Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract BCBytes is ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    string public PROVENANCE = "";
    uint256 public MAX_SUPPLY;

    uint256 public mintPrice;
    uint256 public maxByMint;

    address public clientAddress;
    address public devAddress;

    bool public saleIsActive;
    bool public startBreeding;

    event MintNFT(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    modifier startedBreeding() {
        require(startBreeding == true, "Breeding is not active");
        _;
    }

    constructor() ERC721("BCBYTES", "BCBYTES") {
        saleIsActive = false;

        MAX_SUPPLY = 11170;
        mintPrice = 3 * 10**16;
        maxByMint = 20;

        clientAddress = 0x47b2Ee634a2681B12E7325A3068B8Fb65fd567d4;
        devAddress = 0xE1bF6046BC0F602F8c31E5dd4e090bd959F9B7a4;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMaxByMint(uint256 newMaxByMint) external onlyOwner {
        maxByMint = newMaxByMint;
    }

    function setSaleStatus(bool status) external onlyOwner {
        saleIsActive = status;
    }

    function setBreedStatus(bool status) external onlyOwner {
        startBreeding = status;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function getTokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokenIdList = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIdList[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIdList;
    }

    function _mintOne(address _to) internal {
        uint256 id = _totalSupply();

        _tokenIdTracker.increment();
        _safeMint(_to, id);

        emit MintNFT(_to, id);
    }

    function mintByUser(address _to, uint256 _numberOfTokens)
        public
        payable
        checkSaleIsActive
    {
        uint256 totalSupply = _totalSupply();
        require(
            totalSupply + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );
        require(_numberOfTokens <= maxByMint, "Exceeds Amount");
        require(
            mintPrice.mul(_numberOfTokens) <= msg.value,
            "Low Price To Mint"
        );

        for (uint256 i = 0; i < _numberOfTokens; i += 1) {
            _mintOne(_to);
        }
    }

    function breed(uint256 tokenId1, uint256 tokenId2)
        public
        startedBreeding
    {
        require(!isContract(_msgSender()), "No Contract");
        burn(tokenId1);
        burn(tokenId2);
        _mintOne(_msgSender());
    }

    function mintByOwner(address _to, uint256 _numberOfTokens)
        external
        onlyOwner
    {
        uint256 totalSupply = _totalSupply();
        require(
            totalSupply + _numberOfTokens <= MAX_SUPPLY,
            "Max Limit To Presale"
        );

        for (uint256 i = 0; i < _numberOfTokens; i += 1) {
            _mintOne(_to);
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 devAmount = totalBalance.div(4);
        uint256 clientAmount = totalBalance.sub(devAmount);

        payable(devAddress).transfer(devAmount);
        payable(clientAddress).transfer(clientAmount);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}