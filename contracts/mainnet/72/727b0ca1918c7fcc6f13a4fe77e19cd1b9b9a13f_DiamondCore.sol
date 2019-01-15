pragma solidity ^0.4.25;

  /**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
    
    
    /// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
    /// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="046061706144657c6d6b697e616a2a676b">[email&#160;protected]</a>> (https://github.com/dete)
    contract ERC721 {
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(string _diamondId) public view returns (address owner);
    function approve(address _to, string _diamondId) external;
    function transfer(address _to, string _diamondId) external;
    function transferFrom(address _from, address _to, string _diamondId) external;
    
    // Events
    event Transfer(address indexed from, address indexed to, string indexed diamondId);
    event Approval(address indexed owner, address indexed approved, string indexed diamondId);
    }
    
    contract DiamondAccessControl {
    
    address public CEO;
    
    mapping (address => bool) public admins;
    
    bool public paused = false;
    
    modifier onlyCEO() {
      require(msg.sender == CEO);
      _;
    }
    
    modifier onlyAdmin() {
      require(admins[msg.sender]);
      _;
    }
    
    /*** Pausable functionality adapted from OpenZeppelin ***/
    
    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
      require(!paused);
      _;
    }
    
    modifier onlyAdminOrCEO() 
{      require(admins[msg.sender] || msg.sender == CEO);
      _;
    }
    
    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
      require(paused);
      _;
    }
    
    function setCEO(address _newCEO) external onlyCEO {
      require(_newCEO != address(0));
      CEO = _newCEO;
    }
    
    function setAdmin(address _newAdmin, bool isAdmin) external onlyCEO {
      require(_newAdmin != address(0));
      admins[_newAdmin] = isAdmin;
    }
    
    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyAdminOrCEO whenNotPaused {
      paused = true;
    }
    
    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when admin account are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() external onlyCEO whenPaused {
      // can&#39;t unpause if contract was upgraded
      paused = false;
    }
}
    
/// @title Base contract for CryptoDiamond. Holds all common structs, events and base variables.
contract DiamondBase is DiamondAccessControl {
    
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, string indexed diamondId);
    event TransactionHistory(  
      string indexed _diamondId, 
      address indexed _seller, 
      string _sellerId, 
      address indexed _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice,
      uint256 timestamp
    );
    
    /*** DATA TYPE ***/
    /// @dev The main Diamond struct. Every dimond is represented by a copy of this structure
    struct Diamond {
      string ownerId;
      string status;
      string gemCompositeScore;
      string gemSubcategory;
      string media;
      string custodian;
      uint256 arrivalTime;
    }
    
    // variable to store total amount of diamonds
    uint256 internal total;
    
    // Mapping for checking the existence of token with such diamond ID
    mapping(string => bool) internal diamondExists;
    
    // Mapping from adress to number of diamonds owned by this address
    mapping(address => uint256) internal balances;
    
    // Mapping from diamond ID to owner address
    mapping (string => address) internal diamondIdToOwner;
    
    // Mapping from diamond ID to metadata
    mapping(string => Diamond) internal diamondIdToMetadata;
    
    // Mapping from diamond ID to an address that has been approved to call transferFrom()
    mapping(string => address) internal diamondIdToApproved;
    
    //Status Constants
    string constant STATUS_PENDING = "Pending";
    string constant STATUS_VERIFIED = "Verified";
    string constant STATUS_OUTSIDE  = "Outside";

    function _createDiamond(
      string _diamondId, 
      address _owner, 
      string _ownerId, 
      string _gemCompositeScore, 
      string _gemSubcategory, 
      string _media
    )  
      internal 
    {
      Diamond memory diamond;
      
      diamond.status = "Pending";
      diamond.ownerId = _ownerId;
      diamond.gemCompositeScore = _gemCompositeScore;
      diamond.gemSubcategory = _gemSubcategory;
      diamond.media = _media;
      
      diamondIdToMetadata[_diamondId] = diamond;

      total = total.add(1); 
      diamondExists[_diamondId] = true;
    
      _transfer(address(0), _owner, _diamondId); 
    }
    
    function _transferInternal(
      string _diamondId, 
      address _seller, 
      string _sellerId, 
      address _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice
    )   
      internal 
    {
      Diamond storage diamond = diamondIdToMetadata[_diamondId];
      diamond.ownerId = _buyerId;
      _transfer(_seller, _buyer, _diamondId);   
      emit TransactionHistory(_diamondId, _seller, _sellerId, _buyer, _buyerId, _usdPrice, _cedexPrice, now);
    
    }
    
    function _transfer(address _from, address _to, string _diamondId) internal {
      if (_from != address(0)) {
          balances[_from] = balances[_from].sub(1);
      }
      balances[_to] = balances[_to].add(1);
      diamondIdToOwner[_diamondId] = _to;
      delete diamondIdToApproved[_diamondId];
      emit Transfer(_from, _to, _diamondId);
    }
    
    function _burn(string _diamondId) internal {
      address _from = diamondIdToOwner[_diamondId];
      balances[_from] = balances[_from].sub(1);
      total = total.sub(1);
      delete diamondIdToOwner[_diamondId];
      delete diamondIdToMetadata[_diamondId];
      delete diamondExists[_diamondId];
      delete diamondIdToApproved[_diamondId];
      emit Transfer(_from, address(0), _diamondId);
    }
    
    function _isDiamondOutside(string _diamondId) internal view returns (bool) {
      require(diamondExists[_diamondId]);
      return keccak256(abi.encodePacked(diamondIdToMetadata[_diamondId].status)) == keccak256(abi.encodePacked(STATUS_OUTSIDE));
    }
    
    function _isDiamondVerified(string _diamondId) internal view returns (bool) {
      require(diamondExists[_diamondId]);
      return keccak256(abi.encodePacked(diamondIdToMetadata[_diamondId].status)) == keccak256(abi.encodePacked(STATUS_VERIFIED));
    }
}
    
/// @title The ontract that manages ownership, ERC-721 (draft) compliant.
contract DiamondBase721 is DiamondBase, ERC721 {
    
    function totalSupply() external view returns (uint256) {
      return total;
    }
    
    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) external view returns (uint256) {
      return balances[_owner];
    
    }
    
    /**
    * @dev Gets the owner of the specified diamond ID
    * @param _diamondId string ID of the diamond to query the owner of
    * @return owner address currently marked as the owner of the given diamond ID
    */
    function ownerOf(string _diamondId) public view returns (address) {
      require(diamondExists[_diamondId]);
      return diamondIdToOwner[_diamondId];
    }
    
    function approve(address _to, string _diamondId) external whenNotPaused {
      require(_isDiamondOutside(_diamondId));
      require(msg.sender == ownerOf(_diamondId));
      diamondIdToApproved[_diamondId] = _to;
      emit Approval(msg.sender, _to, _diamondId);
    }
    
    /**
    * @dev Transfers the ownership of a given diamond ID to another address
    * @param _to address to receive the ownership of the given diamond ID
    * @param _diamondId uint256 ID of the diamond to be transferred
    */
    function transfer(address _to, string _diamondId) external whenNotPaused {
      require(_isDiamondOutside(_diamondId));
      require(msg.sender == ownerOf(_diamondId));
      require(_to != address(0));
      require(_to != address(this));
      require(_to != ownerOf(_diamondId));
      _transfer(msg.sender, _to, _diamondId);
    }
    
    function transferFrom(address _from, address _to,  string _diamondId)
      external 
      whenNotPaused 
    {
      require(_isDiamondOutside(_diamondId));
      require(_from == ownerOf(_diamondId));
      require(_to != address(0));
      require(_to != address(this));
      require(_to != ownerOf(_diamondId));
      require(diamondIdToApproved[_diamondId] == msg.sender);
      _transfer(_from, _to, _diamondId);
    }
    
}
    
/// @dev The main contract, keeps track of diamonds.
contract DiamondCore is DiamondBase721 {

    /// @notice Creates the main Diamond smart contract instance.
    constructor() public {
      // the creator of the contract is the initial CEO
      CEO = msg.sender;
    }
    
    function createDiamond(
      string _diamondId, 
      address _owner, 
      string _ownerId, 
      string _gemCompositeScore, 
      string _gemSubcategory, 
      string _media
    ) 
      external 
      onlyAdminOrCEO 
      whenNotPaused 
    {
      require(!diamondExists[_diamondId]);
      require(_owner != address(0));
      require(_owner != address(this));
      _createDiamond( 
          _diamondId, 
          _owner, 
          _ownerId, 
          _gemCompositeScore, 
          _gemSubcategory, 
          _media
      );
    }
    
    function updateDiamond(
      string _diamondId, 
      string _custodian, 
      uint256 _arrivalTime
    ) 
      external 
      onlyAdminOrCEO 
      whenNotPaused 
    {
      require(!_isDiamondOutside(_diamondId));
      
      Diamond storage diamond = diamondIdToMetadata[_diamondId];
      
      diamond.status = "Verified";
      diamond.custodian = _custodian;
      diamond.arrivalTime = _arrivalTime;
    }
    
    function transferInternal(
      string _diamondId, 
      address _seller, 
      string _sellerId, 
      address _buyer, 
      string _buyerId, 
      uint256 _usdPrice, 
      uint256 _cedexPrice
    ) 
      external 
      onlyAdminOrCEO                                                                                                                                                                                                                                              
      whenNotPaused 
    {
      require(_isDiamondVerified(_diamondId));
      require(_seller == ownerOf(_diamondId));
      require(_buyer != address(0));
      require(_buyer != address(this));
      require(_buyer != ownerOf(_diamondId));
      _transferInternal(_diamondId, _seller, _sellerId, _buyer, _buyerId, _usdPrice, _cedexPrice);
    }
    
    function burn(string _diamondId) external onlyAdminOrCEO whenNotPaused {
      require(!_isDiamondOutside(_diamondId));
      _burn(_diamondId);
    }
    
    function getDiamond(string _diamondId) 
        external
        view
        returns(
            string ownerId,
            string status,
            string gemCompositeScore,
            string gemSubcategory,
            string media,
            string custodian,
            uint256 arrivalTime
        )
    {
        require(diamondExists[_diamondId]);
        
         ownerId = diamondIdToMetadata[_diamondId].ownerId;
         status = diamondIdToMetadata[_diamondId].status;
         gemCompositeScore = diamondIdToMetadata[_diamondId].gemCompositeScore;
         gemSubcategory = diamondIdToMetadata[_diamondId].gemSubcategory;
         media = diamondIdToMetadata[_diamondId].media;
         custodian = diamondIdToMetadata[_diamondId].custodian;
         arrivalTime = diamondIdToMetadata[_diamondId].arrivalTime;
    }
}