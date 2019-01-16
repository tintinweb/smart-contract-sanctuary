pragma solidity 0.4.24;

contract ERC20 {
  function transferFrom (address _from, address _to, uint256 _value) public returns (bool success);
}

contract ERC223 {
  function transfer (address _to, uint256 _value) public returns (bool success);
}

contract TokenSwap {

  ERC223 CanYaCoin223;
  ERC20 CanYaCoin20;

  address can20Receiver = 0x000000000000000000000000000000000000dEaD;

  constructor (address _can223, address _can20) {
    CanYaCoin223 = ERC223(_can223);
    CanYaCoin20 = ERC20(_can20);
  }

  function swap (uint256 _value) {
    require(CanYaCoin20.transferFrom(msg.sender, can20Receiver, _value));
    require(CanYaCoin223.transfer(msg.sender, _value));
  }

}