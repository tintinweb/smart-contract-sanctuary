pragma solidity ^0.4.24;

contract Test2 {
    
    function seeAddress() external view returns(address) {
        return msg.sender;
    }
  
  
}