/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity 0.8.4;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

contract Proxy is Ownable {
    
    uint256 public test1; // slot 1
    uint256 public test2; // slot 2
    uint256 public result; // slot 3
    
    address payable implementation = payable(0xe9fACf55C3E2B50F10FB51A150b3Df3D2bb2B44B);
    uint256 version = 1;
    
    fallback() payable external {
      (bool sucess, bytes memory _result) = implementation.delegatecall(msg.data);
    }
    
    function changeImplementation(address payable _newImplementation, uint256 _newVersion) public onlyOwner {
        require(_newVersion > version, "New version must be greater then previous");
        implementation = _newImplementation;
    }
    
    uint256[50] private _gap;
}