/*
  Copyright 2017 Delphy Foundation.

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

//   /$$$$$$$            /$$           /$$
//  | $$__  $$          | $$          | $$
//  | $$  \ $$  /$$$$$$ | $$  /$$$$$$ | $$$$$$$  /$$   /$$
//  | $$  | $$ /$$__  $$| $$ /$$__  $$| $$__  $$| $$  | $$
//  | $$  | $$| $$$$$$$$| $$| $$  \ $$| $$  \ $$| $$  | $$
//  | $$  | $$| $$_____/| $$| $$  | $$| $$  | $$| $$  | $$
//  | $$$$$$$/|  $$$$$$$| $$| $$$$$$$/| $$  | $$|  $$$$$$$
//  |_______/  \_______/|__/| $$____/ |__/  |__/ \____  $$
//                          | $$                 /$$  | $$
//                          | $$                |  $$$$$$/
//                          |__/                 \______/

pragma solidity ^0.4.11;


/// @title Abstract token contract - Functions to be implemented by token contracts
contract Token {

    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint);

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
}

library Math {
    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}


/// @title Standard token contract with overflow protection
contract StandardToken is Token {
    using Math for *;

    /*
     *  Storage
     */
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowances;

    /*
     *  Public functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success
    /// @param to Address of token receiver
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transfer(address to, uint value)
        public
        returns (bool)
    {
        if (!balances[msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[msg.sender] -= value;
        balances[to] += value;
        Transfer(msg.sender, to, value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success
    /// @param from Address from where tokens are withdrawn
    /// @param to Address to where tokens are sent
    /// @param value Number of tokens to transfer
    /// @return Was transfer successful?
    function transferFrom(address from, address to, uint value)
        public
        returns (bool)
    {
        if (   !balances[from].safeToSub(value)
            || !allowances[from][msg.sender].safeToSub(value)
            || !balances[to].safeToAdd(value))
            return false;
        balances[from] -= value;
        allowances[from][msg.sender] -= value;
        balances[to] += value;
        Transfer(from, to, value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success
    /// @param spender Address of allowed account
    /// @param value Number of approved tokens
    /// @return Was approval successful?
    function approve(address spender, uint value)
        public
        returns (bool)
    {
        allowances[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

    /// @dev Returns number of allowed tokens for given address
    /// @param owner Address of token owner
    /// @param spender Address of token spender
    /// @return Remaining allowance for spender
    function allowance(address owner, address spender)
        public
        constant
        returns (uint)
    {
        return allowances[owner][spender];
    }

    /// @dev Returns number of tokens owned by given address
    /// @param owner Address of token owner
    /// @return Balance of owner
    function balanceOf(address owner)
        public
        constant
        returns (uint)
    {
        return balances[owner];
    }
}

/// @title Delphy Token contract
/// For Delphy ICO details: https://delphy.org/index.html#ICO
/// For Delphy Project: https://delphy.org
/// @author <span class="__cf_email__" data-cfemail="e58f9692a5818089958d9ccb8a9782">[email&#160;protected]</span>
contract DelphyToken is StandardToken {
    /*
     *  Constants
     */

    string constant public name = "Delphy Token";
    string constant public symbol = "DPY";
    uint8 constant public decimals = 18;

    /// Delphy token total supply
    uint public constant TOTAL_TOKENS = 100000000 * 10**18; // 1e

    /*
     *  Public functions
     */

    /// @dev Initialization of the Delphy Token contract
    /// @param owners is the addresses of Delphy token distribution
    /// @param tokens is the token number of Delphy token distribution
    function DelphyToken(address[] owners, uint[] tokens)
        public
    {
        totalSupply = 0;

        for (uint i=0; i<owners.length; i++) {
            require (owners[i] != 0);

            balances[owners[i]] += tokens[i];
            Transfer(0, owners[i], tokens[i]);
            totalSupply += tokens[i];
        }

        require (totalSupply == TOTAL_TOKENS);
    }
}