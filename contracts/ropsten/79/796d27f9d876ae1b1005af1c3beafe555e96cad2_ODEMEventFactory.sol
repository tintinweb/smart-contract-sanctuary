pragma solidity 0.4.24;                                                                         
 
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

// File: contracts/Lockable.sol

/// @title Lockable
/// @notice Allows the owner to lock the contract, which can temporarily
/// block some methods from being called.
contract Lockable is Ownable {

    bool public locked;

    modifier onlyWhenUnlocked() {
        require(!locked, "Contract is locked");
        _;
    }

    /// @notice Lock the contract and temporarily disallow some methods from
    /// being called. Only the owner can lock.
    function lock() external onlyOwner {
        locked = true;
    }

    /// @notice Unlock the contract and allow methods to be called again. Only
    /// the owner can unlock.
    function unlock() external onlyOwner {
        locked = false;
    }
}

// File: contracts/ERC900.sol

/// @title ERC900
/// @notice The ERC900 interface for staking tokens.
/// See https://github.com/ethereum/EIPs/issues/900
contract ERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes data) public;
    function stakeFor(address user, uint256 amount, bytes data) public;
    function unstake(uint256 amount, bytes data) public;
    function totalStakedFor(address addr) public view returns (uint256);
    function totalStaked() public view returns (uint256);
    function token() public view returns (address);
    function supportsHistory() public pure returns (bool);

    // Optional
    function lastStakedFor(address addr) public view returns (uint256);
    function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
    function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

// File: contracts/ODEMEvent.sol

/// @title ODEMEvent
/// @notice When an educator registers a new event (educational course), ODEM
/// uses the event factory to deploy a new ODEMEvent contract which handles
/// staking of ODEM tokens. The ODEM platform will then only proceed with the
/// event, or afterwards issue certificates and claims, if staking criteria
/// are met.
/// Implements the ERC900 interface.
contract ODEMEvent is ERC900, Lockable {

    using SafeMath for uint256;

    ERC20 public token;
    uint public eventId;

    uint256 public totalStaked;
    mapping (address => uint256) public totalStakedFor;
    mapping (address => mapping (address => uint256)) public totalStakedForBy;

    // This is needed to allow someone to withdraw all of their stakes at once.
    // It will end up containing some duplicates but that&#39;s fine.
    mapping (address => address[]) internal stakedForRecipients;

    /// @notice Create a new ODEMEvent contract for an ODEM event.
    /// @param _eventId The ODEM event code.
    /// @param tokenAddr The address of the ODEMToken contract.
    constructor(uint _eventId, address tokenAddr) public {
        require(tokenAddr != address(0), "tokenAddr must not be zero");
        require(_eventId > 0, "eventId must not be zero");
        token = ERC20(tokenAddr);
        eventId = _eventId;
    }

    /// @notice Stake ODEM tokens for this event for yourself.
    /// The event contract initiates the token transfer, so you must first
    /// approve an allowance on the ODEMToken contract with the event contract
    /// as the spender.
    /// Not allowed when the event is locked.
    /// @param amount Amount of tokens to stake, in the smallest unit ("wei"
    /// equivalent).
    /// @param data Ignored. Provided for compatibility with ERC900.
    function stake(uint256 amount, bytes data) public onlyWhenUnlocked {
        stakeFor(msg.sender, amount, data);
    }

    /// @notice Stake ODEM tokens for this event for someone else.
    /// The event contract initiates the token transfer, so you must first
    /// approve an allowance on the ODEMToken contract with the event contract
    /// as the spender.
    /// Not allowed when the event is locked.
    /// @param addr Address to stake for.
    /// @param amount Amount of tokens to stake, in the smallest unit ("wei"
    /// equivalent).
    /// @param data Ignored. Provided for compatibility with ERC900.
    function stakeFor(address addr, uint256 amount, bytes data) public onlyWhenUnlocked {
        if (totalStakedForBy[addr][msg.sender] == 0) {
            stakedForRecipients[msg.sender].push(addr);
        }
        totalStaked = totalStaked.add(amount);
        totalStakedFor[addr] = totalStakedFor[addr].add(amount);
        totalStakedForBy[addr][msg.sender] = totalStakedForBy[addr][msg.sender].add(amount);

        require(token.transferFrom(msg.sender, address(this), amount), "Token transfer failed");

        emit Staked(addr, amount, totalStakedFor[addr], data);
    }

    /// @notice Unstake ODEM tokens for this event for yourself.
    /// Not allowed when the event is locked.
    /// @param amount Amount of tokens to unstake, in the smallest unit ("wei"
    /// equivalent).
    /// @param data Ignored. Provided for compatibility with ERC900.
    function unstake(uint256 amount, bytes data) public onlyWhenUnlocked {
        unstakeFor(msg.sender, amount, data);
    }

    /// @notice Untake ODEM tokens for this event for someone else.
    /// Not allowed when the event is locked.
    /// @param addr Address to unstake for.
    /// @param amount Amount of tokens to unstake, in the smallest unit ("wei"
    /// equivalent).
    /// @param data Ignored. Provided for compatibility with ERC900.
    function unstakeFor(address addr, uint256 amount, bytes data) public onlyWhenUnlocked {
        require(totalStakedForBy[addr][msg.sender] >= amount, "Unstake amount greater than currently staked amount");

        totalStaked = totalStaked.sub(amount);
        totalStakedFor[addr] = totalStakedFor[addr].sub(amount);
        totalStakedForBy[addr][msg.sender] = totalStakedForBy[addr][msg.sender].sub(amount);

        require(token.transfer(msg.sender, amount), "Token transfer failed");

        emit Unstaked(addr, amount, totalStakedFor[addr], data);
    }

    /// @notice Unstake all tokens that you staked for yourself or for anyone
    /// else.
    /// Not allowed when the event is locked.
    function unstakeAll() public onlyWhenUnlocked {
        uint unstaked = 0;
        for (uint i = 0; i < stakedForRecipients[msg.sender].length; i++) {
            address addr = stakedForRecipients[msg.sender][i];
            uint amount = totalStakedForBy[addr][msg.sender];

            unstaked = unstaked.add(amount);
            totalStaked = totalStaked.sub(amount);
            totalStakedFor[addr] = totalStakedFor[addr].sub(amount);
            totalStakedForBy[addr][msg.sender] = 0;

            emit Unstaked(addr, amount, totalStakedFor[addr], "");
        }
        stakedForRecipients[msg.sender].length = 0;

        require(token.transfer(msg.sender, unstaked), "Token transfer failed");
    }

    /// @notice Get the ODEM token address.
    /// @return The ODEM token address.
    function token() public view returns (address) {
        return token;
    }

    /// @notice Get the total amount of ODEM tokens that have been staked for
    /// this event.
    /// @return The amount of ODEM tokens staked.
    function totalStaked() public view returns (uint256) {
        return totalStaked;
    }

    /// @notice Get the total amount of ODEM tokens that have been staked for
    /// someone (a particular address) for this event.
    /// @param addr The address.
    /// @return The amount of ODEM tokens staked.
    function totalStakedFor(address addr) public view returns (uint256) {
        return totalStakedFor[addr];
    }

    /// @notice Check if history methods are implemented.
    /// @return A boolean indicating whether history is implemented. Always
    /// false.
    function supportsHistory() public pure returns (bool) {
        return false;
    }

    /// @notice Provided for compatibility with ERC900. Always fails.
    function lastStakedFor(address addr) public view returns (uint256) {
        revert();
    }

    /// @notice Provided for compatibility with ERC900. Always fails.
    function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256) {
        revert();
    }

    /// @notice Provided for compatibility with ERC900. Always fails.
    function totalStakedAt(uint256 blockNumber) public view returns (uint256) {
        revert();
    }
}

// File: contracts/RBACInterface.sol

/// @title RBACInterface
/// @notice The interface for Role-Based Access Control.
contract RBACInterface {
    function hasRole(address addr, string role) public view returns (bool);
}

// File: contracts/RBACManaged.sol

/// @title RBACManaged
/// @notice Controls access by delegating to a deployed RBAC contract.
contract RBACManaged is Ownable {

    RBACInterface public rbac;

    /// @param rbacAddr The address of the RBAC contract which controls access.
    constructor(address rbacAddr) public {
        rbac = RBACInterface(rbacAddr);
    }

    function roleAdmin() internal pure returns (string);

    /// @notice Check if an address has a role.
    /// @param addr The address.
    /// @param role The role.
    /// @return A boolean indicating whether the address has the role.
    function hasRole(address addr, string role) public view returns (bool) {
        return rbac.hasRole(addr, role);
    }

    modifier onlyRole(string role) {
        require(hasRole(msg.sender, role), "Access denied: missing role");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || hasRole(msg.sender, roleAdmin()), "Access denied: missing role");
        _;
    }

    /// @notice Change the address of the deployed RBAC contract which
    /// controls access. Only the owner or an admin can change the address.
    /// @param rbacAddr The address of the RBAC contract which controls access.
    function setRBACAddress(address rbacAddr) public onlyOwnerOrAdmin {
        rbac = RBACInterface(rbacAddr);
    }
}

// File: contracts/ODEMEventFactory.sol

/// @title ODEMEventFactory
/// @notice When an educator registers a new event (educational course), ODEM
/// uses the event factory to deploy a new ODEMEvent contract which handles
/// staking of ODEM tokens. The ODEM platform will then only proceed with the
/// event, or afterwards issue certificates and claims, if staking criteria
/// are met.
contract ODEMEventFactory is RBACManaged {

    event EventCreated(uint indexed eventId, address eventAddress);

    string constant ROLE_ADMIN = "events__admin";
    string constant ROLE_CREATOR = "events__creator";

    ERC20 public token;

    mapping(uint => address) public events;

    /// @param tokenAddr The address of the ODEMToken contract.
    /// @param rbacAddr The address of the RBAC contract which controls access to this
    /// contract.
    constructor(address tokenAddr, address rbacAddr) RBACManaged(rbacAddr) public {
        require(tokenAddr != address(0), "Token address must not be zero");
        token = ERC20(tokenAddr);
    }

    /// @notice Deploy a new ODEMEvent contract and transfer ownership to
    /// yourself.
    /// @dev Transfers ownership of the ODEMEvent to msg.sender.
    /// @param eventId The ODEM event code.
    /// @return The address of the deployed contract.
    function deployEventContract(uint eventId) public returns (address) {
        ODEMEvent deployed = new ODEMEvent(eventId, token);
        deployed.transferOwnership(msg.sender);
        address eventAddress = address(deployed);
        return eventAddress;
    }

    /// @notice Create an event, which deploys and registers a new ODEMEvent
    /// contract, bypassing safety checks.
    /// Only ODEM can create events.
    /// @dev Requires caller to have the role "events_creator".
    /// @param eventId The ODEM event code.
    /// @return The address of the deployed contract.
    function createEventUnsafe(uint eventId) public onlyRole(ROLE_CREATOR) returns (address) {
        address eventAddress = deployEventContract(eventId);
        events[eventId] = eventAddress;
        emit EventCreated(eventId, eventAddress);
        return eventAddress;
    }

    /// @notice Create an event, which deploys and registers a new ODEMEvent
    /// contract.
    /// Only ODEM can create events.
    /// @dev Requires caller to have the role "events_creator".
    /// Requires eventId to be unique and non-zero.
    /// @param eventId The ODEM event code.
    /// @return The address of the deployed contract.
    function createEvent(uint eventId) public onlyRole(ROLE_CREATOR) returns (address) {
        require(eventId > 0, "eventId must not be zero");
        require(events[eventId] == address(0), "eventId already in use");
        return createEventUnsafe(eventId);
    }

    /// @notice Remove an event by unregistering it, but leave the ODEMEvent
    /// contract.
    /// Only ODEM can remove events.
    /// @dev Requires caller to have the role "events_creator".
    /// @param eventId The ODEM event code.
    function softRemoveEvent(uint eventId) public onlyRole(ROLE_CREATOR) {
        delete events[eventId];
    }

    /// @notice Get the address of the ODEMEvent contract for an event.
    /// @param eventId The ODEM event code.
    /// @return The address of the deployed contract.
    function eventContractAddress(uint eventId) public view returns (address) {
        return events[eventId];
    }

    function roleAdmin() internal pure returns (string) {
        return ROLE_ADMIN;
    }
}