pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: registry/contracts/Registry.sol

contract Registry {
    struct AttributeData {
        uint256 value;
        bytes32 notes;
        address adminAddr;
        uint256 timestamp;
    }
    
    address public owner;
    address public pendingOwner;
    bool public initialized;

    // Stores arbitrary attributes for users. An example use case is an ERC20
    // token that requires its users to go through a KYC/AML check - in this case
    // a validator can set an account&#39;s "hasPassedKYC/AML" attribute to 1 to indicate
    // that account can use the token. This mapping stores that value (1, in the
    // example) as well as which validator last set the value and at what time,
    // so that e.g. the check can be renewed at appropriate intervals.
    mapping(address => mapping(bytes32 => AttributeData)) public attributes;
    // The logic governing who is allowed to set what attributes is abstracted as
    // this accessManager, so that it may be replaced by the owner as needed

    bytes32 public constant WRITE_PERMISSION = keccak256("canWriteTo-");

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SetAttribute(address indexed who, bytes32 attribute, uint256 value, bytes32 notes, address indexed adminAddr);
    event SetManager(address indexed oldManager, address indexed newManager);


    function initialize() public {
        require(!initialized, "already initialized");
        owner = msg.sender;
        initialized = true;
    }

    function writeAttributeFor(bytes32 _attribute) public pure returns (bytes32) {
        return keccak256(WRITE_PERMISSION ^ _attribute);
    }

    // Allows a write if either a) the writer is that Registry&#39;s owner, or
    // b) the writer is writing to attribute foo and that writer already has
    // the canWriteTo-foo attribute set (in that same Registry)
    function confirmWrite(bytes32 _attribute, address _admin) public view returns (bool) {
        return (_admin == owner || hasAttribute(_admin, keccak256(WRITE_PERMISSION ^ _attribute)));
    }

    // Writes are allowed only if the accessManager approves
    function setAttribute(address _who, bytes32 _attribute, uint256 _value, bytes32 _notes) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, _notes, msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, _notes, msg.sender);
    }

    function setAttributeValue(address _who, bytes32 _attribute, uint256 _value) public {
        require(confirmWrite(_attribute, msg.sender));
        attributes[_who][_attribute] = AttributeData(_value, "", msg.sender, block.timestamp);
        emit SetAttribute(_who, _attribute, _value, "", msg.sender);
    }

    // Returns true if the uint256 value stored for this attribute is non-zero
    function hasAttribute(address _who, bytes32 _attribute) public view returns (bool) {
        return attributes[_who][_attribute].value != 0;
    }

    function hasBothAttributes(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 && attributes[_who][_attribute2].value != 0;
    }

    function hasEitherAttribute(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 || attributes[_who][_attribute2].value != 0;
    }

    function hasAttribute1ButNotAttribute2(address _who, bytes32 _attribute1, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who][_attribute1].value != 0 && attributes[_who][_attribute2].value == 0;
    }

    function bothHaveAttribute(address _who1, address _who2, bytes32 _attribute) public view returns (bool) {
        return attributes[_who1][_attribute].value != 0 && attributes[_who2][_attribute].value != 0;
    }
    
    function eitherHaveAttribute(address _who1, address _who2, bytes32 _attribute) public view returns (bool) {
        return attributes[_who1][_attribute].value != 0 || attributes[_who2][_attribute].value != 0;
    }

    function haveAttributes(address _who1, bytes32 _attribute1, address _who2, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who1][_attribute1].value != 0 && attributes[_who2][_attribute2].value != 0;
    }

    function haveEitherAttribute(address _who1, bytes32 _attribute1, address _who2, bytes32 _attribute2) public view returns (bool) {
        return attributes[_who1][_attribute1].value != 0 || attributes[_who2][_attribute2].value != 0;
    }

    // Returns the exact value of the attribute, as well as its metadata
    function getAttribute(address _who, bytes32 _attribute) public view returns (uint256, bytes32, address, uint256) {
        AttributeData memory data = attributes[_who][_attribute];
        return (data.value, data.notes, data.adminAddr, data.timestamp);
    }

    function getAttributeValue(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].value;
    }

    function getAttributeAdminAddr(address _who, bytes32 _attribute) public view returns (address) {
        return attributes[_who][_attribute].adminAddr;
    }

    function getAttributeTimestamp(address _who, bytes32 _attribute) public view returns (uint256) {
        return attributes[_who][_attribute].timestamp;
    }

    function reclaimEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    function reclaimToken(ERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

    /**
    * @dev sets the original `owner` of the contract to the sender
    * at construction. Must then be reinitialized 
    */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/modularERC20/BalanceSheet.sol

// A wrapper around the balanceOf mapping.
contract BalanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => uint256) public balanceOf;

    function addBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].add(_value);
    }

    function subBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = balanceOf[_addr].sub(_value);
    }

    function setBalance(address _addr, uint256 _value) public onlyOwner {
        balanceOf[_addr] = _value;
    }
}

// File: contracts/modularERC20/AllowanceSheet.sol

// A wrapper around the allowanceOf mapping.
contract AllowanceSheet is Claimable {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) public allowanceOf;

    function addAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].add(_value);
    }

    function subAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = allowanceOf[_tokenHolder][_spender].sub(_value);
    }

    function setAllowance(address _tokenHolder, address _spender, uint256 _value) public onlyOwner {
        allowanceOf[_tokenHolder][_spender] = _value;
    }
}

// File: contracts/utilities/GlobalPause.sol

/*
All future trusttoken tokens can reference this contract. 
Allow for Admin to pause a set of tokens with one transaction
Used to signal which fork is the supported fork for asset-back tokens
*/
contract GlobalPause is Claimable {
    bool public allTokensPaused = false;
    string public pauseNotice;

    function pauseAllTokens(bool _status, string _notice) public onlyOwner {
        allTokensPaused = _status;
        pauseNotice = _notice;
    }

    function requireNotPaused() public view {
        require(!allTokensPaused, pauseNotice);
    }
}

// File: contracts/ProxyStorage.sol

/*
Defines the storage layout of the implementaiton (TrueUSD) contract. Any newly declared 
state variables in future upgrades should be appened to the bottom. Never remove state variables
from this list
 */
contract ProxyStorage {
    address public owner;
    address public pendingOwner;

    bool public initialized;
    
    BalanceSheet public balances;
    AllowanceSheet public allowances;

    uint256 totalSupply_;
    
    bool public paused = false;
    GlobalPause public globalPause;

    uint256 public burnMin = 0;
    uint256 public burnMax = 0;

    Registry public registry;

    string public name = "TrueUSD";
    string public symbol = "TUSD";

    uint[] public gasRefundPool;
    uint256 public redemptionAddressCount;
}

// File: contracts/HasOwner.sol

/**
 * @title HasOwner
 * @dev The HasOwner contract is a copy of Claimable Contract by Zeppelin. 
 and provides basic authorization control functions. Inherits storage layout of 
 ProxyStorage.
 */
contract HasOwner is ProxyStorage {

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
    * @dev sets the original `owner` of the contract to the sender
    * at construction. Must then be reinitialized 
    */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/modularERC20/ModularBasicToken.sol

// Version of OpenZeppelin&#39;s BasicToken whose balances mapping has been replaced
// with a separate BalanceSheet contract. remove the need to copy over balances.
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract ModularBasicToken is HasOwner {
    using SafeMath for uint256;

    event BalanceSheetSet(address indexed sheet);
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
    * @dev claim ownership of the balancesheet contract
    * @param _sheet The address to of the balancesheet to claim.
    */
    function setBalanceSheet(address _sheet) public onlyOwner returns (bool) {
        balances = BalanceSheet(_sheet);
        balances.claimOwnership();
        emit BalanceSheetSet(_sheet);
        return true;
    }

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
        _transferAllArgs(msg.sender, _to, _value);
        return true;
    }


    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        // SafeMath.sub will throw if there is not enough balance.
        balances.subBalance(_from, _value);
        balances.addBalance(_to, _value);
        emit Transfer(_from, _to, _value);
    }
    

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances.balanceOf(_owner);
    }
}

// File: contracts/modularERC20/ModularStandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ModularStandardToken is ModularBasicToken {
    
    event AllowanceSheetSet(address indexed sheet);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
    * @dev claim ownership of the AllowanceSheet contract
    * @param _sheet The address to of the AllowanceSheet to claim.
    */
    function setAllowanceSheet(address _sheet) public onlyOwner returns(bool) {
        allowances = AllowanceSheet(_sheet);
        allowances.claimOwnership();
        emit AllowanceSheetSet(_sheet);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transferFromAllArgs(_from, _to, _value, msg.sender);
        return true;
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        require(_value <= allowances.allowanceOf(_from, _spender),"not enough allowance to transfer");

        _transferAllArgs(_from, _to, _value);
        allowances.subAllowance(_from, _spender, _value);
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
        _approveAllArgs(_spender, _value, msg.sender);
        return true;
    }

    function _approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal {
        allowances.setAllowance(_tokenHolder, _spender, _value);
        emit Approval(_tokenHolder, _spender, _value);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances.allowanceOf(_owner, _spender);
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
        _increaseApprovalAllArgs(_spender, _addedValue, msg.sender);
        return true;
    }

    function _increaseApprovalAllArgs(address _spender, uint256 _addedValue, address _tokenHolder) internal {
        allowances.addAllowance(_tokenHolder, _spender, _addedValue);
        emit Approval(_tokenHolder, _spender, allowances.allowanceOf(_tokenHolder, _spender));
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
        _decreaseApprovalAllArgs(_spender, _subtractedValue, msg.sender);
        return true;
    }

    function _decreaseApprovalAllArgs(address _spender, uint256 _subtractedValue, address _tokenHolder) internal {
        uint256 oldValue = allowances.allowanceOf(_tokenHolder, _spender);
        if (_subtractedValue > oldValue) {
            allowances.setAllowance(_tokenHolder, _spender, 0);
        } else {
            allowances.subAllowance(_tokenHolder, _spender, _subtractedValue);
        }
        emit Approval(_tokenHolder,_spender, allowances.allowanceOf(_tokenHolder, _spender));
    }
}

// File: contracts/modularERC20/ModularBurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ModularBurnableToken is ModularStandardToken {
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        _burnAllArgs(msg.sender, _value);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
        require(_value <= balances.balanceOf(_burner), "not enough balance to burn");
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        /* uint burnAmount = _value / (10 **16) * (10 **16); */
        balances.subBalance(_burner, _value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_burner, _value);
        emit Transfer(_burner, address(0), _value);
    }
}

// File: contracts/modularERC20/ModularMintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract ModularMintableToken is ModularBurnableToken {
    event Mint(address indexed to, uint256 value);

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0), "to address cannot be zero");
        totalSupply_ = totalSupply_.add(_value);
        balances.addBalance(_to, _value);
        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
    }
}

// File: contracts/modularERC20/ModularPausableToken.sol

/**
 * @title Pausable token
 * @dev MintableToken modified with pausable transfers.
 **/
contract ModularPausableToken is ModularMintableToken {

    event Pause();
    event Unpause();
    event GlobalPauseSet(address indexed newGlobalPause);

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Token Paused");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Token Not Paused");
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }


    //All erc20 transactions are paused when not on the supported fork
    modifier onSupportedChain() {
        globalPause.requireNotPaused();
        _;
    }

    function setGlobalPause(address _newGlobalPause) external onlyOwner {
        globalPause = GlobalPause(_newGlobalPause);
        emit GlobalPauseSet(_newGlobalPause);
    }
    
    function _transferAllArgs(address _from, address _to, uint256 _value) internal whenNotPaused onSupportedChain {
        super._transferAllArgs(_from, _to, _value);
    }

    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal whenNotPaused onSupportedChain {
        super._transferFromAllArgs(_from, _to, _value, _spender);
    }

    function _approveAllArgs(address _spender, uint256 _value, address _tokenHolder) internal whenNotPaused onSupportedChain {
        super._approveAllArgs(_spender, _value, _tokenHolder);
    }

    function _increaseApprovalAllArgs(address _spender, uint256 _addedValue, address _tokenHolder) internal whenNotPaused onSupportedChain {
        super._increaseApprovalAllArgs(_spender, _addedValue, _tokenHolder);
    }

    function _decreaseApprovalAllArgs(address _spender, uint256 _subtractedValue, address _tokenHolder) internal whenNotPaused onSupportedChain {
        super._decreaseApprovalAllArgs(_spender, _subtractedValue, _tokenHolder);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal whenNotPaused onSupportedChain {
        super._burnAllArgs(_burner, _value);
    }
}

// File: contracts/BurnableTokenWithBounds.sol

/**
 * @title Burnable Token WithBounds
 * @dev Burning functions as redeeming money from the system. The platform will keep track of who burns coins,
 * and will send them back the equivalent amount of money (rounded down to the nearest cent).
 */
contract BurnableTokenWithBounds is ModularPausableToken {

    event SetBurnBounds(uint256 newMin, uint256 newMax);

    function _burnAllArgs(address _burner, uint256 _value) internal {
        require(_value >= burnMin, "below min burn bound");
        require(_value <= burnMax, "exceeds max burn bound");
        super._burnAllArgs(_burner, _value);
    }

    //Change the minimum and maximum amount that can be burned at once. Burning
    //may be disabled by setting both to 0 (this will not be done under normal
    //operation, but we can&#39;t add checks to disallow it without losing a lot of
    //flexibility since burning could also be as good as disabled
    //by setting the minimum extremely high, and we don&#39;t want to lock
    //in any particular cap for the minimum)
    function setBurnBounds(uint256 _min, uint256 _max) public onlyOwner {
        require(_min <= _max, "min > max");
        burnMin = _min;
        burnMax = _max;
        emit SetBurnBounds(_min, _max);
    }
}

// File: contracts/CompliantToken.sol

/**
 * @title Compliant Token
 */
contract CompliantToken is ModularPausableToken {
    // In order to deposit USD and receive newly minted TrueUSD, or to burn TrueUSD to
    // redeem it for USD, users must first go through a KYC/AML check (which includes proving they
    // control their ethereum address using AddressValidation.sol).
    bytes32 public constant HAS_PASSED_KYC_AML = "hasPassedKYC/AML";
    // Redeeming ("burning") TrueUSD tokens for USD requires a separate flag since
    // users must not only be KYC/AML&#39;ed but must also have bank information on file.
    bytes32 public constant CAN_BURN = "canBurn";
    // Addresses can also be blacklisted, preventing them from sending or receiving
    // TrueUSD. This can be used to prevent the use of TrueUSD by bad actors in
    // accordance with law enforcement. See [TrueCoin Terms of Use](https://www.trusttoken.com/trueusd/terms-of-use)
    bytes32 public constant IS_BLACKLISTED = "isBlacklisted";

    event WipeBlacklistedAccount(address indexed account, uint256 balance);
    event SetRegistry(address indexed registry);
    
    
    /**
    * @dev Point to the registry that contains all compliance related data
    @param _registry The address of the registry instance
    */
    function setRegistry(Registry _registry) public onlyOwner {
        registry = _registry;
        emit SetRegistry(registry);
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        require(registry.hasAttribute1ButNotAttribute2(_to, HAS_PASSED_KYC_AML, IS_BLACKLISTED), "_to cannot mint");
        super.mint(_to, _value);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
        require(registry.hasAttribute1ButNotAttribute2(_burner, CAN_BURN, IS_BLACKLISTED), "_burner cannot burn");
        super._burnAllArgs(_burner, _value);
    }

    // A blacklisted address can&#39;t call transferFrom
    function _transferFromAllArgs(address _from, address _to, uint256 _value, address _spender) internal {
        require(!registry.hasAttribute(_spender, IS_BLACKLISTED), "_spender is blacklisted");
        super._transferFromAllArgs(_from, _to, _value, _spender);
    }

    // transfer and transferFrom both call this function, so check blacklist here.
    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        require(!registry.eitherHaveAttribute(_from, _to, IS_BLACKLISTED), "blacklisted");
        super._transferAllArgs(_from, _to, _value);
    }

    // Destroy the tokens owned by a blacklisted account
    function wipeBlacklistedAccount(address _account) public onlyOwner {
        require(registry.hasAttribute(_account, IS_BLACKLISTED), "_account is not blacklisted");
        uint256 oldValue = balanceOf(_account);
        balances.setBalance(_account, 0);
        totalSupply_ = totalSupply_.sub(oldValue);
        emit WipeBlacklistedAccount(_account, oldValue);
        emit Transfer(_account, address(0), oldValue);
    }
}

// File: contracts/RedeemableToken.sol

/** @title Redeemable Token 
Makes transfers to 0x0 alias to Burn
Implement Redemption Addresses
*/
contract RedeemableToken is ModularPausableToken {

    event RedemptionAddress(address indexed addr);

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        if (_to == address(0)) {
            revert("_to address is 0x0");
        } else if (uint(_to) <= redemptionAddressCount) {
            // Transfers to redemption addresses becomes burn
            super._transferAllArgs(_from, _to, _value);
            _burnAllArgs(_to, _value);
        } else {
            super._transferAllArgs(_from, _to, _value);
        }
    }
    
    function incrementRedemptionAddressCount() external onlyOwner {
        emit RedemptionAddress(address(redemptionAddressCount));
        redemptionAddressCount += 1;
    }
}

// File: contracts/DepositToken.sol

/** @title Deposit Token
Allows users to register their address so that all transfers to deposit addresses
of the registered address will be forwarded to the registered address.  
For example for address 0x9052BE99C9C8C5545743859e4559A751bDe4c923,
its deposit addresses are all addresses between
0x9052BE99C9C8C5545743859e4559A75100000 and 0x9052BE99C9C8C5545743859e4559A751fffff
Transfers to 0x9052BE99C9C8C5545743859e4559A75100005 will be forwared to 0x9052BE99C9C8C5545743859e4559A751bDe4c923
 */
contract DepositToken is ModularPausableToken {
    
    bytes32 public constant IS_DEPOSIT_ADDRESS = "isDepositAddress"; 

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        address shiftedAddress = address(uint(_to) >> 20);
        uint depositAddressValue = registry.getAttributeValue(shiftedAddress, IS_DEPOSIT_ADDRESS);
        if (depositAddressValue != 0) {
            super._transferAllArgs(_from, _to, _value);
            super._transferAllArgs(_to, address(depositAddressValue), _value);
        } else {
            super._transferAllArgs(_from, _to, _value);
        }
    }

    function mint(address _to, uint256 _value) public onlyOwner {
        address shiftedAddress = address(uint(_to) >> 20);
        uint depositAddressValue = registry.getAttributeValue(shiftedAddress, IS_DEPOSIT_ADDRESS);
        if (depositAddressValue != 0) {
            super.mint(_to, _value);
            super._transferAllArgs(_to, address(depositAddressValue), _value);
        } else {
            super.mint(_to, _value);
        }
    }
}

// File: contracts/GasRefundToken.sol

/**  
@title Gas Refund Token
Allow any user to sponsor gas refunds for transfer and mints. Utilitzes the gas refund mechanism in EVM
Each time an non-empty storage slot is set to 0, evm refund 15,000 (19,000 after Constantinople) to the sender
of the transaction. 
*/
contract GasRefundToken is ModularPausableToken {

    function sponsorGas() external {
        uint256 len = gasRefundPool.length;
        gasRefundPool.length = len + 9;
        gasRefundPool[len] = 1;
        gasRefundPool[len + 1] = 1;
        gasRefundPool[len + 2] = 1;
        gasRefundPool[len + 3] = 1;
        gasRefundPool[len + 4] = 1;
        gasRefundPool[len + 5] = 1;
        gasRefundPool[len + 6] = 1;
        gasRefundPool[len + 7] = 1;
        gasRefundPool[len + 8] = 1;
    }  

    /**  
    @dev refund up to 45,000 (57,000 after Constantinople) gas for functions with 
    gasRefund modifier.
    */
    modifier gasRefund {
        uint256 len = gasRefundPool.length;
        if (len != 0) {
            gasRefundPool[--len] = 0;
            gasRefundPool[--len] = 0;
            gasRefundPool[--len] = 0;
            gasRefundPool.length = len;
        }   
        _;  
    }

    /**  
    *@dev Return the remaining sponsored gas slots
    */
    function remainingGasRefundPool() public view returns(uint) {
        return gasRefundPool.length;
    }

    function _transferAllArgs(address _from, address _to, uint256 _value) internal gasRefund {
        super._transferAllArgs(_from, _to, _value);
    }

    function mint(address _to, uint256 _value) public onlyOwner gasRefund {
        super.mint(_to, _value);
    }
}

// File: contracts/TrueCoinReceiver.sol

contract TrueCoinReceiver {
    function tokenFallback( address from, uint256 value ) external;
}

// File: contracts/TokenWithHook.sol

/** @title Token With Hook
If tokens are transferred to a Registered Token Receiver contract, trigger the tokenFallback function in the 
Token Receiver contract. Assume all Registered Token Receiver contract implements the TrueCoinReceiver 
interface. If the tokenFallback reverts, the entire transaction reverts. 
 */
contract TokenWithHook is ModularPausableToken {
    
    bytes32 public constant IS_REGISTERED_CONTRACT = "isRegisteredContract"; 

    function _transferAllArgs(address _from, address _to, uint256 _value) internal {
        uint length;
        assembly { length := extcodesize(_to) }
        super._transferAllArgs(_from, _to, _value);
        if (length > 0) {
            if(registry.hasAttribute(_to, IS_REGISTERED_CONTRACT)) {
                TrueCoinReceiver(_to).tokenFallback(_from, _value);
            }
        }
    }
}

// File: contracts/DelegateERC20.sol

/** @title DelegateERC20
Accept forwarding delegation calls from the old TrueUSD (V1) contract. THis way the all the ERC20
functions in the old contract still works (except Burn). 
*/
contract DelegateERC20 is ModularStandardToken {

    address public constant DELEGATE_FROM = 0x8dd5fbCe2F6a956C3022bA3663759011Dd51e73E;
    
    modifier onlyDelegateFrom() {
        require(msg.sender == DELEGATE_FROM);
        _;
    }

    function delegateTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function delegateBalanceOf(address who) public view returns (uint256) {
        return balanceOf(who);
    }

    function delegateTransfer(address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferAllArgs(origSender, to, value);
        return true;
    }

    function delegateAllowance(address owner, address spender) public view returns (uint256) {
        return allowance(owner, spender);
    }

    function delegateTransferFrom(address from, address to, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _transferFromAllArgs(from, to, value, origSender);
        return true;
    }

    function delegateApprove(address spender, uint256 value, address origSender) public onlyDelegateFrom returns (bool) {
        _approveAllArgs(spender, value, origSender);
        return true;
    }

    function delegateIncreaseApproval(address spender, uint addedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _increaseApprovalAllArgs(spender, addedValue, origSender);
        return true;
    }

    function delegateDecreaseApproval(address spender, uint subtractedValue, address origSender) public onlyDelegateFrom returns (bool) {
        _decreaseApprovalAllArgs(spender, subtractedValue, origSender);
        return true;
    }
}

// File: contracts/TrueUSD.sol

/** @title TrueUSD
* @dev This is the top-level ERC20 contract, but most of the interesting functionality is
* inherited - see the documentation on the corresponding contracts.
*/
contract TrueUSD is 
ModularPausableToken, 
BurnableTokenWithBounds, 
CompliantToken,
RedeemableToken,
TokenWithHook,
DelegateERC20,
DepositToken,
GasRefundToken {
    using SafeMath for *;

    uint8 public constant DECIMALS = 18;
    uint8 public constant ROUNDING = 2;

    event ChangeTokenName(string newName, string newSymbol);

    function decimals() public returns (uint8) {
      return DECIMALS;
    }

    function rounding() public returns (uint8) {
      return ROUNDING;
    }

    function changeTokenName(string _name, string _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
        emit ChangeTokenName(_name, _symbol);
    }

    /**  
    *@dev send all eth balance in the TrueUSD contract to another address
    */
    function reclaimEther(address _to) external onlyOwner {
        _to.transfer(address(this).balance);
    }

    /**  
    *@dev send all token balance of an arbitary erc20 token
    in the TrueUSD contract to another address
    */
    function reclaimToken(ERC20 token, address _to) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(_to, balance);
    }

    /**  
    *@dev allows owner of TrueUSD to gain ownership of any contract that TrueUSD currently owns
    */
    function reclaimContract(Ownable _ownable) external onlyOwner {
        _ownable.transferOwnership(owner);
    }

    function _burnAllArgs(address _burner, uint256 _value) internal {
        //round down burn amount so that the lowest amount allowed is 1 cent
        uint burnAmount = _value.div(10 ** uint256(DECIMALS - ROUNDING)).mul(10 ** uint256(DECIMALS - ROUNDING));
        super._burnAllArgs(_burner, burnAmount);
    }
}