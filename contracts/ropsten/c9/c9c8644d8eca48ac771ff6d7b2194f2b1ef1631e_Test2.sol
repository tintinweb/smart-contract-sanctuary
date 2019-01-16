pragma solidity ^0.4.24;

contract Test2 {
    
    function seeAddress(uint256 xxx) external view returns(address, uint256) {
        return(msg.sender, xxx);
    }
  
  
}