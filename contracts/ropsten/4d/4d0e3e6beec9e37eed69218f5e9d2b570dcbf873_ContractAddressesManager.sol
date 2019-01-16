pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/VpfFactoryInterface.sol

contract VpfFactoryInterface {
    function generateNext() public;
    function isPaused() public view returns(bool);
}

// File: contracts/oracles/OracleInterface.sol

contract OracleInterface {
    function request(
        bytes32 _assetHash,
        uint _time,
        uint8 _decimalPoints,
        uint _gasLimit) public;
}

// File: contracts/PhenomenonsContract.sol

contract PhenomenonsContract is Ownable {

    struct Phenomenon {
        string mnemonic;
        string name;
        string description;
        string category;
        uint8 valueDecimalPlaces;
        bool enabled;
        bool exists;
    }

    mapping(bytes32 => Phenomenon) public phenomenons;
    string[] public mnemonics;

    event PhenomenonAdd(bytes32 hash);
    event PhenomenonDisable(bytes32 hash);
    event PhenomenonEnable(bytes32 hash);

    function addPhenomenon(
        string _mnemonic,
        string _name,
        string _description,
        string _category,
        uint8 _valueDecimalPlaces
    ) public onlyOwner
    {
        bytes32 hash = keccak256(abi.encodePacked(_mnemonic));
        require(bytes(phenomenons[hash].mnemonic).length == 0, "Phenomenon already exists!");

        Phenomenon memory phenomenon = Phenomenon(
            _mnemonic,
            _name,
            _description,
            _category,
            _valueDecimalPlaces,
            true,
            true
        );

        phenomenons[hash] = phenomenon;
        mnemonics.push(_mnemonic);

        emit PhenomenonAdd(hash);
    }

    function disablePhenomenon(bytes32 _hash) public onlyOwner {
        require(phenomenons[_hash].enabled == true);

        phenomenons[_hash].enabled = false;

        emit PhenomenonDisable(_hash);
    }

    function enablePhenomenon(bytes32 _hash) public onlyOwner {
        require(phenomenons[_hash].exists == true);
        require(phenomenons[_hash].enabled == false);

        phenomenons[_hash].enabled = true;

        emit PhenomenonEnable(_hash);
    }

    function mnemonicsCount() public view returns(uint) {
        return mnemonics.length;
    }

    function isEnabled(bytes32 _hash) public view returns(bool) {
        return phenomenons[_hash].enabled;
    }

    function decimalPoints(bytes32 _hash) public view returns(uint8) {
        return phenomenons[_hash].valueDecimalPlaces;
    }
}

// File: contracts/ContractAddressesManager.sol

contract ContractAddressesManager is Ownable {

    OracleInterface public oracle;
    PhenomenonsContract public phenomenonsContract;
    mapping(address => bool) public factories;

    event AddFactory(address _factory);
    event RemoveFactory(address _factory);

    function addFactory(VpfFactoryInterface _factory) public onlyOwnerOrigin {
        factories[_factory] = true;
        emit AddFactory(_factory);
    }

    function removeFactory(VpfFactoryInterface _factory) public onlyOwner {
        factories[_factory] = false;
        emit RemoveFactory(_factory);
    }

    function setOracle(OracleInterface _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setPhenomenonsContract(PhenomenonsContract _phenomenonsContract) public onlyOwner {
        phenomenonsContract = _phenomenonsContract;
    }

    modifier onlyOwnerOrigin() {
        require(tx.origin == owner);
        _;
    }
}