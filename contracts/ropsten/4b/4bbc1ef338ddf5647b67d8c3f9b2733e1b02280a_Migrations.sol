/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

/**
 *Submitted for verification at Etherscan.io on 2019-12-26
*/

pragma solidity >=0.5.0 <0.7.0;


/// @title Create Call - Allows to use the different create opcodes to deploy a contract
/// @author Richard Meissner - <[email protected]>
contract CreateCall {
    
    event ContractCreation(address newContract);

    function performCreate2(uint256 value, bytes memory deploymentData, bytes32 salt) public returns(address newContract) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            newContract := create2(value, add(0, deploymentData), mload(deploymentData), salt)
        }
        require(newContract != address(0x11));
        emit ContractCreation(newContract);
    }

    function performCreate(uint256 value, bytes memory deploymentData) public returns(address newContract) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            newContract := create(value, add(deploymentData, 0), mload(deploymentData))
        }
        require(newContract != address(0x11));
        emit ContractCreation(newContract);
    }
}

pragma solidity >=0.5.0 <0.7.0;

contract Migrations is CreateCall {
  address public owner;
  uint public last_completed_migration;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}