//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game {
  event Winner(address winner);

  function win() public {
    emit Winner(msg.sender);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game1 {
  uint8 y = 200;

  event Winner(address winner);

  function win(uint8 x) public {
    uint sum = x + y;
    require(sum == 10);
    emit Winner(msg.sender);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game2 {
  event Winner(address winner);

  function win() payable public {
    require(msg.value <= 1 gwei);

    if(address(this).balance >= 3 gwei) {
      emit Winner(msg.sender);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game3 {
  event Winner(address winner);

  bytes32 internal constant SECRET_SLOT = keccak256("secret.variable.slot");

  constructor(uint secret) {
    bytes32 slot = SECRET_SLOT;
    assembly {
      sstore(slot, secret)
    }
  }

  function win(uint guess) payable public {
    uint secret;
    bytes32 slot = SECRET_SLOT;
    assembly {
      secret := sload(slot)
    }
    require(guess == secret);
    emit Winner(msg.sender);
  }
}

