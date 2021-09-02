// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "Counters.sol";
import "ERC721Pausable.sol";

contract KuddlyKoalas is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_ELEMENTS = 2222;
    uint256 public constant PRICE = 33 * 10**15;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant creatorAddress = 0x893E23C01658bC1C112d6fdf10f34826c280A1B1;
    string public KUDDLY_PROVENANCE = "";
    string public baseTokenURI;

    // Reserve 120 Koalas for Giveaways/Prizes etc
    uint public koalasReserve = 120;

    event CreateKoalas(uint256 indexed id);

    constructor(string memory baseURI) ERC721("KuddlyKoalas", "KKL") {
        setBaseURI(baseURI); // use original sketch as baseURI egg
        pause(true); // contract starts paused
    }
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_ELEMENTS, "Sale end");
        if (_msgSender() != owner()) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function saleIsActive() public view returns (bool) {
        if(paused()) {
            return true;
        } else {
            return false;
        }
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateKoalas(id);
    }

    // This function increases the cap from 2222 (early sale) to 8888 (primary sale)
    // There is NO other method to increase the cap, the final cap is 8888 - this can never be altered
    function enablePrimarySale() public onlyOwner {
        MAX_ELEMENTS = 8888;
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        KUDDLY_PROVENANCE = provenanceHash;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(creatorAddress, address(this).balance);
    }

    function withdrawSome(uint _amount) public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > _amount);
        _withdraw(creatorAddress, _amount);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function KoalasReserve(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= koalasReserve, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        koalasReserve = koalasReserve.sub(_reserveAmount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}