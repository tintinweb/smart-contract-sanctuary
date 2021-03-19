/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.7.6;

contract UniversalDeployer2 {
  event Deploy(address _addr) anonymous;
      
  /**
    * @notice will deploy a contract via create2
    * @param _creationCode Creation code of contract to deploy
    * @param _instance Instance number of contract to deploy
    */
  function deploy(bytes memory _creationCode, uint256 _instance) public payable {
    address addr;
    assembly { addr := create2(callvalue(), add(_creationCode, 32), mload(_creationCode), _instance) }
    emit Deploy(addr);
  }
}