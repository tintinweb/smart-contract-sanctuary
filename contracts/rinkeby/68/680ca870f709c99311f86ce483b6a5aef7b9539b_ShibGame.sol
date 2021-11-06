// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ERC721Pausable.sol";

contract ShibGame is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
	
	struct Minter {
       uint256 mintLimit;
       uint256 minted;
    }
	
	mapping(address => Minter) public minter;
	
    uint256 public MAX_NFT;
	uint256 public NFT_ASSIGNED;
    uint256 public MAX_BY_MINT;
	uint256 public PRICE;
	uint256 public START_TIME;
	uint256 public END_TIME;
	
    string public baseTokenURI;
	
    event CreateShibGame(uint256 indexed id);
	event AddToWhiteList(address account, uint256 count);
    event RemovedFromWhiteList(address account);
	event WhiteListMultipleAddress(address[] accounts, uint256[] count);
    event RemoveWhiteListedMultipleAddress(address[] accounts);
    
    mapping (address => bool) public isWhiteListed;
	
    constructor(string memory baseURI, uint256 maxNFT, uint256 maxByMint, uint256 Price, uint256 startTime, uint256 endTime) ERC721("Shib Game", "SG") {
        MAX_NFT = maxNFT;
		MAX_BY_MINT = maxByMint;
		PRICE = Price;
		START_TIME = startTime;
		END_TIME = endTime;
		setBaseURI(baseURI);
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
	
    function mint(uint256 _count) public saleIsOpen {
        uint256 total = _totalSupply();
        require(total.add(_count) <= MAX_NFT, "Max limit");
        require(total <= MAX_NFT, "Sale end");
		require(START_TIME <= block.timestamp, "Mint after start time");
		require(block.timestamp <= END_TIME, "Mint before end time");
		require(minter[_msgSender()].minted.add(_count) <= minter[_msgSender()].mintLimit, "Exceeds number");
		
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_msgSender());
			minter[_msgSender()].minted++;
        }
    }
	
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateShibGame(id);
    }
	
    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
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
	
	function updatePrice(uint256 newPrice) external onlyOwner {
        PRICE = newPrice;
    }
	
	function updateMintLimit(uint256 newLimit) external onlyOwner {
	    require(MAX_NFT >= newLimit, "Incorrect value");
        MAX_BY_MINT = newLimit;
    }
	
	function updateMaxSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply > _totalSupply(), "Incorrect value");
		require(newSupply >= NFT_ASSIGNED, "Incorrect value");
        MAX_NFT = newSupply;
    }
	
	function whitelistAddress(address account, uint256 count) public onlyOwner{
	   require(NFT_ASSIGNED.sub(minter[account].mintLimit).add(count) <= MAX_NFT, "Exceeds number");
	   require(minter[account].minted <= count, "Exceeds number");
	   if(account != owner()) {
		   require(count <= MAX_BY_MINT, "Exceeds number");
	   }
	   isWhiteListed[account] = true;
	   NFT_ASSIGNED = NFT_ASSIGNED.sub(minter[account].mintLimit).add(count);
	   minter[account].mintLimit = count;
	   
	   emit AddToWhiteList(account, count);
    }
	
	function removeFromWhiteList(address account) public onlyOwner{
	   require(isWhiteListed[account], 'Incorrect minter'); 
	   
	   isWhiteListed[account] = false;
	   NFT_ASSIGNED = NFT_ASSIGNED.sub(minter[account].mintLimit).add(minter[account].minted);
	   minter[account].mintLimit = minter[account].minted;
	   
	   emit RemovedFromWhiteList(account);
	}
	
	function whiteListMultipleAddress(address[] calldata accounts, uint256[] calldata count) public onlyOwner {
	    require(accounts.length==count.length, 'Incorrect mapping'); 
        for(uint256 i = 0; i < accounts.length; i++){
		
		   require(NFT_ASSIGNED.sub(minter[accounts[i]].mintLimit).add(count[i]) <= MAX_NFT, "Exceeds number");
		   require(minter[accounts[i]].minted <= count[i], "Exceeds number");
		   if(accounts[i] != owner()){
			   require(count[i] <= MAX_BY_MINT, "Exceeds number");
		   }
		   isWhiteListed[accounts[i]] = true;
		   NFT_ASSIGNED = NFT_ASSIGNED.sub(minter[accounts[i]].mintLimit).add(count[i]);
		   minter[accounts[i]].mintLimit = count[i];
        }
        emit WhiteListMultipleAddress(accounts, count);
    }
	
	function removeWhiteListedMultipleAddress(address[] calldata accounts) public onlyOwner {
		for(uint256 i = 0; i < accounts.length; i++){
			require(isWhiteListed[accounts[i]], 'Incorrect minter'); 
		    isWhiteListed[accounts[i]] = false;
		    NFT_ASSIGNED = NFT_ASSIGNED.sub(minter[accounts[i]].mintLimit).add(minter[accounts[i]].minted);
		    minter[accounts[i]].mintLimit = minter[accounts[i]].minted;
        }
		emit RemoveWhiteListedMultipleAddress(accounts);
    }
	
	function updateMintTime(uint256 startTime, uint256 endTime) external onlyOwner {
	    require(startTime < endTime, "Incorrect time");
        START_TIME = startTime;
		END_TIME = endTime;
    }
	
	function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}