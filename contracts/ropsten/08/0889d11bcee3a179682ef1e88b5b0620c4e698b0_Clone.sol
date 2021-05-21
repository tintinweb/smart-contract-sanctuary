/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.4.23;

contract CloneFactory {

  // BK Ok - Event
  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"600034603b57603080600f833981f36000368180378080368173bebebebebebebebebebebebebebebebebebebebe5af43d82803e15602c573d90f35b3d90fd";
    // BK Ok - Template code address
    bytes20 targetBytes = bytes20(target);
    // BK Next block Ok - Overwrite `beefbeefbeefbeefbeefbeefbeefbeefbeefbeef` with template code address
    for (uint i = 0; i < 20; i++) {
      clone[26 + i] = targetBytes[i];
    }
    assembly {
      // BK NOTE - mload(p) - mem[p..(p+32)). Load word from memory.
      // BK Ok - Len will be 0x48 (72), the number of bytes in clone
      let len := mload(clone)
      // BK NOTE - `data` will point to the start of the `clone` data
      // BK NOTE - In this function, data will be 0xa0 (160)
      let data := add(clone, 0x20)
      // BK Ok - create(v, p, s) - create new contract with code mem[p..(p+s)) and send v wei and return the new address
      result := create(0, data, len)
    }
  }
}

contract Code {
    uint public testVar;
    
}

contract Clone is CloneFactory {
    Code public template;
    Code public cloneAddress;

    constructor() public {
        template = new Code();
    }
    
    function cloneIt() public payable returns (Code _cloneAddress) {
        cloneAddress = Code(createClone(template));
        _cloneAddress = cloneAddress;
    }
}