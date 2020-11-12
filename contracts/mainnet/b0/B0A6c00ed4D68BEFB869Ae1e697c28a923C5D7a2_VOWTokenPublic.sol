pragma solidity 0.5.12;

import "./BasicToken.sol";

contract VOWTokenPublic is BasicToken {
  mapping(address => bool) public vscContracts;

  event LogVSCContractRegistered(address indexed vscContract);
  event LogVSCContractDeregistered(address indexed vscContract);

  constructor(uint256 _initialSupply)
    BasicToken("Vow", "Vow", _initialSupply)
    public {}

  function registerVSCContract(address _vscContract)
    external
    onlyOwner
  {
    require(!vscContracts[_vscContract], "VSC contract already registered");
    vscContracts[_vscContract] = true;

    emit LogVSCContractRegistered(_vscContract);
  }

  function deregisterVSCContract(address _vscContract)
    external
    onlyOwner
  {
    require(vscContracts[_vscContract], "VSC contract is not registered");
    vscContracts[_vscContract] = false;

    emit LogVSCContractDeregistered(_vscContract);
  }

  function isRegisteredVSCContract(address _vscContract)
    public
    view
    returns (bool isRegistered_)
  {
    isRegistered_ = vscContracts[_vscContract];
  }
}