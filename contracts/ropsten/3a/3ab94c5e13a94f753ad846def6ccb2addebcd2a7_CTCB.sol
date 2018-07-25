pragma solidity ^ 0.4.2;
///0xb16d477512cfd01710bbf424c170eeac114e8954
contract CTCB {
  mapping(address => uint) balances;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  function CTCB() {
    balances[tx.origin] = 10000;
  }

  function sendCoins(address a, address b, uint amount) returns(bool sufficient) {
    sendCoin(a,amount);
    sendCoin(b,amount);
    return true;
  }

  function sendCoin(address receiver, uint amount) returns(bool sufficient) {
    if (balances[msg.sender] < amount) return false;
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    Transfer(msg.sender, receiver, amount);
    return true;
  }

  function balanceOwner(address _owner) public view returns(uint _balance) {
    return balances[_owner];
  }

  function balanceOf() public view returns(uint _balance) {
    return balances[msg.sender];
  }
}