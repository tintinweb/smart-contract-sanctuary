/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity ^0.4.0;

contract owned {

    address public owner;
    address public candidate;

    function owned() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    function changeOwner(address _owner) onlyOwner public {
            candidate = _owner;
     }

    function confirmOwner() public {
        require(candidate == msg.sender);
        owner = candidate;
    }


}