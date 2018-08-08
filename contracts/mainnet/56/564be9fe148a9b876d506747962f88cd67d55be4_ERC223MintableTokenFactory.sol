pragma solidity ^0.4.22;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/MainFabric.sol

//import "./tokens/ERC20StandardToken.sol";
//import "./tokens/ERC20MintableToken.sol";
//import "./crowdsale/RefundCrowdsale.sol";

contract MainFabric is Ownable {

    using SafeMath for uint256;

    struct Contract {
        address addr;
        address owner;
        address fabric;
        string contractType;
        uint256 index;
    }

    struct Fabric {
        address addr;
        address owner;
        bool isActive;
        uint256 index;
    }

    struct Admin {
        address addr;
        address[] contratcs;
        uint256 numContratcs;
        uint256 index;
    }

    // ---====== CONTRACTS ======---
    /**
     * @dev Get contract object by address
     */
    mapping(address => Contract) public contracts;

    /**
     * @dev Contracts addresses list
     */
    address[] public contractsAddr;

    /**
     * @dev Count of contracts in list
     */
    function numContracts() public view returns (uint256)
    { return contractsAddr.length; }


    // ---====== ADMINS ======---
    /**
     * @dev Get contract object by address
     */
    mapping(address => Admin) public admins;

    /**
     * @dev Contracts addresses list
     */
    address[] public adminsAddr;

    /**
     * @dev Count of contracts in list
     */
    function numAdmins() public view returns (uint256)
    { return adminsAddr.length; }

    function getAdminContract(address _adminAddress, uint256 _index) public view returns (
        address
    ) {
        return (
            admins[_adminAddress].contratcs[_index]
        );
    }

    // ---====== FABRICS ======---
    /**
     * @dev Get fabric object by address
     */
    mapping(address => Fabric) public fabrics;

    /**
     * @dev Fabrics addresses list
     */
    address[] public fabricsAddr;

    /**
     * @dev Count of fabrics in list
     */
    function numFabrics() public view returns (uint256)
    { return fabricsAddr.length; }

    /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyFabric() {
        require(fabrics[msg.sender].isActive);
        _;
    }

    // ---====== CONSTRUCTOR ======---

    function MainFabric() public {

    }

    /**
     * @dev Add fabric
     * @param _address Fabric address
     */
    function addFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        fabrics[_address].addr = _address;
        fabrics[_address].owner = msg.sender;
        fabrics[_address].isActive = true;
        fabrics[_address].index = fabricsAddr.push(_address) - 1;

        return true;
    }

    /**
     * @dev Remove fabric
     * @param _address Fabric address
     */
    function removeFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        require(fabrics[_address].isActive);
        fabrics[_address].isActive = false;

        uint rowToDelete = fabrics[_address].index;
        address keyToMove   = fabricsAddr[fabricsAddr.length-1];
        fabricsAddr[rowToDelete] = keyToMove;
        fabrics[keyToMove].index = rowToDelete;
        fabricsAddr.length--;

        return true;
    }

    /**
     * @dev Create refund crowdsale
     * @param _address Fabric address
     */
    function addContract(
        address _address,
        address _owner,
        string _contractType
    )
    public
    onlyFabric
    returns (bool)
    {
        contracts[_address].addr = _address;
        contracts[_address].owner = _owner;
        contracts[_address].fabric = msg.sender;
        contracts[_address].contractType = _contractType;
        contracts[_address].index = contractsAddr.push(_address) - 1;

        if (admins[_owner].addr != _owner) {
            admins[_owner].addr = _owner;
            admins[_owner].index = adminsAddr.push(_owner) - 1;
        }

        admins[_owner].contratcs.push(contracts[_address].addr);
        admins[_owner].numContratcs++;

        return true;
    }
}

// File: contracts/tokens/ERC223/ERC223_receiving_contract.sol

/**
* @title Contract that will work with ERC223 tokens.
*/

contract ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenFallback(address _from, uint _value, bytes _data);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
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

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/tokens/ERC223/ERC223.sol

/**
 * @title Reference implementation of the ERC223 standard token.
 */
contract ERC223 is StandardToken {

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    * @param _data Optional metadata.
    */
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        super.transfer(_to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            Transfer(msg.sender, _to, _value, _data);
        }

        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     * @param _data Optional metadata.
     */
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        super.transferFrom(_from, _to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        Transfer(_from, _to, _value, _data);
        return true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length>0);
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: contracts/tokens/ERC223MintableToken.sol

contract ERC223MintableToken is MintableToken, ERC223 {

    string public name = "";
    string public symbol = "";
    uint public decimals = 18;

    function ERC223MintableToken(string _name, string _symbol, uint8 _decimals, address _owner) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        owner = _owner;
    }
}

// File: contracts/factories/BaseFactory.sol

contract BaseFactory {

    address public mainFabricAddress;
    string public title;

    struct Parameter {
        string title;
        string paramType;
    }

    /**
     * @dev params list
     */
    Parameter[] public params;

    /**
     * @dev Count of parameters in factory
     */
    function numParameters() public view returns (uint256)
    {
        return params.length;
    }

    function getParam(uint _i) public view returns (
        string title,
        string paramType
    ) {
        return (
        params[_i].title,
        params[_i].paramType
        );
    }
}

// File: contracts/factories/ERC223MintableTokenFactory.sol

contract ERC223MintableTokenFactory is BaseFactory {

    function ERC223MintableTokenFactory(address _mainFactory) public {
        require(_mainFactory != 0x0);
        mainFabricAddress = _mainFactory;

        title = "ERC223MintableToken";

        params.push(Parameter({
            title: "Token name",
            paramType: "string"
            }));

        params.push(Parameter({
            title: "Token symbol",
            paramType: "string"
            }));

        params.push(Parameter({
            title: "Decimals",
            paramType: "string"
            }));

        params.push(Parameter({
            title: "Token owner",
            paramType: "string"
            }));
    }

    function create(string _name, string _symbol, uint8 _decimals, address _owner) public returns (ERC223MintableToken) {
        ERC223MintableToken newContract = new ERC223MintableToken(_name, _symbol, _decimals, _owner);

        MainFabric fabric = MainFabric(mainFabricAddress);
        fabric.addContract(address(newContract), msg.sender, title);

        return newContract;
    }
}