// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract Knowman is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_NFT = 20000;
	uint256 public constant NFT_FOR_PUBLIC_SALE = 10000;
	uint256 public constant NFT_FOR_PRIVATE_SALE = 10000;
    uint256 public constant PRICE = 4 * 10**16;
    uint256 public constant MAX_BY_MINT = 24;
	
	uint256 public CURRENT_LIMIT_FOR_PUBLIC_SALE;
	uint256 public TOTAL_MINTED_IN_PUBLIC_SALE;
	uint256 public TOTAL_MINTED_IN_PRIVATE_SALE;
	
    address public creatorAddress;
    string public baseTokenURI;
	
    event CreateKnowman(uint256 indexed id);
	event AddToWhiteList(address _address);
    event RemovedFromWhiteList(address _address);
	event WhiteListMultipleAddress(address[] accounts);
    event RemoveWhiteListedMultipleAddress(address[] accounts);
	event PublicSaleLimit(uint256 newLimit);
	
	mapping (address => bool) public isWhiteListed;
	
    constructor(string memory baseURI, address payable creator) ERC721("KnowMansLand", "Knowman") {
        setBaseURI(baseURI);
		creatorAddress = creator;
        pause(true);
    }
	
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
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
        uint256 total = TOTAL_MINTED_IN_PUBLIC_SALE;
        require(total + _count <= CURRENT_LIMIT_FOR_PUBLIC_SALE, "Max limit");
        require(total <= CURRENT_LIMIT_FOR_PUBLIC_SALE, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			TOTAL_MINTED_IN_PUBLIC_SALE++;
        }
    }
	
	function __mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = TOTAL_MINTED_IN_PRIVATE_SALE;
        require(total + _count <= NFT_FOR_PRIVATE_SALE, "Max limit");
        require(total <= NFT_FOR_PRIVATE_SALE, "Sale end");
		if (_msgSender() != owner()) {
		    require(_count <= MAX_BY_MINT, "Exceeds number");
            require(msg.value >= price(_count), "Value below price");
			require(isWhiteListed[_msgSender()], "Sender not whitelist to mint");
		}
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
			TOTAL_MINTED_IN_PRIVATE_SALE++;
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateKnowman(id);
    }
	
    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setCreatorAddress(address payable creator) public onlyOwner {
        creatorAddress = creator;
    }
	
	function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
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

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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
	
	function getWhiteListStatus(address _address) public view returns (bool) {
        return isWhiteListed[_address];
	}
	
	function whiteListAddress(address _address) public onlyOwner{
	   isWhiteListed[_address] = true;
	   emit AddToWhiteList(_address);
    }
	
	function removeWhiteListedAddress (address _address) public onlyOwner{
	   isWhiteListed[_address] = false;
	   emit RemovedFromWhiteList(_address);
	}
	
	function whiteListMultipleAddress(address[] calldata accounts) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
			isWhiteListed[accounts[i]] = true;
        }
        emit WhiteListMultipleAddress(accounts);
    }
	
	function removeWhiteListedMultipleAddress(address[] calldata accounts) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
			isWhiteListed[accounts[i]] = false;
        }
		emit RemoveWhiteListedMultipleAddress(accounts);
    }
	
	function updatePublicSaleLimit(uint256 newLimit) external onlyOwner {
        require(newLimit < NFT_FOR_PUBLIC_SALE, "bad value");
		require(CURRENT_LIMIT_FOR_PUBLIC_SALE < newLimit, "bad value");
        CURRENT_LIMIT_FOR_PUBLIC_SALE = newLimit;
        emit PublicSaleLimit(newLimit);
    }
}