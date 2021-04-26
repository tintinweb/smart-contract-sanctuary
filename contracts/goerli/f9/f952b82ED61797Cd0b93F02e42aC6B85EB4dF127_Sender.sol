/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.8.0;

interface IStateSender {
  function syncState(address receiver, bytes calldata data) external;
  function register(address sender, address receiver) external;
}

contract Sender {
    
    address public stateSender = 0xEAa852323826C71cd7920C3b4c007184234c3945;
    address public receiver;
    uint256 public states;
    constructor(address _stateSender, address _receiver) {
        stateSender = _stateSender;
        receiver = _receiver;
    }

    function sendDepositState(uint256 _amount) external {
         _incrementState();
         bytes memory data = abi.encode(msg.sender, _amount);
         IStateSender(stateSender).syncState(receiver, data);
    }

    function sendState(bytes calldata data) external {
        _incrementState();
        IStateSender(stateSender).syncState(receiver, data);
    }

    function setSender(address _sender) external {
        stateSender = _sender;
    }

    function setReceiver(address _receiver) external {
        receiver = _receiver;
    }

    function _incrementState() private {
           states = states + 1;
    }

}