/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

/**
 *Submitted for verification at Etherscan.io on 2018-01-17
*/

pragma solidity ^0.4.19;

/*
    Copyright 2016, Jordi Baylina
    Contributor: Adrià Massanet <[email protected]>

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
    
    
    This is just some extra garbage to check about comments
*/
/// Add an extra comment here see if I care
/// @title Owned
/// @author Adrià Massanet <[email protected]>
/// @notice The Owned contract has an owner address, and provides basic 
///  authorization control functions, this simplifies & the implementation of
///  user permissions; this contract has three work flows for a change in
///  ownership, the first requires the new owner to validate that they have the
///  ability to accept ownership, the second allows the ownership to be
///  directly transfered without requiring acceptance, and the third allows for
///  the ownership to be removed to allow for decentralization 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

    /// @dev The constructor sets the `msg.sender` as the`owner` of the contract
    function Owned() public {
        owner = msg.sender;
    }

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    /// @dev In this 1st option for ownership transfer `proposeOwnership()` must
    ///  be called first by the current `owner` then `acceptOwnership()` must be
    ///  called by the `newOwnerCandidate`
    /// @notice `onlyOwner` Proposes to transfer control of the contract to a
    ///  new owner
    /// @param _newOwnerCandidate The address being proposed as the new owner
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;
        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @notice Can only be called by the `newOwnerCandidate`, accepts the
    ///  transfer of ownership
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate);

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 2nd option for ownership transfer `changeOwnership()` can
    ///  be called and it will immediately assign ownership to the `newOwner`
    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        OwnershipTransferred(oldOwner, owner);
    }

    /// @dev In this 3rd option for ownership transfer `removeOwnership()` can
    ///  be called and it will immediately assign ownership to the 0x0 address;
    ///  it requires a 0xdece be input as a parameter to prevent accidental use
    /// @notice Decentralizes the contract, this operation cannot be undone 
    /// @param _dac `0xdac` has to be entered for this function to work
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac);
        owner = 0x0;
        newOwnerCandidate = 0x0;
        OwnershipRemoved();     
    }
} 



/**
 * @title ERC20
 * @dev A standard interface for tokens.
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
 */
contract ERC20 {
  
    /// @dev Returns the total token supply
    function totalSupply() public constant returns (uint256 supply);

    /// @dev Returns the account balance of the account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @dev Transfers _value number of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @dev Transfers _value number of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @dev Allows _spender to withdraw from the msg.sender's account up to the _value amount
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @dev Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


/// @dev `Escapable` is a base level contract built off of the `Owned`
///  contract; it creates an escape hatch function that can be called in an
///  emergency that will allow designated addresses to send any ether or tokens
///  held in the contract to an `escapeHatchDestination` as long as they were
///  not blacklisted
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist; // Token contract addresses

    /// @notice The Constructor assigns the `escapeHatchDestination` and the
    ///  `escapeHatchCaller`
    /// @param _escapeHatchCaller The address of a trusted account or contract
    ///  to call `escapeHatch()` to send the ether in this contract to the
    ///  `escapeHatchDestination` it would be ideal that `escapeHatchCaller`
    ///  cannot move funds out of `escapeHatchDestination`
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

    /// @dev The addresses preassigned as `escapeHatchCaller` or `owner`
    ///  are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

    /// @notice Creates the blacklist of tokens that are not able to be taken
    ///  out of the contract; can only be done at the deployment, and the logic
    ///  to add to the blacklist will be in the constructor of a child contract
    /// @param _token the token contract address that is to be blacklisted 
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

    /// @notice Checks to see if `_token` is in the blacklist of tokens
    /// @param _token the token address being queried
    /// @return False if `_token` is in the blacklist and can't be taken out of
    ///  the contract via the `escapeHatch()`
    function isTokenEscapable(address _token) constant public returns (bool) {
        return !escapeBlacklist[_token];
    }

    /// @notice The `escapeHatch()` should only be called as a last resort if a
    /// security issue is uncovered or something unexpected happened
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

        /// @dev Logic for ether
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller The address of a trusted account or
    ///  contract to call `escapeHatch()` to send the value in this contract to
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

// Copyright (C) 2018 Alon Bukai This program is free software: you 
// can redistribute it and/or modify it under the terms of the GNU General 
// Public License as published by the Free Software Foundation, version. 
// This program is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details. You should have received a copy of the GNU General Public
// License along with this program. If not, see http://www.gnu.org/licenses/

/// @notice `MultiSend` is a contract for sending multiple ETH/ERC20 Tokens to
///  multiple addresses. In addition this contract can call multiple contracts
///  with multiple amounts. There are also TightlyPacked functions which in
///  some situations allow for gas savings. TightlyPacked is cheaper if you
///  need to store input data and if amount is less than 12 bytes. Normal is
///  cheaper if you don't need to store input data or if amounts are greater
///  than 12 bytes. Supports deterministic deployment. As explained
///  here: https://github.com/ethereum/EIPs/issues/777#issuecomment-356103528
contract MultiSend is Escapable {
  
    /// @dev Hardcoded escapeHatchCaller
    address CALLER = 0x839395e20bbB182fa440d08F850E6c7A8f6F0780;
    /// @dev Hardcoded escapeHatchDestination
    address DESTINATION = 0x8ff920020c8ad673661c8117f2855c384758c572;

    event MultiTransfer(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );

    event MultiCall(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );

    event MultiERC20Transfer(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount,
        ERC20 _token
    );

    /// @notice Constructor using Escapable and Hardcoded values
    function MultiSend() Escapable(CALLER, DESTINATION) public {}

    /// @notice Send to multiple addresses using a byte32 array which
    ///  includes the address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array
    ///  Address is stored in the 20 most significant bytes
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer
    ///  Payable
    /// @param _addressesAndAmounts Bitwise packed array of addresses
    ///  and amounts
    function multiTransferTightlyPacked(bytes32[] _addressesAndAmounts)
    payable public returns(bool)
    {
        uint startBalance = this.balance;
        for (uint i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(_addressesAndAmounts[i] >> 96);
            uint amount = uint(uint96(_addressesAndAmounts[i]));
            _safeTransfer(to, amount);
            MultiTransfer(msg.sender, msg.value, to, amount);
        }
        require(startBalance - msg.value == this.balance);
        return true;
    }

    /// @notice Send to multiple addresses using two arrays which
    ///  includes the address and the amount.
    ///  Payable
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of amounts to send
    function multiTransfer(address[] _addresses, uint[] _amounts)
    payable public returns(bool)
    {
        uint startBalance = this.balance;
        for (uint i = 0; i < _addresses.length; i++) {
            _safeTransfer(_addresses[i], _amounts[i]);
            MultiTransfer(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }
        require(startBalance - msg.value == this.balance);
        return true;
    }

    /// @notice Call to multiple contracts using a byte32 array which
    ///  includes the contract address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array.
    ///  Address is stored in the 20 most significant bytes.
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes.
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer.
    ///  Payable
    /// @param _addressesAndAmounts Bitwise packed array of contract
    ///  addresses and amounts
    function multiCallTightlyPacked(bytes32[] _addressesAndAmounts)
    payable public returns(bool)
    {
        uint startBalance = this.balance;
        for (uint i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(_addressesAndAmounts[i] >> 96);
            uint amount = uint(uint96(_addressesAndAmounts[i]));
            _safeCall(to, amount);
            MultiCall(msg.sender, msg.value, to, amount);
        }
        require(startBalance - msg.value == this.balance);
        return true;
    }

    /// @notice Call to multiple contracts using two arrays which
    ///  includes the contract address and the amount.
    /// @param _addresses Array of contract addresses to call
    /// @param _amounts Array of amounts to send
    function multiCall(address[] _addresses, uint[] _amounts)
    payable public returns(bool)
    {
        uint startBalance = this.balance;
        for (uint i = 0; i < _addresses.length; i++) {
            _safeCall(_addresses[i], _amounts[i]);
            MultiCall(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }
        require(startBalance - msg.value == this.balance);
        return true;
    }

    /// @notice Send ERC20 tokens to multiple contracts 
    ///  using a byte32 array which includes the address and the amount.
    ///  Addresses and amounts are stored in a packed bytes32 array.
    ///  Address is stored in the 20 most significant bytes.
    ///  The address is retrieved by bitshifting 96 bits to the right
    ///  Amount is stored in the 12 least significant bytes.
    ///  The amount is retrieved by taking the 96 least significant bytes
    ///  and converting them into an unsigned integer.
    /// @param _token The token to send
    /// @param _addressesAndAmounts Bitwise packed array of addresses
    ///  and token amounts
    function multiERC20TransferTightlyPacked
    (
        ERC20 _token,
        bytes32[] _addressesAndAmounts
    ) public
    {
        for (uint i = 0; i < _addressesAndAmounts.length; i++) {
            address to = address(_addressesAndAmounts[i] >> 96);
            uint amount = uint(uint96(_addressesAndAmounts[i]));
            _safeERC20Transfer(_token, to, amount);
            MultiERC20Transfer(msg.sender, msg.value, to, amount, _token);
        }
    }

    /// @notice Send ERC20 tokens to multiple contracts
    ///  using two arrays which includes the address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiERC20Transfer(
        ERC20 _token,
        address[] _addresses,
        uint[] _amounts
    ) public
    {
        for (uint i = 0; i < _addresses.length; i++) {
            _safeERC20Transfer(_token, _addresses[i], _amounts[i]);
            MultiERC20Transfer(
                msg.sender,
                msg.value,
                _addresses[i],
                _amounts[i],
                _token
            );
        }
    }

    /// @notice `_safeTransfer` is used internally when transfer funds safely.
    function _safeTransfer(address _to, uint _amount) internal {
        require(_to != 0);
        _to.transfer(_amount);
    }

    /// @notice `_safeCall` is used internally when call a contract safely.
    function _safeCall(address _to, uint _amount) internal {
        require(_to != 0);
        require(_to.call.value(_amount)());
    }

    /// @notice `_safeERC20Transfer` is used internally when
    ///  transfer a quantity of ERC20 tokens.
    function _safeERC20Transfer(ERC20 _token, address _to, uint _amount)
    internal
    {
        require(_to != 0);
        require(_token.transferFrom(msg.sender, _to, _amount));
    }

    /// @dev Default payable function to not allow sending to contract;
    ///  remember this does not necesarily prevent the contract
    ///  from accumulating funds.
    function () public payable {
        revert();
    }
}