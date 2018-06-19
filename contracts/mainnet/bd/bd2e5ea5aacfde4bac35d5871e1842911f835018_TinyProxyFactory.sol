pragma solidity ^0.4.17;

contract TinyProxy {
  address public receiver;
  uint public gasBudget;

  function TinyProxy(address toAddr, uint proxyGas) public {
    receiver = toAddr;
    gasBudget = proxyGas;
  }

  event FundsReceived(uint amount);
  event FundsReleased(address to, uint amount);

  function () payable public {
    emit FundsReceived(msg.value);
  }

  function release() public {
    uint balance = address(this).balance;
    if(gasBudget > 0){
      require(receiver.call.gas(gasBudget).value(balance)());
    } else {
      require(receiver.send(balance));
    }
    emit FundsReleased(receiver, balance);
  }
}

contract TinyProxyFactory {
  mapping(address => mapping(uint => address)) public proxyFor;
  mapping(address => address[]) public userProxies;

  event ProxyDeployed(address to, uint gas);
  function make(address to, uint gas, bool track) public returns(address proxy){
    proxy = proxyFor[to][gas];
    if(proxy == 0x0) {
      proxy = new TinyProxy(to, gas);
      proxyFor[to][gas] = proxy;
      emit ProxyDeployed(to, gas);
    }
    if(track) {
      userProxies[msg.sender].push(proxy);
    }
    return proxy;
  }

  function untrack(uint index) public {
    uint lastProxy = userProxies[msg.sender].length - 1;
    userProxies[msg.sender][index] = userProxies[msg.sender][lastProxy];
    delete userProxies[msg.sender][lastProxy];
  }
}