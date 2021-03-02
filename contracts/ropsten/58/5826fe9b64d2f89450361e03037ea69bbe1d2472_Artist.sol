/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

/**
 * Feb 4th,2021 Meteor
*/

pragma solidity ^0.5.16;


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

contract ArtistBase is Ownable {
    
    using SafeMath for uint256;
    
    
    /*** EVENTS ***/
    /// @dev Transfer event as defined in current draft of ERC721. 
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/
    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    address public cfoAddress;
    address public cooAddress;
    
    address public bonusPoolAddress=0x202eA6a21c7D37edA4860B7D95Df6f3832967472;
    address public devPoolAddress=0xBe97566cAE12870699638B32F03AD0feC32c34AE;  



    /// @dev The main art struct. 
    struct Art {

        uint256 id;

        // The timestamp from the block when aution startTime
        uint64 bidStartTime;

        uint64 round;
        //bid issue privileges
        bool bid;
        string ipfs;
    }

    /*** CONSTANTS ***/
    uint256 lastBidTime=0;

    /*** STORAGE ***/

    Art[]  arts;

    /// @dev A mapping from cat IDs to the address that owns them. 
    mapping (uint256 => address) public artIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from artIDs to an address that has been approved to call
    ///  transferFrom(). Each art can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public artIndexToApproved;

    //current id 
    uint256 curid;
    
    uint256 public bidInterval;
    uint256 public defaultBidTokenId;
    
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == cfoAddress
        );
        _;
    }
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCLevel whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
    /// @dev Assigns ownership of a specific art to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of kittens is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        artIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;

            // clear any previously approved ownership exchange
            delete artIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    function creatArt(
        bool bidflag,
        string calldata ipfsaddr,
        uint64 startTime

    )
        external
        whenNotPaused
        returns (uint256)
    {
         require(msg.sender == owner, "ERR_NOT_OWNER");


        if(lastBidTime==0){
            bidflag=false;
        }else if((now-lastBidTime)<bidInterval){
            bidflag=false;
        }else{
            if(bidflag){
                lastBidTime==now;
            }
        }

        Art memory _art = Art({
            id: curid,
            bidStartTime: startTime,
            round: 0,
            bid: bidflag,
            ipfs: ipfsaddr

        });
        curid = arts.push(_art) ;


        // It's probably never going to happen, 4 billion is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(curid == uint256(uint32(curid)));


        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(address(0), owner, curid-1);

        return curid;
    }

    function openBidTokenAuthority() 
        external
        onlyCLevel
        {
            lastBidTime=now - bidInterval;
        }

    function closeBidTokenAuthority() 
        external
        onlyCLevel
        {
            lastBidTime=0;
        }

    function setBidInterval(uint256 interval) 
        external
        onlyCLevel
        {
            bidInterval=interval;
        }
        

    function changeArtData(uint256 tokenid,string calldata ipfs) 
        external
        onlyCLevel
        {
            require(tokenid<curid, "ERR_ARTID_TOOBIG");
            arts[tokenid].ipfs=ipfs;
        }
    function editArtData(uint256 tokenid,string calldata ipfs) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_ARTID_TOOBIG");
            require(arts[tokenid].bidStartTime>now,"ERR_ALREADY_START");
            arts[tokenid].ipfs=ipfs;
        }

    function checkBidable() view
        external
        returns (bool){
        
            if(lastBidTime==0){
                return false;
            }else if((now-lastBidTime)<bidInterval){
                return false;
            }else{
                return true;
            }
        
        }
    function getLatestTokenID() view
        external
        returns (uint256){
            return curid;
        }
        
    function setBidStartTime(uint256 tokenid,uint64 startTime) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");
            require(arts[tokenid].bidStartTime>now,"ERR_ALREADY_START");
            arts[tokenid].bidStartTime=startTime;
        }
    function getBidStartTime(uint256 tokenid) view
        external
        returns(uint64)
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");
            return arts[tokenid].bidStartTime;
        }
    function setDefaultBidId(uint256 tokenid) 
        external
        onlyOwner
        {
            require(tokenid<curid, "ERR_TOKEN_ID_ERROR");

            defaultBidTokenId=tokenid;
        }
        
    function getTokenRound(uint256 tokenid) view 
        external
        returns (uint64){
            return arts[tokenid].round;
        }

    event LOG_AUCTION(
        uint256  artid,
        uint256  lastPrice,
        uint256  curPrice,
        uint256  bid,
        address  lastOwner,
        address  buyer,
        address  inviterAddress
    );
        //bid token address
    IERC20 public bidtoken = IERC20(0x97A441b3B0025c2D4539818474D20096676Ed5f5);
    function () external
    whenNotPaused
     payable {
        _bid(devPoolAddress,defaultBidTokenId);
         
    }
   
      function bid(address inviterAddress, uint256 artid) payable
    whenNotPaused
     public {
        _bid(inviterAddress,artid); 
     }
    
    function _bid(address inviterAddress, uint256 artid)  internal
     {
         require(curid>0, "ERR_NO_ART");
         require(artIndexToOwner[artid]!=msg.sender, "ERR_CAN_NOT_PURCHASE_OWN_ART");
         require(artid<curid, "ERR_ARTID_TOOBIG");
         require(arts[artid].bidStartTime<now,"ERR_BID_NOT_START_YET");
         uint256 r=arts[artid].round;
         require(r<256,"ERR_ROUND_REACH_MAX");
         uint256 curprice=0.05 ether;
         
         if(r==0){
             uint256 payprice=curprice;
             require(msg.value>payprice, "ERR_NOT_ENOUGH_MONEY");
              msg.sender.transfer(msg.value.sub(payprice));
              address(uint160(owner)).transfer(payprice);
              uint256 x=0;
              if(arts[artid].bid){
                  if(bidtoken.balanceOf(cfoAddress)>=10 ether){
                      x=10 ether;
                      bidtoken.transferFrom(cfoAddress,msg.sender,x);                  
                  }else{
                      x=0;
                  }
             }
             arts[artid].round++;
             address lastOwner=artIndexToOwner[artid];
            _transfer(artIndexToOwner[artid], msg.sender, artid);

            emit LOG_AUCTION(artid, curprice,payprice,x,lastOwner,msg.sender,inviterAddress );
            return;
         }
         for (uint64 i=0;i<r;i++){
             curprice=curprice.mul(11).div(10);
         }
         uint256 payprice=curprice.mul(11).div(10);
         require(msg.value>payprice, "ERR_NOT_ENOUGH_MONEY");
         //refund extra money
         msg.sender.transfer(msg.value-payprice);
         
         uint256 smoney=payprice-curprice;
         
         address(uint160(owner)).transfer(smoney.mul(5).div(10));
         //contract,can not use transfer, it's fixed gas
         (bool success, ) =address(uint160(bonusPoolAddress)).call.value(smoney.mul(18).div(100))("");
         require(success,"ERR contract transfer bid fail,maybe gas fail");
        
         address(uint160(inviterAddress)).transfer(smoney.mul(2).div(100));

         
         address(uint160(artIndexToOwner[artid])).transfer(smoney.mul(30).div(100).add(curprice));

         uint256 x;
         if(arts[artid].bid){
            if(bidtoken.balanceOf(cfoAddress)>=10 ether){
                x=r<10?10 ether:(r.mul(1 ether));
                bidtoken.transferFrom(cfoAddress,msg.sender,x);
            }else{
                x=0;
            }
         }

         arts[artid].round++;
         address lastOwner=artIndexToOwner[artid];
          _transfer(artIndexToOwner[artid], msg.sender, artid);

        emit LOG_AUCTION(artid, curprice,payprice,x,lastOwner,msg.sender,inviterAddress );

    }

}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract Artist is ArtistBase,IERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name = "";
    string public symbol = "ART";


    bytes4 constant InterfaceSignature_ERC165 =0x01ffc9a7;
    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor(string memory n,string memory nft,address artistaddr,address auditor) public {
        curid=0;
        owner=artistaddr;
        cfoAddress=msg.sender;
        cooAddress=auditor;
        name=n;
        symbol=nft;
        bidInterval=7 days;
        defaultBidTokenId=0;
    }
    /// @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    ///  Returns true for any standardized interfaces implemented by this contract. We implement
    ///  ERC-165 (obviously!) and ERC-721.
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721)|| (_interfaceID == _INTERFACE_ID_ERC721_METADATA));
    }


    // Internal utility functions: These functions all assume that their input arguments
    // are valid. We leave it to public methods to sanitize their inputs and follow
    // the required logic.

    /// @dev Checks if a given address is the current owner of a particular art.
    /// @param _claimant the address we are validating against.
    /// @param _tokenId kitten id, only valid when > 0
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artIndexToOwner[_tokenId] == _claimant;
    }

    /// @dev Checks if a given address currently has transferApproval for a particular art.
    /// @param _claimant the address we are confirming art is approved for.
    /// @param _tokenId id, only valid when > 0
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return artIndexToApproved[_tokenId] == _claimant;
    }

    /// @dev Marks an address as being approved for transferFrom(), overwriting any previous
    ///  approval. Setting _approved to address(0) clears all transfer approval.
    ///  NOTE: _approve() does NOT send the Approval event. This is intentional because
    ///  _approve() and transferFrom() are used together for putting art on auction, and
    ///  there is no value in spamming the log with Approval events in that case.
    function _approve(uint256 _tokenId, address _approved) internal {
        artIndexToApproved[_tokenId] = _approved;
    }

    /// @notice Returns the number of arts owned by a specific address.
    /// @param _owner The owner address to check.
    /// @dev Required for ERC-721 compliance
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    /// @notice Transfers a art to another address. If transferring to a smart
    ///  contract be VERY CAREFUL to ensure that it is aware of ERC-721 your art may be lost forever. Seriously.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _tokenId The ID of the art to transfer.
    /// @dev Required for ERC-721 compliance.
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any art
        require(_to != address(this));


        require(_owns(msg.sender, _tokenId));

        // Reassign ownership, clear pending approvals, emit Transfer event.
        _transfer(msg.sender, _to, _tokenId);
    }

    /// @notice Grant another address the right to transfer a specific art via
    ///  transferFrom(). This is the preferred flow for transfering NFTs to contracts.
    /// @param _to The address to be granted transfer approval. Pass address(0) to
    ///  clear all approvals.
    /// @param _tokenId The ID of the art that can be transferred if this call succeeds.
    /// @dev Required for ERC-721 compliance.
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId)  public view returns (address operator)  {
        return artIndexToApproved[_tokenId];
    }
    function _exists(uint256 tokenId) internal view  returns (bool) {
        return tokenId<curid;
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner=artIndexToOwner[tokenId];
        return (spender == owner || _approvedFor(spender, tokenId)||isApprovedForAll(owner,msg.sender));
    }
    /// @notice Transfer a art owned by another address, for which the calling address
    ///  has previously been granted transfer approval by the owner.
    /// @param _from The address that owns the art to be transfered.
    /// @param _to The address that should take ownership of the art. Can be any address,
    ///  including the caller.
    /// @param _tokenId The ID of the art to be transferred.
    /// @dev Required for ERC-721 compliance.
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }


    /// @notice Returns the address currently assigned ownership of a given art.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = artIndexToOwner[_tokenId];

        require(owner != address(0));
    }



    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the art whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId)view  external  returns (string memory) {

        return arts[_tokenId].ipfs;
    }
    
     function safeTransferFrom(address from, address  to, uint256 _tokenId) public {
        this.transferFrom(from,to,_tokenId);
    
    }



  /*
     * Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     */
     
      // You can nest mappings, this example maps owner to operator approvals
    mapping(address => mapping(address => bool)) private operatorApprovals;
    
    function setApprovalForAll(address to, bool approved) public  {
        
        operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    // Tells whether an operator is approved by a given owner
    function isApprovedForAll(address owner, address operator)  public view returns (bool)
    {
        return operatorApprovals[owner][operator];
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)  public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    } 
     bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
     function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
 
}
contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}