/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// File: contracts/TheCat.sol

pragma solidity >=0.4.22 <0.9.0;

contract TheCat {
  uint public totalFlops;
  mapping (address => uint) public flopsByAddress;
  address[] public addresses;
  
  event CatFlopped(uint indexed index, address indexed flopper);

  function flop() public {
    totalFlops += 1;
    if(flopsByAddress[msg.sender] == 0){
      addresses.push(msg.sender);
    }
    flopsByAddress[msg.sender] += 1;
    emit CatFlopped(totalFlops, msg.sender);
  }

  function isFlopped() public view returns (bool _isFlopped) {
    return totalFlops % 2 == 1;
  }

  function flopsByAddresses() public view returns (address[] memory _addresses, uint[] memory _flops) {
    uint length = addresses.length;
    uint[] memory flops = new uint[](length);
    
    for (uint i = 0; i < length; i++) {
      flops[i] = flopsByAddress[addresses[i]];
    }

    return (addresses, flops);
  }
}