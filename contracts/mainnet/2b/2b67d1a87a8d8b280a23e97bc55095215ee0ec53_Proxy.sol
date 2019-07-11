/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

contract Delegatable {
    address public empty1; // unknown slot
    address public empty2; // unknown slot
    address public empty3;  // unknown slot
    address public owner;  // matches owner slot in controller
    address public delegation; // matches thisAddr slot in controller

    event DelegationTransferred(address indexed previousDelegate, address indexed newDelegation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    constructor() public {}

    /**
    * @dev Allows owner to transfer delegation of the contract to a newDelegation.
    * @param _newDelegation The address to transfer delegation to.
    */
    function transferDelegation(address _newDelegation) public onlyOwner {
        require(_newDelegation != address(0), "Trying to transfer to address 0");
        emit DelegationTransferred(delegation, _newDelegation);
        delegation = _newDelegation;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Trying to transfer to address 0");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract DelegateProxy {

    constructor() public {}

    /**
    * @dev Performs a delegatecall and returns whatever is returned (entire context execution will return!)
    * @param _dst Destination address to perform the delegatecall
    * @param _calldata Calldata for the delegatecall
    */
    function delegatedFwd(address _dst, bytes _calldata) internal {
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract Proxy is Delegatable, DelegateProxy {

    constructor() public {}

    /**
    * @dev Function to invoke all function that are implemented in controler
    */
    function () public {
        require(delegation != address(0), "Delegation is address 0, not initialized");
        delegatedFwd(delegation, msg.data);
    }

    /**
    * @dev Function to initialize storage of proxy
    * @param _controller The address of the controller to load the code from
    */
    function initialize(address _controller, uint256) public {
        require(owner == 0, "Already initialized");
        owner = msg.sender;
        delegation = _controller;
        delegatedFwd(_controller, msg.data);
    }
}