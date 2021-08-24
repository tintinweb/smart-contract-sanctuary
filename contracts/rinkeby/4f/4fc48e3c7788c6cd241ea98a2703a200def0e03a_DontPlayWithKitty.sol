/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity >=0.5.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

library Strings {
	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d,
		string memory _e
	) internal pure returns (string memory) {
		bytes memory _ba = bytes(_a);
		bytes memory _bb = bytes(_b);
		bytes memory _bc = bytes(_c);
		bytes memory _bd = bytes(_d);
		bytes memory _be = bytes(_e);
		string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
		bytes memory babcde = bytes(abcde);
		uint256 k = 0;
		for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
		for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
		for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
		for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
		for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
		return string(babcde);
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c,
		string memory _d
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, _d, "");
	}

	function strConcat(
		string memory _a,
		string memory _b,
		string memory _c
	) internal pure returns (string memory) {
		return strConcat(_a, _b, _c, "", "");
	}

	function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
		return strConcat(_a, _b, "", "", "");
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len - 1;
		while (_i != 0) {
			bstr[k--] = bytes1(uint8(48 + (_i % 10)));
			_i /= 10;
		}
		return string(bstr);
	}
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == owner;
    }
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, IERC165, IERC721, IERC721Metadata {
    using Address for address;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721METADATA = 0x5b5e139f;
    bytes4 constant private INTERFACE_SIGNATURE_ERC721ENUMERABLE = 0x780e9d63;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        if (
            _interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC721 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC721METADATA ||
            _interfaceId == INTERFACE_SIGNATURE_ERC721ENUMERABLE
            ) {
                return true;
            }
        return false;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view  returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, _data);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, _data);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    bytes4 constant internal ERC721_RECEIVED_VALUE = 0xf0b9e5ba; 
    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private{
        if (to.isContract()) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
            require(retval == ERC721_RECEIVED_VALUE, "ERC721: INVALID_ON_RECEIVE_MESSAGE");
        }
            
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

contract Random {
    uint256 radex = 66;
    
    function _random (uint256 range, uint256 time, bytes32 data) internal view returns (uint256) {
        uint256 key = uint256(keccak256(abi.encodePacked(blockhash(block.number), radex, uint256(21), time, data)));
        return key%range;
    }
    
    function _radex(address player, uint256 time) internal returns (uint256) {
        if(radex > 256) {
            radex = radex/(_random(uint256(keccak256(abi.encodePacked(time, player)))%radex, time, "radex"));
        } else {
            radex = radex + uint256(blockhash(block.number - radex))%radex;
        }
    } 
    
    function random(uint256 range, string memory data) internal returns (uint256) {
        _radex(msg.sender, uint256(now));
        bytes32 hash = keccak256(abi.encodePacked(data));
        return _random(range, uint256(now), hash);
    }
}

contract ERC721Tradable is ERC721, Ownable, Random {
    using SafeMath for uint256;
    using Strings for string;    
    
    event NFTGenerated(uint256 indexed _nft, bytes4[4] indexed _seeds);
    event NewNFTPrice(uint256 indexed _newprice);
    
    MarketPlace public marketplace; 
    string internal baseMetadataURI;
	address proxyRegistryAddress;
	uint256 public totalNFTs;
    
    struct NFT {
        bytes4 headseed;
        bytes4 bodyseed;
        bytes4 limbseed;
        bytes4 weaponseed;
    }
    
    NFT[] NFTs;
    
    mapping (uint256 => address) NFTtoCreator;
    mapping (address => bool) public ifAirdropped;
    mapping (address => uint256) public OwnBoxes;
    mapping (address => mapping(uint256 => bytes8)) BoxLabels;
    
	constructor(
		string memory _name,
		string memory _symbol,
		uint256 _totalNFTs,
		address _proxyRegistryAddress
	) public {
		_name = _name;
		_symbol = _symbol;
		totalNFTs = _totalNFTs;
		proxyRegistryAddress = _proxyRegistryAddress;
		
	}
	
	function setProxyAddress(address _proxyAddress) public onlyOwner {
	    proxyRegistryAddress = _proxyAddress;
	}

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(baseMetadataURI, Strings.uint2str(_tokenId));
    }
    
    function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
        baseMetadataURI = _newBaseMetadataURI;
    }

	function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
		_setBaseMetadataURI(_newBaseMetadataURI);
	}
    
    function addNFTCapacity(uint256 amount) public onlyOwner {
	    totalNFTs = totalNFTs + amount;
	}
	
	function airdrop(address[] memory _users) public onlyOwner {
	    for (uint256 i=0; i< _users.length; i++) {
	        ifAirdropped[_users[i]] = true;
	    }
	}
    
    function openNFT() public returns(uint256) {
        if (ifAirdropped[_msgSender()] == true) {
            ifAirdropped[_msgSender()] = false;
        } else {
            require(OwnBoxes[_msgSender()] > 0);
            OwnBoxes[_msgSender()] = OwnBoxes[_msgSender()].sub(1);
        }
        
        bytes4 headseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "HEAD"), "HEADSEED")));
        bytes4 bodyseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "BODY"), "BODYSEED")));
        bytes4 limbseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "LIMP"), "LIMPSEED")));
        bytes4 weaponseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "WEAPON"), "WEAPONSEED")));
        bytes4[4] memory seeds = [headseed, bodyseed, limbseed, weaponseed];
        
        NFT memory _NFT = NFT({
           headseed: headseed,
           bodyseed: bodyseed,
           limbseed: limbseed,
           weaponseed: weaponseed
        });
        NFTs.push(_NFT);
        uint256 nftId = NFTs.length - 1;
        _mint(msg.sender, nftId);
        NFTtoCreator[nftId] = msg.sender;
        
        emit NFTGenerated(nftId, seeds);
        
        return nftId;
    }
    
    function getNFT(uint256 nftId) public view returns(
        bytes4 headseed,
        bytes4 bodyseed,
        bytes4 limbseed,
        bytes4 weaponseed
    ){
        NFT memory _NFT = NFTs[nftId];
        headseed = _NFT.headseed;
        bodyseed = _NFT.bodyseed;
        limbseed = _NFT.limbseed;
        weaponseed = _NFT.weaponseed;
    }
    
    function getNFTCreator(uint256 nftId) public view returns(address) {
        return NFTtoCreator[nftId];
    }
    
    function NFTleft() public view returns(uint256) {
        return SafeMath.sub(totalNFTs, NFTs.length);
    }

	function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(_owner)) == _operator) {
			return true;
		}

		return ERC721.isApprovedForAll(_owner, _operator);
	}
}

interface MarketPlace {
    function isMarket() external pure returns(bool);
    function createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address payable _seller) external;
    function createAuction(uint256 _tokenId, uint256 _initialPrice, uint256 _duration, address payable _seller) external;
    function withdrawBalance() external;
}

contract KittyMarket is ERC721Tradable {
    function setMarketPlaceAddress(address _address) external onlyOwner {
        MarketPlace candidateContract = MarketPlace(_address);

        require(candidateContract.isMarket());

        marketplace = candidateContract;
    }
    
    function createSale(
        uint256 _id,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
    {
        require(ownerOf(_id) == msg.sender, "You do not have enough!");
        marketplace.createSale(
            _id,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
    function createAuction(
        uint256 _id,
        uint256 _initialPrice,
        uint256 _duration
    )
        external
    {
        marketplace.createAuction(
            _id,
            _initialPrice,
            _duration,
            msg.sender
        );
    }
    
    function withdrawMarketBalances() external onlyOwner {
        marketplace.withdrawBalance();
    }

}

interface USDTERC20 {
    function allowance(address owner, address spender) external returns (uint);
    function transferFrom(address from, address to, uint value) external;
    function approve(address spender, uint value) external;
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract DontPlayWithKitty is KittyMarket {
    event BoughtMesteryBox(uint256 indexed boxNum, bytes8 indexed label);
    
    USDTERC20 public usdtERC20;
    uint256 public usdtPrice = 50*10**6;
    uint256 public repickPrice = 1*10**6;
    uint256 public bnbPrice = 0.01 * 10**18;
    
    function setUSDTAddress(address _address) external onlyOwner {
        USDTERC20 candidateContract = USDTERC20(_address);
        usdtERC20 = candidateContract;
    }
    
    function setUSDTPrice(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        usdtPrice = _amount;
    }
    
    function setBNBPrice(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        bnbPrice = _amount;
    }
    
    function buyKittyWithUSDT() public returns(uint256) {
        require(usdtERC20.allowance(msg.sender, address(this)) >= usdtPrice, "Insuffcient approved USDT");
        usdtERC20.transferFrom(msg.sender, address(this), usdtPrice);
        
        uint256 nextBoxNum = OwnBoxes[msg.sender].add(1);
        OwnBoxes[msg.sender] = nextBoxNum;
        openNFT();
        return nextBoxNum;
    }
    
    function buyKittyWithBNB() payable public returns(uint256) {
        require(msg.value >= bnbPrice, "Insuffcient BNB");
        
        bytes4 headseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "HEAD"), "HEADSEED")));
        bytes4 bodyseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "BODY"), "BODYSEED")));
        bytes4 limbseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "LIMP"), "LIMPSEED")));
        bytes4 weaponseed = bytes4(keccak256(abi.encodePacked(random(totalNFTs, "WEAPON"), "WEAPONSEED")));
        bytes4[4] memory seeds = [headseed, bodyseed, limbseed, weaponseed];
        
        NFT memory _NFT = NFT({
           headseed: headseed,
           bodyseed: bodyseed,
           limbseed: limbseed,
           weaponseed: weaponseed
        });
        NFTs.push(_NFT);
        uint256 nftId = NFTs.length - 1;
        _mint(msg.sender, nftId);
        NFTtoCreator[nftId] = msg.sender;
        
        emit NFTGenerated(nftId, seeds);
        
        return nftId;
    }
    
	constructor(address _proxyRegistryAddress) public ERC721Tradable("DontPlayWithKitty", "DPK", 5000, _proxyRegistryAddress) {
		_setBaseMetadataURI("https://yanyi-test.oss-cn-hangzhou.aliyuncs.com/");
		usdtERC20 = USDTERC20(0xc2e0FCE0278aaE1034F1b8E50d22931a751538bD);
	}

	function contractURI() public pure returns (string memory) {
		return "https://yanyi-test.oss-cn-hangzhou.aliyuncs.com/honhuang-erc1155";
	}
	
	function withdrawBalance() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}