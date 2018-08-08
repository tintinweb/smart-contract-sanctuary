/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

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
pragma solidity ^0.4.11;

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
}

contract Token {
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


/// @title LRC Foundation Icebox Program
/// @author Daniel Wang - <<span class="__cf_email__" data-cfemail="0c686d626569604c6063637c7e65626b22637e6b">[email&#160;protected]</span>>.
/// For more information, please visit https://loopring.org.

/// Loopring Foundation&#39;s LRC (20% of total supply) will be locked during the first two years，
/// two years later, 1/24 of all locked LRC fund can be unlocked every month.

contract LRCFoundationIceboxContract {
    using SafeMath for uint;
    
    uint public constant FREEZE_PERIOD = 720 days; // = 2 years

    address public lrcTokenAddress  = 0x0;
    address public owner            = 0x0;

    uint public lrcInitialBalance   = 0;
    uint public lrcWithdrawn         = 0;
    uint public lrcUnlockPerMonth   = 0;
    uint public startTime           = 0;

    /* 
     * EVENTS
     */

    /// Emitted when program starts.
    event Started(uint _time);

    /// Emitted for each sucuessful deposit.
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, uint _lrcAmount);

    /// @dev Initialize the contract
    /// @param _lrcTokenAddress LRC ERC20 token address
    /// @param _owner Owner&#39;s address
    function LRCFoundationIceboxContract(address _lrcTokenAddress, address _owner) {
        require(_lrcTokenAddress != address(0));
        require(_owner != address(0));

        lrcTokenAddress = _lrcTokenAddress;
        owner = _owner;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev start the program.
    function start() public {
        require(msg.sender == owner);
        require(startTime == 0);

        lrcInitialBalance = Token(lrcTokenAddress).balanceOf(address(this));
        require(lrcInitialBalance > 0);

        lrcUnlockPerMonth = lrcInitialBalance.div(24); // 24 month
        startTime = now;

        Started(startTime);
    }


    function () payable {
        require(msg.sender == owner);
        require(msg.value == 0);
        require(startTime > 0);
        require(now > startTime + FREEZE_PERIOD);

        var token = Token(lrcTokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance > 0);

        uint lrcAmount = calculateLRCUnlockAmount(now, balance);
        if (lrcAmount > 0) {
            lrcWithdrawn += lrcAmount;

            Withdrawal(withdrawId++, lrcAmount);
            require(token.transfer(owner, lrcAmount));
        }
    }


    /*
     * INTERNAL FUNCTIONS
     */

    function calculateLRCUnlockAmount(uint _now, uint _balance) internal returns (uint lrcAmount) {
        uint unlockable = (_now - startTime - FREEZE_PERIOD)
            .div(30 days)
            .mul(lrcUnlockPerMonth) - lrcWithdrawn;

        require(unlockable > 0);

        if (unlockable > _balance) return _balance;
        else return unlockable;
    }

}