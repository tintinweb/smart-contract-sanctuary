pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    constructor () public {
        owner = 0xCfBbef59AC2620271d8C8163a294A04f0b31Ef3f;
    }

     modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
}

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TokenERC20 {
  function transfer(address _to, uint256 _value) public;
}

contract SensusTokenSender is Ownable {

    function drop(TokenERC20 token, address[] to, uint256[] value) onlyOwner public {
    for (uint256 i = 0; i < to.length; i++) {
      token.transfer(to[i], value[i]);
    }
  }
}