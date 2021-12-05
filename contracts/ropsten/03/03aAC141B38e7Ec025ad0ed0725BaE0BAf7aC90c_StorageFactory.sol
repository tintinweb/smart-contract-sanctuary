//SPDX-License-Identifier: UNLICENSED


pragma solidity >=0.8.10 <0.9.0;

import "./Wallet.sol";


contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}


contract StorageFactory is CloneFactory  {
    address public admin;
    address public contractToClone;

    mapping(address => address) public DCAWallets; // Only one per address
    event ClonedContract(address _clonedContract);

    constructor(){
        admin = msg.sender;
        Wallet wallet = new Wallet(address(this));
        contractToClone = address(wallet);
    }

    modifier isAdmin() {
        require(msg.sender == admin, "Not the admin");
        _;
    }

    function setContractToClone(address _addr) external isAdmin {
        contractToClone = _addr;
    }

    function createStorage() public {
        require(DCAWallets[msg.sender] == address(0), "Wallet already exist for this address");
        //Create clone of Storage smart contract
        require(contractToClone != address(0), "No contract to clone");
        address clone = createClone(contractToClone);
        // Storage(clone).init(msg.sender); fonction pour initialiser le clone 
        Wallet(clone).init(address(this), msg.sender);
        DCAWallets[msg.sender] = clone;
        emit ClonedContract(clone);
    }

}