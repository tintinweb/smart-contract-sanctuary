/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/core/PDispatcher.sol

pragma solidity >=0.4.21 <0.6.0;


contract PDispatcher is Ownable{

  mapping (bytes32 => address ) public targets;

  constructor() public{}

  event TargetChanged(bytes32 key, address old_target, address new_target);
  function resetTarget(bytes32 _key, address _target) public onlyOwner{
    require(_target != address(0x0), "invalid target");
    address old = address(targets[_key]);
    targets[_key] = _target;
    emit TargetChanged(_key, old, _target);
  }

  function getTarget(bytes32 _key) public view returns (address){
    return targets[_key];
  }
}

contract PDispatcherFactory{
  event NewPDispatcher(address addr);

  function createHDispatcher() public returns(address){
      PDispatcher dis = new PDispatcher();
      dis.transferOwnership(msg.sender);
      emit NewPDispatcher(address(dis));
      return address(dis);
  }
}