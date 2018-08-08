pragma solidity ^0.4.11;

/*
   Copyright 2017 DappHub, LLC

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

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract ERC20Token {
	function totalSupply() constant returns (uint supply);

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

pragma solidity ^0.4.11;

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
contract MiniMeToken is Controlled, ERC20Token {

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
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

	/**
	*
	* Fix for the ERC20 short address attack
	*
	* http://vessenes.com/the-erc20-short-address-attack-explained/
	*/
	modifier onlyPayloadSize(uint size) {
		if(msg.data.length != size + 4) {
		throw;
		}
		_;
	}

	/// @notice Send `_amount` tokens to `_to` from `msg.sender`
	/// @param _to The address of the recipient
	/// @param _amount The amount of tokens to be transferred
	/// @return Whether the transfer was successful or not
	function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) returns (bool success) {
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

           if (parentSnapShotBlock >= block.number) throw;

           // Do not allow transfer to 0x0 or the token contract itself
           if ((_to == 0) || (_to == address(this))) throw;

           // If the amount being transfered is more than the balance of the
           //  account the transfer returns false
           var previousBalanceFrom = balanceOfAt(_from, block.number);
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
           var previousBalanceTo = balanceOfAt(_to, block.number);
           if (previousBalanceTo + _amount < previousBalanceTo) throw; // Check for overflow
           updateValueAtNow(balances[_to], previousBalanceTo + _amount);

           // An event to make the transfer easy to find on the blockchain
           Transfer(_from, _to, _amount);

           return true;
    }

    /// @param _owner The address that&#39;s balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
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
        return totalSupplyAt(block.number);
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
        ) onlyController returns(address) {
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
    function generateTokens(address _owner, uint _amount) onlyController returns (bool) {
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
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
        uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
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
        || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
               Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
               newCheckPoint.fromBlock =  uint128(block.number);
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


	////////////////
	// Events
	////////////////
	event Transfer(address indexed _from, address indexed _to, uint256 _amount);
	event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
	event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

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

/// @title Clit Token (CLIT) - Crowd funding code for CLIT Coin project
/// 


contract ClitCoinToken is MiniMeToken {


	function ClitCoinToken(
		//address _tokenFactory
	) MiniMeToken(
		0x0,
		0x0,            // no parent token
		0,              // no snapshot block number from parent
		"CLIT Token", 	// Token name
		0,              // Decimals
		"CLIT",         // Symbol
		false            // Enable transfers
	) {
		version = "CLIT 1.0";
	}


}

/*
 * Math operations with safety checks
 */
contract SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
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
}


contract ClitCrowdFunder is Controlled, SafeMath {

	address public creator;
    address public fundRecipient;
	
	// State variables
    State public state = State.Fundraising; // initialize on create	
    uint public fundingGoal; 
	uint public totalRaised;
	uint public currentBalance;
	uint public issuedTokenBalance;
	uint public totalTokensIssued;
	uint public capTokenAmount;
	uint public startBlockNumber;
	uint public endBlockNumber;
	uint public eolBlockNumber;
	
	uint public firstExchangeRatePeriod;
	uint public secondExchangeRatePeriod;
	uint public thirdExchangeRatePeriod;
	uint public fourthExchangeRatePeriod;
	
	uint public firstTokenExchangeRate;
	uint public secondTokenExchangeRate;
	uint public thirdTokenExchangeRate;
	uint public fourthTokenExchangeRate;
	uint public finalTokenExchangeRate;	
	
	bool public fundingGoalReached;
	
    ClitCoinToken public exchangeToken;
	
	/* This generates a public event on the blockchain that will notify clients */
	event HardCapReached(address fundRecipient, uint amountRaised);
	event GoalReached(address fundRecipient, uint amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution);	
	event FrozenFunds(address target, bool frozen);
	event RefundPeriodStarted();

	/* data structure to hold information about campaign contributors */
	mapping(address => uint256) private balanceOf;
	mapping (address => bool) private frozenAccount;
	
	// Data structures
    enum State {
		Fundraising,
		ExpiredRefund,
		Successful,
		Closed
	}
	
	/*
     *  Modifiers
     */

	modifier inState(State _state) {
        if (state != _state) throw;
        _;
    }
	
	// Add one week to endBlockNumber
	modifier atEndOfLifecycle() {
        if(!((state == State.ExpiredRefund && block.number > eolBlockNumber) || state == State.Successful)) {
            throw;
        }
        _;
    }
	
	modifier accountNotFrozen() {
        if (frozenAccount[msg.sender] == true) throw;
        _;
    }
	
    modifier minInvestment() {
      // User has to send at least 0.01 Eth
      require(msg.value >= 10 ** 16);
      _;
    }
	
	modifier isStarted() {
		require(block.number >= startBlockNumber);
		_;
	}

	/*  at initialization, setup the owner */
	function ClitCrowdFunder(
		address _fundRecipient,
		uint _delayStartHours,
		ClitCoinToken _addressOfExchangeToken
	) {
		creator = msg.sender;
		
		fundRecipient = _fundRecipient;
		fundingGoal = 7000 * 1 ether;
		capTokenAmount = 140 * 10 ** 6;
		state = State.Fundraising;
		fundingGoalReached = false;
		
		totalRaised = 0;
		currentBalance = 0;
		totalTokensIssued = 0;
		issuedTokenBalance = 0;
		
		startBlockNumber = block.number + div(mul(3600, _delayStartHours), 14);
		endBlockNumber = startBlockNumber + div(mul(3600, 1080), 14); // 45 days 
		eolBlockNumber = endBlockNumber + div(mul(3600, 168), 14);  // one week - contract end of life

		firstExchangeRatePeriod = startBlockNumber + div(mul(3600, 24), 14);   // First 24 hour sale 
		secondExchangeRatePeriod = firstExchangeRatePeriod + div(mul(3600, 240), 14); // Next 10 days
		thirdExchangeRatePeriod = secondExchangeRatePeriod + div(mul(3600, 240), 14); // Next 10 days
		fourthExchangeRatePeriod = thirdExchangeRatePeriod + div(mul(3600, 240), 14); // Next 10 days
		
		uint _tokenExchangeRate = 1000;
		firstTokenExchangeRate = (_tokenExchangeRate + 1000);	
		secondTokenExchangeRate = (_tokenExchangeRate + 500);
		thirdTokenExchangeRate = (_tokenExchangeRate + 300);
		fourthTokenExchangeRate = (_tokenExchangeRate + 100);
		finalTokenExchangeRate = _tokenExchangeRate;
		
		exchangeToken = ClitCoinToken(_addressOfExchangeToken);
	}
	
	function freezeAccount(address target, bool freeze) onlyController {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }	
	
	function getCurrentExchangeRate(uint amount) public constant returns(uint) {
		if (block.number <= firstExchangeRatePeriod) {
			return firstTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= secondExchangeRatePeriod) {
			return secondTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= thirdExchangeRatePeriod) {
			return thirdTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= fourthExchangeRatePeriod) {
			return fourthTokenExchangeRate * amount / 1 ether;
		} else if (block.number <= endBlockNumber) {
			return finalTokenExchangeRate * amount / 1 ether;
		}
		
		return finalTokenExchangeRate * amount / 1 ether;
	}

	function investment() public inState(State.Fundraising) isStarted accountNotFrozen minInvestment payable returns(uint)  {
		
		uint amount = msg.value;
		if (amount == 0) throw;
		
		balanceOf[msg.sender] += amount;	
		
		totalRaised += amount;
		currentBalance += amount;
						
		uint tokenAmount = getCurrentExchangeRate(amount);
		exchangeToken.generateTokens(msg.sender, tokenAmount);
		totalTokensIssued += tokenAmount;
		issuedTokenBalance += tokenAmount;
		
		FundTransfer(msg.sender, amount, true); 
		
		checkIfFundingCompleteOrExpired();
		
		return balanceOf[msg.sender];
	}

	function checkIfFundingCompleteOrExpired() {
		if (block.number > endBlockNumber || totalTokensIssued >= capTokenAmount ) {
			// Hard limit reached
			if (currentBalance > fundingGoal || fundingGoalReached == true) {
				state = State.Successful;
				payOut();
				
				HardCapReached(fundRecipient, totalRaised);
				
				// Contract can be immediately closed out
				removeContract();

			} else  {
				state = State.ExpiredRefund; // backers can now collect refunds by calling getRefund()
				
				RefundPeriodStarted();
			}
		} else if (currentBalance > fundingGoal && fundingGoalReached == false) {
			// Once goal reached
			fundingGoalReached = true;
			
			state = State.Successful;
			payOut();
			
			// Continue allowing users to buy in
			state = State.Fundraising;
			
			// currentBalance is zero after pay out
			GoalReached(fundRecipient, totalRaised);
		}
	}

	function payOut() public inState(State.Successful) {
		// Ethereum balance
		var amount = currentBalance;
		currentBalance = 0;

		fundRecipient.transfer(amount);
		
		// Update the token reserve amount so that 50% of tokens remain in reserve
		var tokenCount = issuedTokenBalance;
		issuedTokenBalance = 0;
		
		exchangeToken.generateTokens(fundRecipient, tokenCount);		
	}

	function getRefund() public inState(State.ExpiredRefund) {	
		uint amountToRefund = balanceOf[msg.sender];
		balanceOf[msg.sender] = 0;
		
		// throws error if fails
		msg.sender.transfer(amountToRefund);
		currentBalance -= amountToRefund;
		
		FundTransfer(msg.sender, amountToRefund, false);
	}
	
	function removeContract() public atEndOfLifecycle {		
		state = State.Closed;
		
		// Allow clit owners to freely trade coins on the open market
		exchangeToken.enableTransfers(true);
		
		// Restore ownership to controller
		exchangeToken.changeController(controller);

		selfdestruct(msg.sender);
	}
	
	/* The function without name is the default function that is called whenever anyone sends funds to a contract */
	function () payable { 
		investment(); 
	}	

}