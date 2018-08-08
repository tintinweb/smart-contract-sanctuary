pragma solidity 0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Presale {

  using SafeMath for uint256;
  uint256 private weiRaised;
  uint256 private startTime;
  uint256 private endTime;
  uint256 private rate;

  uint256 private cap;

  function Presale(uint256 _startTime, uint256 duration, uint256 _rate, uint256 _cap) public {
    require(_rate > 0);
    require(_cap > 0);
    require(_startTime >= now);
    require(duration > 0);

    rate = _rate;
    cap = _cap;
    startTime = _startTime;
    endTime = startTime + duration * 1 days;
    weiRaised = 0;
  }

  function totalWei() public constant returns(uint256) {
    return weiRaised;
  }

  function capRemaining() public constant returns(uint256) {
    return cap.sub(weiRaised);
  }

  function totalCap() public constant returns(uint256) {
    return cap;
  }

  function buyTokens(address purchaser, uint256 value) internal returns(uint256) {
    require(validPurchase(value));
    uint256 tokens = rate.mul(value);
    weiRaised = weiRaised.add(value);
    return tokens;
  }

  function hasEnded() internal constant returns(bool) {
    return now > endTime || weiRaised >= cap;
  }

  function hasStarted() internal constant returns(bool) {
    return now > startTime;
  }

  function validPurchase(uint256 value) internal view returns (bool) {
    bool withinCap = weiRaised.add(value) <= cap;
    return withinCap && withinPeriod();
  }

  function presaleRate() public view returns(uint256) {
    return rate;
  }

  function withinPeriod () private constant returns(bool) {
    return now >= startTime && now <= endTime;
  }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

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
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

/// @title Vesting trustee contract for erc20 token.
contract VestingTrustee is Ownable, CanReclaimToken {
    using SafeMath for uint256;

    // erc20 token contract.
    ERC20 public token;

    // Vesting grant for a speicifc holder.
    struct Grant {
        uint256 value;
        uint256 start;
        uint256 cliff;
        uint256 end;
        uint256 installmentLength; // In seconds.
        uint256 transferred;
        bool revokable;
        uint256 prevested;
        uint256 vestingPercentage;
    }

    // Holder to grant information mapping.
    mapping (address => Grant) public grants;

    // Total tokens available for vesting.
    uint256 public totalVesting;

    event NewGrant(address indexed _from, address indexed _to, uint256 _value);
    event TokensUnlocked(address indexed _to, uint256 _value);
    event GrantRevoked(address indexed _holder, uint256 _refund);

    /// @dev Constructor that initializes the address of the  token contract.
    /// @param _token erc20 The address of the previously deployed token contract.
    function VestingTrustee(address _token) {
        require(_token != address(0));

        token = ERC20(_token);
    }

    /// @dev Grant tokens to a specified address.
    /// @param _to address The holder address.
    /// @param _value uint256 The amount of tokens to be granted.
    /// @param _start uint256 The beginning of the vesting period.
    /// @param _cliff uint256 Duration of the cliff period (when the first installment is made).
    /// @param _end uint256 The end of the vesting period.
    /// @param _installmentLength uint256 The length of each vesting installment (in seconds).
    /// @param _revokable bool Whether the grant is revokable or not.
    function grant(address _to, uint256 _value, uint256 _start, uint256 _cliff, uint256 _end,
        uint256 _installmentLength, uint256 vestingPercentage, uint256 prevested, bool _revokable)
        external onlyOwner {

        require(_to != address(0));
        require(_to != address(this)); // Don&#39;t allow holder to be this contract.
        require(_value > 0);
        require(_value.sub(prevested) > 0);
        require(vestingPercentage > 0);

        // Require that every holder can be granted tokens only once.
        require(grants[_to].value == 0);

        // Require for time ranges to be consistent and valid.
        require(_start <= _cliff && _cliff <= _end);

        // Require installment length to be valid and no longer than (end - start).
        require(_installmentLength > 0 && _installmentLength <= _end.sub(_start));

        // Grant must not exceed the total amount of tokens currently available for vesting.
        require(totalVesting.add(_value.sub(prevested)) <= token.balanceOf(address(this)));

        // Assign a new grant.
        grants[_to] = Grant({
            value: _value,
            start: _start,
            cliff: _cliff,
            end: _end,
            installmentLength: _installmentLength,
            transferred: prevested,
            revokable: _revokable,
            prevested: prevested,
            vestingPercentage: vestingPercentage
        });

        totalVesting = totalVesting.add(_value.sub(prevested));
        NewGrant(msg.sender, _to, _value);
    }

    /// @dev Revoke the grant of tokens of a specifed address.
    /// @param _holder The address which will have its tokens revoked.
    function revoke(address _holder) public onlyOwner {
        Grant memory grant = grants[_holder];

        // Grant must be revokable.
        require(grant.revokable);

        // Calculate amount of remaining tokens that are still available to be
        // returned to owner.
        uint256 refund = grant.value.sub(grant.transferred);

        // Remove grant information.
        delete grants[_holder];

        // Update total vesting amount and transfer previously calculated tokens to owner.
        totalVesting = totalVesting.sub(refund);
        token.transfer(msg.sender, refund);

        GrantRevoked(_holder, refund);
    }

    /// @dev Calculate the total amount of vested tokens of a holder at a given time.
    /// @param _holder address The address of the holder.
    /// @param _time uint256 The specific time to calculate against.
    /// @return a uint256 Representing a holder&#39;s total amount of vested tokens.
    function vestedTokens(address _holder, uint256 _time) external constant returns (uint256) {
        Grant memory grant = grants[_holder];
        if (grant.value == 0) {
            return 0;
        }

        return calculateVestedTokens(grant, _time);
    }

    /// @dev Calculate amount of vested tokens at a specifc time.
    /// @param _grant Grant The vesting grant.
    /// @param _time uint256 The time to be checked
    /// @return a uint256 Representing the amount of vested tokens of a specific grant.
    function calculateVestedTokens(Grant _grant, uint256 _time) private constant returns (uint256) {
        // If we&#39;re before the cliff, then nothing is vested.
        if (_time < _grant.cliff) {
            return _grant.prevested;
        }

        // If we&#39;re after the end of the vesting period - everything is vested;
        if (_time >= _grant.end) {
            return _grant.value;
        }

        // Calculate amount of installments past until now.
        uint256 installmentsPast = _time.sub(_grant.cliff).div(_grant.installmentLength) + 1;


        // Calculate and return installments that have passed according to vesting days that have passed.
        return _grant.prevested.add(_grant.value.mul(installmentsPast.mul(_grant.vestingPercentage)).div(100));
    }

    /// @dev Unlock vested tokens and transfer them to their holder.
    /// @return a uint256 Representing the amount of vested tokens transferred to their holder.
    function unlockVestedTokens() external {
        Grant storage grant = grants[msg.sender];

        // Require that there will be funds left in grant to tranfser to holder.
        require(grant.value != 0);

        // Get the total amount of vested tokens, acccording to grant.
        uint256 vested = calculateVestedTokens(grant, now);
        if (vested == 0) {
            revert();
        }

        // Make sure the holder doesn&#39;t transfer more than what he already has.
        uint256 transferable = vested.sub(grant.transferred);
        if (transferable == 0) {
            revert();
        }

        grant.transferred = grant.transferred.add(transferable);
        totalVesting = totalVesting.sub(transferable);
        token.transfer(msg.sender, transferable);
        TokensUnlocked(msg.sender, transferable);
    }

    function reclaimEther() external onlyOwner {
      assert(owner.send(this.balance));
    }
}

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { require(msg.sender == controller); _; }

    address public controller;

    function Controlled() public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) public payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public
        returns(bool);
}

/*
    Copyright 2016, Jordi Baylina

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MiniMeToken Contract
/// @author Jordi Baylina
/// @dev This token contract&#39;s goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO&#39;s
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.




contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = &#39;MMT_0.2&#39;; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct  Checkpoint {

        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;

        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    MiniMeToken public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

    // The factory used to create new clone tokens
    MiniMeTokenFactory public tokenFactory;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a MiniMeToken
    /// @param _tokenFactory The address of the MiniMeTokenFactory contract that
    ///  will create the Clone token contracts, the token factory needs to be
    ///  deployed first
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    function MiniMeToken(
        address _tokenFactory,
        address _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            require(allowed[_from][msg.sender] >= _amount);
            allowed[_from][msg.sender] -= _amount;
        }
        doTransfer(_from, _to, _amount);
        return true;
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount
    ) internal {

           if (_amount == 0) {
               Transfer(_from, _to, _amount);    // Follow the spec to louch the event when transfer 0
               return;
           }

           require(parentSnapShotBlock < block.number);

           // Do not allow transfer to 0x0 or the token contract itself
           require((_to != 0) && (_to != address(this)));

           // If the amount being transfered is more than the balance of the
           //  account the transfer throws
           var previousBalanceFrom = balanceOfAt(_from, block.number);

           require(previousBalanceFrom >= _amount);

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               require(TokenController(controller).onTransfer(_from, _to, _amount));
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           var previousBalanceTo = balanceOfAt(_to, block.number);
           require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

    }

    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            require(TokenController(controller).onApprove(msg.sender, _spender, _amount));
        }

        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender
    ) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public constant returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public constant
        returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0)
            || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public constant returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0)
            || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != 0) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Clone Token Method
////////////////

    /// @notice Creates a new clone token with the initial distribution being
    ///  this token at `_snapshotBlock`
    /// @param _cloneTokenName Name of the clone token
    /// @param _cloneDecimalUnits Number of decimals of the smallest unit
    /// @param _cloneTokenSymbol Symbol of the clone token
    /// @param _snapshotBlock Block when the distribution of the parent token is
    ///  copied to set the initial distribution of the new clone token;
    ///  if the block is zero than the actual block, the current block is used
    /// @param _transfersEnabled True if transfers are allowed in the clone
    /// @return The address of the new MiniMeToken Contract
    function createCloneToken(
        string _cloneTokenName,
        uint8 _cloneDecimalUnits,
        string _cloneTokenSymbol,
        uint _snapshotBlock,
        bool _transfersEnabled
        ) public returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = block.number;
        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            _snapshotBlock,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
            );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), _snapshotBlock);
        return address(cloneToken);
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount
    ) public onlyController returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController public returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public onlyController {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block
    ) constant internal returns (uint) {
        if (checkpoints.length == 0) return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
    ) internal  {
        if ((checkpoints.length == 0)
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint storage newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
               oldCheckPoint.value = uint128(_value);
           }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract&#39;s controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () public payable {
        require(isContract(controller));
        require(TokenController(controller).proxyPayment.value(msg.value)(msg.sender));
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        MiniMeToken token = MiniMeToken(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

////////////////
// Events
////////////////
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

}


////////////////
// MiniMeTokenFactory
////////////////

/// @dev This contract is used to generate clone contracts from a contract.
///  In solidity this is the way to create a contract from a contract of the
///  same class
contract MiniMeTokenFactory {

    /// @notice Update the DApp by creating a new token with new functionalities
    ///  the msg.sender becomes the controller of this clone token
    /// @param _parentToken Address of the token being cloned
    /// @param _snapshotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    /// @return The address of the new token contract
    function createCloneToken(
        address _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken) {
        MiniMeToken newToken = new MiniMeToken(
            this,
            _parentToken,
            _snapshotBlock,
            _tokenName,
            _decimalUnits,
            _tokenSymbol,
            _transfersEnabled
            );

        newToken.changeController(msg.sender);
        return newToken;
    }
}

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      WhitelistedAddressAdded(addr);
      success = true;
    }
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

contract Crowdsale is Presale, Pausable, CanReclaimToken, Whitelist {

  using SafeMath for uint256;
  address public whitelistAddress;
  address public wallet; //wallet where the funds collected are transfered
  MiniMeToken public token; //ERC20 Token
  uint256 private weiRaised = 0; //WeiRaised during the public Sale
  uint256 private cap = 0; //Cap of the public Sale in Wei
  bool private publicSaleInitialized = false;
  bool private finalized = false;
  uint256 private tokensSold = 0; //tokens sold during the entire sale
  uint256 private startTime; //start time of the public sale initialized after the presale is over
  uint256 private endTime; //endtime of the public sale
  uint256 public maxTokens;
  mapping(address => uint256) public contributions; //contributions of each investor
  mapping(address => uint256) public investorCaps; //for whitelisting
  address[] public investors; //investor list who participate in the ICO
  address[] public founders; //list of founders
  address[] public advisors; //list of advisors
  VestingTrustee public trustee;
  address public reserveWallet; //reserveWallet where the unsold tokens will be sent to

  //Rate for each tier (no of tokens for 1 ETH)
  //Max wei for each tier
  struct Tier {
    uint256 rate;
    uint256 max;
  }

  uint public privateSaleTokensAvailable;
  uint public privateSaleTokensSold = 0;
  uint public publicTokensAvailable;

  uint8 public totalTiers = 0; //total Tiers in the public sale
  bool public tiersInitialized = false;
  uint256 public maxTiers = 6; //max tiers that can be in the publicsale
  Tier[6] public tiers; //array of tiers

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  enum Stage { Preparing, Presale, PresaleFinished, PublicSale, Success, Finalized }

  function Crowdsale(
    uint256 _presaleStartTime, //presale start time
    uint256 _presaleDuration, //presale duration in days
    uint256 _presaleRate, // presale rate. ie No of tokens per 1 ETH
    uint256 _presaleCap, // max wei that can raised
    address erc20Token, // Token used for the crowdsale
    address _wallet,
    uint8 _tiers,
    uint256 _cap,
    address _reserveWallet)
    public
    Presale(_presaleStartTime, _presaleDuration, _presaleRate, _presaleCap)
    {
      require(_wallet != address(0));
      require(erc20Token != address(0));
      require(_tiers > 0 && _tiers <= maxTiers);
      require(_cap > 0);
      require(_reserveWallet != address(0));
      token = MiniMeToken(erc20Token);
      wallet = _wallet;
      totalTiers = _tiers;
      cap = _cap;
      reserveWallet = _reserveWallet;
      trustee = new VestingTrustee(erc20Token);
      maxTokens = 1000000000 * (10 ** 18); // 1 B tokens
      privateSaleTokensAvailable = maxTokens.mul(22).div(100);
      publicTokensAvailable = maxTokens.mul(28).div(100);
      super.addAddressToWhitelist(msg.sender);

    }

  function() public payable {
    buyTokens(msg.sender, msg.value);
  }

  function getStage() public constant returns(Stage) {
    if (finalized) return Stage.Finalized;
    if (!tiersInitialized || !Presale.hasStarted()) return Stage.Preparing;
    if (!Presale.hasEnded()) return Stage.Presale;
    if (Presale.hasEnded() && !hasStarted()) return Stage.PresaleFinished;
    if (!hasEnded()) return Stage.PublicSale;
    if (hasEnded()) return Stage.Success;
    return Stage.Preparing;
  }

  modifier inStage(Stage _stage) {
    require(getStage() == _stage);
    _;
  }

  // rates for each tier and total wei in that tiers
  // they are added up together
  function initTiers(uint256[] rates, uint256[] totalWeis) public onlyWhitelisted returns(uint256) {
    require(token.controller() == address(this));
    require(!tiersInitialized);
    require(rates.length == totalTiers && rates.length == totalWeis.length);
    uint256 tierMax = 0;

    for (uint8 i=0; i < totalTiers; i++) {

      require(totalWeis[i] > 0 && rates[i] > 0);

      tierMax = tierMax.add(totalWeis[i]);
      tiers[i] = Tier({
        rate: rates[i],
        max: tierMax
      });
    }

    require(tierMax == cap);
    tiersInitialized = true;
    return tierMax;
  }

  // function for whitelisting investors with caps
  function setCapForParticipants(address[] participants, uint256[] caps) onlyWhitelisted public  {
    require(participants.length <= 50 && participants.length == caps.length);
    for (uint8 i=0; i < participants.length; i++) {
      investorCaps[participants[i]] = caps[i];
    }
  }


  function addGrant(address assignee, uint256 value, bool isFounder) public onlyWhitelisted whenNotPaused {
    require(value > 0);
    require(assignee != address(0));
    uint256 start;
    uint256 cliff;
    uint256 vestingPercentage;
    uint256 initialTokens;
    if(isFounder) {
      start = now;
      cliff = start + 12*30 days; //12 months
      vestingPercentage = 20; //20%
      founders.push(assignee);
    }
    else {
      // for advisors
      // transfer 10% of the tokens at start
      initialTokens = value.mul(10).div(100);
      transferTokens(assignee, initialTokens);
      start = now;
      cliff = start + 6*30 days;  //6 months
      vestingPercentage = 15; //15% for each installments
      advisors.push(assignee);
    }

    uint256 end = now + 3 * 1 years; //3 years
    uint256 installmentLength = 6 * 30 days; // 6 month installments
    bool revokable = true;
    transferTokens(trustee, value.sub(initialTokens));
    trustee.grant(assignee, value, start, cliff, end, installmentLength, vestingPercentage, initialTokens, revokable);
  }

  // called by the owner to close the crowdsale
  function finalize() public onlyWhitelisted inStage(Stage.Success) {
    require(!finalized);
    //trustee&#39;s ownership is transfered from the crowdsale to owner of the contract
    trustee.transferOwnership(msg.sender);
    //enable token transfer
    token.enableTransfers(true);
    //generate the unsold tokens to the reserve
    uint256 unsold = maxTokens.sub(token.totalSupply());
    transferTokens(reserveWallet, unsold);

    // change the token&#39;s controller to a zero Address so that it cannot
    // generate or destroy tokens
    token.changeController(0x0);
    finalized = true;
  }

  //start the public sale manually after the presale is over, duration is in days
  function startPublicSale(uint _startTime, uint _duration) public onlyWhitelisted inStage(Stage.PresaleFinished) {
    require(_startTime >= now);
    require(_duration > 0);
    startTime = _startTime;
    endTime = _startTime + _duration * 1 days;
    publicSaleInitialized = true;
  }

  // total wei raised in the presale and public sale
  function totalWei() public constant returns(uint256) {
    uint256 presaleWei = super.totalWei();
    return presaleWei.add(weiRaised);
  }

  function totalPublicSaleWei() public constant returns(uint256) {
    return weiRaised;
  }
  // total cap of the presale and public sale
  function totalCap() public constant returns(uint256) {
    uint256 presaleCap = super.totalCap();
    return presaleCap.add(cap);
  }

  // Total tokens sold duing the presale and public sale.
  // Total tokens has to divided by 10^18
  function totalTokens() public constant returns(uint256) {
    return tokensSold;
  }

  // MAIN BUYING Function
  function buyTokens(address purchaser, uint256 value) internal  whenNotPaused returns(uint256) {
    require(value > 0);
    Stage stage = getStage();
    require(stage == Stage.Presale || stage == Stage.PublicSale);

    //the purchase amount cannot be more than the whitelisted cap
    uint256 purchaseAmount = Math.min256(value, investorCaps[purchaser].sub(contributions[purchaser]));
    require(purchaseAmount > 0);
    uint256 numTokens;

    //call the presale contract
    if (stage == Stage.Presale) {
      if (Presale.totalWei().add(purchaseAmount) > Presale.totalCap()) {
        purchaseAmount = Presale.capRemaining();
      }
      numTokens = Presale.buyTokens(purchaser, purchaseAmount);
    } else if (stage == Stage.PublicSale) {

      uint totalWei = weiRaised.add(purchaseAmount);
      uint8 currentTier = getTier(weiRaised); //get current tier
      if (totalWei >= cap) { // will TOTAL_CAP(HARD_CAP) of the public sale be reached ?
        totalWei = cap;
        //purchase amount can be only be (CAP - WeiRaised)
        purchaseAmount = cap.sub(weiRaised);
      }

      // if the totalWei( weiRaised + msg.value) fits within current cap
      // number of tokens would be rate * purchaseAmount
      if (totalWei <= tiers[currentTier].max) {
        numTokens = purchaseAmount.mul(tiers[currentTier].rate);
      } else {
        //wei remaining in the current tier
        uint remaining = tiers[currentTier].max.sub(weiRaised);
        numTokens = remaining.mul(tiers[currentTier].rate);

        //wei in the next tier
        uint256 excess = totalWei.sub(tiers[currentTier].max);
        //number of tokens  = wei remaining in the next tier * rate of the next tier
        numTokens = numTokens.add(excess.mul(tiers[currentTier + 1].rate));
      }

      // update the total raised so far
      weiRaised = weiRaised.add(purchaseAmount);
    }

    // total tokens sold in the entire sale
    require(tokensSold.add(numTokens) <= publicTokensAvailable);
    tokensSold = tokensSold.add(numTokens);

    // forward funds to the wallet
    forwardFunds(purchaser, purchaseAmount);
    // transfer the tokens to the purchaser
    transferTokens(purchaser, numTokens);

    // return the remaining unused wei back
    if (value.sub(purchaseAmount) > 0) {
      msg.sender.transfer(value.sub(purchaseAmount));
    }

    //event
    TokenPurchase(purchaser, numTokens, purchaseAmount);

    return numTokens;
  }



  function forwardFunds(address purchaser, uint256 value) internal {
    //new investor
    if (contributions[purchaser] == 0) {
      investors.push(purchaser);
    }
    //add contribution to the purchaser
    contributions[purchaser] = contributions[purchaser].add(value);
    wallet.transfer(value);
  }

  function changeEndTime(uint _endTime) public onlyWhitelisted {
    endTime = _endTime;
  }

  function changeFundsWallet(address _newWallet) public onlyWhitelisted {
    require(_newWallet != address(0));
    wallet = _newWallet;
  }

  function changeTokenController() onlyWhitelisted public {
    token.changeController(msg.sender);
  }

  function changeTrusteeOwner() onlyWhitelisted public {
    trustee.transferOwnership(msg.sender);
  }
  function changeReserveWallet(address _reserve) public onlyWhitelisted {
    require(_reserve != address(0));
    reserveWallet = _reserve;
  }

  function setWhitelistAddress(address _whitelist) public onlyWhitelisted {
    require(_whitelist != address(0));
    whitelistAddress = _whitelist;
  }

  function transferTokens(address to, uint256 value) internal {
    token.generateTokens(to, value);
  }

  function sendPrivateSaleTokens(address to, uint256 value) public whenNotPaused onlyWhitelisted {
    require(privateSaleTokensSold.add(value) <= privateSaleTokensAvailable);
    privateSaleTokensSold = privateSaleTokensSold.add(value);
    transferTokens(to, value);
  }

  function hasEnded() internal constant returns(bool) {
    return now > endTime || weiRaised >= cap;
  }

  function hasStarted() internal constant returns(bool) {
    return publicSaleInitialized && now >= startTime;
  }

  function getTier(uint256 _weiRaised) internal constant returns(uint8) {
    for (uint8 i = 0; i < totalTiers; i++) {
      if (_weiRaised < tiers[i].max) {
        return i;
      }
    }
    //wont reach but for safety
    return totalTiers + 1;
  }



  function getCurrentTier() public constant returns(uint8) {
    return getTier(weiRaised);
  }


  // functions for the mini me token
  function proxyPayment(address _owner) public payable returns(bool) {
    return true;
  }

  function onApprove(address _owner, address _spender, uint _amount) public returns(bool) {
    return true;
  }

  function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
    return true;
  }

  function getTokenSaleTime() public constant returns(uint256, uint256) {
    return (startTime, endTime);
  }
}