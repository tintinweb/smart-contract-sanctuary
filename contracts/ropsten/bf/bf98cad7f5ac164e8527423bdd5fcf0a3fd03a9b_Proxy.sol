/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// File: contracts/AccessControlledBase.sol


pragma solidity 0.4.24;


/**
 * @title AccessControlledBase
 * @author dYdX
 *
 * Base functionality for access control. Requires an implementation to
 * provide a way to grant and optionally revoke access
 */
contract AccessControlledBase {
    // ---------------------------
    // ----- State Variables -----
    // ---------------------------

    mapping(address => bool) public authorized;

    // ------------------------
    // -------- Events --------
    // ------------------------

    event AccessGranted(
        address who
    );

    event AccessRevoked(
        address who
    );

    // ---------------------------
    // -------- Modifiers --------
    // ---------------------------

    modifier requiresAuthorization() {
        require(authorized[msg.sender]);
        _;
    }
}
// File: zeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.4.24;


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


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

// File: zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;




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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


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

// File: contracts/OwnedAccessControlled.sol

pragma solidity 0.4.24;




/**
 * @title OwnedAccessControlled
 * @author dYdX
 *
 * Allows for functions to be access controled
 * Owner has permission to grant and revoke access
 */
contract OwnedAccessControlled is AccessControlledBase, Ownable {
    // -------------------------------------------
    // --- Owner Only State Changing Functions ---
    // -------------------------------------------

    function grantAccess(
        address who
    )
        onlyOwner
        external
    {
        authorized[who] = true;
        emit AccessGranted(who);
    }

    function revokeAccess(
        address who
    )
        onlyOwner
        external
    {
        authorized[who] = false;
        emit AccessRevoked(who);
    }
}
// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
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
}

// File: zeppelin-solidity/contracts/ownership/HasNoContracts.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: zeppelin-solidity/contracts/ownership/CanReclaimToken.sol

pragma solidity ^0.4.24;





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

// File: zeppelin-solidity/contracts/ownership/HasNoTokens.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <[email protected]π.com>
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

// File: zeppelin-solidity/contracts/ownership/HasNoEther.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
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

// File: zeppelin-solidity/contracts/ownership/NoOwner.sol

pragma solidity ^0.4.24;





/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

// File: contracts/ERC20_own.sol

pragma solidity 0.4.24;

contract ERC20 {
    // MAXSUPPLY, supply, fee and minter
    // We use uint256 because it’s most efficient data type in solidity
    // The EVM works with 256bit and if data is smaller
    // further operations are needed to downscale it from 256bit.
    // The variables are private by convention and getters/setters can
    // be used to retrieve or amend them.
    uint256 constant private fee = 1;
    uint256 constant private MAXSUPPLY = 1000000;
    uint256 private supply = 50000;
    address private minter;

    // Event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Event to be emitted on mintership transfer
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // Mapping for balances
    mapping (address => uint) public balances;

    // Mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() public {
        // Sender's balance gets set to total supply and sender gets assigned as minter
        balances[msg.sender] = supply;
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // Returns total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // Returns the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // Mint tokens by updating receiver's balance and total supply
        // Total supply must not exceed MAXSUPPLY
        // The sender needs to be the current minter to mint more tokens
        require(msg.sender == minter, "Sender is not the current minter");
        require(totalSupply() + amount <= MAXSUPPLY, "The added supply will exceed the max supply");
        supply += amount;
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // Burn tokens by sending tokens to address(0)
        // Must have enough balance to burn
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        supply -= amount;
        balances[address(0)] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // Transfer mintership to newminter
        // Only incumbent minter can transfer mintership
        // Should emit MintershipTransfer event
        require(msg.sender == minter, "Sender is not the current minter");
        minter = newMinter;
        emit MintershipTransfer(minter, newMinter);
        return true;
    }

    function doTransfer(address _from, address _to, uint256 _value) private returns (bool) {
        // Private method to avoid code duplication between transfer and transferFrom
        // Transfer `_value` tokens from _from to _to
        // _from needs to have enough tokens
        // Transfer value needs to be sufficient to cover fee
        // Emit events for sending to _to and to minter
        require(balances[_from] >= _value, "Insufficient balance");
        require(fee < _value, "Cover fee exceeds the transfer value");
        balances[_from] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(_from, _to, _value - fee);
        emit Transfer(_from, minter, fee);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from sender to `_to`
        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // Transfer `_value` tokens from `_from` to `_to`
        // `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        bool response = doTransfer(_from, _to, _value);
        allowances[_from][msg.sender] -= _value;
        return response;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // Allow `_spender` to spend `_value` on sender's behalf
        // If an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // Return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}

// File: contracts/Proxy.sol

pragma solidity 0.4.24;


//import { ERC20 } from "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";








/**
 * @title Proxy
 * @author dYdX
 *
 * Used to transfer tokens between addresses which have set allowance on this contract
 */
contract Proxy is OwnedAccessControlled, NoOwner, Pausable {
    using SafeMath for uint;

    // ---------------------------
    // ----- State Variables -----
    // ---------------------------

    /**
     * Only addresses that are transfer authorized can move funds.
     * Authorized addresses through AccessControlled can add and revoke
     * transfer authorized addresses
     */
    mapping(address => bool) public transferAuthorized;

    // ------------------------
    // -------- Events --------
    // ------------------------

    event TransferAuthorization(
        address who
    );

    event Print(uint voter);

    event TransferDeauthorization(
        address who
    );

    // ---------------------------
    // -------- Modifiers --------
    // ---------------------------

    modifier requiresTransferAuthorization() {
        require(transferAuthorized[msg.sender]);
        _;
    }

    modifier requiresAuthorizationOrOwner() {
        require(authorized[msg.sender] || owner == msg.sender);
        _;
    }

    // --------------------------------------------------
    // ---- Authorized Only State Changing Functions ----
    // --------------------------------------------------

    function grantTransferAuthorization(
        address who
    )
        //requiresAuthorizationOrOwner
        external
    {
        if (!transferAuthorized[who]) {
            transferAuthorized[who] = true;

            emit TransferAuthorization(
                who
            );
        }
    }

    function revokeTransferAuthorization(
        address who
    )
        requiresAuthorizationOrOwner
        external
    {
        if (transferAuthorized[who]) {
            delete transferAuthorized[who];

            emit TransferDeauthorization(
                who
            );
        }
    }

    // -----------------------------------------------------------
    // ---- Transfer Authorized Only State Changing Functions ----
    // -----------------------------------------------------------

    function transfer(
        address token,
        address from,
        uint value
    )
        requiresTransferAuthorization
        whenNotPaused
        external
    {
        require(ERC20(token).transferFrom(from, msg.sender, value));
    }

    function transferTo(
        address token,
        address from,
        address to,
        uint value
    )
        requiresTransferAuthorization
        whenNotPaused
        external
    {
        require(ERC20(token).transferFrom(from, to, value));
    }

    // -----------------------------------------
    // ------- Public Constant Functions -------
    // -----------------------------------------

    function available(
        address who,
        address token
    )
        view
        external
        returns (uint _allowance)
    {
        //uint t = 12321;
        uint test = ERC20(token).balanceOf(who);
        return test;
        //return IERC20(token).balanceOf(who);
        //return Math.min256(
            //IERC20(token).allowance(who, address(this)),
            //IERC20(token).balanceOf(who)
        //);
    }


 function queryERC20Balance(address _tokenAddress) view public returns (uint) {
        return ERC20(_tokenAddress).totalSupply();
    }
}