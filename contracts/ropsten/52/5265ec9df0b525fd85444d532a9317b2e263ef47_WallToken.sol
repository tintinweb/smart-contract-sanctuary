pragma solidity ^0.4.24;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd
interface ERC721 /* is ERC165 */ {
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
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

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets.
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the
    /// recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
    /// of other than the magic value MUST result in the transaction being reverted.
    /// @notice The contract address is always the message sender. 
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
 }

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver is ERC721TokenReceiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    external
    returns(bytes4);
}


contract WallToken is ERC721, ERC165
{
    string internal Name;
    string internal Coin;
    address public CEO;

    constructor(string _name, string _symbol) public {
        Name = _name;
        Coin = _symbol;
        CEO = msg.sender;
        TotalSupply = 0;
    }

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    bytes4 constant ERC165_INTERFACE = bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    bytes4 constant ERC721_INTERFACE = bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^ 
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^ 
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;)) ^ 
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^ 
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^ 
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^ 
    bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^ 
    bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^ 
    bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;));

    /// ERC721 compliance
    /// @notice token owner address
    mapping (uint256 => address) public TokenOwners;

    /// @notice owner token count
    mapping (address => uint256) public OwnerTokenCounts;

    /// @notice claimed token count
    mapping (address => uint256) public ClaimedTokensCounts;

    /// @notice tokens ever owned for address
    mapping (address => uint256[]) public OwnerTokens;
    
    mapping (address => mapping (uint256 => uint8)) public Votes;    
    
    /// @notice mapping owner => operator => approved
    mapping (address => mapping (address => bool)) public Operators;
    
    mapping (uint256 => address) public TokenApprovals;
    
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// Extensions
    /// @notice tokens ever issued or latest issued token id
    uint256 public TotalSupply;
    
    /// @notice metadata URI for token
    mapping (uint256 => string) public TokenURIs;

    /// @notice coordinate => token mapping
    mapping (uint256 => mapping (uint256 => uint256)) public WallOfTokens;

    /// @notice token => coordinate mapping
    struct WallCoordinate
    {
        uint256 x;
        uint256 y;
    }
    mapping (uint256 => WallCoordinate) public TokenCoordinates;
    
    mapping (uint256 => uint256) public Likes;
    
    mapping (uint256 => uint256) public Dislikes;

    event RatingChange (address _from, uint256 _tokenId, bool vote, uint256 likes, uint256 dislikes);

    /// @notice emits when cell is placed on the wall
    event Claim (uint256 indexed _x, uint256 indexed _y, uint256 indexed _tokenId, address _sender);

    /// @notice emits when cell metadata is changed
    event URI (uint256 indexed _x, uint256 indexed _y, uint256 indexed _tokenId, string _tokenURI);


    /// ERC721 compliance
    function balanceOf(address _owner) external view  returns (uint256)
    {
        require(_owner != address(0));
        return OwnerTokenCounts[_owner];
    }


    /// @notice returns address of token owner
    function ownerOf(uint256 _tokenId) external view returns (address)
    {
        address owner = TokenOwners[_tokenId];
        require(owner != address(0));
        return TokenOwners[_tokenId];
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
        require(_tokenId > 0);
        address owner = TokenOwners[_tokenId];
        address approved = TokenApprovals[_tokenId];
        require ((msg.sender == owner) || (Operators[msg.sender][owner]) || (msg.sender == approved) || (msg.sender == CEO));
        require (_from == owner);
        require (_to != address(0));
        
        this.transferFrom(_from, _to, _tokenId);
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, data));
    }


    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool)
    {
    //   if (!_to.isContract()) {
    //      return true;
    //   }
      bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      return (retval == ERC721_RECEIVED);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        require(_tokenId > 0);
        address owner = TokenOwners[_tokenId];
        require ((msg.sender == owner) || (Operators[msg.sender][owner])
         || (msg.sender == TokenApprovals[_tokenId]) || (msg.sender == CEO));
        require (_from == owner);
        require (_to != address(0));
        
        this.safeTransferFrom(_from, _to, _tokenId, "");
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
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable
    {
        require(_tokenId > 0);
        require(OwnerTokenCounts[msg.sender] - ClaimedTokensCounts[msg.sender] <= 1);
        address owner = TokenOwners[_tokenId];
        require ((msg.sender == owner) || (Operators[msg.sender][owner])
         || (msg.sender == TokenApprovals[_tokenId]) || (msg.sender == CEO));
        require (_from == owner);
        require (_to != address(0));
        
        TokenApprovals[_tokenId] = address(0);
        
        TokenOwners[_tokenId] = _to;
        OwnerTokenCounts[_from] -= 1;
        OwnerTokenCounts[_to] += 1;
        OwnerTokens[_to].push(_tokenId);

        emit Transfer(_from, _to, _tokenId);
    }
    
    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable
    {
        address owner = TokenOwners[_tokenId];
        require ((msg.sender == owner) || (Operators[msg.sender][owner])
         || (msg.sender == TokenApprovals[_tokenId]) || (msg.sender == CEO));
        TokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`&#39;s assets.
    /// @dev operators the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external 
    {   
        require((msg.sender == CEO) || (msg.sender == _operator) || (msg.sender == msg.sender));
        Operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address)
    {
        // require valid _tokenId;
        return TokenApprovals[_tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return Operators[_owner][_operator];
    }
    
    /// ERC165 compliance
    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
          interfaceID == ERC165_INTERFACE ||
          interfaceID == ERC721_INTERFACE;
    }
    
    /// Extensions
    /// @notice token issue
    /// - called only once for each token
    /// called by CEO (FIXME)
    /// returns ID of issued token
    function MintNFT(address _to) external payable returns(uint256)
    {
        require(msg.sender == CEO);
        require(_to != address(0));

        TotalSupply += 1;
        uint256 _tokenId = TotalSupply;

        TokenOwners[_tokenId] = _to;
        OwnerTokens[_to].push(_tokenId);
        OwnerTokenCounts[_to] += 1;
        TokenURIs[_tokenId] = "";

        emit Transfer(address(0), _to, _tokenId);
        return _tokenId;
    }

    /// @notice placing cell on the wall
    /// - called only once for each token
    /// only called by token owner
    function ClaimNFT(uint256 _tokenId, uint256 x, uint256 y) external payable
    {
        require(_tokenId > 0);
        require(TokenOwners[_tokenId] == msg.sender);

        require(x != 0 && y != 0);
        require(WallOfTokens[x][y] == uint256(0));

        WallCoordinate memory coords = TokenCoordinates[_tokenId];
        require(coords.x == 0 && coords.y == 0);

        coords.x = x;
        coords.y = y;
        TokenCoordinates[_tokenId] = coords;

        ClaimedTokensCounts[msg.sender] += 1;

        emit Claim(coords.x, coords.y, _tokenId, msg.sender);
    }

    /// @notice sets metadata for given _tokenId
    /// token ownership required
    function SetURI(uint256 _tokenId, string _tokenURI) external payable
    {
        require(_tokenId > 0);
        require(TokenOwners[_tokenId] == msg.sender);

        WallCoordinate memory coords = TokenCoordinates[_tokenId];
        require(coords.x != 0 && coords.y != 0);

        TokenURIs[_tokenId] = _tokenURI;

        emit URI(coords.x, coords.y, _tokenId, _tokenURI);
    }

    /// @notice returns coordinates for given tokenId
    /// - reverts if zero coordinates (token never claimed)
    /// - reverts if token not issued
    function coordinatesOf(uint256 _tokenId) external view returns(uint256, uint256)
    {
        require(_tokenId > 0);
        require(TokenOwners[_tokenId] != address(0));

        WallCoordinate memory coords = TokenCoordinates[_tokenId];
        return (coords.x, coords.y);
    }

    function EverOwnedTokens(address _owner) external view returns(uint256[])
    {
        return OwnerTokens[_owner];
    }
    
    function Vote(address _from, uint256 _tokenId, bool _vote) public payable {
        uint8 registered_vote = Votes[_from][_tokenId];
        
        uint8 vote;
        if (_vote) {
            vote = 1;
        } else {
            vote = 2;
        }
        
        if ((registered_vote > 0) && (registered_vote == vote)) {
                revert();
        }
        
        Votes[_from][_tokenId] = vote;
        
        if (_vote) {
            Likes[_tokenId] = Likes[_tokenId] + 1;
            if (registered_vote > 0) {
                Dislikes[_tokenId] = Dislikes[_tokenId] - 1;
            }
        } else {
            Dislikes[_tokenId] = Dislikes[_tokenId] + 1;
            if (registered_vote > 0) {
                Likes[_tokenId] = Likes[_tokenId] - 1;
            }
        }
        
        emit RatingChange (_from, _tokenId, _vote, Likes[_tokenId], Dislikes[_tokenId]);
    }

}