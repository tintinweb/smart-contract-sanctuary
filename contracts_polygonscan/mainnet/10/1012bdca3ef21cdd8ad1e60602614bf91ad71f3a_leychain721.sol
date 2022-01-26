/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ERC721 {
	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) virtual external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) virtual external view returns (address);

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
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) virtual external payable;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) virtual external payable;

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
	function transferFrom(address _from, address _to, uint256 _tokenId) virtual external payable;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) virtual external payable;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) virtual external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) virtual external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) virtual external view returns (bool);

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
}

contract leychain721 is ERC721 {

	address public fundation;

	struct asset {
		uint256 _tokenId;
		address owner;
		address approver;
		uint256 timestamp;
        string _uri;
		bytes data;
	}

	event Mint(uint256 tokenId);

	mapping(address => uint256) balances;
	mapping(uint256 => asset) tokens;
	// mapping(uint256 => address) approves;
	mapping(address => mapping(address => bool)) isAllApproved;

	modifier onlyrun() {
		require(msg.sender == fundation);
		_;
	}

    constructor() {
        fundation = msg.sender;
    }

    function mint(string calldata _uri) external onlyrun {
        // 随机数生成
		uint256 tokenId = uint256(keccak256(abi.encodePacked(_uri)));

        require(tokenId != 0);
		require(tokens[tokenId]._tokenId != tokenId);

        asset memory Asset = asset(tokenId, msg.sender, address(0), block.timestamp, _uri, bytes(''));
		tokens[tokenId] = Asset;
        balances[msg.sender] += 1;


        emit Mint(tokenId);
    }

    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        require(_tokenId != 0);
        require(tokens[_tokenId]._tokenId == _tokenId);
        return tokens[_tokenId]._uri;
    }

	function setAsset(uint256 number, address owner, bytes memory data) onlyrun public {
		// require(owner != address(0));

		// // 随机数生成
		// uint256 tokenId = uint256(keccak256(abi.encodePacked(number, msg.sender, block.timestamp, owner, data)));

		// // require(tokens[tokenId] == asset(0, address(0), address(0), 0, bytes("")));
		// require(tokenId != 0);
		// require(tokens[tokenId]._tokenId != tokenId);

		// // asset memory Asset = asset(tokenId, owner, address(0), block.timestamp, data);

		// tokens[tokenId] = Asset;
	}

	function balanceOf(address _owner) override external view returns (uint256) {
		require(_owner != address(0));
		return balances[_owner];
	}

	function ownerOf(uint256 _tokenId) override external view returns (address) {
		require(_tokenId != 0);
		return tokens[_tokenId].owner;
	}

	function approve(address _approved, uint256 _tokenId) override external payable {
		require(tokens[_tokenId].owner == msg.sender);
		require(_tokenId != 0);
		tokens[_tokenId].approver = _approved;

        emit Approval(_approved, msg.sender, _tokenId);
	}

	function getApproved(uint256 _tokenId) override external view returns (address) {
		require(_tokenId != 0);
		return tokens[_tokenId].approver;
	}


	function setApprovalForAll(address _operator, bool _approved) override external {

		require(_operator != address(0));
		require(isAllApproved[msg.sender][_operator] != _approved);
		isAllApproved[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
		require(_owner != address(0) || _operator != address(0));
		return isAllApproved[_owner][_operator];
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
		require(_from != address(0) && _to != address(0) && _tokenId != 0);
		require(tokens[_tokenId].owner == _from);
		require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllApproved[_from][_to]);
		tokens[_tokenId].owner = _to;
		tokens[_tokenId].approver = address(0);
		tokens[_tokenId].timestamp = block.timestamp;
		tokens[_tokenId].data = bytes("");
		balances[_from] -= 1;
		balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
	}
	
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable {
		require(_from != address(0) && _to != address(0) && _tokenId != 0);
		require(addrCheck(_to));
		require(tokens[_tokenId].owner == _from);
		require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllApproved[_from][_to]);
		tokens[_tokenId].owner = _to;
		tokens[_tokenId].approver = address(0);
		tokens[_tokenId].timestamp = block.timestamp;
		tokens[_tokenId].data = data;
		balances[_from] -= 1;
		balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
	}


	function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
		require(_from != address(0) && _to != address(0) && _tokenId != 0);
		require(addrCheck(_to));
		require(tokens[_tokenId].owner == _from);
		require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllApproved[_from][_to]);
		tokens[_tokenId].owner = _to;
		tokens[_tokenId].approver = address(0);
		tokens[_tokenId].timestamp = block.timestamp;
		tokens[_tokenId].data = bytes("");
		balances[_from] -= 1;
		balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
	}

	// true account, false contract
	function addrCheck(address _addr) private view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_addr)
		}

		require(size == 0);
		return true;
	}
}