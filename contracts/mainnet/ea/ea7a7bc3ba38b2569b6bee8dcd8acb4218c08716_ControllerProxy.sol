pragma solidity ^0.4.23;

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _owner Address of the new owner
    */
    function setOwner(address _owner) public onlyOwner returns (bool) {
        require(_owner != address(0));
        owner = _owner;
        return true;
    } 
}


contract HasWorkers is Ownable {
    mapping(address => uint256) private workerToIndex;    
    address[] private workers;

    event AddedWorker(address _worker);
    event RemovedWorker(address _worker);

    constructor() public {
        workers.length++;
    }

    modifier onlyWorker() {
        require(isWorker(msg.sender));
        _;
    }

    modifier workerOrOwner() {
        require(isWorker(msg.sender) || msg.sender == owner);
        _;
    }

    function isWorker(address _worker) public view returns (bool) {
        return workerToIndex[_worker] != 0;
    }

    function allWorkers() public view returns (address[] memory result) {
        result = new address[](workers.length - 1);
        for (uint256 i = 1; i < workers.length; i++) {
            result[i - 1] = workers[i];
        }
    }

    function addWorker(address _worker) public onlyOwner returns (bool) {
        require(!isWorker(_worker));
        uint256 index = workers.push(_worker) - 1;
        workerToIndex[_worker] = index;
        emit AddedWorker(_worker);
        return true;
    }

    function removeWorker(address _worker) public onlyOwner returns (bool) {
        require(isWorker(_worker));
        uint256 index = workerToIndex[_worker];
        address lastWorker = workers[workers.length - 1];
        workerToIndex[lastWorker] = index;
        workers[index] = lastWorker;
        workers.length--;
        delete workerToIndex[_worker];
        emit RemovedWorker(_worker);
        return true;
    }
}

contract ControllerStorage {
    address public walletsDelegate;
    address public controllerDelegate;
    address public forward;
    uint256 public createdWallets;
    mapping(bytes32 => bytes32) public gStorage;
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

contract DelegateProvider {
    function getDelegate() public view returns (address delegate);
}

contract ControllerProxy is ControllerStorage, Ownable, HasWorkers, DelegateProvider, DelegateProxy {
    function getDelegate() public view returns (address delegate) {
        delegate = walletsDelegate;
    }

    function setWalletsDelegate(address _delegate) public onlyOwner returns (bool) {
        walletsDelegate = _delegate;
        return true;
    }

    function setControllerDelegate(address _delegate) public onlyOwner returns (bool) {
        controllerDelegate = _delegate;
        return true;
    }

    function() public payable {
        if (gasleft() > 2400) {
            delegatedFwd(controllerDelegate, msg.data);
        }
    }
}