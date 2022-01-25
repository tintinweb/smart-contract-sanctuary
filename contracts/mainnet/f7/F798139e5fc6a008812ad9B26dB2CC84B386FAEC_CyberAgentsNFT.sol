/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
// Created by petdomaa100

pragma solidity 0.8.11;


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

library Address {
	function isContract(address account) internal view returns(bool) {
		return account.code.length > 0;
	}
}

library Counters {
	struct Counter {
		uint256 _value;
	}


	function current(Counter storage counter) internal view returns(uint256) {
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		unchecked {
			counter._value += 1;
		}
	}

	function decrement(Counter storage counter) internal {
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");

		unchecked {
			counter._value = value - 1;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}


interface IERC165 {
	function supportsInterface(bytes4 interfaceID) external view returns(bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenID);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);

	function ownerOf(uint256 tokenID) external view returns(address owner);

	function safeTransferFrom(address from, address to, uint256 tokenID) external;

	function transferFrom(address from, address to, uint256 tokenID) external;

	function approve(address to, uint256 tokenID) external;

	function getApproved(uint256 tokenID) external view returns(address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns(bool);

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenID) external view returns(string memory);
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}


abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 
	constructor() {
		_transferOwnership(_msgSender());
	}


	function owner() public view virtual returns(address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}


	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");

		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;

		_owner = newOwner;

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceID) public view virtual override returns(bool) {
		return interfaceID == type(IERC165).interfaceId;
	}
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
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

	function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165, IERC165) returns(bool) {
		return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceID);
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
		address owner = ERC721.ownerOf(tokenID);
		require(to != owner, "ERC721: approval to current owner");

		require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

		_approve(to, tokenID);
	}

	function getApproved(uint256 tokenID) public view virtual override returns(address) {
		require(_exists(tokenID), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenID];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenID);
	}

	function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");

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

		require(_checkOnERC721Received(address(0), to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _mint(address to, uint256 tokenID) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenID), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenID);

		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(address(0), to, tokenID);

		_afterTokenTransfer(address(0), to, tokenID);
	}

	function _burn(uint256 tokenID) internal virtual {
		address owner = ERC721.ownerOf(tokenID);

		_beforeTokenTransfer(owner, address(0), tokenID);
		_approve(address(0), tokenID);

		_balances[owner] -= 1;
		delete _owners[tokenID];

		emit Transfer(owner, address(0), tokenID);

		_afterTokenTransfer(owner, address(0), tokenID);
	}

	function _transfer(address from, address to, uint256 tokenID) internal virtual {
		require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer from incorrect owner");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenID);
		_approve(address(0), tokenID);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(from, to, tokenID);

		_afterTokenTransfer(from, to, tokenID);
	}

	function _approve(address to, uint256 tokenID) internal virtual {
		_tokenApprovals[tokenID] = to;

		emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
	}

	function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
		require(owner != operator, "ERC721: approve to caller");
		
		_operatorApprovals[owner][operator] = approved;
		
		emit ApprovalForAll(owner, operator, approved);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns(bool) {
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenID, _data) returns(bytes4 retval) {
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

	function _afterTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}
}



contract CyberAgentsNFT is ERC721, Ownable {
	using Counters for Counters.Counter;
	using Strings for uint256;


	bool public paused;
	bool public revealed;

	string private unrevealedURI;
	string private baseURI;
	string private uriSuffix;
	
	uint256 public cost;
	uint256 public maxSupply;
	uint256 public freeToMintSupply;
	uint256 public maxMintAmountPerTX;

	Counters.Counter private supply;


	constructor(string memory _initUnrevealedURI) ERC721("Cyber Agents", "CA") {
		paused = true;
		revealed = false;

		cost = 0;
		maxSupply = 5555;
		freeToMintSupply = 555;
		maxMintAmountPerTX = 5;

		setURIsuffix(".json");
		setUnrevealedURI(_initUnrevealedURI);
	}


	function mint(uint256 amount) public payable {
		uint256 newSupply = supply.current() + amount;

		require(amount > 0 && amount <= maxMintAmountPerTX, "Invalid mint amount");
		require(newSupply <= maxSupply, "Max token supply exceeded");
		require(!paused, "Minting is paused");
		require(msg.value >= cost * amount, "Insufficient funds");


		_mintLoop(_msgSender(), amount);


		if (cost == 0 && newSupply >= freeToMintSupply) cost = 0.05 ether;
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) public onlyOwner {
		assert(addresses.length == amounts.length);
		assert(addresses.length > 0 && amounts.length > 0);


		uint256 totalAmount;
		for (uint256 i = 0; i < amounts.length; i++) totalAmount += amounts[0];

		uint256 newSupply = supply.current() + totalAmount;
		require(newSupply <= maxSupply, "Max token supply exceeded");


		for (uint256 i = 0; i < addresses.length; i++) {
			_mintLoop(addresses[i], amounts[i]);
		}


		if (cost == 0 && newSupply >= freeToMintSupply) cost = 0.07 ether;
	}

	function flipPausedState() public onlyOwner {
		paused = !paused;
	}

	function reveal(string memory _initBaseURI) public onlyOwner {
		revealed = true;

		setBaseURI(_initBaseURI);
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(owner()).call{ value: address(this).balance }("");
		require(success);
	}


	function totalSupply() public view returns(uint256) {
		return supply.current();
	}

	function tokenURI(uint256 tokenID) public view override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		if (!revealed) return unrevealedURI;


		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked(currentBaseURI, tokenID.toString(), uriSuffix) ) : "";
	}

	function walletOfOwner(address _address) public view returns(uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_address);

		uint256[] memory ownedTokenIDs = new uint256[](ownerTokenCount);


		uint256 tokenIndex = 1;
		uint256 ownedTokenIndex = 0;

		while (ownedTokenIndex < ownerTokenCount && tokenIndex <= maxSupply) {
			address owner = ownerOf(tokenIndex);

			if (owner == _address) {
				ownedTokenIDs[ownedTokenIndex] = tokenIndex;

				ownedTokenIndex++;
			}

			tokenIndex++;
		}


		return ownedTokenIDs;
	}


	function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

	function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
		unrevealedURI = newUnrevealedURI;
	}

	function setURIsuffix(string memory newSuffix) public onlyOwner {
		uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newAmount) public onlyOwner {
		maxSupply = newAmount;
	}

	function setFreeToMintSupply(uint256 newAmount) public onlyOwner {
		freeToMintSupply = newAmount;
	}

	function setMaxMintAmountPerTX(uint256 newAmount) public onlyOwner {
		maxMintAmountPerTX = newAmount;
	}

	function setCost(uint256 newCost) public onlyOwner {
		cost = newCost;
	}


	function _baseURI() internal view override returns(string memory) {
		return baseURI;
	}

	function _mintLoop(address to, uint256 amount) internal {
		for (uint256 i = 0; i < amount; i++) {
			supply.increment();

			_safeMint(to, supply.current());
		}
	}
}