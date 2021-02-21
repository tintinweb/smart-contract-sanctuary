/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

/**
 *Submitted for verification at Etherscan.io on 2019-08-08
*/

/* ===============================================
* Flattened with Solidifier by Coinage
* 
* https://solidifier.coina.ge
* ===============================================
*/


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Owned.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski

date:       2018-2-26

-----------------------------------------------------------------
MODULE DESCRIPTION
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

pragma solidity 0.4.25;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
        public
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Proxy.sol
version:    1.3
author:     Anton Jurisevic

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A proxy contract that, if it does not recognise the function
being called on it, passes all value and call data to an
underlying target contract.

This proxy has the capacity to toggle between DELEGATECALL
and CALL style proxy functionality.

The former executes in the proxy's context, and so will preserve 
msg.sender and store data at the proxy address. The latter will not.
Therefore, any contract the proxy wraps in the CALL style must
implement the Proxyable interface, in order that it can pass msg.sender
into the underlying contract as the state parameter, messageSender.

-----------------------------------------------------------------
*/


contract Proxy is Owned {

    Proxyable public target;
    bool public useDELEGATECALL;

    constructor(address _owner)
        Owned(_owner)
        public
    {}

    function setTarget(Proxyable _target)
        external
        onlyOwner
    {
        target = _target;
        emit TargetUpdated(_target);
    }

    function setUseDELEGATECALL(bool value) 
        external
        onlyOwner
    {
        useDELEGATECALL = value;
    }

    function _emit(bytes callData, uint numTopics, bytes32 topic1, bytes32 topic2, bytes32 topic3, bytes32 topic4)
        external
        onlyTarget
    {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi). 
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            } 
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }

    function()
        external
        payable
    {
        if (useDELEGATECALL) {
            assembly {
                /* Copy call data into free memory region. */
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                /* Forward all gas and call data to the target contract. */
                let result := delegatecall(gas, sload(target_slot), free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                /* Revert if the call failed, otherwise return the result. */
                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        } else {
            /* Here we are as above, but must send the messageSender explicitly 
             * since we are using CALL rather than DELEGATECALL. */
            target.setMessageSender(msg.sender);
            assembly {
                let free_ptr := mload(0x40)
                calldatacopy(free_ptr, 0, calldatasize)

                /* We must explicitly forward ether to the underlying contract as well. */
                let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
                returndatacopy(free_ptr, 0, returndatasize)

                if iszero(result) { revert(free_ptr, returndatasize) }
                return(free_ptr, returndatasize)
            }
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Proxyable.sol
version:    1.1
author:     Anton Jurisevic

date:       2018-05-15

checked:    Mike Spain
approved:   Samuel Brooks

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A proxyable contract that works hand in hand with the Proxy contract
to allow for anyone to interact with the underlying contract both
directly and through the proxy.

-----------------------------------------------------------------
*/


// This contract should be treated like an abstract contract
contract Proxyable is Owned {
    /* The proxy this contract exists behind. */
    Proxy public proxy;
    Proxy public integrationProxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address messageSender;

    constructor(address _proxy, address _owner)
        Owned(_owner)
        public
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address _proxy)
        external
        onlyOwner
    {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setIntegrationProxy(address _integrationProxy)
        external
        onlyOwner
    {
        integrationProxy = Proxy(_integrationProxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy {
        require(Proxy(msg.sender) == proxy || Proxy(msg.sender) == integrationProxy, "Only the proxy can call");
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy) {
            messageSender = msg.sender;
        }
        _;
    }

    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy && Proxy(msg.sender) != integrationProxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
        _;
    }

    event ProxyUpdated(address proxyAddress);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20 {
    function totalSupply() public view returns (uint);

    function balanceOf(address owner) public view returns (uint);

    function allowance(address owner, address spender) public view returns (uint);

    function transfer(address to, uint value) public returns (bool);

    function approve(address spender, uint value) public returns (bool);

    function transferFrom(address from, address to, uint value) public returns (bool);

    // ERC20 Optional
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    event Transfer(
      address indexed from,
      address indexed to,
      uint value
    );

    event Approval(
      address indexed owner,
      address indexed spender,
      uint value
    );
}


/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       ProxyERC20.sol
version:    1.0
author:     Jackson Chan, Clinton Ennis

date:       2019-06-19

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A proxy contract that is ERC20 compliant for the Synthetix Network.

If it does not recognise a function being called on it, passes all
value and call data to an underlying target contract.

The ERC20 standard has been explicitly implemented to ensure
contract to contract calls are compatable on MAINNET

-----------------------------------------------------------------
*/


contract ProxyERC20 is Proxy, IERC20 {

    constructor(address _owner)
        Proxy(_owner)
        public
    {}

    // ------------- ERC20 Details ------------- //

    function name() public view returns (string){
        // Immutable static call from target contract
        return IERC20(target).name();
    }

    function symbol() public view returns (string){
         // Immutable static call from target contract
        return IERC20(target).symbol();
    }

    function decimals() public view returns (uint8){
         // Immutable static call from target contract
        return IERC20(target).decimals();
    }

    // ------------- ERC20 Interface ------------- //

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        // Immutable static call from target contract
        return IERC20(target).totalSupply();
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        // Immutable static call from target contract
        return IERC20(target).balanceOf(owner);
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        // Immutable static call from target contract
        return IERC20(target).allowance(owner, spender);
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(target).transfer(to, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(target).approve(spender, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        // Mutable state call requires the proxy to tell the target who the msg.sender is.
        target.setMessageSender(msg.sender);

        // Forward the ERC20 call to the target contract
        IERC20(target).transferFrom(from, to, value);

        // Event emitting will occur via Synthetix.Proxy._emit()
        return true;
    }
}