/**
 * Copyright (C) Siousada.io
 * All rights reserved.
 * Author: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="89e0e7efe6c9fae0e6fcfae8ede8a7e0e6">[email&#160;protected]</a>
 *
 * This code is adapted from OpenZeppelin Project.
 * more at http://openzeppelin.org.
 *
 * MIT License
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy 
 * of this software and associated documentation files (the ""Software""), to 
 * deal in the Software without restriction, including without limitation the 
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
 * sell copies of the Software, and to permit persons to whom the Software is 
 * furnished to do so, subject to the following conditions: 
 *  The above copyright notice and this permission notice shall be included in 
 *  all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
 * THE SOFTWARE.
 *
 */
pragma solidity ^0.4.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Guarded {

    modifier isValidAmount(uint256 _amount) { 
        require(_amount > 0); 
        _; 
    }

    // ensure address not null, and not this contract address
    modifier isValidAddress(address _address) {
        require(_address != 0x0 && _address != address(this));
        _;
    }

}

contract Ownable {
    address public owner;

    /** 
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner. 
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to. 
     */
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Claimable is Ownable {
    address public pendingOwner;

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner. 
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address. 
     * @param newOwner The address to transfer ownership to. 
     */
    function transferOwnership(address newOwner) onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = 0x0;
    }
}

contract ERC20 {
    
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

contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    string public standard = &#39;Cryptoken 0.1.1&#39;;

    string public name = &#39;&#39;;            // the token name
    string public symbol = &#39;&#39;;          // the token symbol
    uint8 public decimals = 0;          // the number of decimals

    // mapping of our users to balance
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    // our constructor. We have fixed everything above, and not as 
    // parameters in the constructor.
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    // get token balance
    function balanceOf(address _owner) 
        public constant 
        returns (uint256 balance) 
    {
        return balances[_owner];
    }    

    /**
     * make a transfer. This can be called from the token holder.
     * e.g. Token holder Alice, can issue somethign like this to Bob
     *      Alice.transfer(Bob, 200);     // to transfer 200 to Bob
     */
    /// Initiate a transfer to `_to` with value `_value`?
    function transfer(address _to, uint256 _value) 
        public returns (bool success) 
    {
        // sanity check
        require(_to != address(this));

        // // check for overflows
        // require(_value > 0 &&
        //   balances[msg.sender] < _value &&
        //   balances[_to] + _value < balances[_to]);

        // 
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        // emit transfer event
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * make an approved transfer to another account from vault. This operation
     * should be called after approved operation below.
     * .e.g Alice allow Bob to spend 30 by doing:
     *      Alice.approve(Bob, 30);                 // allow 30 to Bob
     *
     * and Bob can claim, say 10, from that by doing
     *      Bob.transferFrom(Alice, Bob, 10);       // spend only 10
     * and Bob&#39;s balance shall be 20 in the allowance.
     */
    /// Initiate a transfer of `_value` from `_from` to `_to`
    function transferFrom(address _from, address _to, uint256 _value)         
        public returns (bool success) 
    {    
        // sanity check
        require(_to != 0x0 && _from != 0x0);
        require(_from != _to && _to != address(this));

        // check for overflows
        // require(_value > 0 &&
        //   balances[_from] >= _value &&
        //   allowed[_from][_to] <= _value &&
        //   balances[_to] + _value < balances[_to]);

        // update public balance
        allowed[_from][_to] = allowed[_from][_to].sub(_value);        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        // emit transfer event
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * This method is explained further in https://goo.gl/iaqxBa on the
     * possible attacks. As such, we have to make sure the value is
     * drained, before any Alice/Bob can approve each other to
     * transfer on their behalf.
     * @param _spender  - the recipient of the value
     * @param _value    - the value allowed to be spent 
     *
     * This can be called by the token holder
     * e.g. Alice can allow Bob to spend 30 on her behalf
     *      Alice.approve(Bob, 30);     // gives 30 to Bob.
     */
    /// Approve `_spender` to claim/spend `_value`?
    function approve(address _spender, uint256 _value)          
        public returns (bool success) 
    {
        // sanity check
        require(_spender != 0x0 && _spender != address(this));            

        // if the allowance isn&#39;t 0, it can only be updated to 0 to prevent 
        // an allowance change immediately after withdrawal
        require(allowed[msg.sender][_spender] == 0);

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Check the allowance that has been approved previously by owner.
     */
    /// check allowance approved from `_owner` to `_spender`?
    function allowance(address _owner, address _spender)          
        public constant returns (uint remaining) 
    {
        // sanity check
        require(_spender != 0x0 && _owner != 0x0);
        require(_owner != _spender && _spender != address(this));            

        // constant op. Just return the balance.
        return allowed[_owner][_spender];
    }

}

contract SSDToken is ERC20Token, Guarded, Claimable {

    uint256 public SUPPLY = 1000000000 ether;   // 1b ether;

    // our constructor, just supply the total supply.
    function SSDToken() 
        ERC20Token(&#39;SIOUSADA&#39;, &#39;SSD&#39;, 18) 
    {
        totalSupply = SUPPLY;
        balances[msg.sender] = SUPPLY;
    }

}