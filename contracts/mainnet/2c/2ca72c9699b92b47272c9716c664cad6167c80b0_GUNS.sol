pragma solidity ^0.4.11;

/*
    Copyright 2017, Shaun Shull

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

/// @title GUNS Crowdsale Contract - GeoFounders.com
/// @author Shaun Shull
/// @dev Simple single crowdsale contract for fixed supply, single-rate, 
///  block-range crowdsale. Additional token cleanup functionality.


/// @dev Generic ERC20 Token Interface, totalSupply made to var for compiler
contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/// @dev ERC20 Standard Token Contract
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


/// @dev Primary Token Contract
contract GUNS is StandardToken {

    // metadata
    string public constant name = "GeoUnits";
    string public constant symbol = "GUNS";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public hostAccount;       // address that kicks off the crowdsale
    address public ethFundDeposit;    // deposit address for ETH for GeoFounders
    address public gunsFundDeposit;   // deposit address for GeoFounders Tokens - GeoUnits (GUNS)

    // crowdsale parameters
    bool public isFinalized;                                                      // false until crowdsale finalized
    uint256 public fundingStartBlock;                                             // start block
    uint256 public fundingEndBlock;                                               // end block
    uint256 public constant gunsFund = 35 * (10**6) * 10**decimals;               // 35m GUNS reserved for devs
    uint256 public constant tokenExchangeRate = 1000;                             // 1000 GUNS per 1 ETH
    uint256 public constant tokenCreationCap =  100 * (10**6) * 10**decimals;     // 100m GUNS fixed supply
    uint256 public constant tokenCreationMin =  1 * (10**6) * 10**decimals;       // 1m minimum must be in supply (legacy code)

    // events
    event LogRefund(address indexed _to, uint256 _value);   // event for refund
    event CreateGUNS(address indexed _to, uint256 _value);  // event for token creation

    // safely add
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    // safely subtract
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    // safely multiply
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    // constructor
    function GUNS() {}

    // initialize deployed contract
    function initialize(
        address _ethFundDeposit,
        address _gunsFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock
    ) public {
        require(address(hostAccount) == 0x0);     // one time initialize
        hostAccount = msg.sender;                 // assign initializer var
        isFinalized = false;                      // crowdsale state
        ethFundDeposit = _ethFundDeposit;         // set final ETH deposit address
        gunsFundDeposit = _gunsFundDeposit;       // set final GUNS dev deposit address
        fundingStartBlock = _fundingStartBlock;   // block number to start crowdsale
        fundingEndBlock = _fundingEndBlock;       // block number to end crowdsale
        totalSupply = gunsFund;                   // update totalSupply to reserve
        balances[gunsFundDeposit] = gunsFund;     // deposit reserve tokens to dev address
        CreateGUNS(gunsFundDeposit, gunsFund);    // logs token creation event
    }

    // enable people to pay contract directly
    function () public payable {
        require(address(hostAccount) != 0x0);                      // initialization check

        if (isFinalized) throw;                                    // crowdsale state check
        if (block.number < fundingStartBlock) throw;               // within start block check
        if (block.number > fundingEndBlock) throw;                 // within end block check
        if (msg.value == 0) throw;                                 // person actually sent ETH check

        uint256 tokens = safeMult(msg.value, tokenExchangeRate);   // calculate num of tokens purchased
        uint256 checkedSupply = safeAdd(totalSupply, tokens);      // calculate total supply if purchased

        if (tokenCreationCap < checkedSupply) throw;               // if exceeding token max, cancel order

        totalSupply = checkedSupply;                               // update totalSupply
        balances[msg.sender] += tokens;                            // update token balance for payer
        CreateGUNS(msg.sender, tokens);                            // logs token creation event
    }

    // generic function to pay this contract
    function emergencyPay() external payable {}

    // wrap up crowdsale after end block
    function finalize() external {
        //if (isFinalized) throw;                                                        // check crowdsale state is false
        if (msg.sender != ethFundDeposit) throw;                                         // check caller is ETH deposit address
        //if (totalSupply < tokenCreationMin) throw;                                     // check minimum is met
        if (block.number <= fundingEndBlock && totalSupply < tokenCreationCap) throw;    // check past end block unless at creation cap

        if (!ethFundDeposit.send(this.balance)) throw;                                   // send account balance to ETH deposit address
        
        uint256 remainingSupply = safeSubtract(tokenCreationCap, totalSupply);           // calculate remaining tokens to reach fixed supply
        if (remainingSupply > 0) {                                                       // if remaining supply left
            uint256 updatedSupply = safeAdd(totalSupply, remainingSupply);               // calculate total supply with remaining supply
            totalSupply = updatedSupply;                                                 // update totalSupply
            balances[gunsFundDeposit] += remainingSupply;                                // manually update devs token balance
            CreateGUNS(gunsFundDeposit, remainingSupply);                                // logs token creation event
        }

        isFinalized = true;                                                              // update crowdsale state to true
    }

    // legacy code to enable refunds if min token supply not met (not possible with fixed supply)
    function refund() external {
        if (isFinalized) throw;                               // check crowdsale state is false
        if (block.number <= fundingEndBlock) throw;           // check crowdsale still running
        if (totalSupply >= tokenCreationMin) throw;           // check creation min was not met
        if (msg.sender == gunsFundDeposit) throw;             // do not allow dev refund

        uint256 gunsVal = balances[msg.sender];               // get callers token balance
        if (gunsVal == 0) throw;                              // check caller has tokens

        balances[msg.sender] = 0;                             // set callers tokens to zero
        totalSupply = safeSubtract(totalSupply, gunsVal);     // subtract callers balance from total supply
        uint256 ethVal = gunsVal / tokenExchangeRate;         // calculate ETH from token exchange rate
        LogRefund(msg.sender, ethVal);                        // log refund event

        if (!msg.sender.send(ethVal)) throw;                  // send caller their refund
    }

    // clean up mistaken tokens sent to this contract
    // also check empty address for tokens and clean out
    // (GUNS only, does not support 3rd party tokens)
    function mistakenTokens() external {
        if (msg.sender != ethFundDeposit) throw;                // check caller is ETH deposit address
        
        if (balances[this] > 0) {                               // if contract has tokens
            Transfer(this, gunsFundDeposit, balances[this]);    // log transfer event
            balances[gunsFundDeposit] += balances[this];        // send tokens to dev tokens address
            balances[this] = 0;                                 // zero out contract token balance
        }

        if (balances[0x0] > 0) {                                // if empty address has tokens
            Transfer(0x0, gunsFundDeposit, balances[0x0]);      // log transfer event
            balances[gunsFundDeposit] += balances[0x0];         // send tokens to dev tokens address
            balances[0x0] = 0;                                  // zero out empty address token balance
        }
    }

}