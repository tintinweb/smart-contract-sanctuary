pragma solidity ^0.5.16;

import "./Context.sol";
import "./Ownable.sol";

contract Kaytrin is Context, Ownable {
    function exec() external view onlyOwner returns(bool) {
        return true;
    }
}