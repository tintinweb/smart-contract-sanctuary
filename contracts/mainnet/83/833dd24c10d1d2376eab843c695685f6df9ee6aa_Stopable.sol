//pragma solidity >=0.4.24 <0.6.0;
pragma solidity ^0.4.24;

import "./Ownable.sol";

contract Stoppable is Ownable{
    bool public stopped = false;
    
    modifier enabled {
        require (!stopped);
        _;
    }
    
    function stop() external onlyOwner { 
        stopped = true; 
    }
    
    function start() external onlyOwner {
        stopped = false;
    }    
}
