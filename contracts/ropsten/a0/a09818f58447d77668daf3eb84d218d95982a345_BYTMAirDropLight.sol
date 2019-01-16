pragma solidity ^0.4.24;

// File: contracts/ERC20-token.sol

/**
 * @title ERC20 interface 
 * 
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/OwnableWithAdmin.sol

/**
 * @title OwnableWithAdmin 
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract OwnableWithAdmin {
  address public owner;
  address public adminOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    adminOwner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    require(msg.sender == adminOwner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or admin.
   */
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == adminOwner || msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current adminOwner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferAdminOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(adminOwner, newOwner);
    adminOwner = newOwner;
  }

}

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }
 
  
}

// File: contracts/AirDropLight.sol

/**
 * @title AirDrop Light Direct Airdrop
 * @notice Contract is not payable.
 * Owner or admin can allocate tokens.
 * Tokens will be released direct. 
 *
 *
 */
contract AirDropLight is OwnableWithAdmin {
  using SafeMath for uint256;
  
  // Amount of tokens claimed
  uint256 public grandTotalClaimed = 0;

  // The token being sold
  ERC20 public token;

  // Max amount in one airdrop
  uint256  maxDirect = 10000 * (10**uint256(18));

  // Recipients
  mapping(address => bool) public recipients;

  // List of all addresses
  address[] public addresses;
   
  constructor(ERC20 _token) public {
     
    require(_token != address(0));

    token = _token;

  }

  
  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () public {
    //Not payable
  }


  /**
    * @dev Transfer tokens direct
    * @param _recipients Array of wallets
    * @param _tokenAmount Amount Allocated tokens + 18 decimals
    */
  function transferManyDirect (address[] _recipients, uint256 _tokenAmount) onlyOwnerOrAdmin  public{
    for (uint256 i = 0; i < _recipients.length; i++) {
      transferDirect(_recipients[i],_tokenAmount);
    }    
  }

        
  /**
    * @dev Transfer tokens direct to recipient without allocation. 
    * _recipient can only get one transaction and _tokens can&#39;t be above maxDirect value
    *  
    */
  function transferDirect(address _recipient,uint256 _tokens) public{

    //Check if contract has tokens
    require(token.balanceOf(this)>=_tokens);
    
    //Check max value
    require(_tokens < maxDirect );

    //Check if _recipient already have got tokens
    require(!recipients[_recipient]); 
    recipients[_recipient] = true;
  
    //Transfer tokens
    require(token.transfer(_recipient, _tokens));

    //Add claimed tokens to grandTotalClaimed
    grandTotalClaimed = grandTotalClaimed.add(_tokens); 
     
  }
  

  // Allow transfer of tokens back to owner or reserve wallet
  function returnTokens() public onlyOwner {
    uint256 balance = token.balanceOf(this);
    require(token.transfer(owner, balance));
  }

  // Owner can transfer tokens that are sent here by mistake
  function refundTokens(address _recipient, ERC20 _token) public onlyOwner {
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }

}

// File: contracts/BYTM/BYTMAirDropLight.sol

/**
 * @title BYTMAirDropLight
 *  
 *
*/
contract BYTMAirDropLight is AirDropLight {
  constructor(   
    ERC20 _token
  ) public AirDropLight(_token) {

     

  }
}