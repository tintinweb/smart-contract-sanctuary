/**
 *Submitted for verification at Etherscan.io on 2021-11-30
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

// File: contracts/ZeroExSafeMath.sol

pragma solidity 0.4.24;

contract ZeroExSafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint256) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
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

//import "./ERC20.sol";



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
        //uint test = ERC20(token).balanceOf(who);
        //return test;
        //return IERC20(token).balanceOf(who);
        return Math.min256(
            ERC20(token).allowance(who, address(this)),
            ERC20(token).balanceOf(who)
        );
    }


 function queryERC20Balance(address _tokenAddress) view public returns (uint) {
        return ERC20(_tokenAddress).totalSupply();
    }
}
// File: contracts/Exchange.sol

pragma solidity 0.4.24;

/// Modified version of 0x Exchange contract. Uses dYdX proxy and no protocol token

/*

  Copyright 2017 ZeroEx Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";





/// @title Exchange - Facilitates exchange of ERC20 tokens.
/// @author Amir Bandeali - <[email protected]>, Will Warren - <[email protected]>
/// @author dYdX [modified from 0x version]
contract Exchange is ZeroExSafeMath, NoOwner {

    // Error Codes
    uint8 constant ERROR_ORDER_EXPIRED = 0;                     // Order has already expired
    uint8 constant ERROR_ORDER_FULLY_FILLED_OR_CANCELLED = 1;   // Order has already been fully filled or cancelled
    uint8 constant ERROR_ROUNDING_ERROR_TOO_LARGE = 2;          // Rounding error too large
    uint8 constant ERROR_INSUFFICIENT_BALANCE_OR_ALLOWANCE = 3; // Insufficient balance or allowance for token transfer


    address public PROXY_CONTRACT;

    // Mappings of orderHash => amounts of takerTokenAmount filled or cancelled.
    mapping (bytes32 => uint) public filled;
    mapping (bytes32 => uint) public cancelled;

    event LogFill(
        address indexed maker,
        address taker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        address makerFeeToken,
        address takerFeeToken,
        uint filledMakerTokenAmount,
        uint filledTakerTokenAmount,
        uint paidMakerFee,
        uint paidTakerFee,
        bytes32 indexed tokens, // keccak256(makerToken, takerToken), allows subscribing to a token pair
        bytes32 orderHash
    );

    event LogCancel(
        address indexed maker,
        address indexed feeRecipient,
        address makerToken,
        address takerToken,
        uint cancelledMakerTokenAmount,
        uint cancelledTakerTokenAmount,
        bytes32 indexed tokens,
        bytes32 orderHash
    );

    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);

    struct Order {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        address makerFeeToken;
        address takerFeeToken;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint makerFee;
        uint takerFee;
        uint expirationTimestampInSec;
        bytes32 orderHash;
    }

    constructor(address _PROXY_CONTRACT) public {
        PROXY_CONTRACT = _PROXY_CONTRACT;
    }

    function queryProxyBalance(address _tokenAddress) view public returns (uint) {
        return Proxy(PROXY_CONTRACT).queryERC20Balance(_tokenAddress);
    }

    /*
    * Core exchange functions
    */ 

    /**
     * Fills the input order and allows for custom fee tokens
     *
     * @param  orderAddresses           Addresses corresponding to:
     *
     * [0] = maker
     * [1] = taker
     * [2] = makerToken
     * [3] = takerToken
     * [4] = feeRecipient
     * [5] = makerFeeToken
     * [6] = takerFeeToken
     *
     * @param orderValues               Array of:
     *
     * [0] = makerTokenAmount
     * [1] = takerTokenAmount
     * [2] = makerFee
     * [3] = takerFee
     * [4] = expirationTimestampInSec
     * [5] = salt
     *
     * @param fillTakerTokenAmount      Desired amount of takerToken to fill
     * @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfer will fail before
     *                                                    attempting
     * @param v                         ECDSA signature parameter v
     * @param r                         CDSA signature parameters r
     * @param s                         CDSA signature parameters s
     * @return filledTakerTokenAmount   Total amount of takerToken filled in trade
     */
    function fillOrder(
        address[7] orderAddresses,
        uint[6] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        returns (uint filledTakerTokenAmount)
    {
        // Parse the arguments into an Order

        Order memory order = Order({
            maker: orderAddresses[0],
            taker: orderAddresses[1],
            makerToken: orderAddresses[2],
            takerToken: orderAddresses[3],
            feeRecipient: orderAddresses[4],
            makerFeeToken: orderAddresses[5],
            takerFeeToken: orderAddresses[6],
            makerTokenAmount: orderValues[0],
            takerTokenAmount: orderValues[1],
            makerFee: orderValues[2],
            takerFee: orderValues[3],
            expirationTimestampInSec: orderValues[4],
            orderHash: getOrderHash(orderAddresses, orderValues)
        });

        // Validate Order

        require(order.taker == address(0) || order.taker == msg.sender);

        require(
            isValidSignature(
                order.maker,
                order.orderHash,
                v,
                r,
                s
            )
        );

        if (block.timestamp >= order.expirationTimestampInSec) {
            emit LogError(ERROR_ORDER_EXPIRED, order.orderHash);
            return 0;
        }

        uint remainingTakerTokenAmount = safeSub(
            order.takerTokenAmount,
            getUnavailableTakerTokenAmount(order.orderHash)
        );
        filledTakerTokenAmount = min256(fillTakerTokenAmount, remainingTakerTokenAmount);
        if (filledTakerTokenAmount == 0) {
            emit LogError(ERROR_ORDER_FULLY_FILLED_OR_CANCELLED, order.orderHash);
            return 0;
        }

        if (
            isRoundingError(
                filledTakerTokenAmount,
                order.takerTokenAmount,
                order.makerTokenAmount
            )
        ) {
            emit LogError(ERROR_ROUNDING_ERROR_TOO_LARGE, order.orderHash);
            return 0;
        }

        // Calculate Amounts

        uint filledMakerTokenAmount = getPartialAmount(
            filledTakerTokenAmount,
            order.takerTokenAmount,
            order.makerTokenAmount
        );
        uint fillMakerFee = getPartialAmount(
            filledTakerTokenAmount,
            order.takerTokenAmount,
            order.makerFee
        );
        uint fillTakerFee = getPartialAmount(
            filledTakerTokenAmount,
            order.takerTokenAmount,
            order.takerFee
        );

        if (
            !shouldThrowOnInsufficientBalanceOrAllowance
            && !isTransferable(
                order,
                filledMakerTokenAmount,
                filledTakerTokenAmount,
                fillMakerFee,
                fillTakerFee
            )
        ) {
            emit LogError(ERROR_INSUFFICIENT_BALANCE_OR_ALLOWANCE, order.orderHash);
            return 0;
        }

        // Update filled amount

        filled[order.orderHash] = safeAdd(filled[order.orderHash], filledTakerTokenAmount);

        // Transfer Tokens

        transferViaProxy(
            order.makerToken,
            order.maker,
            msg.sender,
            filledMakerTokenAmount
        );
        transferViaProxy(
            order.takerToken,
            msg.sender,
            order.maker,
            filledTakerTokenAmount
        );

        // Transfer Fees

        if (order.feeRecipient != address(0)) {
            if (order.makerFee > 0) {
                transferViaProxy(
                    order.makerFeeToken,
                    order.maker,
                    order.feeRecipient,
                    fillMakerFee
                );
            }
            if (order.takerFee > 0) {
                transferViaProxy(
                    order.takerFeeToken,
                    msg.sender,
                    order.feeRecipient,
                    fillTakerFee
                );
            }
        }

        // Log Event

        logFillEvent(
            order,
            [
                filledMakerTokenAmount,
                filledTakerTokenAmount,
                fillMakerFee,
                fillTakerFee
            ]
        );

        return filledTakerTokenAmount;
    }

    /// @dev Cancels the input order.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, feeRecipient, makerFeeToken, and takerFeeToken.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param canceltakerTokenAmount Desired amount of takerToken to cancel in order.
    /// @return Amount of takerToken cancelled.
    function cancelOrder(
        address[7] orderAddresses,
        uint[6] orderValues,
        uint canceltakerTokenAmount
    )
        public
        returns (uint cancelledTakerTokenAmount)
    {
        Order memory order = Order({
            maker: orderAddresses[0],
            taker: orderAddresses[1],
            makerToken: orderAddresses[2],
            takerToken: orderAddresses[3],
            feeRecipient: orderAddresses[4],
            makerFeeToken: orderAddresses[5],
            takerFeeToken: orderAddresses[6],
            makerTokenAmount: orderValues[0],
            takerTokenAmount: orderValues[1],
            makerFee: orderValues[2],
            takerFee: orderValues[3],
            expirationTimestampInSec: orderValues[4],
            orderHash: getOrderHash(orderAddresses, orderValues)
        });

        require(order.maker == msg.sender);

        if (block.timestamp >= order.expirationTimestampInSec) {
            emit LogError(ERROR_ORDER_EXPIRED, order.orderHash);
            return 0;
        }

        uint remainingTakerTokenAmount = safeSub(
            order.takerTokenAmount,
            getUnavailableTakerTokenAmount(order.orderHash)
        );
        cancelledTakerTokenAmount = min256(canceltakerTokenAmount, remainingTakerTokenAmount);
        if (cancelledTakerTokenAmount == 0) {
            emit LogError(ERROR_ORDER_FULLY_FILLED_OR_CANCELLED, order.orderHash);
            return 0;
        }

        cancelled[order.orderHash] = safeAdd(cancelled[order.orderHash], cancelledTakerTokenAmount);

        emit LogCancel(
            order.maker,
            order.feeRecipient,
            order.makerToken,
            order.takerToken,
            getPartialAmount(
                cancelledTakerTokenAmount,
                order.takerTokenAmount,
                order.makerTokenAmount
            ),
            cancelledTakerTokenAmount,
            keccak256(abi.encodePacked(order.makerToken, order.takerToken)),
            order.orderHash
        );
        return cancelledTakerTokenAmount;
    }

    /*
    * Wrapper functions
    */

    /// @dev Fills an order with specified parameters and ECDSA signature, throws if specified amount not filled entirely.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, and feeRecipient.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
    /// @param v ECDSA signature parameter v.
    /// @param r CDSA signature parameters r.
    /// @param s CDSA signature parameters s.
    /// @return Success of entire fillTakerTokenAmount being filled.
    function fillOrKillOrder(
        address[7] orderAddresses,
        uint[6] orderValues,
        uint fillTakerTokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        returns (bool success)
    {
        assert(
            fillOrder(
                orderAddresses,
                orderValues,
                fillTakerTokenAmount,
                false,
                v,
                r,
                s
            ) == fillTakerTokenAmount
        );
        return true;
    }

    /// @dev Synchronously executes multiple fill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    /// @return Successful if no orders throw.
    function batchFillOrders(
        address[7][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s
    )
        public
        returns (bool success)
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            fillOrder(
                orderAddresses[i],
                orderValues[i],
                fillTakerTokenAmounts[i],
                shouldThrowOnInsufficientBalanceOrAllowance,
                v[i],
                r[i],
                s[i]
            );
        }

        return true;
    }

    /// @dev Synchronously executes multiple fillOrKill orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmounts Array of desired amounts of takerToken to fill in orders.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    /// @return Success of all orders being filled with respective fillTakerTokenAmount.
    function batchFillOrKillOrders(
        address[7][] orderAddresses,
        uint[6][] orderValues,
        uint[] fillTakerTokenAmounts,
        uint8[] v,
        bytes32[] r,
        bytes32[] s
    )
        public
        returns (bool success)
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            assert(
                fillOrKillOrder(
                    orderAddresses[i],
                    orderValues[i],
                    fillTakerTokenAmounts[i],
                    v[i],
                    r[i],
                    s[i]
                )
            );
        }
        return true;
    }

    /// @dev Synchronously executes multiple fill orders in a single transaction until total fillTakerTokenAmount filled.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param fillTakerTokenAmount Desired total amount of takerToken to fill in orders.
    /// @param shouldThrowOnInsufficientBalanceOrAllowance Test if transfers will fail before attempting.
    /// @param v Array ECDSA signature v parameters.
    /// @param r Array of ECDSA signature r parameters.
    /// @param s Array of ECDSA signature s parameters.
    /// @return Total amount of fillTakerTokenAmount filled in orders.
    function fillOrdersUpTo(
        address[7][] orderAddresses,
        uint[6][] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s
    )
        public
        returns (uint filledTakerTokenAmount)
    {
        filledTakerTokenAmount = 0;
        for (uint i = 0; i < orderAddresses.length; i++) {
            require(orderAddresses[i][3] == orderAddresses[0][3]); // takerToken must be the same for each order
            filledTakerTokenAmount = safeAdd(
                filledTakerTokenAmount,
                fillOrder(
                    orderAddresses[i],
                    orderValues[i],
                    safeSub(fillTakerTokenAmount, filledTakerTokenAmount),
                    shouldThrowOnInsufficientBalanceOrAllowance,
                    v[i],
                    r[i],
                    s[i]
                )
            );
            if (filledTakerTokenAmount == fillTakerTokenAmount) {
                break;
            }
        }
        return filledTakerTokenAmount;
    }

    /// @dev Synchronously cancels multiple orders in a single transaction.
    /// @param orderAddresses Array of address arrays containing individual order addresses.
    /// @param orderValues Array of uint arrays containing individual order values.
    /// @param cancelTakerTokenAmounts Array of desired amounts of takerToken to cancel in orders.
    /// @return Successful if no cancels throw.
    function batchCancelOrders(
        address[7][] orderAddresses,
        uint[6][] orderValues,
        uint[] cancelTakerTokenAmounts
    )
        public
        returns (bool success)
    {
        for (uint i = 0; i < orderAddresses.length; i++) {
            cancelOrder(
                orderAddresses[i],
                orderValues[i],
                cancelTakerTokenAmounts[i]
            );
        }
        return true;
    }

    /*
    * Constant public functions
    */

    /// @dev Calculates Keccak-256 hash of order with specified parameters.
    /// @param orderAddresses Array of order's maker, taker, makerToken, takerToken, feeRecipient, makerFeeToken, and takerFeeToken.
    /// @param orderValues Array of order's makerTokenAmount, takerTokenAmount, makerFee, takerFee, expirationTimestampInSec, and salt.
    /// @return Keccak-256 hash of order.
    function getOrderHash(
        address[7] orderAddresses,
        uint[6] orderValues
    )
        public
        view
        returns (bytes32 orderHash)
    {
        return keccak256(abi.encodePacked(
            address(this),
            orderAddresses[0], // maker
            orderAddresses[1], // taker
            orderAddresses[2], // makerToken
            orderAddresses[3], // takerToken
            orderAddresses[4], // feeRecipient
            orderAddresses[5], // makerFeeToken
            orderAddresses[6], // takerFeeToken
            orderValues[0],    // makerTokenAmount
            orderValues[1],    // takerTokenAmount
            orderValues[2],    // makerFee
            orderValues[3],    // takerFee
            orderValues[4],    // expirationTimestampInSec
            orderValues[5]     // salt
        ));
    }

    /// @dev Verifies that an order signature is valid.
    /// @param signer address of signer.
    /// @param hash Signed Keccak-256 hash.
    /// @param v ECDSA signature parameter v.
    /// @param r ECDSA signature parameters r.
    /// @param s ECDSA signature parameters s.
    /// @return Validity of order signature.
    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        pure
        returns (bool isValid)
    {
        return signer == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            v,
            r,
            s
        );
    }

    /// @dev Checks if rounding error > 0.1%.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return Rounding error is present.
    function isRoundingError(
        uint numerator,
        uint denominator,
        uint target
    )
        public
        pure
        returns (bool isError)
    {
        return (target < 10**3 && mulmod(target, numerator, denominator) != 0);
    }

    /// @dev Calculates partial value given a numerator and denominator.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return Partial value of target.
    function getPartialAmount(uint numerator, uint denominator, uint target)
        public
        pure
        returns (uint)
    {
        return safeDiv(safeMul(numerator, target), denominator);
    }

    /// @dev Calculates the sum of values already filled and cancelled for a given order.
    /// @param orderHash The Keccak-256 hash of the given order.
    /// @return Sum of values already filled and cancelled.
    function getUnavailableTakerTokenAmount(
        bytes32 orderHash
    )
        public
        view
        returns (uint unavailableTakerTokenAmount)
    {
        return safeAdd(filled[orderHash], cancelled[orderHash]);
    }

    /*
    * Internal functions
    */

    /// @dev Transfers a token using PROXY_CONTRACT transferFrom function.
    /// @param token Address of token to transferFrom.
    /// @param from Address transfering token.
    /// @param to Address receiving token.
    /// @param value Amount of token to transfer.
    /// @return Success of token transfer.
    function transferViaProxy(
        address token,
        address from,
        address to,
        uint value
    )
        internal
    {
        Proxy(PROXY_CONTRACT).transferTo(
            token,
            from,
            to,
            value
        );
    }

    /// @dev Checks if any order transfers will fail.
    /// @param order Order struct of params that will be checked.
    /// @param fillMakerTokenAmount Desired amount of makerToken to fill.
    /// @param fillTakerTokenAmount Desired amount of takerToken to fill.
    /// @param fillMakerFee calculated maker fee
    /// @param fillTakerFee calculated taker fee
    /// @return Predicted result of transfers.
    function isTransferable(
        Order order,
        uint fillMakerTokenAmount,
        uint fillTakerTokenAmount,
        uint fillMakerFee,
        uint fillTakerFee
    )
        internal
        view
        returns (bool _isTransferable)
    {
        address taker = msg.sender;

        if (order.feeRecipient != address(0)) {
            bool isMakerTokenFeeToken = order.makerToken == order.makerFeeToken;
            bool isTakerTokenFeeToken = order.takerToken == order.takerFeeToken;

            uint requiredMakerFeeToken = isMakerTokenFeeToken ? safeAdd(
                fillMakerTokenAmount,
                fillMakerFee
            ) : fillMakerFee;
            uint requiredTakerFeeToken = isTakerTokenFeeToken ? safeAdd(
                fillTakerTokenAmount,
                fillTakerFee
            ) : fillTakerFee;

            if (
                getBalance(order.makerFeeToken, order.maker) < requiredMakerFeeToken
                || getAllowance(order.makerFeeToken, order.maker) < requiredMakerFeeToken
                || getBalance(order.takerFeeToken, taker) < requiredTakerFeeToken
                || getAllowance(order.takerFeeToken, taker) < requiredTakerFeeToken
            ) {
                return false;
            }

            if (
                !isMakerTokenFeeToken
                && (
                    getBalance(order.makerToken, order.maker) < fillMakerTokenAmount
                    || getAllowance(order.makerToken, order.maker) < fillMakerTokenAmount
                )
            ) {
                return false;
            }
            if (
                !isTakerTokenFeeToken
                && (
                    getBalance(order.takerToken, taker) < fillTakerTokenAmount
                    || getAllowance(order.takerToken, taker) < fillTakerTokenAmount
                )
            ) {
                return false;
            }
        } else if (
            getBalance(order.makerToken, order.maker) < fillMakerTokenAmount
            || getAllowance(order.makerToken, order.maker) < fillMakerTokenAmount
            || getBalance(order.takerToken, taker) < fillTakerTokenAmount
            || getAllowance(order.takerToken, taker) < fillTakerTokenAmount
        ) {
            return false;
        }

        return true;
    }

    /// @dev Get token balance of an address.
    /// @param token Address of token.
    /// @param owner Address of owner.
    /// @return Token balance of owner.
    function getBalance(
        address token,
        address owner
    )
        internal
        view
        returns (uint balance)
    {
        return ERC20(token).balanceOf(owner);
    }

    /// @dev Get allowance of token given to PROXY_CONTRACT by an address.
    /// @param token Address of token.
    /// @param owner Address of owner.
    /// @return Allowance of token given to PROXY_CONTRACT by owner.
    function getAllowance(
        address token,
        address owner
    )
        internal
        view
        returns (uint allowance)
    {
        return ERC20(token).allowance(owner, PROXY_CONTRACT);
    }

    // @dev Helper to log a LogFill event
    function logFillEvent(
        Order order,
        uint[4] values
    )
        internal
    {
        emit LogFill(
            order.maker,
            msg.sender,
            order.feeRecipient,
            order.makerToken,
            order.takerToken,
            order.makerFeeToken,
            order.takerFeeToken,
            values[0],
            values[1],
            values[2],
            values[3],
            keccak256(abi.encodePacked(order.makerToken, order.takerToken)),
            order.orderHash
        );
    }
}