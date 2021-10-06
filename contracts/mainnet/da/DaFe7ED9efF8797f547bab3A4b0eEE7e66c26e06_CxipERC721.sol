/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___        
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_       
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_      
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__     
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____    
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________   
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________  
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________ 
        _______\/////////__\///_______\///__\///////////__\///____________*/

contract CxipERC721 {

	using Strings for string;
	using Address for address;

	function getRegistry () internal pure returns (ICxipRegistry) {
		return ICxipRegistry (0xC267d41f81308D7773ecB3BDd863a902ACC01Ade);
	}

	event Transfer (address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval (address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll (address indexed owner, address indexed operator, bool approved);
	event Withdraw (address indexed to, uint256 amount);
	event PermanentURI (string uri, uint256 indexed id);

	CollectionData private _collectionData;

	uint256 private _currentTokenId;
	uint256 [] private _allTokens;
	mapping (uint256 => uint256) private _ownedTokensIndex;
	mapping (uint256 => address) private _tokenOwner;
	mapping (uint256 => address) private _tokenApprovals;
	mapping (address => uint256) private _ownedTokensCount;
	mapping (address => uint256 []) private _ownedTokens;
	mapping (address => mapping (address => bool)) private _operatorApprovals;
	mapping (uint256 => TokenData) private _tokenData;

	address private _admin;
	address private _owner;

	uint256 private _totalTokens;

	constructor () {}

	function init (address newOwner, CollectionData calldata collectionData) public {
		require (_admin.isZero (), 'CXIP: already initialized');
		_admin = msg.sender;
		_owner = address (this);
		_collectionData = collectionData;
		(bool royaltiesSuccess, /*bytes memory royaltiesResponse*/) = getRegistry ().getPA1D ().delegatecall (
			abi.encodeWithSelector (
				bytes4 (0xea2299f8),
				0,
				payable (collectionData.royalties),
				uint256 (collectionData.bps)
			)
		);
		require (royaltiesSuccess, 'CXIP: failed setting royalties');
		_owner = newOwner;
	}

	function getIdentity () public view returns (address) {
		return ICxipProvenance (getRegistry ().getProvenance ()).getWalletIdentity (_owner);
	}

	function owner () public view returns (address) {
		return (isOwner () ? msg.sender : _owner);
	}

	function isOwner () public view returns (bool) {
		return (msg.sender == _owner || msg.sender == _admin || ICxipIdentity (getIdentity ()).isWalletRegistered (msg.sender));
	}
	
	modifier onlyOwner () {
		require (isOwner (), 'CXIP: caller not an owner');
		_;
	}

	function setName (bytes32 newName, bytes32 newName2) public onlyOwner {
		_collectionData.name = newName;
		_collectionData.name2 = newName2;
	}

	function setSymbol (bytes32 newSymbol) public onlyOwner {
		_collectionData.symbol = newSymbol;
	}

	function transferOwnership (address newOwner) public onlyOwner {
		if (!newOwner.isZero ()) {
			_owner = newOwner;
		}
	}

	function supportsInterface (bytes4 interfaceId) external view returns (bool) {
		if (
			interfaceId == 0x01ffc9a7
			|| interfaceId == 0x80ac58cd
			|| interfaceId == 0x5b5e139f
			|| interfaceId == 0x150b7a02
			|| interfaceId == 0xe8a3d485
			|| IPA1D (getRegistry ().getPA1D ()).supportsInterface (interfaceId)
		) {
			return true;
		} else {
			return false;
		}
	}

	function ownerOf (uint256 tokenId) public view returns (address) {
		address tokenOwner = _tokenOwner [tokenId];
		require (!tokenOwner.isZero (), 'ERC721: token does not exist');
		return tokenOwner;
	}

	function approve (address to, uint256 tokenId) public {
		address tokenOwner = _tokenOwner [tokenId];
		if (to != tokenOwner && _isApproved (msg.sender, tokenId)) {
			_tokenApprovals [tokenId] = to;
			emit Approval (tokenOwner, to, tokenId);
		}
	}

	function getApproved (uint256 tokenId) public view returns (address) {
		return _tokenApprovals [tokenId];
	}

	function setApprovalForAll (address to, bool approved) public {
		if (to != msg.sender) {
			_operatorApprovals [msg.sender] [to] = approved;
			emit ApprovalForAll (msg.sender, to, approved);
		} else {
			assert (false);
		}
	}

	function setApprovalForAll (address from, address to, bool approved) public onlyOwner {
		if (to != from) {
			_operatorApprovals [from] [to] = approved;
			emit ApprovalForAll (from, to, approved);
		}
	}

	function isApprovedForAll (address wallet, address operator) public view returns (bool) {
		return
			_operatorApprovals [wallet] [operator]
			|| 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be == operator // Rarible Transfer Proxy
			|| address (OpenSeaProxyRegistry (0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies (wallet)) == operator // OpenSea Transfer Proxy
		;
	}

	function transferFrom (address from, address to, uint256 tokenId) public {
		transferFrom (from, to, tokenId, '');
	}

	function transferFrom (address from, address to, uint256 tokenId, bytes memory /*_data*/) public {
		if (_isApproved (msg.sender, tokenId)) {
			_transferFrom (from, to, tokenId);
		}
	}

	function safeTransferFrom (address from, address to, uint256 tokenId) public {
		safeTransferFrom (from, to, tokenId, '');
	}

	function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory /*_data*/) public {
		if (_isApproved (msg.sender, tokenId)) {
			_transferFrom (from, to, tokenId);
		}
	}

	function _exists (uint256 tokenId) private view returns (bool) {
		address tokenOwner = _tokenOwner [tokenId];
		return !tokenOwner.isZero ();
	}
	
	function _isApproved (address spender, uint256 tokenId) private view returns (bool) {
		require (_exists (tokenId));
		address tokenOwner = _tokenOwner [tokenId];
		return (
			spender == tokenOwner
			|| getApproved (tokenId) == spender
			|| isApprovedForAll (tokenOwner, spender)
			|| ICxipIdentity (getIdentity ()).isWalletRegistered (spender)
		);
	}

	function _clearApproval (uint256 tokenId) private {
		delete _tokenApprovals [tokenId];
	}

	function totalSupply () public view returns (uint256) {
		return _totalTokens;
	}

	function _transferFrom (address from, address to, uint256 tokenId) private {
		if (_tokenOwner [tokenId] == from && !to.isZero ()) {
			_clearApproval (tokenId);
			_tokenOwner [tokenId] = to;
			emit Transfer (from, to, tokenId);
		} else {
			assert (false);
		}
	}

	function _mint (address to, uint256 tokenId) private {
		if (to.isZero () || _exists (tokenId)) {
			assert (false);
		}
		_tokenOwner [tokenId] = to;
		emit Transfer (address (0), to, tokenId);
		_totalTokens += 1;
	}

	function burn (uint256 tokenId) public {
		if (_isApproved (msg.sender, tokenId)) {
			address wallet = _tokenOwner [tokenId];
			require (!wallet.isZero ());
			_clearApproval (tokenId);
			_tokenOwner [tokenId] = address (0);
			emit Transfer (wallet, address (0), tokenId);
			_totalTokens -= 1;
			delete _tokenData [tokenId];
		}
	}

	function cxipMint (uint256 id, TokenData calldata tokenData) public onlyOwner returns (uint256) {
		if (id == 0) {
			_currentTokenId += 1;
			id = _currentTokenId;
		}
		_mint (tokenData.creator, id);
		_tokenData [id] = tokenData;
		emit PermanentURI (string (abi.encodePacked ('https://arweave.net/', tokenData.arweave)), id);
		return id;
	}

	function tokenURI (uint256 tokenId) external view returns (string memory) {
		return string (abi.encodePacked ('https://arweave.net/', _tokenData [tokenId].arweave,  _tokenData [tokenId].arweave2));
	}

	function name () external view returns (string memory) {
		return string (abi.encodePacked (Bytes.trim (_collectionData.name), Bytes.trim (_collectionData.name2)));
	}

	function symbol () external view returns (string memory) {
		return string (Bytes.trim (_collectionData.symbol));
	}

	function baseURI () public view returns (string memory) {
		return string (abi.encodePacked ('https://cxip.io/nft/', Strings.toHexString (address (this))));
	}
	
	function contractURI () external view returns (string memory) {
		return string (abi.encodePacked ('https://nft.cxip.io/', Strings.toHexString (address (this)), '/'));
	}

	function creator (uint256 tokenId) external view returns (address) {
		return _tokenData [tokenId].creator;
	}

	function payloadHash (uint256 tokenId) external view returns (bytes32) {
		return _tokenData [tokenId].payloadHash;
	}

	function payloadSignature (uint256 tokenId) external view returns (Verification memory) {
		return _tokenData [tokenId].payloadSignature;
	}

	function payloadSigner (uint256 tokenId) external view returns (address) {
		return _tokenData [tokenId].creator;
	}

	function arweaveURI (uint256 tokenId) external view returns (string memory) {
		return string (abi.encodePacked ('https://arweave.net/', _tokenData [tokenId].arweave,  _tokenData [tokenId].arweave2));
	}

	function httpURI (uint256 tokenId) external view returns (string memory) {
		return string (abi.encodePacked (baseURI (), '/', Strings.toHexString (tokenId)));
	}

	function ipfsURI (uint256 tokenId) external view returns (string memory) {
		return string (abi.encodePacked ('https://ipfs.io/ipfs/', _tokenData [tokenId].ipfs, _tokenData [tokenId].ipfs2));
	}

	function verifySHA256 (bytes32 hash, bytes calldata payload) external pure returns (bool) {
		bytes32 thePayloadHash = sha256 (payload);
		return hash == thePayloadHash;
	}

	function onERC721Received (address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes calldata /*_data*/) public pure returns (bytes4) {
		return 0x150b7a02;
	}

	function _royaltiesFallback () internal {
		address _target = getRegistry ().getPA1D ();
		assembly {
			calldatacopy (0, 0, calldatasize ())
			let result := delegatecall (gas (), _target, 0, calldatasize (), 0, 0)
			returndatacopy (0, 0, returndatasize ())
			switch result
				case 0 {
					revert (0, returndatasize ())
				}
				default {
					return (0, returndatasize ())
				}
		}
	}

	fallback () external {
		_royaltiesFallback ();
	}

	receive () external payable {
		_royaltiesFallback ();
	}

}

library Address {

	function isZero (address account) internal pure returns (bool) {
		return (account == address (0));
	}

	function isContract (address account) internal view returns (bool) {
		bytes32 codehash;
		assembly {
			codehash := extcodehash (account)
		}
		return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
	}

}

library Strings {

	function toHexString (address account) internal pure returns (string memory) {
		return toHexString (uint256 (uint160 (account)));
	}

	function toHexString (uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return '0x00';
		}
		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString (value, length);
	}

	function toHexString (uint256 value, uint256 length) internal pure returns (string memory) {
		bytes memory buffer = new bytes (2 * length + 2);
		buffer [0] = '0';
		buffer [1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer [i] = bytes16 ('0123456789abcdef') [value & 0xf];
			value >>= 4;
		}
		require (value == 0, 'Strings: hex length insufficient');
		return string (buffer);
	}

}

library Bytes {

	function trim (bytes32 source) internal pure returns (bytes memory) {
		uint256 temp = uint256 (source);
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return slice (abi.encodePacked (source), 32 - length, length);
	}

	function slice (bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
		require (_length + 31 >= _length, 'slice_overflow');
		require (_bytes.length >= _start + _length, 'slice_outOfBounds');
		bytes memory tempBytes;
		assembly {
			switch iszero (_length)
				case 0 {
					tempBytes := mload (0x40)
					let lengthmod := and (_length, 31)
					let mc := add (add (tempBytes, lengthmod), mul (0x20, iszero (lengthmod)))
					let end := add (mc, _length)
					for {
						let cc := add (add (add (_bytes, lengthmod), mul (0x20, iszero (lengthmod))), _start)
					} lt (mc, end) {
						mc := add (mc, 0x20)
						cc := add (cc, 0x20)
					} {
						mstore (mc, mload (cc))
					}
					mstore (tempBytes, _length)
					mstore (0x40, and (add (mc, 31), not (31)))
				}
				default {
					tempBytes := mload (0x40)
					mstore (tempBytes, 0)
					mstore(0x40, add (tempBytes, 0x20))
				}
		}
		return tempBytes;
	}

}

struct Verification {

	bytes32 r;
	bytes32 s;
	uint8 v;

}

struct CollectionData {

	bytes32 name;
	bytes32 name2;
	bytes32 symbol;
	address royalties;
	uint96 bps;

}

struct TokenData {

	bytes32 payloadHash;
	Verification payloadSignature;
	address creator;
	bytes32 arweave;
	bytes11 arweave2;
	bytes32 ipfs;
	bytes14 ipfs2;

}

interface IPA1D {

	function supportsInterface (bytes4 interfaceId) external pure returns (bool);

}

interface ICxipProvenance {

	function getIdentity () external view returns (address);

	function getWalletIdentity (address wallet) external view returns (address);

	function isIdentityValid (address identity) external view returns (bool);

}

interface ICxipIdentity {

	function isWalletRegistered (address wallet) external view returns (bool);

	function isOwner () external view returns (bool);

	function isCollectionCertified (address collection) external view returns (bool);

	function isCollectionRegistered (address collection) external view returns (bool);

}

interface ICxipRegistry {

	function getPA1D () external view returns (address);

	function setPA1D (address proxy) external;

	function getPA1DSource () external view returns (address);

	function setPA1DSource (address source) external;

	function getAsset () external view returns (address);

	function setAsset (address proxy) external;

	function getAssetSource () external view returns (address);

	function setAssetSource (address source) external;

	function getCopyright () external view returns (address);

	function setCopyright (address proxy) external;

	function getCopyrightSource () external view returns (address);

	function setCopyrightSource (address source) external;

	function getProvenance () external view returns (address);

	function setProvenance (address proxy) external;

	function getProvenanceSource () external view returns (address);

	function setProvenanceSource (address source) external;

	function getIdentitySource () external view returns (address);

	function setIdentitySource (address source) external;

	function getERC721CollectionSource () external view returns (address);

	function setERC721CollectionSource (address source) external;

	function getERC1155CollectionSource () external view returns (address);

	function setERC1155CollectionSource (address source) external;

	function getAssetSigner () external view returns (address);

	function setAssetSigner (address source) external;

	function getCustomSource (bytes32 name) external view returns (address);

	function getCustomSourceFromString (string memory name) external view returns (address);

	function setCustomSource (string memory name, address source) external;

	function owner () external view returns (address);

}

contract OpenSeaOwnableDelegateProxy  {

}

contract OpenSeaProxyRegistry {

	mapping (address => OpenSeaOwnableDelegateProxy) public proxies;

}