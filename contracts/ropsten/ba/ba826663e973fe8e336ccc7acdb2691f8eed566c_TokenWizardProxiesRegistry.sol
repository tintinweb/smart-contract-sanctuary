pragma solidity ^0.4.24;

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

contract AbstractProxy {
  bytes32 public app_exec_id;
  function getAdmin() external view returns (address);
}

contract MintedCappedIdx {
    function getAdmin(address, bytes32) external view returns (address);
}

contract DutchIdx {
    function getAdmin(address, bytes32) external view returns (address);
}

/**
 * Registry of contracts deployed from Token Wizard 2.0.
 */
contract TokenWizardProxiesRegistry is Ownable {
  address public abstractStorageAddr;
  address public mintedCappedIdxAddr;
  address public dutchIdxAddr;
  mapping (address => address[]) private deployedProxiesByUser;
  mapping (address => bytes32[]) private deployedExecIdsByUser;
  event Added(address indexed sender, address indexed proxyAddress, bytes32 appExecID);
  
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
    MintedCappedIdx mintedCappedIdx = MintedCappedIdx(mintedCappedIdxAddr);
    DutchIdx dutchIdx = DutchIdx(dutchIdxAddr);
    require(mintedCappedIdx.getAdmin(abstractStorageAddr, appExecID) == msg.sender || dutchIdx.getAdmin(abstractStorageAddr, appExecID) == msg.sender);
    for (uint i = 0; i < deployedProxiesByUser[msg.sender].length; i++) {
        require(deployedProxiesByUser[msg.sender][i] != proxyAddress);
        require(deployedExecIdsByUser[msg.sender][i] != appExecID);
    }
    deployedProxiesByUser[msg.sender].push(proxyAddress);
    deployedExecIdsByUser[msg.sender].push(appExecID);
    emit Added(msg.sender, proxyAddress, appExecID);
  }

  function countCrowdsalesForUser(address deployer) public view returns (uint) {
    return deployedProxiesByUser[deployer].length;
  }
  
  function getCrowdsalesForUser(address deployer) public view returns (address[]) {
      return deployedProxiesByUser[deployer];
  }

  function getProxyExecID(address proxyAddress) view public returns (bytes32) {
    AbstractProxy proxy = AbstractProxy(proxyAddress);
    bytes32 appExecID = proxy.app_exec_id();
    return appExecID;
  }

  function getAdminFromMintedCappedProxy(address proxyAddress) view public returns(address) {
    AbstractProxy proxy = AbstractProxy(proxyAddress);
    bytes32 appExecID = proxy.app_exec_id();
    MintedCappedIdx mintedCappedIdx = MintedCappedIdx(mintedCappedIdxAddr);
    return mintedCappedIdx.getAdmin(abstractStorageAddr, appExecID);
  }

  function getADminFromDutchProxy(address proxyAddress) view public returns(address) {
    AbstractProxy proxy = AbstractProxy(proxyAddress);
    bytes32 appExecID = proxy.app_exec_id();
    DutchIdx dutchIdx = DutchIdx(dutchIdxAddr);
    return dutchIdx.getAdmin(abstractStorageAddr, appExecID);
  }
}