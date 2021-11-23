// SPDX-License-Identifier: Unlicense

/*
  ██████ 
▒██    ▒ 
░ ▓██▄   
  ▒   ██▒
▒██████▒▒
▒ ▒▓▒ ▒ ░
░ ░▒  ░ ░
░  ░  ░  
      ░   
*/

pragma solidity^0.8.1;

contract CorruptionsStrangeApparatus {
    event Message(string indexed message);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function cipher() public pure returns (string memory) {
        return "(CORRUPTOR...).APPEND(QWERTY...)";
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "CorruptionsStrangeApparatus: not owner");
        emit Message(message);
    }
}