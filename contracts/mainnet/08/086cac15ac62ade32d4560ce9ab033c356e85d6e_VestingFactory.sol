/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity =0.5.16;

contract ReservoirLike {
  function init(uint numTokens, address target) external;
  function drip() external;  
}

contract Proxy {
    function() external payable {
        assembly {
            let _target := 0x9a2E280aAeB4dE82AAD34Df9c114f67A1699744c
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}

contract VestingFactory {
  event Create(address proxy, uint numTokens, address target);

  function create(uint numTokens, address target) public returns(address) {
    Proxy proxy = new Proxy();
    ReservoirLike(address(proxy)).init(numTokens, target);

    emit Create(address(proxy), numTokens, target);

    return address(proxy);
  }

  function drip(address proxy) public {
    ReservoirLike(proxy).drip();
  }
}