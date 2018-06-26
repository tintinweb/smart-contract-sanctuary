pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/PhenomenonsContract.sol

contract PhenomenonsContract is Ownable {

    struct Phenomenon {
        string mnemonic;
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
        string mnemonic,
        string description,
        string category,
        uint8 valueDecimalPlaces
    ) public onlyOwner
    {
        bytes32 hash = keccak256(abi.encodePacked(mnemonic));
        require(bytes(phenomenons[hash].mnemonic).length == 0, &quot;Phenomenon already exists!&quot;);

        Phenomenon memory phenomenon = Phenomenon(
            mnemonic,
            description,
            category,
            valueDecimalPlaces,
            true,
            true
        );

        phenomenons[hash] = phenomenon;
        mnemonics.push(mnemonic);

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
}

// File: contracts/VpfFactoryInterface.sol

interface VpfFactoryInterface {
    function generateNext() public;
    function isPaused() public view returns(bool);
}

// File: contracts/oracles/OracleInterface.sol

interface OracleInterface {
    function request(bytes32 _assetHash, string _call, uint _time) public;
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

// File: contracts/oracles/UsingOracle.sol

contract UsingOracle {
    ContractAddressesManager addressManager;

    constructor(ContractAddressesManager _manager) public {
        addressManager = _manager;
    }

    modifier onlyFromOracle() {
        require(msg.sender == address(addressManager.oracle()));
        _;
    }
}

// File: contracts/VpfsContract.sol

contract VpfsContract is UsingOracle, Ownable {
    struct Vpf {
        bytes32 phenomenonHash;
        uint openDate;
        uint closeDate;
        uint checkDate;
        string oracleCall;
        uint maxBeta;
        uint[] intervals;
        VpfFactoryInterface vpfFactoryInterface;
        uint tradesTotal;
        uint[] virtualTradesSummed;
        uint oracleValue;
    }

    mapping(bytes32 => Vpf) public vpfs;

    event VpfAdd(bytes32 hash);
    event VpfTradesFill(bytes32 hash);
    event VpfCheck(bytes32 hash, uint value);

    constructor(ContractAddressesManager _manager) public UsingOracle(_manager) {}

    function addVpf(
        bytes32 _phenomenonHash,
        uint _openDate,
        uint _closeDate,
        uint _checkDate,
        string _oracleCall,
        uint _maxBeta,
        uint[] _intervals
    ) public onlyValidFactory
    {
        require(addressManager.phenomenonsContract().isEnabled(_phenomenonHash));

        bytes32 hash = vpfHash(_phenomenonHash, _openDate, _checkDate);
        vpfs[hash] = Vpf(
            _phenomenonHash,
            _openDate,
            _closeDate,
            _checkDate,
            _oracleCall,
            _maxBeta,
            _intervals,
            VpfFactoryInterface(msg.sender),
            0,
            new uint[](0),
            0
        );
        emit VpfAdd(hash);

        addressManager.oracle().request(hash, _oracleCall, _checkDate);
    }

    function fillTradesInfo(bytes32 _vpfHash, uint _tradesTotal, uint[] _virtualTradesSummed) public onlyOwner {
        Vpf storage vpf = vpfs[_vpfHash];
        require(vpf.openDate > 0);
        require(vpf.tradesTotal == 0);

        vpf.tradesTotal = _tradesTotal;
        vpf.virtualTradesSummed = _virtualTradesSummed;

        emit VpfTradesFill(_vpfHash);
    }

    function updateValue(bytes32 _vpfHash, uint _value) public onlyFromOracle {
        Vpf storage vpf = vpfs[_vpfHash];
        vpf.oracleValue = _value;
        emit VpfCheck(_vpfHash, _value);

        if (vpf.vpfFactoryInterface.isPaused() == false &&
            addressManager.phenomenonsContract().isEnabled(vpf.phenomenonHash)
        ) {
            vpf.vpfFactoryInterface.generateNext();
        }
    }

    function vpfHash(bytes32 _phenomenonHash, uint _openDate, uint _checkDate) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_phenomenonHash, _openDate, _checkDate));
    }

    function intervalsCount(bytes32 _vpfHash) public view returns(uint) {
        return vpfs[_vpfHash].intervals.length;
    }

    function virtualTradesSummedCount(bytes32 _vpfHash) public view returns(uint) {
        return vpfs[_vpfHash].virtualTradesSummed.length;
    }

    function getIntervals(bytes32 _vpfHash, uint _index) public view returns(uint) {
        return vpfs[_vpfHash].intervals[_index];
    }

    function getVirtualTradesSummed(bytes32 _vpfHash, uint _index) public view returns(uint) {
        return vpfs[_vpfHash].virtualTradesSummed[_index];
    }

    modifier onlyValidFactory() {
        require(addressManager.factories(msg.sender));
        _;
    }
}