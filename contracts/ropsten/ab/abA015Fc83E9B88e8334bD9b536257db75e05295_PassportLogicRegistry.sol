pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d3a1b6beb0bc93e1">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1062757d737f5022">[email&#160;protected]</a>π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param _from address The address that is transferring the tokens
  * @param _value uint256 the amount of the specified token
  * @param _data Bytes The data passed from the caller.
  */
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

// File: contracts/IPassportLogicRegistry.sol

interface IPassportLogicRegistry {
    /**
     * @dev This event will be emitted every time a new passport logic implementation is registered
     * @param version representing the version name of the registered passport logic implementation
     * @param implementation representing the address of the registered passport logic implementation
     */
    event PassportLogicAdded(string version, address implementation);

    /**
     * @dev This event will be emitted every time a new passport logic implementation is set as current one
     * @param version representing the version name of the current passport logic implementation
     * @param implementation representing the address of the current passport logic implementation
     */
    event CurrentPassportLogicSet(string version, address implementation);

    /**
     * @dev Tells the address of the passport logic implementation for a given version
     * @param _version to query the implementation of
     * @return address of the passport logic implementation registered for the given version
     */
    function getPassportLogic(string _version) external view returns (address);

    /**
     * @dev Tells the version of the current passport logic implementation
     * @return version of the current passport logic implementation
     */
    function getCurrentPassportLogicVersion() external view returns (string);

    /**
     * @dev Tells the address of the current passport logic implementation
     * @return address of the current passport logic implementation
     */
    function getCurrentPassportLogic() external view returns (address);
}

// File: contracts/PassportLogicRegistry.sol

/**
 * @title PassportImplRegistry
 * @dev This contract works as a registry of passport implementations, it holds the implementations for the registered versions.
 */
contract PassportLogicRegistry is IPassportLogicRegistry, Ownable, HasNoEther, HasNoTokens {
    // current passport version/implementation
    string internal currentPassportLogicVersion;
    address internal currentPassportLogic;

    // Mapping of versions to passport implementations
    mapping(string => address) internal passportLogicImplementations;

    /**
     * @dev The PassportImplRegistry constructor sets the current passport version and implementation.
     */
    constructor (string _version, address _implementation) public {
        _addPassportLogic(_version, _implementation);
        _setCurrentPassportLogic(_version);
    }

    /**
     * @dev Registers a new passport version with its logic implementation address
     * @param _version representing the version name of the new passport logic implementation to be registered
     * @param _implementation representing the address of the new passport logic implementation to be registered
     */
    function addPassportLogic(string _version, address _implementation) public onlyOwner {
        _addPassportLogic(_version, _implementation);
    }

    /**
     * @dev Tells the address of the passport logic implementation for a given version
     * @param _version to query the implementation of
     * @return address of the passport logic implementation registered for the given version
     */
    function getPassportLogic(string _version) external view returns (address) {
        return passportLogicImplementations[_version];
    }

    /**
     * @dev Sets a new passport logic implementation as current one
     * @param _version representing the version name of the passport logic implementation to be set as current one
     */
    function setCurrentPassportLogic(string _version) public onlyOwner {
        _setCurrentPassportLogic(_version);
    }

    /**
     * @dev Tells the version of the current passport logic implementation
     * @return version of the current passport logic implementation
     */
    function getCurrentPassportLogicVersion() external view returns (string) {
        return currentPassportLogicVersion;
    }

    /**
     * @dev Tells the address of the current passport logic implementation
     * @return address of the current passport logic implementation
     */
    function getCurrentPassportLogic() external view returns (address) {
        return currentPassportLogic;
    }

    function _addPassportLogic(string _version, address _implementation) internal {
        require(_implementation != 0x0, "Cannot set implementation to a zero address");
        require(passportLogicImplementations[_version] == 0x0, "Cannot replace existing version implementation");

        passportLogicImplementations[_version] = _implementation;
        emit PassportLogicAdded(_version, _implementation);
    }

    function _setCurrentPassportLogic(string _version) internal {
        require(passportLogicImplementations[_version] != 0x0, "Cannot set non-existing passport logic as current implementation");

        currentPassportLogicVersion = _version;
        currentPassportLogic = passportLogicImplementations[_version];
        emit CurrentPassportLogicSet(currentPassportLogicVersion, currentPassportLogic);
    }
}