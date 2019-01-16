pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract DetailedToken {
  string public name;
  string public symbol;
  uint8 public decimals;
}

contract KeyValueStorage {

  mapping(address => mapping(bytes32 => uint256)) _uintStorage;
  mapping(address => mapping(bytes32 => address)) _addressStorage;
  mapping(address => mapping(bytes32 => bool)) _boolStorage;

  /**** Get Methods ***********/

  function getAddress(bytes32 key) public view returns (address) {
      return _addressStorage[msg.sender][key];
  }

  function getUint(bytes32 key) public view returns (uint) {
      return _uintStorage[msg.sender][key];
  }

  function getBool(bytes32 key) public view returns (bool) {
      return _boolStorage[msg.sender][key];
  }

  /**** Set Methods ***********/

  function setAddress(bytes32 key, address value) public {
    _addressStorage[msg.sender][key] = value;
  }

  function setUint(bytes32 key, uint value) public {
      _uintStorage[msg.sender][key] = value;
  }

  function setBool(bytes32 key, bool value) public {
      _boolStorage[msg.sender][key] = value;
  }

  /**** Delete Methods ***********/

  function deleteAddress(bytes32 key) public {
      delete _addressStorage[msg.sender][key];
  }

  function deleteUint(bytes32 key) public {
      delete _uintStorage[msg.sender][key];
  }

  function deleteBool(bytes32 key) public {
      delete _boolStorage[msg.sender][key];
  }

}

contract Proxy is Ownable {

  event Upgraded(address indexed implementation);

  address internal _implementation;

  function implementation() public view returns (address) {
    return _implementation;
  }

  function upgradeTo(address impl) public onlyOwner {
    require(_implementation != impl);
    _implementation = impl;
    Upgraded(impl);
  }
 
  function () payable public {
    address _impl = implementation();
    require(_impl != address(0));
    bytes memory data = msg.data;

    assembly {
      let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
      let size := returndatasize
      let ptr := mload(0x40)
      returndatacopy(ptr, 0, size)
      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }

}

contract StorageStateful {
    
  KeyValueStorage _storage;
  
}

contract StorageConsumer is StorageStateful {
    
  constructor(KeyValueStorage storage_) public {
    _storage = storage_;
  }
  
}

contract ShrimpCoin is StorageConsumer, Proxy, DetailedToken {

  constructor(KeyValueStorage storage_)
    public
    StorageConsumer(storage_)
  {
    // set some immutable state
    name = "ShrimpCoin";
    symbol = "SHRMP";
    decimals = 18;

    // set token owner in the key-value store
    storage_.setAddress("owner", msg.sender);
  }

}

contract TokenDelegate is StorageStateful {
  using SafeMath for uint256;

  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));
    require(value <= getBalance(msg.sender));

    subBalance(msg.sender, value);
    addBalance(to, value);
    return true;
  }

  function balanceOf(address owner) public view returns (uint256 balance) {
    return getBalance(owner);
  }

  function getBalance(address balanceHolder) public view returns (uint256) {
    return _storage.getUint(keccak256("balances", balanceHolder));
  }

  function totalSupply() public view returns (uint256) {
    return _storage.getUint("totalSupply");
  }

  function addSupply(uint256 amount) internal {
    _storage.setUint("totalSupply", totalSupply().add(amount));
  }

  function addBalance(address balanceHolder, uint256 amount) internal {
    setBalance(balanceHolder, getBalance(balanceHolder).add(amount));
  }

  function subBalance(address balanceHolder, uint256 amount) internal {
    setBalance(balanceHolder, getBalance(balanceHolder).sub(amount));
  }

  function setBalance(address balanceHolder, uint256 amount) internal {
    _storage.setUint(keccak256("balances", balanceHolder), amount);
  }

}

contract MintableTokenDelegate is TokenDelegate {

  modifier onlyOwner {
    require(msg.sender == _storage.getAddress("owner"));
    _;
  }
  
  modifier canMint() {
    require(!_storage.getBool("mintingFinished"));
    _;
  }

  function mint(address to, uint256 amount) onlyOwner canMint public returns (bool) {
    addSupply(amount);
    addBalance(to, amount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    _storage.setBool("mintingFinished", true);
    return true;
  }

}