pragma solidity ^0.4.25;

//This contract is for anyone that interacts with a p3d style contract that didn&#39;t publish their code on etherscan

contract contractX 
{
  function exit() public;
}

contract EmergencyExit {
  address unknownContractAddress;

  function callExitFromUnknownContract(address contractAddress) public 
  {
     contractX(contractAddress).exit();
     address(msg.sender).transfer(address(this).balance);
  }
}