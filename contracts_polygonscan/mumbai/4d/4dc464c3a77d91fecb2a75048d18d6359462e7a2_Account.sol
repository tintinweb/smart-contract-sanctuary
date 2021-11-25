/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

pragma solidity 0.8.10;

contract Account {
    address public owner;

    constructor(address payable _owner) public {
        owner = _owner;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }

    function destroy(address payable recipient) public {
        require(msg.sender == owner);
        selfdestruct(recipient);
    }

    fallback() external payable {}

    receive() external payable {}
}