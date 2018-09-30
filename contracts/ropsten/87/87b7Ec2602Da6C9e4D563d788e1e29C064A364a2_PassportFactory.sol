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
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="1a687f7779755a28">[email&#160;protected]</a>π.com>
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
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3c4e59515f537c0e">[email&#160;protected]</a>π.com>
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

// File: contracts/ownership/OwnableProxy.sol

/**
 * @title OwnableProxy
 */
contract OwnableProxy {
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Storage slot with the owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.owner", and is
     * validated in the constructor.
     */
    bytes32 private constant OWNER_SLOT = 0x3ca57e4b51fc2e18497b219410298879868edada7e6fe5132c8feceb0a080d22;

    /**
     * @dev The OwnableProxy constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        assert(OWNER_SLOT == keccak256("org.monetha.proxy.owner"));

        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _getOwner());
        _;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_getOwner());
        _setOwner(address(0));
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
        emit OwnershipTransferred(_getOwner(), _newOwner);
        _setOwner(_newOwner);
    }

    /**
     * @return The owner address.
     */
    function owner() public view returns (address) {
        return _getOwner();
    }

    /**
     * @return The owner address.
     */
    function _getOwner() internal view returns (address own) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            own := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy owner.
     * @param _newOwner Address of the new proxy owner.
     */
    function _setOwner(address _newOwner) internal {
        bytes32 slot = OWNER_SLOT;

        assembly {
            sstore(slot, _newOwner)
        }
    }
}

// File: contracts/ownership/ClaimableProxy.sol

/**
 * @title ClaimableProxy
 * @dev Extension for the OwnableProxy contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract ClaimableProxy is OwnableProxy {
    /**
     * @dev Storage slot with the pending owner of the contract.
     * This is the keccak-256 hash of "org.monetha.proxy.pendingOwner", and is
     * validated in the constructor.
     */
    bytes32 private constant PENDING_OWNER_SLOT = 0xcfd0c6ea5352192d7d4c5d4e7a73c5da12c871730cb60ff57879cbe7b403bb52;

    /**
     * @dev The ClaimableProxy constructor validates PENDING_OWNER_SLOT constant.
     */
    constructor() public {
        assert(PENDING_OWNER_SLOT == keccak256("org.monetha.proxy.pendingOwner"));
    }

    function pendingOwner() public view returns (address) {
        return _getPendingOwner();
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == _getPendingOwner());
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(_getOwner(), _getPendingOwner());
        _setOwner(_getPendingOwner());
        _setPendingOwner(address(0));
    }

    /**
     * @return The pending owner address.
     */
    function _getPendingOwner() internal view returns (address penOwn) {
        bytes32 slot = PENDING_OWNER_SLOT;
        assembly {
            penOwn := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the pending owner.
     * @param _newPendingOwner Address of the new pending owner.
     */
    function _setPendingOwner(address _newPendingOwner) internal {
        bytes32 slot = PENDING_OWNER_SLOT;

        assembly {
            sstore(slot, _newPendingOwner)
        }
    }
}

// File: contracts/lifecycle/DestructibleProxy.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract DestructibleProxy is OwnableProxy {
    /**
     * @dev Transfers the current balance to the owner and terminates the contract.
     */
    function destroy() public onlyOwner {
        selfdestruct(_getOwner());
    }

    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
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

// File: contracts/upgradeability/Proxy.sol

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    function () payable external {
        _delegate(_implementation());
    }

    /**
     * @return The Address of the implementation.
     */
    function _implementation() internal view returns (address);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn&#39;t return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

        // Call the implementation.
        // out and outsize are 0 because we don&#39;t know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }
}

// File: contracts/Passport.sol

/**
 * @title Passport
 */
contract Passport is Proxy, ClaimableProxy, DestructibleProxy {

    event PassportLogicRegistryChanged(
        address indexed previousRegistry,
        address indexed newRegistry
    );

    /**
     * @dev Storage slot with the address of the current registry of the passport implementations.
     * This is the keccak-256 hash of "org.monetha.passport.proxy.registry", and is
     * validated in the constructor.
     */
    bytes32 private constant REGISTRY_SLOT = 0xa04bab69e45aeb4c94a78ba5bc1be67ef28977c4fdf815a30b829a794eb67a4a;

    /**
     * @dev Contract constructor.
     * @param _registry Address of the passport implementations registry.
     */
    constructor(IPassportLogicRegistry _registry) public {
        assert(REGISTRY_SLOT == keccak256("org.monetha.passport.proxy.registry"));

        _setRegistry(_registry);
    }

    /**
     * @dev Changes the passport logic registry.
     * @param _registry Address of the new passport implementations registry.
     */
    function changePassportLogicRegistry(IPassportLogicRegistry _registry) public onlyOwner {
        emit PassportLogicRegistryChanged(address(_getRegistry()), address(_registry));
        _setRegistry(_registry);
    }

    /**
     * @return the address of passport logic registry.
     */
    function getPassportLogicRegistry() public view returns (address) {
        return _getRegistry();
    }

    /**
     * @dev Returns the current passport logic implementation (used in Proxy fallback function to delegate call
     * to passport logic implementation).
     * @return Address of the current passport implementation
     */
    function _implementation() internal view returns (address) {
        return _getRegistry().getCurrentPassportLogic();
    }

    /**
     * @dev Returns the current passport implementations registry.
     * @return Address of the current implementation
     */
    function _getRegistry() internal view returns (IPassportLogicRegistry reg) {
        bytes32 slot = REGISTRY_SLOT;
        assembly {
            reg := sload(slot)
        }
    }

    function _setRegistry(IPassportLogicRegistry _registry) internal {
        require(address(_registry) != 0x0, "Cannot set registry to a zero address");

        bytes32 slot = REGISTRY_SLOT;
        assembly {
            sstore(slot, _registry)
        }
    }
}

// File: contracts/PassportFactory.sol

/**
 * @title PassportFactory
 * @dev This contract works as a passport factory.
 */
contract PassportFactory is Ownable, HasNoEther, HasNoTokens {
    IPassportLogicRegistry private registry;

    /**
    * @dev This event will be emitted every time a new passport is created
    * @param passport representing the address of the passport created
    * @param owner representing the address of the passport owner
    */
    event PassportCreated(address indexed passport, address indexed owner);

    /**
    * @dev This event will be emitted every time a passport logic registry is changed
    * @param oldRegistry representing the address of the old passport logic registry
    * @param newRegistry representing the address of the new passport logic registry
    */
    event PassportLogicRegistryChanged(address indexed oldRegistry, address indexed newRegistry);

    constructor(IPassportLogicRegistry _registry) public {
        _setRegistry(_registry);
    }

    function setRegistry(IPassportLogicRegistry _registry) public onlyOwner {
        emit PassportLogicRegistryChanged(registry, _registry);
        _setRegistry(_registry);
    }

    function getRegistry() external view returns (address) {
        return registry;
    }

    /**
    * @dev Creates new passport. The method should be called by the owner of the created passport.
    * After the passport is created, the owner must call the claimOwnership() passport method to become a full owner.
    * @return address of the created passport
    */
    function createPassport() public returns (Passport) {
        Passport pass = new Passport(registry);
        pass.transferOwnership(msg.sender); // owner needs to call claimOwnership()
        emit PassportCreated(pass, msg.sender);
        return pass;
    }

    function _setRegistry(IPassportLogicRegistry _registry) internal {
        require(address(_registry) != 0x0);
        registry = _registry;
    }
}