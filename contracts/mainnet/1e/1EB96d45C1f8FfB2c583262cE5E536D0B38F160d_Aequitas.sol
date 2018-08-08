pragma solidity ^0.4.11;
/*
 * The MIT License (MIT)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE
*/


// A base contract that implements the following concepts:
// 1. A smart contract with an owner
// 2. Methods that can only be called by the owner
// 3. Transferability of ownership
contract Owned {
    // The address of the owner
    address public owner;

    // Constructor
    function Owned() {
        owner = msg.sender;
    }

    // A modifier that provides a pre-check as to whether the sender is the owner
    modifier _onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    // Transfers ownership to newOwner, given that the sender is the owner
    function transferOwnership(address newOwner) _onlyOwner {
        owner = newOwner;
    }
}

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract Token is Owned {
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

// Implementation of Token contract
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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



/*
This Token Contract implements the standard token functionality (https://github.com/ethereum/EIPs/issues/20) as well as the following OPTIONAL extras intended for use by humans.

In other words. This is intended for deployment in something like a Token Factory or Mist wallet, and then used by humans.
Imagine coins, currencies, shares, voting weight, etc.
Machine-based, rapid creation of many tokens would not necessarily need these extra features or will be minted in other manners.

1) Initial Finite Supply (upon creation one specifies how much is minted).
2) In the absence of a token registry: Optional Decimal, Symbol & Name.
3) Optional approveAndCall() functionality to notify a contract if an approval() has occurred.

.*/
contract HumanStandardToken is StandardToken {

    function() {
        //if ether is sent to this address, send it back.
        revert();
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = &#39;H0.1&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.

    function HumanStandardToken(uint256 _initialAmount, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) {
        balances[msg.sender] = _initialAmount;
        // Give the creator all initial tokens
        totalSupply = _initialAmount;
        // Update total supply
        name = _tokenName;
        // Set the name for display purposes
        decimals = _decimalUnits;
        // Amount of decimals for display purposes
        symbol = _tokenSymbol;
        // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {revert();}
        return true;
    }
}



contract CapitalMiningToken is HumanStandardToken {

    /* Public variables of the token */

    // Vanity variables
    uint256 public simulatedBlockNumber;

    uint256 public rewardScarcityFactor; // The factor by which the reward reduces
    uint256 public rewardReductionRate; // The number of blocks before the reward reduces

    // Reward related variables
    uint256 public blockInterval; // Simulate intended blocktime of BitCoin
    uint256 public rewardValue; // 50 units, to 8 decimal places
    uint256 public initialReward; // Assignment of initial reward

    // Payout related variables
    mapping (address => Account) public pendingPayouts; // Keep track of per-address contributions in this reward block
    mapping (uint => uint) public totalBlockContribution; // Keep track of total ether contribution per block
    mapping (uint => bool) public minedBlock; // Checks if block is mined

    // contains all variables required to disburse AQT to a contributor fairly
    struct Account {
        address addr;
        uint blockPayout;
        uint lastContributionBlockNumber;
        uint blockContribution;
    }

    uint public timeOfLastBlock; // Variable to keep track of when rewards were given

    // Constructor
    function CapitalMiningToken(string _name, uint8 _decimals, string _symbol, string _version,
    uint256 _initialAmount, uint _simulatedBlockNumber, uint _rewardScarcityFactor,
    uint _rewardHalveningRate, uint _blockInterval, uint _rewardValue)
    HumanStandardToken(_initialAmount, _name, _decimals, _symbol) {
        version = _version;
        simulatedBlockNumber = _simulatedBlockNumber;
        rewardScarcityFactor = _rewardScarcityFactor;
        rewardReductionRate = _rewardHalveningRate;
        blockInterval = _blockInterval;
        rewardValue = _rewardValue;
        initialReward = _rewardValue;
        timeOfLastBlock = now;
    }

    // function to call to contribute Ether to, in exchange for AQT in the next block
    // mine or updateAccount must be called at least 10 minutes from timeOfLastBlock to get the reward
    // minimum required contribution is 0.05 Ether
    function mine() payable _updateBlockAndRewardRate() _updateAccount() {
        // At this point it is safe to assume that the sender has received all his payouts for previous blocks
        require(msg.value >= 50 finney);
        totalBlockContribution[simulatedBlockNumber] += msg.value;
        // Update total contribution

        if (pendingPayouts[msg.sender].addr != msg.sender) {// If the sender has not contributed during this interval
            // Add his address and payout details to the contributor map
            pendingPayouts[msg.sender] = Account(msg.sender, rewardValue, simulatedBlockNumber,
            pendingPayouts[msg.sender].blockContribution + msg.value);
            minedBlock[simulatedBlockNumber] = true;
        }
        else {// the sender has contributed during this interval
            require(pendingPayouts[msg.sender].lastContributionBlockNumber == simulatedBlockNumber);
            pendingPayouts[msg.sender].blockContribution += msg.value;
        }
        return;
    }

    modifier _updateBlockAndRewardRate() {
        // Stop update if the time since last block is less than specified interval
        if ((now - timeOfLastBlock) >= blockInterval && minedBlock[simulatedBlockNumber] == true) {
            timeOfLastBlock = now;
            simulatedBlockNumber += 1;
            // update reward according to block number
            rewardValue = initialReward / (2 ** (simulatedBlockNumber / rewardReductionRate)); // 後で梨沙ちゃんと中本さんに見てもらったほうがいい( &#180;∀｀ )
            // 毎回毎回計算するよりsimulatedBlockNumber%rewardReductionRateみたいな条件でやったらトランザクションが安くなりそう
        }
        _;
    }

    modifier _updateAccount() {
        if (pendingPayouts[msg.sender].addr == msg.sender && pendingPayouts[msg.sender].lastContributionBlockNumber < simulatedBlockNumber) {
            // もうブロックチェーンにのっているからやり直せないがこれ気持ち悪くない？
            uint payout = pendingPayouts[msg.sender].blockContribution * pendingPayouts[msg.sender].blockPayout / totalBlockContribution[pendingPayouts[msg.sender].lastContributionBlockNumber]; //　これ分かりづらいから時間あれば分けてやって
            pendingPayouts[msg.sender] = Account(0, 0, 0, 0);
            // mint coins
            totalSupply += payout;
            balances[msg.sender] += payout;
            // broadcast transfer event to owner
            Transfer(0, owner, payout);
            // broadcast transfer event from owner to payee
            Transfer(owner, msg.sender, payout);
        }
        _;
    }

    function updateAccount() _updateBlockAndRewardRate() _updateAccount() {}

    function withdrawEther() _onlyOwner() {
        owner.transfer(this.balance);
    }
}

// This contract defines specific parameters that make the initialized coin Bitcoin-like
contract Aequitas is CapitalMiningToken {
    // Constructor
    function Aequitas() CapitalMiningToken(
            "Aequitas",             // name
            8,                      // decimals
            "AQT",                  // symbol
            "0.1",                  // version
            0,                      // initialAmount
            0,                      // simulatedBlockNumber
            2,                      // rewardScarcityFactor
            210000,                 // rewardReductionRate
            10 minutes,             // blockInterval
            5000000000              // rewardValue
    ){}
}