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

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

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


/// @title Mid-Team Holding Incentive Program
/// @author Daniel Wang - <<span class="__cf_email__" data-cfemail="593d3837303c3519353636292b30373e77362b3e">[email&#160;protected]</span>>, Kongliang Zhong - <<span class="__cf_email__" data-cfemail="ff9490919893969e9198bf9390908f8d969198d1908d98">[email&#160;protected]</span>>.
/// For more information, please visit https://loopring.org.
contract LRCMidTermHoldingContract {
    using SafeMath for uint;
    using Math for uint;

    // During the first 60 days of deployment, this contract opens for deposit of LRC
    // in exchange of ETH.
    uint public constant DEPOSIT_WINDOW                 = 60 days;

    // For each address, its LRC can only be withdrawn between 180 and 270 days after LRC deposit,
    // which means:
    //    1) LRC are locked during the first 180 days,
    //    2) LRC will be sold to the `owner` with the specified `RATE` 270 days after the deposit.
    uint public constant WITHDRAWAL_DELAY               = 180 days;
    uint public constant WITHDRAWAL_WINDOW              = 90  days;

    uint public constant MAX_LRC_DEPOSIT_PER_ADDRESS    = 150000 ether; // = 20 ETH * 7500

    // 7500 LRC for 1 ETH. This is the best token sale rate ever.
    uint public constant RATE       = 7500;

    address public lrcTokenAddress  = 0x0;
    address public owner            = 0x0;

    // Some stats
    uint public lrcReceived         = 0;
    uint public lrcSent             = 0;
    uint public ethReceived         = 0;
    uint public ethSent             = 0;

    uint public depositStartTime    = 0;
    uint public depositStopTime     = 0;

    bool public closed              = false;

    struct Record {
        uint lrcAmount;
        uint timestamp;
    }

    mapping (address => Record) records;

    /*
     * EVENTS
     */
    /// Emitted when program starts.
    event Started(uint _time);

    /// Emitted for each sucuessful deposit.
    uint public depositId = 0;
    event Deposit(uint _depositId, address indexed _addr, uint _ethAmount, uint _lrcAmount);

    /// Emitted for each sucuessful withdrawal.
    uint public withdrawId = 0;
    event Withdrawal(uint _withdrawId, address indexed _addr, uint _ethAmount, uint _lrcAmount);

    /// Emitted when this contract is closed.
    event Closed(uint _ethAmount, uint _lrcAmount);

    /// Emitted when ETH are drained.
    event Drained(uint _ethAmount);

    /// CONSTRUCTOR
    /// @dev Initialize and start the contract.
    /// @param _lrcTokenAddress LRC ERC20 token address
    /// @param _owner Owner of this contract
    function LRCMidTermHoldingContract(address _lrcTokenAddress, address _owner) {
        require(_lrcTokenAddress != address(0));
        require(_owner != address(0));

        lrcTokenAddress = _lrcTokenAddress;
        owner = _owner;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    /// @dev Get back ETH to `owner`.
    /// @param ethAmount Amount of ETH to drain back to owner
    function drain(uint ethAmount) public payable {
        require(!closed);
        require(msg.sender == owner);

        uint amount = ethAmount.min256(this.balance);
        require(amount > 0);
        owner.transfer(amount);

        Drained(amount);
    }

    /// @dev Set depositStartTime
    function start() public {
        require(msg.sender == owner);
        require(depositStartTime == 0);

        depositStartTime = now;
        depositStopTime  = now + DEPOSIT_WINDOW;

        Started(depositStartTime);
    }

    /// @dev Get all ETH and LRC back to `owner`.
    function close() public payable {
        require(!closed);
        require(msg.sender == owner);
        require(now > depositStopTime + WITHDRAWAL_DELAY + WITHDRAWAL_WINDOW);

        uint ethAmount = this.balance;
        if (ethAmount > 0) {
            owner.transfer(ethAmount);
        }

        var lrcToken = Token(lrcTokenAddress);
        uint lrcAmount = lrcToken.balanceOf(address(this));
        if (lrcAmount > 0) {
            require(lrcToken.transfer(owner, lrcAmount));
        }

        closed = true;
        Closed(ethAmount, lrcAmount);
    }

    /// @dev This default function allows simple usage.
    function () payable {
        require(!closed);

        if (msg.sender != owner) {
            if (now <= depositStopTime) depositLRC();
            else withdrawLRC();
        }
    }


    /// @dev Deposit LRC for ETH.
    /// If user send x ETH, this method will try to transfer `x * 100 * 6500` LRC from
    /// the user&#39;s address and send `x * 100` ETH to the user.
    function depositLRC() payable {
        require(!closed && msg.sender != owner);
        require(now <= depositStopTime);
        require(msg.value == 0);

        var record = records[msg.sender];
        var lrcToken = Token(lrcTokenAddress);

        uint lrcAmount = this.balance.mul(RATE)
            .min256(lrcToken.balanceOf(msg.sender))
            .min256(lrcToken.allowance(msg.sender, address(this)))
            .min256(MAX_LRC_DEPOSIT_PER_ADDRESS - record.lrcAmount);

        uint ethAmount = lrcAmount.div(RATE);
        lrcAmount = ethAmount.mul(RATE);

        require(lrcAmount > 0 && ethAmount > 0);

        record.lrcAmount += lrcAmount;
        record.timestamp = now;
        records[msg.sender] = record;

        lrcReceived += lrcAmount;
        ethSent += ethAmount;


        Deposit(
                depositId++,
                msg.sender,
                ethAmount,
                lrcAmount
                );
        require(lrcToken.transferFrom(msg.sender, address(this), lrcAmount));
        msg.sender.transfer(ethAmount);
    }

    /// @dev Withdrawal LRC with ETH transfer.
    function withdrawLRC() payable {
        require(!closed && msg.sender != owner);
        require(now > depositStopTime);
        require(msg.value > 0);

        var record = records[msg.sender];
        require(now >= record.timestamp + WITHDRAWAL_DELAY);
        require(now <= record.timestamp + WITHDRAWAL_DELAY + WITHDRAWAL_WINDOW);

        uint ethAmount = msg.value.min256(record.lrcAmount.div(RATE));
        uint lrcAmount = ethAmount.mul(RATE);

        record.lrcAmount -= lrcAmount;
        if (record.lrcAmount == 0) {
            delete records[msg.sender];
        } else {
            records[msg.sender] = record;
        }

        lrcSent += lrcAmount;
        ethReceived += ethAmount;

        Withdrawal(
                   withdrawId++,
                   msg.sender,
                   ethAmount,
                   lrcAmount
                   );

        require(Token(lrcTokenAddress).transfer(msg.sender, lrcAmount));

        uint ethRefund = msg.value - ethAmount;
        if (ethRefund > 0) {
            msg.sender.transfer(ethRefund);
        }
    }

    function getLRCAmount(address addr) public constant returns (uint) {
        return records[addr].lrcAmount;
    }

    function getTimestamp(address addr) public constant returns (uint) {
        return records[addr].timestamp;
    }
}