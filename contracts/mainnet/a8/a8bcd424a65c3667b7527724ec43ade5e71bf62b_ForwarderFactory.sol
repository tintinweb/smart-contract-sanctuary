/******************************************************************************\

file:   RegBase.sol
ver:    0.3.3
updated:12-Sep-2017
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

This file is part of the SandalStraps framework

`RegBase` provides an inheriting contract the minimal API to be compliant with 
`Registrar`.  It includes a set-once, `bytes32 public regName` which is refered
to by `Registrar` lookups.

An owner updatable `address public owner` state variable is also provided and is
required by `Factory.createNew()`.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release notes:
* Framworking changing to Factory v0.3.3 usage
\******************************************************************************/

pragma solidity ^0.4.13;

contract RegBaseAbstract
{
    /// @dev A static identifier, set in the constructor and used for registrar
    /// lookup
    /// @return Registrar name SandalStraps registrars
    bytes32 public regName;

    /// @dev An general purpose resource such as short text or a key to a
    /// string in a StringsMap
    /// @return resource
    bytes32 public resource;
    
    /// @dev An address permissioned to enact owner restricted functions
    /// @return owner
    address public owner;
    
    /// @dev An address permissioned to take ownership of the contract
    /// @return newOwner
    address public newOwner;

//
// Events
//

    /// @dev Triggered on initiation of change owner address
    event ChangeOwnerTo(address indexed _newOwner);

    /// @dev Triggered on change of owner address
    event ChangedOwner(address indexed _oldOwner, address indexed _newOwner);

    /// @dev Triggered when the contract accepts ownership of another contract.
    event ReceivedOwnership(address indexed _kAddr);

    /// @dev Triggered on change of resource
    event ChangedResource(bytes32 indexed _resource);

//
// Function Abstracts
//

    /// @notice Will selfdestruct the contract
    function destroy() public;

    /// @notice Initiate a change of owner to `_owner`
    /// @param _owner The address to which ownership is to be transfered
    function changeOwner(address _owner) public returns (bool);

    /// @notice Finalise change of ownership to newOwner
    function acceptOwnership() public returns (bool);

    /// @notice Change the resource to `_resource`
    /// @param _resource A key or short text to be stored as the resource.
    function changeResource(bytes32 _resource) public returns (bool);
}


contract RegBase is RegBaseAbstract
{
//
// Constants
//

    bytes32 constant public VERSION = "RegBase v0.3.3";

//
// State Variables
//

    // Declared in RegBaseAbstract for reasons that an inherited abstract
    // function is not seen as implimented by a public state identifier of
    // the same name.
    
//
// Modifiers
//

    // Permits only the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

//
// Functions
//

    /// @param _creator The calling address passed through by a factory,
    /// typically msg.sender
    /// @param _regName A static name referenced by a Registrar
    /// @param _owner optional owner address if creator is not the intended
    /// owner
    /// @dev On 0x0 value for owner, ownership precedence is:
    /// `_owner` else `_creator` else msg.sender
    function RegBase(address _creator, bytes32 _regName, address _owner)
    {
        require(_regName != 0x0);
        regName = _regName;
        owner = _owner != 0x0 ? _owner : 
                _creator != 0x0 ? _creator : msg.sender;
    }
    
    /// @notice Will selfdestruct the contract
    function destroy()
        public
        onlyOwner
    {
        selfdestruct(msg.sender);
    }
    
    /// @notice Initiate a change of owner to `_owner`
    /// @param _owner The address to which ownership is to be transfered
    function changeOwner(address _owner)
        public
        onlyOwner
        returns (bool)
    {
        ChangeOwnerTo(_owner);
        newOwner = _owner;
        return true;
    }
    
    /// @notice Finalise change of ownership to newOwner
    function acceptOwnership()
        public
        returns (bool)
    {
        require(msg.sender == newOwner);
        ChangedOwner(owner, msg.sender);
        owner = newOwner;
        delete newOwner;
        return true;
    }

    /// @notice Change the resource to `_resource`
    /// @param _resource A key or short text to be stored as the resource.
    function changeResource(bytes32 _resource)
        public
        onlyOwner
        returns (bool)
    {
        resource = _resource;
        ChangedResource(_resource);
        return true;
    }
}

/******************************************************************************\

file:   Factory.sol
ver:    0.3.3
updated:12-Sep-2017
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

This file is part of the SandalStraps framework

Factories are a core but independant concept of the SandalStraps framework and 
can be used to create SandalStraps compliant &#39;product&#39; contracts from embed
bytecode.

The abstract Factory contract is to be used as a SandalStraps compliant base for
product specific factories which must impliment the createNew() function.

is itself compliant with `Registrar` by inhereting `RegBase` and
compiant with `Factory` through the `createNew(bytes32 _name, address _owner)`
API.

An optional creation fee can be set and manually collected by the owner.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
* Changed from`withdaw(<value>)` to `withdrawAll()`
\******************************************************************************/

pragma solidity ^0.4.13;

// import "./RegBase.sol";

contract Factory is RegBase
{
//
// Constants
//

    // Deriving factories should have `bytes32 constant public regName` being
    // the product&#39;s contract name, e.g for products "Foo":
    // bytes32 constant public regName = "Foo";

    // Deriving factories should have `bytes32 constant public VERSION` being
    // the product&#39;s contract name appended with &#39;Factory` and the version
    // of the product, e.g for products "Foo":
    // bytes32 constant public VERSION "FooFactory 0.0.1";

//
// State Variables
//

    /// @return The payment in wei required to create the product contract.
    uint public value;

//
// Events
//

    // Is triggered when a product is created
    event Created(address indexed _creator, bytes32 indexed _regName, address indexed _addr);

//
// Modifiers
//

    // To check that the correct fee has bene paid
    modifier feePaid() {
        require(msg.value == value || msg.sender == owner);
        _;
    }

//
// Functions
//

    /// @param _creator The calling address passed through by a factory,
    /// typically msg.sender
    /// @param _regName A static name referenced by a Registrar
    /// @param _owner optional owner address if creator is not the intended
    /// owner
    /// @dev On 0x0 value for _owner or _creator, ownership precedence is:
    /// `_owner` else `_creator` else msg.sender
    function Factory(address _creator, bytes32 _regName, address _owner)
        RegBase(_creator, _regName, _owner)
    {
        // nothing left to construct
    }
    
    /// @notice Set the product creation fee
    /// @param _fee The desired fee in wei
    function set(uint _fee) 
        onlyOwner
        returns (bool)
    {
        value = _fee;
        return true;
    }

    /// @notice Send contract balance to `owner`
    function withdrawAll()
        public
        returns (bool)
    {
        owner.transfer(this.balance);
        return true;
    }

    /// @notice Create a new product contract
    /// @param _regName A unique name if the the product is to be registered in
    /// a SandalStraps registrar
    /// @param _owner An address of a third party owner.  Will default to
    /// msg.sender if 0x0
    /// @return kAddr_ The address of the new product contract
    function createNew(bytes32 _regName, address _owner) 
        payable returns(address kAddr_);
}

/******************************************************************************\

file:   Forwarder.sol
ver:    0.3.0
updated:4-Oct-2017
author: Darryl Morris (o0ragman0o)
email:  o0ragman0o AT gmail.com

This file is part of the SandalStraps framework

Forwarder acts as a proxy address for payment pass-through.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
* Name change from &#39;Redirector&#39; to &#39;Forwarder&#39;
* Changes state name from &#39;payTo&#39; to &#39;forwardTo&#39;

\******************************************************************************/

pragma solidity ^0.4.13;

// import "https://github.com/o0ragman0o/SandalStraps/contracts/Factory.sol";

contract Forwarder is RegBase {
//
// Constants
//

    bytes32 constant public VERSION = "Forwarder v0.3.0";

//
// State
//

    address public forwardTo;
    
//
// Events
//
    
    event Forwarded(
        address indexed _from,
        address indexed _to,
        uint _value);

//
// Functions
//

    function Forwarder(address _creator, bytes32 _regName, address _owner)
        public
        RegBase(_creator, _regName, _owner)
    {
        // forwardTo will be set to msg.sender of if _owner == 0x0 or _owner
        // otherwise
        forwardTo = owner;
    }
    
    function ()
        public
        payable 
    {
        Forwarded(msg.sender, forwardTo, msg.value);
        require(forwardTo.call.value(msg.value)(msg.data));
    }
    
    function changeForwardTo(address _forwardTo)
        public
        returns (bool)
    {
        // Only owner or forwarding address can change forwarding address 
        require(msg.sender == owner || msg.sender == forwardTo);
        forwardTo = _forwardTo;
        return true;
    }
}


contract ForwarderFactory is Factory
{
//
// Constants
//

    /// @return registrar name
    bytes32 constant public regName = "forwarder";
    
    /// @return version string
    bytes32 constant public VERSION = "ForwarderFactory v0.3.0";

//
// Functions
//

    /// @param _creator The calling address passed through by a factory,
    /// typically msg.sender
    /// @param _regName A static name referenced by a Registrar
    /// @param _owner optional owner address if creator is not the intended
    /// owner
    /// @dev On 0x0 value for _owner or _creator, ownership precedence is:
    /// `_owner` else `_creator` else msg.sender
    function ForwarderFactory(
            address _creator, bytes32 _regName, address _owner) public
        Factory(_creator, regName, _owner)
    {
        // _regName is ignored as `regName` is already a constant
        // nothing to construct
    }

    /// @notice Create a new product contract
    /// @param _regName A unique name if the the product is to be registered in
    /// a SandalStraps registrar
    /// @param _owner An address of a third party owner.  Will default to
    /// msg.sender if 0x0
    /// @return kAddr_ The address of the new product contract
    function createNew(bytes32 _regName, address _owner)
        public
        payable
        feePaid
        returns (address kAddr_)
    {
        kAddr_ = address(new Forwarder(msg.sender, _regName, _owner));
        Created(msg.sender, _regName, kAddr_);
    }
}