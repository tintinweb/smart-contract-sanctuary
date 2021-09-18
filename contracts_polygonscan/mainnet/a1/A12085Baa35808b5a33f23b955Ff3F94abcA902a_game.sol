/**
 *Submitted for verification at polygonscan.com on 2021-09-18
*/

pragma solidity ^0.5.10;

contract game {
    event win(address addr);
    
    address public code;
    address public owner;
    constructor() public payable {
        owner = msg.sender;
    }

    function check(address addr) public {
        uint size;
        assembly { size := extcodesize(addr) }
        require(size > 0 && size <= 4);
        code = addr;
    }
    
    function execute() public {
        require(code != address(0));
        code.delegatecall(abi.encodeWithSelector(bytes4(keccak256(""))));
        selfdestruct(address(uint160(owner)));
    }
    
    function getBouns() public payable {
        require(msg.value >= 233333 ether);
        emit win(msg.sender);
        msg.sender.transfer(address(this).balance);
    }
    function() external payable {}
    
}