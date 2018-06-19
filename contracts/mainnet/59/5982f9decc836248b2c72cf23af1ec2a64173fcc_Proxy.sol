pragma solidity 0.4.23;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);

    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Proxied is Ownable {
    address public target;
    mapping (address => bool) public initialized;

    event EventUpgrade(address indexed newTarget, address indexed oldTarget, address indexed admin);
    event EventInitialized(address indexed target);

    function upgradeTo(address _target) public;
}

contract Proxy is Proxied {
    /*
     * @notice Constructor sets the target and emmits an event with the first target
     * @param _target - The target Upgradeable contracts address
     */
    constructor(address _target) public {
        upgradeTo(_target);
    }

    /*
     * @notice Upgrades the contract to a different target that has a changed logic. Can only be called by owner
     * @dev See https://github.com/jackandtheblockstalk/upgradeable-proxy for what can and cannot be done in Upgradeable
     * contracts
     * @param _target - The target Upgradeable contracts address
     */
    function upgradeTo(address _target) public onlyOwner {
        assert(target != _target);

        address oldTarget = target;
        target = _target;

        emit EventUpgrade(_target, oldTarget, msg.sender);
    }

    /*
     * @notice Performs an upgrade and then executes a transaction. Intended use to upgrade and initialize atomically
     */
    function upgradeTo(address _target, bytes _data) public onlyOwner {
        upgradeTo(_target);
        assert(target.delegatecall(_data));
    }

    /*
     * @notice Fallback function that will execute code from the target contract to process a function call.
     * @dev Will use the delegatecall opcode to retain the current state of the Proxy contract and use the logic
     * from the target contract to process it.
     */
    function () payable public {
        bytes memory data = msg.data;
        address impl = target;

        assembly {
            let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}