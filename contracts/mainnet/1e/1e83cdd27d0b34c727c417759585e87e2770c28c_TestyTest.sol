/*
file:   TestyTestTest.sol
ver:    0.0.1_deploy
author: peter godbolt
date:   15-Mar-2018
email:  peter AT TestyTest.tech
(c) Peter Godbolt, based on the fine work of Darryl Morris 2018, 2017

Testing of an ERC20 Token, backed by a regulated financial product in Australia. Nice.

License
-------
This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
* way we go

Dedications
-------------
* to Tom Waits, Taylor Swift and Jo Jo Siwa
*/


pragma solidity ^0.4.17;


contract TestyTestConfig
{
    // ERC20 token name
    string  public constant name            = "TESTY";

    // ERC20 trading symbol
    string  public constant symbol          = "TST";

    // Contract owner at time of deployment.
    address public constant OWNER           = 0x8579A678Fc76cAe308ca280B58E2b8f2ddD41913;

    // Opening Supply
    uint    public constant TOTAL_TOKENS    = 100;

    // ERC20 decimal places
    uint8   public constant decimals        = 18;


}


library SafeMath
{
    // a add to b
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }

    // a subtract b
    function sub(uint a, uint b) internal pure returns (uint c) {
        c = a - b;
        assert(c <= a);
    }

    // a multiplied by b
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    // a divided by b
    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b != 0);
        c = a / b;
    }
}


contract ReentryProtected
{
    // The reentry protection state mutex.
    bool __reMutex;

    // Sets and clears mutex in order to block function reentry
    modifier preventReentry() {
        require(!__reMutex);
        __reMutex = true;
        _;
        delete __reMutex;
    }

    // Blocks function entry if mutex is set
    modifier noReentry() {
        require(!__reMutex);
        _;
    }
}


contract ERC20Token
{
    using SafeMath for uint;

/* Constants */

    // none

/* State variable */

    /// @return The Total supply of tokens
    uint public totalSupply;

    /// @return Tokens owned by an address
    mapping (address => uint) balances;

    /// @return Tokens spendable by a thridparty
    mapping (address => mapping (address => uint)) allowed;

/* Events */

    // Triggered when tokens are transferred.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _amount);

    // Triggered whenever approve(address _spender, uint256 _amount) is called.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount);

/* Modifiers */

    // none

/* Functions */

    // Using an explicit getter allows for function overloading
    function balanceOf(address _addr)
        public
        view
        returns (uint)
    {
        return balances[_addr];
    }

    // Quick checker on total supply
    function currentSupply()
        public
        view
        returns (uint)
    {
        return totalSupply;
    }


    // Using an explicit getter allows for function overloading
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _amount)
        public
        returns (bool)
    {
        return xfer(msg.sender, _to, _amount);
    }

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool)
    {
        require(_amount <= allowed[_from][msg.sender]);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        return xfer(_from, _to, _amount);
    }

    // Process a transfer internally.
    function xfer(address _from, address _to, uint _amount)
        internal
        returns (bool)
    {
        require(_amount <= balances[_from]);

        emit Transfer(_from, _to, _amount);

        // avoid wasting gas on 0 token transfers
        if(_amount == 0) return true;

        balances[_from] = balances[_from].sub(_amount);
        balances[_to]   = balances[_to].add(_amount);

        return true;
    }

    // Approves a third-party spender
    function approve(address _spender, uint256 _amount)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
}



contract TestyTestAbstract
{

    /// @dev Logged when new owner accepts ownership
    /// @param _from the old owner address
    /// @param _to the new owner address
    event ChangedOwner(address indexed _from, address indexed _to);

    /// @dev Logged when owner initiates a change of ownership
    /// @param _to the new owner address
    event ChangeOwnerTo(address indexed _to);

    /// @dev Logged KYC against an address
    /// @param _addr Address to set or clear KYC flag
    /// @param _kyc A boolean flag
    event Kyc(address indexed _addr, bool _kyc);

// State Variables
//

    /// @dev An address permissioned to enact owner restricted functions
    /// @return owner
    address public owner;

    /// @dev An address permissioned to take ownership of the contract
    /// @return new owner address
    address public newOwner;

    /// @returns KYC flag for an address
    mapping (address => bool) public clearedKyc;

//
// Modifiers
//

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

//
// Function Abstracts
//


    /// @notice Clear the KYC flags for an array of addresses to allow tokens
    /// transfers
    function clearKyc(address[] _addrs) public returns (bool);

    /// @notice Make bulk transfer of tokens to many addresses
    /// @param _addrs An array of recipient addresses
    /// @param _amounts An array of amounts to transfer to respective addresses
    /// @return Boolean success value
    function transferToMany(address[] _addrs, uint[] _amounts)
        public returns (bool);

    /// @notice Salvage `_amount` tokens at `_kaddr` and send them to `_to`
    /// @param _kAddr An ERC20 contract address
    /// @param _to and address to send tokens
    /// @param _amount The number of tokens to transfer
    /// @return Boolean success value
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public returns (bool);
}


/*-----------------------------------------------------------------------------\

TestyTest implementation

\*----------------------------------------------------------------------------*/

contract TestyTest is
    ReentryProtected,
    ERC20Token,
    TestyTestAbstract,
    TestyTestConfig
{
    using SafeMath for uint;

//
// Constants
//

    // Token fixed point for decimal places
    uint constant TOKEN = uint(10)**decimals;


//
// Functions
//

    function TestyTest()
        public
    {

        owner = OWNER;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);
        balances[owner] = totalSupply;

    }

    // Default function.
    function ()
        public
        payable
    {
        // empty, could do stuff
    }


//
// Manage supply
//

event LowerSupply(address indexed burner, uint256 value);
event IncreaseSupply(address indexed burner, uint256 value);

    /**
     * @dev lowers the supply by a specified amount of tokens.
     * @param _value The amount of tokens to lower the supply by.
     */

    function lowerSupply(uint256 _value)
        public
        onlyOwner
        preventReentry() {
            require(_value > 0);
            address burner = 0x41CaE184095c5DAEeC5B2b2901D156a029B3dAC6;
            balances[burner] = balances[burner].sub(_value);
            totalSupply = totalSupply.sub(_value);
            emit LowerSupply(msg.sender, _value);
    }

    function increaseSupply(uint256 _value)
        public
        onlyOwner
        preventReentry() {
            require(_value > 0);
            totalSupply = totalSupply.add(_value);
            emit IncreaseSupply(msg.sender, _value);
    }

//
//  clear KYC onchain
//

    function clearKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            clearedKyc[_addrs[i]] = true;
            emit Kyc(_addrs[i], true);
        }
        return true;
    }

//
//  re-instate KYC onchain, should circumstances change
//

    function requireKyc(address[] _addrs)
        public
        noReentry
        onlyOwner
        returns (bool)
    {
        uint len = _addrs.length;
        for(uint i; i < len; i++) {
            delete clearedKyc[_addrs[i]];
            emit Kyc(_addrs[i], false);
        }
        return true;
    }


//
// ERC20 additional functions
//

    // Allows a sender to transfer tokens to an array of recipients
    function transferToMany(address[] _addrs, uint[] _amounts)
        public
        noReentry
        returns (bool)
    {
        require(_addrs.length == _amounts.length);
        uint len = _addrs.length;
        for(uint i = 0; i < len; i++) {
            xfer(msg.sender, _addrs[i], _amounts[i]);
        }
        return true;
    }

   // Overload placeholder - could apply further logic
    function xfer(address _from, address _to, uint _amount)
        internal
        noReentry
        returns (bool)
    {
        super.xfer(_from, _to, _amount);
        return true;
    }

//
// Contract management functions
//

    // Initiate a change of owner to `_owner`
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        emit ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }

    // Finalise change of ownership to newOwner
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        emit ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
    }


    // Owner can salvage ERC20 tokens that may have been sent to the account
    function transferExternalToken(address _kAddr, address _to, uint _amount)
        public
        onlyOwner
        preventReentry
        returns (bool)
    {
        require(ERC20Token(_kAddr).transfer(_to, _amount));
        return true;
    }


}