pragma solidity ^0.4.22;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address delegate;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    delegate = newOwner;
  }

  function confirmChangeOwnership() public {
    require(msg.sender == delegate);
    emit OwnershipTransferred(owner, delegate);
    owner = delegate;
    delegate = 0;
  }

}







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
}







contract TransferFilter is Ownable {
  bool public isTransferable;
  mapping( address => bool ) public mapAddressPass;
  mapping( address => bool ) public mapAddressBlock;

  event LogFilterPass(address indexed target, bool status);
  event LogFilterBlock(address indexed target, bool status);

  // if Token transfer
  modifier checkTokenTransfer(address source) {
      if (isTransferable == true) {
          require(mapAddressBlock[source] == false);
      }
      else {
          require(mapAddressPass[source] == true);
      }
      _;
  }

  constructor() public {
      isTransferable = true;
  }

  function setTransferable(bool status) public onlyOwner {
      isTransferable = status;
  }

  function isInPassFilter(address user) public view returns (bool) {
    return mapAddressPass[user];
  }

  function isInBlockFilter(address user) public view returns (bool) {
    return mapAddressBlock[user];
  }

  function addressToPass(address[] target, bool status)
  public
  onlyOwner
  {
    for( uint i = 0 ; i < target.length ; i++ ) {
        address targetAddress = target[i];
        bool old = mapAddressPass[targetAddress];
        if (old != status) {
            if (status == true) {
                mapAddressPass[targetAddress] = true;
                emit LogFilterPass(targetAddress, true);
            }
            else {
                delete mapAddressPass[targetAddress];
                emit LogFilterPass(targetAddress, false);
            }
        }
    }
  }

  function addressToBlock(address[] target, bool status)
  public
  onlyOwner
  {
      for( uint i = 0 ; i < target.length ; i++ ) {
          address targetAddress = target[i];
          bool old = mapAddressBlock[targetAddress];
          if (old != status) {
              if (status == true) {
                  mapAddressBlock[targetAddress] = true;
                  emit LogFilterBlock(targetAddress, true);
              }
              else {
                  delete mapAddressBlock[targetAddress];
                  emit LogFilterBlock(targetAddress, false);
              }
          }
      }
  }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, TransferFilter {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value)
  onlyPayloadSize(2 * 32)
  checkTokenTransfer(msg.sender)
  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value)
  onlyPayloadSize(3 * 32)
  checkTokenTransfer(_from)
  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)
  onlyPayloadSize(2 * 32)
  checkTokenTransfer(msg.sender)
  public returns (bool) {
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender,0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract BurnableToken is StandardToken {
  event Burn(address indexed from, uint256 value);

  function burn(address _from, uint256 _amount) public onlyOwner {
    require(_amount <= balances[_from]);
    totalSupply = totalSupply.sub(_amount);
    balances[_from] = balances[_from].sub(_amount);
    emit Transfer(_from, address(0), _amount);
    emit Burn(_from, _amount);
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is BurnableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  address public minter;

  constructor() public {
    minter = msg.sender;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasPermission() {
    require(msg.sender == owner || msg.sender == minter);
    _;
  }

  function () public payable {
    require(false);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) canMint hasPermission public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() canMint onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract VoltraCoin is MintableToken {

  string public constant name = "VoltraCoin"; // solium-disable-line uppercase
  string public constant symbol = "VLT"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply = 0;
  }
}