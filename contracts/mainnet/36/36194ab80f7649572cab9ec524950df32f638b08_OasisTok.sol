pragma solidity ^0.6.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    //function name() public view returns (string memory name);
    //function symbol() public view returns (string memory symbol);
    //function totalSupply() public view returns (uint256 totalSupply);
    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) external virtual view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external virtual view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
    function approve(address to, uint256 tokenId) external virtual;
    function getApproved(uint256 tokenId) external virtual view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


contract OasisTok is IERC721
 {
    using SafeMath for uint256;
    event tokenMinted(uint256 tokenId, address owner);
    event tokenBurned(uint256 tokenId);
    event TokenTransferred(address from, address to, uint256 tokenId);
    event ApprovalForAll(address from, address to, bool approved);
 
    // Mapping ontology id to Hash(properties)
  
    struct Multihash
    {
      uint8 hashFunction;
      uint8 size;
      bytes32 digest;
    } 
     
    struct OSC
    {
     Multihash ontology;
     Multihash query;
     uint256 prev;
    }
    
    mapping(bytes32 => uint) ontoHashToId;
    mapping (uint => address) ontologyOwner;
    mapping (uint => bool)  ontologyActive;
    mapping (address => uint) public ownerOntoCount;
      // Mapping from token ID to approved address
    mapping (uint => address) ontologyApprovals;
    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) operatorApprovals;

    address _contOwner;
    string _name;
    string _symbol;
     
    OSC[] private ontologies;
    
    constructor(string memory name, string memory symbol)
        public
    {
        _contOwner = msg.sender;
        _name = name;
        _symbol = symbol;
        //burn token 0
        bytes32 hash = keccak256(abi.encodePacked(uint8(0), uint8(0), bytes32(0), uint8(0), uint8(0), bytes32(0), uint256(0))); 
        OSC memory osc= OSC(Multihash(uint8(0), uint8(0), bytes32(0)), Multihash(uint8(0),uint8(0), bytes32(0)), uint256(0));    
        ontologies.push(osc);         
        ontoHashToId[hash] = 0;
        ontologyOwner[0] = address(0); 
        ontologyActive[0] = false;

    }
    
       
   function mint (uint8 hashO, uint8 sizeO, bytes32 digestO, uint8 hashQ, uint8 sizeQ, bytes32 digestQ, uint256 prev) public 
      {
         if(tokenExists(hashO, sizeO, digestO, hashQ, sizeQ, digestQ, prev)) 
         {
            revert("This token already exist!");
         }
         if (prev != 0 && !tokenIDExists(prev))
         {
           revert("Previous token does not exists or different from 0!");
         }
         bytes32 hash = keccak256(abi.encodePacked(hashO, sizeO, digestO, hashQ, sizeQ, digestQ, prev)); 
         OSC memory osc= OSC(Multihash(hashO, sizeO, digestO), Multihash(hashQ, sizeQ, digestQ), prev);    
         ontologies.push(osc);
         uint256 id = ontologies.length;
         id--;
         ontoHashToId[hash] = id;
         ontologyOwner[id] = msg.sender; 
         ontologyActive[id] = true;        
         ownerOntoCount[msg.sender] = SafeMath.add(ownerOntoCount[msg.sender], 1);         

         emit tokenMinted (id, msg.sender);        
     }
     
     function burn (uint256 id) external
     {
         require(msg.sender == ontologyOwner[id]);
         require(tokenIDExists(id));
         ontologyActive[id]= false;        
         ownerOntoCount[msg.sender] = SafeMath.sub(ownerOntoCount[msg.sender], 1);
         //ontologyOwner[id]=address(0);
         emit tokenBurned(id);
     }
     
     function  transferFrom(address from, address to, uint256 id) public override
     {
         require(from != address(0) && to != address(0));
         require(_isApprovedOrOwner(msg.sender, id));
         require(tokenIDExists(id));
         ontologyOwner[id] = to;
          _clearApproval(to, id);
         ownerOntoCount[to] = SafeMath.add(ownerOntoCount[to], 1);
         ownerOntoCount[from] = SafeMath.sub(ownerOntoCount[from], 1);
         emit TokenTransferred(from, to,id);
         
     }

     
     function tokenExists(uint8 hashO, uint8 sizeO, bytes32 digestO, uint8 hashQ, uint8 sizeQ, bytes32 digestQ, uint256 prev) public view returns (bool)
     {        
        bytes32 hash = keccak256(abi.encodePacked(hashO, sizeO, digestO, hashQ, sizeQ, digestQ, prev));
        if (ontoHashToId[hash] == 0)
        {
           return false;
        }
        return true;
     }
     
     function tokenIDExists(uint256 id) public view returns (bool)
     {
         return ontologyActive[id];
     }
     
     function getTokenInfo(uint256 id) public view returns (uint8 hashO, uint8 sizeO, bytes32 digestO, uint8 hashQ, uint8 sizeQ, bytes32 digestQ, uint256 prev)
     {
         return (ontologies[id].ontology.hashFunction,
                 ontologies[id].ontology.size,
                 ontologies[id].ontology.digest,
                 ontologies[id].query.hashFunction,
                 ontologies[id].query.size,
                 ontologies[id].query.digest,
                 ontologies[id].prev);

     }
     
  
     function balanceOf(address _tokenOwner)  
        public
        view override
        returns(uint256 _balance)
    {
        return ownerOntoCount[_tokenOwner];
    }



     
     // Approve other wallet to transfer ownership of token
    function approve(address _to, uint256 id) public override
    {
        require(msg.sender == ontologyOwner[id]);
        ontologyApprovals[id] = _to;
        emit Approval(msg.sender, _to, id);
    }

    // Return approved address for specific token
    function getApproved(uint256 id)  public view override returns(address operator)
    {
        require(tokenIDExists(id));
        return ontologyApprovals[id];
    }

    /**
     * Private function to clear current approval of a given token ID
     * Reverts if the given address is not indeed the owner of the token
     */
    function _clearApproval(address owner, uint256 id) private
    {
        require(ontologyOwner[id] == owner);
        require(tokenIDExists(id));
        if (ontologyApprovals[id] != address(0)) {
            ontologyApprovals[id] = address(0);
        }
    }

    /*
     * Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     */
     function setApprovalForAll(address to, bool approved)  public override
    {
        require(to != msg.sender);
        operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    // Tells whether an operator is approved by a given owner
    function isApprovedForAll(address Owner, address operator)  public  view override returns(bool)
    {
        return operatorApprovals[Owner][operator];
    }

    // Take ownership of token - only for approved users
    function takeOwnership(uint256 id)  public
    {
        require(_isApprovedOrOwner(msg.sender, id));
        address Owner = ownerOf(id);
        transferFrom(Owner, msg.sender, id);
    }

     function _isApprovedOrOwner(address spender, uint256 id) internal   view   returns(bool)
    {
        address Owner = ontologyOwner[id];
        return (spender == Owner || getApproved(id) == spender || isApprovedForAll(Owner, spender));
    }

     function ownerOf(uint256 id)  public  view  override returns(address _owner)
    {
        return  ontologyOwner[id];
    }


     
    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
     
    // Return the owner address
    function owner()
        public
        view
        returns (address)
    {
        return _contOwner;
    }

    // Returns true if the caller is the current owner.
    function isOwner()
        public
        view
        returns (bool)
    {
        return msg.sender == _contOwner;
    }
	
	// Destroy this smart contract and withdraw balance to owner
	function shutdown() public
		onlyOwner
	{
        selfdestruct(msg.sender);
    }

     
      // Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
     
     
      /**
     * Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
    */
    function safeTransferFrom(address from, address to, uint256 id)  external override
    {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, id, "");
    }

    /**
     * Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     */
    function safeTransferFrom(address from, address to, uint256 id, bytes memory _data) public override
    {
        transferFrom(from, to, id);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, id, _data));
    }

    // Returns whether the target address is a contract
    function isContract(address account)
        internal
        view
        returns(bool)
    {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    
     /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }


    // Allows the owener to capture the balance available to the contract.
    function withdrawBalance()
        external
        onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }
     
 }