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

    mapping(address => uint256) private whitelist;

    uint256 public MAX_ELEMENTS = 7;
    uint256 public constant PRICE = 33 * 10**15;
    uint256 public constant MAX_BY_MINT = 20;
    address public constant creatorAddress = 0x893E23C01658bC1C112d6fdf10f34826c280A1B1;
    string public KUDDLY_PROVENANCE = "";
    string public baseTokenURI;
    bool public canChangeSupply = true;
    bool public presaleOpen = false;
    bool public mainSaleOpen = false;
    uint256 private presaleMaxPerMint = 3;

    // Reserve 250 Koalas for Giveaways/Prizes/Team etc
    uint public koalasReserve = 250;

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
        require(mainSaleOpen, "Public sale hasn't started!");
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function mintPresale(address _to, uint256 _count) public payable {
        require(presaleOpen);
        require(_count <= whitelist[msg.sender]);
        uint256 total = _totalSupply();
        require(total + _count <= MAX_ELEMENTS, "Max limit");
        require(msg.value >= (_count * 33 * 10**15), "Value below price");

        for (uint256 i = 0; i < _count; i++) {
          _mintAnElement(_to);
        }

        whitelist[msg.sender] = whitelist[msg.sender] - _count;
    }

    function togglePresaleMint() public onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function enableMainSale() public onlyOwner {
        mainSaleOpen = true;
    }

    function changePresaleMaxPerMint(uint256 _amount) public onlyOwner {
        presaleMaxPerMint = _amount;
    }

    function addToWhitelist(address[] memory _listToAdd) public onlyOwner {
        for (uint256 i = 0; i < 50; i++) {
          whitelist[_listToAdd[i]] = presaleMaxPerMint;
        }
    }

    function saleIsActive() public view returns (bool) {
        if(paused()) {
            return false;
        } else {
            return true;
        }
    }

    function isMainSaleOpen() public view returns (bool) {
        return mainSaleOpen;
    }

    function isPresaleOpen() public view returns (bool) {
        return presaleOpen;
    }

    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateKoalas(id);
    }

    // These functions allow an adaptive mint supply as defined in the Kuddly Koalas roadmap
    // There are NO other methods to increase the cap, the final cap is 8888 - this can never be altered
    function enableStage2Sale() public onlyOwner {
        require(canChangeSupply);
        MAX_ELEMENTS = 4444;
    }

    function enableStage3Sale() public onlyOwner {
        require(canChangeSupply);
        MAX_ELEMENTS = 6666;
    }

    function enableStage4Sale() public onlyOwner {
        require(canChangeSupply);
        MAX_ELEMENTS = 8888;
    }

    function enableHardLimit(uint256 _limit) public onlyOwner {
        require(canChangeSupply);
        require(_limit <= 8888);
        MAX_ELEMENTS = _limit;
    }

    function relinquishMintSupplyControl() public onlyOwner {
        // Sets canChangeSupply to false (off)
        // This is a one-way switch
        // There is no other possible method to re-enable control of max Mint Supply
        require(canChangeSupply);
        canChangeSupply = false;
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

    function withdrawAllBackup() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdrawBackup(creatorAddress, address(this).balance);
    }

    function withdrawSomeBackup(uint _amount) public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > _amount);
        _withdrawBackup(creatorAddress, _amount);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _withdrawBackup(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
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