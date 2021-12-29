/**
 *Submitted for verification at snowtrace.io on 2021-12-28
*/

// SPDX-License-Identifier: MIT
// Created by petdomaa100

pragma solidity 0.8.11;


library Address {
	function isContract(address account) internal view returns(bool) {
		uint256 size;

		assembly {
			size := extcodesize(account)
		}

		return size > 0;
	}
}

library Strings {
	function toString(uint256 value) internal pure returns(string memory) {
		if (value == 0) return "0";

		uint256 temp = value;
		uint256 digits;

		while (temp != 0) {
			digits++;
			temp /= 10;
		}

		bytes memory buffer = new bytes(digits);

		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}

		return string(buffer);
	}
}


interface IERC165 {
	function supportsInterface(bytes4 interfaceId) external view returns(bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


	function balanceOf(address owner) external view returns(uint256 balance);

	function ownerOf(uint256 tokenId) external view returns(address owner);

	function safeTransferFrom(address from, address to, uint256 tokenId) external;

	function transferFrom(address from, address to, uint256 tokenId) external;

	function approve(address to, uint256 tokenId) external;

	function getApproved(uint256 tokenId) external view returns(address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns(bool);

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenId) external view returns(string memory);
}

interface IERC721Enumerable is IERC721 {
	function totalSupply() external view returns(uint256);

	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256 tokenId);

	function tokenByIndex(uint256 index) external view returns(uint256);
}

abstract contract Ownable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	constructor() {
		_owner = msg.sender;
	}

	function owner() public view virtual returns(address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == msg.sender, "Ownable: Caller is not the owner");
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: New owner is the zero address");

		address oldOwner = _owner;
		_owner = newOwner;

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
		return interfaceId == type(IERC165).interfaceId;
	}
}

abstract contract ERC721 is ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	string private _name;
	string private _symbol;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;


	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}


	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns(bool) {
		return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");

		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];

		require(owner != address(0), "ERC721: owner query for nonexistent token");

		return owner;
	}

	function name() public view virtual override returns(string memory) {
		return _name;
	}

	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();

		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
	}

	function _baseURI() internal view virtual returns(string memory) {
		return "";
	}

	function approve(address to, uint256 tokenID) public virtual override {
		address tokenOwner = ERC721.ownerOf(tokenID);

		require(to != tokenOwner, "ERC721: Approval to current owner");
		require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: Approve caller is not owner nor approved for all");

		_approve(to, tokenID);
	}

	function getApproved(uint256 tokenId) public view virtual override returns(address) {
		require(_exists(tokenId), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenId];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(operator != msg.sender, "ERC721: approve to caller");

		_operatorApprovals[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenID);
	}

	function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(msg.sender, tokenID), "ERC721: transfer caller is not owner nor approved");

		_safeTransfer(from, to, tokenID, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
		_transfer(from, to, tokenID);

		require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _exists(uint256 tokenID) internal view virtual returns(bool) {
		return _owners[tokenID] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenID) internal view virtual returns(bool) {
		require(_exists(tokenID), "ERC721: operator query for nonexistent token");

		address owner = ERC721.ownerOf(tokenID);

		return (spender == owner || getApproved(tokenID) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenID) internal virtual {
		_safeMint(to, tokenID, "");
	}

	function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
		_mint(to, tokenID);

		require(
			_checkOnERC721Received(address(0), to, tokenID, _data),
			"ERC721: transfer to non ERC721Receiver implementer"
		);
	}

	function _mint(address to, uint256 tokenID) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenID), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenID);

		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(address(0), to, tokenID);
	}

	function _burn(uint256 tokenID) internal virtual {
		address owner = ERC721.ownerOf(tokenID);

		_beforeTokenTransfer(owner, address(0), tokenID);
		_approve(address(0), tokenID);

		_balances[owner] -= 1;
		delete _owners[tokenID];

		emit Transfer(owner, address(0), tokenID);
	}

	function _transfer(address from, address to, uint256 tokenID) internal virtual {
		require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer of token that is not own");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenID);
		_approve(address(0), tokenID);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(from, to, tokenID);
	}

	function _approve(address to, uint256 tokenID) internal virtual {
		_tokenApprovals[tokenID] = to;

		emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns(bool) {
		if ( to.isContract() ) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenID, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) revert("ERC721: transfer to non ERC721Receiver implementer");

				else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}
		
		else return true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
	mapping(uint256 => uint256) private _ownedTokensIndex;

	uint256[] private _allTokens;
	mapping(uint256 => uint256) private _allTokensIndex;


	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns(bool) {
		return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

		return _ownedTokens[owner][index];
	}

	function totalSupply() public view virtual override returns(uint256) {
		return _allTokens.length;
	}

	function tokenByIndex(uint256 index) public view virtual override returns(uint256) {
		require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");

		return _allTokens[index];
	}

	function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) _addTokenToAllTokensEnumeration(tokenId);

		else if (from != to) _removeTokenFromOwnerEnumeration(from, tokenId);

		if (to == address(0)) _removeTokenFromAllTokensEnumeration(tokenId);

		else if (to != from) _addTokenToOwnerEnumeration(to, tokenId);
	}

	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		uint256 length = ERC721.balanceOf(to);

		_ownedTokens[to][length] = tokenId;
		_ownedTokensIndex[tokenId] = length;
	}

	function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
		_allTokensIndex[tokenId] = _allTokens.length;
		_allTokens.push(tokenId);
	}

	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
		uint256 tokenIndex = _ownedTokensIndex[tokenId];

		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

			_ownedTokens[from][tokenIndex] = lastTokenId;
			_ownedTokensIndex[lastTokenId] = tokenIndex;
		}

		delete _ownedTokensIndex[tokenId];
		delete _ownedTokens[from][lastTokenIndex];
	}

	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
		uint256 lastTokenIndex = _allTokens.length - 1;
		uint256 tokenIndex = _allTokensIndex[tokenId];

		uint256 lastTokenId = _allTokens[lastTokenIndex];

		_allTokens[tokenIndex] = lastTokenId;
		_allTokensIndex[lastTokenId] = tokenIndex;

		delete _allTokensIndex[tokenId];
		_allTokens.pop();
	}
}



contract VendingMachinesNFT is ERC721Enumerable, Ownable {
	string private baseURI;
	string private unrevealedURI;

	bool public paused;
	bool public revealed;
	bool public whitelistOnly;

	uint256 public cost;
	uint256 public maxSupply;
	uint256 public reservedSupply;
	uint256 public mintsPerAddressLimit;

	address[] private whitelistedAddresses;

	mapping(address => uint16) private mintsPerAddress;

	uint256 public mintRewards;
	uint256 public salesRewards;
	uint256 public totalMintRewardsVault;
	uint256 public totalSalesRewardsVault;

	mapping(address => uint256) private mintRewardsVault;
	mapping(address => uint256) private salesRewardsVault;

	address private payoutAddress;
	address private vaultAddress1;
	address private vaultAddress2;

	struct Listing {
		uint256 tokenID;
		uint256 price;
		address seller;
	}

	Listing[] private listings;

	event NewListing(uint256 indexed tokenID);
	event TokenSold(uint256 indexed tokenID, address indexed from, address indexed to, uint256 price);
	event ClaimedRewards(address indexed wallet, uint256 amount, uint8 indexed rewardType);


	constructor(string memory _initbaseURI, string memory _initunrevealedURI, address _payoutAddress, address _vaultAddress1, address _vaultAddress2) ERC721("Vending Machines NFT", "VM") {
		cost = 2 ether;
		maxSupply = 4444;
		reservedSupply = 444;
		mintsPerAddressLimit = 5;
		paused = true;
		revealed = false;
		whitelistOnly = true;

		mintRewards = 10;
		salesRewards = 30;

		payoutAddress = _payoutAddress;
		vaultAddress1 = _vaultAddress1;
		vaultAddress2 = _vaultAddress2;

		setBaseURI(_initbaseURI);
		setUnrevealedURI(_initunrevealedURI);
	}


	function mint(uint8 amount) public payable {
		assert(amount > 0);
		require(!paused, "Minting is currently disabled!");


		uint256 supply = totalSupply();
		uint256 newSupply = supply + amount;

		require(newSupply <= maxSupply, "Number of tokens exceeded max supply!");
		require(newSupply <= maxSupply - reservedSupply, "The rest of the available tokens are reserved!");

		if (whitelistOnly) {
			require(isAddressWhitelisted(msg.sender) == true, "Currently, minting is restricted to whitelisted addresses only!");
		}


		if (msg.sender != owner()) {
			require(getNumberOfMintsOfAddress(msg.sender) + amount <= mintsPerAddressLimit, "Exceeded maximum mints per address!");
			require(amount <= mintsPerAddressLimit, "Mint amount must be less than or equal to the max mint amount!");
			require(msg.value >= cost * amount, "Not enough value sent!");
		}


		for (uint8 i = 1; i <= amount; i++) {
			_safeMint(msg.sender, supply + i);
		}

		mintsPerAddress[msg.sender] += amount;


		uint256 individualMintRewardValue = (msg.value * mintRewards / 100) / newSupply;
		uint256 mintRewardValue = individualMintRewardValue * newSupply;

		for (uint16 i = 1; i <= newSupply; i++) {
			address owner = ownerOf(i);

			mintRewardsVault[owner] += individualMintRewardValue;
		}

		totalMintRewardsVault += mintRewardValue;
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) public payable onlyOwner {
		assert(addresses.length > 0 && amounts.length > 0);
		assert(addresses.length == amounts.length);


		uint16 totalAmount;
		uint256 supply = totalSupply();

		for (uint256 i = 0; i < amounts.length; i++) totalAmount += amounts[0];

		require(supply + totalAmount <= maxSupply, "Number of tokens exceeded max supply!");


		for (uint8 i = 0; i < addresses.length; i++) {
			uint8 amount = amounts[i];
			address _address = addresses[i];

			for (uint8 I = 1; I <= amount; I++) {
				_safeMint(_address, supply + i + I);
			}
		}
	}

	function flipPausedState() public onlyOwner {
		paused = !paused;
	}

	function reveal() public onlyOwner {
		revealed = true;
	}

	function endPresale(uint256 newCost) public onlyOwner {
		whitelistOnly = false;
		cost = newCost;
	}

	function claimMintRewards() public payable {
		uint256 reward = mintRewardsVault[msg.sender];

		require(reward > 0, "You don't have any rewards that you could collect!");


		(bool os, ) = payable(msg.sender).call{value: reward}("");
		require(os, "Failed to transfer funds!");

		delete mintRewardsVault[msg.sender];
		totalMintRewardsVault -= reward;

		emit ClaimedRewards(msg.sender, reward, 1);
	}

	function claimSalesRewards() public payable {
		uint256 reward = salesRewardsVault[msg.sender];

		require(reward > 0, "You don't have any rewards that you could collect!");


		(bool os, ) = payable(msg.sender).call{value: reward}("");
		require(os, "Failed to transfer funds!");

		delete salesRewardsVault[msg.sender];
		totalSalesRewardsVault -= reward;

		emit ClaimedRewards(msg.sender, reward, 2);
	}

	function withdraw() public payable onlyOwner {
		uint256 totalRewards = totalMintRewardsVault + totalSalesRewardsVault;
		uint256 balance_10percent = (address(this).balance - totalRewards) * 10 / 100;

		(bool hs1, ) = payable(payoutAddress).call{value: balance_10percent}("");
		require(hs1, "Failed to transfer funds to payout wallet!");

		(bool hs2, ) = payable(vaultAddress1).call{value: balance_10percent}("");
		require(hs2, "Failed to transfer funds to vault wallet #1!");

		(bool hs3, ) = payable(vaultAddress2).call{value: balance_10percent}("");
		require(hs3, "Failed to transfer funds to vault wallet #2!");


		(bool os, ) = payable(owner()).call{value: address(this).balance - totalRewards}("");
		require(os, "Failed to transfer funds to owner wallet!");
	}

	function emergencyWithdraw() public payable onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os, "Failed to transfer funds!");
	}


	function safeTransferFrom(address from, address to, uint256 tokenID) public override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public override {
		(bool isListed, ) = isTokenListed(tokenID);
		require(!isListed, "ERC721 Marketplace: Unable to transfer a listed token");

		super.safeTransferFrom(from, to, tokenID, _data);
	}

	function createListing(uint256 tokenID, uint256 price) public {
		require(price > 0, "ERC721 Marketplace: Listing price must be more than 0");
		require(ownerOf(tokenID) == msg.sender, "ERC721 Marketplace: Caller is not the owner");

		Listing memory sale = Listing({
			tokenID: tokenID,
			price: price,
			seller: msg.sender
		});

		listings.push(sale);


		emit NewListing(tokenID);
	}

	function withdrawListing(uint256 tokenID) public {
		(bool isListed, uint256 listingIndex) = isTokenListed(tokenID);

		require(isListed, "ERC721 Marketplace: Token is not listed");
		require(listings[listingIndex].seller == msg.sender, "ERC721 Marketplace: Caller is not the owner");

		listings[listingIndex] = listings[listings.length - 1];
		listings.pop();
	}

	function fulfillListing(uint256 tokenID) public payable {
		(bool isListed, uint256 listingIndex) = isTokenListed(tokenID);

		require(isListed, "ERC721 Marketplace: Token is not listed");


		Listing memory listing = listings[listingIndex];

		require(listing.seller != msg.sender, "ERC721 Marketplace: Buyer and seller must be be different addresses");
		require(msg.value >= listing.price, "ERC721 Marketplace: Transaction value must be equal or bigger than the listing price");


		uint256 supply = totalSupply();
		uint256 individualsalesRewardValue = (msg.value * salesRewards / 100) / supply;
		uint256 salesRewardValue = individualsalesRewardValue * supply;


		(bool success, ) = payable(listing.seller).call{ value: msg.value - salesRewardValue }("");
		require(success, "ETH Transaction: Failed to transfer funds");


		listings[listingIndex] = listings[listings.length - 1];
		listings.pop();


		for (uint256 i = 1; i <= supply; i++) {
			address owner = ownerOf(i);

			salesRewardsVault[owner] += individualsalesRewardValue;
		}

		totalSalesRewardsVault += salesRewardValue;


		emit TokenSold(tokenID, listing.seller, msg.sender, msg.value);

		_approve(msg.sender, tokenID);
		safeTransferFrom(listing.seller, msg.sender, tokenID);
	}

	function isTokenListed(uint256 tokenID) public view returns(bool, uint256) {
		bool isListed = false;
		uint256 index;

		for (uint256 i = 0; i < listings.length; i++) {
			if (listings[i].tokenID != tokenID) continue;

			isListed = true;
			index = i;
		}

		return (isListed, index);
	}

	function getListings() public view returns(Listing[] memory) {
		return listings;
	}


	function _baseURI() internal view virtual override returns(string memory) {
		return baseURI;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721 Metadata: URI query for nonexistent token!");

		if (!revealed) return unrevealedURI;

		return string( abi.encodePacked(baseURI, Strings.toString(tokenID), ".json") );
	}

	function walletOfOwner(address _address) public view returns(uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_address);
		uint256[] memory tokenIDs = new uint256[](ownerTokenCount);

		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIDs[i] = tokenOfOwnerByIndex(_address, i);
		}

		return tokenIDs;
	}

	function getNumberOfMintsOfAddress(address _address) public view returns(uint16) {
		return mintsPerAddress[_address];
	}

	function isAddressWhitelisted(address _address) public view returns(bool) {
		if (_address == owner()) return true;

		for (uint16 i = 0; i < whitelistedAddresses.length; i++) {
			if (whitelistedAddresses[i] == _address) return true;
		}

		return false;
	}

	function getMintRewardsOfAddress(address _address) public view returns(uint256) {
		return mintRewardsVault[_address];
	}

	function getSalesRewardsOfAddress(address _address) public view returns(uint256) {
		return salesRewardsVault[_address];
	}


	function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

	function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
		unrevealedURI = newUnrevealedURI;
	}

	function setMaxSupply(uint256 newAmount) public onlyOwner {
		maxSupply = newAmount;
	}

	function setReservedSupply(uint256 newAmount) public onlyOwner {
		reservedSupply = newAmount;
	}

	function setCost(uint256 newCost) public onlyOwner {
		cost = newCost;
	}

	function setMintsPerAddressLimit(uint256 newLimit) public onlyOwner {
		mintsPerAddressLimit = newLimit;
	}

	function getWhitelistedAddresses() public view onlyOwner returns(address[] memory) {
		return whitelistedAddresses;
	}

	function setWhitelistedAddresses(address[] calldata addresses) public onlyOwner {
		delete whitelistedAddresses;

		whitelistedAddresses = addresses;
	}

	function setMintRewards(uint256 percentage) public onlyOwner {
		mintRewards = percentage;
	}

	function setSalesRewards(uint256 percentage) public onlyOwner {
		salesRewards = percentage;
	}

	function setWithdrawAddresses(address newPayoutAddress, address newVaultAddress1, address newVaultAddress2) public onlyOwner {
		payoutAddress = newPayoutAddress;
		vaultAddress1 = newVaultAddress1;
		vaultAddress2 = newVaultAddress2;
	}

	function resetRewards(address[] calldata addresses) public onlyOwner {
		for (uint16 i = 0; i < addresses.length; i++) {
			address _address = addresses[i];

			delete mintRewardsVault[_address];
			delete salesRewardsVault[_address];
		}

		totalMintRewardsVault = 0;
		totalSalesRewardsVault = 0;
	}
}