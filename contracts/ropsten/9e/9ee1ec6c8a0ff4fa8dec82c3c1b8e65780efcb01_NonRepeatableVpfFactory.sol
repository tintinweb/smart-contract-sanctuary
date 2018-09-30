pragma solidity ^0.4.23;

// File: contracts/VpfFactoryInterface.sol

contract VpfFactoryInterface {
    function generateNext() public;
    function isPaused() public view returns(bool);
}

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/oracles/OracleInterface.sol

contract OracleInterface {
    function request(bytes32 _assetHash, uint _time, uint8 _decimalPoints) public;
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

// File: contracts/oracles/UsingOracle.sol

contract UsingOracle {
    ContractAddressesManager addressManager;

    constructor(ContractAddressesManager _manager) public {
        addressManager = _manager;
    }

    function updateValue(bytes32 _vpfHash, uint _time, uint _value) public onlyFromOracle;

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
        uint resolveDate;
        uint maxBeta;
        int[] intervals;
        VpfFactoryInterface vpfFactoryInterface;
        uint tradesTotal;
        uint[] virtualTradesSummed;
        uint openValue;
        uint resolveValue;
    }

    mapping(bytes32 => Vpf) public vpfs;

    event VpfAdd(bytes32 hash);
    event VpfTradesFill(bytes32 hash);
    event VpfOpenValueCheck(bytes32 hash, uint value);
    event VpfResolveValueCheck(bytes32 hash, uint value);

    constructor(ContractAddressesManager _manager) public UsingOracle(_manager) {}

    function addVpf(
        bytes32 _phenomenonHash,
        uint _openDate,
        uint _closeDate,
        uint _resolveDate,
        uint _maxBeta,
        int[] _intervals
    ) public onlyValidFactory
    {
        require(addressManager.phenomenonsContract().isEnabled(_phenomenonHash));

        bytes32 hash = vpfHash(_phenomenonHash, _openDate, _resolveDate);
        vpfs[hash] = Vpf(
            _phenomenonHash,
            _openDate,
            _closeDate,
            _resolveDate,
            _maxBeta,
            _intervals,
            VpfFactoryInterface(msg.sender),
            0,
            new uint[](0),
            0,
            0
        );
        emit VpfAdd(hash);

        uint8 decimalPoints = addressManager.phenomenonsContract().decimalPoints(_phenomenonHash);

        addressManager.oracle().request(hash, _openDate, decimalPoints);
        addressManager.oracle().request(hash, _resolveDate, decimalPoints);
    }

    function fillTradesInfo(bytes32 _vpfHash, uint _tradesTotal, uint[] _virtualTradesSummed) public onlyOwner {
        Vpf storage vpf = vpfs[_vpfHash];
        require(vpf.openDate > 0);
        require(vpf.tradesTotal == 0);

        vpf.tradesTotal = _tradesTotal;
        vpf.virtualTradesSummed = _virtualTradesSummed;

        emit VpfTradesFill(_vpfHash);
    }

    function updateValue(bytes32 _vpfHash, uint _time, uint _value) public onlyFromOracle {
        Vpf storage vpf = vpfs[_vpfHash];

        require(_time == vpf.openDate || _time == vpf.resolveDate, "Time of request does not match openDate nor checkDate");

        if (_time == vpf.openDate) {
            vpf.openValue = _value;
            emit VpfOpenValueCheck(_vpfHash, _value);
        } else {
            vpf.resolveValue = _value;
            emit VpfResolveValueCheck(_vpfHash, _value);

            if (vpf.vpfFactoryInterface.isPaused() == false &&
            addressManager.phenomenonsContract().isEnabled(vpf.phenomenonHash)
            ) {
                vpf.vpfFactoryInterface.generateNext();
            }
        }
    }

    function vpfHash(bytes32 _phenomenonHash, uint _openDate, uint _resolveDate) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_phenomenonHash, _openDate, _resolveDate));
    }

    function intervalsCount(bytes32 _vpfHash) public view returns(uint) {
        return vpfs[_vpfHash].intervals.length;
    }

    function virtualTradesSummedCount(bytes32 _vpfHash) public view returns(uint) {
        return vpfs[_vpfHash].virtualTradesSummed.length;
    }

    function getIntervals(bytes32 _vpfHash, uint _index) public view returns(int) {
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

// File: contracts/BaseVpfFactory.sol

contract BaseVpfFactory is Pausable {
    using SafeMath for uint256;

    string public name;
    bytes32 public phenomenonHash;
    uint public maxBeta;
    int[] public intervals;

    VpfsContract vpfsContract;
    ContractAddressesManager manager;

    constructor(
        VpfsContract _vpfsContract,
        ContractAddressesManager _manager,
        string _name,
        bytes32 _phenomenonHash,
        uint _maxBeta,
        int[] _intervals
    ) public
    {
        vpfsContract = _vpfsContract;
        manager = _manager;
        name = _name;
        phenomenonHash = _phenomenonHash;
        maxBeta = _maxBeta;
        intervals = _intervals;

        manager.addFactory(VpfFactoryInterface(address(this)));
    }

    function isPaused() public view returns(bool) {
        return paused;
    }

    modifier onlyVpfsContractOrOwner {
        require(msg.sender == address(vpfsContract) || msg.sender == owner);
        _;
    }
}

// File: contracts/NonRepeatableVpfFactory.sol

contract NonRepeatableVpfFactory is BaseVpfFactory {
    constructor(
        VpfsContract _vpfsContract,
        ContractAddressesManager _manager,
        string _name,
        bytes32 _phenomenonHash,
        uint _maxBeta,
        int[] _intervals
    ) public BaseVpfFactory(_vpfsContract, _manager, _name, _phenomenonHash, _maxBeta, _intervals) {}

    function generateNext() public whenNotPaused onlyVpfsContractOrOwner {
        revert("This factory doesn&#39;t generate vpfs automatically");
    }

    function isPaused() public view returns(bool) {
        return true;
    }

    function add(uint _openDate, uint _closeDate, uint _checkDate) public onlyOwner {
        vpfsContract.addVpf(
            phenomenonHash,
            _openDate,
            _closeDate,
            _checkDate,
            maxBeta,
            intervals
        );
    }
}