pragma solidity ^0.4.18;

/*
  Copyright 2017, Anton Egorov (Mothership Foundation)
  Copyright 2017, An Hoang Phan Ngo (Mothership Foundation)

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

// File: contracts/interface/Controlled.sol

contract Controlled {
  /// @notice The address of the controller is the only address that can call
  ///  a function with this modifier
  modifier onlyController {
    require(msg.sender == controller);
    _;
  }

  address public controller;

  function Controlled() public { controller = msg.sender; }

  /// @notice Changes the controller of the contract
  /// @param _newController The new controller of the contract
  function changeController(address _newController) public onlyController {
    controller = _newController;
  }
}

// File: contracts/interface/Burnable.sol

/// @dev Burnable introduces a burner role, which could be used to destroy
///  tokens. The burner address could be changed by himself.
contract Burnable is Controlled {
  address public burner;

  /// @notice The function with this modifier could be called by a controller
  /// as well as by a burner. But burner could use the onlt his/her address as
  /// a target.
  modifier onlyControllerOrBurner(address target) {
    assert(msg.sender == controller || (msg.sender == burner && msg.sender == target));
    _;
  }

  modifier onlyBurner {
    assert(msg.sender == burner);
    _;
  }

  /// Contract creator become a burner by default
  function Burnable() public { burner = msg.sender;}

  /// @notice Change a burner address
  /// @param _newBurner The new burner address
  function changeBurner(address _newBurner) public onlyBurner {
    burner = _newBurner;
  }
}

// File: contracts/interface/ERC20Token.sol

// @dev Abstract contract for the full ERC 20 Token standard
//  https://github.com/ethereum/EIPs/issues/20
contract ERC20Token {
  /// total amount of tokens
  function totalSupply() public view returns (uint256 balance);

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) public view returns (uint256 balance);

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success);

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) public returns (bool success);

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/interface/MiniMeTokenI.sol

/// @dev MiniMeToken interface. Using this interface instead of whole contracts
///  will reduce contract sise and gas cost
contract MiniMeTokenI is ERC20Token, Burnable {

  string public name;                //The Token&#39;s name: e.g. DigixDAO Tokens
  uint8 public decimals;             //Number of decimals of the smallest unit
  string public symbol;              //An identifier: e.g. REP
  string public version = "MMT_0.1"; //An arbitrary versioning scheme

///////////////////
// ERC20 Methods
///////////////////

  /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
  ///  its behalf, and then a function is triggered in the contract that is
  ///  being approved, `_spender`. This allows users to use their tokens to
  ///  interact with contracts in one function call instead of two
  /// @param _spender The address of the contract able to transfer the tokens
  /// @param _amount The amount of tokens to be approved for transfer
  /// @return True if the function call was successful
  function approveAndCall(
    address _spender,
    uint256 _amount,
    bytes _extraData) public returns (bool success);

////////////////
// Query balance and totalSupply in History
////////////////

  /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
  /// @param _owner The address from which the balance will be retrieved
  /// @param _blockNumber The block number when the balance is queried
  /// @return The balance at `_blockNumber`
  function balanceOfAt(
    address _owner,
    uint _blockNumber) public constant returns (uint);

  /// @notice Total amount of tokens at a specific `_blockNumber`.
  /// @param _blockNumber The block number when the totalSupply is queried
  /// @return The total amount of tokens at `_blockNumber`
  function totalSupplyAt(uint _blockNumber) public constant returns(uint);

////////////////
// Generate and destroy tokens
////////////////

  /// @notice Generates `_amount` tokens that are assigned to `_owner`
  /// @param _owner The address that will be assigned the new tokens
  /// @param _amount The quantity of tokens generated
  /// @return True if the tokens are generated correctly
  function mintTokens(address _owner, uint _amount) public returns (bool);


  /// @notice Burns `_amount` tokens from `_owner`
  /// @param _owner The address that will lose the tokens
  /// @param _amount The quantity of tokens to burn
  /// @return True if the tokens are burned correctly
  function destroyTokens(address _owner, uint _amount) public returns (bool);

/////////////////
// Finalize 
////////////////
  function finalize() public;

//////////
// Safety Methods
//////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public;

////////////////
// Events
////////////////

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}

// File: contracts/interface/TokenController.sol

/// @dev The token controller contract must implement these functions
contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
  function proxyMintTokens(
    address _owner, 
    uint _amount,
    bytes32 _paidTxID) public returns(bool);

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

// File: contracts/Distribution.sol

contract Distribution is Controlled, TokenController {

  /// Record tx details for each minting operation
  struct Transaction {
    uint256 amount;
    bytes32 paidTxID;
  }

  MiniMeTokenI public token;

  address public reserveWallet; // Team&#39;s wallet address

  uint256 public totalSupplyCap; // Total Token supply to be generated
  uint256 public totalReserve; // A number of tokens to reserve for the team/bonuses

  uint256 public finalizedBlock;

  /// Record all transaction details for all minting operations
  mapping (address => Transaction[]) allTransactions;

  /// @param _token Address of the SEN token contract
  ///  the contribution finalizes.
  /// @param _reserveWallet Team&#39;s wallet address to distribute reserved pool
  /// @param _totalSupplyCap Maximum amount of tokens to generate during the contribution
  /// @param _totalReserve A number of tokens to reserve for the team/bonuses
  function Distribution(
    address _token,
    address _reserveWallet,
    uint256 _totalSupplyCap,
    uint256 _totalReserve
  ) public onlyController
  {
    // Initialize only once
    assert(address(token) == 0x0);

    token = MiniMeTokenI(_token);
    reserveWallet = _reserveWallet;

    require(_totalReserve < _totalSupplyCap);
    totalSupplyCap = _totalSupplyCap;
    totalReserve = _totalReserve;

    assert(token.totalSupply() == 0);
    assert(token.decimals() == 18); // Same amount of decimals as ETH
  }

  function distributionCap() public constant returns (uint256) {
    return totalSupplyCap - totalReserve;
  }

  /// @notice This method can be called the distribution cap is reached only
  function finalize() public onlyController {
    assert(token.totalSupply() >= distributionCap());

    // Mint reserve pool
    doMint(reserveWallet, totalReserve);

    finalizedBlock = getBlockNumber();
    token.finalize(); // Token becomes unmintable after this

    // Distribution controller becomes a Token controller
    token.changeController(controller);

    Finalized();
  }

//////////
// TokenController functions
//////////

  function proxyMintTokens(
    address _th,
    uint256 _amount,
    bytes32 _paidTxID
  ) public onlyController returns (bool)
  {
    require(_th != 0x0);

    require(_amount + token.totalSupply() <= distributionCap());

    doMint(_th, _amount);
    addTransaction(
      allTransactions[_th],
      _amount,
      _paidTxID);

    Purchase(
      _th,
      _amount,
      _paidTxID);

    return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
    return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
    return false;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyController {
    if (token.controller() == address(this)) {
      token.claimTokens(_token);
    }
    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20Token otherToken = ERC20Token(_token);
    uint256 balance = otherToken.balanceOf(this);
    otherToken.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  //////////////////////////////////
  // Minting tokens and oraclization
  //////////////////////////////////

  /// Total transaction count belong to an address
  function totalTransactionCount(address _owner) public constant returns(uint) {
    return allTransactions[_owner].length;
  }

  /// Query a transaction details by address and its index in transactions array
  function getTransactionAtIndex(address _owner, uint index) public constant returns(
    uint256 _amount,
    bytes32 _paidTxID
  ) {
    _amount = allTransactions[_owner][index].amount;
    _paidTxID = allTransactions[_owner][index].paidTxID;
  }

  /// Save transaction details belong to an address
  /// @param  transactions all transactions belong to an address
  /// @param _amount amount of tokens issued in the transaction
  /// @param _paidTxID blockchain tx_hash
  function addTransaction(
    Transaction[] storage transactions,
    uint _amount,
    bytes32 _paidTxID
    ) internal
  {
    Transaction storage newTx = transactions[transactions.length++];
    newTx.amount = _amount;
    newTx.paidTxID = _paidTxID;
  }

  function doMint(address _th, uint256 _amount) internal {
    assert(token.mintTokens(_th, _amount));
  }

//////////
// Testing specific methods
//////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) { return block.number; }


////////////////
// Events
////////////////
  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event Purchase(
    address indexed _owner,
    uint256 _amount,
    bytes32 _paidTxID
  );
  event Finalized();
}