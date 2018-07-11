pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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

// File: contracts/ProxiesRegistry.sol

contract AbstractProxy {
  bytes32 public app_exec_id;
  function getAdmin() external view returns (address);
}

contract AbstractIdx {
    function getAdmin(address, bytes32) external view returns (address);
}

/**
 * Registry of Proxy smart-contracts deployed from Token Wizard 2.0.
 */
contract TokenWizardProxiesRegistry is Ownable {
  address public abstractStorageAddr;
  address public mintedCappedIdxAddr;
  address public dutchIdxAddr;
  mapping (address => Crowdsale[]) private deployedCrowdsalesByUser;
  event Added(address indexed sender, address indexed proxyAddress, bytes32 appExecID);
  struct Crowdsale {
      address proxyAddress;
      bytes32 execID;
  }
  
  constructor (
    address _abstractStorage,
    address _mintedCappedIdx,
    address _dutchIdx
  ) public {
      require(_abstractStorage != address(0));
      require(_mintedCappedIdx != address(0));
      require(_dutchIdx != address(0));
      require(_abstractStorage != _mintedCappedIdx && _abstractStorage != _dutchIdx && _mintedCappedIdx != _dutchIdx);
      abstractStorageAddr = _abstractStorage;
      mintedCappedIdxAddr = _mintedCappedIdx;
      dutchIdxAddr = _dutchIdx;
  }

  function changeAbstractStorage(address newAbstractStorageAddr) public onlyOwner {
    abstractStorageAddr = newAbstractStorageAddr;
  }

  function changeMintedCappedIdx(address newMintedCappedIdxAddr) public onlyOwner {
    mintedCappedIdxAddr = newMintedCappedIdxAddr;
  }

  function changeDutchIdxAddr(address newDutchIdxAddr) public onlyOwner {
    dutchIdxAddr = newDutchIdxAddr;
  }

  function trackCrowdsale(address proxyAddress) public {
    AbstractProxy proxy = AbstractProxy(proxyAddress);
    require(proxyAddress != address(0));
    require(msg.sender == proxy.getAdmin());
    bytes32 appExecID = proxy.app_exec_id();
    AbstractIdx mintedCappedIdx = AbstractIdx(mintedCappedIdxAddr);
    AbstractIdx dutchIdx = AbstractIdx(dutchIdxAddr);
    require(mintedCappedIdx.getAdmin(abstractStorageAddr, appExecID) != address(0) || dutchIdx.getAdmin(abstractStorageAddr, appExecID) != address(0));
    for (uint i = 0; i < deployedCrowdsalesByUser[msg.sender].length; i++) {
        require(deployedCrowdsalesByUser[msg.sender][i].proxyAddress != proxyAddress);
        require(deployedCrowdsalesByUser[msg.sender][i].execID != appExecID);
    }
    deployedCrowdsalesByUser[msg.sender].push(Crowdsale({proxyAddress: proxyAddress, execID: appExecID}));
    emit Added(msg.sender, proxyAddress, appExecID);
  }

  function countCrowdsalesForUser(address deployer) public view returns (uint) {
    return deployedCrowdsalesByUser[deployer].length;
  }
  
  function getCrowdsalesForUser(address deployer) public view returns (address[]) {
      address[] memory proxies = new address[](deployedCrowdsalesByUser[deployer].length);
      for (uint k = 0; k < deployedCrowdsalesByUser[deployer].length; k++) {
          proxies[k] = deployedCrowdsalesByUser[deployer][k].proxyAddress;
      }
      return proxies;
  }
}