/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

/*
VERSION DATE: 24/03/2021
*/

library Address 
{
    function isContract(address account) internal view returns (bool)
	{
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library Strings
{
    function toString(uint256 value) internal pure returns (string memory)
	{
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0)
		{
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0)
		{
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

abstract contract Context
{
    function _msgSender() internal view virtual returns (address)
	{
        return msg.sender;
    }
}

interface IERC165
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165
{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
	{
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165
{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Enumerable is IERC721
{
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721
{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver
{
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract ERC721Full is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable, IERC721Receiver
{
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    string private _baseTokenURI;
	
    mapping (uint256 => address) private _owners;			// Mapping from token ID to owner address
    mapping (address => uint256) private _balances;			// Mapping owner address to token count
    mapping (uint256 => address) private _tokenApprovals;	// Mapping from token ID to approved address
    mapping (address => mapping (address => bool)) private _operatorApprovals;	// Mapping from owner to operator approvals

	uint256[] private _allTokens;							// Array with all token ids, used for enumeration
    mapping(uint256 => uint256) private _allTokensIndex;	// Mapping from token id to position in the allTokens array

	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;	// Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) private _ownedTokensIndex;	// Mapping from token ID to index of the owner tokens list

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_)
	{
		_name = name_;
		_symbol = symbol_;
		_baseTokenURI = baseTokenURI_;
    }

	function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes calldata _data )
		external pure override returns(bytes4)
	{
		_operator;
		_from;
		_tokenId;
		_data;
		return 0x150b7a02;
	}
	
	// 0x01ffc9a7 = ERC165
	// 0x80ac58cd = ERC721
	// 0x780e9d63 = ERC721Enumerable
	// 0x5b5e139f = ERC721Metadata
	// 0x150b7a02 = ERC721Receiver
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool)
	{
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override returns (uint256)
	{
		return _allTokens.length;
	}

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId)
	{
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
	}

    function tokenByIndex(uint256 index) public view virtual override returns (uint256)
	{
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
	}

    function balanceOf(address owner) public view virtual override returns (uint256)
	{
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address)
	{
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory)
	{
        return _name;
    }

    function symbol() public view virtual override returns (string memory)
	{
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function _baseURI() internal view virtual returns (string memory)
	{
        return _baseTokenURI;
    }

    function approve(address to, uint256 tokenId) public virtual override
	{
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address)
	{
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override
	{
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
	{
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override
	{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override
	{
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override
	{
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual
	{
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool)
	{
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool)
	{
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual
	{
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual
	{
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual
	{
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual
	{
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        if (_tokenApprovals[tokenId] != address(0)) _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual
	{
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
    {
        if (to.isContract()) 
		{
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
		else 
		{
            return true;
        }
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual
	{
		require( to != address(0), "forbidden transfer to address(0)" );
		require( from != to, "from equal to" );
		
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
		
		_addTokenToOwnerEnumeration(to, tokenId);
    }
	
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private
	{
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
	
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private
	{
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private
	{
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

}
 
abstract contract CheckAccess 
{
	function isAdmin(address addr) public virtual view returns (bool);
}

contract MultiHandler is ERC721Full
{
	using Strings for uint256;
    using Address for address;
	address checkAccessContract;
	
	struct Type
	{
        string name;
        string URI;
        string IPFSHash;
        uint issuedCount;
		uint minBound;
		uint maxBound;
    }

	Type[] typesById;

	uint public endPoint = 0;
	
	mapping (uint256 => uint256) public tokenType; // idToken => idType
	mapping (uint64 => bool) public nonces;
	
    constructor(
		string memory _name,
		string memory _symbol,
		string memory _tokenURI,
		address _checkAccessContract
	) ERC721Full(_name, _symbol, _tokenURI) 
	{
		checkAccessContract = _checkAccessContract;
		
		require(checkAccessContract.isContract(), "checkAccessContract is not found");
	}
	
	event CreateType(uint typeId, string name, uint count, uint min, uint max);
	
	function checkAdmin(address addr) public view returns (bool)
	{
		CheckAccess check = CheckAccess(checkAccessContract);
		return( check.isAdmin(addr) );
	}

	modifier onlyAdmin()
	{
		require( checkAdmin(_msgSender()), "wrong admin" );
		_;
	}
	
	function createType(
		string memory _name,
		string memory _uri,
		string memory _ipfs,
		uint _startPoint,
		uint _count) public onlyAdmin
	{
		require( bytes(_name).length >= 3, "wrong length" );
		require( bytes(_ipfs).length >= 3, "wrong length" );
		require( _count > 0, "count must not be zero" );
		require( _startPoint > endPoint, "wrong startPoint" );
		
		uint id = typesById.length;
		if ( bytes(_uri).length == 0 ) _uri = _baseURI();

		uint minBound = _startPoint;
		uint maxBound = _startPoint + _count - 1;
		endPoint = maxBound;
		
		Type memory _type = Type({
			name: _name,
			URI: _uri,
			IPFSHash: _ipfs,
			issuedCount: 0,
			minBound: minBound,
			maxBound: maxBound
		});

		typesById.push( _type );
		
		emit CreateType(id, _name, _count, minBound, maxBound);
	}

	function getTypeById(uint256 typeId) public view returns (
		string memory name,
		string memory URI,
		string memory IPFSHash,
		uint maxCount,
		uint issuedCount,
		uint minBound,
		uint maxBound
	){
		require( typeId < typesById.length, "query for nonexistent type" );
		
		name = typesById[typeId].name;
		URI = typesById[typeId].URI;
		IPFSHash = typesById[typeId].IPFSHash;
		maxCount = typesById[typeId].maxBound - typesById[typeId].minBound + 1;
		issuedCount = typesById[typeId].issuedCount;
		minBound = typesById[typeId].minBound;
		maxBound = typesById[typeId].maxBound;
	}
	
    function tokenURI(uint256 tokenId) public view override returns (string memory)
	{
        require(_exists(tokenId), "query for nonexistent token");
		uint typeId = tokenType[tokenId];
		return string(abi.encodePacked( typesById[typeId].URI, tokenId.toString()));
    }
	
	function tokenIPFSHash(uint256 tokenId) public view returns (string memory hash)
	{
		require(_exists(tokenId), "query for nonexistent token");
		uint typeId = tokenType[tokenId];
		return typesById[typeId].IPFSHash;
	}
	
	function issueToken(address addr, uint typeId, uint256 tokenId) internal
	{
		require( typeId < typesById.length, "query for nonexistent type" );
		
		require( tokenId >= typesById[typeId].minBound, "min overrun" );
		require( tokenId <= typesById[typeId].maxBound, "max overrun" );
		
		if (_exists(tokenId))
		{
			_transfer(address(this), addr, tokenId);
		}
		else
		{
			tokenType[tokenId] = typeId;
			
			typesById[typeId].issuedCount++;
			
			_mint(addr, tokenId);
		}
	}
	
	function giveTokenTo(address to, uint typeId, uint tokenId) public onlyAdmin
	{
		issueToken(to, typeId, tokenId);
	}
	
	function giveTokens(address[] memory addrs, uint typeId, uint[] memory idTokens) public onlyAdmin
	{
		require(addrs.length>0, "length is 0");
		require(addrs.length == idTokens.length, "arrays are not equal");
		
		uint count = addrs.length;
		for(uint i = 0; i < count; i++) 
		{
			issueToken(addrs[i], typeId, idTokens[i]);
        }
    }
	
	function takeToken(uint256 typeId, uint256 tokenId, uint64 nonce, bytes32 r, bytes32 s, uint8 v) public
	{
		bytes memory prefix = "\x19Ethereum Signed Message:\n32";
		bytes32 hash = keccak256( abi.encodePacked(address(this), _msgSender(), nonce, typeId, tokenId) );
        address signer = ecrecover(keccak256(abi.encodePacked(prefix,hash)), v, r, s);

		require( nonces[nonce] == false, "wrong nonce" );
		nonces[nonce] = true;

		require( checkAdmin(signer), "wrong admin" );
		
		issueToken(_msgSender(), typeId, tokenId);
	}
}