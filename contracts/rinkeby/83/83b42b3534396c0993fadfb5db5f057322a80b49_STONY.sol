// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract STONY is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_NFT = 10420;
    uint256 public constant PRICE = 42 * 10**16;
    uint256 public constant MAX_BY_MINT = 10;
	
	bool public cookingIsActive = false;
	
    address public creatorAddress;
    string public baseTokenURI;
	
    event CreateSTONY(uint256 indexed id);
	event EthDeposited(uint256 amount);
    event EthClaimed(address to, uint256 amount);
	event Cooked(uint256 firstTokenId, uint256 secondTokenId, uint256 cookedTokenId);
	
	mapping(uint256 => uint256) private _claimableEth;
	
    constructor(string memory baseURI, address payable creator) ERC721("Stoney Society", "STONY") {
        setBaseURI(baseURI);
		creatorAddress = creator;
        pause(true);
    }
	
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
        if (_msgSender() != owner() && !isWhiteListed[_msgSender()]) {
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
        require(total + _count <= MAX_NFT, "Max limit");
        require(total <= MAX_NFT, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= price(_count), "Value below price");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
	
	function __mint(address _to, uint256 _count) public saleIsOpen onlyOwner{
        uint256 total = _totalSupply();
         require(total <= MAX_NFT, "Sale end");
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateSTONY(id);
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
	
	function claim() public {
        uint256 amount = 0;
        uint256 numTokens = balanceOf(msg.sender);
        for(uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            amount += _claimableEth[tokenId];
            _claimableEth[tokenId] = 0;
        }
        require(amount > 0, "There is no amount left to claim");
        emit EthClaimed(msg.sender, amount);
		(bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
	
	 function claimableBalance(address owner) public view returns (uint256) {
        uint256 balance = 0;
        uint256 numTokens = balanceOf(owner);
        for(uint256 i = 0; i < numTokens; i++) {
            balance += claimableBalanceOfTokenId(tokenOfOwnerByIndex(owner, i));
        }
        return balance;
    }
	
	function claimableBalanceOfTokenId(uint256 tokenId) public view returns (uint256) {
        return _claimableEth[tokenId];
    }
	
	function deposit() public payable onlyOwner {
        uint256 tokenCount = totalSupply();
        uint256 claimableAmountPerToken = msg.value / tokenCount;
        for(uint256 i = 0; i < tokenCount; i++) {
            _claimableEth[tokenByIndex(i)] += claimableAmountPerToken;
        }
        emit EthDeposited(msg.value);
    }
	
	function cook(uint256 firstTokenId, uint256 secondTokenId) public {
	    require(cookingIsActive, "Cooking is inactive");
        require(_isApprovedOrOwner(_msgSender(), firstTokenId) && _isApprovedOrOwner(_msgSender(), secondTokenId), "Caller is not owner nor approved");
        
        _burn(firstTokenId);
        _burn(secondTokenId);

        uint256 cookedTokenId = _tokenIdTracker.current() + 1;
        _safeMint(msg.sender, cookedTokenId);
        _tokenIdTracker.increment();

        emit Cooked(firstTokenId, secondTokenId, cookedTokenId);
    }
	
	function flipCookingState() public onlyOwner {
        cookingIsActive = !cookingIsActive;
    }
    
}