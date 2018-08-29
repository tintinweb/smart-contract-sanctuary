pragma solidity ^0.4.24;

// @title An interface to interact with Burnable ERC20 tokens 
interface BurnableERC20 { 

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function burnFrom(address _tokenHolder, uint _amount) external returns (bool success); 

}

/// @title A contract for burning MYB tokens as usage fee for dapps 
/// @author Kyle Dewhurst, MyBit Foundation
/// @notice Allows Dapps to call this contract to burn MYB as a usage fee
/// @dev This contract does not accept tokens. It only burns tokens from users wallets when approved to do so
contract MyBitBurner {

  BurnableERC20 public mybToken;  // The instance of the MyBitBurner contract
  address public owner;           // Owner can add or remove authorized contracts 

  mapping (address => bool) public authorizedBurner;    // A mapping showing which addresses are allowed to call the burn function

  // @notice constructor: instantiates myb token address and sets owner
  // @param (address) _myBitTokenAddress = The MyBit token address 
  constructor(address _myBitTokenAddress)
  public {
    mybToken = BurnableERC20(_myBitTokenAddress);
    owner = msg.sender;
  }

  // @notice authorized contracts can burn mybit tokens here if the user has approved this contract to do so
  // @param (address) _tokenHolder = the address of the mybit token holder who wishes to burn _amount of tokens 
  // @param (uint) _amount = the amount of tokens to be burnt (must include decimal places)
  function burn(address _tokenHolder, uint _amount)
  external
  returns (bool) {
    require(authorizedBurner[msg.sender]);
    require(mybToken.allowance(_tokenHolder, address(this)) >= _amount); 
    require(mybToken.burnFrom(_tokenHolder, _amount));
    emit LogMYBBurned(_tokenHolder, msg.sender, _amount);
    return true;
  }

  // @notice owner can authorize a contract to burn MyBit here 
  // @param the address of the mybit dapp contract
  function authorizeBurner(address _burningContract)
  external
  onlyOwner
  returns (bool) {
    require(!authorizedBurner[_burningContract]);
    authorizedBurner[_burningContract] = true;
    emit LogBurnerAuthorized(msg.sender, _burningContract);
    return true;
  }

  // @notice owner can revoke a contracts authorization to burn MyBit here 
  // @param the address of the mybit dapp contract
  function removeBurner(address _burningContract)
  external
  onlyOwner
  returns (bool) {
    require(authorizedBurner[_burningContract]);
    delete authorizedBurner[_burningContract];
    emit LogBurnerRemoved(msg.sender, _burningContract); 
    return true;
  }

  // @notice fallback function. Rejects all ether 
  function ()
  external { 
    revert(); 
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //                                            Modifiers
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // @notice reverts if msg.sender isn&#39;t the owner
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  event LogMYBBurned(address indexed _tokenHolder, address indexed _burningContract, uint _amount);
  event LogBurnerAuthorized(address _owner, address _burningContract);
  event LogBurnerRemoved(address _owner, address _burningContract); 
}