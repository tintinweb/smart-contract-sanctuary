/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity 0.5.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public delegate;

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
    require(msg.sender == owner, "You must be owner.");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid new owner address.");
    delegate = newOwner;
  }

  function confirmChangeOwnership() public {
    require(msg.sender == delegate, "You must be delegate.");
    emit OwnershipTransferred(owner, delegate);
    owner = delegate;
    delegate = address(0);
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
    require(c / a == b, "Multiplying uint256 overflow.");
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Dividing by zero is not allowed.");
    uint256 c = a / b;
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Negative uint256 is now allowed.");
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "Adding uint256 overflow.");
    return c;
  }
}







contract TransferFilter is Ownable {
  bool public isTransferable;
  mapping( address => bool ) internal mapAddressPass;
  mapping( address => bool ) internal mapAddressBlock;

  event LogSetTransferable(bool transferable);
  event LogFilterPass(address indexed target, bool status);
  event LogFilterBlock(address indexed target, bool status);

  // if Token transfer
  modifier checkTokenTransfer(address source) {
      if (isTransferable) {
          require(!mapAddressBlock[source], "Source address is in block filter.");
      }
      else {
          require(mapAddressPass[source], "Source address must be in pass filter.");
      }
      _;
  }

  constructor() public {
      isTransferable = true;
  }

  function setTransferable(bool transferable) external onlyOwner {
      isTransferable = transferable;
      emit LogSetTransferable(transferable);
  }

  function isInPassFilter(address user) external view returns (bool) {
    return mapAddressPass[user];
  }

  function isInBlockFilter(address user) external view returns (bool) {
    return mapAddressBlock[user];
  }

  function addressToPass(address[] calldata target, bool status)
  external
  onlyOwner
  {
    for( uint i = 0 ; i < target.length ; i++ ) {
        address targetAddress = target[i];
        bool old = mapAddressPass[targetAddress];
        if (old != status) {
            if (status) {
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

  function addressToBlock(address[] calldata target, bool status)
  external
  onlyOwner
  {
      for( uint i = 0 ; i < target.length ; i++ ) {
          address targetAddress = target[i];
          bool old = mapAddressBlock[targetAddress];
          if (old != status) {
              if (status) {
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

  mapping(address => uint256) internal balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyPayloadSize(uint8 param) {
    // Check payload size to prevent short address attack.
    // Payload size must be longer than sum of methodID length and size of parameters.
    require(msg.data.length >= param * 32 + 4);
    _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value)
  onlyPayloadSize(2) // number of parameters
  checkTokenTransfer(msg.sender)
  public returns (bool) {
    require(_to != address(0), "Invalid destination address.");

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
  onlyPayloadSize(3) // number of parameters
  checkTokenTransfer(_from)
  public returns (bool) {
    require(_from != address(0), "Invalid source address.");
    require(_to != address(0), "Invalid destination address.");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    uint256 _allowedValue = allowed[_from][msg.sender].sub(_value);
    allowed[_from][msg.sender] = _allowedValue;
    emit Transfer(_from, _to, _value);
    emit Approval(_from, msg.sender, _allowedValue);
    return true;
  }

  function approve(address _spender, uint256 _value)
  onlyPayloadSize(2) // number of parameters
  checkTokenTransfer(msg.sender)
  public returns (bool) {
    require(_spender != address(0), "Invalid spender address.");

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender,0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0), "Already approved.");

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

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken {
  event MinterTransferred(address indexed previousMinter, address indexed newMinter);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address indexed from, uint256 value);

  bool public mintingFinished = false;
  address public minter;

  constructor() public {
    minter = msg.sender;
    emit MinterTransferred(address(0), minter);
  }

  modifier canMint() {
    require(!mintingFinished, "Minting is already finished.");
    _;
  }

  modifier hasPermission() {
    require(msg.sender == owner || msg.sender == minter, "You must be either owner or minter.");
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) canMint hasPermission external returns (bool) {
    require(_to != address(0), "Invalid destination address.");

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
  function finishMinting() canMint onlyOwner external returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

  function transferMinter(address newMinter) public onlyOwner {
    require(newMinter != address(0), "Invalid new minter address.");
    address prevMinter = minter;
    minter = newMinter;
    emit MinterTransferred(prevMinter, minter);
  }

  function burn(address _from, uint256 _amount) external hasPermission {
    require(_from != address(0), "Invalid source address.");

    balances[_from] = balances[_from].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
    emit Burn(_from, _amount);
  }
}


contract ZCON is MintableToken {
  string public constant name = "ZCON Protocol"; // solium-disable-line uppercase
  string public constant symbol = "ZCON"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  /**
   * @dev Constructor that initialize token.
   */
  constructor() public {
    //totalSupply = 0;
  }
}