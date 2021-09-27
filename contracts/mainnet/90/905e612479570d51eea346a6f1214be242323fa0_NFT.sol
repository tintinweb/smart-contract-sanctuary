/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 is ERC165 {
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

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

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface ERC721Metadata is ERC721 {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface ERC721Enumerable is ERC721 {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);
}

contract NFT is ERC721Metadata, ERC721Enumerable {
    mapping (uint256 => address) private tokenOwnerFromTokenId;
    uint256 public immutable override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => bool)) public override isApprovedForAll;
    mapping (uint256 => address) public override getApproved;
    string public override name;
    string public override symbol;
    string private IPFSbase;
    address private immutable originOwner;
    uint256 private mintCounter = 0;
    
    constructor(uint256 _totalSupply, string memory _name, string memory _symbol, string memory _IPFSbase) {
        totalSupply = _totalSupply;
        name = _name;
        symbol = _symbol;
        IPFSbase = _IPFSbase; // "ipfs://bafybeih6a5b7kakekyfla4qtooq6u5vxtaoixxbezybl7hi5elc23xcx3u/"
        originOwner = msg.sender;
        balanceOf[msg.sender] = _totalSupply;
    }
    
    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < totalSupply, "Token ID invalid.");
        _;
    }
    
    function ownerOf(uint256 _tokenId) external view override validTokenId(_tokenId) returns (address) {
        address owner = tokenOwnerFromTokenId[_tokenId];
        return owner == address(0x0) ? originOwner : owner;
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        _transferFrom(_from, _to, _tokenId);
    }
    
    function _transferFrom(address _from, address _to, uint256 _tokenId) internal validTokenId(_tokenId) {
        require(_to != address(0x0), "Zero address recipient.");
        address owner = tokenOwnerFromTokenId[_tokenId];
        require(msg.sender == _from || isApprovedForAll[_from][msg.sender] || getApproved[_tokenId] == msg.sender || (_from == originOwner && owner == address(0x0)), "Transfer authorization failed.");
        require(owner == _from, "Not owning token trying to transfer");
        
        balanceOf[_from]--;
        balanceOf[_to]++;
        tokenOwnerFromTokenId[_tokenId] = _to;
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external override {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) internal {
        _transferFrom(_from, _to, _tokenId);
        
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size == 0) {
            return;
        }
        
        require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) == ERC721TokenReceiver.onERC721Received.selector, "safeTransferFrom invalid return");
    }
    
    function setApprovalForAll(address _operator, bool _approved) external override {
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
    function approve(address _approvee, uint256 _tokenId) external override validTokenId(_tokenId) {
        address owner = tokenOwnerFromTokenId[_tokenId];
        require(owner == msg.sender || isApprovedForAll[owner][msg.sender] || getApproved[_tokenId] == msg.sender, "Approve authorization failed.");
        getApproved[_tokenId] = _approvee;
        
        emit Approval(owner, _approvee, _tokenId);
    }
    
    function tokenByIndex(uint256 _index) external view override validTokenId(_index) returns (uint256) {
        return _index;
    }
    
    function mint(uint256 number) external {
        uint256 _mintCounter = mintCounter;
        uint256 mcAndNumber = _mintCounter + number;
        uint256 target = mcAndNumber < totalSupply ? mcAndNumber : totalSupply;
        
        while (_mintCounter < target) {
            address owner = tokenOwnerFromTokenId[_mintCounter];
            if (owner != address(0x0)) {
                _mintCounter++;
                continue;
            }
            
            emit Transfer(address(0x0), originOwner, _mintCounter);
            _mintCounter++;
        }
        
        mintCounter = _mintCounter;
    }
    
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x780e9d63;
    }
    
    function tokenURI(uint256 _tokenId) external view override validTokenId(_tokenId) returns (string memory) {
        // Base for the base 10 encoding https://stackoverflow.com/a/65707309
        uint len;
        if (_tokenId == 0) {
            len = 1;
        } else {
            uint j = _tokenId;
            while (j != 0) {
                len++;
                j /= 10;
            }
        }
        bytes memory base = bytes(IPFSbase);
        uint lbase = base.length;
        len += lbase;
        bytes memory bstr = new bytes(len+5);
        while (lbase > 0) { // copy "ipfs://bafy.../" at the start
            lbase--;
            bstr[lbase] = base[lbase];
        }
        bstr[len] = "."; // copy ".json" at the end
        bstr[len+1] = "j";
        bstr[len+2] = "s";
        bstr[len+3] = "o";
        bstr[len+4] = "n";
        if (_tokenId > 0) {
            while (_tokenId != 0) { // base10 encode the id in the middle
                len--;
                bstr[len] = bytes1((48 + uint8(_tokenId - _tokenId / 10 * 10)));
                _tokenId /= 10;
            }
        } else {
            bstr[len-1] = "0";
        }
        return string(bstr);
    }
}