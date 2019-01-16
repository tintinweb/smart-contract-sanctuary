pragma solidity ^0.4.25;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }
}

contract FORWARD_1 {
  using SafeMath for uint256;

  address owner = msg.sender;
  address multisig = 0x875EE7167c296365Fae785EC9C1858E6d8b2FDD5;

  event Send(uint256 _amount, address indexed _receiver);

  modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
  function() public payable {
    multisig.transfer(msg.value);
  }

  function Sender(uint256 amount, address[] list) onlyOwner external returns (bool) {
    uint256 totalList = list.length;
    uint256 totalAmount = amount.mul(totalList);
    require(address(this).balance > totalAmount);

    for (uint256 i = 0; i < list.length; i++) {
      require(list[i] != address(0));
      require(list[i].send(amount));

      emit Send(amount, list[i]);
    }

    return true;
  }

}