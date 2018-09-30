/*
file:   AUDR.sol
ver:    0.0.1_deploy
author: OnRamp Technologies Pty Ltd
date:   18-Sep-2018
email:  <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="394a4c4949564b4d7956574b585449174d5c5a51">[email&#160;protected]</a>

Licence
-------
(c) 2018 OnRamp Technologies Pty Ltd
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (Software), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the Software (or any combination of that), and to permit persons to whom the Software is furnished to do so, subject to the following fundamental conditions:
1. The above copyright notice and this permission notice must be included in all copies or substantial portions of the Software.
2. Subject only to the extent to which applicable law cannot be excluded, modified or limited:
2.1	The Software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and non-infringement of third party rights.
2.2	In no event will the authors, copyright holders or other persons in any way associated with any of them be liable for any claim, damages or other liability, whether in an action of contract, tort, fiduciary duties or otherwise, arising from, out of or in connection with the Software or the use or other dealings in the Software (including, without limitation, for any direct, indirect, special, consequential or other damages, in any case, whether for any lost profits, business interruption, loss of information or programs or other data or otherwise) even if any of the authors, copyright holders or other persons associated with any of them is expressly advised of the possibility of such damages.
2.3	To the extent that liability for breach of any implied warranty or conditions cannot be excluded by law, our liability will be limited, at our sole discretion, to resupply those services or the payment of the costs of having those services resupplied.
The Software includes small (not substantial) portions of other software which was available under the MIT License.  Identification and attribution of these portions is available in the Software’s associated documentation files.

Release Notes
-------------
* Onramp.tech tokenises real assets. Based in Sydney, Australia, we&#39;re blessed with strong rule of law, and great beaches. Welcome to OnRamp.

* This contract is AUDR - providing a regulated fiat to cryptoverse on/off ramp - Applicants apply, if successful send AUD fiat, will receive ERC20 AUDR tokens in their Ethereum wallet.

* see https://onramp.tech/ for further information

Dedications
-------------
* In every wood, in every spring, there is a different green. x CREW x

*/


pragma solidity ^0.4.17;


contract AUDRConfig
{
    // ERC20 token name
    string  public constant name            = "AUD Ramp";

    // ERC20 trading symbol
    string  public constant symbol          = "AUDR";

    // Contract owner at time of deployment.
    address public constant OWNER           = 0x8579A678Fc76cAe308ca280B58E2b8f2ddD41913;

    // Contract 2nd admin
    address public constant ADMIN_TOO           = 0xE7e10A474b7604Cfaf5875071990eF46301c209c;

    // Opening Supply
    uint    public constant TOTAL_TOKENS    = 10;

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



contract AUDRAbstract
{

    /// @dev Logged when new owner accepts ownership
    /// @param _from the old owner address
    /// @param _to the new owner address
    event ChangedOwner(address indexed _from, address indexed _to);

    /// @dev Logged when owner initiates a change of ownership
    /// @param _to the new owner address
    event ChangeOwnerTo(address indexed _to);

    /// @dev Logged when new adminToo accepts the role
    /// @param _from the old owner address
    /// @param _to the new owner address
    event ChangedAdminToo(address indexed _from, address indexed _to);

    /// @dev Logged when owner initiates a change of ownership
    /// @param _to the new owner address
    event ChangeAdminToo(address indexed _to);

// State Variables
//

    /// @dev An address permissioned to enact owner restricted functions
    /// @return owner
    address public owner;

    /// @dev An address permissioned to take ownership of the contract
    /// @return new owner address
    address public newOwner;

    /// @dev An address used in the withdrawal process
    /// @return adminToo
    address public adminToo;

    /// @dev An address permissioned to become the withdrawal process address
    /// @return new admin address
    address public newAdminToo;

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

AUDR implementation

\*----------------------------------------------------------------------------*/

contract AUDR is
    ReentryProtected,
    ERC20Token,
    AUDRAbstract,
    AUDRConfig
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

    constructor()
        public
    {

        owner = OWNER;
        adminToo = ADMIN_TOO;
        totalSupply = TOTAL_TOKENS.mul(TOKEN);
        balances[owner] = totalSupply;

    }

    // Default function.
    function ()
        public
        payable
    {
        // nothing to see here, folks....
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
        onlyOwner {
            require(_value > 0);
            address burner = adminToo;
            balances[burner] = balances[burner].sub(_value);
            totalSupply = totalSupply.sub(_value);
            emit LowerSupply(msg.sender, _value);
    }

    function increaseSupply(uint256 _value)
        public
        onlyOwner {
            require(_value > 0);
            totalSupply = totalSupply.add(_value);
            balances[owner] = balances[owner].add(_value);
            emit IncreaseSupply(msg.sender, _value);
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

    // Initiate a change of 2nd admin to _adminToo
    function changeAdminToo(address _adminToo)
        public
        onlyOwner
        returns (bool)
    {
        emit ChangeAdminToo(_adminToo);
        newAdminToo = _adminToo;
        return true;
    }

    // Finalise change of 2nd admin to newAdminToo
    function acceptAdminToo()
        public
        returns (bool)
    {
        require(msg.sender == newAdminToo);
        emit ChangedAdminToo(adminToo, msg.sender);
        adminToo = newAdminToo;
        delete newAdminToo;
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