pragma solidity ^0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract MultiTransfer {
  function balanceOf(address _token, address _who) public view returns(uint256) {
    return ERC20Basic(_token).balanceOf(_who);
  }

  function transfer(address _token, address[] _to, uint256[] _value) public returns(bool) {

    require(_to.length != 0);
    require(_value.length != 0);
    require(_to.length == _value.length);

    uint256 sum = 0;

    for (uint256 i = 0; i < _to.length; i++) {
      require(_to[i] != address(0));
      sum += _value[i];
    }

    assert(balanceOf(_token, msg.sender) >= sum);


    for (i = 0; i < _to.length; i++) {
      ERC20Basic(_token).transfer(_to[i], _value[i]);
    }

    return true;
  }
}