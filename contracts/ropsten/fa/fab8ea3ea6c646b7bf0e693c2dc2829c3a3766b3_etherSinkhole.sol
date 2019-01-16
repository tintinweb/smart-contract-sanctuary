pragma solidity ^0.4.25;
contract etherSinkhole{
    constructor() public{}
    function destroy() public{
        selfdestruct(msg.sender);
    }
}