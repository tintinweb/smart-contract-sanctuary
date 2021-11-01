// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ICeramic.sol";

/**
 * @title Dragon Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Dragon is ERC721Burnable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _ceramicIdTracker;

    string public PROVENANCE = "";
    uint256 public MAX_SUPPLY;
    uint256 public CERAMIC_SUPPLY;

    uint256 public mintPrice;
    uint256 public maxByMint;

    address public wallet;
    address public ceramicAddress;

    bool public saleIsActive;

    mapping(uint256 => bool) private mintedFromCeramic;

    event MintNFT(address indexed minter, uint256 indexed id);

    modifier checkSaleIsActive() {
        require(saleIsActive == true, "Sale is not active");
        _;
    }

    constructor() ERC721("DRAGON", "DRAGON") {
        saleIsActive = false;

        MAX_SUPPLY = 2000;
        CERAMIC_SUPPLY = 5000;
        mintPrice = 79 * 10**15;
        maxByMint = 20;

        wallet = 0xFa06f02481fb8e35AADcF5Fe1B39f92A7F0f1a62;
        ceramicAddress = 0x7C4d474bb7c274dDe68c0e6E82Bdfd81A2f8fa9F;
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

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current().add(_ceramicIdTracker.current());
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function totalMintByCeramic() public view returns (uint256) {
        return _ceramicIdTracker.current();
    }

    function totalMintByETH() public view returns (uint256) {
        return _tokenIdTracker.current();
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

    function _claimOne(address _to) internal {
        uint256 id = _totalSupply();

        _ceramicIdTracker.increment();
        _safeMint(_to, id);

        emit MintNFT(_to, id);
    }

    function getMintStatus(uint256 _startID, uint256 _length)
        public
        view
        returns (bool[] memory)
    {
        bool[] memory mintInfo = new bool[](_length);
        for (uint256 i; i < _length; i++) {
            mintInfo[i] = mintedFromCeramic[_startID + i];
        }
        return mintInfo;
    }

    function mintByUser(address _to, uint256 _numberOfTokens)
        public
        payable
        checkSaleIsActive
    {
        uint256 totalSupply = totalMintByETH();
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

    function getAvailableCeramic(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = ICeramic(ceramicAddress).tokensOfOwner(
            owner
        );

        uint256 availableCount;
        for (uint256 i; i < tokenIds.length; i++) {
            if (!mintedFromCeramic[tokenIds[i]]) {
                availableCount++;
            }
        }

        return availableCount;
    }

    function claimByCeramic(address _to, uint256 _numberOfTokens)
        public
        checkSaleIsActive
    {
        uint256 balance = ICeramic(ceramicAddress).balanceOf(_msgSender());
        require(balance >= _numberOfTokens, "Don't have enough Ceramic");
        uint256 totalSupply = totalMintByCeramic();
        require(
            totalSupply + _numberOfTokens <= CERAMIC_SUPPLY,
            "Max Limit To Presale"
        );

        uint256 j = 0;
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = ICeramic(ceramicAddress).tokenOfOwnerByIndex(
                _msgSender(),
                i
            );
            if (!mintedFromCeramic[tokenId]) {
                mintedFromCeramic[tokenId] = true;
                _claimOne(_to);
                j++;
            }
            if (j == _numberOfTokens) {
                break;
            }
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(wallet).transfer(totalBalance);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}