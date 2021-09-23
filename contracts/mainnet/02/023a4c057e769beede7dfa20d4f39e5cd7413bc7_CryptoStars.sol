/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

pragma solidity ^0.4.24;


/// @title ERC-165 Standard Interface Detection
/// @dev Reference https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev Reference https://eips.ethereum.org/EIPS/eip-721
interface ERC721 /* is ERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
interface ERC721Metadata /* is ERC721 */ {
    function name() external pure returns (string _name);
    function symbol() external pure returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
interface ERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/// @title A reusable contract to comply with ERC-165
/// @author William Entriken (https://phor.net)
contract SupportsInterface is ERC165 {
    /// @dev Every interface that we support, do not set 0xffffffff to true
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() internal {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return supportedInterfaces[interfaceID] && (interfaceID != 0xffffffff);
    }
}

/// @title Compliance with ERC-721 for Su Squares
/// @dev This implementation assumes:
///  - A fixed supply of NFTs, cannot mint or burn
///  - ids are numbered sequentially starting at 1.
///  - NFTs are initially assigned to this contract
///  - This contract does not externally call its own functions
/// @author William Entriken (https://phor.net)
contract CryptoStarsNFTs is ERC165, ERC721, ERC721Metadata, ERC721Enumerable, SupportsInterface {
    /// @dev The authorized address for each NFT
    mapping (uint256 => address) internal tokenApprovals;

    /// @dev The authorized operators for each address
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /// @dev Guarantees msg.sender is the owner of _tokenId
    /// @param _tokenId The token to validate belongs to msg.sender
    modifier onlyOwnerOf(uint256 _tokenId) {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // assert(msg.sender != address(this))
        require(msg.sender == owner);
        _;
    }

    modifier mustBeOwnedByThisContract(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(owner == address(0) || owner == address(this));
        _;
    }

    modifier canOperate(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(msg.sender == owner || operatorApprovals[owner][msg.sender]);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        // assert(msg.sender != address(this))
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        require(msg.sender == owner ||
          msg.sender == tokenApprovals[_tokenId] ||
          operatorApprovals[owner][msg.sender]);
        _;
    }

    modifier mustBeValidToken(uint256 _tokenId) {
        require(_tokenId >= 1 && _tokenId <= TOTAL_SUPPLY);
        _;
    }

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
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _tokensOfOwnerWithSubstitutions[_owner].length;
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (address _owner)
    {
        _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (_owner == address(0)) {
            _owner = address(this);
        }
    }

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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

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
    function transferFrom(address _from, address _to, uint256 _tokenId)
        external
        payable
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId)
        external
        payable
        // assert(mustBeValidToken(_tokenId))
        canOperate(_tokenId)
    {
        address _owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (_owner == address(0)) {
            _owner = address(this);
        }
        tokenApprovals[_tokenId] = _approved;
        emit Approval(_owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to
    ///  manage all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (address)
    {
        return tokenApprovals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    // COMPLIANCE WITH ERC721Metadata //////////////////////////////////////////

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string) {
        return "Crypto Stars";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string) {
        return "CSTARS";
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId)
        external
        view
        mustBeValidToken(_tokenId)
        returns (string _tokenURI)
    {

        _tokenURI = "ipfs://QmcAmuwE6n2YGrbjgfRe2pJCmPd1RcBEhr55TmDznhgPv9/cryptostar0000.json";
        bytes memory _tokenURIBytes = bytes(_tokenURI);
        _tokenURIBytes[64] = bytes1(uint8(48+(_tokenId / 1000) % 10));
        _tokenURIBytes[65] = bytes1(uint8(48+(_tokenId / 100) % 10));
        _tokenURIBytes[66] = bytes1(uint8(48+(_tokenId / 10) % 10));
        _tokenURIBytes[67] = bytes1(uint8(48+(_tokenId / 1) % 10));

    }

    // COMPLIANCE WITH ERC721Enumerable ////////////////////////////////////////

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one
    ///  has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < TOTAL_SUPPLY);
        return _index + 1;
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId) {
        require(_owner != address(0));
        require(_index < _tokensOfOwnerWithSubstitutions[_owner].length);
        _tokenId = _tokensOfOwnerWithSubstitutions[_owner][_index];
        // Handle substitutions
        if (_owner == address(this)) {
            if (_tokenId == 0) {
                _tokenId = _index + 1;
            }
        }
    }

/*    function available(uint8 needed) public view returns (uint8) {
        uint8 count=0;
        for (uint8 t=1;t<1002;t++) {
            if (_tokenOwnerWithSubstitutions[t] == address(0))
             count++;
        //    if (count>=needed)
        //    {
        //        return count;
            //    break;
           // }    
        }
        return count;
    } */

    function starsAvailable() public view returns (uint256) {
        return _tokensOfOwnerWithSubstitutions[address(this)].length;
    }


    function buyCryptoStars(uint256 count) external payable {
        require(msg.value >= count*0.001 ether);
        require(starsAvailable()>=count);
// function id			"buyCryptoStars(uint16)": "d29b13b1",
        uint256 claimed=0;
        uint256 tokenid;
        do {
            tokenid=uint(keccak256(abi.encodePacked(block.timestamp*(tokenid+1)*(claimed+1), block.difficulty))) % 1001+1;
            while (_tokenOwnerWithSubstitutions[tokenid] != address(0)) {
              tokenid++;
              if (tokenid==1002) tokenid=1;
            }  
            _transfer(tokenid, msg.sender);
            claimed++;
        } while (claimed<count);        
    
    }

    function giftCryptoStars(uint256 count, address friend) internal {
        uint256 claimed=0;
        uint256 tokenid;
        do {
            tokenid=uint256(keccak256(abi.encodePacked(block.timestamp*(tokenid+1)*(claimed+1), block.difficulty))) % 1001+1;
            while (_tokenOwnerWithSubstitutions[tokenid] != address(0)) {
              tokenid++;
              if (tokenid==1002) tokenid=1;
            }  
            _transfer(tokenid, friend);
            claimed++;
        } while (claimed<count);        
    }

    // INTERNAL INTERFACE //////////////////////////////////////////////////////

    /// @dev Actually do a transfer, does NO precondition checking
    function _transfer(uint256 _tokenId, address _to) internal {
        // Here are the preconditions we are not checking:
        // assert(canTransfer(_tokenId))
        // assert(mustBeValidToken(_tokenId))
        require(_to != address(0));

        // Find the FROM address
        address from = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (from == address(0)) {
            from = address(this);
        }

        // Take away from the FROM address
        // The Entriken algorithm for deleting from an indexed, unsorted array
        uint256 indexToDelete = _ownedTokensIndexWithSubstitutions[_tokenId];
        // Do owned tokens substitution
        if (indexToDelete == 0) {
            indexToDelete = _tokenId - 1;
        } else {
            indexToDelete = indexToDelete - 1;
        }
        // We can only shrink an array from its end. If the item we want to
        // delete is in the middle then copy last item to middle and shrink
        // the end.
        if (indexToDelete != _tokensOfOwnerWithSubstitutions[from].length - 1) {
            uint256 lastNft = _tokensOfOwnerWithSubstitutions[from][_tokensOfOwnerWithSubstitutions[from].length - 1];
            // Do tokens of owner substitution
            if (lastNft == 0) {
                // assert(from ==  address(0) || from == address(this));
                lastNft = _tokensOfOwnerWithSubstitutions[from].length; // - 1 + 1
            }
            _tokensOfOwnerWithSubstitutions[from][indexToDelete] = lastNft;
            _ownedTokensIndexWithSubstitutions[lastNft] = indexToDelete + 1;
        }
        // Next line also deletes the contents at the last position of the array (gas refund)
        _tokensOfOwnerWithSubstitutions[from].length--;
        // Right now _ownedTokensIndexWithSubstitutions[_tokenId] is invalid, set it below based on the new owner

        // Give to the TO address
        _tokensOfOwnerWithSubstitutions[_to].push(_tokenId);
        _ownedTokensIndexWithSubstitutions[_tokenId] = (_tokensOfOwnerWithSubstitutions[_to].length - 1) + 1;

        // External processing
        _tokenOwnerWithSubstitutions[_tokenId] = _to;
        tokenApprovals[_tokenId] = address(0);
        emit Transfer(from, _to, _tokenId);
    }

    // PRIVATE STORAGE AND FUNCTIONS ///////////////////////////////////////////

    // See Solidity issue #3356, it would be clearer to initialize in SuMain
    uint256 private constant TOTAL_SUPPLY = 1001;

    bytes4 private constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /// @dev The owner of each NFT
    ///  If value == address(0), NFT is owned by address(this)
    ///  If value != address(0), NFT is owned by value
    ///  assert(This contract never assigns ownership to address(0) or destroys NFTs)
    ///  See commented out code in constructor, saves hella gas
    ///  In other words address(0) in storage means address(this) outside
    mapping (uint256 => address) private _tokenOwnerWithSubstitutions;

    /// @dev The list of NFTs owned by each address
    ///  Nomenclature: arr[key][index] = value
    ///  If key != address(this) or value != 0, then value represents an NFT
    ///  If key == address(this) and value == 0, then index + 1 is the NFT
    ///  assert(0 is not a valid NFT)
    ///  See commented out code in constructor, saves hella gas
    ///  In other words [0, 0, a, 0] is equivalent to [1, 2, a, 4] for address(this)
    mapping (address => uint256[]) private _tokensOfOwnerWithSubstitutions;

    /// @dev (Location + 1) of each NFT in its owner's list
    ///  Nomenclature: arr[nftId] = value
    ///  If value != 0, _tokensOfOwnerWithSubstitutions[owner][value - 1] = nftId
    ///  If value == 0, _tokensOfOwnerWithSubstitutions[owner][nftId - 1] = nftId
    ///  assert(2**256-1 is not a valid NFT)
    ///  See commented out code in constructor, saves hella gas
    ///  In other words mapping {a=>a} is equivalent to {a=>0}
    mapping (uint256 => uint256) private _ownedTokensIndexWithSubstitutions;

    // Due to implementation choices (no mint, no burn, contiguous NFT ids), it
    // is not necessary to keep an array of NFT ids nor where each NFT id is
    // located in that array.
    // address[] private nftIds;
    // mapping (uint256 => uint256) private nftIndexOfId;

    constructor() internal {
        // Publish interfaces with ERC-165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
        supportedInterfaces[0x8153916a] = true; // ERC721 + 165 (not needed)

        // The effect of substitution makes storing address(this), address(this)
        // ..., address(this) for a total of TOTAL_SUPPLY times unnecessary at
        // deployment time
        // for (uint256 i = 1; i <= TOTAL_SUPPLY; i++) {
        //     _tokenOwnerWithSubstitutions[i] = address(this);
        // }

        // The effect of substitution makes storing 1, 2, ..., TOTAL_SUPPLY
        // unnecessary at deployment time
        _tokensOfOwnerWithSubstitutions[address(this)].length = TOTAL_SUPPLY;
        // for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
        //     _tokensOfOwnerWithSubstitutions[address(this)][i] = i + 1;
        // }
        // for (uint256 i = 1; i <= TOTAL_SUPPLY; i++) {
        //     _ownedTokensIndexWithSubstitutions[i] = i - 1;
        // }
    }

    /// @dev Actually perform the safeTransferFrom
    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data)
        private
        mustBeValidToken(_tokenId)
        canTransfer(_tokenId)
    {
        address owner = _tokenOwnerWithSubstitutions[_tokenId];
        // Do owner address substitution
        if (owner == address(0)) {
            owner = address(this);
        }
        require(owner == _from);
        require(_to != address(0));
        _transfer(_tokenId, _to);

        // Do the callback after everything is done to avoid reentrancy attack
        uint256 codeSize;
        assembly { codeSize := extcodesize(_to) }
        if (codeSize == 0) {
            return;
        }
        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        require(retval == ERC721_RECEIVED);
    }
}


/* SuMain.sol *****************************************************************/

/// @title The features that deed owners can use
/// @author William Entriken (https://phor.net)
contract CryptoStars is CryptoStarsNFTs {
    constructor() public {
        
       
 //Chris Rare        
 _transfer(12, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(956, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(632, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(910, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(397, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(829, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(520, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(26, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(853, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(79, 0x1494c6E369B4c262E2b8e3C7bDF173b602D32eF9);
 _transfer(81, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(134, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(229, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(350, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(621, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(581, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(561, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(428, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(657, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(683, 0x00F64A288821daE5cd50A30b29D059a065aceC20);
 _transfer(834, 0xA598741A18D7c8eD53fb122C77490914831976Ba);
 _transfer(881, 0xA598741A18D7c8eD53fb122C77490914831976Ba);
 _transfer(1001, 0xA598741A18D7c8eD53fb122C77490914831976Ba);
 _transfer(29, 0xA598741A18D7c8eD53fb122C77490914831976Ba);
 _transfer(9, 0xA598741A18D7c8eD53fb122C77490914831976Ba);

 //Morgane Rare
 _transfer(1, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(274, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(290, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(431, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(534, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(312, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(619, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(194, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(807, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(41, 0x0Ff7ede572b24b0f4ac239700EEC9C942a01A70F);
 _transfer(100, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(252, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(221, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(432, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(465, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(545, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(588, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(644, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(697, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(732, 0xcD7F73ca6B3Bfb454698658446392E2FdCE1aB31);
 _transfer(975, 0x7287583F6A348cC1Ea40c271e6dc6Babb5919E0b);
 _transfer(948, 0x7287583F6A348cC1Ea40c271e6dc6Babb5919E0b);
 _transfer(389, 0x7287583F6A348cC1Ea40c271e6dc6Babb5919E0b);
 _transfer(4, 0x7287583F6A348cC1Ea40c271e6dc6Babb5919E0b);
 _transfer(46, 0x7287583F6A348cC1Ea40c271e6dc6Babb5919E0b);

 //Cookie Rare
 _transfer(757, 0x69a80Ce346B8F6f6A9Cc11908D26d77BF81BB299);
 giftCryptoStars(9, 0xeF97c92C47a76756CF8f33fB8b227Cd8ebd7638D);

 //Dikasso Rare
 _transfer(169, 0x36ED2D75A82e180e0871456b15c239b73B4EE9F4);
 giftCryptoStars(9, 0x36ED2D75A82e180e0871456b15c239b73B4EE9F4);

 //james Rare
 _transfer(907, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(666, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(737, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(758, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(742, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(878, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(917, 0x4e0438B9F5133897844336442207f9b181e73C55);
 _transfer(99, 0x4e0438B9F5133897844336442207f9b181e73C55);
 giftCryptoStars(2, 0x4e0438B9F5133897844336442207f9b181e73C55);

 //gift casey 
 giftCryptoStars(10, 0x6c9Cb75B97bEb33095927fAe1C5401cCC05FeCae);

 //gift hugh
 giftCryptoStars(10, 0x4e0438B9F5133897844336442207f9b181e73C55);
 

    }
}