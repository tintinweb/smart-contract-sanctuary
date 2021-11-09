/**
 *Submitted for verification at polygonscan.com on 2021-11-07
*/

pragma solidity ^0.8.2;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external payable;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract ERC721 is IERC721{
// contract ERC721 {

	mapping(address => uint256) internal _balances;
	mapping(uint256 => address) internal _owners;
	mapping(address => mapping(address => bool)) private _operatorApprovals;
	mapping(uint256 => address) private _tokenApprovals;

	function balanceOf(address _owner) override external view returns (uint256) {
		require(_owner != address(0), "NFTs assigned to the zero address are considered invalid");
		return _balances[_owner];
	}

	function ownerOf(uint256 _tokenId) override public view returns (address) {
		address owner = _owners[_tokenId];
		require(owner != address(0), "TokenId does not exist");
		return owner;
	}

	function setApprovalForAll(address _operator, bool _approved) override external {
		_operatorApprovals[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function isApprovedForAll(address _owner, address _operator) override public view returns (bool) {
		return _operatorApprovals[_owner][_operator];
	}

	function approve(address _approved, uint256 _tokenId) override public payable {
		address owner = ownerOf(_tokenId);
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Sender is not the owner or the approved operator");
		_tokenApprovals[_tokenId] = _approved;
		emit Approval(owner, _approved, _tokenId);
	}

	function getApproved(uint256 _tokenId) override public view returns (address) {
		require(_owners[_tokenId] != address(0), "Token ID does not exists");
		return _tokenApprovals[_tokenId];
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) override public payable {
		address owner = ownerOf(_tokenId);
		require(
			msg.sender == owner
			|| getApproved(_tokenId) == msg.sender
			|| isApprovedForAll(owner, msg.sender),
			"Sender is not the owner or approved for transfer"
		);
		require(owner == _from, "From address is not the owner");
		require(_to != address(0), "Address is zero");
		require(_owners[_tokenId] != address(0), "Token ID does not exists");

		approve(address(0), _tokenId);

		_balances[_from] -= 1;
		_balances[_to] += 1;
		_owners[_tokenId] = _to;

		emit Transfer(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override public payable {
		transferFrom(_from, _to, _tokenId);
		require(_checkOnERC721Received(), "Receiver not implemented");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	//Oversimplified
	// openzeppelin https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol#L382
	// https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721Receiver-onERC721Received-address-address-uint256-bytes-
	function _checkOnERC721Received() private pure returns(bool) {
		return true;
	}

	function supportsInterface(bytes4 interfaceId) public pure virtual returns(bool) {
		return interfaceId == 0x80ac58cd;
	}

}



// contract SuperMarioWorld is ERC721, IERC721Metadata {
contract SuperMarioWorld is ERC721 {

	string public name; //ERC721Metadata
	string public symbol; //ERC721Metadata
	uint256 public tokenCount; //ERC721Metadata

	mapping(uint256 => string) private _tokenURIs;

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
	}

	// Returns a URL that points to the metadata
	function tokenURI(uint256 tokenId) public view returns (string memory) {
		require(_owners[tokenId] != address(0), "TokenId does not exist");
		return _tokenURIs[tokenId];
	}

	// Creates a new NFT inside our collection
	function mint(string memory _tokenURI) public {
		tokenCount += 1; //tokenId
		_balances[msg.sender] += 1;
		_owners[tokenCount] = msg.sender;
		_tokenURIs[tokenCount] = _tokenURI;
		emit Transfer(address(0), msg.sender, tokenCount);
	}

	function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
		return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
	}
}