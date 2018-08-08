pragma solidity ^0.4.11;

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract ERC20Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
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


/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount)
        returns(bool);
}

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController { if (msg.sender != controller) throw; _; }

    address public controller;

    function Controlled() { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = &#39;MMT_0.1&#39;; //An arbitrary versioning scheme


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
    ) {
        tokenFactory = MiniMeTokenFactory(_tokenFactory);
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = MiniMeToken(_parentToken);
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = getBlockNumber();
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            if (!transfersEnabled) throw;

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount) return false;
            allowed[_from][msg.sender] -= _amount;
        }
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount
    ) internal returns(bool) {

           if (_amount == 0) {
               return true;
           }

           if (parentSnapShotBlock >= getBlockNumber()) throw;

           // Do not allow transfer to 0x0 or the token contract itself
           if ((_to == 0) || (_to == address(this))) throw;

           // If the amount being transfered is more than the balance of the
           //  account the transfer returns false
           var previousBalanceFrom = balanceOfAt(_from, getBlockNumber());
           if (previousBalanceFrom < _amount) {
               return false;
           }

           // Alerts the token controller of the transfer
           if (isContract(controller)) {
               if (!TokenController(controller).onTransfer(_from, _to, _amount))
               throw;
           }

           // First update the balance array with the new value for the address
           //  sending the tokens
           updateValueAtNow(balances[_from], previousBalanceFrom - _amount);

           // Then update the balance array with the new value for the address
           //  receiving the tokens
           var previousBalanceTo = balanceOfAt(_to, getBlockNumber());
           if (previousBalanceTo + _amount < previousBalanceTo) throw; // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

           return true;
    }

    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, getBlockNumber());
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) returns (bool success) {
        if (!transfersEnabled) throw;

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        if ((_amount!=0) && (allowed[msg.sender][_spender] !=0)) throw;

        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
                throw;
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
    ) constant returns (uint256 remaining) {
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
    ) returns (bool success) {
        if (!approve(_spender, _amount)) throw;

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
    function totalSupply() constant returns (uint) {
        return totalSupplyAt(getBlockNumber());
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) constant
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
    function totalSupplyAt(uint _blockNumber) constant returns(uint) {

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
        ) returns(address) {
        if (_snapshotBlock == 0) _snapshotBlock = getBlockNumber();
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
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
        if (curTotalSupply + _amount < curTotalSupply) throw; // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        var previousBalanceTo = balanceOf(_owner);
        if (previousBalanceTo + _amount < previousBalanceTo) throw; // Check for overflow
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        Transfer(0, _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount
    ) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, getBlockNumber());
        if (curTotalSupply < _amount) throw;
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        var previousBalanceFrom = balanceOf(_owner);
        if (previousBalanceFrom < _amount) throw;
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        Transfer(_owner, 0, _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController {
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
        || (checkpoints[checkpoints.length -1].fromBlock < getBlockNumber())) {
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(getBlockNumber());
               newCheckPoint.value = uint128(_value);
           } else {
               Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
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
    function min(uint a, uint b) internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract&#39;s controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function ()  payable {
        if (isContract(controller)) {
            if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender))
                throw;
        } else {
            throw;
        }
    }


//////////
// Testing specific methods
//////////

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
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
    ) returns (MiniMeToken) {
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

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        if(msg.sender != owner) throw;
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

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

contract ATTContribution is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public exchangeRate = 600;   // will be set before the token sale.
    uint256 constant public maxGasPrice = 50000000000;  // 50GWei

    uint256 public maxFirstRoundTokenLimit = 20000000 ether; // ATT have same precision with ETH

    uint256 public maxIssueTokenLimit = 70000000 ether; // ATT have same precision with ETH

    MiniMeToken public  ATT;            // The ATT token itself

    address public attController;

    address public destEthFoundation;
    address public destTokensAngel;

    uint256 public startTime;
    uint256 public endTime;

    uint256 public totalNormalTokenGenerated;
    uint256 public totalNormalEtherCollected;

    uint256 public totalIssueTokenGenerated;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    bool public paused;

    modifier initialized() {
        require(address(ATT) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
              time() <= endTime &&
              finalizedBlock == 0 &&
              address(ATT) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function ATTContribution() {
        paused = false;
    }


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _att Address of the ATT token contract
    /// @param _attController Token controller for the ATT that will be transferred after
    ///  the contribution finalizes.
    /// @param _startTime Time when the contribution period starts
    /// @param _endTime The time that the contribution period ends
    /// @param _destEthFoundation Destination address where the contribution ether is sent
    /// @param _destTokensAngel Address where the tokens for the angels are sent
    function initialize(
        address _att,
        address _attController,
        uint _startTime,
        uint _endTime,
        address _destEthFoundation,
        address _destTokensAngel
    ) public onlyOwner {
      // Initialize only once
      require(address(ATT) == 0x0);

      ATT = MiniMeToken(_att);
      require(ATT.totalSupply() == 0);
      require(ATT.controller() == address(this));
      require(ATT.decimals() == 18);  // Same amount of decimals as ETH

      startTime = _startTime;
      endTime = _endTime;

      assert(startTime < endTime);

      require(_attController != 0x0);
      attController = _attController;

      require(_destEthFoundation != 0x0);
      destEthFoundation = _destEthFoundation;

      require(_destTokensAngel != 0x0);
      destTokensAngel = _destTokensAngel;
  }

  /// @notice If anybody sends Ether directly to this contract, consider he is
  ///  getting ATTs.
  function () public payable notPaused {
      proxyPayment(msg.sender);
  }


  //////////
  // MiniMe Controller functions
  //////////

  /// @notice This method will generally be called by the ATT token contract to
  ///  acquire ATTs. Or directly from third parties that want to acquire ATTs in
  ///  behalf of a token holder.
  /// @param _th ATT holder where the ATTs will be minted.
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
      require(_th != 0x0);

      buyNormal(_th);

      return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
      return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
      return false;
  }

  function buyNormal(address _th) internal {
      require(tx.gasprice <= maxGasPrice);
      
      // Antispam mechanism
      // TODO: Is this checking useful?
      address caller;
      if (msg.sender == address(ATT)) {
          caller = _th;
      } else {
          caller = msg.sender;
      }

      // Do not allow contracts to game the system
      require(!isContract(caller));

      doBuy(_th, msg.value);
  }

  function doBuy(address _th, uint256 _toFund) internal {
      require(tx.gasprice <= maxGasPrice);

      assert(msg.value >= _toFund);  // Not needed, but double check.
      assert(totalNormalTokenGenerated < maxFirstRoundTokenLimit);

      uint256 endOfFirstWeek = startTime.add(1 weeks);
      uint256 endOfSecondWeek = startTime.add(2 weeks);
      uint256 finalExchangeRate = exchangeRate;
      if (now < endOfFirstWeek)
      {
          // 10% Bonus in first week
          finalExchangeRate = exchangeRate.mul(110).div(100);
      } else if (now < endOfSecondWeek)
      {
          // 5% Bonus in second week
          finalExchangeRate = exchangeRate.mul(105).div(100);
      }

      if (_toFund > 0) {
          uint256 tokensGenerating = _toFund.mul(finalExchangeRate);

          uint256 tokensToBeGenerated = totalNormalTokenGenerated.add(tokensGenerating);
          if (tokensToBeGenerated > maxFirstRoundTokenLimit)
          {
              tokensGenerating = maxFirstRoundTokenLimit - totalNormalTokenGenerated;
              _toFund = tokensGenerating.div(finalExchangeRate);
          }

          assert(ATT.generateTokens(_th, tokensGenerating));
          destEthFoundation.transfer(_toFund);

          totalNormalTokenGenerated = totalNormalTokenGenerated.add(tokensGenerating);

          totalNormalEtherCollected = totalNormalEtherCollected.add(_toFund);

          NewSale(_th, _toFund, tokensGenerating);
      }

      uint256 toReturn = msg.value.sub(_toFund);
      if (toReturn > 0) {
          // TODO: If the call comes from the Token controller,
          // then we return it to the token Holder.
          // Otherwise we return to the sender.
          if (msg.sender == address(ATT)) {
              _th.transfer(toReturn);
          } else {
              msg.sender.transfer(toReturn);
          }
      }
  }

  function issueTokenToGuaranteedAddress(address _th, uint256 _amount, bytes data) onlyOwner initialized notPaused contributionOpen {
      require(totalIssueTokenGenerated.add(_amount) <= maxIssueTokenLimit);

      assert(ATT.generateTokens(_th, _amount));

      totalIssueTokenGenerated = totalIssueTokenGenerated.add(_amount);

      NewIssue(_th, _amount, data);
  }

  function adjustLimitBetweenIssueAndNormal(uint256 _amount, bool _isAddToNormal) onlyOwner initialized contributionOpen {
      if(_isAddToNormal)
      {
          require(totalIssueTokenGenerated.add(_amount) <= maxIssueTokenLimit);
          maxIssueTokenLimit = maxIssueTokenLimit.sub(_amount);
          maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.add(_amount);
      } else {
          require(totalNormalTokenGenerated.add(_amount) <= maxFirstRoundTokenLimit);
          maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.sub(_amount);
          maxIssueTokenLimit = maxIssueTokenLimit.add(_amount);
      }
  }

  // NOTE on Percentage format
  // Right now, Solidity does not support decimal numbers. (This will change very soon)
  //  So in this contract we use a representation of a percentage that consist in
  //  expressing the percentage in "x per 10**18"
  // This format has a precision of 16 digits for a percent.
  // Examples:
  //  3%   =   3*(10**16)
  //  100% = 100*(10**16) = 10**18
  //
  // To get a percentage of a value we do it by first multiplying it by the percentage in  (x per 10^18)
  //  and then divide it by 10**18
  //
  //              Y * X(in x per 10**18)
  //  X% of Y = -------------------------
  //               100(in x per 10**18)
  //


  /// @notice This method will can be called by the owner before the contribution period
  ///  end or by anybody after the `endBlock`. This method finalizes the contribution period
  ///  by creating the remaining tokens and transferring the controller to the configured
  ///  controller.
  function finalize() public onlyOwner initialized {
      require(time() >= startTime);
      // require(msg.sender == owner || time() > endTime);
      require(finalizedBlock == 0);

      finalizedBlock = getBlockNumber();
      finalizedTime = now;

      uint256 tokensToSecondRound = 90000000 ether;

      uint256 tokensToReserve = 90000000 ether;

      uint256 tokensToAngelAndOther = 30000000 ether;

      // totalTokenGenerated should equal to ATT.totalSupply()

      // If tokens in first round is not sold out, they will be added to second round and frozen together
      tokensToSecondRound = tokensToSecondRound.add(maxFirstRoundTokenLimit).sub(totalNormalTokenGenerated);
      
      tokensToSecondRound = tokensToSecondRound.add(maxIssueTokenLimit).sub(totalIssueTokenGenerated);

      uint256 totalTokens = 300000000 ether;

      require(totalTokens == ATT.totalSupply().add(tokensToSecondRound).add(tokensToReserve).add(tokensToAngelAndOther));

      assert(ATT.generateTokens(0xb1, tokensToSecondRound));

      assert(ATT.generateTokens(0xb2, tokensToReserve));

      assert(ATT.generateTokens(destTokensAngel, tokensToAngelAndOther));

      // totalTokens should equal to ATT.totalSupply()

      ATT.changeController(attController);

      Finalized();
  }

  function percent(uint256 p) internal returns (uint256) {
      return p.mul(10**16);
  }
  
  /// @dev Internal function to determine if an address is a contract
  /// @param _addr The address being queried
  /// @return True if `_addr` is a contract
  function isContract(address _addr) constant internal returns (bool) {
      if (_addr == 0) return false;
      uint256 size;
      assembly {
          size := extcodesize(_addr)
      }
      return (size > 0);
  }

  function time() constant returns (uint) {
      return block.timestamp;
  }

  //////////
  // Constant functions
  //////////

  /// @return Total tokens issued in weis.
  function tokensIssued() public constant returns (uint256) {
      return ATT.totalSupply();
  }

  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
      return block.number;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
      if (ATT.controller() == address(this)) {
          ATT.claimTokens(_token);
      }
      if (_token == 0x0) {
          owner.transfer(this.balance);
          return;
      }

      ERC20Token token = ERC20Token(_token);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
      ClaimedTokens(_token, owner, balance);
  }

  /// @notice Pauses the contribution if there is any issue
  function pauseContribution() onlyOwner {
      paused = true;
  }

  /// @notice Resumes the contribution
  function resumeContribution() onlyOwner {
      paused = false;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event NewIssue(address indexed _th, uint256 _amount, bytes data);
  event Finalized();
}

contract ATTPlaceHolder is TokenController, Owned {
    using SafeMath for uint256;

    MiniMeToken public att;
    ATTContribution public contribution;
    uint256 public activationTime;

    /// @notice Constructor
    /// @param _owner Trusted owner for this contract.
    /// @param _att ATT token contract address
    /// @param _contribution ATTContribution contract address
    function ATTPlaceHolder(address _owner, address _att, address _contribution) {
        owner = _owner;
        att = MiniMeToken(_att);
        contribution = ATTContribution(_contribution);
    }

    /// @notice The owner of this contract can change the controller of the ATT token
    ///  Please, be sure that the owner is a trusted agent or 0x0 address.
    /// @param _newController The address of the new controller
    function changeController(address _newController) public onlyOwner {
        att.changeController(_newController);
        ControllerChanged(_newController);
    }


    //////////
    // MiniMe Controller Interface functions
    //////////

    // In between the offering and the network. Default settings for allowing token transfers.
    function proxyPayment(address) public payable returns (bool) {
        return false;
    }

    function onTransfer(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function onApprove(address _from, address, uint256) public returns (bool) {
        return transferable(_from);
    }

    function transferable(address _from) internal returns (bool) {
        // Allow the exchanger to work from the beginning
        if (activationTime == 0) {
            uint256 f = contribution.finalizedTime();
            if (f > 0) {
                activationTime = f.add(1 weeks);
            } else {
                return false;
            }
        }
        return getTime() > activationTime;
    }


    //////////
    // Testing specific methods
    //////////

    /// @notice This function is overrided by the test Mocks.
    function getTime() internal returns (uint256) {
        return now;
    }


    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (att.controller() == address(this)) {
            att.claimTokens(_token);
        }
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, owner, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
    event ControllerChanged(address indexed _newController);
}