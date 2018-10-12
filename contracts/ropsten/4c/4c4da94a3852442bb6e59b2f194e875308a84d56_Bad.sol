pragma solidity ^0.4.10;

contract Bad {
    
    function doFail() public {
        require(false, "It&#39;s fail, bro!");
    }
}