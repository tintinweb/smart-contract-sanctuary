pragma solidity ^0.4.24;

// File: node_modules\zeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts\Hamon.sol

//solium-disable linebreak-style
pragma solidity ^0.4.24;


contract Hamon is Ownable {

    string public constant name = "Hamon";
    struct DataInfo {
        address owner;
        string dataHash;
        string dataStorage;
    }
    mapping(string => DataInfo) internal datas;
    string[] internal storages;

    event Modify(string key, address owner);

    constructor() public {
    }

    function write(
        string key,
        string dataHash,
        string dataStorage
    )
      public
      returns (bool)
    {
        datas[key] = DataInfo(msg.sender, dataHash, dataStorage);
        emit Modify(key, msg.sender);

        return true;
    }

    function readHash(string key) public view returns (string) {
        return datas[key].dataHash;
    }

    function readStorage(string key) public view returns (string) {
        return datas[key].dataStorage;
    }

}