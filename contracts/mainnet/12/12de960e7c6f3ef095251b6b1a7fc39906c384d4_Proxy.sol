/*
-----------------------------------------------------------------
FILE HEADER
-----------------------------------------------------------------

file:       Proxy.sol
version:    1.0
authors:    Anton Jurisevic
            Dominic Romanowski

date:       2018-2-28
checked:    Mike Spain
approved:   Samuel Brooks

repo:       https://github.com/Havven/havven
commit:     34e66009b98aa18976226c139270970d105045e3

-----------------------------------------------------------------
*/

pragma solidity ^0.4.21;

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner)
        public
    {
        owner = _owner;
    }

    function nominateOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

A proxy contract that, if it does not recognise the function
being called on it, passes all value and call data to an
underlying target contract.

-----------------------------------------------------------------
*/

contract Proxy is Owned {
    Proxyable public target;

    function Proxy(Proxyable _target, address _owner)
        Owned(_owner)
        public
    {
        target = _target;
        emit TargetChanged(_target);
    }

    function _setTarget(address _target) 
        external
        onlyOwner
    {
        require(_target != address(0));
        target = Proxyable(_target);
        emit TargetChanged(_target);
    }

    function () 
        public
        payable
    {
        target.setMessageSender(msg.sender);
        assembly {
            // Copy call data into free memory region.
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            // Forward all gas, ether, and data to the target contract.
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            // Revert if the call failed, otherwise return the result.
            if iszero(result) { revert(free_ptr, calldatasize) }
            return(free_ptr, returndatasize)
        } 
    }

    event TargetChanged(address targetAddress);
}

/*
-----------------------------------------------------------------
CONTRACT DESCRIPTION
-----------------------------------------------------------------

This contract is the Proxyable interface. Any contract the proxy
wraps must implement this, in order for the proxy to be able to
pass msg.sender into the underlying contract as the state
parameter, messageSender.

-----------------------------------------------------------------
*/

contract Proxyable is Owned {
    // the proxy this contract exists behind.
    Proxy public proxy;

    // The caller of the proxy, passed through to this contract.
    // Note that every function using this member must apply the onlyProxy or
    // optionalProxy modifiers, otherwise their invocations can use stale values.
    address messageSender;

    function Proxyable(address _owner)
        Owned(_owner)
        public { }

    function setProxy(Proxy _proxy)
        external
        onlyOwner
    {
        proxy = _proxy;
        emit ProxyChanged(_proxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy
    {
        require(Proxy(msg.sender) == proxy);
        _;
    }

    modifier onlyOwner_Proxy
    {
        require(messageSender == owner);
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

    // Combine the optionalProxy and onlyOwner_Proxy modifiers.
    // This is slightly cheaper and safer, since there is an ordering requirement.
    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner);
        _;
    }

    event ProxyChanged(address proxyAddress);

}

/*
MIT License

Copyright (c) 2018 Havven

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/