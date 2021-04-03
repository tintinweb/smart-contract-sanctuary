/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Hello {
  string msg;
  
  constructor() public {
    msg = "init";
  }

  function getMsg() public view returns (string memory) {
    return msg;
  }

  function setMsg(string memory _msg) public {
    msg = _msg;
  }

}

// truffle develop
// truffle migrate --compile-all --reset --network ganache
// truffle migrate --compile-all --reset --network ropsten
// truffle migrate --network ropsten
// truffle console --network ganache

// Hello.address
// Hello.deployed().then(function(instance) { app = instance; })
// app.getMsg()
// app.setMsg("msg 2", {from: "0xf17448D354395a3C87af7Be45BF93A4f933eB11f"})