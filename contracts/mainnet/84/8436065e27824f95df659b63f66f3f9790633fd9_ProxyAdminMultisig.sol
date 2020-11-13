pragma solidity ^0.5.16;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract MultiOwnable is
    Initializable
{

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 1 hours;
    uint public constant MAXIMUM_DELAY = 30 days;

    struct VoteInfo {
        uint32 timelockFrom;
        uint32 votesCounter;
        uint64 curVote;
        mapping(uint => mapping (address => bool)) isVoted; // [curVote][owner]
    }
    mapping(bytes => VoteInfo) public votes;

    mapping(address => bool) public  multiOwners;

    uint public multiOwnersCounter;

    uint public minVotes = 2;           // initial value

    uint public delay = MINIMUM_DELAY;  // initial value

    event QueueVote(address indexed owner, bytes data);
    event TxTimelockStart(bytes data, uint32 start);
    event CancelVote(address indexed owner, bytes data);
    event ExecuteVote(bytes data);
    event NewMinVotes(uint newMinVotes);
    event NewDelay(uint newDelay);
    event MultiOwnerAdded(address indexed newMultiOwner);
    event MultiOwnerRemoved(address indexed exMultiOwner);

    modifier onlyMultiOwners {
        // hook instead of using huge main modifier
        if (_onlyMultiOwnersCall()) {
            _;
        }
    }

    modifier _onlyMultiOwnersHelper {
        address account = msg.sender;
        bytes memory data = msg.data;
        require(multiOwners[account], "Permission denied");

        uint curVote = votes[data].curVote;
        uint32 curTimestamp = uint32(block.timestamp);

        // vote for current call
        if (!votes[data].isVoted[curVote][account]) {
            votes[data].isVoted[curVote][account] = true;
            votes[data].votesCounter++;
            emit QueueVote(account, data);

            if (votes[data].votesCounter == min(minVotes, multiOwnersCounter)) {
                votes[data].timelockFrom = curTimestamp;
                emit TxTimelockStart(data, curTimestamp);
            }
        }

        // execute tx
        if (votes[data].votesCounter >= min(minVotes, multiOwnersCounter) &&
            votes[data].timelockFrom + delay <= curTimestamp &&
            votes[data].timelockFrom + delay + GRACE_PERIOD >= curTimestamp
        ){
            // iterate to new vote for this msg.data
            votes[data].votesCounter = 0;
            votes[data].timelockFrom = 0;
            votes[data].curVote++;
            emit ExecuteVote(data);
            _;  // tx execution
        }
    }

    // ** INITIALIZERS **

    function initialize() public initializer {
        _addMultiOwner(msg.sender);
    }

    function initialize(address[] memory _newMultiOwners) public initializer {
        require(_newMultiOwners.length > 0, "Array lengths have to be greater than zero");

        for (uint i = 0; i < _newMultiOwners.length; i++) {
            _addMultiOwner(_newMultiOwners[i]);
        }
    }

    // ** ONLY_MULTI_OWNERS functions **

    function addMultiOwner(address _newMultiOwner) public onlyMultiOwners {
        _addMultiOwner(_newMultiOwner);
    }

    function addMultiOwners(address[] memory _newMultiOwners) public onlyMultiOwners {
        require(_newMultiOwners.length > 0, "Array lengths have to be greater than zero");

        for (uint i = 0; i < _newMultiOwners.length; i++) {
            _addMultiOwner(_newMultiOwners[i]);
        }
    }

    function removeMultiOwner(address _exMultiOwner) public onlyMultiOwners {
        _removeMultiOwner(_exMultiOwner);
    }

    function removeMultiOwners(address[] memory _exMultiOwners) public onlyMultiOwners {
        require(_exMultiOwners.length > 0, "Array lengths have to be greater than zero");

        for (uint i = 0; i < _exMultiOwners.length; i++) {
            _removeMultiOwner(_exMultiOwners[i]);
        }
    }

    function setMinVotes(uint _minVotes) public onlyMultiOwners {
        require(_minVotes > 0, "MinVotes have to be greater than zero");
        minVotes = _minVotes;
        emit NewMinVotes(_minVotes);
    }

    function setDelay(uint _delay) public onlyMultiOwners {
        require(_delay >= MINIMUM_DELAY, "Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "Delay must not exceed maximum delay.");
        delay = _delay;

        emit NewDelay(_delay);
    }

    function cancelVote(bytes memory _data) public {
        address account = msg.sender;
        require(multiOwners[account], "Permission denied");

        // check vote data
        uint curVote = votes[_data].curVote;
        require(votes[_data].isVoted[curVote][account] && votes[_data].votesCounter > 0, "Incorrect vote data");

        // cancel current vote
        votes[_data].isVoted[curVote][account] = false;
        votes[_data].votesCounter--;    // safe
        emit CancelVote(account, _data);
    }

    // ** INTERNAL functions **

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function _onlyMultiOwnersCall() internal _onlyMultiOwnersHelper returns (bool success) {
        success = true;
    }

    function _addMultiOwner(address _newMultiOwner) internal {
        require(!multiOwners[_newMultiOwner], "The owner has already been added");

        // UPD states
        multiOwners[_newMultiOwner] = true;
        multiOwnersCounter++;

        emit MultiOwnerAdded(_newMultiOwner);
    }

    function _removeMultiOwner(address _exMultiOwner) internal {
        require(multiOwners[_exMultiOwner], "This address is not the owner");
        require(multiOwnersCounter > 1, "At least one owner required");

        // UPD states
        multiOwners[_exMultiOwner] = false;
        multiOwnersCounter--;   // safe

        emit MultiOwnerRemoved(_exMultiOwner);
    }

}

// **INTERFACES**

interface IAdminUpgradeabilityProxy {
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
}

/**
 * @title ProxyAdminMultisig
 * @dev This contract is the admin of a proxy, and is in charge
 * of upgrading it as well as transferring it to another admin.
 */
contract ProxyAdminMultisig is MultiOwnable {

    constructor() public {
        address[] memory newOwners = new address[](1);
        newOwners[0] = 0xdAE0aca4B9B38199408ffaB32562Bf7B3B0495fE;
        initialize(newOwners);
    }

    /**
     * @dev Returns the current implementation of a proxy.
     * This is needed because only the proxy admin can query it.
     * @return The address of the current implementation of the proxy.
     */
    function getProxyImplementation(IAdminUpgradeabilityProxy proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the admin of a proxy. Only the admin can query it.
     * @return The address of the current admin of the proxy.
     */
    function getProxyAdmin(IAdminUpgradeabilityProxy proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of a proxy.
     * @param proxy Proxy to change admin.
     * @param newAdmin Address to transfer proxy administration to.
     */
    function changeProxyAdmin(IAdminUpgradeabilityProxy proxy, address newAdmin) public onlyMultiOwners {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades a proxy to the newest implementation of a contract.
     * @param proxy Proxy to be upgraded.
     * @param implementation the address of the Implementation.
     */
    function upgrade(IAdminUpgradeabilityProxy proxy, address implementation) public onlyMultiOwners {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades a proxy to the newest implementation of a contract and forwards a function call to it.
     * This is useful to initialize the proxied contract.
     * @param proxy Proxy to be upgraded.
     * @param implementation Address of the Implementation.
     * @param data Data to send as msg.data in the low level call.
     * It should include the signature and the parameters of the function to be called, as described in
     * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
     */
    function upgradeAndCall(IAdminUpgradeabilityProxy proxy, address implementation, bytes memory data) public payable  onlyMultiOwners {
        proxy.upgradeToAndCall.value(msg.value)(implementation, data);
    }
}