// Smart contract used for the EatMeCoin Crowdsale 
//
// @author: Pavel Metelitsyn, Geejay101
// April 2018

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

  function percent(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c / 100;
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */

 /* from OpenZeppelin library */
 /* https://github.com/OpenZeppelin/zeppelin-solidity */

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



contract EatMeCoin is MiniMeToken { 

  // we use this variable to store the number of the finalization block
  uint256 public checkpointBlock;

  // address which is allowed to trigger tokens generation
  address public mayGenerateAddr;

  // flag
  bool tokenGenerationEnabled = true; //<- added after first audit


  modifier mayGenerate() {
    require ( (msg.sender == mayGenerateAddr) &&
              (tokenGenerationEnabled == true) ); //<- added after first audit
    _;
  }

  // Constructor
  function EatMeCoin(address _tokenFactory) 
    MiniMeToken(
      _tokenFactory,
      0x0,
      0,
      "EatMeCoin",
      18, // decimals
      "EAT",
      // SHOULD TRANSFERS BE ENABLED? -- NO
      false){
    
    controller = msg.sender;
    mayGenerateAddr = controller;
  }

  function setGenerateAddr(address _addr) onlyController{
    // we can appoint an address to be allowed to generate tokens
    require( _addr != 0x0 );
    mayGenerateAddr = _addr;
  }


  /// @notice this is default function called when ETH is send to this contract
  ///   we use the campaign contract for selling tokens
  function () payable {
    revert();
  }

  
  /// @notice This function is copy-paste of the generateTokens of the original MiniMi contract
  ///   except it uses mayGenerate modifier (original uses onlyController)
  function generate_token_for(address _addrTo, uint256 _amount) mayGenerate returns (bool) {
    
    //balances[_addr] += _amount;
   
    uint256 curTotalSupply = totalSupply();
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow    
    uint256 previousBalanceTo = balanceOf(_addrTo);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
    updateValueAtNow(balances[_addrTo], previousBalanceTo + _amount);
    Transfer(0, _addrTo, _amount);
    return true;
  }

  // overwrites the original function
  function generateTokens(address _owner, uint256 _amount
    ) onlyController returns (bool) {
    revert();
    generate_token_for(_owner, _amount);    
  }


  // permanently disables generation of new tokens
  function finalize() mayGenerate {
    tokenGenerationEnabled = false;
    transfersEnabled = true;
    checkpointBlock = block.number;
  }  
}


contract eat_token_interface{
  uint8 public decimals;
  function generate_token_for(address _addr,uint256 _amount) returns (bool);
  function finalize();
}

// Controlled is implemented in MiniMeToken.sol
contract TokenCampaign is Controlled {
  using SafeMath for uint256;

  // this is our token
  eat_token_interface public token;

  uint8 public constant decimals = 18;

  uint256 public constant scale = (uint256(10) ** decimals);

  uint256 public constant hardcap = 100000000 * scale;

  ///////////////////////////////////
  //
  // constants related to token sale

  // after sale ends, additional tokens will be generated
  // according to the following rules,
  // where 100% correspond to the number of sold tokens

  // percent of reward tokens to be generated
  uint256 public constant PRCT100_D_TEAM = 63; // % * 100 , 0.63%
  uint256 public constant PRCT100_R_TEAM = 250; // % * 100 , 2.5%
  uint256 public constant PRCT100_R2 = 150;  // % * 100 , 1.5%

  // fixed reward
  uint256 public constant FIXEDREWARD_MM = 100000 * scale; // fixed

  // we keep some of the ETH in the contract until the sale is finalized
  // percent of ETH going to operational and reserve account
  uint256 public constant PRCT100_ETH_OP = 4000; // % * 100 , 2x 40%

  // preCrowd structure, Wei
  uint256 public constant preCrowdMinContribution = (20 ether);

  // minmal contribution, Wei
  uint256 public constant minContribution = (1 ether) / 100;

  // how many tokens for one ETH
  uint256 public constant preCrowd_tokens_scaled = 7142857142857140000000; // 30% discount
  uint256 public constant stage_1_tokens_scaled =  6250000000000000000000; // 20% discount
  uint256 public constant stage_2_tokens_scaled =  5555555555555560000000; // 10% discount
  uint256 public constant stage_3_tokens_scaled =  5000000000000000000000; //<-- scaled

  // Tokens allocated for each stage
  uint256 public constant PreCrowdAllocation =  20000000 * scale ; // Tokens
  uint256 public constant Stage1Allocation =    15000000 * scale ; // Tokens
  uint256 public constant Stage2Allocation =    15000000 * scale ; // Tokens
  uint256 public constant Stage3Allocation =    20000000 * scale ; // Tokens

  // keeps track of tokens allocated, scaled value
  uint256 public tokensRemainingPreCrowd = PreCrowdAllocation;
  uint256 public tokensRemainingStage1 = Stage1Allocation;
  uint256 public tokensRemainingStage2 = Stage2Allocation;
  uint256 public tokensRemainingStage3 = Stage3Allocation;

  // If necessary we can cap the maximum amount 
  // of individual contributions in case contributions have exceeded the hardcap
  // this avoids to cap the contributions already when funds flow in
  uint256 public maxPreCrowdAllocationPerInvestor =  20000000 * scale ; // Tokens
  uint256 public maxStage1AllocationPerInvestor =    15000000 * scale ; // Tokens
  uint256 public maxStage2AllocationPerInvestor =    15000000 * scale ; // Tokens
  uint256 public maxStage3AllocationPerInvestor =    20000000 * scale ; // Tokens

  // keeps track of tokens generated so far, scaled value
  uint256 public tokensGenerated = 0;

  address[] public joinedCrowdsale;

  // total Ether raised (= Ether paid into the contract)
  uint256 public amountRaised = 0; 

  // How much wei we have given back to investors.
  uint256 public amountRefunded = 0;


  ////////////////////////////////////////////////////////
  //
  // folowing addresses need to be set in the constructor
  // we also have setter functions which allow to change
  // an address if it is compromised or something happens

  // destination for D-team&#39;s share
  address public dteamVaultAddr1;
  address public dteamVaultAddr2;
  address public dteamVaultAddr3;
  address public dteamVaultAddr4;

  // destination for R-team&#39;s share
  address public rteamVaultAddr;

  // advisor address
  address public r2VaultAddr;

  // adivisor address
  address public mmVaultAddr;
  
  // destination for reserve tokens
  address public reserveVaultAddr;

  // destination for collected Ether
  address public trusteeVaultAddr;
  
  // destination for operational costs account
  address public opVaultAddr;

  // adress of our token
  address public tokenAddr;
  
  // @check ensure that state transitions are 
  // only in one direction
  // 3 - passive, not accepting funds
  // 2 - active main sale, accepting funds
  // 1 - closed, not accepting funds 
  // 0 - finalized, not accepting funds
  uint8 public campaignState = 3; 
  bool public paused = false;

  // time in seconds since epoch 
  // set to midnight of saturday January 1st, 4000
  uint256 public tCampaignStart = 64060588800;

  uint256 public t_1st_StageEnd = 5 * (1 days); // Stage1 3 days open
  // for testing
  // uint256 public t_1st_StageEnd = 3 * (1 hours); // Stage1 3 days open

  uint256 public t_2nd_StageEnd = 2 * (1 days); // Stage2 2 days open
  // for testing
  // uint256 public t_2nd_StageEnd = 2 * (1 hours); // Stage2 2 days open

  uint256 public tCampaignEnd = 35 * (1 days); // Stage3 35 days open
  // for testing
  // uint256 public tCampaignEnd = 35 * (1 hours); // Stage3 35 days open

  uint256 public tFinalized = 64060588800;

  // participant data
  struct ParticipantListData {

    bool participatedFlag;

    uint256 contributedAmountPreAllocated;
    uint256 contributedAmountPreCrowd;
    uint256 contributedAmountStage1;
    uint256 contributedAmountStage2;
    uint256 contributedAmountStage3;

    uint256 preallocatedTokens;
    uint256 allocatedTokens;

    uint256 spentAmount;
  }

  /** participant addresses */
  mapping (address => ParticipantListData) public participantList;

  uint256 public investorsProcessed = 0;
  uint256 public investorsBatchSize = 100;

  bool public isWhiteListed = true;

  struct WhiteListData {
    bool status;
    uint256 maxCap;
  }

  /** Whitelisted addresses */
  mapping (address => WhiteListData) public participantWhitelist;


  //////////////////////////////////////////////
  //
  // Events
 
  event CampaignOpen(uint256 timenow);
  event CampaignClosed(uint256 timenow);
  event CampaignPaused(uint256 timenow);
  event CampaignResumed(uint256 timenow);

  event PreAllocated(address indexed backer, uint256 raised);
  event RaisedPreCrowd(address indexed backer, uint256 raised);
  event RaisedStage1(address indexed backer, uint256 raised);
  event RaisedStage2(address indexed backer, uint256 raised);
  event RaisedStage3(address indexed backer, uint256 raised);
  event Airdropped(address indexed backer, uint256 tokensairdropped);

  event Finalized(uint256 timenow);

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);

  // Address early participation whitelist status changed
  event Whitelisted(address addr, bool status);

  // Refund was processed for a contributor
  event Refund(address investor, uint256 weiAmount);

  /// @notice Constructor
  /// @param _tokenAddress Our token&#39;s address
  /// @param  _trusteeAddress Trustee address
  /// @param  _opAddress Operational expenses address 
  /// @param  _reserveAddress Project Token Reserve
  function TokenCampaign(
    address _tokenAddress,
    address _dteamAddress1,
    address _dteamAddress2,
    address _dteamAddress3,
    address _dteamAddress4,
    address _rteamAddress,
    address _r2Address,
    address _mmAddress,
    address _trusteeAddress,
    address _opAddress,
    address _reserveAddress)
  {

    controller = msg.sender;
    
    /// set addresses     
    tokenAddr = _tokenAddress;
    dteamVaultAddr1 = _dteamAddress1;
    dteamVaultAddr2 = _dteamAddress2;
    dteamVaultAddr3 = _dteamAddress3;
    dteamVaultAddr4 = _dteamAddress4;
    rteamVaultAddr = _rteamAddress;
    r2VaultAddr = _r2Address;
    mmVaultAddr = _mmAddress;
    trusteeVaultAddr = _trusteeAddress; 
    opVaultAddr = _opAddress;
    reserveVaultAddr = _reserveAddress;

    /// reference our token
    token = eat_token_interface(tokenAddr);
   
  }


  /////////////////////////////////////////////
  ///
  /// Functions that change contract state

  ///
  /// Setters
  ///

  /// @notice  Puts campaign into active state  
  ///  only controller can do that
  ///  only possible if team token Vault is set up
  ///  WARNING: usual caveats apply to the Ethereum&#39;s interpretation of time
  function startSale() public onlyController {
    require( campaignState > 2 );

    campaignState = 2;

    uint256 tNow = now;
    // assume timestamps will not cause overflow
    tCampaignStart = tNow;
    t_1st_StageEnd += tNow;
    t_2nd_StageEnd += tNow;
    tCampaignEnd += tNow;

    CampaignOpen(now);
  }


  /// @notice Pause sale
  ///   just in case we have some troubles 
  ///   Note that time marks are not updated
  function pauseSale() public onlyController {
    require( campaignState  == 2 );
    paused = true;
    CampaignPaused(now);
  }


  /// @notice Resume sale
  function resumeSale() public onlyController {
    require( campaignState  == 2 );
    paused = false;
    CampaignResumed(now);
  }



  /// @notice Puts the camapign into closed state
  ///   only controller can do so
  ///   only possible from the active state
  ///   we can call this function if we want to stop sale before end time 
  ///   and be able to perform &#39;finalizeCampaign()&#39; immediately
  function closeSale() public onlyController {
    require( campaignState  == 2 );
    campaignState = 1;

    CampaignClosed(now);
  }   


  function setParticipantWhitelist(address addr, bool status, uint256 maxCap) public onlyController {
    participantWhitelist[addr] = WhiteListData({status:status, maxCap:maxCap});
    Whitelisted(addr, status);
  }

  function setMultipleParticipantWhitelist(address[] addrs, bool[] statuses, uint[] maxCaps) public onlyController {
    for (uint256 iterator = 0; iterator < addrs.length; iterator++) {
      setParticipantWhitelist(addrs[iterator], statuses[iterator], maxCaps[iterator]);
    }
  }

  function investorCount() public constant returns (uint256) {
    return joinedCrowdsale.length;
  }

  function contractBalance() public constant returns (uint256) {
    return this.balance;
  }

  /**
   * Investors can claim refund after finalisation.
   *
   * Note that any refunds from proxy buyers should be handled separately,
   * and not through this contract.
   */
  function refund() public {
    require (campaignState == 0);

    uint256 weiValue = participantList[msg.sender].contributedAmountPreCrowd;
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage1);
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage2);
    weiValue = weiValue.add(participantList[msg.sender].contributedAmountStage3);
    weiValue = weiValue.sub(participantList[msg.sender].spentAmount);

    if (weiValue <= 0) revert();

    participantList[msg.sender].contributedAmountPreCrowd = 0;
    participantList[msg.sender].contributedAmountStage1 = 0;
    participantList[msg.sender].contributedAmountStage2 = 0;
    participantList[msg.sender].contributedAmountStage3 = 0;

    amountRefunded = amountRefunded.add(weiValue);

    // send it
    if (!msg.sender.send(weiValue)) revert();

    // announce to world
    Refund(msg.sender, weiValue);

  }

  /// @notice Finalizes the campaign
  ///   Get funds out, generates team, reserve and reserve tokens
  function allocateInvestors() public onlyController {     
      
    /// only if sale was closed or 48 hours = 2880 minutes have passed since campaign end
    /// we leave this time to complete possibly pending orders from offchain contributions 

    require ( (campaignState == 1) || ((campaignState != 0) && (now > tCampaignEnd + (2880 minutes))));

    uint256 nTokens = 0;
    uint256 rate = 0;
    uint256 contributedAmount = 0; 

    uint256 investorsProcessedEnd = investorsProcessed + investorsBatchSize;

    if (investorsProcessedEnd > joinedCrowdsale.length) {
      investorsProcessedEnd = joinedCrowdsale.length;
    }

    for (uint256 i = investorsProcessed; i < investorsProcessedEnd; i++) {

        investorsProcessed++;

        address investorAddress = joinedCrowdsale[i];

        // PreCrowd stage
        contributedAmount = participantList[investorAddress].contributedAmountPreCrowd;

        if (isWhiteListed) {

            // is contributeAmount within whitelisted amount
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

            // calculate remaining whitelisted amount
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

            // calculate the number of tokens
            rate = preCrowd_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

            // check whether individual allocations are capped
            if (nTokens > maxPreCrowdAllocationPerInvestor) {
              nTokens = maxPreCrowdAllocationPerInvestor;
            }

            // If tokens are bigger than whats left in the stage, give the rest 
            if (tokensRemainingPreCrowd.sub(nTokens) < 0) {
                nTokens = tokensRemainingPreCrowd;
            }

            // update spent amount
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

            // calculate leftover tokens for the stage 
            tokensRemainingPreCrowd = tokensRemainingPreCrowd.sub(nTokens);

            // update the new token holding
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

        //  stage1
        contributedAmount = participantList[investorAddress].contributedAmountStage1;

        if (isWhiteListed) {

            // is contributeAmount within whitelisted amount
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

            // calculate remaining whitelisted amount
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

            // calculate the number of tokens
            rate = stage_1_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

            // check whether individual allocations are capped
            if (nTokens > maxStage1AllocationPerInvestor) {
              nTokens = maxStage1AllocationPerInvestor;
            }

            // If tokens are bigger than whats left in the stage, give the rest 
            if (tokensRemainingStage1.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage1;
            }

            // update spent amount
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

            // calculate leftover tokens for the stage 
            tokensRemainingStage1 = tokensRemainingStage1.sub(nTokens);

            // update the new token holding
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

        //  stage2
        contributedAmount = participantList[investorAddress].contributedAmountStage2;

        if (isWhiteListed) {

            // is contributeAmount within whitelisted amount
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

            // calculate remaining whitelisted amount
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

            // calculate the number of tokens
            rate = stage_2_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

            // check whether individual allocations are capped
            if (nTokens > maxStage2AllocationPerInvestor) {
              nTokens = maxStage2AllocationPerInvestor;
            }

            // If tokens are bigger than whats left in the stage, give the rest 
            if (tokensRemainingStage2.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage2;
            }

            // update spent amount
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

            // calculate leftover tokens for the stage 
            tokensRemainingStage2 = tokensRemainingStage2.sub(nTokens);

            // update the new token holding
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

        //  stage3
        contributedAmount = participantList[investorAddress].contributedAmountStage3;

        if (isWhiteListed) {

            // is contributeAmount within whitelisted amount
            if (contributedAmount > participantWhitelist[investorAddress].maxCap) {
                contributedAmount = participantWhitelist[investorAddress].maxCap;
            }

            // calculate remaining whitelisted amount
            if (contributedAmount>0) {
                participantWhitelist[investorAddress].maxCap = participantWhitelist[investorAddress].maxCap.sub(contributedAmount);
            }

        }

        if (contributedAmount>0) {

            // calculate the number of tokens
            rate = stage_3_tokens_scaled;
            nTokens = (rate.mul(contributedAmount)).div(1 ether);

            // check whether individual allocations are capped
            if (nTokens > maxStage3AllocationPerInvestor) {
              nTokens = maxStage3AllocationPerInvestor;
            }

            // If tokens are bigger than whats left in the stage, give the rest 
            if (tokensRemainingStage3.sub(nTokens) < 0) {
                nTokens = tokensRemainingStage3;
            }

            // update spent amount
            participantList[joinedCrowdsale[i]].spentAmount = participantList[joinedCrowdsale[i]].spentAmount.add(nTokens.div(rate).mul(1 ether));

            // calculate leftover tokens for the stage 
            tokensRemainingStage3 = tokensRemainingStage3.sub(nTokens);

            // update the new token holding
            participantList[investorAddress].allocatedTokens = participantList[investorAddress].allocatedTokens.add(nTokens);

        }

        do_grant_tokens(investorAddress, participantList[investorAddress].allocatedTokens);

    }

  }

  /// @notice Finalizes the campaign
  ///   Get funds out, generates team, reserve and reserve tokens
  function finalizeCampaign() public onlyController {     
      
    /// only if sale was closed or 48 hours = 2880 minutes have passed since campaign end
    /// we leave this time to complete possibly pending orders from offchain contributions 

    require ( (campaignState == 1) || ((campaignState != 0) && (now > tCampaignEnd + (2880 minutes))));

    campaignState = 0;

    // dteam tokens
    uint256 drewardTokens = (tokensGenerated.mul(PRCT100_D_TEAM)).div(10000);

    // rteam tokens
    uint256 rrewardTokens = (tokensGenerated.mul(PRCT100_R_TEAM)).div(10000);

    // r2 tokens
    uint256 r2rewardTokens = (tokensGenerated.mul(PRCT100_R2)).div(10000);

    // mm tokens
    uint256 mmrewardTokens = FIXEDREWARD_MM;

    do_grant_tokens(dteamVaultAddr1, drewardTokens);
    do_grant_tokens(dteamVaultAddr2, drewardTokens);
    do_grant_tokens(dteamVaultAddr3, drewardTokens);
    do_grant_tokens(dteamVaultAddr4, drewardTokens);     
    do_grant_tokens(rteamVaultAddr, rrewardTokens);
    do_grant_tokens(r2VaultAddr, r2rewardTokens);
    do_grant_tokens(mmVaultAddr, mmrewardTokens);

    // generate reserve tokens 
    // uint256 reserveTokens = rest of tokens under hardcap
    uint256 reserveTokens = hardcap.sub(tokensGenerated);
    do_grant_tokens(reserveVaultAddr, reserveTokens);

    // prevent further token generation
    token.finalize();

    tFinalized = now;
    
    // notify the world
    Finalized(tFinalized);
  }


  ///   Get funds out
  function retrieveFunds() public onlyController {     

      require (campaignState == 0);
      
      // forward funds to the trustee 
      // since we forward a fraction of the incomming ether on every contribution
      // &#39;amountRaised&#39; IS NOT equal to the contract&#39;s balance
      // we use &#39;this.balance&#39; instead

      // we do this manually to give people the chance to claim refunds in case of overpayments

      trusteeVaultAddr.transfer(this.balance);

  }

     ///   Get funds out
  function emergencyFinalize() public onlyController {     

    campaignState = 0;

    // prevent further token generation
    token.finalize();

  }


  /// @notice triggers token generaton for the recipient
  ///  can be called only from the token sale contract itself
  ///  side effect: increases the generated tokens counter 
  ///  CAUTION: we do not check campaign state and parameters assuming that&#39;s callee&#39;s task
  function do_grant_tokens(address _to, uint256 _nTokens) internal returns (bool){
    
    require( token.generate_token_for(_to, _nTokens) );
    
    tokensGenerated = tokensGenerated.add(_nTokens);
    
    return true;
  }


  ///  @notice processes the contribution
  ///   checks campaign state, time window and minimal contribution
  ///   throws if one of the conditions fails
  function process_contribution(address _toAddr) internal {

    require ((campaignState == 2)   // active main sale
         && (now <= tCampaignEnd)   // within time window
         && (paused == false));     // not on hold
    
    // we check that Eth sent is sufficient 
    // though our token has decimals we don&#39;t want nanocontributions
    require ( msg.value >= minContribution );

    amountRaised = amountRaised.add(msg.value);

    // check whether we know this investor, if not add him to list
    if (!participantList[_toAddr].participatedFlag) {

       // A new investor
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);
    }

    if ( msg.value >= preCrowdMinContribution ) {

      participantList[_toAddr].contributedAmountPreCrowd = participantList[_toAddr].contributedAmountPreCrowd.add(msg.value);
      
      // notify the world
      RaisedPreCrowd(_toAddr, msg.value);

    } else {

      if (now <= t_1st_StageEnd) {

        participantList[_toAddr].contributedAmountStage1 = participantList[_toAddr].contributedAmountStage1.add(msg.value);

        // notify the world
        RaisedStage1(_toAddr, msg.value);

      } else if (now <= t_2nd_StageEnd) {

        participantList[_toAddr].contributedAmountStage2 = participantList[_toAddr].contributedAmountStage2.add(msg.value);

        // notify the world
        RaisedStage2(_toAddr, msg.value);

      } else {

        participantList[_toAddr].contributedAmountStage3 = participantList[_toAddr].contributedAmountStage3.add(msg.value);
        
        // notify the world
        RaisedStage3(_toAddr, msg.value);

      }

    }

    // compute the fraction of ETH going to op account
    uint256 opEth = (PRCT100_ETH_OP.mul(msg.value)).div(10000);

    // transfer to op account 
    opVaultAddr.transfer(opEth);

    // transfer to reserve account 
    reserveVaultAddr.transfer(opEth);

  }

  /**
  * Preallocated tokens have been sold or given in airdrop before the actual crowdsale opens. 
  * This function mints the tokens and moves the crowdsale needle.
  *
  */
  function preallocate(address _toAddr, uint fullTokens, uint weiPaid) public onlyController {

    require (campaignState != 0);

    uint tokenAmount = fullTokens * scale;
    uint weiAmount = weiPaid ; // This can be also 0, we give out tokens for free

    if (!participantList[_toAddr].participatedFlag) {

       // A new investor
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);

    }

    participantList[_toAddr].contributedAmountPreAllocated = participantList[_toAddr].contributedAmountPreAllocated.add(weiAmount);
    participantList[_toAddr].preallocatedTokens = participantList[_toAddr].preallocatedTokens.add(tokenAmount);

    amountRaised = amountRaised.add(weiAmount);

    // side effect: do_grant_tokens updates the "tokensGenerated" variable
    require( do_grant_tokens(_toAddr, tokenAmount) );

    // notify the world
    PreAllocated(_toAddr, weiAmount);

  }

  function airdrop(address _toAddr, uint fullTokens) public onlyController {

    require (campaignState != 0);

    uint tokenAmount = fullTokens * scale;

    if (!participantList[_toAddr].participatedFlag) {

       // A new investor
       participantList[_toAddr].participatedFlag = true;
       joinedCrowdsale.push(_toAddr);

    }

    participantList[_toAddr].preallocatedTokens = participantList[_toAddr].allocatedTokens.add(tokenAmount);

    // side effect: do_grant_tokens updates the "tokensGenerated" variable
    require( do_grant_tokens(_toAddr, tokenAmount) );

    // notify the world
    Airdropped(_toAddr, fullTokens);

  }

  function multiAirdrop(address[] addrs, uint[] fullTokens) public onlyController {

    require (campaignState != 0);

    for (uint256 iterator = 0; iterator < addrs.length; iterator++) {
      airdrop(addrs[iterator], fullTokens[iterator]);
    }
  }

  // set individual preCrowd cap
  function setInvestorsBatchSize(uint256 _batchsize) public onlyController {
      investorsBatchSize = _batchsize;
  }

  // set individual preCrowd cap
  function setMaxPreCrowdAllocationPerInvestor(uint256 _cap) public onlyController {
      maxPreCrowdAllocationPerInvestor = _cap;
  }

  // set individual stage1Crowd cap
  function setMaxStage1AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage1AllocationPerInvestor = _cap;
  }

  // set individual stage2Crowd cap
  function setMaxStage2AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage2AllocationPerInvestor = _cap;
  }

  // set individual stage3Crowd cap
  function setMaxStage3AllocationPerInvestor(uint256 _cap) public onlyController {
      maxStage3AllocationPerInvestor = _cap;
  }

  function setdteamVaultAddr1(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr1 = _newAddr;
  }

  function setdteamVaultAddr2(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr2 = _newAddr;
  }

  function setdteamVaultAddr3(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr3 = _newAddr;
  }

  function setdteamVaultAddr4(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    dteamVaultAddr4 = _newAddr;
  }

  function setrteamVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    rteamVaultAddr = _newAddr;
  }

  function setr2VaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    r2VaultAddr = _newAddr;
  }

  function setmmVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    mmVaultAddr = _newAddr;
  }

  function settrusteeVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    trusteeVaultAddr = _newAddr;
  }

  function setopVaultAddr(address _newAddr) public onlyController {
    require( _newAddr != 0x0 );
    opVaultAddr = _newAddr;
  }

  function toggleWhitelist(bool _isWhitelisted) public onlyController {
    isWhiteListed = _isWhitelisted;
  }

  /// @notice This function handles receiving Ether in favor of a third party address
  ///   we can use this function for buying tokens on behalf
  /// @param _toAddr the address which will receive tokens
  function proxy_contribution(address _toAddr) public payable {
    require ( _toAddr != 0x0 );

    process_contribution(_toAddr);
  }


  /// @notice This function handles receiving Ether
  function () payable {
      process_contribution(msg.sender); 
  }

  /// This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  function claimTokens(address _tokenAddr) public onlyController {

      ERC20Basic some_token = ERC20Basic(_tokenAddr);
      uint256 balance = some_token.balanceOf(this);
      some_token.transfer(controller, balance);
      ClaimedTokens(_tokenAddr, controller, balance);
  }
}