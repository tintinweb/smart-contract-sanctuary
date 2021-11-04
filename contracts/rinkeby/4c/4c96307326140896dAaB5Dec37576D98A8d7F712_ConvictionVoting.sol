/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/common/ReentrancyGuard.sol";

/**
* @dev When creating a subcontract, we recommend overriding the _internal_ functions that you want to hook.
*/
contract TokenManagerHook is ReentrancyGuard {

    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 public constant TOKEN_MANAGER_POSITION = keccak256("hookedTokenManager.tokenManagerHook.tokenManager");
    */
    bytes32 private constant TOKEN_MANAGER_POSITION = 0x5c513b2347f66d33af9d68f4a0ed7fbb73ce364889b2af7f3ee5764440da6a8a;

    modifier onlyTokenManager() {
        require (getTokenManager() == msg.sender, "Hooks must be called from Token Manager");
        _;
    }

    function getTokenManager() public returns (address) {
        return TOKEN_MANAGER_POSITION.getStorageAddress();
    }

    /*
    * @dev Called when this contract has been included as a Token Manager hook
    * @param _hookId The position in which the hook is going to be called
    * @param _token The token controlled by the Token Manager
    */
    function onRegisterAsHook(uint256 _hookId, address _token) external nonReentrant {
        require(getTokenManager() == address(0), "Hook already registered by Token Manager");
        TOKEN_MANAGER_POSITION.setStorageAddress(msg.sender);
        _onRegisterAsHook(msg.sender, _hookId, _token);
    }

    /*
    * @dev Called when this hook is being removed from the Token Manager
    * @param _hookId The position in which the hook is going to be called
    * @param _token The token controlled by the Token Manager
    */
    function onRevokeAsHook(uint256 _hookId, address _token) external onlyTokenManager nonReentrant {
        _onRevokeAsHook(msg.sender, _hookId, _token);
    }

    /*
    * @dev Notifies the hook about a token transfer allowing the hook to react if desired. It should return
    * true if left unimplemented, otherwise it will prevent some functions in the TokenManager from
    * executing successfully.
    * @param _from The origin of the transfer
    * @param _to The destination of the transfer
    * @param _amount The amount of the transfer
    */
    function onTransfer(address _from, address _to, uint256 _amount) external onlyTokenManager nonReentrant returns (bool) {
        return _onTransfer(_from, _to, _amount);
    }

    /*
    * @dev Notifies the hook about an approval allowing the hook to react if desired. It should return
    * true if left unimplemented, otherwise it will prevent some functions in the TokenManager from
    * executing successfully.
    * @param _holder The account that is allowing to spend
    * @param _spender The account that is allowed to spend
    * @param _amount The amount being allowed
    */
    function onApprove(address _holder, address _spender, uint _amount) external onlyTokenManager nonReentrant returns (bool) {
        return _onApprove(_holder, _spender, _amount);
    }

    // Function to override if necessary:

    function _onRegisterAsHook(address _tokenManager, uint256 _hookId, address _token) internal {
        return;
    }

    function _onRevokeAsHook(address _tokenManager, uint256 _hookId, address _token) internal {
        return;
    }

    function _onTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        return true;
    }

    function _onApprove(address _holder, address _spender, uint _amount) internal returns (bool) {
        return true;
    }
}

pragma solidity ^0.4.24;

contract FundsManager {

    address public owner;
    mapping(address => bool) public fundsUsers;

    modifier onlyOwner {
        require(msg.sender == owner, "ERR:NOT_OWNER");
        _;
    }

    modifier onlyFundsUser {
        require(fundsUsers[msg.sender] == true, "ERR:NOT_FUNDS_USER");
        _;
    }

    constructor (address _owner) public {
        owner = _owner;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function addFundsUser(address _fundsUser) public onlyOwner {
        fundsUsers[_fundsUser] = true;
    }

    function revokeFundsUser(address _fundsUser) public onlyOwner {
        require(fundsUsers[_fundsUser] == true, "ERR:SHOULD_BE_FUNDS_USER");
        fundsUsers[_fundsUser] = false;
    }

    function fundsOwner() public view returns (address);

    function balance(address _token) public view returns (uint256);

    // This must revert if the transfer fails or returns false
    function transfer(address _token, address _beneficiary, uint256 _amount) public;
}

pragma solidity ^0.4.24;

/// @dev The token controller contract must implement these functions


interface ITokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) external payable returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) external returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) external returns(bool);
}

pragma solidity ^0.4.24;

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
/// @dev This token contract's goal is to make it easy for anyone to clone this
///  token using the token distribution at a given block, this will allow DAO's
///  and DApps to upgrade their features in a decentralized manner without
///  affecting the original token
/// @dev It is ERC20 compliant, but still needs to under go further testing.

import "./ITokenController.sol";

contract Controlled {
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
        require(msg.sender == controller);
        _;
    }

    address public controller;

    function Controlled()  public { controller = msg.sender;}

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) onlyController  public {
        controller = _newController;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes _data
    ) public;
}

/// @dev The actual token contract, the default controller is the msg.sender
///  that deploys the contract, so usually this token will be deployed by a
///  token controller contract, which Giveth will call a "Campaign"
contract MiniMeToken is Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "MMT_0.1"; //An arbitrary versioning scheme


    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {

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
        MiniMeTokenFactory _tokenFactory,
        MiniMeToken _parentToken,
        uint _parentSnapShotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        tokenFactory = _tokenFactory;
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
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
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {

        // The controller of this contract can move tokens around at will,
        //  this is important to recognize! Confirm that you trust the
        //  controller of this contract, which in most situations should be
        //  another open source smart contract or 0x0
        if (msg.sender != controller) {
            require(transfersEnabled);

            // The standard ERC 20 transferFrom functionality
            if (allowed[_from][msg.sender] < _amount)
                return false;
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
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != 0) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        var previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onTransfer(_from, _to, _amount) == true);
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
        return true;
    }

    /// @param _owner The address that's balance is being requested
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
            // Adding the ` == true` makes the linter shut up so...
            require(ITokenController(controller).onApprove(msg.sender, _spender, _amount) == true);
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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        _spender.receiveApproval(
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
    function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
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
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
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
    ) public returns(MiniMeToken)
    {
        uint256 snapshot = _snapshotBlock == 0 ? block.number - 1 : _snapshotBlock;

        MiniMeToken cloneToken = tokenFactory.createCloneToken(
            this,
            snapshot,
            _cloneTokenName,
            _cloneDecimalUnits,
            _cloneTokenSymbol,
            _transfersEnabled
        );

        cloneToken.changeController(msg.sender);

        // An event to make the token easy to find on the blockchain
        NewCloneToken(address(cloneToken), snapshot);
        return cloneToken;
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) onlyController public returns (bool) {
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
    function destroyTokens(address _owner, uint _amount) onlyController public returns (bool) {
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
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) constant internal returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
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
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0)
            return false;

        assembly {
            size := extcodesize(_addr)
        }

        return size>0;
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function () external payable {
        require(isContract(controller));
        // Adding the ` == true` makes the linter shut up so...
        require(ITokenController(controller).proxyPayment.value(msg.value)(msg.sender) == true);
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) onlyController public {
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
        MiniMeToken _parentToken,
        uint _snapshotBlock,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol,
        bool _transfersEnabled
    ) public returns (MiniMeToken)
    {
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

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[]) {
        return new uint256[](0);
    }

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c, _d);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IACL {
    function initialize(address permissionsCreator) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IAragonApp.sol";
import "../common/UnstructuredStorage.sol";
import "../kernel/IKernel.sol";


contract AppStorage is IAragonApp {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_POSITION = keccak256("aragonOS.appStorage.kernel");
    bytes32 internal constant APP_ID_POSITION = keccak256("aragonOS.appStorage.appId");
    */
    bytes32 internal constant KERNEL_POSITION = 0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b;
    bytes32 internal constant APP_ID_POSITION = 0xd625496217aa6a3453eecb9c3489dc5a53e6c67b444329ea2b2cbc9ff547639b;

    function kernel() public view returns (IKernel) {
        return IKernel(KERNEL_POSITION.getStorageAddress());
    }

    function appId() public view returns (bytes32) {
        return APP_ID_POSITION.getStorageBytes32();
    }

    function setKernel(IKernel _kernel) internal {
        KERNEL_POSITION.setStorageAddress(address(_kernel));
    }

    function setAppId(bytes32 _appId) internal {
        APP_ID_POSITION.setStorageBytes32(_appId);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./AppStorage.sol";
import "../acl/ACLSyntaxSugar.sol";
import "../common/Autopetrified.sol";
import "../common/ConversionHelpers.sol";
import "../common/ReentrancyGuard.sol";
import "../common/VaultRecoverable.sol";
import "../evmscript/EVMScriptRunner.sol";
import "../lib/standards/ERC165.sol";


// Contracts inheriting from AragonApp are, by default, immediately petrified upon deployment so
// that they can never be initialized.
// Unless overriden, this behaviour enforces those contracts to be usable only behind an AppProxy.
// ReentrancyGuard, EVMScriptRunner, and ACLSyntaxSugar are not directly used by this contract, but
// are included so that they are automatically usable by subclassing contracts
contract AragonApp is ERC165, AppStorage, Autopetrified, VaultRecoverable, ReentrancyGuard, EVMScriptRunner, ACLSyntaxSugar {
    string private constant ERROR_AUTH_FAILED = "APP_AUTH_FAILED";

    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)), ERROR_AUTH_FAILED);
        _;
    }

    modifier authP(bytes32 _role, uint256[] _params) {
        require(canPerform(msg.sender, _role, _params), ERROR_AUTH_FAILED);
        _;
    }

    /**
    * @dev Check whether an action can be performed by a sender for a particular role on this app
    * @param _sender Sender of the call
    * @param _role Role on this app
    * @param _params Permission params for the role
    * @return Boolean indicating whether the sender has the permissions to perform the action.
    *         Always returns false if the app hasn't been initialized yet.
    */
    function canPerform(address _sender, bytes32 _role, uint256[] _params) public view returns (bool) {
        if (!hasInitialized()) {
            return false;
        }

        IKernel linkedKernel = kernel();
        if (address(linkedKernel) == address(0)) {
            return false;
        }

        return linkedKernel.hasPermission(
            _sender,
            address(this),
            _role,
            ConversionHelpers.dangerouslyCastUintArrayToBytes(_params)
        );
    }

    /**
    * @dev Get the recovery vault for the app
    * @return Recovery vault address for the app
    */
    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        return kernel().getRecoveryVault(); // if kernel is not set, it will revert
    }

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == ARAGON_APP_INTERFACE_ID;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../kernel/IKernel.sol";


contract IAragonApp {
    // Includes appId and kernel methods:
    bytes4 internal constant ARAGON_APP_INTERFACE_ID = bytes4(0x54053e6c);

    function kernel() public view returns (IKernel);
    function appId() public view returns (bytes32);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IAgreement.sol";
import "./IDisputable.sol";
import "../AragonApp.sol";
import "../../lib/math/SafeMath64.sol";
import "../../lib/token/ERC20.sol";


contract DisputableAragonApp is IDisputable, AragonApp {
    /* Validation errors */
    string internal constant ERROR_SENDER_NOT_AGREEMENT = "DISPUTABLE_SENDER_NOT_AGREEMENT";
    string internal constant ERROR_AGREEMENT_STATE_INVALID = "DISPUTABLE_AGREEMENT_STATE_INVAL";

    // This role is used to protect who can challenge actions in derived Disputable apps. However, it is not required
    // to be validated in the app itself as the connected Agreement is responsible for performing the check on a challenge.
    // bytes32 public constant CHALLENGE_ROLE = keccak256("CHALLENGE_ROLE");
    bytes32 public constant CHALLENGE_ROLE = 0xef025787d7cd1a96d9014b8dc7b44899b8c1350859fb9e1e05f5a546dd65158d;

    // bytes32 public constant SET_AGREEMENT_ROLE = keccak256("SET_AGREEMENT_ROLE");
    bytes32 public constant SET_AGREEMENT_ROLE = 0x8dad640ab1b088990c972676ada708447affc660890ec9fc9a5483241c49f036;

    // bytes32 internal constant AGREEMENT_POSITION = keccak256("aragonOS.appStorage.agreement");
    bytes32 internal constant AGREEMENT_POSITION = 0x6dbe80ccdeafbf5f3fff5738b224414f85e9370da36f61bf21c65159df7409e9;

    modifier onlyAgreement() {
        require(address(_getAgreement()) == msg.sender, ERROR_SENDER_NOT_AGREEMENT);
        _;
    }

    /**
    * @notice Challenge disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external onlyAgreement {
        _onDisputableActionChallenged(_disputableActionId, _challengeId, _challenger);
    }

    /**
    * @notice Allow disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function onDisputableActionAllowed(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionAllowed(_disputableActionId);
    }

    /**
    * @notice Reject disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function onDisputableActionRejected(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionRejected(_disputableActionId);
    }

    /**
    * @notice Void disputable action #`_disputableActionId`
    * @dev This hook must be implemented by Disputable apps. We provide a base implementation to ensure that the `onlyAgreement` modifier
    *      is included. Subclasses should implement the internal implementation of the hook.
    * @param _disputableActionId Identifier of the action to be voided
    */
    function onDisputableActionVoided(uint256 _disputableActionId) external onlyAgreement {
        _onDisputableActionVoided(_disputableActionId);
    }

    /**
    * @notice Set Agreement to `_agreement`
    * @param _agreement Agreement instance to be set
    */
    function setAgreement(IAgreement _agreement) external auth(SET_AGREEMENT_ROLE) {
        IAgreement agreement = _getAgreement();
        require(agreement == IAgreement(0) && _agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);

        AGREEMENT_POSITION.setStorageAddress(address(_agreement));
        emit AgreementSet(_agreement);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function getAgreement() external view returns (IAgreement) {
        return _getAgreement();
    }

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == DISPUTABLE_INTERFACE_ID;
    }

    /**
    * @dev Internal implementation of the `onDisputableActionChallenged` hook
    * @param _disputableActionId Identifier of the action to be challenged
    * @param _challengeId Identifier of the challenge in the context of the Agreement
    * @param _challenger Address that submitted the challenge
    */
    function _onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionRejected` hook
    * @param _disputableActionId Identifier of the action to be rejected
    */
    function _onDisputableActionRejected(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionAllowed` hook
    * @param _disputableActionId Identifier of the action to be allowed
    */
    function _onDisputableActionAllowed(uint256 _disputableActionId) internal;

    /**
    * @dev Internal implementation of the `onDisputableActionVoided` hook
    * @param _disputableActionId Identifier of the action to be voided
    */
    function _onDisputableActionVoided(uint256 _disputableActionId) internal;

    /**
    * @dev Register a new disputable action in the Agreement
    * @param _disputableActionId Identifier of the action in the context of the Disputable
    * @param _context Link to human-readable context for the given action
    * @param _submitter Address that submitted the action
    * @return Unique identifier for the created action in the context of the Agreement
    */
    function _registerDisputableAction(uint256 _disputableActionId, bytes _context, address _submitter) internal returns (uint256) {
        IAgreement agreement = _ensureAgreement();
        return agreement.newAction(_disputableActionId, _context, _submitter);
    }

    /**
    * @dev Close disputable action in the Agreement
    * @param _actionId Identifier of the action in the context of the Agreement
    */
    function _closeDisputableAction(uint256 _actionId) internal {
        IAgreement agreement = _ensureAgreement();
        agreement.closeAction(_actionId);
    }

    /**
    * @dev Tell the linked Agreement
    * @return Agreement
    */
    function _getAgreement() internal view returns (IAgreement) {
        return IAgreement(AGREEMENT_POSITION.getStorageAddress());
    }

    /**
    * @dev Tell the linked Agreement or revert if it has not been set
    * @return Agreement
    */
    function _ensureAgreement() internal view returns (IAgreement) {
        IAgreement agreement = _getAgreement();
        require(agreement != IAgreement(0), ERROR_AGREEMENT_STATE_INVALID);
        return agreement;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../../lib/token/ERC20.sol";


contract IAgreement {

    event ActionSubmitted(uint256 indexed actionId, address indexed disputable);
    event ActionClosed(uint256 indexed actionId);
    event ActionChallenged(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionSettled(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionDisputed(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionAccepted(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionVoided(uint256 indexed actionId, uint256 indexed challengeId);
    event ActionRejected(uint256 indexed actionId, uint256 indexed challengeId);

    enum ChallengeState {
        Waiting,
        Settled,
        Disputed,
        Rejected,
        Accepted,
        Voided
    }

    function newAction(uint256 _disputableActionId, bytes _context, address _submitter) external returns (uint256);

    function closeAction(uint256 _actionId) external;

    function challengeAction(uint256 _actionId, uint256 _settlementOffer, bool _finishedSubmittingEvidence, bytes _context) external;

    function settleAction(uint256 _actionId) external;

    function disputeAction(uint256 _actionId, bool _finishedSubmittingEvidence) external;
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IAgreement.sol";
import "../../lib/standards/ERC165.sol";
import "../../lib/token/ERC20.sol";


contract IDisputable is ERC165 {
    // Includes setAgreement, onDisputableActionChallenged, onDisputableActionAllowed,
    // onDisputableActionRejected, onDisputableActionVoided, getAgreement, canChallenge, and canClose methods:
    bytes4 internal constant DISPUTABLE_INTERFACE_ID = bytes4(0xf3d3bb51);

    event AgreementSet(IAgreement indexed agreement);

    function setAgreement(IAgreement _agreement) external;

    function onDisputableActionChallenged(uint256 _disputableActionId, uint256 _challengeId, address _challenger) external;

    function onDisputableActionAllowed(uint256 _disputableActionId) external;

    function onDisputableActionRejected(uint256 _disputableActionId) external;

    function onDisputableActionVoided(uint256 _disputableActionId) external;

    function getAgreement() external view returns (IAgreement);

    function canChallenge(uint256 _disputableActionId) external view returns (bool);

    function canClose(uint256 _disputableActionId) external view returns (bool);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Petrifiable.sol";


contract Autopetrified is Petrifiable {
    constructor() public {
        // Immediately petrify base (non-proxy) instances of inherited contracts on deploy.
        // This renders them uninitializable (and unusable without a proxy).
        petrify();
    }
}

pragma solidity ^0.4.24;


library ConversionHelpers {
    string private constant ERROR_IMPROPER_LENGTH = "CONVERSION_IMPROPER_LENGTH";

    function dangerouslyCastUintArrayToBytes(uint256[] memory _input) internal pure returns (bytes memory output) {
        // Force cast the uint256[] into a bytes array, by overwriting its length
        // Note that the bytes array doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 byteLength = _input.length * 32;
        assembly {
            output := _input
            mstore(output, byteLength)
        }
    }

    function dangerouslyCastBytesToUintArray(bytes memory _input) internal pure returns (uint256[] memory output) {
        // Force cast the bytes array into a uint256[], by overwriting its length
        // Note that the uint256[] doesn't need to be initialized as we immediately overwrite it
        // with the input and a new length. The input becomes invalid from this point forward.
        uint256 intsLength = _input.length / 32;
        require(_input.length == intsLength * 32, ERROR_IMPROPER_LENGTH);

        assembly {
            output := _input
            mstore(output, intsLength)
        }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address internal constant ETH = address(0);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IVaultRecoverable {
    event RecoverToVault(address indexed vault, address indexed token, uint256 amount);

    function transferToVault(address token) external;

    function allowRecoverability(address token) external view returns (bool);
    function getRecoveryVault() external view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./TimeHelpers.sol";
import "./UnstructuredStorage.sol";


contract Initializable is TimeHelpers {
    using UnstructuredStorage for bytes32;

    // keccak256("aragonOS.initializable.initializationBlock")
    bytes32 internal constant INITIALIZATION_BLOCK_POSITION = 0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e;

    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    string private constant ERROR_NOT_INITIALIZED = "INIT_NOT_INITIALIZED";

    modifier onlyInit {
        require(getInitializationBlock() == 0, ERROR_ALREADY_INITIALIZED);
        _;
    }

    modifier isInitialized {
        require(hasInitialized(), ERROR_NOT_INITIALIZED);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return INITIALIZATION_BLOCK_POSITION.getStorageUint256();
    }

    /**
    * @return Whether the contract has been initialized by the time of the current block
    */
    function hasInitialized() public view returns (bool) {
        uint256 initializationBlock = getInitializationBlock();
        return initializationBlock != 0 && getBlockNumber() >= initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(getBlockNumber());
    }

    /**
    * @dev Function to be called by top level contract after initialization to enable the contract
    *      at a future block number rather than immediately.
    */
    function initializedAt(uint256 _blockNumber) internal onlyInit {
        INITIALIZATION_BLOCK_POSITION.setStorageUint256(_blockNumber);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract IsContract {
    /*
    * NOTE: this should NEVER be used for authentication
    * (see pitfalls: https://github.com/fergarrui/ethereum-security/tree/master/contracts/extcodesize).
    *
    * This is only intended to be used as a sanity check that an address is actually a contract,
    * RATHER THAN an address not being a contract.
    */
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Initializable.sol";


contract Petrifiable is Initializable {
    // Use block UINT256_MAX (which should be never) as the initializable date
    uint256 internal constant PETRIFIED_BLOCK = uint256(-1);

    function isPetrified() public view returns (bool) {
        return getInitializationBlock() == PETRIFIED_BLOCK;
    }

    /**
    * @dev Function to be called by top level contract to prevent being initialized.
    *      Useful for freezing base contracts when they're used behind proxies.
    */
    function petrify() internal onlyInit {
        initializedAt(PETRIFIED_BLOCK);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../common/UnstructuredStorage.sol";


contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

// Inspired by AdEx (https://github.com/AdExNetwork/adex-protocol-eth/blob/b9df617829661a7518ee10f4cb6c4108659dd6d5/contracts/libs/SafeERC20.sol)
// and 0x (https://github.com/0xProject/0x-monorepo/blob/737d1dc54d72872e24abce5a1dbe1b66d35fa21a/contracts/protocol/contracts/protocol/AssetProxy/ERC20Proxy.sol#L143)

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";


library SafeERC20 {
    // Before 0.5, solidity has a mismatch between `address.transfer()` and `token.transfer()`:
    // https://github.com/ethereum/solidity/issues/3544
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;

    string private constant ERROR_TOKEN_BALANCE_REVERTED = "SAFE_ERC_20_BALANCE_REVERTED";
    string private constant ERROR_TOKEN_ALLOWANCE_REVERTED = "SAFE_ERC_20_ALLOWANCE_REVERTED";

    function invokeAndCheckSuccess(address _addr, bytes memory _calldata)
        private
        returns (bool)
    {
        bool ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            let success := call(
                gas,                  // forward all gas
                _addr,                // address
                0,                    // no value
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                // Check number of bytes returned from last function call
                switch returndatasize

                // No bytes returned: assume success
                case 0 {
                    ret := 1
                }

                // 32 bytes returned: check if non-zero
                case 0x20 {
                    // Only return success if returned data was true
                    // Already have output in ptr
                    ret := eq(mload(ptr), 1)
                }

                // Not sure what was returned: don't mark as success
                default { }
            }
        }
        return ret;
    }

    function staticInvoke(address _addr, bytes memory _calldata)
        private
        view
        returns (bool, uint256)
    {
        bool success;
        uint256 ret;
        assembly {
            let ptr := mload(0x40)    // free memory pointer

            success := staticcall(
                gas,                  // forward all gas
                _addr,                // address
                add(_calldata, 0x20), // calldata start
                mload(_calldata),     // calldata length
                ptr,                  // write output over free memory
                0x20                  // uint256 return
            )

            if gt(success, 0) {
                ret := mload(ptr)
            }
        }
        return (success, ret);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transfer() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransfer(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            TRANSFER_SELECTOR,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.transferFrom() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeTransferFrom(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.transferFrom.selector,
            _from,
            _to,
            _amount
        );
        return invokeAndCheckSuccess(_token, transferFromCallData);
    }

    /**
    * @dev Same as a standards-compliant ERC20.approve() that never reverts (returns false).
    *      Note that this makes an external call to the token.
    */
    function safeApprove(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _amount
        );
        return invokeAndCheckSuccess(_token, approveCallData);
    }

    /**
    * @dev Static call into ERC20.balanceOf().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticBalanceOf(ERC20 _token, address _owner) internal view returns (uint256) {
        bytes memory balanceOfCallData = abi.encodeWithSelector(
            _token.balanceOf.selector,
            _owner
        );

        (bool success, uint256 tokenBalance) = staticInvoke(_token, balanceOfCallData);
        require(success, ERROR_TOKEN_BALANCE_REVERTED);

        return tokenBalance;
    }

    /**
    * @dev Static call into ERC20.allowance().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticAllowance(ERC20 _token, address _owner, address _spender) internal view returns (uint256) {
        bytes memory allowanceCallData = abi.encodeWithSelector(
            _token.allowance.selector,
            _owner,
            _spender
        );

        (bool success, uint256 allowance) = staticInvoke(_token, allowanceCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return allowance;
    }

    /**
    * @dev Static call into ERC20.totalSupply().
    * Reverts if the call fails for some reason (should never fail).
    */
    function staticTotalSupply(ERC20 _token) internal view returns (uint256) {
        bytes memory totalSupplyCallData = abi.encodeWithSelector(_token.totalSupply.selector);

        (bool success, uint256 totalSupply) = staticInvoke(_token, totalSupplyCallData);
        require(success, ERROR_TOKEN_ALLOWANCE_REVERTED);

        return totalSupply;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./Uint256Helpers.sol";


contract TimeHelpers {
    using Uint256Helpers for uint256;

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
    * @dev Returns the current block number, converted to uint64.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

    /**
    * @dev Returns the current timestamp.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp; // solium-disable-line security/no-block-members
    }

    /**
    * @dev Returns the current timestamp, converted to uint64.
    *      Using a function rather than `block.timestamp` allows us to easily mock it in
    *      tests.
    */
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly { data := sload(position) }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly { data := sload(position) }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly { data := sload(position) }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly { data := sload(position) }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly { sstore(position, data) }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly { sstore(position, data) }
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../lib/token/ERC20.sol";
import "./EtherTokenConstant.sol";
import "./IsContract.sol";
import "./IVaultRecoverable.sol";
import "./SafeERC20.sol";


contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    using SafeERC20 for ERC20;

    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_VAULT_NOT_CONTRACT = "RECOVER_VAULT_NOT_CONTRACT";
    string private constant ERROR_TOKEN_TRANSFER_FAILED = "RECOVER_TOKEN_TRANSFER_FAILED";

    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token), ERROR_DISALLOWED);
        address vault = getRecoveryVault();
        require(isContract(vault), ERROR_VAULT_NOT_CONTRACT);

        uint256 balance;
        if (_token == ETH) {
            balance = address(this).balance;
            vault.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.staticBalanceOf(this);
            require(token.safeTransfer(vault, balance), ERROR_TOKEN_TRANSFER_FAILED);
        }

        emit RecoverToVault(vault, _token, balance);
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }

    // Cast non-implemented interface to be public so we can use it internally
    function getRecoveryVault() public view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";
import "./IEVMScriptRegistry.sol";

import "../apps/AppStorage.sol";
import "../kernel/KernelConstants.sol";
import "../common/Initializable.sol";


contract EVMScriptRunner is AppStorage, Initializable, EVMScriptRegistryConstants, KernelNamespaceConstants {
    string private constant ERROR_EXECUTOR_UNAVAILABLE = "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED = "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(address indexed executor, bytes script, bytes input, bytes returnData);

    function getEVMScriptExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getEVMScriptRegistry().getScriptExecutor(_script));
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(KERNEL_APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(bytes _script, bytes _input, address[] _blacklist)
        internal
        isInitialized
        protectState
        returns (bytes)
    {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(sig, _script, _input, _blacklist);

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas,                // forward all gas
                executor,           // address
                add(data, 0x20),    // calldata start
                mload(data),        // calldata length
                0,                  // don't write output (we'll handle this ourselves)
                0                   // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    // Need at least 0x40 bytes returned for properly ABI-encoded bytes values,
                    // revert with "EVMRUN_EXECUTOR_INVALID_RETURN"
                    // See remix: doing a `revert("EVMRUN_EXECUTOR_INVALID_RETURN")` always results in
                    // this memory layout
                    mstore(output, 0x08c379a000000000000000000000000000000000000000000000000000000000)         // error identifier
                    mstore(add(output, 0x04), 0x0000000000000000000000000000000000000000000000000000000000000020) // starting offset
                    mstore(add(output, 0x24), 0x000000000000000000000000000000000000000000000000000000000000001e) // reason length
                    mstore(add(output, 0x44), 0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000) // reason

                    revert(output, 100) // 100 = 4 + 3 * 32 (error identifier + 3 words for the ABI encoded error)
                }
                default {
                    // Copy result
                    //
                    // Needs to perform an ABI decode for the expected `bytes` return type of
                    // `executor.execScript()` as solidity will automatically ABI encode the returned bytes as:
                    //    [ position of the first dynamic length return value = 0x20 (32 bytes) ]
                    //    [ output length (32 bytes) ]
                    //    [ output content (N bytes) ]
                    //
                    // Perform the ABI decode by ignoring the first 32 bytes of the return data
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize)) // free mem ptr set
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
    function executorType() external pure returns (bytes32);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "./IEVMScriptExecutor.sol";


contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    */
    bytes32 internal constant EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(IEVMScriptExecutor executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    // TODO: this should be external
    // See https://github.com/ethereum/solidity/issues/4832
    function getScriptExecutor(bytes script) public view returns (IEVMScriptExecutor);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;

import "../acl/IACL.sol";
import "../common/IVaultRecoverable.sol";


interface IKernelEvents {
    event SetApp(bytes32 indexed namespace, bytes32 indexed appId, address app);
}


// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 appId, address app) public;
    function getApp(bytes32 namespace, bytes32 appId) public view returns (address);
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract KernelAppIds {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_APP_ID = apmNamehash("kernel");
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = apmNamehash("acl");
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = apmNamehash("vault");
    */
    bytes32 internal constant KERNEL_CORE_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 internal constant KERNEL_DEFAULT_ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 internal constant KERNEL_DEFAULT_VAULT_APP_ID = 0x7e852e0fcfce6551c13800f1e7476f982525c2b5277ba14b24339c68416336d1;
}


contract KernelNamespaceConstants {
    /* Hardcoded constants to save gas
    bytes32 internal constant KERNEL_CORE_NAMESPACE = keccak256("core");
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = keccak256("base");
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = keccak256("app");
    */
    bytes32 internal constant KERNEL_CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 internal constant KERNEL_APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 internal constant KERNEL_APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
}

pragma solidity ^0.4.24;

/**
 * @title Math
 * @dev Assorted math operations
 */

library Math {
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

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted to use pragma ^0.4.24 and satisfy our linter rules

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    string private constant ERROR_ADD_OVERFLOW = "MATH_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b, ERROR_MUL_OVERFLOW);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint256 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/d51e38758e1d985661534534d5c61e27bece5042/contracts/math/SafeMath.sol
// Adapted for uint64, pragma ^0.4.24, and satisfying our linter rules
// Also optimized the mul() implementation, see https://github.com/aragon/aragonOS/pull/417

pragma solidity ^0.4.24;


/**
 * @title SafeMath64
 * @dev Math operations for uint64 with safety checks that revert on error
 */
library SafeMath64 {
    string private constant ERROR_ADD_OVERFLOW = "MATH64_ADD_OVERFLOW";
    string private constant ERROR_SUB_UNDERFLOW = "MATH64_SUB_UNDERFLOW";
    string private constant ERROR_MUL_OVERFLOW = "MATH64_MUL_OVERFLOW";
    string private constant ERROR_DIV_ZERO = "MATH64_DIV_ZERO";

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint256 c = uint256(_a) * uint256(_b);
        require(c < 0x010000000000000000, ERROR_MUL_OVERFLOW); // 2**64 (less gas this way)

        return uint64(c);
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b > 0, ERROR_DIV_ZERO); // Solidity only automatically asserts when dividing by 0
        uint64 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint64 _a, uint64 _b) internal pure returns (uint64) {
        require(_b <= _a, ERROR_SUB_UNDERFLOW);
        uint64 c = _a - _b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint64 _a, uint64 _b) internal pure returns (uint64) {
        uint64 c = _a + _b;
        require(c >= _a, ERROR_ADD_OVERFLOW);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint64 a, uint64 b) internal pure returns (uint64) {
        require(b != 0, ERROR_DIV_ZERO);
        return a % b;
    }
}

/*
 * SPDX-License-Identifier:    MIT
 */

pragma solidity ^0.4.24;


contract ERC165 {
    // Includes supportsInterface method:
    bytes4 internal constant ERC165_INTERFACE_ID = bytes4(0x01ffc9a7);

    /**
    * @dev Query if a contract implements a certain interface
    * @param _interfaceId The interface identifier being queried, as specified in ERC-165
    * @return True if the contract implements the requested interface and if its not 0xffffffff, false otherwise
    */
    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        return _interfaceId == ERC165_INTERFACE_ID;
    }
}

// See https://github.com/OpenZeppelin/openzeppelin-solidity/blob/a9f910d34f0ab33a1ae5e714f69f9596a02b4d91/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
        public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
        public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/disputable/DisputableAragonApp.sol";
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";
import "@aragon/os/contracts/lib/math/Math.sol";
import "@1hive/apps-token-manager/contracts/TokenManagerHook.sol";
import "@1hive/funds-manager/contracts/FundsManager.sol";
import "./lib/ArrayUtils.sol";
import "./lib/IPriceOracle.sol";

contract ConvictionVoting is DisputableAragonApp, TokenManagerHook {
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using ArrayUtils for uint256[];

    // bytes32 constant public PAUSE_CONTRACT_ROLE = keccak256("PAUSE_CONTRACT_ROLE");
    bytes32 constant public PAUSE_CONTRACT_ROLE = 0x0e3a87ad3cd0c04dcd1e538226de2b467c72316c162f937f5b6f791361662462;
    // bytes32 constant public UPDATE_SETTINGS_ROLE = keccak256("UPDATE_SETTINGS_ROLE");
    bytes32 constant public UPDATE_SETTINGS_ROLE = 0x9d4f140430c9045e12b5a104aa9e641c09b980a26ab8e12a32a2f3d155229ae3;
    // bytes32 constant public CREATE_PROPOSALS_ROLE = keccak256("CREATE_PROPOSALS_ROLE");
    bytes32 constant public CREATE_PROPOSALS_ROLE = 0xbf05b9322505d747ab5880dfb677dc4864381e9fc3a25ccfa184a3a53d02f4b2;
    // bytes32 constant public CANCEL_PROPOSALS_ROLE = keccak256("CANCEL_PROPOSALS_ROLE");
    bytes32 constant public CANCEL_PROPOSALS_ROLE = 0x82c52f79cad6ac09c16c165c562b50c5e655a09a19bb99b2d182ab3caff020f2;

    uint256 public constant D = 10000000;
    uint256 public constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 private constant TWO_128 = 0x100000000000000000000000000000000; // 2^128
    uint256 private constant TWO_127 = 0x80000000000000000000000000000000; // 2^127
    uint256 private constant TWO_64 = 0x10000000000000000; // 2^64
    uint256 public constant ABSTAIN_PROPOSAL_ID = 1;
    uint64 public constant MAX_STAKED_PROPOSALS = 10;

    string private constant ERROR_CONTRACT_PAUSED = "CV_CONTRACT_PAUSED";
    string private constant ERROR_PROPOSAL_DOES_NOT_EXIST = "CV_PROPOSAL_DOES_NOT_EXIST";
    string private constant ERROR_REQUESTED_AMOUNT_ZERO = "CV_REQUESTED_AMOUNT_ZERO";
    string private constant ERROR_NO_BENEFICIARY = "CV_NO_BENEFICIARY";
    string private constant ERROR_STAKING_ALREADY_STAKED = "CV_STAKING_ALREADY_STAKED";
    string private constant ERROR_PROPOSAL_NOT_ACTIVE = "CV_PROPOSAL_NOT_ACTIVE";
    string private constant ERROR_CANNOT_EXECUTE_ABSTAIN_PROPOSAL = "CV_CANNOT_EXECUTE_ABSTAIN_PROPOSAL";
    string private constant ERROR_CANNOT_EXECUTE_ZERO_VALUE_PROPOSAL = "CV_CANNOT_EXECUTE_ZERO_VALUE_PROPOSAL";
    string private constant ERROR_INSUFFICIENT_CONVICION = "CV_INSUFFICIENT_CONVICION";
    string private constant ERROR_SENDER_CANNOT_CANCEL = "CV_SENDER_CANNOT_CANCEL";
    string private constant ERROR_CANNOT_CANCEL_ABSTAIN_PROPOSAL = "CV_CANNOT_CANCEL_ABSTAIN_PROPOSAL";
    string private constant ERROR_AMOUNT_OVER_MAX_RATIO = "CV_AMOUNT_OVER_MAX_RATIO";
    string private constant ERROR_INCORRECT_TOKEN_MANAGER_HOOK = "CV_INCORRECT_TOKEN_MANAGER_HOOK";
    string private constant ERROR_AMOUNT_CAN_NOT_BE_ZERO = "CV_AMOUNT_CAN_NOT_BE_ZERO";
    string private constant ERROR_INCORRECT_PROPOSAL_STATUS = "CV_INCORRECT_PROPOSAL_STATUS";
    string private constant ERROR_STAKING_MORE_THAN_AVAILABLE = "CV_STAKING_MORE_THAN_AVAILABLE";
    string private constant ERROR_MAX_PROPOSALS_REACHED = "CV_MAX_PROPOSALS_REACHED";
    string private constant ERROR_WITHDRAW_MORE_THAN_STAKED = "CV_WITHDRAW_MORE_THAN_STAKED";
    string private constant ERROR_NO_TOKEN_MANAGER_SET = "CV_NO_TOKEN_MANAGER_SET";

    enum ProposalStatus {
        Active,              // A vote that has been reported to Agreements
        Paused,              // A vote that is being challenged by Agreements
        Cancelled,           // A vote that has been cancelled
        Executed             // A vote that has been executed
    }

    struct Proposal {
        uint256 requestedAmount;
        bool stableRequestAmount;
        address beneficiary;
        uint256 stakedTokens;
        uint256 convictionLast;
        uint64 blockLast;
        uint256 agreementActionId;
        ProposalStatus proposalStatus;
        mapping(address => uint256) voterStake;
        address submitter;
    }

    MiniMeToken public stakeToken;
    address public requestToken;
    address public stableToken;
    IPriceOracle public stableTokenOracle;
    FundsManager public fundsManager;
    uint256 public decay;
    uint256 public maxRatio;
    uint256 public weight;
    uint256 public minThresholdStakePercentage;
    uint256 public proposalCounter;
    uint256 public totalStaked;
    bool public contractPaused;

    mapping(uint256 => Proposal) internal proposals;
    mapping(address => uint256) internal totalVoterStake;
    mapping(address => uint256[]) internal voterStakedProposals;

    event ContractPaused(bool pauseEnabled);
    event OracleSettingsChanged(IPriceOracle stableTokenOracle, address stableToken);
    event FundsManagerChanged(FundsManager fundsManager);
    event ConvictionSettingsChanged(uint256 decay, uint256 maxRatio, uint256 weight, uint256 minThresholdStakePercentage);
    event ProposalAdded(address indexed entity, uint256 indexed id, uint256 indexed actionId, string title, bytes link, uint256 amount, bool stable, address beneficiary);
    event StakeAdded(address indexed entity, uint256 indexed id, uint256  amount, uint256 tokensStaked, uint256 totalTokensStaked, uint256 conviction);
    event StakeWithdrawn(address entity, uint256 indexed id, uint256 amount, uint256 tokensStaked, uint256 totalTokensStaked, uint256 conviction);
    event ProposalExecuted(uint256 indexed id, uint256 conviction);
    event ProposalPaused(uint256 indexed proposalId, uint256 indexed challengeId);
    event ProposalResumed(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalRejected(uint256 indexed proposalId);

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId == 1 || proposals[_proposalId].submitter != address(0), ERROR_PROPOSAL_DOES_NOT_EXIST);
        _;
    }

    modifier notPaused() {
        require(!contractPaused, ERROR_CONTRACT_PAUSED);
        _;
    }

    function initialize(
        MiniMeToken _stakeToken,
        address _requestToken,
        address _stableToken,
        IPriceOracle _stableTokenOracle,
        FundsManager _fundsManager,
        uint256 _decay,
        uint256 _maxRatio,
        uint256 _weight,
        uint256 _minThresholdStakePercentage
    )
        external onlyInit
    {
        proposalCounter = 2; // First proposal should be #2, #1 is reserved for abstain proposal, #0 is not used for better UX.
        stakeToken = _stakeToken;
        requestToken = _requestToken;
        stableToken = _stableToken;
        stableTokenOracle = _stableTokenOracle;
        fundsManager = _fundsManager;
        decay = _decay;
        maxRatio = _maxRatio;
        weight = _weight;
        minThresholdStakePercentage = _minThresholdStakePercentage;

        proposals[ABSTAIN_PROPOSAL_ID] = Proposal(
            0,
            false,
            0x0,
            0,
            0,
            0,
            0,
            ProposalStatus.Active,
            0x0
        );
        emit ProposalAdded(0x0, ABSTAIN_PROPOSAL_ID, 0, "Abstain proposal", "", 0, false, 0x0);

        initialized();
    }

    /**
    * @notice Pause / unpause the contract preventing / allowing general interaction
    * @param _pauseEnabled Whether to enable or disable pause
    */
    function pauseContract(bool _pauseEnabled) external auth(PAUSE_CONTRACT_ROLE) {
        contractPaused = _pauseEnabled;
        emit ContractPaused(contractPaused);
    }

    /**
    * @notice Update the stable token oracle settings
    * @param _stableTokenOracle The new stable token oracle
    * @param _stableToken The new stable token
    */
    function setStableTokenOracleSettings(IPriceOracle _stableTokenOracle, address _stableToken)
        external auth(UPDATE_SETTINGS_ROLE)
    {
        stableTokenOracle = _stableTokenOracle;
        stableToken = _stableToken;

        emit OracleSettingsChanged(_stableTokenOracle, _stableToken);
    }

    /**
    * @notice Update the funds manager
    * @param _fundsManager The new funds manager
    */
    function setFundsManager(FundsManager _fundsManager) external auth(UPDATE_SETTINGS_ROLE) {
        fundsManager = _fundsManager;
        emit FundsManagerChanged(_fundsManager);
    }

    /**
     * @notice Update the conviction voting parameters
     * @param _decay The rate at which conviction is accrued or lost from a proposal
     * @param _maxRatio Proposal threshold parameter
     * @param _weight Proposal threshold parameter
     * @param _minThresholdStakePercentage The minimum percent of stake token max supply that is used for calculating
        conviction
     */
    function setConvictionCalculationSettings(
        uint256 _decay,
        uint256 _maxRatio,
        uint256 _weight,
        uint256 _minThresholdStakePercentage
    )
        external auth(UPDATE_SETTINGS_ROLE)
    {
        decay = _decay;
        maxRatio = _maxRatio;
        weight = _weight;
        minThresholdStakePercentage = _minThresholdStakePercentage;

        emit ConvictionSettingsChanged(_decay, _maxRatio, _weight, _minThresholdStakePercentage);
    }

    /**
     * @notice Create signaling proposal `_title`
     * @param _title Title of the proposal
     * @param _link IPFS or HTTP link with proposal's description
     */
    function addSignalingProposal(string _title, bytes _link) external authP(CREATE_PROPOSALS_ROLE, arr(msg.sender)) {
        _addProposal(_title, _link, 0, false, address(0));
    }

    /**
     * @notice Create proposal `_title` for `@tokenAmount((self.requestToken(): address), _requestedAmount)` to `_beneficiary`
     * @param _title Title of the proposal
     * @param _link IPFS or HTTP link with proposal's description
     * @param _requestedAmount Tokens requested
     * @param _stableRequestAmount Whether the requested amount is in the request token or the stable token, converted to the request token upon execution
     * @param _beneficiary Address that will receive payment
     */
    function addProposal(string _title, bytes _link, uint256 _requestedAmount, bool _stableRequestAmount, address _beneficiary)
        external authP(CREATE_PROPOSALS_ROLE, arr(msg.sender))
    {
        require(_requestedAmount > 0, ERROR_REQUESTED_AMOUNT_ZERO);
        require(_beneficiary != address(0), ERROR_NO_BENEFICIARY);

        _addProposal(_title, _link, _requestedAmount, _stableRequestAmount, _beneficiary);
    }

    /**
      * @notice Stake `@tokenAmount((self.stakeToken(): address), _amount)` on proposal #`_proposalId`
      * @param _proposalId Proposal id
      * @param _amount Amount of tokens staked
      */
    function stakeToProposal(uint256 _proposalId, uint256 _amount) external isInitialized {
        _stake(_proposalId, _amount, msg.sender);
    }

    /**
     * @notice Stake all my `(self.stakeToken(): address).symbol(): string` tokens on proposal #`_proposalId`
     * @param _proposalId Proposal id
     */
    function stakeAllToProposal(uint256 _proposalId) external isInitialized {
        require(totalVoterStake[msg.sender] == 0, ERROR_STAKING_ALREADY_STAKED);
        _stake(_proposalId, stakeToken.balanceOf(msg.sender), msg.sender);
    }

    /**
     * @notice Withdraw `@tokenAmount((self.stakeToken(): address), _amount)` previously staked on proposal #`_proposalId`
     * @param _proposalId Proposal id
     * @param _amount Amount of tokens withdrawn
     */
    function withdrawFromProposal(uint256 _proposalId, uint256 _amount) external isInitialized proposalExists(_proposalId) {
        _withdrawFromProposal(_proposalId, _amount, msg.sender);
    }

    /**
     * @notice Withdraw all `(self.stakeToken(): address).symbol(): string` tokens previously staked on proposal #`_proposalId`
     * @param _proposalId Proposal id
     */
    function withdrawAllFromProposal(uint256 _proposalId) external isInitialized proposalExists(_proposalId) {
        _withdrawFromProposal(_proposalId, proposals[_proposalId].voterStake[msg.sender], msg.sender);
    }

    /**
     * @notice Withdraw all callers stake from inactive proposals
     */
    function withdrawFromInactiveProposals() external isInitialized {
        _withdrawInactiveStakedTokens(uint256(-1), msg.sender);
    }

    /**
     * @notice Execute proposal #`_proposalId`
     * @dev ...by sending `@tokenAmount((self.requestToken(): address), self.getPropoal(_proposalId): ([uint256], address, uint256, uint256, uint64, bool))` to `self.getPropoal(_proposalId): (uint256, [address], uint256, uint256, uint64, bool)`
     * @param _proposalId Proposal id
     */
    function executeProposal(uint256 _proposalId) external notPaused isInitialized proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        require(_proposalId != ABSTAIN_PROPOSAL_ID, ERROR_CANNOT_EXECUTE_ABSTAIN_PROPOSAL);
        require(proposal.requestedAmount > 0, ERROR_CANNOT_EXECUTE_ZERO_VALUE_PROPOSAL);
        require(proposal.proposalStatus == ProposalStatus.Active, ERROR_PROPOSAL_NOT_ACTIVE);

        _calculateAndSetConviction(proposal, proposal.stakedTokens);
        uint256 requestedAmount = _getRequestAmount(proposal);
        require(proposal.convictionLast > calculateThreshold(requestedAmount), ERROR_INSUFFICIENT_CONVICION);

        proposal.proposalStatus = ProposalStatus.Executed;
        _closeDisputableAction(proposal.agreementActionId);

        fundsManager.transfer(requestToken, proposal.beneficiary, requestedAmount);

        emit ProposalExecuted(_proposalId, proposal.convictionLast);
    }

    /**
     * @notice Cancel proposal #`_proposalId`
     * @param _proposalId Proposal id
     */
    function cancelProposal(uint256 _proposalId) external notPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        bool senderHasPermission = canPerform(msg.sender, CANCEL_PROPOSALS_ROLE, new uint256[](0));
        require(proposal.submitter == msg.sender || senderHasPermission, ERROR_SENDER_CANNOT_CANCEL);
        require(_proposalId != ABSTAIN_PROPOSAL_ID, ERROR_CANNOT_CANCEL_ABSTAIN_PROPOSAL);
        require(proposal.proposalStatus == ProposalStatus.Active, ERROR_PROPOSAL_NOT_ACTIVE);

        proposal.proposalStatus = ProposalStatus.Cancelled;
        _closeDisputableAction(proposal.agreementActionId);

        emit ProposalCancelled(_proposalId);
    }

    /**
     * @dev Get proposal details
     * @param _proposalId Proposal id
     * @return Requested amount
     * @return If requested in stable amount
     * @return Beneficiary address
     * @return Current total stake of tokens on this proposal
     * @return Conviction this proposal had last time calculateAndSetConviction was called
     * @return Block when calculateAndSetConviction was called
     * @return True if proposal has already been executed
     * @return AgreementActionId assigned by the Agreements app
     * @return ProposalStatus defining the state of the proposal
     * @return Submitter of the proposal
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 requestedAmount,
        bool stableRequestAmount,
        address beneficiary,
        uint256 stakedTokens,
        uint256 convictionLast,
        uint64 blockLast,
        uint256 agreementActionId,
        ProposalStatus proposalStatus,
        address submitter,
        uint256 threshold
    )
    {
        Proposal storage proposal = proposals[_proposalId];
        threshold = proposal.requestedAmount == 0 ? 0 : calculateThreshold(_getRequestAmount(proposal));
        return (
            proposal.requestedAmount,
            proposal.stableRequestAmount,
            proposal.beneficiary,
            proposal.stakedTokens,
            proposal.convictionLast,
            proposal.blockLast,
            proposal.agreementActionId,
            proposal.proposalStatus,
            proposal.submitter,
            threshold
        );
    }

    /**
     * @notice Get stake of voter `_voter` on proposal #`_proposalId`
     * @param _proposalId Proposal id
     * @param _voter Voter address
     * @return Proposal voter stake
     */
    function getProposalVoterStake(uint256 _proposalId, address _voter) external view returns (uint256) {
        return proposals[_proposalId].voterStake[_voter];
    }

    /**
     * @notice Get the total stake of voter `_voter` on all proposals
     * @param _voter Voter address
     * @return Total voter stake
     */
    function getTotalVoterStake(address _voter) external view returns (uint256) {
        return totalVoterStake[_voter];
    }

    /**
     * @notice Get all proposal ID's voter `_voter` has currently staked to
     * @param _voter Voter address
     * @return Voter proposals
     */
    function getVoterStakedProposals(address _voter) external view returns (uint256[]) {
        return voterStakedProposals[_voter];
    }

    /**
    * @dev IDisputable interface conformance
    */
    function canChallenge(uint256 _proposalId) external view returns (bool) {
        return proposals[_proposalId].proposalStatus == ProposalStatus.Active && !contractPaused;
    }

    /**
    * @dev IDisputable interface conformance
    */
    function canClose(uint256 _proposalId) external view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];

        return proposal.proposalStatus == ProposalStatus.Executed
            || proposal.proposalStatus == ProposalStatus.Cancelled;
    }

    /**
     * @dev Conviction formula: a^t * y(0) + x * (1 - a^t) / (1 - a)
     * Solidity implementation: y = (2^128 * a^t * y0 + x * D * (2^128 - 2^128 * a^t) / (D - aD) + 2^127) / 2^128
     * @param _timePassed Number of blocks since last conviction record
     * @param _lastConv Last conviction record
     * @param _oldAmount Amount of tokens staked until now
     * @return Current conviction
     */
    function calculateConviction(uint64 _timePassed, uint256 _lastConv, uint256 _oldAmount) public view returns(uint256) {
        uint256 t = uint256(_timePassed);
        // atTWO_128 = 2^128 * a^t
        uint256 atTWO_128 = _pow((decay << 128).div(D), t);
        // solium-disable-previous-line
        // conviction = (atTWO_128 * _lastConv + _oldAmount * D * (2^128 - atTWO_128) / (D - aD) + 2^127) / 2^128
        return (atTWO_128.mul(_lastConv).add(_oldAmount.mul(D).mul(TWO_128.sub(atTWO_128)).div(D - decay))).add(TWO_127) >> 128;
    }

    /**
     * @dev Formula: ρ * totalStaked / (1 - a) / (β - requestedAmount / total)**2
     * For the Solidity implementation we amplify ρ and β and simplify the formula:
     * weight = ρ * D
     * maxRatio = β * D
     * decay = a * D
     * threshold = weight * totalStaked * D ** 2 * funds ** 2 / (D - decay) / (maxRatio * funds - requestedAmount * D) ** 2
     * @param _requestedAmount Requested amount of tokens on certain proposal
     * @return Threshold a proposal's conviction should surpass in order to be able to
     * executed it.
     */
    function calculateThreshold(uint256 _requestedAmount) public view returns (uint256 _threshold) {
        uint256 funds = fundsManager.balance(requestToken);
        require(maxRatio.mul(funds) > _requestedAmount.mul(D), ERROR_AMOUNT_OVER_MAX_RATIO);
        // denom = maxRatio * 2 ** 64 / D  - requestedAmount * 2 ** 64 / funds
        uint256 denom = (maxRatio << 64).div(D).sub((_requestedAmount << 64).div(funds));
        // _threshold = (weight * 2 ** 128 / D) / (denom ** 2 / 2 ** 64) * totalStaked * D / 2 ** 128
        _threshold = ((weight << 128).div(D).div(denom.mul(denom) >> 64)).mul(D).div(D.sub(decay)).mul(_totalStaked()) >> 64;
    }

    function _totalStaked() internal view returns (uint256) {
        uint256 minTotalStake = (stakeToken.totalSupply().mul(minThresholdStakePercentage)).div(ONE_HUNDRED_PERCENT);
        return totalStaked < minTotalStake ? minTotalStake : totalStaked;
    }

    function _getRequestAmount(Proposal storage proposal) internal view returns (uint256) {
        return proposal.stableRequestAmount ?
            stableTokenOracle.consult(stableToken, proposal.requestedAmount, requestToken) : proposal.requestedAmount;
    }

    /**
     * @dev Internal implementation of the `onDisputableActionChallenged` hook
     * @param _proposalId Identification number of the disputable action to be challenged
     */
    function _onDisputableActionChallenged(uint256 _proposalId, uint256  _challengeId, address /* _challenger */) internal {
        Proposal storage proposal = proposals[_proposalId];
        proposal.proposalStatus = ProposalStatus.Paused;

        emit ProposalPaused(_proposalId, _challengeId);
    }

    /**
    * @dev Internal implementation of the `onDisputableActionRejected` hook
    * @param _proposalId Identification number of the disputable action to be rejected
    */
    function _onDisputableActionRejected(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        proposal.proposalStatus = ProposalStatus.Cancelled;

        emit ProposalRejected(_proposalId);
    }

    /**
    * @dev Internal implementation of the `onDisputableActionAllowed` hook
    * @param _proposalId Identification number of the disputable action to be allowed
    */
    function _onDisputableActionAllowed(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        proposal.proposalStatus = ProposalStatus.Active;

        emit ProposalResumed(_proposalId);
    }

    /**
    * @dev Internal implementation of the `onDisputableActionVoided` hook
    * @param _proposalId Identification number of the disputable action to be voided
    */
    function _onDisputableActionVoided(uint256 _proposalId) internal {
        _onDisputableActionAllowed(_proposalId);
    }

    /**
     * @dev Overrides TokenManagerHook's `_onRegisterAsHook`
     */
    function _onRegisterAsHook(address _tokenManager, uint256 _hookId, address _token) internal {
        require(_token == address(stakeToken), ERROR_INCORRECT_TOKEN_MANAGER_HOOK);
    }

    /**
     * @dev Overrides TokenManagerHook's `_onTransfer`
     */
    function _onTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        if (_from == 0x0) {
            return true; // Do nothing on token mintings
        }

        uint256 newBalance = stakeToken.balanceOf(_from).sub(_amount);
        if (newBalance < totalVoterStake[_from]) {
            _withdrawInactiveStakedTokens(totalVoterStake[_from].sub(newBalance), _from);
        }

        if (newBalance < totalVoterStake[_from]) {
            _withdrawActiveStakedTokens(totalVoterStake[_from].sub(newBalance), _from);
        }

        return true;
    }

    /**
     * Multiply _a by _b / 2^128.  Parameter _a should be less than or equal to
     * 2^128 and parameter _b should be less than 2^128.
     * @param _a left argument
     * @param _b right argument
     * @return _a * _b / 2^128
     */
    function _mul(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
        require(_a <= TWO_128, "_a should be less than or equal to 2^128");
        require(_b < TWO_128, "_b should be less than 2^128");
        return _a.mul(_b).add(TWO_127) >> 128;
    }

    /**
     * Calculate (_a / 2^128)^_b * 2^128.  Parameter _a should be less than 2^128.
     *
     * @param _a left argument
     * @param _b right argument
     * @return (_a / 2^128)^_b * 2^128
     */
    function _pow(uint256 _a, uint256 _b) internal pure returns (uint256 _result) {
        require(_a < TWO_128, "_a should be less than 2^128");
        uint256 a = _a;
        uint256 b = _b;
        _result = TWO_128;
        while (b > 0) {
            if (b & 1 == 0) {
                a = _mul(a, a);
                b >>= 1;
            } else {
                _result = _mul(_result, a);
                b -= 1;
            }
        }
    }

    /**
     * @dev Calculate conviction and store it on the proposal
     * @param _proposal Proposal
     * @param _oldStaked Amount of tokens staked on a proposal until now
     */
    function _calculateAndSetConviction(Proposal storage _proposal, uint256 _oldStaked) internal {
        uint64 blockNumber = getBlockNumber64();
        assert(_proposal.blockLast <= blockNumber);
        if (_proposal.blockLast == blockNumber) {
            return; // Conviction already stored
        }
        // calculateConviction and store it
        uint256 conviction = calculateConviction(
            blockNumber - _proposal.blockLast, // we assert it doesn't overflow above
            _proposal.convictionLast,
            _oldStaked
        );
        _proposal.blockLast = blockNumber;
        _proposal.convictionLast = conviction;
    }

    function _addProposal(string _title, bytes _link, uint256 _requestedAmount, bool _stableRequestAmount, address _beneficiary)
        internal notPaused
    {
        uint256 agreementActionId = _registerDisputableAction(proposalCounter, _link, msg.sender);
        proposals[proposalCounter] = Proposal(
            _requestedAmount,
            _stableRequestAmount,
            _beneficiary,
            0,
            0,
            0,
            agreementActionId,
            ProposalStatus.Active,
            msg.sender
        );

        emit ProposalAdded(msg.sender, proposalCounter, agreementActionId, _title, _link, _requestedAmount, _stableRequestAmount, _beneficiary);
        proposalCounter++;
    }

    /**
     * @dev Stake an amount of tokens on a proposal
     * @param _proposalId Proposal id
     * @param _amount Amount of staked tokens
     * @param _from Account from which we stake
     */
    function _stake(uint256 _proposalId, uint256 _amount, address _from) internal notPaused proposalExists(_proposalId) {
        require(getTokenManager() != address(0), ERROR_NO_TOKEN_MANAGER_SET);

        Proposal storage proposal = proposals[_proposalId];
        require(_amount > 0, ERROR_AMOUNT_CAN_NOT_BE_ZERO);
        require(proposal.proposalStatus == ProposalStatus.Active || proposal.proposalStatus == ProposalStatus.Paused,
            ERROR_INCORRECT_PROPOSAL_STATUS);

        uint256 unstakedAmount = stakeToken.balanceOf(_from).sub(totalVoterStake[_from]);
        if (_amount > unstakedAmount) {
            _withdrawInactiveStakedTokens(_amount.sub(unstakedAmount), _from);
        }

        require(totalVoterStake[_from].add(_amount) <= stakeToken.balanceOf(_from), ERROR_STAKING_MORE_THAN_AVAILABLE);

        uint256 previousStake = proposal.stakedTokens;
        proposal.stakedTokens = proposal.stakedTokens.add(_amount);
        proposal.voterStake[_from] = proposal.voterStake[_from].add(_amount);
        totalVoterStake[_from] = totalVoterStake[_from].add(_amount);
        totalStaked = totalStaked.add(_amount);

        if (proposal.blockLast == 0) {
            proposal.blockLast = getBlockNumber64();
        } else {
            _calculateAndSetConviction(proposal, previousStake);
        }

        _updateVoterStakedProposals(_proposalId, _from);

        emit StakeAdded(_from, _proposalId, _amount, proposal.voterStake[_from], proposal.stakedTokens, proposal.convictionLast);
    }

    function _updateVoterStakedProposals(uint256 _proposalId, address _submitter) internal {
        uint256[] storage voterStakedProposalsArray = voterStakedProposals[_submitter];

        if (!voterStakedProposalsArray.contains(_proposalId)) {
            require(voterStakedProposalsArray.length < MAX_STAKED_PROPOSALS, ERROR_MAX_PROPOSALS_REACHED);
            voterStakedProposalsArray.push(_proposalId);
        }
    }

    /**
     * @dev Withdraw staked tokens from executed proposals until a target amount is reached.
     * @param _targetAmount Target at which to stop withdrawing tokens
     * @param _from Account to withdraw from
     */
    function _withdrawInactiveStakedTokens(uint256 _targetAmount, address _from) internal {
        uint256 i = 0;
        uint256 toWithdraw;
        uint256 withdrawnAmount = 0;
        uint256[] memory voterStakedProposalsCopy = voterStakedProposals[_from];

        while (i < voterStakedProposalsCopy.length && withdrawnAmount < _targetAmount) {
            uint256 proposalId = voterStakedProposalsCopy[i];
            Proposal storage proposal = proposals[proposalId];

            if (proposal.proposalStatus == ProposalStatus.Executed || proposal.proposalStatus == ProposalStatus.Cancelled) {
                toWithdraw = proposal.voterStake[_from];
                if (toWithdraw > 0) {
                    _withdrawFromProposal(proposalId, toWithdraw, _from);
                    withdrawnAmount = withdrawnAmount.add(toWithdraw);
                }
            }
            i++;
        }
    }

    /**
     * @dev Withdraw staked tokens from active proposals until a target amount is reached.
     *      Assumes there are no inactive staked proposals, to save gas.
     * @param _targetAmount Target at which to stop withdrawing tokens
     * @param _from Account to withdraw from
     */
    function _withdrawActiveStakedTokens(uint256 _targetAmount, address _from) internal {
        uint256 i = 0;
        uint256 toWithdraw;
        uint256 withdrawnAmount = 0;
        uint256[] memory voterStakedProposalsCopy = voterStakedProposals[_from];

        if (voterStakedProposals[_from].contains(ABSTAIN_PROPOSAL_ID)) {
            toWithdraw = Math.min256(_targetAmount, proposals[ABSTAIN_PROPOSAL_ID].voterStake[_from]);
            if (toWithdraw > 0) {
                _withdrawFromProposal(ABSTAIN_PROPOSAL_ID, toWithdraw, _from);
                withdrawnAmount = withdrawnAmount.add(toWithdraw);
            }
        }

        // We reset this variable as _withdrawFromProposal can update voterStakedProposals
        voterStakedProposalsCopy = voterStakedProposals[_from];

        while (i < voterStakedProposalsCopy.length && withdrawnAmount < _targetAmount) {
            uint256 proposalId = voterStakedProposalsCopy[i];
            Proposal storage proposal = proposals[proposalId];

            // For active proposals, we only subtract the needed amount to reach the target
            toWithdraw = Math.min256(_targetAmount.sub(withdrawnAmount), proposal.voterStake[_from]);
            if (toWithdraw > 0) {
                _withdrawFromProposal(proposalId, toWithdraw, _from);
                withdrawnAmount = withdrawnAmount.add(toWithdraw);
            }
            i++;
        }
    }

    /**
     * @dev Withdraw an amount of tokens from a proposal
     * @param _proposalId Proposal id
     * @param _amount Amount of withdrawn tokens
     * @param _from Account to withdraw from
     */
    function _withdrawFromProposal(uint256 _proposalId, uint256 _amount, address _from) internal {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voterStake[_from] >= _amount, ERROR_WITHDRAW_MORE_THAN_STAKED);
        require(_amount > 0, ERROR_AMOUNT_CAN_NOT_BE_ZERO);

        uint256 previousStake = proposal.stakedTokens;
        proposal.stakedTokens = proposal.stakedTokens.sub(_amount);
        proposal.voterStake[_from] = proposal.voterStake[_from].sub(_amount);
        totalVoterStake[_from] = totalVoterStake[_from].sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        if (proposal.voterStake[_from] == 0) {
            voterStakedProposals[_from].deleteItem(_proposalId);
        }

        if (proposal.proposalStatus == ProposalStatus.Active || proposal.proposalStatus == ProposalStatus.Paused) {
            _calculateAndSetConviction(proposal, previousStake);
        }

        emit StakeWithdrawn(_from, _proposalId, _amount, proposal.voterStake[_from], proposal.stakedTokens, proposal.convictionLast);
    }
}

pragma solidity ^0.4.24;


library ArrayUtils {
    function deleteItem(uint256[] storage self, uint256 item) internal returns (bool) {
        uint256 length = self.length;
        for (uint256 i = 0; i < length; i++) {
            if (self[i] == item) {
                uint256 newLength = self.length - 1;
                if (i != newLength) {
                    self[i] = self[newLength];
                }

                delete self[newLength];
                self.length = newLength;

                return true;
            }
        }
        return false;
    }

    function contains(uint256[] storage self, uint256 item) internal returns (bool) {
        for (uint256 i = 0; i < self.length; i++) {
            if (self[i] == item) {
                return true;
            }
        }
        return false;
    }
}

pragma solidity ^0.4.24;

contract IPriceOracle {
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}