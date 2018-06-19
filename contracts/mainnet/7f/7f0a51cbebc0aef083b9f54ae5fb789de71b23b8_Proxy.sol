contract Delegatable {
  address empty1; // unknown slot
  address empty2; // unknown slot
  address empty3;  // unknown slot
  address public owner;  // matches owner slot in controller
  address public delegation; // matches thisAddr slot in controller

  event DelegationTransferred(address indexed previousDelegate, address indexed newDelegation);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows owner to transfer delegation of the contract to a newDelegation.
   * @param newDelegation The address to transfer delegation to.
   */
  function transferDelegation(address newDelegation) public onlyOwner {
    require(newDelegation != address(0));
    emit DelegationTransferred(delegation, newDelegation);
    delegation = newDelegation;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract DelegateProxy {

    /**
    * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
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

  /**
   * @dev Function to invoke all function that are implemented in controler
   */
  function () public {
    delegatedFwd(delegation, msg.data);
  }

  /**
   * @dev Function to initialize storage of proxy
   * @param _controller The address of the controller to load the code from
   * @param _cap Max amount of tokens that should be mintable
   */
  function initialize(address _controller, uint256 _cap) public {
    require(owner == 0);
    owner = msg.sender;
    delegation = _controller;
    delegatedFwd(_controller, msg.data);
  }

}