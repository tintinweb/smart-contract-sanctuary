/**
 *Submitted for verification at Etherscan.io on 2021-02-19
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


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <[email protected]> (https://github.com/dete)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}


/// @title A facet of artCore that manages special access privileges.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the artCore contract documentation to understand how the various contract facets are arranged.
contract ArtistAccessControl {
    // This facet controls access control for CryptoKitties. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the artCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from artCore and its auction contracts.
    //
    //     - The COO: The COO can release gen0 kitties to auction, and mint promo cats.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    
    address public bonusPoolAddress=0x202eA6a21c7D37edA4860B7D95Df6f3832967472;
    address public devPoolAddress=0xBe97566cAE12870699638B32F03AD0feC32c34AE;   

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
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
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
}




/// @title Base contract for CryptoKitties. Holds all common structs, events and base variables.
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the artCore contract documentation to understand how the various contract facets are arranged.
contract ArtistBase is ArtistAccessControl,Ownable {
    
    using SafeMath for uint256;
    
    
    /*** EVENTS ***/
    /// @dev Transfer event as defined in current draft of ERC721. 
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

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

    function getNow() view
        external
        returns (uint256){
            return now;
        }
            function getMinutes() view
        external
        returns (uint256){
            return 1 minutes;
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




contract Artist is ArtistBase, ERC721 {

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public name = "TopBidder Artist";
    string public symbol = "ART";


    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256('supportsInterface(bytes4)'));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)')) ^
        bytes4(keccak256('tokenMetadata(uint256)'));


    constructor(string memory n,string memory nft,address artistaddr) public {
        curid=0;
        owner=artistaddr;
        ceoAddress=msg.sender;
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
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
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
        external
        whenNotPaused
    {
        // Only an owner can grant transfer approval.
        require(_owns(msg.sender, _tokenId));

        // Register the approval (replacing any previous approval).
        _approve(_tokenId, _to);

        // Emit approval event.
        emit Approval(msg.sender, _to, _tokenId);
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
        external
        whenNotPaused
    {
        // Safety check to prevent against an unexpected 0x0 default.
        require(_to != address(0));
        // Disallow transfers to this contract to prevent accidental misuse.
        // The contract should never own any kitties
        require(_to != address(this));
        // Check for approval and valid ownership
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        // Reassign ownership (also clears pending approvals and emits Transfer event).
        _transfer(_from, _to, _tokenId);
    }

    /// @notice Returns the total number of Kitties currently in existence.
    /// @dev Required for ERC-721 compliance.
    function totalSupply() public view returns (uint) {
        return arts.length;
    }

    /// @notice Returns the address currently assigned ownership of a given art.
    /// @dev Required for ERC-721 compliance.
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = artIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    /// @notice Returns a list of all art IDs assigned to an address.
    /// @param _owner The owner 
    /// @dev This method MUST NEVER be called by smart contract code. First, it's fairly
    ///  expensive 
    ///  but it also returns a dynamic array, which is only supported for web3 calls, and
    ///  not contract-to-contract calls.
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalArts = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the total count.
            uint256 artId;

            for (artId = 1; artId <= totalArts; artId++) {
                if (artIndexToOwner[artId] == _owner) {
                    result[resultIndex] = artId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Returns a URI pointing to a metadata package for this token conforming to
    ///  ERC-721 (https://github.com/ethereum/EIPs/issues/721)
    /// @param _tokenId The ID number of the art whose metadata should be returned.
    function tokenMetadata(uint256 _tokenId)view  external  returns (string memory) {

        return arts[_tokenId].ipfs;
    }

 
}